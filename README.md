# ~/bin scripts
===========

A bunch of ~/bin utilities for Linux (though most will probably work on Mac OS X too).
Several of them will need Ruby as well as certain Ruby gems.

## age
A CLI Ruby script that returns your (Terran) age in various descriptions, based on your date of birth.
To get your own age, configure the script with your date (and possibly even hour!) of birth and call the script without any arguments.
You can also pass some date in the past to get the time that has passed since that time, for instance to get someone else's age.

### Examples:
````
$ age
I was born 15786.81 Terran days, or 378883 hours and roughly 32 minutes ago. This makes me about 22733012 minutes (or about 43.22 Terran years) old
$ age 2 November 1981
You were born 11463.82 Terran days, or 275131 hours and roughly 33 minutes ago. This makes you about 16507893 minutes (or about 31.39 Terran years) old
````

### Dependencies:
- *Rubygems:*
  - chronic

## checksums
CLI Ruby script that returns various checksum (MD5, SHAsum, SHA1sum, sha512sum)

### Dependencies:
- *Commandline tools:*
  - md5 and/or md5sum commandline tool
  - shasum and/or sha1sum commandline tool
  - sha512sum commandline tool

## convert_units.rb
CLI Ruby script that converts various temperature and other units.
Started as a temperature conversion tool to convert degrees Fahrenheit to various other temperature scales and ended up getting a fallback to the *ruby-units* gem for conversion of various other units.

### Dependencies:
- *Rubygems:*
  - ruby-units

## find_larger_than
CLI Bash script that helps you find the large files that are hogging your disk space.

### Usage:
`find_larger_than MIN_SIZE START_PATH`
*MIN_SIZE* supports following suffixes: 
- _'b'_ (512-byte blocks (default))
- _'c'_ (bytes)
- _'w'_ (two-byte words)
- _'k'_ (1024 (kilo) bytes))
- _'M'_ (1048576 (Mega) bytes)
- _'G'_ (1073741824 (Giga) bytes)
*MIN_SIZE* defaults to 100M and START_PATH to ~/

### Examples:
#### Find files larger than 200 kilobytes in your bindir and its subdirs:
`find_larger_than 200k ~/bin/`
#### Find files larger than 200 megabytes across all your partitions:
`sudo find_larger_than 200M /`
#### Find files larger than 100 megabytes in your homedir and its subdirs (the defaults):
`find_larger_than`

### Dependencies:
- `find` commandline tool.

## fliptext.rb
CLI Ruby script which converts your text into Unicode glyphs that makes your text look like it's upsidedown.
Based on the javascript code from http://www.revfad.com/flip.html

## mathtext.rb
CLI Ruby script that converts your text into Unicode glyphs from the bold, bold-italic, script, script-italic, fraktur or fraktur-bold mathematical character ranges.
Inspired by [fliptext.rb](https://gist.github.com/FiXato/525297) and [Sai's post on G+](https://plus.google.com/u/0/103112149634414554669/posts/V7zxyRYg2EB) which mentioned Fraktur symbols in Unicode.

## urlserver
CLI Python script which can be used to add urls/messages to your local urlserver database, which can be used by the [urlserver.py WeeChat script](https://github.com/torhve/weechat-urls).

### Dependencies:
- sqlite database
- *Python libraries:*
  - sys
  - os
  - string
  - time
  - datetime
  - socket
  - re
  - base64
  - cgi
  - sqlite3
  - urlparse
  - urllib
  - htmlentitydefs



## tog
CLI Ruby script to look up if NSB.no trains are still on time and to display their departure times. Ties into the urlserver script.
Get train delays for given route between any NSB trainstation in Norway.

## Usage:
`tog <predefined_route|departure_station arrival_station>`

## Example:
`tog Oslo Fauske`

## Dependencies:
- *Ruby gems:*
  - Nokogiri
- Standard Ruby libraries:
  - open-uri
  - uri
- urlserver CLI Python tool (though this requirement can easily be disabled)


## weather
Wrapper around weather_formatter.rb and barometer. Supports reports local weather from various sources.

### weather_formatter.rb
Formats the output for the weather wrapper
### Dependencies:
- *Ruby gems:*
  - barometer
