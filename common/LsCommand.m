#import "LsCommand.h"

@implementation LsCommand

- (nonnull NSString *)name {
    return @"ls";
}

- (nonnull NSString *)usage {
    return @"ls";
}


- (BOOL)executeOnVolume:(MFSVolume *)vol withArgs:(nonnull NSArray<NSString *> *)args {
    puts("TODO");
    return NO;
}

@end
