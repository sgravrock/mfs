#import <XCTest/XCTest.h>
#import "MFSFile.h"

#define MAX_FDB_SIZE 306
#define NAME_LENGTH_OFFSET 50
#define TYPE_OFFSET 2
#define CREATOR_OFFSET 6

@interface MFSFileTests : XCTestCase
@end

@implementation MFSFileTests

- (void)testName {
    uint8_t fdb[MAX_FDB_SIZE];
    const char *expectedName = "this is a file name";
    size_t len = strlen(expectedName);
    fdb[NAME_LENGTH_OFFSET] = len;
    strcpy((char *)fdb + NAME_LENGTH_OFFSET + 1, expectedName);
    // Pascal strings are not null terminated
    strcpy((char *)fdb + NAME_LENGTH_OFFSET + 1 + len, "garbage");
    MFSFile *subject = [[MFSFile alloc] initWithVolume:nil fdb:(struct mfs_fdb *)&fdb];
    
    XCTAssertEqualObjects([subject name], [NSString stringWithUTF8String:expectedName]);
}

- (void)testType {
    uint8_t fdb[MAX_FDB_SIZE];
    memcpy(fdb + TYPE_OFFSET, "ASDF", 4);
    MFSFile *subject = [[MFSFile alloc] initWithVolume:nil fdb:(struct mfs_fdb *)&fdb];
    
    struct type_or_creator *type = [subject type];
    
    XCTAssertEqual(type->bytes[0], 'A');
    XCTAssertEqual(type->bytes[1], 'S');
    XCTAssertEqual(type->bytes[2], 'D');
    XCTAssertEqual(type->bytes[3], 'F');
}

- (void)testCreator {
    uint8_t fdb[MAX_FDB_SIZE];
    memcpy(fdb + CREATOR_OFFSET, "qwer", 4);
    MFSFile *subject = [[MFSFile alloc] initWithVolume:nil fdb:(struct mfs_fdb *)&fdb];
    
    struct type_or_creator *creator = [subject creator];
    
    XCTAssertEqual(creator->bytes[0], 'q');
    XCTAssertEqual(creator->bytes[1], 'w');
    XCTAssertEqual(creator->bytes[2], 'e');
    XCTAssertEqual(creator->bytes[3], 'r');
}

@end
