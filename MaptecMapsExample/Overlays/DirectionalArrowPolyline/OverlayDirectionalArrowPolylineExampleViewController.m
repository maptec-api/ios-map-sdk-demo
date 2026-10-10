#import "OverlayDirectionalArrowPolylineExampleViewController.h"

#import "ExampleSettingsSheetView.h"
#import "MTCExampleMapTestSupport.h"
#import "MTCExampleTestAccessibility.h"
#import "MTCExampleToastView.h"

#import <MaptecMapsKit/MaptecMapsKit.h>

#include <math.h>

static CLLocationDegrees const OverlayDirectionalArrowPolylineExampleSingaporeLatitude = 1.3048264556208515;
static CLLocationDegrees const OverlayDirectionalArrowPolylineExampleSingaporeLongitude = 103.83052199958921;
static double const OverlayDirectionalArrowPolylineExampleDefaultZoomLevel = 13.0;

@interface OverlayDirectionalArrowPolylineExampleFormState : NSObject <NSCopying>
@property (nonatomic) NSInteger routeIndex;
@property (nonatomic) NSInteger strokeColorIndex;
@property (nonatomic) double strokeWeight;
@property (nonatomic) double strokeOpacity;
@property (nonatomic) NSInteger dashIndex;
@property (nonatomic) BOOL closed;
@property (nonatomic) BOOL draggable;
@property (nonatomic) BOOL directionalArrowsEnabled;
@property (nonatomic) NSInteger directionalArrowTypeIndex;
@property (nonatomic) NSInteger directionalArrowColorIndex;
@property (nonatomic) double directionalArrowDensity;
@property (nonatomic, copy, nullable) NSData *coordinateData;
@end

@implementation OverlayDirectionalArrowPolylineExampleFormState

- (id)copyWithZone:(NSZone *)zone {
    OverlayDirectionalArrowPolylineExampleFormState *state = [[[self class] allocWithZone:zone] init];
    state.routeIndex = self.routeIndex;
    state.strokeColorIndex = self.strokeColorIndex;
    state.strokeWeight = self.strokeWeight;
    state.strokeOpacity = self.strokeOpacity;
    state.dashIndex = self.dashIndex;
    state.closed = self.closed;
    state.draggable = self.draggable;
    state.directionalArrowsEnabled = self.directionalArrowsEnabled;
    state.directionalArrowTypeIndex = self.directionalArrowTypeIndex;
    state.directionalArrowColorIndex = self.directionalArrowColorIndex;
    state.directionalArrowDensity = self.directionalArrowDensity;
    state.coordinateData = self.coordinateData;
    return state;
}

@end

@interface OverlayDirectionalArrowPolylineExampleViewController () <MTCMapViewDelegate>
@property (nonatomic, strong) MTCMapView *mapView;
@property (nonatomic, strong) MTCPolyline *polyline;
@property (nonatomic, strong) OverlayDirectionalArrowPolylineExampleFormState *state;
@property (nonatomic, strong, nullable) OverlayDirectionalArrowPolylineExampleFormState *editingState;
@property (nonatomic, weak, nullable) MTCPolyline *editingPolyline;
@property (nonatomic, strong) MTCExampleMapTestSupport *mapTestSupport;
@end

@implementation OverlayDirectionalArrowPolylineExampleViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = UIColor.whiteColor;
    self.view.accessibilityIdentifier = @"OverlayDirectionalArrowPolylineExampleViewController.screen";
    self.state = [self defaultPolylineState];

    [self configureNavigationItems:NO];
    [self configureMapView];
    [self addDirectionalArrowPolyline];
    [self.mapView setCenterCoordinate:[self singaporeCoordinate]
                             zoomLevel:OverlayDirectionalArrowPolylineExampleDefaultZoomLevel];
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
    BOOL normalizedDash = [self enforceDirectionalArrowDashCompatibilityForState:self.editingState showToast:NO];
    if (normalizedDash) {
        [self syncEditingPolylineForState:self.editingState];
    }

    __weak typeof(self) weakSelf = self;
    __block ExampleSettingsSheetView *sheet = nil;
    sheet = [[ExampleSettingsSheetView alloc] initWithTitle:[self localizedStringForKey:@"common_settings_sheet_title"]
                                                   sections:[self sectionsForState:self.editingState
                                                                            action:^{
        [weakSelf replacePolylineWithState:weakSelf.editingState recenter:YES];
        [sheet dismissAnimated:YES];
    }]];
    [sheet showInView:self.view animated:YES];
    if (normalizedDash) {
        [self showDirectionalArrowDashCompatibilityToast];
    }
}

- (NSArray<ExampleSettingsSection *> *)sectionsForState:(OverlayDirectionalArrowPolylineExampleFormState *)state
                                                 action:(dispatch_block_t)action {
    __weak OverlayDirectionalArrowPolylineExampleFormState *weakState = state;
    __weak typeof(self) weakSelf = self;
    void (^syncState)(void) = ^{
        [weakSelf syncEditingPolylineForState:weakState];
    };
    ExampleSettingsListGroup *colorGroup =
        [ExampleSettingsListGroup groupWithTitle:[self localizedStringForKey:@"overlay_colors"]
                                         options:[self colorTitles]
                                optionHexValues:[self colorHexValues]
                             initiallyCollapsed:NO];

    ExampleSettingsItem *directionalArrowTypeItem =
        [[ExampleSettingsItem listItemWithTitle:[self localizedStringForKey:@"overlay_arrow_style"]
                                        options:[self directionalArrowTypeTitles]
                                     popupSize:CGSizeMake(260.0, 180.0)
                                         getter:^NSInteger {
        return weakState.directionalArrowTypeIndex;
    } setter:^(NSInteger index) {
        weakState.directionalArrowTypeIndex = index;
        syncState();
    }] enabledWhen:^BOOL {
        return weakState.directionalArrowsEnabled;
    }];

    ExampleSettingsItem *directionalArrowColorItem =
        [[ExampleSettingsItem groupedListItemWithTitle:[self localizedStringForKey:@"overlay_arrow_color"]
                                                groups:@[colorGroup]
                                             popupSize:CGSizeMake(260.0, 300.0)
                                                getter:^NSInteger {
        return weakState.directionalArrowColorIndex;
    } setter:^(NSInteger index) {
        weakState.directionalArrowColorIndex = index;
        syncState();
    }] enabledWhen:^BOOL {
        return weakState.directionalArrowsEnabled;
    }];

    ExampleSettingsItem *directionalArrowDensityItem =
        [[ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"overlay_arrow_density"]
                                          minimum:1.0
                                          maximum:10.0
                                             step:1.0
                                           getter:^double {
        return weakState.directionalArrowDensity;
    } setter:^(double value) {
        weakState.directionalArrowDensity = value;
        syncState();
    } formatter:^NSString *(double value) {
        return [NSString stringWithFormat:@"%.0f", value];
    }] enabledWhen:^BOOL {
        return weakState.directionalArrowsEnabled;
    }];

    ExampleSettingsItem *dashItem =
        [[ExampleSettingsItem listItemWithTitle:[self localizedStringForKey:@"overlay_dash_pattern"]
                                        options:[self dashTitles]
                                     popupSize:CGSizeMake(260.0, 180.0)
                                         getter:^NSInteger {
        return weakState.dashIndex;
    } setter:^(NSInteger index) {
        if (weakState.directionalArrowsEnabled && index != 0) {
            weakState.dashIndex = 0;
            [weakSelf showDirectionalArrowDashCompatibilityToast];
        } else {
            weakState.dashIndex = index;
        }
        syncState();
    }] enabledWhen:^BOOL {
        return !weakState.directionalArrowsEnabled;
    }];

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
            dashItem,
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
        [ExampleSettingsSection sectionWithTitle:[self localizedStringForKey:@"overlay_directional_arrow"] items:@[
            [ExampleSettingsItem boolItemWithTitle:[self localizedStringForKey:@"overlay_directional_arrow"]
                                            getter:^BOOL {
                return weakState.directionalArrowsEnabled;
            } setter:^(BOOL value) {
                weakState.directionalArrowsEnabled = value;
                [weakSelf enforceDirectionalArrowDashCompatibilityForState:weakState showToast:YES];
                syncState();
            }],
            directionalArrowTypeItem,
            directionalArrowColorItem,
            directionalArrowDensityItem,
        ]],
        [ExampleSettingsSection sectionWithTitle:@"" items:@[
            [[ExampleSettingsItem actionItemWithTitle:[self localizedStringForKey:@"overlay_add_b58c75"] handler:action]
             withAccessibilityIdentifier:MTCExampleTestAccessibilityLineButtonDraw],
        ]],
    ];
}

#pragma mark - Polyline

- (void)addDirectionalArrowPolyline {
    [self addDirectionalArrowPolylineWithState:self.state];
}

- (void)addDirectionalArrowPolylineWithState:(OverlayDirectionalArrowPolylineExampleFormState *)state {
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

- (void)replacePolylineWithState:(OverlayDirectionalArrowPolylineExampleFormState *)state
                          recenter:(BOOL)recenter {
    if (!state) {
        return;
    }

    NSData *coordinateData = [self coordinateDataForState:state];
    [self removeDirectionalArrowPolyline];
    [self addDirectionalArrowPolylineWithState:state];
    if (recenter && self.polyline) {
        [self focusCoordinateData:coordinateData animated:YES];
    }
}

- (void)removeDirectionalArrowPolyline {
    if (self.polyline) {
        [self.mapView removeOverlay:self.polyline];
    }
    self.polyline = nil;
    self.editingPolyline = nil;
    [self.mapTestSupport syncOverlayCount:0];
}

- (void)updatePolylineWithState:(OverlayDirectionalArrowPolylineExampleFormState *)state {
    if (!self.polyline || !state) {
        return;
    }

    [self.mapView performOverlayUpdates:^{
        [self applyState:state toPolyline:self.polyline updateCoordinates:YES];
    }];
    self.state = [state copy];
}

- (void)syncEditingPolylineForState:(OverlayDirectionalArrowPolylineExampleFormState *)state {
    MTCPolyline *editingPolyline = self.editingPolyline;
    if (!editingPolyline || editingPolyline != self.polyline || !state) {
        return;
    }

    [self updatePolylineWithState:state];
}

- (void)applyState:(OverlayDirectionalArrowPolylineExampleFormState *)state
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

- (OverlayDirectionalArrowPolylineExampleFormState *)defaultPolylineState {
    OverlayDirectionalArrowPolylineExampleFormState *state = [[OverlayDirectionalArrowPolylineExampleFormState alloc] init];
    state.routeIndex = 0;
    state.strokeColorIndex = 0;
    state.strokeWeight = 18.0;
    state.strokeOpacity = 1.0;
    state.dashIndex = 0;
    state.closed = NO;
    state.draggable = NO;
    state.directionalArrowsEnabled = YES;
    state.directionalArrowTypeIndex = 0;
    state.directionalArrowColorIndex = 5;
    state.directionalArrowDensity = 1.0;
    return state;
}

- (OverlayDirectionalArrowPolylineExampleFormState *)stateFromPolyline:(MTCPolyline *)polyline {
    OverlayDirectionalArrowPolylineExampleFormState *state = self.state ? [self.state copy] : [self defaultPolylineState];
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
    state.directionalArrowsEnabled = polyline.style.directionalArrowStyle.enabled;
    state.directionalArrowTypeIndex = [self indexForDirectionalArrowType:polyline.style.directionalArrowStyle.type
                                                            fallbackIndex:state.directionalArrowTypeIndex];
    state.directionalArrowColorIndex = [self indexForColor:polyline.style.directionalArrowStyle.color
                                             fallbackIndex:state.directionalArrowColorIndex];
    state.directionalArrowDensity = polyline.style.directionalArrowStyle.spacingMultiplier;
    return state;
}

- (MTCPolylineStyle *)styleForState:(OverlayDirectionalArrowPolylineExampleFormState *)state {
    MTCPolylineStyle *style = [[MTCPolylineStyle alloc] init];
    style.strokeColor = [self colorForIndex:state.strokeColorIndex];
    style.strokeWeight = state.strokeWeight;
    style.strokeOpacity = state.strokeOpacity;
    style.strokeDashArray = state.directionalArrowsEnabled ? @[] : [self dashArrayForIndex:state.dashIndex];
    style.directionalArrowStyle.enabled = state.directionalArrowsEnabled;
    style.directionalArrowStyle.type = [self directionalArrowTypeForIndex:state.directionalArrowTypeIndex];
    style.directionalArrowStyle.color = [self colorForIndex:state.directionalArrowColorIndex];
    style.directionalArrowStyle.spacingMultiplier = state.directionalArrowDensity;
    return style;
}

#pragma mark - Coordinates

- (CLLocationCoordinate2D)singaporeCoordinate {
    return CLLocationCoordinate2DMake(OverlayDirectionalArrowPolylineExampleSingaporeLatitude,
                                      OverlayDirectionalArrowPolylineExampleSingaporeLongitude);
}

- (NSArray<NSString *> *)routeTitles {
    return @[[self localizedStringForKey:@"overlay_route_a_4_points"], [self localizedStringForKey:@"overlay_route_b_6_points"], [self localizedStringForKey:@"overlay_short_route_3_points"], [self localizedStringForKey:@"overlay_polyline_c_5_points"]];
}

- (NSData *)coordinateDataForState:(OverlayDirectionalArrowPolylineExampleFormState *)state {
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
        [self.mapView setCenterCoordinate:center zoomLevel:OverlayDirectionalArrowPolylineExampleDefaultZoomLevel];
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

- (NSArray<NSString *> *)directionalArrowTypeTitles {
    return @[@"Classic", @"Triangle", @"Chevron"];
}

- (MTCLineDirectionalArrowType)directionalArrowTypeForIndex:(NSInteger)index {
    switch (index) {
        case 1:
            return MTCLineDirectionalArrowTypeTriangle;
        case 2:
            return MTCLineDirectionalArrowTypeChevron;
        default:
            return MTCLineDirectionalArrowTypeClassic;
    }
}

- (NSInteger)indexForDirectionalArrowType:(MTCLineDirectionalArrowType)type
                            fallbackIndex:(NSInteger)fallbackIndex {
    switch (type) {
        case MTCLineDirectionalArrowTypeClassic:
            return 0;
        case MTCLineDirectionalArrowTypeTriangle:
            return 1;
        case MTCLineDirectionalArrowTypeChevron:
            return 2;
        default:
            return fallbackIndex;
    }
}

#pragma mark - Compatibility

- (BOOL)enforceDirectionalArrowDashCompatibilityForState:(OverlayDirectionalArrowPolylineExampleFormState *)state
                                               showToast:(BOOL)showToast {
    if (!state.directionalArrowsEnabled || state.dashIndex == 0) {
        return NO;
    }

    state.dashIndex = 0;
    if (showToast) {
        [self showDirectionalArrowDashCompatibilityToast];
    }
    return YES;
}

- (void)showDirectionalArrowDashCompatibilityToast {
    [MTCExampleToastView showMessage:[self localizedStringForKey:@"overlay_directional_arrow_polyline_supports_solid_only_s"] inView:self.view];
}

#pragma mark -- multi-language

- (void)handleExampleSettingsAction {
    [self showSettingsSheet];
}

- (void)demoLanguageDidChange {
    [self applyLocalizedTexts];
}

- (void)applyLocalizedTexts {
    self.title = [self localizedStringForKey:@"demo_title_OverlayDirectionalArrowPolylineExampleViewController"];
    if (self.mapView) {
        self.mapView.mapLanguage = [self mapLanguageForDemoLanguage:self.demoLanguage];
    }
    if ([self isSettingsSheetVisible:ExampleSettingsSheetView.class]) {
        [self showSettingsSheet];
    }
}
@end
