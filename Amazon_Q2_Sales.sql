
USE rvportfolio;
SELECT * FROM rvportfolio.amazon_salesq2;
SELECT * FROM rvportfolio.amazon_salesq2 WHERE Status IN ('Shipped - Returned to Seller','Shipped - Returning to Seller','Shipped - Rejected by Buyer','Shipped - Lost in Transit');

-- Data Cleaning

-- Date gettting incorrectly uploaded directly, so imported it in text format first then converted to date format
UPDATE amazon_salesq2 SET Ordering_Date = STR_TO_DATE(Order_Date, "%d-%m-%y");
ALTER TABLE amazon_salesq2 DROP COLUMN Order_Date;


-- Data Exploration

SELECT DISTINCT Status FROM amazon_salesq2;

-- Total Orders, Cancellled/Rejected Orders, Delivered Orders, Amount MTD

SELECT a.idx, a.Ordering_Date, date_format(a.Ordering_Date, "%M %y") AS Order_Month, a.Status, b.Total_Orders, b.Delivered_Orders,
b.Failed_Orders, b.NonCancel_Amount AS NonCancel_Amount_$ FROM amazon_salesq2 a 
JOIN (SELECT idx, SUM(1) OVER(ORDER BY Ordering_Date) AS Total_Orders, SUM(CASE WHEN Status = "Shipped - Delivered to Buyer" THEN 1 ELSE 0 END) OVER (ORDER BY Ordering_Date) AS Delivered_Orders, 
SUM(CASE WHEN Status IN ('Cancelled', 'Shipped - Returned to Seller','Shipped - Returning to Seller','Shipped - Rejected by Buyer','Shipped - Lost in Transit') THEN 1 ELSE 0 END) 
OVER (ORDER BY Ordering_Date) AS Failed_Orders, SUM(Amount) OVER(ORDER BY Ordering_Date) AS NonCancel_Amount FROM amazon_salesq2) b ON a.idx = b.idx;

-- Create View 

CREATE OR REPLACE VIEW MTD_View AS SELECT Order_Month, MAX(Total_Orders) AS Total_Orders, MAX(Delivered_Orders) AS Delivered_Orders, 
MAX(Failed_Orders) AS Failed_Orders, MAX(Total_Orders) - MAX(Delivered_Orders) - MAX(Failed_Orders) AS OrdersInProcess, MAX(NonCancel_Amount_$) AS NonCancel_Amount_$ FROM (SELECT a.idx, a.Ordering_Date, date_format(a.Ordering_Date, "%M %y") AS Order_Month, 
a.Status, b.Total_Orders, b.Delivered_Orders, b.Failed_Orders, b.NonCancel_Amount AS NonCancel_Amount_$ FROM amazon_salesq2 a 
JOIN (SELECT idx, SUM(1) OVER(ORDER BY Ordering_Date) AS Total_Orders, SUM(CASE WHEN Status = "Shipped - Delivered to Buyer" THEN 1 ELSE 0 END) OVER (ORDER BY Ordering_Date) AS Delivered_Orders, 
SUM(CASE WHEN Status IN ('Cancelled', 'Shipped - Returned to Seller','Shipped - Returning to Seller','Shipped - Rejected by Buyer','Shipped - Lost in Transit') THEN 1 ELSE 0 END) 
OVER (ORDER BY Ordering_Date) AS Failed_Orders, SUM(Amount) OVER(ORDER BY Ordering_Date) AS NonCancel_Amount FROM amazon_salesq2) b ON a.idx = b.idx) tmp GROUP BY tmp.Order_Month; 



-- Distribution of orders placed a/c to categories and states


CREATE OR REPLACE VIEW Category_State_Distribution AS (SELECT amazon_salesq2.Ship_State, Category, COUNT(idx) AS Orders_Placed, MAX(Total) AS Total_Orders, ROUND((COUNT(idx)/MAX(Total)) * 100,2) 
AS Fraction_Percent FROM amazon_salesq2 JOIN (SELECT Ship_State, SUM(1) AS Total FROM amazon_salesq2 GROUP BY Ship_State) s ON s.Ship_State = amazon_salesq2.Ship_State 
GROUP BY amazon_salesq2.Ship_State, Category ORDER BY amazon_salesq2.Ship_State, Fraction_Percent DESC);

SELECT * FROM Category_State_Distribution;


