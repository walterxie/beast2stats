
# work path
setwd("~/WorkSpace/beast2stats")
# load source
source("utils.R")

dataDir = "tmp-2018-08-08"
package = "beast2"

stats.summary <- getAPackageStats(dataDir=dataDir, package=package)
stats.summary

require(ggplot2)
# bar plot
p <- ggplot(stats.summary, aes(x=date, y=LOC)) +
  geom_bar(stat = "identity", fill="#56B4E9") +
  ylab("lines of Java code") + 
  coord_flip() +
  theme_bw()

# create svg for website
# require X11 for Mac: https://stackoverflow.com/questions/38952427/include-cairo-r-on-a-mac
ggsave(file=file.path("figures", paste0(package,".svg")), plot=p, width=8, height=10)

