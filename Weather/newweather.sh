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

# Bash shell syntactic sugar for comparison expressions:
# http://stackoverflow.com/questions/6534891/when-do-you-use-or-usr-bin-test

# Define ANSI color sequences
GREEN='\e[1;32m'
YELLOW='\e[1;33m'
WHITE='\e[1;37m'
RED='\e[1;31m'
BLUE='\e[1;34m'
COLOROFF='\e[0m'

# Yahoo API
clientId=dj0yJmk9Zk1qN0ZqZmR3R2hNJmQ9WVdrOVFXWkVSRFZYTm0wbWNHbzlNQS0tJnM9Y29uc3VtZXJzZWNyZXQmeD03MQ--
WHEREURL="http://where.yahooapis.com/v1/places.q"

# Return values from bash functions ref:
# http://www.linuxjournal.com/content/return-values-bash-functions
getWOEID() {
  WOEIDURL="$WHEREURL('$1')?appid=$clientId"
  LOCDATA=$(curl -s $WOEIDURL)
  local __LOC=''
  __LOC=$(echo $LOCDATA | perl -pe 's/(.*?)<woeid>(\d+).*/$2/g')

  # No location match or no data
  local __LEN=SIZE=${#__LOC}
  if (( ($__LEN > 20) || ($__LEN < 2) ));
  then
    eval "$2"="-1"
  else
    eval "$2"=$__LOC
  fi
}


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
    LOC=''
    # Replace spaces in the city name with "%20" and remove leading and trailing '%20's
    ARG=$(echo $ARG | perl -pe 's/\s+/%20/g' | perl -pe 's/^(%20)//' | perl -pe 's/(%20)$//')
    getWOEID $ARG LOC
    if (( $LOC == -1 ))
    then
      echo -e "Unable to fetch weather data for location: $ARG"
      exit
    fi
    ;;
  esac

else
  LOC="2295412"
fi

# Supress zenity window
NOWIN=0
if [[ ($1 == "nw") || ($1 == "-nw") ]];
then
  NOWIN=1
fi

if [[ ($# > 1) && (($2 == "nw") || ($2 == "-nw")) ]];
then
  NOWIN=1
fi

# For some reason the API must be given units in lowercase letters!
URL="http://weather.yahooapis.com/forecastrss?w=$LOC&u=${UNITS,,}"

rm -rf /tmp/yahoo
mkdir /tmp/yahoo

WDATA=$(curl -s $URL)

SIZE=${#WDATA}

if (( $SIZE < 10 ));
then
  echo -e "Unable to fetch weather data. Check network connection."
  exit
fi

# Note: If your ssh client does not support colors, remove all the color tags
# Use non-greedy match (using .*?) to limit the match

TEMP=$(echo $WDATA | perl -pe 'binmode STDOUT, ":utf8"; s/(.*)Conditions for (.*) at(.*)Current Conditions:(.*?),\s*('$sFPN')\s*[C|F](.*)/'$GREEN'Currently in $2: '$RED'$5'$pDEG' C, '$YELLOW'$4/g' | perl -pe 's/<\/b><br \/>\s+//')

# remove breaks and other non-printable characters and terminate each line with CRLF
DAYS=$(echo $WDATA | perl -pe 'binmode STDOUT, ":utf8"; s/(.*)Forecast:(.*)(<br \/>).*/'$COLOROFF'$2/' | perl -pe 's/<\/b><BR \/>\s+//' | perl -pe 's/<br \/>\s+/\\r\\n/g')

# put the degree symbols and units and reverse the order of data
DAYS=$(echo $DAYS | perl -pe 'binmode STDOUT, ":utf8"; s/(\w+?) - (.*?)\. High: ('$sFPN') Low: ('$sFPN')/$1 - High: $3'$pDEG$UNITS' Low: $4'$pDEG$UNITS', $2/g')

# Use non-greedy match (using .*?) to limit the match
if (( $NOWIN == 0 ));
then
  HTMLTEMP=$(echo $WDATA | perl -pe 'binmode STDOUT, ":utf8"; s/(.*)Conditions for (.*) at(.*)Current Conditions:(.*?),\s*('$sFPN')\s*[C|F](.*)/<font color="green">Currently in $2:<\/font> <font color="red">$5'$pDEG' C,<\/font> <font color="brown">$4<\/font>/g' | perl -pe 's/<\/b><br \/>\s+//')

# remove breaks and other non-printable characters and terminate each line with CRLF
  HTMLDAYS=$(echo $WDATA | perl -pe 'binmode STDOUT, ":utf8"; s/(.*)Forecast:(.*)(<br \/>).*/$2/' | perl -pe 's/<\/b><BR \/>\s+//' | perl -pe 's/<br \/>\s+/\\r\\n/g')

# put the degree symbols and units and reverse the order of data
  HTMLDAYS=$(echo $HTMLDAYS | perl -pe 'binmode STDOUT, ":utf8"; s/(\w+?) - (.*?)\. High: ('$sFPN') Low: ('$sFPN')/$1 - High: $3'$pDEG$UNITS' Low: $4'$pDEG$UNITS', $2/g')
  

fi

# Get weather image
IMG=$(echo $WDATA | perl -pe 'binmode STDOUT, ":utf8"; s/(.*)CDATA\[\s*<img src=\"(.*?)\"\/><br \/>.*/$2/')
# image download disabled since we can't use it anyways (see <img> note below)
#curl -s -o /tmp/yahoo/current.gif $IMG

SIZE=${#TEMP}
if (( $SIZE > 100 ))
then
	echo "Unable to get temperature for location: $LOC"
  exit
fi

echo -e $TEMP

SIZE=${#DAYS}
if (( $SIZE < 10 ))
then	
  exit
fi

if (( $NOWIN == 1 ));
then
  echo -e "\nForecast:\n$DAYS"
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
  echo -e "" >| /tmp/yahoo/current.html
  echo -e "<!DOCTYPE HTML>" >> /tmp/yahoo/current.html
  echo -e "<html>" >> /tmp/yahoo/current.html
  echo -e "<body>" >> /tmp/yahoo/current.html
  echo -e "<img src=\"$IMG\" />" >> /tmp/yahoo/current.html 

  HTMLDAYS=$(echo $HTMLDAYS | perl -pe 's/\\r/<\/p><p>/g')
  echo -e "<p>$HTMLTEMP</p><p>Forecast:</p><p>$HTMLDAYS</p>" >> \
  /tmp/yahoo/current.html

  echo -e "</body>" >> /tmp/yahoo/current.html
  echo -e "</html>" >> /tmp/yahoo/current.html
  
  zenity --text-info --width 400 --height 400 2 --title "Weather info" \
  --html --filename="/tmp/yahoo/current.html" &> /dev/null

fi

