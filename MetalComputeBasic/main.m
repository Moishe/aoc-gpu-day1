#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import "MetalInc.h"
#import "MetalSum.h"

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
        printf("increments found\n");
        
        int length = (int)(mBufferResult.length / sizeof(int));

        ((int *)mBufferResult.contents)[0] = (int)(length / 2) + 1;

        MetalSum* sum = [[MetalSum alloc] initWithDevice:device];
        [sum setInputBuffer:(int *)mBufferResult.contents length:length + 1];
        
        [sum prepareData];
        
        [sum sendComputeCommand];

        NSLog(@"Execution finished.");
    }
    return 0;
}
