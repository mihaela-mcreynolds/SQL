set echo on;
set pagesize 90;
set linesize 80;
column id heading 'ID' format 9999
column full_name heading 'Full Name' format a25 word_wrapped
column full_address heading 'Full Address' format a24 word_wrapped
column productname heading 'Product Name' format a28 word_wrapped
column description heading 'Description' format a22 word_wrapped
column cost heading 'Cost' format $990.00
column priority heading 'Selling Priority' format a24 word_wrapped
-- Mihaela McReynolds
-- CITC 2340 Lab 5

--1.    Display the full name (ex. Tom R. Brown) of each aviation customer who has chartered a plane from us.
SELECT TRIM(REGEXP_REPLACE((cus_fname || ' ' || cus_initial || '. ' || cus_lname ), '\s.\s', ' ')) AS full_name
    FROM avia_customer
    WHERE avia_customer.cus_code IN 
        (SELECT charter.cus_code FROM charter 
        INTERSECT 
        SELECT avia_customer.cus_code FROM avia_customer)
    ORDER BY cus_fname, cus_initial, cus_lname; 
    
--2.    Display the full name and customer balance of all aviation customers who have chartered planes 
--to Atlanta (ATL).
SELECT TRIM(REGEXP_REPLACE((cus_fname || ' ' || cus_initial || '. ' || cus_lname ), '\s.\s', ' ')) AS full_name, 
       cus_balance AS "Customer Balance"
    FROM avia_customer
    WHERE avia_customer.cus_code IN
        (SELECT charter.cus_code FROM charter WHERE char_destination = 'ATL');

--3.    Display the full names (ex. Mr. Tom R Davis) and hire dates (ex. March 21, 2000) of all aviation employees 
--who have earned ratings that have also been earned by employee 106.
SELECT TRIM(REGEXP_REPLACE((emp_title || emp_fname || ' ' || emp_initial || '. ' || emp_lname ), '\s.\s', ' ')) AS full_name,
        TO_CHAR(TO_DATE(emp_hire_date, 'DD-MON-RR'), 'fmMonth DD, YYYY') as "Date Hired"
    FROM avia_employee
    WHERE emp_num IN 
        (SELECT emp_num FROM earnedrating WHERE rtg_code IN 
            (SELECT rtg_code FROM earnedrating WHERE emp_num = 106))
    AND emp_num <> 106
    ORDER BY emp_fname, emp_initial, emp_lname;

--4.  Display the full name and date of birth (using 4-digit years) of each aviation employee 
--who is younger than John Lange.
SELECT TRIM(REGEXP_REPLACE((emp_fname || ' ' || emp_initial || '. ' || emp_lname ), '\s.\s', ' ')) AS full_name,
        TO_CHAR(TO_DATE(emp_dob, 'DD-MON-RR'), 'fmMonth DD, YYYY') AS "Date Of Birth"
    FROM avia_employee
    WHERE TRUNC ((SYSDATE - emp_dob)/ 365.25) <
        (SELECT TRUNC ((SYSDATE - emp_dob)/ 365.25) 
            FROM avia_employee 
            WHERE LOWER(emp_fname) = 'john' 
            AND LOWER(emp_lname) = 'lange')
    ORDER BY emp_fname, emp_initial, emp_lname;

--5.    Display the full name and phone number of each aviation customer who has chartered 
--as many or more planes than aviation customer#10011.

SELECT TRIM(REGEXP_REPLACE((cus_fname || ' ' || cus_initial || '. ' || cus_lname ), '\s.\s', ' ')) AS full_name,
            '(' || cus_areacode || ')' || cus_phone AS "Phone Number"
    FROM avia_customer 
    WHERE cus_code IN 
        (SELECT cus_code FROM charter GROUP BY cus_code HAVING COUNT(char_trip) >=
            (SELECT COUNT (char_trip) FROM charter WHERE cus_code = 10011 GROUP BY cus_code))
    AND cus_code <> 10011
    ORDER BY cus_fname, cus_initial, cus_lname;


--6.    Display the aircraft number, model code, manufacturer and model name of the aircraft that was most recently chartered.
--Hint: June 1, 2018 is more recent than June 1, 2015.  Be sure that your query will still work if multiple aircraft were 
--chartered on the same day. You are permitted to use one inner join to get the manufacturer and model name displayed as 
--part of the result set. Your query must include at least one nested query to earn full credit.
SELECT RPAD(ac_number, 8) AS "Aircraft", aircraft.mod_code AS "Model", mod_manufacturer AS "Manufacturer", mod_name AS "Model Name"
    FROM aircraft, model
    WHERE aircraft.mod_code = model.mod_code AND
    aircraft.ac_number IN 
        (SELECT charter.ac_number FROM charter WHERE char_date = 
            (SELECT MAX(char_date) FROM charter));
        
--7.    Display the aircraft number and model code of all aircraft that have a higher AVERAGE 
--charter hours flown than aircraft#2778V.    
SELECT aircraft.ac_number AS "Aircraft", aircraft.mod_code AS "Model Code"
    FROM aircraft, charter
    WHERE aircraft.ac_number = charter.ac_number
    GROUP BY aircraft.ac_number, mod_code
    HAVING  AVG(char_hours_flown)  > 
        (SELECT AVG(char_hours_flown) FROM charter WHERE ac_number = '2778V');
    
--8.    Display the full name and phone number of each aviation customer who has not chartered 
--a plane.
SELECT TRIM(REGEXP_REPLACE((cus_fname || ' ' || cus_initial || '. ' || cus_lname ), '\s.\s', ' ')) AS full_name, 
        '(' || cus_areacode || ')' || cus_phone AS "Phone Number"
    FROM avia_customer
    WHERE cus_code IN 
        (SELECT cus_code FROM avia_customer MINUS SELECT cus_code FROM charter);
    
--For queries#9, 10 and 11, use the SALESREP and SALESREP_LEADERS tables owned by user JJ. 
--Your queries must be constructed using the relational operators union, intersect, or minus. 
--Sales reps in the SALESREP_LEADER table have won a special award for selling a certain amount 
--and brand of particular targeted products. Some of the people in the leader table no longer 
--work for the company. All sales reps in the SALESREP table are current employees.

--9.	Display sales rep id, full name and highest degree earned of all sales reps that have 
--won leader awards and are current employees.
SELECT salesrepid AS id, firstname || ' ' || lastname AS full_name, highestdegree AS "Highest Degree"
    FROM jj.salesrep 
    INTERSECT 
    SELECT salesrepid, firstname || ' ' || lastname, highestdegree 
    FROM jj.salesrep_leader;
    
--10.	Display sales rep id, full name and hire date of all sales reps that are either 
--current employees or have won leader awards.
SELECT salesrepid AS id, firstname || ' ' || lastname AS full_name, 
        TO_CHAR(TO_DATE(hiredate, 'DD MON, RR'), 'fmMonth DD, YYYY') AS "Hire Date"
    FROM jj.salesrep 
    UNION 
    SELECT salesrepid, firstname || ' ' || lastname, TO_CHAR(TO_DATE(hiredate, 'DD MON, RR'), 'fmMonth DD, YYYY')
    FROM jj.salesrep_leader;
    
--11.	We want to invite all sales leaders to a special ceremony in their honor. 
--We have already sent email to existing employees using company email. However we wish 
--to invite former leaders who are no longer employees. Write a query that will provide 
--the appropriate contact information and insert a comment into your script explaining 
--how the executive assistant can use the information to do the invitation. 
SELECT firstname || ' ' || lastname AS full_name, 
        address || ', ' || city || ', ' || state || ' ' || zipcode AS full_address,
        '(' || SUBSTR(homephone, 1, 3) || ')' || SUBSTR(homephone, 4,3) || '-' || SUBSTR(homephone, 7,4) AS "Home Phone", 
        '(' || SUBSTR(cellphone, 1, 3) || ')' || SUBSTR(cellphone, 4,3) || '-' || SUBSTR(cellphone, 7,4) AS "Cellphone"
    FROM jj.salesrep_leader
    MINUS
    SELECT firstname || ' ' || lastname, address || ', ' || city || ', ' || state || ' ' || zipcode, homephone, cellphone
    FROM jj.salesrep;
-- Please use home phone and/ or cellphone to request an email address or verify the mailing address
-- in order to send these former employees their invites.

--12.	Use the DECODE( ) statement to display the product name, description,  cost and 
--selling priority from user JJ’s PRODUCT table, where the selling priority is derived 
--from the BRAND value as follows: Discount => Low priority – don’t encourage, 
--House => Only sell if customer requests it, Premium => High Priority – Push!,  
--all others => Brand Unknown.
SELECT productname, description, cost, 
        DECODE(brand,
            'Discount', 'Low priority - don' || chr(39) || 't encourage',
            'House', 'Only sell if customer requests it',
            'Premium', 'High Priority - Push!',
            'Brand Unknown') 
        AS priority
        FROM jj.product;
    
--13.	Use a CASE statement that produces the same result as #12. 
SELECT productname, description, cost, 
        CASE brand
            WHEN 'Discount' THEN 'Low priority - don' || chr(39) || 't encourage'
            WHEN 'House' THEN 'Only sell if customer requests it'
            WHEN 'Premium' THEN 'High Priority - Push!'
            ELSE 'Brand Unknown'
            END
        AS priority
        FROM jj.product;
        
--14.	Use a DECODE or CASE statement to display words for JJ’s PRODUCT COST column as follows:
--$5.00 or below =>   “Low Price”
--Greater than $5.00 and less than $20.00 “Moderate Price”
--$20.00 and above “High Price”
--    Be sure to include enough of the other columns from the table to make the output meaningful.
SELECT productname, description, 
    CASE 
        WHEN cost <= 5 THEN 'Low Price'
        WHEN cost > 5 AND cost < 20 THEN 'Moderate Price'
        WHEN cost >= 20 THEN 'High Price'
        ELSE 'Cost Unknown'
        END
    AS "Cost"
    FROM jj.product;