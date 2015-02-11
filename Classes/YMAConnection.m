//
//  YMAConnection.m
//
//  Created by Alexander Mertvetsov on 31.10.13.
//  Copyright (c) 2014 Yandex.Money. All rights reserved.
//

#import "YMAConnection.h"

static NSString *const kRequestMethodPost = @"POST";
static NSString *const kRequestMethodGet = @"GET";

static NSInteger const kRequestTimeoutIntervalDefault = 60;
static NSString *const kHeaderContentLength = @"Content-Length";

@interface YMAConnection ()

@property (nonatomic, strong) NSMutableURLRequest *request;

@end

@implementation YMAConnection

#pragma mark - Object Lifecycle

- (instancetype)initWithUrl:(NSURL *)url parameters:(NSDictionary *)params requestMethod:(NSString *)requestMethod
{
    self = [super init];
    
    if (self != nil) {
        NSURL *requestUrl = url;
        NSString *paramString = [YMAConnection bodyStringWithParams:params];
        
        if ([requestMethod isEqualToString:kRequestMethodGet]) {
            NSString *urlWithQuery = [NSString stringWithFormat:@"%@?%@", [url absoluteString], paramString];
            requestUrl = [NSURL URLWithString:urlWithQuery];
        }
        
        _request = [[NSMutableURLRequest alloc] initWithURL:requestUrl
                                                cachePolicy:NSURLRequestUseProtocolCachePolicy
                                            timeoutInterval:kRequestTimeoutIntervalDefault];
        _request.HTTPMethod = requestMethod;
        
        if ([requestMethod isEqualToString:kRequestMethodPost])
            _request.HTTPBody = [paramString dataUsingEncoding:NSUTF8StringEncoding];
    }
    
    return self;
}

- (instancetype)initWithUrl:(NSURL *)url bodyData:(NSData *)bodyData
{
    self = [super init];
    
    if (self != nil) {
        NSURL *requestUrl = url;
        _request = [[NSMutableURLRequest alloc] initWithURL:requestUrl
                                                cachePolicy:NSURLRequestUseProtocolCachePolicy
                                            timeoutInterval:kRequestTimeoutIntervalDefault];
        _request.HTTPMethod = kRequestMethodPost;
        _request.HTTPBody = bodyData;
    }
    
    return self;
}

+ (instancetype)connectionForPostRequestWithUrl:(NSURL *)url
                                      postParameters:(NSDictionary *)postParams
{
    return [[YMAConnection alloc] initWithUrl:url parameters:postParams requestMethod:kRequestMethodPost];
}

+ (instancetype)connectionForPostRequestWithUrl:(NSURL *)url
                                         bodyData:(NSData *)bodyData
{
    return [[YMAConnection alloc] initWithUrl:url bodyData:bodyData];
}

+ (instancetype)connectionForGetRequestWithUrl:(NSURL *)url
                                     parameters:(NSDictionary *)postParams
{
    return [[YMAConnection alloc] initWithUrl:url parameters:postParams requestMethod:kRequestMethodGet];
}

#pragma mark - Public methods

+ (NSString *)addPercentEscapesForString:(NSString *)string
{
    return (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,
        (__bridge CFStringRef)string,
        NULL,
        (CFStringRef)@";/?:@&=+$,",
        kCFStringEncodingUTF8));
}

- (void)sendAsynchronousWithQueue:(NSOperationQueue *)queue completionHandler:(YMAConnectionHandler)handler
{

    [self.request addValue:[NSString stringWithFormat:@"%lu", (unsigned long)[self.request.HTTPBody length]]
        forHTTPHeaderField:kHeaderContentLength];

    NSLog(@"<<<< Request to URL: %@ >>> %@", self.request.URL.absoluteString,
          [[NSString alloc] initWithData:self.request.HTTPBody encoding:NSUTF8StringEncoding]);

    [NSURLConnection sendAsynchronousRequest:self.request
                                       queue:queue
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               handler(self.request, response, data, connectionError);
                           }];
}

- (void)addValue:(NSString *)value forHeader:(NSString *)header
{
    [self.request addValue:value forHTTPHeaderField:header];
}

+ (NSString *)bodyStringWithParams:(NSDictionary *)postParams
{
    if (!postParams)
        return [NSString string];
    
    NSMutableArray *bodyParams = [NSMutableArray array];
    
    for (NSString *key in postParams.allKeys) {
        id value = postParams[key];
        NSString *paramValue = [value isKindOfClass:[NSNumber class]] ? [value stringValue] : value;
        
        NSString *encodedValue = [YMAConnection addPercentEscapesForString:paramValue];
        NSString *encodedKey = [YMAConnection addPercentEscapesForString:key];
        
        [bodyParams addObject:[NSString stringWithFormat:@"%@=%@", encodedKey, encodedValue]];
    }
    
    return [bodyParams componentsJoinedByString:@"&"];
}

@end
