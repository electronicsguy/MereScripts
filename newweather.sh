#!/bin/bash
# Sujay Phadke, 2015
#
# This program is deistributed with GPL v3 licence
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Uses weather.com yahooapi-s
# Weather codes:
# http://docs.rainmeter.net/tips/webparser-weather-location-code

# Perl floating point numbers:
# www.regular-expressions.info/floatingpoint.html
# use this strings for repeatedly using a regex for signed floating point (or integer) numbers
# note: the use of the variable inside the perl command line expression need to be single quoted
# to allow variable interpretation. Somehow only this technique works in this case, not double-quoting.
# see this for ref: http://www.justskins.com/forums/problem-using-bash-variables-81824.html
sFPN='[-+]?[0-9]*\.?[0-9]+'

# Perl degree symbol Unicode:
# http://www.fileformat.info/info/unicode/char/00b0/index.htm
# Perl set output encoding
# http://stackoverflow.com/questions/15210532/use-utf8-gives-me-wide-character-in-print
# Perl non-greedy regexp match
# http://docstore.mik.ua/orelly/perl/cookbook/ch06_16.htm
pDEG='\N{U+00B0}'

# print deg symbol in UTF-8:
# http://stackoverflow.com/questions/8334266/how-to-make-special-characters-in-a-bash-script-for-conky
DEG=$'\xc2\xb0'

UNITS="C"

if [ -n "$1" ]
then
  ARG=$1
  ARG=${ARG,,}    # convert all to lowercase
  
  #echo "Find weather for: $ARG"
  
  case $ARG in
  "mumbai"|"bombay")
    LOC="2295411"
    ;;
  
  48109|48105|48104|"Ann Arbor")
    LOC="2354842"
    ;;
    
  "pune")
    LOC="2295412"
    ;;
    
  "delhi"|"new delhi"|"newdelhi")
    LOC="29229014"
    ;;

  "bangalore"|"bengaluru")
    LOC="2295420"
    ;;

  "calcutta"|"kolkata")
    LOC="2295386"
    ;;

  *)
    LOC="2295412"
    ;;
  esac

else
  LOC="2295412"
fi

#LOC="2295420"	# Bangalore
#LOC="2354842"	# Ann Arbor
#LOC="2295411"	# Mumbai
#LOC="2295386"  # Kolkata

# For some reason the API must be given units in lowercase letters!
URL="http://weather.yahooapis.com/forecastrss?w=$LOC&u=${UNITS,,}"

rm -rf /tmp/yahoo
mkdir /tmp/yahoo

WDATA=$(curl -s $URL)

SIZE=${#WDATA}

if [ $SIZE -lt 10 ];
then
  echo -e "Unable to fetch weather data. Check network connection."
  exit
fi

TEMP=$(echo $WDATA | perl -pe 'binmode STDOUT, ":utf8"; s/(.*)Conditions for (.*) at(.*)Current Conditions:(.*?),\s*('$sFPN')\s*[C|F](.*)/Currently in $2: $5'$pDEG' C, $4/g' | perl -pe 's/<\/b><br \/>\s+//')

DAYS=$(echo $WDATA | perl -pe 'binmode STDOUT, ":utf8"; s/(.*)Forecast:(.*)(<br \/>).*/$2/' | perl -pe 's/<\/b><BR \/>\s+//' | perl -pe 's/<br \/>\s+/\\r\\n/g')
DAYS=$(echo $DAYS | perl -pe 'binmode STDOUT, ":utf8"; s/High: ('$sFPN') Low: ('$sFPN')/High: $1'$pDEG$UNITS' Low: $2'$pDEG$UNITS'/g')

# Get weather image
IMG=$(echo $WDATA | perl -pe 'binmode STDOUT, ":utf8"; s/(.*)CDATA\[\s*<img src=\"(.*?)\"\/><br \/>.*/$2/')
# image download disabled since we can't use it anyways (see <img> note below)
#curl -s -o /tmp/yahoo/current.gif $IMG

SIZE=${#TEMP}
# Somehow, using [[ $SIZE > 100 ]] does not work here
if [ $SIZE -gt 100 ]
then
	echo "Unable to get temperature for location: $LOC"
  exit
fi

echo -e $TEMP

SIZE=${#DAYS}
if [ $SIZE -lt 10 ]
then	
  exit
fi

if [[ -z $DISPLAY ]];
then
  echo -e "\nForecast:\n$DAYS"
  exit
else
  # the html <img> tag doesn't seem to load local files
  # ./current.gif or file:///current.gif or /tmp/yahoo/current.gif
  # this seems to be for security reasons
  echo -e "<img src=\"$IMG\" />" >| /tmp/yahoo/current.html

  HTMLDAYS=$(echo $DAYS | perl -pe 's/\\r/<\/p><p>/g')
  echo -e "<p>$TEMP</p><p>Forecast:</p><p>$HTMLDAYS</p>" >> \
  /tmp/yahoo/current.html

  zenity --text-info --width 400 --height 400 2 --title "Weather info" \
  --html --filename="/tmp/yahoo/current.html" &> /dev/null

fi

