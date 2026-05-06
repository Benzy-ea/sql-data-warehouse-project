/*
CRETE DATABASE AND SCHEMAS
SCRIPT PURPOSE:
    This script creates a new database named 'datawarehouse' after checking if it already exists.
    If the database exists, it is dropped and recreated. Additionally, the script sets up three schemas
    within the database: 'bronze','silver', and 'gold'.
*/

USE master;

CREATE DATABASE DataWarehouse;

USE DataWarehouse; 

CREATE SCHEMA Bronze;
GO
CREATE SCHEMA SILVER;
GO
CREATE SCHEMA GOLD;
