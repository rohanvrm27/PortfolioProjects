-- Select Queries

USE wc22;
SELECT * FROM wc22.passing_stats;
SELECT * FROM shooting_stats;
SELECT * FROM defensive_stats;
SELECT * FROM gk_stats;
SELECT * FROM team_rankings;
SELECT * FROM wc22.passing_stats2;
SELECT * FROM misc_stats;

-- Bit of exploration
SELECT Player, Pos, One_Third,PrgP / 90s, OneThird_PrgP / 90s FROM passing_stats where 90s >= 5 ORDER BY PrgP / 90s DESC;

-- Add column to passing stats

ALTER TABLE passing_stats ADD COLUMN PrgP_90s int;
UPDATE passing_stats SET PrgP_90s = ROUND(PrgP / 90s, 1);

-- Clean Data --

-- Remove all zero 90s played players from passing stats

DELETE FROM passing_stats WHERE 90s = 0;

-- Clean Country Data for each player

UPDATE team_rankings SET Squad = SUBSTRING_INDEX(Squad," ",-1);
UPDATE defensive_stats SET Squad = REPLACE(Squad, CONCAT(SUBSTRING_INDEX(Squad," ",1)," "), "");
UPDATE passing_stats SET Squad = REPLACE(Squad, CONCAT(SUBSTRING_INDEX(Squad," ",1)," "), "");
UPDATE shooting_stats SET Squad = REPLACE(Squad, CONCAT(SUBSTRING_INDEX(Squad," ",1)," "), "");
UPDATE gk_stats SET Squad = REPLACE(Squad, CONCAT(SUBSTRING_INDEX(Squad," ",1)," "), "");
UPDATE misc_stats SET Squad = REPLACE(Squad, CONCAT(SUBSTRING_INDEX(Squad," ",1)," "), "");

-- Delete from all tables where Country is not top 8 OR player played less than four 90 mins

DELETE FROM defensive_stats WHERE Squad NOT IN (SELECT Squad FROM team_rankings) OR 90s < 4;
DELETE FROM passing_stats WHERE Squad NOT IN (SELECT Squad FROM team_rankings) OR 90s < 4;
DELETE FROM shooting_stats WHERE Squad NOT IN (SELECT Squad FROM team_rankings) OR 90s < 4;
DELETE FROM gk_stats WHERE Squad NOT IN (SELECT Squad FROM team_rankings) OR 90s < 4;

-- Clean Player names with ? in them

UPDATE passing_stats SET Player = REPLACE(Player,"?","c");
UPDATE defensive_stats SET Player = REPLACE(Player,"?","c");
UPDATE shooting_stats SET Player = REPLACE(Player,"?","c");
UPDATE gk_stats SET Player = REPLACE(Player,"?","c");

-- Clean Position Column in all tables

UPDATE passing_stats SET Pos = CASE WHEN LENGTH(Pos) > 2 THEN LEFT(Pos,2) ELSE Pos END;
UPDATE shooting_stats SET Pos = CASE WHEN LENGTH(Pos) > 2 THEN LEFT(Pos,2) ELSE Pos END;
UPDATE defensive_stats SET Pos = CASE WHEN LENGTH(Pos) > 2 THEN LEFT(Pos,2) ELSE Pos END;


-- Create Misc, Top 8 Views and Creator_Scorer Chart Views

CREATE OR REPLACE VIEW TOP8_Passers AS (SELECT a.*, b.Short_Cmp,b.Med_Cmp,b.Long_Cmp, ROUND((b.Short_Cmp + b.Med_Cmp * 1.5 + b.Long_Cmp * 2) / 90s ,2) AS Rk_Metric FROM passing_stats a 
JOIN passing_stats2 b ON a.Rk = b.Rk WHERE a.Pos <> "DF" ORDER BY Rk_Metric DESC LIMIT 8); 

CREATE OR REPLACE VIEW TOP8_Attackers AS (SELECT a.*, b.Ast,b.KP, (a.Gls + b.Ast) AS Rk_Metric FROM shooting_stats a 
JOIN passing_stats b ON a.Rk = b.Rk ORDER BY RkMetric DESC LIMIT 8);

CREATE OR REPLACE VIEW Creator_Scorer AS (SELECT a.*, b.Ast,b.KP, ROUND((2.5 * a.Gls + b.KP) / 90s, 2) AS RkMetric FROM shooting_stats a 
JOIN (SELECT Ast, KP, Rk FROM passing_stats) b ON a.Rk = b.Rk ORDER BY RkMetric DESC LIMIT 20);

CREATE OR REPLACE VIEW TOP8_Defenders AS (SELECT *, ROUND(( Tkl * 0.5 + Blocks + IntC + Clr),2) AS RkMetric FROM defensive_stats ORDER BY RkMetric DESC LIMIT 8);

CREATE OR REPLACE VIEW TOP8_GKs AS (SELECT *, (CS * 10 + Saves) AS RkMetric FROM gk_stats Order by RkMetric DESC);

CREATE OR REPLACE VIEW Misc_view AS (SELECT Squad, MAX(Age) As Age, MAX(MP) AS MP, MAX(tmp.Min) As MinP, MAX(90s) AS Ninety_Played, MAX(Gls) As Goals, Max(Ast) As Assists, Max(CrdY) AS Y_Cards, MAx(CrdR) AS R_Cards, ROUND(AVG(Attendance)) AS Avg_Attendance FROM
(SELECT * FROM attendance_stats a JOIN misc_stats b ON b.Squad = a.Home OR b.Squad = a.Away) tmp GROUP BY Squad ORDER BY Squad);  









