# COVID19 
This is me playing around with freely available Coronavirus data during my free time. 

 - Covid19_GetData: Gets the data and formats it, including smoothing out the outliers
 - Ease_Functions: I have added two functions for faster labelling and graphing which the following files rely on
 - Covid19_Outliers:  Shows why these observations are identified as being incorrect (Separate folder)
 
 Note:  This is ** NOT ** the most 'robust' analysis. I did this quickly, partially as a demonstration and partially because this is an interesting topic. The code needs a lot of formatting & documentation.  The underlying data needs validating which would take a lot of time. Many of the graphs lead me to question these numbers.  The wildly different mortality rate data so far suggests that either there are massive healthcare or genetic differences between neighbouring countries, or (much more likely) reported Deaths and Case numbers are inaccurate, with both sets likely underestimated by a large margin.  
 
## Mortality rate
![Gif](https://raw.githubusercontent.com/michaelhawley/Demo/master/R/graphs/CovidGif.gif)

I take away two things from this graph.  First is that the number of cases has grown **really** fast which aligns with how I perceived the reporting, moving from 'no big deal' to large numbers of cases seemly overnight.
The second is that there must be a lot of uncertainty about how many cases there are and how may deaths. The fatality rate seems to vary wildly by country which suggests that either something to do with the country is impacting the rate of survival, or that misreporting is going on. 
NYT did a great piece on the discrepancy between the increase in the background death rate, and the reported deaths from COVID19, suggesting that many are dying from COVID19 without being listed as so. 
https://www.nytimes.com/interactive/2020/04/21/world/coronavirus-missing-deaths.html
It's also very probable that there's a large degree of undertesting which is skewing the mortality rate. 
Deaths lag cases, so potentially, given more time and a more complete dataset, the countries shown might converge to a similar mortality rate. 
 ![Gif](https://github.com/michaelhawley/Demo/blob/master/R/graphs/Graph2.png)
 
Looking at Belgium and Switzerland for example. Both have relatively similar levels of healthcare, similar ethnicity, and similar number of cases per million people suggesting that their hospitals should be at similar levels of strain. But Belgium is reporting a significantly higher mortality rate. The difference is more likely to be reporting error than a reflection of reality. 
  
## Outliers
It is worth nothing that there are some very large outliers in this data. A quick graph shows that there are some huge spikes. While the deaths per day are somewhat steadier, cases per day show a large variability likely due to processing time rather than infection rates. I smoothed some outliers in this data, as noted in the outlier’s folder. 
![Gif](https://raw.githubusercontent.com/michaelhawley/Demo/master/R/outliers/graphs/Initial_Graph.png)

## Most affected areas
![Gif](https://raw.githubusercontent.com/michaelhawley/Demo/master/R/graphs/Graph1.png)
One of the first questions I wanted to know, is where the worst affected places were. 
While the news loves to report absolute numbers, it becomes much harder to make fair comparisons between places. 
There is also a question here in whether large countries should be split up into their states/provinces. The US is a large country with individual states whose populations dwarf some European countries.  The rate of infection varies wildly between States and therefore grouping them misses the reality of the situation. For this reason, I choose to break up the US, China, and Canada (debateable). I also broke up Australia because I was interested in seeing differences though population wise this is unjustified. 
The downside of this approach of splitting up States is that the US dominates the chart. 
## Measuring the first wave
### Cases & Deaths over time
![Gif](https://raw.githubusercontent.com/michaelhawley/Demo/master/R/graphs/Graph4.png)
Here I am using the seven-day moving average for cases and deaths.  This smooths out the highly variable data, making it easier to see the pattern in the data. 

I find this type of graph hard to look at, with Cases and Deaths on the same axis. 

### Cases & Deaths over time as a proportion of total
![Gif](https://raw.githubusercontent.com/michaelhawley/Demo/master/R/graphs/Graph5.png)
Some statisticians strongly advise against putting our two data series on different axis's.  Doing so, allows the maker to the freedom to make spurious correlations. 
For example, in Italy it suggests that deaths are higher than cases rather than that the highest share of deaths came later.  I could alter the axis to paint a different picture. 

What this does show is that the height in deaths arrives somewhere from 6-10 days after the peak in cases. It is interesting that this lag is different in different places. 
Deaths are recorded on the day, but Cases are recorded on positive confirmation which depends on lab processing time. 
If lab processing time is short and people are getting proactively tested, someone could be recorded as a case 10 days before dying. If the processing time is long and people are only getting tested upon being hospitalised, their positive test result might coincide with their death. 

