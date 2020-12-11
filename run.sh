#!/usr/bin/env bash

# Name:     Youtube-DL Interface
# Version:  5.1.1
# Date:     2020-12-09

_MEDIA="media"
_AUDIO="audio"
_VIDEO="video"
_DESTINATION="$_MEDIA/$_VIDEO"

# Indicates which function to call
_FUNCTION="downloadVideo"

_LINKS="links.lnk"
_LOG="/tmp/youtube-dl.log"

function checkInternet() {
  wget --quiet --spider "google.com" && ping -c 1 "google.com" >/dev/null 2>&1
  return $?
}

function createScenario() {
  log "--info" "Creating scenario."

  mkdir --parents "$_MEDIA/$_AUDIO"
  mkdir --parents "$_MEDIA/$_VIDEO"
  mkdir --parents ".$_MEDIA/$_AUDIO"
  mkdir --parents ".$_MEDIA/$_VIDEO"
  [[ ! -f "$_LINKS" ]] && resetLinks
}

function download() {
  local _destination
  _destination="$1"

  local _filename
  _filename="$2"

  local _link
  _link="$3"

  local _format
  _format="bestvideo[height<=1080]+bestaudio/bestvideo+bestaudio/best"

  local _output
  _output="$_destination/$_filename"

  log "--info" "Downloading '$_filename' from '$_link'."
  notify "Downloading '$_filename' from '$_link'."

  if ./youtube-dl --quiet --ignore-errors --no-warnings --no-playlist --format "$_format" --output "$_output" --merge-output-format "mkv" "$_link"; then
    log "--info" "Done '$_filename'."
    notify "Done '$_filename'."
    return 0
  else
    log "--error" "Failed: '$_filename'."
    notify "Failed: '$_filename'."
    return 1
  fi
}

function downloadAudio() {
  local _destination
  _destination="$1"

  local _link
  _link="$2"

  local _data
  _data="$(./youtube-dl --ignore-errors --no-warnings --get-filename --no-playlist "$_link" -o "[%(artist)s][%(track)s][%(uploader)s][%(title)s]")"

  local _artist
  _artist=$(echo "$_data" | cut -d '[' -f 2 | cut -d ']' -f 1)
  [[ "$_artist" == "NA" ]] && _artist=$(echo "$_data" | cut -d '[' -f 4 | cut -d ']' -f 1)

  local _title
  _title=$(echo "$_data" | cut -d '[' -f 3 | cut -d ']' -f 1)
  [[ "$_title" == "NA" ]] && _title=$(echo "$_data" | cut -d '[' -f 5 | cut -d ']' -f 1)

  local _output
  _output="$_destination/$_artist - $_title.%(ext).s"

  log "--info" "Downloading '$_artist - $_title'."
  notify "Downloading '$_artist - $_title'."

  # Automatically uses '--audio-format best'
  if ./youtube-dl --quiet --ignore-errors --no-warnings --extract-audio --audio-quality 0 --output "$_output" "$_link"; then
    log "--info" "Done '$_artist - $_title'."
    notify "Done '$_artist - $_title'."
    return 0
  else
    log "--error" "Failed: '$_artist - $_title'."
    notify "Failed: '$_artist - $_title'."
    return 1
  fi
}

function downloadPlaylist() {
  local _destination
  _destination="$1"

  local _link
  _link="$2"

  local _data
  mapfile -t _data < <(./youtube-dl --ignore-errors --no-warnings --get-filename --output "[%(playlist_title)s][%(title)s][https://www.youtube.com/watch?v=%(id)s]" "$_link")

  for _i in "${_data[@]}"; do
    local _playlistName
    _playlistName="$(echo "$_i" | cut -d '[' -f 2 | cut -d ']' -f 1)"

    local _name
    _name="$(echo "$_i" | cut -d '[' -f 3 | cut -d ']' -f 1)"

    local _url
    _url="$(echo "$_i" | cut -d '[' -f 4 | cut -d ']' -f 1)"

    download "$_destination/$_playlistName" "$_name" "$_url" &
  done

  return 0
}

function downloadVideo() {
  local _destination
  _destination="$1"

  local _link
  _link="$2"

  local _name
  _name="$(./youtube-dl --ignore-errors --no-warnings --no-playlist --get-filename --output "%(title)s" "$_link")"
  _name="$(echo "$_name" | tr "/" "_")"

  download "$_destination" "$_name" "$_link" &
  return 0
}

function log() {
  if [[ $# -ne 2 ]]; then
    log "--error" "Wrong call of function: 'log'."
    return 1
  fi

  local _message

  case "$1" in
  "")
    _message="$2"
    ;;
  "--error")
    _message="[ E ]: $2"
    ;;
  "--info")
    _message="[ I ]: $2"
    ;;
  "--warn")
    _message="[ W ]: $2"
    ;;
  *)
    _message="[ ? ]: $2"
    ;;
  esac

  echo "[ $(date +%T) ] $_message" | tee "$_LOG"
  return 0
}

function notify() {
  if [[ $# -gt 0 ]]; then
    notify-send "Youtube-DL" "$*"
    return 0
  else
    log "--error" "Wrong call of function 'notify'"
    return 1
  fi
}

function readFile() {
  while read -r _line; do
    [[ -z "$_line" ]] && continue

    case "$_line" in
    "[AUDIO]")
      _DESTINATION="$_MEDIA/$_AUDIO"
      log "--info" "Changing destination to '$_DESTINATION'."

      _FUNCTION="downloadAudio"
      log "--info" "Changing function to '$_FUNCTION'."
      ;;
    "[CLEAR]")
      log "--info" "Resetting the '$_LINKS' file."
      resetLinks
      ;;
    "[HIDE]")
      [[ -n "$(echo "$_MEDIA" | cut -d "." -f 1)" ]] && _MEDIA=".$_MEDIA"
      log "--info" "Changing visibility to '$_MEDIA'"
      ;;
    "[NORMAL]")
      _MEDIA="$(echo "$_MEDIA" | cut -d "." -f 2)"
      log "--info" "Changing visibility to '$_MEDIA'"
      ;;
    "[PLAYLIST]")
      _DESTINATION="$_MEDIA/$_VIDEO"
      log "--info" "Changing destination to '$_DESTINATION'."

      _FUNCTION="downloadPlaylist"
      log "--info" "Changing function to '$_FUNCTION'."
      ;;
    "[VIDEO]")
      _DESTINATION="$_MEDIA/$_VIDEO"
      log "--info" "Changing destination to '$_DESTINATION'."

      _FUNCTION="downloadVideo"
      log "--info" "Changing function to '$_FUNCTION'."
      ;;
    *)
      # Runs the correct function
      "$_FUNCTION" "$_DESTINATION" "$_line" &
      ;;
    esac
  done <"$_LINKS"
}

function resetLinks() {
  {
    echo "[NORMAL]"
    echo "[AUDIO]"
    echo "[VIDEO]"
    echo "[PLAYLIST]"
    echo "[HIDE]"
    echo "[AUDIO]"
    echo "[VIDEO]"
    echo "[PLAYLIST]"
    echo "[CLEAR]"
  } >"$_LINKS"

  chmod 664 "$_LINKS"
  return 0
}

function showHelp() {
  echo "Youtube-DL Interface"
  echo "    It has fully automated operation and can be run either from the"
  echo "    command line or from the graphical interface."
  echo
  echo "SYNTAX"
  echo "    $0 [option]"
  echo
  echo "OPTIONS"
  echo "    -h, --help"
  echo "        Show this help content."
  echo
  echo "    -l, --log"
  echo "        Show the log content."
  echo
  echo "    N/A"
  echo "        Runs in auto mode."
  echo
  echo "HOW IT WORKS"
  echo "    If it is the first time you are running, it must be run from the"
  echo "    terminal to check and solve the dependencies. Also, it will try to"
  echo "    download the newest version of the youtube-dl binary."
  echo
  echo "    To use, fill the '$_LINKS' file with the links that should be"
  echo "    downloaded (one link per line), then run this script with no argument."
  echo
  echo "    The tags in '$_LINKS' indicates how and where to download the links."
  echo "    See more below."
  echo
  echo "TAGS"
  echo "     [AUDIO] - The links below this tag will have the audio extracted."
  echo "               It only works for single files."
  echo "     [CLEAR] - Indicates that the links file should be cleaned. This tag"
  echo "               should be in the end to avoid errors."
  echo "      [HIDE] - The links below this tag will be downloaded to the hidden"
  echo "               folder. Links directly below this tag can not work as"
  echo "               expected."
  echo "    [NORMAL] - The links below this tag will be downloaded to the videos"
  echo "               folder. Links directly below this tag can not work as"
  echo "               expected."
  echo "  [PLAYLIST] - Indicates to download the entire playlist. The files will"
  echo "               be placed in a folder with the same name as the playlist."
  echo "               This folder will be placed inside the directory indicated"
  echo "               by the [NORMAL] and [HIDE] tags, because of this, it needs"
  echo "               to appear after these tags. It only for Youtube links."
  echo "     [VIDEO] - Indicates to download a single video."
  echo
  echo "    Tags can be repeated as many times as needed."
  echo
  echo "ERRORS CODE"
  echo "    1 - There are dependencies but cannot install then unless it is"
  echo "        running through the terminal."
  echo "    2 - There are dependencies but cannot install then with sudo."
  echo "    3 - There is no internet connection."
  echo "    4 - Can not install Youtube-DL and there is no local version available."
  echo
  echo "REQUIREMENTS"
  echo "    -        less: crt viewer"
  echo "    -      ffmpeg: video converter"
  echo "    - notify-send: notification sender"
  echo "    -        ping: icmp sender"
  echo "    -        wget: internet downloader"
  echo
  echo "COMPATIBILITY"
  echo "    Debian based distros (fully)."
  echo "    It can work in other distros as far them supplies all dependencies."
  echo
  echo "KNOWN BUG"
  echo "    - The file '$_LINKS' must end with a blank line, otherwise the last"
  echo "      command will not run."
  echo
  echo "[ Q ] - Quit"
  echo
}

function solveDependencies() {
  log "--info" "Checking dependencies."

  if ! hash ffmpeg 2>/dev/null || ! hash less 2>/dev/null || ! hash notify-send 2>/dev/null || ! hash ping 2>/dev/null || ! hash wget 2>/dev/null; then
    if [[ $UID -eq 0 ]]; then
      apt-get update >/dev/null 2>&1
      apt-get install ffmpeg less libnotify-bin ping wget >/dev/null 2>&1
    elif [[ $SHLVL -le 1 ]]; then
      log "--error" "Run it in terminal to install the dependencies."
      notify "Run it in terminal to install the dependencies."
      exit 1
    elif hash sudo 2>/dev/null; then
      sudo apt-get update >/dev/null 2>&1
      sudo apt-get install ffmpeg libnotify-bin >/dev/null 2>&1
    else
      log "--error" "Run it in terminal as root to install the dependencies."
      exit 2
    fi
  else
    log "--info" "No dependencies found."
  fi

  return 0
}

function updateYoutubeDL() {
  local _flag
  _flag="/tmp/youtube-dl.flag"

  if [[ -f "$_flag" && -f "youtube-dl" ]]; then
    log "--info" "Youtube-DL is up to date."
    notify "Youtube-DL is up to date."
    return 0
  fi

  log "--info" "Updating Youtube-DL."
  notify "Updating Youtube-DL."

  if wget --quiet "https://yt-dl.org/downloads/latest/youtube-dl" --output-document="youtube-dl-new"; then
    mv "youtube-dl-new" "youtube-dl"
    chmod 766 "youtube-dl"
    touch "$_flag"
    log "--info" "Youtube-DL is up to date."
    notify "Youtube-DL is up to date."
    return 0
  else
    log "--error" "Failed to update Youtube-DL."
    notify "Failed to update Youtube-DL."
    [[ -e "youtube-dl-new" ]] && rm "youtube-dl-new"
  fi

  if [[ -e "youtube-dl" ]]; then
    log "--warn" "Using local version of Youtube-DL."
    notify "Using local version of Youtube-DL."
    return 0
  else
    log "--error" "There is no local version available."
    notify "There is no local version available."
    exit 4
  fi
}

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
  showHelp | less
  exit 0
elif [[ "$1" == "-l" || "$1" == "--log" ]]; then
  less "$_LOG" 2>/dev/null
  exit 0
elif ! checkInternet; then
  log "--error" "System is offline."
  notify "System is offline."
  exit 3
fi

createScenario
solveDependencies
updateYoutubeDL
readFile

exit 0
