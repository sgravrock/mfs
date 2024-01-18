#import "MFSFork.h"
#import "MFSVolume.h"
#import "MFSBlockMap.h"
#import "mfs.h"

@interface MFSFork()
@property (nonatomic, strong) MFSVolume *vol;
@property (nonatomic, assign) uint32_t logicalSize;
@property (nonatomic, assign) uint32_t physicalSize;
@property (nonatomic, assign) uint16_t firstAbn;
@end

@implementation MFSFork

- (instancetype)initWithVolume:(MFSVolume *)vol
                   logicalSize:(uint32_t)logicalSize
                  physicalSize:(uint32_t)physicalSize
       firstAllocationBlockNum:(uint16_t)firstAbn {
    
    if ((self = [super init])) {
        _vol = vol;
        _physicalSize = physicalSize;
        _logicalSize = logicalSize;
        _firstAbn = firstAbn;
    }
    
    return self;
}

- (NSArray<NSNumber *> *)allocationBlockNums {
    if (_firstAbn == MFS_ALLOCATION_BLOCK_NUM_UNUSED) {
        // Empty fork
        return [NSArray array];
    }
    
    MFSBlockMap *blockMap = [self.vol blockMap];
    uint32_t nBlocksAllocated = _physicalSize / [self.vol allocationBlockSize];
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:nBlocksAllocated];
    uint16_t abn = _firstAbn;

    while (abn != MFS_ALLOCATION_BLOCK_NUM_EOF) {
        [result addObject:[NSNumber numberWithUnsignedShort:abn]];
        abn = [blockMap nextAllocationBlock:abn];
    }
    
    if (result.count != nBlocksAllocated) {
        fprintf(stderr, "Expected %u allocation blocks but found %lu\n", nBlocksAllocated, (unsigned long)result.count);
    }
    
    return result;

}

- (NSData *)contents {
    uint32_t abSize = [self.vol allocationBlockSize];
    NSMutableData *result = [NSMutableData dataWithLength:_logicalSize];
    uint8_t *destp = result.mutableBytes;
    NSArray<NSNumber *> *allocationBlockNums = [self allocationBlockNums];
    
    for (uint32_t i = 0; i < allocationBlockNums.count; i++) {
        uint16_t abn = [allocationBlockNums[i] unsignedShortValue];
        const uint8_t *ab = [self.vol allocationBlock:abn];
        uint32_t blocksize;
        
        if (i + 1 < allocationBlockNums.count) {
            blocksize = abSize;
        } else {
            // Last allocation block. Truncate to logical EOF.
            blocksize = _logicalSize % abSize;
        }
        
        memcpy(destp, ab, blocksize);
        destp += blocksize;
    }
    
    return result;
}


@end
