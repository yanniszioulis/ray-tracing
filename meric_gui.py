import pygame
import numpy as np
import socket
import struct
from pygame.locals import *
from PIL import Image

# Initial camera parameters
initial_camera_pos = np.array([250, 512, 0], dtype=np.int32)
initial_camera_front = np.array([0, 0, 230], dtype=np.int32)
initial_camera_up = np.array([0, 1, 0], dtype=np.int32)

# Camera parameters
camera_pos = np.copy(initial_camera_pos)
camera_front = np.copy(initial_camera_front)
camera_up = np.copy(initial_camera_up)

background_color = [0, 0, 0]
font = None
movement_speed = 5
mouse_sensitivity = 0.1
yaw = -90
pitch = 0

# TCP client settings
SERVER_IP = '192.168.178.41'  # FPGA's IP address
SERVER_PORT = 12345

# Update interval in milliseconds
UPDATE_INTERVAL = 500  # 200 milliseconds
last_update_time = 0

# Initialize pygame and create window
def initialize():
    global font
    pygame.init()
    pygame.display.set_caption("3D Camera Control")
    font = pygame.font.Font(None, 24)
    return pygame.display.set_mode((1300, 900))

# Draw a grid of squares for RGB selection
def draw_color_grid(screen):
    grid_size = 20
    rows = 10
    cols = 10
    start_x, start_y = 1050, 100

    # Draw "Background color" text
    color_text = font.render("Background color", True, (255, 255, 255))
    screen.blit(color_text, (1050, 70))

    for row in range(rows):
        for col in range(cols):
            x = start_x + col * grid_size
            y = start_y + row * grid_size

            if row == 0:
                # Top row for black, white, and shades of gray
                color_value = int(col / (cols - 1) * 255)
                color = (color_value, color_value, color_value)
            else:
                hue = col / cols
                lightness = 1 - (row / rows)
                color = hsv_to_rgb(hue, 1, lightness)
            pygame.draw.rect(screen, color, (x, y, grid_size, grid_size))

def hsv_to_rgb(h, s, v):
    h_i = int(h * 6)
    f = h * 6 - h_i
    p = int(255 * v * (1 - s))
    q = int(255 * v * (1 - f * s))
    t = int(255 * v * (1 - (1 - f) * s))
    v = int(255 * v)
    if h_i == 0:
        return (v, t, p)
    if h_i == 1:
        return (q, v, p)
    if h_i == 2:
        return (p, v, t)
    if h_i == 3:
        return (p, q, v)
    if h_i == 4:
        return (t, p, v)
    if h_i == 5:
        return (v, p, q)

def handle_grid_click(mouse_pos):
    grid_size = 20
    rows = 10
    cols = 10
    start_x, start_y = 1050, 100

    for row in range(rows):
        for col in range(cols):
            x = start_x + col * grid_size
            y = start_y + row * grid_size

            if x <= mouse_pos[0] <= x + grid_size and y <= mouse_pos[1] <= y + grid_size:
                if row == 0:
                    color_value = int(col / (cols - 1) * 255)
                    return (color_value, color_value, color_value)
                else:
                    hue = col / cols
                    lightness = 1 - (row / rows)
                    return hsv_to_rgb(hue, 1, lightness)

    return None

# Display camera position and direction on the game screen
def display_camera_info(screen):
    pos_text = font.render(f"Camera Position: X={camera_pos[0]}, Y={camera_pos[1]}, Z={camera_pos[2]}", True, (255, 255, 255))
    dir_text = font.render(f"Camera Direction: X={camera_front[0]}, Y={camera_front[1]}, Z={camera_front[2]}", True, (255, 255, 255))
    mag_text = font.render(f"Direction Magnitude: {np.linalg.norm(camera_front):.2f}", True, (255, 255, 255))
    screen.blit(pos_text, (10, 10))
    screen.blit(dir_text, (10, 40))
    screen.blit(mag_text, (10, 70))

# Send camera parameters to the server
def send_camera_parameters(client_socket):
    # Create the binary strings
    regfile_0 = '00' + '{0:010b}'.format(camera_front[2]) + '{0:010b}'.format(camera_front[1]) + '{0:010b}'.format(camera_front[0])
    regfile_1 = '00' + '{0:010b}'.format(camera_pos[2]) + '{0:010b}'.format(camera_pos[1]) + '{0:010b}'.format(camera_pos[0])

    # Convert the binary strings to integers
    regfile_0_int = int(regfile_0, 2)
    regfile_1_int = int(regfile_1, 2)

    # Pack the integers as bytes and send them
    data = struct.pack(
        'II',
        regfile_0_int,  # Combined camera direction values
        regfile_1_int,  # Combined camera position values 
    )
    client_socket.sendall(data)

    print("Sent data:")
    print(f"Camera Direction (binary): {regfile_0} -> (int): {regfile_0_int} -> (hex): {regfile_0_int:08X}")
    print(f"Camera Position (binary): {regfile_1} -> (int): {regfile_1_int} -> (hex): {regfile_1_int:08X}")

# Draw sliders for camera parameters
def draw_sliders(screen):
    slider_color = (200, 200, 200)
    slider_handle_color = (100, 100, 100)

    # Camera Position Sliders
    camera_pos_labels = ['X', 'Y', 'Z']
    for i in range(3):
        label = font.render(f"Camera Position {camera_pos_labels[i]}:", True, (255, 255, 255))
        screen.blit(label, (10, 100 + i * 60))
        pygame.draw.rect(screen, slider_color, (200, 100 + i * 60, 300, 20))
        handle_x = 200 + int(camera_pos[i] / 1023 * 300)
        pygame.draw.rect(screen, slider_handle_color, (handle_x, 95 + i * 60, 10, 30))

    # Camera Direction Sliders
    camera_dir_labels = ['X', 'Y', 'Z']
    for i in range(3):
        label = font.render(f"Camera Direction {camera_dir_labels[i]}:", True, (255, 255, 255))
        screen.blit(label, (10, 300 + i * 60))
        pygame.draw.rect(screen, slider_color, (200, 300 + i * 60, 300, 20))
        handle_x = 200 + int(camera_front[i] / 1023 * 300)
        pygame.draw.rect(screen, slider_handle_color, (handle_x, 295 + i * 60, 10, 30))

def handle_slider_click(mouse_pos):
    slider_width = 300
    slider_start_x = 200

    # Camera Position Sliders
    for i in range(3):
        if 100 + i * 60 <= mouse_pos[1] <= 120 + i * 60:
            camera_pos[i] = int((mouse_pos[0] - slider_start_x) / slider_width * 1023)
            camera_pos[i] = np.clip(camera_pos[i], 0, 1023)

    # Camera Direction Sliders
    for i in range(3):
        if 300 + i * 60 <= mouse_pos[1] <= 320 + i * 60:
            camera_front[i] = int((mouse_pos[0] - slider_start_x) / slider_width * 1023)
            camera_front[i] = np.clip(camera_front[i], 0, 1023)

# Main loop
def main():
    global background_color, last_update_time
    screen = initialize()
    clock = pygame.time.Clock()
    running = True
    right_mouse_button_held = False

    # Connect to the server
    client_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    client_socket.connect((SERVER_IP, SERVER_PORT))

    # Send initial parameters and receive the first frame
    send_camera_parameters(client_socket)
    frame_size = 640 * 480 * 3  # Width * Height * 3 (RGB)
    frame_data = b''
    while len(frame_data) < frame_size:
        packet = client_socket.recv(frame_size - len(frame_data))
        if not packet:
            break
        frame_data += packet
    frame = np.frombuffer(frame_data, dtype=np.uint8).reshape((480, 640, 3))
    frame_surface = pygame.image.fromstring(frame.tobytes(), (640, 480), 'RGB')

    # Button settings
    button_font = pygame.font.Font(None, 36)
    button_color = (255, 255, 255)
    button_background_color = (0, 0, 255)

    horizontal_flip_button = pygame.Rect(1050, 500, 200, 50)
    vertical_flip_button = pygame.Rect(1050, 560, 200, 50)
    reset_camera_button = pygame.Rect(1050, 620, 200, 50)

    while running:
        clock.tick(60)
        keys = pygame.key.get_pressed()

        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False
            elif event.type == pygame.MOUSEBUTTONDOWN:
                if event.button == 3:  # Right mouse button
                    right_mouse_button_held = True
                    pygame.mouse.get_rel()  # Reset relative movement on mouse down
                elif event.button == 1:  # Left mouse button
                    if horizontal_flip_button.collidepoint(event.pos):
                        print("Horizontal Flip button clicked")
                    elif vertical_flip_button.collidepoint(event.pos):
                        print("Vertical Flip button clicked")
                    elif reset_camera_button.collidepoint(event.pos):
                        print("Reset Camera button clicked")
                        camera_pos[:] = initial_camera_pos
                        camera_front[:] = initial_camera_front
                        send_camera_parameters(client_socket)
                        frame_data = b''
                        while len(frame_data) < frame_size:
                            packet = client_socket.recv(frame_size - len(frame_data))
                            if not packet:
                                break
                            frame_data += packet
                        frame = np.frombuffer(frame_data, dtype=np.uint8).reshape((480, 640, 3))
                        frame_surface = pygame.image.fromstring(frame.tobytes(), (640, 480), 'RGB')
                    else:
                        new_color = handle_grid_click(pygame.mouse.get_pos())
                        if new_color:
                            background_color = new_color
                        handle_slider_click(pygame.mouse.get_pos())
                        send_camera_parameters(client_socket)
                        frame_data = b''
                        while len(frame_data) < frame_size:
                            packet = client_socket.recv(frame_size - len(frame_data))
                            if not packet:
                                break
                            frame_data += packet
                        frame = np.frombuffer(frame_data, dtype=np.uint8).reshape((480, 640, 3))
                        frame_surface = pygame.image.fromstring(frame.tobytes(), (640, 480), 'RGB')
            elif event.type == pygame.MOUSEBUTTONUP:
                if event.button == 3:  # Right mouse button
                    right_mouse_button_held = False

        if right_mouse_button_held:
            mouse_rel = pygame.mouse.get_rel()
            # process_mouse(mouse_rel) # Commenting out as it's not needed for sliders

        # Clear the screen
        screen.fill(background_color)

        # Display camera position and direction on the game screen
        display_camera_info(screen)

        # Draw the grid pattern for RGB selection
        draw_color_grid(screen)

        # Draw sliders for camera parameters
        draw_sliders(screen)

        # Display the frame received from the server
        screen.blit(frame_surface, (10, 400))

        # Draw buttons
        pygame.draw.rect(screen, button_background_color, horizontal_flip_button)
        pygame.draw.rect(screen, button_background_color, vertical_flip_button)
        pygame.draw.rect(screen, button_background_color, reset_camera_button)

        horizontal_flip_text = button_font.render("Horizontal Flip", True, button_color)
        vertical_flip_text = button_font.render("Vertical Flip", True, button_color)
        reset_camera_text = button_font.render("Reset Camera", True, button_color)

        screen.blit(horizontal_flip_text, (horizontal_flip_button.x + 10, horizontal_flip_button.y + 10))
        screen.blit(vertical_flip_text, (vertical_flip_button.x + 10, vertical_flip_button.y + 10))
        screen.blit(reset_camera_text, (reset_camera_button.x + 10, reset_camera_button.y + 10))

        pygame.display.flip()

    pygame.quit()
    client_socket.close()

if __name__ == "__main__":
    main()
