##About

This is a 100% Bash script used to download imgur albums while making sure that
the order of the pictures is retained.

Compatible with Linux, Unix, OS X, and Windows under Cygwin.

Author:  
    manabutameni  
    https://github.com/manabutameni/Imgur

##Usage

    bash imgur.sh [-sd] URL [URL]

    OPTIONS
        -h       Show this message.
        -s       Silent mode. Overrides debug mode.
        -d       Debug mode. Overrides starndard output.

Multiple albums can be downloaded like so: `bash imgur.sh URL1 URL2 ...`

##Installation

This is only necessary if you want to run the script without having it in the
same folder you want the imgur album, or if you want to install imgur.desktop
for KDE.

##### Nix like operating systems

    sudo mkdir -p /usr/local/bin 
    sudo chown `whoami` /usr/local/bin
    cd /usr/local/bin
    curl https://raw.github.com/manabutameni/Imgur/master/imgur.sh -o imgur
    chmod +x imgur
    PATH=$PATH:/usr/local/bin
    export PATH
Do note that you will need to append the last two lines to your ~/.bashrc

After you have installed the script with this method you can always update to
the latest version of the script with the following command:

    curl https://raw.github.com/manabutameni/Imgur/master/imgur.sh -o /usr/local/bin/imgur

To use:  
In any directory type: `imgur imgur.com/a/XXXXX`  

#####KDE

There is a file named imgur.desktop with you in mind. Simply copy imgur.desktop
to your local `kde4-config --path services` folder location and make sure it's
executable. `chmod +x imgur.desktop`.

To use: Simply copy the url of an imgur album into your clipboard and right
click on an empty area in dolphin. Under actions you should see "Imgur Album
DL".

Please note, this will only work if you have installed the script in the
Installation part of this readme.

##Extra

I wanted to write a script that would ensure that each image is in the proper
order which you can't do by clicking the "Download" button on imgur albums.
Clicking the "Download" link on imgur albums does not save the order.

##### What this script does not do

This script will not update an album. For example, if there's an album that is
frequently updated that you enjoy following, this script (by design) cannot and
will not update that album with the newest images. Just imagine if you tried
downloading an album that was titled "Pictures".
