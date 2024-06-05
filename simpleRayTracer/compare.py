def compare_ppm_files(file1_path, file2_path):
    try:
        with open(file1_path, 'r') as file1, open(file2_path, 'r') as file2:
            diff_count = 0

            # Reading the header of the PPM files
            header1 = [file1.readline().strip() for _ in range(3)]
            header2 = [file2.readline().strip() for _ in range(3)]

            if header1 != header2:
                print("PPM headers are different. Files might be incompatible for line-by-line comparison.")
                return

            # Compare the rest of the lines (pixel data)
            line_num = 4  # Starting line number after the header
            for line1, line2 in zip(file1, file2):
                if line1 != line2:
                    diff_count += 1
                    print(f"Difference found at line {line_num}")
                line_num += 1

            # Check if file1 has more lines
            for line1 in file1:
                diff_count += 1
                print(f"Difference found at line {line_num} (extra line in first file)")
                line_num += 1

            # Check if file2 has more lines
            for line2 in file2:
                diff_count += 1
                print(f"Difference found at line {line_num} (extra line in second file)")
                line_num += 1

            print(f"Total number of different lines: {diff_count}")
            return diff_count

    except FileNotFoundError as e:
        print(f"Error: {e}")
    except Exception as e:
        print(f"An error occurred: {e}")

# Example usage:
file1_path = '/home/snesamal/Documents/project/ray-tracing/simpleRayTracer/output.ppm'
file2_path = '/home/snesamal/Documents/project/ray-tracing/simpleRayTracer/output1.ppm'
compare_ppm_files(file1_path, file2_path)
