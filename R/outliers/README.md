 ## Outliers
 ![Gif](https://raw.githubusercontent.com/michaelhawley/Demo/master/R/CovidGif.gif)
 The first thing to do is plot the data.  Here I've standardised the start dates by adding in a 'Days Since' column. Each country started its first wave of COVID19 at different times, with some falling away while others are still rising. 
 Setting day 1 as the first day where 10 cases were recorded on the same day seems to best align most countries. 
 
We can already see there's some serious outliers in the data. One way of spotting them is to take a linear model of the nearest observations (in this case 8 forward and 8 backward) and forecast each values position. Then we can highlight those more than 3sd from the line to investigate further.
 ![Gif](https://raw.githubusercontent.com/michaelhawley/Demo/master/R/Outliers_1_InitialView.png) 

Upon doing this, we can see a pattern exists - look at Alaska! A pattern exists across most countries with very high days following low days. This is likely where testing is delayed and reported the next day. These jumps aren't necessarily outliers but a reflection of the nature of the reporting. We want to identify outliers, data points that are outside the normal range.  Instead the function should ask if an indivdual observation is higher than expected. If so, it's averaged with the lower of it's neighbours (and vv). Observations that are still over 3sd from where they should be are highlighted. 

Outliers_2_DifferentMethod

After making this fix, I went through a graph of each region of the world to check which observations are highlighted. 

Outliers_Cases_Found

Outliers_Deaths_Found