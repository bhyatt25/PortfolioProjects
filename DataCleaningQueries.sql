SELECT * 
FROM NashvilleHousing


-- Standardize SaleDate Format

SELECT SaleDate, CONVERT(Date,SaleDate)
FROM NashvilleHousing

UPDATE NashvilleHousing
SET SaleDate = CONVERT(Date,SaleDate)


--Populate Property Address Data (Parcels with NULL Address, we can replace NULL with PropertyAddress from previous sale using the IDENTIFYING PARCELID)

SELECT *
FROM NashvilleHousing
WHERE PropertyAddress IS NULL
ORDER BY ParcelID
--find address for each parcelID that has null address
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM NashvilleHousing a
JOIN NashvilleHousing b
    ON a.ParcelID = b.ParcelID
    AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL
 --replace null address with the property address
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM NashvilleHousing a
JOIN NashvilleHousing b
    ON a.ParcelID = b.ParcelID
    AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL


--Breaking out address into Individual Columns (Address, City, State)

SELECT PropertyAddress
FROM NashvilleHousing
--choose street address & city (this dataset delimits address from city with COMMA (no other commas in strings))
SELECT
SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1) AS 'Address',
SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1, LEN(PropertyAddress)) AS 'City'
FROM NashvilleHousing

--Create 2 new columns in table to add the address and city
ALTER TABLE NashvilleHousing
ADD PropertySplitAddress NVARCHAR(MAX)

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1)

ALTER TABLE NashvilleHousing
ADD PropertySplitCity NVARCHAR(MAX)

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1, LEN(PropertyAddress))

--Show updated columns in table (add in at END of table)
SELECT *
FROM NashvilleHousing

--Do the same as above but with Owner Address (includes State and second comma)

SELECT OwnerAddress
FROM NashvilleHousing

--Can use method above or use PARSENAME (it looks for periods though. So, must replace commas with periods first!) It also works backwards (3 -> 1).
SELECT
PARSENAME(REPLACE(OwnerAddress,',','.'),3),
PARSENAME(REPLACE(OwnerAddress,',','.'),2),
PARSENAME(REPLACE(OwnerAddress,',','.'),1)
FROM NashvilleHousing

--now update table & add columns just like above
ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress NVARCHAR(MAX)

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',','.'),3)

ALTER TABLE NashvilleHousing
ADD OwnerSplitCity NVARCHAR(MAX)

UPDATE NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',','.'),2)

ALTER TABLE NashvilleHousing
ADD OwnerSplitState NVARCHAR(MAX)

UPDATE NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',','.'),1)

--Show updated columns in table (add in at END of table)
SELECT *
FROM NashvilleHousing


--Standardize "Sold As Vacant" Field Using CASE Statement

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2
--create new placeholder column to change values
SELECT SoldAsVacant,
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
     WHEN SoldAsVacant = 'N' THEN 'No'
     ELSE SoldAsVacant
     END
FROM NashvilleHousing
--update the existing column where 'Y' and 'N' exist
UPDATE NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
     WHEN SoldAsVacant = 'N' THEN 'No'
     ELSE SoldAsVacant
     END


-- REMOVE DUPLICATES (deleting data -- not usually what you would do)

WITH RowNumCTE AS (
SELECT *,--(can use rank, row_number, etc.)
    ROW_NUMBER() OVER (
    PARTITION BY ParcelID,
                 PropertyAddress,
                 SalePrice,
                 SaleDate,
                 LegalReference
                 ORDER BY
                    UniqueID
                    ) row_num
FROM NashvilleHousing
--ORDER BY ParcelID
)

DELETE
FROM RowNumCTE
WHERE row_num > 1




-- DELETE UNUSED COLUMNS

SELECT *
FROM NashvilleHousing

ALTER TABLE NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress