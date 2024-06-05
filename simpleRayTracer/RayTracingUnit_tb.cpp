#include "verilated.h"
#include "VRayTracingUnit.h" // This should be the name of the generated header file
#include "verilated_vcd_c.h"
#include <iostream>
#include <fstream>
#include <chrono>

int main(int argc, char** argv, char** env) {
    // Initialize Verilator
    int count = 0;
    int pixels = 0;
    Verilated::commandArgs(argc, argv);

    // Create an instance of the module
    VRayTracingUnit* top = new VRayTracingUnit;

    Verilated::traceEverOn(true);
    VerilatedVcdC* tfp = new VerilatedVcdC;
    top->trace (tfp, 99);
    tfp->open("RayTracingUnit.vcd");

    // Initialize simulation inputs
    int image_width = 512;
    int image_height = 512;
    top->clk = 0;
    top->reset = 1;
    top->cameraPosX = 250;
    top->cameraPosY = 512;
    top->cameraPosZ = 0;
    top->cameraDirX = 0;
    top->cameraDirY = 0;
    top->cameraDirZ = 1; // Assuming the camera is pointing in the positive z direction
    top->imageWidth = image_width;
    top->imageHeight = image_height;
    top->cameraDistance = 230; // Example distance

    // Open a file to write the output in PPM format
    std::ofstream ppmfile("output1.ppm");

    // Check if file is open
    if (!ppmfile.is_open()) {
        std::cerr << "Error opening file for writing" << std::endl;
        return 1;
    }

    // Write the PPM header
    ppmfile << "P3\n" << image_width << " " << image_height << "\n255\n";

    // Simulate for a number of cycles
    auto start = std::chrono::high_resolution_clock::now();
    for (int i = 0; i < 300 * (image_height * image_width); i++) {
        // Toggle clock
        for (int clk = 0; clk<2; clk++) {
            tfp->dump(2*i+clk);
            top->clk = !top->clk;

            // Evaluate the model
            top->eval();
            if (top->clk && top->validRead) { // Check at the positive edge and if validRead is high
                ppmfile << static_cast<int>(top->red) << " "
                        << static_cast<int>(top->green) << " "
                        << static_cast<int>(top->blue) << "\n";
                pixels ++;
                
            }
            
        }
        count ++;
        if (pixels == image_height * image_width)
        {
            std::cout << "Took: " << count << " clock cycles." << std::endl;
            break;
        }
    }

    // Close the file
    ppmfile.close();
    auto end = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double> duration = end - start;
    std::cout << "Time taken: " << duration.count() << " seconds" << std::endl;

    // Final model cleanup
    top->final();

    // Destroy model
    delete top;

    tfp->close();

    // Finishing
    return 0;
}