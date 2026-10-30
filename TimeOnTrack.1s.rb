#!/usr/bin/env ruby

# Metadata for SwiftBar
#  <swiftbar.title>TimeOnTrack</swiftbar.title>
#  <swiftbar.version>v2.0.0</swiftbar.version>
#  <swiftbar.author>Roman Gebath</swiftbar.author>
#  <swiftbar.author.github>rcheetah</swiftbar.author.github>
#  <swiftbar.desc>A sophisticated time tracker, which allows to track and pause mulitple projects at once.</swiftbar.desc>
#  <swiftbar.image>https://github.com/rcheetah/xbar-timeontrack/blob/ea0f22ad093ec8ed3eabca3a774f78f241752f54/screenshot.jpg</swiftbar.image>
#  <swiftbar.dependencies>ruby</swiftbar.dependencies>
#  <swiftbar.abouturl>https://github.com/rcheetah/xbar-timeontrack/</swiftbar.abouturl>
#  <swiftbar.hideLastUpdated>true</swiftbar.hideLastUpdated>
#  <swiftbar.refreshOnOpen>true</swiftbar.refreshOnOpen>
#  <swiftbar.runInBash>false</swiftbar.runInBash>

# Variables for preferences in the app:
#  <swiftbar.var>string(VAR_LANGUAGE_OVERRIDE=): Override the system language using a language code (e.g. en_US, de_DE)</swiftbar.var>
#  <swiftbar.var>boolean(VAR_DEV_MODE=false): Developer mode. Use a separate data directory and mark the menu bar item, so a test copy can run alongside the real one without touching its data.</swiftbar.var>


require 'json'
require 'securerandom'
require 'time'
require 'tmpdir'
require 'fileutils'


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


# The plugin runs from a symlink in the host's plugin folder. Ruby's __dir__ already
# resolves symlinks, but realpath makes that explicit and guarantees the directory we
# read our bundled assets from is the real repository.
$PLUGIN_DIR = File.dirname(File.realpath(__FILE__))

# Mutable state lives outside the repository.
#
# SwiftBar passes SWIFTBAR_PLUGIN_DATA_PATH, but that path is
# `<plugin folder>/<this file's name>` — and it therefore *is* this very file whenever
# the plugin sits directly in the plugin folder. On a case-insensitive volume (macOS
# default) SwiftBar's support folder and the plugin folder are the same directory, so
# using that path would collide with the plugin itself. Use it only when it resolves to
# a separate, existing directory; otherwise fall back to our own support directory.
$DATA_DIR = ENV["SWIFTBAR_PLUGIN_DATA_PATH"].to_s
$DATA_DIR = "" unless File.directory?($DATA_DIR)
if $DATA_DIR.empty?
  $DATA_DIR = File.join(Dir.home, "Library", "Application Support", "TimeOnTrack")
end

# Dev mode: run a second copy (e.g. the SwiftBar build alongside the production xbar
# plugin) against SEPARATE data so the two never write to the same files, and mark it
# visibly in the menu bar. Enable by setting VAR_DEV_MODE in the plugin settings, or
# SWIFTBAR_TIMEONTRACK_DEV=1 in the environment for command-line testing.
def var_set?(value)
  %w[1 true yes on].include?(value.to_s.strip.downcase)
end

$DEV_MODE = var_set?(ENV["VAR_DEV_MODE"]) || var_set?(ENV["SWIFTBAR_TIMEONTRACK_DEV"])
$DATA_DIR = File.join($DATA_DIR, "dev") if $DEV_MODE

$SAVEFILE = File.join($DATA_DIR, "TimeOnTrackData.json")
$ARCHIVEFILE = File.join($DATA_DIR, "TimeOnTrackArchive.json")
$LANG_DIR = File.join($PLUGIN_DIR, "TimeOnTrack", "lang")
$LANG_FALLBACK = "en_US"
$FONT_MENU = "font='PTMono-Bold' size=13"
# Shown in front of the menu bar text in dev mode so the two copies are told apart.
$DEV_PREFIX = "DEV "
$DEV_SUFFIX = " ⚠"
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
  yes = t("prompt.yes")
  no = t("prompt.no")
  script = <<~SCRIPT
    tell application "System Events"
      display dialog "#{text}" with title "#{title}" buttons {"#{no}", "#{yes}"} default button "#{yes}"
      if button returned of result is "#{yes}" then
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

# Dialog with multiple buttons
def show_dialog(text, title: "", buttons: ["OK"])
  buttons_list = buttons.reverse.map { |b| "\"#{b}\"" }.join(", ") # macOS erwartet Buttons in umgekehrter Reihenfolge
  default_button = buttons.length
  script = <<~SCRIPT
    tell application "System Events"
      activate
      display dialog "#{text}" with title "#{title}" buttons {#{buttons_list}} default button #{default_button}
      button returned of result
    end tell
  SCRIPT
  result = `osascript -e '#{script}' 2>/dev/null`
  return nil if $?.exitstatus != 0
  return result.strip
end


# Helpers

def system_language
  # LANG is already exported to the plugin environment, so prefer it over spawning
  # a `defaults` subprocess on every tick. Format: de_AT.UTF-8 -> de_AT
  lang = ENV["LANG"].to_s.split(".").first.to_s
  return lang unless lang.empty?
  `defaults read -g AppleLocale`.strip
end

def resolve_language
  # In action mode the environment is not passed along, so the language is
  # remembered in the data file instead.
  return $data["language"] || $LANG_FALLBACK if ARGV.length > 0

  # VAR_* is what SwiftBar injects from the plugin settings; the plain name is an
  # escape hatch for running the script by hand.
  override = ENV["VAR_LANGUAGE_OVERRIDE"].to_s.strip
  override = ENV["LANGUAGE_OVERRIDE"].to_s.strip if override.empty?
  return override unless override.empty?

  lang = system_language
  lang.empty? ? $LANG_FALLBACK : lang
end

def load_language_file
  $LANG = resolve_language

  # Exact match, then any region of the same language, then the fallback language.
  candidates = [
    File.join($LANG_DIR, "#{$LANG}.json"),
    Dir.glob(File.join($LANG_DIR, "#{$LANG.split('_').first}*.json")).first,
    File.join($LANG_DIR, "#{$LANG_FALLBACK}.json"),
  ].compact

  path = candidates.find { |candidate| File.exist?(candidate) }
  return path ? read_json(path) : {}
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

def escape_html(text)
  text.to_s.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;").gsub('"', "&quot;")
end

# Always read as UTF-8: Ruby falls back to US-ASCII when LANG is unset, which
# would raise on the translated language files.
def read_json(path)
  JSON.parse(File.read(path, encoding: "UTF-8"))
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

def format_duration(timestamp, enforce_hours=false, hide_seconds=false)
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
  string += ":#{seconds.to_s.rjust(2,'0')}" unless hide_seconds
  return string
end


# Getters

def archive_jobs
  # Lazily parsed: the archive can be large and most runs never need it.
  return $ARCHIVE_JOBS if $ARCHIVE_JOBS
  $ARCHIVE_JOBS = File.exist?($ARCHIVEFILE) ? (read_json($ARCHIVEFILE)["jobs"] || []) : []
end

def getJobById(id, include_archived: false)
  begin
    job = $data["jobs"].find { |job| job["id"] == id }
    return job if job
    return archive_jobs.find { |job| job["id"] == id } if include_archived
  rescue => error
    alert("#{t("error.getJobById", {id: id})}: \n#{error.message}\n#{error.backtrace.join("\n")}")
  end
  return nil
end

def getActiveJob()
  return nil if $data["activeJob"] == nil
  return getJobById($data["activeJob"])
end

def getEntryById(id, include_archived: false)
  begin
    $data["jobs"].each do |job|
      entry = job["entries"].find { |entry| entry["id"] == id }
      return entry if entry
    end
    if include_archived
      archive_jobs.each do |job|
        entry = job["entries"].find { |entry| entry["id"] == id }
        return entry if entry
      end
    end
  rescue => error
    alert("#{t("error.getEntryById")} \n#{error.message}\n#{error.backtrace.join("\n")}")
  end
  return nil
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
  $data["jobs"] = $data["jobs"].reject { |job| job["id"] == id }
end

def deleteEntry(id)
  $data["jobs"].each do |job|
    job["entries"] = job["entries"].reject { |entry| entry["id"] == id }
  end
end

def archiveJob(job)
  job["archived"] = true
  $data["jobs"].reject! { |j| j["id"] == job["id"] }

  archive_data = { "jobs" => archive_jobs }
  archive_data["jobs"] << job
  File.write($ARCHIVEFILE, JSON.pretty_generate(archive_data))
  $ARCHIVE_JOBS = archive_data["jobs"]

  if $data["activeJob"] == job["id"]
    $data["activeJob"] = nil
    $data["activeEntry"] = nil
  end
end

def generateJournalJobDom(job)
  tmpl_job = "<div class='job'><h3>%%JOB_NAME%%</h3><p><strong>#{t("journal.job.total")}: %%TIME_TOTAL%%</strong></p><p class='timeframe'>%%TIME_FRAME%%</p><table><thead><tr><th>#{t("journal.job.start")}</th><th>#{t("journal.job.end")}</th><th>#{t("journal.job.duration")}</th></tr></thead><tbody>%%ENTRIES%%</tbody></table></div>"
  tmpl_job.gsub!("%%JOB_NAME%%", escape_html(job["name"]))
  tmpl_job.gsub!("%%TIME_TOTAL%%", format_duration(job["total"]))

  unless job["entries"].empty?
    earliest = job["entries"].min_by { |entry| entry["start"] }
    latest = job["entries"].max_by { |entry| entry["end"] }
    timeframe = Time.at(earliest["start"]).strftime("%d.%m.%Y") + " #{t("journal.job.duration.to")} " + Time.at(latest["end"]).strftime("%d.%m.%Y")
    tmpl_job.gsub!("%%TIME_FRAME%%", timeframe)

    tmpl_entry_row = '<tr><td>%%START%%</td><td>%%END%%</td><td>%%DURATION%%</td></tr>'
    rows = []
    job["entries"].sort_by { |entry| entry["start"] }.each do |entry|
      # dup: gsub! would mutate the shared template string, repeating the first row.
      row = tmpl_entry_row.dup
      start = Time.at(entry["start"]).strftime("%Y-%m-%d %H:%M:%S")
      ende = Time.at(entry["end"]).strftime("%Y-%m-%d %H:%M:%S")
      duration = format_duration(entry["total"])
      duration += " (#{escape_html(entry["name"])})" if entry["name"]
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

  tmpl_journal_dom = "<!DOCTYPE html><html lang='#{$LANG.gsub("_", "-")}'><head><meta charset='UTF-8'><meta name='viewport' content='width=device-width, initial-scale=1.0'><title>#{t("journal.title")}</title><style>body{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Open Sans', 'Helvetica Neue', sans-serif;} #main{ max-width: 1200px; margin: 0 auto;} .jobs{flex-direction:column;display:flex;gap:.5rem} .job { background-color: lightgrey; padding: 1rem; border-radius: 0.25rem; margin: 0.5rem;}</style></head><body><div id='main'><h1>📖 #{t("journal.title")}</h1><h2>#{t("journal.jobs.active")}</h2><div id='jobs-active' class='jobs'>%%JOBS_ACTIVE%% </div><h2>#{t("journal.jobs.archived")}</h2><div id='jobs-archived' class='jobs'>%%JOBS_ARCHIVED%% </div></div></body></html>"
  active = $data["jobs"].select { |job| !job["archived"] }
  archived = archive_jobs

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
    $data = read_json($SAVEFILE)
  else
    $data = $EMPTY_DATA
  end

  # Tolerate missing keys so a fresh or hand-edited file cannot crash the plugin.
  $data["jobs"] ||= []
  $data["activeJob"] = nil unless $data.key?("activeJob")
  $data["activeEntry"] = nil unless $data.key?("activeEntry")

  if !File.exist?($ARCHIVEFILE)
    FileUtils.mkpath($DATA_DIR)
    File.write($ARCHIVEFILE, JSON.pretty_generate({ "jobs" => [] }))
  end

  # Recalculate totals for active jobs
  $data["jobs"].each do |job|
    job["entries"] ||= []
    job["entries"].each { |entry| entry["total"] = entry["end"] - entry["start"] }
    job["total"] = job["entries"].sum { |entry| entry["total"] }
    job["entries"].each { |entry| entry["job_id"] = job["id"] }
  end
end

def saveJSON()
  FileUtils.mkpath($DATA_DIR)
  File.write($SAVEFILE, JSON.pretty_generate($data))
end

def updateRunningTimer()
  return unless $data["activeEntry"]
  entry = getEntryById($data["activeEntry"])
  entry["end"] = Time.now.to_i
end

def buildMenu()
  activeJob = getActiveJob()

  # Menubar. In dev mode the text is prefixed and tinted yellow, so a test copy is
  # unmistakable next to the real one. (SwiftBar has no background-colour parameter.)
  prefix = $DEV_MODE ? $DEV_PREFIX : ""
  dev_params = $DEV_MODE ? "| color=#E8A400" : ""
  if $data["activeJob"].nil?
    puts "#{prefix}#{icon("logo")} #{dev_params}"
  else
    if $data["activeEntry"]
      puts "#{prefix}#{format_duration(activeJob["total"], true)} #{icon(activeJob["total"] % 2 == 0 ? "rec" : "rec-alt")} | #{$FONT_MENU} | refresh=true #{dev_params}" #| color=#88ff88
    else
      puts "#{prefix}#{format_duration(activeJob["total"], true)} #{icon("pause")} | #{$FONT_MENU} | refresh=true #{dev_params}" #| color=#ffaaaa
    end
  end

  # Divider for Dropdown
  puts "---"

  # Dropdown

  puts "#{t("job.continue", { jobname: activeJob["name"] })} | refresh=true | #{run_command("job:start", [activeJob["id"]])} #{icon("play")}" if $data["activeJob"] && !$data["activeEntry"]
  puts "#{t("job.pause", { jobname: activeJob["name"] })} | refresh=true | #{run_command("job:pause")} #{icon("pause")}" if $data["activeEntry"]
  puts "#{t("job.stop", { jobname: activeJob["name"] })} | refresh=true | #{run_command("job:stop")} #{icon("stop")}" if $data["activeJob"]
  puts "#{t("job.new")} | refresh=true | #{run_command("job:new")} #{icon("new")}" unless $data["activeEntry"]

  # Visual Divider
  puts "---"

  # SwiftBar has no `disabled=` parameter: an entry is greyed out when it carries
  # no action at all, so restricted entries are emitted without an action.
  tracking_job_id = $data["activeEntry"] ? getEntryById($data["activeEntry"])&.fetch("job_id", nil) : nil

  $data["jobs"].sort_by { |job| job["name"].to_s.downcase }.each do |job|
    next if job["archived"]
    job_is_tracking = (job["id"] == tracking_job_id)

    puts "#{job["name"]} | length=35 #{job_is_tracking ? icon("rec", true) : ""}"
    puts "-- #{format_duration(job["total"])} #{icon("time")}"
    puts "-----"
    puts job_is_tracking ?
      "-- #{t("job.menu.continue")} #{icon("play")}" :
      "-- #{t("job.menu.continue")} | #{run_command("job:start", [job["id"]])} #{icon("play")} | refresh=true"
    puts "-- #{t("job.menu.rename")} | #{run_command("job:rename", [job["id"]])} #{icon("rename")} | refresh=true"
    puts job_is_tracking ?
      "-- #{t("job.menu.archive")} #{icon("archive")}" :
      "-- #{t("job.menu.archive")} | #{run_command("job:archive", [job["id"]])} #{icon("archive")} | refresh=true"
    puts job_is_tracking ?
      "-- #{t("job.menu.delete")} #{icon("delete")}" :
      "-- #{t("job.menu.delete")} | #{run_command("job:delete", [job["id"]])} #{icon("delete")} | refresh=true"
    puts "-- #{t("job.menu.daily_summary")} | #{run_command("job:summary", [job["id"]])} #{icon("journal")} | refresh=true"
    if(job["entries"].length > 0)
      puts "-----"
      puts "-- #{t("job.menu.entries")}"
      job["entries"].each { |entry|
        entry_is_tracking = ( $data["activeEntry"] == entry["id"] )
        entry_name = Time.at(entry["start"]).strftime("%Y-%m-%d %H:%M")
        entry_name = entry["name"] if entry["name"]
        puts "-- #{format_duration( entry["total"])} (#{entry_name}) #{entry_is_tracking ? icon("rec", true) : ""}"
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

  # An unmistakable in-menu banner, plus the data directory, so it is obvious that this
  # copy is the dev one and which files it writes to.
  if $DEV_MODE
    puts "---"
    puts "#{$DEV_SUFFIX.strip} DEV MODE | color=#E8A400"
    puts "-- data: #{$DATA_DIR} | color=#888888 length=80"
  end
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
      alert("#{t("error.job:rename")} \n#{error.message}\n#{error.backtrace.join("\n")}")
    end

  when "job:archive"
    job = getJobById(ARGV[1])
    archiveJob(job)

  when "job:delete"
    begin
      job = getJobById(ARGV[1])
      confirmed = yes_no_prompt(t("prompt.job.delete.message", {jobname: job["name"]}), title: t("prompt.job.delete.title"))
      return unless confirmed
      active_job = getActiveJob()
      active_entry = getEntryById($data["activeEntry"]) if $data["activeEntry"]
      $data["activeJob"] = nil if active_job && job["id"] == active_job["id"]
      $data["activeEntry"] = nil if active_entry && job["id"] == active_entry["job_id"]
      deleteJob(ARGV[1]) if confirmed

    rescue => error
      alert("#{t("error.job:delete")} \n#{error.message}\n#{error.backtrace.join("\n")}")
    end

  when "job:summary"
    begin
      job = getJobById(ARGV[1])
      daily_totals = Hash.new(0)

      job["entries"].each do |entry|
        day = Time.at(entry["start"]).strftime("%Y-%m-%d")
        daily_totals[day] += entry["total"]
      end

      total_diff = 0

      summary_lines = daily_totals.map do |date, total|
        # 15 minutes = 900 seconds
        rounded_total = (total / 900.0).round * 900
        total_diff += (total - rounded_total)
        "#{date}: #{format_duration(total)} (≈ #{format_duration(rounded_total, false, true)})"
      end

      diff_sign = total_diff < 0 ? "-" : "+"
      formatted_diff = "#{diff_sign}#{format_duration(total_diff.abs)}"

      total_rounded = (job["total"] / 900.0).round * 900
      total_line = "—\n#{t("summary.total")} #{format_duration(job["total"])} (≈ #{format_duration(total_rounded, false, true)})\nRest: #{formatted_diff}"

      dialog_text = summary_lines.join("\n") + "\n" + total_line
      result = show_dialog(
        dialog_text,
        title: t("prompt.job.daily_summary.title", {jobname: job["name"]}),
        buttons: [t("prompt.job.daily_summary.button.ok"), t("prompt.job.daily_summary.button.archive")]
      )

      if result == t("prompt.job.daily_summary.button.archive")
        archiveJob(job)
      end
    rescue => error
      alert("#{t("error.job:summary")} \n#{error.message}\n#{error.backtrace.join("\n")}")
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
      entry = getEntryById(ARGV[1])
      job = getJobById(entry["job_id"])

      new_entry_name = prompt(t("prompt.entry.rename", {jobname: job["name"], duration: format_duration(entry["total"])}), input: "#{entry["name"] || ""}")
      exit if new_entry_name.nil? # user canceled the dialog
      entry["name"] = new_entry_name
      entry["name"] = nil if new_entry_name.strip.empty?
    rescue => error
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