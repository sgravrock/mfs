#import "Command.h"
#import "MFSVolume.h"
#import "MFSFile.h"
#import "MFSBlockMap.h"

@implementation GetCommand

- (nonnull NSString *)name {
    return @"get";
}

- (nonnull NSString *)usage {
    return @"get mfs-filename destination-path [--text]";
}


- (BOOL)executeOnVolume:(nonnull MFSVolume *)vol withArgs:(nonnull NSArray<NSString *> *)args {
    BOOL textMode;
    
    if (args.count == 2) {
        textMode = NO;
    } else if (args.count == 3 && [args[2] isEqualToString:@"--text"]) {
        textMode = YES;
    } else {
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
    
    NSData *contents = [srcFile dataForkContents];
    BOOL ok = YES;
    
    if (textMode) {
        NSMutableString *converted = [[NSMutableString alloc] initWithData:contents
                                                                  encoding:NSMacOSRomanStringEncoding];
        [converted replaceOccurrencesOfString:@"\r"
                                   withString:@"\n"
                                      options:0
                                        range:NSMakeRange(0, converted.length)];
        contents = [converted dataUsingEncoding:NSUTF8StringEncoding];
        
        if (!contents) {
            fprintf(stderr, "%s does not appear to be a text file\n", [destPath UTF8String]);
            ok = NO;
        }
    }
    
    if (ok) {
        if (fwrite(contents.bytes, contents.length, 1, destFile) != 1) {
            perror([destPath UTF8String]);
            ok = NO;
        }
    }
    
    if (fclose(destFile) != 0) {
        perror([destPath UTF8String]);
        return NO;
    }
    
    // TODO: copy resource fork
    
    // TODO: set type and creator

    return ok;
}

@end
