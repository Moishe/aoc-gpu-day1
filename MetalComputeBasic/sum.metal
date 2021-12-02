//
//  sum.metal
//  MetalComputeBasic
//
//  Created by Moishe Lettvin on 12/2/21.
//

#include <metal_stdlib>
using namespace metal;

kernel void sum_array(device const int* inA,
                      device int* result,
                      uint index [[thread_position_in_grid]])
{
    uint midpoint = (uint)inA[0];
    if (index == 0) {
        if (inA[index] <= 2) {
            result[index] = inA[index] - 1;
        } else {
            result[index] = inA[index] / 2 + 1;
        }
    } else if (index > midpoint) {
        result[index] = 0;
    } else {
        result[index] = inA[index] + inA[index + midpoint];
    }
}

