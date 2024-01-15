//
//  MFSVolumeTests.m
//  tests
//
//  Created by Stephen Gravrock on 1/15/24.
//

#import <XCTest/XCTest.h>
#import <string.h>
#import "mfs.h"
#import "MFSVolume.h"

#define MDB_OFFSET 1024

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
    const char *expectedName = "this is a file name";
    size_t len = strlen(expectedName);
    *(uint8_t *)(mdbp + 36) = len;
    strcpy(mdbp + 37, expectedName);
    strcpy(mdbp + 37 + len, "garbage"); // Pascal strings are not null terminated
    MFSVolume *subject = [[MFSVolume alloc] initWithData:data error:nil];
    
    XCTAssertEqualObjects([subject volumeName], [NSString stringWithUTF8String:expectedName]);
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
