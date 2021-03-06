//
//  inc.metal
//  MetalComputeBasic
//
//  Created by Moishe Lettvin on 12/1/21.
//  Copyright © 2021 Apple. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

kernel void find_incs(device const int* inA,
                      device int* result,
                      uint index [[thread_position_in_grid]])
{
    if (index > 0) {
        result[index] = inA[index] > inA[index - 1] ? 1 : 0;
    } else {
        // Note that we use the fact that this is guaranteed to be zero
        // to leave space for our midpoint in the next stage
        result[index] = 0;
    }
}

