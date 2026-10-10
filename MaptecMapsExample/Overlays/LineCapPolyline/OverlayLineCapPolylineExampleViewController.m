#import "OverlayLineCapPolylineExampleViewController.h"

#import "ExampleSettingsSheetView.h"
#import "MTCExampleMapTestSupport.h"
#import "MTCExampleTestAccessibility.h"

#import <MaptecMapsKit/MaptecMapsKit.h>

#include <math.h>

static CLLocationDegrees const OverlayLineCapPolylineExampleSingaporeLatitude = 1.3048264556208515;
static CLLocationDegrees const OverlayLineCapPolylineExampleSingaporeLongitude = 103.83052199958921;
static double const OverlayLineCapPolylineExampleDefaultZoomLevel = 13.0;
static CGFloat const OverlayLineCapPolylineExampleStrokeWeight = 10.0;
static CGFloat const OverlayLineCapPolylineExampleArrowViewportSize = 300.0;
static CGFloat const OverlayLineCapPolylineExampleArrowBaseViewportSize = 140.0;
static CGFloat const OverlayLineCapPolylineExampleArrowBaseToStrokeRatio = 2.0;
static NSString * const OverlayLineCapPolylineExampleArrowLeftImageName = @"line_cap_arrow_left";
static NSString * const OverlayLineCapPolylineExampleArrowRightImageName = @"line_cap_arrow_right";

typedef NS_ENUM(NSInteger, OverlayLineCapPolylineExampleLineCapOption) {
    OverlayLineCapPolylineExampleLineCapOptionButt = 0,
    OverlayLineCapPolylineExampleLineCapOptionRound,
    OverlayLineCapPolylineExampleLineCapOptionSquare,
    OverlayLineCapPolylineExampleLineCapOptionArrow,
};

@interface OverlayLineCapPolylineExampleFormState : NSObject <NSCopying>
@property (nonatomic) NSInteger routeIndex;
@property (nonatomic) NSInteger strokeColorIndex;
@property (nonatomic) double strokeWeight;
@property (nonatomic) double strokeOpacity;
@property (nonatomic) NSInteger dashIndex;
@property (nonatomic) BOOL closed;
@property (nonatomic) BOOL draggable;
@property (nonatomic) NSInteger startLineCapTypeIndex;
@property (nonatomic) NSInteger endLineCapTypeIndex;
@property (nonatomic, copy, nullable) NSData *coordinateData;
@end

@implementation OverlayLineCapPolylineExampleFormState

- (id)copyWithZone:(NSZone *)zone {
    OverlayLineCapPolylineExampleFormState *state = [[[self class] allocWithZone:zone] init];
    state.routeIndex = self.routeIndex;
    state.strokeColorIndex = self.strokeColorIndex;
    state.strokeWeight = self.strokeWeight;
    state.strokeOpacity = self.strokeOpacity;
    state.dashIndex = self.dashIndex;
    state.closed = self.closed;
    state.draggable = self.draggable;
    state.startLineCapTypeIndex = self.startLineCapTypeIndex;
    state.endLineCapTypeIndex = self.endLineCapTypeIndex;
    state.coordinateData = self.coordinateData;
    return state;
}

@end

@interface OverlayLineCapPolylineExampleViewController () <MTCMapViewDelegate>
@property (nonatomic, strong) MTCMapView *mapView;
@property (nonatomic, strong) MTCPolyline *polyline;
@property (nonatomic, strong, nullable) MTCMarker *startArrowCapMarker;
@property (nonatomic, strong, nullable) MTCMarker *endArrowCapMarker;
@property (nonatomic, strong) OverlayLineCapPolylineExampleFormState *state;
@property (nonatomic, strong, nullable) OverlayLineCapPolylineExampleFormState *editingState;
@property (nonatomic, weak, nullable) MTCPolyline *editingPolyline;
@property (nonatomic, strong) MTCExampleMapTestSupport *mapTestSupport;
@end

@implementation OverlayLineCapPolylineExampleViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = UIColor.whiteColor;
    self.view.accessibilityIdentifier = @"OverlayLineCapPolylineExampleViewController.screen";
    self.state = [self defaultPolylineState];

    [self configureNavigationItems:NO];
    [self configureMapView];
    [self addLineCapPolyline];
    [self.mapView setCenterCoordinate:[self singaporeCoordinate]
                             zoomLevel:OverlayLineCapPolylineExampleDefaultZoomLevel];
    [self applyLocalizedTexts];
}

#pragma mark - Setup

- (void)configureMapView {
    self.mapTestSupport = [[MTCExampleMapTestSupport alloc] init];
    self.mapTestSupport.overlayCountValueKey = MTCExampleTestAccessibilityLineCountValueKey;
    self.mapTestSupport.overlayPresenceIdentifier = MTCExampleTestAccessibilityLineHasLines;
    [self.mapTestSupport installOnHostView:self.view];

    self.mapView = [[MTCMapView alloc] initWithFrame:self.view.bounds];
    self.mapView.delegate = self;
    self.mapView.uiSettings.zoomLevelVisible = YES;
    self.mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.mapView];
}

#pragma mark - Delegate

- (void)mapViewDidFinishLoadingMap:(MTCMapView *)mapView {
    dispatch_async(dispatch_get_main_queue(), ^{
        (void)mapView;
        [self.mapTestSupport markMapRenderedReady];
        [self.mapTestSupport pauseMapRenderingIfUITesting:self.mapView];
    });
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
    dispatch_async(dispatch_get_main_queue(), ^{
        (void)mapView;
        (void)mapStyleID;
        [self.mapTestSupport markMapRenderedReady];
        [self.mapTestSupport pauseMapRenderingIfUITesting:self.mapView];
    });
}

#pragma mark - Sheet

- (void)showSettingsSheet {
    MTCPolyline *currentPolyline = [self currentPolyline];
    self.editingPolyline = currentPolyline;
    self.editingState = currentPolyline ? [self stateFromPolyline:currentPolyline] : [self defaultPolylineState];

    __weak typeof(self) weakSelf = self;
    __block ExampleSettingsSheetView *sheet = nil;
    sheet = [[ExampleSettingsSheetView alloc] initWithTitle:[self localizedStringForKey:@"common_settings_sheet_title"]
                                                   sections:[self sectionsForState:self.editingState
                                                                            action:^{
        [weakSelf replacePolylineWithState:weakSelf.editingState recenter:YES];
        [sheet dismissAnimated:YES];
    }]];
    [sheet showInView:self.view animated:YES];
}

- (NSArray<ExampleSettingsSection *> *)sectionsForState:(OverlayLineCapPolylineExampleFormState *)state
                                                 action:(dispatch_block_t)action {
    __weak OverlayLineCapPolylineExampleFormState *weakState = state;
    __weak typeof(self) weakSelf = self;
    void (^syncState)(void) = ^{
        [weakSelf syncEditingPolylineForState:weakState];
    };
    ExampleSettingsListGroup *colorGroup =
        [ExampleSettingsListGroup groupWithTitle:[self localizedStringForKey:@"overlay_colors"]
                                         options:[self colorTitles]
                                optionHexValues:[self colorHexValues]
                             initiallyCollapsed:NO];

    return @[
        [ExampleSettingsSection sectionWithTitle:[self localizedStringForKey:@"overlay_geometry"] items:@[
            [ExampleSettingsItem listItemWithTitle:[self localizedStringForKey:@"overlay_vertices"]
                                           options:[self routeTitles]
                                        popupSize:CGSizeMake(260.0, 220.0)
                                            getter:^NSInteger {
                return weakState.routeIndex;
            } setter:^(NSInteger index) {
                weakState.routeIndex = index;
                weakState.coordinateData = nil;
                syncState();
            }],
        ]],
        [ExampleSettingsSection sectionWithTitle:[self localizedStringForKey:@"overlay_style"] items:@[
            [ExampleSettingsItem groupedListItemWithTitle:[self localizedStringForKey:@"overlay_line_color"]
                                                   groups:@[colorGroup]
                                               popupSize:CGSizeMake(260.0, 300.0)
                                                  getter:^NSInteger {
                return weakState.strokeColorIndex;
            } setter:^(NSInteger index) {
                weakState.strokeColorIndex = index;
                syncState();
            }],
            [ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"overlay_opacity"]
                                             minimum:0.0
                                             maximum:1.0
                                                step:0.05
                                              getter:^double {
                return weakState.strokeOpacity;
            } setter:^(double value) {
                weakState.strokeOpacity = value;
                syncState();
            } formatter:^NSString *(double value) {
                return [NSString stringWithFormat:@"%.2f", value];
            }],
            [ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"overlay_line_width_px"]
                                             minimum:1.0
                                             maximum:30.0
                                                step:1.0
                                              getter:^double {
                return weakState.strokeWeight;
            } setter:^(double value) {
                weakState.strokeWeight = value;
                syncState();
            } formatter:^NSString *(double value) {
                return [NSString stringWithFormat:@"%.0f", value];
            }],
            [ExampleSettingsItem listItemWithTitle:[self localizedStringForKey:@"overlay_dash_pattern"]
                                           options:[self dashTitles]
                                        popupSize:CGSizeMake(260.0, 180.0)
                                            getter:^NSInteger {
                return weakState.dashIndex;
            } setter:^(NSInteger index) {
                weakState.dashIndex = index;
                syncState();
            }],
        ]],
        [ExampleSettingsSection sectionWithTitle:[self localizedStringForKey:@"overlay_behavior"] items:@[
            [[ExampleSettingsItem boolItemWithTitle:[self localizedStringForKey:@"overlay_closed"]
                                             getter:^BOOL {
                return weakState.closed;
            } setter:^(BOOL value) {
                weakState.closed = value;
                syncState();
            }] withAccessibilityIdentifier:MTCExampleTestAccessibilityLineSwitchClosed],
            [[ExampleSettingsItem boolItemWithTitle:[self localizedStringForKey:@"overlay_draggable"]
                                             getter:^BOOL {
                return weakState.draggable;
            } setter:^(BOOL value) {
                weakState.draggable = value;
                syncState();
            }] withAccessibilityIdentifier:MTCExampleTestAccessibilityLineSwitchDraggable],
        ]],
        [ExampleSettingsSection sectionWithTitle:[self localizedStringForKey:@"overlay_line_cap"] items:@[
            [[ExampleSettingsItem listItemWithTitle:[self localizedStringForKey:@"overlay_start_cap"]
                                            options:[self lineCapTitles]
                                         popupSize:CGSizeMake(260.0, 220.0)
                                             getter:^NSInteger {
                return weakState.startLineCapTypeIndex;
            } setter:^(NSInteger index) {
                weakState.startLineCapTypeIndex = index;
                syncState();
            }] withAccessibilityIdentifier:MTCExampleTestAccessibilityLineDropdownStartCap],
            [[ExampleSettingsItem listItemWithTitle:[self localizedStringForKey:@"overlay_end_cap"]
                                            options:[self lineCapTitles]
                                         popupSize:CGSizeMake(260.0, 220.0)
                                             getter:^NSInteger {
                return weakState.endLineCapTypeIndex;
            } setter:^(NSInteger index) {
                weakState.endLineCapTypeIndex = index;
                syncState();
            }] withAccessibilityIdentifier:MTCExampleTestAccessibilityLineDropdownEndCap],
        ]],
        [ExampleSettingsSection sectionWithTitle:@"" items:@[
            [[ExampleSettingsItem actionItemWithTitle:[self localizedStringForKey:@"overlay_add_b58c75"] handler:action]
             withAccessibilityIdentifier:MTCExampleTestAccessibilityLineButtonDraw],
        ]],
    ];
}

#pragma mark - Polyline

- (void)addLineCapPolyline {
    [self addLineCapPolylineWithState:self.state];
}

- (void)addLineCapPolylineWithState:(OverlayLineCapPolylineExampleFormState *)state {
    if (!state) {
        return;
    }

    NSData *coordinateData = [self coordinateDataForState:state];
    NSUInteger coordinateCount = [self coordinateCountForData:coordinateData];
    if (coordinateCount == 0) {
        return;
    }

    self.polyline = [[MTCPolyline alloc] initWithCoordinates:(const CLLocationCoordinate2D *)coordinateData.bytes
                                                       count:coordinateCount];
    [self applyState:state toPolyline:self.polyline updateCoordinates:NO];
    [self.mapView addOverlay:self.polyline];
    self.state = [state copy];
    self.editingPolyline = self.polyline;
    [self syncArrowCapMarkersForState:state];
    [self.mapTestSupport syncOverlayCount:1];
}

- (MTCPolyline *)currentPolyline {
    return self.polyline;
}

- (void)replacePolylineWithState:(OverlayLineCapPolylineExampleFormState *)state
                          recenter:(BOOL)recenter {
    if (!state) {
        return;
    }

    NSData *coordinateData = [self coordinateDataForState:state];
    [self removeLineCapPolyline];
    [self addLineCapPolylineWithState:state];
    if (recenter && self.polyline) {
        [self focusCoordinateData:coordinateData animated:YES];
    }
}

- (void)removeLineCapPolyline {
    [self removeArrowCapMarkers];
    if (self.polyline) {
        [self.mapView removeOverlay:self.polyline];
    }
    self.polyline = nil;
    self.editingPolyline = nil;
    [self.mapTestSupport syncOverlayCount:0];
}

- (void)updatePolylineWithState:(OverlayLineCapPolylineExampleFormState *)state {
    if (!self.polyline || !state) {
        return;
    }

    [self.mapView performOverlayUpdates:^{
        [self applyState:state toPolyline:self.polyline updateCoordinates:YES];
    }];
    [self syncArrowCapMarkersForState:state];
    self.state = [state copy];
}

- (void)syncEditingPolylineForState:(OverlayLineCapPolylineExampleFormState *)state {
    MTCPolyline *editingPolyline = self.editingPolyline;
    if (!editingPolyline || editingPolyline != self.polyline || !state) {
        return;
    }

    [self updatePolylineWithState:state];
}

- (void)applyState:(OverlayLineCapPolylineExampleFormState *)state
        toPolyline:(MTCPolyline *)polyline
 updateCoordinates:(BOOL)updateCoordinates {
    if (updateCoordinates) {
        NSData *coordinateData = [self coordinateDataForState:state];
        [polyline setCoordinates:(const CLLocationCoordinate2D *)coordinateData.bytes
                            count:[self coordinateCountForData:coordinateData]];
    }

    polyline.closed = state.closed;
    polyline.draggable = state.draggable;
    polyline.style = [self styleForState:state];
}

- (OverlayLineCapPolylineExampleFormState *)defaultPolylineState {
    OverlayLineCapPolylineExampleFormState *state = [[OverlayLineCapPolylineExampleFormState alloc] init];
    state.routeIndex = 0;
    state.strokeColorIndex = 0;
    state.strokeWeight = OverlayLineCapPolylineExampleStrokeWeight;
    state.strokeOpacity = 1.0;
    state.dashIndex = 0;
    state.closed = NO;
    state.draggable = NO;
    state.startLineCapTypeIndex = 1;
    state.endLineCapTypeIndex = 1;
    return state;
}

- (OverlayLineCapPolylineExampleFormState *)stateFromPolyline:(MTCPolyline *)polyline {
    OverlayLineCapPolylineExampleFormState *state = self.state ? [self.state copy] : [self defaultPolylineState];
    if (!polyline) {
        return state;
    }

    state.coordinateData = [self coordinateDataFromPolyline:polyline];
    state.strokeColorIndex = [self indexForColor:polyline.style.strokeColor fallbackIndex:state.strokeColorIndex];
    state.strokeWeight = polyline.style.strokeWeight;
    state.strokeOpacity = polyline.style.strokeOpacity;
    state.dashIndex = [self indexForDashArray:polyline.style.strokeDashArray fallbackIndex:state.dashIndex];
    state.closed = polyline.isClosed;
    state.draggable = polyline.isDraggable;
    state.startLineCapTypeIndex = [self indexForLineCapType:polyline.style.startLineCapType
                                       preservingArrowIndex:state.startLineCapTypeIndex
                                              fallbackIndex:state.startLineCapTypeIndex];
    state.endLineCapTypeIndex = [self indexForLineCapType:polyline.style.endLineCapType
                                     preservingArrowIndex:state.endLineCapTypeIndex
                                            fallbackIndex:state.endLineCapTypeIndex];
    return state;
}

- (MTCPolylineStyle *)styleForState:(OverlayLineCapPolylineExampleFormState *)state {
    MTCPolylineStyle *style = [[MTCPolylineStyle alloc] init];
    style.strokeColor = [self colorForIndex:state.strokeColorIndex];
    style.strokeWeight = state.strokeWeight;
    style.strokeOpacity = state.strokeOpacity;
    style.strokeDashArray = [self dashArrayForIndex:state.dashIndex];
    style.startLineCapType = [self engineLineCapTypeForIndex:state.startLineCapTypeIndex];
    style.endLineCapType = [self engineLineCapTypeForIndex:state.endLineCapTypeIndex];
    return style;
}

#pragma mark - Arrow Cap Markers

- (void)syncArrowCapMarkersForState:(OverlayLineCapPolylineExampleFormState *)state {
    if (!self.polyline || !state || self.polyline.coordinateCount < 2) {
        [self removeArrowCapMarkers];
        return;
    }

    NSUInteger coordinateCount = self.polyline.coordinateCount;
    NSMutableData *coordinateData = [NSMutableData dataWithLength:coordinateCount * sizeof(CLLocationCoordinate2D)];
    CLLocationCoordinate2D *coordinates = (CLLocationCoordinate2D *)coordinateData.mutableBytes;
    [self.polyline getCoordinates:coordinates range:NSMakeRange(0, coordinateCount)];

    self.startArrowCapMarker = [self arrowCapMarker:self.startArrowCapMarker
                                            enabled:[self isArrowLineCapIndex:state.startLineCapTypeIndex]
                                             anchor:coordinates[0]
                                           neighbor:coordinates[1]
                                            isStart:YES
                                              state:state];
    self.endArrowCapMarker = [self arrowCapMarker:self.endArrowCapMarker
                                          enabled:[self isArrowLineCapIndex:state.endLineCapTypeIndex]
                                           anchor:coordinates[coordinateCount - 1]
                                         neighbor:coordinates[coordinateCount - 2]
                                          isStart:NO
                                            state:state];
}

- (MTCMarker *)arrowCapMarker:(MTCMarker *)marker
                      enabled:(BOOL)enabled
                       anchor:(CLLocationCoordinate2D)anchor
                     neighbor:(CLLocationCoordinate2D)neighbor
                      isStart:(BOOL)isStart
                        state:(OverlayLineCapPolylineExampleFormState *)state {
    if (!enabled) {
        if (marker) {
            [self.mapView removeOverlay:marker];
        }
        return nil;
    }

    UIImage *image = [UIImage imageNamed:isStart ? OverlayLineCapPolylineExampleArrowLeftImageName : OverlayLineCapPolylineExampleArrowRightImageName];
    if (!image) {
        if (marker) {
            [self.mapView removeOverlay:marker];
        }
        return nil;
    }

    if (!marker) {
        marker = [[MTCMarker alloc] initWithCoordinate:anchor];
        marker.clickable = NO;
        marker.togglesSelectionOnTap = NO;
        marker.draggable = NO;
        [self.mapView addOverlay:marker];
    }

    marker.coordinate = anchor;
    marker.zIndex = self.polyline.zIndex + 1;
    marker.style = [self arrowCapMarkerStyleWithImage:image
                                              isStart:isStart
                                               anchor:anchor
                                             neighbor:neighbor
                                                state:state];
    return marker;
}

- (MTCMarkerStyle *)arrowCapMarkerStyleWithImage:(UIImage *)image
                                         isStart:(BOOL)isStart
                                          anchor:(CLLocationCoordinate2D)anchor
                                        neighbor:(CLLocationCoordinate2D)neighbor
                                           state:(OverlayLineCapPolylineExampleFormState *)state {
    MTCMarkerStyle *style = [[MTCMarkerStyle alloc] init];
    style.icon.type = MTCMarkerIconTypeCustom;
    style.icon.customImage = image;
    style.icon.tintColor = [self colorForIndex:state.strokeColorIndex];
    style.icon.size = [self arrowCapMarkerSizeForState:state];
    style.icon.anchor = CGPointMake(0.5, 0.5);
    style.icon.rotation = [self arrowCapMarkerRotationWithAnchor:anchor neighbor:neighbor isStart:isStart];
    style.icon.opacity = state.strokeOpacity;
    return style;
}

- (CGSize)arrowCapMarkerSizeForState:(OverlayLineCapPolylineExampleFormState *)state {
    CGFloat baseLength = state.strokeWeight * OverlayLineCapPolylineExampleArrowBaseToStrokeRatio;
    CGFloat iconLength = baseLength / OverlayLineCapPolylineExampleArrowBaseViewportSize * OverlayLineCapPolylineExampleArrowViewportSize;
    return CGSizeMake(iconLength, iconLength);
}

- (CGFloat)arrowCapMarkerRotationWithAnchor:(CLLocationCoordinate2D)anchor
                                   neighbor:(CLLocationCoordinate2D)neighbor
                                    isStart:(BOOL)isStart {
    CLLocationDegrees latitudeDelta = anchor.latitude - neighbor.latitude;
    CLLocationDegrees longitudeDelta = anchor.longitude - neighbor.longitude;
    double length = sqrt(latitudeDelta * latitudeDelta + longitudeDelta * longitudeDelta);
    CGFloat angle = length > 1e-9 ? (CGFloat)(atan2(-latitudeDelta, longitudeDelta) * 180.0 / M_PI) : 0.0;
    CLLocationDirection bearing = self.mapView.camera ? self.mapView.camera.bearing : 0.0;
    CGFloat screenAngle = angle - (CGFloat)bearing;
    return isStart ? screenAngle - 180.0 : screenAngle;
}

- (void)removeArrowCapMarkers {
    if (self.startArrowCapMarker) {
        [self.mapView removeOverlay:self.startArrowCapMarker];
        self.startArrowCapMarker = nil;
    }
    if (self.endArrowCapMarker) {
        [self.mapView removeOverlay:self.endArrowCapMarker];
        self.endArrowCapMarker = nil;
    }
}

#pragma mark - Coordinates

- (CLLocationCoordinate2D)singaporeCoordinate {
    return CLLocationCoordinate2DMake(OverlayLineCapPolylineExampleSingaporeLatitude,
                                      OverlayLineCapPolylineExampleSingaporeLongitude);
}

- (NSArray<NSString *> *)routeTitles {
    return @[[self localizedStringForKey:@"overlay_route_a_4_points"], [self localizedStringForKey:@"overlay_route_b_6_points"], [self localizedStringForKey:@"overlay_short_route_3_points"], [self localizedStringForKey:@"overlay_polyline_c_5_points"]];
}

- (NSData *)coordinateDataForState:(OverlayLineCapPolylineExampleFormState *)state {
    if (state.coordinateData.length > 0) {
        return state.coordinateData;
    }
    return [self coordinateDataForRouteIndex:state.routeIndex];
}

- (NSData *)coordinateDataFromPolyline:(MTCPolyline *)polyline {
    NSUInteger count = polyline.coordinateCount;
    NSMutableData *data = [NSMutableData dataWithLength:count * sizeof(CLLocationCoordinate2D)];
    if (count > 0) {
        [polyline getCoordinates:(CLLocationCoordinate2D *)data.mutableBytes range:NSMakeRange(0, count)];
    }
    return data;
}

- (NSData *)coordinateDataForRouteIndex:(NSInteger)routeIndex {
    NSUInteger count = [self coordinateCountForRouteIndex:routeIndex];
    NSMutableData *data = [NSMutableData dataWithLength:count * sizeof(CLLocationCoordinate2D)];
    CLLocationCoordinate2D *coordinates = (CLLocationCoordinate2D *)data.mutableBytes;
    for (NSUInteger index = 0; index < count; ++index) {
        coordinates[index] = [self coordinateForRouteIndex:routeIndex pointIndex:index];
    }
    return data;
}

- (NSUInteger)coordinateCountForData:(NSData *)coordinateData {
    return coordinateData.length / sizeof(CLLocationCoordinate2D);
}

- (NSUInteger)coordinateCountForRouteIndex:(NSInteger)routeIndex {
    switch (routeIndex) {
        case 1:
            return 6;
        case 2:
            return 3;
        case 3:
            return 5;
        default:
            return 4;
    }
}

- (CLLocationCoordinate2D)coordinateForRouteIndex:(NSInteger)routeIndex
                                      pointIndex:(NSUInteger)pointIndex {
    switch (routeIndex) {
        case 1:
            switch (pointIndex) {
                case 0:
                    return CLLocationCoordinate2DMake(1.292826, 103.812522);
                case 1:
                    return CLLocationCoordinate2DMake(1.301826, 103.820522);
                case 2:
                    return CLLocationCoordinate2DMake(1.306826, 103.834522);
                case 3:
                    return CLLocationCoordinate2DMake(1.314826, 103.844522);
                case 4:
                    return CLLocationCoordinate2DMake(1.323826, 103.836522);
                default:
                    return CLLocationCoordinate2DMake(1.331826, 103.850522);
            }
        case 2:
            switch (pointIndex) {
                case 0:
                    return CLLocationCoordinate2DMake(1.308826, 103.817522);
                case 1:
                    return CLLocationCoordinate2DMake(1.318826, 103.828522);
                default:
                    return CLLocationCoordinate2DMake(1.310826, 103.842522);
            }
        case 3:
            switch (pointIndex) {
                case 0:
                    return CLLocationCoordinate2DMake(1.296826, 103.838522);
                case 1:
                    return CLLocationCoordinate2DMake(1.304826, 103.848522);
                case 2:
                    return CLLocationCoordinate2DMake(1.316826, 103.846522);
                case 3:
                    return CLLocationCoordinate2DMake(1.318826, 103.830522);
                default:
                    return CLLocationCoordinate2DMake(1.306826, 103.822522);
            }
        default:
            switch (pointIndex) {
                case 0:
                    return CLLocationCoordinate2DMake(1.298826, 103.820522);
                case 1:
                    return CLLocationCoordinate2DMake(1.304826, 103.830522);
                case 2:
                    return CLLocationCoordinate2DMake(1.311826, 103.839522);
                default:
                    return CLLocationCoordinate2DMake(1.319826, 103.828522);
            }
    }
}

- (void)focusCoordinateData:(NSData *)coordinateData animated:(BOOL)animated {
    CLLocationCoordinate2D center = [self centerCoordinateForData:coordinateData];
    if (animated) {
        [self.mapView setCenterCoordinate:center transition:[MTCCameraTransition easeWithDuration:0.25] completion:nil];
    } else {
        [self.mapView setCenterCoordinate:center zoomLevel:OverlayLineCapPolylineExampleDefaultZoomLevel];
    }
}

- (CLLocationCoordinate2D)centerCoordinateForData:(NSData *)coordinateData {
    NSUInteger count = [self coordinateCountForData:coordinateData];
    if (count == 0) {
        return [self singaporeCoordinate];
    }

    const CLLocationCoordinate2D *coordinates = (const CLLocationCoordinate2D *)coordinateData.bytes;
    CLLocationDegrees latitude = 0.0;
    CLLocationDegrees longitude = 0.0;
    for (NSUInteger index = 0; index < count; ++index) {
        latitude += coordinates[index].latitude;
        longitude += coordinates[index].longitude;
    }
    return CLLocationCoordinate2DMake(latitude / count, longitude / count);
}

#pragma mark - Formatting

- (NSArray<NSString *> *)colorTitles {
    return @[@"#00A63E", @"#2563EB", @"#EF4444", @"#F59E0B", @"#111827", @"#000000", @"#FFFFFF"];
}

- (NSArray<NSString *> *)colorHexValues {
    return [self colorTitles];
}

- (UIColor *)colorForIndex:(NSInteger)index {
    NSArray<NSString *> *hexValues = [self colorHexValues];
    if (index < 0 || index >= hexValues.count) {
        index = 0;
    }
    return [self colorFromHexString:hexValues[index]];
}

- (UIColor *)colorFromHexString:(NSString *)hexString {
    NSString *candidate = [[hexString ?: @"" stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] uppercaseString];
    if ([candidate hasPrefix:@"#"]) {
        candidate = [candidate substringFromIndex:1];
    }

    unsigned int rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:candidate];
    if (candidate.length != 6 || ![scanner scanHexInt:&rgbValue]) {
        return UIColor.systemGreenColor;
    }

    return [UIColor colorWithRed:((rgbValue >> 16) & 0xFF) / 255.0
                           green:((rgbValue >> 8) & 0xFF) / 255.0
                            blue:(rgbValue & 0xFF) / 255.0
                           alpha:1.0];
}

- (NSInteger)indexForColor:(UIColor *)color fallbackIndex:(NSInteger)fallbackIndex {
    NSString *hexString = [self hexStringFromColor:color];
    NSArray<NSString *> *hexValues = [self colorHexValues];
    for (NSUInteger index = 0; index < hexValues.count; ++index) {
        if ([hexString isEqualToString:hexValues[index]]) {
            return (NSInteger)index;
        }
    }
    return fallbackIndex;
}

- (NSString *)hexStringFromColor:(UIColor *)color {
    CGFloat red = 0.0;
    CGFloat green = 0.0;
    CGFloat blue = 0.0;
    CGFloat alpha = 0.0;
    if (![color getRed:&red green:&green blue:&blue alpha:&alpha]) {
        return @"";
    }

    NSInteger redValue = (NSInteger)lrint(fmin(fmax(red, 0.0), 1.0) * 255.0);
    NSInteger greenValue = (NSInteger)lrint(fmin(fmax(green, 0.0), 1.0) * 255.0);
    NSInteger blueValue = (NSInteger)lrint(fmin(fmax(blue, 0.0), 1.0) * 255.0);
    return [NSString stringWithFormat:@"#%02lX%02lX%02lX", (long)redValue, (long)greenValue, (long)blueValue];
}

- (NSArray<NSString *> *)dashTitles {
    return @[[self localizedStringForKey:@"overlay_solid"], @"2, 2", @"6, 3", @"10, 4"];
}

- (NSArray<NSNumber *> *)dashArrayForIndex:(NSInteger)index {
    switch (index) {
        case 1:
            return @[@2.0, @2.0];
        case 2:
            return @[@6.0, @3.0];
        case 3:
            return @[@10.0, @4.0];
        default:
            return @[];
    }
}

- (NSInteger)indexForDashArray:(NSArray<NSNumber *> *)dashArray
                 fallbackIndex:(NSInteger)fallbackIndex {
    for (NSInteger index = 0; index < [self dashTitles].count; ++index) {
        NSArray<NSNumber *> *candidate = [self dashArrayForIndex:index];
        if ([self dashArray:candidate equalsDashArray:dashArray]) {
            return index;
        }
    }
    return fallbackIndex;
}

- (BOOL)dashArray:(NSArray<NSNumber *> *)lhs equalsDashArray:(NSArray<NSNumber *> *)rhs {
    if (lhs.count != rhs.count) {
        return NO;
    }
    for (NSUInteger index = 0; index < lhs.count; ++index) {
        if (fabs(lhs[index].doubleValue - rhs[index].doubleValue) > 0.0001) {
            return NO;
        }
    }
    return YES;
}

- (NSArray<NSString *> *)lineCapTitles {
    return @[@"Butt", @"Round", @"Square", @"Arrow"];
}

- (MTCLineCapType)engineLineCapTypeForIndex:(NSInteger)index {
    switch (index) {
        case OverlayLineCapPolylineExampleLineCapOptionRound:
            return MTCLineCapTypeRound;
        case OverlayLineCapPolylineExampleLineCapOptionSquare:
            return MTCLineCapTypeSquare;
        case OverlayLineCapPolylineExampleLineCapOptionArrow:
        case OverlayLineCapPolylineExampleLineCapOptionButt:
        default:
            return MTCLineCapTypeButt;
    }
}

- (BOOL)isArrowLineCapIndex:(NSInteger)index {
    return index == OverlayLineCapPolylineExampleLineCapOptionArrow;
}

- (NSInteger)indexForLineCapType:(MTCLineCapType)lineCapType
                    fallbackIndex:(NSInteger)fallbackIndex {
    switch (lineCapType) {
        case MTCLineCapTypeButt:
            return OverlayLineCapPolylineExampleLineCapOptionButt;
        case MTCLineCapTypeRound:
            return OverlayLineCapPolylineExampleLineCapOptionRound;
        case MTCLineCapTypeSquare:
            return OverlayLineCapPolylineExampleLineCapOptionSquare;
        default:
            return fallbackIndex;
    }
}

- (NSInteger)indexForLineCapType:(MTCLineCapType)lineCapType
             preservingArrowIndex:(NSInteger)currentIndex
                    fallbackIndex:(NSInteger)fallbackIndex {
    if ([self isArrowLineCapIndex:currentIndex]) {
        return currentIndex;
    }
    return [self indexForLineCapType:lineCapType fallbackIndex:fallbackIndex];
}

#pragma mark - MTCMapViewDelegate

- (void)mapView:(MTCMapView *)mapView
cameraDidChange:(MTCMapCamera *)camera
         reason:(MTCMapCameraChangeReason)reason
       animated:(BOOL)animated {
    (void)mapView;
    (void)camera;
    (void)reason;
    (void)animated;
    [self syncArrowCapMarkersForState:self.state];
}

- (void)mapView:(MTCMapView *)mapView
cameraDidBecomeIdle:(MTCMapCamera *)camera
         reason:(MTCMapCameraChangeReason)reason
       animated:(BOOL)animated {
    (void)mapView;
    (void)camera;
    (void)reason;
    (void)animated;
    [self syncArrowCapMarkersForState:self.state];
}

- (void)mapView:(MTCMapView *)mapView didDragOverlay:(id<MTCOverlay>)overlay {
    (void)mapView;
    MTCPolyline *polyline = [(id)overlay isKindOfClass:MTCPolyline.class] ? (MTCPolyline *)overlay : nil;
    if (polyline == self.polyline) {
        [self syncArrowCapMarkersForState:self.state];
    }
}

- (void)mapView:(MTCMapView *)mapView didEndDraggingOverlay:(id<MTCOverlay>)overlay {
    (void)mapView;
    MTCPolyline *polyline = [(id)overlay isKindOfClass:MTCPolyline.class] ? (MTCPolyline *)overlay : nil;
    if (polyline == self.polyline) {
        [self syncArrowCapMarkersForState:self.state];
    }
}

#pragma mark -- multi-language

- (void)handleExampleSettingsAction {
    [self showSettingsSheet];
}

- (void)demoLanguageDidChange {
    [self applyLocalizedTexts];
}

- (void)applyLocalizedTexts {
    self.title = [self localizedStringForKey:@"demo_title_OverlayLineCapPolylineExampleViewController"];
    if (self.mapView) {
        self.mapView.mapLanguage = [self mapLanguageForDemoLanguage:self.demoLanguage];
    }
    if ([self isSettingsSheetVisible:ExampleSettingsSheetView.class]) {
        [self showSettingsSheet];
    }
}
@end
