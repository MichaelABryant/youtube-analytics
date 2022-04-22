-- view entire metrics by country, video, and subscribed table
SELECT *
FROM dbo.Aggregated_Metrics_By_Country_A$;

-- create view to see totals/average by country and subscribed
CREATE VIEW metrics_total_by_country_subscribed AS
SELECT country_code, is_subscribed,
		SUM([views]) AS total_views,
		SUM(video_likes_added) AS total_likes_added,
		SUM(video_dislikes_added) AS total_dislikes_added,
		SUM(video_likes_removed) AS total_likes_removed,
		SUM(user_subscriptions_added) AS total_user_subscriptions_added,
		SUM(user_subscriptions_removed) AS total_user_subscriptions_removed,
		AVG(average_view_percentage) AS average_percentage_of_videos_clicked_on_watched
FROM dbo.Aggregated_Metrics_By_Country_A$
GROUP BY country_code, is_subscribed;

-- subscriptions per country
SELECT country_code, total_user_subscriptions_added - total_user_subscriptions_removed AS net_subscriptions
FROM metrics_total_by_country_subscribed;

-- total subscriptions
WITH subs_per_country AS
(SELECT country_code, total_user_subscriptions_added - total_user_subscriptions_removed AS net_subscriptions
FROM metrics_total_by_country_subscribed)
SELECT SUM(net_subscriptions) AS total_subscriptions
FROM subs_per_country;

-- display table of metrics by video
SELECT *
FROM dbo.Aggregated_Metrics_By_Video$;

-- total revenue
SELECT SUM(estimated_revenue_usd) AS total_revenue
FROM dbo.Aggregated_Metrics_By_Video$;

-- likes to dislikes ratio
SELECT video_id, video_title, likes-dislikes AS net_likes
FROM dbo.Aggregated_Metrics_By_Video$
WHERE YEAR(video_publish_time) = 2021
ORDER BY net_likes DESC;

-- display table with all comments
SELECT *
FROM dbo.All_Comments_Final$;

-- display table with video performance over time
SELECT *
FROM dbo.Video_Performance_Over_Time$;

-- running totals by video
SELECT [date], video_id, video_title,
	SUM([views]) OVER (PARTITION BY video_id ORDER BY [date] ASC) AS running_total_views,
	SUM(video_likes_added) OVER (PARTITION BY video_id ORDER BY [date] ASC) AS running_total_likes_added,
	SUM(video_dislikes_added) OVER (PARTITION BY video_id ORDER BY [date] ASC) AS running_total_dislikes_added,
	SUM(user_subscriptions_added) OVER (PARTITION BY video_id ORDER BY [date] ASC) AS running_total_subscriptions_added,
	SUM(user_subscriptions_removed) OVER (PARTITION BY video_id ORDER BY [date] ASC) AS running_total_subscriptions_removed
FROM dbo.Video_Performance_Over_Time$;


-- join comments with video performance over time to count comments over time

-- first count comments per day from comments table then join

WITH comment_counts AS
(SELECT [date], video_id, COUNT(comment_id) AS comment_cnt
FROM dbo.All_Comments_Final$
GROUP BY [date], video_id),

joined_comment_cnt AS
(SELECT vpot.[date], vpot.video_id, cc.comment_cnt AS comments_per_day
FROM dbo.Video_Performance_Over_Time$ vpot
JOIN comment_counts cc
	ON vpot.video_id = cc.video_id
	AND YEAR(vpot.date) = YEAR(cc.date)
	AND MONTH(vpot.date) = MONTH(cc.date)
	AND DAY(vpot.date) = DAY(cc.date))

SELECT *,
	SUM(comments_per_day) OVER (PARTITION BY video_id ORDER BY [date] ASC) AS running_total_comments
FROM joined_comment_cnt;