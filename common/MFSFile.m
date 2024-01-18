#import "MFSFile.h"
#import "MFSVolume.h"
#import "MFSBlockMap.h"
#import "MFSFork.h"
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

- (MFSFork *)dataFork {
    return [[MFSFork alloc] initWithVolume:_vol
                               logicalSize:__DARWIN_OSSwapInt32(_fdb->data_fork_size)
                              physicalSize:__DARWIN_OSSwapInt32(_fdb->data_fork_allocated_space)
                   firstAllocationBlockNum:__DARWIN_OSSwapInt16(_fdb->first_data_fork_allocation_block)];
}

- (BOOL)hasResourceFork {
    return __DARWIN_OSSwapInt32(_fdb->resource_fork_size) > 0;
}

- (MFSFork *)resourceFork {
    return [[MFSFork alloc] initWithVolume:_vol
                               logicalSize:__DARWIN_OSSwapInt32(_fdb->resource_fork_size)
                              physicalSize:__DARWIN_OSSwapInt32(_fdb->resource_fork_allocated_space)
                   firstAllocationBlockNum:__DARWIN_OSSwapInt16(_fdb->first_resource_fork_allocation_block)];
}


@end
