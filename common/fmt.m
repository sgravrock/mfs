#import "fmt.h"

static NSString *formatUnprintableTypeOrCreator(struct type_or_creator *typeOrCreator);


NSString *formatTypeOrCreator(struct type_or_creator *typeOrCreator) {
    BOOL allPrintable = YES;
    
    for (int i = 0; i < 4; i++) {
        allPrintable = allPrintable && isprint(typeOrCreator->bytes[i]);
    }
    
    if (!allPrintable) {
        return formatUnprintableTypeOrCreator(typeOrCreator);
    }
    
    NSString *s = [[NSString alloc] initWithBytes:&typeOrCreator->bytes
                                           length:4
                                         encoding:NSMacOSRomanStringEncoding];
    
    if (s) {
        return s;
    } else {
        return formatUnprintableTypeOrCreator(typeOrCreator);
    }
}

static NSString *formatUnprintableTypeOrCreator(struct type_or_creator *typeOrCreator) {
    return [NSString stringWithFormat:@"$%02X%02X%02X%02X",
            typeOrCreator->bytes[0],
            typeOrCreator->bytes[1],
            typeOrCreator->bytes[2],
            typeOrCreator->bytes[3]];
}
