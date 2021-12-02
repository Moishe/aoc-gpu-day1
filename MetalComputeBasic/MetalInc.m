/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A class to manage all of the Metal objects this app creates.
*/

#import "MetalInc.h"

// The number of ints in each array, and the size of the arrays in bytes.
const unsigned int inc_arrayLength = 10;
const unsigned int inc_bufferSize = inc_arrayLength * sizeof(int);

const unsigned int data[] = {
    199,
    200,
    208,
    210,
    200,
    207,
    240,
    269,
    260,
    263
};

@implementation MetalInc
{
    id<MTLDevice> _mDevice;

    // The compute pipeline generated from the compute kernel in the .metal shader file.
    id<MTLComputePipelineState> _mIncFunction;

    // The command queue used to pass commands to the device.
    id<MTLCommandQueue> _mCommandQueue;

    // Buffers to hold data.
    id<MTLBuffer> _mBufferIn;
    id<MTLBuffer> _mBufferResult;

}

- (instancetype) initWithDevice: (id<MTLDevice>) device
{
    self = [super init];
    if (self)
    {
        _mDevice = device;

        NSError* error = nil;

        // Load the shader files with a .metal file extension in the project

        id<MTLLibrary> defaultLibrary = [_mDevice newDefaultLibrary];
        if (defaultLibrary == nil)
        {
            NSLog(@"Failed to find the default library.");
            return nil;
        }

        id<MTLFunction> incFunction = [defaultLibrary newFunctionWithName:@"find_incs"];
        if (incFunction == nil)
        {
            NSLog(@"Failed to find the inc function.");
            return nil;
        }

        // Create a compute pipeline state object.
        _mIncFunction = [_mDevice newComputePipelineStateWithFunction: incFunction error:&error];
        if (_mIncFunction == nil)
        {
            //  If the Metal API validation is enabled, you can find out more information about what
            //  went wrong.  (Metal API validation is enabled by default when a debug build is run
            //  from Xcode)
            NSLog(@"Failed to created pipeline state object, error %@.", error);
            return nil;
        }

        _mCommandQueue = [_mDevice newCommandQueue];
        if (_mCommandQueue == nil)
        {
            NSLog(@"Failed to find the command queue.");
            return nil;
        }
    }

    return self;
}

- (void) prepareData
{
    // Allocate three buffers to hold our initial data and the result.
    _mBufferIn = [_mDevice newBufferWithLength:inc_bufferSize options:MTLResourceStorageModeShared];
    _mBufferResult = [_mDevice newBufferWithLength:inc_bufferSize options:MTLResourceStorageModeShared];

    [self populateDataBuffer:_mBufferIn];
}

- (void) sendComputeCommand
{
    // Create a command buffer to hold commands.
    id<MTLCommandBuffer> commandBuffer = [_mCommandQueue commandBuffer];
    assert(commandBuffer != nil);

    // Start a compute pass.
    id<MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];
    assert(computeEncoder != nil);

    [self encodeIncCommand:computeEncoder];

    // End the compute pass.
    [computeEncoder endEncoding];

    // Execute the command.
    [commandBuffer commit];

    // Normally, you want to do other work in your app while the GPU is running,
    // but in this example, the code simply blocks until the calculation is complete.
    [commandBuffer waitUntilCompleted];

    [self verifyResults];
}

- (void)encodeIncCommand:(id<MTLComputeCommandEncoder>)computeEncoder {

    // Encode the pipeline state object and its parameters.
    [computeEncoder setComputePipelineState:_mIncFunction];
    [computeEncoder setBuffer:_mBufferIn offset:0 atIndex:0];
    [computeEncoder setBuffer:_mBufferResult offset:0 atIndex:1];

    MTLSize gridSize = MTLSizeMake(inc_arrayLength, 1, 1);

    // Calculate a threadgroup size.
    NSUInteger threadGroupSize = _mIncFunction.maxTotalThreadsPerThreadgroup;
    if (threadGroupSize > inc_arrayLength)
    {
        threadGroupSize = inc_arrayLength;
    }
    MTLSize threadgroupSize = MTLSizeMake(threadGroupSize, 1, 1);

    // Encode the compute command.
    [computeEncoder dispatchThreads:gridSize
              threadsPerThreadgroup:threadgroupSize];
}

- (void) populateDataBuffer: (id<MTLBuffer>) buffer
{
    int* dataPtr = buffer.contents;

    for (unsigned long index = 0; index < inc_arrayLength; index++)
    {
        dataPtr[index] = data[index];
    }
}
- (void) verifyResults
{
    int* a = _mBufferIn.contents;
    int* result = _mBufferResult.contents;

    for (unsigned long index = 0; index < inc_arrayLength; index++)
    {
        int expected_result = 0;
        if (index > 0 && a[index] > a[index - 1]) {
            expected_result = 1;
        }
        if (expected_result != result[index]) {
            printf("Compute ERROR: index=%lu result=%d vs %d=a+b\n",
                   index, result[index], expected_result);
            assert(result[index] == expected_result);
        }
    }
    printf("Compute results as expected\n");
}

- (id<MTLBuffer>) getComputedBuffer
{
    return _mBufferResult;
}
@end
