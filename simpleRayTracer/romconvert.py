def convert_hex_file(input_file, output_file):
    try:
        with open(input_file, 'r') as infile, open(output_file, 'w') as outfile:
            lines = infile.readlines()
            for line_number, hex_number in enumerate(lines):
                hex_number = hex_number.strip()  # Remove any leading/trailing whitespace
                outfile.write(f"rom_array[{line_number}] = 32'h{hex_number};\n")
        print(f"Conversion successful. Output written to {output_file}")
    except Exception as e:
        print(f"An error occurred: {e}")

# Example usage
input_file = 'octree.txt'  # Replace with your input file name
output_file = 'out.txt'  # Replace with your desired output file name
convert_hex_file(input_file, output_file)
