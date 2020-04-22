

#--------- open librarys ---------
library(tidyverse)
library(reshape)
library(reshape2)
library(chron)
library(scales)
library(ggrepel)
library(gridExtra )
#--------- Links to data ---------
Link_WorldRawCases = 'https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_global.csv'
Link_WorldRawDeaths = 'https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_global.csv'
Link_USRawCases = 'https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_US.csv'
Link_USRawDeaths = 'https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_US.csv'

#--------- Backup function ---------
## Tries to get the online version.  If unavailable, uses the CSV.  If available, and does not match the CSV, replaces the CSV. 
Backupfunction <- function(Link, Name, SavedName, address){
  try(OnlineVersion <- suppressWarnings(read.csv(Link, stringsAsFactors = FALSE)),silent = TRUE)
  OnlineVersionFound = exists('Name')
  try(CSV  <- suppressWarnings(read.csv(paste(address,SavedName, sep ="/"),stringsAsFactors = FALSE)),silent = TRUE)
  CSVVersionFound = exists('CSV')
  if (!OnlineVersionFound & !CSVVersionFound){stop('No CSV or Online Version!')}
  if (OnlineVersionFound){
    if(!CSVVersionFound || !identical(CSV,OnlineVersion)  ) {write.csv(OnlineVersion,file = paste(address,SavedName, sep ="/"), row.names=FALSE)}
    return(OnlineVersion)
    }
  CSV
}

#--------- Get case data ---------
WorldRawCases    <- Backupfunction(Link = Link_WorldRawCases , SavedName = 'WorldRawCases.csv' , address = 'data')
WorldRawDeaths   <- Backupfunction(Link = Link_WorldRawDeaths, SavedName = 'WorldRawDeaths.csv', address = 'data')
USRawCases       <- Backupfunction(Link = Link_USRawCases    , SavedName = 'USRawCases.csv'    , address = 'data')
USRawDeaths      <- Backupfunction(Link = Link_USRawDeaths   , SavedName = 'USRawDeaths.csv'   , address = 'data')

#--------- Get reference data ---------
Country          <- read.table("data/CountryLookup.txt", header = TRUE, sep = "\t", stringsAsFactors = FALSE, quote = "")
WorldBank        <- read.table("data/WorldIndicatorsQuoted.csv", header = TRUE, sep = ",", fileEncoding = "UTF-8-BOM", stringsAsFactors = FALSE, quote = "\"")
Change           <- read.table("data/Change.txt", header = TRUE, sep = "\t", stringsAsFactors = FALSE,fileEncoding = "UTF-8-BOM")
Pop_State        <- read.table("data/Pop_States.csv", header = TRUE, sep = ",", stringsAsFactors = FALSE,fileEncoding = "UTF-8-BOM")
#--------- formatting  ---------
#Country:  Change Country column names for consistency 
names(Country)[names(Country) == "CountryCode"]     <- "iso2"
names(Country)[names(Country) == "CountryCodeLong"] <- "iso3"
Country[Country$iso3 == "NAM",]$iso3 = "NA"


#WorldBank:  Change WorldBank column names for consistency 
names(WorldBank)[names(WorldBank) == "Country.Name"] <- "CountryName"
names(WorldBank)[names(WorldBank) == "Country.Code"] <- "Alpha3"

#WorldBank: Pivot the data, keeping only the series code, but keeping the series name seperately for reference
WorldBankRef = distinct(WorldBank, Series.Code, Series.Name)
WorldBank$Value = NaN
WorldBank$Value[which(WorldBank$X2015..YR2015. != "..")] = WorldBank$X2015..YR2015.[which(WorldBank$X2015..YR2015. != "..")]
WorldBank$Value[which(WorldBank$X2016..YR2016. != "..")] = WorldBank$X2016..YR2016.[which(WorldBank$X2016..YR2016. != "..")]
WorldBank$Value[which(WorldBank$X2017..YR2017. != "..")] = WorldBank$X2017..YR2017.[which(WorldBank$X2017..YR2017. != "..")]
WorldBank$Value[which(WorldBank$X2018..YR2018. != "..")] = WorldBank$X2018..YR2018.[which(WorldBank$X2018..YR2018. != "..")]
WorldBank$Value[which(WorldBank$X2019..YR2019. != "..")] = WorldBank$X2019..YR2019.[which(WorldBank$X2019..YR2019. != "..")]
WorldBank <- subset(WorldBank, select = -c(Series.Name,X2015..YR2015.,X2016..YR2016.,X2017..YR2017.,X2018..YR2018.,X2019..YR2019.) )
WorldBank$Value <- as.numeric(WorldBank$Value)
WorldBank <- dcast(data = WorldBank[which(WorldBank$Series.Code !=""),], formula = CountryName +  Alpha3 ~ Series.Code, fun.aggregate = sum, value.var = "Value")

#Case data: Pivot the raw data, rename and combine
#get World raw case data
WorldRawCases <- melt(WorldRawCases, id=c('Province.State','Country.Region','Lat','Long')) %>% 
  mutate(Date = chron(dates = substring(as.character(.[,'variable'] ),2),format='m.d.y', out.format = 'd/m/y')) %>% 
  subset(select = -c(Lat, Long,variable ))
colnames(WorldRawCases) <- c('Province.State','Country','TotalCases',  'Date')
WorldRawCases <- WorldRawCases%>% group_by(Province.State,Country,Date) %>% summarise(TotalCases = sum(TotalCases))
#get World raw death data
WorldRawDeaths <- melt(WorldRawDeaths, id=c('Province.State','Country.Region','Lat','Long')) %>% 
  mutate(Date = chron(dates = substring(as.character(.[,'variable'] ),2),format='m.d.y', out.format = 'd/m/y')) %>% 
  subset(select = -c(Lat, Long,variable ))
colnames(WorldRawDeaths) <- c('Province.State','Country','TotalDeaths',  'Date')
WorldRawDeaths <- WorldRawDeaths%>% group_by(Province.State,Country,Date) %>% summarise(TotalDeaths = sum(TotalDeaths))
#Combine for world
World <- merge(WorldRawCases, WorldRawDeaths, by.x = c('Province.State','Country', 'Date'), )

#get US raw case data
USRawCases <- melt(USRawCases, id=c('UID','iso2','iso3','code3','FIPS','Admin2','Province_State','Country_Region','Lat','Long_','Combined_Key')) %>% 
  mutate(Date = chron(dates = substring(as.character(.[,'variable'] ),2),format='m.d.y', out.format = 'd/m/y')) %>% 
  subset(select = -c(Lat, Long_,variable )) %>% group_by(iso2,iso3,Province_State,Country_Region,Date) %>% summarize(TotalCases = sum(value))
#get US raw death data
USRawDeaths <- melt(USRawDeaths, id=c('UID','iso2','iso3','code3','FIPS','Admin2','Province_State','Country_Region','Lat','Long_','Combined_Key', 'Population')) %>% 
  mutate(Date = chron(dates = substring(as.character(.[,'variable'] ),2),format='m.d.y', out.format = 'd/m/y')) %>% 
  subset(select = -c(Lat, Long_,variable )) %>% group_by(iso2,iso3,Province_State,Country_Region,Date) %>% summarize(TotalDeaths = sum(value))
#Combine for US
US <-merge(USRawCases, USRawDeaths, by.x = c('iso2','iso3','Province_State','Country_Region', 'Date'), )

#Align datasets 
#US changes
US <- US %>% mutate(Country = 'United States') %>% subset(select = -c(Country_Region)) #US Remove columns
US <- US %>% mutate(Region = "North America",   Sub.region="North America")
#World Changes
World <- merge(World, Change, by.x='Country', by.y = 'Original', all.x = TRUE) #World fix names of countries to match lookup table
World[which(!is.na(World[,'Switch'])), 'Country'] = World[which(!is.na(World[,'Switch'])), 'Switch']
World <- World %>% subset(select=-c(Switch))
World <- merge(World, Country, by = 'Country',all.x = TRUE) #merge in the country lookup table 
names(World)[names(World) == "Province.State"] <- "Province_State"

#remove US from World, then add US detailed data
World <- World[which(World$iso2 != 'US'),]
Data <- rbind(World,US)
rm(US, Country, Change, USRawCases, USRawDeaths, World, WorldRawCases, WorldRawDeaths)

## here we have to make some decisons around where should be allowed to have provinces and where should not
#	Australia      *- Arguably should be aggregated however each state has a large population, differing response and special interest to me
#	Canada         *- Arguably should be aggregated but the West and East coasts both have large populations, seperated so far as to cause potential differences? 
#	China          *- Provinces are large (the size of other countries), and were affected differently
#	Denmark         - Has territories. Though these are very different from mainland denmark, the population is so small it warrents grouping 
#	France          - Has territories. Though these are very different from mainland denmark, the population is so small it warrents grouping 
# Netherlands     - Has territories. Though these are very different from mainland denmark, the population is so small it warrents grouping 
#	United Kingdom  - Has territories. Though these are very different from mainland denmark, the population is so small it warrents grouping 
#	United States  *- States are large (the size of other countries), and very different - should be treated seperately
head(Data)
view(Data[which(Data$Province_State =='New York'),])
view(Data[which(!is.na(Data$Source)),])


Data <- merge(Data, WorldBank[,c('CountryName','SP.POP.TOTL')], by.x = 'Country', by.y = 'CountryName', all.x = TRUE)
Data <- merge(Data, Pop_State, by.x = c('Country','Province_State'), by.y = c('Country','State'), all.x = TRUE)
colnames(Data)
Data[which(!is.na(Data$Pop)),'SP.POP.TOTL'] = Data[which(!is.na(Data$Pop)),'Pop']
Data <- Data %>% subset(select = -c(Source, Pop))
names(Data)[names(Data) == "SP.POP.TOTL"] <- "Pop"
Data$DateText <- as.character(Data$Date)


#  ----------------Data basic input finished  ----------------

#  ---------------- Add useful metrics ----------------
#Add daily totals by Provice/Country
Data<- Data[order(Data$Country,Data$Province_State, Data$Date),] %>% 
  group_by(Country, Province_State) %>% 
  mutate(Cases = c(TotalCases[1],diff(TotalCases)), Deaths = c(TotalCases[1],diff(TotalDeaths)))

#Add the week
Data$EndOfWeek <- Data$Date+ (7 - as.numeric(Data$Date+4))%%7 
# We will use the threshold of n daily cases recorded to normalise the data
MinCasesN = 10
MinDateCountry        <- Data %>% group_by(Country,Date) %>% summarize(Cases = sum(Cases)) %>% filter(Cases>MinCasesN)%>% summarize(CountryDate = min(Date))
MinDateProvince_State <- Data %>% filter(Cases>MinCasesN) %>% group_by(Country,Province_State) %>% summarize(StateDate = min(Date))
Data <- 
  merge(x = Data, y = MinDateCountry, by ='Country') %>% 
  merge(y = MinDateProvince_State,by=c('Country', 'Province_State')) %>% 
  mutate(CNDays = as.numeric(Date - CountryDate), StDays = as.numeric(Date - StateDate)) %>%
  select(-c(CountryDate,StateDate ))

#Add the Cases per capita
Data$CasesPC <- Data$Cases / Data$Pop
Data$TotalCasesPC <- Data$TotalCases / Data$Pop
Data$Cn_Pr = paste(Data$Province_State, Data$Country, sep = ", ")
Data[which(Data$Province_State == "" ),'Cn_Pr']= Data[which(Data$Province_State == "" ),'Country']


OData <- Data

#FROM OUTLIERS
removeOutliers <- function(D, CnP, Col, Date){
  Date = chron(dates = Date,format='d/m/y')
  NextDay = chron(dates = Date+1,format='d/m/y')
  PriorDay = chron(dates = Date-1,format='d/m/y')
  Outlier <- D[which(D$Cn_Pr == CnP & D$Date == Date  ), Col ]
  NewValue = mean(D[which(D$Cn_Pr == CnP & (D$Date == NextDay | D$Date == PriorDay  )), Col ])
  Disperse  = Outlier - NewValue
  D[which(D$Cn_Pr == CnP & D$Date == Date  ), Col ] = NewValue
  Values = D[ which(D$Cn_Pr == CnP & D$Date < Date  ), Col ] 
  D[ which(D$Cn_Pr == CnP & D$Date < Date  ), Col ]  = Values + Values / sum(Values) * Disperse
}
#
removeOutliers(Data, "Hubei, China", 'Deaths', '17/04/20')
removeOutliers(Data, "Hubei, China", 'Cases', '17/04/20')
removeOutliers(Data, "Hubei, China", 'Cases', '13/02/20')
removeOutliers(Data, "France", 'Cases', '12/04/20')
#Deaths
#17/04/20 - Hubei, China 

#Cases
#17/04/20 - Hubei, China 
#13/02/20 - Hubei, China 
#12/04/20 - France

head(Data)


Data$R_Cases <- pull(split(Data,Data$Cn_Pr) %>%  #pull the first and only line of data back
                        lapply(function(i){
                          RollingCases <- RcppRoll::roll_sum(i$Cases,4, fill=NA, align="right") /4
                          data.frame(RollingCases)
                        }) %>% bind_rows)

Data$R_Deaths <- pull(split(Data,Data$Cn_Pr) %>%  #pull the first and only line of data back
                       lapply(function(i){
                         RollingDeaths <- RcppRoll::roll_sum(i$Cases,4, fill=NA, align="right") /4
                         data.frame(RollingDeaths)
                       }) %>% bind_rows)




