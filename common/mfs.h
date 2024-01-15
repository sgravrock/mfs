// See Inside Macintosh II-119 to II-123,
// or <https://wiki.osdev.org/MFS> for a quick reference.

// Signed-ness of fields in on-disk data structures is undocumented.
// Pascal, the intended lingua franca of Macintosh development at the time,
// only had signed integers. However, MFS was almost certainly implemented in
// asm, and most of these data structures were not visible to user code. It
// probably doesn't matter in practice since negative numbers are not valid
// for any of these fields and MFS does not support volumes large enough to
// have e.g. a numbe of files that doesn't fit in a signed 16 bit integer.

// Note: 16- and 32-bit values are big-endian.

// MFS master directory block
struct __attribute__((__packed__)) mfs_mdb {
    uint8_t signature[2];
    int32_t creation_date;
    int32_t last_backup_date;
    int16_t attrs;
    int16_t num_files;
    int16_t file_directory_start;
    int16_t file_directory_len;
    int16_t num_allocation_blocks;
    int32_t allocation_block_size;
    int32_t clump_size;
    int16_t allocation_block_start;
    int32_t next_file_number;
    int16_t num_free_allocation_blocks;
    // Volume name is a Pascal string, not a C string. The length is broken out
    // seperately here for convenience. vol_name should not be assumed to be
    // null-terminated.
    uint8_t vol_name_len;
    char vol_name[27];
};

// MFS file directory block
// Note: The size of file directory blocks varies with the length of the
// filename. Almost all of them will be smaller than sizeof(mfs_fdb). They are
// padded to a multiple of 2 bytes and do not cross block boundaries.
struct __attribute__((__packed__)) mfs_fdb {
    uint8_t flags;
    int8_t version;
    char type[4];
    char creator[4];
    uint16_t finder_flags;
    int32_t icon_position;
    int16_t folder_number;
    int32_t file_number;
    int16_t first_data_fork_allocation_block;
    int32_t data_fork_size;
    int32_t data_fork_allocated_space;
    int16_t first_resource_fork_allocation_block;
    int32_t resource_fork_size;
    int32_t resource_fork_allocated_space;
    int32_t creation_date;
    int32_t modification_date;
    // File name is a Pascal string, not a C string. The length is broken out
    // seperately here for convenience. file_name should not be assumed to be
    // null-terminated.
    uint8_t file_name_len;
    char file_name[255];
};
