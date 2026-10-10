//
//  MTCRouteConditionViewController.m
//  MaptecMapsExample
//
//  Created by ZHOUPanpan on 2026/8/20.
//

#import "MTCRouteConditionViewController.h"

#import "ExampleSettingsSheetView.h"
#import "MTCExampleMapTestSupport.h"
#import "MTCExampleTestAccessibility.h"
#import "MTCExampleToastView.h"

#import <MaptecMapsKit/MaptecMapsKit.h>

static CLLocationDegrees const MTCRouteConditionInitialLatitude = 1.360879;
static CLLocationDegrees const MTCRouteConditionInitialLongitude = 103.732578;
static double const MTCRouteConditionInitialZoomLevel = 13.0;

@interface MTCRouteConditionViewController () <MTCMapViewDelegate>

@property (nonatomic, strong) MTCMapView *mapView;
@property (nonatomic, strong) MTCExampleMapTestSupport *mapTestSupport;
@property (nonatomic, weak) ExampleSettingsSheetView *settingsSheet;
@property (nonatomic) MTCMapType currentMapType;
@property (nonatomic) MTCMapType pendingMapType;
@property (nonatomic) BOOL hasCurrentMapType;
@property (nonatomic) BOOL hasPendingMapType;
@property (nonatomic, getter=isTrafficEnabled) BOOL trafficEnabled;
@property (nonatomic) NSInteger selectedMapStyleIndex;

@end

@implementation MTCRouteConditionViewController

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = UIColor.whiteColor;
    self.view.accessibilityIdentifier = MTCExampleTestAccessibilityMapTrafficScreen;

    [self configureNavigationItems:NO];
    [self configureMapView];
    [self applyLocalizedTexts];
}

#pragma mark - Delegate

#pragma mark -- MTCMapViewDelegate

- (void)mapView:(MTCMapView *)mapView willStartLoadingMapStyleWithID:(NSString *)mapStyleID {
    (void)mapView;
    (void)mapStyleID;
    [self.mapTestSupport clearMapRenderedReady];
    [self.mapTestSupport pauseMapRenderingIfUITesting:self.mapView];
}

- (void)mapView:(MTCMapView *)mapView didLoadMapStyleWithID:(NSString *)mapStyleID {
    dispatch_async(dispatch_get_main_queue(), ^{
        (void)mapView;
        (void)mapStyleID;
        [self.mapTestSupport markMapRenderedReady];
        [self.mapTestSupport pauseMapRenderingIfUITesting:self.mapView];
    });
}

- (void)mapView:(MTCMapView *)mapView didFinishSwitchingMapStyleWithID:(NSString *)mapStyleID {
    (void)mapView;
    (void)mapStyleID;
    if (self.hasPendingMapType) {
        self.currentMapType = self.pendingMapType;
        self.hasCurrentMapType = YES;
        self.hasPendingMapType = NO;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.mapTestSupport markMapRenderedReady];
        [self.mapTestSupport pauseMapRenderingIfUITesting:self.mapView];
        [self refreshSettingsSheetIfVisible];
    });
}

- (void)mapView:(MTCMapView *)mapView didFailLoadingMapStyleWithID:(NSString *)mapStyleID message:(NSString *)message {
    (void)mapView;
    self.hasPendingMapType = NO;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self refreshSettingsSheetIfVisible];
        NSString *errorMessage = message.length > 0 ? message : [self localizedStringForKey:@"common_unknown_error"];
        [MTCExampleToastView showMessage:[NSString stringWithFormat:[self localizedStringForKey:@"map_style_switch_failure"], mapStyleID, errorMessage]
                                  inView:(self.view.window ?: self.view)];
    });
}

- (void)mapViewDidFinishLoadingMap:(MTCMapView *)mapView {
    dispatch_async(dispatch_get_main_queue(), ^{
        (void)mapView;
        [self.mapTestSupport markMapRenderedReady];
        [self.mapTestSupport pauseMapRenderingIfUITesting:self.mapView];
    });
}

#pragma mark - Event

- (void)handleExampleSettingsAction {
    if ([self isSettingsSheetVisible:ExampleSettingsSheetView.class]) {
        return;
    }

    [self showSettingsSheet];
}

#pragma mark - Private

- (void)showSettingsSheet {
    ExampleSettingsSheetView *sheet =
        [[ExampleSettingsSheetView alloc] initWithTitle:[self localizedStringForKey:@"demo_title_MTCRouteConditionViewController"]
                                               sections:[self settingsSections]];
    self.settingsSheet = sheet;
    [sheet showInView:self.view animated:NO];
}

- (void)configureMapView {
    self.mapTestSupport = [[MTCExampleMapTestSupport alloc] init];
    [self.mapTestSupport installOnHostView:self.view];

    self.mapView = [[MTCMapView alloc] initWithFrame:self.view.bounds];
    self.mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.mapView.delegate = self;
    self.trafficEnabled = YES;
    self.selectedMapStyleIndex = 0;
    self.hasCurrentMapType = NO;
    self.hasPendingMapType = NO;
    self.mapView.mapType = [self mapTypeForSelectedIndex:self.selectedMapStyleIndex trafficEnabled:self.trafficEnabled];
    self.mapView.uiSettings.compassEnabled = NO;
    self.mapView.uiSettings.scaleBarEnabled = NO;
    self.mapView.uiSettings.dayNightModeEnabled = NO;
    self.mapView.uiSettings.zoomButtonsEnabled = YES;
    self.mapView.uiSettings.zoomLevelVisible = YES;
    self.mapView.uiSettings.zoomButtonsGravity = MTCUIPositionTop | MTCUIPositionLeft;
    self.mapView.uiSettings.zoomButtonsMargins = UIEdgeInsetsMake(12.0, 12.0, 4.0, 4.0);
    self.mapView.uiSettings.zoomLevelFormat = MTCZoomLevelPrecisionTwoDecimals;
    self.mapView.uiSettings.zoomLevelPosition = MTCZoomLevelPositionMiddle;
    [self.view addSubview:self.mapView];

    [self.mapView setCenterCoordinate:CLLocationCoordinate2DMake(MTCRouteConditionInitialLatitude, MTCRouteConditionInitialLongitude)
                            zoomLevel:MTCRouteConditionInitialZoomLevel];
}

- (NSArray<ExampleSettingsSection *> *)settingsSections {
    __weak typeof(self) weakSelf = self;
    return @[
        [ExampleSettingsSection sectionWithTitle:@"" items:@[
            [[ExampleSettingsItem boolItemWithTitle:[self localizedStringForKey:@"map_traffic_switch_traffic"]
                                            getter:^BOOL{
                return weakSelf.isTrafficEnabled;
            } setter:^(BOOL value) {
                weakSelf.trafficEnabled = value;
                [weakSelf applySelectedMapStyle];
            }] withAccessibilityIdentifier:MTCExampleTestAccessibilitySwitchTrafficEnabled],
            [[ExampleSettingsItem boolItemWithTitle:[self localizedStringForKey:@"map_traffic_map_style_label"]
                                             getter:^BOOL {
                return weakSelf.selectedMapStyleIndex == 1;
            } setter:^(BOOL value) {
                weakSelf.selectedMapStyleIndex = value ? 1 : 0;
                [weakSelf applySelectedMapStyle];
            }] withAccessibilityIdentifier:MTCExampleTestAccessibilitySwitchMapStyle],
            [[ExampleSettingsItem dynamicInfoItemWithGetter:^NSString *{
                return [NSString stringWithFormat:@"%.2f", weakSelf.mapView.camera.zoomLevel];
            }] withAccessibilityIdentifier:MTCExampleTestAccessibilityTextCurrentZoom],
        ]],
    ];
}

- (void)refreshSettingsSheetIfVisible {
    if (![self isSettingsSheetVisible:ExampleSettingsSheetView.class]) {
        return;
    }
    [self.settingsSheet reloadData];
}

- (BOOL)isDarkMapStyleSelected {
    return self.selectedMapStyleIndex == 1;
}

- (NSArray<NSString *> *)mapStyleOptions {
    if (self.trafficEnabled) {
        return @[
            [self localizedStringForKey:@"map_traffic_style_light"],
            [self localizedStringForKey:@"map_traffic_style_dark"],
        ];
    }
    return @[
        [self localizedStringForKey:@"map_style_standard"],
        [self localizedStringForKey:@"map_style_night"],
    ];
}

- (MTCMapType)mapTypeForSelectedIndex:(NSInteger)selectedIndex trafficEnabled:(BOOL)trafficEnabled {
    if (trafficEnabled) {
        return selectedIndex == 1 ? MTCMapTypeTrafficNight : MTCMapTypeTrafficStandard;
    }
    return selectedIndex == 1 ? MTCMapTypeNight : MTCMapTypeStandard;
}

- (MTCMapType)desiredMapType {
    return [self mapTypeForSelectedIndex:self.selectedMapStyleIndex trafficEnabled:self.trafficEnabled];
}

- (void)applySelectedMapStyle {
    MTCMapType desiredMapType = [self desiredMapType];
    if (self.hasPendingMapType && self.pendingMapType == desiredMapType) {
        return;
    }
    if (self.hasCurrentMapType && self.currentMapType == desiredMapType) {
        return;
    }

    self.pendingMapType = desiredMapType;
    self.hasPendingMapType = YES;
    [self.mapTestSupport clearMapRenderedReady];
    [self.mapTestSupport pauseMapRenderingIfUITesting:self.mapView];
    self.mapView.mapType = desiredMapType;
}

#pragma mark -- multi-language

- (void)demoLanguageDidChange {
    [self applyLocalizedTexts];
}

- (void)applyLocalizedTexts {
    self.title = [self localizedStringForKey:@"demo_title_MTCRouteConditionViewController"];
    if (self.mapView) {
        self.mapView.mapLanguage = [self mapLanguageForDemoLanguage:self.demoLanguage];
    }
    if ([self isSettingsSheetVisible:ExampleSettingsSheetView.class]) {
        [self refreshSettingsSheetIfVisible];
    }
}

@end
