-- Select the data we are going to be using

SELECT location, date, total_cases,new_cases,total_deaths,population
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2

-- Looking at total cases vs total deaths
-- Shows the likelihood of dying if you contract COVID in your country

SELECT location,date,total_cases,total_deaths,(total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
--WHERE location like '%states%'
WHERE continent IS NOT NULL
ORDER BY 1,2

-- Looking at total cases vs population
-- Shows what percentage of population for COVID

SELECT location,date,total_cases,population,(total_cases/population)*100 AS CasePercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
--WHERE location like '%states%'
ORDER BY 1,2

-- Looking at countries with highest infection rate compared to population
SELECT location,population,MAX(total_cases) AS HighestInfectionCount,MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
--WHERE location like '%states%'
WHERE continent IS NOT NULL
GROUP BY location,population
ORDER BY PercentPopulationInfected DESC

-- Showing Countries with highest death count per Location

SELECT location,MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC


-- Let's break things down by Continent

-- Showing continents with highest death count

SELECT continent,MAX(CAST(total_deaths AS INT)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC


-- GLOBAL NUMBERS

SELECT SUM(new_cases) as total_cases,SUM(CAST(new_deaths AS INT)) as total_deaths, 
	   SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
--WHERE location like '%states%'
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1,2


-- Join both tables

SELECT * 
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
ON dea.location = vac.location 
and dea.date = vac.date

-- Looking at Total Population vs Total Vaccinations

SELECT dea.continent, dea.location,dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
ON dea.location = vac.location 
and dea.date = vac.date
WHERE dea.continent IS NOT NULL 
ORDER BY 1,2,3

-- USE CTE

WITH PopvsVac(Continent,Location,Date,Population,New_Vaccinations,RollingPeopleVaccinated) as 
(SELECT dea.continent, dea.location,dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(float,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
ON dea.location = vac.location 
and dea.date = vac.date
WHERE dea.continent IS NOT NULL 
)
SELECT *,(RollingPeopleVaccinated/Population)*100 
FROM PopvsVac
ORDER BY 1,2,3


-- USE TEMP TABLE
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingPeopleVaccinated numeric
)
INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location,dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
ON dea.location = vac.location 
and dea.date = vac.date
WHERE dea.continent IS NOT NULL 
ORDER BY 1,2,3

SELECT *,(RollingPeopleVaccinated/Population)*100 
FROM #PercentPopulationVaccinated
ORDER BY 1,2,3

-- Creating a View

CREATE VIEW PercentPopulationVaccinated as
SELECT dea.continent, dea.location,dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
ON dea.location = vac.location 
and dea.date = vac.date
WHERE dea.continent IS NOT NULL 
--ORDER BY 1,2,3

select *
from PercentPopulationVaccinated