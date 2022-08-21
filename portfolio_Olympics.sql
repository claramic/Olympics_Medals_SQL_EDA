-- datasets = Countries Olympics Medals since 1896
select * from portfolio.dbo.olympics

-- Is there any duplicated countries in the dataset ? 
select count(distinct countries) as distinct_countries
	, count(countries) as total_countries 
from portfolio.dbo.olympics

-- How many countries participated? 
select count(distinct countries) from portfolio.dbo.olympics

-- Top 10 Countries in terms of nb of participation : 
-- All seasons 
select top 10 countries 
		, total_participation
from portfolio.dbo.olympics 
order by 2 desc

-- Summer 
select top 10 countries 
		, summer_participations
from portfolio.dbo.olympics 
order by total_participation desc

-- Winter
select top 10 countries 
		, winter_participations
from portfolio.dbo.olympics 
order by total_participation desc

-- Do some countries prefer to participate in a specific season ? 
-- (focus on countries who participated at least 10 times)
select countries
	, total_participation
	, round(winter_participations/total_participation,2)*100 as winter_participation_percentage
	, round(abs(0.5-(winter_participations/total_participation)),2) as distance_score
from portfolio.dbo.olympics
where total_participation>10
order by 4 desc

/*
Interpretation : 
The calculation of the winter_participation_percentage gives each country's percentage of Winter participations, among all their 
participations. The closest it is to 50%, the more their participations are well distributed between Winter and Summer.
To be able to rank with the most uneven countries on top, not matter if they prefer winter or summer, we calculate a distance score. 
The highest the distance_score is, the more the country shows a preference for a specific season. 

At first sight, it seems that the countries attending the Winter Olympics also attend the Summer Olympics, and that quite a lot of countries 
prefer to participate only in Summer.
Let's validate that :
*/

with calculations as
					(select countries
						, total_participation
						, round(winter_participations/total_participation,2)*100 as winter_participation_percentage
						, round(abs(0.5-(winter_participations/total_participation)),2) as distance_score
					from portfolio.dbo.olympics
					where total_participation>10)
select		case when winter_participation_percentage>=55.0 then 'Winter Appetent'  
			when winter_participation_percentage<=45.0 then 'Summer Appetent'  
			else 'No preference'
			end as season_appetency
			, count(countries) as nb_countries
			, round(avg(distance_score),2) as avg_distance_score
from calculations 
group by case when winter_participation_percentage>=55.0 then 'Winter Appetent'  
			when winter_participation_percentage<=45.0 then 'Summer Appetent'  
			else 'No preference'
			end

/*
If we define as "Summer Appetent" the countries which participated in Winter less than 45% of their total partipations, 
and "Winter Appetent" those which participated in Winter more than 55% of the time, we notice that most of the countries are "Summer Appetent".
Also, the average distance score of the Summer Appetents is 84% more important than among the Winter Appetent. In other words, the Summer Appentents 
show a stronger appetency for this season, than the Winter Appetents do for Winter.
What can explain that ? Find answer in another dataset ?  est ce que c'est parce que le summer olympics 
est plus attrayant (mediatisation, popularité?) ? parce que les climats favorables aux sports d'hiver sont plus rares parmi les pays participants ? 
*/

-- Repartition of countries per nb of medals won : 

-- Let's find out in which country do we find the best athletes.
-- To do so, we will calculate, for each country, the number of medals won per participation.

-- Cleaning step : Medals counts are using a coma as mille separator. Thus, we have to remove it : 
create view clean_olympics as
select countries
		, total_participation
		, summer_participations
		, winter_participations
		,  try_cast(replace(total_total, '.', '') as integer) as total_total
		,  try_cast(replace(summer_total, '.', '') as integer) as summer_total
		,  try_cast(replace(winter_total, '.', '') as integer) as winter_total
		,  try_cast(replace(total_gold, '.', '') as integer) as total_gold
		,  try_cast(replace(summer_gold, '.', '') as integer) as summer_gold
		,  try_cast(replace(winter_gold, '.', '') as integer) as winter_gold
		,  try_cast(replace(total_silver, '.', '') as integer) as total_silver
		,  try_cast(replace(summer_silver, '.', '') as integer) as summer_silver
		,  try_cast(replace(winter_silver, '.', '') as integer) as winter_silver
		,  try_cast(replace(total_bronze, '.', '') as integer) as total_bronze
		,  try_cast(replace(summer_bronze, '.', '') as integer) as summer_bronze
		,  try_cast(replace(winter_bronze, '.', '') as integer) as winter_bronze
from portfolio.dbo.olympics 
where total_participation>10 

-- Countries ranking, in terms of total medals won per participation :
with calculation as (select countries
				, total_participation
				, round(total_total/total_participation, 2) as total_medals_per_participation
			from clean_olympics
			where total_participation>10)
select countries
	, total_participation
	, total_medals_per_participation
	, rank() over (order by total_medals_per_participation desc) as rank_medals
from calculation


-- Do we get a similar ranking in each season ? 
-- Summer
select top 10 countries
	, summer_participations
	, round(summer_total/summer_participations, 2) as total_medals_per_participation
from clean_olympics
where summer_participations>10
order by 3 desc

-- Winter
select top 10 countries
	, winter_participations
	, round(winter_total/winter_participations, 2) as total_medals_per_participation
from clean_olympics
where winter_participations>10
order by 3 desc

-- Overall champion = Sovietic Union 
-- Summer champion = USA
-- Winter champion = Germany 

/*
-- In this ranking, the repartition of the total medals between the different levels (gold, silver, bronze) is not considered.
However, winning 50 bronze medals and 1 gold is not the same as winning 52 gold medals.
Let's add this new criteria to the ranking. 

To do so, we will attribute a weight to each medal level, and then calculate, for each country, their overall score.
Gold = 0.5
Silver = 0.3
Bronze = 0.2
*/

select countries
		, total_gold*0.5 + total_silver*0.3 + total_bronze*0.2 as medal_score
		, (total_gold*0.5 + total_silver*0.3 + total_bronze*0.2)/total_participation as medal_score_per_participation
		, rank() over (order by (total_gold*0.5 + total_silver*0.3 + total_bronze*0.2)/total_participation desc) as rank_with_score
		, rank() over (order by total_total/total_participation desc) as rank_no_score
		, rank() over (order by total_gold/total_participation desc) as rank_only_gold
		, rank() over (order by total_silver/total_participation desc) as rank_only_silver
		, rank() over (order by total_bronze/total_participation desc) as rank_only_bronze
from clean_olympics
order by 3 desc

/*
Among the Top 10 countries, the rank_with_score and the rank_no_score are the same, giving a weight to the different level of medals 
doesn't impact the ranking.
It means that the Top 10 most performing countries in terms of nb of medals won per participation are also those winning the more Gold medals.





