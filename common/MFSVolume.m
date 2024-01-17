#import "MFSVolume.h"
#import "MFSFile.h"
#import "MFSBlockMap.h"
#import "mfs.h"

@interface MFSVolume()
@property (nonatomic, strong) NSData *data;
@end;

@implementation MFSVolume

+ (instancetype)volumeWithPath:(NSString *)path error:(NSError **)error {
    // The typical MFS volume is 400KB and the maximum is 20MB (and those are rare)
    // so just read the whole thing into RAM.
    NSData *data = [NSData dataWithContentsOfFile:path options:0 error:error];
    
    if (!data) {
        return nil;
    }
    
    return [[MFSVolume alloc] initWithData:data error:error];
}

- (instancetype)initWithData:(NSData *)data error:(NSError **)error {
    if (data.length < 400 * 1024) {
        *error = [MFSVolume errorWithDescription:@"too small to be an MFS volume"];
        return nil;
    }
    
    struct mfs_mdb *mdb = (struct mfs_mdb *)(data.bytes + MFS_MDB_OFFSET);
    
    if (!(mdb->signature[0] == 0xd2 && mdb->signature[1] == 0xd7)) {
        *error = [MFSVolume errorWithDescription:@"not an MFS volume"];
        return nil;
    }

    if ((self = [super init])) {
        _data = data;
        _mdb = mdb;
    }
    
    return self;
}

- (NSString *)volumeName {
    return [[NSString alloc] initWithBytes:&(_mdb->vol_name)
                                    length:_mdb->vol_name_len
                                  encoding:NSMacOSRomanStringEncoding];
}

- (NSArray<MFSFile *> *)files {
    uint16_t start_block_num = __DARWIN_OSSwapInt16(_mdb->file_directory_start);
    unsigned char *fd_blocks = (unsigned char *)_data.bytes + MFS_BLOCKSIZE * start_block_num;
    uint16_t num_files = __DARWIN_OSSwapInt16(_mdb->num_files);
    uint16_t num_dir_blocks = __DARWIN_OSSwapInt16(_mdb->file_directory_len);
    NSMutableArray<MFSFile *> *result = [NSMutableArray arrayWithCapacity:num_files];
    
    for (int i = 0; i < num_dir_blocks && result.count < num_files; i++) {
        [self addFilesFromDirectoryBlock:fd_blocks + i * MFS_BLOCKSIZE
                                 toArray:result
                                   limit:num_files];
    }
    
    return result;
}

- (void)addFilesFromDirectoryBlock:(unsigned char *)block
                           toArray:(NSMutableArray<MFSFile *> *)dest
                             limit:(uint16_t)limit {
    unsigned char *p = block;
    unsigned char *end = block + MFS_BLOCKSIZE;
    
    while (dest.count < limit) {
        struct mfs_fdb *fdb = (struct mfs_fdb *)p;
        

        // Entries do not span block boundaries.
        // But since entries are variable length, we might have to look at the
        // maybe-not-an-entry to figure out whether it exists. Fortunately the
        // empty space at the end of a directory block appears to always be zero-
        // filled in practice, although this isn't documented. So we can assume
        // we've reached dead space if the first byte of the name field would be
        // in the next block or the name length is zero.
        
        // TODO: check the flags (whch *are* documented) rather than relying on
        // zero fill
        if (p + offsetof(struct mfs_fdb, file_name) >= end || fdb->file_name_len == 0) {
            break;
        }

        MFSFile *file = [[MFSFile alloc] initWithVolume:self fdb:fdb];
        [dest addObject: file];
    
        // Entries are variable length and padded to an even number of bytes
        p = (unsigned char *)&fdb->file_name + fdb->file_name_len;
        
        if ((uintptr_t)p % 2 != 0) {
            p++;
        }
    }
}

- (MFSFile *)fileWithName:(NSString *)name {
    for (MFSFile *file in [self files]) {
        if ([[file name] isEqualToString:name]) {
            return file;
        }
    }
    
    return nil;
}

- (MFSBlockMap *)blockMap {
    int16_t dir_start = __DARWIN_OSSwapInt16(_mdb->file_directory_start);
    return [[MFSBlockMap alloc] initWithBytes:_data.bytes + MFS_BLOCK_MAP_OFFSET
                                          end:_data.bytes + dir_start * MFS_BLOCKSIZE];
}

- (uint32_t)allocationBlockSize {
    return __DARWIN_OSSwapInt32(_mdb->allocation_block_size);
}

- (const uint8_t *)allocationBlock:(uint16_t)abi {
    uint32_t base = __DARWIN_OSSwapInt16(_mdb->allocation_block_start) * MFS_BLOCKSIZE;
    const uint32_t allocationBlockSize = __DARWIN_OSSwapInt32(_mdb->allocation_block_size);
    uint32_t offset = base + (abi - MFS_MIN_ALLOCATION_BLOCK_NUM) * allocationBlockSize;
    return _data.bytes + offset;
}

+ (NSError *)errorWithDescription:(NSString *)description {
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:description forKey:NSLocalizedDescriptionKey];
    return [NSError errorWithDomain:@"application" code:0 userInfo:userInfo];
}

@end
