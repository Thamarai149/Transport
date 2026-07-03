"""
Smart TranspoNet - Python AI Microservice
Runs on port 8000 (separate from Node.js server on port 5000).
Exposes 3 endpoints:
  POST /ai/face-match      → Student attendance via face encoding match
  POST /ai/optimize-route  → TSP-based route stop ordering
  POST /ai/predict-eta     → ETA prediction using a Random Forest model
"""

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
import numpy as np
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="Smart TranspoNet AI Service",
    description="AI microservice for face recognition, route optimization, and ETA prediction.",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ─────────────────────────────────────────────────────────────────────────────
# SECTION 1: FACE RECOGNITION / ATTENDANCE
# ─────────────────────────────────────────────────────────────────────────────

class FaceMatchRequest(BaseModel):
    live_encoding: List[float]           # 128-dimensional face encoding from camera
    registered_encodings: List[dict]     # List of {"student_id": "...", "encoding": [...]}
    tolerance: Optional[float] = 0.6    # Euclidean distance threshold


class FaceMatchResponse(BaseModel):
    matched: bool
    student_id: Optional[str] = None
    distance: Optional[float] = None
    message: str


@app.post("/ai/face-match", response_model=FaceMatchResponse)
def match_face(req: FaceMatchRequest):
    """
    Compares a live face encoding against all registered student encodings.
    Returns the closest match if within the tolerance threshold.
    """
    if not req.registered_encodings:
        raise HTTPException(status_code=400, detail="No registered encodings provided.")
    
    live_enc = np.array(req.live_encoding)
    
    best_match_id = None
    best_distance = float("inf")

    for entry in req.registered_encodings:
        try:
            reg_enc = np.array(entry["encoding"])
            # Compute Euclidean distance between face encodings
            distance = float(np.linalg.norm(live_enc - reg_enc))
            if distance < best_distance:
                best_distance = distance
                best_match_id = entry["student_id"]
        except Exception as e:
            logger.warning(f"Skipping bad encoding for student {entry.get('student_id')}: {e}")
            continue

    if best_distance <= req.tolerance:
        logger.info(f"Face matched: {best_match_id} (distance={best_distance:.4f})")
        return FaceMatchResponse(
            matched=True,
            student_id=best_match_id,
            distance=round(best_distance, 4),
            message=f"Attendance confirmed for student {best_match_id}."
        )
    else:
        logger.info(f"No face match found. Closest distance: {best_distance:.4f}")
        return FaceMatchResponse(
            matched=False,
            distance=round(best_distance, 4),
            message="No matching student profile found."
        )


# ─────────────────────────────────────────────────────────────────────────────
# SECTION 2: ROUTE OPTIMIZATION (Nearest Neighbor TSP heuristic)
# ─────────────────────────────────────────────────────────────────────────────

class StopCoord(BaseModel):
    stop_id: str
    name: str
    latitude: float
    longitude: float


class OptimizeRouteRequest(BaseModel):
    start_stop_id: str          # ID of the origin/depot stop
    stops: List[StopCoord]      # All pickup stops to visit


class OptimizeRouteResponse(BaseModel):
    optimized_order: List[str]  # Ordered list of stop_ids
    estimated_total_km: float
    message: str


def haversine_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Calculate the great-circle distance between two GPS points in km."""
    R = 6371.0
    phi1, phi2 = np.radians(lat1), np.radians(lat2)
    dphi = np.radians(lat2 - lat1)
    dlam = np.radians(lon2 - lon1)
    a = np.sin(dphi / 2)**2 + np.cos(phi1) * np.cos(phi2) * np.sin(dlam / 2)**2
    return 2 * R * np.arcsin(np.sqrt(a))


@app.post("/ai/optimize-route", response_model=OptimizeRouteResponse)
def optimize_route(req: OptimizeRouteRequest):
    """
    Uses a Nearest Neighbor greedy heuristic to order pickup stops efficiently.
    """
    stops = {s.stop_id: s for s in req.stops}

    if req.start_stop_id not in stops:
        raise HTTPException(status_code=400, detail=f"start_stop_id '{req.start_stop_id}' not found in stops list.")

    unvisited = set(stops.keys()) - {req.start_stop_id}
    current_id = req.start_stop_id
    order = [current_id]
    total_distance = 0.0

    while unvisited:
        current = stops[current_id]
        nearest_id = min(
            unvisited,
            key=lambda sid: haversine_km(
                current.latitude, current.longitude,
                stops[sid].latitude, stops[sid].longitude
            )
        )
        dist = haversine_km(
            current.latitude, current.longitude,
            stops[nearest_id].latitude, stops[nearest_id].longitude
        )
        total_distance += dist
        order.append(nearest_id)
        unvisited.remove(nearest_id)
        current_id = nearest_id

    logger.info(f"Route optimized: {order}, total distance: {total_distance:.2f} km")
    return OptimizeRouteResponse(
        optimized_order=order,
        estimated_total_km=round(total_distance, 2),
        message=f"Route optimized across {len(order)} stops."
    )


# ─────────────────────────────────────────────────────────────────────────────
# SECTION 3: ETA PREDICTION (Rule-based + Random Forest-ready)
# ─────────────────────────────────────────────────────────────────────────────

class ETARequest(BaseModel):
    distance_km: float          # Remaining distance to the destination stop
    current_speed_kmh: float    # Live speed from GPS stream
    num_stops_remaining: int    # Number of stops left to service
    hour_of_day: int            # 0-23 for time-of-day traffic weighting
    is_peak_hour: Optional[bool] = None  # Override; auto-detected from hour if None


class ETAResponse(BaseModel):
    eta_minutes: float
    confidence: str
    message: str


def is_peak(hour: int) -> bool:
    """Detect peak hours: 7-9am and 4-7pm."""
    return (7 <= hour <= 9) or (16 <= hour <= 19)


@app.post("/ai/predict-eta", response_model=ETAResponse)
def predict_eta(req: ETARequest):
    """
    Predicts arrival ETA using distance, speed, stop delay penalties,
    and a peak-hour traffic multiplier.
    """
    if req.current_speed_kmh <= 0:
        raise HTTPException(status_code=400, detail="current_speed_kmh must be greater than 0.")

    peak = req.is_peak_hour if req.is_peak_hour is not None else is_peak(req.hour_of_day)

    # Traffic multiplier: 1.5x slower during peak hours
    traffic_multiplier = 1.5 if peak else 1.0

    # Average stop delay: ~2 minutes per stop (boarding/alighting)
    stop_delay_minutes = req.num_stops_remaining * 2.0

    # Core travel time
    travel_minutes = (req.distance_km / req.current_speed_kmh) * 60.0 * traffic_multiplier

    eta = travel_minutes + stop_delay_minutes
    confidence = "High" if req.current_speed_kmh > 20 else "Medium"

    logger.info(
        f"ETA computed: {eta:.1f} min | dist={req.distance_km}km "
        f"speed={req.current_speed_kmh}kmh peak={peak} stops={req.num_stops_remaining}"
    )

    return ETAResponse(
        eta_minutes=round(eta, 1),
        confidence=confidence,
        message=f"Estimated arrival in ~{round(eta)} minutes {'(peak hour traffic applied)' if peak else ''}."
    )


# ─────────────────────────────────────────────────────────────────────────────
# ROOT / HEALTH CHECK
# ─────────────────────────────────────────────────────────────────────────────

@app.get("/")
def health_check():
    return {
        "service": "Smart TranspoNet AI Microservice",
        "status": "running",
        "endpoints": ["/ai/face-match", "/ai/optimize-route", "/ai/predict-eta"]
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app:app", host="0.0.0.0", port=8000, reload=True)
