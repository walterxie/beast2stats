
# work path
setwd("~/WorkSpace/beast2stats")
# load source
source("utils.R")

######### find all packages
packages <- findAllUniquePackages("https://github.com/CompEvol/CBAN/raw/master/packages2.6.xml")
packages <- correctURL(packages)
nrow(packages)
packages[1,]

# exclude beast2
packages <- packages[packages$dir != "beast2", c("package","version","dir","projurl")]
nrow(packages)


######### run bash

### run createStats.sh
for (i in 1:nrow(packages)) {
  pkg.dir = packages[i, "dir"]
  setwd("~/WorkSpace")
  # if folder not exist, git clone it
  if (!dir.exists(pkg.dir)) {
     projurl = packages[i, "projurl"]
     warning("Cannot find package dir : ", pkg.dir, " in ", getwd(), " !\n", "check out ", projurl)
     cmd <- paste("git clone ", projurl)
     system(cmd)
  }
  
  setwd("~/WorkSpace/beast2stats")
  cmd <- paste("./createStats.sh ", pkg.dir)
  system(cmd)
}

stats.date=system("date +%Y-%m-%d", intern = TRUE)
# such as 2019-08-14
cat("stats.date = ", stats.date, ".\n\n")
# author: Walter Xie
### check if createStats.sh works
err = c()
for (pkg.dir in packages$dir) {
  setwd("~/WorkSpace/beast2stats/tmp")
  # such as beast2-2019-08-14
  dir.name = paste0(pkg.dir, "-", stats.date)
  if (!dir.exists(dir.name) || length(list.files(dir.name)) < 1)
    err = c(err, dir.name)
}  
cat("Tested", nrow(packages), "packages: \n")
if (length(err) > 0) 
  stop("createStats.sh failed in ", paste(err, collapse=", "), " ! ")
cat("All passed.\n")


### adjust stats bash
setwd("~/WorkSpace/beast2stats")
system("./adjustStats.sh")
######### finish bash

######### packages stats excluding beast2 
# work path
setwd("~/WorkSpace/beast2stats")
# load source
source("utils.R")

all.stats <- data.frame(stringsAsFactors = F)
for (i in 1:nrow(packages)) {
  package <- packages$package[i]
  pkg.dir <- packages$dir[i]
  dataDir = file.path("tmp", paste(pkg.dir, stats.date, sep = "-"))
  stats.summary <- getAPackageStats(dataDir=dataDir, package=pkg.dir)
  if (nrow(stats.summary) > 0) {
    stats.summary$package <- package
    stats.summary$dir <- pkg.dir
    all.stats <- rbind(all.stats, stats.summary)
  } else {
    warning("Packages ", packages , " has no summary log file !")
  }
}
all.stats[1:5,]
# no adjust
LOC <- aggregate(all.stats$LOC, list(date = all.stats$date), sum)
PKG <- aggregate(all.stats$LOC, list(date = all.stats$date), length)
LOC.PKG <- merge(LOC, PKG, by="date")
colnames(LOC.PKG )[2:3] <- c("LoC", "NoP")

# check the plot
require(ggplot2)
ggplot(LOC.PKG, aes(x = date, group = 1)) + 
  geom_line(aes(y = LoC, colour = "LoC others")) + 
  geom_line(aes(y = NoP*10000, colour = "Packages")) + 
  scale_y_continuous(sec.axis = sec_axis(~./10000, name = "Number of packages")) + 
  labs(y = "Lines of Java code", x = "Date", colour = "Statistics") +
  theme_bw() +
  theme(axis.text.x = element_text(angle = 315, hjust = -0.05), legend.position = c(0.1, 0.8)) 
  

######### adjust stats to make the plot suiting with the released time-line in CBAN
# pull CBAN XML history
pkg.his <- getPackagesHistory(xml.dir="CBAN-XML")
pkg.his[1,]
aggregate(package ~ xml + date, pkg.his, length)
 
last.date <- max(pkg.his$date)
last.xml <- max(pkg.his$xml)
cat("There are ", nrow(pkg.his[pkg.his$date==last.date & pkg.his$xml==last.xml, ]), 
    " packages (exl. beast2) on the last date ", last.date, " according to ", last.xml, ".\n")

# adjust all.stats by pkg.his
all.stats.adj <- merge(pkg.his[,c("date","dir")], all.stats, by=c("date","dir"))
#"2018-04-01" "2018-08-01"
range(all.stats.adj$date)

# add stats on the last date in pkg.his into all.stats.adj
all.stats.last <- all.stats[all.stats$date==max(all.stats$date),]
all.stats.adj.last <- merge(pkg.his[pkg.his$date==last.date,c("date","dir")], 
                              all.stats.last[,c("dir","file","LOC","NOF","package")], by="dir")

# filter out earlier packages not exists in pkg.his
earlier.date <- min(pkg.his$date)
earlier.pkg.dir <- pkg.his[pkg.his$date==earlier.date, "dir"]
earlier.xml <- min(pkg.his$xml)
cat("There are ", length(earlier.pkg.dir), " packages (exl. beast2) on ", 
    earlier.date, " according to ", earlier.xml, ".\n")

all.stats.adj.earlier <- all.stats[all.stats$date < earlier.date & all.stats$dir %in% earlier.pkg.dir,]

# combine
all.stats.adj <- rbind(all.stats.adj.last, all.stats.adj, 
                       all.stats.adj.earlier[,c("date","dir","file","LOC","NOF","package")])


######### final stats
LOC.summary <- aggregate(all.stats.adj$LOC, list(date = all.stats.adj$date), sum)
PKG.summary <- aggregate(all.stats.adj$LOC, list(date = all.stats.adj$date), length)

nrow(LOC.summary)
nrow(PKG.summary)
LoCNoP <- merge(LOC.summary, PKG.summary, by="date")
colnames(LoCNoP)[2:3] <- c("LoC", "NoP")
nrow(LoCNoP)
LoCNoP

write.table(LoCNoP, file = "other-packages.txt", sep = "\t", quote = F, row.names = F)

### add beast 2 core
package = "beast2"
dataDir = file.path("tmp", paste(package, stats.date, sep = "-"))

stats.summary <- getAPackageStats(dataDir=dataDir, package=package)
stats.summary[1:10,]
LoCNoP <- merge(LoCNoP, stats.summary[,2:4], by="date", all.x = T)
colnames(LoCNoP)[4] <- c("LoC.core") # LOC

require(ggplot2)
######### (2d version)
# choose 10000 as transformation
range(LoCNoP$LoC) / range(LoCNoP$NoP)
# copied from https://rpubs.com/MarkusLoew/226759
# group = 1, https://stackoverflow.com/questions/27082601/ggplot2-line-chart-gives-geom-path-each-group-consist-of-only-one-observation
p <- ggplot(LoCNoP, aes(x = date, group = 1)) + 
  geom_line(aes(y = LoC.core, colour = "LoC core")) +
  geom_line(aes(y = LoC, colour = "LoC others"))
  
# As the secondary axis can only show a one-to-one transformation of the right y-axis, 
# we’ll have to transform the the data that are shown on the secondary axis
# adding the relative number of packages, transformed to match roughly the range of lines of code
p <- p + geom_line(aes(y = NoP*10000, colour = "Packages"))

# now adding the secondary axis, following the example in the help file ?scale_y_continuous
# and, very important, reverting the above transformation
p <- p + scale_y_continuous(sec.axis = sec_axis(~./10000, name = "Number of packages"))

# reduce labels on x-axis to quarterly or 6-monthly using LoCNoP$date
len.date <- length(LoCNoP$date)
breaks <- rep("", len.date)
breaks[seq(1, len.date, by = 6)] <- LoCNoP$date[seq(1, len.date, by = 6)]
breaks[len.date] <- LoCNoP$date[len.date]
p <- p + scale_x_discrete(breaks = breaks)

# theme
p <- p + labs(y = "Lines of Java code", x = "Date", colour = "Statistics") +
  #coord_flip() +
  theme_bw() +
  theme(axis.text.x = element_text(angle = 315, hjust = -0.05), legend.position = c(0.1, 0.8)) 

# add release dates
b2releases <- data.frame(version=c("2.6.0","2.5.0","2.4.0","2.3.0","2.2.0","2.1.0","2.0.2"), 
              date=c("2019-08-01","2018-03-15","2016-02-24","2015-05-14","2015-01-27","2014-01-28","2013-04-16"))
b2releases$version <- paste0("v", b2releases$version)
b2releases$month <- gsub("^(.*)-(.*)-(.*)$", "\\1-\\2", b2releases$date) 
LoCNoP$month <- gsub("^(.*)-(.*)-(.*)$", "\\1-\\2", LoCNoP$date) 
# calculate position in x-axis 
b2releases$date.numeric <- gsub("^(.*)-(.*)-(.*)$", "\\3", b2releases$date)
b2releases$date.numeric <- round(as.numeric(b2releases$date.numeric) / 30, digits = 2)

b2releases$x <- match(b2releases$month, LoCNoP$month, nomatch = NA)
# rm NA rows
b2releases <- b2releases[!is.na(b2releases$x),]
b2releases$x <- b2releases$x + b2releases$date.numeric
b2releases

# guess txt y
y.max = round(max(LoCNoP$LoC), digits = -5)

p <- p + geom_vline(xintercept=b2releases$x,linetype=2, colour="grey") +
  geom_text(data=b2releases, aes(x=(x-1.6), y=rep(y.max,length(b2releases$x)),
                label=version), colour="darkgrey")

ggsave(file=file.path("figures", "beast2-stats-every6m.svg"), plot=p, width=10, height=6)
#ggsave(file=file.path("figures", "beast2-stats.svg"), plot=p, width=12, height=6)
#ggsave(file=file.path("figures", "other-packages.svg"), plot=p, width=12, height=6)


# bar plot
p <- ggplot(LOC.summary, aes(x=date, y=x)) +
  geom_bar(stat = "identity", fill="#56B4E9") +
  ylab("lines of Java code") + 
  coord_flip() +
  theme_bw()

ggsave(file=file.path("figures", "other-packages-LoC.svg"), plot=p, width=8, height=10)

p <- ggplot(PKG.summary, aes(x=date, y=x)) +
  geom_bar(stat = "identity", fill="#56B4E9") +
  ylab("number of packages") + 
  coord_flip() +
  theme_bw()

ggsave(file=file.path("figures", "other-packages-NoP.svg"), plot=p, width=8, height=10)


######### (3d version)
require(plotly)
LoCNoP$id <- seq_len(nrow(LoCNoP))
ms <- replicate(2, LoCNoP, simplify = F)
ms[[2]]$NoP <- 0
m <- group2NA(dplyr::bind_rows(ms), "id")

scene = list(camera = list(eye = list(x = -0.25, y = 1.25, z = 1.25)), 
             xaxis = list(nticks = 60, tickangle = 270),
             yaxis = list(title = 'lines of Java code'),
             zaxis = list(title = 'number of packages'),
             aspectmode = "manual", aspectratio = list(y=0.8, x=1, z=0.8))
plot_ly(showlegend = F) %>%
  add_markers(data = LoCNoP, x = ~date, y = ~LoC, z= ~NoP) %>%
  add_paths(data = m, x = ~date, y = ~LoC, z= ~NoP) %>% 
  layout(title = "Other packages excluding BEAST 2 core", scene = scene)


######## in development ######## 
LoCNoP$LoC <- as.numeric(as.character(LoCNoP$LoC))
LoCNoP$NoP <- as.numeric(as.character(LoCNoP$NoP))

require(reshape2)
# rm 1st col file name
all.stats.melt <- melt(all.stats, id='package')
all.stats.melt$value<-as.numeric(all.stats.melt$value)

#create plots
p <- ggplot(all.stats.melt, aes(x=date, y=value, group=variable)) +
  geom_area(aes(fill = variable)) +
  scale_y_log10("number")



