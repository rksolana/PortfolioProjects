select *
from PortfolioProject..CovidDeaths
where continent is not null
order by 3, 4

--select *
--from PortfolioProject..CovidVaccinations
--order by 3, 4

select Location, Date, Total_Cases, New_Cases, Total_Deaths, Population
from PortfolioProject..CovidDeaths
order by 1,2


select Location, Date, Total_Cases, Total_Deaths, (Total_Deaths/Total_Cases)*100 as DeathPercentage
from PortfolioProject..CovidDeaths
where location like '%states%'
order by 1, 2

select Location, Date, Total_Cases, Population, (Total_Cases/population)*100 as PercentPopulationInfected
from PortfolioProject..CovidDeaths
--where location like '%states%'
order by 5 desc

select Location, Population, Max(total_cases) as HighestInfectionCount, (max(Total_Cases)/population)*100 as PercentPopulationInfected
from PortfolioProject..CovidDeaths
--where location like '%states%'
group by location, population
order by 4 desc

select Location, max(cast(total_deaths as int)) as TotalDeathCount
from PortfolioProject..CovidDeaths
where continent is not null
group by location
order by 2 desc

select continent, max(cast(total_deaths as int)) as TotalDeathCount
from PortfolioProject..CovidDeaths
where continent is not null
group by continent
order by 2 desc

select continent, location, total_deaths
from PortfolioProject..CovidDeaths
where continent is not null
order  by 1, 2


select Date, sum(new_cases) as NewCases, sum(cast(new_deaths as int)) as NewDeaths, sum(cast(new_deaths as int))/sum(new_cases)*100 AS DeathPercentage
from PortfolioProject..CovidDeaths
where continent is not null
group by date
order by 1, 2

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(cast(new_vaccinations as int)) OVER (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

with PopVsVac (continent, location, date, population, new_vaccinations, rollingpeoplevaccinated)
as (
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(cast(new_vaccinations as int)) OVER (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
)

select *, (rollingpeoplevaccinated/population)*100
from PopVsVac

drop table if exists #percentpopulationvaccinated
create table #PercentPopulationVaccinated
(
continent nvarchar(255), location nvarchar(255), date datetime, population numeric, new_vaccinations numeric, rollingpeoplevaccinated numeric
)

insert into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(cast(new_vaccinations as int)) OVER (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null

select *, (rollingpeoplevaccinated/population)*100
from #PercentPopulationVaccinated


create View PercentPopulationVaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(cast(new_vaccinations as int)) OVER (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null

select *
from PercentPopulationVaccinated