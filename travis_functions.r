quality_threshold <- function(quality_per_unit=2.25,descriptive_output=FALSE){
  # Computes the minimum quality percent level of an item to be worth picking up based on object shape in grid. Defaults to 2.25.
  # You may specify if you would like a printed description or just the 4-tuple as output. Defaults to 4-tuple output. Intended for
  # use in the Steam game, Path of Exile.
  classes <- c(3,4,6,8)
  quality <- 0
  restrict <- c(-1,-1,-1,-1)
  cont_check <- rep(TRUE,length(restrict))
  proceed <- TRUE
  while (proceed == TRUE){
    if (quality >= 20){
      proceed <- FALSE
    }
    margin <- quality/classes
    for (shape in c(1:length(margin))){
      if (cont_check[shape] == TRUE){
        if (margin[shape] >= quality_per_unit){
          restrict[shape] <- quality
          cont_check[shape] <- FALSE
        }
      }
    }
    quality <- quality+1
  }
  for (result in c(1:length(restrict))){
    if (restrict[result] == -1){
      restrict[result] <- "NA"
    }
  }
  if (descriptive_output == FALSE){
    Shape <- c("1x3","1x4","2x2","2x3","2x4")
    Quality_Percent <- c(restrict[1:2],restrict[2],restrict[3:4])
    restrict_frame <- data.frame(Shape,Quality_Percent)
    return(restrict_frame)
  }
  else{
    item_x3 <- paste("The minimum quality percentage for items one unit wide by three units tall {1x3} you should pick up are {",
                     restrict[1],"%} quality.",sep="")
    item_x4_1 <- paste("The minimum quality percentage for items one unit wide by four units tall {1x4} you should pick up are {",
                       restrict[2],"%} quality.",sep="")
    item_x4_2 <- paste("The minimum quality percentage for items two units wide by two units tall {2x2} you should pick up are {",
                       restrict[2],"%} quality.",sep="")
    item_x6 <- paste("The minimum quality percentage for items two units wide by three units tall {2x3} you should pick up are {",
                     restrict[3],"%} quality.",sep="")
    item_x8 <- paste("The minimum quality percentage for items two units wide by four units tall {2x4} you should pick up are {",
                     restrict[4],"%} quality.",sep="")
    return(writeLines(paste(item_x3,item_x4_1,item_x4_2,item_x6,item_x8,sep="\n")))
  }
}




load_GIS_lib <- function(){
  # Loads the most common plotting packages for geomapping in R
  x <- c("rgeos","tmap","ggmap","rgdal","maptools","dplyr","tidyr")
  lapply(x,library,character.only=TRUE)
}




appendwd <- function(addition){
  # Allows a user to set their working directory to a child path by passing a character containing the remaining filepath as input
  setwd(paste(gsub("/","\\\\",getwd()),addition,sep="\\"))
}




selection_by_location <-function(base_layer,selection_layer){
  ###*NOTE: CURRENTLY HAS ISSUES WITH OUTPUT*###
  # Takes a base layer object and selects all objects in a selection layer based on the base layer's ID field. Both input objects
  # must be of one of the three vector SpatialXDataFrame objects (i.e. all spatial data frame types except Grid). If no ID field
  #  exists in the base layer object, one is assigned.
  if (all(lapply(list(base_layer,selection_layer),class) %in% c("SpatialPointsDataFrame","SpatialLinesDataFrame",
                                                                 "SpatialPolygonsDataFrame"))==FALSE){
    return("base_layer input and selection_layer input must be of the 'SpatialXDataFrame' classes.")
  }
  if (require(rgdal) != TRUE){
    library(rgdal)
  }
  if (is.null(base_layer$ID)){
    for (i in c(1:length(county))){
      base_layer$ID <- i
    }
  }
  input <- 0
  if (input %in% base_layer$ID){
    input_logic <- vector(length = length(selection_layer))
    for (i in (1:length(selection_layer))){input_logic[i] <- gIntersects(base_layer[input+1,],selection_layer[i,])}
    # plot(selection_layer) ###Activate this line to graph the selection with respect to full context. If you add this line back in, 
    # be sure to add "add=TRUE" to next line
    plot(selection_layer[input_logic,],col="green")
    if (class(base_layer)=="SpatialPolygonsDataFrame"){
      baselines <- as(base_layer,"SpatialLinesDataFrame")
      plot(baselines[input+1,],col="blue",add=TRUE)}
    else {plot(base_layer[input+1],col="green",add=TRUE)}
  }
}




agg_shared_polypts <- function(input){
  # Collects all points from a SpatialPolygonDataFrame that are not unique to a single polygon
  ne_lin <- as(input,"SpatialLinesDataFrame")
  ne_pts <- as.data.frame(as(ne_lin,"SpatialPointsDataFrame"))
  ne_xcords <- ne_pts[,8]
  ne_ycords <- ne_pts[,9]
  ne_xuniq <- unique(ne_xcords)
  ne_yuniq <- unique(ne_ycords)
  ne_list <- ne_pts[,5]

  # This function collects a list
  long_count <- 0
  linRep_list <- list(mode="numeric",length=0)
  xRep_list <- list(mode="numeric",length=0)
  yRep_list <- list(mode="numeric",length=0)
  for (i in (1:length(unique(ne_xcords)))){
    xtru <- ne_xuniq[i] == ne_xcords
    xtru_val <- ne_xcords[xtru]
    if (length(xtru_val)>length(unique(xtru_val))){
      ytru_val <- ne_ycords[xtru]
      ytru <- ne_yuniq[i] == ne_ycords
      if (length(ytru_val)>length(unique(ytru_val))){
        if (length(ne_list[ne_xuniq[i] == ne_xcords]) == length(unique(ne_list[ne_xuniq[i] == ne_xcords]))){
          long_count <- long_count+1
          linRep_list[long_count] <- ne_list[i]
          xytru <- xtru==TRUE & ytru==TRUE
          xRep_list[long_count] <- unique(ne_xcords[xytru])
          yRep_list[long_count] <- unique(ne_ycords[xytru])
        }
      }
    }
  }

  # Make point list into SpatialPointsDataFrame:
  ne_replist <- cbind(xRep_list,yRep_list)
  ne_replist1 <- as.data.frame(ne_replist,col.names=c("x_cord","y_cord"),row.names = c(1:72))
  ne_replist2 <- data.matrix(ne_replist1, rownames.force = NA)
  ne_spt <- SpatialPoints(ne_replist2)
  ne_rep_pts <- SpatialPointsDataFrame(ne_spt,ne_replist1)
  ne_rep_pts$line <- linRep_list
  return(ne_rep_pts)
}




markov_chain <- function(init,trans,trials=100,return_final=FALSE){
  # Performs a markov chain procedure for an initial vector of length N with square transition matrix of dimension N. Accepts four
  # inputs: the initial vector, the transition matrix, the number of trials desired for iteration, and a variable that determines
  # the type and amount of output: if no 'return_value' is passed to the function, it will return the entire result chain from the
  # Markov process; if 'return_final' is passed 'TRUE', it will return the final probability as a result; if 'return_final' is
  # passed with a positive integer 'X', it will return the last 'X' probabilities from the procedure. The number of 'trials'
  # defaults to 100, and the type of output defaults to the entire chain. Will reject input and provide helpful feedback to fix
  # the issue if any of the following are true: 'trans' is not a square matrix, the length of 'init' does not match the dimension
  # of 'trans'

  # Checks to make sure the dimensions of 'init' and 'trans' are acceptable:
  if (dim(trans)[1] != dim(trans)[2]){
    return("'trans' must be a square matrix.")
  }
  if (dim(init)[2] != dim(trans)[1]){
    return("The rank of 'init' must be equal to the dimension of square matrix 'trans'.")
  }

  # Checks to make sure 'init' is a probability vector and that 'trans' is a transition matrix:
  L <- length(init)
  prob_check <- rep(0,L+1)
  prob_check[1] <- sum(init)
  for (i in c(1:L)){
    prob_check[i+1] <- sum(trans[i,])
  }
  prob_check_error <- abs(1-prob_check)
  if (all(prob_check_error<0.001)==FALSE){
    return("All probabality vectors must sum to 1. This also means that all rows of the transition matrix must sum to 1.")
  }

  # Checks 'trials' for validity:
  if (class(trials)=="numeric"){
    if (round(trials)==trials){
      if (trials>0){
      }
      else{
        return("Please enter a positive integer amount of trials to perform.")
      }
    }
    else{
      return("Cannot perform a non-integer amount of trials!")
    }
  }
  else{
    return("'trials' must be an integer.")
  }

  # Checks 'return_final' for validity before returning result:
  if ((class(return_final) %in% c("logical","numeric")) == FALSE){
    return("'return_final' must either be boolean or an integer.")
  }
  if (class(return_final)=="numeric"){
    if (round(return_final)==return_final){
      if (return_final>0){
      }
      else{
        return("Please enter a positive integer amount of entries to return.")
      }
    }
    else{
      return("Cannot return a non-integer number of entries!")
    }
  }

  # If all conditions are satisfied, performs the following:
  result <- c()
  iter_init <- init
  for (i in c(1:trials)){
    iter_init <- iter_init %*% trans
    result[i]=iter_init[6]
  }
  if (return_final==FALSE){
    return(result)
  }
  if (return_final==TRUE){
    return(tail(result,1))
  }
  else{
    return(tail(result,return_final))
  }
}
