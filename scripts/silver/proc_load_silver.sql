/*
===============================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
===============================================================
Script Purpose:
  This stored procedure performs the ETL (Extract, Transform, Load) process to
  populate the 'silver' schema tables from the 'bronze' schema.
Actions Performed:
  - Truncates Silver tables,
  - Inserts transformed and cleansed data from Bronzee into Silver tables.

Parameters:
  None,
  This stored procedure does not accept any parameters or return any values

Usage example:
  EXEC SILVER.load_silver
==================================================================
*/




CREATE OR ALTER PROCEDURE Silver.load_silver AS


BEGIN
	DECLARE @start_time DATETIME;
	DECLARE @end_time DATETIME;
	DECLARE @batch_start_time DATETIME;
	DECLARE @batch_end_time DATETIME;
BEGIN TRY
	PRINT '=================================================='
	PRINT 'Loading data into Silver layer...'
	PRINT '=================================================='

		SET @batch_start_time = GETDATE();
	
	PRINT '--------------------------------------------------'
	PRINT 'Loading data into CRM Tables'
	PRINT '--------------------------------------------------'

		SET @start_time = GETDATE();

	PRINT 'Truncating Table: Silver.crm_cust_info'

	TRUNCATE TABLE silver.crm_cust_info;

	PRINT '>> Inserting cleaned data into Silver.crm_cust_info table'
		INSERT INTO Silver.crm_cust_info (
			cst_id, 
			cst_key,
			cst_firstname, 
			cst_lastname, 
			cst_marital_status, 
			cst_gndr, 
			cst_create_date)

	-- Data Standadization & Consistency
		SELECT 
			cst_id,
			cst_key,
			TRIM(cst_firstname) AS cst_firstname,
			TRIM(cst_lastname) AS cst_lastname,
			CASE 
				WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
				WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
				ELSE 'n/a'
			END cst_marital_status,
			CASE 
				WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
				WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
				ELSE 'n/a'
			END cst_gndr,
			cst_create_date
		FROM (
			SELECT *,
			ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
			FROM Bronze.crm_cust_info
			WHERE cst_id IS NOT NULL
		)t 
			WHERE flag_last = 1
 
			SET @end_time = GETDATE();

	PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'seconds';
	PRINT '>> ---------------------------'

		SET @start_time = GETDATE();

	PRINT 'Truncating Table: Silver.crm_prd_info'

	TRUNCATE TABLE silver.crm_prd_info;

	PRINT '>> Inserting cleaned data into Silver.crm_prd_info table'

	-- INSERTING CLEANED AND PROCESSED DATA INTO THE SILVER.CRM_PRD_INFO TABLE
		INSERT INTO silver.crm_prd_info (
			prd_id,
			cat_id,
			prd_key,
			prd_nm,
			prd_cost,
			prd_line,
			prd_start_dt,
			prd_end_dt
		)

	--CLEANED AND PROCESSED DATA FOR SILVER.CRM_PRD_INFO TABLE

		SELECT
			prd_id,
			REPLACE(SUBSTRING(prd_key, 1, 5), '-','_') AS cat_id,
			SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,
			prd_nm,
			ISNULL(prd_cost, 0) AS prd_cost,
			CASE UPPER(TRIM(prd_line)) 
				WHEN 'M' THEN 'Mountain'
				WHEN 'R' THEN 'Road'
				WHEN 'T' THEN 'Touring'
				WHEN 'S' THEN 'Other Sales'
				ELSE 'n/a' 
			END AS prd_line,
			CAST(prd_start_dt AS DATE) prd_start_dt,
			CAST(LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)-1 AS DATE) AS prd_end_dt
		FROM bronze.crm_prd_info

		SET @end_time = GETDATE();

	PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'seconds';
	PRINT '>> ---------------------------'

		SET @start_time = GETDATE();

	PRINT 'Truncating Table: Silver.crm_sales_details'

	TRUNCATE TABLE silver.crm_sales_details;

	PRINT '>> Inserting cleaned data into Silver.crm_sales_details table'
	--> Insert cleaned and processed data into silver.crm_sales_details
		INSERT INTO silver.crm_sales_details (
			sls_ord_num,
			sls_prd_key,
			sls_cust_id,
			sls_order_dt,
			sls_ship_dt,
			sls_due_dt,
			sls_sales,
			sls_quantity,
			sls_price
			)

	-- CLEANING AND PROCESSING DATA FOR crm_sales_details
		SELECT
			sls_ord_num,
			sls_prd_key,
			sls_cust_id,
			CASE 
				WHEN sls_order_dt = 0  
				OR sls_order_dt IS NULL 
				OR LEN(sls_order_dt) != 8
				OR sls_order_dt > 20300101
				OR sls_order_dt < 19000101
				THEN NULL
				ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
			END sls_order_dt,
			CASE 
				WHEN sls_ship_dt = 0  
				OR sls_ship_dt IS NULL 
				OR LEN(sls_ship_dt) != 8
				OR sls_ship_dt > 20300101
				OR sls_ship_dt < 19000101
				THEN NULL
				ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
			END sls_ship_dt,
			CASE 
				WHEN sls_due_dt = 0  
				OR sls_due_dt IS NULL 
				OR LEN(sls_due_dt) != 8
				OR sls_due_dt > 20300101
				OR sls_due_dt < 19000101
				THEN NULL
				ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
			END sls_due_dt,
			CASE WHEN sls_sales != sls_quantity * ABS(sls_price) 
				OR sls_sales <= 0
				OR sls_sales IS NULL
				THEN sls_quantity * ABS(sls_price) 
				ELSE sls_sales 
			END AS sls_sales,
			sls_quantity,
			CASE WHEN sls_price IS NULL 
				OR sls_price <= 0 
				THEN sls_sales / NULLIF(sls_quantity, 0)
				ELSE sls_price
			END AS sls_price
		FROM bronze.crm_sales_details

		SET @end_time = GETDATE();


	PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'seconds';
	PRINT '>> ---------------------------'

	PRINT '--------------------------------------------------'
	PRINT 'Loading data into ERP Tables'
	PRINT '--------------------------------------------------'

		SET @start_time = GETDATE();	

	PRINT 'Truncating Table: Silver.erp_cust_az12'

	TRUNCATE TABLE silver.erp_cust_az12;

	PRINT '>> Inserting cleaned data into Silver.erp_cust_az12 table'

	-- Insert cleaned and processed data into silver.erp_cust_az12

		INSERT INTO silver.erp_cust_az12 (
			cid,
			bdate,
			gen
			)

		SELECT 

			CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
			ELSE cid
			END AS cid,

			CASE WHEN bdate < '1900-01-01' OR bdate > GETDATE() OR bdate IS NULL
			THEN NULL
			ELSE bdate
			END AS bdate,

			CASE WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
				WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
						ELSE 'Other/Unknown'
			END AS gen
		FROM bronze.erp_cust_az12

		
		SET @end_time = GETDATE();

			
	PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'seconds';
	PRINT '>> ---------------------------'

		SET @start_time = GETDATE();

	PRINT 'Truncating Table: silver.erp_loc_a101' 

	TRUNCATE TABLE silver.erp_loc_a101;

	PRINT '>> Inserting cleaned data into Silver.erp_loc_a101 table'

	-- Inserting cleaned and processed data into silver.erp_loc_a101
		INSERT INTO silver.erp_loc_a101 (
			cid,
			cntry
			)

	-- cleaning and processing data for silver.erp_loc_a101
		SELECT
					REPLACE (cid, '-', '') AS cid,
			CASE WHEN UPPER(TRIM(cntry)) IN ('US', 'USA', 'UNITED STATES') THEN 'United States'
				 WHEN UPPER(TRIM(cntry)) = 'DE' THEN 'Germany'
				 WHEN UPPER(TRIM(cntry)) = '' OR cntry IS NULL THEN 'n/a'
				ELSE TRIM(cntry)
			END AS cntry
		FROM bronze.erp_loc_a101

		SET @end_time = GETDATE();

	PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'seconds';
	PRINT '>> ---------------------------'

		SET @start_time = GETDATE();

	PRINT 'Truncating Table: silver.erp_px_cat_g1v2'

	TRUNCATE TABLE silver.erp_px_cat_g1v2;

	PRINT '>> Inserting cleaned data into Silver.erp_px_cat_g1v2 table'

	-- Inserting cleaned and processed data into silver.erp_px_cat_g1v2
		INSERT INTO silver.erp_px_cat_g1v2 (
			id,
			cat,
			subcat,
			maintenance
			)	

		SELECT
			id,
			CASE WHEN UPPER(cat) != UPPER(TRIM(cat)) THEN TRIM(cat)
				ELSE cat
			END AS cat, 
			subcat,
			maintenance
		FROM bronze.erp_px_cat_g1v2

		SET @end_time = GETDATE();

	PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'seconds';
	PRINT '>> ---------------------------'

		SET @batch_end_time = GETDATE(); 
	PRINT 'Load Duration Bronze Layer Whole Batch'
	PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @batch_start_time, @batch_end_time) AS NVARCHAR) + 'seconds';
	PRINT '>> ---------------------------'
	END TRY

	BEGIN CATCH
		PRINT '==================================================='
		PRINT 'ERROR OCCURED DURING LOADING BRONZE'
		PRINT 'ERROR MESSAGE' + ERROR_MESSAGE();
		PRINT 'ERROR MESSAGE' + CAST (ERROR_NUMBER() AS NVARCHAR);
		PRINT 'ERROR MESSAGE' + CAST (ERROR_STATE() AS NVARCHAR);
		PRINT '==================================================='
	END CATCH 
END

