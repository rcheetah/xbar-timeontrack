# Migrating from xbar to SwiftBar

TimeOnTrack was originally written as an [xbar](https://xbarapp.com) plugin. This document
records what changed in the move to [SwiftBar](https://github.com/swiftbar/SwiftBar), and the
procedure for switching over the live installation.

Findings were verified against the SwiftBar README **and its Swift source**
(`PluginMetadata.swift`, `Plugin.swift`, `Environment.swift`, `MenuLineParameters.swift`),
since the README omits several behaviours that the code implements.

## What the migration changed

### Metadata and variables

The descriptive tags keep the **`xbar.` prefix**: `title`, `version`, `author`,
`author.github`, `desc`, `image`, `dependencies`, `abouturl`. In SwiftBar's
`PluginMetadata.swift` these are typed `[.bitbar, .xbar]` — *not* `.swiftbar`. Only
SwiftBar's own additions use `swiftbar.`:

- `<swiftbar.hideLastUpdated>true</swiftbar.hideLastUpdated>` — at a 1-second refresh the
  "last updated" row is noise.
- `<swiftbar.refreshOnOpen>true</swiftbar.refreshOnOpen>` — the menu is current when clicked.
- `<swiftbar.runInBash>false</swiftbar.runInBash>` — SwiftBar wraps plugins in bash by
  default; this is a shebanged Ruby script, so the wrapper is pointless work.

An earlier revision of this migration renamed *everything* to `swiftbar.*`, which silently
blanked the About pane and the Plugin Variables UI. `<swiftbar.var>` remains correct — the
var-tag regex accepts both prefixes, and user values are stored in `<plugin>.vars.json`
beside the plugin.

### Menu output

**`disabled=true` was removed — it never worked.** SwiftBar has no `disabled` parameter at
all; the xbar version was emitting it into the void. A line is greyed out when it carries no
action, so the "already tracking" entries are now printed with no action parameters:

```
-- Continue | shell="..." param1=job:start param2="<uuid>" terminal=false   # actionable
-- Continue                                                                  # greyed out
```

**The `|` separator was also wrong, and this one was worse.** SwiftBar splits a line on the
**first** `|` only, then parses the remainder as a space-separated parameter list. The old
output had a `|` before *every* parameter:

```
New Job | refresh=true | shell="..." param1=job:new | templateImage="..."   # broken
```

which makes `"| shell"` and `"| templateimage"` the parameter keys, so `bash` resolves to nil.
Every menu item rendered but **did nothing when clicked** — a silent failure, not an error.
All lines are now built by a single `menu_line(title, *params)` helper, with parameters
separated by spaces:

```
New Job | refresh=true shell="..." param1=job:new terminal=false templateImage="..."
```

The `shell=` / `param1=` / `terminal=false` / `refresh=true` parameter *names* are unchanged —
SwiftBar reads `params["bash"] ?? params["shell"]` and collects every `param*` key.

### Path resolution

The plugin now derives its asset directory from `File.realpath(__FILE__)` instead of `__dir__`.
This is a clarification rather than a fix: Ruby's `__dir__` **already resolves symlinks**, so
the old code found its bundled `lang/` directory correctly even when the host executed the
plugin through a symlink. Verified directly — running a script through a symlink gives
`__dir__ == File.dirname(File.realpath(__FILE__))`.

An earlier draft of this document claimed the old code was broken here and that it caused the
stray `lang/` and `*.json` entries in the plugin folder. That was wrong. Those entries are
plain leftovers — a `lang/` copy dated April 2025 plus two *empty directories* named
`de_DE.json` and `en_US.json`. They were placed there by hand, not created by the plugin. They
are still worth deleting: SwiftBar treats anything in the plugin folder as a plugin candidate,
which is why the two are listed in `DisabledPlugins`.

### Data files

State moved out of the repository to `~/Library/Application Support/TimeOnTrack/`. Personal
time data is no longer committed to git.

The obvious choice — SwiftBar's `SWIFTBAR_PLUGIN_DATA_PATH` — turned out to be unusable.
SwiftBar builds that path as `<plugin folder>/<plugin file name>`, which **is the plugin file
itself** when the plugin sits directly in the plugin folder. macOS's default volume is
case-insensitive, so SwiftBar's support directory (`.../SwiftBar/Plugins`) and the plugin
folder (`.../swiftbar/plugins`) are the same directory, and the path resolves to the symlink
rather than to a directory. The plugin now checks that the variable points at a real,
separate directory and otherwise uses its own Application Support folder. This is worth
knowing before anyone "simplifies" it back.

### Behaviour preserved deliberately

- **The per-tick write stays.** While a timer runs, the entry's `end` is refreshed and the
  file re-saved every second. This is what makes a crash or reboot lose at most one second.
  Removing it would save ~7 KB/s of writes but discard the whole current segment on a crash.
- **The 1-second refresh stays.** A live clock in the menu bar must tick every second.

### Bugs fixed along the way

| Bug | Effect |
|---|---|
| `disabled=true` (see above) | Tracking-state entries were not actually disabled in SwiftBar |
| Dialog text interpolated into AppleScript | **A job name containing an umlaut was silently never created** (see below) |
| Second `|` in menu lines (see above) | **Every** action parameter was mis-parsed, so menu items rendered but did nothing when clicked |
| Descriptive tags renamed to `swiftbar.*` | Metadata unread; About pane and Plugin Variables section were blank |
| Unquoted `<swiftbar.var>` defaults | Var regex never matched, so variables stayed hidden in the UI |
| `icon("running")` — not a key in `$ICON` | Emitted `templateImage=""`; the "currently tracking" marker never rendered. Now uses the existing `rec` icon |
| The `rec` marker used `image=` (colour-preserving) | Rendered the SVG's literal black, so the dot vanished against a dark dropdown while every other icon turned white. All icons are now template images |
| Title line carried `refresh=true` with no `bash` | SwiftBar treated left click as that action, so the dropdown opened **only on right click** |
| Shared-string mutation in `generateJournalJobDom` | `row = template` then `gsub!` mutated the template, so **every journal row repeated the first entry's data** |
| `deleteJob` / `deleteEntry` read `ARGV[1]` instead of their argument | Worked by accident; now uses the parameter |
| `yes_no_prompt` hardcoded German buttons | English users saw "Ja"/"Nein" |
| Journal hardcoded `lang='de'` and an English title | Wrong `lang` attribute and a title that ignored the language files |
| `en_US.json` missing `prompt.job.daily_summary.title` | German was fine, English fell back to the raw key |
| UTF-8 not forced when reading JSON | With `LANG` unset Ruby reads as US-ASCII and **raises** on translated language files |
| `loadJSON` assumed `$data["jobs"]` exists | An empty or hand-edited data file crashed the plugin |
| Journal written to `$TMPDIR` with a timestamp | Bookmarks broke on every view, files accumulated, and macOS purged them after 3 days |
| Data-directory guard compared paths as strings | SwiftBar reports `…/SwiftBar/Plugins/…` but the plugin folder resolves to `…/swiftbar/plugins`; macOS calls those one directory, Ruby compared case-sensitively, so the guard never fired and **user data was written into the plugin folder** — where SwiftBar then imported `journal.html` as a plugin and rescanned in a loop (see "Where data lives") |
| `NSAlert` used for the "don't ask again" dialog | Actions run detached (`terminal=false`), so the alert had no GUI session: the window was never shown, yet `runModal()` blocked. The action looked completely dead. Replaced with a third `display dialog` button (see "Dialog text") |
| `job:pause`, `job:stop`, `job:archive` had no `rescue` | Unlike every other branch, so a failure there vanished silently |
| `savefile:edit` interpolated its path into the shell | The data directory contains a space (`Application Support`), so the path split into two arguments and `open` failed silently. Also had a misplaced `begin`/`rescue` that wrapped nothing |
| `error.job:summary` referenced but never defined | The raw key would have been shown instead of a message |

### The journal was rebuilt

The old journal rendered all jobs at once as static HTML built from Ruby string templates.
With the real dataset that is 777 jobs and 3,235 entries (1,645 hours across two years),
which is not usable as a flat list — and the generation code was where the shared-template
`gsub!` bug lived.

It is now a self-contained offline page under `TimeOnTrack/journal/`: the data is embedded
as JSON (≈100 KB, down from ≈530 KB thanks to shortened keys and dropped derived fields) and
all filtering, sorting, grouping, charting and CSV export happens in the browser. Ruby only
embeds data and assets.

Behaviour changes worth knowing:

- Written to a **fixed** path, `~/Library/Application Support/TimeOnTrack/journal.html`, so
  bookmarks work and nothing accumulates.
- **Never regenerated on a timer.** The journal is a rarely used view, and the plugin cannot
  know whether a browser tab is open. It is written only when requested.
- A ⟳ button regenerates on demand through `swiftbar://refreshplugin?…&journal=regen`. The
  page also attempts this on load when it is more than a minute old.

> ⚠️ **That reload mechanism needs SwiftBar 2.1.2, which is still in beta.** The
> `refreshplugin` endpoint does not exist in 2.1.1 — the last stable release, and what
> Homebrew currently installs. On 2.1.1 the button and the auto-refresh do nothing at all,
> and they fail *silently*: `open` returns success and the app ignores the URL. Confirmed by
> checking the 2.1.1 binary (`refreshplugin` is absent from it) and by watching a probe
> plugin, which never received the parameter.
>
> The code is written correctly for 2.1.2 — the `v2.1.2-beta-5` source has the endpoint and
> forwards query parameters to the plugin as environment variables. No rewrite is needed once
> it ships; the TODOs marked `swiftbar-2.1.2` in `TimeOnTrack.1s.rb` and `journal.js` say what
> to check.
>
> In the meantime **"Show Journal" from the menu always regenerates**, so the journal is
> never stale when you open it deliberately. Only an already-open tab cannot be refreshed
> from within the page.


### Umlauts in dialog input (pre-existing bug, finally fixed)

The original plugin never accepted non-ASCII characters in its dialogs. Typing an umlaut —
"Büro" — aborted the action and the job was *silently* not created: no error, no dialog, just
nothing. Easy to miss and then wonder why no clock was running.

The cause was encoding, not typing. osascript's output is tagged with Ruby's default external
encoding, which is **US-ASCII whenever `LANG` is unset** — the normal state for an app launched
from the Finder/Dock rather than a terminal. `strip` on a US-ASCII string that contains an
umlaut raises `Encoding::CompatibilityError`, and the old code let that propagate out of the
action handler.

The dialogs now pass every user-facing string to osascript as an argv argument
(`on run argv` + `osascript -e <script> -- <args>`), and the pipe is read explicitly as UTF-8
with a defensive `scrub`. That fixes the encoding crash and, as a bonus, the quoting bug where
a `"` in the text produced an AppleScript syntax error.


The archive file can be ~1 MB (hundreds of archived jobs) and was parsed on *every one of the
86,400 daily runs*, even though only the journal needs it. It is now parsed lazily. Measured
on a 1.3 MB archive: an ordinary run reads only `TimeOnTrackData.json` and the language file.

`defaults read -g AppleLocale` also forked a process every run; `ENV["LANG"]` is used first
now, with `defaults` only as a fallback.

Deferred, deliberately: the SwiftBar **streamable** plugin type. It would keep one long-lived
process instead of spawning 86,400 a day (Ruby startup alone is ~50 ms per run), but SwiftBar
rebuilds the whole menu on each `~~~` separator, and the open dropdown may flicker while the
user is clicking. Worth benchmarking later; not part of this migration.

---

## Cutover procedure — NOT YET PERFORMED

The xbar plugin is **still the live production plugin**. Until it is replaced, it keeps
running and writing its own data. Nothing below has been executed.

The two installations are independent: the xbar version lives in `~/git/xbar-timeontrack`
with data beside it, the SwiftBar version in `~/git/swiftbar-timeontrack` with data in
`~/Library/Application Support/TimeOnTrack/`. They do not share files.

### Before switching

1. Confirm the SwiftBar plugin works, using a **dev-named** plugin link so it can coexist
   with the live one:

   ```bash
   ln -s ~/git/swiftbar-timeontrack/TimeOnTrack.1s.rb \
         ~/Library/Application\ Support/swiftbar/plugins/TimeOnTrack-dev.1s.rb
   ```

   Then check the menu, the ticking clock, pause/stop/new, and the journal. Both plugins will
   share the same data directory while testing, so seed it with throwaway data first (or
   expect the dev copy to show the same jobs):

   ```bash
   ruby ~/git/swiftbar-timeontrack/bin/seed-data.rb \
        ~/Library/Application\ Support/TimeOnTrack
   ```

2. **Stop the xbar plugin first.** Quit xbar (or disable the plugin) and wait until no entry
   is running. Migrating while it is still ticking would race on the data file.

3. Copy the real data across:

   ```bash
   DEST=~/Library/Application\ Support/TimeOnTrack
   mkdir -p "$DEST"
   cp ~/git/xbar-timeontrack/TimeOnTrack/TimeOnTrackData.json    "$DEST/"
   cp ~/git/xbar-timeontrack/TimeOnTrack/TimeOnTrackArchive.json "$DEST/"
   ```

   The schema is unchanged, so no conversion is needed. `total` values are recomputed from
   `end - start` on load, so any staleness in them corrects itself.

4. Verify the migrated data renders — total time per job and the journal should match what
   xbar showed.

### Switching over

5. Remove the dev link and point the real plugin name at the new repository:

   ```bash
   cd ~/Library/Application\ Support/swiftbar/plugins
   rm TimeOnTrack-dev.1s.rb
   ln -sf ~/git/swiftbar-timeontrack/TimeOnTrack.1s.rb TimeOnTrack.1s.rb
   ```

6. Clean up the leftovers created by the old `__dir__` bug — the stray `lang/` directory and
   the empty `de_DE.json/`, `en_US.json/` directories in the plugins folder:

   ```bash
   rm -rf ~/Library/Application\ Support/swiftbar/plugins/lang \
          ~/Library/Application\ Support/swiftbar/plugins/de_DE.json \
          ~/Library/Application\ Support/swiftbar/plugins/en_US.json
   ```

   and drop the now-dangling `DisabledPlugins` entries (the SwiftBar preferences domain is
   `com.ameba.SwiftBar`):

   ```bash
   defaults read com.ameba.SwiftBar DisabledPlugins
   # then, if de_DE.json / en_US.json are still listed:
   defaults delete com.ameba.SwiftBar DisabledPlugins
   ```

7. Keep `~/git/xbar-timeontrack` and its data untouched until you are satisfied the SwiftBar
   version is correct — it is the only remaining copy of the original data.

### Rolling back

Delete the `TimeOnTrack.1s.rb` symlink from SwiftBar's plugin folder and restore the xbar
plugin. Since nothing in `~/git/xbar-timeontrack` was modified, rollback is immediate and
lossless (apart from time tracked on the SwiftBar side after the switch).
