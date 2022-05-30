#!/bin/bash
# Use the given CBAN XML from different dates to adjust the stats 
# which makes the plot suiting with the released time-line in CBAN.
# The XMLs from different dates are then used by beast2Stats.R.
# Input: $XML and $MONTHS
#        $CLEAN_FOLDER allows multiple versions of CBAN XML
### tested in MacOS Sierra 10.12.6
# chmod u+x 
# author: Walter Xie

# dir containing all files for analysis
WD="$HOME/WorkSpace/beast2stats"
# released packages
WD_PKG="$HOME/WorkSpace/CBAN"
XML=$1 # e.g. "packages2.5.xml" or "packages2.6.xml"
# make months up to the first commit of packages2.5.xml, Mar 21, 2018
MONTHS=49
# if false, it will allow multiple versions of CBAN XML
CLEAN_FOLDER=false

### init
TMP="CBAN-XML"
cd $WD
if [[ ! -e $TMP ]]; then
    mkdir $TMP
    echo "Create $WD/$TMP to store *.xml"
else 
    # rm all XML
    if [ "$CLEAN_FOLDER" = true ] ; then
		cd $TMP
		echo "Clean *.xml in $WD/$TMP ..."
		rm *.xml
    fi
fi

### cp xmls
cd $WD_PKG
# update
git checkout master
git pull
# date of 1st commit
COMMIT=`git rev-list --max-parents=0 HEAD`
# first commit of packages2.5.xml
DATE_1st_COMMIT=`git log --format=%cd --date=short $XML | tail -1`

# loop through n months before 
for m_before in $(seq 0 $MONTHS); do
    # e.g. 2018-07-01
    DATE_CHECK_OUT=`date -v-${m_before}m +%Y-%m-01`    
    
    if [[ "$DATE_CHECK_OUT" > "$DATE_1st_COMMIT" ]]; then
      # checkout version at the 1st date of a month
      git checkout `git rev-list -n 1 --before="$DATE_CHECK_OUT 00:00" master`
    
      # count the line of java code 
      cp "$XML" "$WD/$TMP/$DATE_CHECK_OUT-$XML"
         
    else 
      echo "$XML did not exist on $DATE_CHECK_OUT !"
    fi
done

# make sure HEAD back to master
git checkout master
DATE_CHECK_OUT=`date +%Y-%m-%d` 
cp "$XML" "$WD/$TMP/$DATE_CHECK_OUT-$XML"  

# back to WD 
cd $WD

