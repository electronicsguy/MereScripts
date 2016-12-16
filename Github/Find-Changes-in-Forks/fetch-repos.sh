#!/bin/bash

readarray x < config.txt
# Remove trailing space
USER=`echo ${x[0]} | tr -d ' '`
REPO=`echo ${x[1]} | tr -d ' '`

URL="https://api.github.com/repos/$USER/$REPO/forks"
echo "Fetching fork directories from: $URL"
echo

rm -rf repo-changes/
mkdir repo-changes
cd repo-changes

curl -i $URL |grep -e "git_url" |awk '{gsub(/,/,"");split($2,a,"/"); system("mkdir "a[4]"; cd "a[4]"; git clone " $2);}'

cd ..

echo
echo "Forks stored in directory: repo-changes/"
echo
