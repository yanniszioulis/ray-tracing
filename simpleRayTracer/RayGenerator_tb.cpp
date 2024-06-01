#include "verilated.h"
#include "VRayGenerator.h" // This should be the name of the generated header file
#include "verilated_vcd_c.h"
#include <iostream>
#include <fstream>

int main(int argc, char** argv, char** env) {
    // Initialize Verilator
    Verilated::commandArgs(argc, argv);

    // Create an instance of the module
    VRayGenerator* top = new VRayGenerator;

    Verilated::traceEverOn(true);
    VerilatedVcdC* tfp = new VerilatedVcdC;
    top->trace (tfp, 99);
    tfp->open("RayGenerator.vcd");

    // Initialize simulation inputs
    int image_width = 1280;
    int image_height = 720;
    top->clk = 0;
    top->reset_n = 1;
    top->camera_pos_x = 0;
    top->camera_pos_y = 0;
    top->camera_pos_z = 0;
    top->camera_dir_x = 3;
    top->camera_dir_y = 1;
    top->camera_dir_z = 1; // Assuming the camera is pointing in the positive z direction
    top->image_width = image_width;
    top->image_height = image_height;
    top->distance = 250; // Example distance

    // Open a file to write the output
    std::ofstream outfile("ray_directions.txt");

    // Check if file is open
    if (!outfile.is_open()) {
        std::cerr << "Error opening file for writing" << std::endl;
        return 1;
    }

    // Simulate for a number of cycles
    for (int i = 0; i < (image_height * image_width) + 15; i++) {
        // Toggle clock
        for (int clk = 0; clk<2; clk++)
        {
            tfp->dump(2*i+clk);
            top->clk = !top->clk;

            // Evaluate the model
            top->eval();
            if (top->clk) { // Check at the positive edge

                // std::string state_str;
                // switch (top->curr_state) {
                //     case 0: state_str = "IDLE"; break;
                //     case 1: state_str = "CALCULATE"; break;
                //     case 2: state_str = "CALCULATE_IMAGE"; break;
                //     case 3: state_str = "GENERATE_RAYS"; break;
                //     default: state_str = "UNKNOWN"; break;
                // }
                // std::cout << "Current State: " << state_str << std::endl;   

                outfile << "Ray Direction: ("
                        << static_cast<int>(top->ray_dir_x) << ", "
                        << static_cast<int>(top->ray_dir_y) << ", "
                        << static_cast<int>(top->ray_dir_z) << ")\n";

                // std::cout << "pixel coordinate: " << top->pixel_x << " " << top->pixel_y << std::endl;
                // std::cout << "image coordinate: " << top->image_center_x << " " << top->image_center_y << std::endl;
                // std::cout << "mu: " << top->mu << std::endl;
            }
        }

        // Write the output to the file
    }

    // Close the file
    outfile.close();

    // Final model cleanup
    top->final();

    // Destroy model
    delete top;

    tfp->close();

    // Finishing
    return 0;
}
