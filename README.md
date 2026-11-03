# Manufacturing Analytics Training Project (MySQL+Power BI)  
An interactive Power BI dashboard that analyzes production output, product quality, material and energy efficiency, batch expiry and supervisor performance across a manufacturing unit. Built to help production and quality teams quickly see which lines, products and supervisors are performing well, and where waste is building up.

> **Project type:** Training project (beginner level) | **Stack:** CSV → MySQL → Power BI | **Data:** 50 production batches, Dec 2024 – Jan 2025

## Overview
The dashboard answers three core questions about the plant:

1. **Production & Quality** – How much are we producing, and how much of it is defective?
2. **Efficiency & Value** – How much material and energy does each unit cost us, and which products or categories bring in the most value?
3. **Batches & People** – Which batches are close to expiry, and which supervisors deliver the best (and worst) quality?

It is built as six connected pages (Home, Production, Quality, Efficiency, Batch & Expiry, Supervisor Performance) with slicers for date, product, category, production line, shift and supervisor, plus navigation buttons between pages.

## Dataset

The data covers 50 production batches of 15 products in 5 categories (Metal Products, Packaging, Components, Construction, Electrical), made on 3 production lines (A, B, C) across 3 shifts (Morning, Evening, Night), between 1 Dec 2024 and 19 Jan 2025.

Each record includes:

- Product ID, product name, category and batch number
- Production date and expiry date
- Quantity produced, unit price (USD) and defective units
- Production line, shift and supervisor name
- Material used (kg) and energy consumed (kWh)

**Note:** This is a training/practice dataset, not real company data. With only 50 batches, small differences between lines, products or supervisors may be random and should not be treated as proven facts.

## Tools Used

- **MySQL** – staging table, data-quality checks and reporting views
- **Power BI** – data modeling (star schema), DAX measures, dashboard design
- **Power Query** – data type checks and light cleaning
- **CSV** – source data

## Star Schema

- **Fact table:** `fact_production`
- **Dimension tables:** `dim_batch`, `dim_date`, `dim_line`, `dim_product`, `dim_shift`, `dim_supervisor`

The full SQL is in `mfg_star_schema.sql`.
  

## Steps
1. Cleaned the CSV files
2. Created the database and tables in MySQL
3. Loaded the CSV data into the tables
4. Built the star schema with primary/foreign keys
5. Connected Power BI to MySQL
6. Created relationships, measures, and visuals

## Dashboard
<img width="1054" height="633" alt="image" src="https://github.com/user-attachments/assets/87e1099f-f8ad-43ff-b6e5-33313df7c763" />
<img width="1066" height="638" alt="image" src="https://github.com/user-attachments/assets/a9fb813e-a483-47ad-b872-f88d8b65ac49" />
<img width="1057" height="632" alt="image" src="https://github.com/user-attachments/assets/d1e9e784-8fcf-48ba-8f93-84fb7abf476e" />
<img width="1072" height="630" alt="image" src="https://github.com/user-attachments/assets/dbfdc299-3726-4110-a474-34aeec580333" />
<img width="1050" height="630" alt="image" src="https://github.com/user-attachments/assets/df2a6be6-6c42-47e1-8c4d-1d2db761a087" />
<img width="1080" height="634" alt="image" src="https://github.com/user-attachments/assets/b7aec754-505c-4d70-97b5-8559bc51588c" />

## Key Findings

### Production & Quality

- The plant produced **33,100** units with **317** defective, giving a defect rate of **0.96%** and a yield of **99.04%**.
- Line B (Evening shift) has the highest defect rate at **1.70%**. Line A is at **0.84%** and Line C (Night shift) is lowest at **0.44%**.
- Line C produces the most (**13,850 units**), while Line A produces the least (**8,250 units**).
- Concrete Block (**1.35%**) and Brass Valve (**1.33%**) have the highest product defect rates. Among categories, Electrical and Metal Products are highest at about 1.14%.
- Packaging is the highest-volume category (**12,800 units**).
- Defect rate went from 0.91% in December to 1.03% in January, but January only has 19 days of data, so this is not a reliable trend.

### Efficiency & Value

- On average the plant uses **0.31 kg** of material and **0.20 kWh** of energy per unit produced.
- Line C uses the most energy per unit (**0.25 kWh**); Line B uses the least (**0.13 kWh**).
- Insulation Panel is the most resource-heavy product (**0.50 kg and 0.32 kWh per unit**). Paper Bag is the lightest (**0.13 kg and 0.10 kWh per unit**).
- Total gross value (quantity × unit price) is **$721,075**. Construction alone contributes about **$322,875 (45%)**, even though it is not the biggest category by volume.

### Supervisors

- Liam Thomas (**3.87%**) and Lucas Anderson (**2.12%**) have the highest defect rates, each across **6** batches.
- Isabella Davis has zero defects across 5 batches, and Mia Wilson has just **0.09%** across 6 batches and **6,850** units, the highest output of any supervisor.

## Business Recommendations
These come from what the dashboard shows. Where the data shows a pattern but not the cause, it is flagged as something to investigate, not a conclusion.
1. **Review quality control on Line B (Evening shift)**. Its defect rate (1.70%) is almost four times Line C's. The data does not say why. Action: check machine settings, raw material quality and operator checks on this line first.
2. **Look at the batches supervised by Liam Thomas and Lucas Anderson**. Both stand out on defect rate. Action: compare their batches with those of Mia Wilson and Isabella Davis to see what differs (products, line, process) before judging individual performance.
3. **Find out why Line C uses more energy per unit**. It makes the most units but uses almost twice the energy per unit of Line B. Action: check whether this comes from the products it makes (heavier items) or from machine inefficiency.
4. **Watch the resource-heavy products**. Insulation Panel, Steel Pipe and Concrete Block use the most material and energy per unit. Action: review material sourcing and processing for these products.
5. **Check Concrete Block and Brass Valve quality**. They have the highest defect rates, and Construction is also the highest-value category, so defects here cost more. Action: prioritize these two products in quality checks.
6. **Confirm the Night/Evening/Morning comparison is fair**. In this dataset each line runs only one shift, so line and shift results cannot be separated. Action: collect data where lines run multiple shifts before concluding that a shift has a quality problem.
7. **Use the Batch & Expiry page to prioritize stock**. Action: review batches marked near-expiry first, and consider shorter-shelf-life products when planning production.
8. **Collect more data**. 50 batches over 7 weeks is too small to spot real trends. Action: extend to several months and re-check these findings before acting on them.

## Dashboard Pages

| Page | What it shows |
|---|---|
| **Home** | Overall KPIs (total production, yield %, defect rate %, gross value, defective units), production by category, defect and yield trends over time |
| **Production Analysis** | Production over time, units by product, production by line and shift |
| **Quality Analysis** | Defect rate trend and by product and line, yield by line and shift, good vs defective units |
| **Efficiency Analysis** | Material per unit and energy per unit over time and by production line |
| **Batch & Expiry** | Batch list with expiry date, days to expiry and expiry status, by product and category |
| **Supervisor Performance** | Supervisor ranking, good units, defect rate and yield by supervisor and batch |

## Repository Structure
```├── manufacturing_analysis - GithuB.pbix                       # Power BI report
├── mfg_star_schema.sql                                           # MySQL star schema
├── Manufacturing_Dataset1_Master_Fixed.csv                       # source data
├── Manufacturing_MySQL_PowerBI_Functional_Technical_Document.docx
├── images/                                                       # dashboard screenshots
└── README.md
```
```

## What I Learned

1. Designing a star schema (fact and dimension tables) and relationships in Power BI
2. Writing DAX measures with `SUM`, `SUMX` and `DIVIDE`
3. Writing SQL data-quality checks before loading data
4. Building a multi-page report with slicers and navigation
5. Turning dashboard numbers into recommendations, and being careful not to overclaim from a small dataset

