"""
GaitWatch ML Model Training Module
Trains LSTM model on PhysioNet gait data for Parkinson's detection
"""

import numpy as np
import pandas as pd
from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import train_test_split
import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import LSTM, Dense, Dropout, Input
import pickle
import json
import warnings
warnings.filterwarnings('ignore')

class GaitModelTrainer:
    """Train LSTM model for Parkinson's gait detection"""
    
    def __init__(self, window_size=128, overlap=0.5):
        self.window_size = window_size
        self.overlap = overlap
        self.scaler = StandardScaler()
        self.model = None
        self.history = None
        
    def create_synthetic_dataset(self, n_samples=1000):
        """
        Create synthetic gait dataset mimicking PhysioNet structure
        Real implementation would use actual PhysioNet data
        """
        np.random.seed(42)
        X = []
        y = []
        
        for i in range(n_samples):
            is_pd = i % 2 == 0  # 50% healthy, 50% PD
            
            # Simulate 30 seconds of sensor data at 100Hz
            n_points = 30 * 100
            
            if is_pd:
                # PD gait characteristics: increased variability, altered stride patterns
                accel_x = np.sin(np.linspace(0, 20, n_points)) * 2 + np.random.normal(0, 0.8, n_points)
                accel_y = np.cos(np.linspace(0, 20, n_points)) * 1.5 + np.random.normal(0, 0.7, n_points)
                accel_z = np.sin(np.linspace(0, 30, n_points)) * 1.2 + np.random.normal(0, 0.9, n_points)
                gyro_x = np.random.normal(0.2, 1.2, n_points)
                gyro_y = np.random.normal(0.15, 1.3, n_points)
                gyro_z = np.random.normal(0.1, 1.1, n_points)
                label = 1
            else:
                # Healthy gait: regular stride, consistent pattern
                accel_x = np.sin(np.linspace(0, 20, n_points)) * 1.5 + np.random.normal(0, 0.3, n_points)
                accel_y = np.cos(np.linspace(0, 20, n_points)) * 1.2 + np.random.normal(0, 0.25, n_points)
                accel_z = np.sin(np.linspace(0, 30, n_points)) * 1 + np.random.normal(0, 0.3, n_points)
                gyro_x = np.random.normal(0, 0.4, n_points)
                gyro_y = np.random.normal(0, 0.45, n_points)
                gyro_z = np.random.normal(0, 0.35, n_points)
                label = 0
            
            # Stack all 6-axis data
            sequence = np.column_stack([accel_x, accel_y, accel_z, gyro_x, gyro_y, gyro_z])
            X.append(sequence)
            y.append(label)
        
        return np.array(X), np.array(y)
    
    def preprocess_data(self, X, y):
        """Normalize and prepare data for training"""
        n_samples = X.shape[0]
        n_features = X.shape[2]
        
        # Reshape for scaling: (n_samples * n_timesteps, n_features)
        X_reshaped = X.reshape(-1, n_features)
        X_scaled = self.scaler.fit_transform(X_reshaped)
        X = X_scaled.reshape(n_samples, -1, n_features)
        
        # Split into train/test
        X_train, X_test, y_train, y_test = train_test_split(
            X, y, test_size=0.2, random_state=42, stratify=y
        )
        
        return X_train, X_test, y_train, y_test
    
    def build_model(self, input_shape):
        """Build LSTM architecture for gait analysis"""
        model = Sequential([
            Input(shape=input_shape),
            LSTM(128, activation='relu', return_sequences=True),
            Dropout(0.3),
            LSTM(64, activation='relu'),
            Dropout(0.3),
            Dense(32, activation='relu'),
            Dense(16, activation='relu'),
            Dense(1, activation='sigmoid')
        ])
        
        model.compile(
            optimizer='adam',
            loss='binary_crossentropy',
            metrics=['accuracy', tf.keras.metrics.AUC(name='auc')]
        )
        
        return model
    
    def train(self, epochs=50, batch_size=32, verbose=1):
        """Train the model on synthetic gait data"""
        print("[*] Generating synthetic gait dataset...")
        X, y = self.create_synthetic_dataset(n_samples=1000)
        
        print(f"[*] Dataset shape: {X.shape}, Labels shape: {y.shape}")
        
        print("[*] Preprocessing data...")
        X_train, X_test, y_train, y_test = self.preprocess_data(X, y)
        
        print(f"[*] Train shape: {X_train.shape}, Test shape: {X_test.shape}")
        
        print("[*] Building LSTM model...")
        input_shape = (X_train.shape[1], X_train.shape[2])
        self.model = self.build_model(input_shape)
        
        print(self.model.summary())
        
        print("[*] Training model...")
        self.history = self.model.fit(
            X_train, y_train,
            validation_data=(X_test, y_test),
            epochs=epochs,
            batch_size=batch_size,
            verbose=verbose,
            callbacks=[
                keras.callbacks.EarlyStopping(monitor='val_loss', patience=10, restore_best_weights=True),
                keras.callbacks.ReduceLROnPlateau(monitor='val_loss', factor=0.5, patience=5, min_lr=1e-5)
            ]
        )
        
        # Evaluate
        test_loss, test_acc, test_auc = self.model.evaluate(X_test, y_test, verbose=0)
        print(f"\n[✓] Test Accuracy: {test_acc:.4f}")
        print(f"[✓] Test AUC-ROC: {test_auc:.4f}")
        
        return self.model
    
    def save_model(self, model_path='gait_model.h5', scaler_path='scaler.pkl'):
        """Save trained model and scaler"""
        self.model.save(model_path)
        with open(scaler_path, 'wb') as f:
            pickle.dump(self.scaler, f)
        print(f"[✓] Model saved to {model_path}")
        print(f"[✓] Scaler saved to {scaler_path}")

if __name__ == '__main__':
    trainer = GaitModelTrainer(window_size=128)
    trainer.train(epochs=50, batch_size=32, verbose=1)
    trainer.save_model('gait_model.h5', 'scaler.pkl')
