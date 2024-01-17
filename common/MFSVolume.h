//
//  MFSVolume.h
//  mfs
//
//  Created by Stephen Gravrock on 1/14/24.
//

#import <Foundation/Foundation.h>
struct mfs_mdb;
@class MFSFile, MFSBlockMap;

NS_ASSUME_NONNULL_BEGIN

@interface MFSVolume : NSObject

+ (instancetype)volumeWithPath:(NSString *)path error:(NSError **)error;
- (instancetype)initWithData:(NSData *)data error:(NSError **)error;

@property (nonatomic, readonly, assign) struct mfs_mdb *mdb;

- (NSString *)volumeName;
- (NSArray<MFSFile *> *)files;
- (MFSFile *)fileWithName:(NSString *)name;
- (MFSBlockMap *)blockMap;
- (uint32_t)allocationBlockSize;
- (const uint8_t *)allocationBlock:(uint16_t)abi;

@end

NS_ASSUME_NONNULL_END
