from PIL import Image

# Open the PPM file
ppm_image = Image.open("output.ppm")

# Save the image as a PNG file
ppm_image.save("output.png", "PNG")

print("Conversion from PPM to PNG completed successfully.")