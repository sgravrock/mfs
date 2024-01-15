#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MFSVolume;

@protocol Command <NSObject>

- (NSString *)name;
- (NSString *)usage;
- (BOOL)executeOnVolume:(MFSVolume *)vol withArgs:(NSArray<NSString *> *)args;

@end

NS_ASSUME_NONNULL_END
