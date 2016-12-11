#!/bin/bash
#Ref: https://developer.github.com/v3/activity/starring/#list-stargazers

USER='electronicsguy'
REPO='ESP8266'

if [[ $# -eq 2 ]]
then
  USER=$1
  REPO=$2
  echo -e "Fetching info for user: '$USER', repo: '$REPO'"
fi

curl -s "https://api.github.com/repos/$USER/$REPO/forks" -H "Accept: application/vnd.github.v3.star+json" > list.txt

cat list.txt | grep -i login | cut -d':' -f2 | sed -e 's/ \"//' | sed -e 's/\",$/: /' >| usernames.txt
cat list.txt | grep -i created_at | cut -d':' -f2 | sed -e 's/ \"//' | sed -e 's/T\w*//' >| dates.txt
cat list.txt | grep -i html_url | sed -n '1~2!p' | cut -d':' -f2,3 | sed -e 's/ \"//' | sed -e 's/\",$//' >| users_url.txt

echo -e "$USER $REPO stats"
echo -e "Username\tFork date\tUser Github URL"
echo -e "========\t=========\t==============="

paste usernames.txt dates.txt users_url.txt
#pr -m -t usernames.txt dates.txt users_url.txt

rm list.txt
rm usernames.txt
rm dates.txt
rm users_url.txt
