# Migrate TimeOnTrack from xbar to SwiftBar (+ moderate cleanup)

> Status: **plan only, not yet executed.** Written 2026-10-29 on branch `swiftbar`.

## Context

`TimeOnTrack.1s.rb` is a ~640-line Ruby menu-bar time tracker written as an **xbar/BitBar**
plugin. It tracks multiple named jobs concurrently, with per-job time entries, archiving,
an HTML "journal" export, a daily summary, and EN/DE localization.

Work has moved to SwiftBar (`/Applications/SwiftBar.app`, v2.1.1, already installed). The
branch `swiftbar` and the checkout `~/git/swiftbar-timeontrack` exist for this migration.
Goal: a plugin that installs cleanly into SwiftBar, is easier to work on, and stops
committing personal time data to the repo.

Research was done against the SwiftBar README **and its Swift source**
(`MenuLineParameters.swift`, `PluginMetadata.swift`, `MenuBarItem.swift`), so the
compatibility findings below are verified, not assumed.

**Decisions taken:** SwiftBar-only (no xbar compatibility constraint); moderate cleanup;
data files to be sourced from SwiftBar's plugin-data directory rather than the repo.

**Hard constraints (from the user):**
- The **xbar version remains in production** until the SwiftBar one is verified. Do not
  modify `git/xbar-timeontrack`, do not repoint or remove the live plugin symlink, and do
  not migrate, copy, or otherwise touch any real time data.
- Work happens **only inside `git/swiftbar-timeontrack`**, plus brand-new empty/seed data in
  the new SwiftBar data folder. Migration of the real data is a separate, later step the
  user performs themselves.

---

## Current environment (verified)

- SwiftBar 2.1.1 at `/Applications/SwiftBar.app`; prefs bundle id `com.ameba.SwiftBar`.
- Plugin Folder = `~/Library/Application Support/swiftbar/plugins`.
- Live symlink `plugins/TimeOnTrack.1s.rb` → `~/git/xbar-timeontrack/TimeOnTrack.1s.rb`
  (so the running plugin is the **xbar** checkout — leave it alone).
- xbar's own folder `~/Library/Application Support/xbar/plugins` still holds a copy and a
  `TimeOnTrack.1s.rb.vars.json` with `VAR_LANGUAGE_OVERRIDE`.
- Ruby 3.3.1 (rbenv shim) plus Homebrew and system Ruby.

---

## What actually differs (verified)

Mostly compatible. The concrete deltas:

| Area | xbar | SwiftBar | Action |
|---|---|---|---|
| Metadata tags | `<xbar.*>` | parses `<xbar.*>` **and** `<swiftbar.*>`; extra options: `hideAbout`, `hideRunInTerminal`, `hideLastUpdated`, `hideDisablePlugin`, `hideSwiftBar`, `schedule`, `refreshOnOpen`, `collapseOnClose`, `runInBash`, `environment` | keep `xbar.title/version/author/…`; add SwiftBar-only tags where useful |
| Plugin variables | `<xbar.var>string(VAR_X="")…` | accepts **both** `xbar.var` and `swiftbar.var` (same regex) | switch to `swiftbar.var`; values live in SwiftBar's store, not a `*.vars.json` sidecar |
| **`disabled=true`** | supported | **not supported at all** (no `disabled` key in the source) | **remove it** — SwiftBar auto-greys a line whose `hasAction` is false (`href`/`bash`/`stdin`/`refresh` all absent), so emit such lines with no action |
| `shell=` / `param1=` | supported | supported (`params["bash"] ?? params["shell"]`, all `param*` keys collected) | **no change needed** — existing `run_command()` helper works as-is |
| Dark mode | `XBARDarkMode` | `OS_APPEARANCE` (`Light`/`Dark`) + `light,dark` colour pairs | not currently used; use `OS_APPEARANCE` if colour is ever added |
| Plugin folder | fixed `~/Library/Application Support/xbar/plugins` | user-chosen; here `…/swiftbar/plugins`, **symlinks are traversed** | symlink the plugin (as today) |
| Per-plugin dirs | none | `SWIFTBAR_PLUGIN_PATH`, `SWIFTBAR_PLUGIN_DATA_PATH`, `SWIFTBAR_PLUGIN_CACHE_PATH`, `SWIFTBAR_PLUGIN_REFRESH_REASON`, `SWIFTBAR_LAUNCH_TIME` | use `SWIFTBAR_PLUGIN_DATA_PATH` for the data files |
| Bash wrapper | n/a | plugins are wrapped in bash by default (`<swiftbar.runInBash>false</swiftbar.runInBash>` to disable) | document; not needed for a shebanged Ruby script |

### Two live install problems this explains

1. **`disabled=true` is a no-op**, so the currently-greyed "Continue / Archive / Delete"
   entries for the job being tracked are *not* actually disabled in SwiftBar.
2. **`__dir__` resolves to the symlink's directory.** SwiftBar execs
   `…/swiftbar/plugins/TimeOnTrack.1s.rb`, so `$LANG_DIR` resolves to
   `<plugins>/TimeOnTrack/lang` — which doesn't exist. That is why a `lang/` folder (and
   empty `de_DE.json/`, `en_US.json/` folders) were copied into the plugins folder, and why
   those `*.json` files got swept up by SwiftBar as plugins and landed in `DisabledPlugins`.
   Fixing path resolution removes the whole workaround.

---

## Plan

### 1. Path resolution (fixes the symlink bug)

In `TimeOnTrack.1s.rb`, stop using bare `__dir__`:

```ruby
$PLUGIN_DIR = File.dirname(File.realpath(__FILE__))   # repo root, even when symlinked
$DATA_DIR   = ENV["SWIFTBAR_PLUGIN_DATA_PATH"] || File.join($PLUGIN_DIR, "TimeOnTrack")
```

- Bundled assets (`lang/`, icons) read from `$PLUGIN_DIR` → resolved through the symlink.
- Mutable state (`TimeOnTrackData.json`, `TimeOnTrackArchive.json`) goes to `$DATA_DIR`,
  with the repo-local fallback so the script still runs standalone from a checkout.
- Add `require "fileutils"` — `FileUtils` is used at lines 339/355 but only *happens* to be
  loaded as a side effect of `require "tmpdir"`. Make it explicit.

### 2. SwiftBar metadata + variables

- Keep the standard `xbar.title/version/author/author.github/desc/image/dependencies/abouturl`
  header (SwiftBar reads these; they are still the canonical fields). Bump version to `v2.0.0`.
- Update `desc` and `abouturl` to the SwiftBar repo.
- Replace `<xbar.var>…</xbar.var>` with `<swiftbar.var>string(VAR_LANGUAGE_OVERRIDE=): …</swiftbar.var>`.
- Add `<swiftbar.hideLastUpdated>true</swiftbar.hideLastUpdated>` (the 1s interval makes the
  "last updated" row noise) and `<swiftbar.refreshOnOpen>true</swiftbar.refreshOnOpen>`.

### 3. Data files out of git

**Sequencing constraint:** the xbar version stays in production until the SwiftBar one is
verified, so this phase is *preparation only* — no live data is moved or copied anywhere.

- The new plugin reads/writes `$DATA_DIR` = `SWIFTBAR_PLUGIN_DATA_PATH`
  (`~/Library/Application Support/SwiftBar/data/TimeOnTrack/`).
- Add the two data filenames to `.gitignore` and `git rm --cached` them **in
  `git/swiftbar-timeontrack` only** (working-tree copies stay put; the xbar checkout is a
  separate clone and is never touched).
- **Start from empty/seed data.** Create a fresh `TimeOnTrackData.json` (+ empty archive)
  in `$DATA_DIR` with a couple of placeholder jobs, so the SwiftBar build is exercised
  end-to-end without any real data. No legacy-copy-on-first-run helper.
- The real data hand-off is a **deliberate, separate step the user performs later**, after
  the SwiftBar plugin is confirmed working. Document the procedure but do not execute it.
- Because the repo's `TimeOnTrack/*.json` stay untracked-but-present, note in the docs that
  `git checkout` in this repo must not be relied on to restore data until the cutover.

### 4. Moderate cleanup (behaviour-preserving except where listed as a bug)

Reorganise the one file into labelled sections and remove duplication — keeping a single
file (chosen scope), not a module split:

- **BUG** `deleteJob`/`deleteEntry` ignore their `id` argument and read `ARGV[1]` directly
  (lines 250, 255). Make them use the parameter.
- **BUG** `icon("running", …)` on lines 399/414 — `"running"` is not a key in `$ICON`, so it
  emits `templateImage=""`; the "currently tracking" marker never renders. Use `rec`/`rec-alt`
  (already present) or add a real `running` icon.
- **BUG/i18n** `yes_no_prompt` hardcodes German button titles (`"Nein"`, `"Ja"`) regardless
  of language — wrong for EN users. Localize the button labels.
- **BUG/i18n** `generateJournal` hardcodes `lang='de'` and an English literal title instead
  of `t("journal.title")`.
- **i18n** `en_US.json` is missing `prompt.job.daily_summary.title` (add it); drop the unused
  `prompt.job.daily_summary.body`, which exists only in EN and is never read.
- Remove debug leftovers `alert("Errror rename")` (lines 478, 584).
- Collapse the repeated "find job / find entry / scan archive" logic into one pair of lookups
  that builds an id→job index once per run, reused by the ~15 call sites.
- Extract the repeated `| shell=… param1=… terminal=false` construction (already
  `run_command`) and the repeated menu-item line assembly so the dropdown block shrinks.
- Reuse `getJobById(…, include_archived: true)` consistently instead of ad-hoc archive reads.

**Efficiency note (not changing):** the file is named `.1s.rb`, so a Ruby process (plus
`osascript` for `defaults`) is spawned every second. Left as-is for this pass, but flag it in
the docs as the obvious future win (e.g. `.5s`/`.10s` plus `refresh=true` on actions).

### 5. Documentation

- **`CLAUDE.md`** — new. Architecture map (sections of the script, data model, the
  action-dispatch protocol via `ARGV`), the SwiftBar/xbar differences that matter, the
  path/symlink rule, where data lives, and how to test a change without touching real data.
- **`README.md`** — rewrite the install section for SwiftBar (Plugin Folder, symlink,
  `swiftbar://addplugin`), document `swiftbar.var` settings, the new data location, and the
  SwiftBar-only statements.
- **`MIGRATION.md`** — new, short: the compatibility table above, the behaviour changes
  (notably that `disabled=true` was silently ineffective), and the data-move procedure.

### 6. Install/setup steps — deferred, and NOT part of this change

The live symlink currently points at `git/xbar-timeontrack/` and must stay that way while the
xbar version is in production. Therefore, until the user is ready to cut over:

- **Do not** repoint the symlink.
- **Do not** remove the stale `lang/`, `de_DE.json/`, `en_US.json/` folders or their
  `DisabledPlugins` defaults entries.
- **Do not** modify `~/git/xbar-timeontrack` in any way — it is a separate clone actively
  written to by the running plugin.

Instead, test the SwiftBar build with a **second, temporary plugin link** (distinct filename,
e.g. `TimeOnTrack-dev.1s.rb`) pointing at `git/swiftbar-timeontrack/TimeOnTrack.1s.rb`, so
both can coexist. Cutover steps (repoint the link, remove the stale folders, drop the
`DisabledPlugins` entries, move real data) are documented for the user to perform when ready.

---

## Files touched

| File | Change |
|---|---|
| `TimeOnTrack.1s.rb` | main migration + cleanup |
| `TimeOnTrack/lang/en_US.json` | add missing key, drop dead key |
| `TimeOnTrack/lang/de_DE.json` | button-title keys for `yes_no_prompt` |
| `.gitignore` | ignore data + archive JSON |
| `README.md` | SwiftBar install/docs |
| `CLAUDE.md` | new — architecture & conventions |
| `MIGRATION.md` | new — xbar→SwiftBar notes |
| `TimeOnTrack/TimeOnTrackData.json`, `…Archive.json` | `git rm --cached` in this repo only; files left in place |
| `~/Library/Application Support/SwiftBar/data/TimeOnTrack/` | seed data created here (new dir, not the live one) |

---

## Verification (against seed data only — no real data involved)

Real data is never read, copied, or written by any of this. The xbar checkout and its data
are out of scope entirely.

1. `ruby -c TimeOnTrack.1s.rb` — syntax.
2. Run against a **scratch data dir** with seed data, e.g.
   `SWIFTBAR_PLUGIN_DATA_PATH=/tmp/tot-test ruby TimeOnTrack.1s.rb`, and in action mode
   `… ruby TimeOnTrack.1s.rb job:start <seed-uuid>`:
   - plugin mode: inspect the menu on stdout — tracking marker renders, header shows the
     active job, and no `disabled=` survives in the output.
   - action mode: `activeJob`/`activeEntry` change, totals recalculate, file re-saves.
   - exercise archive + daily-summary + new/rename/delete on the seed data.
   - confirm the archive file is created when absent.
3. Assert nothing outside the scratch dir changed: `git status` in `git/swiftbar-timeontrack`
   shows no modified data files, and `git/xbar-timeontrack` is untouched.
4. Run both languages (`VAR_LANGUAGE_OVERRIDE=en_US` / `de_DE`) and confirm no key falls back
   to its raw identifier (specifically the new `prompt.job.daily_summary.title` and the
   localized `yes_no_prompt` buttons).
5. Live smoke test via the **temporary `TimeOnTrack-dev.1s.rb` link** into SwiftBar: menu
   renders, Continue/Pause/New Job work, Journal opens, data lands in `SWIFTBAR_PLUGIN_DATA_PATH`
   — while the production xbar plugin keeps running untouched.
6. Confirm the repo no longer tracks personal data: `git status` shows the two JSON files as
   removed from tracking and `.gitignore` covers them.

---

## Open questions for the user (before implementation)

1. **Real source data for the seeded test.** The plan seeds fresh placeholder jobs. If you'd
   prefer the SwiftBar build exercised against a *copy* of the real data (read-only, into a
   scratch dir, repo untouched), say so — otherwise seed data only.
2. **Version bump.** Proposed `v1.1.0` → `v2.0.0`; adjust if you'd rather keep `1.x`.
3. **Script filename.** Keep `TimeOnTrack.1s.rb`, or change the interval (see the efficiency
   note) at the same time?
