# Maufacturing_Analytics_Training_Project. 
End-to-end BI project: CSV data modeled into a MySQL star schema and visualized in a Power BI dashboard (beginner training project).

## Overview
This project walks through a basic BI pipeline: raw CSV files → cleaned and loaded into MySQL → star schema (fact + dimension tables) → Power BI dashboard.

## Dataset
- Source: [from a random Datasource] 
- Files: [Manufacturing_Dataset1_Master_Fixed.csv, mfg_star_schema.sql, Manufacturing_MySQL_PowerBI_Functional_Technical_Document.do]

## Tools Used
- MySQL (database and star schema)
- Power BI Desktop (dashboard)
- Excel
  
## Star Schema
- **Fact table:** `fact_production'`
- - **Dimension tables:** `dim_batch`, `dim_date`, `dim_line`, 'dim_product',  'dim_shift', 'dim_supervior' 

## Steps
1. Cleaned the CSV files
2. Created the database and tables in MySQL
3. Loaded the CSV data into the tables
4. Built the star schema with primary/foreign keys
5. Connected Power BI to MySQL
6. Created relationships, measures, and visuals

## Dashboard
![Dashboard Screenshot](images/dashboard.png)
<img width="1054" height="633" alt="image" src="https://github.com/user-attachments/assets/87e1099f-f8ad-43ff-b6e5-33313df7c763" />
<img width="1066" height="638" alt="image" src="https://github.com/user-attachments/assets/a9fb813e-a483-47ad-b872-f88d8b65ac49" />
<img width="1057" height="632" alt="image" src="https://github.com/user-attachments/assets/d1e9e784-8fcf-48ba-8f93-84fb7abf476e" />
<img width="1072" height="630" alt="image" src="https://github.com/user-attachments/assets/dbfdc299-3726-4110-a474-34aeec580333" />
<img width="1050" height="630" alt="image" src="https://github.com/user-attachments/assets/df2a6be6-6c42-47e1-8c4d-1d2db761a087" />
<img width="1080" height="634" alt="image" src="https://github.com/user-attachments/assets/b7aec754-505c-4d70-97b5-8559bc51588c" />


**Questions answered:**
- [e.g., Total sales by month]
- [e.g., Top 5 products]
- [e.g., Sales by region]

## Repository Structure
