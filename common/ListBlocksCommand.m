#import "Command.h"
#import "MFSVolume.h"
#import "MFSFile.h"
#import "MFSFork.h"

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
    printf("%s data: ", [[file name] UTF8String]);
    [self listBlocksForFork:[file dataFork]];
    
    if ([file hasResourceFork]) {
        printf("%s resource: ", [[file name] UTF8String]);
        [self listBlocksForFork:[file resourceFork]];
    }
}

- (void)listBlocksForFork:(MFSFork *)fork {
    NSArray<NSNumber *> *blockNums = [fork allocationBlockNums];
    
    if (blockNums.count == 0) {
        puts("empty");
    } else {
        puts([[blockNums componentsJoinedByString:@" "] UTF8String]);
    }
}


@end
