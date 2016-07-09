#import "NSString+parsing.h"

@implementation NSString (parsing)

-(NSArray <TranslatableStringModel *> *)substringsBetweenStartString:(NSString *)startString andEndString:(NSString *)endString
{
    NSMutableArray *substrings = [NSMutableArray array];
    
    BOOL inComment = NO;
    NSInteger commentStartIndex = 0;
    
    for (int i = 0; i < self.length - startString.length; i++) {
        //trying to check start string
        NSString *substring = [self substringWithRange:NSMakeRange(i, startString.length)];
        if ([substring isEqualToString:startString] && !inComment) {
            inComment = YES;
            commentStartIndex = i + startString.length;
        }
        
        //trying to check end string
        substring = [self substringWithRange:NSMakeRange(i, endString.length)];
        if ([substring isEqualToString:endString] && inComment) {
            inComment = NO;
            TranslatableStringModel *comment = [[TranslatableStringModel alloc] init];
            comment.originalString = [self substringWithRange:NSMakeRange(commentStartIndex + 1, i - commentStartIndex)];
            comment.loc = commentStartIndex + 1;
            [substrings addObject:comment];
        }
    }
    return substrings;
}

-(NSArray <TranslatableStringModel *> *)substringsBetweenStartStrings:(NSArray *)startStrings andEndStrings:(NSArray *)endStrings
{
    NSMutableArray *substrings = [NSMutableArray array];
    
    BOOL inComment = NO;
    NSInteger commentStartIndex = 0;
    
    NSInteger startStringsMaxLength = [[startStrings valueForKeyPath: @"@max.length"] integerValue];
    //NSInteger endStringsMaxLength = [[endStrings valueForKeyPath: @"@max.length"] integerValue];
    
    for (int i = 0; i < self.length - startStringsMaxLength; i++) {
        //trying to check start string
        
        for (NSString *startString in startStrings) {
            NSString *substring = [self substringWithRange:NSMakeRange(i, startString.length)];

            if ([substring isEqualToString:startString] && !inComment) {
                inComment = YES;
                commentStartIndex = i + startString.length;
            }
        }
        
        //trying to check end string
        for (NSString *endString in endStrings) {
            NSString *substring = [self substringWithRange:NSMakeRange(i, endString.length)];
            if ([substring isEqualToString:endString] && inComment) {
                inComment = NO;
				
				NSString *commentString = [self substringWithRange:NSMakeRange(commentStartIndex + 1, i - commentStartIndex)];
				
				if (![self isCodeString:commentString]) {
					
					TranslatableStringModel *comment = [[TranslatableStringModel alloc] init];
					comment.originalString = commentString;
					comment.loc = commentStartIndex + 1;
					[substrings addObject:comment];
				} else {
					NSLog(@"%@", commentString);
				}
			}
        }
    }
    return substrings;
}

-(BOOL)isCodeString:(NSString *)string
{
	NSArray *codeComponents = @[@"=", @"if", @"for", @"+", @"-", @"*", @"/"];
	BOOL stringContainCodePart = NO;
	
	for (NSString *codePart in codeComponents) {
		stringContainCodePart = [string containsString:codePart];
	}
	
	return stringContainCodePart;
}


@end
