#import "Command.h"
#import <sys/xattr.h>
#import "MFSVolume.h"
#import "MFSFile.h"
#import "MFSFork.h"
#import "mfs.h"

#define XATTR_FINDERINFO_LENGTH 32 // see ATTR_CMN_FNDRINFO in getattrlist(2)


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
    
    // Copy the data fork even if it's empty. MFS doesn't distinguish between
    // empty and nonexistent forks, but AFS does. And it requries a file to have
    // a data fork.
    BOOL ok = [self copyDataForkFrom:srcFile to:destPath textMode:textMode];
    ok = ok && [self copyAttrsFrom:srcFile to:destPath];
    
    if (ok && [srcFile hasResourceFork]) {
        NSString *destResPath = [NSString stringWithFormat:@"%@/..namedfork/rsrc", destPath];
        ok = [self copyResourceForkFrom:srcFile to:destResPath];
    }
    
    return ok;
}

- (BOOL)copyDataForkFrom:(MFSFile *)srcFile to:(NSString *)destPath textMode:(BOOL)textMode {
    return [self copyFork:[srcFile dataFork] to:destPath withConversion:^NSData *(NSData *contents) {
        if (!textMode) {
            return contents;
            
        }
        
        NSMutableString *converted = [[NSMutableString alloc] initWithData:contents
                                                                  encoding:NSMacOSRomanStringEncoding];
        [converted replaceOccurrencesOfString:@"\r"
                                   withString:@"\n"
                                      options:0
                                        range:NSMakeRange(0, converted.length)];
        NSData *result = [converted dataUsingEncoding:NSUTF8StringEncoding];
        
        if (!result) {
            fprintf(stderr, "%s does not appear to be a text file\n", [destPath UTF8String]);
        }
        
        return result;
    }];
}

- (BOOL)copyResourceForkFrom:(MFSFile *)srcFile to:(NSString *)destPath {
    return [self copyFork:[srcFile resourceFork] to:destPath withConversion:nil];
}

- (BOOL)copyFork:(MFSFork *)fork to:(NSString *)destPath withConversion:(NSData * (^)(NSData *))conversion {
    FILE *destFile = fopen([destPath UTF8String], "wxb");

    if (!destFile) {
        perror([destPath UTF8String]);
        return NO;
    }
    
    NSData *contents = [fork contents];
    
    if (conversion) {
        contents = conversion(contents);
    }
    
    BOOL ok = YES;
    
    if (!contents) {
        ok = NO;
    } else if (contents.length > 0) {
        if (fwrite(contents.bytes, contents.length, 1, destFile) != 1) {
            perror([destPath UTF8String]);
            ok = NO;
        }
    }
    
    if (fclose(destFile) != 0) {
        perror([destPath UTF8String]);
        return NO;
    }

    return ok;
}

- (BOOL)copyAttrsFrom:(MFSFile *)srcFile to:(NSString *)destPath {
    // Set type and creator
    char attr[XATTR_FINDERINFO_LENGTH];
    bzero(attr, sizeof(attr));
    memcpy(attr, srcFile.fdb->type, 4);
    memcpy(attr + 4, srcFile.fdb->creator, 4);
    
    if (setxattr([destPath UTF8String], XATTR_FINDERINFO_NAME, attr, sizeof(attr), 0, XATTR_CREATE) == -1) {
        perror("setxattr");
        return NO;
    }
    
    return YES;
}

@end
