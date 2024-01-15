//
//  MFSVolume.h
//  mfs
//
//  Created by Stephen Gravrock on 1/14/24.
//

#import <Foundation/Foundation.h>
struct mfs_mdb;
@class MFSFile;

NS_ASSUME_NONNULL_BEGIN

@interface MFSVolume : NSObject

+ (instancetype)volumeWithPath:(NSString *)path error:(NSError **)error;
- (instancetype)initWithData:(NSData *)data error:(NSError **)error;

@property (nonatomic, readonly, assign) struct mfs_mdb *mdb;

- (NSString *)volumeName;
- (NSArray<MFSFile *> *)files;

@end

NS_ASSUME_NONNULL_END
