--first explore data. make sure tables populated correctly
-- data pulled from https://ourworldindata.org/covid-deaths
SELECT *
FROM coviddeaths
Order By 3,4

SELECT *
FROM Covidvax
order by 3,4

Select Location, Date, total_cases, new_cases, total_deaths, population
FROM coviddeaths
order by 1,2



--Look at total cases vs total deaths
--Shows likelihood of dying if you contract covid
SELECT Location, Date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathRatePercentage
FROM coviddeaths
WHERE Location = 'United States'
order by 1,2


--Look at total cases vs population
--shows what percentage of population contracted covid in US
SELECT Location, Date, total_cases, population, (total_cases/population)*100 as PercentCovidPositive
FROM coviddeaths
WHERE Location = 'United States'
order by 1,2

--Looking at Countries with highest infection rate compared to populations
--grouped by location and sort by percentpopulationinfectedc
SELECT Location, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population)*100) as PercentPopulationInfected
FROM coviddeaths
Group By population, location
order by 3 desc

--Countries with highest death count per Popuylation
--add where to clean up locations
SELECT Location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM coviddeaths
Where continent is not null
Group By location
order by 2 desc

--Let's break things down by continent
SELECT location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM coviddeaths
Where continent is null
Group By location
order by 2 desc

--showing continents with the highest death count per pop
--begin to think about viz
SELECT continent, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM coviddeaths
Where continent is not null
Group By continent
order by 2 desc

--global numbers
SELECT date, Sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths, sum(cast(new_deaths as int))/sum(new_cases)*100 as DeathPercentage--, total_deaths, (total_deaths/total_cases)*100 as DeathRatePercentage
FROM coviddeaths
Where continent is not null
group by date
order by 1,2

--total global nuimbers one line
SELECT Sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths, sum(cast(new_deaths as int))/sum(new_cases)*100 as DeathPercentage--, total_deaths, (total_deaths/total_cases)*100 as DeathRatePercentage
FROM coviddeaths
Where continent is not null
order by 1,2

--NOW LET'S START BRINGING IN THE OTHER TABLE
SELECT *
from coviddeaths dea
JOIN covidvax vax
	on dea.location = vax.location
	and dea.date = vax.date

--looking at total population vs vaccinations
Select dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations, sum(convert(bigint,vax.new_vaccinations)) OVER (partition by dea.location Order By dea.location, dea.date) as RollingPeopleVaccinated,
--now we want to divide rolling people vaccinated by population
from coviddeaths dea
JOIN covidvax vax
	on dea.location = vax.location
	and dea.date = vax.date
Where dea.continent is not null
Order by 2,3

--CTE
With PopvsVac (Continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations, sum(convert(bigint,vax.new_vaccinations)) OVER (partition by dea.location Order By dea.location, dea.date) as RollingPeopleVaccinated
From coviddeaths dea
JOIN covidvax vax
	on dea.location = vax.location
	and dea.date = vax.date
Where dea.continent is not null
)
SELECT *, (RollingPeopleVaccinated/Population)*100
From PopvsVac

--or temp table
--Drop table if exists #percentpopulationvaccinated **use this is u make changes and need to replace
Create Table #percentpopulationvaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingPeopleVaccinated numeric
)

insert into #percentpopulationvaccinated
Select dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations, sum(convert(bigint,vax.new_vaccinations)) OVER (partition by dea.location Order By dea.location, dea.date) as RollingPeopleVaccinated
From coviddeaths dea
JOIN covidvax vax
	on dea.location = vax.location
	and dea.date = vax.date
Where dea.continent is not null

SELECT *, (RollingPeopleVaccinated/Population)*100
From #percentpopulationvaccinated


--create a view to store data for later viz
Create View percentpopulationvaccinated as 
Select dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations, sum(convert(bigint,vax.new_vaccinations)) OVER (partition by dea.location Order By dea.location, dea.date) as RollingPeopleVaccinated
From coviddeaths dea
JOIN covidvax vax
	on dea.location = vax.location
	and dea.date = vax.date
Where dea.continent is not null
