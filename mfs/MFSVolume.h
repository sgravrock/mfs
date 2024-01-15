//
//  MFSVolume.h
//  mfs
//
//  Created by Stephen Gravrock on 1/14/24.
//

#import <Foundation/Foundation.h>
#import "mfs.h"

NS_ASSUME_NONNULL_BEGIN

@interface MFSVolume : NSObject

+ (instancetype)volumeWithPath:(NSString *)path error:(NSError **)error;

@property (nonatomic, readonly, assign) struct mfs_mdb *mdb;

- (NSString *)volumeName;

@end

NS_ASSUME_NONNULL_END
