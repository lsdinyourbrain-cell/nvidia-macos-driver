#!/bin/bash
# Patch plugin for macOS 14.5 SDK compatibility
# Run this in the plugin source directory before building

set -euo pipefail

PLUGIN_DIR="$1"
cd "$PLUGIN_DIR"

echo "Patching plugin for macOS 14.5 SDK compatibility..."

# 1. Fix MTLResidencySet - wrap in availability checks
# In NVMTLObjects.h line 151
sed -i '' 's/@interface NVMTLResidencySet : NSObject <MTLResidencySet> {/@interface NVMTLResidencySet : NSObject <MTLResidencySet> __attribute__((availability(macos, introduced=14.0))) {/' NVMTLObjects.h

# 2. Fix MTLShaderValidation - add fallback definition
# Find where MTLShaderValidation is used and add fallback
if ! grep -q "MTLShaderValidationDisabled" NVMTLObjects.m 2>/dev/null; then
    # Add typedef before first use
    sed -i '' '/^#import <Metal\/Metal.h>/a\
#if !__has_feature(objc_attr_available) || !defined(MTLShaderValidation)\
typedef NS_ENUM(NSInteger, MTLShaderValidation) {\
    MTLShaderValidationDisabled = 0,\
    MTLShaderValidationEnabled = 1\
} API_AVAILABLE(macos(14.0), ios(17.0));\
#endif' NVMTLObjects.m
fi

# 3. Fix method signatures that use MTLResidencySet in protocols
# Change id<MTLResidencySet> to id with availability
sed -i '' 's/id<MTLResidencySet>/id<MTLResidencySet> __attribute__((availability(macos, introduced=14.0)))/g' NVMTLDevice.m NVMTLObjects.m NVMTLObjects.h 2>/dev/null || true

# 4. Add @synthesize for protocol properties that warn
# For NVMTLDevice
if grep -q "@implementation NVMTLDevice" NVMTLObjects.m; then
    sed -i '' '/@implementation NVMTLDevice/a\
@synthesize registryID, lowPower, headless, removable, location, locationNumber, maxTransferRate, depth24Stencil8PixelFormatSupported, supports32BitFloatFiltering, supports32BitMSAA, supportsQueryTextureLOD, supportsPullModelInterpolation, maxArgumentBufferSamplerCount, peerGroupID, peerIndex, peerCount, sparseTileSizeInBytes, maximumConcurrentCompilationTaskCount;' NVMTLObjects.m
fi

# 5. Fix NVMTLRenderPipelineState properties
if grep -q "@implementation NVMTLRenderPipelineState" NVMTLObjects.m; then
    sed -i '' '/@implementation NVMTLRenderPipelineState/a\
@synthesize maxTotalThreadsPerObjectThreadgroup, maxTotalThreadsPerMeshThreadgroup, objectThreadExecutionWidth, meshThreadExecutionWidth, maxTotalThreadgroupsPerMeshGrid;' NVMTLObjects.m
fi

# 6. Fix MTLFeatureSet deprecated warning - suppress
sed -i '' 's/#import <Metal\/Metal.h>/#import <Metal\/Metal.h>\n#pragma clang diagnostic push\n#pragma clang diagnostic ignored "-Wdeprecated-declarations"/' NVMTLDevice.m NVMTLObjects.m NVMTLObjects.h 2>/dev/null || true

# 7. Fix the specific error: MTLCommandQueueDescriptor forward declaration
# The code tries to access properties on a forward-declared class
# Wrap in respondsToSelector checks
sed -i '' 's/NSUInteger n = d ? d.maxCommandBufferCount : 0;/NSUInteger n = 0; if (d && [d respondsToSelector:@selector(maxCommandBufferCount)]) n = [d maxCommandBufferCount];/' NVMTLDevice.m

# 8. Fix d.label access on descriptor
sed -i '' 's/r->_label = d.label;/if ([d respondsToSelector:@selector(label)]) r->_label = [d label];/' NVMTLDevice.m

echo "Patch complete"