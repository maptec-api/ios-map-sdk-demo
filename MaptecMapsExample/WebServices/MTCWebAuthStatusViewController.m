//
//  MTCWebAuthStatusViewController.m
//  MaptecMapsExample
//
//  Created by ZHOUPanpan+ on 2026/7/23.
//  Copyright © 2026 ZHOUPanpan+. All rights reserved.
//

#import "MTCWebAuthStatusViewController.h"

#import "MTCMTCWebDetailPopupView.h"
#import "MTCExampleTestAccessibility.h"
#import "MTCWebSettingsFloatView.h"
#import "MTCWebSupportUtil.h"

#import <MaptecMapsKit/MaptecMapsKit.h>

@interface MTCWebAuthStatusViewController ()

@property (nonatomic, strong) MTCWebSettingsFloatView *floatView;
@property (nonatomic, strong, nullable) MTCMTCWebDetailPopupView *popupView;
@property (nonatomic, assign) BOOL loading;
@property (nonatomic, assign) MTCWebPopupPurpose activePopupPurpose;

@property (nonatomic, strong, nullable) MTCAuthStatusResponse *response;
@property (nonatomic, copy, nullable) NSString *errorMessage;

@end

@implementation MTCWebAuthStatusViewController

- (void)dealloc {
    self.popupView = nil;
}

#pragma mark - Public

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureNavigationItems:YES];
    self.view.backgroundColor = UIColor.systemGroupedBackgroundColor;
    self.view.accessibilityIdentifier = MTCExampleTestAccessibilityWebAuthStatusScreen;
    self.loading = NO;
    self.activePopupPurpose = MTCWebPopupPurposeNone;
    [self configureFloatView];
    [self applyLocalizedTexts];
}

#pragma mark - Protocol

#pragma mark - Delegate

#pragma mark - Event

- (void)submitRequest {
    if (self.loading) {
        return;
    }

    [self dismissPopupWithoutSelectionMutation];
    self.loading = YES;
    self.response = nil;
    self.errorMessage = nil;
    [self.floatView updateSections:[self buildSections]];

    __weak typeof(self) weakSelf = self;
    [[MTCSearchService sharedService] fetchAuthStatusWithCompletion:^(MTCAuthStatusResponse * _Nullable response, NSError * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        strongSelf.loading = NO;
        strongSelf.response = response;
        strongSelf.errorMessage = error.localizedDescription;
        [strongSelf.floatView updateSections:[strongSelf buildSections]];
    }];
}

#pragma mark - Private

- (void)configureFloatView {
    self.floatView = [[MTCWebSettingsFloatView alloc] initWithTitle:self.title sections:[self buildSections]];
    self.floatView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.floatView];
    [NSLayoutConstraint activateConstraints:@[
        [self.floatView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.floatView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.floatView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.floatView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];
}

- (NSArray<MTCWebSettingsSection *> *)buildSections {
    __weak typeof(self) weakSelf = self;
    NSMutableArray<MTCWebSettingsSection *> *sections = [NSMutableArray array];

    [sections addObject:[MTCWebSettingsSection sectionWithTitle:[self localizedStringForKey:@"overlay_actions"]
                                                          items:@[
        [[MTCWebSettingsItem actionItemWithTitle:self.loading ? [self localizedStringForKey:@"web_requesting"] : [self localizedStringForKey:@"web_send_request"]
                                           style:MTCWebSettingsActionStylePrimary
                                         handler:^{ [weakSelf submitRequest]; }]
         enabledWhen:^BOOL{ return weakSelf.loading == NO; }],
    ]]];

    if (self.errorMessage.length > 0) {
        [sections addObject:[MTCWebSettingsSection sectionWithTitle:[self localizedStringForKey:@"web_error"]
                                                              items:@[
            [MTCWebSettingsItem infoItemWithTitle:@"message" value:^NSString *{ return weakSelf.errorMessage ?: @""; }],
        ]]];
    }

    if (self.response) {
        [sections addObject:[MTCWebSettingsSection sectionWithTitle:[self localizedStringForKey:@"web_response_json"]
                                                              items:@[
            [MTCWebSettingsItem selectableInfoItemWithTitle:@"raw"
                                                     detail:[self localizedStringForKey:@"web_tap_to_view_full_response_json"]
                                                      value:^NSString *{
                return @"";
            }
                                                   selected:nil
                                                    handler:^{
                [weakSelf presentPopupWithTitle:[self localizedStringForKey:@"web_response_json"]
                                            text:[MTCWebSupportUtil mtc_prettyJSONStringFromDictionary:weakSelf.response.rawDictionary ?: @{}]
                                         purpose:MTCWebPopupPurposeResponseRaw];
            }],
        ]]];
    }

    return sections;
}

- (void)presentPopupWithTitle:(NSString *)title text:(NSString *)text purpose:(MTCWebPopupPurpose)purpose {
    [self dismissPopupWithoutSelectionMutation];
    self.activePopupPurpose = purpose;

    MTCMTCWebDetailPopupView *popupView = [[MTCMTCWebDetailPopupView alloc] initWithFrame:CGRectZero];
    self.popupView = popupView;

    __weak typeof(self) weakSelf = self;
    [popupView presentInView:self.view title:title text:text dismissHandler:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        strongSelf.popupView = nil;
        strongSelf.activePopupPurpose = MTCWebPopupPurposeNone;
        [strongSelf.floatView reloadData];
    }];
}

- (void)dismissPopupWithoutSelectionMutation {
    if (!self.popupView) {
        return;
    }
    dispatch_block_t dismissHandler = self.popupView.dismissHandler;
    self.popupView.dismissHandler = nil;
    [self.popupView removeFromSuperview];
    self.popupView = nil;
    if (dismissHandler) {
        dismissHandler();
    }
}

#pragma mark -- multi-language

- (void)demoLanguageDidChange {
    [self applyLocalizedTexts];
}

- (void)applyLocalizedTexts {
    self.title = [self localizedStringForKey:@"demo_title_MTCWebAuthStatusViewController"];
    if (self.floatView) {
        [self.floatView updateTitle:self.title];
        [self.floatView updateSections:[self buildSections]];
    }
}

#pragma mark - Getter & Setter

@end
