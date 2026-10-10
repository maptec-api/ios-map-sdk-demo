#import "OverlayInteractivePolygonExampleViewController.h"

#import "ExampleSettingsSheetView.h"
#import "MTCExampleMapTestSupport.h"
#import "MTCExampleTestAccessibility.h"
#import "MTCExampleToastView.h"

#import <MaptecMapsKit/MaptecMapsKit.h>

#include <math.h>

static CLLocationDegrees const OverlayInteractivePolygonExampleSingaporeLatitude = 1.3048264556208515;
static CLLocationDegrees const OverlayInteractivePolygonExampleSingaporeLongitude = 103.83052199958921;
static double const OverlayInteractivePolygonExampleDefaultZoomLevel = 13.0;

@interface OverlayInteractivePolygonExampleState : NSObject <NSCopying>
@property (nonatomic) NSInteger polygonIndex;
@property (nonatomic) NSInteger fillColorIndex;
@property (nonatomic) double fillOpacity;
@property (nonatomic) NSInteger strokeColorIndex;
@property (nonatomic) double strokeWeight;
@property (nonatomic) double strokeOpacity;
@property (nonatomic) NSInteger dashIndex;
@property (nonatomic) BOOL fillAntialias;
@property (nonatomic) BOOL draggable;
@property (nonatomic) NSInteger blendModeIndex;
@property (nonatomic, copy, nullable) NSData *coordinateData;
@end

@implementation OverlayInteractivePolygonExampleState

- (id)copyWithZone:(NSZone *)zone {
    OverlayInteractivePolygonExampleState *state = [[[self class] allocWithZone:zone] init];
    state.polygonIndex = self.polygonIndex;
    state.fillColorIndex = self.fillColorIndex;
    state.fillOpacity = self.fillOpacity;
    state.strokeColorIndex = self.strokeColorIndex;
    state.strokeWeight = self.strokeWeight;
    state.strokeOpacity = self.strokeOpacity;
    state.dashIndex = self.dashIndex;
    state.fillAntialias = self.fillAntialias;
    state.draggable = self.draggable;
    state.blendModeIndex = self.blendModeIndex;
    state.coordinateData = self.coordinateData;
    return state;
}

@end

@interface OverlayInteractivePolygonExampleViewController () <MTCMapViewDelegate>
@property (nonatomic, strong) MTCMapView *mapView;
@property (nonatomic, strong, nullable) MTCPolygon *polygon;
@property (nonatomic, strong) OverlayInteractivePolygonExampleState *currentState;
@property (nonatomic, strong, nullable) OverlayInteractivePolygonExampleState *editingState;
@property (nonatomic, weak, nullable) MTCPolygon *editingPolygon;
@property (nonatomic, strong) MTCExampleMapTestSupport *mapTestSupport;
@end

@implementation OverlayInteractivePolygonExampleViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = UIColor.whiteColor;
    self.view.accessibilityIdentifier = @"OverlayInteractivePolygonExampleViewController.screen";
    self.currentState = [self defaultState];

    [self configureNavigationItems:NO];
    [self configureMapView];
    [self addPolygonWithState:self.currentState];
    [self.mapView setCenterCoordinate:[self singaporeCoordinate]
                             zoomLevel:OverlayInteractivePolygonExampleDefaultZoomLevel];
    [self applyLocalizedTexts];
}

#pragma mark - Setup

- (void)configureMapView {
    self.mapTestSupport = [[MTCExampleMapTestSupport alloc] init];
    self.mapTestSupport.overlayCountValueKey = MTCExampleTestAccessibilityFillCountValueKey;
    self.mapTestSupport.overlayPresenceIdentifier = MTCExampleTestAccessibilityFillHasFills;
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
    MTCPolygon *currentPolygon = [self currentPolygon];
    self.editingPolygon = currentPolygon;
    self.editingState = currentPolygon ? [self stateFromPolygon:currentPolygon] : [self defaultState];

    __weak typeof(self) weakSelf = self;
    __block ExampleSettingsSheetView *sheet = nil;
    sheet = [[ExampleSettingsSheetView alloc] initWithTitle:[self localizedStringForKey:@"common_settings_sheet_title"]
                                                   sections:[self sectionsForState:self.editingState
                                                                            action:^{
        [weakSelf replacePolygonWithState:weakSelf.editingState recenter:YES];
        [sheet dismissAnimated:YES];
    }]];
    [sheet showInView:self.view animated:YES];
}

- (NSArray<ExampleSettingsSection *> *)sectionsForState:(OverlayInteractivePolygonExampleState *)state
                                                 action:(dispatch_block_t)action {
    __weak OverlayInteractivePolygonExampleState *weakState = state;
    __weak typeof(self) weakSelf = self;
    void (^syncState)(void) = ^{
        [weakSelf syncEditingPolygonForState:weakState];
    };
    ExampleSettingsListGroup *colorGroup =
        [ExampleSettingsListGroup groupWithTitle:[self localizedStringForKey:@"overlay_colors"]
                                         options:[self colorTitles]
                                  optionHexValues:[self colorHexValues]
                               initiallyCollapsed:NO];

    return @[
        [ExampleSettingsSection sectionWithTitle:[self localizedStringForKey:@"overlay_geometry"] items:@[
            [ExampleSettingsItem listItemWithTitle:[self localizedStringForKey:@"overlay_vertices"]
                                           options:[self polygonTitles]
                                        popupSize:CGSizeMake(260.0, 220.0)
                                            getter:^NSInteger {
                return weakState.polygonIndex;
            } setter:^(NSInteger index) {
                weakState.polygonIndex = index;
                weakState.coordinateData = nil;
                syncState();
            }],
        ]],
        [ExampleSettingsSection sectionWithTitle:[self localizedStringForKey:@"overlay_fill"] items:@[
            [ExampleSettingsItem groupedListItemWithTitle:[self localizedStringForKey:@"overlay_fill_color"]
                                                   groups:@[colorGroup]
                                               popupSize:CGSizeMake(260.0, 280.0)
                                                  getter:^NSInteger {
                return weakState.fillColorIndex;
            } setter:^(NSInteger index) {
                weakState.fillColorIndex = index;
                syncState();
            }],
            [ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"overlay_fill_opacity"]
                                             minimum:0.0
                                             maximum:1.0
                                                step:0.05
                                              getter:^double {
                return weakState.fillOpacity;
            } setter:^(double value) {
                weakState.fillOpacity = value;
                syncState();
            } formatter:^NSString *(double value) {
                return [NSString stringWithFormat:@"%.2f", value];
            }],
        ]],
        [ExampleSettingsSection sectionWithTitle:[self localizedStringForKey:@"overlay_stroke"] items:@[
            [ExampleSettingsItem groupedListItemWithTitle:[self localizedStringForKey:@"overlay_stroke_color"]
                                                   groups:@[colorGroup]
                                               popupSize:CGSizeMake(260.0, 280.0)
                                                  getter:^NSInteger {
                return weakState.strokeColorIndex;
            } setter:^(NSInteger index) {
                weakState.strokeColorIndex = index;
                syncState();
            }],
            [ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"overlay_border_width"]
                                             minimum:0.0
                                             maximum:20.0
                                                step:1.0
                                              getter:^double {
                return weakState.strokeWeight;
            } setter:^(double value) {
                weakState.strokeWeight = value;
                syncState();
            } formatter:^NSString *(double value) {
                return [NSString stringWithFormat:@"%.0f", value];
            }],
            [ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"overlay_stroke_opacity"]
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
        [ExampleSettingsSection sectionWithTitle:[self localizedStringForKey:@"overlay_interaction"] items:@[
            [ExampleSettingsItem boolItemWithTitle:[self localizedStringForKey:@"overlay_fill_anti_aliasing"]
                                            getter:^BOOL {
                return weakState.fillAntialias;
            } setter:^(BOOL value) {
                weakState.fillAntialias = value;
                syncState();
            }],
            [[ExampleSettingsItem boolItemWithTitle:[self localizedStringForKey:@"overlay_draggable_69a79a"]
                                             getter:^BOOL {
                return weakState.draggable;
            } setter:^(BOOL value) {
                weakState.draggable = value;
                syncState();
            }] withAccessibilityIdentifier:MTCExampleTestAccessibilityFillSwitchDraggable],
            [ExampleSettingsItem listItemWithTitle:[self localizedStringForKey:@"overlay_blend_mode"]
                                           options:[self blendModeTitles]
                                        popupSize:CGSizeMake(260.0, 220.0)
                                            getter:^NSInteger {
                return weakState.blendModeIndex;
            } setter:^(NSInteger index) {
                weakState.blendModeIndex = index;
                syncState();
            }],
        ]],
        [ExampleSettingsSection sectionWithTitle:@"" items:@[
            [[ExampleSettingsItem actionItemWithTitle:[self localizedStringForKey:@"overlay_add_b58c75"] handler:action]
             withAccessibilityIdentifier:MTCExampleTestAccessibilityFillDrawButton],
        ]],
    ];
}

#pragma mark - Polygon

- (void)addPolygonWithState:(OverlayInteractivePolygonExampleState *)state {
    if (!state) {
        return;
    }

    NSData *coordinateData = [self coordinateDataForState:state];
    NSUInteger coordinateCount = [self coordinateCountForData:coordinateData];
    if (coordinateCount < 3) {
        return;
    }

    self.polygon = [[MTCPolygon alloc] initWithCoordinates:(const CLLocationCoordinate2D *)coordinateData.bytes
                                                     count:coordinateCount];
    [self applyState:state toPolygon:self.polygon updateCoordinates:NO];
    [self.mapView addOverlay:self.polygon];
    [self.mapTestSupport syncOverlayCount:1];
    self.currentState = [state copy];
    self.editingPolygon = self.polygon;
}

- (MTCPolygon *)currentPolygon {
    return self.polygon;
}

- (void)replacePolygonWithState:(OverlayInteractivePolygonExampleState *)state
                       recenter:(BOOL)recenter {
    if (!state) {
        return;
    }

    NSData *coordinateData = [self coordinateDataForState:state];
    [self removePolygon];
    [self addPolygonWithState:state];
    if (recenter && self.polygon) {
        [self focusCoordinateData:coordinateData animated:YES];
    }
}

- (void)removePolygon {
    if (self.polygon) {
        [self.mapView removeOverlay:self.polygon];
    }
    self.polygon = nil;
    self.editingPolygon = nil;
    self.editingState = nil;
    [self.mapTestSupport syncOverlayCount:0];
}

- (void)updatePolygonWithState:(OverlayInteractivePolygonExampleState *)state {
    if (!state || !self.polygon) {
        return;
    }

    [self.mapView performOverlayUpdates:^{
        [self applyState:state toPolygon:self.polygon updateCoordinates:YES];
    }];
    self.currentState = [state copy];
}

- (void)syncEditingPolygonForState:(OverlayInteractivePolygonExampleState *)state {
    MTCPolygon *editingPolygon = self.editingPolygon;
    if (!editingPolygon || editingPolygon != self.polygon || !state) {
        return;
    }

    [self updatePolygonWithState:state];
}

- (void)applyState:(OverlayInteractivePolygonExampleState *)state
         toPolygon:(MTCPolygon *)polygon
  updateCoordinates:(BOOL)updateCoordinates {
    if (updateCoordinates) {
        NSData *coordinateData = [self coordinateDataForState:state];
        [polygon setCoordinates:(const CLLocationCoordinate2D *)coordinateData.bytes
                          count:[self coordinateCountForData:coordinateData]];
    }

    polygon.clickable = YES;
    polygon.draggable = state.draggable;
    polygon.style = [self styleForState:state];
}

- (OverlayInteractivePolygonExampleState *)defaultState {
    OverlayInteractivePolygonExampleState *state = [[OverlayInteractivePolygonExampleState alloc] init];
    state.polygonIndex = 0;
    state.fillColorIndex = 0;
    state.fillOpacity = 0.28;
    state.strokeColorIndex = 1;
    state.strokeWeight = 3.0;
    state.strokeOpacity = 0.9;
    state.dashIndex = 0;
    state.fillAntialias = YES;
    state.draggable = YES;
    state.blendModeIndex = 1;
    return state;
}

- (OverlayInteractivePolygonExampleState *)stateFromPolygon:(MTCPolygon *)polygon {
    OverlayInteractivePolygonExampleState *state = self.currentState ? [self.currentState copy] : [self defaultState];
    if (!polygon) {
        return state;
    }

    state.coordinateData = [self coordinateDataFromPolygon:polygon];
    state.fillColorIndex = [self indexForColor:polygon.style.fillColor fallbackIndex:state.fillColorIndex];
    state.fillOpacity = polygon.style.fillOpacity;
    state.strokeColorIndex = [self indexForColor:polygon.style.strokeColor fallbackIndex:state.strokeColorIndex];
    state.strokeWeight = polygon.style.strokeWeight;
    state.strokeOpacity = polygon.style.strokeOpacity;
    state.dashIndex = [self indexForDashArray:polygon.style.strokeDashArray fallbackIndex:state.dashIndex];
    state.fillAntialias = polygon.style.isFillAntialias;
    state.draggable = polygon.isDraggable;
    state.blendModeIndex = [self indexForBlendMode:polygon.style.blendMode fallbackIndex:state.blendModeIndex];
    return state;
}

- (MTCPolygonStyle *)styleForState:(OverlayInteractivePolygonExampleState *)state {
    MTCPolygonStyle *style = [[MTCPolygonStyle alloc] init];
    style.fillColor = [self colorForIndex:state.fillColorIndex];
    style.fillOpacity = state.fillOpacity;
    style.fillPatternType = MTCPolygonFillPatternTypeSolid;
    style.fillAntialias = state.fillAntialias;
    style.strokeColor = [self colorForIndex:state.strokeColorIndex];
    style.strokeWeight = state.strokeWeight;
    style.strokeOpacity = state.strokeOpacity;
    style.strokeDashArray = [self dashArrayForIndex:state.dashIndex];
    style.blendMode = [self blendModeForIndex:state.blendModeIndex];
    return style;
}

#pragma mark - Coordinates

- (CLLocationCoordinate2D)singaporeCoordinate {
    return CLLocationCoordinate2DMake(OverlayInteractivePolygonExampleSingaporeLatitude,
                                      OverlayInteractivePolygonExampleSingaporeLongitude);
}

- (NSArray<NSString *> *)polygonTitles {
    return @[[self localizedStringForKey:@"overlay_area_a_4_points"], [self localizedStringForKey:@"overlay_area_b_5_points"], [self localizedStringForKey:@"overlay_triangle_area_3_points"], [self localizedStringForKey:@"overlay_area_c_6_points"]];
}

- (NSData *)coordinateDataForState:(OverlayInteractivePolygonExampleState *)state {
    if (state.coordinateData.length > 0) {
        return state.coordinateData;
    }
    return [self coordinateDataForPolygonIndex:state.polygonIndex];
}

- (NSData *)coordinateDataFromPolygon:(MTCPolygon *)polygon {
    NSUInteger count = polygon.outerRingCoordinateCount;
    NSMutableData *data = [NSMutableData dataWithLength:count * sizeof(CLLocationCoordinate2D)];
    if (count > 0) {
        [polygon getOuterRingCoordinates:(CLLocationCoordinate2D *)data.mutableBytes
                                   range:NSMakeRange(0, count)];
    }
    return data;
}

- (NSData *)coordinateDataForPolygonIndex:(NSInteger)polygonIndex {
    NSUInteger count = [self coordinateCountForPolygonIndex:polygonIndex];
    NSMutableData *data = [NSMutableData dataWithLength:count * sizeof(CLLocationCoordinate2D)];
    CLLocationCoordinate2D *coordinates = (CLLocationCoordinate2D *)data.mutableBytes;
    for (NSUInteger index = 0; index < count; ++index) {
        coordinates[index] = [self coordinateForPolygonIndex:polygonIndex pointIndex:index];
    }
    return data;
}

- (NSUInteger)coordinateCountForData:(NSData *)coordinateData {
    return coordinateData.length / sizeof(CLLocationCoordinate2D);
}

- (NSUInteger)coordinateCountForPolygonIndex:(NSInteger)polygonIndex {
    switch (polygonIndex) {
        case 1:
            return 5;
        case 2:
            return 3;
        case 3:
            return 6;
        default:
            return 4;
    }
}

- (CLLocationCoordinate2D)coordinateForPolygonIndex:(NSInteger)polygonIndex
                                        pointIndex:(NSUInteger)pointIndex {
    switch (polygonIndex) {
        case 1:
            switch (pointIndex) {
                case 0:
                    return CLLocationCoordinate2DMake(1.315826, 103.817522);
                case 1:
                    return CLLocationCoordinate2DMake(1.329826, 103.827522);
                case 2:
                    return CLLocationCoordinate2DMake(1.326826, 103.845522);
                case 3:
                    return CLLocationCoordinate2DMake(1.309826, 103.849522);
                default:
                    return CLLocationCoordinate2DMake(1.302826, 103.832522);
            }
        case 2:
            switch (pointIndex) {
                case 0:
                    return CLLocationCoordinate2DMake(1.287826, 103.836522);
                case 1:
                    return CLLocationCoordinate2DMake(1.300826, 103.854522);
                default:
                    return CLLocationCoordinate2DMake(1.282826, 103.862522);
            }
        case 3:
            switch (pointIndex) {
                case 0:
                    return CLLocationCoordinate2DMake(1.295826, 103.800522);
                case 1:
                    return CLLocationCoordinate2DMake(1.311826, 103.806522);
                case 2:
                    return CLLocationCoordinate2DMake(1.319826, 103.820522);
                case 3:
                    return CLLocationCoordinate2DMake(1.314826, 103.835522);
                case 4:
                    return CLLocationCoordinate2DMake(1.300826, 103.831522);
                default:
                    return CLLocationCoordinate2DMake(1.290826, 103.817522);
            }
        default:
            switch (pointIndex) {
                case 0:
                    return CLLocationCoordinate2DMake(1.295826, 103.817522);
                case 1:
                    return CLLocationCoordinate2DMake(1.311826, 103.819522);
                case 2:
                    return CLLocationCoordinate2DMake(1.314826, 103.838522);
                default:
                    return CLLocationCoordinate2DMake(1.299826, 103.840522);
            }
    }
}

- (void)focusCoordinateData:(NSData *)coordinateData animated:(BOOL)animated {
    CLLocationCoordinate2D center = [self centerCoordinateForData:coordinateData];
    if (animated) {
        [self.mapView setCenterCoordinate:center transition:[MTCCameraTransition easeWithDuration:0.25] completion:nil];
    } else {
        [self.mapView setCenterCoordinate:center zoomLevel:OverlayInteractivePolygonExampleDefaultZoomLevel];
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
    return @[@"#2F80ED", @"#0B5CAD", @"#00A63E", @"#EF4444", @"#F59E0B", @"#111827", @"#000000", @"#FFFFFF"];
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
        return UIColor.systemBlueColor;
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

#pragma mark - Options

- (NSArray<NSString *> *)blendModeTitles {
    return @[[self localizedStringForKey:@"overlay_normal"], [self localizedStringForKey:@"overlay_multiply"], [self localizedStringForKey:@"overlay_screen"], [self localizedStringForKey:@"overlay_overlay"]];
}

- (MTCPolygonBlendMode)blendModeForIndex:(NSInteger)index {
    switch (index) {
        case 1:
            return MTCPolygonBlendModeMultiply;
        case 2:
            return MTCPolygonBlendModeScreen;
        case 3:
            return MTCPolygonBlendModeOverlay;
        case 0:
        default:
            return MTCPolygonBlendModeNormal;
    }
}

- (NSInteger)indexForBlendMode:(MTCPolygonBlendMode)blendMode
                  fallbackIndex:(NSInteger)fallbackIndex {
    switch (blendMode) {
        case MTCPolygonBlendModeNormal:
            return 0;
        case MTCPolygonBlendModeMultiply:
            return 1;
        case MTCPolygonBlendModeScreen:
            return 2;
        case MTCPolygonBlendModeOverlay:
            return 3;
    }
    return fallbackIndex;
}

#pragma mark - Toast

- (void)showToast:(NSString *)message {
    [MTCExampleToastView showMessage:message inView:self.view];
}

#pragma mark - MTCMapViewDelegate

- (void)mapView:(MTCMapView *)mapView didTapOverlay:(id<MTCOverlay>)overlay {
    (void)mapView;
    MTCPolygon *polygon = [(id)overlay isKindOfClass:MTCPolygon.class] ? (MTCPolygon *)overlay : nil;
    if (polygon == self.polygon) {
        [self showToast:[self localizedStringForKey:@"overlay_polygon_tap"]];
    }
}

- (void)mapView:(MTCMapView *)mapView didLongPressOverlay:(id<MTCOverlay>)overlay {
    (void)mapView;
    MTCPolygon *polygon = [(id)overlay isKindOfClass:MTCPolygon.class] ? (MTCPolygon *)overlay : nil;
    if (polygon == self.polygon) {
        [self showToast:[self localizedStringForKey:@"overlay_polygon_long_press"]];
    }
}

- (void)mapView:(MTCMapView *)mapView didBeginDraggingOverlay:(id<MTCOverlay>)overlay {
    (void)mapView;
    MTCPolygon *polygon = [(id)overlay isKindOfClass:MTCPolygon.class] ? (MTCPolygon *)overlay : nil;
    if (polygon == self.polygon) {
        [self showToast:[self localizedStringForKey:@"overlay_started_dragging_polygon"]];
    }
}

- (void)mapView:(MTCMapView *)mapView didDragOverlay:(id<MTCOverlay>)overlay {
    (void)mapView;
    (void)overlay;
}

- (void)mapView:(MTCMapView *)mapView didEndDraggingOverlay:(id<MTCOverlay>)overlay {
    (void)mapView;
    MTCPolygon *polygon = [(id)overlay isKindOfClass:MTCPolygon.class] ? (MTCPolygon *)overlay : nil;
    if (polygon == self.polygon) {
        [self showToast:[self localizedStringForKey:@"overlay_finished_dragging_polygon"]];
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
    self.title = [self localizedStringForKey:@"demo_title_OverlayInteractivePolygonExampleViewController"];
    if (self.mapView) {
        self.mapView.mapLanguage = [self mapLanguageForDemoLanguage:self.demoLanguage];
    }
    if ([self isSettingsSheetVisible:ExampleSettingsSheetView.class]) {
        [self showSettingsSheet];
    }
}
@end
