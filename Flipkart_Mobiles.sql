-- Creating a Database
CREATE DATABASE Billeasy;

-- Selecting Database
USE Billeasy;

-- Importing Dataset
SELECT * FROM Flipkart_Mobiles;

-------------------------------------------- DATA EXPLORATION AND CLEANING -------------------------------------------
--1. Brand wise total number of mobiles.
SELECT Brand, COUNT(*) AS 'Total_Mobiles' FROM Flipkart_Mobiles
GROUP BY Brand
ORDER BY Total_Mobiles DESC;
-->> Top 5: 1. Samsung - 719, 2. Apple - 387, 3. Realme - 327, 4. Oppo - 260, 5. Nokia - 213


--2. Finding maximum and minimum price of each brand
SELECT Brand, MAX(Selling_Price) AS 'Max_Price', MIN(Selling_Price) AS 'Min_Price' FROM Flipkart_Mobiles
GROUP BY Brand
ORDER BY Max_Price DESC;

--3. Creating a new column - Discount to check the percentage of discounts given on each mobile
ALTER TABLE Flipkart_Mobiles
ADD Discount INT;

UPDATE Flipkart_Mobiles
SET Discount = ROUND(((Original_Price - Selling_Price) * 100.0) / Original_Price,0);


SELECT Brand, Model, Selling_Price, Memory, Storage, ROUND(Rating,2) AS 'Rating', Discount FROM Flipkart_Mobiles
WHERE Discount > 50
ORDER BY Discount DESC;

----------------------------------------**** CREATING FUNCTION FOR PRICE BUCKET ****-------------------------------------------------
CREATE FUNCTION Price_Bucket (@SP INT)
RETURNS VARCHAR(25)
AS
BEGIN
	DECLARE @Price_Bucket VARCHAR(20)

	SET @Price_Bucket = CASE WHEN @SP < 20000 THEN 'Low'
							 WHEN @SP BETWEEN 20000 AND 50000 THEN 'Mid'
							 ELSE 'Premium'
						END
	RETURN @Price_Bucket
END;
-------------------------------------------------------------------------
--5. Count of mobiles based on different price range.
---------------------------***** Question 1: What are the different price range segments for mobiles in India? *****-----------------------------
-- Under 20,000 (Low), 20,000 to 50,000 (Mid), Above 50,000 (Premium)
WITH Price_Count AS(
    SELECT CASE WHEN Selling_Price < 20000 THEN 'Low'
				WHEN Selling_Price BETWEEN 20000 AND 50000 THEN 'Mid'
				ELSE 'Premium'
		   END AS 'Price_Range', COUNT(*) AS 'Total_Mobiles'
    FROM Flipkart_Mobiles
    GROUP BY CASE WHEN Selling_Price < 20000 THEN 'Low'
				  WHEN Selling_Price BETWEEN 20000 AND 50000 THEN 'Mid'
				  ELSE 'Premium'
			 END)
SELECT Price_Range, Total_Mobiles, ROUND(Total_Mobiles * 100 / SUM(Total_Mobiles) OVER(), 1) AS 'Percentage_Share'
FROM Price_Count
ORDER BY Price_Range;
-->> Low Range (< 20,000):
-- 67% of phones are in this range. Most people in India prefer budget-friendly options.

-->> Mid Range (20,000 - 50,000):
-- 20% of phones fall here. This range balances features and price.

-->> Premium (> 50,000):
-- 13% of phones are premium. Fewer options, but demand is slowly growing.

-------------------------***** Question 2: Which brand provides the most product offerings for the Indian Market? *****--------------------------
SELECT 
    Brand, 
    COUNT(*) AS Total_Models
FROM Flipkart_Mobiles
GROUP BY Brand
ORDER BY Total_Models DESC;

--1. Brand-wise variety in Memory + Storage combinations
SELECT Brand, COUNT(DISTINCT CONCAT(Memory, '-', Storage)) AS 'Memory_Storage_Combo' FROM Flipkart_Mobiles
GROUP BY Brand
ORDER BY Memory_Storage_Combo DESC;

--2. Brand-wise Average Discount Offered
SELECT Brand, ROUND(AVG(Discount),1) AS 'Avg_Discount' FROM Flipkart_Mobiles
GROUP BY Brand
ORDER BY Avg_Discount DESC;

--3. Brand-wise Average Rating (Customer Satisfaction)
SELECT Brand, ROUND(AVG(Rating),1) AS 'Avg_Rating' FROM Flipkart_Mobiles
GROUP BY Brand
ORDER BY Avg_Rating DESC;

--4. Brand-wise Average Selling Price
SELECT Brand, ROUND(AVG(Selling_Price),0) AS 'Avg_Selling_Price' FROM Flipkart_Mobiles
GROUP BY Brand
ORDER BY Avg_Selling_Price DESC;

--5. How many models each brand offers across all price ranges (Low/Mid/Premium)
SELECT Brand, DBO.Price_Bucket(Selling_Price) AS 'Price_Range',  COUNT(*) AS 'Total_Mobiles'
FROM Flipkart_Mobiles
GROUP BY Brand, DBO.Price_Bucket(Selling_Price)
ORDER BY  Brand, Price_Range

-->> Brands with offerings in all 3 segments (Low, Mid, Premium):
-- Samsung, Apple, ASUS, Google Pixel, HTC, LG, Motorola, Nokia, OPPO, LG, vivo - show wide coverage across all price ranges.

-->> Samsung leads the market with the highest variety:
-- 751 low-range, 282 mid-range, and 124 premium phones.

-->> Apple focuses on premium:
-- 400 premium models. Zero low-range phones - targets high-end buyers.

-->> realme and Nokia dominate low-range:
-- realme (343), Nokia (337) - ideal for budget buyers.

-->> Brands with limited or no premium segment phones:
-- realme, POCO, IQOO, Lenovo, Infinix - mostly under 20,000, for value-conscious users.


--6. Which brands offer the widest price spread between their cheapest and costliest phones?
SELECT Brand, MIN(Selling_Price) AS 'Min_Price', MAX(Selling_Price) AS 'Max_Price', MAX(Selling_Price) - MIN(Selling_Price) AS 'Price_Spread'
FROM Flipkart_Mobiles
GROUP BY Brand
ORDER BY Price_Spread DESC;
-->> Samsung has the biggest price range, offering mobiles from 1,099 to 1.7 lakh - covering all segments.
-->> Apple focuses only on mid to premium phones, starting from 24,999 up to 1.8 lakh.
-->> Brands like Motorola, ASUS, vivo offer mobiles across a wide range, giving more choices to different types of buyers.


--7. Top 10 most diverse models (unique combinations of Memory, Storage, Color) offered by brand
SELECT TOP 10 Brand, COUNT(DISTINCT CONCAT(Model, '-', Memory, '-', Storage, '-', Color)) AS 'Unique_Model_Variants'
FROM Flipkart_Mobiles
GROUP BY Brand
ORDER BY Unique_Model_Variants DESC;

-->> Samsung offers the highest variety with 712 unique mobile combinations - showing its wide range in the Indian market.
-->> realme and Apple also provide high variety, with 319 combinations each - appealing to different customer need
-->> Other brands like OPPO, Nokia, and Xiaomi offer a good mix of models, giving buyers plenty of choices.

--8.  Which brands have the highest number of high-rated (>=4.5) phones?
SELECT Brand, COUNT(*) AS 'High_Rated_LowPrice'
FROM Flipkart_Mobiles
WHERE Rating >= 4.5
GROUP BY Brand
ORDER BY High_Rated_LowPrice DESC;

-->> Apple dominates with 380 high-rated phones (4.5+), showing strong customer approval in the premium segment.
-->> realme and Samsung also perform well, offering many well-rated models across price ranges.


--9. Over all High-rated (>=4.5) phones in the low-price range segment
SELECT Brand, COUNT(*) AS 'High_Rated_LowPrice'
FROM Flipkart_Mobiles
WHERE Selling_Price < 20000 AND Rating >= 4.5
GROUP BY Brand
ORDER BY High_Rated_LowPrice DESC;

-->> realme leads with 77 high-rated budget phones, showing strong customer satisfaction at low prices.
-->> Xiaomi follows with 35 such models, also proving popular in the affordable, high-quality segment.



----------------------------------***** Question 2: Which brand caters to all different segments? *****------------------------------

SELECT Brand, COUNT(DISTINCT DBO.Price_Bucket(Selling_Price)) AS 'Price_Range'
FROM Flipkart_Mobiles
GROUP BY Brand
HAVING COUNT(DISTINCT DBO.Price_Bucket(Selling_Price)) = 3;

-- Brands with broad Memory + Storage range
SELECT Brand, MIN(Memory) AS Min_Memory, MAX(Memory) AS Max_Memory, MIN(Storage) AS Min_Storage, MAX(Storage) AS Max_Storage
FROM Flipkart_Mobiles
WHERE Brand IN (
    'ASUS', 'Google Pixel', 'HTC', 'LG', 'Motorola', 
    'Nokia', 'OPPO', 'SAMSUNG', 'vivo', 'Xiaomi')
GROUP BY Brand
ORDER BY Brand;

-->> ASUS, HTC, LG, and Motorola offer both low and high memory options (1 GB to 8 GB).
-->> Google Pixel and OPPO have mid-range memory (2–6 GB) but good storage up to 128 GB.
-->> Some storage values look swapped (e.g., 128 GB as Min, 8 GB as Max), meaning storage data might need fixing.


----------------------------***** What specifications are the most common that are offered by various brands? *****---------------------------

SELECT 
  (SELECT TOP 1 Memory 
   FROM Flipkart_Mobiles 
   GROUP BY Memory 
   ORDER BY COUNT(*) DESC) AS Most_Common_Memory,

  (SELECT TOP 1 Storage 
   FROM Flipkart_Mobiles 
   GROUP BY Storage 
   ORDER BY COUNT(*) DESC) AS Most_Common_Storage,

  (SELECT TOP 1 Color 
   FROM Flipkart_Mobiles 
   GROUP BY Color 
   ORDER BY COUNT(*) DESC) AS Most_Common_Color,

  (SELECT TOP 1 
       CASE 
         WHEN Rating >= 4.5 THEN 'Excellent'
         WHEN Rating >= 4.0 THEN 'Good'
         WHEN Rating >= 3.0 THEN 'Average'
         ELSE 'Low'
       END
   FROM Flipkart_Mobiles 
   GROUP BY 
       CASE 
         WHEN Rating >= 4.5 THEN 'Excellent'
         WHEN Rating >= 4.0 THEN 'Good'
         WHEN Rating >= 3.0 THEN 'Average'
         ELSE 'Low'
       END
   ORDER BY COUNT(*) DESC) AS Most_Common_Rating_Category,

  (SELECT TOP 1 
       CASE 
         WHEN Selling_Price < 20000 THEN 'Low'
         WHEN Selling_Price BETWEEN 20000 AND 50000 THEN 'Mid'
         ELSE 'Premium'
       END
   FROM Flipkart_Mobiles 
   GROUP BY 
       CASE 
         WHEN Selling_Price < 20000 THEN 'Low' 
         WHEN Selling_Price BETWEEN 20000 AND 50000 THEN 'Mid'
         ELSE 'Premium'
       END
   ORDER BY COUNT(*) DESC) AS Most_Common_Price_Range

-->> Most common Memory: 4 GB
-->> Most common Storage: 64 GB
-->> Most common Color: Black
-->> Most common Rating Category: Good (Rating between 4.0 and 4.49)
-->> Most common Price Segment: Low (Under 20,000)


----------------------------------------------***** FLIPKART MOBILE SUMMAARY ****------------------------------------------------

--> Most common segment: Low-price (< 2K) - 67% of all phones
--> Top brand by variety: Samsung (719 models, widest price spread 1K - 1.7L)
--> Premium-focused: Apple (no budget phones, 380 high-rated)
--> Budget leaders: realme, Nokia (most models under 20K)
--> Most common specs:
-- Memory – 4 GB
-- Storage – 64 GB
-- Color – Black
--> High-rated budget phones: realme (77), Xiaomi (35)
--> Brands covering all price segments: Samsung, Xiaomi, OPPO, vivo, Motorola, etc.
--> Highest product diversity: Samsung (712 unique model variants)