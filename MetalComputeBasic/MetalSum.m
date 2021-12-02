/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A class to manage all of the Metal objects this app creates.
*/

#import "MetalSum.h"

@implementation MetalSum
{
    id<MTLDevice> _mDevice;

    // The compute pipeline generated from the compute kernel in the .metal shader file.
    id<MTLComputePipelineState> _mSumFunction;

    // The command queue used to pass commands to the device.
    id<MTLCommandQueue> _mCommandQueue;

    // Buffers to hold data.
    id<MTLBuffer> _mBufferA;
    id<MTLBuffer> _mBufferB;
    
    int step;
    
    int *input_buffer;
    int input_length;
    int input_size;
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

        id<MTLFunction> sumFunction = [defaultLibrary newFunctionWithName:@"sum_array"];
        if (sumFunction == nil)
        {
            NSLog(@"Failed to find the sum function.");
            return nil;
        }

        // Create a compute pipeline state object.
        _mSumFunction = [_mDevice newComputePipelineStateWithFunction: sumFunction error:&error];
        if (_mSumFunction == nil)
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
        
        step = 0;
    }

    return self;
}

- (void) setInputBuffer: (int *)buffer length:(int)length
{
    input_buffer = buffer;
    input_length = length;
    input_size = length * sizeof(int);
}


- (void) prepareData
{
    // Allocate two buffers to hold our initial data and the result.
    // The zeroth element of _mBufferIn contains the midpoint

    _mBufferA = [_mDevice newBufferWithLength:input_size options:MTLResourceStorageModeShared];
    _mBufferB = [_mDevice newBufferWithLength:input_size options:MTLResourceStorageModeShared];
    
    [self populateDataBuffer:_mBufferA];
}

- (void) sendComputeCommand
{
    int *a;
    int *result;

    do {
        // Create a command buffer to hold commands.
        id<MTLCommandBuffer> commandBuffer = [_mCommandQueue commandBuffer];
        assert(commandBuffer != nil);

        // Start a compute pass.
        id<MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];
        assert(computeEncoder != nil);
        
        [self encodeSumCommand:computeEncoder];

        // End the compute pass.
        [computeEncoder endEncoding];

        // Execute the command.
        [commandBuffer commit];

        // Normally, you want to do other work in your app while the GPU is running,
        // but in this example, the code simply blocks until the calculation is complete.
        [commandBuffer waitUntilCompleted];

        [self verifyResults];
        
        if (step % 2 == 0) {
            a = _mBufferA.contents;
            result = _mBufferB.contents;
        } else {
            a = _mBufferB.contents;
            result = _mBufferA.contents;
        }

        step += 1;
    } while (result[0] > 0);
}

- (void)encodeSumCommand:(id<MTLComputeCommandEncoder>)computeEncoder {

    // Encode the pipeline state object and its parameters.
    [computeEncoder setComputePipelineState:_mSumFunction];
    
    if (step % 2 == 0) {
        [computeEncoder setBuffer:_mBufferA offset:0 atIndex:0];
        [computeEncoder setBuffer:_mBufferB offset:0 atIndex:1];
    } else {
        [computeEncoder setBuffer:_mBufferB offset:0 atIndex:0];
        [computeEncoder setBuffer:_mBufferA offset:0 atIndex:1];
    }

    MTLSize gridSize = MTLSizeMake(input_length - 1, 1, 1);

    // Calculate a threadgroup size.
    NSUInteger threadGroupSize = _mSumFunction.maxTotalThreadsPerThreadgroup;
    if (threadGroupSize > input_length)
    {
        threadGroupSize = input_length;
    }
    MTLSize threadgroupSize = MTLSizeMake(threadGroupSize, 1, 1);

    // Encode the compute command.
    [computeEncoder dispatchThreads:gridSize
              threadsPerThreadgroup:threadgroupSize];
}

- (void) populateDataBuffer: (id<MTLBuffer>) buffer
{
    int* dataPtr = buffer.contents;

    for (unsigned long index = 0; index < input_length; index++)
    {
        dataPtr[index] = input_buffer[index];
    }
    
    dataPtr[0] = (int)round(input_length / 2);
}

- (void) verifyResults
{
    int *a;
    int *result;
    if (step % 2 == 0) {
        a = _mBufferA.contents;
        result = _mBufferB.contents;
    } else {
        a = _mBufferB.contents;
        result = _mBufferA.contents;
    }

    for (unsigned long index = 0; index < input_length; index++)
    {
        printf("%d: %d\n", a[index], result[index]);
    }
    printf("Compute results as expected\n");
}

- (id<MTLBuffer>) getComputedBuffer
{
    return _mBufferB;
}
@end
