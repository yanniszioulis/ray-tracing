import socket
from pynq import Overlay
from pynq.lib.video import *
import struct

def set_camera_params(pixgen, params):
    # Unpack the data
    regfile_0, regfile_1, regfile_2, regfile_3, regfile_4, regfile_5, regfile_6 = struct.unpack('IIIIIII', params[:28])

    # Set the parameters in the registers
    pixgen.register_map.gp0 = regfile_0
    pixgen.register_map.gp1 = regfile_1
    pixgen.register_map.gp2 = regfile_2
    pixgen.register_map.gp3 = regfile_3
    pixgen.register_map.gp4 = regfile_4
    pixgen.register_map.gp5 = regfile_5
    pixgen.register_map.gp6 = regfile_6

    print("Received data:")
    print(f"Camera Direction (hex): {regfile_0:08X}")
    print(f"Camera Position (hex): {regfile_1:08X}")

def start_server():
    # Load the overlay
    overlay = Overlay("/home/xilinx/jupyter_notebooks/house.bit")
    print('Overlay loaded.')

    server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server_socket.bind(('0.0.0.0', 12345))  # Listen on all interfaces on port 12345
    server_socket.listen(5)
    print("Server listening on port 12345")

    while True:
        client_socket, addr = server_socket.accept()
        print(f"Connection from {addr}")

        try:
            # Initialize the pixel generator and VDMA
            pixgen = overlay.pixel_generator_0
            pixgen.register_map.gp0 = 0x0E600000
            pixgen.register_map.gp1 = 0x000800FA
            pixgen.register_map.gp2 = 0x00000001
            pixgen.register_map.gp3 = 0x00000400
            pixgen.register_map.gp4 = 0x00000000

            imgen_vdma = overlay.video.axi_vdma_0.readchannel
            videoMode = common.VideoMode(512, 512, 24)
            imgen_vdma.mode = videoMode
            imgen_vdma.start()
            print('VDMA started.')

            while True:
                data = client_socket.recv(28)
                if not data:
                    break

                # Set the camera parameters in the register map
                set_camera_params(pixgen, data)
             
                print(pixgen.register_map)
                
                # Read the frame 4 times
                for _ in range(4):
                    frame = imgen_vdma.readframe()
                    print("reading frame for ", _ , " time")
                frame_data = frame.tobytes()
                print("frame completed")
                # Send the frame data to the client
                client_socket.sendall(frame_data)

        except Exception as e:
            print(f"An error occurred: {e}")

        finally:
            client_socket.close()
            imgen_vdma.stop()
            print("VDMA stopped.")

if __name__ == "__main__":
    start_server()