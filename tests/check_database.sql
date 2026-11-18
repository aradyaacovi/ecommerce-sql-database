/*
Post-install checks, run by CI after sql/01_create_database_and_load_data.sql.

Every number here is one the README states, so a change to the data or the
schema that contradicts the README fails the build instead of going unnoticed.
Each THROW makes sqlcmd -b exit non-zero.
*/

SET NOCOUNT ON;
USE zales;
GO

/* 10 tables, as the schema table in the README lists */
DECLARE @tables INT = (SELECT COUNT(*) FROM sys.tables);
PRINT CONCAT('Tables: ', @tables);
IF @tables <> 10
    THROW 50001, 'Expected 10 tables.', 1;
GO

/* The unit totals behind the Power BI report */
DECLARE @customized INT, @default INT;
SELECT
    @customized = SUM(CASE WHEN JV.Variant_Type = 'Customized' THEN I.Quantity ELSE 0 END),
    @default    = SUM(CASE WHEN JV.Variant_Type = 'Default'    THEN I.Quantity ELSE 0 END)
FROM dbo.INCLUDES AS I
JOIN dbo.JEWELRY_VARIANTS AS JV
    ON I.Jewelry_Variant = JV.Jewelry_Variant;

PRINT CONCAT('Customized units: ', @customized, ' / Default units: ', @default);
IF @customized <> 1814 OR @default <> 1826
    THROW 50002, 'Unit totals do not match the figures published in the README.', 1;
GO

/* SEARCHES keeps its composite primary key (Search_IP, Search_DT) */
DECLARE @key_cols INT = (
    SELECT COUNT(*)
    FROM sys.indexes AS i
    JOIN sys.index_columns AS ic
        ON i.object_id = ic.object_id AND i.index_id = ic.index_id
    WHERE i.is_primary_key = 1
      AND OBJECT_NAME(i.object_id) = 'SEARCHES'
);
PRINT CONCAT('SEARCHES primary key columns: ', @key_cols);
IF @key_cols <> 2
    THROW 50003, 'SEARCHES should have a two-column primary key.', 1;
GO

/* The view, function, trigger and procedure the README documents */
IF OBJECT_ID('dbo.V_ORDER_ANALYSIS', 'V') IS NULL
    THROW 50004, 'View V_ORDER_ANALYSIS is missing.', 1;
IF OBJECT_ID('dbo.GetStateSalesSummary', 'IF') IS NULL
   AND OBJECT_ID('dbo.GetStateSalesSummary', 'TF') IS NULL
    THROW 50005, 'Function GetStateSalesSummary is missing.', 1;
IF OBJECT_ID('dbo.trg_UpdateOrderValue', 'TR') IS NULL
    THROW 50006, 'Trigger trg_UpdateOrderValue is missing.', 1;
IF OBJECT_ID('dbo.sp_SetOrderPackaging', 'P') IS NULL
    THROW 50007, 'Procedure sp_SetOrderPackaging is missing.', 1;
PRINT 'View, function, trigger and procedure are all present.';
GO

PRINT 'All checks passed.';
GO
