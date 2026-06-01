"""
GaitWatch FastAPI Server
Handles encrypted gait data processing and LSTM inference
"""

from fastapi import FastAPI, HTTPException, File, UploadFile
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from typing import Optional, List
import numpy as np
import pickle
import json
import os
from datetime import datetime
import tensorflow as tf
from encryption import GaitEncryption

# Load model and scaler
try:
    MODEL = tf.keras.models.load_model('gait_model.h5')
    with open('scaler.pkl', 'rb') as f:
        SCALER = pickle.load(f)
    MODEL_LOADED = True
except Exception as e:
    print(f"[!] Warning: Could not load model: {e}")
    MODEL = None
    SCALER = None
    MODEL_LOADED = False

app = FastAPI(
    title="GaitWatch API",
    description="Secure gait analysis for Parkinson's detection",
    version="1.0.0"
)

encryptor = GaitEncryption()

# Request/Response models
class GaitDataRequest(BaseModel):
    """Encrypted sensor data from mobile client"""
    encrypted_payload: str
    device_id: str
    timestamp: str

class PredictionResponse(BaseModel):
    """Risk assessment result"""
    risk_score: int  # 0-100
    status: str      # healthy, low_risk, moderate_risk, high_risk, critical
    confidence: float
    step_count: Optional[float] = None
    avg_stride: Optional[float] = None
    gait_velocity: Optional[float] = None
    processing_time_ms: float
    server_status: str = "operational"

class ServerStatus(BaseModel):
    """Server health status"""
    status: str
    model_loaded: bool
    version: str
    timestamp: str

def extract_features(accel_x: List[float], accel_y: List[float], accel_z: List[float],
                    gyro_x: List[float], gyro_y: List[float], gyro_z: List[float]) -> dict:
    """Extract gait metrics from sensor data"""
    
    accel_x = np.array(accel_x)
    accel_y = np.array(accel_y)
    accel_z = np.array(accel_z)
    gyro_x = np.array(gyro_x)
    gyro_y = np.array(gyro_y)
    gyro_z = np.array(gyro_z)
    
    # Calculate magnitude
    accel_mag = np.sqrt(accel_x**2 + accel_y**2 + accel_z**2)
    gyro_mag = np.sqrt(gyro_x**2 + gyro_y**2 + gyro_z**2)
    
    # Detect steps by finding peaks in vertical acceleration
    # Simple peak detection
    threshold = np.mean(accel_z) + 0.5 * np.std(accel_z)
    peaks = np.where(accel_z > threshold)[0]
    step_count = len(peaks) if len(peaks) > 0 else 0
    
    # Estimate stride length from step count (30 sec test)
    avg_stride = 0.0
    if step_count > 0:
        avg_stride = 1.5 / (step_count / 30.0) if (step_count / 30.0) > 0 else 0.0
    
    # Gait velocity estimation
    gait_velocity = step_count * 0.5 if step_count > 0 else 0.0
    
    # Variability metrics (PD indicator)
    accel_variability = np.std(accel_mag)
    gyro_variability = np.std(gyro_mag)
    
    return {
        'step_count': float(step_count),
        'avg_stride': float(avg_stride),
        'gait_velocity': float(gait_velocity),
        'accel_variability': float(accel_variability),
        'gyro_variability': float(gyro_variability)
    }

def score_to_status(score: float) -> str:
    """Convert risk score to status label"""
    if score < 25:
        return "healthy"
    elif score < 45:
        return "low_risk"
    elif score < 65:
        return "moderate_risk"
    elif score < 85:
        return "high_risk"
    else:
        return "critical"

@app.get("/", tags=["Health"])
async def root():
    """Root endpoint"""
    return {
        "message": "GaitWatch API v1.0.0",
        "status": "operational",
        "endpoints": ["/health", "/predict", "/model-info"]
    }

@app.get("/health", tags=["Health"])
async def health():
    """Server health check"""
    return ServerStatus(
        status="operational",
        model_loaded=MODEL_LOADED,
        version="1.0.0",
        timestamp=datetime.now().isoformat()
    )

@app.get("/model-info", tags=["Model"])
async def model_info():
    """Get model information"""
    if not MODEL_LOADED:
        raise HTTPException(status_code=503, detail="Model not loaded")
    
    return {
        "model_type": "LSTM",
        "input_features": 6,
        "architecture": "2-layer LSTM (128->64 units)",
        "training_data": "PhysioNet Gait Dataset",
        "output": "Binary classification (Healthy/PD)",
        "status": "production"
    }

@app.post("/predict", response_model=PredictionResponse, tags=["Prediction"])
async def predict_gait(request: GaitDataRequest):
    """
    Main prediction endpoint - receives encrypted sensor data
    Decrypts, processes, and returns risk assessment
    """
    
    start_time = datetime.now()
    
    if not MODEL_LOADED:
        raise HTTPException(status_code=503, detail="Model not loaded")
    
    try:
        # Decrypt payload
        decrypted_data = encryptor.decrypt_payload(request.encrypted_payload)
        
        # Extract sensor readings
        accel_x = decrypted_data.get('accel_x', [])
        accel_y = decrypted_data.get('accel_y', [])
        accel_z = decrypted_data.get('accel_z', [])
        gyro_x = decrypted_data.get('gyro_x', [])
        gyro_y = decrypted_data.get('gyro_y', [])
        gyro_z = decrypted_data.get('gyro_z', [])
        
        if not all([accel_x, accel_y, accel_z, gyro_x, gyro_y, gyro_z]):
            raise ValueError("Missing sensor data")
        
        # Extract gait features
        features = extract_features(accel_x, accel_y, accel_z, gyro_x, gyro_y, gyro_z)
        
        # Prepare sequence for LSTM
        n_points = len(accel_x)
        sequence = np.column_stack([accel_x, accel_y, accel_z, gyro_x, gyro_y, gyro_z])
        
        # Normalize using scaler
        n_features = sequence.shape[1]
        sequence_reshaped = sequence.reshape(-1, n_features)
        sequence_scaled = SCALER.transform(sequence_reshaped)
        sequence_scaled = sequence_scaled.reshape(1, n_points, n_features)
        
        # Get prediction
        raw_prediction = float(MODEL.predict(sequence_scaled, verbose=0)[0][0])
        
        # Convert to risk score (0-100)
        # Apply feature adjustment
        variability_penalty = min(10, features['accel_variability'] * 5)
        base_score = raw_prediction * 100
        risk_score = int(base_score + variability_penalty)
        risk_score = max(0, min(100, risk_score))  # Clamp to 0-100
        
        # Get status
        status = score_to_status(risk_score)
        
        # Calculate confidence (higher prediction probability = higher confidence)
        confidence = max(raw_prediction, 1 - raw_prediction)
        
        # Processing time
        processing_time = (datetime.now() - start_time).total_seconds() * 1000
        
        return PredictionResponse(
            risk_score=risk_score,
            status=status,
            confidence=round(confidence, 4),
            step_count=features['step_count'],
            avg_stride=round(features['avg_stride'], 2),
            gait_velocity=round(features['gait_velocity'], 2),
            processing_time_ms=round(processing_time, 2),
            server_status="operational"
        )
    
    except ValueError as e:
        raise HTTPException(status_code=400, detail=f"Invalid data: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Prediction error: {str(e)}")

@app.post("/test-encryption", tags=["Debug"])
async def test_encryption(data: dict):
    """Test endpoint for encryption/decryption"""
    try:
        encrypted = encryptor.encrypt_payload(data)
        decrypted = encryptor.decrypt_payload(encrypted)
        return {
            "original": data,
            "encrypted": encrypted[:50] + "...",
            "decrypted": decrypted,
            "match": data == decrypted
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/metrics", tags=["Monitoring"])
async def get_metrics():
    """Get server metrics and statistics"""
    return {
        "timestamp": datetime.now().isoformat(),
        "model_status": "loaded" if MODEL_LOADED else "not_loaded",
        "api_version": "1.0.0",
        "features": [
            "AES-256-GCM encryption",
            "LSTM inference",
            "Gait feature extraction",
            "Real-time risk scoring"
        ]
    }

if __name__ == '__main__':
    import uvicorn
    print("[*] Starting GaitWatch API Server...")
    print("[*] Model Loaded:", MODEL_LOADED)
    uvicorn.run(app, host='0.0.0.0', port=8000, reload=False)
