#!/bin/bash

ITERATE=0
CURL_ARGS=""
MULTIPLE_URLS=false
SANITIZE=false
PRESERVE=false
TEMPNAME=`basename $0`
TEMPFILE=`mktemp -t ${TEMPNAME}.XXXXX` || exit 1

declare -a GALLERY_URL=(''); 
IMAGE=

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
      echo "usage: $0 [-m] file..."
      echo
      exit 1
      ;;
  esac
done

if ! $MULTIPLE_URLS
then
  GALLERY_URL[0]="${@: -1}"
fi

for url in ${GALLERY_URL[@]}
do
  ITERATE=0
  if [[ "$url" =~ "imgur.com" ]]
  then
    curl $CURL_ARGS$url > $TEMPFILE
    # sed -n 1p is needed since sometimes data-title appears twice
    ALBUM_TITLE=$(awk -F\" '/data-title/ { print $6 }' $TEMPFILE | sed -n 1p)

    if $SANITIZE
    then
      CLEAN=${ALBUM_TITLE//_/}
      CLEAN=${CLEAN// /_}
      ALBUM_TITLE=${CLEAN//[^a-zA-Z0-9_]/}
    fi

    if $PRESERVE
    then
      ALBUM_TITLE=
    fi

    if [ -z "$ALBUM_TITLE" ]
    then
      # Find the /a/ in the url and cut out the last bit of the url
      # for the folder name
      ALBUM_TITLE=`echo ${url#*a} | sed 's/\///g' | cut -b 1-5`
    fi

    # Get all images and ensure that they aren't thumbnails
    for IMAGE in $(awk -F\" '/data-src/ { print $10 }' $TEMPFILE | 
                   sed '/^$/d' | sed 's/s.jpg/.jpg/g')
    do
      # Determine the name of the image
      # Special Note: Some albums' source has the images out of order?
      if $PRESERVE
      then
        ITERATE=${IMAGE:(-9):5}
      else
        let ITERATE=$ITERATE+1;
      fi

      mkdir -p "$ALBUM_TITLE"
      curl $CURL_ARGS$IMAGE > "$ALBUM_TITLE"/$ITERATE.jpg
    done
  else
    echo
    echo "Must be an album from imgur.com"
    echo "usage: $0 [-cps] URL..."
    echo "usage: $0 [-m] file..."
    echo
    exit 1
  fi
done

rm $TEMPFILE
