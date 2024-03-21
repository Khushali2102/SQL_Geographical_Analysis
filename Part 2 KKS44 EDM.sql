---Individual Project
---Name:Khushali Sheth kks44@njit.edu


--Creating Geospatial Data
Use Weather
go
IF NOT EXISTS(
    SELECT *
    FROM sys.columns 
    WHERE Name      = N'GeoLocation'
      AND Object_ID = Object_ID(N'AQS_Sites'))
BEGIN
      ALTER TABLE AQS_Sites ADD GeoLocation Geography NULL
END
go

UPDATE aqs_sites
SET GeoLocation = geography::STPointFromText('POINT(' + LONGITUDE + ' ' + 
                    [Latitude] + ')', 4326)
where (LATITUDE is not null and 
Longitude is not null) and 
Longitude <> '0' and 
Longitude <> ''

UPDATE [dbo].[AQS_Sites]
SET [GeoLocation] = geography::Point([Latitude], [Longitude], 4326)

if not exists(
	select * from sys.columns where name = 'Geolocation' and
	object_id = object_id('Aqs_sites'))
Begin
	Alter table Aqs_sites add Geolocation geography
End
Go

UPDATE [dbo].[AQS_Sites]
SET [Geolocation] = geography::Point(Latitude, Longitude, 4326 )

Select state_code, geolocation from aqs_sites

IF COL_LENGTH('aqs_sites', 'GeoLocation') IS NULL
BEGIN
alter table aqs_sites
add GeoLocation Geography
END

UPDATE [dbo].[AQS_Sites]
SET [GeoLocation] = geography::Point([Latitude], [Longitude], 4326) 
where [LATITUDE] is not null

-- To check if procedure exits
IF OBJECT_ID('kks44_Fall2022_Calc_GEO_Distance') IS NOT NULL
DROP procedure rg695_Fall2022_Calc_GEO_Distance
GO
-- Creating a new procedure
CREATE procedure kks44_Fall2022_Calc_GEO_Distance
@longitude varchar(255),
@latitude varchar(255),
@State varchar(255),
@rownum int
as 
begin
	declare @h geography
	set @h = geography::Point(@longitude, @latitude, 4326)
	select top(@rownum)
	site_number,
	Local_Site_Name =
	CASE
	WHEN local_site_name IS NULL THEN Site_Number + City_Name
	ELSE Local_Site_Name
	END,
	Address,
	City_Name,
	State_Name,
	Zip_Code,
	Geolocation.STDistance(@h) as Distance_In_Meters,
	Latitude,
	Longitude,
	(Geolocation.STDistance(@h))/80000 as Hours_of_Travel
	from [aqs_sites]
	where State_Name = @State
	end
GO


-- Execute following queries to check stored procedure result
EXEC kks44_Fall2022_Calc_GEO_Distance '-74.426598','40.4991','Arizona',15
GO

-- Checking for Location 1
EXEC [dbo].[kks44_Fall2022_Calc_GEO_Distance]
@latitude = '40.058324',
@longitude = '-74.405661', 
@State = 'New York', 
@rownum = 15
GO

-- Checking for Location 2
EXEC [dbo].[kks44_Fall2022_Calc_GEO_Distance]
@latitude = '36.778261',
@longitude = '-119.417932',  
@State = 'California', 
@rownum = 30
GO


-- Following query shows geolocation column and data is loaded into it
SELECT Top 50 GeoLocation FROM aqs_sites;
EXEC kks44_Fall2022_Calc_GEO_Distance'-81.33821','27.48589','Florida',5
GO

