/*
====================================================================
Stored Procedure: Load Bronze Layer (Source -> Bronze)
====================================================================
Script Purpose:
  This stored procedure loads data into the 'bronze' schema from external CSV files.
  It performs the following actions;
  - Truncates the bronze tables before loading data.
  - Uses the 'BULK INSERT' command to load data from csv files to bronze tables.

Parameters:
    None.
  This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC bronze.load_bronze;
=====================================================================
*/

CREATE OR ALTER PROCEDURE bronze.load_bronze AS 


BEGIN
	DECLARE @start_time DATETIME;
	DECLARE @end_time DATETIME;
	DECLARE @batch_start_time DATETIME;
	DECLARE @batch_end_time DATETIME;
BEGIN TRY
	PRINT '=================================================='
	PRINT 'Loading data into Bronze layer...'
	PRINT '=================================================='
		
		SET @batch_start_time = GETDATE();
	
	PRINT '--------------------------------------------------'
	PRINT 'Loading data into CRM Tables'
	PRINT '--------------------------------------------------'
	
		SET @start_time = GETDATE();
	
	PRINT '>> Truncating Table: bronze.crm_cust_info'
	
	TRUNCATE TABLE bronze.crm_cust_info;
	
	PRINT '>> Inserting Data Into: bronze.crm_cust_info';
			
			BULK INSERT bronze.crm_cust_info
				FROM 'C:\Users\MERCY PC\Documents\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
					WITH (
						FIRSTROW = 2,
						FIELDTERMINATOR = ',',
						TABLOCK
						);
		SET @end_time = GETDATE();
	
	PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'seconds';
	PRINT '>> ---------------------------'

		SET @start_time = GETDATE();
	
	PRINT '>> Truncating Table: bronze.crm_prd_info';
			
			TRUNCATE TABLE bronze.crm_prd_info;

	PRINT '>> Inserting Data Into: bronze.crm_prd_info'
			BULK INSERT bronze.crm_prd_info
				FROM 'C:\Users\MERCY PC\Documents\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
					WITH (
						FIRSTROW = 2,
						FIELDTERMINATOR = ',',
						TABLOCK
						);

		SET @end_time = GETDATE();
	
	PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'seconds';
	PRINT '>> ---------------------------'

		SET @start_time = GETDATE();
			
	PRINT '>> Truncating Table: bronze.crm_sales_details';
			
			TRUNCATE TABLE bronze.crm_sales_details;
	
	PRINT '>> Inserting Data Into: bronze.crm_sales_details';
			BULK INSERT bronze.crm_sales_details
				FROM 'C:\Users\MERCY PC\Documents\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
					WITH (
						FIRSTROW = 2,
						FIELDTERMINATOR = ',',
						TABLOCK
						);
		
		SET @end_time = GETDATE();
		
	PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'seconds';
	PRINT '>> ---------------------------'

	
	PRINT '--------------------------------------------------'
	PRINT 'Loading data into ERP Tables'
	PRINT '--------------------------------------------------'
	
		SET @start_time = GETDATE();
	PRINT '>> Truncating Table: Bronze.erp_cust_az12';
	
			TRUNCATE TABLE bronze.erp_cust_az12;
	
	PRINT '>> Inserting Data Into: Bronze.erp_cust_az12';
			BULK INSERT bronze.erp_cust_az12
				FROM 'C:\Users\MERCY PC\Documents\sql-data-warehouse-project\datasets\source_erp\cust_az12.csv'
					WITH (
					FIRSTROW = 2,
					FIELDTERMINATOR = ',',
					TABLOCK
					);

		SET @end_time = GETDATE();
	
	PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'seconds';
	PRINT '>> ---------------------------'

		SET @start_time = GETDATE();
			PRINT '>> Truncating Table: Bronze.erp_loc_a101';
			
			TRUNCATE TABLE bronze.erp_loc_a101;
	
	PRINT '>> Inserting Data Into: Bronze.erp_loc_a101';
			BULK INSERT bronze.erp_loc_a101
				FROM 'C:\Users\MERCY PC\Documents\sql-data-warehouse-project\datasets\source_erp\loc_a101.csv'
					WITH (
					FIRSTROW = 2,
					FIELDTERMINATOR = ',',
					TABLOCK
					);
		SET @end_time = GETDATE();
	
	PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'seconds';
	PRINT '>> ---------------------------'

		SET @start_time = GETDATE();
	PRINT '>> Truncating Table: Bronze.erp_px_cat_g1v2';
			
			TRUNCATE TABLE bronze.erp_px_cat_g1v2;
	
	PRINT '>> Inserting Data Into: Bronze.erp_px_cat_g1v2';
			BULK INSERT bronze.erp_px_cat_g1v2
				FROM 'C:\Users\MERCY PC\Documents\sql-data-warehouse-project\datasets\source_erp\px_cat_g1v2.csv'
					WITH (
					FIRSTROW = 2,
					FIELDTERMINATOR = ',',
					TABLOCK
					);
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
