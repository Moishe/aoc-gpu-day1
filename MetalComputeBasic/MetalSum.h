/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A class to manage all of the Metal objects this app creates.
*/

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

NS_ASSUME_NONNULL_BEGIN

@interface MetalSum : NSObject
- (instancetype) initWithDevice: (id<MTLDevice>) device;
- (void) setInputBuffer: (const int*)buffer length:(int)size;
- (void) prepareData;
- (void) sendComputeCommand;
- (id<MTLBuffer>) getComputedBuffer;
@end

NS_ASSUME_NONNULL_END
