USE rvportfolio;


-- Look at the raw data
SELECT * FROM prices_comparison;


-- Create table for the processed data be used
DROP TABLE prices_compare_final;
CREATE TABLE IF NOT EXISTS prices_compare_final AS (SELECT idx, Sku, Style_Id, REPLACE(UPPER(Sku),UPPER(CONCAT(Style_Id,"_")),"") AS Size, Category, Ajio_MRP, Amazon_MRP, Flipkart_MRP, Myntra_MRP FROM prices_comparison);

SELECT * FROM prices_compare_final;

-- Remove discrepancies from the prices_compare_final
UPDATE prices_compare_final SET Sku = REPLACE(Sku,"LL","L"), Size = REPLACE(Size,"LL","L") WHERE Sku LIKE '%2xll%';
UPDATE prices_compare_final SET Sku = REPLACE(Sku,"MM","M"), Size = REPLACE(Size,"MM","M") WHERE Sku LIKE '%MM%';

SELECT * FROM prices_compare_final WHERE Size LIKE "%Os163_2XL%";

-- Create View comparing prices across sites for different category and sizes in the month of March '21 
CREATE OR REPLACE VIEW ComparePricebyCategoryxSize AS SELECT CONCAT(Category,"_",Size) AS Category_Size, Category, Size, ROUND(AVG(Ajio_MRP),0) AS Ajio, ROUND(AVG(Amazon_MRP),0) AS Amazon, ROUND(AVG(Flipkart_MRP),0) AS Flipkart, ROUND(AVG(Myntra_MRP),0) AS Myntra FROM prices_compare_final GROUP BY Category, Size ORDER BY Category, Size;

SELECT * FROM ComparePricebyCategoryxSize;

-- Number of styles available in each category
SELECT Category, COUNT(Style_Id) As Styles FROM (SELECT DISTINCT Style_ID, Category FROM prices_compare_final) tmp GROUP BY Category;






