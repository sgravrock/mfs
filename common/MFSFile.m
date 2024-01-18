#import "MFSFile.h"
#import "MFSVolume.h"
#import "MFSBlockMap.h"
#import "mfs.h"

// The MFS date epoch, Jan 1 1904, in Unix seconds
#define EPOCH_OFFSET -2082844800


@interface MFSFile()
@property (nonatomic, strong) MFSVolume *vol;
@end

@implementation MFSFile

- (instancetype)initWithVolume:(MFSVolume *)vol fdb:(struct mfs_fdb *)fdb {
    if ((self = [super init])) {
        _vol = vol;
        _fdb = fdb;
    }
    
    return self;
}

- (NSString *)name {
    return [[NSString alloc] initWithBytes:&(_fdb->file_name)
                                    length:_fdb->file_name_len
                                  encoding:NSMacOSRomanStringEncoding];
}

- (struct type_or_creator *)type {
    return (struct type_or_creator *)&_fdb->type;
}

- (struct type_or_creator *)creator {
    return (struct type_or_creator *)&_fdb->creator;
}

- (NSDate *)creationDate {
    return [NSDate dateWithTimeIntervalSince1970:EPOCH_OFFSET + __DARWIN_OSSwapInt32(_fdb->creation_date)];
}

- (NSDate *)modificationDate {
    return [NSDate dateWithTimeIntervalSince1970:EPOCH_OFFSET + __DARWIN_OSSwapInt32(_fdb->modification_date)];
}

- (NSArray<NSNumber *> *)dataForkAllocationBlockNums {
    MFSBlockMap *blockMap = [self.vol blockMap];
    uint32_t nBytesAllocated = __DARWIN_OSSwapInt32(_fdb->data_fork_allocated_space);
    uint32_t nBlocksAllocated = nBytesAllocated / [self.vol allocationBlockSize];
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:nBlocksAllocated];
    uint16_t abn = __DARWIN_OSSwapInt16(_fdb->first_data_fork_allocation_block);
    
    if (abn == MFS_ALLOCATION_BLOCK_NUM_UNUSED) {
        // Empty fork
        return result;
    }

    while (abn != MFS_ALLOCATION_BLOCK_NUM_EOF) {
        [result addObject:[NSNumber numberWithUnsignedShort:abn]];
        abn = [blockMap nextAllocationBlock:abn];
    }
    
    if (result.count != nBlocksAllocated) {
        fprintf(stderr, "Expected %u allocation blocks but found %lu\n", nBlocksAllocated, (unsigned long)result.count);
    }
    
    return result;
}

- (NSData *)dataForkContents {
    uint32_t len = __DARWIN_OSSwapInt32(_fdb->data_fork_size);
    uint32_t abSize = [self.vol allocationBlockSize];
    NSMutableData *result = [NSMutableData dataWithLength:(NSUInteger)len];
    uint8_t *destp = result.mutableBytes;
    NSArray<NSNumber *> *allocationBlockNums = [self dataForkAllocationBlockNums];
    
    for (uint32_t i = 0; i < allocationBlockNums.count; i++) {
        uint16_t abn = [allocationBlockNums[i] unsignedShortValue];
        const uint8_t *ab = [self.vol allocationBlock:abn];
        uint32_t blocksize;
        
        if (i + 1 < allocationBlockNums.count) {
            blocksize = abSize;
        } else {
            // Last allocation block. Truncate to logical EOF.
            blocksize = __DARWIN_OSSwapInt32(_fdb->data_fork_size) % abSize;
        }
        
        memcpy(destp, ab, blocksize);
        destp += blocksize;
    }
    
    return result;
}



@end
