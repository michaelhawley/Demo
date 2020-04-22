
#--------- open librarys ---------
library(tidyverse)
library(reshape)
library(reshape2)
library(chron)
library(scales)
library(ggrepel)
library(gridExtra )


#  ---------------- Graphs----------------


head(Data)
#Top 15 Countries
Top20 <- CustomN(Data[which(Data$Pop>4000000),], N=30, dim='Cn_Pr', metric = 'TotalCasesPC'  )
Top20
view(Data[which(Data$Cn_Pr =='New York, United States'),])

graphOutliers <- function(d,SplitOn, XAxis, YAxis, Nr,Nc, LimX, sd){
  SplitData <- d %>% split(.[[SplitOn]])
  Plots <- lapply(SplitData, function(i){
    errors <- i[which(i$D >= sd | i$D<= -sd),]
    ggplot(i, aes(x = i[[XAxis]], y =i[[YAxis]] ))+
      geom_point(alpha = 0.5, size = 2, shape = 16,stroke = 0, aes(colour = D))+
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
