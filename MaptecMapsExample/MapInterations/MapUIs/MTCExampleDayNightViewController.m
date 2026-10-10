//
//  MTCExampleDayNightViewController.m
//  MaptecMapsExample
//
//  Created by ZHOUPanpan on 2026/6/26.
//

#import "MTCExampleDayNightViewController.h"

#import "ExampleSettingsSheetView.h"
#import "MTCExampleMapBizUtil.h"
#import "MTCExampleMapTestSupport.h"
#import "MTCExampleTestAccessibility.h"

#import <MaptecMapsKit/MaptecMapsKit.h>

@interface MTCExampleDayNightViewController () <MTCMapViewDelegate>

@property (nonatomic, strong) MTCMapView *mapView;
@property (nonatomic, strong) MTCExampleMapTestSupport *mapTestSupport;
@property (nonatomic, assign) NSInteger positionIndex;

@end

@implementation MTCExampleDayNightViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = UIColor.whiteColor;
    self.view.accessibilityIdentifier = MTCExampleTestAccessibilityMapDayNightScreen;

    [self configureNavigationItems:NO];
    [self configureMapView];
    [self applyLocalizedTexts];
}

#pragma mark -- MTCMapViewDelegate

- (void)mapViewDidFinishLoadingMap:(MTCMapView *)mapView {
    (void)mapView;
    [self.mapTestSupport markMapRenderedReady];
    [self.mapTestSupport pauseMapRenderingIfUITesting:self.mapView];
}

- (void)mapView:(MTCMapView *)mapView didFinishSwitchingMapStyleWithID:(NSString *)mapStyleID {
    (void)mapView;
    (void)mapStyleID;
    [self.mapTestSupport markMapRenderedReady];
    [self.mapTestSupport pauseMapRenderingIfUITesting:self.mapView];
}

#pragma mark - Event

- (void)showDayNightSettings {
    ExampleSettingsSheetView *sheet =
        [[ExampleSettingsSheetView alloc] initWithTitle:[self localizedStringForKey:@"demo_title_MTCExampleDayNightViewController"]
                                               sections:[self dayNightSections]];
    [sheet showInView:self.view animated:NO];
}

#pragma mark - Private

- (void)configureMapView {
    self.mapView = [[MTCMapView alloc] initWithFrame:self.view.bounds];
    self.mapView.delegate = self;
    self.mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.mapView];

    self.mapTestSupport = [[MTCExampleMapTestSupport alloc] init];
    [self.mapTestSupport installOnHostView:self.view];

    [self.mapView setCenterCoordinate:CLLocationCoordinate2DMake(31.2304, 121.4737) zoomLevel:11.5];

    self.mapView.uiSettings.permitShowAll = YES;
    self.mapView.uiSettings.compassEnabled = NO;
    self.mapView.uiSettings.zoomButtonsEnabled = NO;
    self.mapView.uiSettings.scaleBarEnabled = NO;
    self.mapView.uiSettings.dayNightModeEnabled = YES;
    self.mapView.uiSettings.dayNightModeGravity = MTCUIPositionTop | MTCUIPositionLeft;
    self.mapView.uiSettings.dayNightModeMargins = UIEdgeInsetsMake(4.0, 4.0, 4.0, 4.0);

    self.positionIndex = [MTCExampleMapBizUtil MTCIndexForUIPosition:self.mapView.uiSettings.dayNightModeGravity];
}

- (NSArray<ExampleSettingsSection *> *)dayNightSections {
    __weak typeof(self) weakSelf = self;
    return @[
        [ExampleSettingsSection sectionWithTitle:[self localizedStringForKey:@"common_section_display"] items:@[
            [[ExampleSettingsItem boolItemWithTitle:[self localizedStringForKey:@"day_night_enable_control"]
                                             getter:^BOOL { return weakSelf.mapView.uiSettings.dayNightModeEnabled; }
                                             setter:^(BOOL value) {
                weakSelf.mapView.uiSettings.dayNightModeEnabled = value;
            }] withAccessibilityIdentifier:MTCExampleTestAccessibilitySwitchDayNightEnabled],
        ]],
        [ExampleSettingsSection sectionWithTitle:[self localizedStringForKey:@"common_section_layout"] items:@[
            [[ExampleSettingsItem listItemWithTitle:[self localizedStringForKey:@"day_night_gravity_label"]
                                            options:[self localizedUIPositionTitles]
                                          popupSize:CGSizeMake(260.0, 360.0)
                                             getter:^NSInteger { return weakSelf.positionIndex; }
                                             setter:^(NSInteger index) {
                weakSelf.positionIndex = index;
                weakSelf.mapView.uiSettings.dayNightModeGravity = [MTCExampleMapBizUtil MTCUIPositionForIndex:index];
            }] withAccessibilityIdentifier:MTCExampleTestAccessibilityDropdownDayNightGravity],
        ]],
    ];
}

#pragma mark -- multi-language

- (void)handleExampleSettingsAction {
    [self showDayNightSettings];
}

- (void)demoLanguageDidChange {
    [self applyLocalizedTexts];
}

- (void)applyLocalizedTexts {
    self.title = [self localizedStringForKey:@"demo_title_MTCExampleDayNightViewController"];
    if (self.mapView) {
        self.mapView.mapLanguage = [self mapLanguageForDemoLanguage:self.demoLanguage];
    }
    if ([self isSettingsSheetVisible:ExampleSettingsSheetView.class]) {
        [self showDayNightSettings];
    }
}
@end
