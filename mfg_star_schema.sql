-- ============================================================================
-- MANUFACTURING DATA WAREHOUSE PIPELINE
-- ============================================================================
-- This script is your ORIGINAL requirement, unchanged, PLUS the missing
-- pieces needed to actually run it end-to-end:
--   1. Database creation                         [YOUR ORIGINAL]
--   2. Staging table                             [YOUR ORIGINAL]
--   3. CSV load into staging                     [ADDED]
--   4. Data quality checks                       [YOUR ORIGINAL]
--   5. Dimension tables (dim_date, dim_product,
--      dim_line, dim_shift, dim_supervisor,
--      dim_batch)                                [ADDED - required by fact_production FKs]
--   6. Fact table                                [YOUR ORIGINAL]
--   7. Transform/load: staging -> dimensions
--      -> fact table                             [ADDED - required to populate fact_production]
--   8. Reporting view                            [YOUR ORIGINAL]
--
-- Sections marked [ADDED] were missing from the original requirement doc.
-- Without them, fact_production's CREATE TABLE would fail (its foreign keys
-- point to tables that didn't exist yet), and there would be no way to get
-- data from staging into the star schema.
-- ============================================================================


-- ============================================================================
-- 0. CLEAN SLATE  [ADDED]
-- ----------------------------------------------------------------------------
-- Drops everything this script creates, so the ENTIRE script can be run
-- top-to-bottom repeatedly with zero errors — useful for demos, or any time
-- you want to prove the pipeline works from a completely empty state.
-- Order matters: fact_production first (it holds the FKs), then the
-- dimension tables it points to, then staging, then the view.
-- Safe to run even on a totally fresh database — DROP ... IF EXISTS simply
-- does nothing if a table isn't there.
-- ============================================================================
DROP VIEW IF EXISTS reporting.vw_production_summary;
DROP TABLE IF EXISTS manufacturing_db.fact_production;
DROP TABLE IF EXISTS manufacturing_db.dim_date;
DROP TABLE IF EXISTS manufacturing_db.dim_product;
DROP TABLE IF EXISTS manufacturing_db.dim_line;
DROP TABLE IF EXISTS manufacturing_db.dim_shift;
DROP TABLE IF EXISTS manufacturing_db.dim_supervisor;
DROP TABLE IF EXISTS manufacturing_db.dim_batch;
DROP TABLE IF EXISTS manufacturing_db.staging_manufacturing_production;


-- ============================================================================
-- 1. DATABASE  [YOUR ORIGINAL]
-- ============================================================================
CREATE DATABASE IF NOT EXISTS manufacturing_db;
USE manufacturing_db;


-- ============================================================================
-- 2. STAGING TABLE  [YOUR ORIGINAL]
-- ----------------------------------------------------------------------------
-- Raw landing zone for the CSV. No constraints/foreign keys here on purpose —
-- staging tables should accept messy data as-is; cleanup happens in the
-- data quality step below, before anything moves into the star schema.
-- ============================================================================
CREATE TABLE staging_manufacturing_production (
    product_id VARCHAR(50),
    product_name VARCHAR(150),
    category VARCHAR(100),
    batch_no VARCHAR(50),
    production_date DATE,
    expiry_date DATE,
    quantity_produced INT,
    unit_price DECIMAL(12,2),
    defective_units INT,
    production_line VARCHAR(50),
    supervisor_name VARCHAR(150),
    shift_name VARCHAR(30),
    material_used_kg DECIMAL(14,3),
    energy_consumption_kwh DECIMAL(14,3),
    load_datetime DATETIME DEFAULT CURRENT_TIMESTAMP
);


-- ============================================================================
-- 3. LOAD CSV INTO STAGING  [ADDED / UPDATED]
-- ----------------------------------------------------------------------------
-- This is the step your original script was missing: it defined the staging
-- table but never populated it. LOAD DATA INFILE is the fastest way to bulk
-- load a CSV into MySQL/MariaDB.
--
-- UPDATE: pointing this at the CORRECTED CSV
-- (Manufacturing_Dataset1_Master_Fixed.csv). The original source file had a
-- data bug: from row 17 onward, Expiry Date wasn't calculated from
-- Production Date at all — it was just cycling through the same 6 fixed
-- dates on repeat. That has been fixed by recalculating
-- Expiry Date = Production Date + shelf-life years, using this per-category
-- rule (average shelf life from the clean rows, rounded):
--     Metal Products : +2 years
--     Packaging      : +1 year
--     Electrical     : +3 years
--     Components     : +4 years
--     Construction   : +5 years
-- Rows 2-16 (already correct) were left untouched.
--
-- BEFORE RUNNING:
--   - Replace the file path below with the actual location of
--     Manufacturing_Dataset1_Master_Fixed.csv on your DB server (or client,
--     if using LOAD DATA LOCAL INFILE).
--   - If your MySQL server has "secure_file_priv" set, the file must sit in
--     that allowed directory (check with: SHOW VARIABLES LIKE 'secure_file_priv';).
--   - Use LOAD DATA LOCAL INFILE instead if the file is on your client
--     machine rather than the DB server (may require enabling local_infile).
--   - Adjust column order in the trailing (...) list if your CSV's column
--     order differs from the table's.
--   - load_datetime is deliberately excluded from the column list so it
--     keeps using its DEFAULT CURRENT_TIMESTAMP value.
--   - If you already ran this pipeline once against the OLD (buggy) CSV,
--     run the truncate/reload block right below before loading the fixed
--     file, so the bad expiry dates in dim_batch / fact_production get
--     cleared out rather than duplicated alongside the corrected rows.
-- ============================================================================

-- NOTE: the old truncate/reload block that used to live here has been
-- removed — it's no longer needed. Section 0 (top of script) already drops
-- and recreates every table on a full run, so staging is always empty by
-- the time we get here. (Keeping a TRUNCATE here would fail on a fresh run,
-- since fact_production/dim_* don't exist yet at this point — they're
-- created later, in Section 5/6.)

-- [UPDATED - 2nd fix] Two real data issues found from the load warnings:
--   1. The CSV has an extra "Total Cost ($)" column (position 9) that isn't
--      in staging_manufacturing_production. LOAD DATA maps fields by
--      POSITION, so without accounting for it, every column from
--      Total Cost onward shifted by one (Shift values like "Morning" were
--      landing in material_used_kg, etc.). Fixed by reading it into a
--      throwaway user variable (@total_cost) so it's consumed but discarded.
--   2. production_date / expiry_date in the CSV are in M/D/YYYY format
--      (e.g. 12/1/2024), but MySQL DATE columns expect YYYY-MM-DD. Fixed by
--      reading the raw text into user variables and converting with
--      STR_TO_DATE(..., '%m/%d/%Y') in the SET clause below.
LOAD DATA LOCAL INFILE 'C:/Users/moham/Desktop/MY PROJECTS/CSV Files/Manufacturing_Dataset1_Master_Fixed.csv'
INTO TABLE staging_manufacturing_production
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS                 -- skip the CSV header row
(
    product_id,
    product_name,
    category,
    batch_no,
    @production_date_raw,
    @expiry_date_raw,
    quantity_produced,
    unit_price,
    @total_cost,              -- CSV's "Total Cost ($)" column: read but discarded, no matching table column
    defective_units,
    production_line,
    supervisor_name,
    shift_name,
    material_used_kg,
    energy_consumption_kwh
)
SET
    production_date = STR_TO_DATE(@production_date_raw, '%m/%d/%Y'),
    expiry_date = STR_TO_DATE(@expiry_date_raw, '%m/%d/%Y');


-- ============================================================================
-- 4. DATA QUALITY CHECKS  [YOUR ORIGINAL]
-- ----------------------------------------------------------------------------
-- These are diagnostic SELECTs — they just show you the bad rows so you can
-- decide what to do (fix, exclude, flag). They don't delete or change
-- anything by themselves.
-- ============================================================================

-- Invalid quantities
SELECT *
FROM staging_manufacturing_production
WHERE quantity_produced <= 0;

-- Invalid defect counts
SELECT *
FROM staging_manufacturing_production
WHERE defective_units < 0
   OR defective_units > quantity_produced;

-- Invalid dates
SELECT *
FROM staging_manufacturing_production
WHERE expiry_date < production_date;

-- Duplicate batch records
SELECT batch_no, COUNT(*) AS record_count
FROM staging_manufacturing_production
GROUP BY batch_no
HAVING COUNT(*) > 1;


-- ============================================================================
-- 5. DIMENSION TABLES  [ADDED]
-- ----------------------------------------------------------------------------
-- fact_production (your original design) references dim_date, dim_product,
-- dim_line, dim_shift, dim_supervisor, and dim_batch via foreign keys — but
-- none of these were defined in the requirement doc, so the original
-- CREATE TABLE fact_production would have failed. These are added here,
-- built to match exactly what fact_production and vw_production_summary
-- expect (same key names, same columns referenced in the view).
-- ============================================================================

-- Date dimension: one row per calendar date, with commonly-used breakdowns
CREATE TABLE dim_date (
    date_key INT PRIMARY KEY,          -- e.g. 20260101 (YYYYMMDD), set at insert time
    full_date DATE NOT NULL UNIQUE,
    day_of_month INT,
    month INT,
    month_name VARCHAR(20),
    quarter INT,
    year INT,
    day_name VARCHAR(20)
);

-- Product dimension
CREATE TABLE dim_product (
    product_key INT AUTO_INCREMENT PRIMARY KEY,
    product_id VARCHAR(50) NOT NULL UNIQUE,
    product_name VARCHAR(150),
    category VARCHAR(100)
);

-- Production line dimension
CREATE TABLE dim_line (
    line_key INT AUTO_INCREMENT PRIMARY KEY,
    production_line VARCHAR(50) NOT NULL UNIQUE
);

-- Shift dimension
CREATE TABLE dim_shift (
    shift_key INT AUTO_INCREMENT PRIMARY KEY,
    shift_name VARCHAR(30) NOT NULL UNIQUE
);

-- Supervisor dimension
CREATE TABLE dim_supervisor (
    supervisor_key INT AUTO_INCREMENT PRIMARY KEY,
    supervisor_name VARCHAR(150) NOT NULL UNIQUE
);

-- Batch dimension (holds expiry_date, since vw_production_summary selects b.expiry_date)
CREATE TABLE dim_batch (
    batch_key INT AUTO_INCREMENT PRIMARY KEY,
    batch_no VARCHAR(50) NOT NULL UNIQUE,
    expiry_date DATE
);


-- ============================================================================
-- 6. FACT TABLE  [YOUR ORIGINAL]
-- ----------------------------------------------------------------------------
-- Now that all six referenced dimension tables exist above, this original
-- CREATE TABLE statement will run without error.
-- ============================================================================
CREATE TABLE fact_production (
    production_key BIGINT AUTO_INCREMENT PRIMARY KEY,
    date_key INT NOT NULL,
    product_key INT NOT NULL,
    line_key INT NOT NULL,
    shift_key INT NOT NULL,
    supervisor_key INT NOT NULL,
    batch_key INT NOT NULL,
    quantity_produced INT NOT NULL,
    defective_units INT NOT NULL,
    material_used_kg DECIMAL(14,3),
    energy_consumption_kwh DECIMAL(14,3),
    unit_price DECIMAL(12,2),
    FOREIGN KEY (date_key) REFERENCES dim_date(date_key),
    FOREIGN KEY (product_key) REFERENCES dim_product(product_key),
    FOREIGN KEY (line_key) REFERENCES dim_line(line_key),
    FOREIGN KEY (shift_key) REFERENCES dim_shift(shift_key),
    FOREIGN KEY (supervisor_key) REFERENCES dim_supervisor(supervisor_key),
    FOREIGN KEY (batch_key) REFERENCES dim_batch(batch_key)
);


-- ============================================================================
-- 7. TRANSFORM & LOAD: staging -> dimensions -> fact  [ADDED]
-- ----------------------------------------------------------------------------
-- This is the logic that actually moves cleaned data from staging into the
-- star schema. Run this AFTER you've reviewed/handled the data quality
-- issues found in section 4 (e.g. you may want to add WHERE clauses here to
-- exclude known-bad rows).
--
-- Order matters: dimensions must be populated first (fact rows need their
-- surrogate keys), and each dimension uses INSERT IGNORE with a UNIQUE
-- constraint so re-running this section is safe and won't create duplicates.
-- ============================================================================

-- 7a. Populate dim_date from distinct production dates in staging
INSERT IGNORE INTO dim_date (date_key, full_date, day_of_month, month, month_name, quarter, year, day_name)
SELECT DISTINCT
    CAST(DATE_FORMAT(production_date, '%Y%m%d') AS UNSIGNED) AS date_key,
    production_date,
    DAY(production_date),
    MONTH(production_date),
    MONTHNAME(production_date),
    QUARTER(production_date),
    YEAR(production_date),
    DAYNAME(production_date)
FROM staging_manufacturing_production
WHERE production_date IS NOT NULL;

-- 7b. Populate dim_product
INSERT IGNORE INTO dim_product (product_id, product_name, category)
SELECT DISTINCT product_id, product_name, category
FROM staging_manufacturing_production
WHERE product_id IS NOT NULL;

-- 7c. Populate dim_line
INSERT IGNORE INTO dim_line (production_line)
SELECT DISTINCT production_line
FROM staging_manufacturing_production
WHERE production_line IS NOT NULL;

-- 7d. Populate dim_shift
INSERT IGNORE INTO dim_shift (shift_name)
SELECT DISTINCT shift_name
FROM staging_manufacturing_production
WHERE shift_name IS NOT NULL;

-- 7e. Populate dim_supervisor
INSERT IGNORE INTO dim_supervisor (supervisor_name)
SELECT DISTINCT supervisor_name
FROM staging_manufacturing_production
WHERE supervisor_name IS NOT NULL;

-- 7f. Populate dim_batch
INSERT IGNORE INTO dim_batch (batch_no, expiry_date)
SELECT DISTINCT batch_no, expiry_date
FROM staging_manufacturing_production
WHERE batch_no IS NOT NULL;

-- 7g. Populate fact_production by joining staging to the now-populated dimensions
INSERT INTO fact_production (
    date_key, product_key, line_key, shift_key, supervisor_key, batch_key,
    quantity_produced, defective_units, material_used_kg, energy_consumption_kwh, unit_price
)
SELECT
    dd.date_key,
    dp.product_key,
    dl.line_key,
    ds.shift_key,
    dsu.supervisor_key,
    db.batch_key,
    s.quantity_produced,
    s.defective_units,
    s.material_used_kg,
    s.energy_consumption_kwh,
    s.unit_price
FROM staging_manufacturing_production s
JOIN dim_date       dd  ON dd.full_date = s.production_date
JOIN dim_product     dp ON dp.product_id = s.product_id
JOIN dim_line        dl ON dl.production_line = s.production_line
JOIN dim_shift        ds ON ds.shift_name = s.shift_name
JOIN dim_supervisor  dsu ON dsu.supervisor_name = s.supervisor_name
JOIN dim_batch        db ON db.batch_no = s.batch_no
-- Basic quality filter mirroring section 4's checks, so bad rows don't
-- pollute the fact table. Remove/adjust if you want to load everything.
WHERE s.quantity_produced > 0
  AND s.defective_units >= 0
  AND s.defective_units <= s.quantity_produced
  AND s.expiry_date >= s.production_date;


-- ============================================================================
-- 8. REPORTING VIEW  [YOUR ORIGINAL]
-- ----------------------------------------------------------------------------
-- Your original view lives in a "reporting" database/schema (reporting.vw_...),
-- so that database is created here first — this line is added only because
-- the view can't be created without its target schema existing.
-- ============================================================================
CREATE DATABASE IF NOT EXISTS reporting;   -- [ADDED] required so the view below has somewhere to live

CREATE OR REPLACE VIEW reporting.vw_production_summary AS
SELECT
    f.production_key,
    d.full_date,
    p.product_id,
    p.product_name,
    p.category,
    l.production_line,
    s.shift_name,
    sp.supervisor_name,
    b.batch_no,
    b.expiry_date,
    f.quantity_produced,
    f.defective_units,
    f.quantity_produced - f.defective_units AS good_units,
    f.material_used_kg,
    f.energy_consumption_kwh,
    f.unit_price,
    f.quantity_produced * f.unit_price AS gross_value
FROM manufacturing_db.fact_production f
JOIN manufacturing_db.dim_date d ON f.date_key = d.date_key
JOIN manufacturing_db.dim_product p ON f.product_key = p.product_key
JOIN manufacturing_db.dim_line l ON f.line_key = l.line_key
JOIN manufacturing_db.dim_shift s ON f.shift_key = s.shift_key
JOIN manufacturing_db.dim_supervisor sp ON f.supervisor_key = sp.supervisor_key
JOIN manufacturing_db.dim_batch b ON f.batch_key = b.batch_key;

-- NOTE: table names in the FROM/JOIN clauses are qualified with
-- "manufacturing_db." because the view itself lives in the "reporting"
-- database, not "manufacturing_db" — without qualification, MySQL would
-- look for fact_production etc. inside "reporting" and fail to find them.


-- ============================================================================
-- 9. QUICK SANITY CHECK (optional, run after everything above)
-- ============================================================================
-- SELECT * FROM reporting.vw_production_summary LIMIT 10;
