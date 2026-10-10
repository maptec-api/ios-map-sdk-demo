//
//  MTCMapLimitViewController.m
//  MaptecMapsExample
//
//  Created by Codex on 2026/9/8.
//

#import "MTCMapLimitViewController.h"

#import "ExampleSettingsSheetView.h"
#import "MTCExampleMapTestSupport.h"
#import "MTCExampleTestAccessibility.h"

#import <MaptecMapsKit/MaptecMapsKit.h>

static CLLocationDegrees const MTCMapLimitInitialLatitude = 1.3521;
static CLLocationDegrees const MTCMapLimitInitialLongitude = 103.8198;
static double const MTCMapLimitInitialZoomLevel = 11.5;

static MTCCoordinateBounds MTCMapLimitBounds(void) {
    return MTCCoordinateBoundsMake(CLLocationCoordinate2DMake(1.29, 103.78),
                                   CLLocationCoordinate2DMake(1.37, 103.90));
}

static void MTCMapLimitWriteRectangleCoordinates(MTCCoordinateBounds bounds,
                                                 CLLocationCoordinate2D coordinates[5]) {
    coordinates[0] = bounds.southwest;
    coordinates[1] = CLLocationCoordinate2DMake(bounds.southwest.latitude, bounds.northeast.longitude);
    coordinates[2] = bounds.northeast;
    coordinates[3] = CLLocationCoordinate2DMake(bounds.northeast.latitude, bounds.southwest.longitude);
    coordinates[4] = bounds.southwest;
}

static MTCPolygon *MTCMapLimitRegionPolygonWithBounds(MTCCoordinateBounds bounds) {
    CLLocationCoordinate2D coordinates[5];
    MTCMapLimitWriteRectangleCoordinates(bounds, coordinates);

    MTCPolygon *polygon = [[MTCPolygon alloc] initWithCoordinates:coordinates count:5];
    polygon.clickable = NO;
    polygon.draggable = NO;
    polygon.visible = YES;
    polygon.zIndex = 100;

    MTCPolygonStyle *style = [[MTCPolygonStyle alloc] init];
    UIColor *accentColor = [UIColor colorWithRed:0.227 green:0.369 blue:0.984 alpha:1.0];
    style.fillColor = accentColor;
    style.fillOpacity = 0.25;
    style.strokeColor = accentColor;
    style.strokeWeight = 3.0;
    style.strokeOpacity = 1.0;
    style.fillAntialias = YES;
    polygon.style = style;
    return polygon;
}

@interface MTCMapLimitViewController () <MTCMapViewDelegate>

@property (nonatomic, strong) MTCMapView *mapView;
@property (nonatomic, weak) ExampleSettingsSheetView *settingsSheet;
@property (nonatomic, strong) MTCExampleMapTestSupport *mapTestSupport;
@property (nonatomic, strong, nullable) MTCPolygon *limitRegionPolygon;
@property (nonatomic) BOOL limitApplied;

@end

@implementation MTCMapLimitViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = UIColor.whiteColor;
    self.view.accessibilityIdentifier = MTCExampleTestAccessibilityMapLimitScreen;

    [self configureNavigationItems:NO];
    [self configureMapView];
    [self applyLocalizedTexts];
    [self applySelectedLimit];
}

#pragma mark - Delegate

- (void)mapViewDidFinishLoadingMap:(MTCMapView *)mapView {
    (void)mapView;
    [self refreshLimitBorder];
    [self.mapTestSupport markMapRenderedReady];
    [self.mapTestSupport pauseMapRenderingIfUITesting:self.mapView];
}

- (void)mapView:(MTCMapView *)mapView didLoadMapStyleWithID:(NSString *)mapStyleID {
    (void)mapView;
    (void)mapStyleID;
    [self refreshLimitBorder];
    [self.mapTestSupport markMapRenderedReady];
    [self.mapTestSupport pauseMapRenderingIfUITesting:self.mapView];
}

- (void)mapView:(MTCMapView *)mapView didFinishSwitchingMapStyleWithID:(NSString *)mapStyleID {
    (void)mapView;
    (void)mapStyleID;
    [self refreshLimitBorder];
    [self.mapTestSupport markMapRenderedReady];
    [self.mapTestSupport pauseMapRenderingIfUITesting:self.mapView];
}

#pragma mark - Event

- (void)handleExampleSettingsAction {
    [self showSettingsSheet];
}

- (void)showSettingsSheet {
    __weak typeof(self) weakSelf = self;
    __block ExampleSettingsSheetView *sheet = nil;
    sheet = [[ExampleSettingsSheetView alloc] initWithTitle:[self localizedStringForKey:@"common_settings_sheet_title"]
                                                   sections:[self settingsSectionsWithApplyAction:^{
        [weakSelf applySelectedLimit];
        [sheet dismissAnimated:YES];
    } clearAction:^{
        [weakSelf clearMapLimit];
        [sheet dismissAnimated:YES];
    }]];
    self.settingsSheet = sheet;
    [sheet showInView:self.view animated:YES];
}

#pragma mark - Private

- (void)configureMapView {
    self.mapTestSupport = [[MTCExampleMapTestSupport alloc] init];
    [self.mapTestSupport installOnHostView:self.view];

    self.mapView = [[MTCMapView alloc] initWithFrame:self.view.bounds];
    self.mapView.delegate = self;
    self.mapView.uiSettings.zoomLevelVisible = YES;
    self.mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.mapView];

//    [self.mapView setCenterCoordinate:CLLocationCoordinate2DMake(MTCMapLimitInitialLatitude, MTCMapLimitInitialLongitude)
//                            zoomLevel:MTCMapLimitInitialZoomLevel];
    
    [self.mapView setVisibleCoordinateBounds:MTCMapLimitBounds() edgePadding:UIEdgeInsetsMake(50, 100, 50, 50) transition:[MTCCameraTransition jump] completion:nil];
}

- (NSArray<ExampleSettingsSection *> *)settingsSectionsWithApplyAction:(dispatch_block_t)applyAction
                                                            clearAction:(dispatch_block_t)clearAction {
    __weak typeof(self) weakSelf = self;
    ExampleSettingsEnabledGetter applyEnabled = ^BOOL{
        return !weakSelf.limitApplied;
    };
    ExampleSettingsEnabledGetter clearEnabled = ^BOOL{
        return weakSelf.limitApplied;
    };

    return @[
        [ExampleSettingsSection sectionWithTitle:@"" items:@[
            [[[ExampleSettingsItem actionItemWithTitle:[self localizedStringForKey:@"map_limit_apply"]
                                               handler:applyAction]
                withAccessibilityIdentifier:MTCExampleTestAccessibilityMapLimitApplyButton] enabledWhen:applyEnabled],
            [[[ExampleSettingsItem actionItemWithTitle:[self localizedStringForKey:@"map_limit_clear"]
                                               handler:clearAction]
                withAccessibilityIdentifier:MTCExampleTestAccessibilityMapLimitClearButton] enabledWhen:clearEnabled],
        ]],
    ];
}

- (void)refreshLimitBorder {
    [self removeLimitBorder];
    self.limitRegionPolygon = MTCMapLimitRegionPolygonWithBounds(MTCMapLimitBounds());
    if (!self.limitRegionPolygon) {
        return;
    }
    [self.mapView addOverlay:self.limitRegionPolygon level:MTCOverlayLevelDefault];
}

- (void)removeLimitBorder {
    if (!self.limitRegionPolygon) {
        return;
    }
    [self.mapView removeOverlay:self.limitRegionPolygon];
    self.limitRegionPolygon = nil;
}

- (void)applySelectedLimit {
    [self.mapView setCameraCenterBoundsLimit:MTCMapLimitBounds()];
    self.limitApplied = YES;
}

- (void)clearMapLimit {
    [self.mapView setCameraCenterBoundsLimit:MTCCoordinateBoundsNull];
    self.limitApplied = NO;
}

#pragma mark -- multi-language

- (void)demoLanguageDidChange {
    [self applyLocalizedTexts];
}

- (void)applyLocalizedTexts {
    self.title = [self localizedStringForKey:@"demo_title_MTCMapLimitViewController"];
    if ([self isSettingsSheetVisible:ExampleSettingsSheetView.class]) {
        [self showSettingsSheet];
    }
}

@end
