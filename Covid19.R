library(tidyverse)
library(reshape)
library(reshape2)
library(chron)
library(scales)

#--------- loading and formatting of data ---------

#inital data load
Country <- read.table("data/CountryLookup.csv", header = TRUE, sep = ",", fileEncoding = "UTF-8-BOM", stringsAsFactors = FALSE)
Cases <-  read.csv("data/CountryLookup.csv", na.strings = "", fileEncoding = "UTF-8-BOM",stringsAsFactors = FALSE)
if(length(Cases)<10){Cases <-  read.csv("data/geographicdistribution.csv", na.strings = "", fileEncoding = "UTF-8-BOM",stringsAsFactors = FALSE)}
WorldBank <- read.table("data/WorldIndicatorsQuoted.csv", header = TRUE, sep = ",", fileEncoding = "UTF-8-BOM", stringsAsFactors = FALSE)


#examine data structure
head(Country)
head(Cases)
head(WorldBank)

#Change Country column names for consistency 
names(Country)[names(Country) == "CountryCode"] <- "Alpha2"
names(Country)[names(Country) == "CountryCodeLong"] <- "Alpha3"
Country[Country$Alpha3 == "NAM",]$Alpha2 = "NA"

#remove unnecessary columns from Cases, rename columns, and reformat
Cases <- subset(Cases, select = -c(day,month,year,popData2018) )
names(Cases)[names(Cases) == "dateRep"] <- "Date"
names(Cases)[names(Cases) == "cases"] <- "Cases"
names(Cases)[names(Cases) == "deaths"] <- "Deaths"
names(Cases)[names(Cases) == "countriesAndTerritories"] <- "CountryName"
names(Cases)[names(Cases) == "geoId"] <- "Alpha2"
names(Cases)[names(Cases) == "countryterritoryCode"] <- "Alpha3"
Cases$Date = chron(dates=as.character(Cases$Date),format='d/m/y')
#Add in a running total of cases
Cases <- Cases[order(Cases$Date, Cases$Alpha2),] %>% group_by(CountryName) %>% mutate(TotalCases = cumsum(Cases), TotalDeaths = cumsum(Deaths))
Cases$EndOfWeek <- Cases$Date+ (7 - as.numeric(Cases$Date+4))%%7 

#Change WorldBank column names for consistency 
#Pivot the data, keeping only the series code, but keeping the series name seperately for reference
names(WorldBank)[names(WorldBank) == "Country.Name"] <- "CountryName"
names(WorldBank)[names(WorldBank) == "Country.Code"] <- "Alpha2"
WorldBankRef = distinct(WorldBank, Series.Code, Series.Name)

WorldBank$Value = NaN
WorldBank$Value[which(WorldBank$X2015..YR2015. != "..")] = WorldBank$X2015..YR2015.[which(WorldBank$X2015..YR2015. != "..")]
WorldBank$Value[which(WorldBank$X2016..YR2016. != "..")] = WorldBank$X2016..YR2016.[which(WorldBank$X2016..YR2016. != "..")]
WorldBank$Value[which(WorldBank$X2017..YR2017. != "..")] = WorldBank$X2017..YR2017.[which(WorldBank$X2017..YR2017. != "..")]
WorldBank$Value[which(WorldBank$X2018..YR2018. != "..")] = WorldBank$X2018..YR2018.[which(WorldBank$X2018..YR2018. != "..")]
WorldBank$Value[which(WorldBank$X2019..YR2019. != "..")] = WorldBank$X2019..YR2019.[which(WorldBank$X2019..YR2019. != "..")]
WorldBank <- subset(WorldBank, select = -c(Series.Name,X2015..YR2015.,X2016..YR2016.,X2017..YR2017.,X2018..YR2018.,X2019..YR2019.) )
WorldBank$Value <- as.numeric(WorldBank$Value)
WorldBank <- dcast(data = WorldBank[which(WorldBank$Series.Code !=""),], formula = CountryName +  Alpha2 ~ Series.Code, fun.aggregate = sum, value.var = "Value")


#create weekly view
Cases_D <- Cases
rm(Cases)
Cases_W <- Cases_D %>% 
  group_by(EndOfWeek, CountryName,Alpha2,Alpha3) %>% 
  summarize(Cases = sum(Cases), Deaths = sum(Deaths), TotalCases = max(TotalCases), TotalDeaths = max(TotalDeaths))


#--------- queries---------

# First we want to examine the data 
# Lets lets filter to countries that have been affected (There's a lot of countries in the world)
OverAmount = 5000
OverX <- (Cases_W %>% group_by(Alpha2) %>% summarise(maxCases = max(TotalCases)>OverAmount) %>% filter(maxCases))$Alpha2

# As one might expect, the daily variance obscures the patterns
ggplot(Cases_D[which(Cases_D$Alpha2 %in% OverX),], aes(as.POSIXct(Date, origin = "1970-01-01"), Cases))+
  geom_line(aes(color = CountryName))+
  scale_x_datetime(breaks = pretty(as.POSIXct(CasesOver$EndOfWeek), n = (max(CasesOver$EndOfWeek)-min(CasesOver$EndOfWeek))/7), labels = date_format("%d-%m-%Y"))+
  scale_y_continuous(trans = 'log10')+
  theme(axis.text.x = element_text(angle = 90, hjust = 1), legend.position = "bottom")+
  labs(title = "Reported COVID Cases by Week", x = "Week ending", y = 'Daily Cases (Log10 Scale)')

# Lets plot the number of new cases as reported at the end of each week
ggplot(Cases_W[which(Cases_W$Alpha2 %in% OverX),], aes(as.POSIXct(EndOfWeek, origin = "1970-01-01"), Cases))+
  geom_line(aes(color = CountryName))+
  scale_x_datetime(breaks = pretty(as.POSIXct(CasesOver$EndOfWeek), n = (max(CasesOver$EndOfWeek)-min(CasesOver$EndOfWeek))/7), labels = date_format("%d-%m-%Y"))+
  scale_y_continuous(trans = 'log10')+
  theme(axis.text.x = element_text(angle = 90, hjust = 1), legend.position = "bottom")+
  labs(title = "Reported COVID Cases by Week", x = "Week ending", y = 'Log10 Cases')

# the bottom of the graph isn't helpful.  When cases are very low, cases can randomly drop to zero.  
# The lines also start at very different times which doesn't help comparison

# We can normalise the X-axis (date) by starting our date as each country hits a predefined threshold
# Method 1 would be to start after Total Cses get over n, but this 
MinCasesN = 50
MinDate <- Cases_D  %>% filter(TotalCases>MinCasesN) %>% group_by(Alpha2) %>% summarize(FirstDate = min(Date)) 
# Method 2 would be to start after a Daily case number of n is recorded 
MinCasesN = 10
MinDate <- Cases_D  %>% filter(Cases>MinCasesN) %>% group_by(Alpha2) %>% summarize(FirstDate = min(Date)) 

# We need to redefine the daily frame, in how many days since each country hit that threshhold
class(Cases_D$Date)
class(MinDate$FirstDate)
class(HighCases_D$DaysSince)
HighCases_D <- 
  merge(x = Cases_D, y = MinDate, by ='Alpha2') %>% 
  mutate(DaysSince = Date - FirstDate) %>%
  filter(DaysSince>=0) %>% 
  select(-c(EndOfWeek,FirstDate,Date)) %>%
  mutate(Week = floor(DaysSince/7))

# We will make a weekly view as well, while we're here
HighCases_W <- HighCases_D %>% 
  group_by(Alpha2,Alpha3,CountryName,Week) %>% 
  summarize(Cases = sum(Cases), Deaths = sum(Deaths), TotalCases = max(TotalCases), TotalDeaths = max(TotalDeaths))

# This stil shows s alot of noise and is quite hard to look at
ggplot(HighCases_D[which(HighCases_D$Alpha2 %in% OverX),], aes(DaysSince, Cases))+
  geom_line(aes(color = CountryName))+
  scale_y_continuous(trans = 'log10')+
  theme(axis.text.x = element_text(angle = 90, hjust = 1), legend.position = "bottom")+
  labs(title = "Reported COVID Cases by Week", x = "Week ending", y = 'Log10 Cases')

# We can look weekly instead, but still doesn't look right.  We could go to a 3 day scale, but instead we will use a smoothing line
ggplot(HighCases_W[which(HighCases_W$Alpha2 %in% OverX),], aes(Week, Cases))+
  geom_line(aes(color = CountryName))+
  scale_y_continuous(trans = 'log10')+
  theme(axis.text.x = element_text(angle = 90, hjust = 1), legend.position = "bottom")+
  labs(title = "Reported COVID Cases by Week", x = "Week ending", y = 'Log10 Cases')



# First we should make some labels as the legend is hard to decipher
Data <- HighCases_D[which(HighCases_D$Alpha2 %in% OverX),]
Data <- Data[which(Data$Cases != 0 ),]
LabelFormatted <- split(Data, Data$Alpha2)%>%
  lapply(function(x){
    data.frame(
      MaxDay = max(x$DaysSince),
      LastCases = x$Cases[which(x$DaysSince==max(x$DaysSince))]
    )})%>%
  bind_rows
LabelFormatted$label = levels(as.factor(Data$Alpha2))

# We can look at this pattern with a lot scale.  For statistical purposes, this is better
ggplot(Data, aes(DaysSince, Cases))+
  geom_smooth(aes(color = CountryName))+
  geom_point(aes(color = CountryName),alpha = 0.5, size = 2, shape = 16,stroke = 0)+
  theme(axis.text.x = element_text(angle = 90, hjust = 1),legend.position = "none")+
  labs(title = "Reported COVID Cases by Week", x = "Days Since Daily Infections Over 10", y = 'Cases Daily (Log 10 Scale)')+
  scale_y_continuous(trans = log2_trans(),
                     breaks = trans_breaks("log10", function(x) 10^x),
                     labels = trans_format("log10", math_format(10^.x)))+
  geom_label_repel(data = LabelFormatted, aes(x= MaxDay, y = LastCases, label = label, color = label,nudge_x = 5))

# for the public, a log scale is deceptive, and log should not be used
ggplot(Data, aes(DaysSince, Cases))+
  geom_smooth(aes(color = CountryName))+
  geom_point(aes(color = CountryName),alpha = 0.5, size = 2, shape = 16,stroke = 0)+
  theme(axis.text.x = element_text(angle = 90, hjust = 1),legend.position = "none")+
  labs(title = "Reported COVID Cases by Week", x = "Days Since Daily Infections Over 10", y = 'Daily Cases')+
  geom_label_repel(data = LabelFormatted, aes(x= MaxDay, y = LastCases, label = label, color = label,nudge_x = 5))

#
# so far all the graphs have been in absolute case numbers.
# Population is obviously a factor which we should account for 
# The US as a very large country with differences in infection should be broken up by state
#


#Lets bring in some US Data, make a new column for Country_State(Either) and a flag for which one we want to exclude, then reformat the US data and append as a new dataframe
USCases <-  read.csv("https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-states.csv", na.strings = "", fileEncoding = "UTF-8-BOM",stringsAsFactors = FALSE)
head(USCases)
colnames(USCases) = c('Date', 'Country_State', 'fips', 'TotalCases','TotalDeaths')
USCases$Alpha2 = 'US'
USCases$Alpha3 = 'USA'
USCases$CountryName = 'United_States_of_America'
USCases$StateFlag = 'State'
USCases$Date = chron(dates=as.character(USCases$Date),format='y-m-d', out.format = 'd/m/y')
USCases$EndOfWeek <- USCases$Date+ (7 - as.numeric(USCases$Date+4))%%7 
USCases <- USCases%>%select(-c(fips))
USCases <- USCases[order(USCases$Country_State, USCases$Date),] %>% group_by(Country_State) %>% mutate(Cases = c(1,diff(TotalCases)), Deaths = c(1,diff(TotalDeaths)))
USCases$Cases = as.integer(USCases$Cases)
USCases$Deaths = as.integer(USCases$Deaths)
USCases = USCases[,c('Date','Cases','Deaths','CountryName','Alpha2','Alpha3','TotalCases','TotalDeaths','EndOfWeek','StateFlag','Country_State')]

Cases_D_temp <- Cases_D %>% mutate(StateFlag= '')
Cases_D_temp <- Cases_D_temp %>% mutate(Country_State = '')
Cases_D_temp$Country_State = Cases_D_temp$CountryName
Cases_D_S = rbind(as.data.frame(Cases_D_temp),as.data.frame(USCases))



MinDate <- Cases_D_S  %>% filter(Cases>MinCasesN) %>% group_by(Country_State) %>% summarize(FirstDate = min(Date))
Cases_D_S <- 
  merge(x = Cases_D_S, y = MinDate, by ='Country_State') %>% 
  mutate(DaysSince = as.integer(Date - FirstDate)) %>%
  filter(DaysSince>=0) %>% 
  select(-c(EndOfWeek,FirstDate,Date)) %>%
  mutate(Week = floor(DaysSince/7))

OverAmount = 5000
OverY = OverX
OverX <- (Cases_D_S %>% group_by(Country_State) %>% summarise(maxCases = max(TotalCases)>OverAmount) %>% filter(maxCases))$Country_State

view((Cases_D_S %>% group_by(CountryName,Country_State) %>% summarise(maxCases = max(TotalCases)>OverAmount) %>% filter(maxCases)))
view(Cases_W %>% group_by(CountryName) %>% summarise(maxCases = max(TotalCases)>OverAmount) %>% filter(maxCases))

#quick check 

Data <- Cases_D_S[which(Cases_D_S$Country_State %in% OverX & Cases_D_S$DaysSince>=0),]
Data <- Data[which(Cases_D_S$Cases != 0 ),]
head(Data)

LabelFormatted <- split(Data, Data$Country_State)%>%
  lapply(function(x){
    data.frame(
      MaxDay = max(x$DaysSince),
      LastCases = x$Cases[which(x$DaysSince==max(x$DaysSince))]
    )})%>%
  bind_rows
LabelFormatted$label = levels(as.factor(Data$Country_State))

ggplot(Data, aes(DaysSince, Cases))+
  geom_smooth(aes(color = Country_State))+
  geom_point(aes(color = Country_State),alpha = 0.5, size = 2, shape = 16,stroke = 0)+
  theme(axis.text.x = element_text(angle = 90, hjust = 1),legend.position = "none")+
  labs(title = "Reported COVID Cases by Week", x = "Days Since Daily Infections Over 10", y = 'Cases Daily (Log 10 Scale)')+
  scale_y_continuous(trans = log2_trans(),
                     breaks = trans_breaks("log10", function(x) 10^x),
                     labels = trans_format("log10", math_format(10^.x)))+
  geom_label_repel(data = LabelFormatted, aes(x= MaxDay, y = LastCases, label = label, color = label,nudge_x = 5))
