+-----+
|ABOUT|
+-----+

This is a 100% Bash script used to download imgur albums while making sure that
the order of the pictures is retained. The script now allows for multi-album
support.

  usage: ./imgur.sh [-cpsm] [file] URL
  This script is used solely to download imgur albums.

  OPTIONS:
    -h        Show this message.
    -m <File> Download multiple albums found in <File>.
    -c        Clean nonalphanumeric characters from the album's name.
    -p        Preserve imgur's naming. (Warning! This will not retain order.)
    -s        Silent mode.

Thanks to everyone in this thread who helped me out.
http://redd.it/webn1
Special Thanks goes to Reddit users:
Ihasn and Skaarj for help on the base code during the early stages.
invisiblescars for the idea and original code for a kde4 context menu.

Compatible with:
  Linux
  Unix
  OS X

+-----+
|USAGE|
+-----+

The script was created so that all that you need to do is copy+paste 
the address bar link into the terminal.

chmod +x imgur.sh
./imgur.sh -h

If you want to use the multiple-files feature then you will need to have
a plain text file with imgur album URLs seperated by new lines

./imgur.sh -m Imgur-Albums-List.txt

Special note: If you do use the -m flag it must be the last option.
E.X. ./imgur.sh -scm Imgur-Albums-List.txt

+------------+
|INSTALLATION|
+------------+

This is only if you want to reference the script without having it in 
the directory you want the imgur album.

sudo mkdir -p /usr/local/bin 
sudo chown `whoami` /usr/local/bin
cd /usr/local/bin
curl https://raw.github.com/manabutameni/Imgur/master/imgur.bash -o imgur
chmod +x imgur
PATH=$PATH:/usr/local/bin # only if you haven't done this already
export PATH

To use:
imgur http://www.imgur.com/a/XXXXX

+--------------+
|FOR KDE4 USERS|
+--------------+

There is a file named imgur.desktop with you in mind.
Simply copy to your local `kde4-config --path services` location and 
make sure it's executable. chmod +x imgur.desktop.

To use: Simply copy the url of an imgur album into your clipboard and
right click on an empty area in dolphin. Under actions you should see 
"Imgur Album DL".

+-----+
|EXTRA|
+-----+

You may be wondering why I bothered to write this script.
The answer is twofold. First, I wanted to write a script that would ensure
that each image is in the proper order which you can't do by clicking the
"Download" button on imgur albums. Seriously, click the "Download" link
here and see for yourself: http://imgur.com/a/NhmjT/all#0
The second reason was to test my ability with bash.
