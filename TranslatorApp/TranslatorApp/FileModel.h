#import <Foundation/Foundation.h>

@interface FileModel : NSObject

@property (nonatomic) NSString *originalPath;
@property (nonatomic) NSString *translatedPath;

@property (nonatomic) BOOL translatable;
@property (nonatomic) BOOL translated;

@end
