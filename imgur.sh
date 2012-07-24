#!/bin/bash

# HTMLTEMP holds .html file for quick, multiple searches
# LOGFILE holds logs and failed curl downloads
HTMLNAME=`basename $0`
LOGNAME=$HTMLNAME.log
HTMLTEMP=`mktemp -t ${HTMLNAME}.XXXXX` || exit 1
LOGFILE=`mktemp -t ${LOGNAME}.XXXXX` || exit 1

MULTIPLE_URLS=false
FOLDEREXISTS=true # Assume the worst. Pragmatism not idealism.
SANITIZE=false
PRESERVE=false
CURL_ARGS=" "
IMAGE_NAME=""
DATA_INDEX=""
CLEAN=""

declare -a GALLERY_URL=(''); 

usage()
{
  cat << EOF

  usage: ./imgur-devel.sh [-cpsm] [file / URL] 
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
      MULTIPLE_URLS=true
      GALLERY_URL=( `cat "$OPTARG"` )
      ;;
    c)
      SANITIZE=true
      ;;
    p)
      PRESERVE=true
      ;;
    s)
      CURL_ARGS="-s "
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

if ! $MULTIPLE_URLS
then
  GALLERY_URL[0]="${@: -1}"
fi

if [ -z ${GALLERY_URL[0]} ]
then
  usage
  exit 1
fi

for url in ${GALLERY_URL[@]}
do
  if [[ "$url" =~ "imgur.com/a/" ]]
  then
    curl $CURL_ARGS $url > $HTMLTEMP
    # sed -n 1p is needed since sometimes data-title appears twice
    ALBUM_TITLE=$(awk -F\" '/data-title/ {print $6}' $HTMLTEMP | sed -n 1p)

    if $SANITIZE # remove special characters
    then
      CLEAN=${ALBUM_TITLE//_/} #turn / into _
      CLEAN=${CLEAN// /_} #turn spaces into _
      ALBUM_TITLE="${CLEAN//[^a-zA-Z0-9_]/}"
    else
      ALBUM_TITLE=`echo $ALBUM_TITLE | sed 's/\//_/g'`
    fi

    # if PRESERVE flag has been raised or $ALBUM_TITLE is empty
    if $PRESERVE || [[ -z "$ALBUM_TITLE" ]]
    then
      # Find the /a/ in the url and cut out the last bit of the url
      # for the folder name. Hope this works every time. :\
      ALBUM_TITLE=`echo ${url#*a} | sed 's/\///g' | cut -b 1-5`
    fi

    # It only takes one album named Pictures to possibly screw up
    # an entire folder. This will also save images to a new directory
    # if the script is used twice on the same album in the same folder.
    test -d "$ALBUM_TITLE" || FOLDEREXISTS=false
    if $FOLDEREXISTS
    then
      tempdir=`mktemp -d "$ALBUM_TITLE"_XXXXX` || exit 1
      ALBUM_TITLE=$tempdir
    else
      mkdir -p "$ALBUM_TITLE"
    fi

    # Get all images and ensure that they aren't thumbnails
    for IMAGE_URL in $(awk -F\" '/data-src/ {print $10}' $HTMLTEMP | sed '/^$/d')
    do
      # Some albums have the source images out of order, this fixes that.
      DATA_INDEX=`grep $IMAGE_URL $HTMLTEMP | awk -F\" '{print $12}'`

      # Ensure no images are thumbnails
      # Always works because all files currently in $IMAGE_URL are thumbnails.
      IMAGE_URL=`echo $IMAGE_URL | sed 's/s.jpg/.jpg/g'`

      if $PRESERVE
      then
        # Preserve imgur naming conventions.
        # Note: Does not guarantee images to be properly sorted.
        IMAGE_NAME=${IMAGE_URL:(-9):5}
      else
        IMAGE_NAME=`echo $DATA_INDEX`
      fi

      curl $CURL_ARGS $IMAGE_URL > "$ALBUM_TITLE"/$IMAGE_NAME.jpg ||
          echo "cURL failed to download :: $IMAGE_URL" >> $LOGFILE
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
echo

if [[ -s $LOGFILE ]]
then
  echo "exited with errors, check $LOGFILE"
  exit 1
else
  rm $HTMLTEMP
  rm $LOGFILE
  exit 0
fi
