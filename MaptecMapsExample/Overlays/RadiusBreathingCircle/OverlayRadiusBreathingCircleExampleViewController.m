#import "OverlayRadiusBreathingCircleExampleViewController.h"

#import "ExampleSettingsSheetView.h"
#import "MTCExampleMapTestSupport.h"
#import "MTCExampleTestAccessibility.h"

#import <MaptecMapsKit/MaptecMapsKit.h>

#include <math.h>

static CLLocationDegrees const OverlayRadiusBreathingCircleExampleDefaultLatitude = 1.4;
static CLLocationDegrees const OverlayRadiusBreathingCircleExampleDefaultLongitude = 103.75;
static double const OverlayRadiusBreathingCircleExampleDefaultZoomLevel = 13.0;

static double OverlayRadiusBreathingCircleExampleClamp(double value, double minimum, double maximum) {
    return fmin(fmax(value, minimum), maximum);
}

static NSString *OverlayRadiusBreathingCircleExampleNormalizeHexString(NSString *hexString, NSString *fallback) {
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

@interface OverlayRadiusBreathingCircleExampleFormState : NSObject <NSCopying>
@property (nonatomic) CLLocationCoordinate2D center;
@property (nonatomic, copy) NSString *fillColorHex;
@property (nonatomic) NSInteger fillColorIndex;
@property (nonatomic) double fillOpacity;
@property (nonatomic) BOOL draggable;
@property (nonatomic) double minimumRadius;
@property (nonatomic) double maximumRadius;
@property (nonatomic) double durationMilliseconds;
@end

@implementation OverlayRadiusBreathingCircleExampleFormState

- (id)copyWithZone:(NSZone *)zone {
    OverlayRadiusBreathingCircleExampleFormState *state = [[[self class] allocWithZone:zone] init];
    state.center = self.center;
    state.fillColorHex = self.fillColorHex;
    state.fillColorIndex = self.fillColorIndex;
    state.fillOpacity = self.fillOpacity;
    state.draggable = self.draggable;
    state.minimumRadius = self.minimumRadius;
    state.maximumRadius = self.maximumRadius;
    state.durationMilliseconds = self.durationMilliseconds;
    return state;
}

@end

@interface OverlayRadiusBreathingCircleExampleViewController () <MTCMapViewDelegate>
@property (nonatomic, strong) MTCMapView *mapView;
@property (nonatomic, strong) MTCCircle *circle;
@property (nonatomic, strong) OverlayRadiusBreathingCircleExampleFormState *formState;
@property (nonatomic, strong, nullable) OverlayRadiusBreathingCircleExampleFormState *draftFormState;
@property (nonatomic, weak, nullable) MTCCircle *editingCircle;
@property (nonatomic) BOOL radiusAnimationRunning;
@property (nonatomic) BOOL didStartInitialRadiusAnimation;
@property (nonatomic, strong) MTCExampleMapTestSupport *mapTestSupport;
@end

@implementation OverlayRadiusBreathingCircleExampleViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = UIColor.whiteColor;
    self.view.accessibilityIdentifier = @"OverlayRadiusBreathingCircleExampleViewController.screen";
    self.formState = [self defaultFormState];

    [self configureNavigationItems:NO];
    [self configureMapView];
    [self configureCircle];
    [self.mapView setCenterCoordinate:[self defaultCoordinate]
                             zoomLevel:OverlayRadiusBreathingCircleExampleDefaultZoomLevel];
    [self applyLocalizedTexts];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    if (self.didStartInitialRadiusAnimation) {
        return;
    }
    self.didStartInitialRadiusAnimation = YES;
    [self startRadiusAnimation];
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
    MTCCircle *circle = [self circleForState:self.formState radiusAnimationRunning:NO];
    self.circle = circle;
    self.editingCircle = circle;
    [self.mapView addOverlay:circle];
    [self.mapTestSupport syncOverlayCount:1];
}

#pragma mark - Sheet

- (void)showSettingsSheet {
    MTCCircle *currentCircle = [self currentCircle];
    self.editingCircle = currentCircle;
    OverlayRadiusBreathingCircleExampleFormState *draftState = currentCircle
        ? [self stateFromCircle:currentCircle preservingPreviousState:self.formState]
        : [self defaultFormState];
    self.draftFormState = draftState;

    __weak typeof(self) weakSelf = self;
    __block ExampleSettingsSheetView *sheet = nil;
    sheet = [[ExampleSettingsSheetView alloc] initWithTitle:[self localizedStringForKey:@"common_settings_sheet_title"]
                                                   sections:[self sectionsForState:draftState
                                                                            action:^{
        [weakSelf replaceCircleWithState:weakSelf.draftFormState
                  radiusAnimationRunning:weakSelf.radiusAnimationRunning
                                recenter:YES];
        [sheet dismissAnimated:YES];
    } startAction:^{
        [weakSelf startRadiusAnimationWithState:weakSelf.draftFormState];
        [sheet dismissAnimated:YES];
    } stopAction:^{
        [weakSelf stopRadiusAnimationWithState:weakSelf.draftFormState];
        [sheet dismissAnimated:YES];
    }]];
    [sheet showInView:self.view animated:YES];
}

- (NSArray<ExampleSettingsSection *> *)sectionsForState:(OverlayRadiusBreathingCircleExampleFormState *)state
                                                 action:(dispatch_block_t)action
                                            startAction:(dispatch_block_t)startAction
                                             stopAction:(dispatch_block_t)stopAction {
    __weak OverlayRadiusBreathingCircleExampleFormState *weakState = state;
    __weak typeof(self) weakSelf = self;
    void (^syncState)(void) = ^{
        [weakSelf syncEditingCircleForState:weakState];
    };
    NSArray<NSString *> *colorOptions = [self colorHexValues];
    CGSize colorPopupSize = CGSizeMake(260.0, 280.0);

    return @[
        [ExampleSettingsSection sectionWithTitle:[self localizedStringForKey:@"overlay_fill"] items:@[
            [self colorInputItemWithTitle:[self localizedStringForKey:@"overlay_fill_color"]
                              placeholder:@"#3F7BF9"
                                  options:colorOptions
                                popupSize:colorPopupSize
                                    getter:^NSString *{
                return weakState.fillColorHex ?: @"";
            } setter:^(NSString *value) {
                NSString *hexValue = OverlayRadiusBreathingCircleExampleNormalizeHexString(value, @"#3F7BF9");
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
        [ExampleSettingsSection sectionWithTitle:[self localizedStringForKey:@"overlay_behavior"] items:@[
            [[ExampleSettingsItem boolItemWithTitle:[self localizedStringForKey:@"overlay_draggable"]
                                             getter:^BOOL {
                return weakState.draggable;
            } setter:^(BOOL value) {
                weakState.draggable = value;
                syncState();
            }] withAccessibilityIdentifier:MTCExampleTestAccessibilityCircleSwitchDraggable],
        ]],
        [ExampleSettingsSection sectionWithTitle:[self localizedStringForKey:@"overlay_radius_breathing_animation"] items:@[
            [ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"overlay_start_radius"]
                                             minimum:1.0
                                             maximum:500.0
                                                step:1.0
                                              getter:^double {
                return weakState.minimumRadius;
            } setter:^(double value) {
                weakState.minimumRadius = value;
                syncState();
            } formatter:^NSString *(double value) {
                return [NSString stringWithFormat:@"%.0f", value];
            }],
            [ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"overlay_target_radius"]
                                             minimum:1.0
                                             maximum:500.0
                                                step:1.0
                                              getter:^double {
                return weakState.maximumRadius;
            } setter:^(double value) {
                weakState.maximumRadius = value;
                syncState();
            } formatter:^NSString *(double value) {
                return [NSString stringWithFormat:@"%.0f", value];
            }],
            [ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"overlay_period_ms"]
                                             minimum:500.0
                                             maximum:10000.0
                                                step:100.0
                                              getter:^double {
                return weakState.durationMilliseconds;
            } setter:^(double value) {
                weakState.durationMilliseconds = value;
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

#pragma mark - Animation

- (void)updateCurrentCirclePreservingAnimationState {
    [self updateCurrentCircleWithState:self.formState radiusAnimationRunning:self.radiusAnimationRunning];
}

- (void)startRadiusAnimation {
    [self updateCurrentCircleWithRadiusAnimationRunning:YES];
}

- (void)startRadiusAnimationWithState:(OverlayRadiusBreathingCircleExampleFormState *)state {
    [self updateCurrentCircleWithState:state radiusAnimationRunning:YES];
}

- (void)stopRadiusAnimation {
    [self updateCurrentCircleWithRadiusAnimationRunning:NO];
}

- (void)stopRadiusAnimationWithState:(OverlayRadiusBreathingCircleExampleFormState *)state {
    [self updateCurrentCircleWithState:state radiusAnimationRunning:NO];
}

- (void)updateCurrentCircleWithRadiusAnimationRunning:(BOOL)radiusAnimationRunning {
    [self updateCurrentCircleWithState:self.formState radiusAnimationRunning:radiusAnimationRunning];
}

- (void)updateCurrentCircleWithState:(OverlayRadiusBreathingCircleExampleFormState *)state
              radiusAnimationRunning:(BOOL)radiusAnimationRunning {
    if (!state) {
        return;
    }

    self.radiusAnimationRunning = radiusAnimationRunning;
    self.formState = [state copy];
    MTCCircle *circle = self.circle;
    if (!circle) {
        return;
    }

    [self.mapView performOverlayUpdates:^{
        [self applyState:state toCircle:circle radiusAnimationRunning:radiusAnimationRunning];
    }];
}

#pragma mark - State

- (OverlayRadiusBreathingCircleExampleFormState *)defaultFormState {
    OverlayRadiusBreathingCircleExampleFormState *state = [[OverlayRadiusBreathingCircleExampleFormState alloc] init];
    state.center = [self defaultCoordinate];
    state.fillColorHex = @"#3F7BF9";
    state.fillColorIndex = [self indexForColorHex:state.fillColorHex fallbackIndex:0];
    state.fillOpacity = 0.5;
    state.draggable = NO;
    state.minimumRadius = 30.0;
    state.maximumRadius = 150.0;
    state.durationMilliseconds = 2000.0;
    return state;
}

- (OverlayRadiusBreathingCircleExampleFormState *)stateFromCircle:(MTCCircle *)circle
                                           preservingPreviousState:(OverlayRadiusBreathingCircleExampleFormState *)previousState {
    OverlayRadiusBreathingCircleExampleFormState *state = previousState ? [previousState copy] : [self defaultFormState];
    if (!circle) {
        return state;
    }
    state.center = circle.center;
    state.fillColorHex = [self hexStringFromColor:circle.style.fillColor fallbackHex:state.fillColorHex];
    state.fillColorIndex = [self indexForColorHex:state.fillColorHex fallbackIndex:state.fillColorIndex];
    state.fillOpacity = circle.style.fillOpacity;
    state.draggable = circle.isDraggable;
    return state;
}

#pragma mark - Circle

- (MTCCircle *)currentCircle {
    return self.circle;
}

- (void)replaceCircleWithState:(OverlayRadiusBreathingCircleExampleFormState *)state
        radiusAnimationRunning:(BOOL)radiusAnimationRunning
                      recenter:(BOOL)recenter {
    if (!state) {
        return;
    }

    CLLocationCoordinate2D center = state.center;
    [self removeCircle];
    [self addCircleWithState:state radiusAnimationRunning:radiusAnimationRunning];
    if (recenter) {
        [self focusCoordinate:center animated:YES];
    }
}

- (void)addCircleWithState:(OverlayRadiusBreathingCircleExampleFormState *)state
    radiusAnimationRunning:(BOOL)radiusAnimationRunning {
    if (!state) {
        return;
    }

    MTCCircle *circle = [self circleForState:state radiusAnimationRunning:radiusAnimationRunning];
    self.circle = circle;
    self.formState = [state copy];
    self.radiusAnimationRunning = radiusAnimationRunning;
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

- (void)syncEditingCircleForState:(OverlayRadiusBreathingCircleExampleFormState *)state {
    MTCCircle *circle = self.editingCircle;
    if (!circle || circle != self.circle || !state) {
        return;
    }

    [self updateCurrentCircleWithState:state radiusAnimationRunning:self.radiusAnimationRunning];
}

- (MTCCircle *)circleForState:(OverlayRadiusBreathingCircleExampleFormState *)state
       radiusAnimationRunning:(BOOL)radiusAnimationRunning {
    MTCCircle *circle = [[MTCCircle alloc] initWithCenter:state.center
                                                   radius:[self minimumRadiusForState:state]];
    [self applyState:state toCircle:circle radiusAnimationRunning:radiusAnimationRunning];
    return circle;
}

- (void)applyState:(OverlayRadiusBreathingCircleExampleFormState *)state
          toCircle:(MTCCircle *)circle
radiusAnimationRunning:(BOOL)radiusAnimationRunning {
    circle.center = state.center;
    circle.radius = [self minimumRadiusForState:state];
    circle.renderMode = MTCCircleRenderModeScreen;
    circle.draggable = state.draggable;
    circle.style = [self styleForState:state radiusAnimationRunning:radiusAnimationRunning];
}

- (CLLocationCoordinate2D)defaultCoordinate {
    return CLLocationCoordinate2DMake(OverlayRadiusBreathingCircleExampleDefaultLatitude,
                                      OverlayRadiusBreathingCircleExampleDefaultLongitude);
}

- (void)focusCoordinate:(CLLocationCoordinate2D)coordinate animated:(BOOL)animated {
    if (animated) {
        [self.mapView setCenterCoordinate:coordinate transition:[MTCCameraTransition easeWithDuration:0.25] completion:nil];
    } else {
        [self.mapView setCenterCoordinate:coordinate zoomLevel:OverlayRadiusBreathingCircleExampleDefaultZoomLevel];
    }
}

- (MTCCircleStyle *)styleForState:(OverlayRadiusBreathingCircleExampleFormState *)state
            radiusAnimationRunning:(BOOL)radiusAnimationRunning {
    double minimumRadius = [self minimumRadiusForState:state];
    double maximumRadius = [self maximumRadiusForState:state];

    MTCCircleStyle *style = [[MTCCircleStyle alloc] init];
    style.fillColor = [self colorFromHexString:state.fillColorHex fallbackHex:@"#3F7BF9"];
    style.fillOpacity = OverlayRadiusBreathingCircleExampleClamp(state.fillOpacity, 0.0, 1.0);
    style.strokeColor = UIColor.clearColor;
    style.strokeWeight = 0.0;
    style.strokeOpacity = 0.0;
    style.radiusAnimationMinimumRadius = minimumRadius;
    style.radiusAnimationMaximumRadius = maximumRadius;
    style.radiusAnimationDuration = [self durationForState:state];
    style.radiusAnimation = radiusAnimationRunning;
    return style;
}

- (double)minimumRadiusForState:(OverlayRadiusBreathingCircleExampleFormState *)state {
    return OverlayRadiusBreathingCircleExampleClamp(state.minimumRadius, 1.0, 500.0);
}

- (double)maximumRadiusForState:(OverlayRadiusBreathingCircleExampleFormState *)state {
    double minimumRadius = [self minimumRadiusForState:state];
    double maximumRadius = OverlayRadiusBreathingCircleExampleClamp(state.maximumRadius, 1.0, 500.0);
    return MAX(maximumRadius, minimumRadius + 1.0);
}

- (NSTimeInterval)durationForState:(OverlayRadiusBreathingCircleExampleFormState *)state {
    return OverlayRadiusBreathingCircleExampleClamp(state.durationMilliseconds, 500.0, 10000.0) / 1000.0;
}

#pragma mark - Formatting

- (NSArray<NSString *> *)colorHexValues {
    return @[@"#3F7BF9", @"#FFFFFF", @"#2F80ED", @"#0B5CAD", @"#00A63E", @"#EF4444", @"#F59E0B", @"#111827", @"#000000"];
}

- (NSInteger)indexForColorHex:(NSString *)hexString fallbackIndex:(NSInteger)fallbackIndex {
    NSString *normalizedHex = OverlayRadiusBreathingCircleExampleNormalizeHexString(hexString, @"");
    NSArray<NSString *> *hexValues = [self colorHexValues];
    for (NSUInteger index = 0; index < hexValues.count; ++index) {
        if ([normalizedHex isEqualToString:hexValues[index]]) {
            return (NSInteger)index;
        }
    }
    return fallbackIndex;
}

- (UIColor *)colorFromHexString:(NSString *)hexString fallbackHex:(NSString *)fallbackHex {
    NSString *normalizedHex = OverlayRadiusBreathingCircleExampleNormalizeHexString(hexString, fallbackHex);
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

    NSInteger redValue = (NSInteger)lrint(OverlayRadiusBreathingCircleExampleClamp(red, 0.0, 1.0) * 255.0);
    NSInteger greenValue = (NSInteger)lrint(OverlayRadiusBreathingCircleExampleClamp(green, 0.0, 1.0) * 255.0);
    NSInteger blueValue = (NSInteger)lrint(OverlayRadiusBreathingCircleExampleClamp(blue, 0.0, 1.0) * 255.0);
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
    self.title = [self localizedStringForKey:@"demo_title_OverlayRadiusBreathingCircleExampleViewController"];
    if (self.mapView) {
        self.mapView.mapLanguage = [self mapLanguageForDemoLanguage:self.demoLanguage];
    }
    if ([self isSettingsSheetVisible:ExampleSettingsSheetView.class]) {
        [self showSettingsSheet];
    }
}
@end
