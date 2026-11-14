#!/bin/bash

set -e

sqlite3 movies_rating.db < db_init.sql

echo "1. Для каждого фильма вывести название, год выпуска и средний рейтинг. Добавить ранг фильма по убыванию среднего рейтинга с помощью RANK(). Оставить 10 фильмов с наивысшим рейтингом."
echo "--------------------------------------------------"

sqlite3 movies_rating.db -box -echo "
WITH movie_avg AS (
    SELECT
        m.id,
        m.title,
        m.year,
        AVG(r.rating) AS avg_rating
    FROM movies AS m
    JOIN ratings AS r ON r.movie_id = m.id
    GROUP BY m.id, m.title, m.year
),
ranked_movies AS (
    SELECT
        title,
        year,
        avg_rating,
        RANK() OVER (ORDER BY avg_rating DESC) AS rank_by_avg_rating
    FROM movie_avg
)
SELECT
    title,
    year,
    ROUND(avg_rating, 2) AS avg_rating,
    rank_by_avg_rating
FROM ranked_movies
ORDER BY rank_by_avg_rating, title
LIMIT 10;
"

echo " "

echo "2. С помощью рекурсивного CTE выделить все жанры фильмов. Для каждого жанра рассчитать средний рейтинг и ранг по убыванию среднего рейтинга."
echo "--------------------------------------------------"

sqlite3 movies_rating.db -box -echo "
WITH RECURSIVE genre_split(movie_id, genre, rest) AS (
    SELECT
        id,
        '',
        genres || '|'
    FROM movies
    WHERE genres IS NOT NULL
      AND genres <> ''

    UNION ALL

    SELECT
        movie_id,
        substr(rest, 1, instr(rest, '|') - 1),
        substr(rest, instr(rest, '|') + 1)
    FROM genre_split
    WHERE rest <> ''
),
genre_avg AS (
    SELECT
        gs.genre,
        AVG(r.rating) AS avg_rating
    FROM genre_split AS gs
    JOIN ratings AS r ON r.movie_id = gs.movie_id
    WHERE gs.genre <> ''
      AND gs.genre <> '(no genres listed)'
    GROUP BY gs.genre
)
SELECT
    genre,
    ROUND(avg_rating, 3) AS avg_rating,
    RANK() OVER (ORDER BY avg_rating DESC) AS genre_rank
FROM genre_avg
ORDER BY genre_rank, genre;
"

echo " "

echo "3. Посчитать количество фильмов в каждом жанре. Вывести жанр и количество фильмов, отсортировать по убыванию количества."
echo "--------------------------------------------------"

sqlite3 movies_rating.db -box -echo "
WITH RECURSIVE genre_split(movie_id, genre, rest) AS (
    SELECT
        id,
        '',
        genres || '|'
    FROM movies
    WHERE genres IS NOT NULL
      AND genres <> ''

    UNION ALL

    SELECT
        movie_id,
        substr(rest, 1, instr(rest, '|') - 1),
        substr(rest, instr(rest, '|') + 1)
    FROM genre_split
    WHERE rest <> ''
)
SELECT
    genre,
    COUNT(DISTINCT movie_id) AS movie_count
FROM genre_split
WHERE genre <> ''
  AND genre <> '(no genres listed)'
GROUP BY genre
ORDER BY movie_count DESC, genre;
"

echo " "

echo "4. Найти жанры, в которых чаще всего оставляют теги. Вывести жанр, количество тегов и долю жанра в общем числе тегов в процентах."
echo "--------------------------------------------------"

sqlite3 movies_rating.db -box -echo "
WITH RECURSIVE genre_split(movie_id, genre, rest) AS (
    SELECT
        id,
        '',
        genres || '|'
    FROM movies
    WHERE genres IS NOT NULL
      AND genres <> ''

    UNION ALL

    SELECT
        movie_id,
        substr(rest, 1, instr(rest, '|') - 1),
        substr(rest, instr(rest, '|') + 1)
    FROM genre_split
    WHERE rest <> ''
),
genre_tag_counts AS (
    SELECT
        gs.genre,
        COUNT(t.id) AS tag_count
    FROM (
        SELECT DISTINCT movie_id, genre
        FROM genre_split
        WHERE genre <> ''
          AND genre <> '(no genres listed)'
    ) AS gs
    LEFT JOIN tags AS t ON t.movie_id = gs.movie_id
    GROUP BY gs.genre
)
SELECT
    genre,
    tag_count,
    ROUND(
        tag_count * 100.0 / NULLIF((SELECT COUNT(*) FROM tags), 0),
        2
    ) AS tag_share
FROM genre_tag_counts
ORDER BY tag_count DESC, genre;
"

echo " "

echo "5. Для каждого пользователя рассчитать количество оценок, средний рейтинг, дату первой и последней оценки. Вывести первые 10 пользователей по количеству оценок."
echo "--------------------------------------------------"

sqlite3 movies_rating.db -box -echo "
SELECT
    u.id AS user_id,
    COUNT(r.id) AS rating_count,
    ROUND(AVG(r.rating), 2) AS avg_rating,
    date(MIN(r.timestamp), 'unixepoch') AS first_rating_date,
    date(MAX(r.timestamp), 'unixepoch') AS last_rating_date
FROM users AS u
LEFT JOIN ratings AS r ON r.user_id = u.id
GROUP BY u.id
ORDER BY rating_count DESC, u.id
LIMIT 10;
"

echo " "

echo "6. Сегментировать пользователей по количеству оценок и тегов. Категории: Комментаторы, Оценщики, Активные и Пассивные. Использовать CASE."
echo "--------------------------------------------------"

sqlite3 movies_rating.db -box -echo "
WITH rating_counts AS (
    SELECT
        user_id,
        COUNT(*) AS rating_count
    FROM ratings
    GROUP BY user_id
),
tag_counts AS (
    SELECT
        user_id,
        COUNT(*) AS tag_count
    FROM tags
    GROUP BY user_id
),
user_activity AS (
    SELECT
        u.id AS user_id,
        COALESCE(rc.rating_count, 0) AS rating_count,
        COALESCE(tc.tag_count, 0) AS tag_count
    FROM users AS u
    LEFT JOIN rating_counts AS rc ON rc.user_id = u.id
    LEFT JOIN tag_counts AS tc ON tc.user_id = u.id
)
SELECT
    user_id,
    rating_count,
    tag_count,
    CASE
        WHEN rating_count >= 10 AND tag_count >= 10
            THEN 'Активные'
        WHEN rating_count < 5 AND tag_count < 5
            THEN 'Пассивные'
        WHEN tag_count > rating_count
            THEN 'Комментаторы'
        WHEN rating_count > tag_count
            THEN 'Оценщики'
        ELSE 'Без категории'
    END AS behavior_category
FROM user_activity
ORDER BY user_id;
"

echo " "

echo "7. Для каждого пользователя вывести его имя и последний оценённый фильм. Пользователей без оценок также включить в результат."
echo "--------------------------------------------------"

sqlite3 movies_rating.db -box -echo "
WITH ranked_ratings AS (
    SELECT
        r.user_id,
        r.movie_id,
        r.timestamp,
        ROW_NUMBER() OVER (
            PARTITION BY r.user_id
            ORDER BY r.timestamp DESC, r.id DESC
        ) AS rn
    FROM ratings AS r
)
SELECT
    u.id AS user_id,
    u.name,
    m.title AS last_rated_movie_title,
    rr.timestamp AS last_rating_timestamp
FROM users AS u
LEFT JOIN ranked_ratings AS rr
    ON rr.user_id = u.id
   AND rr.rn = 1
LEFT JOIN movies AS m
    ON m.id = rr.movie_id
ORDER BY u.id;
"

echo " "
