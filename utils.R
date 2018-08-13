
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

