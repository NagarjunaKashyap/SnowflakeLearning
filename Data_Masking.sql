/*
Snowflake's Data Masking Policy
-------------------------------

In Snowflake, a data masking policy is a security feature that helps protect sensitive data
(like PII — Personally Identifiable Information) by dynamically masking or hiding it when queried
by unauthorized users.

It allows you to control who can see what data without physically changing or duplicating
the data stored in your tables.
*/

/* --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

🧩 1. What is a Masking Policy?

A masking policy is a schema-level object in Snowflake that defines rules for transforming (masking)
data returned from a column based on the querying user’s role.

You can apply it to one or more table columns.

Syntax:
*/

CREATE OR REPLACE MASKING POLICY example_mask_policy
AS (val STRING)
RETURNS STRING ->
CASE
WHEN CURRENT_ROLE() = 'ADMIN_ROLE' THEN val
ELSE 'MASKED'
END;

/* ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

🧠 2. Simple Example
*/

CREATE OR REPLACE TABLE employees (
id INT,
name STRING,
email STRING,
salary NUMBER
);

/*
You want to hide salaries from non-admin users.
*/

/* Step 1: Create the Masking Policy */
CREATE OR REPLACE MASKING POLICY mask_salary
AS (val NUMBER) RETURNS NUMBER ->
CASE
WHEN CURRENT_ROLE() IN ('HR_ADMIN', 'ACCOUNTANT') THEN val
ELSE NULL
END;

/*
Here:
If the current role is HR_ADMIN or ACCOUNTANT, the user sees the real salary.
Everyone else sees NULL.
*/

/* Step 2: Apply the Policy to a Column */
ALTER TABLE employees
MODIFY COLUMN salary
SET MASKING POLICY mask_salary;

/* Step 3: Test It */
USE ROLE HR_ADMIN;
SELECT * FROM employees;  -- Sees actual salaries

USE ROLE ANALYST;
SELECT * FROM employees;  -- Sees salary as NULL

/* ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

🔐 3. Example with String Masking
You can also partially mask strings, like emails or phone numbers.
*/

/* Step 1: Create a masking policy for emails */
CREATE OR REPLACE MASKING POLICY mask_email
AS (val STRING) RETURNS STRING ->
CASE
WHEN CURRENT_ROLE() IN ('ADMIN_ROLE') THEN val
ELSE CONCAT('***@', SPLIT_PART(val, '@', 2))
END;

/* Step 2: Apply the Policy to a Column */
ALTER TABLE employees
MODIFY COLUMN email
SET MASKING POLICY mask_email;

/* Step 3: Test */
USE ROLE HR_ADMIN;
SELECT * FROM employees;  -- Sees actual emails

USE ROLE ANALYST;
SELECT * FROM employees;  -- Sees masked emails

/*
Role	Email Output
ADMIN_ROLE	[john.doe@snowflake.com](mailto:john.doe@snowflake.com)
ANALYST	***@snowflake.com
*/

/* Detach (remove) a policy */
ALTER TABLE employees MODIFY COLUMN email UNSET MASKING POLICY;

/* Check applied policies */
SHOW MASKING POLICIES;
DESC MASKING POLICY mask_email;

/*
5. Dynamic Data Masking with Conditions
You can use:
CURRENT_ROLE()
CURRENT_USER()
IS_ROLE_IN_SESSION('role_name')
SYSTEM$USER_IS_MEMBER_OF_ROLE('role_name')
*/

/* Example: */
CREATE OR REPLACE MASKING POLICY mask_phone
AS (val STRING) RETURNS STRING ->
CASE
WHEN SYSTEM$USER_IS_MEMBER_OF_ROLE('SUPPORT_TEAM') THEN val
ELSE CONCAT('XXX-XXX-', RIGHT(val, 4))
END;

/*

| Concept          | Description                                     |
| ---------------- | ----------------------------------------------- |
| **Purpose**      | Protect sensitive data dynamically              |
| **Level**        | Column-level                                    |
| **Control**      | Based on user role or function                  |
| **Effect**       | Masks data at query time (no change in storage) |
| **Combine with** | Row access policies for full data governance    |
| */               |                                                 |

/* -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

🧩 Scenario
We’ll secure employee salary data so that:
HR_ADMIN and ACCOUNTANT can see real salaries.
ANALYST sees masked salaries (NULL).
*/

/* Step 1: Create Roles and Assign Privileges */
CREATE OR REPLACE ROLE HR_ADMIN;
CREATE OR REPLACE ROLE ACCOUNTANT;
CREATE OR REPLACE ROLE ANALYST;

/* Grant roles to your user (replace <your_user_name>) */
GRANT ROLE HR_ADMIN TO USER <your_user_name>;
GRANT ROLE ACCOUNTANT TO USER <your_user_name>;
GRANT ROLE ANALYST TO USER <your_user_name>;

/* Grant necessary privileges to roles */
GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE HR_ADMIN;
GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE ACCOUNTANT;
GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE ANALYST;

GRANT USAGE ON DATABASE DEMO_DB TO ROLE HR_ADMIN;
GRANT USAGE ON DATABASE DEMO_DB TO ROLE ACCOUNTANT;
GRANT USAGE ON DATABASE DEMO_DB TO ROLE ANALYST;

GRANT USAGE ON SCHEMA DEMO_DB.PUBLIC TO ROLE HR_ADMIN;
GRANT USAGE ON SCHEMA DEMO_DB.PUBLIC TO ROLE ACCOUNTANT;
GRANT USAGE ON SCHEMA DEMO_DB.PUBLIC TO ROLE ANALYST;

/* 🧱 Step 2: Create a Sample Table */
USE ROLE ACCOUNTADMIN;
USE DATABASE DEMO_DB;
USE SCHEMA PUBLIC;

CREATE OR REPLACE TABLE employees (
id INT,
name STRING,
email STRING,
salary NUMBER
);

INSERT INTO employees VALUES
(1, 'Alice', '[alice@snowflake.com](mailto:alice@snowflake.com)', 90000),
(2, 'Bob', '[bob@snowflake.com](mailto:bob@snowflake.com)', 85000),
(3, 'Charlie', '[charlie@snowflake.com](mailto:charlie@snowflake.com)', 80000);

/* 🧠 Step 3: Create a Masking Policy */
CREATE OR REPLACE MASKING POLICY mask_salary
AS (val NUMBER) RETURNS NUMBER ->
CASE
WHEN CURRENT_ROLE() IN ('HR_ADMIN', 'ACCOUNTANT') THEN val
ELSE NULL
END;

/* Step 4: Apply the Policy to the Column */
ALTER TABLE employees
MODIFY COLUMN salary
SET MASKING POLICY mask_salary;

/* 👀 Step 5: Test the Masking Policy */

/* 🧑‍💼 As HR_ADMIN */
USE ROLE HR_ADMIN;
SELECT * FROM employees;
/*
| id
-------------------------------
SELECT CURRENT_ACCOUNT(), CURRENT_REGION(), CURRENT_ORGANIZATION_NAME();

SHOW PARAMETERS LIKE 'edition';

SHOW PARAMETERS LIKE 'ENABLE_DATA_MASKING';

-- Create a secure view that hides salary for non-HR roles
CREATE OR REPLACE SECURE VIEW employee_view AS
SELECT
    id,
    name,
    CASE
        WHEN CURRENT_ROLE() IN ('HR_ADMIN', 'ACCOUNTANT') THEN salary
        ELSE NULL
    END AS masked_salary
FROM EMPLOYEES;

select * from employees

select * from employee_view
