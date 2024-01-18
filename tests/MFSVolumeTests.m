#import <XCTest/XCTest.h>
#import <string.h>
#import "mfs.h"
#import "MFSVolume.h"
#import "MFSFile.h"

#define MDB_OFFSET 1024
#define DIR_START_OFFSET 14
#define DIR_LEN_OFFSET 16
#define NUM_FILES_OFFSET 12
#define FLAGS_OFFSET 0
#define FILE_NAME_LEN_OFFSET 50
#define FILE_NAME_OFFSET 51

@interface MFSVolumeTests : XCTestCase

@end

@implementation MFSVolumeTests

- (void)testRejectsTooSmallVolume {
    NSMutableData *data = [self dataWithValidSignature];
    data.length = 400 * 1024 - 1;
    NSError *error = nil;
    
    MFSVolume *result = [[MFSVolume alloc] initWithData:data error:&error];
    
    XCTAssertNil(result);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects([error localizedDescription], @"too small to be an MFS volume");
}

- (void)testRejectsInvalidSignature {
    NSMutableData *data = [self dataWithValidSignature];
    unsigned char *mdbp = (unsigned char *)data.mutableBytes + MDB_OFFSET;
    mdbp[1] = 0;
    NSError *error = nil;
    
    MFSVolume *result = [[MFSVolume alloc] initWithData:data error:&error];
    
    XCTAssertNil(result);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects([error localizedDescription], @"not an MFS volume");
}


- (void)testVolumeName {
    NSMutableData *data = [self dataWithValidSignature];
    char *mdbp = (char *)data.mutableBytes + MDB_OFFSET;
    const char *expectedName = "this is a volume name";
    size_t len = strlen(expectedName);
    *(uint8_t *)(mdbp + 36) = len;
    strcpy(mdbp + 37, expectedName);
    strcpy(mdbp + 37 + len, "garbage"); // Pascal strings are not null terminated
    MFSVolume *subject = [[MFSVolume alloc] initWithData:data error:nil];
    
    XCTAssertEqualObjects([subject volumeName], [NSString stringWithUTF8String:expectedName]);
}

- (void)testFiles {
    NSMutableData *data = [self dataWithValidSignature];
    unsigned char *bytes = (unsigned char *)data.mutableBytes;
    unsigned char *mdbp = bytes + MDB_OFFSET;
    
    // Set up a directory with:
    // * 2 blocks
    // * at least one entry that needs padding to 2 bytes
    // * Some unused space at the end of the first block
    // * Enough unused space in the last block to accomodate more entries
    *(uint16_t *)(mdbp + DIR_START_OFFSET) = __DARWIN_OSSwapInt16(4);
    *(uint16_t *)(mdbp + DIR_LEN_OFFSET) = __DARWIN_OSSwapInt16(2);
    const char *names[] = {
        "a fairy long name that will take up a bunch of space but is not longer than the 256 byte MFS name limit", // 103
        "another fairly long name that will take up a bunch of space but is not longer than the 256 byte MFS name limit", // 110
        "fairly long name that will take up a bunch of space but is not longer than the 256 byte MFS name limit number 3", //111
        "a name that will be in the second block" // 39
    };
    int nfiles = sizeof names / sizeof *names;
    *(uint16_t *)(mdbp + NUM_FILES_OFFSET) = __DARWIN_OSSwapInt16(nfiles);
    unsigned char *first_dir_block = bytes + MFS_BLOCKSIZE * 4;
    unsigned char *second_dir_block = first_dir_block + MFS_BLOCKSIZE;
    bzero(first_dir_block, MFS_BLOCKSIZE * 2);
    unsigned char *entries[] = {
        first_dir_block,
        first_dir_block + FILE_NAME_OFFSET + 103,
        first_dir_block + FILE_NAME_OFFSET + 103 + FILE_NAME_OFFSET + 111,
        second_dir_block
    };
    
    for (int i = 0; i < nfiles; i++) {
        entries[i][FLAGS_OFFSET] = 0x80; // in use
        size_t len = strlen(names[i]);
        entries[i][FILE_NAME_LEN_OFFSET] = len;
        memcpy(entries[i] + FILE_NAME_OFFSET, names[i], len);
    }
    
    MFSVolume *subject = [[MFSVolume alloc] initWithData:data error:nil];
    NSArray<MFSFile *> *result = [subject files];
    
    XCTAssertEqual(result.count, nfiles);
    // Unroll the loop so we can more easily see which assertion failed
    XCTAssertEqualObjects([result[0] name], [NSString stringWithUTF8String:names[0]]);
    XCTAssertEqualObjects([result[1] name], [NSString stringWithUTF8String:names[1]]);
    XCTAssertEqualObjects([result[2] name], [NSString stringWithUTF8String:names[2]]);
    XCTAssertEqualObjects([result[3] name], [NSString stringWithUTF8String:names[3]]);
}

- (NSMutableData *)dataWithValidSignature {
    NSMutableData *data = [NSMutableData dataWithLength:400 * 1024];
    unsigned char *mdbp = (unsigned char *)data.mutableBytes + MDB_OFFSET;
    bzero(mdbp, 64);
    mdbp[0] = 0xd2;
    mdbp[1] = 0xd7;
    return data;
}

@end
