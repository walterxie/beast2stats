
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
# rm any package not knowing source
packages <- packages[!grepl("http|zip", packages$dir),]
# rm orgization
packages$dir <- gsub("^.*/", "", packages$dir)

nrow(packages)


######### run bash
packages <- packages[packages$dir != "beast2", c("package","version","dir")]
nrow(packages)

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







