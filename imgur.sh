#!/bin/bash

#=======================================#
# All rights reserved.                  #
# Licensed under GNU                    #
# http://www.gnu.org/copyleft/gpl.html  #
# Author's github.                      #
# https://github.com/manabutameni/Imgur #
#=======================================#

gallery_url=$1
tempname=`basename $0`
tempfile=`mktemp -t ${tempname}.XXXXX` || exit 1

if [ -n "$gallery_url" ]  #  If command-line argument present,
then

  if [[ "$gallery_url" =~ "imgur.com" ]]
  then

    i=0
    curl -s $gallery_url > $tempfile

    album_title=`awk -F\" '/data-title/ { print $6 }' $tempfile | head -1`

    if [ ${#album_title} -eq 0 ]
    then
      album_title=${gallery_url:(-5)}
    fi

    mkdir -p "$album_title"
    for image in $(awk -F\" '/data-src/ { print $10 } ' $tempfile | sed '/^$/d' | sed 's/s.jpg/.jpg/')
    do
      let i=$i+1;
      curl $image > "$album_title"/$i.jpg
    done

  else
    echo -e "\nImgur albums only\n"
    exit 1
  fi

  rm $tempfile

else
  echo -e "\nYou need to enter a parameter. Such as \
    \nhttps://www.imgur.com/a/qwerty\n"
  exit 1
fi
