"""
GaitWatch Encryption Module
Implements AES-256-GCM encryption for secure sensor data transmission
"""

from Crypto.Cipher import AES
from Crypto.Random import get_random_bytes
from Crypto.Protocol.KDF import PBKDF2
import base64
import json
import hashlib

class GaitEncryption:
    """End-to-end encryption for gait sensor data"""
    
    def __init__(self, shared_key: str = None):
        """
        Initialize encryption with shared key (256-bit)
        In production, this would be derived from device pairing
        """
        if shared_key is None:
            self.shared_key = "gaitwatch_default_key_must_change_in_production_12345"
        else:
            self.shared_key = shared_key
        
        # Derive 256-bit key from shared key using PBKDF2
        self.key = PBKDF2(self.shared_key, b'gaitwatch_salt', dkLen=32, count=100000)
    
    def encrypt_payload(self, data: dict) -> str:
        """
        Encrypt sensor data using AES-256-GCM
        Returns: base64-encoded (nonce + ciphertext + tag)
        """
        # Convert dict to JSON
        plaintext = json.dumps(data).encode('utf-8')
        
        # Generate random nonce (96 bits for GCM)
        nonce = get_random_bytes(12)
        
        # Create cipher
        cipher = AES.new(self.key, AES.MODE_GCM, nonce=nonce)
        
        # Encrypt and get authentication tag
        ciphertext, tag = cipher.encrypt_and_digest(plaintext)
        
        # Combine nonce + ciphertext + tag and encode as base64
        encrypted_package = nonce + tag + ciphertext
        encoded = base64.b64encode(encrypted_package).decode('utf-8')
        
        return encoded
    
    def decrypt_payload(self, encrypted_data: str) -> dict:
        """
        Decrypt AES-256-GCM encrypted sensor data
        Input: base64-encoded (nonce + tag + ciphertext)
        Returns: decrypted dict
        """
        try:
            # Decode from base64
            encrypted_package = base64.b64decode(encrypted_data.encode('utf-8'))
            
            # Extract components
            nonce = encrypted_package[:12]
            tag = encrypted_package[12:28]
            ciphertext = encrypted_package[28:]
            
            # Create cipher
            cipher = AES.new(self.key, AES.MODE_GCM, nonce=nonce)
            
            # Decrypt and verify
            plaintext = cipher.decrypt_and_verify(ciphertext, tag)
            
            # Parse JSON
            data = json.loads(plaintext.decode('utf-8'))
            return data
        except Exception as e:
            raise ValueError(f"Decryption failed: {str(e)}")
    
    @staticmethod
    def hash_data(data: str) -> str:
        """Create SHA-256 hash for data integrity verification"""
        return hashlib.sha256(data.encode()).hexdigest()

if __name__ == '__main__':
    # Test encryption
    encryptor = GaitEncryption()
    
    test_data = {
        'accel_x': [1.0, 2.0, 3.0],
        'accel_y': [0.5, 1.5, 2.5],
        'accel_z': [0.2, 0.3, 0.4],
        'gyro_x': [0.1, 0.2, 0.3],
        'gyro_y': [0.05, 0.15, 0.25],
        'gyro_z': [0.0, 0.1, 0.2],
        'timestamp': '2024-05-23T10:30:00Z'
    }
    
    print("[*] Original data:", test_data)
    
    encrypted = encryptor.encrypt_payload(test_data)
    print(f"[✓] Encrypted: {encrypted[:50]}...")
    
    decrypted = encryptor.decrypt_payload(encrypted)
    print("[✓] Decrypted:", decrypted)
    
    assert decrypted == test_data, "Decryption mismatch!"
    print("[✓] Encryption test passed!")
