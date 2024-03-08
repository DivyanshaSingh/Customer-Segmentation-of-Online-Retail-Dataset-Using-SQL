create database project;
use project;
SELECT *
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE';
select*from dbo.OnlineRetail;

---------------------------------------------------------------------

-- Step 1: Calculate RFM Metrics

SELECT customerid,DATEDIFF(day,max(invoicedate),
GETDATE()) AS Recency,
COUNT(Distinct invoiceno) AS Frequency,
SUM(unitprice*quantity) AS Monetary
into RFM_temp
from dbo.onlineretail
Group by customerid
order by Monetary desc
;


select*from RFM_temp;

-------------------------------------------------------------------
-- Step 2: Assign RFM Scores

SELECT 
    customerid,
    CASE 
        WHEN Recency <= 30 THEN 5
        WHEN Recency <= 60 THEN 4
        WHEN Recency <= 90 THEN 3
        WHEN Recency <= 180 THEN 2
        ELSE 1
    END AS R_Score,
    CASE 
        WHEN Frequency >= 20 THEN 5
        WHEN Frequency >= 15 THEN 4
        WHEN Frequency >= 10 THEN 3
        WHEN Frequency >= 5 THEN 2
        ELSE 1
    END AS F_Score,
    CASE 
        WHEN Monetary >= 1000 THEN 5
        WHEN Monetary >= 500 THEN 4
        WHEN Monetary >= 250 THEN 3
        WHEN Monetary >= 100 THEN 2
        ELSE 1
    END AS M_Score
INTO RFM_Scores
FROM RFM_Temp;


select*from RFM_Scores;

-- Step 3: Combine RFM Scores

SELECT 
    customerid, 
    R_Score,F_Score,M_Score,
    SUM(R_Score + F_Score + M_Score) AS RFM_Sum
FROM RFM_Scores 
GROUP BY customerid , R_Score, F_Score, M_Score
order by RFM_Sum desc;


----------------------------------------------------------------------------------

-- Step 4: RFM Segmentation

SELECT 
    customerid,
    CASE 
        WHEN RFM_Sum >= 10 THEN 'High Value'
        WHEN RFM_Sum >= 6 THEN 'Mid Value'
        ELSE 'Low Value'
    END AS RFM_Segment
FROM (
    SELECT 
        customerid,
        SUM(R_Score + F_Score + M_Score) AS RFM_Sum
    FROM RFM_Scores
    GROUP BY customerid
) AS RFM_Final;

-- Step 5: Insights

SELECT 
    RFM_Segment,
    COUNT(*) AS Customer_Count,
    AVG(R_Score) AS Avg_Recency,
    AVG(F_Score) AS Avg_Frequency,
    AVG(M_Score) AS Avg_Monetary
FROM RFM_Scores rs
JOIN (
    SELECT 
        customerid,
        CASE 
            WHEN RFM_Sum >= 10 THEN 'High Value'
            WHEN RFM_Sum >= 6 THEN 'Mid Value'
            ELSE 'Low Value'
        END AS RFM_Segment
    FROM (
        SELECT 
            customerid,
            SUM(R_Score + F_Score + M_Score) AS RFM_Sum
        FROM RFM_Scores
        GROUP BY customerid
    ) AS RFM_Final
) AS RFM_Segments ON rs.customerid = RFM_Segments.customerid
GROUP BY RFM_Segment;



