#include <vector>
#include <cmath>
#include <bitset>
#include <string>
#include <iostream>
#include <fstream>

using namespace std;


int coord_bit_length = 10;

vector<int> cam_pos = {200, 300, 0};
vector<int> cam_norm = {0,0,100};
vector<int> cam_up = {0,1,0};
vector<int> cam_right = {1,0,0};

int im_width = 256;
int im_height = 256;

const vector<bitset<32>> octree = {
    bitset<32>(1),
    bitset<32>(0x80000000),
    bitset<32>(0x80000000),
    bitset<32>(0x80000000),
    bitset<32>(0x80000000),
    bitset<32>(0x80000000),
    bitset<32>(0x80000000),
    bitset<32>(0x80000000),
    bitset<32>(0x80000001)
}; 
// bit 31 is set for material 
vector<vector<int>> material_table = {{0,0,0}, {255,255,255}, {0,255,0}, {0,0,255}, {255,0,0}};

vector<vector<int>> image;

bool withinAABB(vector<int> position, vector<int> aabb_min, vector<int> aabb_max){
    return position[0] >= aabb_min[0] && position[1] >= aabb_min[1] && position[2] >= aabb_min[2] && position[0] <= aabb_max[0] && position[1] <= aabb_max[1] && position[2] <= aabb_max[2];
}

bool justOutsideAABB(vector<int> position, vector<int> aabb_min, vector<int> aabb_max){
    return position[0] == aabb_min[0] - 1 || position[1] == aabb_min[1] - 1 || position[2] == aabb_min[2] - 1 || position[0] == aabb_max[0] + 1 || position[1] == aabb_max[1] + 1 || position[2] == aabb_max[2] + 1;
}

bitset<32> traverseTree(vector<int> ray_pos, int& oct_size, vector<int>& aabb_min, vector<int>& aabb_max){
    int depth = 0;
    bitset<32> node(octree[0]);
    bitset<10> x_bin(ray_pos[0]);
    bitset<10> y_bin(ray_pos[1]);
    bitset<10> z_bin(ray_pos[2]);
    while(!node.test(31) && depth < coord_bit_length){
        string temp_str;
        temp_str += z_bin.to_string()[depth];
        temp_str += y_bin.to_string()[depth];
        temp_str += x_bin.to_string()[depth];
        bitset<3> temp(temp_str);
        int octant = int(temp.to_ulong());
        depth += 1;
        oct_size /= 2;

        aabb_min[0] = aabb_min[0] + (x_bin[coord_bit_length-depth]*oct_size);
        aabb_min[1] = aabb_min[1] + (y_bin[coord_bit_length-depth]*oct_size);
        aabb_min[2] = aabb_min[2] + (z_bin[coord_bit_length-depth]*oct_size);
        aabb_max[0] = aabb_min[0] + oct_size-1;
        aabb_max[1] = aabb_min[1] + oct_size-1;
        aabb_max[2] = aabb_min[2] + oct_size-1;

        int nodeIndex = int(node.to_ulong()) + octant;
        node = octree[nodeIndex];
    }
    return node;
}

vector<int> stepRay(vector<int> ray_pos, vector<int> ray_dir, int oct_size, vector<int> aabb_min, vector<int> aabb_max){
    while(ray_dir[0]*ray_dir[0] + ray_dir[1]*ray_dir[1] + ray_dir[2]*ray_dir[2] < oct_size*oct_size){
        ray_dir[0] *= 2;
        ray_dir[1] *= 2;
        ray_dir[2] *= 2;
    }
    while(!justOutsideAABB(ray_pos, aabb_min, aabb_max)){
        vector<int> temp_pos = ray_pos;
        temp_pos[0] = temp_pos[0] + ray_dir[0];
        temp_pos[1] = temp_pos[1] + ray_dir[1];
        temp_pos[2] = temp_pos[2] + ray_dir[2];
        if(withinAABB(temp_pos, aabb_min, aabb_max) || justOutsideAABB(temp_pos, aabb_min, aabb_max)){
            ray_pos = temp_pos;
        }
        ray_dir[0] /= 2;
        ray_dir[1] /= 2;
        ray_dir[2] /= 2;
    }
    return ray_pos;
}


void writePPM(const string& filename) {
    ofstream file(filename);
    if (file.is_open()) {
        file << "P3\n" << im_width << " " << im_height << "\n255\n";
        for (const auto& row : image) {
            for (int i = 0; i < row.size(); i += 3) {
                file << row[i] << " " << row[i + 1] << " " << row[i + 2] << " ";
            }
            file << "\n";
        }
        file.close();
    } else {
        cerr << "Unable to open file";
    }
}

int main(){
    for(int y = 0; y < im_height; y++){
        for(int x = 0; x < im_width; x++){
            int centered_x = x - (im_width / 2);
            int centered_y = (im_height / 2) - y;
            vector<int> ray_dir = cam_norm;
            ray_dir[0] += centered_x*cam_right[0] + centered_y*cam_up[0];
            ray_dir[1] += centered_x*cam_right[1] + centered_y*cam_up[1];
            ray_dir[2] += centered_x*cam_right[2] + centered_y*cam_up[2];
            vector<int> ray_pos = cam_pos;

            int world_size = 1<<coord_bit_length;
            vector<int> world_min = {0, 0, 0}; 
            vector<int> world_max = {world_size-1, world_size-1, world_size-1};

            int oct_size = world_size;
            vector<int> aabb_min = world_min;
            vector<int> aabb_max = world_max;

            bitset<32> node;
            vector<int> colour;
            while(withinAABB(ray_pos, world_min, world_max)){
                node = traverseTree(ray_pos, oct_size, aabb_min, aabb_max);

                unsigned int mid = node.to_ulong() & ((1u << 31) - 1);

                if(mid==0){
                    ray_pos = stepRay(ray_pos, ray_dir, oct_size, aabb_min, aabb_max);
                }
                if(mid>0){
                    colour = material_table[mid];
                    break;
                }
            }
            if(colour.empty()){
                colour = {0, 0, 0};
            }

            image.push_back(colour);

        }
    }

    writePPM("output.ppm");

    return 0;
}