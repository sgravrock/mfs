#import "Command.h"
#import "MFSVolume.h"
#import "MFSFile.h"

@implementation ListBlocksCommand

- (nonnull NSString *)name {
    return @"list-blocks";
}

- (nonnull NSString *)usage {
    return @"list-blocks [filename]";
}


- (BOOL)executeOnVolume:(nonnull MFSVolume *)vol withArgs:(nonnull NSArray<NSString *> *)args {
    if (args.count > 1) {
        fprintf(stderr, "%s\n", [[self usage] UTF8String]);
        return NO;
    } else if (args.count == 1) {
        NSString *filename = args[0];
        MFSFile *f = [vol fileWithName:filename];
        
        if (!f) {
            fprintf(stderr, "%s: no such file\n", [filename UTF8String]);
            return NO;
        }

        [self listBlocksForFile:f];
    } else {
        for (MFSFile *f in [vol files]) {
            [self listBlocksForFile:f];
        }
    }
        
    return YES;
}

- (void)listBlocksForFile:(MFSFile *)file {
    printf("%s: ", [[file name] UTF8String]);
    NSArray<NSNumber *> *blockNums = [file dataForkAllocationBlockNums];
    
    if (blockNums.count == 0) {
        puts("empty");
    } else {
        puts([[blockNums componentsJoinedByString:@" "] UTF8String]);
    }
}


@end
