SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent is NOT NULL
ORDER BY 3,4

--SELECT *
--FROM PortfolioProject..CovidVaccination
--ORDER BY 3,4

--Dataset

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2

ALTER TABLE CovidDeaths
ALTER COLUMN total_deaths int

ALTER TABLE CovidDeaths
ALTER COLUMN total_cases int

--Cases vs Deaths
SELECT location, date, total_cases, total_deaths, (CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0)) * 100 AS Deathpercentage
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2

--Death percentage in Malaysia
SELECT location, date, total_cases, total_deaths, (CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0)) * 100 AS Deathpercentage
FROM PortfolioProject..CovidDeaths
WHERE location = 'Malaysia'
ORDER BY 1,2

--Total Cases vs population
SELECT location, date, total_cases, population, (total_cases/population)*100 AS CasesPercentage
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2

--Cases percentage in Malaysia
SELECT location, date, total_cases, population, (total_cases/population)*100 AS CasesPercentage
FROM PortfolioProject..CovidDeaths
WHERE location = 'Malaysia'
ORDER BY 1,2

--location where the cases percentage is the highest
SELECT location, population,  MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population)*100) AS HighestInfectionPercentage
FROM PortfolioProject..CovidDeaths
GROUP BY location, population
ORDER BY HighestInfectionPercentage desc

--countries with the highest death count
SELECT location, MAX(Total_deaths) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is NOT NULL
GROUP BY location
ORDER BY TotalDeathCount desc

--continents with the highest death count
SELECT continent, MAX(Total_deaths) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount desc

--SELECT location, MAX(Total_deaths) as TotalDeathCount
--FROM PortfolioProject..CovidDeaths
--WHERE continent is NULL AND location LIKE '%A%' OR location = 'Europe'
--GROUP BY location
--ORDER BY TotalDeathCount desc

--countries with the highest death percentage per population
SELECT location, MAX(Total_deaths) as TotalDeathCount, MAX((total_deaths/population)*100) 
AS DeathOverPopulationPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is NOT NULL
GROUP BY location
ORDER BY DeathOverPopulationPercentage desc

--continents with the highest death percentage per population
SELECT continent, MAX(Total_deaths) as TotalDeathCount, MAX((total_deaths/population)*100) 
AS DeathOverPopulationPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is NOT NULL
GROUP BY continent
ORDER BY DeathOverPopulationPercentage desc

ALTER TABLE CovidDeaths
ALTER COLUMN new_deaths float

ALTER TABLE CovidDeaths
ALTER COLUMN new_cases float

-- Delete data before 18 Jan 2020 because there is no cases
DELETE
FROM PortfolioProject..CovidDeaths
WHERE date < '2020-01-18'

--Global numbers by date
SELECT date, SUM(new_cases) AS DailyCases, SUM(new_deaths) AS DailyDeaths,
SUM(new_deaths)/NULLIF(SUM(new_cases),0)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is NOT NULL
GROUP BY date
ORDER BY 1,2

--Total global number
SELECT SUM(new_cases) AS DailyCases, SUM(new_deaths) AS DailyDeaths,
SUM(new_deaths)/NULLIF(SUM(new_cases),0)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is NOT NULL
ORDER BY 1,2

--VACCINATION
SELECT *
FROM PortfolioProject..CovidVaccination
ORDER BY 3,4

SELECT MIN(date)
FROM PortfolioProject..CovidVaccination

DELETE
FROM PortfolioProject..CovidVaccination
WHERE date < '2020-01-18'

SELECT *
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccination vac
	ON dea.location = vac.location
	AND dea.date = vac.date

--Check when is the first date for vaccination
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccination vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is NOT NULL AND new_vaccinations is NOT NULL
ORDER BY date

--Total population vs vaccination
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(Cast(vac.new_vaccinations AS float)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccination vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is NOT NULL
ORDER BY 2,3

--USE CTE
With PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(float,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccination vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is NOT NULL
)
SELECT *, (RollingPeopleVaccinated/population)*100 AS RollingVaccinationPercentage
FROM PopvsVac

--Use Temp Table
DROP TABLE If exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccination numeric,
RollingPeopleVaccinated numeric,
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(float,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccination vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is NOT NULL

SELECT *, (RollingPeopleVaccinated/population)*100 AS RollingVaccinationPercentage
FROM #PercentPopulationVaccinated
WHERE continent = 'Europe'

--View to store data for visualization
CREATE VIEW TotalDeathCountGlobal AS
SELECT continent, MAX(Total_deaths) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is NOT NULL
GROUP BY continent

CREATE VIEW PercentagePopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(float,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccination vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is NOT NULL

CREATE VIEW DeathVSCases AS
SELECT location, date, total_cases, total_deaths, (CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0)) * 100 AS Deathpercentage
FROM PortfolioProject..CovidDeaths
