#import "LsCommand.h"
#import "MFSVolume.h"
#import "MFSFile.h"
#import "fmt.h"

@implementation LsCommand

- (nonnull NSString *)name {
    return @"ls";
}

- (nonnull NSString *)usage {
    return @"ls";
}


- (BOOL)executeOnVolume:(MFSVolume *)vol withArgs:(nonnull NSArray<NSString *> *)args {
    NSArray<MFSFile *> *files = [vol files];
    
    for (MFSFile *file in files) {
        const char *name = [[file name] UTF8String];
        
        if (!name) {
            name = "(name that can't be converted to Unicode)";
        }
        
        printf("%s (type=%s, creator=%s)\n", name,
               [formatTypeOrCreator([file type]) UTF8String],
               [formatTypeOrCreator([file creator]) UTF8String]);
    }
    
    return YES;
}

@end
