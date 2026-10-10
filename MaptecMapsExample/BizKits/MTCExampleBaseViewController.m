//
//  MTCExampleBaseViewController.m
//  MaptecMapsExample
//
//  Created by ZHOUPanpan on 2026/8/3.
//

#import "MTCExampleBaseViewController.h"

#import "MTCExampleLanguageToggleControl.h"
#import "MTCExampleTestAccessibility.h"

@interface MTCExampleBaseViewController ()

@property (nonatomic, strong) MTCExampleLanguageToggleControl *languageToggleControl;

@end

@implementation MTCExampleBaseViewController

#pragma mark - Public

- (NSString *)localizedStringForKey:(NSString *)key {
    return [MTCExampleDemoLocalization stringForKey:key language:self.demoLanguage];
}

- (void)handleExampleSettingsAction {
}

- (void)demoLanguageDidChange {
}

#pragma mark - Life Cycle

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:MTCExampleDemoLanguageDidChangeNotification
                                                  object:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.demoLanguage = [MTCExampleDemoLocalization currentLanguage];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleDemoLanguageDidChangeNotification:)
                                                 name:MTCExampleDemoLanguageDidChangeNotification
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self syncDemoLanguageFromGlobalIfNeeded];
}

#pragma mark - Event

- (void)handleLanguageToggle {
    MTCExampleDemoLanguage nextLanguage =
        [MTCExampleDemoLocalization toggledLanguage:[MTCExampleDemoLocalization currentLanguage]];
    [MTCExampleDemoLocalization setCurrentLanguage:nextLanguage];
}

- (void)handleDemoLanguageDidChangeNotification:(NSNotification *)notification {
    [self syncDemoLanguageFromGlobalIfNeeded];
}

#pragma mark - Private

- (void)syncDemoLanguageFromGlobalIfNeeded {
    MTCExampleDemoLanguage language = [MTCExampleDemoLocalization currentLanguage];
    if (self.demoLanguage == language) {
        self.languageToggleControl.selectedLanguage = language;
        return;
    }

    self.demoLanguage = language;
    self.languageToggleControl.selectedLanguage = language;
    [self demoLanguageDidChange];
}

@end

@implementation MTCExampleBaseViewController (NavigationItems)

#pragma mark - Public

- (void)configureNavigationItems:(BOOL)onlyLan {
    self.languageToggleControl = [[MTCExampleLanguageToggleControl alloc] initWithFrame:CGRectZero];
    self.languageToggleControl.selectedLanguage = self.demoLanguage;
    [self.languageToggleControl addTarget:self
                                   action:@selector(handleLanguageToggle)
                         forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *languageItem = [[UIBarButtonItem alloc] initWithCustomView:self.languageToggleControl];

    if (onlyLan) {
        self.navigationItem.rightBarButtonItems = @[ languageItem ];
        return;
    }

    UIImage *settingsImage = [UIImage systemImageNamed:@"gearshape"];
    UIBarButtonItem *settingsItem = nil;
    if (settingsImage) {
        settingsItem = [[UIBarButtonItem alloc] initWithImage:settingsImage
                                                        style:UIBarButtonItemStylePlain
                                                       target:self
                                                       action:@selector(handleExampleSettingsAction)];
    } else {
        settingsItem = [[UIBarButtonItem alloc] initWithTitle:[self localizedStringForKey:@"settings"]
                                                        style:UIBarButtonItemStylePlain
                                                       target:self
                                                       action:@selector(handleExampleSettingsAction)];
    }

    settingsItem.accessibilityIdentifier = MTCExampleTestAccessibilitySettingsButton;

    // rightBarButtonItems 从右到左排布：语言按钮在设置按钮右侧。
    self.navigationItem.rightBarButtonItems = @[ languageItem, settingsItem ];
}

- (MTCMapLanguage)mapLanguageForDemoLanguage:(MTCExampleDemoLanguage)language {
    return language == MTCExampleDemoLanguageEnglish
        ? MTCMapLanguageEnglish
        : MTCMapLanguageChinese;
}

- (BOOL)isSettingsSheetVisible:(Class)settingClass {
    for (UIView *subview in self.view.subviews) {
        if ([subview isKindOfClass:settingClass]) {
            return YES;
        }
    }
    return NO;
}

- (NSArray<NSString *> *)localizedUIPositionTitles {
    return @[
        [self localizedStringForKey:@"zoom_gravity_top_end"],
        [self localizedStringForKey:@"zoom_gravity_top_start"],
        [self localizedStringForKey:@"zoom_gravity_top_center"],
        [self localizedStringForKey:@"zoom_gravity_middle_start"],
        [self localizedStringForKey:@"zoom_gravity_center"],
        [self localizedStringForKey:@"zoom_gravity_middle_end"],
        [self localizedStringForKey:@"zoom_gravity_bottom_end"],
        [self localizedStringForKey:@"zoom_gravity_bottom_start"],
        [self localizedStringForKey:@"zoom_gravity_bottom_center"],
    ];
}

@end
