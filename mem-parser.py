# Define the input and output file names
input_file = '/Users/yanniszioulis/Documents/raytracinggithub/ray-tracing/mem-parser/octree_output.txt'
intermediate_file = '/Users/yanniszioulis/Documents/raytracinggithub/ray-tracing/mem-parser/intermediate-octree_output.txt'
final_output_file = '/Users/yanniszioulis/Documents/raytracinggithub/ray-tracing/mem-parser/effdog.mem'


# Function to convert an integer to 32-bit hexadecimal in the required format
def to_hex_32bit(value):
    return f"{value:08x}"

# Step 1: Add line numbers to the input file
def add_line_numbers(input_file, output_file):
    with open(input_file, 'r') as file:
        lines = file.readlines()
    
    with open(output_file, 'w') as file:
        for i, line in enumerate(lines):
            file.write(f"{i}: {line}")

# Step 2: Create a dictionary to map node numbers to their line indices
def create_node_mapping(file_with_lines):
    node_to_line_index = {}
    with open(file_with_lines, 'r') as file:
        lines = file.readlines()
    
    for i, line in enumerate(lines):
        parts = line.split(':')
        node_number = int(parts[1].split()[1])
        node_to_line_index[node_number] = i
    
    return node_to_line_index, lines

# Step 3: Update First Child Index and format lines
def update_and_format_lines(node_to_line_index, lines, output_file):
    with open(output_file, 'w') as file:
        for index, line_content in enumerate(lines):
            if "First Child Index" in line_content:
                parts = line_content.split('First Child Index = ')
                first_child_index = int(parts[1].strip())
                if first_child_index in node_to_line_index:
                    hex_index = to_hex_32bit(node_to_line_index[first_child_index])
                    updated_line = f"{hex_index}\n"
                else:
                    updated_line = line_content
            else:
                if "Material ID = None" in line_content:
                    updated_line = f"FFFFFFF0\n"
                elif ("Material ID = BrownMaterial (Instance)" in line_content):
                    updated_line = f"FFFFFFF1\n"
                elif ("Material ID = BeigeMaterial (Instance)" in line_content):
                    updated_line = f"FFFFFFF2\n"
                elif ("Material ID = WhiteMaterial (Instance)" in line_content):
                    updated_line = f"FFFFFFF3\n"
                elif ("Material ID = BlackMaterial (Instance)" in line_content):
                    updated_line = f"FFFFFFF4\n"
                elif ("Material ID = DarkBeigeMaterial (Instance)" in line_content):
                    updated_line = f"FFFFFFF5\n"
            file.write(updated_line)

# Main function to execute all steps
def main():
    add_line_numbers(input_file, intermediate_file)
    node_to_line_index, lines = create_node_mapping(intermediate_file)
    update_and_format_lines(node_to_line_index, lines, final_output_file)
    print(f"Processed {len(lines)} lines and saved to {final_output_file}")

if __name__ == "__main__":
    main()


