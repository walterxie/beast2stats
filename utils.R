
# setwd("~/WorkSpace/beast2stats")

# get data frame of stats summary given a package-*.txt files in "dataDir" 
getAPackageStats <- function(dataDir="tmp", package="beast2") {
  if (!dir.exists(dataDir)) 
    stop("Cannot find data dir : ", dataDir, " in working path ", getwd(), " !")
  
  files <- list.files(path = dataDir, pattern = paste(package, ".*\\.txt$", sep="-"))
  if (length(files) < 1) 
    stop("Cannot find any stats summary file ", package, "-*.txt in ", dataDir, " in working path ", getwd(), " !")
    
  # lines of code, number of files
  stats.summary <- data.frame(file=character(0), LOC=integer(0), NOF=integer(0))
  
  # each file is a summary at one time stamp
  for (file in files) {
    # 43 src/test/beast/util/XMLTest.java
    # 125029 total, but if only 1 file then no total
    f = file.path(dataDir, file)
    if (!file.exists(f)) 
      stop("Cannot find summary log : ", f, " for package ",package, " !")
    
    stats <- try(read.table(f, header = F, stringsAsFactors = F))
    if (inherits(stats, 'try-error')) {
      warning("Summary log : ", f, " for package ",package, " is empty or not readable !")
      next
    }
    
    if (nrow(stats) > 0) {
      # num of files in total
      nofTot = nrow(stats)-1
      # lines of code in total
      locTot = stats[nrow(stats), 1]
      # if only 1 file then no total
      if (nofTot < 1) 
        nofTot=1
      
      stats.summary <- rbind(stats.summary, t(c(file=file, LOC=locTot, NOF=nofTot)))
    } else {
      warning("File ", f , " is empty !")
    }
  }
  
  # parsing date from file name
  stats.summary$date <- gsub("^.*-([0-9]+)-([0-9]+)-([0-9]+).txt", "\\1-\\2-\\3", stats.summary$file)
  
  # rbind messed up 
  stats.summary$LOC <- as.numeric(as.character(stats.summary$LOC))
  
  return(stats.summary)
}

# xml.full.path= "https://github.com/CompEvol/CBAN/raw/master/packages2.5.xml"
# return: package, version, url, dir
# dir is the best key to identifiy packages 
findAllUniquePackages <- function(xml.full.path) {
  require(xml2)
  cban <- read_xml(xml.full.path)
  
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
  
  cat("Find ", nrow(packages), " unique packages from ", xml.full.path, ".\n")
  return(packages)
}

# earliest date is min(pkg.his$date)
# return: date, package, version 
getPackagesHistory <- function(xml.dir="CBAN-XML") {
  if (!dir.exists(xml.dir)) 
    stop("Cannot find CBAN XML folder : ", xml.dir, " in working path ", getwd(), " !")
  
  files <- list.files(path = xml.dir, pattern = ".*\\.xml$")
  if (length(files) < 1) 
    stop("Cannot find any CBAN XML in ", xml.dir, " in working path ", getwd(), " !")
  
  pkg.his <- data.frame(stringsAsFactors = F)
  for (file in files) {
    f = file.path(xml.dir, file)
    if (!file.exists(f)) 
      stop("Cannot find CBAN XML : ", f, " !")
    
    date <- gsub("^([0-9]+)-([0-9]+)-([0-9]+)-.*.xml", "\\1-\\2-\\3", file)
    
    packages <- findAllUniquePackages(f)
    packages$date <- date
    
    # exclude beast2
    packages <- packages[packages$package != "BEAST", c("date","package","version","dir")]
    cat("Find ", nrow(packages), " packages exclude beast2 on ", date, ".\n")
    
    pkg.his <- rbind(packages, pkg.his)
  }
  return(pkg.his)
}


# adjust stats because of package commit dates not equivalent to package released dates in CBAN
adjustPackageStats <- function(all.stats.pre, pkg.his) {
  
}

