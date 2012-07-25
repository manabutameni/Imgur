#!/bin/bash

# htmltemp holds .html file for quick, multiple searches
# logfile holds failed curl downloads
htmlname="${0##*/}"
logname=$htmlname.log
htmltemp=$(mktemp -t ${htmlname}.XXXXX) || exit 1
logfile=$(mktemp -t ${logname}.XXXXX) || exit 1

folderexists="TRUE" # Assume the worst. Pragmatism not idealism.
multiple_urls="FALSE"
sanitize="FALSE"
preserve="FALSE"
curl_args=("-# ")
image_name=""
data_index=""
clean=""
count=0

gallery_url=('') 

usage()
{
  cat << EOF

  usage: ./imgur-devel.sh [-cps] [-m file] URL
  This script is used solely to download imgur albums.

  OPTIONS:
    -h        Show this message.
    -m <File> Download multiple albums found in <File>.
    -c        Clean and Remove nonalphanumeric characters from the album's name.
    -p        Preserve imgur's naming. (Warning! This will not retain order.)
    -s        Silent mode.

EOF
}

while getopts "hm:cps" OPTION
do
  case $OPTION in
    h)
      usage
      exit 0
      ;;
    m)
      multiple_urls="TRUE"
      gallery_url=$(<"$OPTARG")
      ;;
    c)
      sanitize="TRUE"
      ;;
    p)
      preserve="TRUE"
      ;;
    s)
      curl_args=("-s ")
      ;;
    ?)
      echo
      echo "usage: $0 [-cps] URL..."
      echo "usage: $0 [-m]  file..."
      echo
      exit 1
      ;;
  esac
done


if [[ "$multiple_urls" == "FALSE" ]]
then
  gallery_url[0]="${@: -1}"
fi

if [[ -z ${gallery_url[0]} ]]
then
  usage
  exit 1
fi

for url in ${gallery_url[@]}
do
  if [[ "$url" =~ "imgur.com/a/" ]]
  then
    # Silent here because we are not downloading an image.
    curl -s $url > $htmltemp
    # ;exit is needed since sometimes data-title appears twice
    album_title=$(awk -F\" '/data-title/ {print $6; exit}' $htmltemp)

    if [[ "$sanitize" == "TRUE" ]] # remove special characters
    then
      clean=${album_title//_/} #turn / into _
      clean=${clean// /_} #turn spaces into _
      album_title="${clean//[^a-zA-Z0-9_]/}" # remove all special chars
    else
      album_title=$(sed 's/\//_/g' <<< $album_title) # ensure no / chars
    fi

    # if preserve flag has been raised or $album_title is empty
    if [[ "$preserve" == "TRUE" ]] || [[ -z "$album_title" ]]
    then
      # Find the /a/ in the url and cut out the last bit of the url
      # for the folder name. Hope this works every time. :/
      #album_title=$(sed -e 's/\///g' -e 's/#.*//g'  <<< ${url#*a})
      album_title=$(awk -F\/ '{print $5}' <<< "$url")
    fi

    # It only takes one album named Pictures to possibly screw up
    # an entire folder. This will also save images to a new directory
    # if the script is used twice on the same album in the same folder.
    test -d "$album_title" || folderexists="FALSE"
    if [[ "$folderexists" == "TRUE" ]]
    then
      tempdir=$(mktemp -d "$album_title"_XXXXX) || exit 1
      album_title="$tempdir"
    else
      mkdir -p "$album_title"
    fi

    # Get all images and ensure that they aren't thumbnails
    for image_url in $(awk -F\" '/data-src/ {print $10}' $htmltemp | sed '/^$/d')
    do
      # Some albums have the source images out of order, this fixes that.
      data_index=$(grep $image_url $htmltemp | awk -F\" '{print $12}')

      # Ensure no images are thumbnails
      # Always works because all files currently in $image_url are thumbnails.
      image_url=$(echo $image_url | sed 's/s.jpg/.jpg/g')

      if [[ "$preserve" == "TRUE" ]]
      then
        # Preserve imgur naming conventions.
        # Note: Does not guarantee images to be properly sorted.
        image_name=${image_url:(-9):5}
      else
        image_name=$(echo $data_index)
      fi

      curl $curl_args $image_url > "$album_title"/$image_name.jpg ||
        printf "failed to download: $image_url"

      let count=$count+1;
    done
  else
    echo
    echo "Must be an album from imgur.com"
    echo "usage: $0 [-cps] URL..."
    echo "usage: $0 [-m]  file..."
    echo
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
