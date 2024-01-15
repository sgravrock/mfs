#import "MFSFile.h"
#import "MFSVolume.h"
#import "mfs.h"

@interface MFSFile()
@property (nonatomic, strong) MFSVolume *vol;
@end

@implementation MFSFile

- (instancetype)initWithVolume:(MFSVolume *)vol fdb:(struct mfs_fdb *)fdb {
    if ((self = [super init])) {
        _vol = vol;
        _fdb = fdb;
    }
    
    return self;
}

- (NSString *)name {
    return [[NSString alloc] initWithBytes:&(_fdb->file_name)
                                    length:_fdb->file_name_len
                                  encoding:NSMacOSRomanStringEncoding];
}

- (struct type_or_creator *)type {
    return (struct type_or_creator *)&_fdb->type;
}

- (struct type_or_creator *)creator {
    return (struct type_or_creator *)&_fdb->creator;
}



@end
