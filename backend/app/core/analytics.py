from typing import Dict
from app.core.database import db

class AnalyticsStore:
    def increment_query(self, source: str):
        conn = db.get_connection()
        try:
            cursor = conn.cursor()
            
            # Increment total
            cursor.execute("UPDATE analytics SET value = value + 1 WHERE key = 'total_queries'")
            
            # Increment source
            source_key = f"source_{source}"
            cursor.execute("UPDATE analytics SET value = value + 1 WHERE key = ?", (source_key,))
            if cursor.rowcount == 0:
                # If key didn't exist, insert it
                cursor.execute("INSERT INTO analytics (key, value) VALUES (?, 1)", (source_key,))
                
            conn.commit()
        finally:
            conn.close()

    def get_stats(self) -> Dict:
        conn = db.get_connection()
        try:
            cursor = conn.cursor()
            cursor.execute("SELECT key, value FROM analytics")
            rows = cursor.fetchall()
            
            stats = {
                "total_queries": 0,
                "sources": {}
            }
            
            for row in rows:
                k = row["key"]
                v = row["value"]
                if k == "total_queries":
                    stats["total_queries"] = v
                elif k.startswith("source_"):
                    source_name = k.replace("source_", "")
                    stats["sources"][source_name] = v
                    
            return stats
        finally:
            conn.close()

analytics_store = AnalyticsStore()
