import re

class OctreeNode:
    def __init__(self, center, extents, material_id, mid1, dividing):
        self.center = center
        self.extents = extents
        self.material_id = material_id
        self.mid1 = mid1
        self.dividing = dividing
        self.children = []

def parse_node(lines, idx, level):
    node_info = re.match(r'\s*Node Bounds: Center: \(([^)]+)\), Extents: \(([^)]+)\)', lines[idx].strip())
    if not node_info:
        raise ValueError(f"Invalid node format at line {idx}: {lines[idx]}")
    
    center = tuple(map(float, node_info.group(1).split(', ')))
    extents = tuple(map(float, node_info.group(2).split(', ')))

    material_id = re.match(r'\s*Material ID: (.+)', lines[idx + 1].strip()).group(1)
    mid1 = re.match(r'\s*Mid1: (.+)', lines[idx + 2].strip()).group(1) == 'True'
    dividing = re.match(r'\s*Dividing: (.+)', lines[idx + 3].strip()).group(1) == 'True'

    node = OctreeNode(center, extents, material_id, mid1, dividing)

    idx += 4
    while idx < len(lines) and lines[idx].startswith(' ' * (level + 2)):
        child, idx = parse_node(lines, idx, level + 2)
        node.children.append(child)

    return node, idx

def parse_octree_structure(file_path):
    with open(file_path, 'r') as file:
        lines = file.readlines()
    root, _ = parse_node(lines, 0, 0)
    return root

def assign_addresses(node, address_map, next_address):
    address_map[id(node)] = next_address
    if node.dividing:
        child_base_address = next_address + 32  # Reserve block for 8 children
        for i, child in enumerate(node.children):
            assign_addresses(child, address_map, child_base_address + i * 32)
    return next_address + (32 if node.dividing else 4)

def generate_mem_lines(node, address_map, level=0):
    mem_lines = []
    base_address = address_map[id(node)]
    if node.dividing:
        for i, child in enumerate(node.children):
            child_address = address_map[id(child)]
            if child.dividing:
                mem_lines.append(f"{child_address:08X} // lvl{level} child{i} (0x{child_address:08X})")
            else:
                material_value = 0 if child.material_id == 'None' else 1
                mem_lines.append(f"{0xFFFFFF00 + material_value:08X} // lvl{level} child{i} (0x{child_address:08X})")
        # Ensure blocks of 8
        for i in range(len(node.children), 8):
            mem_lines.append(f"FFFFFF00 // lvl{level} child{i} (padding)")

        for i, child in enumerate(node.children):
            if child.dividing:
                mem_lines.extend(generate_mem_lines(child, address_map, level + 1))
    return mem_lines

def print_tree(node, level=0):
    indent = '  ' * level
    print(f"{indent}Node Bounds: Center: {node.center}, Extents: {node.extents}")
    print(f"{indent}Material ID: {node.material_id}")
    print(f"{indent}Mid1: {node.mid1}")
    print(f"{indent}Dividing: {node.dividing}")
    # print(f"{indent}Address: 0x{node.address:08X}")
    for child in node.children:
        print_tree(child, level + 1)

# Change this to the path of your input .txt file
input_file_path = '/Users/yanniszioulis/Documents/raytracinggithub/ray-tracing/mem-parser/OctreeInfo.txt'

octree_root = parse_octree_structure(input_file_path)
address_map = {}
assign_addresses(octree_root, address_map, 0x20000000)
mem_lines = generate_mem_lines(octree_root, address_map)

with open("/Users/yanniszioulis/Documents/raytracinggithub/ray-tracing/mem-parser/octree.mem", "w") as mem_file:
    mem_file.write("\n".join(mem_lines))

# Print the tree structure to the console
print_tree(octree_root)





