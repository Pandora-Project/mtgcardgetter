## Table of contents
* [General info](#general-info)
* [Technologies](#technologies)
* [Usage](#usage)

## General info
This project is a simple image downloader and viewer for mtg cards with a simple GUI.
	
## Technologies
Project is created with:
* Perl version: 12.3
* GNU bash, version 5.2.21(1)-release
* jq version 1.7

## Usage
To run this project, run the terminal.sh file and ensure all files from directory are in place:
Here are some example uses
```
$ ./terminal.sh -h
$ ./terminal.sh -v -i
$ ./terminal.sh -v -n ajani -c white -t planeswalker
$ ./terminal.sh -m 3 -s DMU -o output_dir/
```