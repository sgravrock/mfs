#import "LsCommand.h"
#import "MFSVolume.h"
#import "MFSFile.h"

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
               [[self formatTypeOrCreator:[file type]] UTF8String],
               [[self formatTypeOrCreator:[file creator]] UTF8String]);
    }
    
    return YES;
}

- (NSString *)formatTypeOrCreator:(struct type_or_creator *)typeOrCreator {
    BOOL allPrintable = YES;
    
    for (int i = 0; i < 4; i++) {
        allPrintable = allPrintable && isprint(typeOrCreator->bytes[i]);
    }
    
    if (!allPrintable) {
        return [self formatUnprintableTypeOrCreator:typeOrCreator];
    }
    
    NSString *s = [[NSString alloc] initWithBytes:&typeOrCreator->bytes
                                           length:4
                                         encoding:NSMacOSRomanStringEncoding];
    
    if (s) {
        return s;
    } else {
        return [self formatUnprintableTypeOrCreator:typeOrCreator];
    }
}

- (NSString *)formatUnprintableTypeOrCreator:(struct type_or_creator *)typeOrCreator {
    return [NSString stringWithFormat:@"$%02X%02X%02X%02X",
            typeOrCreator->bytes[0],
            typeOrCreator->bytes[1],
            typeOrCreator->bytes[2],
            typeOrCreator->bytes[3]];
}

@end
