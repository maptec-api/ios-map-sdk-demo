//
//  MTCGEOFencingPolygonViewController.m
//  MaptecMapsExample
//
//  Created by ZHOUPanpan on 2026/7/13.
//

#import "MTCGEOFencingPolygonViewController.h"

#import "ExampleSettingsSheetView.h"
#import "MTCExampleMapTestSupport.h"
#import "MTCExampleTestAccessibility.h"
#import "MTCExampleToastView.h"
#import "MTCGEOFencingSupport.h"

typedef NS_ENUM(NSInteger, MTCGEOFencingPolygonStatusKind) {
    MTCGEOFencingPolygonStatusKindTip = 0,
    MTCGEOFencingPolygonStatusKindMarkerInside,
    MTCGEOFencingPolygonStatusKindMarkerOutside,
    MTCGEOFencingPolygonStatusKindMarkerPlaced,
    MTCGEOFencingPolygonStatusKindFenceAlreadyLoaded,
    MTCGEOFencingPolygonStatusKindFenceLoaded,
    MTCGEOFencingPolygonStatusKindAllCleared,
    MTCGEOFencingPolygonStatusKindMarkersCleared,
};

@interface MTCGEOFencingPolygonViewController () <MTCMapViewDelegate>

@property (nonatomic, strong) MTCMapView *mapView;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UIButton *clearButton;
@property (nonatomic, strong, nullable) MTCPolygon *polygonFence;
@property (nonatomic, strong, nullable) MTCMarker *tapMarker;
@property (nonatomic, assign) BOOL polygonLoaded;
@property (nonatomic, assign) MTCGEOFencingPolygonStatusKind statusKind;
@property (nonatomic, assign) CLLocationCoordinate2D statusCoordinate;
@property (nonatomic, strong) MTCExampleMapTestSupport *mapTestSupport;

@end

@implementation MTCGEOFencingPolygonViewController

#pragma mark - Public

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = UIColor.whiteColor;
    self.view.accessibilityIdentifier = MTCExampleTestAccessibilityGeofencePolygonScreen;
    [self configureNavigationItems:NO];
    [self configureMapView];
    [self configureTopBar];
    [self focusMap];
    [self applyLocalizedTexts];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!self.polygonLoaded) {
        [self didTapLoadPolygon];
    }
}

#pragma mark - protocol

- (void)mapView:(MTCMapView *)mapView didTapAtCoordinate:(CLLocationCoordinate2D)coordinate {
    (void)mapView;
    if (!CLLocationCoordinate2DIsValid(coordinate)) {
        return;
    }
    [self clearMarker];
    self.tapMarker = [[MTCMarker alloc] initWithCoordinate:coordinate];
    [self.mapView addOverlay:self.tapMarker];
    [self.mapTestSupport syncOverlayCount:1];
    self.statusCoordinate = coordinate;
    if (!self.polygonFence) {
        self.statusKind = MTCGEOFencingPolygonStatusKindMarkerPlaced;
        [self refreshStatusLabelShowToast:NO];
        return;
    }
    BOOL inside = MTCGEOFencingPointInsidePolygon(coordinate, self.polygonFence);
    self.statusKind = inside ? MTCGEOFencingPolygonStatusKindMarkerInside
                             : MTCGEOFencingPolygonStatusKindMarkerOutside;
    [self refreshStatusLabelShowToast:NO];
}

#pragma mark - Delegate

- (void)mapViewDidFinishLoadingMap:(MTCMapView *)mapView {
    (void)mapView;
    [self.mapTestSupport markMapRenderedReady];
    [self.mapTestSupport pauseMapRenderingIfUITesting:self.mapView];
}

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

#pragma mark - Event

- (void)showGeofenceSettings {
    __weak typeof(self) weakSelf = self;
    ExampleSettingsSheetView *sheet =
        [[ExampleSettingsSheetView alloc] initWithTitle:self.title
                                               sections:@[
        [ExampleSettingsSection sectionWithTitle:[self localizedStringForKey:@"overlay_actions"] items:@[
            [[ExampleSettingsItem actionItemWithTitle:[self localizedStringForKey:@"overlay_load_polygon_geofence"] handler:^{
                [weakSelf didTapLoadPolygon];
            }] withAccessibilityIdentifier:MTCExampleTestAccessibilityGeofenceLoadPolygon],
            [[ExampleSettingsItem actionItemWithTitle:[self localizedStringForKey:@"overlay_clear_all"] handler:^{
                [weakSelf didTapClearAll];
            }] withAccessibilityIdentifier:MTCExampleTestAccessibilityGeofenceClearAll],
        ]],
    ]];
    [sheet showInView:self.view animated:NO];
}

- (void)didTapLoadPolygon {
    if (self.polygonFence) {
        self.polygonLoaded = YES;
        self.statusKind = MTCGEOFencingPolygonStatusKindFenceAlreadyLoaded;
        [self refreshStatusLabelShowToast:NO];
        return;
    }
    self.polygonFence = [[MTCPolygon alloc] initWithCoordinates:MTCGEOFencingPolygonFenceCoords
                                                          count:MTCGEOFencingPolygonFenceCount];
    self.polygonFence.style = MTCGEOFencingMakePolygonStyle();
    self.polygonFence.zIndex = 2;
    [self.mapView addOverlay:self.polygonFence];
    self.polygonLoaded = YES;
    self.statusKind = MTCGEOFencingPolygonStatusKindFenceLoaded;
    [self refreshStatusLabelShowToast:NO];
}

- (void)didTapClearAll {
    if (self.polygonFence) {
        [self.mapView removeOverlay:self.polygonFence];
        self.polygonFence = nil;
    }
    self.polygonLoaded = NO;
    [self clearMarker];
    self.statusKind = MTCGEOFencingPolygonStatusKindAllCleared;
    [self refreshStatusLabelShowToast:YES];
}

- (void)didTapClearMarker {
    [self clearMarker];
    self.statusKind = MTCGEOFencingPolygonStatusKindMarkersCleared;
    [self refreshStatusLabelShowToast:NO];
}

#pragma mark - Private

- (void)configureMapView {
    self.mapView = [[MTCMapView alloc] initWithFrame:self.view.bounds];
    self.mapView.delegate = self;
    self.mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.mapView];

    self.mapTestSupport = [[MTCExampleMapTestSupport alloc] init];
    self.mapTestSupport.overlayPresenceIdentifier = MTCExampleTestAccessibilitySymbolLayerHasMarkers;
    [self.mapTestSupport installOnHostView:self.view];
    [self.mapTestSupport syncOverlayCount:0];
}

- (void)configureTopBar {
    UIView *topBar = [[UIView alloc] init];
    topBar.translatesAutoresizingMaskIntoConstraints = NO;
    topBar.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.95];
    [self.view addSubview:topBar];
    [topBar addSubview:self.statusLabel];
    [topBar addSubview:self.clearButton];

    self.statusLabel.accessibilityIdentifier = MTCExampleTestAccessibilityGeofenceStatus;
    self.clearButton.accessibilityIdentifier = MTCExampleTestAccessibilityGeofenceClearMarker;

    [NSLayoutConstraint activateConstraints:@[
        [topBar.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [topBar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [topBar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [topBar.heightAnchor constraintEqualToConstant:60.0],
        [self.statusLabel.topAnchor constraintEqualToAnchor:topBar.topAnchor constant:4.0],
        [self.statusLabel.leadingAnchor constraintEqualToAnchor:topBar.leadingAnchor constant:8.0],
        [self.statusLabel.trailingAnchor constraintEqualToAnchor:topBar.trailingAnchor constant:-8.0],
        [self.clearButton.topAnchor constraintEqualToAnchor:self.statusLabel.bottomAnchor constant:4.0],
        [self.clearButton.centerXAnchor constraintEqualToAnchor:topBar.centerXAnchor],
        [self.clearButton.widthAnchor constraintEqualToConstant:120.0],
        [self.clearButton.heightAnchor constraintEqualToConstant:28.0],
    ]];
}

- (void)focusMap {
    [self.mapView setCenterCoordinate:CLLocationCoordinate2DMake(MTCGEOFencingCameraLatitude, MTCGEOFencingCameraLongitude)
                            zoomLevel:MTCGEOFencingCameraZoom];
}

- (void)clearMarker {
    if (self.tapMarker) {
        [self.mapView removeOverlay:self.tapMarker];
        self.tapMarker = nil;
    }
    [self.mapTestSupport syncOverlayCount:0];
}

- (NSString *)statusTextForCurrentKind {
    NSString *coordStr = [NSString stringWithFormat:@"(%.5f, %.5f)",
                          self.statusCoordinate.latitude,
                          self.statusCoordinate.longitude];
    switch (self.statusKind) {
        case MTCGEOFencingPolygonStatusKindMarkerInside:
            return [NSString stringWithFormat:[self localizedStringForKey:@"overlay_marker_is_inside_the_polygon_geofence"], coordStr];
        case MTCGEOFencingPolygonStatusKindMarkerOutside:
            return [NSString stringWithFormat:[self localizedStringForKey:@"overlay_marker_is_outside_the_polygon_geofence"], coordStr];
        case MTCGEOFencingPolygonStatusKindMarkerPlaced:
            return [NSString stringWithFormat:[self localizedStringForKey:@"overlay_marker_placed"], coordStr];
        case MTCGEOFencingPolygonStatusKindFenceAlreadyLoaded:
            return [self localizedStringForKey:@"overlay_polygon_geofence_loaded"];
        case MTCGEOFencingPolygonStatusKindFenceLoaded:
            return [self localizedStringForKey:@"overlay_loaded_polygon_geofence_campus_fence"];
        case MTCGEOFencingPolygonStatusKindAllCleared:
            return [self localizedStringForKey:@"overlay_all_overlays_cleared"];
        case MTCGEOFencingPolygonStatusKindMarkersCleared:
            return [self localizedStringForKey:@"overlay_markers_cleared_tap_the_map_to_place_a_new_marke"];
        case MTCGEOFencingPolygonStatusKindTip:
        default:
            return [self localizedStringForKey:@"overlay_tap_the_map_to_place_a_marker_and_check_polygon_"];
    }
}

- (void)refreshStatusLabelShowToast:(BOOL)showToast {
    NSString *text = [self statusTextForCurrentKind];
    self.statusLabel.text = text;
    switch (self.statusKind) {
        case MTCGEOFencingPolygonStatusKindMarkerInside:
            self.statusLabel.textColor = [UIColor colorWithRed:0.106 green:0.498 blue:0.165 alpha:1.0];
            break;
        case MTCGEOFencingPolygonStatusKindMarkerOutside:
            self.statusLabel.textColor = UIColor.redColor;
            break;
        default:
            self.statusLabel.textColor = UIColor.darkGrayColor;
            break;
    }
    if (showToast) {
        [MTCExampleToastView showMessage:text inView:self.view];
    }
}

#pragma mark - Getter & Setter

- (UILabel *)statusLabel {
    if (_statusLabel) {
        return _statusLabel;
    }
    _statusLabel = [[UILabel alloc] init];
    _statusLabel.numberOfLines = 2;
    _statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _statusLabel.textAlignment = NSTextAlignmentCenter;
    _statusLabel.font = [UIFont systemFontOfSize:14.0];
    _statusLabel.textColor = UIColor.darkGrayColor;
    return _statusLabel;
}

- (UIButton *)clearButton {
    if (_clearButton) {
        return _clearButton;
    }
    _clearButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _clearButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_clearButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    _clearButton.backgroundColor = UIColor.redColor;
    _clearButton.layer.cornerRadius = 6.0;
    _clearButton.titleLabel.font = [UIFont boldSystemFontOfSize:13.0];
    [_clearButton addTarget:self action:@selector(didTapClearMarker) forControlEvents:UIControlEventTouchUpInside];
    return _clearButton;
}

#pragma mark -- multi-language

- (void)handleExampleSettingsAction {
    [self showGeofenceSettings];
}

- (void)demoLanguageDidChange {
    [self applyLocalizedTexts];
}

- (void)applyLocalizedTexts {
    self.title = [self localizedStringForKey:@"demo_title_MTCGEOFencingPolygonViewController"];
    if (self.mapView) {
        self.mapView.mapLanguage = [self mapLanguageForDemoLanguage:self.demoLanguage];
    }
    [self.clearButton setTitle:[self localizedStringForKey:@"overlay_clear_marker"] forState:UIControlStateNormal];
    [self refreshStatusLabelShowToast:NO];
    if ([self isSettingsSheetVisible:ExampleSettingsSheetView.class]) {
        [self showGeofenceSettings];
    }
}
@end
