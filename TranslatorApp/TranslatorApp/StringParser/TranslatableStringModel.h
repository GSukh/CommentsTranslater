#import <Foundation/Foundation.h>

@interface TranslatableStringModel : NSObject

@property (nonatomic) NSString *originalString;
@property (nonatomic) NSString *translatedString;

@property (nonatomic) NSInteger loc;

@property (nonatomic) BOOL translated;

@end
