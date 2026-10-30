
# TimeOnTrack

**TimeOnTrack** is a sophisticated time tracker for [SwiftBar](https://github.com/swiftbar/SwiftBar) that allows you to track, pause, and manage multiple projects simultaneously. It provides a convenient way to log time spent on different tasks and review your work history.

- Track multiple projects concurrently
- Start, pause, and stop timers for each project
- Rename, archive, and delete projects and time entries
- View and edit logged time entries
- Generate and view a detailed journal of your tracked time
- Supports localization


![Screenshot of the TimeOnTrack plugin](./screenshot.jpg)


## Installation

1. Install [SwiftBar](https://github.com/swiftbar/SwiftBar#installation) and choose a plugin
   folder when it first launches.
2. Get this repository and link the plugin into that folder:

   ```bash
   git clone https://github.com/rcheetah/xbar-timeontrack.git
   ln -s "$PWD/xbar-timeontrack/TimeOnTrack.1s.rb" \
         ~/Library/Application\ Support/swiftbar/plugins/
   ```

   SwiftBar follows symlinks, so the plugin runs straight from your checkout.

Alternatively, use SwiftBar's URL scheme:

```bash
open "swiftbar://addplugin?src=<url to TimeOnTrack.1s.rb>"
```

The plugin needs Ruby, which ships with macOS.

## Where your data lives

Your tracked time is stored outside the repository, under your Application Support folder:

```
~/Library/Application Support/TimeOnTrack/
├── TimeOnTrackData.json      # active jobs and their entries
└── TimeOnTrackArchive.json   # archived jobs
```

The plugin creates both files automatically — you never need to make them by hand, and you
never need to keep the repository anywhere in particular for them to be found.

## Features

### Track Jobs Individually

Create named jobs that represent different tasks, projects, or activities. Each job operates independently, allowing you to start and stop timers as needed. This enables you to manage multiple client projects or break down your workflow into specific tasks, providing the flexibility to track time as required.

### Seamless Switching Between Jobs

Easily switch between tasks without losing track of time. Pause tracking on one job and start tracking another immediately. You can return to the paused job later and continue tracking from where you left off. This is particularly useful for multitaskers who need to switch contexts frequently.

### Detailed Entry Management

Each job consists of multiple time entries, representing individual tracking sessions. These entries can be edited or deleted as needed. If time was booked on the wrong job or the timer was not paused during a break, the duration of the entry can be adjusted to correct the record. This ensures that your time tracking remains accurate.

Individual entries can also be given a name, which shows up in the job list and in the journal.

### Archiving Jobs to Declutter Your Workspace

Completed or inactive jobs can be archived, keeping the data intact for future reference while decluttering your active job list. Archived jobs are hidden from the main view but remain accessible through the journal, ensuring that all data is preserved.

### Comprehensive Journal Overview

*Show Journal* opens a self-contained page covering every job, active and archived, with
all of its entries. It is a single offline HTML file — nothing is loaded from the network,
and it keeps working if you copy it somewhere else.

- **Two views.** *By time* groups the months, with collapsible jobs and their entries;
  *Table* lists jobs with sortable columns and expands to the entries.
- **Search and filter.** Free-text search covers job names *and* entry names, plus date
  range, year, month, a minimum duration (to hide the very short session fragments), and
  switches for active/archived.
- **Live totals.** A summary line always shows the time in the current selection, which is
  what you want when billing for a client or a period.
- **Export.** The filtered rows can be saved as CSV for a spreadsheet.
- **Charts.** Hours per month and the jobs with the most time, drawn with plain CSS.

The page is written to `~/Library/Application Support/TimeOnTrack/journal.html`, so you can
bookmark it. It shows when it was generated, and the ⟳ button fetches fresh numbers.

> ⚠️ **The in-page reload needs SwiftBar 2.1.2 or newer.** That version is still in beta, and
> the current stable release (2.1.1) does not support the mechanism the button relies on — so
> on 2.1.1 the button does nothing. **"Show Journal" from the menu always regenerates the
> page**, so simply reopen it from there until the update lands.

> 🛠️ **Work-in-progress:** This feature is still in development

### Daily Summary

Selecting *Summary* for a job shows time tracked per day, alongside each day rounded to the
nearest quarter hour and the difference that rounding leaves. This makes it easy to compare
tracked time against a rounded billing figure. The summary dialog also offers to archive the
job directly.

## Localization

By default the plugin follows the language of macOS, falling back to en_US when no
translation is available, and then to the key name itself. You can override it in the plugin
settings.

Language files are stored in the `TimeOnTrack/lang/` directory. You can create your own translation by copying an existing one and translating the strings. Use the correct language key for your language and region (according to RFC 5646). If you do so, please share it with the community so others can benefit from it.

## Developer mode

To run a second copy — for example the plugin from a checkout you are editing, next to a
stable one — turn on **dev mode**. It does two things:

- **Separate data.** Tracked time goes to a `dev/` subdirectory instead of the main one, so
  the two copies never write to the same file.
- **Visible marker.** The menu bar item is prefixed with `DEV ` and tinted amber, and the
  dropdown gains a banner showing which data directory this copy writes to.

There are three ways to switch it on, in order of convenience:

**1. SwiftBar's settings UI.** SwiftBar ▸ *Settings* ▸ *Plugins* ▸ TimeOnTrack ▸
**Plugin Variables** ▸ set `VAR_DEV_MODE` to on. (If that section is empty, see the note
below.)

**2. The vars file**, written next to the plugin:

```bash
# ~/Library/Application Support/swiftbar/plugins/TimeOnTrack.1s.rb.vars.json
{ "VAR_DEV_MODE": "true" }
```

**3. The environment**, for running from a shell — this does not work for the plugin as
launched by SwiftBar, only for your own test runs:

```bash
SWIFTBAR_TIMEONTRACK_DEV=1 ruby TimeOnTrack.1s.rb
```

> **If the Plugin Variables section is empty**, the plugin's metadata is not being read —
> SwiftBar only reads the descriptive tags with the `xbar.` prefix (`<xbar.title>`, and so
> on), not `swiftbar.`. Reload the plugin after editing metadata.

## Migrating from xbar

Earlier versions of this plugin ran under [xbar](https://xbarapp.com). The plugin is now
SwiftBar-only. If you are coming from the xbar version, see [MIGRATION.md](MIGRATION.md) for
what changed and how to move your existing data across.

## Acknowledgments

I used [worktime-tracker](https://xbarapp.com/docs/plugins/Time/worktime-tracker.1s.rb.html) by [@hSATAC](https://xbarapp.com/docs/contributors/hSATAC.html) or quite some time, and I drew some inspiration from it. However, the limitation to a single project was not suitable for me in the long run, so I wrote a more sophisticated plugin for my daily use.

## License

This project is licensed under the MIT License.

## Contributing

Contributions are welcome! Feel free to submit a pull request or open an issue for any improvements or bug fixes.
