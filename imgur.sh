#!/bin/bash

i=0
gallery_url=""
multiple_files=false
extra_clean=false
preserve=false
curl_args=""
tempname=`basename $0`
tempfile=`mktemp -t ${tempname}.XXXXX` || exit 1

usage()
{
  cat << EOF

  usage: ./imgur.sh [-cpsm] [file] URL
  This script is used solely to download imgur albums.

  OPTIONS:
    -h        Show this message.
    -m <File> Download multiple albums found in <File>.
    -c        Clean and Remove nonalphanumeric characters from the album's name.
    -p        Preserve imgur's naming. (Warning! This will not retain order.)
    -s        Silent mode.

EOF
}

download()
{
  gallery_url="$1"

  if [[ "$gallery_url" =~ "imgur.com" ]]
  then

    i=0 
    curl -s $gallery_url > $tempfile

    #Search for album title by parsing html
    album_title=`awk -F\" '/data-title/ { print $6 }' $tempfile | sed -n 1p`

    #Sanitize $album_title
    CLEAN=${album_title//_/}
    CLEAN=${CLEAN// /_}

    #The following is executed if -c was declared.
    if [[ $extra_clean == true ]] 
    then
      CLEAN=${CLEAN//[^a-zA-Z0-9_]/}
      CLEAN=`echo -n $CLEAN | tr A-Z a-z`
    fi
    #end -c
    #Sometimes the end of an album title is a blank space
    #Remove it so it doesn't get renamed as _
    if [[ "${album_title:(-1)}" == " " ]]
    then
      album_title=${CLEAN%?}
    else
      album_title=$CLEAN
    fi

    #Sometimes people don't give their albums a title.
    #This sets album_title as the last 5 digits in the URL.
    if [ ${#album_title} -eq 0 ]
    then
      album_title=${gallery_url:(-5)}
      #Some album URLs have a '#' character. Remove that to
      #prevent folder naming problems.
      if [[ "$album_title" =~ "#" ]]
      then
        album_title=${gallery_url:(-7)}
        album_title=${album_title:0:5}
      fi
    elif [[ "$album_title" =~ '/' ]]
    then
      album_title=`echo $album_title | sed 's/\//-/'`
    fi
  else

    echo
    echo "Imgur albums only."
    echo
    exit 1

  fi

  mkdir -p "$album_title"
  #Parse image name from the temporary html file and ensure 
  #that it's not a thumbnail instead of the full sized image.
  for image in $(awk -F\" '/data-src/ { print $10 } ' $tempfile |
          sed '/^$/d' | sed 's/s.jpg/.jpg/')
  do
    #The following is executed if -p was declared.
    if [[ $preserve == false ]]
    then
      let i=$i+1;
      i=$i
    else
      i=${image:(-9):5}
    fi
    #end -p
    #curl_args is written here without spaces to avoid
    #spacing issues if -s was declared.
    curl $curl_args $image > "$album_title"/$i.jpg
  done
}

while getopts "hm:cps" OPTION
do
  case $OPTION in
    h)
      usage
      exit 0
      ;;
    m)
      multiple_files=true

      for line in $(cat $OPTARG)
      do
        gallery_url=$line
        download "$line"
      done
      ;;
    c) 
      extra_clean=true
      ;;
    p)
      preserve=true
      ;;
    s)
      curl_args=" -s "
      ;;
    ?)
      echo
      echo "usage: $0 [-cpsm] [file] URL..."
      echo
      exit 1
      ;;
  esac
done

# gallery_url = multiple_files without this
if [[ $multiple_files == false ]]
then
  gallery_url="${@: -1}"
  if [[ "$curl_args" == " -s " ]]
  then
    curl_args=" -s -O "
  fi
  download $gallery_url
fi
