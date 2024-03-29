#import <Foundation/Foundation.h>
@class MFSVolume, MFSFork;
struct mfs_fdb;

NS_ASSUME_NONNULL_BEGIN

@interface MFSFile : NSObject

- (instancetype)initWithVolume:(MFSVolume *)vol fdb:(struct mfs_fdb *)fdb;

@property (nonatomic, readonly, assign) struct mfs_fdb *fdb;

- (NSString *)name;
- (struct type_or_creator *)type;
- (struct type_or_creator *)creator;
- (NSDate *)creationDate;
- (NSDate *)modificationDate;
- (MFSFork *)dataFork;
- (BOOL)hasResourceFork;
- (MFSFork *)resourceFork;


@end

NS_ASSUME_NONNULL_END
