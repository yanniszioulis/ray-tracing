def read_hex_file(filename):
    with open(filename, 'r') as file:
        lines = file.readlines()
    hex_values = [line.strip() for line in lines]
    return hex_values

def split_rgb(hex_values):
    rgb_values = []
    for hex_value in hex_values:
        hex_value = hex_value.strip()
        if len(hex_value) == 8:
            rgb_values.append(hex_value[:2])  # R1
            rgb_values.append(hex_value[2:4])  # G1
            rgb_values.append(hex_value[4:6])  # B1
            rgb_values.append(hex_value[6:8])  # R2
        elif len(hex_value) == 6:
            rgb_values.append(hex_value[:2])  # R1
            rgb_values.append(hex_value[2:4])  # G1
            rgb_values.append(hex_value[4:6])  # B1
    return rgb_values

def write_ppm(filename, rgb_values, width, height):
    max_pixels = width * height * 3
    rgb_values = rgb_values[:max_pixels]
    
    with open(filename, 'w') as ppm_file:
        ppm_file.write(f"P3\n{width} {height}\n255\n")
        for i in range(0, len(rgb_values), 3):
            r = int(rgb_values[i], 16)
            g = int(rgb_values[i + 1], 16)
            b = int(rgb_values[i + 2], 16)
            ppm_file.write(f"{r} {g} {b}\n")

if __name__ == "__main__":
    hex_values = read_hex_file("out_stream_tdata.txt")
    rgb_values = split_rgb(hex_values)
    write_ppm("output.ppm", rgb_values, 200, 200)
