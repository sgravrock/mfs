#import <Foundation/Foundation.h>
#import "InfoCommand.h"
#import "LsCommand.h"
#import "MFSVolume.h"

static void usage(const char *progname, NSArray<id<Command>> *cmds);
static id<Command> first_matching_cmd(NSArray<id<Command>> *cmds, NSString *name);
static NSArray<NSString *> *array_from_argv(const char **argv);

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSArray<id<Command>> *cmds = @[
            [[InfoCommand alloc] init],
            [[LsCommand alloc] init],
        ];
        
        if (argc < 3) {
            usage(argv[0], cmds);
            return EXIT_FAILURE;
        }
        
        NSString *imagePath = [NSString stringWithUTF8String:argv[1]];
        id<Command> cmd = first_matching_cmd(cmds, [NSString stringWithUTF8String:argv[2]]);
        
        if (!cmd) {
            usage(argv[0], cmds);
            return EXIT_FAILURE;
        }
        
        NSError *error = nil;
        MFSVolume *vol = [MFSVolume volumeWithPath:imagePath error:&error];
        
        if (!vol) {
            fprintf(stderr, "%s\n", [[error localizedDescription] UTF8String]);
            return EXIT_FAILURE;
        }
        
        BOOL ok = [cmd executeOnVolume:vol withArgs:array_from_argv(argv + 3)];
        return ok ? 0 : EXIT_FAILURE;
    }
}

static void usage(const char *progname, NSArray<id<Command>> *cmds) {
    fprintf(stderr, "Usage: %s image-filename command [args...]\n\n", progname);
    fprintf(stderr, "Commands:\n");
    
    for (id<Command> cmd in cmds) {
        fprintf(stderr, "%s\n", [[cmd usage] UTF8String]);
    }
    
    exit(EXIT_FAILURE);
}

static id<Command> first_matching_cmd(NSArray<id<Command>> *cmds, NSString *name) {
    for (id<Command> cmd in cmds) {
        if ([cmd.name isEqualToString:name]) {
            return cmd;
        }
    }
    
    return nil;
}

static NSArray<NSString *> *array_from_argv(const char **argv) {
    NSMutableArray *result = [NSMutableArray array];

    while (*argv) {
        [result addObject:[NSString stringWithUTF8String:*argv]];
        argv++;
    }

    return result;
}
