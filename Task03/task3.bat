#!/bin/bash

sqlite3 movies_rating.db < db_init.sql

echo "1. Составить список фильмов, имеющих хотя бы одну оценку. Список фильмов отсортировать по году выпуска и по названиям. В списке оставить первые 10 фильмов."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "
SELECT DISTINCT movies.title, movies.year
FROM movies
JOIN ratings ON movies.id = ratings.movie_id
ORDER BY movies.year, movies.title
LIMIT 10;
"
echo " "

echo "2. Вывести список всех пользователей, фамилии которых начинаются на букву A. Отсортировать по дате регистрации. Оставить первых 5 пользователей."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "
SELECT name, register_date
FROM users
WHERE substr(name, instr(name, ' ') + 1) LIKE 'A%'
ORDER BY register_date
LIMIT 5;
"
echo " "

echo "3. Вывести рейтинги в читаемом формате: имя и фамилия эксперта, название фильма, год выпуска, оценка и дата оценки. Отсортировать по имени эксперта, названию фильма и оценке. Оставить первые 50 записей."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "
SELECT
    u.name AS expert,
    m.title AS movie,
    m.year AS year,
    r.rating AS rating,
    date(r.timestamp, 'unixepoch') AS rating_date
FROM ratings AS r
JOIN users AS u ON u.id = r.user_id
JOIN movies AS m ON m.id = r.movie_id
ORDER BY u.name, m.title, r.rating
LIMIT 50;
"
echo " "

echo "4. Вывести список фильмов с указанием тегов, присвоенных пользователями. Сортировать по году выпуска, названию фильма и тегу. Оставить первые 40 записей."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "
SELECT
    m.title AS movie,
    m.year AS year,
    t.tag AS tag
FROM movies AS m
JOIN tags AS t ON m.id = t.movie_id
ORDER BY m.year, m.title, t.tag
LIMIT 40;
"
echo " "

echo "5. Вывести все фильмы последнего года выпуска, имеющегося в базе данных."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "
SELECT title, year
FROM movies
WHERE year = (SELECT MAX(year) FROM movies)
ORDER BY title;
"
echo " "

echo "6. Найти драмы, выпущенные после 2005 года, которые понравились женщинам (оценка не ниже 4.5). Вывести название, год выпуска и количество таких оценок. Отсортировать по году и названию."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "
SELECT
    m.title AS movie,
    m.year AS year,
    COUNT(r.id) AS ratings_count
FROM movies AS m
JOIN ratings AS r ON m.id = r.movie_id
JOIN users AS u ON u.id = r.user_id
WHERE m.genres LIKE '%Drama%'
  AND m.year > 2005
  AND u.gender = 'female'
  AND r.rating >= 4.5
GROUP BY m.id, m.title, m.year
ORDER BY m.year, m.title;
"
echo " "

echo "7. Провести анализ востребованности ресурса - вывести количество пользователей, регистрировавшихся на сайте в каждом году. Найти, в каких годах регистрировалось больше всего и меньше всего пользователей."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "
SELECT
    substr(register_date, 1, 4) AS year,
    COUNT(*) AS users_count
FROM users
GROUP BY substr(register_date, 1, 4)
ORDER BY year;
"
echo " "

echo "Максимальное и минимальное количество регистраций по годам:"
sqlite3 movies_rating.db -box -echo "
WITH yearly_stats AS (
    SELECT
        substr(register_date, 1, 4) AS year,
        COUNT(*) AS users_count
    FROM users
    GROUP BY substr(register_date, 1, 4)
)
SELECT year, users_count, 'Максимум' AS result
FROM yearly_stats
WHERE users_count = (SELECT MAX(users_count) FROM yearly_stats)
UNION ALL
SELECT year, users_count, 'Минимум' AS result
FROM yearly_stats
WHERE users_count = (SELECT MIN(users_count) FROM yearly_stats)
ORDER BY users_count DESC;
"
echo " "
