# Lines of Code

The lines of Java code as a function of time (per month) in the last 5 years.

## BEAST 2 core

![BEAST 2 core](figures/beast2.svg)

## Other packages excluding BEAST 2 core

The lines of Java code of other packages excluding BEAST 2 core as a function of time (per month) in the last 5 years.
But there were two packages not included in this summary because the source code was not available by then.

![packages LoC](figures/other-packages-LoC.svg)

The number of other packages created by then as a function of time (per month) in the last 5 years.

![packages NoP](figures/other-packages-NoP.svg)


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

