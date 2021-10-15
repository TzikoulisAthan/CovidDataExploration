SELECT location , population FROM Covid_db.owid_covid_deaths_clean_csv  
group by Location , Population 

SELECT location , population FROM Covid_db.usa_covid_deaths_clean_csv 
WHERE location LIKE "Europe" AND population is not NULL 
order by 1

-- Looking at total cases/total deaths(likelihood of dying). ORDER by date asc
SELECT location , `date` , total_cases , total_deaths, (total_deaths/total_cases)*100 as death_percentage
FROM Covid_db.usa_covid_deaths_clean_csv 
ORDER BY 1,2
 
-- Total cases / population (infection percentage) in the US
SELECT location , `date` , total_cases , population , (total_cases /population)*100 as infection_percentage, (total_deaths/total_cases)*100 as death_percentage
FROM Covid_db.usa_covid_deaths_clean_csv 
WHERE location LIKE "%states%"
ORDER BY 1,2 DESC 

-- Calculate countries' infection rate and order by max values
SELECT location , population , MAX(total_cases),  MAX(total_cases /population)*100 as infection_percentage
FROM Covid_db.owid_covid_deaths_clean_csv 
group by location , population 
ORDER BY infection_percentage DESC 

-- Calculate European countries' infection rate and order by max values
SELECT continent , location , population , MAX(total_cases),  MAX(total_cases /population)*100 as infection_percentage
FROM Covid_db.owid_covid_deaths_clean_csv 
WHERE continent LIKE 'Europe'
group by location , population , continent 
ORDER BY infection_percentage DESC 

-- Death count per country
SELECT location, MAX(total_deaths) as Total_Death_Count
FROM Covid_db.owid_covid_deaths_clean_csv
WHERE continent is not NULL 
group by location 
ORDER BY Total_Death_Count DESC 

-- EXPLORE DATA IN CONTINTENT LEVEL
-- Calculate infection rate and order by max values per continent 
SELECT continent , MAX(total_cases),  MAX(total_cases /population)*100 as infection_percentage
FROM Covid_db.owid_covid_deaths_clean_csv 
WHERE continent is NOT NULL 
group by continent 
ORDER BY infection_percentage DESC 

-- Calculate death rate per continent
SELECT continent , MAX(total_deaths) as Continent_Death_Count, MAX(total_cases / population)*100 as infection_percentage
FROM Covid_db.owid_covid_deaths_clean_csv 
WHERE continent IS NOT NULL 
GROUP BY continent 
ORDER BY continent DESC 

-- EXPLORE AT GLOBAL LEVEL
-- Global total cases, death count and death ratio
SELECT SUM(total_deaths) as Global_Death_Count, SUM(total_cases) as Global_Cases_Count, (SUM(total_deaths)/SUM(total_cases))*100 as Global_Death_Rate
FROM Covid_db.owid_covid_deaths_clean_csv 


-- Daily global cases and deaths
SELECT `date` , SUM(total_deaths) as Global_Death_Count, SUM(total_cases) as Global_Cases_Count, (SUM(total_deaths)/SUM(total_cases))*100 as Global_Death_Rate
FROM Covid_db.owid_covid_deaths_clean_csv 
group by `date` 
ORDER BY `date` 

-- WORK WITH VACCINATION TABLE 
-- View people vaccination in the EU countries
SELECT location , continent , max(people_fully_vaccinated) AS Fully_Vaccinated, MAX(people_fully_vaccinated_per_hundred) as  Fully_Vaccinated_Per_Hundred
FROM Covid_db.owid_covid_vaccs_clean_csv 
WHERE continent LIKE 'Europe'
GROUP BY location, continent 
ORDER BY Fully_Vaccinated_Per_Hundred DESC 



-- COMBINE DEATH AND VACCINATION DATA TABLE AND EXPLORE 
-- Find total tests performed in every continent 
SELECT dt.continent , SUM(vc.total_tests) as Total_Tests_Performed
FROM Covid_db.owid_covid_deaths_clean_csv dt
	JOIN Covid_db.owid_covid_vaccs_clean_csv vc ON dt.location = vc.location 
GROUP BY dt.continent

-- View people vaccination in the EU countries
SELECT vc.location , vc.continent , max(vc.people_fully_vaccinated) AS Fully_Vaccinated,
	MAX(vc.people_fully_vaccinated_per_hundred) as  Fully_Vaccinated_Per_Hundred,
	MAX(dt.total_deaths) as Total_Deaths 
FROM Covid_db.owid_covid_vaccs_clean_csv vc
	join Covid_db.owid_covid_deaths_clean_csv dt ON vc.location = dt.location 
WHERE vc.continent LIKE 'Europe'
GROUP BY location, continent 

-- New vaccinations performed in Greece daily and cumulative table 
SELECT dt.location, dt.`date`, vc.new_vaccinations as New_Vaccinations,
	SUM(vc.new_vaccinations) OVER (PARTITION BY dt.location order by dt.`date`) as Cumulative_Vaccinations
FROM Covid_db.owid_covid_deaths_clean_csv dt
	JOIN Covid_db.owid_covid_vaccs_clean_csv vc 
	ON dt.location = vc.location 
	AND dt.`date` = vc.`date` 
WHERE dt.continent is not NULL and vc.new_vaccinations is not NULL and dt.location like 'Greece'

-- USE COMMON TABLE EXPRESSIONS
-- Calculate daily vaccination percentage to total population
-- Results are off due to vaccinations are not referring to people but to doses

WITH cte_vacc (Location, Date, Population, NewVaccinations, CumulativeVaccinations)
AS
(
SELECT dt.location, dt.`date`, dt.population, vc.new_vaccinations,
	SUM(vc.new_vaccinations) OVER (PARTITION BY dt.location order by dt.`date`) as Cumulative_Vaccinations
FROM Covid_db.owid_covid_deaths_clean_csv dt
	JOIN Covid_db.owid_covid_vaccs_clean_csv vc 
	ON dt.location = vc.location 
	AND dt.`date` = vc.`date` 
WHERE dt.continent is not NULL and vc.new_vaccinations is not NULL and dt.location like 'Greece'
)
SELECT *, (CumulativeVaccinations/population)*100 as DailyVaccinationPercentage
FROM cte_vacc

-- CREATE VIEWS
CREATE VIEW VaccinationEvolution AS
WITH cte_vacc (Location, Date, Population, NewVaccinations, CumulativeVaccinations)
AS
(
SELECT dt.location, dt.`date`, dt.population, vc.new_vaccinations,
	SUM(vc.new_vaccinations) OVER (PARTITION BY dt.location order by dt.`date`) as Cumulative_Vaccinations
FROM Covid_db.owid_covid_deaths_clean_csv dt
	JOIN Covid_db.owid_covid_vaccs_clean_csv vc 
	ON dt.location = vc.location 
	AND dt.`date` = vc.`date` 
WHERE dt.continent is not NULL and vc.new_vaccinations is not NULL and dt.location like 'Greece'
)
SELECT *, (CumulativeVaccinations/population)*100 as DailyVaccinationPercentage
FROM cte_vacc

