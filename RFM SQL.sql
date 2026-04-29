use rfm;
                      -- CREATING CLEANED COMBINED RETAILS TABLE --
drop table retails;
create table Retails as 
select * from retails_1  where Invoice not like 'C%' and Customer_ID !='' and Customer_id is not null and Quantity>0 and Price>0
union all select * from retails_2 where Invoice not like 'C%' and Customer_ID !='' and Customer_id is not null and Quantity>0 and Price>0;

  -- RECENCY --

create view Recency as
select customer_id,timestampdiff(day,max(invoice_date),'2011-12-09') as recency from retails group by customer_id;

-- FREQUENCY --

create view frequency as
select customer_id,count(distinct(invoice)) as Frequency from retails group by Customer_id;

 -- MONETARY --

create view monetary as
select customer_id,sum(quantity*price) as Monetary from retails group by customer_id;

      -- SCORES --

create view R_score as
select *,ntile(5) over (order by recency desc) as R_Score from Recency;

create view F_score as
select *, ntile(5) over(order by frequency) as F_Score from Frequency;

create view M_score as
select * , ntile(5) over(order by monetary) as M_Score from Monetary;

create view RFM_score as
select r.customer_id,r.recency,r.r_score,f.frequency,f.f_score,m.monetary,m.m_score,concat(R_score,F_score,M_score) as RFM_score from 
R_score r inner join F_score f on r.customer_id=f.customer_id inner join m_score m on f.customer_id=m.customer_id;

-- CUSTOMER SEGMENTS --

create view customer_segments as
select customer_id,recency,r_score,frequency,f_score,monetary,m_score,rfm_score,
case when r_score=5 and f_score>=4 and m_score>=4 then 'Champion' 
	 when r_score>=4 and f_score>=4 then 'Loyal Customer'
     when r_score>=4 and f_score in (2,3) then 'Potential Loyalist'
     when r_score=5 and f_score=1 then 'New Customers' 
     when r_score=4 and f_score=1 then 'Promising'
     when r_score=3 then 'Need Attention'
     when r_score<=2 and f_score>=3 then 'At Risk'
     when r_score=1 and f_score=1 then 'Lost' 
     when r_score<=2 and f_score<=2 then 'Hibernating'
     else 'Uncategorised'end as Segments from RFM_Score ;


 -- SEGMENT DISTRIBUTION --

create view Segment_Distribution as
select segments,count(customer_id)  as customer_count,
round(count(customer_id)*100/sum(count(customer_id)) over(),2) as Customers_pct from customer_segments group by segments order by customer_count desc;
-- Champion (12.52%) and Loyal Customers (12.56%) are valuable segments,but their count is moderate, so the company should focus on increasing these high-value customers --
-- Hibernating (17.25%) and Lost (8.74%) together form a large group (~26%),which indicates many customers are inactive and needs attention --
-- At Risk customers (3.86%) are low,which is a positive sign. Need Attention (7.79%) and Potential Loyalists(12.11%) segments are also good and should be focused to improve retention --
-- Overall,the business is stable,but should focus on converting potential customers into loyal ones and retain inactive customers to improve growth --

-- AVERAGE OF R,F,M SCORES ACROSS SEGMENTS --

create view Segments_AvgScore as
select segments,round(avg(r_score),2) as avg_r,round(avg(f_score),2) as avg_f,round(avg(m_score),2) as avg_m from customer_segments group by segments;
-- New customers and Promising customers have high recency score but very low frequency and monetary , which means they are new and they need to be encouraged --
--  At Risk Customers have very low recency but have good frequency and monetary scores, which mens they were good customers but now inactive,they should be targeted to come back --

-- REVENUE BY SEGMENT --

create view Segment_Revenue as
select segments,sum(rs.monetary) as Total_Revenue from rfm_score rs join customer_segments c on rs.customer_id=c.customer_id group by segments order by Total_Revenue desc;
-- Champions generating very high revenue to the business ,even though they are moderate sized customer group --
-- At Risk customers also contributing significant revenue , so they need to be prioritized to retain --

--  TOP 10 CUSTOMERS BY REVENUE --

create view Top10_Revenue_Customers as
select customer_id,rfm_score,Monetary as Revenue from rfm_score order by monetary desc limit 10;
-- Top 10 customers spent much more than average customers --
-- These customers have high RFM scores , which confirms that RFM segmentation working as expected --
-- These customers should be retained with special efforts --

-- COUNTRY WISE DISTRIBUTION --

create  view Country_wise as
select country,count(distinct(customer_id)) as Total_customers,sum(price*quantity) as Revenue from retails group by country order by total_customers desc;
-- United Kingdom has the high number of customers as it is UK based retailer --
-- European countries showing decent customer count compared to others --
-- Australia show good customer count outside of the Europe --

-- CHURN VS ACTIVE STATUS SEGMENT--

create view Churn_Active_ as
select case when recency>365 then 'Churn' else 'Active' end as Status_ ,count(customer_id) as Total_Customers,
round(count(customer_id)*100/sum(count(customer_id)) over() ,2) as Customer_pct,sum(monetary) as Revenue from RFM_Score group by Status_;
-- Customers who have not purchased in over a year are considered as Churned, they are about 27% which is quite high ---
-- It is high concern for the business, retailer should focus on re-engaging these customers,espicially high valu ones first --

               

