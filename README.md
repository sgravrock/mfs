# mfs: copy files from MFS disk images on OS X

This program copies files from MFS images. MFS was the original Macintosh
filesystem. It was quickly superseded by HFS and was only used on 400K floppies
and some very early hard disks.

The structure of the MFS filesystem is explained in
[mfs.h](https://github.com/sgravrock/mfs/blob/main/common/mfs.h).

## Media compatibility

400K disk images are known to work. The image must be a "raw" image of the
floppy disk, with no additional header, container, or encoding. If the `file`
command reports something including "Macintosh MFS data", it'll probably work.
If you have a Disk Copy 4.2 image (unlikely, but possible), you'll need to
strip off the header with a tool like `dd` or
[undiskcopy](https://github.com/sgravrock/adventofcode/blob/master/2022/pascal/undiskcopy.c).

MFS hard disk images might work, but I can't be sure because I've never seen
one.

If you have an actual 400K floppy disk, be aware that modern floppy drives are
physically incapable of reading them. You'll need an old Macintosh with an
Apple SuperDrive. (And if your old Macintosh has an old enough version of the
system software, you won't need this program because you can read the disk
directly.)

## Why?

Because it was there.

Because it was really cold out last weekend.

Because I thought it might be fun. (It was.)

Because most of the programming I do is more high level, and I wanted to see 
whether I could implement a filesystem (albeit a very simple one) with nothing
but a few pages of documentation and a hex editor.

## Building

You'll need Xcode. Version 14.2 on Monterey is known to work. Open
`mfs.xcodeproj` in Xcode and build it (cmd-b or Product-&gt;Build). To find
the resulting `mfs` binary, select Product-&gt;Show Build Folder in Finder.

## Support, or lack thereof

This software is a
[home-cooked meal](https://www.robinsloan.com/notes/home-cooked-app/).
I made it for me. If you find it useful, that's a happy side effect. I'm making
it available with **absolutely no warranty whatsoever** and no promise of
support, bug fixes, or future development of any kind. Use it at your own
risk.

You are welcome to report bugs, but I don't promise to fix them. I'm more
likely to act on bug reports that contain all the information I need to
reproduce the bug. In many cases that includes a copy of the disk image that
you were using when you encountered the bug.

## License

This software is licensed under the MIT License with Commons Clause restriction.
See LICENSE.md.

## Known limitations

* File paths and text file contents on MFS volumes are assumed to be in the
  Mac OS Roman encoding. Other encodings are not supported.
* File paths containing the null character are not supported.
* When copying files, the destination must be an HFS or APFS volume. OSes other
  than OS X are not supported.
