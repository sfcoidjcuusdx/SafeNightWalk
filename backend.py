# SafeNightWalk FastAPI Backend Example
# Install with: pip install fastapi uvicorn motor pydantic pymongo

from fastapi import FastAPI, Query, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional, Tuple
from datetime import datetime
import uvicorn
import os
from dotenv import load_dotenv
import math
import asyncio
from contextlib import asynccontextmanager

# Load environment variables from .env file
load_dotenv()

# For MongoDB
from bson import ObjectId
import pymongo
from pymongo import AsyncMongoClient
from pymongo import ReturnDocument
from pymongo.server_api import ServerApi

# Functionalities
"""
 Step 1: Find the shortest route to the destination (this is our basis for time)
 Step 2: Find all routes that take <1.5x the shortest route
 Step 3: For each valid route calculate
 - Crime score (lower = better)
 - Streetlight score (higher = better)
 Step 4: Return the route with the best score in each category
"""

# MongoDB connection setup - now secure!
MONGODB_URL = os.getenv("MONGODB_URL")  # Fallback to local
DATABASE_NAME = os.getenv("DATABASE_NAME", "safenightwalk_project")

client =  AsyncMongoClient(MONGODB_URL,server_api=pymongo.server_api.ServerApi(version="1", strict=True,deprecation_errors=True))
db = client.get_database(DATABASE_NAME)
assault_collection = db.get_collection("assault_data")
streetlight_collection = db.get_collection("streetlights_data")
footpaths_collection = db.get_collection("footpaths_data")

# Data Models (Pydantic automatically validates these)
class Coordinate(BaseModel):
    latitude: float
    longitude: float
class PoliceIncident(BaseModel):
    id: str
    location: Coordinate
    incident_id: str
    occurrence_data: str
    occurence_year: int
    occurence_month: str
    occurence_hour: int
    occurence_day_of_week: str
    offense_type: str  # "theft", "assault", "vandalism", etc.
    mci_category: str
    location_type: str
    premise_type: str
    division: str
    neighbourhood: str
class Streetlight(BaseModel):
    id: str
    location: Coordinate
    subtype: str
class SafetyResponse(BaseModel):
    safety_score: float  
    nearby_incidents: List[PoliceIncident]
    streetlight_count: int
    risk_factors: List[str]

class RoutePoint(BaseModel):
    latitude: float
    longitude: float

class SafeRoute(BaseModel):
    route_points: List[RoutePoint]
    total_distance: float
    safety_score: float
    streetlight_count: int
    crime_incidents: int
    estimated_time_minutes: int
    
class RouteRequest(BaseModel):
    start: Coordinate
    end: Coordinate
    max_detour_factor: float = 1.5  # Default 1.5x shortest route


# Shows the status of the connection to the database
@asynccontextmanager
async def lifespan(app: FastAPI):
    try:
        await client.admin.command("ping")
        print(" Successful connection to MongoDB!")
        print(f" Database: {DATABASE_NAME}")
        # Show collection summary
        collections = await db.list_collection_names()
        print(f"📦 Found {len(collections)} collections: {collections}")

        # Show document counts
        for collection_name in collections:
            count = await db[collection_name].count_documents({})
            print(f"   📄 {collection_name}: {count} documents")
        print("") # Spacing 

    except Exception as e:
        print(" Failed connection: Could not connect to MongoDB")
        print(f" Error: {e}")

    yield # Pause to let FastAPI run API endpoint
    
    if client: 
        client.close()
        print("MongoDB connection closed")


app = FastAPI(
    title="SafeNightWalk API",
    description="Backend API for analyzing police and streetlight data",
    version="1.0.0",
    lifespan=lifespan
)

# Enable CORS for your iOS app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify your app's domain
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Runs the server if called directly
if __name__ == "__main__":
    print("🚀 Starting SafeNightWalk API server...")
    uvicorn.run("backend:app", host="127.0.0.1", port=8000, reload=True)

# TODO: Add your actual API endpoints here
# Example endpoints you might add:
# @app.post("/find-safe-route")
# @app.get("/safety-analysis")
# @app.get("/assault-data/first")
