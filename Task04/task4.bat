#!/bin/bash

sqlite3 movies_rating.db < db_init.sql

echo "1. Найти все пары пользователей, оценивших один и тот же фильм. Устранить дубликаты, проверить отсутствие пар с самими собой. Для каждой пары указать имена пользователей и название фильма. В списке оставить первые 100 записей."
echo "--------------------------------------------------"

sqlite3 movies_rating.db -box -echo "
SELECT DISTINCT
    u1.name AS user_1,
    u2.name AS user_2,
    m.title AS movie
FROM ratings AS r1
JOIN ratings AS r2
    ON r1.movie_id = r2.movie_id
   AND r1.user_id < r2.user_id
JOIN users AS u1 ON u1.id = r1.user_id
JOIN users AS u2 ON u2.id = r2.user_id
JOIN movies AS m ON m.id = r1.movie_id
ORDER BY m.title, u1.name, u2.name
LIMIT 100;
"
echo " "

echo "2. Найти 10 самых старых оценок от разных пользователей, вывести названия фильмов, имена пользователей, оценку, дату отзыва в формате ГГГГ-ММ-ДД."
echo "--------------------------------------------------"

sqlite3 movies_rating.db -box -echo "
WITH ranked_ratings AS (
    SELECT
        r.user_id,
        r.movie_id,
        r.rating,
        r.timestamp,
        ROW_NUMBER() OVER (
            PARTITION BY r.user_id
            ORDER BY r.timestamp, r.id
        ) AS rn
    FROM ratings AS r
)
SELECT
    m.title AS movie,
    u.name AS user,
    rr.rating,
    date(rr.timestamp, 'unixepoch') AS rating_date
FROM ranked_ratings AS rr
JOIN movies AS m ON m.id = rr.movie_id
JOIN users AS u ON u.id = rr.user_id
WHERE rr.rn = 1
ORDER BY rr.timestamp
LIMIT 10;
"
echo " "

echo "3. Вывести в одном списке все фильмы с максимальным средним рейтингом и все фильмы с минимальным средним рейтингом. Общий список отсортировать по году выпуска и названию фильма. В зависимости от рейтинга в колонке Рекомендуем для фильмов должно быть написано Да или Нет."
echo "--------------------------------------------------"

sqlite3 movies_rating.db -box -echo "
WITH movie_avg AS (
    SELECT
        m.id,
        m.title,
        m.year,
        AVG(r.rating) AS avg_rating
    FROM movies AS m
    JOIN ratings AS r ON m.id = r.movie_id
    GROUP BY m.id, m.title, m.year
),
rating_limits AS (
    SELECT
        MAX(avg_rating) AS max_rating,
        MIN(avg_rating) AS min_rating
    FROM movie_avg
)
SELECT
    ma.title AS movie,
    ma.year,
    ROUND(ma.avg_rating, 3) AS avg_rating,
    CASE
        WHEN ma.avg_rating = rl.max_rating THEN 'Да'
        ELSE 'Нет'
    END AS 'Рекомендуем'
FROM movie_avg AS ma
CROSS JOIN rating_limits AS rl
WHERE ma.avg_rating = rl.max_rating
   OR ma.avg_rating = rl.min_rating
ORDER BY ma.year, ma.title;
"
echo " "
echo "4. Вычислить количество оценок и среднюю оценку, которую дали фильмам пользователи-мужчины в период с 2011 по 2014 год."
echo "--------------------------------------------------"

sqlite3 movies_rating.db -box -echo "
SELECT
    m.title AS movie,
    COUNT(r.id) AS ratings_count,
    ROUND(AVG(r.rating), 2) AS avg_rating
FROM ratings AS r
JOIN users AS u ON u.id = r.user_id
JOIN movies AS m ON m.id = r.movie_id
WHERE u.gender = 'male'
  AND date(r.timestamp, 'unixepoch') >= '2011-01-01'
  AND date(r.timestamp, 'unixepoch') < '2015-01-01'
GROUP BY m.id, m.title
ORDER BY m.title;
"
echo " "

echo "5. Составить список фильмов с указанием средней оценки и количества пользователей, которые их оценили. Полученный список отсортировать по году выпуска и названиям фильмов. В списке оставить первые 20 записей."
echo "--------------------------------------------------"

sqlite3 movies_rating.db -box -echo "
SELECT
    m.title AS movie,
    m.year AS year,
    ROUND(AVG(r.rating), 2) AS avg_rating,
    COUNT(DISTINCT r.user_id) AS users_count
FROM movies AS m
JOIN ratings AS r ON m.id = r.movie_id
GROUP BY m.id, m.title, m.year
ORDER BY m.year, m.title
LIMIT 20;
"
echo " "

echo "6. Определить самый распространённый жанр фильма и количество фильмов в этом жанре. Отдельную таблицу для жанров не использовать, жанры нужно извлекать из таблицы movies."
echo "--------------------------------------------------"

sqlite3 movies_rating.db -box -echo "
WITH RECURSIVE split_genres AS (
    SELECT
        id AS movie_id,
        '',
        genres || '|' AS rest
    FROM movies
    WHERE genres IS NOT NULL

    UNION ALL

    SELECT
        movie_id,
        substr(rest, 1, instr(rest, '|') - 1),
        substr(rest, instr(rest, '|') + 1)
    FROM split_genres
    WHERE rest <> ''
),
genre_counts AS (
    SELECT
        genre,
        COUNT(DISTINCT movie_id) AS movies_count
    FROM (
        SELECT
            movie_id,
            substr(rest, 1, instr(rest, '|') - 1) AS genre
        FROM split_genres
        WHERE rest <> ''
    )
    WHERE genre <> ''
      AND genre <> '(no genres listed)'
    GROUP BY genre
)
SELECT
    genre,
    movies_count
FROM genre_counts
WHERE movies_count = (
    SELECT MAX(movies_count)
    FROM genre_counts
)
ORDER BY genre;
"
echo " "

echo "7. Вывести список из 10 последних зарегистрированных пользователей в формате Фамилия Имя | Дата регистрации (сначала фамилия, потом имя)."
echo "--------------------------------------------------"

sqlite3 movies_rating.db -box -echo "
SELECT
    substr(name, instr(name, ' ') + 1)
    || ' ' ||
    substr(name, 1, instr(name, ' ') - 1)
    || '|' ||
    register_date AS user_info
FROM users
ORDER BY register_date DESC, id DESC
LIMIT 10;
"
echo " "

echo "8. С помощью рекурсивного CTE определить, на какие дни недели приходился ваш день рождения в каждом году."
echo "--------------------------------------------------"

sqlite3 movies_rating.db -box -echo "
WITH RECURSIVE years(year) AS (
    SELECT 2006

    UNION ALL

    SELECT year + 1
    FROM years
    WHERE year < CAST(strftime('%Y', 'now') AS INTEGER)
)
SELECT
    year,
    date(year || '-08-11') AS birthday,
    CASE strftime('%w', date(year || '-08-11'))
        WHEN '0' THEN 'Воскресенье'
        WHEN '1' THEN 'Понедельник'
        WHEN '2' THEN 'Вторник'
        WHEN '3' THEN 'Среда'
        WHEN '4' THEN 'Четверг'
        WHEN '5' THEN 'Пятница'
        WHEN '6' THEN 'Суббота'
    END AS weekday
FROM years
ORDER BY year;
"
echo " "
