#include <verilated.h>
#include "VColorGenerator.h" // Verilator-generated header
#include <fstream>
#include <vector>
#include <filesystem>

// Function to write the image to a PPM file
void write_ppm(const std::string &filename, const std::vector<uint8_t> &image, int width, int height) {
    std::ofstream ofs(filename, std::ios::out | std::ios::binary);
    ofs << "P6\n" << width << " " << height << "\n255\n";
    ofs.write(reinterpret_cast<const char*>(image.data()), image.size());
}

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    VColorGenerator* color_gen = new VColorGenerator;

    const int width = 1024;
    const int height = 1024;
    std::vector<uint8_t> image(width * height * 3);

    // Create the output directory if it doesn't exist
    std::filesystem::create_directory("output");

    for (int y = 0; y < height; ++y) {
        for (int x = 0; x < width; ++x) {
            color_gen->x = x;
            color_gen->y = y;
            color_gen->eval();

            int index = (y * width + x) * 3;
            image[index] = color_gen->r;
            image[index + 1] = color_gen->g;
            image[index + 2] = color_gen->b;
        }
    }

    write_ppm("output/output.ppm", image, width, height);

    delete color_gen;
    return 0;
}

