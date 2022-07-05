import psycopg2
import sys
import random
import string
DB_HOST = "192.168.218.135"
DB_NAME = "deneme"
DB_USER = "postgres"
DB_PASS = "root"
DB_PORT = "5432"

VOWELS = "aeiou"
CONSONANTS = "".join(set(string.ascii_lowercase) - set(VOWELS))


def generate_word(length):
    word = ""
    for i in range(length):
        if i % 2 == 0:
            word += random.choice(CONSONANTS)
        else:
            word += random.choice(VOWELS)
    return word


# establishing the connection
conn = psycopg2.connect(
    database=DB_NAME, user=DB_USER, password=DB_PASS, host=DB_HOST, port=DB_PORT
)
# Creating a cursor object using the cursor() method
cursor = conn.cursor()

# CREATE TABLE
# cursor.execute("CREATE TABLE devops (id SERIAL PRIMARY KEY,name VARCHAR);")
# for i in range(100):
#     word = generate_word(5)
#     cursor.execute("INSERT INTO devops(name) VALUES (%s)", (word,))
# cursor.execute("DELETE FROM devops WHERE id =(%s)", ("2"))
# cursor.execute("INSERT INTO devops(name) VALUES (%s)", ("sdsds",))


# Save the changes to DB
conn.commit()

cursor.execute(
    "SELECT * FROM devops WHERE id=(SELECT max(id) FROM devops);")
print(cursor.fetchall())

# Executing an MYSQL function using the execute() method
cursor.execute("select version()")

# Fetch a single row using fetchone() method.
data = cursor.fetchone()
print("Connection established to: ", data)

sql = "COPY (SELECT * FROM devops) TO STDOUT WITH CSV DELIMITER ';'"
with open("/mnt/postgres/devops/table.csv", "w") as file:
    cursor.copy_expert(sql, file)


# Closing the connection
conn.close()
