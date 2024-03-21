---Individual Project
---Name:Khushali Sheth kks44@njit.edu





Go
if not exists(
	select * from sys.columns where name = 'Geolocation' and
	object_id = object_id('Guncrimes'))
Begin
	Alter table Guncrimes add Geolocation geography
End
Go

update Guncrimes
set [geolocation] = geography::Point([Latitude], [Longitude], 4326)

select incident_id, geolocation from guncrimes

select (site_number + ' - ' + a. city_name + ' - ' + a.address) as [local site name], a.city_name, 
	datepart(year, date) as crime_year, count(incident_id) as shooting_count
from aqs_sites as a, guncrimes as g
where a.state_name = g.state and
	a.city_name = g.city_or_county and
	(g.geolocation.STDistance(g.geolocation)) <= 16000 and
	g.state = 'New Jersey'
group by site_number, a.address, a.city_name, datepart(year, date)
order by [local site name], crime_year


--4.Write a query that ranks all the cities in the state you selected from lowest to highest number of GunCrimes

select (site_number + ' - ' + a. city_name + ' - ' + a.address) as [local site name], a.city_name, 
	datepart(year, date) as crime_year, count(incident_id) as shooting_count,
	dense_rank() over (partition by a.city_name order by count(incident_id)) as rank
from aqs_sites as a, guncrimes as g
where a.state_name = g.state and
	a.city_name = g.city_or_county and
	(g.geolocation.STDistance(g.geolocation)) <= 16000 and 
	g.state = 'New Jersey'
group by site_number, a.address, a.city_name, datepart(year, date)
order by city_name, rank
