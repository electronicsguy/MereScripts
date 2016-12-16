#!/bin/bash

readarray x < config.txt
# Remove trailing space
USER=`echo ${x[0]} | tr -d ' '`
REPO=`echo ${x[1]} | tr -d ' '`
FILE=`echo ${x[2]} | tr -d ' '`

DIRS=$(find repo-changes/ -maxdepth 2 -type d -name "*$REPO" -print)

echo "Last commit stats for file: $FILE"
echo

for d in $DIRS
do
        cd $d
        git fetch
        BRANCHES=$(git branch -a)
        OBS=$(git branch -r |egrep -v '(HEAD)')
        for ob in $OBS 
        do 
                git checkout -t $ob 2>/dev/null
                bonly=$(echo $ob |awk {'split($0,a,"/"); print a[2]'})
                git checkout $bonly &>/dev/null
                git pull &>/dev/null
                out=$(git log --pretty=format:"%H %ad" $FILE |head -n1 | xargs -I{} echo `pwd`"("$ob"): "{})
                echo $out
        done

        cd ../../..
done
