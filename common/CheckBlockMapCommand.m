#import "Command.h"
#import "MFSVolume.h"
#import "MFSBlockMap.h"
#import "mfs.h"

@implementation CheckBlockMapCommand

- (nonnull NSString *)name {
    return @"check-block-map";
}

- (nonnull NSString *)usage {
    return @"check-block-map";
}

- (BOOL)executeOnVolume:(nonnull MFSVolume *)vol withArgs:(nonnull NSArray<NSString *> *)args {
    NSMutableDictionary<NSNumber *, NSNumber *> *backlinks = [NSMutableDictionary dictionary];
    __block BOOL ok = YES;
    __block int32_t minSeen = INT32_MAX, maxSeen = INT32_MIN;
    __block int numUsedBlocksFound = 0;
    
    [[vol blockMap] enumerate:^(uint16_t abNum, uint16_t next) {
        minSeen = MIN(minSeen, abNum);
        maxSeen = MAX(maxSeen, MAX(abNum, next));

        // Unused parts of the block map are zero-filled. 1 indicates the end of the block chain
        // for a file.
        if (next != 0) {
            numUsedBlocksFound++;
        }
        
        if (next != 0 && next != 1) {
            minSeen = MIN(minSeen, next);
            NSNumber *k = [NSNumber numberWithUnsignedShort:next];
            NSNumber *existing = backlinks[k];
            
            if (existing) {
                printf("%u is referenced from both %u and %u\n", next, abNum, [existing unsignedShortValue]);
                ok = NO;
            } else {
                backlinks[k] = [NSNumber numberWithUnsignedShort:abNum];
            }
        }
    }];
    
    if (ok) {
        puts("Block map integrity looks ok");
    }
    
    uint16_t numAbs = __DARWIN_OSSwapInt16(vol.mdb->num_allocation_blocks);
    uint16_t numFreeAbs = __DARWIN_OSSwapInt16(vol.mdb->num_free_allocation_blocks);
    
    if (numFreeAbs != numAbs - numUsedBlocksFound) {
        printf("Found %d free allocation blocks but the master directory block says there are %u\n", numAbs - numUsedBlocksFound, numFreeAbs);
        ok = NO;
    }
    
    NSArray *valuesSeen = [[backlinks allValues] sortedArrayUsingSelector:@selector(compare:)];
    printf("Range of allocation block numbers seen: %u-%u\n", [valuesSeen[0] unsignedShortValue], [[valuesSeen lastObject] unsignedShortValue]);
    
    if (!ok) {
        puts("Note: this is meant as a debugging tool");
        puts("Errors found here might indicate bugs in this program, not problems with the filesystem.");
    }

    // TODO: also check range of blocks, # free blocks, etc.
    
    return ok;
}

@end
