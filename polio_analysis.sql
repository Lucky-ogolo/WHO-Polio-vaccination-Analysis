--create database
    Create database ekiti_polio_analysis;
--create table
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
--data cleaning and exploration
	   Alter table PolioVdata 
	   Alter column vaccination_coverage_pct TYPE NUMERIC(10,2);
-- checking for nulls 
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
-- Note: some vaccination-related columns contain null values,
-- which likely represent missing or unreported data for certain
-- Note: vaccination_coverage_pct contains some values >100 due to reporting errors,these represent anomalies in the original data and are kept intentionally

-- Check for duplicate records by country and year
       select state,report_date, count(*) as record_count
       from poliovdata
       group by state,report_date
       having count(*) > 1;

-- Assign a row number to each record partitioned by state and report_date
       with ranked as (
            select *,
            row_number() over (partition by state,lga,report_date,children_targeted,children_vaccinated order by state) as rn
            from poliovd
        )
         select *
          from ranked
          where rn =2;

-- data analysis

-- Q1. How many total records are in the dataset?
        select count(*) from poliovdata;

-- Q2. How many distinct LGAs are represented in the dataset?
        select distinct lga from poliovdata;

-- Q3. What is the total number of children targeted across all LGAs and dates?
       select report_date, sum(children_targeted) as children_targeted from poliovdata
	   group by report_date;

--Q4. What is the total number of children vaccinated across all LGAs and dates?
       select lga,report_date, sum(children_vaccinated) as children_vaccinated from poliovdata
	   group by lga,report_date;
	   
--Q5. Which vaccination team has the most records in the dataset?
      select vaccination_team,count(*) as records from poliovdata
	  group by vaccination_team
	  order by vaccination_team desc
	  limit 1;
	  
--Q6. What is the average vaccination coverage percentage across all LGAs?
      select lga, round(avg(vaccination_coverage_pct),2) as avg_vacpct from poliovdata
	  group by lga;
	  
--Q7. Which LGA has the highest average vaccination coverage percentage?
      select lga, round(avg(vaccination_coverage_pct),2) as avg_vacpct from poliovdata
	  group by lga
	  order by lga  desc
	  limit 1;
	  
--Q8. Which LGA has the lowest average vaccination coverage percentage?
      select lga, round(avg(vaccination_coverage_pct),2) as avg_vacpct from poliovdata
	  group by lga
	  order by lga  asc
	  limit 1;
	  
--Q9. How many records have vaccination coverage above 100%?
      select count(*) as records from poliovdata
	  where vaccination_coverage_pct>100;
	  
--Q10. How many records belong to each campaign phase (Initial vs Follow-up)?
      select campaign_phase, count(*) as records from poliovdata
	  group by campaign_phase;
	  
--Q11. For each LGA, what is the total number of children targeted vs vaccinated?
      select lga,SUM(
	  CASE WHEN children_targeted IS NOT NULL THEN children_targeted ELSE 0 END)
	  as children_targeted,
      SUM(CASE WHEN children_vaccinated IS NOT NULL THEN children_vaccinated ELSE 0 END)
      as children_vaccinated
	  from poliovdata group by lga;
	  
--Q12. For each vaccination team, calculate the average vaccination coverage percentage.
       select vaccination_team,round(avg(vaccination_coverage_pct),2) as avg_pct 
	   from poliovdata
	   group by vaccination_team;
	   
--Q13. Which LGA has the largest difference between children targeted and children vaccinated?
       select lga,sum(coalesce(children_targeted,0)-coalesce(children_vaccinated,0)) as diff from poliovdata
	   group by lga
	   order by diff desc
	    limit 1;
	  
--Q14. Identify the date with the highest total number of children vaccinated across all LGAs.
        select lga,report_date,sum(coalesce(children_vaccinated,0)) as children_vaccinated from poliovdata
        group by lga,report_date
        order by children_vaccinated desc
       limit 1;
  
--Q15.Rank LGAs by total vaccination coverage percentage and assign a rank number to each.
         select lga,coalesce(sum(vaccination_coverage_pct),0) as vaccine_coverPct,
		 rank()over(partition by lga order by coalesce(sum(vaccination_coverage_pct),0) desc) as rnk
		 from poliovdata 
		 group by lga;

--Q16 . LGAs where coverage consistently stayed below 80%
         select lga
         from poliovdata
         group by lga
         having min(vaccination_coverage_pct) < 80;

--Q17. Vaccination team efficiency (coverage relative to targeted)
         select vaccination_team, sum(children_vaccinated)/sum(children_targeted)*100 as avg_coverage_pct
         from poliovdata
         group by vaccination_team
         order by avg_coverage_pct desc;

--Q18. Proportion of children vaccinated by campaign phase
	     select campaign_phase, sum(children_vaccinated)::decimal / sum(children_targeted)*100 as coverage_pct
         from poliovdata 
         group by campaign_phase;

--Q19. Coverage comparison by weekday
         select extract(DOW from report_date) as weekday,
         avg(vaccination_coverage_pct) as avg_coverage
         from poliovdata
         group by weekday
         order by weekday;

--Q20. LGAs where vaccinated > targeted
         select lga, sum(children_vaccinated - children_targeted) as overreport_total
         from poliovdata
         where children_vaccinated > children_targeted
         group by lga
         order by overreport_total desc;

--Q21. Rank vaccination teams by avg coverage per LGA and campaign phase
         select lga, campaign_phase, vaccination_team,
         rank() over (partition by lga, campaign_phase order by avg(vaccination_coverage_pct) desc) as rank_team,
         avg(vaccination_coverage_pct) as avg_coverage
         from poliovdata
         group by lga, campaign_phase, vaccination_team
         order by lga, campaign_phase, rank_team;

--Q22. Top 3 LGAs with largest gaps between targeted and vaccinated
         select lga, sum(children_targeted - children_vaccinated) as total_gap
         from poliovdata
         group by lga
         order by total_gap desc
         limit 3;

--Q23. Overall campaign metrics per LGA and state-wide,Per LGA
         select lga,
         sum(children_vaccinated) as total_vaccinated,
         sum(children_targeted) as total_targeted,
         sum(children_vaccinated)::decimal / sum(children_targeted)*100 as coverage_pct,
         count(*) filter (where children_vaccinated is null or children_targeted is null) as missing_data_count
         from poliovdata
         group by lga
         order by coverage_pct desc;

--Q24. State-wide
         select sum(children_vaccinated) as total_vaccinated,
         sum(children_targeted) as total_targeted,
         sum(children_vaccinated)::decimal / sum(children_targeted)*100 as coverage_pct,
         count(*) filter (where children_vaccinated is null or children_targeted is null) as missing_data_count
         from poliovdata;

--end of analysis