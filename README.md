# Lines of Code

The lines of Java code as a function of time (per month) in the last 5 years.

## BEAST 2 core

![BEAST 2 core](figures/beast2.svg)

## BEAST 2 packages

TODO


# Pipeline

```bash
# source code has to be ready before analysis
cd ~/WorkSpace
git clone https://github.com/CompEvol/beast2.git
ls

# check out beast2stats project
git clone https://github.com/walterxie/beast2stats.git

# start pipeline
cd ~/WorkSpace/beast2stats
# save code stats to *.txt in tmp-yyyy-mm-dd
PACKAGE="beast2"
./createStats.sh $PACKAGE

# create *.svg in figures
Rscript beast2Stats.R
```

