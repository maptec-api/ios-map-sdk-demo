#import "OverlayTranslatePolygonExampleViewController.h"

#import "ExampleSettingsSheetView.h"
#import "MTCExampleMapTestSupport.h"
#import "MTCExampleTestAccessibility.h"

#import <MaptecMapsKit/MaptecMapsKit.h>

#include <math.h>

static CLLocationDegrees const OverlayTranslatePolygonExampleSingaporeLatitude = 1.3048264556208515;
static CLLocationDegrees const OverlayTranslatePolygonExampleSingaporeLongitude = 103.83052199958921;
static double const OverlayTranslatePolygonExampleDefaultZoomLevel = 13.0;

@interface OverlayTranslatePolygonExampleState : NSObject <NSCopying>
@property (nonatomic) NSInteger polygonIndex;
@property (nonatomic) NSInteger fillColorIndex;
@property (nonatomic) double fillOpacity;
@property (nonatomic) NSInteger strokeColorIndex;
@property (nonatomic) double strokeWeight;
@property (nonatomic) double strokeOpacity;
@property (nonatomic) NSInteger dashIndex;
@property (nonatomic, copy) NSString *translateXText;
@property (nonatomic, copy) NSString *translateYText;
@property (nonatomic) NSInteger translateAnchorIndex;
@property (nonatomic, copy, nullable) NSData *coordinateData;
@end

@implementation OverlayTranslatePolygonExampleState

- (id)copyWithZone:(NSZone *)zone {
    OverlayTranslatePolygonExampleState *state = [[[self class] allocWithZone:zone] init];
    state.polygonIndex = self.polygonIndex;
    state.fillColorIndex = self.fillColorIndex;
    state.fillOpacity = self.fillOpacity;
    state.strokeColorIndex = self.strokeColorIndex;
    state.strokeWeight = self.strokeWeight;
    state.strokeOpacity = self.strokeOpacity;
    state.dashIndex = self.dashIndex;
    state.translateXText = self.translateXText;
    state.translateYText = self.translateYText;
    state.translateAnchorIndex = self.translateAnchorIndex;
    state.coordinateData = self.coordinateData;
    return state;
}

@end

@interface OverlayTranslatePolygonExampleViewController () <MTCMapViewDelegate>
@property (nonatomic, strong) MTCMapView *mapView;
@property (nonatomic, strong, nullable) MTCPolygon *polygon;
@property (nonatomic, strong) OverlayTranslatePolygonExampleState *currentState;
@property (nonatomic, strong, nullable) OverlayTranslatePolygonExampleState *editingState;
@property (nonatomic, weak, nullable) MTCPolygon *editingPolygon;
@property (nonatomic, strong) MTCExampleMapTestSupport *mapTestSupport;
@end

@implementation OverlayTranslatePolygonExampleViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = UIColor.whiteColor;
    self.view.accessibilityIdentifier = @"OverlayTranslatePolygonExampleViewController.screen";
    self.currentState = [self defaultState];

    [self configureNavigationItems:NO];
    [self configureMapView];
    [self addPolygonWithState:self.currentState];
    [self.mapView setCenterCoordinate:[self singaporeCoordinate]
                             zoomLevel:OverlayTranslatePolygonExampleDefaultZoomLevel];
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

- (NSArray<ExampleSettingsSection *> *)sectionsForState:(OverlayTranslatePolygonExampleState *)state
                                                 action:(dispatch_block_t)action {
    __weak OverlayTranslatePolygonExampleState *weakState = state;
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
        [ExampleSettingsSection sectionWithTitle:[self localizedStringForKey:@"overlay_translate"] items:@[
            [ExampleSettingsItem textItemWithTitle:[self localizedStringForKey:@"overlay_translate_x"]
                                       placeholder:[self localizedStringForKey:@"overlay_enter_x_offset"]
                                       keyboardType:UIKeyboardTypeNumbersAndPunctuation
                                             getter:^NSString * {
                return weakState.translateXText ?: @"";
            } setter:^(NSString *value) {
                weakState.translateXText = value ?: @"";
                syncState();
            }],
            [ExampleSettingsItem textItemWithTitle:[self localizedStringForKey:@"overlay_translate_y"]
                                       placeholder:[self localizedStringForKey:@"overlay_enter_y_offset"]
                                       keyboardType:UIKeyboardTypeNumbersAndPunctuation
                                             getter:^NSString * {
                return weakState.translateYText ?: @"";
            } setter:^(NSString *value) {
                weakState.translateYText = value ?: @"";
                syncState();
            }],
            [ExampleSettingsItem listItemWithTitle:[self localizedStringForKey:@"overlay_translate_anchor"]
                                           options:[self translateAnchorTitles]
                                        popupSize:CGSizeMake(260.0, 180.0)
                                            getter:^NSInteger {
                return weakState.translateAnchorIndex;
            } setter:^(NSInteger index) {
                weakState.translateAnchorIndex = index;
                syncState();
            }],
            [ExampleSettingsItem infoItemWithText:[self localizedStringForKey:@"overlay_geographic_and_screen_planes"]],
        ]],
        [ExampleSettingsSection sectionWithTitle:@"" items:@[
            [[ExampleSettingsItem actionItemWithTitle:[self localizedStringForKey:@"overlay_add_b58c75"] handler:action]
             withAccessibilityIdentifier:MTCExampleTestAccessibilityFillDrawButton],
        ]],
    ];
}

#pragma mark - Polygon

- (void)addPolygonWithState:(OverlayTranslatePolygonExampleState *)state {
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

- (void)replacePolygonWithState:(OverlayTranslatePolygonExampleState *)state
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

- (void)updatePolygonWithState:(OverlayTranslatePolygonExampleState *)state {
    if (!state || !self.polygon) {
        return;
    }

    [self.mapView performOverlayUpdates:^{
        [self applyState:state toPolygon:self.polygon updateCoordinates:YES];
    }];
    self.currentState = [state copy];
}

- (void)syncEditingPolygonForState:(OverlayTranslatePolygonExampleState *)state {
    MTCPolygon *editingPolygon = self.editingPolygon;
    if (!editingPolygon || editingPolygon != self.polygon || !state) {
        return;
    }

    [self updatePolygonWithState:state];
}

- (void)applyState:(OverlayTranslatePolygonExampleState *)state
         toPolygon:(MTCPolygon *)polygon
  updateCoordinates:(BOOL)updateCoordinates {
    if (updateCoordinates) {
        NSData *coordinateData = [self coordinateDataForState:state];
        [polygon setCoordinates:(const CLLocationCoordinate2D *)coordinateData.bytes
                          count:[self coordinateCountForData:coordinateData]];
    }

    polygon.style = [self styleForState:state];
}

- (OverlayTranslatePolygonExampleState *)defaultState {
    OverlayTranslatePolygonExampleState *state = [[OverlayTranslatePolygonExampleState alloc] init];
    state.polygonIndex = 0;
    state.fillColorIndex = 0;
    state.fillOpacity = 0.28;
    state.strokeColorIndex = 1;
    state.strokeWeight = 3.0;
    state.strokeOpacity = 0.9;
    state.dashIndex = 0;
    state.translateXText = @"16";
    state.translateYText = @"16";
    state.translateAnchorIndex = 0;
    return state;
}

- (OverlayTranslatePolygonExampleState *)stateFromPolygon:(MTCPolygon *)polygon {
    OverlayTranslatePolygonExampleState *state = self.currentState ? [self.currentState copy] : [self defaultState];
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
    state.translateXText = [self stringFromTranslateValue:polygon.style.translate.x];
    state.translateYText = [self stringFromTranslateValue:polygon.style.translate.y];
    state.translateAnchorIndex = [self indexForTranslateAnchor:polygon.style.translateAnchor];
    return state;
}

- (MTCPolygonStyle *)styleForState:(OverlayTranslatePolygonExampleState *)state {
    MTCPolygonStyle *style = [[MTCPolygonStyle alloc] init];
    style.fillColor = [self colorForIndex:state.fillColorIndex];
    style.fillOpacity = state.fillOpacity;
    style.fillPatternType = MTCPolygonFillPatternTypeSolid;
    style.strokeColor = [self colorForIndex:state.strokeColorIndex];
    style.strokeWeight = state.strokeWeight;
    style.strokeOpacity = state.strokeOpacity;
    style.strokeDashArray = [self dashArrayForIndex:state.dashIndex];
    style.translate = CGPointMake([self translateValueFromText:state.translateXText],
                                  [self translateValueFromText:state.translateYText]);
    style.translateAnchor = [self translateAnchorForIndex:state.translateAnchorIndex];
    style.blendMode = MTCPolygonBlendModeNormal;
    return style;
}

#pragma mark - Coordinates

- (CLLocationCoordinate2D)singaporeCoordinate {
    return CLLocationCoordinate2DMake(OverlayTranslatePolygonExampleSingaporeLatitude,
                                      OverlayTranslatePolygonExampleSingaporeLongitude);
}

- (NSArray<NSString *> *)polygonTitles {
    return @[[self localizedStringForKey:@"overlay_area_a_4_points"], [self localizedStringForKey:@"overlay_area_b_5_points"], [self localizedStringForKey:@"overlay_triangle_area_3_points"], [self localizedStringForKey:@"overlay_area_c_6_points"]];
}

- (NSData *)coordinateDataForState:(OverlayTranslatePolygonExampleState *)state {
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
        [self.mapView setCenterCoordinate:center zoomLevel:OverlayTranslatePolygonExampleDefaultZoomLevel];
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

#pragma mark - Translate

- (NSArray<NSString *> *)translateAnchorTitles {
    return @[[self localizedStringForKey:@"overlay_map_relative_to_map"], [self localizedStringForKey:@"overlay_viewport_relative_to_screen"]];
}

- (CGFloat)translateValueFromText:(NSString *)text {
    NSString *candidate = [text ?: @"" stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (candidate.length == 0) {
        return 0.0;
    }
    return (CGFloat)fmin(fmax(candidate.doubleValue, -200.0), 200.0);
}

- (NSString *)stringFromTranslateValue:(CGFloat)value {
    if (fabs(value - round(value)) < 0.0001) {
        return [NSString stringWithFormat:@"%.0f", value];
    }
    return [NSString stringWithFormat:@"%.2f", value];
}

- (NSInteger)indexForTranslateAnchor:(MTCPolygonTranslateAnchor)anchor {
    switch (anchor) {
        case MTCPolygonTranslateAnchorViewport:
            return 1;
        case MTCPolygonTranslateAnchorMap:
        default:
            return 0;
    }
}

- (MTCPolygonTranslateAnchor)translateAnchorForIndex:(NSInteger)index {
    switch (index) {
        case 1:
            return MTCPolygonTranslateAnchorViewport;
        case 0:
        default:
            return MTCPolygonTranslateAnchorMap;
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
    self.title = [self localizedStringForKey:@"demo_title_OverlayTranslatePolygonExampleViewController"];
    if (self.mapView) {
        self.mapView.mapLanguage = [self mapLanguageForDemoLanguage:self.demoLanguage];
    }
    if ([self isSettingsSheetVisible:ExampleSettingsSheetView.class]) {
        [self showSettingsSheet];
    }
}
@end
