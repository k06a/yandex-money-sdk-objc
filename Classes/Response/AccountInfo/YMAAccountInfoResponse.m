//
// Created by Alexander Mertvetsov on 22.05.14.
// Copyright (c) 2014 Yandex.Money. All rights reserved.
//

#import "YMAAccountInfoResponse.h"
#import "YMAMoneySourceModel.h"
#import "YMAConstants.h"

static NSString *const kParameterError = @"error";

static NSString *const kParameterAccount = @"account";
static NSString *const kParameterBalance = @"balance";
static NSString *const kParameterCurrency = @"currency";
static NSString *const kParameterAccountStatus = @"account_status";
static NSString *const kParameterAccountType = @"account_type";

static NSString *const kParameterAvatar = @"avatar";
static NSString *const kParameterAvatarUrl = @"url";
static NSString *const kParameterAvatarTs = @"ts";

static NSString *const kParameterBalanceDetails = @"balance_details";
static NSString *const kParameterBalanceTotal = @"total";
static NSString *const kParameterBalanceAvailable = @"available";
static NSString *const kParameterBalanceDepositionPending = @"deposition_pending";
static NSString *const kParameterBalanceBlocked = @"blocked";
static NSString *const kParameterBalanceDebt = @"debt";
static NSString *const kParameterBalanceHold = @"hold";

static NSString *const kParameterCardsLinked = @"cards_linked";
static NSString *const kParameterCardsLinkedPanFragment = @"pan_fragment";
static NSString *const kParameterCardsLinkedType = @"type";

static NSString *const kParameterServicesAdditional = @"services_additional";

@implementation YMAAccountInfoResponse

#pragma mark - Overridden methods

- (BOOL)parseJSONModel:(id)responseModel headers:(NSDictionary *)headers error:(NSError * __autoreleasing *)error
{
    NSString *errorKey = responseModel[kParameterError];
    
    if (errorKey != nil) {
        if (error == nil) return NO;
        
        NSError *unknownError = [NSError errorWithDomain:YMAErrorDomainUnknown code:0 userInfo:@{ YMAErrorKeyResponse : self }];
        *error = errorKey ? [NSError errorWithDomain:YMAErrorDomainYaMoneyAPI code:0 userInfo:@{YMAErrorKey : errorKey, YMAErrorKeyResponse : self }] : unknownError;
        
        return NO;
    }
    
    NSString *account = responseModel[kParameterAccount];
    NSString *balance = [responseModel[kParameterBalance] stringValue];
    NSString *currency = responseModel[kParameterCurrency];
    
    NSString *accountStatusString = responseModel[kParameterAccountStatus];
    YMAAccountStatus accountStatus = [YMAAccountInfoModel accountStatusByString:accountStatusString];
    
    NSString *accountTypeString = responseModel[kParameterAccountType];
    YMAAccountType accountType = [YMAAccountInfoModel accountTypeByString:accountTypeString];
    
    id avatarModel = responseModel[kParameterAvatar];
    YMAAvatarModel *avatar = nil;
    
    if (avatarModel != nil) {
        NSString *avatarUrlString = avatarModel[kParameterAvatarUrl];
        NSURL *avatarUrl = [NSURL URLWithString:avatarUrlString];
        NSString *timeStampString = avatarModel[kParameterAvatarTs];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"];
        NSDate *timeStamp = [formatter dateFromString:timeStampString];
        avatar = [YMAAvatarModel avatarWithUrl:avatarUrl timeStamp:timeStamp];
    }
    
    id balanceDetailsModel = responseModel[kParameterBalanceDetails];
    YMABalanceDetailsModel *balanceDetails = nil;
    
    if (balanceDetailsModel != nil) {
        NSString *total = [balanceDetailsModel[kParameterBalanceTotal] stringValue];
        NSString *available = [balanceDetailsModel[kParameterBalanceAvailable] stringValue];
        NSString *depositionPending = [balanceDetailsModel[kParameterBalanceDepositionPending] stringValue];
        NSString *blocked = [balanceDetailsModel[kParameterBalanceBlocked] stringValue];
        NSString *debt = [balanceDetailsModel[kParameterBalanceDebt] stringValue];
        NSString *hold = [balanceDetailsModel[kParameterBalanceHold] stringValue];
        
        balanceDetails = [YMABalanceDetailsModel balanceDetailsWithTotal:total
                                                               available:available
                                                       depositionPending:depositionPending
                                                                 blocked:blocked
                                                                    debt:debt
                                                                    hold:hold];
    }
    
    id cardsLinkedModel = responseModel[kParameterCardsLinked];
    NSMutableArray *cardsLinked = nil;
    
    if (cardsLinkedModel != nil) {
        cardsLinked = [NSMutableArray array];
        
        for (id card in cardsLinkedModel) {
            NSString *panFragment = card[kParameterCardsLinkedPanFragment];
            NSString *cardTypeString = card[kParameterCardsLinkedType];
            YMAPaymentCardType cardType = [YMAMoneySourceModel paymentCardTypeByString:cardTypeString];
            [cardsLinked addObject:[YMAMoneySourceModel moneySourceWithType:YMAMoneySourcePaymentCard
                                                                   cardType:cardType
                                                                panFragment:panFragment
                                                           moneySourceToken:nil]];
        }
    }
    
    id servicesAdditionalModel = responseModel[kParameterServicesAdditional];
    NSMutableArray *servicesAdditional = nil;
    
    if (servicesAdditionalModel != nil) {
        servicesAdditional = [NSMutableArray array];
        
        for (NSString *service in servicesAdditionalModel)
            [servicesAdditional addObject:service];
    }
    
    _accountInfo = [YMAAccountInfoModel accountInfoWithAccount:account
                                                       balance:balance
                                                      currency:currency
                                                 accountStatus:accountStatus
                                                   accountType:accountType
                                                        avatar:avatar
                                                balanceDetails:balanceDetails
                                                   cardsLinked:cardsLinked
                                            servicesAdditional:servicesAdditional];
    
    return YES;
}

@end