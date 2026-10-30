# CLAUDE.md

Guidance for working in this repository.

## What this is

**TimeOnTrack** is a single-file Ruby plugin for [SwiftBar](https://github.com/swiftbar/SwiftBar)
that tracks time across multiple named jobs concurrently. Each job holds any number of
*entries* (individual tracking sessions). Jobs can be paused, stopped, renamed, archived and
deleted; entries can be edited, renamed and deleted. There is no build step and no
dependency beyond the Ruby standard library.

`TimeOnTrack.1s.rb` is the whole program — everything else is data or documentation.

## The one-second contract

The file name `TimeOnTrack.1s.rb` is SwiftBar's refresh schedule: **the script is executed
from scratch every second.** That follows from a hard product requirement — a live timer is
shown in the menu bar and must tick — so per-run cost is the dominant performance concern.

Consequences to keep in mind when editing:

- Anything expensive at startup is paid 86,400 times a day. `require`ing a heavy library, or
  parsing a large file, on every run is a real regression.
- The archive (potentially ~1 MB) is therefore parsed **lazily**, only when an archived job or
  entry is actually looked up. See `archive_jobs`. Never reintroduce an eager parse in
  `loadJSON`.
- Prefer `ENV["LANG"]` over shelling out to `defaults`. A subprocess fork costs more than the
  work the script does. (Measured: `ruby -e ''` ≈ 50 ms; `defaults read` ≈ 8 ms.)
- A larger optimisation (the SwiftBar *streamable* plugin type — one long-lived process
  instead of 86,400 spawns/day) has been deliberately deferred. It is documented in
  `MIGRATION.md`; do not adopt it without benchmarking, because SwiftBar rebuilds the whole
  menu on each `~~~` separator and the open dropdown may flicker.

## Data model

State lives in two JSON files. The schema is flat and denormalised:

```jsonc
// TimeOnTrackData.json
{
  "language": "de_AT",          // remembered so action runs know the language
  "activeJob": "<job id>|null",
  "activeEntry": "<entry id>|null",
  "jobs": [ { "id", "name", "archived": false,
              "entries": [ { "id", "start", "end", "total", "job_id", "name"? } ],
              "total" } ]
}

// TimeOnTrackArchive.json
{ "jobs": [ /* same shape, archived: true */ ] }
```

Notes:

- `start`/`end` are Unix timestamps; `total` is seconds.
- `entry.name` is **optional** and only present when the user named an entry.
- `job_id` on an entry is redundant (the job is the parent) and is recomputed on every load.
- **`total` is derived, never authoritative.** `loadJSON` recomputes every entry's `total`
  from `end - start` and sums them into the job. Do not trust `total` as read from disk.
- A *running* entry is one whose id equals `activeEntry`; its `end` is advanced to now on
  every tick (`updateRunningTimer`) and the file is re-saved, so a crash loses ≤1 second.
  This is intentional — see the note in `MIGRATION.md` before changing it.

## Where data lives

```
$PLUGIN_DIR = File.dirname(File.realpath(__FILE__))   # repo root, even when symlinked
$DATA_DIR   = ~/Library/Application Support/TimeOnTrack
```

- `File.realpath` is used for `$PLUGIN_DIR` to make the asset directory explicit. Note that
  Ruby's `__dir__` *already* resolves symlinks, so this is belt-and-braces rather than a bug
  fix — do not describe it as one.
- **`SWIFTBAR_PLUGIN_DATA_PATH` is not trusted — do not "simplify" this to `ENV[...] ||`.**
  On SwiftBar 2.1.x that variable is broken: the plugin's *absolute* path is appended below
  the support root, producing
  `…/swiftbar/plugins/Users/me/git/repo/TimeOnTrack.1s.rb/`. SwiftBar's own source documents
  this (`regressedSupportDirectory`, "an absolute plugin ID mistakenly appended below the
  support root") and it *creates* that directory, so a plain `File.directory?` test passes and
  is not sufficient. Inside `File.join`, an absolute second argument also discards the first,
  which is how such a path silently becomes a real directory tree.
  Even on a fixed build the value would be `<plugin folder>/<this file's name>` — the plugin
  file itself, because on macOS's case-insensitive volume SwiftBar's support directory and the
  plugin folder are one directory.
  The code therefore accepts the variable only when it is a real directory that is **not**
  inside `$PLUGIN_DIR` and **not** inside `SWIFTBAR_PLUGINS_PATH` (the plugin folder —
  everything in there is treated as a plugin candidate). Otherwise it falls back to
  `~/Library/Application Support/TimeOnTrack`. A test asserting the fallback for a simulated
  2.1.x path is worth keeping.
- Bundled assets (`TimeOnTrack/lang/`) are read from `$PLUGIN_DIR`; mutable state from
  `$DATA_DIR`.
- **Dev mode** (`VAR_DEV_MODE` setting, or `SWIFTBAR_TIMEONTRACK_DEV=1` for CLI runs) appends
  `/dev` to `$DATA_DIR` and prefixes/tints the menu bar text (`$DEV_PREFIX`, `#E8A400`) plus a
  banner at the bottom of the dropdown. It exists so a new build can run alongside the
  production plugin without the two writing to the same files. Note this is *not* what makes
  the two safe in parallel — they are already safe because they resolve to entirely different
  data directories (the xbar copy keeps data in its own repo). Dev mode is for running two
  copies of *this* plugin.
- Data files are intentionally **gitignored** — personal time data does not belong in a
  public repository. The `TimeOnTrack/*.json` paths are ignored too; they are only a stale
  fallback and are no longer written.

## How the script is structured

Sections are marked with comments; keep new code inside the matching section.

1. **Metadata** — the commented header SwiftBar parses. Also holds
   `swiftbar.var` declarations (currently `VAR_LANGUAGE_OVERRIDE`).
2. **Constants** — `$ICON` (base64 SVGs), paths, `$FONT_MENU`, `$EMPTY_DATA`.
3. **Prompts** — AppleScript dialogs (`prompt`, `yes_no_prompt`, `alert`, `show_dialog`).
   These block on user input and are only reachable from action runs.
4. **Helpers** — i18n (`t`, `load_language_file`), `icon`, `escape_html`, `run_command`,
   `format_duration`, `read_json`.
5. **Getters** — `getJobById`, `getEntryById`, `getActiveJob`, `archive_jobs`.
6. **Main functions** — mutations (`createNewJob`, `startNewEntry`, `deleteJob`, …) and the
   daily-summary generator.
7. **Journal** — `journal_payload` / `journal_i18n` / `generateJournal`. See below.
8. **Menu** — `buildMenu`, which prints SwiftBar's line format to stdout.
9. **Action handler** — `actionHandler`, dispatching on `ARGV`.
10. **`_main`** — the entry point.

## The journal

The journal is a **self-contained offline page**, not HTML generated by string templates.
Ruby's only job is to embed the data and the assets; every filter, sort, group and export
runs in the browser.

```
TimeOnTrack/journal/journal.html   scaffold with %%PLACEHOLDERS%%
TimeOnTrack/journal/journal.css    layout, light/dark via prefers-color-scheme
TimeOnTrack/journal/journal.js     all behaviour; pure functions + DOM half
```

Why it is split this way: the previous implementation built the whole document from Ruby
string literals, which made the markup painful to edit and let an entire class of bug hide
in it (the shared-template `gsub!` that repeated every row). Assets on disk keep Ruby free
of HTML quoting and keep `ruby -c` meaningful.

**Data payload.** `journal_payload` shortens keys and drops derived fields (`total`,
`job_id`) because the browser recomputes them. Active + archived jobs are combined; the
page has switches to hide either. That takes the embed from ~530 KB to ~100 KB for 777
jobs / 3.2k entries (total page ≈ 166 KB).

> The embedded JSON is escaped with `gsub("</", "<\\/")`. Without it a job name containing
> `</script>` would end the script block early and break the page (or inject markup). Do
> not remove that line.

**Output location.** A *fixed* path — `$DATA_DIR/journal.html`, not a timestamped file in
`tmpdir`. A bookmark therefore keeps working, and nothing accumulates. macOS purges old
`$TMPDIR` files after 3 days, which silently killed the previous timestamped output.

**Staleness / reload.** The page embeds its own generation timestamp, so it knows how old it
is without asking anyone. A timer re-renders the age every 15 s and reveals the stale banner
on its own once the page crosses the threshold — the banner is not a one-shot check at load.
While stale, the ⟳ button is emphasised.

**Regenerating writes the file; it does not reload the page.** The browser will not notice an
external rewrite of a file it already has open, and this is a real trap: the regeneration
succeeds and *still* nothing appears to change. So the button does both — it fires the
custom-scheme request, then calls `window.location.reload()` after a short delay so SwiftBar
has time to write. Without that second step the button looks broken even though it worked.

**The request goes through a hidden iframe**, not an `<img>` or a top-level
navigation: some browsers drop a custom scheme set on an image's `src`, and a top-level
navigation would leave the page.

**Auto-regen on load is best effort.** If the file is already stale when opened, the page
fires one regeneration. Browsers may refuse a custom scheme without a user gesture, in which
case the banner and the button are the fallback. It deliberately does **not** reload itself —
a reload loop would be worse than slightly old numbers.

The URL is `swiftbar://refreshplugin?name=<plugin>&journal=regen`. SwiftBar passes unknown
query parameters through as environment variables (`AppDelegate.application(_:open:)` does
`plugin.refreshEnv = params.filter { $0.key != "name" }`). `_main` catches `ENV["journal"]
== "regen"` and regenerates *before* the action handler, so no menu is printed and the data
file is never touched — it is a side channel, not a plugin run.

> **REQUIRES SWIFTBAR ≥ 2.1.2 — and that release is not out yet.** As of writing, 2.1.2 is
> at `beta-5` and **2.1.1 is the last stable release and what Homebrew ships**. The
> `refreshplugin` endpoint does not exist in 2.1.1, so on the current install the reload
> button and the auto-regen are inert.
>
> Verified two ways on 2.1.1: the string `refreshplugin` is **absent** from the app binary
> (while `refreshallplugins` and `setephemeralplugin` are present), and a probe plugin
> showed `SWIFTBAR_PLUGIN_REFRESH_REASON=Schedule` rather than `URLScheme`, with no query
> parameter ever arriving. `open` still exits 0 — LaunchServices accepts the URL and the app
> discards it — so **the failure is silent** and looks like a broken button.
>
> The implementation is nonetheless correct for 2.1.2: the `v2.1.2-beta-5` tag contains both
> the `refreshplugin` case and the `refreshEnv` assignment, and `refreshEnv` is merged into
> the plugin's environment. `getPluginByNameOrID` matches `id`, then `name`, then
> `urlSchemeFileName` — the third of which our file name hits.
>
> **When 2.1.2 ships:** confirm Homebrew has it
> (`curl -sL https://formulae.brew.sh/api/cask/swiftbar.json`), then test the button
> end-to-end and remove the TODOs marked `swiftbar-2.1.2` in `TimeOnTrack.1s.rb` and
> `journal.js`. Nothing needs rewriting. Until then, "Show Journal" in the menu is the
> reliable path — it always regenerates.

**The plugin name in that URL matters.** It must be the name SwiftBar knows the plugin by —
the *symlink* name in the plugin folder, which for a dev-named link differs from the real
file. `plugin_file_name` therefore prefers `SWIFTBAR_PLUGIN_PATH` over `File.realpath`;
using `realpath` here would make the reload button silently do nothing.

**Never regenerate on a timer.** The journal is a rarely used view. Writing it on every
data change would be wasted work, and there is no way for the plugin to know a browser tab
is open. It is written only when requested.


### The action-dispatch protocol

This is the part most likely to surprise you. The script runs in **two modes**, decided by
whether it was passed arguments:

- **Plugin mode** (`ARGV` empty): read state, advance the running timer, print the menu, save.
- **Action mode** (arguments present): perform one mutation, save, and `exit` before any
  menu is printed.

Menu items trigger actions by re-invoking the script itself:

```
Neuer Job | refresh=true shell="<path>" param1=job:new terminal=false
```

`run_command` builds the `shell=`/`param*`/`terminal=` part. SwiftBar collects every `param*`
key into argv, so in the shell script `ARGV[0]` is `job:new`, `ARGV[1]` is the uuid, etc.
SwiftBar has no `disabled=` parameter — a line with **no action at all** is rendered greyed
out. That is how the "already tracking" entries are disabled; do not reintroduce
`disabled=true`.

### Two output-format traps (both were real bugs here)
**1. Only the FIRST `|` separates title from parameters.** SwiftBar's parser
(`MenuLineParameters.init`) splits on the first `|` and then treats everything after it as a
space-separated parameter list. Emitting a second `|` — which the old xbar-style output did,
e.g. `title | refresh=true | shell=... | templateImage=...` — makes `"| shell"` and
`"| templateimage"` the *keys*, so `bash` resolves to nil and **the menu item does nothing**.
It fails silently: the item renders, it just isn't clickable. All line building therefore goes
through `menu_line(title, *params)`, and the helpers (`icon`, `run_command`) return bare
`key="value"` fragments with no leading `|`. Do not hand-concatenate a `|` into a line.

**2. Descriptive metadata tags must use the `xbar.` prefix, not `swiftbar.`.** In
`PluginMetadata.swift` the `optionType` for `title/version/author/github/desc/image/
dependencies/about` is `[.bitbar, .xbar]` — *not* `.swiftbar`. Writing `<swiftbar.title>`
parses to nothing and leaves the About pane in SwiftBar's preferences blank, including the
Plugin Variables section (so `VAR_DEV_MODE` never appears). Only SwiftBar's own additions use
`swiftbar.`: `hideAbout`, `hideRunInTerminal`, `hideLastUpdated`, `hideDisablePlugin`,
`hideSwiftBar`, `schedule`, `type`, `environment`, `runInBash`, `refreshOnOpen`,
`collapseOnClose`, `persistentWebView`, `alwaysVisible`. `<swiftbar.var>` *is* correct (the
var-tag regex accepts both prefixes).

Because action mode has no plugin environment, the language is persisted in
`$data["language"]` and read back from there.

### Dialog text goes through argv, never interpolation

`prompt`, `yes_no_prompt`, `alert` and `show_dialog` all build an AppleScript with
`on run argv` and hand the user-facing strings in as arguments via
`IO.popen(["osascript", "-e", script, "--", *args], external_encoding: Encoding::UTF_8)`.
Two reasons, both bugs that existed in the original xbar plugin:

- **Encoding.** osascript's output is tagged with Ruby's *default external* encoding, which
  is US-ASCII when `LANG` is unset — the normal state for a GUI-launched app. Calling
  `.strip` on a US-ASCII string containing an umlaut raises `Encoding::CompatibilityError`,
  which aborted the action. Naming a job "Büro" silently created nothing at all. Reading the
  pipe as UTF-8 fixes it; `run_osascript` also `.scrub`s so a stray byte cannot kill an
  action. Any new subprocess output should be handled the same way.
- **Quoting.** Interpolated `"` broke the AppleScript source (a hard syntax error) and `'`
  could break the surrounding shell string.

Keep the script body pure ASCII and pass values as argv. Note that `default button` takes an
item reference (`(item 4 of argv)`), not a bare number — a number is a *button index*, and an
out-of-range one fails with "-50: button does not exist".

### Icons must be template images

`icon()` emits `templateImage=`, never `image=`. A template image is recoloured by macOS to
match its context — white on a dark menu bar, black on a light one — so it stays legible in
both appearances. `image=` renders the literal colour baked into the SVG instead, so an icon
whose SVG is black stays black and disappears against a dark dropdown. (This is exactly what
happened to the record dot: it was passed `preserve_color=true` and rendered black on a dark
menu.) There is no longer any reason to use `image=` here.

### The title line must not carry `refresh=true`

SwiftBar routes a click by what the *title* line declares. A title line with `refresh` but no
`bash` is treated as its own action (`routeForBarItemClick` → `.runTitleAction`), so a plain
left click just re-runs the plugin and **the dropdown never opens** — you end up needing a
right click, which always opens the menu. The plugin already ticks every second, so the
refresh was pointless anyway. Leave the header line free of action parameters.

## Conventions

- Do not add `disabled=true` (unsupported) or `.darkmode` (xbar-only). Dark mode is
  `ENV["OS_APPEARANCE"]` (`"Light"`/`"Dark"`), or `light,dark` pairs on colour params.
- Every user-visible string goes through `t("key")` and exists in **both**
  `TimeOnTrack/lang/en_US.json` and `de_DE.json`. Keep the two files key-identical — a quick
  check is `git diff --stat` plus a key comparison.
- `TimeOnTrack/lang/en_US.json` is the fallback for every unresolvable locale, so it must
  stay complete. Journal keys are listed in `journal_i18n`; a key that is referenced there
  but missing from a language file silently renders as the raw key name, so verify with the
  check below rather than by eye.
- Escape any user-supplied text interpolated into HTML with `escape_html`, and escape `</`
  in anything embedded inside a `<script>` block.
- Beware Ruby's shared-string mutation: a template string assigned to a loop-local
  (`row = template`) is the *same object*, so `gsub!` corrupts later iterations. Always
  `.dup` the template. (The journal no longer builds HTML this way, but the rule still
  applies anywhere strings are templated.)

## Testing

**Never test against real data.** Generate a fixture and point the plugin at a scratch or
dev-plugin data directory:

```bash
ruby bin/seed-data.rb /tmp/tot-test          # 4 jobs, 7 entries, one running
SWIFTBAR_PLUGIN_DATA_PATH=/tmp/tot-test VAR_LANGUAGE_OVERRIDE=en_US ruby TimeOnTrack.1s.rb
SWIFTBAR_PLUGIN_DATA_PATH=/tmp/tot-test ruby TimeOnTrack.1s.rb job:pause
```

`bin/seed-data.rb` writes to `tmp/seed-data` by default (gitignored) and never touches real
data.

Four gotchas:

- **Confirmation dialogs auto-confirm in a headless shell** — `osascript` returns the default
  button rather than blocking. So `job:delete` / `entry:delete` will actually delete when run
  from a script. Assume destructive actions *will* fire.
- `journal:open` shells out to `open`, which launches a browser. To inspect the HTML without
  that, prepend a stub directory to `PATH` containing an `open` that echoes its argument.
- **To test against production-scale data, copy it to a scratch directory first** — never
  point the plugin at the real data directory. The live xbar install keeps writing its own
  data files while you work, so a changing checksum there means nothing about your changes.
- **The language in action mode comes from `$data["language"]`, not from the environment.**
  Setting `VAR_LANGUAGE_OVERRIDE` on a `journal:open` call has no effect by design; run the
  plugin once without arguments to persist the language, then invoke the action.

### Journal checks

`journal.js` is importable from Node (the DOM half is guarded), so the filter/group/export
logic is testable without a browser:

```bash
node --check TimeOnTrack/journal/journal.js          # syntax
SWIFTBAR_PLUGIN_DATA_PATH=/tmp/tot-test ruby TimeOnTrack.1s.rb journal:open
```

Then assert on the generated file: no `%%` placeholders remain, the `<script id="tot-data">`
block parses as JSON, the job/entry counts match the source data, and no `journal.*` key in
the embedded i18n object has its own name as its value (that means it was never translated).

## Related docs

- `README.md` — user-facing install and feature documentation.
- `MIGRATION.md` — the xbar→SwiftBar migration, the compatibility differences, and the
  not-yet-performed cutover procedure.
