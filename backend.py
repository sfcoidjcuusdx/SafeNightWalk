# SafeNightWalk FastAPI Backend Example
# Install with: pip install fastapi uvicorn motor pydantic pymongo

from fastapi import FastAPI, Query, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime
import uvicorn

# For MongoDB (you'll set this up later)
# from motor.motor_asyncio import AsyncIOMotorClient

app = FastAPI(
    title="SafeNightWalk API",
    description="Backend API for analyzing police and streetlight data",
    version="1.0.0"
)

# Enable CORS for your iOS app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify your app's domain
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Data Models (Pydantic automatically validates these!)
class Coordinate(BaseModel):
    latitude: float
    longitude: float

class PoliceIncident(BaseModel):
    id: str
    location: Coordinate
    crime_type: str  # "theft", "assault", "vandalism", etc.
    severity: int    # 1-10 scale
    timestamp: str
    description: Optional[str] = None

class Streetlight(BaseModel):
    id: str
    location: Coordinate
    brightness: int  # 0-100
    working_status: bool
    last_maintenance: str

class SafetyResponse(BaseModel):
    safety_score: float  # 0-100
    nearby_incidents: List[PoliceIncident]
    streetlight_count: int
    risk_factors: List[str]


# How to run this:
# 1. pip install fastapi uvicorn
# 2. python backend_example.py
# 3. In another terminal: ngrok http 8000
# 4. Use the ngrok URL in your iOS app!
