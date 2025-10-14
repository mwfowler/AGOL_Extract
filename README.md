# AGOL_Extract
Package of common FAIB Data Analysis and Data Management team functions, focusing on functions to import vector into PG in the gr_skey grid lookup table.

### Contact

If you have any questions or inquiries about this R package contact:

Mike Fowler   
Data Scientist  
Office of the Chief Forester - Forest Science, Planning & Practices  
mike.fowler@gov.bc.ca  

### 1. Requirements
### 1. Requirements - Test Push from Local

### RDCOMClient Package in R 
  - For sending emails 
  install from this repo: 
  - devtools::install_github("omegahat/RDCOMClient")

#### Postgres
  -If exporting AGOL data to Posgtres a local server with PostGIS enabled is required

### 2. Environment Variables 
  - The following Environment Variables need to be set
  - ARCGIS_USER - AGOL User Name
  - ARCGIS_PASSWORD - AGOL Password


Graphic of the Process:

![Image](https://github.com/mwfowler/AGOL_Extract/blob/main/Images/AGOL_Extract_Graphic_DBeaver_TransparentBackground.png)

Input CSV Format:

![Image](https://github.com/mwfowler/AGOL_Extract/blob/main/Images/Input_CSV_Format.png)
