#import "PrintBlockMapCommand.h"
#import "MFSVolume.h"
#import "MFSBlockMap.h"

@implementation PrintBlockMapCommand

- (nonnull NSString *)name {
    return @"print-block-map";
}

- (nonnull NSString *)usage {
    return @"print-block-map";
}

- (BOOL)executeOnVolume:(nonnull MFSVolume *)vol withArgs:(nonnull NSArray<NSString *> *)args {
    [[vol blockMap] enumerate:^(uint16_t abNum, uint16_t next) {
        printf("%u\t%u\n", abNum, next);
    }];
    
    return YES;
}

@end
