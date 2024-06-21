import pygame
import numpy as np
import socket
import struct
import threading
from pygame.locals import *

# Initial camera parameters
initial_camera_pos = np.array([450, 600, 300], dtype=np.int32)
initial_camera_front = np.array([0, 0, 90], dtype=np.float32)
initial_camera_up = np.array([0, 1, 0], dtype=np.int32)
up_vector = np.array([0, 1, 0], dtype=np.int32)
right_vector = np.array([1, 0, 0], dtype=np.int32)

# Camera parameters
camera_pos = np.copy(initial_camera_pos)
camera_front = np.copy(initial_camera_front)
camera_up = np.copy(initial_camera_up)

background_color = [30, 30, 30]
frame_background_color = [0, 0, 0]
font = None
movement_speed = 5
mouse_sensitivity = 0.1
yaw = -90
pitch = 0

# TCP client settings
SERVER_IP = '192.168.178.41'  # FPGA's IP address
SERVER_PORT = 12345

# Update interval in milliseconds
UPDATE_INTERVAL = 500  # 500 milliseconds
last_update_time = 0

# Shared variable for frame data
frame_surface = None

# Flag to indicate if camera parameters have changed
camera_params_changed = False

# Variables to store initial yaw and pitch
initial_yaw = yaw
initial_pitch = pitch

# Store the last sent camera direction to detect significant changes
last_sent_camera_front = np.copy(camera_front)

# Define environments with preset camera parameters
environments = {
    "Environment 1": {
        "camera_pos": [250, 512, 0],
        "camera_front": [0, 0, 230]
    },
    "Environment 2": {
        "camera_pos": [100, 300, 50],
        "camera_front": [50, 50, 200]
    },
    "Environment 3": {
        "camera_pos": [400, 600, 100],
        "camera_front": [0, 100, 150]
    }
}

selected_environment = "Environment 1"  # Default selected environment

# Define camera settings with preset parameters
camera_settings = {
    "Preset: Z +ve": {
        "camera_pos": [250, 512, 0],
        "camera_front": [0, 0, 100],
        "right_vector": [1, 0, 0],
        "up_vector": [0, 1, 0]
    },
    "Preset: Z -ve": {
        "camera_pos": [250, 512, 760],
        "camera_front": [0, 0, -100],
        "right_vector": [-1, 0, 0],
        "up_vector": [0, 1, 0]
    },
    "Preset: Y +ve": {
        "camera_pos": [250, 512, 0],
        "camera_front": [0, 1, 0],
        "right_vector": [1, 0, 0],
        "up_vector": [0, 0, -1]
    },
    "Preset: Y -ve": {
        "camera_pos": [250, 512, 0],
        "camera_front": [0, -100, 0],
        "right_vector": [1, 0, 0],
        "up_vector": [0, 0, 1]
    },
    "Preset: X +ve": {
        "camera_pos": [250, 512, 0],
        "camera_front": [100, 0, 0],
        "right_vector": [0, 0, -1],
        "up_vector": [0, 1, 0]
    },
    "Preset: X -ve": {
        "camera_pos": [250, 512, 0],
        "camera_front": [-100, 0, 0],
        "right_vector": [0, 0, 1],
        "up_vector": [0, 1, 0]
    }
}

selected_camera_setting = "Preset: Z +ve"  # Default selected camera setting

# Initialize pygame and create window
def initialize():
    global font
    pygame.init()
    pygame.display.set_caption("FPGA Ray Tracer")
    font = pygame.font.Font(None, 24)
    return pygame.display.set_mode((1300, 1080))

# Draw a grid of squares for RGB selection
def draw_color_grid(screen):
    grid_size = 30
    rows = 10
    cols = 10
    start_x, start_y = 950, 70

    # Draw "Background color" text
    color_text = font.render("Background color", True, (255, 255, 255))
    screen.blit(color_text, (1050, 40))

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
    global camera_params_changed, frame_background_color
    grid_size = 30
    rows = 10
    cols = 10
    start_x, start_y = 950, 70

    for row in range(rows):
        for col in range(cols):
            x = start_x + col * grid_size
            y = start_y + row * grid_size

            if x <= mouse_pos[0] <= x + grid_size and y <= mouse_pos[1] <= y + grid_size:
                if row == 0:
                    color_value = int(col / (cols - 1) * 255)
                    frame_background_color = [color_value, color_value, color_value]
                    camera_params_changed = True
                    return (color_value, color_value, color_value)
                else:
                    hue = col / cols
                    lightness = 1 - (row / rows)
                    frame_background_color = list(hsv_to_rgb(hue, 1, lightness))
                    camera_params_changed = True
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

# Convert camera front vector to yaw and pitch
def camera_front_to_yaw_pitch(camera_front):
    norm_front = camera_front / np.linalg.norm(camera_front)
    yaw = np.degrees(np.arctan2(norm_front[2], norm_front[0]))
    pitch = np.degrees(np.arcsin(norm_front[1]))
    return yaw, pitch

def send_camera_parameters(client_socket):
    global camera_front

    # Ensure all parameters are strictly integers
    camera_front_int = camera_front.astype(np.int32)
    camera_pos_int = camera_pos.astype(np.int32)

    # Print the values before sending
    print(f"Camera Front (float): {camera_front}")
    print(f"Camera Front (int): {camera_front_int}")
    print(f"Camera Position: {camera_pos_int}")

    # Create the binary strings
    regfile_0 = '00000000' + to_12bit_binary(camera_front_int[2]) + to_12bit_binary(camera_front_int[1])
    regfile_1 = '00000000' + to_12bit_binary(camera_front_int[0]) + to_12bit_binary(camera_pos_int[2])
    regfile_2 = '00000000' + to_12bit_binary(camera_pos_int[1]) + to_12bit_binary(camera_pos_int[0])
    regfile_3 = '00000000' + to_12bit_binary(right_vector[2]) + to_12bit_binary(right_vector[1])
    regfile_4 = '00000000' + to_12bit_binary(right_vector[0]) + to_12bit_binary(up_vector[2])
    regfile_5 = '00000000' + to_12bit_binary(up_vector[1]) + to_12bit_binary(up_vector[0])
    regfile_6 = '00000000' + '{:08b}'.format(frame_background_color[2]) + '{:08b}'.format(frame_background_color[1]) + '{:08b}'.format(frame_background_color[0])
    # Convert the binary strings to integers
    regfile_0_int = int(regfile_0, 2)
    regfile_1_int = int(regfile_1, 2)
    regfile_2_int = int(regfile_2, 2)
    regfile_3_int = int(regfile_3, 2)
    regfile_4_int = int(regfile_4, 2)
    regfile_5_int = int(regfile_5, 2)
    regfile_6_int = int(regfile_6, 2)
    print("COLOR: ", frame_background_color[0], frame_background_color[1], frame_background_color[2])

    # Pack the integers as bytes and send them
    data = struct.pack(
        'IIIIIII',
        regfile_0_int,  # Combined camera direction values
        regfile_1_int,  # Combined camera position values 
        regfile_2_int,
        regfile_3_int,
        regfile_4_int,
        regfile_5_int,
        regfile_6_int
    )
    client_socket.sendall(data)

    print("Sent data!")
# Helper function to convert to 12-bit signed binary string
def to_12bit_binary(value):
    if value < -2048 or value > 2047:
        raise ValueError("Value out of range for 12-bit signed integer")
    if value < 0:
        value = (1 << 12) + value
    return format(value & 0xFFF, '012b')

# Draw sliders for camera parameters
def draw_sliders(screen):
    slider_color = (200, 200, 200)
    slider_handle_color = (100, 100, 100)

    # Camera Position Sliders
    camera_pos_labels = ['X', 'Y', 'Z']
    for i in range(3):
        label = font.render(f"Camera Position {camera_pos_labels[i]}:", True, (255, 255, 255))
        screen.blit(label, (10, 610 + i * 60))
        pygame.draw.rect(screen, slider_color, (200, 610 + i * 60, 600, 20))  # Adjust width for visual clarity
        handle_x = 200 + int((camera_pos[i] / 1023) * 600)  # Range from 0 to 600
        pygame.draw.rect(screen, slider_handle_color, (handle_x, 605 + i * 60, 10, 30))

    # Camera Direction Sliders
    camera_dir_labels = ['X', 'Y', 'Z']
    for i in range(3):
        label = font.render(f"Camera Direction {camera_dir_labels[i]}:", True, (255, 255, 255))
        screen.blit(label, (10, 790 + i * 60))
        pygame.draw.rect(screen, slider_color, (200, 790 + i * 60, 600, 20))  # Adjust width for visual clarity
        handle_x = 200 + int((camera_front[i] / 1023 + 1) * 300)  # Center at 300 for 0 value
        pygame.draw.rect(screen, slider_handle_color, (handle_x, 785 + i * 60, 10, 30))

    # Camera Magnitude Slider
    label = font.render("Camera Magnitude:", True, (255, 255, 255))
    screen.blit(label, (10, 970))
    pygame.draw.rect(screen, slider_color, (200, 970, 600, 20))
    handle_x = 200 + int((np.linalg.norm(camera_front) / 1023) * 600)  # Range from 0 to 600
    pygame.draw.rect(screen, slider_handle_color, (handle_x, 965, 10, 30))

def handle_slider_click(mouse_pos):
    global camera_params_changed
    slider_width = 600  # Adjusted width
    slider_start_x = 200

    # Camera Position Sliders
    for i in range(3):
        if 610 + i * 60 <= mouse_pos[1] <= 630 + i * 60:
            value = int((mouse_pos[0] - slider_start_x) / slider_width * 1023)  # Only positive range
            camera_pos[i] = np.clip(value, 0, 1023)  # Ensure non-negative values
            camera_params_changed = True

    # Camera Direction Sliders
    for i in range(3):
        if 790 + i * 60 <= mouse_pos[1] <= 810 + i * 60:
            value = int((mouse_pos[0] - slider_start_x) / slider_width * 2046) - 1023  # Adjust for negative range
            camera_front[i] = np.clip(value, -1023, 1023)
            camera_params_changed = True

    # Camera Magnitude Slider
    if 970 <= mouse_pos[1] <= 990:
        magnitude = int((mouse_pos[0] - slider_start_x) / slider_width * 1023)
        magnitude = np.clip(magnitude, 0, 1023)
        camera_front_normalized = camera_front / np.linalg.norm(camera_front)
        camera_front[:] = (camera_front_normalized * magnitude).astype(np.int32)
        camera_params_changed = True

# Thread function to handle receiving frames from the server
def receive_frames(client_socket):
    global frame_surface
    frame_size = 512 * 512 * 3  # Width * Height * 3 (RGB)

    while True:
        frame_data = b''
        while len(frame_data) < frame_size:
            packet = client_socket.recv(frame_size - len(frame_data))
            if not packet:
                return
            frame_data += packet
        frame = np.frombuffer(frame_data, dtype=np.uint8).reshape((512, 512, 3))
        frame_surface = pygame.image.frombuffer(frame.tobytes(), (512, 512), 'RGB')

# Thread function to handle sending camera parameters at regular intervals
def send_camera_parameters_periodically(client_socket):
    global last_update_time, camera_params_changed, last_sent_camera_front
    while True:
        current_time = pygame.time.get_ticks()
        if camera_params_changed and current_time - last_update_time > UPDATE_INTERVAL:
            send_camera_parameters(client_socket)
            last_update_time = current_time
            camera_params_changed = False
            last_sent_camera_front = np.copy(camera_front)
        pygame.time.delay(UPDATE_INTERVAL)

# Process keyboard input for camera movement
def process_keyboard_input(keys):
    global camera_pos, camera_params_changed, camera_front, right_vector, up_vector
    if keys[K_w]:
        camera_pos[:] += (camera_front / np.linalg.norm(camera_front) * movement_speed).astype(np.int32)
        camera_params_changed = True
    if keys[K_s]:
        camera_pos[:] -= (camera_front / np.linalg.norm(camera_front) * movement_speed).astype(np.int32)
        camera_params_changed = True
    if keys[K_a]:
        camera_pos[:] -= (right_vector / np.linalg.norm(right_vector) * movement_speed).astype(np.int32)
        camera_params_changed = True
    if keys[K_d]:
        camera_pos[:] += (right_vector / np.linalg.norm(right_vector) * movement_speed).astype(np.int32)
        camera_params_changed = True

    # Clamp the camera position values to be non-negative
    camera_pos[:] = np.clip(camera_pos, 0, None)

# Process mouse input for camera direction
def process_mouse(mouse_rel):
    global yaw, pitch, camera_front, camera_params_changed, initial_yaw, initial_pitch, last_sent_camera_front
    xoffset, yoffset = mouse_rel
    xoffset *= mouse_sensitivity
    yoffset *= mouse_sensitivity

    yaw += xoffset
    pitch -= yoffset

    if pitch > 89.0:
        pitch = 89.0
    if pitch < -89.0:
        pitch = -89.0

    # Maintain the original magnitude of the camera_front
    original_magnitude = np.linalg.norm(camera_front)
    print(f"Original Magnitude: {original_magnitude}")

    # Calculate the new front vector using yaw and pitch
    front = np.array([
        np.cos(np.radians(yaw)) * np.cos(np.radians(pitch)),
        np.sin(np.radians(pitch)),
        np.sin(np.radians(yaw)) * np.cos(np.radians(pitch))
    ])
    print(f"New Front (before normalization): {front}")

    # Normalize the front vector to maintain direction but not magnitude
    front_normalized = front / np.linalg.norm(front)
    print(f"New Front (normalized): {front_normalized}")

    # Scale the normalized front vector to the original magnitude
    camera_front = (front_normalized * original_magnitude).astype(np.float32)  # Keep as float for now
    print(f"New Camera Front (scaled): {camera_front}")

    if not np.array_equal(camera_front, last_sent_camera_front):
        camera_params_changed = True

# Draw dropdown menu
def draw_dropdown_menu(screen, dropdown_type):
    global selected_environment, selected_camera_setting
    font = pygame.font.Font(None, 36)
    dropdown_color = (100, 100, 100)
    text_color = (255, 255, 255)

    if dropdown_type == "environment":
        dropdown_rect = pygame.Rect(10, 100, 300, 50)
        pygame.draw.rect(screen, dropdown_color, dropdown_rect)
        text = font.render(selected_environment, True, text_color)
        screen.blit(text, (15, 105))
        return dropdown_rect
    elif dropdown_type == "camera_setting":
        dropdown_rect = pygame.Rect(10, 160, 300, 50)
        pygame.draw.rect(screen, dropdown_color, dropdown_rect)
        text = font.render(selected_camera_setting, True, text_color)
        screen.blit(text, (15, 165))
        return dropdown_rect

# Handle dropdown menu click
def handle_dropdown_click(mouse_pos, dropdown_rect, dropdown_type, screen, client_socket):
    global selected_environment, selected_camera_setting, camera_pos, camera_front
    font = pygame.font.Font(None, 36)
    if dropdown_rect.collidepoint(mouse_pos):
        menu_pos = dropdown_rect.topleft[0]
        menu_width = dropdown_rect.width
        menu_height = 50 * (len(environments) if dropdown_type == "environment" else len(camera_settings))
        menu_rect = pygame.Rect(menu_pos, dropdown_rect.bottom, menu_width, menu_height)
        pygame.draw.rect(screen, (150, 150, 150), menu_rect)
        items = environments if dropdown_type == "environment" else camera_settings
        for i, item in enumerate(items):
            item_rect = pygame.Rect(menu_pos, dropdown_rect.bottom + i * 50, menu_width, 50)
            pygame.draw.rect(screen, (200, 200, 200), item_rect)
            text = font.render(item, True, (0, 0, 0))
            screen.blit(text, (menu_pos + 5, dropdown_rect.bottom + i * 50 + 5))
        pygame.display.update()

        dropdown_open = True
        while dropdown_open:
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    pygame.quit()
                    exit()
                elif event.type == pygame.MOUSEBUTTONDOWN:
                    if not menu_rect.collidepoint(event.pos):
                        dropdown_open = False
                    else:
                        for i, item in enumerate(items):
                            item_rect = pygame.Rect(menu_pos, dropdown_rect.bottom + i * 50, menu_width, 50)
                            if item_rect.collidepoint(event.pos):
                                if dropdown_type == "environment":
                                    selected_environment = item
                                elif dropdown_type == "camera_setting":
                                    selected_camera_setting = item
                                    camera_pos[:] = camera_settings[item]["camera_pos"]
                                    camera_front[:] = camera_settings[item]["camera_front"]
                                    up_vector[:] = camera_settings[item]["up_vector"]
                                    right_vector[:] = camera_settings[item]["right_vector"]
                                    send_camera_parameters(client_socket)
                                dropdown_open = False
                        pygame.draw.rect(screen, background_color, menu_rect)
                        draw_dropdown_menu(screen, "environment")
                        draw_dropdown_menu(screen, "camera_setting")

# Main loop
def main():
    global background_color, last_update_time, frame_surface, camera_params_changed, yaw, pitch, initial_yaw, initial_pitch
    screen = initialize()
    clock = pygame.time.Clock()
    running = True
    right_mouse_button_held = False

    # Connect to the server
    client_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    client_socket.connect((SERVER_IP, SERVER_PORT))

    # Send initial camera parameters
    send_camera_parameters(client_socket)

    # Start the frame receiving thread
    threading.Thread(target=receive_frames, args=(client_socket,), daemon=True).start()
    threading.Thread(target=send_camera_parameters_periodically, args=(client_socket,), daemon=True).start()

    # Wait for the first frame to be received
    while frame_surface is None:
        pygame.time.delay(100)  # Short delay to yield control and wait for the frame

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
        process_keyboard_input(keys)

        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False
            elif event.type == pygame.MOUSEBUTTONDOWN:
                if event.button == 3:  # Right mouse button
                    right_mouse_button_held = True
                    pygame.mouse.get_rel()  # Reset relative movement on mouse down
                    initial_yaw, initial_pitch = camera_front_to_yaw_pitch(camera_front)  # Initialize yaw and pitch from current direction
                    yaw = initial_yaw
                    pitch = initial_pitch
                elif event.button == 1:  # Left mouse button
                    env_dropdown_rect = draw_dropdown_menu(screen, "environment")
                    cam_setting_dropdown_rect = draw_dropdown_menu(screen, "camera_setting")
                    if env_dropdown_rect.collidepoint(event.pos):
                        handle_dropdown_click(event.pos, env_dropdown_rect, "environment", screen, client_socket)
                    elif cam_setting_dropdown_rect.collidepoint(event.pos):
                        handle_dropdown_click(event.pos, cam_setting_dropdown_rect, "camera_setting", screen, client_socket)
                    elif horizontal_flip_button.collidepoint(event.pos):
                        print("Horizontal Flip button clicked")
                        for counter, value in enumerate(right_vector):
                            right_vector[counter] = value * -1
                        send_camera_parameters(client_socket)
                    elif vertical_flip_button.collidepoint(event.pos):
                        print("Vertical Flip button clicked")
                        for counter, value in enumerate(up_vector):
                            up_vector[counter] = value * -1
                        send_camera_parameters(client_socket)
                    elif reset_camera_button.collidepoint(event.pos):
                        print("Reset Camera button clicked")
                        camera_pos[:] = initial_camera_pos
                        camera_front[:] = initial_camera_front
                        yaw = -90
                        pitch = 0
                        up_vector[:] = [0, 1, 0]
                        right_vector[:] = [1, 0, 0]
                        send_camera_parameters(client_socket)
                    else:
                        new_color = handle_grid_click(pygame.mouse.get_pos())
                        if new_color:
                            frame_background_color = new_color
                            send_camera_parameters(client_socket)
                        handle_slider_click(pygame.mouse.get_pos())

            elif event.type == pygame.MOUSEBUTTONUP:
                if event.button == 3:  # Right mouse button
                    right_mouse_button_held = False

        if right_mouse_button_held:
            mouse_rel = pygame.mouse.get_rel()
            process_mouse(mouse_rel)

        # Clear the screen
        screen.fill(background_color)

        # Display camera position and direction on the game screen
        display_camera_info(screen)

        # Display the frame received from the server
        if frame_surface:
            frame_pos_x = (screen.get_width() - frame_surface.get_width()) // 2
            screen.blit(frame_surface, (frame_pos_x, 70))

        # Draw the grid pattern for RGB selection
        draw_color_grid(screen)

        # Draw sliders for camera parameters
        draw_sliders(screen)

        # Draw the dropdown menus
        draw_dropdown_menu(screen, "environment")
        draw_dropdown_menu(screen, "camera_setting")

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