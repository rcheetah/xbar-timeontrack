#!/usr/bin/env ruby

# Metadata for SwiftBar.
#
# NOTE: SwiftBar only reads the descriptive tags (title/version/author/desc/image/
# dependencies/abouturl) with the `xbar.` prefix — in its source these are typed
# [.bitbar, .xbar], NOT .swiftbar. Only SwiftBar's own extras use `swiftbar.`.
# Writing `swiftbar.title` etc. silently leaves the About pane empty.
#  <xbar.title>TimeOnTrack</xbar.title>
#  <xbar.version>v2.0.0</xbar.version>
#  <xbar.author>Roman Gebath</xbar.author>
#  <xbar.author.github>rcheetah</xbar.author.github>
#  <xbar.desc>A sophisticated time tracker, which allows to track and pause mulitple projects at once.</xbar.desc>
#  <xbar.image>https://github.com/rcheetah/xbar-timeontrack/blob/ea0f22ad093ec8ed3eabca3a774f78f241752f54/screenshot.jpg</xbar.image>
#  <xbar.dependencies>ruby</xbar.dependencies>
#  <xbar.abouturl>https://github.com/rcheetah/xbar-timeontrack/</xbar.abouturl>

# SwiftBar-only extras
#  <swiftbar.hideLastUpdated>true</swiftbar.hideLastUpdated>
#  <swiftbar.refreshOnOpen>true</swiftbar.refreshOnOpen>
#  <swiftbar.runInBash>false</swiftbar.runInBash>

# Variables for preferences in the app.
# The default value MUST be double-quoted or SwiftBar's regex does not match the tag
# at all and the variable never shows up in Settings > Plugins > Plugin Variables.
#  <swiftbar.var>string(VAR_LANGUAGE_OVERRIDE=""): Override the system language using a language code (e.g. en_US, de_DE)</swiftbar.var>
#  <swiftbar.var>boolean(VAR_DEV_MODE="false"): Developer mode. Use a separate data directory and mark the menu bar item, so a test copy can run alongside the real one without touching its data.</swiftbar.var>
#  <swiftbar.var>boolean(VAR_SKIP_SAVEFILE_WARNING="false"): Skip the warning before revealing the data file. Set by choosing the "don't ask again" button in that dialog; switch it back off here to see the warning again.</swiftbar.var>


require 'json'
require 'securerandom'
require 'time'
require 'fileutils'
require 'shellwords'


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


# Are two paths the same directory on disk? Compares device + inode, so it is immune to
# spelling differences that a string comparison would trip over — notably macOS's
# case-insensitive filesystem, where SwiftBar reports `.../SwiftBar/Plugins/...` while the
# plugin folder resolves to `.../swiftbar/plugins`. A prefix test on those strings is false,
# which is how the data-directory guard silently stopped working.
def same_dir?(a, b)
  sa = File.stat(a) rescue nil
  sb = File.stat(b) rescue nil
  return false if sa.nil? || sb.nil?
  return sa.dev == sb.dev && sa.ino == sb.ino
end

# The plugin runs from a symlink in the host's plugin folder. Ruby's __dir__ already
# resolves symlinks, but realpath makes that explicit and guarantees the directory we
# read our bundled assets from is the real repository.
$PLUGIN_DIR = File.dirname(File.realpath(__FILE__))

# Mutable state lives outside the repository, and outside the plugin folder too.
#
# SWIFTBAR_PLUGIN_DATA_PATH is NOT trusted here. On SwiftBar 2.1.x it is unusable: the
# plugin's absolute path gets appended below the support root, producing nonsense like
#      <plugin folder>/Users/me/git/repo/TimeOnTrack.1s.rb/
# (SwiftBar's own source calls this out — see `regressedSupportDirectory`, "an absolute
# plugin ID mistakenly appended below the support root"). SwiftBar does create that
# directory, so a plain File.directory? test is not enough to catch it. Even on a
# corrected build the path would be `<plugin folder>/<this file's name>`, which collides
# with the plugin file itself.
#
# So: accept the variable only when it is a real directory that is *not* inside the
# plugin folder; otherwise use our own Application Support directory. That is stable,
# bookmark-friendly, and keeps data out of the plugin folder — which also matters because
# SwiftBar treats everything in there as a plugin candidate.
$DATA_DIR = ENV["SWIFTBAR_PLUGIN_DATA_PATH"].to_s
$DATA_DIR = "" unless File.directory?($DATA_DIR)

unless $DATA_DIR.empty?
  resolved = File.realpath($DATA_DIR) rescue $DATA_DIR

  # Trust only a directory that is plainly outside the plugin world. This must not depend
  # on SWIFTBAR_PLUGINS_PATH: that variable is present for ordinary plugin runs but NOT in
  # plugin.env, which is what SwiftBar hands to menu *actions*. A guard that silently stops
  # guarding depending on how the plugin was invoked is worse than no guard.
  #
  # Instead, derive the forbidden roots from information that is always available:
  # $PLUGIN_DIR (where the code lives, via realpath) and $0/$SWIFTBAR_PLUGIN_PATH (how we
  # were invoked). Walking up from the invoked path covers SwiftBar's plugin folder without
  # naming it.
  #
  # The comparison MUST NOT be a string prefix test. SwiftBar hands us a path spelled
  # `.../SwiftBar/Plugins/...` while the plugin folder resolves to `.../swiftbar/plugins`;
  # macOS treats those as one directory but Ruby compares case-sensitively, so
  # `start_with?` returns false and the guard silently does nothing. Verified against the
  # live plugin: `resolved` kept the capitalised spelling and `hit` was false.
  #
  # Compare by filesystem identity instead: walk the candidate upwards and stop as soon as
  # an ancestor is the same directory as one we must avoid (same device + inode). This is
  # case-insensitive for free, and also survives symlinked or aliased path spellings.
  forbidden = [$PLUGIN_DIR]
  [ENV["SWIFTBAR_PLUGINS_PATH"], ENV["SWIFTBAR_PLUGIN_PATH"], $PROGRAM_NAME].each do |candidate|
    next if candidate.to_s.empty?
    dir = File.dirname(candidate.to_s)
    forbidden << dir if File.directory?(dir)
  end

  # Walk up from the data dir; if any ancestor is a forbidden directory, reject.
  probe = resolved
  loop do
    if forbidden.any? { |base| same_dir?(probe, base) }
      $DATA_DIR = ""
      break
    end
    parent = File.dirname(probe)
    break if parent == probe # reached the root
    probe = parent
  end
end

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
# Fixed name (not timestamped) so a browser bookmark keeps working. The page carries its
# own generation time and offers a reload button, so staleness is visible rather than
# hidden. Never written unless the journal is actually requested.
$SAVEFILE_JOURNAL = File.join($DATA_DIR, "journal.html")
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
#
# All of these hand user-supplied text to osascript as ARGV rather than interpolating it
# into the AppleScript source. Interpolation was the cause of two failures:
#
#   * Encoding. osascript's output is tagged with Ruby's default external encoding, which
#     is US-ASCII when LANG is unset — as it is for a GUI-launched app. `.strip` on a
#     US-ASCII string containing an umlaut raises Encoding::CompatibilityError, so naming a
#     job "Büro" aborted the action and the job was silently never created.
#   * Quoting. A `"` in the text broke the AppleScript literal, and a `'` could break the
#     surrounding shell string.
#
# Passing values via argv sidesteps both: the script text stays pure ASCII and the values
# never travel through the shell.

# Absolute path by default: the plugin runs with <swiftbar.runInBash>false, so it inherits
# SwiftBar's minimal environment rather than a login shell's, and PATH is not guaranteed.
#
# The env override exists so tests can substitute a stub. Without it a test that exercises
# a dialog would block on a real modal window and hang instead of failing.
OSASCRIPT = ENV["TIMEONTRACK_OSASCRIPT"].to_s.empty? ? "/usr/bin/osascript" : ENV["TIMEONTRACK_OSASCRIPT"]

def run_osascript(script, *args)
  # Read as UTF-8 regardless of locale, then scrub defensively so a malformed byte can
  # never take down an action.
  out = IO.popen([OSASCRIPT, "-e", script, "--", *args.map(&:to_s)],
                 external_encoding: Encoding::UTF_8, err: File::NULL, &:read)
  return nil unless $?.success?
  return out.to_s.force_encoding(Encoding::UTF_8).scrub
rescue Errno::ENOENT, Errno::EACCES => error
  # Do NOT use alert() here: alert() goes through run_osascript, so a missing osascript
  # would recurse until the stack blew. Record it where it can be found instead.
  log_error("osascript unavailable (#{error.class}): #{error.message}")
  return nil
end

# Last-resort error trail. Dialogs are the normal channel, but they are exactly what is
# unavailable when something is wrong with the dialog machinery.
#
# Falls back to a fixed path in /tmp: the data directory is itself computed from the
# environment, so if that is what is broken, logging there would fail too and we would be
# blind to the very problem we are trying to see.
def log_error(message)
  line = "#{Time.now.strftime("%Y-%m-%d %H:%M:%S")}  #{message}\n"
  written = false

  [[$DATA_DIR, "errors.log"], ["/tmp", "TimeOnTrack-errors.log"]].each do |dir, name|
    next if dir.to_s.empty?
    begin
      FileUtils.mkpath(dir)
      File.open(File.join(dir, name), "a", encoding: "UTF-8") { |io| io.write(line) }
      written = true
      break
    rescue StandardError
      next
    end
  end

  # Logging must never be the thing that breaks an action.
  return if written
  nil
end

def prompt(text, title: "", input: "")
  script = <<~SCRIPT
    on run argv
      tell application "System Events"
        text returned of (display dialog (item 1 of argv) with title (item 2 of argv) default answer (item 3 of argv))
      end tell
    end run
  SCRIPT
  result = run_osascript(script, text, title, input)
  return nil if result.nil? # user canceled, or osascript failed
  return result.strip
end

def yes_no_prompt(text, title: "")
  yes = t("prompt.yes")
  no = t("prompt.no")
  script = <<~SCRIPT
    on run argv
      tell application "System Events"
        display dialog (item 1 of argv) with title (item 2 of argv) buttons {item 3 of argv, item 4 of argv} default button (item 4 of argv)
        if button returned of result is (item 4 of argv) then
          return "true"
        else
          return "false"
        end if
      end tell
    end run
  SCRIPT
  result = run_osascript(script, text, title, no, yes)
  return result.to_s.strip == "true"
end

# Yes/No dialog offering "don't ask again" as a third button. Returns
# [confirmed, dont_ask_again].
#
# Why a button and not a checkbox: `display dialog` has no checkbox control, and the
# obvious alternative — NSAlert via AppleScriptObjC — does not work here. SwiftBar runs
# actions with `terminal=false`, i.e. `runInBackground: true`, so the process has no GUI
# session; an NSAlert belongs to the osascript process and its window is never shown
# (verified: the frontmost application stays Finder for the whole run). A dialog shown
# through System Events has no such problem, because System Events is itself a GUI app.
#
# Semantics: only the "don't ask again" button persists, and it also means Yes. A plain
# "No" must not switch the dialog off permanently — this dialog is the feature's only
# entry point, so that would make it unreachable.
def confirm_with_skip_option(text, title: "", skip_label: "")
  yes = t("prompt.yes")
  no = t("prompt.no")
  script = <<~SCRIPT
    on run argv
      tell application "System Events"
        display dialog (item 1 of argv) with title (item 2 of argv) buttons {item 3 of argv, item 4 of argv, item 5 of argv} default button (item 5 of argv)
        return button returned of result
      end tell
    end run
  SCRIPT

  # Button order: {no, skip, yes} renders as  No | Don't ask again | Yes(default, rightmost).
  result = run_osascript(script, text, title, no, skip_label, yes)
  return [false, false] if result.nil? # cancelled or osascript failed

  answer = result.to_s.strip
  return [true, true] if answer == skip_label
  return [answer == yes, false]
end

# Path of the vars file SwiftBar keeps beside the plugin
# (<plugin>.vars.json). Returns nil when it cannot be determined, e.g. when the script is
# run by hand and SWIFTBAR_PLUGIN_PATH is absent.
def vars_file_path
  plugin = ENV["SWIFTBAR_PLUGIN_PATH"].to_s
  return nil if plugin.empty?
  dir = File.dirname(plugin)
  return File.join(dir, File.basename(plugin, ".*") + ".vars.json")
end

# Persist a plugin variable so SwiftBar picks it up on the next run. Values are merged,
# never replaced, so unrelated settings survive.
#
# SwiftBar itself only reads this file when it parses the plugin metadata, so the change
# takes effect on the next refresh rather than instantly. It also means the variable must
# be declared as a <swiftbar.var> tag: SwiftBar builds the environment from the declared
# variables, so a key that exists only in the vars file is ignored. Declaring it also makes
# it visible (and resettable) in Settings > Plugins > Plugin Variables.
def save_plugin_var(name, value)
  path = vars_file_path
  return false if path.nil?

  values = File.exist?(path) ? (read_json(path) rescue {}) : {}
  values[name] = value.to_s
  File.write(path, JSON.generate(values), encoding: "UTF-8")
  return true
rescue => error
  alert("#{t("error.savevar")} \n#{error.message}")
  return false
end

def alert(text, title: "")
  script = <<~SCRIPT
    on run argv
      tell application "System Events"
        display dialog (item 1 of argv) with title (item 2 of argv) buttons {"OK"} default button "OK"
      end tell
    end run
  SCRIPT
  run_osascript(script, text, title)
end

# Dialog with multiple buttons
def show_dialog(text, title: "", buttons: ["OK"])
  # macOS expects the buttons in reverse order. The default button must be given as an
  # item reference: a bare number is a *button index* and silently fails with a
  # "-50: button does not exist" error when it exceeds the button count.
  reversed = buttons.reverse
  button_items = reversed.each_index.map { |i| "(item #{i + 3} of argv)" }.join(", ")
  default_item = reversed.length + 2 # last reversed button == first of `buttons`
  script = <<~SCRIPT
    on run argv
      tell application "System Events"
        activate
        display dialog (item 1 of argv) with title (item 2 of argv) buttons {#{button_items}} default button (item #{default_item} of argv)
        button returned of result
      end tell
    end run
  SCRIPT
  result = run_osascript(script, text, title, *reversed)
  return nil if result.nil?
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

# SwiftBar splits a line on the FIRST `|` only; everything after it is the parameter
# list, in which parameters are separated by SPACES. A second `|` therefore becomes part
# of a parameter key and silently disables every parameter after it. So every helper
# below returns bare `key="value"` fragments and the line is assembled once, in
# menu_line, with a single separator.
# All icons are template images, so macOS recolours them to match the menu (white on a
# dark menu bar, black on a light one). Do NOT switch one to `image=`: that renders the
# literal colour baked into the SVG, which is what made the record dot appear black on a
# dark dropdown.
def icon(icon)
  return "templateImage=\"#{$ICON[icon]}\""
end

# Marker for the job/entry currently being tracked.
def running_icon
  return icon("rec")
end

def escape_html(text)
  text.to_s.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;").gsub('"', "&quot;")
end

# Always read as UTF-8: Ruby falls back to US-ASCII when LANG is unset, which
# would raise on the translated language files.
def read_json(path)
  JSON.parse(File.read(path, encoding: "UTF-8"))
end

# Assemble one menu line: "<title> | param=value param=value ...".
# nil/empty/false params are dropped so callers can pass conditionals inline.
def menu_line(title, *params)
  clean = params.flatten.compact.reject { |param| param.to_s.strip.empty? }
  return title.to_s if clean.empty?
  "#{title} | #{clean.join(" ")}"
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

# The journal is a self-contained offline page: the job data is embedded as JSON and all
# filtering, sorting and grouping happens in the browser. The plugin only supplies data.
# Assets live in TimeOnTrack/journal/ so the page can be edited without fighting Ruby
# string quoting.

def journal_asset(name)
  return File.join($PLUGIN_DIR, "TimeOnTrack", "journal", name)
end

# The name SwiftBar knows this plugin by. NOT File.realpath: the plugin runs from a
# symlink in the plugin folder, and SwiftBar's URL scheme addresses it as <plugin file
# name>. A dev-named link (TimeOnTrack-dev.1s.rb) must be addressed by that name, so
# refreshplugin URLs built from the real path would silently target nothing.
def plugin_file_name
  path = ENV["SWIFTBAR_PLUGIN_PATH"].to_s
  return File.basename(path) unless path.empty?
  return File.basename($0) unless $0.to_s.empty?
  return File.basename(File.realpath(__FILE__))
end

# Compact payload. Keys are shortened and derived fields (total, job_id) are dropped
# because the browser recomputes them; this keeps the embedded data at ~100 KB for
# 777 jobs / 3.2k entries instead of ~530 KB.
def journal_payload
  jobs = $data["jobs"].reject { |job| job["archived"] } + archive_jobs
  return jobs.map { |job|
    {
      "n" => job["name"].to_s,
      "a" => job["archived"] ? 1 : 0,
      "e" => (job["entries"] || []).map { |entry|
        e = { "s" => entry["start"], "e" => entry["end"] }
        e["n"] = entry["name"] if entry["name"]
        e
      },
    }
  }
end

# Only the strings the browser needs. Kept separate from the Ruby-side $LANG_DATA.
def journal_i18n
  keys = %w[
    journal.title journal.jobs.active journal.jobs.archived
    journal.job.total journal.job.start journal.job.end journal.job.duration
    journal.job.duration.to journal.job.entries.emptystate
    journal.filter.search journal.filter.from journal.filter.to
    journal.filter.year journal.filter.month journal.filter.all
    journal.filter.active journal.filter.archived journal.filter.min_duration
    journal.filter.view_time journal.filter.view_table journal.filter.reset
    journal.summary.jobs journal.summary.entries journal.summary.total
    journal.summary.avg journal.summary.none
    journal.export.csv journal.refresh journal.generated
    journal.stale journal.staleHint journal.entries journal.entries.named
    journal.by_month journal.top_jobs journal.no_entries journal.status
    journal.period journal.min journal.hours journal.month
  ]
  out = {}
  keys.each { |key| out[key] = t(key) }
  return out
end

def generateJournal
  template = File.read(journal_asset("journal.html"), encoding: "UTF-8")
  css = File.read(journal_asset("journal.css"), encoding: "UTF-8")
  js = File.read(journal_asset("journal.js"), encoding: "UTF-8")

  # `</` inside an embedded <script> would terminate the block early.
  data = JSON.generate(journal_payload).gsub("</", "<\\/")
  i18n = JSON.generate(journal_i18n).gsub("</", "<\\/")

  html = template.dup
  html.gsub!("%%LANG%%", $LANG.gsub("_", "-"))
  html.gsub!("%%TITLE%%", escape_html(t("journal.title")))
  html.gsub!("%%GENERATED%%", Time.now.to_i.to_s)
  html.gsub!("%%GENERATED_TEXT%%", escape_html(Time.now.strftime("%d.%m.%Y %H:%M")))
  html.gsub!("%%PLUGIN_FILE%%", escape_html(plugin_file_name))
  html.gsub!("%%DATA%%", data)
  html.gsub!("%%I18N%%", i18n)
  html.gsub!("%%CSS%%", css)
  html.gsub!("%%JS%%", js)

  FileUtils.mkpath($DATA_DIR)
  File.write($SAVEFILE_JOURNAL, html, encoding: "UTF-8")
  return $SAVEFILE_JOURNAL
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

  # Menubar. In dev mode the text is prefixed and tinted amber, so a test copy is
  # unmistakable next to the real one. (SwiftBar has no background-colour parameter.)
  #
  # Deliberately NO `refresh=true` here. A title line carrying refresh but no bash makes
  # SwiftBar treat a plain left click as that action (`routeForBarItemClick` ->
  # `.runTitleAction`), so the click only re-runs the plugin — which is already ticking
  # every second — and the dropdown never opens. Without it, left click opens the menu
  # normally.
  prefix = $DEV_MODE ? $DEV_PREFIX : ""
  dev_params = $DEV_MODE ? "color=#E8A400" : nil
  if $data["activeJob"].nil?
    puts menu_line("#{prefix}", icon("logo"), dev_params)
  elsif $data["activeEntry"]
    # The icon alternates every other second so the clock visibly ticks while running.
    puts menu_line("#{prefix}#{format_duration(activeJob["total"], true)}",
                   icon(activeJob["total"] % 2 == 0 ? "rec" : "rec-alt"),
                   $FONT_MENU, dev_params)
  else
    puts menu_line("#{prefix}#{format_duration(activeJob["total"], true)}",
                   icon("pause"), $FONT_MENU, dev_params)
  end

  # Divider for Dropdown
  puts "---"

  # Dropdown

  if $data["activeJob"] && !$data["activeEntry"]
    puts menu_line(t("job.continue", { jobname: activeJob["name"] }),
                   "refresh=true", run_command("job:start", [activeJob["id"]]), icon("play"))
  end
  if $data["activeEntry"]
    puts menu_line(t("job.pause", { jobname: activeJob["name"] }),
                   "refresh=true", run_command("job:pause"), icon("pause"))
  end
  if $data["activeJob"]
    puts menu_line(t("job.stop", { jobname: activeJob["name"] }),
                   "refresh=true", run_command("job:stop"), icon("stop"))
  end
  unless $data["activeEntry"]
    puts menu_line(t("job.new"), "refresh=true", run_command("job:new"), icon("new"))
  end

  # Visual Divider
  puts "---"

  # SwiftBar has no `disabled=` parameter: an entry is greyed out when it carries
  # no action at all, so restricted entries are emitted without an action.
  tracking_job_id = $data["activeEntry"] ? getEntryById($data["activeEntry"])&.fetch("job_id", nil) : nil

  $data["jobs"].sort_by { |job| job["name"].to_s.downcase }.each do |job|
    next if job["archived"]
    job_is_tracking = (job["id"] == tracking_job_id)

    puts menu_line(job["name"], "length=35", job_is_tracking ? running_icon : nil)
    puts menu_line("-- #{format_duration(job["total"])}", icon("time"))
    puts "-----"
    # While this job is being tracked, its mutating actions carry no action and are
    # therefore rendered greyed out.
    puts job_is_tracking ?
      menu_line("-- #{t("job.menu.continue")}", icon("play")) :
      menu_line("-- #{t("job.menu.continue")}",
                run_command("job:start", [job["id"]]), icon("play"), "refresh=true")
    puts menu_line("-- #{t("job.menu.rename")}",
                   run_command("job:rename", [job["id"]]), icon("rename"), "refresh=true")
    puts job_is_tracking ?
      menu_line("-- #{t("job.menu.archive")}", icon("archive")) :
      menu_line("-- #{t("job.menu.archive")}",
                run_command("job:archive", [job["id"]]), icon("archive"), "refresh=true")
    puts job_is_tracking ?
      menu_line("-- #{t("job.menu.delete")}", icon("delete")) :
      menu_line("-- #{t("job.menu.delete")}",
                run_command("job:delete", [job["id"]]), icon("delete"), "refresh=true")
    puts menu_line("-- #{t("job.menu.daily_summary")}",
                   run_command("job:summary", [job["id"]]), icon("journal"), "refresh=true")
    if job["entries"].length > 0
      puts "-----"
      puts "-- #{t("job.menu.entries")}"
      job["entries"].each { |entry|
        entry_is_tracking = ( $data["activeEntry"] == entry["id"] )
        entry_name = Time.at(entry["start"]).strftime("%Y-%m-%d %H:%M")
        entry_name = entry["name"] if entry["name"]
        puts menu_line("-- #{format_duration(entry["total"])} (#{entry_name})",
                       entry_is_tracking ? running_icon : nil)
        unless entry_is_tracking
          puts menu_line("---- #{t("entry.edit")}",
                         run_command("entry:edit", [entry["id"]]), icon("edit"), "refresh=true")
          puts menu_line("---- #{t("entry.rename")}",
                         run_command("entry:rename", [entry["id"]]), icon("rename"), "refresh=true")
          puts menu_line("---- #{t("entry.delete")}",
                         run_command("entry:delete", [entry["id"]]), icon("delete"), "refresh=true")
        end
      }
    else
      puts "-- #{t("entry.emptystate")}"
    end
  end

  # Visual Divider
  puts "---"

  puts menu_line(t("journal.show"), run_command("journal:open"), icon("journal"))
  puts menu_line(t("savefile.reveal"), run_command("savefile:reveal"), "alternate=true")

  # An unmistakable in-menu banner, plus the data directory, so it is obvious that this
  # copy is the dev one and which files it writes to.
  if $DEV_MODE
    puts "---"
    puts menu_line("#{$DEV_SUFFIX.strip} DEV MODE", "color=#E8A400")
    puts menu_line("-- data: #{$DATA_DIR}", "color=#888888", "length=80")
  end
end


def actionHandler()
  return if ARGV.empty?

  case ARGV[0]

  when "job:pause"
    begin
      updateRunningTimer()
      $data["activeEntry"] = nil
    rescue => error
      alert("#{t("error.job:pause")} \n#{error.message}\n#{error.backtrace.join("\n")}")
    end

  when "job:start"
    begin
      new_entry_id = startNewEntry(ARGV[1])
      $data["activeJob"] = ARGV[1]
      $data["activeEntry"] = new_entry_id
    rescue => error
      alert("#{t("error.job:pause")} \n#{error.message}\n#{error.backtrace.join("\n")}")
    end

  when "job:stop"
    begin
      updateRunningTimer()
      $data["activeJob"] = nil
      $data["activeEntry"] = nil
    rescue => error
      alert("#{t("error.job:stop")} \n#{error.message}\n#{error.backtrace.join("\n")}")
    end

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
    begin
      job = getJobById(ARGV[1])
      archiveJob(job)
    rescue => error
      alert("#{t("error.job:archive")} \n#{error.message}\n#{error.backtrace.join("\n")}")
    end

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
      total_line = "—\n#{t("summary.total")} #{format_duration(job["total"])} (≈ #{format_duration(total_rounded, false, true)})\n#{t("summary.remainder")}: #{formatted_diff}"

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
    begin
      file = generateJournal()
      # `open` reuses an existing tab for the same URL, but the browser will not re-read
      # a file it already has loaded — the page's own reload button covers that case.
      # `-g` keeps the browser from stealing focus, so the journal can be opened while
      # working in another app. (Note: it suppresses activation, not all visual effects —
      # if the browser is on the current Space a new tab may still appear.)
      `open -g #{Shellwords.escape(file)}`
    rescue => error
      alert("#{t("error.journal:open")} \n#{error.message}\n#{error.backtrace.join("\n")}")
    end

  # Triggered by the journal page's reload button via SwiftBar's URL scheme:
  #   swiftbar://refreshplugin?name=<plugin>&journal=regen
  # SwiftBar passes unknown query parameters through as environment variables
  # (AppDelegate: `plugin.refreshEnv = params.filter { $0.key != "name" }`).
  #
  # !! REQUIRES SWIFTBAR >= 2.1.2 !!
  # The `refreshplugin` endpoint does NOT exist in 2.1.1 (the last stable release, and the
  # version Homebrew currently ships). Verified by inspecting the 2.1.1 binary: the string
  # "refreshplugin" is absent, while "refreshallplugins" and "setephemeralplugin" are
  # present. On 2.1.1 `open` still exits 0 — LaunchServices accepts the URL and the app
  # then ignores it — so the failure is silent. Confirmed with a probe plugin: the refresh
  # reason stayed `Schedule` instead of `URLScheme`, and no query parameter ever arrived.
  #
  # TODO(swiftbar-2.1.2): once 2.1.2 is out of beta AND available via Homebrew
  # (`curl -sL https://formulae.brew.sh/api/cask/swiftbar.json | grep version`), verify
  # end-to-end that the reload button leaves the page fresh, then delete this note.
  # Until then the button and the auto-refresh are inert; "Show Journal" in the menu still
  # regenerates, so the journal itself is never stale when opened deliberately.
  when "journal:regen"
    begin
      generateJournal()
    rescue => error
      alert("#{t("error.journal:open")} \n#{error.message}\n#{error.backtrace.join("\n")}")
    end

  when "savefile:reveal"
    begin
      # Reveals the file in Finder instead of launching an editor on it. The warning stays:
      # revealing puts the user one double-click away from editing, which is exactly the
      # situation it exists to flag.
      #
      # The warning is skipped once the user chose "don't ask again". That preference lives
      # in SwiftBar's own plugin variables, so it can be undone in
      # Settings > Plugins > Plugin Variables without needing a reset command here.
      proceed = true
      unless var_set?(ENV["VAR_SKIP_SAVEFILE_WARNING"])
        confirmed, dont_ask = confirm_with_skip_option(
          t("prompt.savefile.reveal.message"),
          title: t("prompt.savefile.reveal.title"),
          skip_label: t("prompt.savefile.reveal.skip")
        )
        # Only a Yes may persist, and only a Yes proceeds.
        proceed = confirmed
        save_plugin_var("VAR_SKIP_SAVEFILE_WARNING", "true") if confirmed && dont_ask
      end

      # No early `return` here: that would skip the saveJSON() at the end of this method,
      # discarding the running entry's latest tick for no reason.
      if proceed
        # Shellwords.escape is required: the data directory contains a space
        # ("Application Support"), and an unescaped path is split into several arguments,
        # which makes `open` fail silently.
        if File.exist?($SAVEFILE)
          `open -R #{Shellwords.escape($SAVEFILE)}`
        else
          alert("#{t("error.savefile:missing")} \n#{$SAVEFILE}")
        end
      end
    rescue => error
      alert("#{t("error.savefile:reveal")} \n#{error.message}\n#{error.backtrace.join("\n")}")
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

  # A journal reload arrives as a SwiftBar URL-scheme refresh, so the plugin is invoked
  # normally (no ARGV) with `journal` exported into the environment. Regenerate and exit
  # without touching the menu or the data — this is a side-channel, not a plugin run.
  #
  # !! REQUIRES SWIFTBAR >= 2.1.2 — see the note on "journal:regen" in actionHandler. On
  # 2.1.1 this never fires, because the `refreshplugin` endpoint does not exist yet.
  if ENV["journal"].to_s.strip.downcase == "regen"
    begin
      generateJournal()
    rescue => error
      alert("#{t("error.journal:open")} \n#{error.message}\n#{error.backtrace.join("\n")}")
    end
    exit
  end

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