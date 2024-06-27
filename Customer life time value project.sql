--DATA CLEANING 
--Check for duplicates
SELECT Customer_ID,gender,Partner,Dependents,Senior_Citizen,Call_Duration,
Data_Usage,Plan_Type,Plan_Level,
Monthly_Bill_Amount,Tenure_Months,Multiple_Lines,Tech_Support,Churn
FROM NexaSat_data
GROUP BY Customer_ID,gender,Partner,Dependents,Senior_Citizen,Call_Duration,
Data_Usage,Plan_Type,Plan_Level,
Monthly_Bill_Amount,Tenure_Months,Multiple_Lines,Tech_Support,Churn
HAVING COUNT(*) > 1;
--Check null values
SELECT *
FROM NexaSat_data
WHERE Customer_ID IS NULL
OR gender IS NULL
OR Partner IS NULL
OR Dependents IS NULL
OR Senior_Citizen IS NULL
OR Call_Duration IS NULL
OR Data_Usage IS NULL
OR Plan_Type IS NULL
OR Plan_Level IS NULL
OR Monthly_Bill_Amount IS NULL
OR Tenure_Months IS NULL
OR Multiple_Lines IS NULL
OR Tech_Support IS NULL
OR Churn IS NULL;

--EDA
--total users
SELECT COUNT(Customer_ID) AS current_users
FROM NexaSat_data
WHERE Churn = 0;

--total users by level
SELECT Plan_Level, COUNT(Customer_ID) AS total_users
FROM NexaSat_data
WHERE Churn = 0
GROUP BY Plan_Level;

--total revenue
SELECT ROUND(SUM(CAST(Monthly_Bill_Amount AS numeric)), 2) AS revenue
FROM NexaSat_data;

--revenue by plan level
SELECT 
    Plan_Level,
    ROUND(SUM(CAST(Monthly_Bill_Amount AS numeric)), 2) AS revenue
FROM 
    NexaSat_data
GROUP BY 
    Plan_Level
ORDER BY 
    revenue;
--churn count by plan type and plan level
SELECT 
    Plan_Level,
    Plan_Type,
    COUNT(*) AS total_customers,
    SUM(CAST(Churn AS numeric)) AS churn_count
FROM 
    NexaSat_data
GROUP BY 
    Plan_Level, Plan_Type
ORDER BY 
    Plan_Level;
--avg tenure by plan_level
SELECT 
     Plan_Level,
     ROUND(AVG(CAST(Tenure_Months AS numeric)),2) AS avg_tenure
FROM NexaSat_data
GROUP BY Plan_Level
-- marketing segment
--create table of existing users only
SELECT *
INTO existing_users
FROM NexaSat_data
WHERE Churn = 0;
--view new table
SELECT *
FROM existing_users;

--calculate average revenue per users
SELECT ROUND(AVG(CAST(Monthly_Bill_Amount AS numeric)), 2) AS ARPU
FROM existing_users;


--customer lifetime value (clv)
ALTER TABLE existing_users
ADD clv FLOAT;

UPDATE existing_users
SET clv = Monthly_Bill_Amount + Tenure_Months;
--view new clv column

--clv score
--monthly_bill_amount = 40%,tenure = 30%,call_duration = 10%,data_usage = 10%,premium = 10%
ALTER TABLE existing_users
ADD clv_score NUMERIC(10,2);

UPDATE existing_users
SET clv_score =
            (0.4 * Monthly_Bill_Amount)+
			(0.3 * Tenure_Months)+
			(0.1 * Call_Duration)+
			(0.1 * Data_Usage)+
			(0.1 * CASE WHEN Plan_Level = 'Premium'
			       THEN 1 ELSE 0
				   END);

UPDATE existing_users
SET clv_score = 
    (0.4 * CAST(Monthly_Bill_Amount AS FLOAT)) +
    (0.3 * CAST(Tenure_Months AS FLOAT)) +
    (0.1 * CAST(Call_Duration AS FLOAT)) +
    (0.1 * CAST(Data_Usage AS FLOAT)) +
    (0.1 * CASE 
            WHEN Plan_Level = 'Premium' THEN 1 
            ELSE 0 
           END);
--view new clv score column
SELECT Customer_ID,clv_score
FROM existing_users;

--group users into segments based on clv scores
ALTER TABLE existing_users
ADD clv_segments VARCHAR(255);



-- Calculate percentiles and store in variables
--from here run the whole code
DECLARE @P85 FLOAT, @P50 FLOAT, @P25 FLOAT;

SELECT 
    @P85 = PERCENTILE_CONT(0.85) WITHIN GROUP (ORDER BY clv_score) OVER (),
    @P50 = PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY clv_score) OVER (),
    @P25 = PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY clv_score) OVER ()
FROM existing_users;

-- Update clv_segments based on the calculated percentiles
UPDATE existing_users
SET clv_segments = 
    CASE 
        WHEN clv_score > @P85 THEN 'High Value'
        WHEN clv_score >= @P50 THEN 'Moderate Value'
        WHEN clv_score >= @P25 THEN 'Low Value'
        ELSE 'Churn Risk'
    END;
-- View segments
SELECT Customer_ID, clv, clv_score, clv_segments
FROM existing_users;


--ANALYZING THE SEGMENTS
--avg bill and tenure per segment
SELECT clv_segments,
      ROUND(AVG(CAST(Monthly_Bill_Amount AS numeric)), 2) AS avg_monthly_charges,
	  ROUND(AVG(CAST(Tenure_Months AS numeric)), 2) AS avg_tenure
FROM existing_users
GROUP BY clv_segments;

 --tech support and multiple lines count
 SELECT 
    SUM(CASE WHEN TRIM(UPPER(Tech_Support)) = 'YES' THEN 1 ELSE 0 END) AS tech_support_yes_count,
    SUM(CASE WHEN TRIM(UPPER(Multiple_Lines)) = 'YES' THEN 1 ELSE 0 END) AS multiple_lines_yes_count
FROM existing_users;
--revenue per segment
SELECT clv_segments,
       COUNT(Customer_ID) AS customer_count,
       CAST(SUM(CAST(Monthly_Bill_Amount AS numeric(10,2)) + CAST(Tenure_Months AS numeric(10,2))) AS numeric(10,2)) AS total_revenue
FROM existing_users
GROUP BY clv_segments;

--up-selling and cross-selling
--cross-selling tech support to snr citizens(115 customers)
SELECT Customer_ID
FROM existing_users
WHERE Senior_Citizen = 1
AND Dependents = 'No'
AND Tech_Support = 'No'
AND (clv_segments = 'Churn Risk' OR clv_segments = 'Low Value');

--cross-selling multiple lines for patners and dependants(376 customers)
SELECT Customer_ID
FROM existing_users
WHERE Multiple_Lines = 'No'
AND (Dependents = 'Yes' OR Partner = 'Yes')
AND Plan_Level = 'Basic';

-- up-selling: premium discount for basic users with churn risk(753 users)
SELECT Customer_ID
FROM existing_users
WHERE clv_segments = 'Churn Risk'
AND Plan_Level = 'Basic';

-- up-selling:basic to premium for longer lock in period and higher ARPU
SELECT Plan_Level, ROUND(AVG(CAST(Monthly_Bill_Amount AS numeric)),2) AS avg_bill, ROUND(AVG(CAST(Tenure_Months AS numeric)), 2) AS avg_tenure
FROM existing_users
WHERE clv_segments = 'High Value'
OR clv_segments = 'Moderate Value'
GROUP BY Plan_Level;

--select customers(185 users)
SELECT Customer_ID,Monthly_Bill_Amount
FROM existing_users
WHERE Plan_Level = 'Basic'
AND (clv_segments = 'High Value' OR clv_segments = 'Moderate Value')
AND Monthly_Bill_Amount > 150

--CREATE STORED PROCEDURES
--snr citizens who will be offered tech support
CREATE FUNCTION Tech_Support_Snr_Citizens()
RETURNS @Result TABLE (
    Customer_ID VARCHAR(50)
)
AS
BEGIN
    INSERT INTO @Result (Customer_ID)
    SELECT Customer_ID
    FROM existing_users
    WHERE Senior_Citizen = 1
      AND Dependents = 'No'
      AND Tech_Support = 'No'
      AND (clv_segments = 'Churn Risk' OR clv_segments = 'Low Value');
    
    RETURN;
END;

--at risk customers who will be offered premium discount
CREATE FUNCTION Churn_Risk_Discount()
RETURNS @Result TABLE (Customer_ID VARCHAR(50))
AS 
BEGIN
     INSERT INTO @Result (Customer_ID)
	 SELECT Customer_ID
	 FROM existing_users
	 WHERE clv_segments = 'Churn Risk'
	 AND Plan_Level = 'Basic';
  RETURN;
END;

--high usage customers who will be offered premium upgrade
CREATE FUNCTION high_usage_basic()
RETURNS @Result TABLE (Customer_ID VARCHAR(50))
AS
BEGIN
     INSERT INTO @Result (Customer_ID)
	 SELECT Customer_ID
	 FROM existing_users
	 WHERE Plan_Level = 'Basic'
	 AND (clv_segments = 'High Value' OR clv_segments = 'Moderate Value')
	 AND Monthly_Bill_Amount > 150 
	 RETURN;
END;

--multiple lines for patners and dependants
CREATE FUNCTION multiple_lines()
RETURNS @Result TABLE (Customer_ID VARCHAR(50))
AS
BEGIN
     INSERT INTO @Result (Customer_ID)
	 SELECT Customer_ID
	 FROM existing_users
	 WHERE Multiple_Lines = 'No'
	 AND (Dependents = 'Yes' OR Partner = 'Yes')
	 AND Plan_Level = 'Basic';
	 RETURN;
END;	 


--USE PROCEDURES
--churn risk discount
SELECT *
FROM Churn_Risk_Discount();

--high usage basic
SELECT *
FROM high_usage_basic();

--multiple lines for patners and dependants
SELECT *
FROM multiple_lines();

























 























































































































