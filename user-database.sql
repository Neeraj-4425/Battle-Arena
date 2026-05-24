-- ================================================
--   BattleArena - Admin Database (SQL Server / T-SQL Version)
--   SQL File for viewing user & registration data
-- ================================================


-- 'model' डेटाबेस के सभी कनेक्शन को जबरन बंद करने के लिए
USE master;
GO
ALTER DATABASE model SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO
ALTER DATABASE model SET MULTI_USER;
GO



-- 1. Create database if it does not exist
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'battlearena')
BEGIN
    CREATE DATABASE battlearena;
END;
GO

USE battlearena;
GO

-- ── TABLE: users ─────────────────────────────────
IF OBJECT_ID('dbo.users', 'U') IS NULL
BEGIN
    CREATE TABLE users (
      id          INT IDENTITY(1,1) PRIMARY KEY,
      first_name  VARCHAR(100) NOT NULL,
      last_name   VARCHAR(100) NOT NULL,
      email       VARCHAR(150) NOT NULL UNIQUE,
      password    VARCHAR(255) NOT NULL,
      fav_game    VARCHAR(100),
      joined_at   DATETIME DEFAULT CURRENT_TIMESTAMP
    );
END;

-- ── TABLE: tournaments ────────────────────────────
IF OBJECT_ID('dbo.tournaments', 'U') IS NULL
BEGIN
    CREATE TABLE tournaments (
      id          INT IDENTITY(1,1) PRIMARY KEY,
      name        VARCHAR(200) NOT NULL,
      game        VARCHAR(100) NOT NULL,
      date        VARCHAR(50),
      format      VARCHAR(150),
      entry_fee   VARCHAR(50),
      prize_pool  VARCHAR(50),
      status      VARCHAR(50) DEFAULT 'open' CHECK (status IN ('open', 'coming_soon')) -- ENUM का विकल्प
    );
END;

-- ── TABLE: registrations ─────────────────────────
IF OBJECT_ID('dbo.registrations', 'U') IS NULL
BEGIN
    CREATE TABLE registrations (
      id              INT IDENTITY(1,1) PRIMARY KEY,
      user_name       VARCHAR(200) NOT NULL,
      email           VARCHAR(150) NOT NULL,
      team_name       VARCHAR(150) NOT NULL,
      ingame_id       VARCHAR(150) NOT NULL,
      tournament_id   INT,
      registered_at   DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (tournament_id) REFERENCES tournaments(id)
    );
END;
GO

-- ── SAMPLE DATA: tournaments ──────────────────────
-- बार-बार रन करने पर डुप्लिकेट डेटा से बचने के लिए जांच
IF NOT EXISTS (SELECT 1 FROM tournaments)
BEGIN
    INSERT INTO tournaments (name, game, date, format, entry_fee, prize_pool, status) VALUES
    ('BGMI Weekly Scrims',       'BGMI',      '15 March 2026', 'Squad (Erangel & Miramar)', 'Free',       '10000',  'open'),
    ('Valorant Pro League',      'Valorant',  '20 March 2026', '5v5 Custom Rooms',          '500/Team',   '50000',  'open'),
    ('Free Fire Clash Squad',    'Free Fire', '25 March 2026', '4v4 Clash Squad',           'Free',       '5000',   'coming_soon'),
    ('BGMI Championship Series', 'BGMI',      '1 April 2026',  'Squad (All Maps)',           '200/Team',   '25000',  'coming_soon'),
    ('COD Mobile Grand Prix',    'COD',       '5 April 2026',  '5v5 Multiplayer',           '300/Team',   '15000',  'open'),
    ('Valorant Rising Stars',    'Valorant',  '10 April 2026', '5v5 Open Qualifier',        'Free',       '8000',   'open');
END;

-- ── SAMPLE DATA: users ────────────────────────────
IF NOT EXISTS (SELECT 1 FROM users)
BEGIN
    INSERT INTO users (first_name, last_name, email, password, fav_game) VALUES
    ('Rahul',   'Kumar',   'rahul@gmail.com',   'rahul123',  'BGMI'),
    ('Priya',   'Sharma',  'priya@gmail.com',   'priya123',  'Valorant'),
    ('Amit',    'Singh',   'amit@gmail.com',    'amit123',   'Free Fire'),
    ('Sneha',   'Verma',   'sneha@gmail.com',   'sneha123',  'BGMI'),
    ('Vikas',   'Yadav',   'vikas@gmail.com',   'vikas123',  'COD'),
    ('Anjali',  'Gupta',   'anjali@gmail.com',  'anjali123', 'Valorant');
END;

-- ── SAMPLE DATA: registrations ────────────────────
IF NOT EXISTS (SELECT 1 FROM registrations)
BEGIN
    INSERT INTO registrations (user_name, email, team_name, ingame_id, tournament_id) VALUES
    ('Rahul Kumar',  'rahul@gmail.com',  'Phoenix Squad',   'RahulBGMI#001',   1),
    ('Priya Sharma', 'priya@gmail.com',  'Storm Riders',    'PriyaVAL#202',    2),
    ('Amit Singh',   'amit@gmail.com',   'Fire Wolves',     'AmitFF#303',      3),
    ('Sneha Verma',  'sneha@gmail.com',  'Phoenix Squad',   'SnehaBGMI#044',   1),
    ('Vikas Yadav',  'vikas@gmail.com',  'COD Legends',     'VikasCoD#555',    5),
    ('Anjali Gupta', 'anjali@gmail.com', 'Storm Riders',    'AnjaliVAL#606',   2);
END;
GO

-- ================================================
--   ADMIN QUERIES — Run these to see data
-- ================================================

-- 1. See ALL registered users
SELECT
  id,
  first_name,
  last_name,
  email,
  fav_game,
  joined_at
FROM users
ORDER BY joined_at DESC;

-- 2. See ALL tournament registrations with tournament name
SELECT
  r.id,
  r.user_name,
  r.email,
  r.team_name,
  r.ingame_id,
  t.name        AS tournament_name,
  t.game,
  t.prize_pool,
  r.registered_at
FROM registrations r
JOIN tournaments t ON r.tournament_id = t.id
ORDER BY r.registered_at DESC;

-- 3. Count how many players registered per tournament
-- SQL Server में GROUP BY क्लॉज में उन सभी कॉलम्स को लिखना जरूरी है जो SELECT में हैं
SELECT
  t.name        AS tournament_name,
  t.game,
  t.prize_pool,
  COUNT(r.id)   AS total_registrations
FROM tournaments t
LEFT JOIN registrations r ON t.id = r.tournament_id
GROUP BY t.id, t.name, t.game, t.prize_pool
ORDER BY total_registrations DESC;

-- 4. See which tournaments a specific user registered for
SELECT
  r.user_name,
  r.team_name,
  t.name   AS tournament,
  t.game,
  r.registered_at
FROM registrations r
JOIN tournaments t ON r.tournament_id = t.id
WHERE r.email = 'rahul@gmail.com';

-- 5. See all users with their favourite game count
SELECT
  fav_game,
  COUNT(*) AS total_users
FROM users
GROUP BY fav_game
ORDER BY total_users DESC;

-- 6. See full user details + all their registrations
SELECT
  u.id,
  u.first_name,
  u.last_name,
  u.email,
  u.fav_game,
  u.joined_at,
  COUNT(r.id) AS tournaments_joined
FROM users u
LEFT JOIN registrations r ON u.email = r.email
GROUP BY u.id, u.first_name, u.last_name, u.email, u.fav_game, u.joined_at
ORDER BY tournaments_joined DESC;
GO
