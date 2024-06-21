import numpy as np
from PIL import Image

coord_bit_length = 10 

cam_pos = np.array([200, 300, 0]) 
cam_norm = np.array([0, 0, 100]) 
cam_up = np.array([0, 1, 0]) 
cam_right = np.array([1, 0, 0]) 

im_height = 256
im_width = 256


octree = [0, 0, 0, 0, 0, 2, 3, 1] 
material_table = [[0, 0, 0], [255, 255, 255], [0, 255, 0], [0,0,255], [255,0,0]]  # 0 black, 1  white, 2 green, 3 blue, 4 red


image = np.zeros((im_height, im_width, 3), dtype=np.uint8) 

def roundPosition(position):
    return np.round(position).astype(int)

def toBinaryStr(value, bit_length):
    return format(value, f'0{bit_length}b')

def withinAABB(position, aabb_min, aabb_max):
    return np.all(position >= aabb_min) and np.all(position <= aabb_max)

def justOutsideAABB(position, aabb_min, aabb_max):
    return np.any(position == aabb_min - 1) or np.any(position == aabb_max + 1)

def traverseTree(ray_pos, node, oct_size, aabb_min, aabb_max):
    depth = 0
    x_bin = toBinaryStr(ray_pos[0], coord_bit_length)
    y_bin = toBinaryStr(ray_pos[1], coord_bit_length)
    z_bin = toBinaryStr(ray_pos[2], coord_bit_length)
    while isinstance(node, list) and depth < coord_bit_length:
        octant = int(z_bin[depth] + y_bin[depth] + x_bin[depth], 2)
        depth += 1
        oct_size /= 2

        aabb_min = aabb_min + (oct_size * np.array([int(x_bin[depth - 1]), int(y_bin[depth - 1]), int(z_bin[depth - 1])])).astype(int)
        aabb_max = aabb_min + np.array([oct_size - 1, oct_size - 1, oct_size - 1]).astype(int)
        node = node[octant]
    return node, oct_size, aabb_min, aabb_max

def stepRay(ray_pos, ray_dir, oct_size, aabb_min, aabb_max):
    while np.linalg.norm(ray_dir) < oct_size:
        ray_dir *= 2
    while not justOutsideAABB(ray_pos, aabb_min, aabb_max):
        temp_position = ray_pos + ray_dir
        temp_position = roundPosition(temp_position)
        if withinAABB(temp_position, aabb_min, aabb_max) or justOutsideAABB(temp_position, aabb_min, aabb_max):
            ray_pos = temp_position
        ray_dir /= 2
    return ray_pos

for y in range(im_height):
    for x in range(im_width):
        #print(x, y)
        centered_x = x - (im_width / 2)
        centered_y = (im_height / 2) - y
        ray_dir = (cam_right * centered_x + cam_up * centered_y + cam_norm)
        #ray_dir = ray_dir / np.linalg.norm(ray_dir)

        ray_pos = np.copy(cam_pos)
        
        ray_pos = roundPosition(ray_pos)
        
        world_size = 2**coord_bit_length
        world_min = np.array([0, 0, 0], dtype=int)
        world_max = np.array([world_size - 1, world_size - 1, world_size - 1], dtype=int)
        aabb_min = world_min
        aabb_max = world_max

        root = octree

        while withinAABB(ray_pos, world_min, world_max):
            
            mid, oct_size, aabb_min, aabb_max = traverseTree(ray_pos, root, world_size, world_min, world_max)

            if mid == 0:
                ray_pos = stepRay(ray_pos, ray_dir, oct_size, aabb_min, aabb_max)

            if mid > 0:
                print("Colour found at pixel:", x, y, "Node:", mid)
                colour = material_table[mid]
                break
        else:
            colour = [0, 0, 0]  # Ray outside world, return black 

        image[y, x] = colour

print("done")
img = Image.fromarray(image, 'RGB')
img.save('ray_traced_image.png')
img.show()