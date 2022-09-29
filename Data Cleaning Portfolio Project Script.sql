SELECT *
FROM DataCleaningPortfolioProject..NashvilleHousing

---------------------------------------------------------------------------------------------

-- **Standardize Date Format**

SELECT SaleDateConverted, CONVERT(Date,SaleDate)
FROM DataCleaningPortfolioProject..NashvilleHousing

ALTER TABLE NashvilleHousing
ADD SaleDateConverted Date;

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(Date,SaleDate)


---------------------------------------------------------------------------------------------

-- **Populate Property Address Data**

-- Looking to see where property address is null

SELECT *
FROM DataCleaningPortfolioProject..NashvilleHousing
WHERE PropertyAddress is null
ORDER BY ParcelID


-- Using ParcelID as a unique ID, I join the table with itself to find where rows have the same ParcelID but where one has an address and another is null.
-- Therefore I can populate the null address with the previous address from the row with the same ParcelID since they are the same household.

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM DataCleaningPortfolioProject..NashvilleHousing a
JOIN DataCleaningPortfolioProject..NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress is null


-- I then update the PropertyAddress column with the correct address

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM DataCleaningPortfolioProject..NashvilleHousing a
JOIN DataCleaningPortfolioProject..NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress is null


---------------------------------------------------------------------------------------------

-- **Breaking out Address into individual columns (Address, City)**

SELECT PropertyAddress
FROM DataCleaningPortfolioProject..NashvilleHousing


-- Using ',' as a delimiter to split the property address into street and city

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', propertyaddress) -1) AS Address
, SUBSTRING(PropertyAddress, CHARINDEX(',', propertyaddress) +1, LEN(propertyaddress)) AS Address
FROM DataCleaningPortfolioProject..NashvilleHousing


-- Adding the new columns to the NashvilleHousing Table

ALTER TABLE NashvilleHousing
ADD PropertySplitAddress nvarchar(255);

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', propertyaddress) -1)

ALTER TABLE NashvilleHousing
ADD PropertySplitCity nvarchar(255);

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', propertyaddress) +1, LEN(propertyaddress))



SELECT *
FROM DataCleaningPortfolioProject..NashvilleHousing


---------------------------------------------------------------------------------------------

-- **Breaking out Address into individual columns (Address, City, State)**

SELECT OwnerAddress
FROM DataCleaningPortfolioProject..NashvilleHousing



-- Using PARSENAME to search for the delimeter ',' and seperate substrings into individual columns

SELECT
PARSENAME(REPLACE(OwnerAddress, ',', '.') ,3)
, PARSENAME(REPLACE(OwnerAddress, ',', '.') ,2)
, PARSENAME(REPLACE(OwnerAddress, ',', '.') ,1)
FROM DataCleaningPortfolioProject..NashvilleHousing


-- Creating new columns and adding the new broken up substring data

ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.') ,3)

ALTER TABLE NashvilleHousing
ADD OwnerSplitCity nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.') ,2)

ALTER TABLE NashvilleHousing
ADD OwnerSplitState nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.') ,1)



SELECT *
FROM DataCleaningPortfolioProject..NashvilleHousing


---------------------------------------------------------------------------------------------

-- **Changing Y and N to Yes and No in "Sold as Vacant" field**

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM DataCleaningPortfolioProject..NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

SELECT SoldAsVacant
, CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	   WHEN SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END
FROM DataCleaningPortfolioProject..NashvilleHousing

UPDATE NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	   WHEN SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END


---------------------------------------------------------------------------------------------

-- **Remove Duplicates**

-- Creating A CTE that shows duplicate rows when rows share the same ParcelID, PropertyAddress, etc. on a new "row_num" field
-- Then deleting the rows in which 'row_num' is >1, meaning they are a duplicate
WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num

FROM DataCleaningPortfolioProject..NashvilleHousing
)
DELETE
FROM RowNumCTE
WHERE row_num > 1


---------------------------------------------------------------------------------------------

-- **Delete unused columns**

SELECT *
FROM DataCleaningPortfolioProject..NashvilleHousing

ALTER TABLE DataCleaningPortfolioProject..NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress

ALTER TABLE DataCleaningPortfolioProject..NashvilleHousing
DROP COLUMN SaleDate
