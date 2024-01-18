#import "Command.h"
#import "MFSVolume.h"
#import "mfs.h"

@implementation InfoCommand

- (nonnull NSString *)name {
    return @"info";
}

- (nonnull NSString *)usage {
    return @"info";
}

- (BOOL)executeOnVolume:(nonnull MFSVolume *)vol withArgs:(nonnull NSArray<NSString *> *)args {
    printf("Volume name: %s\n"
           "Number of files: %d\n"
           "%d file directory blocks, starting at %d.\n"
           "%d allocation blocks of %d bytes, starting at %d.\n"
           "%d free allocation blocks\n",
           [[vol volumeName] UTF8String],
           __DARWIN_OSSwapInt16(vol.mdb->num_files),
           __DARWIN_OSSwapInt16(vol.mdb->file_directory_len),
           __DARWIN_OSSwapInt16(vol.mdb->file_directory_start),
           __DARWIN_OSSwapInt16(vol.mdb->num_allocation_blocks),
           __DARWIN_OSSwapInt32(vol.mdb->allocation_block_size),
           __DARWIN_OSSwapInt16(vol.mdb->allocation_block_start),
           __DARWIN_OSSwapInt16(vol.mdb->num_free_allocation_blocks));
    return YES;
}

@end
