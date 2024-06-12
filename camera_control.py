import pygame
import sys
import serial

# Initialize pygame
pygame.init()

# Create a window
screen = pygame.display.set_mode((80, 60))
pygame.display.set_caption("WASD Camera Control")

# Initial camera position
camera_pos_x = 0
camera_pos_y = 0
camera_pos_z = 0
camera_dir_x = 1
camera_dir_y = 1
camera_dir_z = 1

# Sensitivity for camera movement
sensitivity = 1  # Use integer sensitivity for movement

# Initialize serial connection to FPGA (adjust port and baud rate as needed)
#ser = serial.Serial('/dev/ttyUSB0', 115200)

print("Use WASD to move the camera horizontally, SPACE and CTRL to move vertically. Press 'ESC' to exit.")

def update_camera_position(keys):
    global camera_pos_x, camera_pos_y, camera_pos_z, camera_dir_x, camera_dir_y, camera_dir_z

    if keys[pygame.K_w]:
        camera_pos_y += sensitivity
    if keys[pygame.K_s]:
        camera_pos_y -= sensitivity
    if keys[pygame.K_a]:
        camera_pos_x -= sensitivity
    if keys[pygame.K_d]:
        camera_pos_x += sensitivity
    if keys[pygame.K_SPACE]:
        camera_pos_z += sensitivity
    if keys[pygame.K_LCTRL]:
        camera_pos_z -= sensitivity
    if keys[pygame.K_UP]:    
        camera_dir_y += sensitivity
    if keys[pygame.K_DOWN]:
        camera_dir_y -= sensitivity
    if keys[pygame.K_LEFT]:
        camera_dir_x -= sensitivity
    if keys[pygame.K_RIGHT]:
        camera_dir_x += sensitivity
    if keys[pygame.K_RSHIFT]:
        camera_dir_z += sensitivity
    if keys[pygame.K_RCTRL]:
        camera_dir_z -= sensitivity    

    # Print updated camera position for debugging
    print(f"Camera Position: X={camera_pos_x}, Y={camera_pos_y}, Z={camera_pos_z} & Camera Direction: X={camera_dir_x}, Y={camera_dir_y}, Z={camera_dir_z}")

    # Send camera position to FPGA
    #ser.write(f"{camera_pos_x},{camera_pos_y},{camera_pos_z},{camera_dir_x},{camera_dir_y},{camera_dir_z}\n".encode())

try:
    while True:
        # Handle pygame events
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit()
                sys.exit()

        # Get the state of all keyboard buttons
        keys = pygame.key.get_pressed()

        # Update camera position based on WASD keys
        update_camera_position(keys)

        # Delay to reduce CPU usage
        pygame.time.wait(100)

except KeyboardInterrupt:
    print("Exiting...")
    pygame.quit()
    #ser.close()
    sys.exit()
