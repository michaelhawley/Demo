# COVID19 
This is me playing around with freely available Coronavirus data. The code I've used is all in the files here. 
 - Covid19_GetData: Gets the data and formats it, including smoothing out the outliers
 - Ease_Functions: I have added two functions for faster labeling and graphing which the following files rely on
 - Covid19_Outliers:  Shows why these observations are identified as being incorrect (Seperate folder)
 
## Mortality rate
![Gif](https://raw.githubusercontent.com/michaelhawley/Demo/master/R/graphs/CovidGif.gif)

I take away two things from this graph.  First is that the number of cases has grown **really** fast. The GIF is hardly moving until it is. 
The second is, that there must be a lot of uncertainty about how many cases there are and how may deaths. The fatality rate seems to vary wildly by country which suggests that either something to do with the country is impacting the rate of survival, or that misreporting is going on. 

NYT did a great piece on the the discrepancy between the increase in the background death rate, and the reported deaths from COVID19, suggesting that many are dieing from COVID19 without being listed as so. 
https://www.nytimes.com/interactive/2020/04/21/world/coronavirus-missing-deaths.html

It's also very probable that there's a large degree of undertesting which is skewing the mortality rate. 
It is clear that deaths lag cases, so potentially with more time and more data the countries shown converge to a similar mortality rate. 
 ![Gif](https://github.com/michaelhawley/Demo/blob/master/R/graphs/Graph2.png)

## Most affected areas
![Gif](https://raw.githubusercontent.com/michaelhawley/Demo/master/R/graphs/Graph1.png)
One of the first questions someone might ask is where is most affected? 

There's a question here in whether large countries should be split up into their states/provinces. 
The US is a very large country with individual states that dwarf other countires.  The rate of infection varies wildly  between them. For this reason, I choose to break up the US, China and Canada (debateable).
I also broke up AU because it's of interest to me. The downside of this, is that the US dominates the chart. 


## Worst hit
![Gif](https://raw.githubusercontent.com/michaelhawley/Demo/master/R/graphs/Graph4.png)


![Gif](https://raw.githubusercontent.com/michaelhawley/Demo/master/R/graphs/Graph5.png)

