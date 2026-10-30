#!/usr/bin/env ruby
# frozen_string_literal: true

# Generates throwaway seed data for developing and testing the plugin.
#
# It writes TimeOnTrackData.json / TimeOnTrackArchive.json into a target directory
# and NEVER touches real tracker data. Point it at a scratch directory, or let it
# default to the data directory SwiftBar assigns to the dev plugin file:
#
#   ruby bin/seed-data.rb                       # -> <repo>/tmp/seed-data
#   ruby bin/seed-data.rb /tmp/tot-test          # explicit directory
#
# To exercise the plugin against it:
#
#   SWIFTBAR_PLUGIN_DATA_PATH=/tmp/tot-test ruby TimeOnTrack.1s.rb

require "json"
require "securerandom"
require "fileutils"

def entry(start_ts, duration_seconds, name: nil)
  e = {
    "id" => SecureRandom.uuid,
    "start" => start_ts,
    "end" => start_ts + duration_seconds,
    "total" => duration_seconds,
  }
  e["name"] = name if name
  e
end

def job(name, entries, archived: false)
  {
    "id" => SecureRandom.uuid,
    "name" => name,
    "archived" => archived,
    "entries" => entries,
    "total" => entries.sum { |e| e["total"] },
  }
end

now = Time.now.to_i
day = 86_400

# A running job: its last entry ends "now" and is referenced as the active entry.
running_first = entry(now - 5_400, 1_800)
running_open  = entry(now - 902, 902)
running = job("Acme Redesign", [running_first, running_open])

jobs = [
  running,

  # Spans several days -> exercises the journal timeframe line.
  job("Multi-day Audit", [
    entry(now - (9 * day), 3_600),
    entry(now - (7 * day), 2_700),
    entry(now - (2 * day), 4_200),
  ]),

  # Includes a sub-minute entry -> exercises format_duration and the
  # 15-minute rounding used by the daily summary.
  job("Support Triage", [
    entry(now - (3 * day), 45, name: "quick fix"),
    entry(now - (3 * day) + 600, 5_400),
  ]),

  # No entries yet -> exercises the empty state.
  job("Someday Maybe", []),
]

data = {
  "language" => "en_US",
  "activeJob" => running["id"],
  "activeEntry" => running_open["id"],
  "jobs" => jobs,
}

target = ARGV[0] || File.join(File.dirname(File.realpath(__FILE__)), "..", "tmp", "seed-data")
FileUtils.mkpath(target)

savefile = File.join(target, "TimeOnTrackData.json")
archivefile = File.join(target, "TimeOnTrackArchive.json")

File.write(savefile, JSON.pretty_generate(data))
File.write(archivefile, JSON.pretty_generate({ "jobs" => [] }))

puts "Seed data written to #{File.expand_path(target)}"
puts "  #{File.basename(savefile)}  (#{jobs.size} jobs, #{jobs.sum { |j| j["entries"].size }} entries)"
puts "  #{File.basename(archivefile)}  (empty)"
puts
puts "Run the plugin against it with:"
puts "  SWIFTBAR_PLUGIN_DATA_PATH=#{File.expand_path(target)} ruby TimeOnTrack.1s.rb"
