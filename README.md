# Karabakh University Library Data Analytics

An end-to-end data analytics project using *Python (Pandas & NumPy), **Google BigQuery (SQL), and **Power BI*. 

This project explores 2 years of book circulation, study room usage, and 1 year of computer reservations to solve operational problems and provide actionable business recommendations.

---

## Project Overview

* *Domain:* Academic Library Operations
* *Data Sources:* 
  * 2 Years of Book Circulation Data
  * 2 Years of Discussion Room Bookings
  * 1 Year of Computer Reservations
* *Tools & Tech Stack:*
  * *Python (Pandas, NumPy):* Data cleaning and preprocessing
  * *Google BigQuery (SQL):* Data analysis, transformations, and KPI calculations
  * *Power BI:* Relational data modeling (Star Schema) and interactive dashboards

---
<img width="1600" height="898" alt="image" src="https://github.com/user-attachments/assets/cb206183-98c5-4d6e-b7c9-79d5ebd77d94" />
<img width="1600" height="898" alt="image" src="https://github.com/user-attachments/assets/2bf6c7d5-0480-4205-8d88-c51c5517c22e" />



## 1. Data Cleaning & Preprocessing (Python)

Manual data entry created several challenges that made the raw datasets unsuitable for analysis. The preprocessing steps included:

* *Date Validation:* Fixed mechanical date-entry errors where return dates preceded check-out dates, causing negative or unrealistic durations.
* *Whitespace Handling:* Removed hidden leading and trailing whitespaces that caused automated functions to miss return dates across 2,336 rows.
* *Categorical Standardization:* Mapped inconsistent department and major names (e.g., standardizing Riy. müəllimliyi to Riyaziyyat müəllimliyi).
* *Handling Duplicates & Blanks:* Cleaned duplicated user entries and resolved formatting mismatches before importing into the database.

---

## 2. Exploratory Data Analysis & SQL (BigQuery)

Cleaned datasets were loaded into Google BigQuery to answer core operational questions:
* Monthly and semester-level circulation volume.
* Peak usage hours for study rooms.
* Departmental distribution for computer and room reservations.
* Unique books vs. total circulation turnover ratios.

(Note: Add your main queries to queries.sql in this repo)

---

## 3. Data Modeling & Visualization (Power BI)

* *Architecture:* Built a *Star Schema* to connect all fact tables (Circulation, Room Bookings, Computer Reservations) through shared dimensions:
  * Dim_User: Centralized table with unique user profiles.
  * Dim_Date: Custom calendar table for continuous time-series filtering.
* *UI/UX Design:* Formatted using official university branding colors, focusing on high readability and clear cross-filtering.
* *Interface Language:* The dashboard visuals are designed in Azerbaijani for internal stakeholders.

---

## 4. Key Insights & Domain-Driven Solutions

Relying strictly on numbers without operational context can lead to misleading decisions. Combining data analysis with firsthand library domain knowledge revealed key insights:

* *The Computer Reservation Outlier:* Data showed that the Primary Education major had double the computer reservations of other majors. In reality, this was driven by intensive daily reservations by an individual volunteer student during that period, not a systemic university-wide equipment shortage.
* *Circulation Density:* Since academic textbooks are strictly non-circulating (reading-room only), the turnover ratio analysis was focused directly on fiction literature.
* *Zero-Budget Business Recommendation:* High-demand fiction titles face significant queues during peak exam periods (April–May and October). Temporarily reducing the borrowing period for these specific titles directly increases book availability and shortens student wait times without any budget expenditure.

---

## Project Structure

├── data_cleaning.py   # Python cleaning script (Pandas & NumPy)
├── queries.sql        # BigQuery SQL queries
└── README.md          # Project documentation & dashboard visuals
