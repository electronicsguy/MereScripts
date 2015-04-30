#!/bin/bash
# Sujay Phadke, 2015

# sed ref:
# http://www.grymoire.com/Unix/Sed.html

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

METRIC=1  # 0 for F, 1 for C
# Ref: find your weather code:
# http://stackoverflow.com/questions/12452961/how-to-get-city-code-weather-in-accuweather
# If code has a space remove it or replace it with %20 or a dash (-)

# Bash converting case ref:
# http://stackoverflow.com/questions/2264428/converting-string-to-lower-case-in-bash-shell-scripting

if [ -n "$1" ]
then
  ARG=$1
  ARG=${ARG,,}    # convert all to lowercase
  
  #echo "Find weather for: $ARG"
  
  case $ARG in
  "mumbai")
    LOCCOD="ASI|IN|IN021|MUMBAI"
    ;;
  
  48109|48105|48104|"Ann Arbor")
    LOCCOD="48109"
    ;;
    
  "pune")
    LOCCOD="ASI|IN|IN012|PUNE"
    ;;
    
  "delhi"|"new delhi"|"newdelhi")
    LOCCOD="ASI|IN|IN010|NEWDELHI"
    ;;

  *)
    LOCCOD="ASI|IN|IN012|PUNE"
    ;;
  esac

else
  LOCCOD="ASI|IN|IN012|PUNE"
fi

#LOCCOD="48109"
#LOCCOD="ASI|IN|IN021|MUMBAI"
#LOCCOD="ASI|IN|IN012|PUNE"
#LOCCOD="ASI|IN|IN010|NEWDELHI"
# This doesn't seem to work
#LOCCOD="ASI|IN|IN017|BANGALORE"

#echo -e "Finding weather in $LOCCOD\n";

URL="http://rss.accuweather.com/rss/liveweather_rss.asp?metric=${METRIC}&locCode=$LOCCOD"

WDATA=$(curl -s $URL)

SIZE=${#WDATA}

if [ $SIZE -lt 10 ];
then
  echo -e "Unable to fetch weather data. Check network connection."
  exit
fi

# If the description of the weather ($5) is included in the replacement, somehow its also matching the Ctrl-M (^M) character at the end
# of the weather description.
# This, when printed, somehow blanks out the first letter of the replacement string ('C'), when using echo later. 
# For that reason, we need a second perl statement to remove the trailing CTRL-M (whitespace)
# The non-greedy match (.*?) is used so that perl stops at that line and does not continue ahead, matching a larger portion till it
# encounters the last (&lt;) character
TEMP=$(echo $WDATA | perl -pe 'binmode STDOUT, ":utf8"; s/(.*)Currently in (.*):\s*('$sFPN')\s*(&#176;)\s*[C|F]\s*and\s*(.*?)(&lt;)(.*)/Currently in $2: $3'$pDEG'C and $5/' | perl -pe 's/\s*$//')

# Use non-greedyfor first day match
DAY1=$(echo $WDATA | perl -pe 'binmode STDOUT, ":utf8"; s/(.*?)High: ('$sFPN') C Low: ('$sFPN') C (.*?)(&lt;)(.*)/Day 1: High: $2'$pDEG'C Low: $3'$pDEG'C\t$4/')
# Use greedy for second day match
DAY2=$(echo $WDATA | perl -pe 'binmode STDOUT, ":utf8"; s/(.*)High: ('$sFPN') C Low: ('$sFPN') C (.*?)(&lt;)(.*)/Day 2: High: $2'$pDEG'C Low: $3'$pDEG'C\t$4/')

SIZE=${#TEMP}

# Somehow, using [[ $SIZE > 100 ]] does not work here
if [ $SIZE -gt 100 ]
then
	echo "Unable to get temperature for location: $LOCCOD"
else
	#echo "Currently: $TEMP"
  echo -e "$TEMP"
  echo -e "\nForecast:"
  echo -e "$DAY1"
  echo -e "$DAY2"
fi
