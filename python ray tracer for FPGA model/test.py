from turtle import pos
import numpy as np
from PIL import Image

coord_bit_length = 2

cam_pos = np.array([3, 2, 0])     # Camera position in world space
cam_norm = np.array([0, 0, 1])    # Camera direction vector 
cam_up = np.array([0, 1, 0])
cam_right = np.cross(cam_norm, cam_up)

im_height = 72
im_width = 128

# Placeholder for image output
image = np.zeros((im_height, im_width, 3), dtype=np.uint8)  # Assuming RGB image

octree = [0, 0, 0, 0, 0, 0, 0, 1]   # Back top right corner is white cube
material_table = [[0, 0, 0], [255, 255, 255]]  # 0 for nothing, 1 for white

def roundPosition(position):
    return np.round(position).astype(int)

def toBinaryStr(value, bit_length):
    return format(value, f'0{bit_length}b')

def withinAABB(position, aabb_min, aabb_max):
    return np.all(position >= aabb_min) and np.all(position <= aabb_max)

def justOutsideAABB(position, aabb_min, aabb_max):
    return np.any(position == aabb_min - 1) or np.any(position == aabb_max + 1)

for y in range(im_height):
    for x in range(im_width):
        centered_x = x - (im_width / 2)
        centered_y = (im_height / 2) - y
        ray_direction = (cam_right * centered_x + cam_up * centered_y + cam_norm)
        ray_direction = ray_direction / np.linalg.norm(ray_direction)

        # Initialize ray position at camera position
        position = np.copy(cam_pos)
        
        # Round position coordinates to nearest integer
        position = roundPosition(position)

        x_bin = toBinaryStr(position[0], coord_bit_length)
        y_bin = toBinaryStr(position[1], coord_bit_length)
        z_bin = toBinaryStr(position[2], coord_bit_length)

        depth = 0
        world_size = 2**coord_bit_length
        oct_size = world_size
        aabb_min = np.array([0, 0, 0], dtype=int)
        aabb_max = np.array([oct_size - 1, oct_size - 1, oct_size - 1], dtype=int)
        world_min = aabb_min
        world_max = aabb_max

        # Start at root 
        node = octree


        # ERROR IS WITHIN THIS WHILE LOOP
        # YOU CAN ENTER AN INFINITE LOOP SINCE THE BOUNDING BOX NEEDS TO BE UPDATED 
        # BUT IF YOU DONT CHECK THE NEW OCTANT, THEN THE VARIABLES ARE UPDATED
        while withinAABB(position, world_min, world_max):
            
            print(f"Im within the world and my position is {position}")
            octant = int(z_bin[depth] + y_bin[depth] + x_bin[depth], 2)

            ## recalculate AABB, consider case where ray has come in from adjacent AABB
            # maybe right a seperate function for identifying leaf node from position on each iteration

            while isinstance(node, list) and depth < coord_bit_length:
                # Determine the current octant
                octant = int(z_bin[depth] + y_bin[depth] + x_bin[depth], 2)
                depth += 1
                oct_size /= 2

                # Update AABB
                aabb_min = aabb_min + (oct_size * np.array([int(x_bin[depth - 1]), int(y_bin[depth - 1]), int(z_bin[depth - 1])])).astype(int)
                aabb_max = aabb_min + np.array([oct_size - 1, oct_size - 1, oct_size - 1]).astype(int)
                node = node[octant]


            print(f"This space is: {node}, and octant: {octant}")

            if isinstance(node, int):
                if node == 0:
                    # Scale direction vector until longer than oct_size
                    while np.linalg.norm(ray_direction) < oct_size:
                        ray_direction *= 2

                    # Step until position outside AABB
                    print(f"ray direction before leaving is: {ray_direction}")
                    while not justOutsideAABB(position, aabb_min, aabb_max):
                        print(f"Ray position: {position}, AABB_min: {aabb_min}, AABB_max: {aabb_max}")
                        temp_position = position + ray_direction
                        temp_position = roundPosition(temp_position)
                        print(f"stepped to: {temp_position}, from octant {octant}")
                        if withinAABB(temp_position, aabb_min, aabb_max) or justOutsideAABB(temp_position, aabb_min, aabb_max):
                            position = temp_position
                        ray_direction /= 2
                        print(f"ray direction is: {ray_direction}")
                    
                    print(f"just exited octant {octant} at {position}, this octant is {node}")
                    print("")

                if node > 0:
                    # Return colour from material table
                    print("Colour found at pixel:", x, y, "Node:", node)
                    colour = material_table[node]
                    break
        else:
            colour = [0, 0, 0]  # Ray outside AABB, return black 

        image[y, x] = colour

print("done")
img = Image.fromarray(image, 'RGB')
img.save('ray_traced_image.png')
img.show()
