#include <vector>
#include <cmath>
#include <bitset>
#include <string>
#include <tuple>
#include <iostream>
#include <fstream>

using namespace std;


int coord_bit_length = 10;

vector<int> cam_pos = {200, 300, 0};
vector<int> cam_norm = {0,0,230};
vector<int> cam_up = {0,1,0};
vector<int> cam_right = {1,0,0};

int im_width = 640;
int im_height = 480;

const vector<bitset<32>> octree = {
    bitset<32>(1),
    bitset<32>(0x80000000),
    bitset<32>(0x80000000),
    bitset<32>(0x80000000),
    bitset<32>(0x80000000),
    bitset<32>(0x80000000),
    bitset<32>(0x80000002),
    bitset<32>(0x80000003),
    bitset<32>(0x80000001)
}; 
// bit 31 is set for material 
vector<vector<int>> material_table = {{0,0,0}, {255,255,255}, {0,255,0}, {0,0,255}, {255,0,0}, {255,255,0}};

vector<vector<int>> image;

bool withinAABB(vector<int> position, vector<int> aabb_min, vector<int> aabb_max){
    return position[0] >= aabb_min[0] && position[1] >= aabb_min[1] && position[2] >= aabb_min[2] && position[0] <= aabb_max[0] && position[1] <= aabb_max[1] && position[2] <= aabb_max[2];
}

bool justOutsideAABB(vector<int> position, vector<int> aabb_min, vector<int> aabb_max) {
    bool outside_x = (position[0] == aabb_min[0] - 1 || position[0] == aabb_max[0] + 1);
    bool outside_y = (position[1] == aabb_min[1] - 1 || position[1] == aabb_max[1] + 1);
    bool outside_z = (position[2] == aabb_min[2] - 1 || position[2] == aabb_max[2] + 1);

    bool within_x = (position[0] >= aabb_min[0] && position[0] <= aabb_max[0]);
    bool within_y = (position[1] >= aabb_min[1] && position[1] <= aabb_max[1]);
    bool within_z = (position[2] >= aabb_min[2] && position[2] <= aabb_max[2]);

    return (outside_x && within_y && within_z) || (within_x && outside_y && within_z) || (within_x && within_y && outside_z) || (outside_x && outside_y && within_z) || (outside_x && within_y && outside_z) || (within_x && outside_y && outside_z) || (outside_x && outside_y && outside_z);
}


tuple<bitset<32>, int, vector<int>, vector<int>> traverseTree(vector<int> ray_pos, int oct_size, vector<int> aabb_min, vector<int> aabb_max){
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
        int octant = stoi(temp_str, nullptr, 2);
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
    return make_tuple(node, oct_size, aabb_min, aabb_max);
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

        ray_dir[0] = (abs(ray_dir[0])<=1) ? (ray_dir[0]>=0 ? 1 : -1) : ray_dir[0]/2;
        ray_dir[1] = (abs(ray_dir[1])<=1) ? (ray_dir[1]>=0 ? 1 : -1)  : ray_dir[1]/2;
        ray_dir[2] = (abs(ray_dir[2])<=1) ? (ray_dir[2]>=0 ? 1 : -1)  : ray_dir[2]/2;
    }
    return ray_pos;
}

vector<double> normaliseVector(const vector<double>& vec) {
    vector<double> normalisedVec;
    double magnitude = 0.0;

    for(int_fast32_t i = 0; i < vec.size(); ++i){
        magnitude += vec[i] * vec[i];
    }

    magnitude = sqrt(magnitude);

    if(magnitude > 0.0){
        for(int i = 0; i < vec.size(); ++i){
            normalisedVec.push_back(vec[i] / magnitude);
        }
    }
    return normalisedVec;
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
    cout << "started" << endl;
    for(int y = 0; y < im_height; y++){
        for(int x = 0; x < im_width; x++){
            int centered_x = x - (im_width / 2);
            int centered_y = (im_height / 2) - y;
            vector<int> ray_dir = cam_norm;
            ray_dir[0] += (centered_x*cam_right[0] + centered_y*cam_up[0]);
            ray_dir[1] += (centered_x*cam_right[1] + centered_y*cam_up[1]);
            ray_dir[2] += (centered_x*cam_right[2] + centered_y*cam_up[2]);

            vector<int> ray_pos = cam_pos;

            int world_size = pow(2, coord_bit_length);
            vector<int> world_min = {0, 0, 0}; 
            vector<int> world_max = {world_size-1, world_size-1, world_size-1};

            int oct_size = world_size;
            vector<int> aabb_min = world_min;
            vector<int> aabb_max = world_max;

            bitset<32> node;
            vector<int> colour;
            while(withinAABB(ray_pos, world_min, world_max)){

                tie(node, oct_size, aabb_min, aabb_max) = traverseTree(ray_pos, world_size, world_min, world_max);
                unsigned int mid = node.to_ulong() & 0x7FFFFFFF;

                if(mid==0){
                    //cout << "air" << endl;
                    ray_pos = stepRay(ray_pos, ray_dir, oct_size, aabb_min, aabb_max);
                }
                if(mid>0){
                    vector<int> hit_normal = {0,0,0};
                    if (ray_pos[0] == aabb_min[0]){
                    hit_normal = {-1, 0, 0};
                    } 
                    else if(ray_pos[0] == aabb_max[0]){
                        hit_normal = {1, 0, 0};
                    } 
                    else if(ray_pos[1] == aabb_min[1]){
                        hit_normal = {0, -1, 0};
                    } 
                    else if(ray_pos[1] == aabb_max[1]){
                        hit_normal = {0, 1, 0};
                    } 
                    else if(ray_pos[2] == aabb_min[2]){
                        hit_normal = {0, 0, -1};
                    } 
                    else if(ray_pos[2] == aabb_max[2]){
                        hit_normal = {0, 0, 1};
                    }

                    vector<double> light_dir = {static_cast<double>(-ray_dir[0]), static_cast<double>(-ray_dir[1]), static_cast<double>(-ray_dir[2])};
                    light_dir = normaliseVector(light_dir);

                    double brightness_factor = pow((hit_normal[0]*light_dir[0] + hit_normal[1]*light_dir[1] + hit_normal[2]*light_dir[2]) , 1.4);

                    // cout << "Material: " << mid << " found at x: " << x << " y: " << y << endl;
                    colour = material_table[mid];
                    double adjusted_colour_r = colour[0] * brightness_factor;
                    double adjusted_colour_g = colour[1] * brightness_factor;
                    double adjusted_colour_b = colour[2] * brightness_factor;
                    colour = {static_cast<int>(round(adjusted_colour_r)), static_cast<int>(round(adjusted_colour_g)), static_cast<int>(round(adjusted_colour_b))};
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
    cout << "done" << endl;
}