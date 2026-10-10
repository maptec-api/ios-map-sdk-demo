#import "OverlayBasicPolylineExampleViewController.h"

#import "ExampleSettingsSheetView.h"
#import "MTCExampleMapTestSupport.h"
#import "MTCExampleTestAccessibility.h"

#import <MaptecMapsKit/MaptecMapsKit.h>

#include <math.h>

static CLLocationDegrees const OverlayBasicPolylineExampleSingaporeLatitude = 1.3048264556208515;
static CLLocationDegrees const OverlayBasicPolylineExampleSingaporeLongitude = 103.83052199958921;
static double const OverlayBasicPolylineExampleDefaultZoomLevel = 13.0;
static double const OverlayBasicPolylineExampleDefaultMiterLimit = 2.0;

typedef NS_ENUM(NSInteger, OverlayBasicPolylineExampleLineJoinOption) {
    OverlayBasicPolylineExampleLineJoinOptionMiter = 0,
    OverlayBasicPolylineExampleLineJoinOptionRound,
    OverlayBasicPolylineExampleLineJoinOptionBevel,
};

@interface OverlayBasicPolylineExampleFormState : NSObject <NSCopying>
@property (nonatomic) NSInteger routeIndex;
@property (nonatomic) NSInteger strokeColorIndex;
@property (nonatomic) double strokeWeight;
@property (nonatomic) double strokeOpacity;
@property (nonatomic) NSInteger dashIndex;
@property (nonatomic) NSInteger lineJoinTypeIndex;
@property (nonatomic) double miterLimit;
@property (nonatomic) BOOL closed;
@property (nonatomic) BOOL draggable;
@property (nonatomic, copy, nullable) NSData *coordinateData;
@end

@implementation OverlayBasicPolylineExampleFormState

- (id)copyWithZone:(NSZone *)zone {
    OverlayBasicPolylineExampleFormState *state = [[[self class] allocWithZone:zone] init];
    state.routeIndex = self.routeIndex;
    state.strokeColorIndex = self.strokeColorIndex;
    state.strokeWeight = self.strokeWeight;
    state.strokeOpacity = self.strokeOpacity;
    state.dashIndex = self.dashIndex;
    state.lineJoinTypeIndex = self.lineJoinTypeIndex;
    state.miterLimit = self.miterLimit;
    state.closed = self.closed;
    state.draggable = self.draggable;
    state.coordinateData = self.coordinateData;
    return state;
}

@end

@interface OverlayBasicPolylineExampleViewController () <MTCMapViewDelegate>
@property (nonatomic, strong) MTCMapView *mapView;
@property (nonatomic, strong) NSMutableArray<MTCPolyline *> *polylines;
@property (nonatomic, strong) NSMapTable<MTCPolyline *, OverlayBasicPolylineExampleFormState *> *polylineBaseStates;
@property (nonatomic, strong) OverlayBasicPolylineExampleFormState *addState;
@property (nonatomic, weak, nullable) MTCPolyline *editingPolyline;
@property (nonatomic, strong) MTCExampleMapTestSupport *mapTestSupport;
@end

@implementation OverlayBasicPolylineExampleViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = UIColor.whiteColor;
    self.view.accessibilityIdentifier = MTCExampleTestAccessibilityOverlayBasicPolylineScreen;
    self.polylines = [NSMutableArray array];
    self.polylineBaseStates = [NSMapTable weakToStrongObjectsMapTable];
    self.addState = [self defaultPolylineState];

    [self configureNavigationItems:NO];
    [self configureMapView];
    [self addPolylineWithState:self.addState recenter:NO];
    [self.mapView setCenterCoordinate:[self singaporeCoordinate]
                             zoomLevel:OverlayBasicPolylineExampleDefaultZoomLevel];
    [self applyLocalizedTexts];
}

#pragma mark - Setup

- (void)configureMapView {
    self.mapView = [[MTCMapView alloc] initWithFrame:self.view.bounds];
    self.mapView.delegate = self;
    self.mapView.uiSettings.zoomLevelVisible = YES;
    self.mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.mapView];

    self.mapTestSupport = [[MTCExampleMapTestSupport alloc] init];
    self.mapTestSupport.overlayCountValueKey = MTCExampleTestAccessibilityLineCountValueKey;
    self.mapTestSupport.overlayPresenceIdentifier = MTCExampleTestAccessibilityLineHasLines;
    [self.mapTestSupport installOnHostView:self.view];
    [self syncPolylineTestAccessibilityState];
}

#pragma mark - Sheets

- (void)showAddPolylineSheet {
    MTCPolyline *currentPolyline = [self currentPolyline];
    self.editingPolyline = currentPolyline;
    self.addState = currentPolyline ? [self stateFromPolyline:currentPolyline] : [self defaultPolylineState];

    __weak typeof(self) weakSelf = self;
    __block ExampleSettingsSheetView *sheet = nil;
    sheet = [[ExampleSettingsSheetView alloc] initWithTitle:[self localizedStringForKey:@"common_settings_sheet_title"]
                                                   sections:[self sectionsForState:self.addState
                                                                       actionTitle:[self localizedStringForKey:@"overlay_add_b58c75"]
                                                                            action:^{
        [weakSelf replacePolylinesWithState:weakSelf.addState recenter:YES];
        [sheet dismissAnimated:YES];
    }]];
    [sheet showInView:self.view animated:YES];
}

- (NSArray<ExampleSettingsSection *> *)sectionsForState:(OverlayBasicPolylineExampleFormState *)state
                                            actionTitle:(NSString *)actionTitle
                                                 action:(dispatch_block_t)action {
    __weak OverlayBasicPolylineExampleFormState *weakState = state;
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
                                               popupSize:CGSizeMake(260.0, 280.0)
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
        [ExampleSettingsSection sectionWithTitle:[self localizedStringForKey:@"overlay_basic_polyline_join"] items:@[
            [ExampleSettingsItem listItemWithTitle:[self localizedStringForKey:@"overlay_basic_polyline_join_style"]
                                           options:[self lineJoinTitles]
                                        popupSize:CGSizeMake(260.0, 220.0)
                                            getter:^NSInteger {
                return weakState.lineJoinTypeIndex;
            } setter:^(NSInteger index) {
                weakState.lineJoinTypeIndex = index;
                syncState();
            }],
            [[ExampleSettingsItem textItemWithTitle:[self localizedStringForKey:@"overlay_basic_polyline_miter_limit"]
                                        placeholder:@"2.0"
                                       keyboardType:UIKeyboardTypeNumbersAndPunctuation
                                             getter:^NSString *{
                return [weakSelf miterLimitTextForState:weakState];
            } setter:^(NSString *value) {
                [weakSelf updateMiterLimitWithText:value state:weakState];
                syncState();
            }] visibleWhen:^BOOL {
                return weakState.lineJoinTypeIndex == OverlayBasicPolylineExampleLineJoinOptionMiter;
            }],
        ]],
        [ExampleSettingsSection sectionWithTitle:@"" items:@[
            [[ExampleSettingsItem actionItemWithTitle:actionTitle handler:action]
                withAccessibilityIdentifier:MTCExampleTestAccessibilityLineButtonDraw],
        ]],
    ];
}

#pragma mark - Polyline

- (void)addPolylineWithState:(OverlayBasicPolylineExampleFormState *)state
                     recenter:(BOOL)recenter {
    if (!state) {
        return;
    }

    NSData *coordinateData = [self coordinateDataForState:state];
    NSUInteger coordinateCount = [self coordinateCountForData:coordinateData];
    if (coordinateCount == 0) {
        return;
    }

    MTCPolyline *polyline = [[MTCPolyline alloc] initWithCoordinates:(const CLLocationCoordinate2D *)coordinateData.bytes
                                                               count:coordinateCount];
    [self applyState:state toPolyline:polyline updateCoordinates:NO];
    [self.polylines addObject:polyline];
    self.addState = [state copy];
    self.editingPolyline = polyline;
    [self.mapView addOverlay:polyline];

    if (recenter) {
        [self focusCoordinateData:coordinateData animated:YES];
    }
    [self syncPolylineTestAccessibilityState];
}

- (MTCPolyline *)currentPolyline {
    return self.polylines.lastObject;
}

- (void)replacePolylinesWithState:(OverlayBasicPolylineExampleFormState *)state
                          recenter:(BOOL)recenter {
    if (!state) {
        return;
    }

    [self clearPolylines];
    [self addPolylineWithState:state recenter:recenter];
}

- (void)updatePolyline:(MTCPolyline *)polyline
             withState:(OverlayBasicPolylineExampleFormState *)state {
    if (!polyline || !state) {
        return;
    }

    [self.mapView performOverlayUpdates:^{
        [self applyState:state toPolyline:polyline updateCoordinates:YES];
    }];
}

- (void)syncEditingPolylineForState:(OverlayBasicPolylineExampleFormState *)state {
    MTCPolyline *editingPolyline = self.editingPolyline;
    if (!editingPolyline || ![self.polylines containsObject:editingPolyline] || !state) {
        return;
    }

    [self updatePolyline:editingPolyline withState:state];
}

- (void)clearPolylines {
    if (self.polylines.count > 0) {
        [self.mapView removeOverlays:self.polylines];
    }
    [self.polylines removeAllObjects];
    [self.polylineBaseStates removeAllObjects];
    self.editingPolyline = nil;
    [self syncPolylineTestAccessibilityState];
}

- (void)syncPolylineTestAccessibilityState {
    [self.mapTestSupport syncOverlayCount:self.polylines.count];
}

#pragma mark - MTCMapViewDelegate

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

- (void)applyState:(OverlayBasicPolylineExampleFormState *)state
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
    [self.polylineBaseStates setObject:[state copy] forKey:polyline];
}

- (OverlayBasicPolylineExampleFormState *)defaultPolylineState {
    OverlayBasicPolylineExampleFormState *state = [[OverlayBasicPolylineExampleFormState alloc] init];
    state.routeIndex = 0;
    state.strokeColorIndex = 0;
    state.strokeWeight = 5.0;
    state.strokeOpacity = 1.0;
    state.dashIndex = 0;
    state.lineJoinTypeIndex = OverlayBasicPolylineExampleLineJoinOptionMiter;
    state.miterLimit = OverlayBasicPolylineExampleDefaultMiterLimit;
    state.closed = NO;
    state.draggable = NO;
    return state;
}

- (OverlayBasicPolylineExampleFormState *)stateFromPolyline:(MTCPolyline *)polyline {
    OverlayBasicPolylineExampleFormState *baseState = [self.polylineBaseStates objectForKey:polyline];
    OverlayBasicPolylineExampleFormState *state = baseState ? [baseState copy] : [self defaultPolylineState];
    state.coordinateData = [self coordinateDataFromPolyline:polyline];
    state.strokeWeight = polyline.style.strokeWeight;
    state.strokeOpacity = polyline.style.strokeOpacity;
    state.strokeColorIndex = [self indexForColor:polyline.style.strokeColor fallbackIndex:state.strokeColorIndex];
    state.dashIndex = [self indexForDashArray:polyline.style.strokeDashArray fallbackIndex:state.dashIndex];
    state.lineJoinTypeIndex = [self indexForLineJoinType:polyline.style.lineJoinType
                                            fallbackIndex:state.lineJoinTypeIndex];
    state.miterLimit = polyline.style.miterLimit;
    state.closed = polyline.isClosed;
    state.draggable = polyline.isDraggable;
    return state;
}

- (MTCPolylineStyle *)styleForState:(OverlayBasicPolylineExampleFormState *)state {
    MTCPolylineStyle *style = [[MTCPolylineStyle alloc] init];
    style.strokeColor = [self colorForIndex:state.strokeColorIndex];
    style.strokeWeight = state.strokeWeight;
    style.strokeOpacity = state.strokeOpacity;
    style.strokeDashArray = [self dashArrayForIndex:state.dashIndex];
    style.lineJoinType = [self engineLineJoinTypeForIndex:state.lineJoinTypeIndex];
    style.miterLimit = state.miterLimit;
    return style;
}

#pragma mark - Coordinates

- (CLLocationCoordinate2D)singaporeCoordinate {
    return CLLocationCoordinate2DMake(OverlayBasicPolylineExampleSingaporeLatitude,
                                      OverlayBasicPolylineExampleSingaporeLongitude);
}

- (NSArray<NSString *> *)routeTitles {
    return @[[self localizedStringForKey:@"overlay_route_a_4_points"], [self localizedStringForKey:@"overlay_route_b_6_points"], [self localizedStringForKey:@"overlay_short_route_3_points"], [self localizedStringForKey:@"overlay_polyline_c_5_points"]];
}

- (NSData *)coordinateDataForState:(OverlayBasicPolylineExampleFormState *)state {
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
        [self.mapView setCenterCoordinate:center zoomLevel:OverlayBasicPolylineExampleDefaultZoomLevel];
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

- (NSArray<NSString *> *)lineJoinTitles {
    return @[@"Miter", @"Round", @"Bevel"];
}

- (NSString *)miterLimitTextForState:(OverlayBasicPolylineExampleFormState *)state {
    return [NSString stringWithFormat:@"%.2f", state.miterLimit];
}

- (void)updateMiterLimitWithText:(NSString *)text
                           state:(OverlayBasicPolylineExampleFormState *)state {
    NSString *trimmedText = [text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (trimmedText.length == 0) {
        return;
    }

    NSScanner *scanner = [NSScanner scannerWithString:trimmedText];
    double value = 0.0;
    if (![scanner scanDouble:&value] || !scanner.isAtEnd) {
        return;
    }
    state.miterLimit = MAX(0.0, value);
}

- (MTCLineJoinType)engineLineJoinTypeForIndex:(NSInteger)index {
    switch (index) {
        case OverlayBasicPolylineExampleLineJoinOptionRound:
            return MTCLineJoinTypeRound;
        case OverlayBasicPolylineExampleLineJoinOptionBevel:
            return MTCLineJoinTypeBevel;
        case OverlayBasicPolylineExampleLineJoinOptionMiter:
        default:
            return MTCLineJoinTypeMiter;
    }
}

- (NSInteger)indexForLineJoinType:(MTCLineJoinType)lineJoinType
                    fallbackIndex:(NSInteger)fallbackIndex {
    switch (lineJoinType) {
        case MTCLineJoinTypeMiter:
            return OverlayBasicPolylineExampleLineJoinOptionMiter;
        case MTCLineJoinTypeRound:
            return OverlayBasicPolylineExampleLineJoinOptionRound;
        case MTCLineJoinTypeBevel:
            return OverlayBasicPolylineExampleLineJoinOptionBevel;
        default:
            return fallbackIndex;
    }
}

#pragma mark -- multi-language

- (void)handleExampleSettingsAction {
    [self showAddPolylineSheet];
}

- (void)demoLanguageDidChange {
    [self applyLocalizedTexts];
}

- (void)applyLocalizedTexts {
    self.title = [self localizedStringForKey:@"demo_title_OverlayBasicPolylineExampleViewController"];
    if (self.mapView) {
        self.mapView.mapLanguage = [self mapLanguageForDemoLanguage:self.demoLanguage];
    }
    if ([self isSettingsSheetVisible:ExampleSettingsSheetView.class]) {
        [self showAddPolylineSheet];
    }
}
@end
