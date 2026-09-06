import time
from typing import List, Dict
from app.core.database import db

class SessionMemory:
    def __init__(self, max_turns: int = 10):
        self.max_turns = max_turns

    def get_history(self, session_id: str) -> List[Dict[str, str]]:
        conn = db.get_connection()
        try:
            cursor = conn.cursor()
            # Fetch the last (max_turns * 2) messages
            cursor.execute(
                "SELECT role, content FROM messages WHERE session_id = ? ORDER BY timestamp ASC",
                (session_id,)
            )
            rows = cursor.fetchall()
            return [{"role": row["role"], "content": row["content"]} for row in rows]
        finally:
            conn.close()

    def add_turn(self, session_id: str, user_query: str, assistant_reply: str):
        conn = db.get_connection()
        try:
            cursor = conn.cursor()
            timestamp = time.time()
            
            # Insert user and assistant messages
            cursor.execute(
                "INSERT INTO messages (session_id, role, content, timestamp) VALUES (?, ?, ?, ?)",
                (session_id, "user", user_query, timestamp)
            )
            cursor.execute(
                "INSERT INTO messages (session_id, role, content, timestamp) VALUES (?, ?, ?, ?)",
                (session_id, "assistant", assistant_reply, timestamp + 0.001) # ensure correct ordering
            )
            
            conn.commit()
            
            # Keep only the last `max_turns * 2` messages
            max_messages = self.max_turns * 2
            cursor.execute(
                """
                DELETE FROM messages 
                WHERE session_id = ? AND id NOT IN (
                    SELECT id FROM messages 
                    WHERE session_id = ? 
                    ORDER BY timestamp DESC 
                    LIMIT ?
                )
                """,
                (session_id, session_id, max_messages)
            )
            conn.commit()
        finally:
            conn.close()

    def delete_session(self, session_id: str) -> bool:
        conn = db.get_connection()
        try:
            cursor = conn.cursor()
            cursor.execute("DELETE FROM messages WHERE session_id = ?", (session_id,))
            conn.commit()
            return cursor.rowcount > 0
        finally:
            conn.close()

    def evict_stale_sessions(self, max_age_seconds: int = 1800):
        # We can implement cleanup logic later if needed for the mobile app, 
        # but persistent means we might not want to automatically evict everything.
        pass

session_memory = SessionMemory(max_turns=10)
