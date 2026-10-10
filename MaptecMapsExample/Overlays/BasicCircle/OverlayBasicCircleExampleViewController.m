#import "OverlayBasicCircleExampleViewController.h"

#import "ExampleSettingsSheetView.h"
#import "MTCExampleMapTestSupport.h"
#import "MTCExampleTestAccessibility.h"

#import <MaptecMapsKit/MaptecMapsKit.h>

#include <math.h>

static CLLocationDegrees const OverlayBasicCircleExampleDefaultLatitude = 1.4;
static CLLocationDegrees const OverlayBasicCircleExampleDefaultLongitude = 103.75;
static double const OverlayBasicCircleExampleDefaultZoomLevel = 13.0;

static double OverlayBasicCircleExampleClamp(double value, double minimum, double maximum) {
    return fmin(fmax(value, minimum), maximum);
}

static NSString *OverlayBasicCircleExampleNormalizeHexString(NSString *hexString, NSString *fallback) {
    NSString *candidate = [[hexString ?: @"" stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] uppercaseString];
    if ([candidate hasPrefix:@"#"]) {
        candidate = [candidate substringFromIndex:1];
    }
    NSCharacterSet *invalidCharacters = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789ABCDEF"] invertedSet];
    if (candidate.length != 6 || [candidate rangeOfCharacterFromSet:invalidCharacters].location != NSNotFound) {
        return fallback;
    }
    return [@"#" stringByAppendingString:candidate];
}

@interface OverlayBasicCircleExampleFormState : NSObject <NSCopying>
@property (nonatomic, copy) NSString *coordinateText;
@property (nonatomic) double radius;
@property (nonatomic, copy) NSString *fillColorHex;
@property (nonatomic) NSInteger fillColorIndex;
@property (nonatomic) double fillOpacity;
@property (nonatomic, copy) NSString *strokeColorHex;
@property (nonatomic) NSInteger strokeColorIndex;
@property (nonatomic) double strokeWeight;
@property (nonatomic) double strokeOpacity;
@property (nonatomic) BOOL draggable;
@end

@implementation OverlayBasicCircleExampleFormState

- (id)copyWithZone:(NSZone *)zone {
    OverlayBasicCircleExampleFormState *state = [[[self class] allocWithZone:zone] init];
    state.coordinateText = self.coordinateText;
    state.radius = self.radius;
    state.fillColorHex = self.fillColorHex;
    state.fillColorIndex = self.fillColorIndex;
    state.fillOpacity = self.fillOpacity;
    state.strokeColorHex = self.strokeColorHex;
    state.strokeColorIndex = self.strokeColorIndex;
    state.strokeWeight = self.strokeWeight;
    state.strokeOpacity = self.strokeOpacity;
    state.draggable = self.draggable;
    return state;
}

@end

@interface OverlayBasicCircleExampleViewController () <MTCMapViewDelegate>
@property (nonatomic, strong) MTCMapView *mapView;
@property (nonatomic, strong) NSMutableArray<MTCCircle *> *circles;
@property (nonatomic, strong) NSMapTable<MTCCircle *, OverlayBasicCircleExampleFormState *> *circleBaseStates;
@property (nonatomic, strong) OverlayBasicCircleExampleFormState *addState;
@property (nonatomic, weak, nullable) MTCCircle *editingCircle;
@property (nonatomic, strong) MTCExampleMapTestSupport *mapTestSupport;
@end

@implementation OverlayBasicCircleExampleViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = UIColor.whiteColor;
    self.view.accessibilityIdentifier = MTCExampleTestAccessibilityOverlayBasicCircleScreen;
    self.circles = [NSMutableArray array];
    self.circleBaseStates = [NSMapTable weakToStrongObjectsMapTable];
    self.addState = [self defaultCircleState];

    [self configureNavigationItems:NO];
    [self configureMapView];
    [self addCircleWithState:self.addState recenter:NO];
    [self.mapView setCenterCoordinate:[self defaultCoordinate]
                             zoomLevel:OverlayBasicCircleExampleDefaultZoomLevel];
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
    self.mapTestSupport.overlayCountValueKey = MTCExampleTestAccessibilityCircleCountValueKey;
    self.mapTestSupport.overlayPresenceIdentifier = MTCExampleTestAccessibilityCircleHasCircles;
    [self.mapTestSupport installOnHostView:self.view];
    [self syncCircleTestAccessibilityState];
}

#pragma mark - Sheets

- (void)showAddCircleSheet {
    MTCCircle *currentCircle = [self currentCircle];
    self.editingCircle = currentCircle;
    self.addState = currentCircle ? [self stateFromCircle:currentCircle] : [self defaultCircleState];

    __weak typeof(self) weakSelf = self;
    __block ExampleSettingsSheetView *sheet = nil;
    sheet = [[ExampleSettingsSheetView alloc] initWithTitle:[self localizedStringForKey:@"common_settings_sheet_title"]
                                                   sections:[self addSectionsForState:self.addState
                                                                            addAction:^{
        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(0, 0);
        if (![weakSelf parseCoordinateText:weakSelf.addState.coordinateText coordinate:&coordinate]) {
            return;
        }
        [weakSelf replaceCirclesWithState:weakSelf.addState recenter:YES];
        [sheet dismissAnimated:YES];
    } clearAction:^{
        [weakSelf clearAllCircles];
        [sheet dismissAnimated:YES];
    }]];
    [sheet showInView:self.view animated:YES];
}

- (NSArray<ExampleSettingsSection *> *)addSectionsForState:(OverlayBasicCircleExampleFormState *)state
                                                 addAction:(dispatch_block_t)addAction
                                               clearAction:(dispatch_block_t)clearAction {
    __weak typeof(self) weakSelf = self;
    __weak OverlayBasicCircleExampleFormState *weakState = state;
    NSMutableArray<ExampleSettingsSection *> *sections = [[self configurationSectionsForState:state] mutableCopy];
    [sections addObject:[ExampleSettingsSection sectionWithTitle:@"" items:@[
        [[ExampleSettingsItem actionItemWithTitle:[self localizedStringForKey:@"overlay_clear_all_3358c6"] handler:clearAction]
            withAccessibilityIdentifier:MTCExampleTestAccessibilitySymbolBtnClearAll],
        [[ExampleSettingsItem actionItemWithTitle:[self localizedStringForKey:@"overlay_add_b58c75"] handler:addAction]
            withAccessibilityIdentifier:MTCExampleTestAccessibilityCircleDrawButton],
    ]]];
    return sections;
}

- (NSArray<ExampleSettingsSection *> *)configurationSectionsForState:(OverlayBasicCircleExampleFormState *)state {
    __weak OverlayBasicCircleExampleFormState *weakState = state;
    __weak typeof(self) weakSelf = self;
    void (^syncState)(void) = ^{
        [weakSelf syncEditingCircleForState:weakState];
    };
    NSArray<NSString *> *colorOptions = [self colorHexValues];
    CGSize colorPopupSize = CGSizeMake(260.0, 280.0);

    return @[
        [ExampleSettingsSection sectionWithTitle:[self localizedStringForKey:@"overlay_geometry"] items:@[
            [[ExampleSettingsItem textItemWithTitle:[self localizedStringForKey:@"overlay_center_lat_lng"]
                                      placeholder:@"1.4, 103.75"
                                     keyboardType:UIKeyboardTypeNumbersAndPunctuation
                                           getter:^NSString *{
                return weakState.coordinateText ?: @"";
            } setter:^(NSString *value) {
                weakState.coordinateText = value ?: @"";
                syncState();
            }] withAccessibilityIdentifier:MTCExampleTestAccessibilityCircleInputLatLng],
            [ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"overlay_radius_px"]
                                             minimum:1.0
                                             maximum:1000.0
                                                step:1.0
                                              getter:^double {
                return weakState.radius;
            } setter:^(double value) {
                weakState.radius = value;
                syncState();
            } formatter:^NSString *(double value) {
                return [NSString stringWithFormat:@"%.0f", value];
            }],
        ]],
        [ExampleSettingsSection sectionWithTitle:[self localizedStringForKey:@"overlay_fill"] items:@[
            [ExampleSettingsItem colorInputItemWithTitle:[self localizedStringForKey:@"overlay_fill_color"]
                                             placeholder:@"#3F7BF9"
                                                 options:colorOptions
                                          optionHexValues:colorOptions
                                               popupSize:colorPopupSize
                                                  getter:^NSString *{
                return weakState.fillColorHex ?: @"";
            } setter:^(NSString *value) {
                NSString *hexValue = OverlayBasicCircleExampleNormalizeHexString(value, @"#3F7BF9");
                weakState.fillColorHex = hexValue;
                weakState.fillColorIndex = [weakSelf indexForColorHex:hexValue fallbackIndex:weakState.fillColorIndex];
                syncState();
            } optionGetter:^NSInteger {
                return weakState.fillColorIndex;
            } optionSetter:^(NSInteger index) {
                if (index < 0 || index >= (NSInteger)colorOptions.count) {
                    return;
                }
                weakState.fillColorHex = colorOptions[index];
                weakState.fillColorIndex = index;
                syncState();
            }],
            [ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"overlay_fill_opacity_0_1"]
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
            [ExampleSettingsItem colorInputItemWithTitle:[self localizedStringForKey:@"overlay_stroke_color"]
                                             placeholder:@"#FFFFFF"
                                                 options:colorOptions
                                          optionHexValues:colorOptions
                                               popupSize:colorPopupSize
                                                  getter:^NSString *{
                return weakState.strokeColorHex ?: @"";
            } setter:^(NSString *value) {
                NSString *hexValue = OverlayBasicCircleExampleNormalizeHexString(value, @"#FFFFFF");
                weakState.strokeColorHex = hexValue;
                weakState.strokeColorIndex = [weakSelf indexForColorHex:hexValue fallbackIndex:weakState.strokeColorIndex];
                syncState();
            } optionGetter:^NSInteger {
                return weakState.strokeColorIndex;
            } optionSetter:^(NSInteger index) {
                if (index < 0 || index >= (NSInteger)colorOptions.count) {
                    return;
                }
                weakState.strokeColorHex = colorOptions[index];
                weakState.strokeColorIndex = index;
                syncState();
            }],
            [ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"overlay_stroke_width"]
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
            [ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"overlay_stroke_opacity_0_1"]
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
        ]],
        [ExampleSettingsSection sectionWithTitle:[self localizedStringForKey:@"overlay_behavior"] items:@[
            [ExampleSettingsItem boolItemWithTitle:[self localizedStringForKey:@"overlay_draggable"]
                                            getter:^BOOL {
                return weakState.draggable;
            } setter:^(BOOL value) {
                weakState.draggable = value;
                syncState();
            }],
        ]],
    ];
}

#pragma mark - Circle

- (nullable MTCCircle *)currentCircle {
    return self.circles.lastObject;
}

- (void)replaceCirclesWithState:(OverlayBasicCircleExampleFormState *)state recenter:(BOOL)recenter {
    [self clearAllCircles];
    [self addCircleWithState:state recenter:recenter];
}

- (void)addCircleWithState:(OverlayBasicCircleExampleFormState *)state recenter:(BOOL)recenter {
    if (!state) {
        return;
    }

    CLLocationCoordinate2D center = [self coordinateForState:state];
    MTCCircle *circle = [[MTCCircle alloc] initWithCenter:center radius:[self radiusForState:state]];
    [self applyState:state toCircle:circle];
    [self.circles addObject:circle];
    self.addState = [state copy];
    self.editingCircle = circle;
    [self.mapView addOverlay:circle];

    if (recenter) {
        [self focusCoordinate:center animated:YES];
    }
    [self syncCircleTestAccessibilityState];
}

- (void)syncEditingCircleForState:(OverlayBasicCircleExampleFormState *)state {
    MTCCircle *circle = self.editingCircle;
    if (!circle || !state) {
        return;
    }

    [self.mapView performOverlayUpdates:^{
        [self applyState:state toCircle:circle];
    }];
}

- (void)clearAllCircles {
    if (self.circles.count > 0) {
        [self.mapView removeOverlays:self.circles];
    }
    [self.circles removeAllObjects];
    [self.circleBaseStates removeAllObjects];
    self.editingCircle = nil;
    [self syncCircleTestAccessibilityState];
}

- (void)syncCircleTestAccessibilityState {
    [self.mapTestSupport syncOverlayCount:self.circles.count];
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

- (void)applyState:(OverlayBasicCircleExampleFormState *)state toCircle:(MTCCircle *)circle {
    circle.center = [self coordinateForState:state];
    circle.radius = [self radiusForState:state];
    circle.renderMode = MTCCircleRenderModeScreen;
    circle.draggable = state.draggable;
    circle.style = [self styleForState:state];
    [self.circleBaseStates setObject:[state copy] forKey:circle];
}

- (OverlayBasicCircleExampleFormState *)defaultCircleState {
    OverlayBasicCircleExampleFormState *state = [[OverlayBasicCircleExampleFormState alloc] init];
    state.coordinateText = [self coordinateTextForCoordinate:[self defaultCoordinate]];
    state.radius = 120.0;
    state.fillColorHex = @"#3F7BF9";
    state.fillColorIndex = [self indexForColorHex:state.fillColorHex fallbackIndex:0];
    state.fillOpacity = 0.5;
    state.strokeColorHex = @"#FFFFFF";
    state.strokeColorIndex = [self indexForColorHex:state.strokeColorHex fallbackIndex:1];
    state.strokeWeight = 2.0;
    state.strokeOpacity = 0.8;
    state.draggable = NO;
    return state;
}

- (OverlayBasicCircleExampleFormState *)stateFromCircle:(MTCCircle *)circle {
    OverlayBasicCircleExampleFormState *baseState = [self.circleBaseStates objectForKey:circle];
    OverlayBasicCircleExampleFormState *state = baseState ? [baseState copy] : [self defaultCircleState];
    state.coordinateText = [self coordinateTextForCoordinate:circle.center];
    state.radius = circle.radius;
    state.fillColorHex = [self hexStringFromColor:circle.style.fillColor fallbackHex:state.fillColorHex];
    state.fillColorIndex = [self indexForColorHex:state.fillColorHex fallbackIndex:state.fillColorIndex];
    state.fillOpacity = circle.style.fillOpacity;
    state.strokeColorHex = [self hexStringFromColor:circle.style.strokeColor fallbackHex:state.strokeColorHex];
    state.strokeColorIndex = [self indexForColorHex:state.strokeColorHex fallbackIndex:state.strokeColorIndex];
    state.strokeWeight = circle.style.strokeWeight;
    state.strokeOpacity = circle.style.strokeOpacity;
    state.draggable = circle.isDraggable;
    return state;
}

- (MTCCircleStyle *)styleForState:(OverlayBasicCircleExampleFormState *)state {
    MTCCircleStyle *style = [[MTCCircleStyle alloc] init];
    style.fillColor = [self colorFromHexString:state.fillColorHex fallbackHex:@"#3F7BF9"];
    style.fillOpacity = OverlayBasicCircleExampleClamp(state.fillOpacity, 0.0, 1.0);
    style.strokeColor = [self colorFromHexString:state.strokeColorHex fallbackHex:@"#FFFFFF"];
    style.strokeWeight = OverlayBasicCircleExampleClamp(state.strokeWeight, 0.0, 20.0);
    style.strokeOpacity = OverlayBasicCircleExampleClamp(state.strokeOpacity, 0.0, 1.0);
    return style;
}

#pragma mark - Coordinates

- (CLLocationCoordinate2D)defaultCoordinate {
    return CLLocationCoordinate2DMake(OverlayBasicCircleExampleDefaultLatitude,
                                      OverlayBasicCircleExampleDefaultLongitude);
}

- (CLLocationCoordinate2D)coordinateForState:(OverlayBasicCircleExampleFormState *)state {
    CLLocationCoordinate2D coordinate = [self defaultCoordinate];
    if ([self parseCoordinateText:state.coordinateText coordinate:&coordinate]) {
        return coordinate;
    }
    return [self defaultCoordinate];
}

- (BOOL)parseCoordinateText:(NSString *)text coordinate:(CLLocationCoordinate2D *)coordinate {
    NSString *normalizedText = [text ?: @"" stringByReplacingOccurrencesOfString:@"，" withString:@","];
    NSArray<NSString *> *components = [normalizedText componentsSeparatedByString:@","];
    if (components.count != 2) {
        return NO;
    }

    double latitude = 0.0;
    double longitude = 0.0;
    if (![self parseDoubleText:components[0] value:&latitude] ||
        ![self parseDoubleText:components[1] value:&longitude]) {
        return NO;
    }
    if (latitude < -90.0 || latitude > 90.0 || longitude < -180.0 || longitude > 180.0) {
        return NO;
    }
    if (coordinate) {
        *coordinate = CLLocationCoordinate2DMake(latitude, longitude);
    }
    return YES;
}

- (BOOL)parseDoubleText:(NSString *)text value:(double *)value {
    NSString *trimmedText = [text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    NSScanner *scanner = [NSScanner scannerWithString:trimmedText];
    double parsedValue = 0.0;
    if (![scanner scanDouble:&parsedValue] || !scanner.isAtEnd || !isfinite(parsedValue)) {
        return NO;
    }
    if (value) {
        *value = parsedValue;
    }
    return YES;
}

- (NSString *)coordinateTextForCoordinate:(CLLocationCoordinate2D)coordinate {
    return [NSString stringWithFormat:@"%.6g, %.6g", coordinate.latitude, coordinate.longitude];
}

- (double)radiusForState:(OverlayBasicCircleExampleFormState *)state {
    return OverlayBasicCircleExampleClamp(state.radius, 1.0, 1000.0);
}

- (void)focusCoordinate:(CLLocationCoordinate2D)coordinate animated:(BOOL)animated {
    if (animated) {
        [self.mapView setCenterCoordinate:coordinate transition:[MTCCameraTransition easeWithDuration:0.25] completion:nil];
    } else {
        [self.mapView setCenterCoordinate:coordinate zoomLevel:OverlayBasicCircleExampleDefaultZoomLevel];
    }
}

#pragma mark - Formatting

- (NSArray<NSString *> *)colorHexValues {
    return @[@"#3F7BF9", @"#FFFFFF", @"#2F80ED", @"#0B5CAD", @"#00A63E", @"#EF4444", @"#F59E0B", @"#111827", @"#000000"];
}

- (NSInteger)indexForColorHex:(NSString *)hexString fallbackIndex:(NSInteger)fallbackIndex {
    NSString *normalizedHex = OverlayBasicCircleExampleNormalizeHexString(hexString, @"");
    NSArray<NSString *> *hexValues = [self colorHexValues];
    for (NSUInteger index = 0; index < hexValues.count; ++index) {
        if ([normalizedHex isEqualToString:hexValues[index]]) {
            return (NSInteger)index;
        }
    }
    return fallbackIndex;
}

- (UIColor *)colorFromHexString:(NSString *)hexString fallbackHex:(NSString *)fallbackHex {
    NSString *normalizedHex = OverlayBasicCircleExampleNormalizeHexString(hexString, fallbackHex);
    NSString *candidate = [normalizedHex hasPrefix:@"#"] ? [normalizedHex substringFromIndex:1] : normalizedHex;
    unsigned int rgbValue = 0;
    if (![[NSScanner scannerWithString:candidate] scanHexInt:&rgbValue]) {
        return UIColor.systemBlueColor;
    }
    return [UIColor colorWithRed:((rgbValue >> 16) & 0xFF) / 255.0
                           green:((rgbValue >> 8) & 0xFF) / 255.0
                            blue:(rgbValue & 0xFF) / 255.0
                           alpha:1.0];
}

- (NSString *)hexStringFromColor:(UIColor *)color fallbackHex:(NSString *)fallbackHex {
    CGFloat red = 0.0;
    CGFloat green = 0.0;
    CGFloat blue = 0.0;
    CGFloat alpha = 0.0;
    if (![color getRed:&red green:&green blue:&blue alpha:&alpha]) {
        return fallbackHex;
    }

    NSInteger redValue = (NSInteger)lrint(OverlayBasicCircleExampleClamp(red, 0.0, 1.0) * 255.0);
    NSInteger greenValue = (NSInteger)lrint(OverlayBasicCircleExampleClamp(green, 0.0, 1.0) * 255.0);
    NSInteger blueValue = (NSInteger)lrint(OverlayBasicCircleExampleClamp(blue, 0.0, 1.0) * 255.0);
    return [NSString stringWithFormat:@"#%02lX%02lX%02lX", (long)redValue, (long)greenValue, (long)blueValue];
}

#pragma mark -- multi-language

- (void)handleExampleSettingsAction {
    [self showAddCircleSheet];
}

- (void)demoLanguageDidChange {
    [self applyLocalizedTexts];
}

- (void)applyLocalizedTexts {
    self.title = [self localizedStringForKey:@"demo_title_OverlayBasicCircleExampleViewController"];
    if (self.mapView) {
        self.mapView.mapLanguage = [self mapLanguageForDemoLanguage:self.demoLanguage];
    }
    if ([self isSettingsSheetVisible:ExampleSettingsSheetView.class]) {
        [self showAddCircleSheet];
    }
}
@end
