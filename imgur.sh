#!/bin/bash
# Requirements: bash, basename, mktemp, curl, (g)awk, sed

# htmltemp holds .html file for quick, multiple searches
# logfile holds failed cURL downloads

# Declarations
htmlname="$(basename $0)"
logname=$htmlname.log
htmltemp=$(mktemp -t ${htmlname}.XXXXX) || exit 1
logfile=$(mktemp -t ${logname}.XXXXX) || exit 1

folderexists="TRUE"
multiple_urls="FALSE"
sanitize="FALSE"
preserve="FALSE"
silent_flag="FALSE"
debug_flag="FALSE"
curl_args="-s"
data_index=-1
count=0
gallery_url=('') 

# Functions
function debug()
{
  if [[ "$debug_flag" == "TRUE" ]] && [[ "$silent_flag" == "FALSE" ]]
  then
    echo DEBUG: $*
  fi
}

function long_desc()
{
  cat << EOF
NAME
    imgur - a simple album downloader

SYNOPSIS
    Download albums from imgur.com while retaining order.

OPTIONS
    -h        Show this message.
    -c        Clean nonalphanumeric characters from the album's name.
    -p        Preserve imgur's naming. (Warning! This will not retain order.)
    -s        Silent mode. Overrides debug mode.
    -d        Debug mode.

EXAMPLES
    bash imgur.bash http://imgur.com/a/fG58m#0
    bash imgur.bash reactiongifsarchive.imgur.com

AUTHOR
    manabutameni
    https://github.com/manabutameni/Imgur

EOF
exit 0
}

function short_desc()
{
  cat << EOF
usage: $0 [-cps] URL [URL]
EOF
exit 1
}

function parse_folder_name()
{
  temp_folder_name="$(awk -F\" '/data-title/ {print $6; exit}' $htmltemp)"

  if [[ "$sanitize" == "TRUE" ]]
  then # remove special characters
    clean=${temp_folder_name//_/} #turn / into _
    clean=${clean// /_} #turn spaces into _
    temp_folder_name="${clean//[^a-zA-Z0-9_]/}" # remove all special chars
  else
    temp_folder_name=$(sed 's/\//_/g' <<< $temp_folder_name) # ensure no / chars
  fi

  if [[ "$preserve" == "TRUE" ]] || [ -z "$temp_folder_name" ]
  then # Create a name for a folder name based on the URL.
    temp_folder_name=$(basename "$url" | sed 's/\#.*//g')
  fi
  echo $temp_folder_name
}

function float_eval()
{
  # Evaluate a floating point number expression.
  echo "$(echo "scale=2; $*" | bc -q 2> /dev/null)"
}

function progress_bar()
{
  printf "[%60s]       \r" " " # clear each time in case of accidental input.
  printf "[%60s] $1\045\r" " " # Print off the percent completed passed to $1
  printf "[%${2}s>\r" " " | tr ' ' '=' # Print progress bar as '=>'
  if [[ $2 == "60.00" ]]
  then #Display completed progress bar.
    printf "[%${2}s]\r" " " | tr ' ' '='
  fi
}

# Option Parsing
while getopts ":dhcps" OPTION
do
  case $OPTION in
    d)
      # print debugging messages
      debug_flag="TRUE"
      ;;
    h)
      long_desc
      ;;
    c)
      # Clean non alpha-numeric characters from album name.
      # Useful for the (rare) albums named !!!$)(@@*$@$%@
      debug Clean Flag Set
      sanitize="TRUE"
      ;;
    p)
      # Preserve Imgur's naming scheme. Please note that this will not keep the
      # order of the images. While this does break the spirit of the script it
      # is included here for the sake of completion.
      debug Preserve Flag Set
      preserve="TRUE"
      ;;
    s)
      # Run silently.
      debug Silent Flag Set
      curl_args="-s"
      silent_flag="TRUE"
      ;;
    '?' | *)
      echo "Invalid option: -$OPTARG" >&2
      short_desc
      ;;
  esac
done
shift $((OPTIND - 1))

gallery_url=("$@")

if [[ $debug_flag == "TRUE" ]]
then
  for (( i = 0 ; i < ${#@} ; i++ ))
  do
    debug gallery_url[$i] '=' ${gallery_url[$i]}
  done
fi

# make sure gallery_url isn't empty.
if [[ -z ${gallery_url[0]} ]]
then
  debug '$gallery_url[0] is empty'
  short_desc
  exit 1
fi

# Program Begins
for url in ${gallery_url[@]}
do
  debug '$url = ' $url
  count=0 # Reset counter
  if [[ "$url" =~ "imgur.com/a/" ]]
  then
    # Download the html source to a temp file for quick parsing.
    curl -s "$url" > $htmltemp
    debug '$htmltemp = ' $htmltemp
    # ;exit is needed since sometimes data-title appears twice

    folder_name="$(parse_folder_name)"

    # It only takes one album named Pictures to possibly screw up
    # an entire folder. This will also save images to a new directory
    # if the script is used twice on the same album in the same folder.
    test -d "$folder_name" || folderexists="FALSE"

    if [[ "$folderexists" == "TRUE" ]] 
    then
      tempdir=$(mktemp -d "$folder_name"_XXXXX) || exit 1
      folder_name="$tempdir"
    else
      mkdir -p "$folder_name"
    fi

    debug '$folder_name = ' $folder_name

    # Save link to album in a text file with the images.
    echo "$url" >> "$folder_name"/"permalink.txt"

    # Get total number of images to properly display percent done.
    total_images=0
    for image_url in $(awk -F\" '/data-src/ {print $10}' $htmltemp | sed '/^$/d')
    do
      let total_images=$total_images+1
    done
    debug '$total_images = ' $total_images

    # Iterate over all images found.
    for image_url in $(awk -F\" '/data-src/ {print $10}' $htmltemp | sed '/^$/d')
    do
      # Some albums have the thumbnail images out of order in the html source,
      # this fixes that.
      data_index="$(grep $image_url $htmltemp | awk -F\" '{print $12}')"
      # data_index=$(echo $data_index)
      let data_index=$data_index+1

      # Ensure no images are thumbnails.
      # Always works because all images that could be in $image_url are currently
      # thumbnails.
      image_url=$(sed 's/s.jpg/.jpg/g' <<< "$image_url")

      if [[ "$preserve" == "TRUE" ]]
      then # Preserve imgur naming conventions.
        image_name=$(basename "$image_url")
      else # name images based on index value.
        image_name=$data_index.jpg
      fi

      # This is where the file is actually downloaded
      curl $curl_args $image_url > "$folder_name"/$image_name ||
        printf "failed to download: $image_url \n" >> $logfile

      if [[ "$preserve" == "TRUE" ]]
      then # rename current file to force {1..11} sorting.
        # This is needed so the next if statement can always get the right file.
        new_image_name="$image_name"
      else
        new_image_name="$(printf %05d.%s ${image_name%.*} ${image_name##*.})"
        # brief expl:     force 5 digits   basename         extension
        mv "$folder_name"/"$image_name" "$folder_name"/"$new_image_name"
      fi

      # Read the first three bytes of the file and see if they contain "GIF"
      # Currently unsure if this will work 100% of the time, but it was the
      # best solution I knew of without forcing people to download imagemagick.
      if [[ $(head -c 3 "$folder_name"/"$new_image_name") == "GIF" ]]
      then # rename the image with the proper extension.
        mv "$folder_name"/"$new_image_name" \
          "$folder_name"/"$(basename $new_image_name .jpg).gif"
      fi
      
      let count=$count+1;
      if [[ $silent_flag == "FALSE" && $count != 0 ]]
      then # display download progress.
        percent=$(float_eval "100 * $count / $total_images")
        percent=${percent/.*}
        prog=$(float_eval "60 * $count / $total_images")
        if [[ $percent =~ ^[0-9]+$ ]]
        then
          progress_bar $percent $prog
        fi
      fi
    done
    if [[ "$silent_flag" == "FALSE" ]]
    then # Echo output
      echo
      echo "Finished with $count files downloaded."
    fi
  else
    echo "Must be an album from imgur.com"
    exit 1
  fi
done

if [[ -s "$logfile" ]]
then
  echo "Exited with errors, check $logfile"
  exit 1
else
  # Cleaning up
  rm $htmltemp
  rm $logfile
  exit 0
fi
