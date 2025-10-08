#' Deterimine if Outlook Applicatinon is currently running
#'
#' @return BOOLEAN (TRUE/FALSE)
#' @export
#'
#' @examples coming soon

isOutlookRunning <- function() {
  # Execute the tasklist command to get a list of running processes
  # The /FI "IMAGENAME eq outlook.exe" filters for the Outlook process
  command_output <- system('tasklist /FI "IMAGENAME eq outlook.exe"', intern = TRUE)
  
  # Check if "outlook.exe" is present in the command output
  # If the output contains "outlook.exe", it means Outlook is running
  if (any(grepl("outlook.exe", command_output, ignore.case = TRUE))) {
    return(TRUE)
  } else {
    return(FALSE)
  }
}