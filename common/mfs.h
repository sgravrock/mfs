/*
 The MFS filesystem was used by the Macintosh on 400KB floppy disks and a few
 very early hard disks. It was superseded by the HFS filesystem with the
 introduction of 800KB floppies and Apple's own 20MB external hard disk. MFS is
 the only filesystem understood by the Macintosh 128K and 512k. Later machines
 use HFS to format any media other than 400KB floppies.
 
 MFS is briefly described in Inside Macintosh II-119 to II-123. There is also a
 useful quick reference at <https://wiki.osdev.org/MFS>.
 
 MFS is a very basic filesystem. It's similar to a simplified FAT12 with two
 forks per file and no support for subdirctories. (The system software sort of
 fakes directories via Finder metadata, but the actual structure is a flat list
 of files and that fact is very much visible to the user.) The design of the
 filesystem sacrifices features, performance, and expandability in favor of
 simplicity. MFS can be implemented with very little code and O(1) memory usage,
 significant virtues if you are trying to fit an operating system and GUI
 toolkit into 64KB of ROM and 128KB of RAM.
 
 
 A typical 400K MFS-formatted floppy disk is laid out as follows:
 
 | logical block # | Contents                             |
 +-----------------+--------------------------------------+
 | 0 to            | Boot blocks[0]                       |
 | 2 to 3          | Master directory block and block map |
 | 4 to n          | Directory                            |
 | n to 799        | Allocation blocks (file contents)    |
 
 Each of those structures are described below.
 
 Some of the structure can at least theoretically be rearranged via the master
 directory block (see below), and it's possible that this was done on MFS-
 formatted hard disks. Those are rare. All of the MFS images I've seen are 400K
 floppies and they are all laid out as above.
 
 [0] Boot blocks were most likely only used by the first two Macintosh models
     with 64KB ROMS. See <https://macgui.com/news/article.php?t=496>. The later
     HFS filesystem also has boot blocks but they are usually empty.

 Signed-ness of most fields in on-disk data structures is undocumented. Pascal,
 the lingua franca of early Macintosh development, only had signed  integers.
 However, MFS was almost certainly implemented in asm, and most of these data
 structures were not visible to user code. It probably doesn't matter in
 practice since negative numbers are not valid for any of these fields and MFS
 does not support volumes large enough to have e.g. a number of files that
 doesn't fit in a signed 16 bit integer. The one exception is
 mfs_fdb.folder_number which has known valid negative values.

 Note: 16- and 32-bit values are big-endian.

 Inside Macintosh describes logical blocks as being 512 bytes plus another
 12 bytes that belong to the disk driver. However, it also says that
 signature (0xD2D7, big-endian) is at the start of the master directory block
 which is logical block 2. In MFS floppy disk images seen in the wild, the
 signature is always 1024 bytes into the image. It follows that the logical
 block size is 512 bytes, at least for floppy disks.
 
 IMPORTANT: the allocation block size is a multiple of the logical block size.
 See mfs_mdb.allocation_block_size below. Some sources indicate that 512 bytes,
 or one logical block, is the norm but I haven't seen any images like that. All
 400KB floppy images I've seen have 1KB allocation block. Inside Macintosh
 II-120 indicates that the allocation block size is chosen to make the master
 directory block and block map fit in two logical blocks, so it's likely that
 anything larger than a 400KB floppy used an allocation block size larger than
 1KB.
 */
#define MFS_BLOCKSIZE 512

// Offsets of the fixed-position parts of the filesystem
#define MFS_MDB_OFFSET 1024
#define MFS_BLOCK_MAP_OFFSET 1088

#define MFS_MIN_ALLOCATION_BLOCK_NUM 2
#define MFS_ALLOCATION_BLOCK_NUM_UNUSED 0
#define MFS_ALLOCATION_BLOCK_NUM_EOF 1


/*
 The master directory block is stored at the start of the third logical block
 (offset 1024). It describes the layout of the filesystem and contains some basic
 metadata
 */
struct __attribute__((__packed__)) mfs_mdb {
    uint8_t signature[2];           // always 0xD2D7
    uint32_t creation_date;          // seconds since Jan 1 1904
    uint32_t last_backup_date;       // seconds since Jan 1 1904
    uint16_t attrs;
    uint16_t num_files;
    uint16_t file_directory_start;   // in logical blocks
    uint16_t file_directory_len;     // in logical blocks
    uint16_t num_allocation_blocks;
    uint32_t allocation_block_size;  // in bytes
    uint32_t clump_size;             // # bytes to allocate when growing a file
    uint16_t allocation_block_start; // in logical blocks
    uint32_t next_file_number;
    uint16_t num_free_allocation_blocks;
    // Volume name is a Pascal string, not a C string. The length is broken out
    // seperately here for convenience. vol_name should not be assumed to be
    // null-terminated.
    uint8_t vol_name_len;
    char vol_name[27];
};

/*
 Next is the block map. This immediately follows the master directory block: it
 starts on the next byte, not the next logical block. The block map is similar
 to FAT12. Conceptually, it can be thought of as one linked list per fork all
 packed into a single array. Each entry corresponds to an allocation block and
 contains the number of the next allocation block in the fork. There are three
 special values:
 
 * 0 indicates that the block is unused.
 * 1 indicates physical end-of-file: The block is used but it is the last block
   in the fork.
 * $FFF indicates that the block is occupied by the directory. This only occurs
   if the directory is located within the allocations block, an arrangement that
   is documented by Inside Macintosh but that I haven't seen in the wild.
 
 Unused blocks are represented by 0 and EOF is represented by 1. So a fork's
 allocation blocks can be found by traversing the block map, starting with the
 first allocation block number in the fork (found in the file directory block,
 see below) until the right number of allocation blocks are found or an
 allocation block number of 1 is reached.
 
 Allocation block numbers are 12 bits long. Two entreis are packed into every
 three bytesof the block map. The first two entries are skipped because 0 and 1
 are not valid allocation block numbers. For example, the entry for allocation
 block 2 is stored in byte 0 and the high nybble of byte 1. The entry for
 allocation block 5 is stored in the low nybble of byte 4 and byte 5.
 
 The block map typically doesn't end on a logical block boundary. The contents
 of the "dead space" between the end of the block map and the next logical block
 is undocumented, but in practice it appears to always be zero-filled.
 

 In a typical MFS filesystem, the next thing after the block map is the (single)
 directory. The directory is a packed array of variable-length file directory
 blocks, each representing a single file. The size of each file directory block
 (FDB) is 36 bytes plus the length of the filename, plus one byte if necessary
 to pad the size of the FDB to an even number of bytes.
 
 FDBs do not cross logical block boundaries. The result is that there is usually
 some dead space at the end of each logical block. In practice the dead space
 appears to always be zero-filled, but Inside Macintosh only documents that bit
 7 of the flags field will be cleared. Other than that, there is no dead space
 in the directory: deleting a file or shortening its name involves rewriting all
 following FDBs.
 
 The filename encoding is not specified. All of the MFS images I have access to
 appear to use either the Mac OS Roman encoding or something else that's highly
 ASCII-compatible, but it probably varies depending on which international
 version of the system softwar wrote the directory. Filenames are
 case-insensitive: "foo" and "FOO" refer to the same file. Figuring out how
 (or whether) that worked in cases where the same volume was written to by
 computers that used different text encodings is left as an exercise to the
 reader.
 */

struct __attribute__((__packed__)) mfs_fdb {
    // Flags is mostly undocumented. Bit 7 is always set if the entry is in use.
    uint8_t flags;
    int8_t version;          // Set to 0
    char type[4];            // Usually but not necessarily printable
    char creator[4];         // Usually but not necessarily printable
    uint16_t finder_flags;   // Undocumented
    uint32_t icon_position;
    // The folder number indicates where the Finder will display the file.
    // -2 means desktop, -1 maans trash, 0 means the main volume window,
    // and a positive number identifies a folder.
    int16_t folder_number;
    uint32_t file_number;     // The file's ID
    
    // Data and resource forks are each described by three fields: the number
    // of the first allocation block, the size of the fork in bytes, and the
    // size of the allocated space in bytes. The size of the allocated space is
    // a multiple of the allocation block size. Zero-length forks are valid and
    // very common.
    uint16_t first_data_fork_allocation_block;
    uint32_t data_fork_size;
    uint32_t data_fork_allocated_space;
    uint16_t first_resource_fork_allocation_block;
    uint32_t resource_fork_size;
    uint32_t resource_fork_allocated_space;
    
    uint32_t creation_date;      // seconds since Jan 1 1904
    uint32_t modification_date;  // seconds since Jan 1 1904
    
    // File name is a Pascal string, not a C string. The length is broken out
    // seperately here for convenience. file_name should not be assumed to be
    // null-terminated.
    uint8_t file_name_len;
    char file_name[255];
};

struct type_or_creator {
    char bytes[4];
};
