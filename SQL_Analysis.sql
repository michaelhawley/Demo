/* --- Can we answer some basic questions ---  */
/* --- 1. What regions of the world are the worst affected? ---  */
/* --- 2. Have their been any outliers in the data we should know about? E.g. when cases jump due to increased testing ---  */
/* --- 3. Is the death rate associated with the 65+ age group ---  */

/* --- 1. What regions of the world are the worst affected? ---  */
/* --- Clearly Europe and North America are the worst hit in terms of 'reported deaths' ---  */
SELECT CL.subregion, sum(gd.deathstodate) as Deaths
FROM geographicdistribution as gd
	INNER JOIN 
	(SELECT MAX(Date)as MD FROM geographicdistribution)as MDData
	ON gd.date = MDData.MD
	INNER JOIN CountryLookup as CL
	ON gd.CountryCode = CL.CountryCode
GROUP BY CL.subregion
ORDER BY Deaths DESC

/* --- 2. Have their been any outliers in the data we should know about? E.g. when cases jump due to increased testing ---  */
/* --- We can see that across the world, lots of countries have masssive increases in a single week  ---  */
SELECT countryname, week, casestodate, totalcasespriorweek, CAST(casestodate/totalcasespriorweek AS SMALLINT) as delta
FROM geographicWeekly
WHERE totalcasespriorweek <> 0 and totalcasespriorweek > 20
ORDER BY Delta DESC
/* --- Where there are already a lot of cases, this could indicate the begining of systematic testings  ---  */
/* --- China and the US stick out as having unusually fast growth of cases  ---  */
SELECT countryname, week, casestodate, totalcasespriorweek, CAST(casestodate/totalcasespriorweek AS SMALLINT) as delta
FROM geographicWeekly
WHERE totalcasespriorweek <> 0 and totalcasespriorweek > 1000
ORDER BY Delta DESC

/* --- 3. Is the death rate associated with the 65+ age group ---  */
/* --- It appears there is some correlation, for a more robust analysis we should turn to R  ---  */
SELECT gd.countryname, gd.casestodate, gd.deathstodate, ROUND((100*gd.deathstodate/gd.casestodate :: numeric),1)::float as deathrate,
ROUND(CAST(100*age.m65/age.total as numeric),2) as MaleOver65,
ROUND(CAST(100*age.F65/age.total as numeric),2) as FemaleOver65,
ROUND(CAST(100*(age.m65+age.f65)/age.total as numeric),2) as Over65
FROM geographicdistribution as gd
	INNER JOIN 
	(SELECT MAX(Date)as MD FROM geographicdistribution)as MDData
	ON gd.date = MDData.MD
	INNER JOIN AGE
	ON gd.countrycodelong = Age.countrycodelong
WHERE AGE.total is not null and gd.deathstodate >100 and age.m65 is not null
ORDER BY deathstodate desc

