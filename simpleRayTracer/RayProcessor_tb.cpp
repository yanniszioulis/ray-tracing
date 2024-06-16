#include "verilated.h"
#include "VRayTracingUnit.h" // This should be the name of the generated header file
#include "verilated_vcd_c.h"
#include <iostream>
#include <fstream>

// Function to display the progress bar
void printProgressBar(float progress) {
    int barWidth = 70;
    std::cout << "[";
    int pos = barWidth * progress;
    for (int i = 0; i < barWidth; ++i) {
        if (i < pos) std::cout << "=";
        else if (i == pos) std::cout << ">";
        else std::cout << " ";
    }
    std::cout << "] " << int(progress * 100.0) << " %\r";
    std::cout.flush();
}

int main(int argc, char** argv, char** env) {
    // Initialize Verilator
    Verilated::commandArgs(argc, argv);
    std::cout<<"1" << std::endl;

    // Create an instance of the module
    VRayTracingUnit* top = new VRayTracingUnit;
    std::cout<<"2" << std::endl;

    Verilated::traceEverOn(true);
    std::cout<<"3" << std::endl;
    VerilatedVcdC* tfp = new VerilatedVcdC;
    std::cout<<"4" << std::endl;
    top->trace (tfp, 99);
    std::cout<<"5" << std::endl;
    tfp->open("RayTracingUnit.vcd");
    std::cout<<"6" << std::endl;

    // Initialize simulation inputs
    int image_width = 200;
    int image_height = 200;
    top->clk = 0;
    top->reset = 1;
    top->cameraPosX = 512;
    top->cameraPosY = 512;
    top->cameraPosZ = 0;
    top->cameraDirX = 0;
    top->cameraDirY = 0;
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

    // Calculate total iterations
    int total_iterations = 10 * (image_height * image_width) + 15;

    // Simulate for a number of cycles
    for (int i = 0; i < total_iterations; i++) {
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

        // Update progress bar
        if (i % (total_iterations / 100) == 0) { // Update progress bar at 1% intervals
            printProgressBar(static_cast<float>(i) / total_iterations);
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
    std::cout << std::endl; // Move to the next line after progress bar is complete
    return 0;
}
