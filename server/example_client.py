"""
GaitWatch Python Client Example
Demonstrates how to send gait data to the server
"""

import json
import numpy as np
import requests
from datetime import datetime

class GaitWatchClient:
    """Client for communicating with GaitWatch API"""
    
    def __init__(self, server_url: str, device_id: str = "mobile-device-001"):
        self.server_url = server_url
        self.device_id = device_id
        self.session = requests.Session()
    
    def generate_synthetic_gait_data(self, is_pd: bool = False) -> dict:
        """Generate synthetic 30-second gait data"""
        n_points = 3000  # 30 seconds at 100Hz
        
        if is_pd:
            # Parkinson's disease pattern: increased variability
            accel_x = np.sin(np.linspace(0, 20, n_points)) * 2 + np.random.normal(0, 0.8, n_points)
            accel_y = np.cos(np.linspace(0, 20, n_points)) * 1.5 + np.random.normal(0, 0.7, n_points)
            accel_z = np.sin(np.linspace(0, 30, n_points)) * 1.2 + np.random.normal(0, 0.9, n_points)
            gyro_x = np.random.normal(0.2, 1.2, n_points)
            gyro_y = np.random.normal(0.15, 1.3, n_points)
            gyro_z = np.random.normal(0.1, 1.1, n_points)
        else:
            # Healthy gait pattern: regular stride
            accel_x = np.sin(np.linspace(0, 20, n_points)) * 1.5 + np.random.normal(0, 0.3, n_points)
            accel_y = np.cos(np.linspace(0, 20, n_points)) * 1.2 + np.random.normal(0, 0.25, n_points)
            accel_z = np.sin(np.linspace(0, 30, n_points)) * 1 + np.random.normal(0, 0.3, n_points)
            gyro_x = np.random.normal(0, 0.4, n_points)
            gyro_y = np.random.normal(0, 0.45, n_points)
            gyro_z = np.random.normal(0, 0.35, n_points)
        
        return {
            'accel_x': accel_x.tolist(),
            'accel_y': accel_y.tolist(),
            'accel_z': accel_z.tolist(),
            'gyro_x': gyro_x.tolist(),
            'gyro_y': gyro_y.tolist(),
            'gyro_z': gyro_z.tolist(),
            'timestamp': datetime.now().isoformat()
        }
    
    def check_server_health(self) -> bool:
        """Check if server is running"""
        try:
            response = self.session.get(f"{self.server_url}/health", timeout=5)
            return response.status_code == 200
        except:
            return False
    
    def submit_gait_data(self, gait_data: dict) -> dict:
        """Submit gait data for analysis"""
        try:
            request_payload = {
                'encrypted_payload': json.dumps(gait_data),
                'device_id': self.device_id,
                'timestamp': datetime.now().isoformat()
            }
            
            response = self.session.post(
                f"{self.server_url}/predict",
                json=request_payload,
                timeout=15
            )
            
            if response.status_code == 200:
                return response.json()
            else:
                return {'error': f'Server error: {response.status_code}'}
        except Exception as e:
            return {'error': str(e)}
    
    def run_test_sequence(self, num_tests: int = 5):
        """Run multiple tests (healthy and PD patterns)"""
        print(f"\nRunning {num_tests} test sequences...")
        print("="*70)
        
        # Check server first
        print("\n[1] Checking server health...")
        if not self.check_server_health():
            print("✗ Server is not running!")
            print("  Start server with: cd server && python main.py")
            return
        print("✓ Server is operational")
        
        # Run tests
        results = []
        
        for i in range(num_tests):
            is_pd = i % 2 == 0  # Alternate between PD and healthy
            pattern = "Parkinson's Pattern" if is_pd else "Healthy Pattern"
            
            print(f"\n[{i+2}] Test {i+1}/{num_tests}: {pattern}")
            print("-"*70)
            
            # Generate data
            gait_data = self.generate_synthetic_gait_data(is_pd=is_pd)
            print(f"  ✓ Generated {len(gait_data['accel_x'])} sensor readings")
            
            # Submit
            print("  ✓ Submitting to server...")
            result = self.submit_gait_data(gait_data)
            
            if 'error' in result:
                print(f"  ✗ Error: {result['error']}")
            else:
                print(f"  ✓ Risk Score: {result['risk_score']}/100")
                print(f"  ✓ Status: {result['status']}")
                print(f"  ✓ Confidence: {result['confidence']:.1%}")
                print(f"  ✓ Steps: {result.get('step_count', 'N/A')}")
                print(f"  ✓ Processing: {result.get('processing_time_ms', 'N/A')}ms")
                results.append(result)
        
        # Summary
        print("\n" + "="*70)
        print("TEST SUMMARY")
        print("="*70)
        
        if results:
            scores = [r['risk_score'] for r in results]
            statuses = [r['status'] for r in results]
            
            print(f"Total Tests: {len(results)}")
            print(f"Avg Risk Score: {np.mean(scores):.1f}/100")
            print(f"Score Range: {min(scores)}-{max(scores)}")
            print(f"Status Distribution:")
            for status in set(statuses):
                count = statuses.count(status)
                print(f"  - {status}: {count}")
            
            print(f"\n✓ All tests completed successfully!")
        else:
            print("✗ No successful tests")

def main():
    """Main entry point"""
    print("\n" + "="*70)
    print(" "*15 + "GaitWatch Python Client Example")
    print("="*70)
    
    # Configuration
    SERVER_URL = "http://localhost:8000"  # Change to your server IP
    DEVICE_ID = "test-client-001"
    
    print(f"\nConfiguration:")
    print(f"  Server: {SERVER_URL}")
    print(f"  Device ID: {DEVICE_ID}")
    
    # Create client
    client = GaitWatchClient(SERVER_URL, DEVICE_ID)
    
    # Run tests
    client.run_test_sequence(num_tests=6)

if __name__ == '__main__':
    main()
