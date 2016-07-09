#import <Foundation/Foundation.h>

@class TranslatableStringModel;

@interface YandexTranslator : NSObject

+ (instancetype)sharedTranslator;

- (void)getTranslationForString:(TranslatableStringModel *)string
                        success:(void (^)())success
                        failure:(void (^)(NSError *))failure;

@end
