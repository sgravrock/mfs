#import "StatCommand.h"
#import "MFSVolume.h"
#import "MFSFile.h"
#import "mfs.h"
#import "fmt.h"

@implementation StatCommand

- (nonnull NSString *)name {
    return @"stat";
}

- (nonnull NSString *)usage {
    return @"stat filename";
}


- (BOOL)executeOnVolume:(nonnull MFSVolume *)vol withArgs:(nonnull NSArray<NSString *> *)args {
    if (args.count != 1) {
        fprintf(stderr, "%s\n", [[self usage] UTF8String]);
        return NO;
    }
    
    NSString *filename = args[0];
    MFSFile *file = [vol fileWithName:filename];
    
    if (!file) {
        fprintf(stderr, "%s: no such file\n", [filename UTF8String]);
        return NO;
    }
    
    struct mfs_fdb *fdb  = file.fdb;
    printf("Basics:\n\n");
    printf("Name:           %s\n", [filename UTF8String]);
    printf("Type:           %s\n", [formatTypeOrCreator([file type]) UTF8String]);
    printf("Creator:        %s\n", [formatTypeOrCreator([file creator]) UTF8String]);
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm";
    printf("Created:        %s\n", [[dateFormatter stringFromDate:[file creationDate]] UTF8String]);
    printf("Last modified:  %s\n",[[dateFormatter stringFromDate:[file modificationDate]] UTF8String]);

    
    printf("\n\nFork allocation info:\n\n");
    printf("First data fork allocation block:      %u\n", __DARWIN_OSSwapInt16(fdb->first_data_fork_allocation_block));
    printf("Data fork size:                        %u bytes\n", __DARWIN_OSSwapInt32(fdb->data_fork_size));
    printf("Data fork allocated space:             %u bytes\n", __DARWIN_OSSwapInt32(fdb->data_fork_allocated_space));
    printf("First resource fork allocation block:  %u\n", __DARWIN_OSSwapInt16(fdb->first_resource_fork_allocation_block));
    printf("Resource fork size:                    %u bytes\n", __DARWIN_OSSwapInt32(fdb->resource_fork_size));
    printf("Resource fork allocated space:         %u bytes\n", __DARWIN_OSSwapInt32(fdb->resource_fork_allocated_space));

    printf("\n\nFinder info:\n\n");
    printf("Finder flags:  %u\n", __DARWIN_OSSwapInt16(fdb->finder_flags));
    printf("Icon position: %u\n", __DARWIN_OSSwapInt32(fdb->icon_position));
    printf("Folder number: %u\n", __DARWIN_OSSwapInt16(fdb->folder_number));

    printf("\n\nArcana:\n\n");
    printf("File number:    %u\n", __DARWIN_OSSwapInt32(fdb->file_number));
    printf("Version: %d\n", fdb->version);
    printf("Flags:   0x%x\n", fdb->flags);

    return YES;
}

@end
