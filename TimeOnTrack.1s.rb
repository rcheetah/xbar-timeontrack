#!/usr/bin/env ruby

# Metadata for xBar
#  <xbar.title>TimeOnTrack</xbar.title>
#  <xbar.version>v1.1.0</xbar.version>
#  <xbar.author>Roman Gebath</xbar.author>
#  <xbar.author.github>rcheetah</xbar.author.github>
#  <xbar.desc>A sophisticated time tracker, which allows to track and pause mulitple projects at once.</xbar.desc>
#  <xbar.image>https://github.com/rcheetah/xbar-timeontrack/blob/ea0f22ad093ec8ed3eabca3a774f78f241752f54/screenshot.jpg</xbar.image>
#  <xbar.dependencies>ruby</xbar.dependencies>
#  <xbar.abouturl>https://github.com/rcheetah/xbar-timeontrack/</xbar.abouturl>

# Variables for preferences in the app:
#  <xbar.var>string(VAR_LANGUAGE_OVERRIDE=): Override the system language using a language code (e.g. en_US, de_DE)</xbar.var>


require 'json'
require 'securerandom'
require 'time'
require 'tmpdir'


$ICON = {
  "logo"    => "PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPHN2ZyBpZD0iRWJlbmVfMSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIiB2aWV3Qm94PSIwIDAgMTggMTgiPgogIDxkZWZzPgogICAgPHN0eWxlPgogICAgICAuY2xzLTEgewogICAgICAgIGZpbGw6ICNmZmY7CiAgICAgICAgc3Ryb2tlOiAjMDAwOwogICAgICAgIHN0cm9rZS1taXRlcmxpbWl0OiAxMDsKICAgICAgICBzdHJva2Utd2lkdGg6IDJweDsKICAgICAgfQogICAgPC9zdHlsZT4KICA8L2RlZnM+CiAgPHBhdGggZD0iTTksNWMzLjAzLDAsNS41LDIuNDcsNS41LDUuNXMtMi40Nyw1LjUtNS41LDUuNS01LjUtMi40Ny01LjUtNS41LDIuNDctNS41LDUuNS01LjVNOSwzYy00LjE0LDAtNy41LDMuMzYtNy41LDcuNXMzLjM2LDcuNSw3LjUsNy41LDcuNS0zLjM2LDcuNS03LjUtMy4zNi03LjUtNy41LTcuNWgwWiIvPgogIDxsaW5lIGNsYXNzPSJjbHMtMSIgeDE9IjUuNSIgeTE9IjEiIHgyPSIxMi41IiB5Mj0iMSIvPgogIDxsaW5lIGNsYXNzPSJjbHMtMSIgeDE9IjkiIHkxPSIxLjI4IiB4Mj0iOSIgeTI9IjQiLz4KICA8Zz4KICAgIDxsaW5lIGNsYXNzPSJjbHMtMSIgeDE9IjUuNSIgeTE9IjEwIiB4Mj0iMTIuNSIgeTI9IjEwIi8+CiAgICA8bGluZSBjbGFzcz0iY2xzLTEiIHgxPSI5IiB5MT0iMTAuMjgiIHgyPSI5IiB5Mj0iMTMiLz4KICA8L2c+Cjwvc3ZnPg==",
  "new"     => "PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPHN2ZyBpZD0iRWJlbmVfMSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIiB2aWV3Qm94PSIwIDAgMTggMTgiPgogIDxyZWN0IHg9IjciIHk9IjIiIHdpZHRoPSI0IiBoZWlnaHQ9IjE0IiB0cmFuc2Zvcm09InRyYW5zbGF0ZSgxOCkgcm90YXRlKDkwKSIvPgogIDxyZWN0IHg9IjciIHk9IjIiIHdpZHRoPSI0IiBoZWlnaHQ9IjE0Ii8+Cjwvc3ZnPg==",
  "journal" => "PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPHN2ZyBpZD0iRWJlbmVfMSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIiB2aWV3Qm94PSIwIDAgMTggMTgiPgogIDxkZWZzPgogICAgPHN0eWxlPgogICAgICAuY2xzLTEgewogICAgICAgIGZpbGw6IG5vbmU7CiAgICAgIH0KCiAgICAgIC5jbHMtMSwgLmNscy0yIHsKICAgICAgICBzdHJva2U6ICMwMDA7CiAgICAgICAgc3Ryb2tlLW1pdGVybGltaXQ6IDEwOwogICAgICAgIHN0cm9rZS13aWR0aDogMS41cHg7CiAgICAgIH0KCiAgICAgIC5jbHMtMiB7CiAgICAgICAgZmlsbDogI2ZmZjsKICAgICAgfQogICAgPC9zdHlsZT4KICA8L2RlZnM+CiAgPHJlY3QgY2xhc3M9ImNscy0xIiB4PSI1Ljc1IiB5PSIzIiB3aWR0aD0iOS41IiBoZWlnaHQ9IjEyLjUiLz4KICA8cGF0aCBjbGFzcz0iY2xzLTEiIGQ9Ik01Ljc1LDN2MTIuNWgtMS41Yy0uODMsMC0xLjUtLjY3LTEuNS0xLjVWM2MwLS44My42Ny0xLjUsMS41LTEuNXMxLjUuNjcsMS41LDEuNVoiLz4KICA8bGluZSBjbGFzcz0iY2xzLTIiIHgxPSI4IiB5MT0iNiIgeDI9IjEzIiB5Mj0iNiIvPgogIDxsaW5lIGNsYXNzPSJjbHMtMiIgeDE9IjgiIHkxPSI5IiB4Mj0iMTMiIHkyPSI5Ii8+CiAgPGxpbmUgY2xhc3M9ImNscy0yIiB4MT0iOCIgeTE9IjEyIiB4Mj0iMTMiIHkyPSIxMiIvPgo8L3N2Zz4=",
  "archive" => "PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPHN2ZyBpZD0iRWJlbmVfMSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIiB2aWV3Qm94PSIwIDAgMTggMTgiPgogIDxkZWZzPgogICAgPHN0eWxlPgogICAgICAuY2xzLTEgewogICAgICAgIGZpbGw6IG5vbmU7CiAgICAgICAgc3Ryb2tlLXdpZHRoOiAxLjVweDsKICAgICAgfQoKICAgICAgLmNscy0xLCAuY2xzLTIgewogICAgICAgIHN0cm9rZTogIzAwMDsKICAgICAgICBzdHJva2UtbWl0ZXJsaW1pdDogMTA7CiAgICAgIH0KICAgIDwvc3R5bGU+CiAgPC9kZWZzPgogIDxwb2x5bGluZSBjbGFzcz0iY2xzLTEiIHBvaW50cz0iMTQuNzUgNC41IDE0Ljc1IC43NSAxMC4yNSAuNzUgOC4zMSAyLjc1IDMuMjUgMi43NSAzLjI1IDYuNSIvPgogIDxwb2x5bGluZSBjbGFzcz0iY2xzLTEiIHBvaW50cz0iMTUuMjUgMTAuNSAxNS4yNSA0LjI1IDExLjI1IDQuMjUgOS4yNSA2LjI1IDIuNzUgNi4yNSAyLjc1IDkuNSIvPgogIDxwYXRoIGNsYXNzPSJjbHMtMiIgZD0iTTEzLjUsOC41bC0xLDEuNWgtN2wtMS0xLjVoLTIuNXY3aDE0di03aC0yLjVaTTEzLDE0LjVINXYtMy41aDh2My41WiIvPgo8L3N2Zz4=",
  "delete"  => "PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPHN2ZyBpZD0iRWJlbmVfMSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIiB2aWV3Qm94PSIwIDAgMTggMTgiPgogIDxkZWZzPgogICAgPHN0eWxlPgogICAgICAuY2xzLTEsIC5jbHMtMiB7CiAgICAgICAgc3Ryb2tlLXdpZHRoOiAxLjVweDsKICAgICAgfQoKICAgICAgLmNscy0xLCAuY2xzLTIsIC5jbHMtMyB7CiAgICAgICAgc3Ryb2tlOiAjMDAwOwogICAgICAgIHN0cm9rZS1taXRlcmxpbWl0OiAxMDsKICAgICAgfQoKICAgICAgLmNscy0xLCAuY2xzLTMgewogICAgICAgIGZpbGw6IG5vbmU7CiAgICAgIH0KCiAgICAgIC5jbHMtMiB7CiAgICAgICAgZmlsbDogI2ZmZjsKICAgICAgfQoKICAgICAgLmNscy0zIHsKICAgICAgICBzdHJva2Utd2lkdGg6IDJweDsKICAgICAgfQogICAgPC9zdHlsZT4KICA8L2RlZnM+CiAgPHBvbHlnb24gY2xhc3M9ImNscy0zIiBwb2ludHM9IjE0Ljc1IDMgMy41IDMgNC40OCAxNiAxMy43NyAxNiAxNC43NSAzIi8+CiAgPHJlY3QgY2xhc3M9ImNscy0yIiB4PSIyLjI1IiB5PSIyLjc1IiB3aWR0aD0iMTMuNSIgaGVpZ2h0PSIxIi8+CiAgPHJlY3QgY2xhc3M9ImNscy0yIiB4PSI3LjI1IiB5PSIxLjc1IiB3aWR0aD0iMy41IiBoZWlnaHQ9IjEiLz4KICA8cG9seWxpbmUgY2xhc3M9ImNscy0xIiBwb2ludHM9IjcgNi41IDcgOCAxMSA4IDExIDYuNSIvPgo8L3N2Zz4==",
  "file"    => "PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPHN2ZyBpZD0iRWJlbmVfMSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIiB2aWV3Qm94PSIwIDAgMTggMTgiPgogIDxkZWZzPgogICAgPHN0eWxlPgogICAgICAuY2xzLTEgewogICAgICAgIGZpbGw6ICNmZmY7CiAgICAgICAgc3Ryb2tlLXdpZHRoOiAxLjVweDsKICAgICAgfQoKICAgICAgLmNscy0xLCAuY2xzLTIgewogICAgICAgIHN0cm9rZTogIzAwMDsKICAgICAgICBzdHJva2UtbWl0ZXJsaW1pdDogMTA7CiAgICAgIH0KCiAgICAgIC5jbHMtMiB7CiAgICAgICAgZmlsbDogbm9uZTsKICAgICAgICBzdHJva2Utd2lkdGg6IDJweDsKICAgICAgfQogICAgPC9zdHlsZT4KICA8L2RlZnM+CiAgPHBvbHlnb24gY2xhc3M9ImNscy0yIiBwb2ludHM9IjE0LjUgNi41IDE0LjUgMTYgMy41IDE2IDMuNSAyIDEwIDIgMTQuNSA2LjUiLz4KICA8cG9seWxpbmUgY2xhc3M9ImNscy0yIiBwb2ludHM9IjkuNSAyLjAyIDkuNSA2Ljk5IDE0LjUgNi45OSIvPgogIDxsaW5lIGNsYXNzPSJjbHMtMSIgeDE9IjYiIHkxPSIxMi43NSIgeDI9IjEyIiB5Mj0iMTIuNzUiLz4KICA8bGluZSBjbGFzcz0iY2xzLTEiIHgxPSI2IiB5MT0iMTAuMjUiIHgyPSIxMiIgeTI9IjEwLjI1Ii8+Cjwvc3ZnPg==",
  "pause"   => "PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPHN2ZyBpZD0iRWJlbmVfMSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIiB2aWV3Qm94PSIwIDAgMTggMTgiPgogIDxyZWN0IHg9IjMiIHk9IjMiIHdpZHRoPSI0LjUiIGhlaWdodD0iMTIiLz4KICA8cmVjdCB4PSIxMC41IiB5PSIzIiB3aWR0aD0iNC41IiBoZWlnaHQ9IjEyIi8+Cjwvc3ZnPg==",
  "play"    => "PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPHN2ZyBpZD0iRWJlbmVfMSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIiB2aWV3Qm94PSIwIDAgMTggMTgiPgogIDxwb2x5Z29uIHBvaW50cz0iMTQuMzMgOSA0LjMzIDIuMzMgNC4zMyAxNS42NyAxNC4zMyA5Ii8+Cjwvc3ZnPg==",
  "edit"    => "PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPHN2ZyBpZD0iRWJlbmVfMSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIiB2aWV3Qm94PSIwIDAgMTggMTgiPgogIDxwb2x5Z29uIHBvaW50cz0iMS4yMiAxNi43OCA2LjUzIDE1LjcyIDIuMjggMTEuNDcgMS4yMiAxNi43OCIvPgogIDxyZWN0IHg9IjUuODIiIHk9IjMuOTMiIHdpZHRoPSI2IiBoZWlnaHQ9IjEwLjUiIHRyYW5zZm9ybT0idHJhbnNsYXRlKDkuMDcgLTMuNTUpIHJvdGF0ZSg0NSkiLz4KICA8cmVjdCB4PSIxMC45NSIgeT0iMy4wNSIgd2lkdGg9IjYiIGhlaWdodD0iMiIgdHJhbnNmb3JtPSJ0cmFuc2xhdGUoNi45NSAtOC42OCkgcm90YXRlKDQ1KSIvPgo8L3N2Zz4==",
  "rename"  => "PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPHN2ZyBpZD0iRWJlbmVfMSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIiB2aWV3Qm94PSIwIDAgMTggMTgiPgogIDxwYXRoIGQ9Ik0xNywxM1Y1aC01di0yaDJWMWgtNnYyaDJ2MkgxdjhoOXYyaC0ydjJoNnYtMmgtMnYtMmg1Wk0xNSw3djRoLTN2LTRoM1pNMywxMXYtNGg3djRIM1oiLz4KPC9zdmc+",
  "stop"    => "PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPHN2ZyBpZD0iRWJlbmVfMSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIiB2aWV3Qm94PSIwIDAgMTggMTgiPgogIDxyZWN0IHg9IjMuNSIgeT0iMy41IiB3aWR0aD0iMTEiIGhlaWdodD0iMTEiLz4KPC9zdmc+",
  "time"    => "PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPHN2ZyBpZD0iRWJlbmVfMSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIiB2aWV3Qm94PSIwIDAgMTggMTgiPgogIDxkZWZzPgogICAgPHN0eWxlPgogICAgICAuY2xzLTEgewogICAgICAgIGZpbGw6IG5vbmU7CiAgICAgICAgc3Ryb2tlOiAjMDAwOwogICAgICAgIHN0cm9rZS1taXRlcmxpbWl0OiAxMDsKICAgICAgICBzdHJva2Utd2lkdGg6IDJweDsKICAgICAgfQogICAgPC9zdHlsZT4KICA8L2RlZnM+CiAgPHBhdGggZD0iTTksM2MzLjMxLDAsNiwyLjY5LDYsNnMtMi42OSw2LTYsNi02LTIuNjktNi02LDIuNjktNiw2LTZNOSwxQzQuNTgsMSwxLDQuNTgsMSw5czMuNTgsOCw4LDgsOC0zLjU4LDgtOFMxMy40MiwxLDksMWgwWiIvPgogIDxwb2x5bGluZSBjbGFzcz0iY2xzLTEiIHBvaW50cz0iOC41IDQuNSA4LjUgMTAgMTIuNSAxMCIvPgo8L3N2Zz4=",
  "rec"     => "PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPHN2ZyBpZD0iRWJlbmVfMSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIiB2aWV3Qm94PSIwIDAgMTggMTgiPgogIDxjaXJjbGUgY3g9IjkiIGN5PSI5IiByPSI2Ii8+Cjwvc3ZnPg==",
  "rec-alt" => "PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPHN2ZyBpZD0iRWJlbmVfMSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIiB2aWV3Qm94PSIwIDAgMTggMTgiPgogIDxwYXRoIGQ9Ik05LDNjLTMuMzEsMC02LDIuNjktNiw2czIuNjksNiw2LDYsNi0yLjY5LDYtNi0yLjY5LTYtNi02Wk05LDEyYy0xLjY2LDAtMy0xLjM0LTMtM3MxLjM0LTMsMy0zLDMsMS4zNCwzLDMtMS4zNCwzLTMsM1oiLz4KPC9zdmc+"
}


$EXT_DIR = "./TimeOnTrack/"
$SAVEFILE = "#{$EXT_DIR}TimeOnTrackData.json"
$LANG_DIR = "#{$EXT_DIR}lang/"
$LANG_FALLBACK = "en_US"
$FONT_MENU = "font='PTMono-Bold' size=13"
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
    $LANG = $data["language"] || $LANG_FALLBACK
  else
    # Script runs in regular mode. Get language from system or preferences.
    $LANG = `defaults read -g AppleLocale`.strip
    if(ENV["VAR_LANGUAGE_OVERRIDE"])
      $LANG = ENV["VAR_LANGUAGE_OVERRIDE"] unless ENV["VAR_LANGUAGE_OVERRIDE"].strip.empty?
    end
    $LANG = $LANG_FALLBACK if $LANG.strip.empty?
  end

  `export LANG="#{$LANG}.UTF-8"`

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

def icon(icon, preserve_color=false)
  return " | #{preserve_color ? "image" : "templateImage"}=\"#{$ICON[icon]}\""
end

def run_command(command, parameters = [])
  param_strings = []
  parameters.each_with_index { |param, index|
    param_string = "param#{index+2}="
    param_string += "\"#{param.gsub('"', '\\"')}\""
    param_strings << param_string
  }
  cmd_string = "shell=\"#{__FILE__}\" param1=#{command} #{param_strings.join(" ")} terminal=false"
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
    puts "#{icon("logo")}"
  else
    if $data["activeEntry"]
      puts "#{format_duration(activeJob["total"], true)} #{icon(activeJob["total"] % 2 == 0 ? "rec" : "rec-alt")} | #{$FONT_MENU}" #| color=#88ff88
    else
      puts "#{format_duration(activeJob["total"], true)} #{icon("pause")} | #{$FONT_MENU}" #| color=#ffaaaa
    end
  end

  # Divider for Dropdown
  puts "---"

  # Dropdown

  puts "#{t("job.continue", { jobname: activeJob["name"] })} | #{run_command("job:start", [activeJob["id"]])} #{icon("play")}" if $data["activeJob"] && !$data["activeEntry"]
  puts "#{t("job.pause", { jobname: activeJob["name"] })} | #{run_command("job:pause")} #{icon("pause")}" if $data["activeEntry"]
  puts "#{t("job.stop", { jobname: activeJob["name"] })} | #{run_command("job:stop")} #{icon("stop")}" if $data["activeJob"]
  puts "#{t("job.new")} | #{run_command("job:new")} #{icon("new")}" unless $data["activeEntry"]

  # Visual Divider
  puts "---"

  $data["jobs"].each do |job|
    next if job["archived"]
    if $data["activeEntry"]
      job_is_tracking = getEntryById($data["activeEntry"])["job_id"] == job["id"] ? true : false
    else
      job_is_tracking = false
    end
    puts "#{job["name"]} | length=35 #{job_is_tracking ? icon("running", true) : ""}"
    puts "-- #{format_duration(job["total"])} #{icon("time")}"
    puts "-----"
    puts "-- #{t("job.menu.continue")} | #{run_command("job:start", [job["id"]])} #{icon("play")} | refresh=true #{"| disabled=true" if job_is_tracking}"
    puts "-- #{t("job.menu.rename")} | #{run_command("job:rename", [job["id"]])} #{icon("rename")} | refresh=true"
    puts "-- #{t("job.menu.archive")} | #{run_command("job:archive", [job["id"]])} #{icon("archive")} | refresh=true #{"| disabled=true" if job_is_tracking}"
    puts "-- #{t("job.menu.delete")} | #{run_command("job:delete", [job["id"]])} #{icon("delete")} | refresh=true #{"| disabled=true" if job_is_tracking}"
    if(job["entries"].length > 0)
      puts "-----"
      puts "-- #{t("job.menu.entries")}"
      job["entries"].each { |entry|
        entry_is_tracking = ( $data["activeEntry"] == entry["id"] )
        entry_name = Time.at(entry["start"]).strftime("%Y-%m-%d %H:%M")
        entry_name = entry["name"] if entry["name"]
        puts "-- #{format_duration( entry["total"])} (#{entry_name}) #{entry_is_tracking ? icon("running", true) : ""}"
        unless entry_is_tracking
          puts "---- #{t("entry.edit")} | #{run_command("entry:edit", [entry["id"]])} #{icon("edit")} | refresh=true"
          puts "---- #{t("entry.rename")} | #{run_command("entry:rename", [entry["id"]])} #{icon("rename")} | refresh=true"
          puts "---- #{t("entry.delete")} | #{run_command("entry:delete", [entry["id"]])} #{icon("delete")} | refresh=true"
        end
      }
    else
      puts "-- #{t("entry.emptystate")}"
    end
  end

  # Visual Divider
  puts "---"

  puts "#{t("journal.show")} #{icon("journal")} | #{run_command("journal:open")} #{icon("journal")}"
  puts "#{t("savefile.edit")} #{icon("file")} | #{run_command("savefile:edit")} | alternate=true"

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

  when "entry:rename"
    begin
      # TODO
      entry = getEntryById(ARGV[1])
      job = getJobById(entry["job_id"])

      new_entry_name = prompt(t("prompt.entry.rename", {jobname: job["name"], duration: format_duration(entry["total"])}), input: "#{entry["name"] || ""}")
      exit if new_entry_name.nil? # user canceled the dialog
      entry["name"] = new_entry_name
      entry["name"] = nil if new_entry_name.strip.empty?
    rescue => error
      alert("Errror rename")
      alert("#{t("error.entry:rename")} \n#{error.message}\n#{error.backtrace.join("\n")}")
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