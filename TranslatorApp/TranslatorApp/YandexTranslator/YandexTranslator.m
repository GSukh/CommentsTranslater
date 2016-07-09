#import "YandexTranslator.h"

#import <AFNetworking/AFNetworking.h>
#import "TranslatableStringModel.h"

static NSString *const baseAPIURL = @"https://translate.yandex.net/api/v1.5/tr.json/";
static NSString *const APIRequest = @"translate";

static NSString *const APIKey = @"trnsl.1.1.20160707T041034Z.0ed00a6f9ae57bc0.f29291eca9eb42546e2dacc2d6b0c9c02ff82016";

// https://translate.yandex.net/api/v1.5/tr.json/translate?key=trnsl.1.1.20160707T041034Z.0ed00a6f9ae57bc0.f29291eca9eb42546e2dacc2d6b0c9c02ff82016&text=Hello&lang=en-ru

static NSString *const englishLanguageKey = @"en";
static NSString *const frenchLanguageKey = @"fr";
static NSString *const russianLanguageKey = @"ru";


@interface YandexTranslator ()

@property (nonatomic) AFHTTPSessionManager *sessionManager;

@end


@implementation YandexTranslator

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSURL *apiURL = [NSURL URLWithString:baseAPIURL];
        
        _sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:apiURL];
        _sessionManager.responseSerializer = [AFJSONResponseSerializer serializer];
        _sessionManager.requestSerializer = [AFHTTPRequestSerializer serializer];
        
        AFSecurityPolicy* security = [AFSecurityPolicy defaultPolicy];
        security.allowInvalidCertificates = YES;
        security.validatesDomainName = NO;
        _sessionManager.securityPolicy = security;
    }
    
    return self;
}

+ (instancetype)sharedTranslator
{
    static YandexTranslator *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[YandexTranslator alloc] init];
    });
    
    return sharedManager;

}

- (void)getTranslationForString:(TranslatableStringModel *)string
                        success:(void (^)())success
                        failure:(void (^)(NSError *))failure
{
    //NSString *lang = [NSString stringWithFormat:@"%@-%@", englishLanguageKey, russianLanguageKey];
    
    NSDictionary * param = @{
                             @"key" : APIKey,
                             @"text" : string.originalString,
                             @"lang" : englishLanguageKey};
    

    [self.sessionManager POST:APIRequest
                   parameters:param
                     progress:nil
                      success:^(NSURLSessionDataTask * _Nonnull task, NSDictionary * _Nullable responseObject) {
                          string.translated = YES;
                          if (responseObject) {
                              NSArray *textStrings = responseObject[@"text"];
                              
                              string.translatedString = [textStrings firstObject];
                              
                              if (success) {
                                  success();
                              }
                          } else {
                              NSLog(@"failure");
                              if (failure) {
                                  failure(nil);
                              }
                          }
                     }
                      failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                          if (error) {
                              string.translated = YES;
                              if (failure) {
                                  failure(error);
                              }
                          }
                      }];
}


@end
