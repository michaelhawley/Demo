
#--------- open librarys ---------
library(tidyverse)
library(reshape)
library(reshape2)
library(chron)
library(scales)
library(ggrepel)
library(gridExtra )

#  ----------------Ease Functions ----------------

#As we're going to have to filter the top countries many times in different ways, let's make it a function
CustomN <- function(Data, N = 15, dim, metric){
  x = Data %>% 
    group_by(.dots = dim)%>%
    summarize(maxN = max(.data[[metric]]))%>%
    top_n(N, maxN)%>%
    .[,dim]
  x[[dim]]
}

# As we will often want to label end of a scatter plot, use this
LabelFunction <- function(data, x,y, SplitOn,maxX = NULL ){
  L <- data %>% split(.[[SplitOn]])%>%
    lapply(function(i){
      data.frame(
        xpos = max(i[[x]]),
        ypos = sum(i[which(i[[x]]>=(max(i[[x]]) -2)),y])/3 #for each that we're splitting on, get the end of that line and find out what the avg Y is on the last 3 obs
      )})%>%
    bind_rows
  if (!is.null(maxX)){L[which(L$xpos>maxX),'xpos'] = maxX }
  L$label = levels(as.factor(data[[SplitOn]]))
  L
}
