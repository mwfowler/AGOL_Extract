#' Get the difference in two times
#' @param time1 as.POSIXct(now()) formatted time value.  start time 
#' @param time2 as.POSIXct(now()) formatted time value.  end 
#'
#' @return string: formatted string expressing time difference in decimal seconds, minutes or hours
#' @export
#'
#' @examples coming soon
#' 
timeDelta <- function(time1, time2){
  time_diff = ""
  if(as.numeric(difftime(time2, time1, units = "secs"))<60){
    time_diff <- glue::glue(round(difftime(time2, time1, units = "secs"),2), ' Seconds')
  }else if(as.numeric(difftime(time2, time1, units = "mins"))<60){
    time_diff <- glue::glue(round(difftime(time2, time1, units = "mins"),2), ' Minutes')
  }else{
    time_diff <- glue::glue(round(difftime(time2, time1, units = "hours"),4), ' Hours')
  }
  return(time_diff)
}