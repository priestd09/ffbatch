ffbatch
=======

A batch processing script for windows to converting files with ffmpeg

## Prerequisites ##

0. Windows 7 or newer
1. install ffmpeg -- see http://ffmpeg.org/

## Installation ##

1. Save this single file to anywhere in your windows machine.
2. Edit global settings in the script:
	* ffmpegbase is the path to the installed ffmpeg
	* change any other settings if you want

## Using ##

`ffbatch.cmd filename <options>`
 
... or simply drop a directory to the script for default batch process.

Skips existing output files, unless -o switch specified.
creates %filename%.bitrate.mp4 output files
Returns only when finished

If you close the terminal window before the end of processing all files, the ongoing processes will 
continue and close when completed, but no more new process will start.

## Options ## 

-o	overwrite existing files (default skip)
-p <number>		number of paralel processes (default 4)
-b <bitrate>	output bitrate in bit/s, you may use k or M postfixes, e.g. 32M (default)
-f <pattern>	RE pattern to filter processed files

## External references ##
- http://ffmpeg.org/
