ALTER MASTER KEY REGENERATE WITH ENCRYPTION BY PASSWORD = 'Password0~';
GO

--DROP TABLE[dbo].[States];
CREATE TABLE [dbo].[States](
	[State] [varchar](2) NULL,
	[StateKey] [int] NULL
)
WITH
(
    DISTRIBUTION = REPLICATE
)
;

--DROP TABLE[dbo].[Specialty];
CREATE TABLE [dbo].[Specialty](
	[SpecialtyDescriptionFlag] [varchar](2) NULL,
	[Year] [int] NULL,
	[YearSpecialtyKey] [int] NULL,
	[Specialty] [varchar](100) NULL
)
WITH
(
	DISTRIBUTION = REPLICATE
);

--DROP TABLE[dbo].[Providers];
CREATE TABLE [dbo].[Providers](
	[npi] [int] NULL,
	[LastName] [varchar](100) NULL,
	[FirstName] [varchar](50) NULL,
	[FullName] [varchar](150) NULL,
	[Year] [int] NULL,
	[YearNPI] [int] NOT NULL
)
WITH
(
	CLUSTERED COLUMNSTORE INDEX,
    DISTRIBUTION = HASH([YearNPI])
);

--DROP TABLE[dbo].[Geography];
CREATE TABLE [dbo].[Geography](
	[City] [varchar](50) NULL,
	[State] [varchar](2) NULL,
	[Year] [int] NULL,
	[YearGeoKey] [int] NULL,
	[CityState] [varchar](50) NULL,
	[StateKey] [int] NULL
)
WITH
(
	DISTRIBUTION = REPLICATE
);

--DROP TABLE[dbo].[Drugs];
CREATE TABLE [dbo].[Drugs](
	[DrugName] [varchar](50) NULL,
	[GenericName] [varchar](50) NULL,
	[Year] [int] NULL,
	[YearDrugKey] [int] NULL
) 
WITH
(
	DISTRIBUTION = REPLICATE
);

--DROP TABLE[dbo].[Details];
CREATE TABLE [dbo].[Details](
	[BeneficiaryCount] [int] NULL,
	[TotalClaimCount] [int] NULL,
	[Total30DayFillCount] [decimal](10, 2) NULL,
	[TotalDaySupply] [int] NULL,
	[TotalDrugCost] [decimal](10, 2) NULL,
	[BeneCountGe65] [int] NULL,
	[BeneCountGe65SuppressFlag] [varchar](2) NULL,
	[TotalClaimCountGe65] [int] NULL,
	[Ge65SuppressFlag] [varchar](2) NULL,
	[Total30DayFillCountGe65] [decimal](10, 2) NULL,
	[TotalDrugCostGe65] [decimal](10, 2) NULL,
	[TotalDaySupplyGe65] [int] NULL,
	[Year] [int] NULL,
	[YearNPI] [int] NULL,
	[YearGeoKey] [int] NULL,
	[YearSpecialtyKey] [int] NULL,
	[YearDrugKey] [int] NULL,
	[CostPerDay] [decimal](10, 2) NULL
)
WITH
(
	CLUSTERED COLUMNSTORE INDEX,
    DISTRIBUTION = HASH([YearNPI])
);
GO

--DROP VIEW [dbo].[Agg-Drug-Specialty-State-Year];
CREATE VIEW [dbo].[Agg-Drug-Specialty-State-Year]
AS
SELECT SUM(dbo.Details.BeneficiaryCount) AS BeneficiaryCount, SUM(dbo.Details.TotalClaimCount) AS TotalClaimCount, SUM(dbo.Details.Total30DayFillCount) AS Total30DayFillCount, SUM(dbo.Details.TotalDaySupply) AS TotalDaySupply, SUM(dbo.Details.TotalDrugCost) AS TotalDrugCost, dbo.Details.Year, dbo.Geography.StateKey, dbo.Details.YearSpecialtyKey, 
         dbo.Details.YearDrugKey
FROM  dbo.Details LEFT OUTER JOIN
         dbo.Geography ON dbo.Details.YearGeoKey = dbo.Geography.YearGeoKey
GROUP BY dbo.Details.Year, dbo.Geography.StateKey, dbo.Details.YearSpecialtyKey, dbo.Details.YearDrugKey
;
GO
