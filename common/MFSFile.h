#import <Foundation/Foundation.h>
@class MFSVolume;
struct mfs_fdb;

struct type_or_creator {
    char bytes[4];
};

NS_ASSUME_NONNULL_BEGIN

@interface MFSFile : NSObject

- (instancetype)initWithVolume:(MFSVolume *)vol fdb:(struct mfs_fdb *)fdb;

@property (nonatomic, readonly, assign) struct mfs_fdb *fdb;

- (NSString *)name;
- (struct type_or_creator *)type;
- (struct type_or_creator *)creator;

@end

NS_ASSUME_NONNULL_END
