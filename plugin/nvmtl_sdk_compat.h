#pragma once

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

#ifndef MTLResidencySet
#define MTLResidencySet MTLResidencySet
API_AVAILABLE(macos(14.0), ios(17.0))
@interface MTLResidencySet : NSObject
@property (readonly, copy, nullable) NSString *label;
- (void)addAllocation:(id)allocation;
- (void)removeAllocation:(id)allocation;
- (void)removeAllAllocations;
- (BOOL)containsAllocation:(id)allocation;
@property (readonly, copy) NSArray *allAllocations;
@property (readonly) NSUInteger allocatedSize;
- (void)commit;
@end
#endif

#ifndef MTLResidencySetDescriptor
#define MTLResidencySetDescriptor MTLResidencySetDescriptor
API_AVAILABLE(macos(14.0), ios(17.0))
@interface MTLResidencySetDescriptor : NSObject
@property (readwrite, copy, nullable) NSString *label;
@end
#endif

#ifndef MTLShaderValidation
#define MTLShaderValidation MTLShaderValidation
typedef NS_ENUM(NSInteger, MTLShaderValidation) {
    MTLShaderValidationDisabled = 0,
    MTLShaderValidationEnabled = 1
} API_AVAILABLE(macos(14.0), ios(17.0));
#endif

#ifndef MTLCommandQueueDescriptor
#define MTLCommandQueueDescriptor MTLCommandQueueDescriptor
API_AVAILABLE(macos(14.0), ios(17.0))
@interface MTLCommandQueueDescriptor : NSObject
@property (readwrite, copy, nullable) NSString *label;
@property (readwrite) NSUInteger maxCommandBufferCount;
@property (readwrite, getter=logState) BOOL logState;
@end
#endif