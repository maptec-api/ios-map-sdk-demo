#import "OverlayScanAnimationCircleExampleViewController.h"

#import "ExampleSettingsSheetView.h"
#import "MTCExampleMapTestSupport.h"
#import "MTCExampleTestAccessibility.h"

#import <MaptecMapsKit/MaptecMapsKit.h>

#include <math.h>

static CLLocationDegrees const OverlayScanAnimationCircleExampleDefaultLatitude = 1.4;
static CLLocationDegrees const OverlayScanAnimationCircleExampleDefaultLongitude = 103.75;
static double const OverlayScanAnimationCircleExampleDefaultZoomLevel = 13.0;
static NSString *const OverlayScanAnimationCircleExampleScanBaseImageName = @"scan_base_image";

static double OverlayScanAnimationCircleExampleClamp(double value, double minimum, double maximum) {
    return fmin(fmax(value, minimum), maximum);
}

static NSString *OverlayScanAnimationCircleExampleNormalizeHexString(NSString *hexString, NSString *fallback) {
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

@interface OverlayScanAnimationCircleExampleFormState : NSObject <NSCopying>
@property (nonatomic) CLLocationCoordinate2D center;
@property (nonatomic) double radius;
@property (nonatomic, copy) NSString *fillColorHex;
@property (nonatomic) NSInteger fillColorIndex;
@property (nonatomic) double fillOpacity;
@property (nonatomic, copy) NSString *strokeColorHex;
@property (nonatomic) NSInteger strokeColorIndex;
@property (nonatomic) double strokeWeight;
@property (nonatomic) double strokeOpacity;
@property (nonatomic) BOOL draggable;
@property (nonatomic) double scanAngle;
@property (nonatomic, copy) NSString *scanColorHex;
@property (nonatomic) NSInteger scanColorIndex;
@property (nonatomic) BOOL scanColorUsesFillColor;
@property (nonatomic) double scanDurationMilliseconds;
@end

@implementation OverlayScanAnimationCircleExampleFormState

- (id)copyWithZone:(NSZone *)zone {
    OverlayScanAnimationCircleExampleFormState *state = [[[self class] allocWithZone:zone] init];
    state.center = self.center;
    state.radius = self.radius;
    state.fillColorHex = self.fillColorHex;
    state.fillColorIndex = self.fillColorIndex;
    state.fillOpacity = self.fillOpacity;
    state.strokeColorHex = self.strokeColorHex;
    state.strokeColorIndex = self.strokeColorIndex;
    state.strokeWeight = self.strokeWeight;
    state.strokeOpacity = self.strokeOpacity;
    state.draggable = self.draggable;
    state.scanAngle = self.scanAngle;
    state.scanColorHex = self.scanColorHex;
    state.scanColorIndex = self.scanColorIndex;
    state.scanColorUsesFillColor = self.scanColorUsesFillColor;
    state.scanDurationMilliseconds = self.scanDurationMilliseconds;
    return state;
}

@end

@interface OverlayScanAnimationCircleExampleViewController () <MTCMapViewDelegate>
@property (nonatomic, strong) MTCMapView *mapView;
@property (nonatomic, strong) MTCCircle *circle;
@property (nonatomic, strong) OverlayScanAnimationCircleExampleFormState *formState;
@property (nonatomic, strong, nullable) OverlayScanAnimationCircleExampleFormState *editingState;
@property (nonatomic, weak, nullable) MTCCircle *editingCircle;
@property (nonatomic) BOOL scanAnimationRunning;
@property (nonatomic, strong) MTCExampleMapTestSupport *mapTestSupport;
@end

@implementation OverlayScanAnimationCircleExampleViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = UIColor.whiteColor;
    self.view.accessibilityIdentifier = @"OverlayScanAnimationCircleExampleViewController.screen";
    self.formState = [self defaultFormState];
    self.scanAnimationRunning = YES;

    [self configureNavigationItems:NO];
    [self configureMapView];
    [self configureCircle];
    [self.mapView setCenterCoordinate:[self defaultCoordinate]
                             zoomLevel:OverlayScanAnimationCircleExampleDefaultZoomLevel];
    [self applyLocalizedTexts];
}

#pragma mark - Setup

- (void)configureMapView {
    self.mapTestSupport = [[MTCExampleMapTestSupport alloc] init];
    self.mapTestSupport.overlayCountValueKey = MTCExampleTestAccessibilityCircleCountValueKey;
    self.mapTestSupport.overlayPresenceIdentifier = MTCExampleTestAccessibilityCircleHasCircles;
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

- (void)configureCircle {
    MTCCircle *circle = [self circleForState:self.formState scanAnimationRunning:self.scanAnimationRunning];
    self.circle = circle;
    self.editingCircle = circle;
    [self.mapView addOverlay:circle];
    [self.mapTestSupport syncOverlayCount:1];
}

#pragma mark - Sheet

- (void)showSettingsSheet {
    MTCCircle *currentCircle = [self currentCircle];
    self.editingCircle = currentCircle;
    self.editingState = currentCircle
        ? [self stateFromCircle:currentCircle preservingPreviousState:self.formState]
        : [self defaultFormState];

    __weak typeof(self) weakSelf = self;
    __block ExampleSettingsSheetView *sheet = nil;
    sheet = [[ExampleSettingsSheetView alloc] initWithTitle:[self localizedStringForKey:@"common_settings_sheet_title"]
                                                   sections:[self sectionsForState:self.editingState
                                                                            action:^{
        [weakSelf replaceCircleWithState:weakSelf.editingState
                    scanAnimationRunning:weakSelf.scanAnimationRunning
                                recenter:YES];
        [sheet dismissAnimated:YES];
    } startAction:^{
        [weakSelf updateCurrentCircleWithState:weakSelf.editingState scanAnimationRunning:YES];
        [sheet dismissAnimated:YES];
    } stopAction:^{
        [weakSelf updateCurrentCircleWithState:weakSelf.editingState scanAnimationRunning:NO];
        [sheet dismissAnimated:YES];
    }]];
    [sheet showInView:self.view animated:YES];
}

- (NSArray<ExampleSettingsSection *> *)sectionsForState:(OverlayScanAnimationCircleExampleFormState *)state
                                                 action:(dispatch_block_t)action
                                            startAction:(dispatch_block_t)startAction
                                             stopAction:(dispatch_block_t)stopAction {
    __weak OverlayScanAnimationCircleExampleFormState *weakState = state;
    __weak typeof(self) weakSelf = self;
    void (^syncState)(void) = ^{
        [weakSelf syncEditingCircleForState:weakState];
    };
    NSArray<NSString *> *colorOptions = [self colorHexValues];
    CGSize colorPopupSize = CGSizeMake(260.0, 280.0);

    ExampleSettingsItem *scanColorItem =
        [self colorInputItemWithTitle:[self localizedStringForKey:@"overlay_sector_color_empty_fill"]
                          placeholder:@"#E60012"
                              options:colorOptions
                            popupSize:colorPopupSize
                                getter:^NSString *{
        return weakState.scanColorUsesFillColor ? @"" : (weakState.scanColorHex ?: @"");
    } setter:^(NSString *value) {
        NSString *trimmedValue = [value ?: @"" stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        if (trimmedValue.length == 0) {
            weakState.scanColorUsesFillColor = YES;
            weakState.scanColorHex = @"";
            syncState();
            return;
        }
        NSString *hexValue = OverlayScanAnimationCircleExampleNormalizeHexString(value, @"#E60012");
        weakState.scanColorUsesFillColor = NO;
        weakState.scanColorHex = hexValue;
        weakState.scanColorIndex = [weakSelf indexForColorHex:hexValue fallbackIndex:weakState.scanColorIndex];
        syncState();
    } optionGetter:^NSInteger {
        return weakState.scanColorIndex;
    } optionSetter:^(NSInteger index) {
        if (index < 0 || index >= (NSInteger)colorOptions.count) {
            return;
        }
        weakState.scanColorUsesFillColor = NO;
        weakState.scanColorHex = colorOptions[index];
        weakState.scanColorIndex = index;
        syncState();
    }];

    return @[
        [ExampleSettingsSection sectionWithTitle:[self localizedStringForKey:@"overlay_geometry"] items:@[
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
            [self colorInputItemWithTitle:[self localizedStringForKey:@"overlay_fill_color"]
                              placeholder:@"#3F7BF9"
                                  options:colorOptions
                                popupSize:colorPopupSize
                                    getter:^NSString *{
                return weakState.fillColorHex ?: @"";
            } setter:^(NSString *value) {
                NSString *hexValue = OverlayScanAnimationCircleExampleNormalizeHexString(value, @"#3F7BF9");
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
            [self colorInputItemWithTitle:[self localizedStringForKey:@"overlay_stroke_color"]
                              placeholder:@"#FFFFFF"
                                  options:colorOptions
                                popupSize:colorPopupSize
                                    getter:^NSString *{
                return weakState.strokeColorHex ?: @"";
            } setter:^(NSString *value) {
                NSString *hexValue = OverlayScanAnimationCircleExampleNormalizeHexString(value, @"#FFFFFF");
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
            [[ExampleSettingsItem boolItemWithTitle:[self localizedStringForKey:@"overlay_draggable"]
                                             getter:^BOOL {
                return weakState.draggable;
            } setter:^(BOOL value) {
                weakState.draggable = value;
                syncState();
            }] withAccessibilityIdentifier:MTCExampleTestAccessibilityCircleSwitchDraggable],
        ]],
        [ExampleSettingsSection sectionWithTitle:[self localizedStringForKey:@"overlay_scan_animation"] items:@[
            [ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"overlay_sector_angle_deg_0_90"]
                                             minimum:0.0
                                             maximum:90.0
                                                 step:1.0
                                               getter:^double {
                return weakState.scanAngle;
            } setter:^(double value) {
                weakState.scanAngle = value;
                syncState();
            } formatter:^NSString *(double value) {
                return [NSString stringWithFormat:@"%.0f", value];
            }],
            scanColorItem,
            [ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"overlay_rotation_period_ms_turn"]
                                             minimum:500.0
                                             maximum:10000.0
                                                 step:100.0
                                               getter:^double {
                return weakState.scanDurationMilliseconds;
            } setter:^(double value) {
                weakState.scanDurationMilliseconds = value;
                syncState();
            } formatter:^NSString *(double value) {
                return [NSString stringWithFormat:@"%.0f", value];
            }],
        ]],
        [ExampleSettingsSection sectionWithTitle:@"" items:@[
            [[ExampleSettingsItem actionItemWithTitle:[self localizedStringForKey:@"overlay_add_b58c75"] handler:action]
             withAccessibilityIdentifier:MTCExampleTestAccessibilityCircleDrawButton],
            [ExampleSettingsItem actionItemWithTitle:[self localizedStringForKey:@"overlay_start_animation"] handler:startAction],
            [ExampleSettingsItem actionItemWithTitle:[self localizedStringForKey:@"overlay_stop_animation_74dcd0"] handler:stopAction],
        ]],
    ];
}

- (ExampleSettingsItem *)colorInputItemWithTitle:(NSString *)title
                                     placeholder:(NSString *)placeholder
                                         options:(NSArray<NSString *> *)options
                                       popupSize:(CGSize)popupSize
                                          getter:(ExampleSettingsTextGetter)getter
                                          setter:(ExampleSettingsTextSetter)setter
                                    optionGetter:(ExampleSettingsSegmentGetter)optionGetter
                                    optionSetter:(ExampleSettingsSegmentSetter)optionSetter {
    return [ExampleSettingsItem colorInputItemWithTitle:title
                                            placeholder:placeholder
                                                options:options
                                         optionHexValues:options
                                              popupSize:popupSize
                                                 getter:getter
                                                 setter:setter
                                           optionGetter:optionGetter
                                           optionSetter:optionSetter];
}

- (void)updateCurrentCirclePreservingAnimationState {
    [self updateCurrentCircleWithState:self.formState scanAnimationRunning:self.scanAnimationRunning];
}

- (void)updateCurrentCircleWithScanAnimationRunning:(BOOL)scanAnimationRunning {
    [self updateCurrentCircleWithState:self.formState scanAnimationRunning:scanAnimationRunning];
}

- (void)updateCurrentCircleWithState:(OverlayScanAnimationCircleExampleFormState *)state
                scanAnimationRunning:(BOOL)scanAnimationRunning {
    if (!state) {
        return;
    }

    self.scanAnimationRunning = scanAnimationRunning;
    self.formState = [state copy];
    MTCCircle *circle = self.circle;
    if (!circle) {
        return;
    }

    [self.mapView performOverlayUpdates:^{
        [self applyState:state toCircle:circle scanAnimationRunning:scanAnimationRunning];
    }];
}

#pragma mark - State

- (OverlayScanAnimationCircleExampleFormState *)defaultFormState {
    OverlayScanAnimationCircleExampleFormState *state = [[OverlayScanAnimationCircleExampleFormState alloc] init];
    state.center = [self defaultCoordinate];
    state.radius = 120.0;
    state.fillColorHex = @"#3F7BF9";
    state.fillColorIndex = [self indexForColorHex:state.fillColorHex fallbackIndex:0];
    state.fillOpacity = 0.5;
    state.strokeColorHex = @"#FFFFFF";
    state.strokeColorIndex = [self indexForColorHex:state.strokeColorHex fallbackIndex:1];
    state.strokeWeight = 2.0;
    state.strokeOpacity = 0.8;
    state.draggable = NO;
    state.scanAngle = 60.0;
    state.scanColorHex = @"#E60012";
    state.scanColorIndex = [self indexForColorHex:state.scanColorHex fallbackIndex:6];
    state.scanDurationMilliseconds = 3000.0;
    return state;
}

- (OverlayScanAnimationCircleExampleFormState *)stateFromCircle:(MTCCircle *)circle
                                        preservingPreviousState:(OverlayScanAnimationCircleExampleFormState *)previousState {
    OverlayScanAnimationCircleExampleFormState *state = [self defaultFormState];
    if (!circle) {
        return state;
    }
    state.center = circle.center;
    state.radius = circle.radius;
    state.fillColorHex = [self hexStringFromColor:circle.style.fillColor fallbackHex:state.fillColorHex];
    state.fillColorIndex = [self indexForColorHex:state.fillColorHex fallbackIndex:state.fillColorIndex];
    state.fillOpacity = circle.style.fillOpacity;
    state.strokeColorHex = [self hexStringFromColor:circle.style.strokeColor fallbackHex:state.strokeColorHex];
    state.strokeColorIndex = [self indexForColorHex:state.strokeColorHex fallbackIndex:state.strokeColorIndex];
    state.strokeWeight = circle.style.strokeWeight;
    state.strokeOpacity = circle.style.strokeOpacity;
    state.draggable = circle.isDraggable;
    state.scanAngle = circle.style.scanAngle;
    if (circle.style.scanDuration > 0.0) {
        state.scanDurationMilliseconds = circle.style.scanDuration * 1000.0;
    } else {
        state.scanDurationMilliseconds = previousState.scanDurationMilliseconds > 0.0
            ? previousState.scanDurationMilliseconds
            : 3000.0;
    }
    state.scanColorUsesFillColor = previousState.scanColorUsesFillColor;
    if (state.scanColorUsesFillColor) {
        state.scanColorHex = @"";
        state.scanColorIndex = previousState.scanColorIndex;
    } else {
        state.scanColorHex = [self hexStringFromColor:circle.style.scanColor fallbackHex:state.scanColorHex];
        state.scanColorIndex = [self indexForColorHex:state.scanColorHex fallbackIndex:state.scanColorIndex];
    }
    return state;
}

#pragma mark - Circle

- (MTCCircle *)currentCircle {
    return self.circle;
}

- (void)replaceCircleWithState:(OverlayScanAnimationCircleExampleFormState *)state
          scanAnimationRunning:(BOOL)scanAnimationRunning
                      recenter:(BOOL)recenter {
    if (!state) {
        return;
    }

    CLLocationCoordinate2D center = state.center;
    [self removeCircle];
    [self addCircleWithState:state scanAnimationRunning:scanAnimationRunning];
    if (recenter) {
        [self focusCoordinate:center animated:YES];
    }
}

- (void)addCircleWithState:(OverlayScanAnimationCircleExampleFormState *)state
      scanAnimationRunning:(BOOL)scanAnimationRunning {
    if (!state) {
        return;
    }

    MTCCircle *circle = [self circleForState:state scanAnimationRunning:scanAnimationRunning];
    self.circle = circle;
    self.formState = [state copy];
    self.editingCircle = circle;
    [self.mapView addOverlay:circle];
    [self.mapTestSupport syncOverlayCount:1];
}

- (void)removeCircle {
    if (self.circle) {
        [self.mapView removeOverlay:self.circle];
    }
    self.circle = nil;
    self.editingCircle = nil;
    [self.mapTestSupport syncOverlayCount:0];
}

- (void)syncEditingCircleForState:(OverlayScanAnimationCircleExampleFormState *)state {
    MTCCircle *circle = self.editingCircle;
    if (!circle || circle != self.circle || !state) {
        return;
    }

    [self updateCurrentCircleWithState:state scanAnimationRunning:self.scanAnimationRunning];
}

- (MTCCircle *)circleForState:(OverlayScanAnimationCircleExampleFormState *)state
         scanAnimationRunning:(BOOL)scanAnimationRunning {
    MTCCircle *circle = [[MTCCircle alloc] initWithCenter:state.center radius:[self radiusForState:state]];
    [self applyState:state toCircle:circle scanAnimationRunning:scanAnimationRunning];
    return circle;
}

- (void)applyState:(OverlayScanAnimationCircleExampleFormState *)state
          toCircle:(MTCCircle *)circle
scanAnimationRunning:(BOOL)scanAnimationRunning {
    circle.center = state.center;
    circle.radius = [self radiusForState:state];
    circle.renderMode = MTCCircleRenderModeScreen;
    circle.draggable = state.draggable;
    circle.style = [self styleForState:state scanAnimationRunning:scanAnimationRunning];
}

- (CLLocationCoordinate2D)defaultCoordinate {
    return CLLocationCoordinate2DMake(OverlayScanAnimationCircleExampleDefaultLatitude,
                                      OverlayScanAnimationCircleExampleDefaultLongitude);
}

- (MTCCircleStyle *)styleForState:(OverlayScanAnimationCircleExampleFormState *)state
             scanAnimationRunning:(BOOL)scanAnimationRunning {
    UIColor *fillColor = [self colorFromHexString:state.fillColorHex fallbackHex:@"#3F7BF9"];

    MTCCircleStyle *style = [[MTCCircleStyle alloc] init];
    style.fillColor = fillColor;
    style.fillOpacity = OverlayScanAnimationCircleExampleClamp(state.fillOpacity, 0.0, 1.0);
    style.strokeColor = [self colorFromHexString:state.strokeColorHex fallbackHex:@"#FFFFFF"];
    style.strokeWeight = OverlayScanAnimationCircleExampleClamp(state.strokeWeight, 0.0, 20.0);
    style.strokeOpacity = OverlayScanAnimationCircleExampleClamp(state.strokeOpacity, 0.0, 1.0);
    style.scanDuration = scanAnimationRunning
        ? OverlayScanAnimationCircleExampleClamp(state.scanDurationMilliseconds, 500.0, 10000.0) / 1000.0
        : 0.0;
    style.scanAngle = OverlayScanAnimationCircleExampleClamp(state.scanAngle, 0.0, 90.0);
    style.scanColor = state.scanColorUsesFillColor ? fillColor : [self colorFromHexString:state.scanColorHex fallbackHex:@"#E60012"];
    style.scanStartAngle = 0.0;
    style.scanBaseImageName = OverlayScanAnimationCircleExampleScanBaseImageName;
    style.scanAnimation = YES;
    return style;
}

- (double)radiusForState:(OverlayScanAnimationCircleExampleFormState *)state {
    return OverlayScanAnimationCircleExampleClamp(state.radius, 1.0, 1000.0);
}

- (void)focusCoordinate:(CLLocationCoordinate2D)coordinate animated:(BOOL)animated {
    if (animated) {
        [self.mapView setCenterCoordinate:coordinate transition:[MTCCameraTransition easeWithDuration:0.25] completion:nil];
    } else {
        [self.mapView setCenterCoordinate:coordinate zoomLevel:OverlayScanAnimationCircleExampleDefaultZoomLevel];
    }
}

#pragma mark - Formatting

- (NSArray<NSString *> *)colorHexValues {
    return @[@"#3F7BF9", @"#FFFFFF", @"#2F80ED", @"#0B5CAD", @"#00A63E", @"#EF4444", @"#E60012", @"#F59E0B", @"#111827", @"#000000"];
}

- (NSInteger)indexForColorHex:(NSString *)hexString fallbackIndex:(NSInteger)fallbackIndex {
    NSString *normalizedHex = OverlayScanAnimationCircleExampleNormalizeHexString(hexString, @"");
    NSArray<NSString *> *hexValues = [self colorHexValues];
    for (NSUInteger index = 0; index < hexValues.count; ++index) {
        if ([normalizedHex isEqualToString:hexValues[index]]) {
            return (NSInteger)index;
        }
    }
    return fallbackIndex;
}

- (UIColor *)colorFromHexString:(NSString *)hexString fallbackHex:(NSString *)fallbackHex {
    NSString *normalizedHex = OverlayScanAnimationCircleExampleNormalizeHexString(hexString, fallbackHex);
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

    NSInteger redValue = (NSInteger)lrint(OverlayScanAnimationCircleExampleClamp(red, 0.0, 1.0) * 255.0);
    NSInteger greenValue = (NSInteger)lrint(OverlayScanAnimationCircleExampleClamp(green, 0.0, 1.0) * 255.0);
    NSInteger blueValue = (NSInteger)lrint(OverlayScanAnimationCircleExampleClamp(blue, 0.0, 1.0) * 255.0);
    return [NSString stringWithFormat:@"#%02lX%02lX%02lX", (long)redValue, (long)greenValue, (long)blueValue];
}

#pragma mark -- multi-language

- (void)handleExampleSettingsAction {
    [self showSettingsSheet];
}

- (void)demoLanguageDidChange {
    [self applyLocalizedTexts];
}

- (void)applyLocalizedTexts {
    self.title = [self localizedStringForKey:@"demo_title_OverlayScanAnimationCircleExampleViewController"];
    if (self.mapView) {
        self.mapView.mapLanguage = [self mapLanguageForDemoLanguage:self.demoLanguage];
    }
    if ([self isSettingsSheetVisible:ExampleSettingsSheetView.class]) {
        [self showSettingsSheet];
    }
}
@end
