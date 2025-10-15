from flask import Flask, jsonify
import psycopg2
import os
from datetime import datetime

app = Flask(__name__)

DB_HOST = os.getenv("DB_HOST")
DB_USER = os.getenv("DB_USER")
DB_PASS = os.getenv("DB_PASS")
DB_NAME = os.getenv("DB_NAME")

def get_db_connection():
    return psycopg2.connect(
        host=DB_HOST,
        user=DB_USER,
        password=DB_PASS,
        dbname=DB_NAME,
        port=5432
    )

@app.route('/')
def home():
    return "Backend is working!"

@app.route('/api', methods=['GET'])
@app.route('/api/', methods=['GET'])
def api():
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("INSERT INTO requests DEFAULT VALUES RETURNING created_at;")
        inserted_time = cur.fetchone()[0]
        conn.commit()
        cur.close()
        conn.close()
        return jsonify({"message": "Timestamp inserted", "timestamp": inserted_time.isoformat()})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
