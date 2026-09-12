"""
Migration script to migrate local Qdrant points to Qdrant Cloud.
Usage:
    d:\\voiceai\\backend\\venv\\Scripts\\python.exe scripts/migrate_to_qdrant_cloud.py
"""
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from qdrant_client import QdrantClient
from qdrant_client.models import Distance, VectorParams
from app.core.config import settings

def migrate():
    print("=" * 60)
    print(" Qdrant Cloud Migration Utility")
    print("=" * 60)
    
    cloud_url = settings.QDRANT_URL
    cloud_api_key = settings.QDRANT_API_KEY
    collection_name = settings.QDRANT_COLLECTION_NAME
    
    if not cloud_url or "localhost" in cloud_url or "127.0.0.1" in cloud_url:
        print("[ERROR] QDRANT_URL in .env is still pointing to localhost!")
        print("Please update .env with your Qdrant Cloud URL and API Key first.")
        print("Example:")
        print("QDRANT_URL=https://xxxx-xxxx.eu-central.aws.cloud.qdrant.io:6333")
        print("QDRANT_API_KEY=your_api_key_here")
        return

    print(f"Connecting to Local Database ('local_qdrant_data')...")
    local_client = QdrantClient(path="local_qdrant_data")
    
    try:
        local_info = local_client.get_collection(collection_name)
        total_points = local_info.points_count
        print(f"Found local collection '{collection_name}' with {total_points} point(s).")
    except Exception as e:
        print(f"[!] No existing points found in local collection: {e}")
        total_points = 0

    print(f"\nConnecting to Qdrant Cloud at: {cloud_url}...")
    cloud_client = QdrantClient(url=cloud_url, api_key=cloud_api_key if cloud_api_key else None)
    
    # Ensure collection exists on Cloud
    if not cloud_client.collection_exists(collection_name=collection_name):
        print(f"Creating collection '{collection_name}' on Qdrant Cloud (384-dim Cosine)...")
        cloud_client.create_collection(
            collection_name=collection_name,
            vectors_config=VectorParams(size=384, distance=Distance.COSINE)
        )
        print("Collection created successfully on Qdrant Cloud.")
    else:
        print(f"Collection '{collection_name}' already exists on Qdrant Cloud.")

    if total_points > 0:
        print(f"\nExporting {total_points} point(s) from local to cloud...")
        records, _ = local_client.scroll(
            collection_name=collection_name,
            limit=10000,
            with_payload=True,
            with_vectors=True
        )
        
        # Upload to cloud
        cloud_client.upsert(
            collection_name=collection_name,
            points=records
        )
        print(f"[SUCCESS] Migrated {len(records)} points to Qdrant Cloud!")
    else:
        print("[INFO] No points needed migration. Cloud collection is ready.")

    cloud_info = cloud_client.get_collection(collection_name)
    print(f"\nVerification: Qdrant Cloud '{collection_name}' now has {cloud_info.points_count} points.")
    print("=" * 60)
    print("Migration complete! You can now turn off Docker Desktop completely.")
    print("=" * 60)

if __name__ == "__main__":
    migrate()
