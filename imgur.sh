#!/bin/bash

# Declarations
api="3c1a21006e8a7a9"
required=("bash" "curl" "bc")
version="0.99-b"

function main() {
  urls=("$@")
  for url in ${urls[@]}; do
    debug "url: $url"
  done
}

function api_call() {
  echo "${1}?client_id=${api}"
}

function long_desc() {
  cat << EOF
NAME
    imgur - a simple album downloader
    Version: $version

SYNOPSIS
    Download albums from imgur.com while retaining order.

OPTIONS
    -h        Show this message.
    -p        Preserve imgur's naming. (Warning! This will not retain order.)
    -s        Silent mode. Overrides debug mode.
    -d        Debug mode. Overrides stdout.

ERROR CODES
    1: General failure.
    6: Could not resolve host (cURL failure).
  127: Command not found.

AUTHOR
    manabutameni
    https://github.com/manabutameni/Imgur

EOF
exit 0
}

function short_desc() {
  stdout "usage: $0 [-ps] URL [URL]"
  exit 1
}

function update_check() {
  local new_version="$(curl -s https://raw.github.com/manabutameni/Imgur/master/version)"
  if [[ "$new_version" != "$version" ]]; then
    echo "+-----------------------------------------------------------------+"
    echo "|              There is an update for this script.                |"
    echo "|    https://raw.github.com/manabutameni/Imgur/master/imgur.sh    |"
    echo "| changelog: https://github.com/manabutameni/Imgur/commits/master |"
    echo "+-----------------------------------------------------------------+"
  fi
}

function systems_check() {
  for command in ${required[@]}; do
    command -v "$command" > /dev/null || {
      echo "$command not installed."; exit 127
    }
  done
}

function stdout() {
  # Normal output is suppressed when debug flag is raised.
  if [[ "$debug_flag" == "FALSE" ]] && [[ "$silent_flag" == "FALSE" ]]; then
    echo "$@"
  fi
}

function debug() {
  # Debug output is suppressed when silent flag is raised.
  if [[ "$debug_flag" == "TRUE" ]] && [[ "$silent_flag" == "FALSE" ]]; then
    echo "[$(echo "$(date +%s) - $time_start" | bc)] DEBUG: $@" 1>&2
  fi
}

function evaluate() {
  scale="$1"
  shift 1
  echo "$(echo "scale=$scale; $@" | bc -q 2> /dev/null)"
}

function progress_bar() {
  printf "[%60s]       \r" " " # clear each time in case of accidental input.
  printf "[%60s] $1\045\r" " " # Print off the percent completed passed to $1
  printf "[%${2}s>\r" " " | tr ' ' '=' # Print progress bar as '=>'
  if [[ "$2" == "60.00" ]]; then
    # Display completed progress bar.
    printf "[%${2}s]\r" " " | tr ' ' '='
  fi
}

while getopts ":hdsp" OPTION; do
  case $OPTION in
    h)
      long_desc
      exit 0
      ;;
    d)
      debug_flag=true
      ;;
    s)
      silent_flag=true
      ;;
    p)
      preserve_flag=true
      ;;
    *)
      stdout "Invalid option: '-$OPTARG'"
      short_desc
      ;;
  esac
done
shift $((OPTIND - 1))

systems_check 

if [[ "$debug_flag" == "TRUE" ]]; then
  update_check
fi

main $@
