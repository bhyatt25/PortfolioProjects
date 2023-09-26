--PART 1 - DATA EXPLORATION

--Reviewing imported CSVs (tables) into database (exploring the data)
SELECT *
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY location, date

SELECT *
FROM CovidVaccinations
WHERE continent IS NOT NULL
ORDER BY location, date

--Select data that we are going to be using
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY [location], [date]

--Looking at Total Cases vs Total Deaths
--Shows likelihood of dying if you contract COVID in country of choice
SELECT location, date, total_cases, total_deaths, (CAST(total_deaths as float)/cast(total_cases as float)) *100 AS 'DeathPercentage'
FROM CovidDeaths
WHERE location LIKE '%United States%' AND continent IS NOT NULL
ORDER BY [location], [date]

--Looking at Total Cases vs Population
--Shows what % of population contracted COVID
SELECT location, date, total_cases, population, (CAST(total_cases as float)/cast(population as float)) *100 AS 'InfectionRate'
FROM CovidDeaths
WHERE location LIKE '%United States%' AND continent IS NOT NULL
ORDER BY [InfectionRate] DESC

--Looking at Countries with Highest Infection Rate Compared to Population in 2021
SELECT location, population, MAX(total_cases) AS 'Highest Infection Count', MAX((CAST(total_cases as float)/cast(population as float))) *100 AS 'InfectionRate'
FROM CovidDeaths
WHERE YEAR([date]) = 2021 AND continent IS NOT NULL
GROUP BY location, population
ORDER BY InfectionRate DESC

--Showing the countries with highest death count by population
SELECT location, population, MAX(total_deaths) AS 'Highest Death Count', MAX((CAST(total_deaths as float)/cast(total_cases as float))) *100 AS 'DeathRate'
FROM CovidDeaths
WHERE YEAR([date]) = 2021 AND continent IS NOT NULL
GROUP BY location, population
ORDER BY [Highest Death Count] DESC

-- Breaking data down by CONTINENT
-- Continents with highest death count and deathRate
SELECT location, MAX(total_deaths) AS 'Total Death Count', MAX((CAST(total_deaths as float)/cast(total_cases as float))) *100 AS 'DeathRate'
FROM CovidDeaths
WHERE YEAR([date]) = 2021 AND continent IS NULL AND [location] NOT LIKE 'World' AND [location] NOT LIKE '%Income%' AND [location] NOT LIKE '%Union%'
GROUP BY location
ORDER BY [DeathRate] DESC

-- GLOBAL NUMBERS (using aggregate functions)
-- Overall death rate
SELECT  SUM(new_cases) AS 'Total Cases', SUM(new_deaths) AS 'Total Deaths', CONVERT(float,((CAST(SUM(new_deaths) as float)/NULLIF(CAST(SUM(new_cases) as float),0)))) *100 AS 'DeathPercentage'
FROM CovidDeaths
WHERE continent IS NOT NULL

-- death rate by day
SELECT date, SUM(new_cases) AS 'Total Cases', SUM(new_deaths) AS 'Total Deaths', CONVERT(float,((CAST(SUM(new_deaths) as float)/NULLIF(CAST(SUM(new_cases) as float),0)))) *100 AS 'DeathPercentage'
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY [date]
ORDER BY 1


--JOIN COVID DEATH AND COVID VACCINATION TABLES
-- Looking at total population vs. vaccinations
SELECT dea.continent, dea.[location], dea.[date], dea.population, vac.new_vaccinations
FROM CovidDeaths dea
JOIN CovidVaccinations vac
    ON dea.[location] = vac.[location]
    AND dea.[date] = vac.[date]
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

-- Adding a ROLLING TOTAL column (using Partition)
SELECT dea.continent, dea.[location], dea.[date], dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS 'RollingVaccinations'
FROM CovidDeaths dea
JOIN CovidVaccinations vac
    ON dea.[location] = vac.[location]
    AND dea.[date] = vac.[date]
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

-- Use ROLLING TOTAL to determine % Vaccinated by Country BY DAY -- USING CTE
WITH PopvsVac(continent, location, date, population,new_vaccinations, RollingVaccinations)
AS
(
SELECT dea.continent, dea.[location], dea.[date], dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS 'RollingVaccinations'
FROM CovidDeaths dea
JOIN CovidVaccinations vac
    ON dea.[location] = vac.[location]
    AND dea.[date] = vac.[date]
WHERE dea.continent IS NOT NULL
)
SELECT *, CAST(RollingVaccinations as float)/CAST(population as float) *100
FROM PopvsVac


-- Use ROLLING TOTAL to determine % Vaccinated by Country -- USING TEMP TABLE
DROP TABLE IF EXISTS #PercentPopulationVaccinated --(run line separately to remove table after changes made below)
CREATE TABLE #PercentPopulationVaccinated
(
    Continent nvarchar(50),
    location NVARCHAR(50),
    date date,
    Population bigint,
    New_Vaccinations bigint,
    RollingVaccinations bigint
)
INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.[location], dea.[date], dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS 'RollingVaccinations'
FROM CovidDeaths dea
JOIN CovidVaccinations vac
    ON dea.[location] = vac.[location]
    AND dea.[date] = vac.[date]
WHERE dea.continent IS NOT NULL

SELECT *, CAST(RollingVaccinations as float)/CAST(population as float) *100 AS 'DailyPercentVaccinated'
FROM #PercentPopulationVaccinated


-- CREATING A VIEW (stored in "Views" folder in Database)
CREATE VIEW PercentPopulationVaccinated2 as
SELECT dea.continent, dea.[location], dea.[date], dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS 'RollingVaccinations'
FROM CovidDeaths dea
JOIN CovidVaccinations vac
    ON dea.[location] = vac.[location]
    AND dea.[date] = vac.[date]
WHERE dea.continent IS NOT NULL

--Querying a View
SELECT *
FROM PercentPopulationVaccinated2