About
-----

This is a 100% Bash script used to download imgur albums while making sure that
the order of the pictures is retained.

    usage: bash imgur.sh [-cps] [-m file] URL
    This script is used solely to download imgur albums.

    OPTIONS:
      -h        Show this message.
      -m <File> Download multiple albums found in <File>.
      -c        Clean nonalphanumeric characters from the album's name.
      -p        Preserve imgur's naming. (Warning! This will not retain order.)
      -s        Silent mode.

Compatible with Linux, Unix, and OS X  

Usage
-----

The script was created so that all that you need to do is copy+paste the address
bar link into the terminal.

    chmod +x imgur.sh
    ./imgur.sh -h

If you want to use the multiple-files feature then you will need to have a plain
text file with imgur album URLs seperated by new lines

`./imgur.sh -m Imgur-Albums-List.txt`

Special note: If you do use the -m flag it must be the last option.  
E.X. `./imgur.sh -scm Imgur-Albums-List.txt`

Installation
------------

This is only if you want to reference the script without having it in the
directory you want the imgur album.

### Nix like operating systems

    sudo mkdir -p /usr/local/bin 
    sudo chown `whoami` /usr/local/bin
    cd /usr/local/bin
    curl https://raw.github.com/manabutameni/Imgur/master/imgur.sh -o imgur
    chmod +x imgur
    PATH=$PATH:/usr/local/bin # only if you haven't done this already
    export PATH

Do note that you will need to add the last two lines to your ~/.bashrc

### Windows under cygwin

[Cygwin website](http://cygwin.com/install.html)  
Using setup.exe install the following:
* curl
* sed
* gawk
* bash
* grep

Then run the Cygwin terminal and paste the following:

    mkdir -p /usr/local/bin
    cd /usr/local/bin
    curl https://raw.github.com/manabutameni/Imgur/master/imgur.sh -o imgur
    chmod +x imgur

To use:
`imgur imgur.com/a/XXXXX`

KDE
---

There is a file named imgur.desktop with you in mind. Simply copy to your local
`kde4-config --path services` location and make sure it's executable. `chmod +x
imgur.desktop`.

To use: Simply copy the url of an imgur album into your clipboard and right
click on an empty area in dolphin. Under actions you should see "Imgur Album
DL".

Please note, this will only work if you have installed the script in the
Installation part of this readme.

Extra
-----

I wanted to write a script that would ensure that each image is in the proper
order which you can't do by clicking the "Download" button on imgur albums.
Clicking the "Download" link on imgur albums does not save the order.
[Example album](http://imgur.com/a/NhmjT/all#0)

This script was made with the intent to be used with minimal requirements and
will work on a fresh install of a minimal system. As long as you have /bin/bash
and the mktemp and curl commands this script should work out of the box.

This script can also download entire subreddit's worth of
albums. [Example1](http://reactiongifsmods.imgur.com/) and
[Example2](http://imgur.com/r/reactiongifs). 


##### Requirements

The following need to be installed for this script to work:  
bash, basename, mktemp, curl, (g)awk, sed

##### What this script does not do: 

This script will not update an album. For example, if there's an album that is
frequently updated that you enjoy following, this script (by design) cannot and
will not update that album with the newest images. Just imagine if you tried
downloading an album that was titled "Pictures".

##### Credits

Thanks to everyone in this thread who helped me out.  
http://redd.it/webn1  
Special Thanks goes to Reddit users:  
  /u/Ihasn and /u/Skaarj for help on the base code during the early stages.  
  /u/invisiblescars for the idea and original code for a kde4 context menu.
