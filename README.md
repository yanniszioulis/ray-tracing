# FPGA Voxel Integer Raytracing

This project aims to accelerate ray tracing using a PYNQ Z1 FPGA. A scene, fitting within a 1024 unit cube coordinate space can be specified within Unity, after which a C# script can be run on the world to produce an equivalent octree representation. The output of this script is parsed into a `.mem` file that can be loaded into the ROM module of the FPGA before bitstream is generated.

Once the `.bit` and `.hwh` files are loaded onto the board, images ray traced images of the scene can be accessed via the GUI. Note this can only be done once the server is running on the board. The following can be controlled via the GUi:
- Camera direction 
- Camera position
- Image background colour
- Preset camera positions.

A complete report for the project can be found [here](report.pdf).
