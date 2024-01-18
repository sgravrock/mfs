#import "Command.h"
#import "MFSVolume.h"
#import "MFSFile.h"
#import "MFSBlockMap.h"

@implementation GetCommand

- (nonnull NSString *)name {
    return @"get";
}

- (nonnull NSString *)usage {
    return @"get mfs-filename destination-path";
}


- (BOOL)executeOnVolume:(nonnull MFSVolume *)vol withArgs:(nonnull NSArray<NSString *> *)args {
    if (args.count != 2) {
        fprintf(stderr, "%s\n", [[self usage] UTF8String]);
        return NO;
    }
    
    NSString *srcName = args[0];
    NSString *destPath = args[1];
    MFSFile *srcFile = [vol fileWithName:srcName];
    
    if (!srcFile) {
        fprintf(stderr, "%s: no such file\n", [srcName UTF8String]);
        return NO;
    }
    
    FILE *destFile = fopen([destPath UTF8String], "wxb");

    if (!destFile) {
        perror([destPath UTF8String]);
        return NO;
    }
    
    __block BOOL ok = YES;
    [srcFile readDataForkWithCallback:^BOOL(const uint8_t * _Nonnull block, uint32_t blocksz) {
        if (fwrite(block, blocksz, 1, destFile) != 1) {
            perror([destPath UTF8String]);
            ok = NO;
            return NO;
        }
        
        return YES;
    }];

    if (fclose(destFile) != 0) {
        perror([destPath UTF8String]);
        return NO;
    }
    
    // TODO: copy resource fork
    
    // TODO: set type and creator

    return YES;
}

@end
