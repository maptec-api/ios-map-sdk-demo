//
//  MTCAuthConfigViewController.m
//  MaptecMapsExample
//
//  Created by ZHOUPanpan on 2026/7/10.
//

#import "MTCAuthConfigViewController.h"

#import "MTCExampleTestAccessibility.h"
#import "MTCMapAddViewController.h"
#import "MTCMapRouteViewController.h"
#import "MTCWebAuthStatusViewController.h"
#import "MTCWebTextSearchViewController.h"

#import <Masonry/Masonry.h>

#if __has_include("MTCExampleBuildConfiguration.h")
#import "MTCExampleBuildConfiguration.h"
#else
#define MTC_EXAMPLE_USE_DEFAULT_API_KEY 0
#define MTC_EXAMPLE_DEFAULT_API_KEY @""
#endif

typedef NS_ENUM(NSInteger, MTCAuthConfigSection) {
    MTCAuthConfigSectionInput = 0,
    MTCAuthConfigSectionVerify,
};

typedef NS_ENUM(NSInteger, MTCAuthConfigInputRow) {
    MTCAuthConfigInputRowAPIKey = 0,
    MTCAuthConfigInputRowSignatureSHA1,
    MTCAuthConfigInputRowAuth,
};

typedef NS_ENUM(NSInteger, MTCAuthConfigVerifyRow) {
    MTCAuthConfigVerifyRowMap = 0,
    MTCAuthConfigVerifyRowSearch,
    MTCAuthConfigVerifyRowRoute,
    MTCAuthConfigVerifyRowWebAuthStatus,
};

@interface MTCAuthConfigViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UITextField *apiKeyTextField;
@property (nonatomic, strong) UITextField *signatureSHA1TextField;
@property (nonatomic, strong) UIButton *authButton;
@property (nonatomic, strong) UILabel *authTipLabel;

@end

@implementation MTCAuthConfigViewController

- (void)dealloc {
}
#pragma mark - Public

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureNavigationItems:YES];
    self.view.backgroundColor = UIColor.systemGroupedBackgroundColor;
    self.view.accessibilityIdentifier = MTCExampleTestAccessibilityAuthConfigScreen;
    [self configureSubviews];
    [self applyLocalizedTexts];
}

#pragma mark - Protocol

#pragma mark -- UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    (void)tableView;
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    (void)tableView;
    if (section == MTCAuthConfigSectionInput) {
        return 3;
    }
    return 4;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    (void)tableView;
    if (section == MTCAuthConfigSectionInput) {
        return [self localizedStringForKey:@"auth_config_section_input"];
    }
    return [self localizedStringForKey:@"auth_config_section_verify"];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == MTCAuthConfigSectionInput) {
        return [self tableView:tableView inputCellForRow:indexPath.row];
    }
    return [self tableView:tableView verifyCellForRow:indexPath.row];
}

#pragma mark - Delegate

#pragma mark -- UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == MTCAuthConfigSectionInput && indexPath.row == MTCAuthConfigInputRowAuth) {
        return UITableViewAutomaticDimension;
    }
    return 54.0;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    (void)tableView;
    if (indexPath.section == MTCAuthConfigSectionInput && indexPath.row == MTCAuthConfigInputRowAuth) {
        return 100.0;
    }
    return 54.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.section != MTCAuthConfigSectionVerify) {
        return;
    }

    switch (indexPath.row) {
        case MTCAuthConfigVerifyRowMap: {
            [self pushViewControllerClass:MTCMapAddViewController.class];
        }
        break;
        case MTCAuthConfigVerifyRowSearch: {
            [self pushViewControllerClass:MTCWebTextSearchViewController.class];
        }
        break;
        case MTCAuthConfigVerifyRowRoute: {
            [self pushViewControllerClass:MTCMapRouteViewController.class];
        }
        break;
        case MTCAuthConfigVerifyRowWebAuthStatus: {
            [self pushViewControllerClass:MTCWebAuthStatusViewController.class];
        }
        break;
        default: {
        }
        break;
    }
}

#pragma mark - Event

- (void)authButtonDidClick {
    NSString *apiKey = [self.apiKeyTextField.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (apiKey.length == 0) {
        [self presentMessage:[self localizedStringForKey:@"auth_config_alert_enter_api_key"]
                       title:[self localizedStringForKey:@"auth_config_alert_title_notice"]];
        return;
    }

    NSString *signatureSHA1 = [self.signatureSHA1TextField.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    MTCMapServices.sharedServices.apiKey = apiKey;
    MTCMapServices.sharedServices.signatureSHA1 = signatureSHA1.length > 0 ? signatureSHA1 : nil;
    [self.view endEditing:YES];
    [self presentMessage:[self localizedStringForKey:@"auth_config_alert_auth_success_message"]
                   title:[self localizedStringForKey:@"auth_config_alert_auth_success_title"]];
}

#pragma mark - Private

- (void)configureSubviews {
    [self.view addSubview:self.tableView];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
}

- (UITableViewCell *)tableView:(UITableView *)tableView inputCellForRow:(NSInteger)row {
    if (row == MTCAuthConfigInputRowAuth) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MTCAuthConfigButtonCell"];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"MTCAuthConfigButtonCell"];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            [cell.contentView addSubview:self.authButton];
            [cell.contentView addSubview:self.authTipLabel];

            [self.authButton mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(cell.contentView).offset(12.0);
                make.leading.equalTo(cell.contentView).offset(16.0);
                make.trailing.equalTo(cell.contentView).offset(-16.0);
                make.height.mas_equalTo(40.0);
            }];
            [self.authTipLabel mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(self.authButton.mas_bottom).offset(8.0);
                make.leading.equalTo(self.authButton);
                make.trailing.equalTo(self.authButton);
                make.bottom.equalTo(cell.contentView).offset(-12.0);
            }];
        }
        return cell;
    }

    NSString *reuseIdentifier = row == MTCAuthConfigInputRowAPIKey ? @"MTCAuthConfigAPIKeyCell" : @"MTCAuthConfigSignatureSHA1Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }

    UITextField *textField = row == MTCAuthConfigInputRowAPIKey ? self.apiKeyTextField : self.signatureSHA1TextField;
    if (!textField.superview) {
        [cell.contentView addSubview:textField];
        [textField mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(cell.contentView);
            make.leading.equalTo(cell.contentView).offset(16.0);
            make.trailing.equalTo(cell.contentView).offset(-16.0);
            make.bottom.equalTo(cell.contentView);
        }];
    }
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView verifyCellForRow:(NSInteger)row {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MTCAuthConfigVerifyCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"MTCAuthConfigVerifyCell"];
        cell.textLabel.font = [UIFont systemFontOfSize:16.0];
    }

    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    cell.textLabel.text = [self verifyTitleForRow:row];
    if (row == MTCAuthConfigVerifyRowMap) {
        cell.accessibilityIdentifier = MTCExampleTestAccessibilityMapAddScreen;
    } else if (row == MTCAuthConfigVerifyRowWebAuthStatus) {
        cell.accessibilityIdentifier = MTCExampleTestAccessibilityWebAuthStatusScreen;
    }
    return cell;
}

- (NSString *)verifyTitleForRow:(NSInteger)row {
    switch (row) {
        case MTCAuthConfigVerifyRowMap: {
            return [self localizedStringForKey:@"auth_config_verify_map"];
        }
        case MTCAuthConfigVerifyRowSearch: {
            return [self localizedStringForKey:@"auth_config_verify_search"];
        }
        case MTCAuthConfigVerifyRowRoute: {
            return [self localizedStringForKey:@"auth_config_verify_route"];
        }
        case MTCAuthConfigVerifyRowWebAuthStatus: {
            return [self localizedStringForKey:@"auth_config_verify_web_auth_status"];
        }
        default: {
            return @"";
        }
    }
}

- (void)pushViewControllerClass:(Class)viewControllerClass {
    if (![viewControllerClass isSubclassOfClass:UIViewController.class]) {
        return;
    }

    UIViewController *viewController = [[viewControllerClass alloc] init];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)presentMessage:(NSString *)message title:(NSString *)title {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:[self localizedStringForKey:@"common_ok"] style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark -- multi-language

- (void)demoLanguageDidChange {
    [self applyLocalizedTexts];
}

- (void)applyLocalizedTexts {
    self.title = [self localizedStringForKey:@"demo_title_MTCAuthConfigViewController"];
    self.apiKeyTextField.placeholder = [self localizedStringForKey:@"auth_config_api_key_placeholder"];
    self.signatureSHA1TextField.placeholder = [self localizedStringForKey:@"auth_config_signature_sha1_placeholder"];
    [self.authButton setTitle:[self localizedStringForKey:@"auth_config_auth_button"] forState:UIControlStateNormal];
    self.authTipLabel.text = [self localizedStringForKey:@"auth_config_auth_tip"];
    [self.tableView reloadData];
}

#pragma mark - Getter & Setter

- (UITableView *)tableView {
    if (_tableView) {
        return _tableView;
    }

    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    return _tableView;
}

- (UITextField *)apiKeyTextField {
    if (_apiKeyTextField) {
        return _apiKeyTextField;
    }

    _apiKeyTextField = [[UITextField alloc] init];
    if (MTC_EXAMPLE_USE_DEFAULT_API_KEY) {
        _apiKeyTextField.text = MTC_EXAMPLE_DEFAULT_API_KEY;
    }
    _apiKeyTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    _apiKeyTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    _apiKeyTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _apiKeyTextField.returnKeyType = UIReturnKeyDone;
    _apiKeyTextField.accessibilityIdentifier = MTCExampleTestAccessibilityInputApiKey;
    return _apiKeyTextField;
}

- (UITextField *)signatureSHA1TextField {
    if (_signatureSHA1TextField) {
        return _signatureSHA1TextField;
    }

    _signatureSHA1TextField = [[UITextField alloc] init];
    _signatureSHA1TextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    _signatureSHA1TextField.autocorrectionType = UITextAutocorrectionTypeNo;
    _signatureSHA1TextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _signatureSHA1TextField.returnKeyType = UIReturnKeyDone;
    _signatureSHA1TextField.accessibilityIdentifier = MTCExampleTestAccessibilityInputSignatureSha1;
    return _signatureSHA1TextField;
}

- (UIButton *)authButton {
    if (_authButton) {
        return _authButton;
    }

    _authButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _authButton.backgroundColor = UIColor.systemBlueColor;
    [_authButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    _authButton.titleLabel.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightSemibold];
    _authButton.layer.cornerRadius = 8.0;
    _authButton.layer.masksToBounds = YES;
    _authButton.accessibilityIdentifier = MTCExampleTestAccessibilityBtnAuthConfirm;
    [_authButton addTarget:self action:@selector(authButtonDidClick) forControlEvents:UIControlEventTouchUpInside];
    return _authButton;
}

- (UILabel *)authTipLabel {
    if (_authTipLabel) {
        return _authTipLabel;
    }

    _authTipLabel = [[UILabel alloc] init];
    _authTipLabel.textColor = UIColor.secondaryLabelColor;
    _authTipLabel.font = [UIFont systemFontOfSize:12.0];
    _authTipLabel.numberOfLines = 0;
    _authTipLabel.lineBreakMode = NSLineBreakByWordWrapping;
    [_authTipLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    return _authTipLabel;
}

@end
