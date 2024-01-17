#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MFSBlockMap : NSObject

/*
 A note on the end pointer:
 MFS doesn't directly encode the size of the block map. It occupies some, but
 not normally all, of the space between the master directory block and the first
 file directory block. The end pointer can point to any byte from the logical
 end of the block map to the end of the last logical block occupied by the block
 map.
 */
- (instancetype)initWithBytes:(const uint8_t *)bytes end:(const uint8_t *)end;

- (void)enumerate:(void (^)(uint16_t abNum, uint16_t next))callback;
- (uint16_t)nextAllocationBlock:(uint16_t)abn;

@end

NS_ASSUME_NONNULL_END
