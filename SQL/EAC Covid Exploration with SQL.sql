

-- ORGANIZING DATA

-- Extract only East Africa Community (EAC) countries data from the the world's covid dataset.

SELECT location, 
    date, 
    total_cases, 
    total_deaths,  
    total_vaccinations,  
    population 
FROM portfolio..covid
WHERE (location = 'Tanzania') or 
    (location = 'Kenya') or 
    (location = 'Uganda') or 
    (location = 'Burundi') or 
    (location = 'Rwanda') or 
    (location = 'Democratic Republic of Congo')
ORDER BY 1
-- Then save as eac_covid.csv file 


-- Total Cases vs Total Death

SELECT location,
    date,
    (TRY_CONVERT(int, total_deaths) / TRY_CONVERT(int, total_cases)) * 100 as DeathPercantage
FROM portfolio..eac_covid
ORDER BY 1,2



-- Total Cases vs Population
-- Shows what Percentage of population infected with Covid

SELECT location,
    date,
    population,
    total_cases,
    (TRY_CONVERT(int, total_cases)/population) * 100 as PercentPopulationInfected
FROM portfolio..eac_covid 
ORDER BY 1,2


-- Countries with Highest Infections

SELECT location, 
    population, 
    MAX(TRY_CONVERT(int, total_cases)) as HighestInfectionCount
FROM portfolio..eac_covid 
GROUP BY location, population
ORDER BY HighestInfectionCount DESC



-- Countries with Highest Infection Rate compared to Population

SELECT location, 
    population, 
    MAX(TRY_CONVERT(int, total_cases)) as HighestInfectionCount,
    MAX((TRY_CONVERT(int, total_cases) / population)) * 100 as PercentPopulationInfected
FROM portfolio..eac_covid 
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC



-- Countries with Highest Death Count

SELECT location, 
    MAX(TRY_CONVERT(int, total_deaths)) as TotalDeathCount
FROM portfolio..eac_covid 
GROUP BY location
ORDER BY totalDeathCount DESC


-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved Covid Vaccine

SELECT location,
    population,
    MAX(TRY_CONVERT (int,total_vaccinations)) as TotalVaccinationCount,
    (MAX(TRY_CONVERT (int,total_vaccinations)) / population) * 100 AS PercentPopulationVaccinated 
FROM portfolio..eac_covid 
GROUP BY location, population
ORDER BY PercentPopulationVaccinated DESC


---Create View to Store Data for Later Visualization

CREATE VIEW 
    PercentPopulationVaccinated AS
SELECT location,
    date,
    population,
    total_vaccinations
FROM portfolio..eac_covid 