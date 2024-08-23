#!/usr/bin/env ruby

# Metadata for xBar
#  <xbar.title>TimeOnTrack</xbar.title>
#  <xbar.version>v1.0.0</xbar.version>
#  <xbar.author>Roman Gebath</xbar.author>
#  <xbar.author.github>rcheetah</xbar.author.github>
#  <xbar.desc>A sophisticated time tracker, which allows to track and pause mulitple projects at once.</xbar.desc>
#  <xbar.dependencies>ruby</xbar.dependencies>

# Variables for preferences in the app:
#  <xbar.var>string(VAR_LANGUAGE_OVERRIDE=): Override the system language using a language code (e.g. en_US, de_DE)</xbar.var>


require 'json'
require 'securerandom'
require 'time'
require 'tmpdir'


$EXT_DIR = "./TimeOnTrack/"
$SAVEFILE = "#{$EXT_DIR}TimeOnTrackData.json"
$LANG_DIR = "#{$EXT_DIR}lang/"
$EMPTY_DATA = {
  "activeJob" => nil,
  "activeEntry" => nil,
  "jobs" => []
}
MATCH_DATE_DURATION = /(\d{4}-\d+-\d+ \d+:\d+) \| (\d+:\d+:\d+)/
$LANG_DATA = nil
$LANG = nil

$data = nil



# Prompts

def prompt(text, title: "", input: "")
  script = <<~SCRIPT
    tell application "System Events"
      text returned of (display dialog "#{text}" with title "#{title}" default answer "#{input}")
    end tell
  SCRIPT
  result = `osascript -e '#{script}' 2>/dev/null`
  return nil if $?.exitstatus != 0 # Return nil if the user canceled
  return result.strip
end

def yes_no_prompt(text, title: "")
  script = <<~SCRIPT
    tell application "System Events"
      display dialog "#{text}" with title "#{title}" buttons {"Nein", "Ja"} default button "Ja"
      if button returned of result is "Ja" then
        return true
      else
        return false
      end if
    end tell
  SCRIPT
  result = `osascript -e '#{script}'`.strip
  return result == "true"
end

def alert(text, title: "")
  script = <<~SCRIPT
    tell application "System Events"
      display dialog "#{text}" with title "#{title}" buttons {"OK"} default button "OK"
    end tell
  SCRIPT
  `osascript -e '#{script}'`
end


# Helpers

def load_language_file
  # If script runs in action mode, load language from data file, as the environment variable is not passed in action mode.
  if(ARGV.length > 0)
    $LANG = $data["language"]
  else
    # Script runs in regular mode. Get language from system or preferences.
    $LANG = `defaults read -g AppleLocale`.strip
    if (ENV["VAR_LANGUAGE_OVERRIDE"])
      $LANG = ENV["VAR_LANGUAGE_OVERRIDE"] unless ENV["VAR_LANGUAGE_OVERRIDE"].strip.empty?
    end
    $LANG = "en_US" if $LANG.strip.empty?
  end

  # load language file
  lang_file_path = File.join($LANG_DIR, "#{$LANG}.json")
  if File.exist?(lang_file_path)
    return JSON.parse(File.read(lang_file_path))
  else
    base_language = $LANG.split('_').first
    base_lang_file = Dir.glob(File.join($LANG_DIR, "#{base_language}*.json")).first
    return base_lang_file ? JSON.parse(File.read(base_lang_file)) : {}
  end
end

def t(key, placeholders = {})
  translation = $LANG_DATA[key] || key
  placeholders.each do |placeholder, value|
    translation.gsub!("%{#{placeholder}}", value.to_s)
  end
  return translation
end

def run_command(command, parameters = [])
  param_strings = []
  parameters.each_with_index { |param, index|
    param_string = "param#{index+2}="
    param_string += "\"#{param.gsub('"', '\\"')}\""
    param_strings << param_string
  }
  cmd_string = "bash=\"#{__FILE__}\" param1=#{command} #{param_strings.join(" ")} terminal=false"
  return cmd_string
end

def format_duration(timestamp, enforce_hours=false)
  total_hours = timestamp / 3600
  minutes = (timestamp % 3600) / 60
  seconds = timestamp % 60
  string = ""
  if enforce_hours
    string += "#{total_hours}:" if total_hours > 0
  else
    string += "#{total_hours}:"
  end
  string += "#{minutes.to_s.rjust(2,'0')}"
  string += ":#{seconds.to_s.rjust(2,'0')}"
  return string
end

# Getters

def getJobById(id)
  begin
    return $data["jobs"].find { |job| job["id"] == id }
  rescue => error
    alert("#{t("error.getJobById", {id: id})}: \n#{error.message}\n#{error.backtrace.join("\n")}")
    return nil
  end
end

def getActiveJob()
  return nil if $data["activeJob"] == nil
  return getJobById($data["activeJob"])
end

def getEntryById(id)
  begin
    $data["jobs"].each do |job|
      entry = job["entries"].find { |entry| entry["id"] == id }
      return entry if entry
    end
    return nil
  rescue => error
    alert("#{t("error.getEntryById")} \n#{error.message}\n#{error.backtrace.join("\n")}")
    return nil
  end
end

# Main Functions

def createNewJob(name)
  job_id = SecureRandom.uuid
  new_job = {
    "id" => job_id,
    "name" => name,
    "archived" => false,
    "entries" => [],
    "total" => 0
  }
  $data["jobs"] << new_job
  return job_id
end

def startNewEntry(job)
  job = getJobById(job)
  entry_id = SecureRandom.uuid
  new_entry = {
    "id" => entry_id,
    "start" => Time.now.to_i,
    "end" => Time.now.to_i,
    "total" => 0
  }
  job["entries"] << new_entry
  return entry_id
end

def deleteJob(id)
  $data["jobs"] = $data["jobs"].reject { |job| job["id"] == ARGV[1] }
end

def deleteEntry(id)
  $data["jobs"].each do |job|
    job["entries"] = job["entries"].reject { |entry| entry["id"] == ARGV[1] }
  end
end

def generateJournalJobDom(job)
  tmpl_job = "<div class='job'><h3>%%JOB_NAME%%</h3><p><strong>#{t("journal.job.total")}: %%TIME_TOTAL%%</strong></p><p class='timeframe'>%%TIME_FRAME%%</p><table><thead><tr><th>#{t("journal.job.start")}</th><th>#{t("journal.job.end")}</th><th>#{t("journal.job.duration")}</th></tr></thead><tbody>%%ENTRIES%%</tbody></table></div>"
  tmpl_job.gsub!("%%JOB_NAME%%", job["name"])
  tmpl_job.gsub!("%%TIME_TOTAL%%", format_duration(job["total"]))

  unless job["entries"].empty?
    earliest = job["entries"].min_by { |entry| entry["start"] }
    latest = job["entries"].max_by { |entry| entry["end"] }
    timeframe = Time.at(earliest["start"]).strftime("%d.%m.%Y") + " #{t("journal.job.duration.to")} " + Time.at(latest["end"]).strftime("%d.%m.%Y")
    tmpl_job.gsub!("%%TIME_FRAME%%", timeframe)

    tmpl_entry_row = '<tr><td>%%START%%</td><td>%%END%%</td><td>%%DURATION%%</td></tr>'
    rows = []
    job["entries"].each do |entry|
      row = tmpl_entry_row
      start = Time.at(entry["start"]).strftime("%Y-%m-%d %H:%M:%S")
      ende = Time.at(entry["end"]).strftime("%Y-%m-%d %H:%M:%S")
      duration = format_duration(entry["total"])
      row.gsub!("%%START%%", start)
      row.gsub!("%%END%%", ende)
      row.gsub!("%%DURATION%%", duration)
      rows << row
    end
    tmpl_job.gsub!("%%ENTRIES%%", rows.join(""))
  else
    tmpl_job.gsub!("%%TIME_FRAME%%", "n/a")
    tmpl_job.gsub!("%%ENTRIES%%", t("journal.job.entries.emptystate"))
  end
  return tmpl_job
end

def generateJournal()

  tmpl_journal_dom = "<!DOCTYPE html><html lang='de'><head><meta charset='UTF-8'><meta name='viewport' content='width=device-width, initial-scale=1.0'><title>#{t("journal.title")}</title><style>body{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Open Sans', 'Helvetica Neue', sans-serif;} #main{ max-width: 1200px; margin: 0 auto;} .jobs{flex-direction:column;display:flex;gap:.5rem} .job { background-color: lightgrey; padding: 1rem; border-radius: 0.25rem; margin: 0.5rem;}</style></head><body><div id='main'><h1>📖 TimeOnTrack Journal</h1><h2>#{t("journal.jobs.active")}</h2><div id='jobs-active' class='jobs'>%%JOBS_ACTIVE%% </div><h2>#{t("journal.jobs.archived")}</h2><div id='jobs-archived' class='jobs'>%%JOBS_ARCHIVED%% </div></div></body></html>"
  active = $data["jobs"].select { |job| !job["archived"] }
  archived = $data["jobs"].select { |job| job["archived"] }

  active_doms = []
  active.each do |job|
    dom = generateJournalJobDom(job)
    active_doms << dom
  end
  tmpl_journal_dom.gsub!("%%JOBS_ACTIVE%%", active_doms.join(""))

  archived_doms = []
  archived.each do |job|
    dom = generateJournalJobDom(job)
    archived_doms << dom
  end
  tmpl_journal_dom.gsub!("%%JOBS_ARCHIVED%%", archived_doms.join(""))

  filepath = Dir.tmpdir + "/TimeOnTrackJournal-#{Time.now.strftime("%Y-%m-%d-%H-%M-%S")}.html"
  File.write(filepath, tmpl_journal_dom)

  return filepath

end

def loadJSON()
  if File.exist?($SAVEFILE)
    $data = JSON.parse(File.read($SAVEFILE))
    # puts "Loaded data: \n#{$data}"
  else
    $data = $EMPTY_DATA;
  end

  # Recalculate Totals and save job id with entry
  $data["jobs"].each do |job|
    total_time = job["entries"].reduce(0) { |sum, entry| sum + (entry["end"] - entry["start"]) }
    job["total"] = total_time
    job["entries"].each { |entry|
      entry["total"] = entry["end"] - entry["start"]
      entry["job_id"] = "#{job["id"]}"
    }
  end
end

def saveJSON()
  FileUtils.mkpath(File.dirname($SAVEFILE))
  File.write($SAVEFILE, JSON.pretty_generate($data))
end

def updateRunningTimer()
  return unless $data["activeEntry"]
  entry = getEntryById($data["activeEntry"])
  entry["end"] = Time.now.to_i
end

def buildMenu()
  activeJob = getActiveJob()

  # Menubar
  if $data["activeJob"].nil?
    puts t("plugin_title_bar")
  else
    if $data["activeEntry"]
      puts "🟢 #{format_duration(activeJob["total"], true)}"
    else
      puts "🟥 #{format_duration(activeJob["total"], true)} | color=red"
    end
  end

  # Divider for Dropdown
  puts "---"

  # Dropdown

  puts "⏯️ #{t("job.continue", { jobname: activeJob["name"] })} | #{run_command("job:start", [activeJob["id"]])}" if $data["activeJob"] && !$data["activeEntry"]
  puts "⏸️ #{t("job.pause", { jobname: activeJob["name"] })} | #{run_command("job:pause")}" if $data["activeEntry"]
  puts "⏹️ #{t("job.stop", { jobname: activeJob["name"] })} | #{run_command("job:stop")}" if $data["activeJob"]
  puts "➕ #{t("job.new")} | #{run_command("job:new")}" unless $data["activeEntry"]

  # Visual Divider
  puts "---"

  $data["jobs"].each do |job|
    next if job["archived"]
    if $data["activeEntry"]
      job_is_tracking = getEntryById($data["activeEntry"])["job_id"] == job["id"] ? true : false
    else
      job_is_tracking = false
    end
    puts "#{job_is_tracking ? "🔴 " : ""}#{job["name"]} | length=30"
    puts "-- 🕘 #{format_duration(job["total"])}"
    puts "-----"
    puts "-- ⏯️ #{t("job.menu.continue")} | #{run_command("job:start", [job["id"]])} | refresh=true #{"| disabled=true" if job_is_tracking}"
    puts "-- ✏️ #{t("job.menu.rename")} | #{run_command("job:rename", [job["id"]])} | refresh=true"
    puts "-- 🗄️ #{t("job.menu.archive")} | #{run_command("job:archive", [job["id"]])} | refresh=true #{"| disabled=true" if job_is_tracking}"
    puts "-- 🗑️ #{t("job.menu.delete")} | #{run_command("job:delete", [job["id"]])} | refresh=true #{"| disabled=true" if job_is_tracking}"
    if(job["entries"].length > 0)
      puts "-----"
      puts "-- #{t("job.menu.entries")}"
      job["entries"].each { |entry|
        entry_is_tracking = ( $data["activeEntry"] == entry["id"] )
        puts "-- #{entry_is_tracking ? "🔴 " : ""}#{format_duration( entry["total"])} (#{Time.at(entry["start"]).strftime("%Y-%m-%d %H:%M")})"
        unless entry_is_tracking
          puts "---- ✏️ #{t("entry.rename")} | #{run_command("entry:edit", [entry["id"]])} | refresh=true"
          puts "---- 🗑️ #{t("entry.delete")} | #{run_command("entry:delete", [entry["id"]])} | refresh=true"
        end
      }
    else
      puts "-- #{t("entry.emptystate")}"
    end
  end

  # Visual Divider
  puts "---"

  puts "📖 #{t("journal.show")} | #{run_command("journal:open")}"
  puts "📝 #{t("savefile.edit")} | #{run_command("savefile:edit")} | alternate=true"

end


def actionHandler()
  return if ARGV.empty?

  case ARGV[0]

  when "job:pause"
    updateRunningTimer()
    $data["activeEntry"] = nil

  when "job:start"
    begin
      new_entry_id = startNewEntry(ARGV[1])
      $data["activeJob"] = ARGV[1]
      $data["activeEntry"] = new_entry_id
    rescue => error
      alert("#{t("error.job:pause")} \n#{error.message}\n#{error.backtrace.join("\n")}")
    end

  when "job:stop"
    updateRunningTimer()
    $data["activeJob"] = nil
    $data["activeEntry"] = nil

  when "job:new"
    begin
      job_name = prompt(t("prompt.job.name"), input: t("job.unnamed"))
      exit if job_name.nil? # user canceled the dialog
      new_job_id = createNewJob(job_name)
      $data["activeJob"] = new_job_id
      new_entry_id = startNewEntry(new_job_id)
      $data["activeEntry"] = new_entry_id
    rescue => error
      alert("#{t("error.job:new")} \n#{error.message}\n#{error.backtrace.join("\n")}")
    end

  when "job:rename"
    begin
      job = getJobById(ARGV[1])
      new_job_name = prompt(t("prompt.job.rename", {jobname: job["name"]}), input: "#{job["name"]}")
      exit if new_job_name.nil? # user canceled the dialog
      new_job_name = t("job.unnamed") if new_job_name.strip.empty?
      job["name"] = new_job_name
    rescue => error
      alert("Errror rename")
      alert("#{t("error.job:rename")} \n#{error.message}\n#{error.backtrace.join("\n")}")
    end

  when "job:archive"
    begin
      job = getJobById(ARGV[1])
      job["archived"] = true
      active_job = getActiveJob();
      active_entry = getEntryById($data["activeEntry"]) if $data["activeEntry"]
      $data["activeJob"] = nil if active_job && job["id"] == active_job["id"]
      $data["activeEntry"] = nil if active_entry && job["id"] == active_entry["job_id"]

    rescue => error
      alert("#{t("error.job:archive")} \n#{error.message}\n#{error.backtrace.join("\n")}")
    end

  when "job:delete"
    begin
      job = getJobById(ARGV[1])
      confirmed = yes_no_prompt(t("prompt.job.delete.message", {jobname: job["name"]}), title: t("prompt.job.delete.title"))
      return unless confirmed
      active_job = getActiveJob();
      active_entry = getEntryById($data["activeEntry"]) if $data["activeEntry"]
      $data["activeJob"] = nil if active_job && job["id"] == active_job["id"]
      $data["activeEntry"] = nil if active_entry && job["id"] == active_entry["job_id"]
      deleteJob(ARGV[1]) if confirmed

    rescue => error
      alert("#{t("error.job:delete")} \n#{error.message}\n#{error.backtrace.join("\n")}")
    end

  when "entry:delete"
    begin
      entry = getEntryById(ARGV[1])
      confirmed = yes_no_prompt(t("prompt.entry.delete.message", {duration: format_duration( entry["total"]), jobname: getJobById(entry["job_id"])["name"]}), title: t("prompt.entry.delete.title"))
      return unless confirmed
      deleteEntry(ARGV[1])
    rescue => error
      alert("#{t("error.entry:delete")} \n#{error.message}\n#{error.backtrace.join("\n")}")
    end

  when "entry:edit"
    begin
      entry = getEntryById(ARGV[1])
      old_data = Time.at(entry["start"]).strftime("%Y-%m-%d %H:%M")
      old_data += " | "
      old_data += format_duration(entry["total"])
      new_data = prompt(t("prompt.entry.edit.message"), title: t("prompt.entry.edit.title"), input: old_data )
      return if new_data.nil? # user canceled the dialog
      if match = new_data.match(MATCH_DATE_DURATION)
        time_start = Time.strptime(match[1], "%Y-%m-%d %H:%M").to_i
        duration = match[2]
        hours, minutes, seconds = duration.split(":").map(&:to_i)
        total_seconds = hours * 3600 + minutes * 60 + seconds
        time_end = time_start + total_seconds
        entry["start"] = time_start
        entry["end"] = time_end
        entry["total"] = time_end - time_start
      else
        alert(t("prompt.entry.edit.formaterror.message"), title: t("prompt.entry.edit.formaterror.title"))
      end
    rescue => error
      alert("#{t("error.entry:edit")} \n#{error.message}\n#{error.backtrace.join("\n")}")
    end

  when "journal:open"
    file = generateJournal()
    `open #{file}`
    begin
    rescue => error
      alert("#{t("error.journal:open")} \n#{error.message}\n#{error.backtrace.join("\n")}")
    end

  when "savefile:edit"
    confirmed = yes_no_prompt(t("prompt.savefile.edit.message"), title: t("prompt.savefile.edit.title"))
    `open #{$SAVEFILE}` if confirmed
    begin
    rescue => error
      alert("#{t("error.savefile:edit")} \n#{error.message}\n#{error.backtrace.join("\n")}")
    end

  else
    alert("#{t("error.actionHandler.action_unknown")} " + ARGV[0])
  end


  saveJSON()
  exit()

end



def _main()

  # Load data
  loadJSON()
  $LANG_DATA = load_language_file()

  # Action Handler
  # will handle actions if arguments are passed to the script
  # it will automatically exit the script afterwards to create false refresh
  actionHandler()

  # only set language if script is not run in action Handler mode (would exit before this line)
  $data["language"] = $LANG

  # Main Loop
  updateRunningTimer()
  buildMenu()
  saveJSON()
end
_main()