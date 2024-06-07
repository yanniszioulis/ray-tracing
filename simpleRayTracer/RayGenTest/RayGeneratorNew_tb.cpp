#include "verilated.h"
#include "verilated_vcd_c.h"
#include "VRayGeneratorNew.h"
#include <iostream>
#include <fstream>

#define RESET_CYCLES 10
#define SIM_CYCLES 1000

int main(int argc, char** argv, char** env) {
    Verilated::commandArgs(argc, argv);

    // Instantiate the module
    VRayGeneratorNew* top = new VRayGeneratorNew;

    // Initialize trace dump
    VerilatedVcdC* tfp = new VerilatedVcdC;
    Verilated::traceEverOn(true);
    top->trace(tfp, 99);
    tfp->open("waveform.vcd");

    // Open output file
    std::ofstream outfile("ray_directions.txt");
    if (!outfile.is_open()) {
        std::cerr << "Failed to open output file!" << std::endl;
        return 1;
    }

    // Simulation variables
    int clk = 0;

    // Initialize signals
    top->clk = 0;
    top->reset_n = 0;
    top->ready_internal = 1;
    top->ready_external = 1;
    top->camera_pos_x = 250;
    top->camera_pos_y = 512;
    top->camera_pos_z = 0;
    top->camera_dir_x = 0;
    top->camera_dir_y = 0;
    top->camera_dir_z = 1;
    top->image_width = 512;
    top->image_height = 512;
    top->distance = 230;

    // Simulation loop
    for (int cycle = 0; cycle < SIM_CYCLES; ++cycle) {
        // Toggle clock
        top->clk = !top->clk;
        
        // Apply reset for the first few cycles
        if (cycle < RESET_CYCLES) {
            top->reset_n = 0;
        } else {
            top->reset_n = 1;
        }

        // Evaluate the module
        top->eval();
        
        // Capture the output signals after the clock edge
        if (top->clk && cycle > RESET_CYCLES) {
            outfile << "Cycle: " << cycle 
                    << " Ray Dir X: " << top->ray_dir_x 
                    << " Ray Dir Y: " << top->ray_dir_y 
                    << " Ray Dir Z: " << top->ray_dir_z 
                    << std::endl;
        }

        // Dump trace data for waveform visualization
        tfp->dump(cycle);
    }

    // Cleanup
    tfp->close();
    outfile.close();
    delete top;

    return 0;
}
