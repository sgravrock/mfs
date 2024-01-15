#import "InfoCommand.h"
#import "MFSVolume.h"

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
           "%d file directory blocks, startiing at %d.\n"
           "%d allocation blocks, starting at %d.\n"
           "%d free allocation blocks\n",
           [[vol volumeName] UTF8String],
           htons(vol.mdb->num_files),
           htons(vol.mdb->file_directory_len), ntohs(vol.mdb->file_directory_start),
           htons(vol.mdb->num_allocation_blocks), ntohs(vol.mdb->allocation_block_start),
           htons(vol.mdb->num_free_allocation_blocks));
    return YES;
}

@end
