# Youtube-DL Interface

It has fully automated operation and can be launched either from the command 
line or from the graphical interface.

### SYNTAX

    ./run.sh [option]

### OPTIONS

    -h, --help
        Show this help content.

    -l, --log
        Show the log content.

    N/A
        Runs in auto mode.

### HOW IT WORKS

If it is the first time you are running, it must be run from the terminal to
check and solve the dependencies. Also, it will try to download the newest
version of the youtube-dl binary.

To use, fill the **links.lnk** file with the links that should be downloaded (
one link per line), then run this script with no argument.

The tags in **links.lnk** indicates how and where to download the links. See
more below.

### TAGS

       [CLEAR] - Indicates that the links file should be cleaned. This tag
                 should be in the end to avoid errors.

        [HIDE] - The links below this tag will be downloaded to a hidden folder.
                 Links directly below this tag will be ignored.

      [NORMAL] - The links below this tag will be downloaded to normal video
                 folder. Links directly below this tag will be ignored.

    [PLAYLIST] - Indicates to download the entire playlist. The files will be
                 placed in a folder with the same name as the playlist. This 
                 folder will be placed inside the directory indicated by the
                 [NORMAL] and [HIDE] tags, because of this, it needs to appear
                 after these tags. It only for Youtube links.

       [VIDEO] - Indicates to download a single video.

*Tags can be repeated as many times as needed.

### ERRORS CODE

    1 - There are dependencies but can not install then unless it is running
        through the terminal.
    2 - There are dependencies but can not install then with sudo.
    3 - There is no internet connection.
    4 - Can not install Youtube-DL and there is no local version available.

### REQUIREMENTS

           less: crt viewer
         ffmpeg: video converter
    notify-send: notification sender
           ping: icmp sender
           wget: internet downloader

### COMPATIBILITY

Debian based distros (fully).

It can work in other distros as far them supplies all dependencies.

### KNOWN BUG

- The file **links.lnk** must end with a blank line, otherwise the last
  command will not run.