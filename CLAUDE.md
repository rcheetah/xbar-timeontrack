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
$DATA_DIR   = ENV["SWIFTBAR_PLUGIN_DATA_PATH"]        # only if it is a real, separate dir
              || ~/Library/Application Support/TimeOnTrack
```

- `File.realpath` is used for `$PLUGIN_DIR` to make the asset directory explicit. Note that
  Ruby's `__dir__` *already* resolves symlinks, so this is belt-and-braces rather than a bug
  fix — do not describe it as one.
- **`SWIFTBAR_PLUGIN_DATA_PATH` is not usable as-is.** SwiftBar builds it as
  `<plugin folder>/<this file's name>`, which *is the plugin file itself* when the plugin sits
  directly in the plugin folder. On macOS's case-insensitive volume, SwiftBar's support
  directory (`.../SwiftBar/Plugins`) and the plugin folder (`.../swiftbar/plugins`) are the
  same directory, so that path resolves to the symlink rather than a directory. The code
  therefore uses it only when `File.directory?` confirms a real, separate directory, and
  otherwise falls back to `~/Library/Application Support/TimeOnTrack`. Do not "simplify" this
  back to a plain `ENV[...] ||` — that reintroduces the trap where data files are scattered
  into the plugin folder and then picked up by SwiftBar as plugins.
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

1. **Metadata** — the commented `<swiftbar.*>` header SwiftBar parses. Also holds
   `swiftbar.var` declarations (currently `VAR_LANGUAGE_OVERRIDE`).
2. **Constants** — `$ICON` (base64 SVGs), paths, `$FONT_MENU`, `$EMPTY_DATA`.
3. **Prompts** — AppleScript dialogs (`prompt`, `yes_no_prompt`, `alert`, `show_dialog`).
   These block on user input and are only reachable from action runs.
4. **Helpers** — i18n (`t`, `load_language_file`), `icon`, `escape_html`, `run_command`,
   `format_duration`, `read_json`.
5. **Getters** — `getJobById`, `getEntryById`, `getActiveJob`, `archive_jobs`.
6. **Main functions** — mutations (`createNewJob`, `startNewEntry`, `deleteJob`, …) and the
   journal/summary generators.
7. **Menu** — `buildMenu`, which prints SwiftBar's line format to stdout.
8. **Action handler** — `actionHandler`, dispatching on `ARGV`.
9. **`_main`** — the entry point.

### The action-dispatch protocol

This is the part most likely to surprise you. The script runs in **two modes**, decided by
whether it was passed arguments:

- **Plugin mode** (`ARGV` empty): read state, advance the running timer, print the menu, save.
- **Action mode** (arguments present): perform one mutation, save, and `exit` before any
  menu is printed.

Menu items trigger actions by re-invoking the script itself:

```
| shell="<path>" param1=job:start param2="<uuid>" terminal=false
```

`run_command` builds that. SwiftBar collects every `param*` key into argv, so in the shell
script `ARGV[0]` is `job:start`, `ARGV[1]` is the uuid, etc. SwiftBar has no `disabled=`
parameter — a line with **no action at all** is rendered greyed out. That is how the
"already tracking" entries are disabled; do not reintroduce `disabled=true`.

Because action mode has no plugin environment, the language is persisted in
`$data["language"]` and read back from there.

## Conventions

- Do not add `disabled=true` (unsupported) or `.darkmode` (xbar-only). Dark mode is
  `ENV["OS_APPEARANCE"]` (`"Light"`/`"Dark"`), or `light,dark` pairs on colour params.
- Every user-visible string goes through `t("key")` and exists in **both**
  `TimeOnTrack/lang/en_US.json` and `de_DE.json`. Keep the two files key-identical — a quick
  check is `git diff --stat` plus a key comparison.
- `TimeOnTrack/lang/en_US.json` is the fallback for every unresolvable locale, so it must
  stay complete.
- Escape any user-supplied text interpolated into the journal HTML with `escape_html`.
- Beware Ruby's shared-string mutation: a template string assigned to a loop-local
  (`row = template`) is the *same object*, so `gsub!` corrupts later iterations. Always
  `.dup` the template. This caused every journal row to repeat the first entry.

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

Two gotchas:

- **Confirmation dialogs auto-confirm in a headless shell** — `osascript` returns the default
  button rather than blocking. So `job:delete` / `entry:delete` will actually delete when run
  from a script. Assume destructive actions *will* fire.
- `journal:open` shells out to `open`, which launches a browser. To inspect the HTML without
  that, prepend a stub directory to `PATH` containing an `open` that echoes its argument.

## Related docs

- `README.md` — user-facing install and feature documentation.
- `MIGRATION.md` — the xbar→SwiftBar migration, the compatibility differences, and the
  not-yet-performed cutover procedure.
