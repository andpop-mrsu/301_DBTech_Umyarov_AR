import csv
import re

def sql_string(value):
    value = value.replace("'", "''")
    return f"'{value}'"

with open("movies.csv", encoding="utf-8") as file:
    movies = list(csv.DictReader(file))

with open("ratings.csv", encoding="utf-8") as file:
    ratings = list(csv.DictReader(file))

with open("tags.csv", encoding="utf-8") as file:
    tags = list(csv.DictReader(file))

users = []

with open("users.txt", encoding="utf-8") as file:
    for line in file:
        parts = line.strip().split("|")
        users.append(parts)

with open("db_init.sql", "w", encoding="utf-8") as sql:

    sql.write("BEGIN TRANSACTION;\n")
    sql.write("DROP TABLE IF EXISTS movies;\n")
    sql.write("DROP TABLE IF EXISTS ratings;\n")
    sql.write("DROP TABLE IF EXISTS tags;\n")
    sql.write("DROP TABLE IF EXISTS users;\n\n")

    sql.write("""
CREATE TABLE movies (
    id INTEGER PRIMARY KEY,
    title TEXT,
    year INTEGER,
    genres TEXT
);
""")

    sql.write("""
CREATE TABLE ratings (
    id INTEGER PRIMARY KEY,
    user_id INTEGER,
    movie_id INTEGER,
    rating REAL,
    timestamp INTEGER
);
""")

    sql.write("""
CREATE TABLE tags (
    id INTEGER PRIMARY KEY,
    user_id INTEGER,
    movie_id INTEGER,
    tag TEXT,
    timestamp INTEGER
);
""")

    sql.write("""
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT,
    email TEXT,
    gender TEXT,
    register_date TEXT,
    occupation TEXT
);
""")

    for movie in movies:
        match = re.search(r"\((\d{4})\)\s*$", movie["title"])

        if match:
            year = match.group(1)
        else:
            year = "NULL"

        sql.write(
            f"INSERT INTO movies (id, title, year, genres) VALUES "
            f"({movie['movieId']}, "
            f"{sql_string(movie['title'])}, "
            f"{year}, "
            f"{sql_string(movie['genres'])});\n"
        )

    for i, rating in enumerate(ratings, 1):
        sql.write(
            f"INSERT INTO ratings "
            f"(id, user_id, movie_id, rating, timestamp) VALUES "
            f"({i}, "
            f"{rating['userId']}, "
            f"{rating['movieId']}, "
            f"{rating['rating']}, "
            f"{rating['timestamp']});\n"
        )

    for i, tag in enumerate(tags, 1):
        sql.write(
            f"INSERT INTO tags "
            f"(id, user_id, movie_id, tag, timestamp) VALUES "
            f"({i}, "
            f"{tag['userId']}, "
            f"{tag['movieId']}, "
            f"{sql_string(tag['tag'])}, "
            f"{tag['timestamp']});\n"
        )

    for user in users:
        sql.write(
            f"INSERT INTO users "
            f"(id, name, email, gender, register_date, occupation) VALUES "
            f"({user[0]}, "
            f"{sql_string(user[1])}, "
            f"{sql_string(user[2])}, "
            f"{sql_string(user[3])}, "
            f"{sql_string(user[4])}, "
            f"{sql_string(user[5])});\n"
        )

    sql.write("COMMIT;\n")

print("db_init.sql создан")
