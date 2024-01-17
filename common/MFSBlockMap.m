#import "MFSBlockMap.h"
#import "mfs.h"

@interface MFSBlockMap()
@property (nonatomic, assign) const uint8_t *bytes;
@property (nonatomic, assign) const uint8_t *end;
@end

@implementation MFSBlockMap

- (instancetype)initWithBytes:(const uint8_t *)bytes end:(const uint8_t *)end {
    if ((self = [super init])) {
        _bytes = bytes;
        _end = end;
    }
    
    return self;
}

- (uint16_t)nextAllocationBlock:(uint16_t)abn {
    uint16_t blockMapIx = abn - MFS_MIN_ALLOCATION_BLOCK_NUM;
        
    // Each entry is 12 bits, with two entries packed into each three bytes.
    // This is very similar to FAT12.
    const uint8_t *p = _bytes + blockMapIx * 3 / 2;
        
    // TODO consider reporting an error instead of crashing
    if (p < _bytes || p >= _end) {
        fprintf(stderr, "Out of range block map pointer: %p\n(Should be >= %p < %p)\n", p, _bytes, _end);
        exit(EXIT_FAILURE);
    }
    
    if (blockMapIx % 2 == 0) {
        return p[0] << 4 | ((p[1] >> 4) & 0x0F);
    } else {
        return ((p[0] & 0x0F) << 8) | p[1];
    }
}

- (void)enumerate:(void (^)(uint16_t abNum, uint16_t next))callback {
    for (const uint8_t *triplet = _bytes; triplet + 2 < _end; triplet += 3) {
        // Each entry is 12 bits, with two entries packed into each three bytes.
        uint16_t lowAbNum = (triplet - _bytes) / 3 * 2 + MFS_MIN_ALLOCATION_BLOCK_NUM;
        uint16_t nextAbNum = (triplet[0] << 4) | ((triplet[1] >> 4) & 0x0F);
        callback(lowAbNum, nextAbNum);
        nextAbNum = ((triplet[1] & 0x0F) << 8) | triplet[2];
        callback(lowAbNum + 1, nextAbNum);
    }
}

@end
