import serial
import numpy as np
from PIL import Image
import struct

# Configuration
SERIAL_PORT = 'COM5'  # Change to your serial port
BAUD_RATE = 9600
IMAGE_SIZE = (256, 256)  # Width, Height #############################################################

# Create a blank white image
image_array = np.ones((IMAGE_SIZE[1], IMAGE_SIZE[0], 3), dtype=np.uint8) * 255
image = Image.fromarray(image_array, 'RGB')

def update_image(address, data):
    """Update the image at the specified address with black color"""
    # Convert 16-bit address to x,y coordinates
    x = address % IMAGE_SIZE[0]
    y = address // IMAGE_SIZE[0]
    
    # Ensure coordinates are within bounds
    if 0 <= x < IMAGE_SIZE[0] and 0 <= y < IMAGE_SIZE[1]:
        # Set pixel to black (0,0,0)
        image_array[y, x] = [0, 0, 0] #############################################################
        return True
    return False

def receive_data(ser):
    """Receive and parse data from serial port"""
    # Wait for start byte
    while True:
        byte = ser.read(1)
        if byte == b'\xAA':
            break
    
    # Read address bytes
    addr_msb = ser.read(1)
    addr_lsb = ser.read(1)
    
    if len(addr_msb) == 1 and len(addr_lsb) == 1:
        address = (addr_msb[0] << 8) | addr_lsb[0]
        return address
    return None

def main():
    # Initialize serial connection
    try:
        ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=1)
        print(f"Connected to {SERIAL_PORT} at {BAUD_RATE} baud")
    except Exception as e:
        print(f"Failed to open serial port: {e}") #############################################################
        return

    try:
        while True:
            # Receive data
            address, data = receive_data(ser)
            
            if address is not None:
                # Update image
                success = update_image(address, data)
                
                # Send acknowledgment (optional)
                ser.write(b'\x55')  # ACK byte
                
                # Show updated image (for visualization)
                if success:
                    image = Image.fromarray(image_array, 'RGB')
                    image.show()
                
    except KeyboardInterrupt:
        print("\nExiting...")
    finally:
        ser.close()
        # Save final image
        image.save('etch_a_sketch_result.png')
        print("Image saved as 'etch_a_sketch_result.png'")

if __name__ == "__main__":
    main()