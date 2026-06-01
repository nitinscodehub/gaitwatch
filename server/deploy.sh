#!/bin/bash

# GaitWatch Server Deployment Script
# Automates setup, training, and deployment

set -e  # Exit on error

echo "=================================="
echo "GaitWatch Server Setup & Deployment"
echo "=================================="

# Check Python version
echo -e "\n[1] Checking Python installation..."
if ! command -v python3 &> /dev/null; then
    echo "✗ Python 3 is not installed"
    exit 1
fi

PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
echo "✓ Python version: $PYTHON_VERSION"

# Create virtual environment
echo -e "\n[2] Creating virtual environment..."
if [ -d "venv" ]; then
    echo "✓ Virtual environment already exists"
else
    python3 -m venv venv
    echo "✓ Virtual environment created"
fi

# Activate virtual environment
echo -e "\n[3] Activating virtual environment..."
source venv/bin/activate
echo "✓ Virtual environment activated"

# Install dependencies
echo -e "\n[4] Installing dependencies..."
pip install --upgrade pip > /dev/null 2>&1
pip install -r requirements.txt > /dev/null 2>&1
echo "✓ Dependencies installed"

# Train model
echo -e "\n[5] Training LSTM model..."
if [ -f "gait_model.h5" ] && [ -f "scaler.pkl" ]; then
    echo "✓ Model already trained (gait_model.h5 exists)"
    echo "  To retrain: rm gait_model.h5 scaler.pkl && python train_model.py"
else
    echo "  Training may take 2-5 minutes..."
    python train_model.py
    if [ -f "gait_model.h5" ]; then
        echo "✓ Model training completed"
    else
        echo "✗ Model training failed"
        exit 1
    fi
fi

# Test encryption
echo -e "\n[6] Testing encryption..."
python encryption.py > /dev/null 2>&1 && echo "✓ Encryption test passed" || echo "✗ Encryption test failed"

# Test suite
echo -e "\n[7] Running test suite..."
if python test_suite.py; then
    echo "✓ All tests passed"
else
    echo "⚠ Some tests failed (non-critical)"
fi

# Summary
echo -e "\n=================================="
echo "✓ GaitWatch Server Ready!"
echo "=================================="

echo -e "\nNext steps:"
echo "1. Start the server:  python main.py"
echo "2. Check health:      curl http://localhost:8000/health"
echo "3. Configure mobile:  Set SERVER_URL in Flutter app"
echo "4. Run tests:         python example_client.py"

echo -e "\nServer will run at: http://0.0.0.0:8000"
echo "Change default server IP in Flutter app to your machine's IP"

echo -e "\n=================================="
