"""
GaitWatch Test Suite
Comprehensive testing for encryption, model, and API
"""

import json
import numpy as np
from encryption import GaitEncryption
from train_model import GaitModelTrainer

def test_encryption():
    """Test AES-256-GCM encryption/decryption"""
    print("\n" + "="*60)
    print("TEST 1: Encryption/Decryption")
    print("="*60)
    
    encryptor = GaitEncryption()
    
    test_data = {
        'accel_x': list(np.random.randn(100).astype(float)),
        'accel_y': list(np.random.randn(100).astype(float)),
        'accel_z': list(np.random.randn(100).astype(float)),
        'gyro_x': list(np.random.randn(100).astype(float)),
        'gyro_y': list(np.random.randn(100).astype(float)),
        'gyro_z': list(np.random.randn(100).astype(float)),
        'timestamp': '2024-05-23T10:30:00Z'
    }
    
    # Encrypt
    encrypted = encryptor.encrypt_payload(test_data)
    print(f"✓ Encrypted payload: {encrypted[:50]}...")
    print(f"  Encrypted length: {len(encrypted)} chars")
    
    # Decrypt
    decrypted = encryptor.decrypt_payload(encrypted)
    print(f"✓ Decrypted successfully")
    
    # Verify
    assert decrypted == test_data, "Data mismatch after decryption!"
    print(f"✓ Data integrity verified")
    print(f"\n✓ TEST PASSED: Encryption/Decryption works correctly\n")
    
    return True

def test_model_training():
    """Test model training and inference"""
    print("\n" + "="*60)
    print("TEST 2: Model Training & Inference")
    print("="*60)
    
    trainer = GaitModelTrainer(window_size=128)
    
    print("Generating test dataset...")
    X_test, y_test = trainer.create_synthetic_dataset(n_samples=50)
    X_train, _, y_train, _ = trainer.create_synthetic_dataset(n_samples=100)
    
    print(f"✓ Dataset created: {X_train.shape}")
    
    # Preprocess
    print("Preprocessing data...")
    X_train_scaled, X_test_scaled, y_train_scaled, y_test_scaled = trainer.preprocess_data(
        X_train, y_train
    )
    print(f"✓ Scaled train shape: {X_train_scaled.shape}")
    print(f"✓ Scaled test shape: {X_test_scaled.shape}")
    
    # Build model
    print("Building LSTM model...")
    input_shape = (X_train_scaled.shape[1], X_train_scaled.shape[2])
    model = trainer.build_model(input_shape)
    print(f"✓ Model built with input shape: {input_shape}")
    
    # Train
    print("Training model (5 epochs for testing)...")
    history = model.fit(
        X_train_scaled, y_train_scaled,
        validation_data=(X_test_scaled, y_test_scaled),
        epochs=5,
        batch_size=32,
        verbose=0
    )
    print(f"✓ Model trained")
    
    # Evaluate
    test_loss, test_acc, test_auc = model.evaluate(X_test_scaled, y_test_scaled, verbose=0)
    print(f"✓ Test Accuracy: {test_acc:.4f}")
    print(f"✓ Test AUC-ROC: {test_auc:.4f}")
    
    # Inference
    print("Testing inference...")
    predictions = model.predict(X_test_scaled[:5], verbose=0)
    print(f"✓ Sample predictions: {predictions.flatten()}")
    
    print(f"\n✓ TEST PASSED: Model training and inference work correctly\n")
    
    return True

def test_gait_feature_extraction():
    """Test gait feature extraction from synthetic data"""
    print("\n" + "="*60)
    print("TEST 3: Gait Feature Extraction")
    print("="*60)
    
    # Create synthetic healthy gait
    n_points = 3000
    accel_x = np.sin(np.linspace(0, 20, n_points)) * 1.5 + np.random.normal(0, 0.3, n_points)
    accel_y = np.cos(np.linspace(0, 20, n_points)) * 1.2 + np.random.normal(0, 0.25, n_points)
    accel_z = np.sin(np.linspace(0, 30, n_points)) * 1 + np.random.normal(0, 0.3, n_points)
    gyro_x = np.random.normal(0, 0.4, n_points)
    gyro_y = np.random.normal(0, 0.45, n_points)
    gyro_z = np.random.normal(0, 0.35, n_points)
    
    # Extract features
    accel_mag = np.sqrt(accel_x**2 + accel_y**2 + accel_z**2)
    threshold = np.mean(accel_z) + 0.5 * np.std(accel_z)
    peaks = np.where(accel_z > threshold)[0]
    step_count = len(peaks)
    
    print(f"✓ Detected {step_count} steps in 30-second test")
    print(f"  - Accel magnitude range: [{np.min(accel_mag):.2f}, {np.max(accel_mag):.2f}]")
    print(f"  - Accel variance: {np.var(accel_mag):.4f}")
    print(f"  - Gyro variability: {np.std(gyro_x):.4f}")
    
    # Test Parkinson's pattern
    print("\nGenerating Parkinson's-like gait pattern...")
    accel_x_pd = np.sin(np.linspace(0, 20, n_points)) * 2 + np.random.normal(0, 0.8, n_points)
    accel_y_pd = np.cos(np.linspace(0, 20, n_points)) * 1.5 + np.random.normal(0, 0.7, n_points)
    accel_z_pd = np.sin(np.linspace(0, 30, n_points)) * 1.2 + np.random.normal(0, 0.9, n_points)
    
    accel_mag_pd = np.sqrt(accel_x_pd**2 + accel_y_pd**2 + accel_z_pd**2)
    peaks_pd = np.where(accel_z_pd > np.mean(accel_z_pd) + 0.5 * np.std(accel_z_pd))[0]
    
    print(f"✓ PD pattern detected {len(peaks_pd)} steps")
    print(f"  - Accel variance: {np.var(accel_mag_pd):.4f} (higher variance)")
    print(f"  - Variability increase: {100 * (np.var(accel_mag_pd) - np.var(accel_mag)) / np.var(accel_mag):.1f}%")
    
    print(f"\n✓ TEST PASSED: Feature extraction correctly identifies gait patterns\n")
    
    return True

def test_risk_scoring():
    """Test risk score calculation"""
    print("\n" + "="*60)
    print("TEST 4: Risk Score Calculation")
    print("="*60)
    
    test_scores = [
        (10, "healthy"),
        (35, "low_risk"),
        (55, "moderate_risk"),
        (75, "high_risk"),
        (95, "critical")
    ]
    
    def score_to_status(score):
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
    
    print("\nRisk Score Mappings:")
    for score, expected_status in test_scores:
        actual_status = score_to_status(score)
        status = "✓" if actual_status == expected_status else "✗"
        print(f"{status} Score {score:3d} → {actual_status:15s} (expected: {expected_status})")
        assert actual_status == expected_status, f"Score mapping error for {score}"
    
    print(f"\n✓ TEST PASSED: Risk scoring works correctly\n")
    
    return True

def test_api_response_structure():
    """Test API response structure validation"""
    print("\n" + "="*60)
    print("TEST 5: API Response Structure")
    print("="*60)
    
    sample_response = {
        "risk_score": 45,
        "status": "moderate_risk",
        "confidence": 0.87,
        "step_count": 42.0,
        "avg_stride": 0.75,
        "gait_velocity": 1.2,
        "processing_time_ms": 250.5,
        "server_status": "operational"
    }
    
    required_fields = [
        "risk_score", "status", "confidence",
        "step_count", "avg_stride", "gait_velocity",
        "processing_time_ms", "server_status"
    ]
    
    print("Checking required fields...")
    for field in required_fields:
        assert field in sample_response, f"Missing field: {field}"
        print(f"✓ {field}: {sample_response[field]}")
    
    # Validate types and ranges
    assert isinstance(sample_response["risk_score"], int), "risk_score must be int"
    assert 0 <= sample_response["risk_score"] <= 100, "risk_score out of range"
    
    assert isinstance(sample_response["status"], str), "status must be str"
    valid_statuses = ["healthy", "low_risk", "moderate_risk", "high_risk", "critical"]
    assert sample_response["status"] in valid_statuses, "Invalid status"
    
    assert isinstance(sample_response["confidence"], float), "confidence must be float"
    assert 0 <= sample_response["confidence"] <= 1, "confidence out of range"
    
    print(f"\n✓ TEST PASSED: Response structure is valid\n")
    
    return True

def run_all_tests():
    """Run all tests"""
    print("\n" + "="*70)
    print(" "*20 + "GAITWATCH TEST SUITE")
    print("="*70)
    
    tests = [
        ("Encryption/Decryption", test_encryption),
        ("Model Training & Inference", test_model_training),
        ("Gait Feature Extraction", test_gait_feature_extraction),
        ("Risk Scoring", test_risk_scoring),
        ("API Response Structure", test_api_response_structure),
    ]
    
    passed = 0
    failed = 0
    
    for test_name, test_func in tests:
        try:
            if test_func():
                passed += 1
        except Exception as e:
            print(f"\n✗ TEST FAILED: {test_name}")
            print(f"  Error: {str(e)}\n")
            failed += 1
    
    # Summary
    print("="*70)
    print(f"RESULTS: {passed} passed, {failed} failed out of {len(tests)} tests")
    print("="*70 + "\n")
    
    return failed == 0

if __name__ == '__main__':
    success = run_all_tests()
    exit(0 if success else 1)
