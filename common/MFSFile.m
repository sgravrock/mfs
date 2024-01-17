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

- (void)readDataForkWithCallback:(BOOL (^)(const uint8_t *, uint32_t))callback {
    // TODO: use dataForkAllocationBlockNums
    uint32_t abSize = [self.vol allocationBlockSize];
    uint32_t nBytesAllocated = __DARWIN_OSSwapInt32(_fdb->data_fork_allocated_space);
    uint32_t nblocks = nBytesAllocated / abSize;
    MFSBlockMap *blockMap = [self.vol blockMap];
    uint16_t abn = __DARWIN_OSSwapInt16(_fdb->first_data_fork_allocation_block);

    for (uint32_t i = 0; i < nblocks; i++) {
        const uint8_t *ab = [self.vol allocationBlock:abn];
        uint32_t sz;
        
        if (i + 1 < nblocks) {
            sz = abSize;
            abn = [blockMap nextAllocationBlock:abn];
        } else {
            // Last allocation block. Truncate to logical EOF.
            sz = __DARWIN_OSSwapInt32(_fdb->data_fork_size) % abSize;
        }
        
        if (!callback(ab, sz)) {
            break;
        }
    }
}



@end
