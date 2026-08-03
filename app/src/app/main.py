import os
from fastapi import FastAPI
import psycopg2

app = FastAPI()

@app.get("/health")
def health():
    return {"status": "ok"}

@app.get("/items")
def get_items():
    conn = psycopg2.connect(os.environ["DATABASE_URL"])
    cur = conn.cursor()
    cur.execute("SELECT id, name FROM items;")
    rows = cur.fetchall()
    cur.close()
    conn.close()
    return {"items": rows}

def main():
    pass