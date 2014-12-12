//
//  RWSearchFormViewController.m
//  TwitterInstant
//
//  Created by Colin Eberhardt on 02/12/2013.
//  Copyright (c) 2013 Colin Eberhardt. All rights reserved.
//

#import "RWSearchFormViewController.h"
#import "RWSearchResultsViewController.h"
#import <ReactiveCocoa.h>
#import "RACEXTScope.h"
@import Accounts;
@import Social;

typedef NS_ENUM(NSInteger, RWTwitterInstantError) {
    RWTwitterInstantErrorAccessDenied,
    RWTwitterInstantErrorNoTwitterAccounts,
    RWTwitterInstantErrorInvalidResponse
};

static NSString *const RWTwitterInstantDomain = @"TwitterInstant";

@interface RWSearchFormViewController ()

@property (weak, nonatomic) IBOutlet UITextField *searchText;

@property (strong, nonatomic) RWSearchResultsViewController *resultsViewController;

@property (strong, nonatomic) ACAccountStore *accountStore;
@property (strong, nonatomic) ACAccountType *twitterAccountType;

@end

@implementation RWSearchFormViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Twitter Instant";
    
    [self styleTextField:self.searchText];
    
    self.resultsViewController = self.splitViewController.viewControllers[1];

    // Use weak reference to avoid potential retain cycle
    // map isValid to a color
    // apply color to searchText background

//    Alternative solution- use map and subscribeNext
//    @weakify(self)
//    [[self.searchText.rac_textSignal
//      map:^id(NSString *text) {
//          return [self isValidSearchText:text] ?
//          [UIColor whiteColor] : [UIColor yellowColor];
//      }]
//     subscribeNext:^(UIColor *color) {
//         @strongify(self)
//         self.searchText.backgroundColor = color;
//     }];

    // create signal by mapping text to boxed boolean
    RACSignal *validSearchTextSignal = [self.searchText.rac_textSignal
                                        map:^id(NSString *text) {
                                            return @([self isValidSearchText:text]);
                                        }];

    // Use RAC macro to map validSearchTextSignal to searchText property backgroundColor
    RAC(self.searchText, backgroundColor) =
    [validSearchTextSignal
     map:^id(NSNumber *searchTextValid) {
         return [searchTextValid boolValue] ? [UIColor whiteColor] : [UIColor yellowColor];
     }];

    self.accountStore = [[ACAccountStore alloc] init];
    self.twitterAccountType = [self.accountStore
                               accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];

    [[self requestAccessToTwitterSignal]
     subscribeNext:^(id x) {
         NSLog(@"Access granted");
     } error:^(NSError *error) {
         NSLog(@"An error occurred: %@", error);
     }];
}

- (BOOL)isValidSearchText:(NSString *)text {
    return text.length > 2;
}

- (void)styleTextField:(UITextField *)textField {
  CALayer *textFieldLayer = textField.layer;
  textFieldLayer.borderColor = [UIColor grayColor].CGColor;
  textFieldLayer.borderWidth = 2.0f;
  textFieldLayer.cornerRadius = 0.0f;
}

- (RACSignal *)requestAccessToTwitterSignal {

    NSError *accessError = [NSError errorWithDomain:RWTwitterInstantDomain
                                               code:RWTwitterInstantErrorAccessDenied
                                           userInfo:nil];

    @weakify(self)
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        // request access to twitter
        @strongify(self)
        [self.accountStore
         requestAccessToAccountsWithType:self.twitterAccountType
         options:nil
         completion:^(BOOL granted, NSError *error) {
             // handle the response
             if (!granted) {
                 [subscriber sendError:accessError];
             } else {
                 [subscriber sendNext:nil];
                 [subscriber sendCompleted];
             }
         }];
        return nil;
    }];
}

@end
