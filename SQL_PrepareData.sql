

/* --- Can we answer some basic questions ---  */
/* --- 1. What regions of the world are the worst affected? ---  */
/* --- 			Here we should pair in a lookup for region ---  */
/* --- 2. Have their been any outliers in the data we should know about? E.g. when cases jump due to increased testing ---  */
/* --- 			Here we probably want to look by week rather than by day to avoid the noise associated with natural data ---  */
/* --- 3. Is the death rate associated with the 65+ age group ---  */
/* --- 			Here we want to bring in some of the WorldBankDevelopment indicators ---  */

/* --- For this we require A) daily data, B) an aggregate to a weekly level, C) A Region Lookup D) WorldBank Indicator data  ---  */

/* --- A Daily Data---  */
DROP TABLE IF EXISTS geographicdistribution; /* create the table */
CREATE TABLE geographicdistribution (
	Date date, d int, m int, y int,
	Cases int, Deaths int,
	CountryName varchar (50),CountryCode varchar (50),CountryCodeLong varchar (50),
	Population2018 int
);
/* update with data from csv: NB - I used "C: address >cacls geographicdistribution.csv /g everyone:f" to give pgAdmin copy rights */
copy public.geographicdistribution (Date, d, m, y, Cases, Deaths, CountryName, CountryCode, CountryCodeLong, Population2018) 
FROM 'C:/Users/micha/projects/COVID/GEOGRA~1.CSV' DELIMITER ',' CSV HEADER QUOTE '"' ESCAPE '''';

CREATE UNIQUE INDEX id_covid ON geographicdistribution (Date, CountryCode);/* create the index */

/* remove unneeded columns*/
ALTER TABLE geographicdistribution
DROP COLUMN d, DROP COLUMN m, DROP COLUMN y, DROP COLUMN Population2018;

/* Add some more useful columns as the week and the running total to date in each country */
ALTER TABLE geographicdistribution
ADD COLUMN CasesToDate int, ADD COLUMN DeathsToDate int, ADD COLUMN Week Date;

/* Get the week */
UPDATE geographicdistribution
SET Week = Date + (7-extract(dow from Date))* INTERVAL '1 day' ;

/* Add the Running Total for CaseToDate*/
WITH RunningTotal as (
	SELECT Date, CountryCode, 
	(sum(cases) OVER(PARTITION BY CountryCode order by date )) as TotalCasesToDate,
	(sum(deaths) OVER(PARTITION BY CountryCode order by date )) as TotalDeathsToDate
	FROM geographicdistribution)
UPDATE geographicdistribution 
SET CasesToDate = TotalCasesToDate, DeathsToDate = TotalDeathsToDate 
FROM RunningTotal
WHERE geographicdistribution.CountryCode = RunningTotal.CountryCode AND geographicdistribution.Date = RunningTotal.Date
/* --- Finished with the daily data  ---  */


/* --- B Weekly Data  ---  */
DROP TABLE IF EXISTS geographicWeekly;
CREATE TABLE geographicWeekly as
	SELECT CountryCode, CountryName, Week, sum(cases) as Cases, sum(deaths) as Deaths, max(casestodate) as CasesToDate, max(DeathsToDate) as DeathsToDate
	FROM geographicdistribution
	GROUP BY CountryCode, CountryName, Week;

/*  Add in the cases from last week*/
ALTER TABLE geographicWeekly
ADD COLUMN Int float;
UPDATE geographicWeekly
SET TotalCasesPriorWeek = WeekPrior.CasesToDate
FROM (
	SELECT CasesToDate as CasesToDate,CountryCode, ((Week + 7* INTERVAL '1 day') :: date) as lastweek
	FROM geographicWeekly
	) as WeekPrior 
WHERE geographicWeekly.week = WeekPrior.lastweek
AND geographicWeekly.countrycode = WeekPrior.countrycode;
UPDATE geographicWeekly
SET TotalCasesPriorWeek = coalesce(TotalCasesPriorWeek,0);
/* --- END Weekly  ---  */

/* ---  c) Bring in the CountryLookup   ---*/
/* create the table */
DROP TABLE IF EXISTS CountryLookup;
CREATE TABLE CountryLookup (
	CountryCode varchar (2),CountryCodeLong varchar (50),Region varchar (50),Subregion varchar (50)
);
/* update with data from csv */
copy public.CountryLookup (CountryCode,CountryCodeLong,Region,Subregion) 
FROM 'C:/Users/micha/projects/COVID/CountryLookup.CSV' DELIMITER ',' CSV HEADER QUOTE '"' ESCAPE '''';


/* ---  D) Bring in the WorldIndicators   ---*/
/* create the table */
DROP TABLE IF EXISTS WorldIndicators;
CREATE TABLE WorldIndicators (
	CountryName varchar (50),
	CountryCodeLong varchar (50),
	Series varchar (100),
	SeriesCode varchar (50),
	Y2015 varchar (50),
	Y2016 varchar (50),
	Y2017 varchar (50),
	Y2018 varchar (50),
	Y2019 varchar (50),
	v float
);
/* update with data from csv */
copy public.WorldIndicators (CountryName,CountryCodeLong,Series,SeriesCode,Y2015,Y2016,Y2017,Y2018,Y2019) 
FROM 'C:/Users/micha/projects/COVID/WorldIndicators.CSV' DELIMITER ',' CSV HEADER QUOTE '"' ESCAPE '''';

UPDATE WorldIndicators
SET v = CASE
	WHEN y2019 != '..' THEN CAST(y2019 as float)
	WHEN y2018 != '..' THEN CAST(y2018 as float)
	WHEN y2017 != '..' THEN CAST(y2017 as float)
	WHEN y2016 != '..' THEN CAST(y2016 as float)
	WHEN y2015 != '..' THEN CAST(y2015 as float)
	ELSE null
END;
ALTER TABLE WorldIndicators
DROP COLUMN y2015,
DROP COLUMN y2016,
DROP COLUMN y2017,
DROP COLUMN y2018,
DROP COLUMN y2019;

/* create age table */
/* check ava series */
/* 
SELECT series, SUM(case when v IS NULL THEN 0 ELSE 1 END) as haveData, count(v) as Total
FROM WorldIndicators
where series like '%age%' and not series like '%Immunization%'
GROUP BY Series
ORDER BY series
*/

CREATE EXTENSION tablefunc ;

DROP TABLE IF EXISTS age;
CREATE TABLE age as
	SELECT *
FROM crosstab(
  'select countrycodelong, series, v
   from WorldIndicators
   where series = ''Population ages 0-14, female'' 
   	or series = ''Population ages 0-14, male'' 
	or series = ''Population ages 15-64, female'' 
   	or series = ''Population ages 15-64, male''
	or series = ''Population ages 65 and above, female'' 
   	or series = ''Population ages 65 and above, male''
	or series = ''Population, total''
   ')
	AS ct(countrycodelong varchar(3), F0_14 float, M0_14 float, F15_64 float, M15_64 float, F65 float, M65 float, total float);


