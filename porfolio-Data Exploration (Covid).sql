-- Total Cases and Total Deaths
-- Show the percentage of deaths

SELECT continent, location, date, total_cases, total_deaths, (total_cases/total_deaths)*100 AS death_percentage
FROM coviddeaths
Where location = 'Vietnam' 
Order By total_cases DESC;

-- Total Cases and population
-- Show the percentage of population got Covid

SELECT continent, location, date, total_cases, population, (total_cases/population)*100 AS death_percentage
FROM coviddeaths
Where location = 'Vietnam' 
Order By total_cases DESC;

-- Show countries with HIGHEST Death count per population

SELECT location, MAX(total_deaths) AS TotalDeathCount
FROM coviddeaths
Where continent is not null
Group by location
Order By TotalDeathCount DESC;

--  Show continent with HIGHEST Death 

SELECT continent, MAX(total_deaths) AS TotalDeathCount
FROM coviddeaths
Where continent is not null
Group by continent
Order By TotalDeathCount DESC;

-- Show Globle numbers

SELECT date, SUM(new_cases) AS total_new_cases, SUM(new_deaths) AS total_new_deaths, SUM(new_deaths)/SUM(new_cases) AS death_percentage
FROM coviddeaths
Where continent is not null
Group By date
Order By 2;

SELECT SUM(new_cases) AS total_new_cases, SUM(new_deaths) AS total_new_deaths, SUM(new_deaths)/SUM(new_cases) AS death_percentage
FROM coviddeaths
Where continent is not null
Order By 2;

-- Show total population and vacination

SELECT cv.location, sum(cv.new_vaccinations) AS total_vaccinations
FROM covidvaccinations cv
Where cv.location = 'Vietnam';


SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (Partition by dea.location order by dea.location) 
FROM coviddeaths dea
Join covidvaccinations vac
	On dea.location = vac.location
    and dea.date = vac.date
Where dea.continent is not null
Order By 2,3;

-- Use CTE

With PopvsVac (Continent, Location, Population, New_Vaccinations, RollingPeopleVaccinated) 
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (Partition by dea.location order by dea.location) 
FROM coviddeaths dea
Join covidvaccinations vac
	On dea.location = vac.location
    and dea.date = vac.date
Where dea.continent is not null
-- Order By 2,3;
)
Select *, (RollingPeopleVaccinated/population)*100
From PopvsVac; 

-- Temp table

Drop table if Exists PercentPopulationVaccinated;
Create Table if not Exists PercentPopulationVaccinated
(
Continent varchar(255),
Location varchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
);

Insert into PercentPopulationVaccninated  
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (Partition by dea.location order by dea.location) 
FROM coviddeaths dea
Join covidvaccinations vac
	On dea.location = vac.location
    and dea.date = vac.date
Where dea.continent is not null;
--    Order By 2,3;

Select *, (RollingPeopleVaccinated/population)*100
From PercentPopulationVaccninated;


SELECT date, CAST(date AS DATETIME) AS dateformat
FROM coviddeaths;




