#' Sends an email from the Outlook Application on the machine using the address of that logged in user
#' @param to string: email address to send the email to
#' @param subject string: subject line of the email 
#' @param body string: email body text content
#'
#' @return nothing is returned
#' @export
#'
#' @examples coming soon
#' 
sendEmail <- function(to,subject,body){
  #--This could be a stumbling block for other package users
  #--May need to be clear in the README.md that you need to download and have this installed from a specific 
  #--repo before installing the agolextract package 
  #--devtools::install_github("omegahat/RDCOMClient")
  require(RDCOMClient) 
  
  OutlookOpenAlready <- AGOLextract::isOutlookRunning()
  OutApp <- COMCreate("Outlook.Application")
  outMail <- OutApp$CreateItem(0) # 0 represents olMailItem
  outMail[["To"]] <- to
  outMail[["subject"]] <- subject
  outMail[["body"]] <- body  
  
  sent <- outMail$Send()
  #--Wait for the message to be sent from the outbox
  repeat {
    Sys.sleep(0.5)    
    if (sent) {
      break
    }
  }
  #--Quit the application if it was closed when we got here
  if(!(OutlookOpenAlready)){
    print('Quitting Outlook')
    OutApp$Quit()  
  }
}