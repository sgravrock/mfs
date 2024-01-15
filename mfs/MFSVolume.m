#import "MFSVolume.h"
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
    } else if (data.length < 400 * 1024) {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Too small to be an MFS volume" forKey:NSLocalizedDescriptionKey];
        *error = [NSError errorWithDomain:@"application" code:0 userInfo:userInfo];
        return nil;
    }

    MFSVolume *result = [[MFSVolume alloc] initWithData:data];
    result.data = data;
    struct mfs_mdb *mdb = result.mdb;
    
    if (!(mdb->signature[0] == 0xd2 && mdb->signature[1] == 0xd7)) {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Not an HFS volume" forKey:NSLocalizedDescriptionKey];
        *error = [NSError errorWithDomain:@"application" code:0 userInfo:userInfo];
        return nil;
    }
    
    return result;
}

- (instancetype)initWithData:(NSData *)data {
    if ((self = [super init])) {
        _mdb = (struct mfs_mdb *)(data.bytes + 1024);
        [self sanityCheck];
    }
    
    return self;
}

- (NSString *)volumeName {
    return [[NSString alloc] initWithBytes:&(_mdb->vol_name)
                                    length:_mdb->vol_name_len
                                  encoding:NSMacOSRomanStringEncoding];
}

- (void)sanityCheck {
    // TODO: move this to a unit test. Assert doesn't run in release builds.
    // Expected offsets are from Inside Macintosh II-121-II-123
    
    // Master Directory Block
    assert(offsetof(struct mfs_mdb, signature) == 0);
    assert(offsetof(struct mfs_mdb, creation_date) == 2);
    assert(offsetof(struct mfs_mdb, last_backup_date) == 6);
    assert(offsetof(struct mfs_mdb, attrs) == 10);
    assert(offsetof(struct mfs_mdb, num_files) == 12);
    assert(offsetof(struct mfs_mdb, file_directory_start) == 14);
    assert(offsetof(struct mfs_mdb, file_directory_len) == 16);
    assert(offsetof(struct mfs_mdb, num_allocation_blocks) == 18);
    assert(offsetof(struct mfs_mdb, allocation_block_size) == 20);
    assert(offsetof(struct mfs_mdb, clump_size) == 24);
    assert(offsetof(struct mfs_mdb, allocation_block_start) == 28);
    assert(offsetof(struct mfs_mdb, next_file_number) == 30);
    assert(offsetof(struct mfs_mdb, num_free_allocation_blocks) == 34);
    assert(offsetof(struct mfs_mdb, vol_name_len) == 36);
    assert(offsetof(struct mfs_mdb, vol_name) == 37);
    
    
    // File Directory Block
    assert(offsetof(struct mfs_fdb, flags) == 0);
    assert(offsetof(struct mfs_fdb, version) == 1);
    
    // Note: offsets of type, creator, finder_flags, icon_position, and folder_number
    // are not documented in Inside Macintosh.
    assert(offsetof(struct mfs_fdb, type) == 2);
    assert(offsetof(struct mfs_fdb, creator) == 6);
    assert(offsetof(struct mfs_fdb, finder_flags) == 10);
    assert(offsetof(struct mfs_fdb, icon_position) == 12);
    assert(offsetof(struct mfs_fdb, folder_number) == 16);
    
    assert(offsetof(struct mfs_fdb, file_number) == 18);
    assert(offsetof(struct mfs_fdb, first_data_fork_allocation_block) == 22);
    assert(offsetof(struct mfs_fdb, data_fork_size) == 24);
    assert(offsetof(struct mfs_fdb, data_fork_allocated_space) == 28);
    assert(offsetof(struct mfs_fdb, first_resource_fork_allocation_block) == 32);
    assert(offsetof(struct mfs_fdb, resource_fork_size) == 34);
    assert(offsetof(struct mfs_fdb, resource_fork_allocated_space) == 38);
    assert(offsetof(struct mfs_fdb, creation_date) == 42);
    assert(offsetof(struct mfs_fdb, modification_date) == 46);
    assert(offsetof(struct mfs_fdb, file_name_len) == 50);
    assert(offsetof(struct mfs_fdb, file_name) == 51);
}

@end
