#!/bin/bash
gallery_url=$1
http_proxy=""

if [ -n "$1" ]  #  If command-line argument present,
then

  if [[ "$1" =~ "imgur.com" ]]
  then

    i=0
    curl -s $1 > temp.html
    album_title=`cat temp.html | grep "h1 style"`

    if [[ ${#album_title} == 18 ]]
    then
      album_title=${1:(-5)}
    else
      album_title=$(echo $album_title | sed -e 's/<[^>][^>]*>//g' -e '/^ *$/d')
    fi

    mkdir -p $album_title
    mv temp.html $album_title
    cd $album_title
    for image in $(cat temp.html | awk -F\" '/data-src/ { print $10 }')
    do
      let i=$i+1;
      curl $image > $i.jpg
    done

  else
    echo -e "\nImgur albums only\n"
    exit
  fi

  rm temp.html

else
  echo -e "\nYou need to enter a parameter. Such as \
    \nhttps://www.imgur.com/a/qwerty\n"
fi
