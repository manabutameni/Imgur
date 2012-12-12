#!/bin/bash
# Requirements: basename, mktemp, curl, awk, sed, bash

# htmltemp holds .html file for quick, multiple searches
# logfile holds failed curl downloads
htmlname="$(basename $0)"
logname=$htmlname.log
htmltemp=$(mktemp -t ${htmlname}.XXXXX) || exit 1
logfile=$(mktemp -t ${logname}.XXXXX) || exit 1

folderexists="TRUE"
multiple_urls="FALSE"
sanitize="FALSE"
preserve="FALSE"
silent_flag="FALSE"
curl_args="-s"
image_name=""
clean=""
data_index=-1
count=0
url=
gallery_url=('') 

long_desc()
{
  cat << EOF
NAME
    imgur - a simple album downloader

SYNOPSIS
    bash imgur.bash [-cps] URL
    bash imgur.bash -m FILE
    After installation simply replace "bash imgur.bash" with "imgur"

DESCRIPTION
    This is a 100% Bash script used to download imgur albums while making
    sure that the order of the pictures is retained.

    The following options are available:

    -h        Show this message.
    -m <File> Download multiple albums found in <File>.
    -c        Clean nonalphanumeric characters from the album's name.
    -p        Preserve imgur's naming. (Warning! This will not retain order.)
    -s        Silent mode.

EXAMPLES
    bash imgur.bash http://imgur.com/a/fG58m#0
    bash imgur.bash reactiongifsarchive.imgur.com

AUTHOR
    manabutameni
    https://github.com/manabutameni/Imgur
EOF
}

short_desc()
{
  cat << EOF
usage: $0 [-cps] URL
usage: $0 [-m]  file
EOF
}

# ============================================================================ #
# Evaluate a floating point number expression.
#
# Floating point math courtesy of:
# http://www.linuxjournal.com/content/floating-point-math-bash
# ============================================================================ #
function float_eval()
{
  float_scale=2

  local stat=0
  local result=0.0
  if [[ $# -gt 0 ]]; then
    result=$(echo "scale=$float_scale; $*" | bc -q 2>/dev/null)
    stat=$?
    if [[ $stat -eq 0  &&  -z "$result" ]]; then stat=1; fi
  fi
  echo $result
  return $stat
}
# ============================================================================ #
# End float_eval function.
# ============================================================================ #

printf "[%60s]      \r" " "
function progress_bar()
{
  printf "[%60s] $1\045\r" " "
  printf "[%${2}s\r" " " | tr ' ' '#'
}

while getopts "hm:cps" OPTION
do
  case $OPTION in
    h)
      long_desc
      exit 0
      ;;
    m)
      # This will output all imgur ablum urls from plain text <File> into the
      # array $gallery_url. Note: urls must be separated by newline.
      multiple_urls="TRUE"
      gallery_url=( $(cat "$OPTARG") )
      ;;
    c)
      # Clean non alpha-numeric characters from album name.
      # Useful for the (rare) albums named !!!OMG$)(@@*$@$%@
      sanitize="TRUE"
      ;;
    p)
      # Preserve Imgur's naming scheme. Please note that this will not keep the
      # order of the images. While this does break the spirit of the script it
      # is included here for the sake of completion.
      preserve="TRUE"
      ;;
    s)
      # Run silently.
      curl_args="-s"
      silent_flag="TRUE"
      ;;
    ?)
      short_desc
      exit 0
  esac
done

if [[ "$multiple_urls" == "FALSE" ]]
then
  # set gallery_url to last argument if we're not downloading multiple albums.
  gallery_url[0]="${@: -1}"
fi

# make sure gallery_url isn't empty.
if [[ -z ${gallery_url[0]} ]]
then
  long_desc
  exit 1
fi

if [[ "$gallery_url[0]" =~ ".imgur.com" ]]
then
  curl -s "${gallery_url[0]}" > $htmltemp

  # Doing it this way allows for recursively searching the html for multiple
  # gallery URLs. Allowing for complete downloads of albums inside albums.
  gallery_url=( $(grep -oh "imgur.com/a/[a-zA-Z0-9]\{5\}" $htmltemp) )

  echo $main_url >> "permalink.txt"
fi

for url in ${gallery_url[@]}
do
  if [[ "$url" =~ "imgur.com/a/" ]]
  then
    # Download the html source to a temp file for quick parsing.
    curl -s $url > $htmltemp
    # ;exit is needed since sometimes data-title appears twice
    folder_name=$(awk -F\" '/data-title/ {print $6; exit}' $htmltemp)

    if [[ "$sanitize" == "TRUE" ]]
    then # remove special characters
      clean=${folder_name//_/} #turn / into _
      clean=${clean// /_} #turn spaces into _
      folder_name="${clean//[^a-zA-Z0-9_]/}" # remove all special chars
    else
      folder_name=$(sed 's/\//_/g' <<< $folder_name) # ensure no / chars
    fi

    if [[ "$preserve" == "TRUE" ]] || [[ -z "$folder_name" ]]
    then # Create a folder name based on the URL.
      folder_name=$(basename "$url" | sed 's/\#.*//g')
    fi

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

    # Save link to album in a text file with the images.
    echo "$url" >> "$folder_name"/"permalink.txt"

    # Get total number of images to properly display percent done.
    total_images=0
    for image_url in $(awk -F\" '/data-src/ {print $10}' $htmltemp | sed '/^$/d')
    do
      let total_images=$total_images+1
    done

    # Iterate over all images found.
    for image_url in $(awk -F\" '/data-src/ {print $10}' $htmltemp | sed '/^$/d')
    do
      # Some albums have the thumbnail images out of order, this fixes that.
      data_index=$(grep $image_url $htmltemp | awk -F\" '{print $12}')
      data_index=$(echo $data_index)
      let data_index=$data_index+1

      # Ensure no images are thumbnails.
      # Always works because all images that could be in $image_url are thumbnails.
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

      if [[ "$preserve" == "FALSE" ]]
      then # rename current file to force {1..11} sorting.
        new_image_name="$(printf %05d.%s ${image_name%.*} ${image_name##*.})"
        # brief expl:     force 5 digits   basename         extension
        mv "$folder_name"/"$image_name" "$folder_name"/"$new_image_name"
      else
        # This is needed so the next if statement can always get the right file.
        new_image_name="$image_name"
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
  else
    echo "Must be an album from imgur.com"
    exit 1
  fi
done

echo 

if [[ -s "$logfile" ]]
then
  echo "Exited with errors, check $logfile"
  exit 1
else
  echo "Finished with $count files downloaded."
  rm $htmltemp
  rm $logfile
  exit 0
fi
