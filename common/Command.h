#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MFSVolume;

@protocol Command <NSObject>

- (NSString *)name;
- (NSString *)usage;
- (BOOL)executeOnVolume:(MFSVolume *)vol withArgs:(NSArray<NSString *> *)args;

@end

@interface InfoCommand : NSObject<Command>
@end

@interface LsCommand : NSObject<Command>
@end

@interface GetCommand : NSObject<Command>
@end

@interface PrintBlockMapCommand : NSObject<Command>
@end

@interface CheckBlockMapCommand : NSObject<Command>
@end

@interface StatCommand : NSObject<Command>
@end

@interface ListBlocksCommand : NSObject<Command>
@end

NS_ASSUME_NONNULL_END
