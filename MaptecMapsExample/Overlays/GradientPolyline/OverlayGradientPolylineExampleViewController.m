#import "OverlayGradientPolylineExampleViewController.h"

#import "ExampleSettingsSheetView.h"
#import "MTCExampleMapTestSupport.h"
#import "MTCExampleTestAccessibility.h"

#import <MaptecMapsKit/MaptecMapsKit.h>

#include <math.h>

static CLLocationDegrees const OverlayGradientPolylineExampleSingaporeLatitude = 1.3048264556208515;
static CLLocationDegrees const OverlayGradientPolylineExampleSingaporeLongitude = 103.83052199958921;
static double const OverlayGradientPolylineExampleDefaultZoomLevel = 13.0;
static CGFloat const OverlayGradientPolylineExampleStrokeWeight = 10.0;

@interface OverlayGradientPolylineExampleFormState : NSObject <NSCopying>
@property (nonatomic) NSInteger routeIndex;
@property (nonatomic) NSInteger gradientIndex;
@property (nonatomic) double strokeWeight;
@property (nonatomic) double strokeOpacity;
@property (nonatomic) NSInteger dashIndex;
@property (nonatomic) BOOL closed;
@property (nonatomic) BOOL draggable;
@property (nonatomic, copy, nullable) NSData *coordinateData;
@end

@implementation OverlayGradientPolylineExampleFormState

- (id)copyWithZone:(NSZone *)zone {
    OverlayGradientPolylineExampleFormState *state = [[[self class] allocWithZone:zone] init];
    state.routeIndex = self.routeIndex;
    state.gradientIndex = self.gradientIndex;
    state.strokeWeight = self.strokeWeight;
    state.strokeOpacity = self.strokeOpacity;
    state.dashIndex = self.dashIndex;
    state.closed = self.closed;
    state.draggable = self.draggable;
    state.coordinateData = self.coordinateData;
    return state;
}

@end

@interface OverlayGradientPolylineExampleViewController () <MTCMapViewDelegate>
@property (nonatomic, strong) MTCMapView *mapView;
@property (nonatomic, strong) MTCPolyline *polyline;
@property (nonatomic, strong) OverlayGradientPolylineExampleFormState *state;
@property (nonatomic, strong, nullable) OverlayGradientPolylineExampleFormState *editingState;
@property (nonatomic, weak, nullable) MTCPolyline *editingPolyline;
@property (nonatomic, strong) MTCExampleMapTestSupport *mapTestSupport;
@end

@implementation OverlayGradientPolylineExampleViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = UIColor.whiteColor;
    self.view.accessibilityIdentifier = MTCExampleTestAccessibilityOverlayGradientPolylineScreen;
    self.state = [self defaultPolylineState];

    [self configureNavigationItems:NO];
    [self configureMapView];
    [self addGradientPolyline];
    [self.mapView setCenterCoordinate:[self singaporeCoordinate]
                             zoomLevel:OverlayGradientPolylineExampleDefaultZoomLevel];
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

- (NSArray<ExampleSettingsSection *> *)sectionsForState:(OverlayGradientPolylineExampleFormState *)state
                                                 action:(dispatch_block_t)action {
    __weak OverlayGradientPolylineExampleFormState *weakState = state;
    __weak typeof(self) weakSelf = self;
    void (^syncState)(void) = ^{
        [weakSelf syncEditingPolylineForState:weakState];
    };

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
            [ExampleSettingsItem listItemWithTitle:[self localizedStringForKey:@"overlay_line_color"]
                                           options:[self gradientTitles]
                                        popupSize:CGSizeMake(280.0, 260.0)
                                            getter:^NSInteger {
                return weakState.gradientIndex;
            } setter:^(NSInteger index) {
                weakState.gradientIndex = index;
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
        [ExampleSettingsSection sectionWithTitle:@"" items:@[
            [[ExampleSettingsItem actionItemWithTitle:[self localizedStringForKey:@"overlay_add_b58c75"] handler:action]
             withAccessibilityIdentifier:MTCExampleTestAccessibilityLineButtonDraw],
        ]],
    ];
}

#pragma mark - Polyline

- (void)addGradientPolyline {
    [self addGradientPolylineWithState:self.state];
}

- (void)addGradientPolylineWithState:(OverlayGradientPolylineExampleFormState *)state {
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
    [self.mapTestSupport syncOverlayCount:1];
}

- (MTCPolyline *)currentPolyline {
    return self.polyline;
}

- (void)replacePolylineWithState:(OverlayGradientPolylineExampleFormState *)state
                          recenter:(BOOL)recenter {
    if (!state) {
        return;
    }

    NSData *coordinateData = [self coordinateDataForState:state];
    [self removeGradientPolyline];
    [self addGradientPolylineWithState:state];
    if (recenter && self.polyline) {
        [self focusCoordinateData:coordinateData animated:YES];
    }
}

- (void)removeGradientPolyline {
    if (self.polyline) {
        [self.mapView removeOverlay:self.polyline];
    }
    self.polyline = nil;
    self.editingPolyline = nil;
    [self.mapTestSupport syncOverlayCount:0];
}

- (void)updatePolylineWithState:(OverlayGradientPolylineExampleFormState *)state {
    if (!self.polyline || !state) {
        return;
    }

    [self.mapView performOverlayUpdates:^{
        [self applyState:state toPolyline:self.polyline updateCoordinates:YES];
    }];
    self.state = [state copy];
}

- (void)syncEditingPolylineForState:(OverlayGradientPolylineExampleFormState *)state {
    MTCPolyline *editingPolyline = self.editingPolyline;
    if (!editingPolyline || editingPolyline != self.polyline || !state) {
        return;
    }

    [self updatePolylineWithState:state];
}

- (void)applyState:(OverlayGradientPolylineExampleFormState *)state
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

- (OverlayGradientPolylineExampleFormState *)defaultPolylineState {
    OverlayGradientPolylineExampleFormState *state = [[OverlayGradientPolylineExampleFormState alloc] init];
    state.routeIndex = 0;
    state.gradientIndex = 0;
    state.strokeWeight = OverlayGradientPolylineExampleStrokeWeight;
    state.strokeOpacity = 1.0;
    state.dashIndex = 0;
    state.closed = NO;
    state.draggable = NO;
    return state;
}

- (OverlayGradientPolylineExampleFormState *)stateFromPolyline:(MTCPolyline *)polyline {
    OverlayGradientPolylineExampleFormState *state = self.state ? [self.state copy] : [self defaultPolylineState];
    if (!polyline) {
        return state;
    }

    state.coordinateData = [self coordinateDataFromPolyline:polyline];
    state.gradientIndex = [self indexForGradient:polyline.style.lineGradient
                                    fallbackIndex:state.gradientIndex];
    state.strokeWeight = polyline.style.strokeWeight;
    state.strokeOpacity = polyline.style.strokeOpacity;
    state.dashIndex = [self indexForDashArray:polyline.style.strokeDashArray
                                 fallbackIndex:state.dashIndex];
    state.closed = polyline.isClosed;
    state.draggable = polyline.isDraggable;
    return state;
}

- (MTCPolylineStyle *)styleForState:(OverlayGradientPolylineExampleFormState *)state {
    MTCPolylineStyle *style = [[MTCPolylineStyle alloc] init];
    MTCLineGradient *gradient = [self gradientForIndex:state.gradientIndex];
    style.strokeColor = gradient.colorStops.firstObject.color ?: UIColor.systemGreenColor;
    style.lineGradient = gradient;
    style.strokeWeight = state.strokeWeight;
    style.strokeOpacity = state.strokeOpacity;
    style.strokeDashArray = [self dashArrayForIndex:state.dashIndex];
    return style;
}

#pragma mark - Coordinates

- (CLLocationCoordinate2D)singaporeCoordinate {
    return CLLocationCoordinate2DMake(OverlayGradientPolylineExampleSingaporeLatitude,
                                      OverlayGradientPolylineExampleSingaporeLongitude);
}

- (NSArray<NSString *> *)routeTitles {
    return @[[self localizedStringForKey:@"overlay_route_a_4_points"],
             [self localizedStringForKey:@"overlay_route_b_6_points"],
             [self localizedStringForKey:@"overlay_short_route_3_points"],
             [self localizedStringForKey:@"overlay_polyline_c_5_points"]];
}

- (NSData *)coordinateDataForState:(OverlayGradientPolylineExampleFormState *)state {
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
        [self.mapView setCenterCoordinate:center
                               transition:[MTCCameraTransition easeWithDuration:0.25]
                               completion:nil];
    } else {
        [self.mapView setCenterCoordinate:center
                                zoomLevel:OverlayGradientPolylineExampleDefaultZoomLevel];
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

- (NSArray<NSString *> *)gradientTitles {
    return @[
        [self localizedStringForKey:@"overlay_gradient_3_stops_01"],
        [self localizedStringForKey:@"overlay_gradient_5_stops_01"],
        [self localizedStringForKey:@"overlay_gradient_8_stops_01"],
        [self localizedStringForKey:@"overlay_gradient_3_stops_no_0"],
        [self localizedStringForKey:@"overlay_gradient_3_stops_no_1"],
    ];
}

- (NSArray<MTCLineGradient *> *)gradientPresets {
    return @[
        [[MTCLineGradient alloc] initWithColorStops:@[
            [self gradientStopWithProgress:0.0 hexString:@"#2563EB"],
            [self gradientStopWithProgress:0.5 hexString:@"#F59E0B"],
            [self gradientStopWithProgress:1.0 hexString:@"#EF4444"],
        ]],
        [[MTCLineGradient alloc] initWithColorStops:@[
            [self gradientStopWithProgress:0.0 hexString:@"#0EA5E9"],
            [self gradientStopWithProgress:0.25 hexString:@"#22C55E"],
            [self gradientStopWithProgress:0.5 hexString:@"#FACC15"],
            [self gradientStopWithProgress:0.75 hexString:@"#F97316"],
            [self gradientStopWithProgress:1.0 hexString:@"#DC2626"],
        ]],
        [[MTCLineGradient alloc] initWithColorStops:@[
            [self gradientStopWithProgress:0.0 hexString:@"#1D4ED8"],
            [self gradientStopWithProgress:0.14 hexString:@"#0EA5E9"],
            [self gradientStopWithProgress:0.28 hexString:@"#14B8A6"],
            [self gradientStopWithProgress:0.42 hexString:@"#22C55E"],
            [self gradientStopWithProgress:0.57 hexString:@"#A3E635"],
            [self gradientStopWithProgress:0.71 hexString:@"#FACC15"],
            [self gradientStopWithProgress:0.85 hexString:@"#F97316"],
            [self gradientStopWithProgress:1.0 hexString:@"#DC2626"],
        ]],
        [[MTCLineGradient alloc] initWithColorStops:@[
            [self gradientStopWithProgress:0.2 hexString:@"#7C3AED"],
            [self gradientStopWithProgress:0.6 hexString:@"#EC4899"],
            [self gradientStopWithProgress:1.0 hexString:@"#F43F5E"],
        ]],
        [[MTCLineGradient alloc] initWithColorStops:@[
            [self gradientStopWithProgress:0.0 hexString:@"#059669"],
            [self gradientStopWithProgress:0.4 hexString:@"#06B6D4"],
            [self gradientStopWithProgress:0.8 hexString:@"#2563EB"],
        ]],
    ];
}

- (MTCLineGradientStop *)gradientStopWithProgress:(CGFloat)progress
                                        hexString:(NSString *)hexString {
    return [[MTCLineGradientStop alloc] initWithLineProgress:progress
                                                       color:[self colorFromHexString:hexString]];
}

- (MTCLineGradient *)gradientForIndex:(NSInteger)index {
    NSArray<MTCLineGradient *> *presets = [self gradientPresets];
    if (index < 0 || index >= presets.count) {
        index = 0;
    }
    return presets[index];
}

- (NSInteger)indexForGradient:(MTCLineGradient *)gradient
                 fallbackIndex:(NSInteger)fallbackIndex {
    if (!gradient) {
        return fallbackIndex;
    }

    NSArray<MTCLineGradient *> *presets = [self gradientPresets];
    for (NSUInteger index = 0; index < presets.count; ++index) {
        if ([gradient isEqual:presets[index]]) {
            return (NSInteger)index;
        }
    }
    return fallbackIndex;
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

#pragma mark - Multi-language

- (void)handleExampleSettingsAction {
    [self showSettingsSheet];
}

- (void)demoLanguageDidChange {
    [self applyLocalizedTexts];
}

- (void)applyLocalizedTexts {
    self.title = [self localizedStringForKey:@"demo_title_OverlayGradientPolylineExampleViewController"];
    if (self.mapView) {
        self.mapView.mapLanguage = [self mapLanguageForDemoLanguage:self.demoLanguage];
    }
    if ([self isSettingsSheetVisible:ExampleSettingsSheetView.class]) {
        [self showSettingsSheet];
    }
}

@end
