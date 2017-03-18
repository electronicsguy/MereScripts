# Find Forks with latest commit (changes) information for your Github repository

This project is a slight modification of the excellent scripts by [hhutch](https://gist.github.com/hhutch/3688814
). I've made some changes to make it customizable.

It'll query the Github database to fetch all current forks for your repo. It'll put them in separate sub-directories 
 and then check the git log for modifications made to a repo file you specify. These parameters have to be put in 
 the configuration file *config.txt*. 

The format of config.txt file is:
 ```
<USER>
<REPO>
<Dir/Filename> to check for changes
```
All you need to do us run:
```
./fetch-changes.sh
```
The output will be list of **fork:branch:commit** for the specific repo file sorted by date of commit.
