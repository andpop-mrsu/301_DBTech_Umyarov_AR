PRAGMA foreign_keys = ON;

BEGIN TRANSACTION;

INSERT INTO users (
    first_name,
    last_name,
    email,
    gender,
    occupation_id
)
SELECT
    'Stanislav',
    'Serov',
    'stanislav.serov@example.com',
    'male',
    id
FROM occupations
WHERE occupation_name = 'student'
  AND NOT EXISTS (
      SELECT 1
      FROM users
      WHERE email = 'stanislav.serov@example.com'
  );

INSERT INTO users (
    first_name,
    last_name,
    email,
    gender,
    occupation_id
)
SELECT
    'Alexander',
    'Smirnov',
    'alexander.smirnov@example.com',
    'male',
    id
FROM occupations
WHERE occupation_name = 'student'
  AND NOT EXISTS (
      SELECT 1
      FROM users
      WHERE email = 'alexander.smirnov@example.com'
  );

INSERT INTO users (
    first_name,
    last_name,
    email,
    gender,
    occupation_id
)
SELECT
    'Arslan',
    'Umyarov',
    'arslan.umyarov@example.com',
    'male',
    id
FROM occupations
WHERE occupation_name = 'student'
  AND NOT EXISTS (
      SELECT 1
      FROM users
      WHERE email = 'arslan.umyarov@example.com'
  );

INSERT INTO users (
    first_name,
    last_name,
    email,
    gender,
    occupation_id
)
SELECT
    'Maxim',
    'Tsvetkov',
    'maxim.tsvetkov@example.com',
    'male',
    id
FROM occupations
WHERE occupation_name = 'student'
  AND NOT EXISTS (
      SELECT 1
      FROM users
      WHERE email = 'maxim.tsvetkov@example.com'
  );

INSERT INTO users (
    first_name,
    last_name,
    email,
    gender,
    occupation_id
)
SELECT
    'Maxim',
    'Shaposhnikov',
    'maxim.shaposhnikov@example.com',
    'male',
    id
FROM occupations
WHERE occupation_name = 'student'
  AND NOT EXISTS (
      SELECT 1
      FROM users
      WHERE email = 'maxim.shaposhnikov@example.com'
  );

INSERT INTO movies (title, year)
SELECT 'Oppenheimer', 2023
WHERE NOT EXISTS (
    SELECT 1
    FROM movies
    WHERE title = 'Oppenheimer' AND year = 2023
);

INSERT INTO movies (title, year)
SELECT 'The Gentlemen', 2019
WHERE NOT EXISTS (
    SELECT 1
    FROM movies
    WHERE title = 'The Gentlemen' AND year = 2019
);

INSERT INTO movies (title, year)
SELECT 'King Arthur: Legend of the Sword', 2017
WHERE NOT EXISTS (
    SELECT 1
    FROM movies
    WHERE title = 'King Arthur: Legend of the Sword' AND year = 2017
);

INSERT INTO movie_genres (movie_id, genre_id)
SELECT m.id, g.id
FROM movies AS m
JOIN genres AS g ON g.genre_name = 'Drama'
WHERE m.title = 'Oppenheimer'
  AND m.year = 2023
  AND NOT EXISTS (
      SELECT 1
      FROM movie_genres AS mg
      WHERE mg.movie_id = m.id AND mg.genre_id = g.id
  );

INSERT INTO movie_genres (movie_id, genre_id)
SELECT m.id, g.id
FROM movies AS m
JOIN genres AS g ON g.genre_name = 'Crime'
WHERE m.title = 'The Gentlemen'
  AND m.year = 2019
  AND NOT EXISTS (
      SELECT 1
      FROM movie_genres AS mg
      WHERE mg.movie_id = m.id AND mg.genre_id = g.id
  );

INSERT INTO movie_genres (movie_id, genre_id)
SELECT m.id, g.id
FROM movies AS m
JOIN genres AS g ON g.genre_name = 'Comedy'
WHERE m.title = 'The Gentlemen'
  AND m.year = 2019
  AND NOT EXISTS (
      SELECT 1
      FROM movie_genres AS mg
      WHERE mg.movie_id = m.id AND mg.genre_id = g.id
  );

INSERT INTO movie_genres (movie_id, genre_id)
SELECT m.id, g.id
FROM movies AS m
JOIN genres AS g ON g.genre_name = 'Adventure'
WHERE m.title = 'King Arthur: Legend of the Sword'
  AND m.year = 2017
  AND NOT EXISTS (
      SELECT 1
      FROM movie_genres AS mg
      WHERE mg.movie_id = m.id AND mg.genre_id = g.id
  );

INSERT INTO movie_genres (movie_id, genre_id)
SELECT m.id, g.id
FROM movies AS m
JOIN genres AS g ON g.genre_name = 'Action'
WHERE m.title = 'King Arthur: Legend of the Sword'
  AND m.year = 2017
  AND NOT EXISTS (
      SELECT 1
      FROM movie_genres AS mg
      WHERE mg.movie_id = m.id AND mg.genre_id = g.id
  );

INSERT INTO movie_genres (movie_id, genre_id)
SELECT m.id, g.id
FROM movies AS m
JOIN genres AS g ON g.genre_name = 'Fantasy'
WHERE m.title = 'King Arthur: Legend of the Sword'
  AND m.year = 2017
  AND NOT EXISTS (
      SELECT 1
      FROM movie_genres AS mg
      WHERE mg.movie_id = m.id AND mg.genre_id = g.id
  );

INSERT INTO ratings (user_id, movie_id, rating)
SELECT u.id, m.id, 4.5
FROM users AS u
JOIN movies AS m
    ON m.title = 'Oppenheimer' AND m.year = 2023
WHERE u.email = 'arslan.umyarov@example.com'
  AND NOT EXISTS (
      SELECT 1
      FROM ratings AS r
      WHERE r.user_id = u.id AND r.movie_id = m.id
  );

INSERT INTO ratings (user_id, movie_id, rating)
SELECT u.id, m.id, 5.0
FROM users AS u
JOIN movies AS m
    ON m.title = 'The Gentlemen' AND m.year = 2019
WHERE u.email = 'arslan.umyarov@example.com'
  AND NOT EXISTS (
      SELECT 1
      FROM ratings AS r
      WHERE r.user_id = u.id AND r.movie_id = m.id
  );

INSERT INTO ratings (user_id, movie_id, rating)
SELECT u.id, m.id, 4.0
FROM users AS u
JOIN movies AS m
    ON m.title = 'King Arthur: Legend of the Sword' AND m.year = 2017
WHERE u.email = 'arslan.umyarov@example.com'
  AND NOT EXISTS (
      SELECT 1
      FROM ratings AS r
      WHERE r.user_id = u.id AND r.movie_id = m.id
  );

COMMIT;
