# Maufacturing_Analytics_Training_Project. 
End-to-end BI project: CSV data modeled into a MySQL star schema and visualized in a Power BI dashboard (beginner training project).

## Overview
This project walks through a basic BI pipeline: raw CSV files → cleaned and loaded into MySQL → star schema (fact + dimension tables) → Power BI dashboard.

## Dataset
- Source: [from a random Datasource] 
- Files: [Manufacturing_Dataset1_Master_Fixed.csv, mfg_star_schema.sql, Manufacturing_MySQL_PowerBI_Functional_Technical_Document.doc]

## Tools Used
- MySQL (database and star schema)
- Power BI Desktop (dashboard)
- Excel
  
## Star Schema
- **Fact table:** `fact_production'`
- - **Dimension tables:** `dim_batch`, `dim_date`, `dim_line`,'dim_product', 'dim_shift','dim_supervior' 

## Steps
1. Cleaned the CSV files
2. Created the database and tables in MySQL
3. Loaded the CSV data into the tables
4. Built the star schema with primary/foreign keys
5. Connected Power BI to MySQL
6. Created relationships, measures, and visuals

## Dashboard
![Dashboard Screenshot](images/dashboard.png)

**Questions answered:**
- [e.g., Total sales by month]
- [e.g., Top 5 products]
- [e.g., Sales by region]

## Repository Structure
