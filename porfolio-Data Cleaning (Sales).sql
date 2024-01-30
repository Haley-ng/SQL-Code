-- Convert Date Format

UPDATE nashville
SET PropertyAddress = NULL
WHERE PropertyAddress = ' ';

SELECT PropertyAddress
FROM nashville
WHERE PropertyAddress = NULL;

SELECT OwnerAddress, SUBSTRING_INDEX(OwnerAddress, ',', 1) AS Street,
SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress,',', 2), ',',-1) AS City,
SUBSTRING_INDEX(OwnerAddress, ',', -1) as State 
FROM nashville;

-- Populate Property Adress Data

SELECT UniqueID, ParcelID,PropertyAddress
FROM nashville
WHERE PropertyAddress = NULL;


SELECT *
FROM nashville
WHERE PropertyAddress is not null AND PropertyAddress <>PercentPopulationVaccinated
Order By ParcelID;

SELECT a.UniqueID, a.ParcelID, a.PropertyAddress, b.UniqueID, b.ParcelID, b.PropertyAddress
FROM nashville a
JOIN nashville b
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress is not null AND a.PropertyAddress <> ' '
Order By a.ParcelID;


UPDATE nashville
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM nashville a
JOIN nashville b
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress = ' ';

-- Breaking out adress into individual columns (Address, City, State)

SELECT PropertyAddress
FROM nashville;

SELECT PropertyAddress, substring_index(PropertyAddress, ',', 1) AS Address
FROM nashville;

SELECT *
FROM nashville
WHERE SaleDate >= '31/12/2013';


SELECT SaleDate, STR_TO_DATE(SaleDate, GET_FORMAT(DATE, 101)) AS Date
FROM nashville;

-- Seperate Address with commas

SELECT OwnerAddress
FROM nashville;

SELECT OwnerAddress, SUBSTRING_INDEX(OwnerAddress, ',', 1) AS Street, -- in front of the comma
SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress,',', 2), ',',-1) AS City, 
SUBSTRING_INDEX(OwnerAddress, ',', -1) as State -- behind the comma
FROM nashville;

CREATE OR REPLACE VIEW OwnerAddress_Splited AS
SELECT 
	Ownername,
    SUBSTRING_INDEX(OwnerAddress, ',', 1) AS Street,
	SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress,',', 2), ',',-1) AS City, 
	SUBSTRING_INDEX(OwnerAddress, ',', -1) as State
FROM nashville;
    
SELECT Ownername, SUBSTRING_INDEX(Ownername, ',', 1) AS first_name, -- in front of the comma
SUBSTRING_INDEX(Ownername, ',', -1) as last_name -- behind the comma
FROM nashville;

alter table nashville
ADD OwnerStreet varchar(255), Add OwnerCity varchar(255), Add OwnerState varchar(255);

UPDATE nashville
Set OwnerStreet = SUBSTRING_INDEX(OwnerAddress, ',', 1),
	OwnerCity = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress,',', 2), ',',-1),
    OwnerState = SUBSTRING_INDEX(OwnerAddress, ',', -1);

select *
From nashville;

-- Change 'Y' and 'N' to 'Yes' and 'No' in SoldAsVacant

SELECT distinct(SoldAsVacant), COUNT(SoldAsVacant)
FROM sql_porfolio.nashville
GROUP BY SoldAsVacant
order by 2;

SELECT SoldAsVacant,
(Case 
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
    WHEN SoldAsVacant = 'N' THEN 'No'
    Else SoldAsVacant
    End)
FROM sql_porfolio.nashville;

UPDATE sql_porfolio.nashville
SET SoldAsVacant = Case WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	Else SoldAsVacant
	End;
    
-- Remove duplicates

-- *Check double rows

SELECT *, 
	row_number() OVER(
    partition by ParcelID, 
				PropertyAddress, 
				SalePrice, 
				SaleDate, 			
                LegalReference 
                order by 
					UniqueID
					) row_num
FROM sql_porfolio.nashville
order by ParcelID;

-- Remove double rows
		
With RownumberCTE As(
SELECT *, 
	row_number() OVER(
    partition by ParcelID, 
				PropertyAddress, 
				SalePrice, 
				SaleDate, 			
                LegalReference 
                order by 
					UniqueID
					) row_num
FROM sql_porfolio.nashville
-- order by ParcelID
)
delete
From RownumberCTE 
Where row_num > 1
order by ParcelID;


CREATE OR REPLACE VIEW RowNum AS
SELECT *, 
	row_number() OVER(
    partition by 
				ParcelID, 
				PropertyAddress, 
				SalePrice, 
				SaleDate, 			
                LegalReference 
                order by 
					UniqueID
					) row_num
FROM sql_porfolio.nashville
order by ParcelID;

SELECT *
FROM sql_porfolio.rownum
Where row_num >= 2;

delete
FROM sql_porfolio.rownum
Where row_num >= 2;

CREATE OR REPLACE VIEW douple_rows As
select *
From sql_porfolio.rownum
Where row_num > 1;


SELECT *, 
	row_number() OVER(
    partition by 
				ParcelID, 
				PropertyAddress, 
				SalePrice, 
				SaleDate, 			
                LegalReference 
                order by 
					UniqueID
					) row_num
FROM sql_porfolio.nashville
JOIN (SELECT * FROM rownum r2 Where row_num = 2);


SELECT *
FROM rownum r1
INNER JOIN douple_rows r2 ON r1.ParcelID = r2.ParcelID;

SELECT * FROM nashville
WHERE UniqueID in (
					SELECT n1.UniqueID, n1.ParcelID, n1.PropertyAddress, n1.SalePrice, n1.SaleDate, n1.LegalReference, n2.UniqueID, n2.ParcelID, n2.PropertyAddress, n2.SalePrice, n2.SaleDate, n2.LegalReference
					FROM nashville n1
					JOIN nashville n2 
						ON n1.ParcelID = n2.ParcelID 
					WHERE n1.UniqueID < n2.UniqueID);

-- THIS IS ALSO THE GOOD ONE, BUT DUE TO THE MYSQL'S LIMITATION, 
-- MySQL doesn't allow using the target table in the subquery for the DELETE statement.
DELETE
FROM sql_porfolio.nashville
WHERE UniqueID NOT IN (
    SELECT MIN(UniqueID)
    FROM sql_porfolio.nashville
    GROUP BY ParcelID -- PropertyAddress, SalePrice, SaleDate, LegalReference
);

-- SHOW ALL ROWS WITH VALUES NOT DUPLICATED
SELECT *
FROM sql_porfolio.nashville
WHERE UniqueID IN (
    SELECT MIN(UniqueID)
    FROM sql_porfolio.nashville
    GROUP BY ParcelID, SalePrice, SaleDate, LegalReference);

-- -- SHOW ALL ROWS WITH VALUES DUPLICATED
SELECT * 
FROM sql_porfolio.nashville
WHERE UniqueID NOT IN (
    SELECT MIN(UniqueID)
    FROM sql_porfolio.nashville
    GROUP BY ParcelID, SalePrice, SaleDate, LegalReference);
	
-- INDICATE ONE OF VALUES FROM DUPLICATION (The value with smallest UniqueID)
SELECT t1.UniqueID, t1.ParcelID, t1.PropertyAddress, t1.SalePrice, t1.SaleDate, t1.LegalReference
FROM nashville AS t1, nashville AS t2
WHERE t1.ParcelID = t2.ParcelID
	AND t1.PropertyAddress = t2.PropertyAddress
	AND t1.SalePrice = t2.SalePrice
	AND t1.SaleDate = t2.SaleDate
	AND t1.LegalReference = t2.LegalReference
    AND t1.UniqueID < t2.UniqueID;

Select *
From nashville
Where ParcelID = "081 07 0 265.00";

-- Create Unique value and separate it in view

CREATE OR REPLACE VIEW Single_Row AS

SELECT UniqueID, ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
FROM sql_porfolio.nashville
WHERE UniqueID IN (
    SELECT MIN(UniqueID)
    FROM sql_porfolio.nashville
    GROUP BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
)
UNION
SELECT t1.UniqueID, t1.ParcelID, t1.PropertyAddress, t1.SalePrice, t1.SaleDate, t1.LegalReference
FROM nashville AS t1, nashville AS t2
WHERE t1.ParcelID = t2.ParcelID
	AND t1.PropertyAddress = t2.PropertyAddress
	AND t1.SalePrice = t2.SalePrice
	AND t1.SaleDate = t2.SaleDate
	AND t1.LegalReference = t2.LegalReference
    AND t1.UniqueID < t2.UniqueID;
    
-- The another way from ChatGPT
DELETE FROM sql_porfolio.nashville
WHERE UniqueID IN (
    SELECT n1.UniqueID
    FROM sql_porfolio.nashville n1
    JOIN sql_porfolio.nashville n2 ON n1.ParcelID = n2.ParcelID
        AND n1.PropertyAddress = n2.PropertyAddress
        AND n1.SalePrice = n2.SalePrice
        AND n1.SaleDate = n2.SaleDate
        AND n1.LegalReference = n2.LegalReference
        AND n1.UniqueID < n2.UniqueID
);
-- it seems like MySQL's restriction on using the target table in the subquery for deletion is persisting in this case.
CREATE TEMPORARY TABLE TempToDelete AS
SELECT n1.UniqueID
FROM sql_porfolio.nashville n1
JOIN sql_porfolio.nashville n2 ON n1.ParcelID = n2.ParcelID
    AND n1.PropertyAddress = n2.PropertyAddress
    AND n1.SalePrice = n2.SalePrice
    AND n1.SaleDate = n2.SaleDate
    AND n1.LegalReference = n2.LegalReference
    AND n1.UniqueID < n2.UniqueID;

DELETE FROM sql_porfolio.nashville
WHERE UniqueID IN (SELECT UniqueID FROM TempToDelete);

DROP TEMPORARY TABLE IF EXISTS TempToDelete;
