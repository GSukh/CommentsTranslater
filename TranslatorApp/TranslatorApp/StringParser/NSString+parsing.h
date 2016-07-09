#import <Foundation/Foundation.h>

#import "TranslatableStringModel.h"

@interface NSString (parsing)

-(NSArray <TranslatableStringModel *> *)substringsBetweenStartString:(NSString *)startString andEndString:(NSString *)endString;

-(NSArray <TranslatableStringModel *> *)substringsBetweenStartStrings:(NSArray *)startStrings andEndStrings:(NSArray *)endStrings;

@end
