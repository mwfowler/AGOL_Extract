#-------------------------------------------------------------------------------
#--Script to Extract ArcGIS Online (AGOL) Web Layers to Postgres and/or Geopackage

#--Mike Fowler
#--Office of the Chief Forester
#--Forest Science, Planning & Practices Branch 
#--October 8, 2025
#-------------------------------------------------------------------------------
#' Extract ArcGIS Online (AGOL) Web Feature Layers to Postgres and/or Geopackage
#' @param input_file string: input csv file defining the AGOL web layers to extract
#' @param agol_portal string: address of the AGOL portal containing the web layers to extract
#' @param pg_db string:  name of the destination Postgres database (if applicable)
#' @param pg_host string:  host of the destination Postgres database (if applicable)
#' @param pg_port integer:  port of the destination Postgres database (if applicable)
#' @param pg_user string:  user of the destination Postgres database (if applicable)
#' @param pg_password string:  password of the destination Postgres database (if applicable)
#' @param resultant_table name of the existing resultant table.
#' @param email_to string: email address to send to, if blank/NA then no email sent
#'
#' @return nothing is returned
#' @export
#'
#' @examples coming soon
agolExtract <- function(input_file,
                 agol_portal, 
                 pg_db,pg_host,pg_port,pg_user,pg_password,
                 email_to=NA){
  tryCatch(
    {
      #--Suppress warnings
      options(warn = -1)
      #-------------------------------------------------------------------------------
      #--Postgres connection information 
      #-------------------------------------------------------------------------------
      #--directory where this script is located
      #dir <- getCurrentFileLocation()
      csv_file <- input_file
      #csv_file <- file.path(dir, input_file)
      #wd <- dir
      #-------------------------------------------------------------------------------
      #--Get a authorization token to our AGOL Portal 
      #-------------------------------------------------------------------------------
      token <- arcgisutils::auth_user(
        username = Sys.getenv("ARCGIS_USER"),
        password = Sys.getenv("ARCGIS_PASSWORD"),
        host = agol_portal,
        expiration = 60
      )
      arcgisutils::set_arc_token(token)
      #-------------------------------------------------------------------------------
      #--Now we loop through the input CSV file 
      input_csv <- read.csv(csv_file, header=TRUE)
      #--Create a dataframe to track what we update.  Will use this after to send an update email
      log_df <- data.frame(
        WebLayer=c(),ServiceUrl=c(),Query=c(),OutPGSchema=c(),OutGPKG=c(),OutTable=c(), 
        TimeStart=c(),cTimeEnd=c(),TimeElapse=c()
      )
      for (i in 1:nrow(input_csv)) {
        #--Only process the active records
        if (input_csv$ACTIVE[i]=='Y'){
          time_start <- as.POSIXct(lubridate::now())
          #--Pull the values from the CSV into variables
          web_layer <- input_csv$WEB_LAYER[i]
          #layer_index <- input_csv$LAYER_INDEX[i]
          service_url <- input_csv$SERVICE_URL[i]
          query <- input_csv$QUERY[i]
          out_schema <- input_csv$OUT_PG_SCHEMA[i]
          out_gpkg <- input_csv$OUT_GPKG[i]
          out_table <- input_csv$OUT_TABLE[i]
          comments <- input_csv$COMMENTS[i]
          #--Get down to business
          print('-----------------------------------------------------------')
          print(glue::glue('Processing {web_layer}'))
          print(glue::glue('Time Start: {time_start}'))
          #--Connect to the AGOL Web Layer Service URL 
          service_info <- arcgislayers::arc_open(service_url)
          layer <- service_info
          #--Get the individual layer from the Web Layer (potentially a group layer)
          #layer <- get_layer(service_info, 0)
          #layer <- get_layer(service_info)
          #--Get the data, apply the query if supplied
          if(!is.na(query) & trimws(query) != ""){
            data <- arcgislayers::arc_select(layer, where = query)
          }else{
            data <- arcgislayers::arc_select(layer)
          }
          #--Create and SF object from our data
          sf_object <- sf::st_as_sf(data, geometry=df$geometry, crs = service_info$spatialReference$latestWkid)
          #plot(st_geometry(sf_object))
          #--Drop problem fields (SE_ANNO_CAD_DATA must be here, it's a list field and throws an error)
          drop_fields <- c("SE_ANNO_CAD_DATA","SHAPE__AREA", "SHAPE__LENGTH", "FEATURE_AREA", "FEATURE_PERIMETER", 
                           "FEATURE_LENGTH_M")  #"FEATURE_AREA_SQM"
          sf_object <- sf_object[,!(toupper(names(sf_object)) %in% drop_fields)]
          #----------------------------------------------------------------------------------------
          #--Extract the layer to Geopackage, if specified
          #----------------------------------------------------------------------------------------
          if(!is.na(out_gpkg)){
            print(glue::glue('----Extracting Web Layer to Geopackage {out_gpkg}:{out_table}'))
            sf::st_write(sf_object, file.path(out_gpkg), layer = out_table, driver = "GPKG", append = FALSE)  
          }
          #----------------------------------------------------------------------------------------
          #--Extract the layer to Postgres, if specified
          #----------------------------------------------------------------------------------------
          if(!is.na(out_schema)){
            print(glue::glue('----Extracting Web Layer to Postgres {out_schema}.{out_table}'))
            conn <- DBI::dbConnect(RPostgres::Postgres(),
                              dbname = pg_db,
                              host = pg_host,
                              port = pg_port,
                              user = pg_user,
                              password = pg_password)
            #--Write the layer out to Postgres
            sf::st_write(obj = sf_object,
                     dsn = conn,
                     DBI::Id(schema=out_schema, 
                        table = tolower(out_table)),
                     append = FALSE, # Set to TRUE to append data to an existing table
                     delete_layer = TRUE)
            #--Add a comment to the table
            upd_time <- format(Sys.time(), "%A, %B %d, %Y %H:%M:%S %Z")
            DBI::dbExecute(conn, glue::glue("COMMENT ON TABLE {out_schema}.{out_table} IS '{comments} \nUpdate Time: {upd_time}';"))
            
            #-Disconnect from Postgres
            DBI::dbDisconnect(conn)
          }
          time_end <- as.POSIXct(lubridate::now())
          time_elapse <- agolextract::timeDelta(time_start, time_end)
          print('')
          print('Processing Complete')
          print(glue::glue('Time Finished: {time_end}'))
          print(glue::glue('Total Elapsed: {time_elapse}'))
          print('-----------------------------------------------------------')
          #--Add a row to our logging dataframe
          log_row <- data.frame(WebLayer = web_layer, ServiceUrl = service_url,Query=query,OutPGSchema=out_schema,
                                OutGPKG=out_gpkg,OutTable=out_table,
                                TimeStart=time_start,TimeEnd=time_end,TimeElapse=time_elapse)
          log_df <- rbind(log_df, log_row)
        }
      }
      #-------------------------------------------------------------------------------
      #---Send an email here
      #-------------------------------------------------------------------------------
      if(!is.na(email_to) | trimws(email_to) != ""){
        datestr <- format(Sys.time(), '%A, %B %d, %Y %H:%M:%S')
        body <- ""
        for (j in 1:nrow(log_df)) {
          body <- paste0(body, 
                         "------------------------------------------------------------",
                         "\n")
          row <- log_df[j,]
          for (k in colnames(row)){
            body <- paste(body, k,":",row[1,k], "\n")
          }
          body <- paste0(body, 
                         "------------------------------------------------------------",
                         "\n")
        }
        subj <- paste0("AGOL Extract: ", datestr)
        email_sent <- agolextract::sendEmail(to=email_to,
                                subject=subj,
                                body=body)
        
      }  
    },
    error = function(cond){#--Put warnings back on 
      options(warn = 0)
      message(conditionMessage(cond))
    }, 
    finally = {options(warn = 0)}
  )
}