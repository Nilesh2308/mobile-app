import sqlite3
import os
import logging
from threading import Lock

logger = logging.getLogger(__name__)

class DatabaseManager:
    def __init__(self, db_path: str = "voiceai.db"):
        self.db_path = os.path.join(os.path.dirname(__file__), "../../data", db_path)
        os.makedirs(os.path.dirname(self.db_path), exist_ok=True)
        self.lock = Lock()
        self._init_db()

    def get_connection(self):
        # sqlite3 needs check_same_thread=False if used across multiple threads in FastAPI workers
        conn = sqlite3.connect(self.db_path, check_same_thread=False)
        conn.row_factory = sqlite3.Row
        return conn

    def _init_db(self):
        with self.lock:
            try:
                conn = self.get_connection()
                cursor = conn.cursor()
                
                # Create messages table for session memory
                cursor.execute("""
                    CREATE TABLE IF NOT EXISTS messages (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        session_id TEXT NOT NULL,
                        role TEXT NOT NULL,
                        content TEXT NOT NULL,
                        timestamp REAL NOT NULL
                    )
                """)
                
                # Create index on session_id for faster lookups
                cursor.execute("""
                    CREATE INDEX IF NOT EXISTS idx_messages_session_id ON messages (session_id)
                """)
                
                # Create analytics table
                cursor.execute("""
                    CREATE TABLE IF NOT EXISTS analytics (
                        key TEXT PRIMARY KEY,
                        value INTEGER NOT NULL DEFAULT 0
                    )
                """)
                
                # Initialize analytics if empty
                cursor.execute("SELECT COUNT(*) FROM analytics")
                if cursor.fetchone()[0] == 0:
                    cursor.executemany(
                        "INSERT INTO analytics (key, value) VALUES (?, ?)",
                        [
                            ("total_queries", 0),
                            ("source_knowledge_base", 0),
                            ("source_llm_general", 0),
                            ("source_refused", 0)
                        ]
                    )
                
                conn.commit()
                conn.close()
            except Exception as e:
                logger.error(f"Failed to initialize database: {e}")

db = DatabaseManager()
