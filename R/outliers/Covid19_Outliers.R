
#--------- open librarys ---------
library(tidyverse)
library(reshape)
library(reshape2)
library(chron)
library(scales)
library(ggrepel)
library(gridExtra )

#Lets take an initial look at the data, first lookig at the top 15 countries

#Top 15 Countries
Top15Countries <- CustomN(OData, N=15, dim='Country', metric = 'TotalCases'  )
WorldWide      <- OData[which(OData$Country %in% Top15Countries & OData$Cases!=0 & OData$CNDays>=0 & OData$CNDays<=60),] %>% 
  group_by(Country,CNDays) %>% 
  summarise(Cases = sum(Cases),Deaths = sum(Deaths),TotalCases = sum(TotalCases),TotalDeaths = sum(TotalDeaths))
DailyLabels <- LabelFunction(WorldWide,x = 'CNDays', y = 'Cases', SplitOn = 'Country', maxX = 60)
DailyLabels

ggplot(WorldWide, aes(CNDays, Cases))+
  geom_smooth(aes(color = Country), span  = 0.4)+
  geom_point( aes(color = Country), alpha = 0.5, size = 2, shape = 16,stroke = 0)+
  theme(axis.text.x = element_text(angle = 90, hjust = 1),legend.position = "none")+
  labs(title = "Total Reported COVID Cases by days since +10", x = "Days Since Daily Infections Over 10", y = 'Reported Cases')+
  geom_label_repel(data = DailyLabels, aes(x= xpos, y = ypos, label = label, color = label), size=4, fill = 'white' )+
  xlim(0,60)

#There are some clear outliers in the data
#France and China are the obvious ones.

#Lets find the outliers
# in this dataset, the curve seems to shift dramatically in a a short number of days, but there's also a large variablity per day
# a simple linear model based on the nearest n values, should tell us if an observation looks odd
OData = OData[order(OData$Cn_Pr, OData$Date),] #ensure the data is ordered
Obs <- 8 #how big the window should be
n <- Obs*2  #how many observations to move forward and back
OData$D_Cases <- pull(split(OData,OData$Cn_Pr) %>%  #pull the first and only line of data back
  lapply(function(i){
    Nr = nrow(i)               
    Deltas = vector(length=Nr)
    for (R in 1:Nr){
      B = min(Obs,R-1) - min(Obs,Nr-R) +Obs         #how far back to go (forward is minus this), this addresses what to do on the first and last values
      sub <- i[c((R-B):(R-B+n))[-(B+1)],c('StDays','Cases')]  # get a subset defined by going backwards and forwards from the current number
      L <- lm(Cases~StDays, data = sub)                       # calculate a linear model based on that data
      sd <- sqrt(sum(L$residuals^2)/(n-2))                  # calculate the sd
      p <-predict(L,data.frame(StDays = i[R,'StDays']))     #predict where is should have been
      Deltas[R] = (p - i[R,'Cases'])/sd                     #check how far off the observed value is
    }
    data.frame(Deltas)
  }) %>% bind_rows)
OData[which(is.na(OData$D_Cases) & OData$Cases == 0),'D'] = 0
OData[which(OData$D_Cases == -Inf | OData$D_Cases == Inf),'D'] = 0 


# we should go through each area of the world to look at them in turn.
# we want more than one country / state in one plot, of it will take a long time to check all the charts

USStates = unique(OData[which(OData$Country =='United States'),'Cn_Pr'])
US1 <- OData[which(OData$Cn_Pr %in% USStates[1:20]),]

graphOutliers <- function(d,SplitOn, XAxis, YAxis, Nr,Nc, LimX, sd, Dx){
  SplitData <- d %>% split(.[[SplitOn]])
  Plots <- lapply(SplitData, function(i){
    errors <- i[which(i[[Dx]] >= sd | i[[Dx]]<= -sd),]
    ggplot(i, aes(x = i[[XAxis]], y =i[[YAxis]] ))+
      geom_point(alpha = 0.5, size = 2, shape = 16,stroke = 0, aes(colour = i[[Dx]]))+
      geom_smooth(span  = 0.4, method = 'loess')+
      geom_point(data = errors, aes(x = errors[[XAxis]], y = errors[[YAxis]]), size = 4, shape =1)+
      theme(legend.position = "none"
            ,axis.ticks.y = element_blank()
            #,axis.text.y = element_blank()
            ,plot.margin = unit(c(0.2,0.2,0,0), "cm"))+
      labs(title = i$Cn_Pr, x = "", y = '')+
      xlim(0,LimX)
  })
  grid.arrange(grobs = Plots, nrow = Nr, ncol = Nc)
}

graphOutliers(d = US1, SplitOn = 'Cn_Pr',  XAxis = 'StDays', YAxis = 'CasesPC', Nr = 5,Nc = 4, LimX= 35, sd=3 , Dx = "D_Cases" )

#we can already see that these points highlighted are not outliers, but the result of delayed reporting.
# A high day often follows a low day, we should look for these and not highlight them as outliers

OData$D_Cases <- pull(split(OData,OData$Cn_Pr) %>%  #pull the first and only line of data back
                 lapply(function(i){
                   Nr = nrow(i)               
                   Deltas = vector(length=Nr)
                   for (R in 1:Nr){
                     B = min(Obs,R-1) - min(Obs,Nr-R) +Obs         #how far back to go (forward is minus this), this addresses what to do on the first and last values
                     sub <- i[c((R-B):(R-B+n))[-(B+1)],c('StDays','Cases')]  # get a subset defined by going backwards and forwards from the current number
                     L <- lm(Cases~StDays, data = sub)                       # calculate a linear model based on that data
                     sd <- sqrt(sum(L$residuals^2)/(n-2))                  # calculate the sd
                     p <-predict(L,data.frame(StDays = i[R,'StDays']))     #predict where is should have been
                     Delta = (i[R,'Cases'] - p)/sd                     #check how far off the observed value is
                     if (is.na(Delta)){Deltas[R] = 0}
                     else{
                        if (Delta>0){ Deltas[R]  = min(Delta,   (mean (c(i[R,'Cases'],min(i[min(R+1, Nr),'Cases'],i[max(R-1,0),'Cases']))) -p)/sd    )} 
                        else{         Deltas[R]  = max(Delta,   (mean (c(i[R,'Cases'],max(i[min(R+1, Nr),'Cases'],i[max(R-1,0),'Cases']))) -p)/sd    )}
                     }
                   }
                   data.frame(Deltas)
                 }) %>% bind_rows)
Data[which(is.nan(Data$D_Cases) & Data$Cases == 0),'D'] = 0
Data[which(is.na(Data$D_Cases) & Data$Cases == 0),'D'] = 0
Data[which(Data$D_Cases == -Inf | Data$D_Cases == Inf),'D'] = 0 

# Deaths
Data$D_Deaths <- pull(split(Data,Data$Cn_Pr) %>%  #pull the first and only line of data back
                 lapply(function(i){
                   Nr = nrow(i)               
                   Deltas = vector(length=Nr)
                   for (R in 1:Nr){
                     B = min(Obs,R-1) - min(Obs,Nr-R) +Obs         #how far back to go (forward is minus this), this addresses what to do on the first and last values
                     sub <- i[c((R-B):(R-B+n))[-(B+1)],c('StDays','Deaths')]  # get a subset defined by going backwards and forwards from the current number
                     L <- lm(Deaths~StDays, data = sub)                       # calculate a linear model based on that data
                     sd <- sqrt(sum(L$residuals^2)/(n-2))                  # calculate the sd
                     p <-predict(L,data.frame(StDays = i[R,'StDays']))     #predict where is should have been
                     Delta = (i[R,'Deaths'] - p)/sd                     #check how far off the observed value is
                     if (is.na(Delta)){Deltas[R] = 0}
                     else{
                       if (Delta>0){ Deltas[R]  = min(Delta,   (mean (c(i[R,'Deaths'],min(i[min(R+1, Nr),'Deaths'],i[max(R-1,0),'Deaths']))) -p)/sd    )} 
                       else{         Deltas[R]  = max(Delta,   (mean (c(i[R,'Deaths'],max(i[min(R+1, Nr),'Deaths'],i[max(R-1,0),'Deaths']))) -p)/sd    )}
                     }
                   }
                   data.frame(Deltas)
                 }) %>% bind_rows)
Data[which(is.nan(Data$D_Deaths) & Data$Deaths == 0),'D'] = 0
Data[which(is.na(Data$D_Deaths) & Data$Deaths == 0),'D'] = 0
Data[which(Data$D_Deaths == -Inf | Data$D_Deaths == Inf),'D'] = 0 


         
            
       
US1 <- Data[which(Data$Cn_Pr %in% USStates[1:20]),]
# After running the graph again looking for 3SD's, ther are no unusual observations that are not counter weighted by another
graphOutliers(d = US1, SplitOn = 'Cn_Pr',  XAxis = 'StDays', YAxis = 'CasesPC', Nr = 5,Nc = 4, LimX= 35, sd = 3 , Dx = 'D_Cases' )
# only at 1 SD to we get results
# the results look strange.
# e.g. Florida has a high point, marked with -1.05.  This is because the average of this point & the prior point, is slighly lower than would be expected
# this means the point before is dragging the result down.  Only to 1 sd though. 
graphOutliers(d = US1, SplitOn = 'Cn_Pr',  XAxis = 'StDays', YAxis = 'CasesPC', Nr = 5,Nc = 4, LimX= 35, sd = 1  )


#Lets go through each area of the world
# DETAIL 
        Latin <- (unique(Data[which(Data$Sub.region == "Latin America and the Caribbean"),"Cn_Pr"]))
        SubA <- (unique(Data[which(Data$Sub.region == "Sub-Saharan Africa"),"Cn_Pr"]))
        ChinaProv <- (unique(Data[which(Data$Country == "China"),"Cn_Pr"]))
        
        graphOutliers(d = Data[which(Data$Cn_Pr %in% USStates[ 0:20]),], SplitOn = 'Cn_Pr',  XAxis = 'StDays', YAxis = 'Cases', Nr = 5,Nc = 4, LimX= 60, sd = 3 , Dx = 'D_Cases' )
        graphOutliers(d = Data[which(Data$Cn_Pr %in% USStates[21:40]),]   , SplitOn = 'Cn_Pr',  XAxis = 'StDays', YAxis = 'Cases', Nr = 5,Nc = 4, LimX= 60, sd = 3 ,Dx = 'D_Cases'  )
        graphOutliers(d = Data[which(Data$Cn_Pr %in% USStates[41:55]),]   , SplitOn = 'Cn_Pr',  XAxis = 'StDays', YAxis = 'Cases', Nr = 4,Nc = 4, LimX= 60, sd = 3 ,Dx = 'D_Cases'  )
        graphOutliers(d = Data[which(Data$Country == "Canada") ,]   , SplitOn = 'Cn_Pr',  XAxis = 'StDays', YAxis = 'Cases', Nr = 3,Nc = 3, LimX= 60, sd = 3  ,Dx = 'D_Cases')
        
        graphOutliers(d = Data[which(Data$Sub.region == "Australia and New Zealand") ,]   , SplitOn = 'Cn_Pr',  XAxis = 'StDays', YAxis = 'Cases', Nr = 3,Nc = 3, LimX= 60, sd = 3  , Dx = 'D_Cases')
        graphOutliers(d = Data[which(Data$Sub.region == "Southern Europe") ,]   , SplitOn = 'Cn_Pr',  XAxis = 'StDays', YAxis = 'Cases', Nr = 4,Nc = 4, LimX= 60, sd = 3  , Dx = 'D_Cases')
        graphOutliers(d = Data[which(Data$Sub.region == "Northern Europe") ,]   , SplitOn = 'Cn_Pr',  XAxis = 'StDays', YAxis = 'Cases', Nr = 4,Nc = 4, LimX= 60, sd = 3  , Dx = 'D_Cases')
        graphOutliers(d = Data[which(Data$Sub.region == "Western Europe") ,]   , SplitOn = 'Cn_Pr',  XAxis = 'StDays', YAxis = 'Cases', Nr = 4,Nc = 4, LimX= 60, sd = 3  , Dx = 'D_Cases')
        
        graphOutliers(d = Data[which(Data$Cn_Pr %in% ChinaProv[1:16]) ,]   , SplitOn = 'Cn_Pr',  XAxis = 'StDays', YAxis = 'Cases', Nr = 4,Nc = 4, LimX= 60, sd = 3  , Dx = 'D_Cases')
        graphOutliers(d = Data[which(Data$Cn_Pr %in% ChinaProv[17:32]) ,]   , SplitOn = 'Cn_Pr',  XAxis = 'StDays', YAxis = 'Cases', Nr = 4,Nc = 3, LimX= 60, sd = 3  , Dx = 'D_Cases')
        
        graphOutliers(d = Data[which(Data$Sub.region == "Southern Asia" |Data$Sub.region == "South-eastern Asia" | Data$Sub.region == "Eastern Asia" & Data$Country != "China" ),]   , SplitOn = 'Cn_Pr',  XAxis = 'StDays', YAxis = 'Cases', Nr = 4,Nc = 5, LimX= 60, sd = 3 , Dx = 'D_Cases' )
        graphOutliers(d = Data[which(Data$Sub.region == "Central Asia" ) ,]   , SplitOn = 'Cn_Pr',  XAxis = 'StDays', YAxis = 'Cases', Nr = 2,Nc = 2, LimX= 60, sd = 3 , Dx = 'D_Cases' )
        graphOutliers(d = Data[which(Data$Sub.region == "Western Asia" ) ,]   , SplitOn = 'Cn_Pr',  XAxis = 'StDays', YAxis = 'Cases', Nr = 4,Nc = 4, LimX= 60, sd = 3, Dx = 'D_Cases'  )
        
        graphOutliers(d = Data[which(Data$Cn_Pr %in%  Latin[1:10] ) ,]   , SplitOn = 'Cn_Pr',  XAxis = 'StDays', YAxis = 'Cases', Nr = 4,Nc = 3, LimX= 60, sd = 3 , Dx = 'D_Cases' )
        graphOutliers(d = Data[which(Data$Cn_Pr %in%  Latin[11:20] ) ,]   , SplitOn = 'Cn_Pr',  XAxis = 'StDays', YAxis = 'Cases', Nr = 4,Nc = 3, LimX= 60, sd = 3 , Dx = 'D_Cases' )
        
        graphOutliers(d = Data[which(Data$Sub.region == "Northern Africa" ) ,]   , SplitOn = 'Cn_Pr',  XAxis = 'StDays', YAxis = 'Cases', Nr = 3,Nc = 2, LimX= 45, sd = 3  , Dx = 'D_Cases')
        graphOutliers(d = Data[which(Data$Cn_Pr %in%  SubA[1:12]  ) ,]   , SplitOn = 'Cn_Pr',  XAxis = 'StDays', YAxis = 'Cases', Nr = 3,Nc = 4, LimX= 60, sd = 3 , Dx = 'D_Cases' )
        graphOutliers(d = Data[which(Data$Cn_Pr %in%  SubA[13:24]  ) ,]   , SplitOn = 'Cn_Pr',  XAxis = 'StDays', YAxis = 'Cases', Nr = 4,Nc = 3, LimX= 60, sd = 3 , Dx = 'D_Cases' )
        
# Summary       
outliers <- c('Hubei, China','Texas, United States','Ohio, United States ','Thailand','Pakistan','France','Morocco','Ecuador','Singapore')
graphOutliers(d = Data[which(Data$Cn_Pr %in%  outliers) ,]   , SplitOn = 'Cn_Pr',  XAxis = 'StDays', YAxis = 'Cases', Nr = 3,Nc = 3, LimX= 60, sd = 3, Dx = 'D_Cases'  )
view(Data[which(Data$Cn_Pr %in%  outliers & Data$D>3) ,])

#Ecuador No reason given http://www.xinhuanet.com/english/2020-04/11/c_138965712.htm
#France - Nursing homes included  https://www.reuters.com/article/us-health-coronavirus-france-toll/french-coronavirus-cases-jump-above-chinas-after-including-nursing-home-tally-idUSKBN21L3BG
#Hubei - Change in defintion https://www.bbc.com/news/world-asia-china-51482994
#Morocco No reason given https://www.albawaba.com/news/morocco-kuwait-lebanon-report-spikes-coronavirus-cases-1351334
#Pakistan - No reason given https://nation.com.pk/06-Apr-2020/coronavirus-pakistan-s-confirmed-cases-rise-to-3278-50-deaths
#Singapore - no reason given https://www.straitstimes.com/singapore/singapore-coronavirus-cases-cross-4000-with-728-cases-in-new-daily-record
# Texas - no reason
#Thailand no reason

#Lets go through each area of the world
# DETAIL 
      Latin <- (unique(Data[which(Data$Sub.region == "Latin America and the Caribbean"),"Cn_Pr"]))
      SubA <- (unique(Data[which(Data$Sub.region == "Sub-Saharan Africa"),"Cn_Pr"]))
      ChinaProv <- (unique(Data[which(Data$Country == "China"),"Cn_Pr"]))
      
      graphOutliers(d = Data[which(Data$Cn_Pr %in% USStates[  0:12]),], SplitOn = 'Cn_Pr', XAxis = 'StDays', YAxis = 'Deaths', Nr = 4,Nc = 3, LimX= 60, sd = 3 , Dx = 'D_Deaths')
      graphOutliers(d = Data[which(Data$Cn_Pr %in% USStates[ 13:24]),], SplitOn = 'Cn_Pr', XAxis = 'StDays', YAxis = 'Deaths', Nr = 4,Nc = 3, LimX= 60, sd = 3 , Dx = 'D_Deaths')
      graphOutliers(d = Data[which(Data$Cn_Pr %in% USStates[ 25:36]),], SplitOn = 'Cn_Pr', XAxis = 'StDays', YAxis = 'Deaths', Nr = 4,Nc = 3, LimX= 60, sd = 3 , Dx = 'D_Deaths' )
      graphOutliers(d = Data[which(Data$Cn_Pr %in% USStates[ 37:48]),], SplitOn = 'Cn_Pr', XAxis = 'StDays', YAxis = 'Deaths', Nr = 4,Nc = 3, LimX= 60, sd = 3 , Dx = 'D_Deaths' )
      graphOutliers(d = Data[which(Data$Cn_Pr %in% USStates[ 49:55]),], SplitOn = 'Cn_Pr', XAxis = 'StDays', YAxis = 'Deaths', Nr = 4,Nc = 3, LimX= 60, sd = 3 , Dx = 'D_Deaths')
      
      graphOutliers(d = Data[which(Data$Country == "Canada") ,]   , SplitOn = 'Cn_Pr',  XAxis = 'StDays', YAxis = 'Deaths', Nr = 3,Nc = 3, LimX= 60, sd = 3  , Dx = 'D_Deaths')
      
      graphOutliers(d = Data[which(Data$Sub.region == "Australia and New Zealand") ,]   , SplitOn = 'Cn_Pr',  XAxis = 'StDays', YAxis = 'Deaths', Nr = 3,Nc = 3, LimX= 60, sd = 3 , Dx = 'D_Deaths' )
      graphOutliers(d = Data[which(Data$Sub.region == "Southern Europe") ,]   , SplitOn = 'Cn_Pr',  XAxis = 'StDays', YAxis = 'Deaths', Nr = 4,Nc = 4, LimX= 60, sd = 3 , Dx = 'D_Deaths' )
      graphOutliers(d = Data[which(Data$Sub.region == "Northern Europe") ,]   , SplitOn = 'Cn_Pr',  XAxis = 'StDays', YAxis = 'Deaths', Nr = 4,Nc = 4, LimX= 60, sd = 3 , Dx = 'D_Deaths' )
      graphOutliers(d = Data[which(Data$Sub.region == "Western Europe") ,]   , SplitOn = 'Cn_Pr',  XAxis = 'StDays', YAxis = 'Deaths', Nr = 4,Nc = 4, LimX= 60, sd = 3  , Dx = 'D_Deaths')
      
      graphOutliers(d = Data[which(Data$Cn_Pr %in% ChinaProv[1:16]) ,]   , SplitOn = 'Cn_Pr',  XAxis = 'StDays', YAxis = 'Deaths', Nr = 4,Nc = 4, LimX= 60, sd = 3  , Dx = 'D_Deaths')
      graphOutliers(d = Data[which(Data$Cn_Pr %in% ChinaProv[17:32]) ,]   , SplitOn = 'Cn_Pr',  XAxis = 'StDays', YAxis = 'Deaths', Nr = 4,Nc = 3, LimX= 60, sd = 3  , Dx = 'D_Deaths')
      
      graphOutliers(d = Data[which(Data$Sub.region == "Southern Asia" |Data$Sub.region == "South-eastern Asia" | Data$Sub.region == "Eastern Asia" & Data$Country != "China" ),]   , SplitOn = 'Cn_Pr',  XAxis = 'StDays', YAxis = 'Deaths', Nr = 4,Nc = 5, LimX= 60, sd = 3  , Dx = 'D_Deaths')
      
      graphOutliers(d = Data[which(Data$Sub.region == "Central Asia" ) ,]   , SplitOn = 'Cn_Pr',  XAxis = 'StDays', YAxis = 'Deaths', Nr = 2,Nc = 2, LimX= 60, sd = 3 , Dx = 'D_Deaths' )
      graphOutliers(d = Data[which(Data$Sub.region == "Western Asia" ) ,]   , SplitOn = 'Cn_Pr',  XAxis = 'StDays', YAxis = 'Deaths', Nr = 4,Nc = 4, LimX= 60, sd = 3 , Dx = 'D_Deaths' )
      
      graphOutliers(d = Data[which(Data$Cn_Pr %in%  Latin[1:10] ) ,]   , SplitOn = 'Cn_Pr',  XAxis = 'StDays', YAxis = 'Deaths', Nr = 4,Nc = 3, LimX= 60, sd = 3 , Dx = 'D_Deaths' )
      graphOutliers(d = Data[which(Data$Cn_Pr %in%  Latin[11:20] ) ,]   , SplitOn = 'Cn_Pr',  XAxis = 'StDays', YAxis = 'Deaths', Nr = 4,Nc = 3, LimX= 60, sd = 3 , Dx = 'D_Deaths' )
      
      graphOutliers(d = Data[which(Data$Sub.region == "Northern Africa" ) ,]   , SplitOn = 'Cn_Pr',  XAxis = 'StDays', YAxis = 'Deaths', Nr = 3,Nc = 2, LimX= 45, sd = 3 , Dx = 'D_Deaths' )
      graphOutliers(d = Data[which(Data$Cn_Pr %in%  SubA[1:12]  ) ,]   , SplitOn = 'Cn_Pr',  XAxis = 'StDays', YAxis = 'Deaths', Nr = 3,Nc = 4, LimX= 60, sd = 3  , Dx = 'D_Deaths')
      graphOutliers(d = Data[which(Data$Cn_Pr %in%  SubA[13:24]  ) ,]   , SplitOn = 'Cn_Pr',  XAxis = 'StDays', YAxis = 'Deaths', Nr = 4,Nc = 3, LimX= 60, sd = 3  , Dx = 'D_Deaths')

# Summary       
outliers <- c('Hubei, China','Texas, United States','Ohio, United States ','Thailand','Pakistan','France','Morocco','Ecuador','Singapore')
graphOutliers(d = Data[which(Data$Cn_Pr %in%  outliers) ,]   , SplitOn = 'Cn_Pr',  XAxis = 'StDays', YAxis = 'Cases', Nr = 3,Nc = 3, LimX= 60, sd = 3  , Dx = 'D_Deaths')
view(Data[which(Data$Cn_Pr %in%  outliers & Data$D_Deaths>3) ,])

#Ecuador No reason given http://www.xinhuanet.com/english/2020-04/11/c_138965712.htm
#France - Nursing homes included  https://www.reuters.com/article/us-health-coronavirus-france-toll/french-coronavirus-cases-jump-above-chinas-after-including-nursing-home-tally-idUSKBN21L3BG
#Hubei - Change in defintion https://www.bbc.com/news/world-asia-china-51482994
#Morocco No reason given https://www.albawaba.com/news/morocco-kuwait-lebanon-report-spikes-coronavirus-cases-1351334
#Pakistan - No reason given https://nation.com.pk/06-Apr-2020/coronavirus-pakistan-s-confirmed-cases-rise-to-3278-50-deaths
#Singapore - no reason given https://www.straitstimes.com/singapore/singapore-coronavirus-cases-cross-4000-with-728-cases-in-new-daily-record
# Texas - no reason
#Thailand no reason


