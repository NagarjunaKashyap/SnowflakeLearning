/*
🧱 Built-in (System) Roles in Snowflake
---------------------------------------

Snowflake comes with a predefined hierarchy of system roles — each with different levels of power.
This script includes detailed explanations in comments so it can be executed directly in Snowflake.
*/

/*

| Role          | Purpose / Access Level                                                                                                                  |
| ------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| ACCOUNTADMIN  | The highest role — full access to all objects and operations in the account. Used for top-level account setup, billing, and governance. |
| SECURITYADMIN | Manages users, roles, and grants. Can create/drop users and roles, assign roles to users. Does not manage data objects like tables.     |
| SYSADMIN      | Manages databases, schemas, tables, warehouses, and data objects. Used by DBAs or developers.                                           |
| USERADMIN     | Creates users, manages user properties (like passwords), and assigns roles.                                                             |
| ORGADMIN      | Exists only for organizations (multiple Snowflake accounts). Manages accounts at the org level.                                         |
| PUBLIC        | Default role automatically granted to all users. Has minimal privileges (e.g., can use the default warehouse or view public objects).   |
| */            |                                                                                                                                         |

/* -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- */

/* Create Custom Roles */
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

CREATE DATABASE DEMO_DB


GRANT USAGE ON DATABASE DEMO_DB TO ROLE HR_ADMIN;
GRANT USAGE ON DATABASE DEMO_DB TO ROLE ACCOUNTANT;
GRANT USAGE ON DATABASE DEMO_DB TO ROLE ANALYST;

GRANT USAGE ON SCHEMA DEMO_DB.PUBLIC TO ROLE HR_ADMIN;
GRANT USAGE ON SCHEMA DEMO_DB.PUBLIC TO ROLE ACCOUNTANT;
GRANT USAGE ON SCHEMA DEMO_DB.PUBLIC TO ROLE ANALYST;

/* -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- */
/* Switching and Viewing Roles */
USE ROLE SYSADMIN;  -- Switch role

SELECT CURRENT_ROLE();  -- View current active role
SHOW ROLES;             -- List all roles assigned to you
SHOW ROLES IN SESSION;  -- List active roles in session

SHOW GRANTS TO ROLE HR_ADMIN;
SHOW GRANTS OF ROLE HR_ADMIN;

/* -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- */
/*
🧩 1. ACCOUNTADMIN (Account Administrator)

* Highest-privileged role in Snowflake
* Can manage everything in the account (billing, governance, structure, etc.)
  */
  USE ROLE ACCOUNTADMIN;
  CREATE DATABASE SALES_DB;
  CREATE SCHEMA SALES_DB.PUBLIC;

CREATE ROLE DATA_ANALYST;
GRANT USAGE ON DATABASE SALES_DB TO ROLE DATA_ANALYST;
GRANT SELECT ON ALL TABLES IN SCHEMA SALES_DB.PUBLIC TO ROLE DATA_ANALYST;
GRANT ROLE DATA_ANALYST TO USER alice;
/* ✅ Use case: Super admin for full account setup and management */

/* -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- */
/*
🧱 2. SECURITYADMIN (Security Administrator)

* Manages users, roles, and privileges (access control)
* Does not manage data objects
  */
  USE ROLE SECURITYADMIN;

CREATE USER bob
PASSWORD = 'StrongPwd123'
DEFAULT_ROLE = DATA_ANALYST
MUST_CHANGE_PASSWORD = TRUE;

CREATE ROLE HR_ANALYST;
GRANT ROLE HR_ANALYST TO USER bob;

GRANT USAGE ON DATABASE HR_DB TO ROLE HR_ANALYST;
GRANT SELECT ON ALL TABLES IN SCHEMA HR_DB.PUBLIC TO ROLE HR_ANALYST;
/* ✅ Use case: Security team handling user access and privileges */

/* -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- */
/*
🧩 3. SYSADMIN (System Administrator)

* Manages databases, schemas, warehouses, and data structures
* Often used by DBAs or data engineers
  */
  USE ROLE SYSADMIN;
  CREATE DATABASE SALES_DB;
  CREATE SCHEMA SALES_DB.PUBLIC;

CREATE TABLE SALES_DB.PUBLIC.ORDERS (
ORDER_ID INT,
CUSTOMER_ID INT,
AMOUNT NUMBER
);

INSERT INTO SALES_DB.PUBLIC.ORDERS VALUES (1, 101, 500), (2, 102, 1000);

CREATE WAREHOUSE ETL_WH WITH WAREHOUSE_SIZE = 'MEDIUM' AUTO_SUSPEND = 300;

GRANT USAGE ON WAREHOUSE ETL_WH TO ROLE DATA_ANALYST;
/* ✅ Use case: Create and manage data warehouses and tables */

/* -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- */
/*
🧠 4. USERADMIN (User Administrator)

* Manages users only (creation, modification, deletion)
* Handles login credentials, MFA, default roles
  */
  USE ROLE USERADMIN;

CREATE USER alice
PASSWORD = 'Password123'
DEFAULT_ROLE = SYSADMIN
DEFAULT_WAREHOUSE = COMPUTE_WH
MUST_CHANGE_PASSWORD = TRUE;

ALTER USER alice SET EMAIL = '[alice@company.com](mailto:alice@company.com)';
DROP USER alice;
/* ✅ Use case: IT admin managing user lifecycle */

/* -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- */
/*
🌐 5. ORGADMIN (Organization Administrator)

* Available only for organizations with multiple Snowflake accounts
* Can create, suspend, or drop accounts under the organization
  */
  USE ROLE ORGADMIN;

SHOW ORGANIZATION ACCOUNTS;

CREATE ACCOUNT HR_ACCOUNT
ADMIN_NAME = 'hr_admin'
ADMIN_PASSWORD = 'StrongPwd!23'
EMAIL = '[hr_admin@company.com](mailto:hr_admin@company.com)'
EDITION = 'ENTERPRISE';

ALTER ACCOUNT HR_ACCOUNT SUSPEND;
/* ✅ Use case: Corporate-level admin managing multiple accounts */

/* -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- */
/*
👥 6. PUBLIC (Default Role)

* Automatically assigned to every user
* Has minimal privileges and used as a fallback
  */
  USE ROLE ACCOUNTADMIN;

GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE PUBLIC;
GRANT SELECT ON TABLE DEMO_DB.PUBLIC.SAMPLE_DATA TO ROLE PUBLIC;
/* ✅ Use case: Allow basic access for all users to shared or demo data */

/* -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- */
/*
🏗️ 7. Summary: Role Comparison Table

| Role          | Focus Area                            | Power Level  | Typical User        | Example Responsibilities           |
| ------------- | ------------------------------------- | ------------ | ------------------- | ---------------------------------- |
| ACCOUNTADMIN  | Entire account (governance, billing)  | 🔥 Highest   | Head of Platform    | Manage billing, global policies    |
| SECURITYADMIN | Access control & user/role management | 🔐 High      | Security Team       | Manage user permissions and roles  |
| SYSADMIN      | Data structures, compute, warehouses  | ⚙️ Medium    | DBA / Data Engineer | Create DBs, tables, and warehouses |
| USERADMIN     | User lifecycle management             | 👤 Medium    | IT Admin            | Create and manage users            |
| ORGADMIN      | Multi-account management              | 🌐 Very High | Org Admin           | Manage all Snowflake accounts      |
| PUBLIC        | Default role for all users            | 🧩 Low       | Everyone            | Access shared/public objects       |
| */            |                                       |              |                     |                                    |
