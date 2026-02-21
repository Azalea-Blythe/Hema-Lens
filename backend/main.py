from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Dict, Any, Optional
import os
import sys

# Ensure database module can be imported
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from database import init_db, save_result, get_all_results, get_summary_stats

app = FastAPI(title="HemaLens Backend", description="API for HemaLens Result Sync and Aggregation")

# Initialize SQLite database
@app.on_event("startup")
def startup_event():
    init_db()

class ScanResult(BaseModel):
    modality: str
    image_probs_list: list[Dict[str, float]]
    survey: Dict[str, Any]
    final_risk: str
    confidence: float

@app.get("/api/health")
def health_check():
    return {"status": "ok", "message": "HemaLens Backend is running."}

@app.post("/api/results")
def create_result(result: ScanResult):
    try:
        data = result.model_dump()
        record_id = save_result(data)
        return {"status": "ok", "message": "Result saved", "id": record_id}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/results")
def read_results():
    try:
        results = get_all_results()
        return {"status": "ok", "results": results}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/results/summary")
def get_summary():
    try:
        summary = get_summary_stats()
        return {"status": "ok", "summary": summary}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# Entry point for local testing
if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
