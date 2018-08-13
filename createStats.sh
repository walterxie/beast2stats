#!/bin/bash
### tested in MacOS Sierra 10.12.6
# chmod u+x 

# dir containing all .txt for analysis
WD="$HOME/WorkSpace/beast2stats"
# dir containing all checked out packages
WD_PKG="$HOME/WorkSpace"
# MONTHS = number of months expected - 1, e.g. MONTHS=59 for 5 years
MONTHS=59

PACKAGE=$1 #"beast2"

### init
TMP="$PACKAGE-$(date +%Y-%m-%d)"
cd $WD
if [[ ! -e $TMP ]]; then
    mkdir $TMP
    echo "Create $WD/$TMP to store *.txt"
else 
    cd $TMP
    echo "Clean *.txt in $WD/$TMP ..."
    rm *.txt
fi

### analyse package
cd $WD_PKG
if [[ ! -e $PACKAGE ]]; then
    echo "$PACKAGE does not exist in $WD_PKG !"
    exit 1
else 
    cd $PACKAGE
    echo "Working dir is $PWD now, analysing package $PACKAGE ..."
fi

# update
git checkout master
git pull
# date of 1st commit
COMMIT=`git rev-list --max-parents=0 HEAD`
DATE_1st_COMMIT=`git show -s --format=%cd --date=short $COMMIT`

# loop through n months before 
for m_before in $(seq 0 $MONTHS); do
    # e.g. 2018-07-01
    DATE_CHECK_OUT=`date -v-${m_before}m +%Y-%m-01`    
    
    if [[ "$DATE_CHECK_OUT" > "$DATE_1st_COMMIT" ]]; then
      # checkout version at the 1st date of a month
      git checkout `git rev-list -n 1 --before="$DATE_CHECK_OUT 00:00" master`
    
      # count the line of java code 
      git ls-files | grep "\.java$" | xargs wc -l > "$PACKAGE-$DATE_CHECK_OUT.txt"
    
      # mv txt to tmp dir created previously
      mv "$PACKAGE-$DATE_CHECK_OUT.txt" "$WD/$TMP"      
    else 
      echo "Package $PACKAGE has no code on $DATE_CHECK_OUT !"
    fi
done

# make sure HEAD back to master
git checkout master

# back to WD of all packages
cd $WD_PKG

