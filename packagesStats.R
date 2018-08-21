
######### find all packages
require(xml2)
cban <- read_xml("https://github.com/CompEvol/CBAN/raw/master/packages2.5.xml")

# get all the <package>s
pkgs <- xml_find_all(cban, "//package")
names <- trimws(xml_attr(pkgs, "name"))
versions <- trimws(xml_attr(pkgs, "version"))
urls <- trimws(xml_attr(pkgs, "url"))

packages <- data.frame(package=names, version=versions, url=urls, stringsAsFactors = F)
# pick up latest version 
packages <- packages[!duplicated(packages$package,fromLast = T), ]

# guess package directory names
packages$dir <- gsub(".*github.com/(.*)/releases.*", "\\1", packages$url)
packages$dir <- gsub(".*bitbucket.org/(.*)/raw.*", "\\1", packages$dir)
# rm any package not knowing source, e.g. STACEY, DENIM
packages <- packages[!grepl("http|zip", packages$dir),]
# rm orgization
packages$dir <- gsub("^.*/", "", packages$dir)
nrow(packages)

# exclude beast2
packages <- packages[packages$dir != "beast2", c("package","version","dir")]
nrow(packages)


######### run bash
for (pkg.dir in packages$dir) {
  setwd("~/WorkSpace")
  if (!dir.exists(pkg.dir)) 
    stop("Cannot find package dir : ", pkg.dir, " in ", getwd(), " !")
  
  setwd("~/WorkSpace/beast2stats")
  cmd <- paste("./createStats.sh ", pkg.dir)
  system(cmd)
}

######### packages stats excluding beast2 
# work path
setwd("~/WorkSpace/beast2stats")
# load source
source("utils.R")

all.stats <- data.frame(stringsAsFactors = F)
for (pkg.dir in packages$dir) {
  dataDir = paste(pkg.dir, "2018-08-13", sep = "-")
  stats.summary <- getAPackageStats(dataDir=dataDir, package=pkg.dir)
  if (nrow(stats.summary) > 0) {
    stats.summary$package <- pkg.dir
    all.stats <- rbind(all.stats, stats.summary)
  } else {
    warning("Packages ", packages , " has no summary log file !")
  }
}

LOC.summary <- aggregate(all.stats$LOC, list(date = all.stats$date), sum)
PKG.summary <- aggregate(all.stats$LOC, list(date = all.stats$date), length)

nrow(LOC.summary)
nrow(PKG.summary)
LoCNoP <- merge(LOC.summary, PKG.summary, by="date")
colnames(LoCNoP)[2:3] <- c("LoC", "NoP")
nrow(LoCNoP)

write.table(LoCNoP, file = "other-packages.txt", sep = "\t", quote = F, row.names = F)


require(ggplot2)
######### (2d version)
# choose 10000 as transformation
range(LoCNoP$LoC) / range(LoCNoP$NoP)
# copied from https://rpubs.com/MarkusLoew/226759
p <- ggplot(LoCNoP, aes(x = date, group = 1)) + 
  geom_line(aes(y = LoC, colour = "LoC"))
# https://stackoverflow.com/questions/27082601/ggplot2-line-chart-gives-geom-path-each-group-consist-of-only-one-observation

# As the secondary axis can only show a one-to-one transformation of the right y-axis, 
# we’ll have to transform the the data that are shown on the secondary axis
# adding the relative number of packages, transformed to match roughly the range of lines of code
p <- p + geom_line(aes(y = NoP*10000, colour = "NoP"))

# now adding the secondary axis, following the example in the help file ?scale_y_continuous
# and, very important, reverting the above transformation
p <- p + scale_y_continuous(sec.axis = sec_axis(~./10000, name = "Number of packages"))

p <- p + labs(y = "Lines of Java code", x = "Date", colour = "Statistics") +
  #coord_flip() +
  theme_bw() +
  theme(axis.text.x = element_text(angle = 315, hjust = -0.05), legend.position = c(0.9, 0.2)) 

# add release dates
b2releases <- data.frame(version=c("2.5.0","2.4.0","2.3.0","2.2.0","2.1.0","2.0.2"), 
              date=c("2018-03-15","2016-02-24","2015-05-14","2015-01-27","2014-01-28","2013-04-16"))
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

p <- p + geom_vline(xintercept=b2releases$x,linetype=2, colour="grey") +
  geom_text(data=b2releases, aes(x=(x-1.5), y=rep(380000,length(b2releases$x)),
                label=version), colour="darkgrey")

ggsave(file=file.path("figures", "other-packages.svg"), plot=p, width=12, height=6)


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



