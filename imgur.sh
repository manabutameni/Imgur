#!/bin/bash
# Requirements: bash, mktemp, basename, curl, (g)awk, sed, sort, bc

# Declarations
version="0.97"
htmlname="$(basename $0)"
logname="$htmlname"
htmltemp="$(mktemp -t ${htmlname}.XXXXX).html" || exit 1
time_start="$(date +%s)"
preserve_flag="FALSE"
silent_flag="FALSE"
debug_flag="FALSE"

function main()
{
  debug "Passed arguments to main: $@"
  debug "html temp = $htmltemp"

  album_urls=(`parse_album_urls "$@"`)
  debug "Full album_urls list: ${album_urls[@]}"
  album_urls=(`remove_duplicate_array_elements "${album_urls[@]}"`)
  debug "Truncated album_urls: ${album_urls[@]}"

  # make sure album_urls isn't empty.
  if [[ -z "${album_urls[0]}" ]]
  then
    debug "album_urls[0] is empty" 
    short_desc
    exit 1
  fi

  # Program Begins
  for url in "${album_urls[@]}"
  do
    count=0 # Reset counter
    url="imgur.com/a/$url"

    # Download the html source to a temp file for quick parsing.
    curl -s "$url" > "$htmltemp"

    # Create a new folder for the images.
    folder_name="$(parse_folder_name)"
    stdout "$folder_name"
    debug "folder_name = $folder_name" 

    # Save link to album in a text file with the images.
    echo "$url" >> "$folder_name/permalink.txt"
    debug "permalink: $folder_name/permalink.txt"

    # Get total number of images to properly display percent done.
    total_images=0
    for image_url in $(awk -F\" '/data-src/ {print $10}' "$htmltemp" | sed '/^$/d')
    do
      let "total_images = $total_images + 1"
    done
    let "persistent_image_count += $total_images"
    debug "Total images = $total_images"

    # Iterate over all images found.
    for image_url in $(awk -F\" '/data-src/ {print $10}' "$htmltemp" | sed '/^$/d')
    do
      # Some albums have the thumbnail images out of order in the html source,
      # this fixes that.
      data_index_new="$(grep -m 2 $image_url $htmltemp | awk -F\" '{print $12}')"
      data_index_new="$(echo $data_index_new)" # necessary to remove preceding newline.
      if [[ "$data_index_new" == "" ]]
      then
        let "data_index_new = $data_index + 1"
      fi
      data_index="$(echo $data_index_new)"
      # let "data_index = $data_index + 1"
      debug "data_index: $data_index"

      # Ensure no images are thumbnails.
      # Always works because all images that could be in $image_url are currently
      # thumbnails.
      image_url=$(sed 's/s.jpg/.jpg/g' <<< "$image_url")
      debug "image_url dethumbnailed: $image_url"

      if [[ "$preserve_flag" == "TRUE" ]]
      then # Preserve imgur naming conventions.
        image_name="$(basename "$image_url")"
      else # name images based on index value.
        image_name="$data_index.jpg"
      fi

      # This is where the file is actually downloaded
      # If a download fail we are going to give a best effort and place links to
      debug "Downloading image: $(($count+1))"
      if [[ "$silent_flag" == "TRUE" ]]
      then
        curl_args="-s"
      fi
      debug "curl $curl_args $image_url > $folder_name/$image_name"
      curl "$curl_args" "$image_url" > "$folder_name"/"$image_name" ||
        debug "failed to download: $image_url \n"

      if [[ "$preserve_flag" == "TRUE" ]]
      then # rename current file to force {1..11} sorting.
        # This is needed so the next if statement can always get the right file.
        new_image_name="$image_name"
        debug "Preserved Image Name: $new_image_name"
      else
        # brief expl:     force 5 digits   basename         extension
        number_of_placeholders="$(grep -o "[0-9]" <<< "$total_images" | wc -l)"
        number_of_placeholders="$(echo $number_of_placeholders)"
        new_image_name="$(printf "%0$(echo $number_of_placeholders)d.%s" ${image_name%.*} ${image_name##*.})"
        if [[ "$image_name" != "$new_image_name" ]]
        then
          mv "$folder_name"/"$image_name" "$folder_name"/"$new_image_name"
        fi
        debug "New Image Name: $new_image_name"
      fi

      # Read the mimetype to ensure proper image renaming.
      if [[ "$(file --brief --mime "$folder_name"/"$new_image_name" | awk -F\; '{print $1}')" == "image/gif" ]]
      then # rename the image with the proper extension.
        mv "$folder_name"/"$new_image_name" \
          "$folder_name"/"$(basename $new_image_name .jpg).gif"
      fi

      let "count = $count + 1"
      if [[ "$silent_flag" == "FALSE" && "$count" != 0 && "$debug_flag" == "FALSE" ]]
      then # display download progress.
        percent="$(evaluate 2 "100 * $count / $total_images")"
        percent="${percent/.*}"
        prog="$(evaluate 2 "60 * $count / $total_images")"
        if [[ "$percent" =~ ^[0-9]+$ ]]
        then
          progress_bar "$percent" "$prog"
        fi
        debug "Progress: $percent%"
      fi
    done
    stdout ""
  done

  stdout ""
  stdout "Finished with $persistent_image_count files downloaded."
  debug "Completed successfully."
  exit 0
}
function long_desc()
{
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
function short_desc()
{
  stdout "usage: $0 [-ps] URL [URL]"
  exit 1
}
function update_check()
{
  new_version="$(curl -s https://raw.github.com/manabutameni/Imgur/master/version)"
  debug "Github Script Version: $new_version"
  if [[ "$new_version" > "$version" ]]
  then
    debug "======"
    debug "There is an update for this script."
    if [[ "$(command -v imgur)" != "" ]]
    then
      debug "Please update with the following shell command:"
      debug "curl -sL https://raw.github.com/manabutameni/Imgur/master/imgur.sh -o `command -v imgur`"
      debug "======"
    fi
  fi
}
function systems_check()
{
  failed="FALSE"
  command -v bash   > /dev/null || { failed="TRUE"; echo Bash   not installed.; }
  command -v mktemp > /dev/null || { failed="TRUE"; echo mktemp not installed.; }
  command -v curl   > /dev/null || { failed="TRUE"; echo cURL   not installed.; }
  command -v awk    > /dev/null || { failed="TRUE"; echo awk    not installed.; }
  command -v sed    > /dev/null || { failed="TRUE"; echo sed    not installed.; }
  command -v sort   > /dev/null || { failed="TRUE"; echo sort   not installed.; }
  command -v bc     > /dev/null || { failed="TRUE"; echo bc     not installed.; }
  if [[ "$failed" == "TRUE" ]]
  then
    exit 127
  fi
  debug 'All system requirements met.'
  debug "Local Script Version: $version"
}
function stdout()
{
  # Normal output is suppressed when debug flag is raised.
  if [[ "$debug_flag" == "FALSE" ]] && [[ "$silent_flag" == "FALSE" ]]
  then
    echo "$@"
  fi
}
function debug()
{
  # Debug output is suppressed when silent flag is raised.
  if [[ "$debug_flag" == "TRUE" ]] && [[ "$silent_flag" == "FALSE" ]]
  then
    echo "[$(echo "$(date +%s) - $time_start" | bc)] DEBUG: $@" 1>&2
  fi
  curl_args="-s"
}
function parse_album_urls()
{
  # Populate album_urls with imgur albums. 
  main_url=("$@")
  debug "urls to parse: ${main_url[@]}"
  for (( i = 0 ; i < "${#@}" ; i++ )); do
    debug "Downloading html source (${main_url[$i]})..."
    curl -sL "${main_url[$i]}" > "$htmltemp" || exit 6
    debug "Parsing HTML..."

    # 1) pull imgur album links
    # 2) print out everything after /a/ but before anything else like /all#
    album_urls+=" $(sed "s,>,\\`echo -e '\n\r'`,g" "$htmltemp" \
        | grep 'imgur.com/a/' \
        | awk -F'//imgur.com/a/' '{print $2}' \
        | awk -F'/all' '{print $1}' \
        | sed 's,[^a-zA-Z0-9],,g' \
        | xargs) "
  done
  debug "Urls parsed: ${album_urls[@]}"
  echo "${album_urls[@]}"
}
function parse_folder_name()
{
  # ;exit is needed since sometimes data-title appears twice
  temp_folder_name="$(awk -F\" '/data-title/ {print $6; exit}' $htmltemp)"
  temp_folder_name="$(sed 's,&#039;,,g' <<< "$temp_folder_name")"
  temp_folder_name="$(sed 's,\&amp;,\&,g' <<< "$temp_folder_name")"
  temp_folder_name="$(sed 's,[^a-zA-Z0-9&],_,g' <<< "$temp_folder_name")"
  if [[ "$preserve_flag" == "TRUE" ]] || [[ "$temp_folder_name" == "" ]]
  then # Create a name for a folder name based on the URL.
    temp_folder_name="$(basename "$url" | sed 's/\#.*//g')"
  fi

  # It only takes one album named Pictures to possibly screw up
  # an entire folder. This will also save images to a new directory
  # if the script is used twice on the same album in the same folder.
  folderexists="TRUE"
  test -d "$temp_folder_name" || folderexists="FALSE"

  if [[ "$folderexists" == "TRUE" ]]
  then
    tempdir="$(mktemp -d "$temp_folder_name"_XXXXX)" || exit 1
    temp_folder_name="$tempdir"
  fi

  mkdir -p "$temp_folder_name"
  echo "$temp_folder_name"
}
function remove_duplicate_array_elements()
{
  array=($@)
  printf '%s\n' "${array[@]}" | sort -u
}
function evaluate()
{
  # Evaluate a floating point number expression.
  # There must be an argument and it must be an integer.
  # Example: evaluate 3 "4 * 5.2" ; # would set the scale to 3
  scale="$1"
  shift 1
  echo "$(echo "scale=$scale; $@" | bc -q 2> /dev/null)"
}
function progress_bar()
{
  printf "[%60s]       \r" " " # clear each time in case of accidental input.
  printf "[%60s] $1\045\r" " " # Print off the percent completed passed to $1
  printf "[%${2}s>\r" " " | tr ' ' '=' # Print progress bar as '=>'
  if [[ "$2" == "60.00" ]]
  then # Display completed progress bar.
    printf "[%${2}s]\r" " " | tr ' ' '='
  fi
}

# Option Parsing
while getopts ":hdps" OPTION
do
  case $OPTION in
    h)
      long_desc
      ;;
    d)
      # print debugging messages
      debug_flag="TRUE" && debug "Debug Flag Raised"
      ;;
    p)
      # Preserve Imgur's naming scheme. Please note that this will not keep the
      # order of the images. While this does break the spirit of the script it
      # is included here for the sake of completion.
      preserve_flag="TRUE" && debug "Preserve Flag Raised" 
      ;;
    s)
      # Run silently.
      silent_flag="TRUE" && debug "Silent Flag Raised" 
      ;;
    '?' | *)
      stdout "Invalid option: -$OPTARG" >&2
      short_desc
      ;;
  esac
done
shift $((OPTIND - 1))

systems_check 
if [[ "$debug_flag" == "TRUE" ]]
then # Run a check to see if this script is the latest version.
  update_check
fi
main $@
