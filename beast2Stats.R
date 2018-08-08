


setwd("~/WorkSpace/beast2stats")

dataDir = "tmp-2018-08-08"
package = "beast2"

files <- list.files(path = dataDir, pattern = paste("beast2", ".*\\.txt$", sep="-"))
length(files)
# lines of code, number of files
stats.summary <- data.frame(file=character(0), LOC=integer(0), NOF=integer(0))

for (file in files) {
  # 43 src/test/beast/util/XMLTest.java
  # 125029 total
  f = file.path(dataDir, file)
  # 1st col is num of lines, 2nd col is file, last row is total
  stats = read.table(f, header = F, stringsAsFactors = F)
  
  if (nrow(stats) > 0) {
    # num of files in total
    nofTot = nrow(stats)-1
    # lines of code in total
    locTot = stats[nrow(stats), 1]
    
    stats.summary <- rbind(stats.summary, t(c(file=file, LOC=locTot, NOF=nofTot)))
  } else {
    warning("File ", f , " is empty !")
  }
}

# parsing date from file name
stats.summary$date <- gsub("^.*-([0-9]+)-([0-9]+)-([0-9]+).txt", "\\1-\\2-\\3", stats.summary$file)

# rbind messed up 
stats.summary$LOC <- as.numeric(as.character(stats.summary$LOC))

require(ggplot2)
# bar plot
p <- ggplot(stats.summary, aes(x=date, y=LOC)) +
  geom_bar(stat = "identity", fill="#56B4E9") +
  ylab("lines of code") + 
  coord_flip() +
  theme_bw()

# create svg for website
# require X11 for Mac: https://stackoverflow.com/questions/38952427/include-cairo-r-on-a-mac
ggsave(file=file.path("figures", paste0(package,".svg")), plot=p, width=8, height=10)



######## in development
require(reshape2)
# rm 1st col file name
stats.melt <- melt(stats.summary[,-1], id='date')
stats.melt$value<-as.numeric(stats.melt$value)

require(ggplot2)
#create plots
p <- ggplot(stats.melt, aes(x=date, y=value, group=variable)) +
  geom_area(aes(fill = variable)) +
  scale_y_log10("number")







