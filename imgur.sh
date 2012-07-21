#!/bin/bash

CURL_ARGS=""
MULTIPLE_URLS=false
FOLDEREXISTS=true # Assume the worst. Pragmatism not idealism.
ITERATE=0
SANITIZE=false
PRESERVE=false
TEMPNAME=`basename $0`
TEMPFILE=`mktemp -t ${TEMPNAME}.XXXXX` || exit 1

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

if [ -z ${GALLERY_URL[0]} ]
then
  usage
  exit 1
fi

for url in ${GALLERY_URL[@]}
do
  if [[ "$url" =~ "imgur.com" ]]
  then
    curl $CURL_ARGS$url > $TEMPFILE
    # sed -n 1p is needed since sometimes data-title appears twice
    ALBUM_TITLE=$(awk -F\" '/data-title/ { print $6 }' $TEMPFILE | sed -n 1p)

    if $SANITIZE # remove special characters
    then
      CLEAN=${ALBUM_TITLE//_/}
      CLEAN=${CLEAN// /_}
      ALBUM_TITLE=${CLEAN//[^a-zA-Z0-9_]/}
    fi

    if $PRESERVE # preserve imugr's naming convention for folder
    then
      ALBUM_TITLE=
    fi

    if [ -z "$ALBUM_TITLE" ] # if [ ALBUM_TITLE is empty ]
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

    ITERATE=0
    # Get all images and ensure that they aren't thumbnails
    for IMAGE in $(awk -F\" '/data-src/ { print $10 }' $TEMPFILE | 
      sed '/^$/d' | sed 's/s.jpg/.jpg/g')
    do
      # Determine the name of the image
      # Special Note: Some albums' html source has the images out of order?
      if $PRESERVE
      then
        # Preserve imgur naming conventions. Note: Does not guarantee
        # images to be properly sorted.
        ITERATE=${IMAGE:(-9):5}
      else
        # Give the images an ascending name
        let ITERATE=$ITERATE+1;
      fi

      # curl -arguments image-url > foldername/imagename.jpg
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

exit 0
