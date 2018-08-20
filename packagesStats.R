
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

require(ggplot2)
######### (2d version)
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



