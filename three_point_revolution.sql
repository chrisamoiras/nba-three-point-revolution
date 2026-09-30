-- ============================================================
-- The 3-Point Revolution in the NBA
-- Database: nba.sqlite (Kaggle: wyattowalsh/basketball)
-- Scope: regular-season games only
-- ============================================================


-- 0. Data check: games per season and missing 3-point stats
SELECT CAST(substr(season_id, 2) AS INT) AS season,
       COUNT(*) AS games,
       SUM(CASE WHEN fg3a_home IS NULL THEN 1 ELSE 0 END) AS missing_3pt
FROM game
WHERE season_type = 'Regular Season'
GROUP BY season
ORDER BY season;


-- 1. Season-level trends  ->  seasons.csv
WITH team_games AS (
  SELECT season_id, fga_home AS fga, fg3a_home AS fg3a, fg3m_home AS fg3m, pts_home AS pts
  FROM game WHERE season_type = 'Regular Season'
  UNION ALL
  SELECT season_id, fga_away, fg3a_away, fg3m_away, pts_away
  FROM game WHERE season_type = 'Regular Season'
)
SELECT CAST(substr(season_id, 2) AS INT)            AS season,
       ROUND(AVG(fg3a), 1)                          AS three_pa_per_game,
       ROUND(AVG(fg3m), 1)                          AS three_pm_per_game,
       ROUND(100.0 * SUM(fg3m) / SUM(fg3a), 1)      AS three_pct,
       ROUND(100.0 * SUM(fg3a) / SUM(fga), 1)       AS share_of_shots_3pt,
       ROUND(100.0 * SUM(3 * fg3m) / SUM(pts), 1)   AS share_of_points_3pt
FROM team_games
WHERE fg3a IS NOT NULL AND CAST(substr(season_id, 2) AS INT) >= 1979
GROUP BY season
ORDER BY season;


-- 2. Made 3-pointers per team-season  ->  3pts_made.csv
WITH team_games AS (
  SELECT season_id, team_abbreviation_home AS team, fg3m_home AS fg3m FROM game WHERE season_type = 'Regular Season'
  UNION ALL
  SELECT season_id, team_abbreviation_away, fg3m_away FROM game WHERE season_type = 'Regular Season'
)
SELECT CAST(substr(season_id, 2) AS INT) AS season, team,
       ROUND(AVG(fg3m), 1) AS three_pm_per_game
FROM team_games
WHERE fg3m IS NOT NULL
GROUP BY season, team
ORDER BY three_pm_per_game DESC;


-- 3. Does the team with more made threes win?  ->  Does_3pt_win_games.csv
SELECT CAST(substr(season_id, 2) AS INT) AS season,
       ROUND(100.0 * AVG(CASE
         WHEN (fg3m_home > fg3m_away AND wl_home = 'W')
           OR (fg3m_away > fg3m_home AND wl_home = 'L') THEN 1.0 ELSE 0 END), 1)
         AS pct_team_with_more_3s_won
FROM game
WHERE season_type = 'Regular Season'
  AND fg3m_home IS NOT NULL AND fg3m_home <> fg3m_away
GROUP BY season
ORDER BY season;
