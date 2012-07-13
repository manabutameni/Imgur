#!/bin/bash
gallery_url=$1
tempname=`basename $0`
tempfile=`mktemp -t ${tempname}.XXXXX` || exit 1

if [ -n "$gallery_url" ]  #  If command-line argument present,
then

  if [[ "$gallery_url" =~ "imgur.com" ]]
  then

    i=0
    curl -s $gallery_url > $tempfile
    album_title=`grep "h1 style" $tempfile`

    if [ ${#album_title} -le 18 ]
    then
      if [ ${#album_title} -eq 0 ]
      then
        echo -e "\nImgur album has been deleted\n"
        exit 1
      fi
      album_title=${gallery_url:(-5)}
    else
      album_title=$(echo "$album_title" | sed -e 's/<[^>][^>]*>//g' -e '/^ *$/d')
    fi

    mkdir -p "$album_title"
    for image in $(awk -F\" '/data-src/ { print $10 }' $tempfile)
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
