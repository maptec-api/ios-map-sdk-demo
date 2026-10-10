#import "MTCMapPOIsViewController.h"

#import "ExampleSettingsSheetView.h"
#import "MTCExampleMapTestSupport.h"
#import "MTCExampleTestAccessibility.h"
#import "MTCExampleToastView.h"

#import <MaptecMapsKit/MaptecMapsKit.h>

@interface MTCMapPOIsViewController () <MTCMapViewDelegate>

@property (nonatomic, strong) MTCMapView *mapView;
@property (nonatomic, strong) MTCExampleMapTestSupport *mapTestSupport;
@property (nonatomic, assign) BOOL centerPoiOnClick;
@property (nonatomic, strong, nullable) MTCMarker *poiMarker;
@property (nonatomic, copy, nullable) NSString *selectedPoiName;
@property (nonatomic, assign) CLLocationCoordinate2D selectedPoiCoordinate;
@property (nonatomic, assign) BOOL hasSelectedPoi;
@property (nonatomic, weak, nullable) ExampleSettingsSheetView *settingsSheet;

@end

@implementation MTCMapPOIsViewController

- (void)dealloc {
}

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = UIColor.whiteColor;
    self.view.accessibilityIdentifier = MTCExampleTestAccessibilityMapPoisScreen;
    self.centerPoiOnClick = YES;

    [self configureNavigationItems:NO];
    [self configureMapView];
    [self applyLocalizedTexts];
}

#pragma mark - Delegate
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

- (void)mapView:(MTCMapView *)mapView didTapAtCoordinate:(CLLocationCoordinate2D)coordinate {
    (void)mapView;
    if (self.poiMarker) {
        [self.mapView removeOverlay:self.poiMarker];
    }
    [self.mapView queryPOIsAtCoordinate:coordinate completion:^(NSArray<MTCPOI *> *pois) {
        MTCPOI *poi = pois.firstObject;
        if (!poi) {
            return;
        }
        
        NSLog(@"queryPOIsAtCoordinate: %@", poi.name);
        [self applyPoiSelection:poi resultCount:pois.count];
    }];
}

#pragma mark - Event

- (void)handleExampleSettingsAction {
    if ([self isSettingsSheetVisible:ExampleSettingsSheetView.class]) {
        return;
    }
    [self showPoiSettings];
}

- (void)showPoiSettings {
    ExampleSettingsSheetView *sheet =
        [[ExampleSettingsSheetView alloc] initWithTitle:[self localizedStringForKey:@"demo_title_MTCMapPOIsViewController"]
                                               sections:[self poiSections]];
    self.settingsSheet = sheet;
    [sheet showInView:self.view animated:NO];
}

- (void)clearPoiSelection {
    if (self.poiMarker) {
        [self.mapView removeOverlay:self.poiMarker];
        self.poiMarker = nil;
    }
    self.selectedPoiName = nil;
    self.hasSelectedPoi = NO;
    [self.mapTestSupport syncOverlayCount:0];
    [self.settingsSheet refreshVisibleItems];
}

#pragma mark - Private

- (void)configureMapView {
    self.mapView = [[MTCMapView alloc] initWithFrame:self.view.bounds];
    self.mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.mapView.delegate = self;
    [self.view addSubview:self.mapView];

    self.mapTestSupport = [[MTCExampleMapTestSupport alloc] init];
    self.mapTestSupport.overlayCountValueKey = MTCExampleTestAccessibilityMarkerCountValueKey;
    [self.mapTestSupport installOnHostView:self.view];
    [self.mapTestSupport syncOverlayCount:0];

    [self.mapView setCenterCoordinate:CLLocationCoordinate2DMake(1.3521, 103.8198) zoomLevel:16.0];
}

- (NSArray<ExampleSettingsSection *> *)poiSections {
    __weak typeof(self) weakSelf = self;
    return @[
        [ExampleSettingsSection sectionWithTitle:[self localizedStringForKey:@"demo_title_MTCMapPOIsViewController"] items:@[
            [[ExampleSettingsItem boolItemWithTitle:@"点击 POI 居中"
                                             getter:^BOOL { return weakSelf.centerPoiOnClick; }
                                             setter:^(BOOL value) {
                weakSelf.centerPoiOnClick = value;
                [weakSelf clearPoiSelection];
            }] withAccessibilityIdentifier:MTCExampleTestAccessibilityPoiCenterSwitch],
            [[ExampleSettingsItem actionItemWithTitle:@"清空选择"
                                             handler:^{
                [weakSelf clearPoiSelection];
            }] withAccessibilityIdentifier:MTCExampleTestAccessibilityPoiClearButton],
            [ExampleSettingsItem dynamicInfoItemWithGetter:^NSString *{
                return [weakSelf selectedPoiNameText];
            }],
            [ExampleSettingsItem dynamicInfoItemWithGetter:^NSString *{
                return [weakSelf selectedPoiCoordinateText];
            }],
        ]],
    ];
}

- (void)applyPoiSelection:(MTCPOI *)poi resultCount:(NSUInteger)resultCount {
    if (!poi) {
        return;
    }

    self.hasSelectedPoi = YES;
    self.selectedPoiName = poi.name.length > 0 ? poi.name : @"-";
    self.selectedPoiCoordinate = poi.coordinate;

    self.poiMarker = [[MTCMarker alloc] initWithCoordinate:poi.coordinate];
    [self.mapView addOverlay:self.poiMarker];
    [self.mapTestSupport syncOverlayCount:1];

    if (self.centerPoiOnClick) {
        [self.mapView setCenterCoordinate:poi.coordinate transition:[MTCCameraTransition easeWithDuration:0.25] completion:nil];
    }

    [MTCExampleToastView showMessage:[self toastMessageForPOI:poi resultCount:resultCount] inView:self.view];
    [self.settingsSheet refreshVisibleItems];
}

- (NSString *)selectedPoiNameText {
    if (!self.hasSelectedPoi) {
        return @"当前命中的 POI 名称：-";
    }
    return [NSString stringWithFormat:@"当前命中的 POI 名称：%@", self.selectedPoiName ?: @"-"];
}

- (NSString *)selectedPoiCoordinateText {
    if (!self.hasSelectedPoi) {
        return @"当前命中的 POI 坐标：-";
    }
    return [NSString stringWithFormat:@"当前命中的 POI 坐标：%@", [self coordinateStringForCoordinate:self.selectedPoiCoordinate]];
}

- (NSString *)toastMessageForPOI:(MTCPOI *)poi resultCount:(NSUInteger)resultCount {
    NSString *name = poi.name.length > 0 ? poi.name : @"-";
    NSString *coordinate = [self coordinateStringForCoordinate:poi.coordinate];
    return [NSString stringWithFormat:@"查询到 %lu 个 POI\n名称：%@\n坐标：%@",
                                      (unsigned long)MAX(resultCount, 1UL),
                                      name,
                                      coordinate];
}

- (NSString *)coordinateStringForCoordinate:(CLLocationCoordinate2D)coordinate {
    return [NSString stringWithFormat:@"%.6f, %.6f", coordinate.latitude, coordinate.longitude];
}

#pragma mark -- multi-language

- (void)demoLanguageDidChange {
    [self applyLocalizedTexts];
}

- (void)applyLocalizedTexts {
    self.title = [self localizedStringForKey:@"demo_title_MTCMapPOIsViewController"];
}

@end
