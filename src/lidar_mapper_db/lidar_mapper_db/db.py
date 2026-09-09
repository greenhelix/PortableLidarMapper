"""세션/방 메타데이터를 저장하는 SQLite 스키마 및 헬퍼 함수."""
import sqlite3

SCHEMA = """
CREATE TABLE IF NOT EXISTS sessions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    started_at TEXT NOT NULL,
    ended_at TEXT NOT NULL,
    map_pgm_path TEXT,
    map_yaml_path TEXT,
    summary TEXT
);

CREATE TABLE IF NOT EXISTS rooms (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id INTEGER NOT NULL REFERENCES sessions(id),
    name TEXT NOT NULL,
    category TEXT,
    centroid_x REAL,
    centroid_y REAL
);
"""


def connect(db_path: str) -> sqlite3.Connection:
    conn = sqlite3.connect(db_path)
    conn.executescript(SCHEMA)
    return conn


def insert_session(conn: sqlite3.Connection, started_at: str, ended_at: str,
                    summary: str, map_pgm_path: str = None,
                    map_yaml_path: str = None) -> int:
    cur = conn.execute(
        "INSERT INTO sessions (started_at, ended_at, map_pgm_path, map_yaml_path, summary) "
        "VALUES (?, ?, ?, ?, ?)",
        (started_at, ended_at, map_pgm_path, map_yaml_path, summary),
    )
    conn.commit()
    return cur.lastrowid
