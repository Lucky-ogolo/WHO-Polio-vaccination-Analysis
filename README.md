 # Ekiti State Polio Vaccination Data Analysis

 ## Project Description
   This project analyzes polio vaccination campaign data from Ekiti State, Nigeria, collected across multiple Local Government Areas (LGAs) between May 29, 2025 and July 2, 2025. 
   The dataset includes vaccination records per team, per campaign phase, and covers children targeted and vaccinated.
 
 ## Objectives
   - Explore the dataset and perform data cleaning.
   - Handle NULLs and anomalies like coverage > 100%.
   - Improve on my sql queries and test my skill.
   - Derive insights on vaccination coverage, team efficiency, and gaps.

  ## Dataset
  - File: datasets
- Columns:
  - state
  - lga
  - report_date
  - children_targeted
  - children_vaccinated
  - vaccination_team
  - campaign_phase
  - vaccination_coverage_pct
- Notes: Contains NULLs representing unreported data; some coverage values > 100% due to reporting errors.

   ## SQL Scripts
1. database table creation
2. data import
3. data exploration and cleaning
4. dataanalysis

## Data Setup
 ### create database:
 ```sql
    Create database ekiti_polio_analysis;
```
### create table:
  ```sql
      create table PolioVdata(
    state	                 varchar(10),
	   lga	                     varchar(20),
	   report_date	             date,
	   children_targeted	     int,
	   children_vaccinated	     int,   
	   vaccination_team	         varchar(20),
	   campaign_phase	         varchar(20),
	   vaccination_coverage_pct  decimal(5,2)
	   );
      Alter table PolioVdata 
	  Alter column vaccination_coverage_pct TYPE NUMERIC(10,2);
  
```
  ### data cleaning and exploration:
	 **checking for nulls**:
   ```sql
       select * from PolioVdata 
	   where state = null
	   or lga=null
	   or report_date is null
	   or report_date is null
	   or children_vaccinated is null
	   or children_targeted is null
	   or vaccination_team is null
	   or campaign_phase is null
	   or vaccination_coverage_pct is null;
```
-- Note: some vaccination-related columns contain null values,
-- which likely represent missing or unreported data for certain
-- Note: vaccination_coverage_pct contains some values >100 due to reporting errors,these represent anomalies in the original data and are kept intentionally

**Check for duplicates**:
```sql
       select state,report_date, count(*) as record_count
       from poliovdata
       group by state,report_date
       having count(*) > 1;

### Assign a row number to each record partitioned by state and report_date:
       with ranked as (
            select *,
            row_number() over (partition by state,lga,report_date,children_targeted,children_vaccinated order by state) as rn
            from poliovd
        )
         select *
          from ranked
          where rn =2;
```
### data analysis


-- Q1. How many total records are in the dataset?
```sql
       select count(*) from poliovdata;
```
-- Q2. How many distinct LGAs are represented in the dataset?
 ```sql
       select distinct lga from poliovdata;
```
-- Q3. What is the total number of children targeted across all LGAs and dates?
   ```sql
    select report_date, sum(children_targeted) as children_targeted from poliovdata
	   group by report_date;
```
--Q4. What is the total number of children vaccinated across all LGAs and dates?
   ```sql
    select lga,report_date, sum(children_vaccinated) as children_vaccinated from poliovdata
	   group by lga,report_date;
```	   
--Q5. Which vaccination team has the most records in the dataset?
   ```sql
   select vaccination_team,count(*) as records from poliovdata
	  group by vaccination_team
	  order by vaccination_team desc
	  limit 1;
```	  
--Q6. What is the average vaccination coverage percentage across all LGAs?
   ```sql
   select lga, round(avg(vaccination_coverage_pct),2) as avg_vacpct from poliovdata
	  group by lga;
```	  
--Q7. Which LGA has the highest average vaccination coverage percentage?
   ```sql
   select lga, round(avg(vaccination_coverage_pct),2) as avg_vacpct from poliovdata
	  group by lga
	  order by lga  desc
	  limit 1;
```	  
--Q8. Which LGA has the lowest average vaccination coverage percentage?
   ```sql
   select lga, round(avg(vaccination_coverage_pct),2) as avg_vacpct from poliovdata
	  group by lga
	  order by lga  asc
	  limit 1;
```	  
--Q9. How many records have vaccination coverage above 100%?
   ```sql
   select count(*) as records from poliovdata
	  where vaccination_coverage_pct>100;
```	  
--Q10. How many records belong to each campaign phase (Initial vs Follow-up)?
   ```sql
   select campaign_phase, count(*) as records from poliovdata
	  group by campaign_phase;
```	  
--Q11. For each LGA, what is the total number of children targeted vs vaccinated?
   ```sql
   select lga,SUM(
	  CASE WHEN children_targeted IS NOT NULL THEN children_targeted ELSE 0 END)
	  as children_targeted,
      SUM(CASE WHEN children_vaccinated IS NOT NULL THEN children_vaccinated ELSE 0 END)
      as children_vaccinated
	  from poliovdata group by lga;
```	  
--Q12. For each vaccination team, calculate the average vaccination coverage percentage.
   ```sql
    select vaccination_team,round(avg(vaccination_coverage_pct),2) as avg_pct 
	   from poliovdata
	   group by vaccination_team;
```	   
--`Q13. Which LGA has the largest difference between children targeted and children vaccinated?
   ```sql
    select lga,sum(coalesce(children_targeted,0)-coalesce(children_vaccinated,0)) as diff from poliovdata
	   group by lga
	   order by diff desc
	    limit 1;
```	  
--Q14. Identify the date with the highest total number of children vaccinated across all LGAs.
   ```sql
     select lga,report_date,sum(coalesce(children_vaccinated,0)) as children_vaccinated from poliovdata
        group by lga,report_date
        order by children_vaccinated desc
       limit 1;
```  
--Q15.Rank LGAs by total vaccination coverage percentage and assign a rank number to each.
   ```sql
      select lga,coalesce(sum(vaccination_coverage_pct),0) as vaccine_coverPct,
		 rank()over(partition by lga order by coalesce(sum(vaccination_coverage_pct),0) desc) as rnk
		 from poliovdata 
		 group by lga;
```
--Q16 . LGAs where coverage consistently stayed below 80%
   ```sql
      select lga
         from poliovdata
         group by lga
         having min(vaccination_coverage_pct) < 80;
```
--Q17. Vaccination team efficiency (coverage relative to targeted)
   ```sql
      select vaccination_team, sum(children_vaccinated)/sum(children_targeted)*100 as avg_coverage_pct
         from poliovdata
         group by vaccination_team
         order by avg_coverage_pct desc;
```
--Q18. Proportion of children vaccinated by campaign phase
	 ```sql 
         select campaign_phase, sum(children_vaccinated)::decimal / sum(children_targeted)*100 as coverage_pct
           from poliovdata 
          group by campaign_phase;
    ```
--Q19. Coverage comparison by weekday
   ```sql
        select extract(DOW from report_date) as weekday,
         avg(vaccination_coverage_pct) as avg_coverage
         from poliovdata
         group by weekday
         order by weekday;
```
--Q20. LGAs where vaccinated > targeted
   ```sql
      select lga, sum(children_vaccinated - children_targeted) as overreport_total
         from poliovdata
         where children_vaccinated > children_targeted
         group by lga
         order by overreport_total desc;
```
--Q21. Rank vaccination teams by avg coverage per LGA and campaign phase
   ```sql
      select lga, campaign_phase, vaccination_team,
         rank() over (partition by lga, campaign_phase order by avg(vaccination_coverage_pct) desc) as rank_team,
         avg(vaccination_coverage_pct) as avg_coverage
         from poliovdata
         group by lga, campaign_phase, vaccination_team
         order by lga, campaign_phase, rank_team;
```
--Q22. Top 3 LGAs with largest gaps between targeted and vaccinated
   ```sql
      select lga, sum(children_targeted - children_vaccinated) as total_gap
         from poliovdata
         group by lga
         order by total_gap desc
         limit 3;
```
--Q23. Overall campaign metrics per LGA and state-wide,Per LGA
   ```sql
      select lga,
         sum(children_vaccinated) as total_vaccinated,
         sum(children_targeted) as total_targeted,
         sum(children_vaccinated)::decimal / sum(children_targeted)*100 as coverage_pct,
         count(*) filter (where children_vaccinated is null or children_targeted is null) as missing_data_count
         from poliovdata
         group by lga
         order by coverage_pct desc;
```
-- Q24. State-wide
```sql
         select sum(children_vaccinated) as total_vaccinated,
         sum(children_targeted) as total_targeted,
         sum(children_vaccinated)::decimal / sum(children_targeted)*100 as coverage_pct,
         count(*) filter (where children_vaccinated is null or children_targeted is null) as missing_data_count
         from poliovdata;
```
## Findings
- Vaccination coverage varies across LGAs; some LGAs consistently fall below 80%, while others exceed 100% due to reporting errors.
- Vaccination teams show differences in efficiency, with some consistently achieving higher coverage per LGA.
- Campaign progress over time highlights LGAs requiring more focused attention.
- NULLs in `children_targeted`, `children_vaccinated`, and `vaccination_coverage_pct` reflect missing or unreported data.
- The largest gaps between targeted and vaccinated children highlight logistical or reporting challenges in certain LGAs.
- No duplicate records were found.

---

## Conclusion
- The dataset provides a realistic simulation of public health campaign data, allowing practice of SQL skills from beginner to advanced.
- Overall coverage is high, but some LGAs need additional attention, as indicated by coverage gaps and discrepancies.
- SQL queries can identify trends, rank teams, and flag data quality issues.
- Retaining NULLs and anomalies provides opportunities to practice data cleaning, aggregation, and conditional logic.

---

## Additional Contributions / Highlights
- 24 analysis questions designed to showcase a range of SQL skills.
- Applied window functions, ranking, aggregation, and NULL handling.
- Detailed comments in SQL scripts explain logic, cleaning decisions, and assumptions.
- Repository structure is organized and portfolio-ready.
- Demonstrates handling of realistic, messy datasets with missing and inconsistent data.

---

## How to Use
1. Open PostgreSQL / pgAdmin environment.
2. Run SQL scripts in order:
   1. `01_create_table.sql`
   2. `02_import_data.sql`
   3. `03_exploration_cleaning.sql`
   4. `04_analysis_queries.sql`
   5. `05_advanced_analysis.sql`
3. Review comments in scripts for explanation of each step.
4. Explore and modify queries to practice further analysis.

## Key Takeaways
- **SQL Mastery:** Demonstrated beginner to advanced SQL skills, including joins, aggregation, window functions, ranking, and handling of NULLs and anomalies.
- **Data Cleaning Awareness:** Retained NULLs and noted reporting errors, reflecting realistic public health data scenarios.
- **Analytical Thinking:** Identified gaps, trends, and efficiency metrics across LGAs, vaccination teams, and campaign phases.
- **Portfolio-Ready Documentation:** Clear comments in SQL scripts, organized repository structure, and detailed README make this project easy to understand and showcase to potential employers.
- **Real-World Data Handling:** Experience working with messy, realistic datasets, preparing for practical analysis challenges.

