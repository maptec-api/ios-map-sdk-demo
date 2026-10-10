//
//  MTCMapAddViewController.m
//  MaptecMapsExample
//
//  Created by ZHOUPanpan on 2026/7/10.
//

#import "MTCMapAddViewController.h"

#import <MaptecMapsKit/MaptecMapsKit.h>

#import "ExampleSettingsSheetView.h"
#import "MTCExampleMapTestSupport.h"
#import "MTCExampleTestAccessibility.h"

static CLLocationDegrees const MTCMapAddInitialLatitude = 1.3521;
static CLLocationDegrees const MTCMapAddInitialLongitude = 103.8198;
static double const MTCMapAddInitialZoomLevel = 11.5;

@interface MTCMapAddViewController () <MTCMapViewDelegate>

@property (nonatomic, strong) MTCMapView *mapView;
@property (nonatomic, weak) ExampleSettingsSheetView *settingsSheet;
@property (nonatomic) MTCMapLanguage selectedMapLanguage;
@property (nonatomic, strong) MTCExampleMapTestSupport *mapTestSupport;

@end

@implementation MTCMapAddViewController

#pragma mark - Public

#pragma mark - Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureNavigationItems:NO];
    self.view.backgroundColor = UIColor.systemGroupedBackgroundColor;
    self.view.accessibilityIdentifier = MTCExampleTestAccessibilityMapAddScreen;
    self.mapTestSupport = [[MTCExampleMapTestSupport alloc] init];
    [self.mapTestSupport installOnHostView:self.view];
    self.selectedMapLanguage = MTCMapLanguageChinese;
    [self configureMapView];
    [self applyLocalizedTexts];
}

//- (void)viewDidAppear:(BOOL)animated {
//    [super viewDidAppear:animated];
//    [self.mapView setMapType:MTCMapTypeNight];
//}

#pragma mark - protocol

#pragma mark - Delegate

#pragma mark -- MTCMapViewDelegate

- (void)mapView:(MTCMapView *)mapView didLoadMapStyleWithID:(NSString *)mapStyleID {
    (void)mapView;
    (void)mapStyleID;
    [self.mapTestSupport markMapRenderedReady];
    [self.mapTestSupport pauseMapRenderingIfUITesting:self.mapView];
}

- (void)mapView:(MTCMapView *)mapView didFinishSwitchingMapStyleWithID:(NSString *)mapStyleID {
    (void)mapView;
    (void)mapStyleID;
    [self.mapTestSupport markMapRenderedReady];
    [self.mapTestSupport pauseMapRenderingIfUITesting:self.mapView];
}

- (void)mapViewDidFinishLoadingMap:(MTCMapView *)mapView {
    (void)mapView;
    [self.mapTestSupport markMapRenderedReady];
    [self.mapTestSupport pauseMapRenderingIfUITesting:self.mapView];
}

#pragma mark - Event

- (void)showSettings {
    ExampleSettingsSheetView *sheet =
        [[ExampleSettingsSheetView alloc] initWithTitle:[self localizedStringForKey:@"common_settings_sheet_title"]
                                               sections:[self settingsSections]];
    self.settingsSheet = sheet;
    [sheet showInView:self.view animated:YES];
}

#pragma mark - Private

- (void)configureMapView {
    self.mapView = [[MTCMapView alloc] initWithFrame:CGRectZero];
    self.mapView.translatesAutoresizingMaskIntoConstraints = NO;

//    self.mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.mapView.delegate = self;
    self.mapView.mapLanguage = self.selectedMapLanguage;
    [self.mapView setCenterCoordinate:CLLocationCoordinate2DMake(MTCMapAddInitialLatitude, MTCMapAddInitialLongitude)
                            zoomLevel:MTCMapAddInitialZoomLevel];
//    [self.mapView setMapType:MTCMapTypeStandard];
    [self.view addSubview:self.mapView];
    [NSLayoutConstraint activateConstraints:@[
        [self.mapView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.mapView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.mapView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.mapView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];

    
}

- (NSArray<ExampleSettingsSection *> *)settingsSections {
    __weak typeof(self) weakSelf = self;
    ExampleSettingsItem *descriptionItem =
        [ExampleSettingsItem infoItemWithText:[self localizedStringForKey:@"map_add_language_desc"]];
    ExampleSettingsItem *languageItem =
        [ExampleSettingsItem listItemWithTitle:[self localizedStringForKey:@"map_add_section_label_language"]
                                       options:[self languageOptionTitles]
                                     popupSize:CGSizeMake(0.0, 280.0)
                                        getter:^NSInteger{
        __strong typeof(weakSelf) self = weakSelf;
        return [self indexForMapLanguage:self.selectedMapLanguage];
    } setter:^(NSInteger index) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }
        self.selectedMapLanguage = [self mapLanguageForIndex:index];
        self.mapView.mapLanguage = self.selectedMapLanguage;
    }];
    return @[
        [ExampleSettingsSection sectionWithTitle:[self localizedStringForKey:@"map_add_section_label_language"]
                                           items:@[descriptionItem, languageItem]],
    ];
}

- (NSArray<NSString *> *)languageOptionTitles {
    return @[
        [self localizedStringForKey:@"map_add_lang_default"],
        [self localizedStringForKey:@"map_add_lang_en"],
        [self localizedStringForKey:@"map_add_lang_zh"],
        [self localizedStringForKey:@"map_add_lang_ms"],
        [self localizedStringForKey:@"map_add_lang_th"],
        [self localizedStringForKey:@"map_add_lang_ar"],
    ];
}

- (NSArray<NSNumber *> *)languageOptionValues {
    return @[
        @(MTCMapLanguageDefault),
        @(MTCMapLanguageEnglish),
        @(MTCMapLanguageChinese),
        @(MTCMapLanguageMalay),
        @(MTCMapLanguageThai),
        @(MTCMapLanguageArabic),
    ];
}

- (NSInteger)indexForMapLanguage:(MTCMapLanguage)language {
    NSArray<NSNumber *> *values = [self languageOptionValues];
    NSUInteger index = [values indexOfObject:@(language)];
    return index == NSNotFound ? 0 : (NSInteger)index;
}

- (MTCMapLanguage)mapLanguageForIndex:(NSInteger)index {
    NSArray<NSNumber *> *values = [self languageOptionValues];
    if (index < 0 || index >= (NSInteger)values.count) {
        return MTCMapLanguageDefault;
    }
    return (MTCMapLanguage)values[(NSUInteger)index].integerValue;
}

#pragma mark -- multi-language

- (void)handleExampleSettingsAction {
    [self showSettings];
}

- (void)demoLanguageDidChange {
    [self applyLocalizedTexts];
}

- (void)applyLocalizedTexts {
    self.title = [self localizedStringForKey:@"demo_title_MTCMapAddViewController"];
    self.selectedMapLanguage = [self mapLanguageForDemoLanguage:self.demoLanguage];
    if (self.mapView) {
        self.mapView.mapLanguage = self.selectedMapLanguage;
    }
    if ([self isSettingsSheetVisible:ExampleSettingsSheetView.class]) {
        [self showSettings];
    }
}

#pragma mark - Getter & Setter

@end
