#import <Foundation/Foundation.h>
@class MFSVolume;

NS_ASSUME_NONNULL_BEGIN

@interface MFSFork : NSObject

- (instancetype)initWithVolume:(MFSVolume *)volume
                   logicalSize:(uint32_t)logicalSize
                  physicalSize:(uint32_t)physicalSize
       firstAllocationBlockNum:(uint16_t)firstAbn;

- (NSArray<NSNumber *> *)allocationBlockNums;
- (NSData *)contents;

@end

NS_ASSUME_NONNULL_END
