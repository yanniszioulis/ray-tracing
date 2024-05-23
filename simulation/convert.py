import os
from PIL import Image

# Define the input and output directories
input_dir = 'output'
output_dir = 'images'

# Create the output directory if it doesn't exist
os.makedirs(output_dir, exist_ok=True)

# Loop through all files in the input directory
for filename in os.listdir(input_dir):
    if filename.endswith('.ppm'):
        # Construct the full path to the input file
        input_filepath = os.path.join(input_dir, filename)
        
        # Open the PPM file
        with Image.open(input_filepath) as img:
            # Construct the full path to the output file
            output_filepath = os.path.join(output_dir, filename.replace('.ppm', '.png'))
            
            # Save the image as PNG
            img.save(output_filepath, 'PNG')
            
        print(f'Converted {input_filepath} to {output_filepath}')

print('All PPM files have been converted to PNG.')
