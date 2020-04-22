# COVID19 
This is me playing around with freely available Coronavirus data. The code I've used is all in the files here. 
 - Covid19_GetData: Gets the data and formats it, including smoothing out the outliers
 - Ease_Functions: I have added two functions for faster labeling and graphing which the following files rely on
 - Covid19_Outliers:  Shows why these observations are identified as being incorrect (Seperate folder)
 
## Number of cases v deaths
![Gif](https://raw.githubusercontent.com/michaelhawley/Demo/master/R/CovidGif.gif)

I take away two things from this graph.  First is that the number of cases has grown **really** fast. The GIF is hardly moving until it is. 
The second is, that there must be a lot of uncertainty about how many cases there are and how may deaths. The fatality rate seems to vary wildly by country which suggests that either something to do with the country is impacting the rate of survival, or that misreporting is going on. 

NYT did a great piece on the the discrepancy between the increase in the background death rate, and the reported deaths from COVID19, suggesting that many are dieing from COVID19 without being listed as so. 
https://www.nytimes.com/interactive/2020/04/21/world/coronavirus-missing-deaths.html

It's also very probable that there's a large degree of undertesting which is skewing the mortality rate. 
It is clear that deaths lag cases, so potentially with more time and more data the countries shown converge to a similar mortality rate. 
 ![Gif](https://raw.githubusercontent.com/michaelhawley/Demo/master/R/Graph2.png)

## Worst hit
![Gif](https://raw.githubusercontent.com/michaelhawley/Demo/master/R/Graph1.png)
I've broken up the US, Canada, Australia and China into states/provinces to allow for more comparible analysis. 
Potentially this is unfair.  The US seems to take up most of the top spots in this graph.

## Worst hit
![Gif](https://raw.githubusercontent.com/michaelhawley/Demo/master/R/Graph4.png)


![Gif](https://raw.githubusercontent.com/michaelhawley/Demo/master/R/Graph5.png)





 ## Outliers
 ![Gif](https://raw.githubusercontent.com/michaelhawley/Demo/master/R/CovidGif.gif)
 The first thing to do is plot the data.  Here I've standardised the start dates by adding in a 'Days Since' column. Each country started its first wave of COVID19 at different times, with some falling away while others are still rising. 
 Setting day 1 as the first day where 10 cases were recorded on the same day seems to best align most countries. 
 
We can already see there's some serious outliers in the data. One way of spotting them is to take a linear model of the nearest observations (in this case 8 forward and 8 backward) and forecast each values position. Then we can highlight those more than 3sd from the line to investigate further.
 ![Gif](https://raw.githubusercontent.com/michaelhawley/Demo/master/R/OutliersExamples.png) 

Upon doing this, we can see a pattern exists - look at Alaska! A pattern exists across most countries with very high days following low days. This is likely where testing is delayed and reported the next day. These jumps aren't necessarily outliers but a reflection of the nature of the reporting. We want to identify outliers, data points that are outside the normal range.  Instead the function should ask if an indivdual observation is higher than expected. If so, it's averaged with the lower of it's neighbours (and vv). Observations that are still over 3sd from where they should be are highlighted. 
