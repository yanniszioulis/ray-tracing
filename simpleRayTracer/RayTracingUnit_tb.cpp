#include "verilated.h"
#include "VRayTracingUnit.h" // This should be the name of the generated header file
#include "verilated_vcd_c.h"
#include <iostream>
#include <fstream>

int main(int argc, char** argv, char** env) {
    // Initialize Verilator
    Verilated::commandArgs(argc, argv);

    // Create an instance of the module
    VRayTracingUnit* top = new VRayTracingUnit;

    Verilated::traceEverOn(true);
    VerilatedVcdC* tfp = new VerilatedVcdC;
    top->trace (tfp, 99);
    tfp->open("RayTracingUnit.vcd");

    // Initialize simulation inputs
    int image_width = 256;
    int image_height = 256;
    top->clk = 0;
    top->reset = 1;
    top->cameraPosX = 90;
    top->cameraPosY = 20;
    top->cameraPosZ = 0;
    top->cameraDirX = 50;
    top->cameraDirY = -30;
    top->cameraDirZ = 80; // Assuming the camera is pointing in the positive z direction
    top->imageWidth = image_width;
    top->imageHeight = image_height;
    top->cameraDistance = 250; // Example distance

    // Open a file to write the output in PPM format
    std::ofstream ppmfile("output.ppm");

    // Check if file is open
    if (!ppmfile.is_open()) {
        std::cerr << "Error opening file for writing" << std::endl;
        return 1;
    }

    // Write the PPM header
    ppmfile << "P3\n" << image_width << " " << image_height << "\n255\n";

    // Simulate for a number of cycles
    for (int i = 0; i <  200 * (image_height * image_width) + 15; i++) {
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
            }
        }
    }

    // Close the file
    ppmfile.close();

    // Final model cleanup
    top->final();

    // Destroy model
    delete top;

    tfp->close();

    // Finishing
    return 0;
}