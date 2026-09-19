import os

import psycopg
import redis
from flask import Flask, jsonify

app = Flask(__name__)

DB_HOST = os.getenv("DB_HOST", "db")
DB_PORT = int(os.getenv("DB_PORT", "5432"))
DB_NAME = os.getenv("DB_NAME", "appdb")
DB_USER = os.getenv("DB_USER", "appuser")
DB_PASSWORD = os.getenv("DB_PASSWORD", "")

REDIS_HOST = os.getenv("REDIS_HOST", "redis")
REDIS_PORT = int(os.getenv("REDIS_PORT", "6379"))

redis_client = redis.Redis(
    host=REDIS_HOST,
    port=REDIS_PORT,
    db=0,
    decode_responses=True,
    socket_connect_timeout=2,
    socket_timeout=2,
)


def get_db_connection():
    return psycopg.connect(
        host=DB_HOST,
        port=DB_PORT,
        dbname=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD,
        connect_timeout=3,
    )


@app.get("/health")
def health():
    try:
        redis_client.ping()

        with get_db_connection() as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT 1;")
                cur.fetchone()

        return jsonify(
            status="healthy",
            database="ok",
            redis="ok",
        ), 200

    except Exception as exc:
        return jsonify(
            status="unhealthy",
            error=str(exc),
        ), 503


@app.get("/")
def index():
    try:
        redis_views = redis_client.incr("page_views")

        with get_db_connection() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    "INSERT INTO visits (source) VALUES (%s) RETURNING id;",
                    ("web",),
                )

                visit_id = cur.fetchone()[0]

                cur.execute("SELECT COUNT(*) FROM visits;")
                db_visits = cur.fetchone()[0]

        return jsonify(
            message="Session 38 Web + PostgreSQL + Redis is running",
            redis_page_views=redis_views,
            database_total_visits=db_visits,
            last_visit_id=visit_id,
        ), 200

    except Exception as exc:
        return jsonify(
            status="error",
            error=str(exc),
        ), 503
