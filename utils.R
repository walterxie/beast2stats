# author: Walter Xie
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
  projectURLs <- trimws(xml_attr(pkgs, "projectURL"))
  description <- trimws(xml_attr(pkgs, "description"))
  
  packages <- data.frame(package=names, version=versions, url=urls, projurl=projectURLs, description=description, stringsAsFactors = F)
  # pick up latest version 
  packages <- packages[!duplicated(packages$package,fromLast = T), ]
  
  # find the source url for git
  packages$srcurl <- packages$projurl
  packages <- correctSrcURL(packages) 
  
  # rm any package not knowing source, e.g. STACEY, DENIM
  rmpkgurl <- packages[!grepl("github|bitbucket", packages$srcurl),"srcurl"]
  cat("Remove", length(rmpkgurl), "packages : ", 
      paste(rmpkgurl, collapse = ", "), ", which not providing source.\n")
  # pick up pkgs having source url
  packages <- packages[grepl("github|bitbucket", packages$srcurl),]
  
  # guess package directory names
  packages$dir <- gsub("^.+/(.*)/$", "\\1", packages$srcurl)
  packages$dir <- gsub("^.+/(.*)$", "\\1", packages$dir)
  
  cat("Find ", nrow(packages), " unique packages from ", xml.full.path, ".\n")
  return(packages[with(packages, order(package, dir)), ])
}

# correct url for git clone
correctSrcURL <- function(packages) {
   packages$srcurl <- gsub("^.*beast2.org/snapp/.*", "https://github.com/BEAST2-Dev/SNAPP/", packages$srcurl)
   packages$srcurl <- gsub("^.*beast2.org.*", "https://github.com/CompEvol/beast2/", packages$srcurl)
   packages$srcurl <- gsub("^.*tgvaughan.github.io/bacter.*", "https://github.com/tgvaughan/bacter/", packages$srcurl)
   packages$srcurl <- gsub("^.*tgvaughan.github.io/EpiInf.*", "https://github.com/tgvaughan/epiinf/", packages$srcurl)
   packages$srcurl <- gsub("^.*tgvaughan.github.io/MASTER.*", "https://github.com/tgvaughan/MASTER/", packages$srcurl)
   packages$srcurl <- gsub("^.*tgvaughan.github.io/MultiTypeTree.*", "https://github.com/tgvaughan/MultiTypeTree/", packages$srcurl)
   packages$srcurl <- gsub("^.*taming-the-beast.org/tutorials/Mascot.*", "https:/github.com/nicfel/Mascot/", packages$srcurl)
   packages$srcurl <- gsub("^.*taming-the-beast.org/tutorials/Reassortment.*", "https:/github.com/nicfel/CoalRe/", packages$srcurl)
   packages$srcurl <- gsub("^.*bModelTest/wiki.*", "https://github.com/BEAST2-Dev/bModelTest", packages$srcurl)
   packages$srcurl <- gsub("^.*nested-sampling/wiki.*", "https://github.com/BEAST2-Dev/nested-sampling", packages$srcurl)
   packages$srcurl <- gsub("^.*MGSM/wiki.*", "https://github.com/BEAST2-Dev/MGSM", packages$srcurl)
   return(packages)
}


# earliest date is min(pkg.his$date)
# return: "date","package","version","dir","xml" 
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
    xml <- gsub("^([0-9]+)-([0-9]+)-([0-9]+)-(.*).xml", "\\4.xml", file)
    
    packages <- findAllUniquePackages(f)
    packages$date <- date
    packages$xml <- xml
    
    # exclude beast2
    packages <- packages[packages$package != "BEAST", c("date","package","version","dir","xml")]
    cat("Find ", nrow(packages), " packages exclude beast2 on ", date, " from ", xml, ".\n")
    
    # if date exists for multiple versions (e.g. 2.5.xml, 2.6 xml)
    if (date %in% pkg.his$date) {
       pre.version.pkg <- nrow(pkg.his[pkg.his$date == date, ])
       # packages >= prevous version
       if (nrow(packages) >= pre.version.pkg) {
         # rm prevous version and add last version
         pkg.his <- pkg.his[pkg.his$date != date, ]
         pkg.his <- rbind(packages, pkg.his)
         
         cat("Remove ", pre.version.pkg, " packages in ", unique(pkg.his[pkg.his$date == date, "xml"]), 
             " add ", nrow(packages),  " packages in ", xml, " on ", date, ".\n")
       } else {
         cat("Keep ", pre.version.pkg, " packages in ", unique(pkg.his[pkg.his$date == date, "xml"]), 
             " ignore ", nrow(packages),  " packages in ", xml, " on ", date, ".\n")
       }   
    } else {
      pkg.his <- rbind(packages, pkg.his)    
    }   
    
  }
  return(pkg.his)
}

# if using multiple versions (e.g. 2.5.xml, 2.6 xml), 
# use last version only if its packages >= prevous version
correctPackageHistory <- function(pkg.his) {



}

# adjust stats because of package commit dates not equivalent to package released dates in CBAN
adjustPackageStats <- function(all.stats.pre, pkg.his) {
  
}

