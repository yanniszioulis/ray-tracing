#include "verilated.h"
#include "VRayTracingUnit.h" // This should be the name of the generated header file
#include "verilated_vcd_c.h"
#include <iostream>
#include <fstream>
#include <chrono>
#include <vector>

int main(int argc, char** argv, char** env) {
    // Initialize Verilator
    int count = 0;
    int pixels = 0;
    int eol = 0;

    std::vector<int> lasts;

    Verilated::commandArgs(argc, argv);

    // Create an instance of the module
    VRayTracingUnit* top = new VRayTracingUnit;

    Verilated::traceEverOn(true);
    VerilatedVcdC* tfp = new VerilatedVcdC;
    top->trace (tfp, 99);
    tfp->open("RayTracingUnit.vcd");

    // Initialize simulation inputs
    int image_width = 600;
    int image_height = 600;
    top->clk = 0;
    top->reset = 1;
    top->cameraPosX = 400;
    top->cameraPosY = 400;
    top->cameraPosZ = 500;
    top->cameraDirX = 0;
    top->cameraDirY = 0;
    top->cameraDirZ = 100; // Assuming the camera is pointing in the positive z direction
    top->cameraRightX = 1;
    top->cameraRightY = 0;
    top->cameraRightZ = 0;
    top->cameraUpX = 0;
    top->cameraUpY = 1;
    top->cameraUpZ = 0;
    top->imageWidth = image_width;
    top->imageHeight = image_height;
    // top->cameraDistance = 230; // Example distance, original: 230
    top->ReadyExternal = 1;

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
    auto start = std::chrono::high_resolution_clock::now();
    for (int i = 0; i < 559710000; i++) {
        // Toggle clock
        for (int clk = 0; clk<2; clk++) {
            tfp->dump(2*i+clk);
            top->clk = !top->clk;

            // Evaluate the model
            top->eval();
            if (top->clk && top->validRead) { // Check at the positive edge and if validRead is high
                ppmfile << static_cast<int>(top->out_red) << " "
                        << static_cast<int>(top->out_green) << " "
                        << static_cast<int>(top->out_blue) << "\n";
                pixels ++;
                if (top->EOL_out)
                {
                    lasts.push_back(pixels);
                    eol++;
                }
            }
            
        }
        count ++;
        if (pixels == image_height * image_width)
        {
            std::cout << "Took: " << count - 20 << " clock cycles." << std::endl;
            break;
        }
        //std::cout << i << std::endl;
    }

    // Close the file
    ppmfile.close();
    auto end = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double> duration = end - start;
    std::cout << "Time taken: " << duration.count() << " seconds" << std::endl;
    std::cout << "EOLs:" << eol << std::endl;
    std::cout << "Pixels: " << pixels << std::endl;

    // for (int i = 0; i < lasts.size(); i++)
    // {
    //     std::cout << "EOL at pixel number: " << lasts[i] << std::endl;
    // }

    // Final model cleanup
    top->final();

    // Destroy model
    delete top;

    tfp->close();

    // Finishing
    return 0;
}