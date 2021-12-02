/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An app that performs a simple calculation on a GPU.
*/

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import "MetalInc.h"
#import "MetalAdder.h"

// This is the C version of the function that the sample
// implements in Metal Shading Language.
void add_arrays(const float* inA,
                const float* inB,
                float* result,
                int length)
{
    for (int index = 0; index < length ; index++)
    {
        result[index] = inA[index] + inB[index];
    }
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        id<MTLDevice> device = MTLCreateSystemDefaultDevice();

        // Create the custom object used to encapsulate the Metal code.
        // Initializes objects to communicate with the GPU.
        MetalInc* inc = [[MetalInc alloc] initWithDevice:device];
        
        // Create buffers to hold data
        [inc prepareData];
        
        // Send a command to the GPU to perform the calculation.
        [inc sendComputeCommand];

        id<MTLBuffer> mBufferResult = [inc getComputedBuffer];
        
        MetalAdder* add = [[MetalAdder alloc] initWithDevice:device];
        
        [add prepareData];
        
        [add sendComputeCommand];

        NSLog(@"Execution finished.");
    }
    return 0;
}
