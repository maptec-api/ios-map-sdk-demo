#import "OverlayPulseAnimationCircleExampleViewController.h"

#import "ExampleSettingsSheetView.h"
#import "MTCExampleMapTestSupport.h"
#import "MTCExampleTestAccessibility.h"

#import <MaptecMapsKit/MaptecMapsKit.h>

#include <math.h>

static CLLocationDegrees const OverlayPulseAnimationCircleExampleDefaultLatitude = 1.4;
static CLLocationDegrees const OverlayPulseAnimationCircleExampleDefaultLongitude = 103.75;
static double const OverlayPulseAnimationCircleExampleDefaultZoomLevel = 13.0;

static double OverlayPulseAnimationCircleExampleClamp(double value, double minimum, double maximum) {
    return fmin(fmax(value, minimum), maximum);
}

static NSString *OverlayPulseAnimationCircleExampleNormalizeHexString(NSString *hexString, NSString *fallback) {
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

@interface OverlayPulseAnimationCircleExampleFormState : NSObject <NSCopying>
@property (nonatomic) CLLocationCoordinate2D center;
@property (nonatomic, copy) NSString *fillColorHex;
@property (nonatomic) NSInteger fillColorIndex;
@property (nonatomic) double fillOpacity;
@property (nonatomic) BOOL draggable;
@property (nonatomic) double pulseMinimumRadius;
@property (nonatomic) double pulseMaximumRadius;
@property (nonatomic) double pulseDurationMilliseconds;
@end

@implementation OverlayPulseAnimationCircleExampleFormState

- (id)copyWithZone:(NSZone *)zone {
    OverlayPulseAnimationCircleExampleFormState *state = [[[self class] allocWithZone:zone] init];
    state.center = self.center;
    state.fillColorHex = self.fillColorHex;
    state.fillColorIndex = self.fillColorIndex;
    state.fillOpacity = self.fillOpacity;
    state.draggable = self.draggable;
    state.pulseMinimumRadius = self.pulseMinimumRadius;
    state.pulseMaximumRadius = self.pulseMaximumRadius;
    state.pulseDurationMilliseconds = self.pulseDurationMilliseconds;
    return state;
}

@end

@interface OverlayPulseAnimationCircleExampleViewController () <MTCMapViewDelegate>
@property (nonatomic, strong) MTCMapView *mapView;
@property (nonatomic, strong) MTCCircle *anchorCircle;
@property (nonatomic, strong) NSMutableArray<MTCCircle *> *activeRipples;
@property (nonatomic, strong) OverlayPulseAnimationCircleExampleFormState *formState;
@property (nonatomic, strong, nullable) OverlayPulseAnimationCircleExampleFormState *draftFormState;
@property (nonatomic, weak, nullable) MTCCircle *editingAnchorCircle;
@property (nonatomic, strong, nullable) NSTimer *pulseEmitterTimer;
@property (nonatomic) BOOL pulseAnimationRunning;
@property (nonatomic) BOOL didStartInitialPulseAnimation;
@property (nonatomic, strong) MTCExampleMapTestSupport *mapTestSupport;
@end

@implementation OverlayPulseAnimationCircleExampleViewController

- (void)dealloc {
    [self stopPulseAnimationClearingRipples:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = UIColor.whiteColor;
    self.view.accessibilityIdentifier = @"OverlayPulseAnimationCircleExampleViewController.screen";
    self.formState = [self defaultFormState];
    self.activeRipples = [NSMutableArray array];

    [self configureNavigationItems:NO];
    [self configureMapView];
    [self configureAnchorCircle];
    [self.mapView setCenterCoordinate:[self defaultCoordinate]
                             zoomLevel:OverlayPulseAnimationCircleExampleDefaultZoomLevel];
    [self applyLocalizedTexts];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    if (self.didStartInitialPulseAnimation) {
        return;
    }
    self.didStartInitialPulseAnimation = YES;
    [self startPulseAnimation];
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

- (void)configureAnchorCircle {
    MTCCircle *circle = [self anchorCircleForState:self.formState];
    self.anchorCircle = circle;
    self.editingAnchorCircle = circle;
    [self.mapView addOverlay:circle];
    [self.mapTestSupport syncOverlayCount:1];
}

#pragma mark - Sheet

- (void)showSettingsSheet {
    MTCCircle *currentCircle = [self currentAnchorCircle];
    self.editingAnchorCircle = currentCircle;
    self.draftFormState = currentCircle
        ? [self stateFromAnchorCircle:currentCircle preservingPreviousState:self.formState]
        : [self defaultFormState];

    __weak typeof(self) weakSelf = self;
    __block ExampleSettingsSheetView *sheet = nil;
    sheet = [[ExampleSettingsSheetView alloc] initWithTitle:[self localizedStringForKey:@"common_settings_sheet_title"]
                                                   sections:[self sectionsForState:self.draftFormState
                                                                            action:^{
        [weakSelf replacePulseCircleWithState:weakSelf.draftFormState
                        pulseAnimationRunning:weakSelf.pulseAnimationRunning
                                     recenter:YES];
        [sheet dismissAnimated:YES];
    } startAction:^{
        [weakSelf startPulseAnimationWithState:weakSelf.draftFormState];
        [sheet dismissAnimated:YES];
    } stopAction:^{
        [weakSelf stopPulseAnimationWithState:weakSelf.draftFormState];
        [sheet dismissAnimated:YES];
    }]];
    [sheet showInView:self.view animated:YES];
}

- (NSArray<ExampleSettingsSection *> *)sectionsForState:(OverlayPulseAnimationCircleExampleFormState *)state
                                                 action:(dispatch_block_t)action
                                            startAction:(dispatch_block_t)startAction
                                             stopAction:(dispatch_block_t)stopAction {
    __weak OverlayPulseAnimationCircleExampleFormState *weakState = state;
    __weak typeof(self) weakSelf = self;
    void (^syncState)(void) = ^{
        [weakSelf syncEditingAnchorCircleForState:weakState];
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
                NSString *hexValue = OverlayPulseAnimationCircleExampleNormalizeHexString(value, @"#3F7BF9");
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
        [ExampleSettingsSection sectionWithTitle:[self localizedStringForKey:@"overlay_pulse_animation"] items:@[
            [ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"overlay_start_radius"]
                                             minimum:1.0
                                             maximum:500.0
                                                step:1.0
                                              getter:^double {
                return weakState.pulseMinimumRadius;
            } setter:^(double value) {
                weakState.pulseMinimumRadius = value;
                syncState();
            } formatter:^NSString *(double value) {
                return [NSString stringWithFormat:@"%.0f", value];
            }],
            [ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"overlay_target_radius"]
                                             minimum:1.0
                                             maximum:500.0
                                                step:1.0
                                              getter:^double {
                return weakState.pulseMaximumRadius;
            } setter:^(double value) {
                weakState.pulseMaximumRadius = value;
                syncState();
            } formatter:^NSString *(double value) {
                return [NSString stringWithFormat:@"%.0f", value];
            }],
            [ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"overlay_animation_duration_ms"]
                                             minimum:100.0
                                             maximum:10000.0
                                                step:100.0
                                              getter:^double {
                return weakState.pulseDurationMilliseconds;
            } setter:^(double value) {
                weakState.pulseDurationMilliseconds = value;
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
    if (self.pulseAnimationRunning) {
        [self startPulseAnimation];
        return;
    }
    [self updateAnchorCircle];
}

- (void)startPulseAnimationWithState:(OverlayPulseAnimationCircleExampleFormState *)state {
    if (state) {
        self.formState = [state copy];
    }
    [self startPulseAnimation];
}

- (void)stopPulseAnimationWithState:(OverlayPulseAnimationCircleExampleFormState *)state {
    if (state) {
        self.formState = [state copy];
    }
    [self stopPulseAnimationClearingRipples:YES];
    [self updateAnchorCircle];
}

- (void)startPulseAnimation {
    [self stopPulseAnimationClearingRipples:YES];
    if (!self.anchorCircle) {
        return;
    }
    self.pulseAnimationRunning = YES;
    [self updateAnchorCircle];
    [self emitRippleWave];
    [self schedulePulseEmitter];
}

- (void)stopPulseAnimationClearingRipples:(BOOL)clearRipples {
    self.pulseAnimationRunning = NO;
    [self.pulseEmitterTimer invalidate];
    self.pulseEmitterTimer = nil;
    if (clearRipples) {
        [self clearActiveRipples];
    }
}

- (void)schedulePulseEmitter {
    NSTimeInterval interval = MAX([self pulseDurationForState:self.formState] / 2.0, 0.1);
    __weak typeof(self) weakSelf = self;
    NSTimer *timer = [NSTimer timerWithTimeInterval:interval repeats:YES block:^(__unused NSTimer *timer) {
        [weakSelf emitRippleWave];
    }];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    self.pulseEmitterTimer = timer;
}

- (void)emitRippleWave {
    if (!self.pulseAnimationRunning || !self.anchorCircle) {
        return;
    }

    double minimumRadius = [self pulseMinimumRadiusForState:self.formState];
    double maximumRadius = [self pulseMaximumRadiusForState:self.formState];
    NSTimeInterval duration = [self pulseDurationForState:self.formState];

    MTCCircle *ripple = [[MTCCircle alloc] initWithCenter:self.anchorCircle.center radius:minimumRadius];
    ripple.renderMode = MTCCircleRenderModeScreen;
    ripple.draggable = NO;
    ripple.zIndex = self.anchorCircle.zIndex - 1;
    ripple.style = [self rippleStyleForState:self.formState
                                minimumRadius:minimumRadius
                                maximumRadius:maximumRadius
                                     duration:duration];
    [self.activeRipples addObject:ripple];
    [self.mapView addOverlay:ripple];

    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((duration + 0.05) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakSelf removeRippleIfActive:ripple];
    });
}

- (void)removeRippleIfActive:(MTCCircle *)ripple {
    NSUInteger index = [self.activeRipples indexOfObjectIdenticalTo:ripple];
    if (index == NSNotFound) {
        return;
    }
    [self.activeRipples removeObjectAtIndex:index];
    [self.mapView removeOverlay:ripple];
}

- (void)clearActiveRipples {
    if (self.activeRipples.count == 0) {
        return;
    }
    NSArray<MTCCircle *> *ripples = [self.activeRipples copy];
    [self.activeRipples removeAllObjects];
    [self.mapView removeOverlays:ripples];
}

- (void)updateAnchorCircle {
    MTCCircle *anchorCircle = self.anchorCircle;
    if (!anchorCircle) {
        return;
    }

    [self.mapView performOverlayUpdates:^{
        [self applyState:self.formState toAnchorCircle:anchorCircle];
    }];
}

#pragma mark - State

- (OverlayPulseAnimationCircleExampleFormState *)defaultFormState {
    OverlayPulseAnimationCircleExampleFormState *state = [[OverlayPulseAnimationCircleExampleFormState alloc] init];
    state.center = [self defaultCoordinate];
    state.fillColorHex = @"#3F7BF9";
    state.fillColorIndex = [self indexForColorHex:state.fillColorHex fallbackIndex:0];
    state.fillOpacity = 0.5;
    state.draggable = NO;
    state.pulseMinimumRadius = 30.0;
    state.pulseMaximumRadius = 150.0;
    state.pulseDurationMilliseconds = 2000.0;
    return state;
}

- (OverlayPulseAnimationCircleExampleFormState *)stateFromAnchorCircle:(MTCCircle *)circle
                                                preservingPreviousState:(OverlayPulseAnimationCircleExampleFormState *)previousState {
    OverlayPulseAnimationCircleExampleFormState *state = previousState ? [previousState copy] : [self defaultFormState];
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

- (MTCCircle *)currentAnchorCircle {
    return self.anchorCircle;
}

- (void)replacePulseCircleWithState:(OverlayPulseAnimationCircleExampleFormState *)state
              pulseAnimationRunning:(BOOL)pulseAnimationRunning
                           recenter:(BOOL)recenter {
    if (!state) {
        return;
    }

    CLLocationCoordinate2D center = state.center;
    [self stopPulseAnimationClearingRipples:YES];
    [self removeAnchorCircle];
    [self addAnchorCircleWithState:state];
    if (pulseAnimationRunning) {
        [self startPulseAnimation];
    }
    if (recenter) {
        [self focusCoordinate:center animated:YES];
    }
}

- (void)addAnchorCircleWithState:(OverlayPulseAnimationCircleExampleFormState *)state {
    if (!state) {
        return;
    }

    MTCCircle *circle = [self anchorCircleForState:state];
    self.anchorCircle = circle;
    self.formState = [state copy];
    self.editingAnchorCircle = circle;
    [self.mapView addOverlay:circle];
    [self.mapTestSupport syncOverlayCount:1];
}

- (void)removeAnchorCircle {
    if (self.anchorCircle) {
        [self.mapView removeOverlay:self.anchorCircle];
    }
    self.anchorCircle = nil;
    self.editingAnchorCircle = nil;
    [self.mapTestSupport syncOverlayCount:0];
}

- (void)syncEditingAnchorCircleForState:(OverlayPulseAnimationCircleExampleFormState *)state {
    MTCCircle *anchorCircle = self.editingAnchorCircle;
    if (!anchorCircle || anchorCircle != self.anchorCircle || !state) {
        return;
    }

    self.formState = [state copy];
    [self updateCurrentCirclePreservingAnimationState];
}

- (MTCCircle *)anchorCircleForState:(OverlayPulseAnimationCircleExampleFormState *)state {
    MTCCircle *circle = [[MTCCircle alloc] initWithCenter:state.center
                                                   radius:[self pulseMinimumRadiusForState:state]];
    [self applyState:state toAnchorCircle:circle];
    return circle;
}

- (void)applyState:(OverlayPulseAnimationCircleExampleFormState *)state toAnchorCircle:(MTCCircle *)circle {
    circle.center = state.center;
    circle.radius = [self pulseMinimumRadiusForState:state];
    circle.renderMode = MTCCircleRenderModeScreen;
    circle.draggable = state.draggable;
    circle.zIndex = 10;
    circle.style = [self baseStyleForState:state];
}

- (CLLocationCoordinate2D)defaultCoordinate {
    return CLLocationCoordinate2DMake(OverlayPulseAnimationCircleExampleDefaultLatitude,
                                      OverlayPulseAnimationCircleExampleDefaultLongitude);
}

- (void)focusCoordinate:(CLLocationCoordinate2D)coordinate animated:(BOOL)animated {
    if (animated) {
        [self.mapView setCenterCoordinate:coordinate transition:[MTCCameraTransition easeWithDuration:0.25] completion:nil];
    } else {
        [self.mapView setCenterCoordinate:coordinate zoomLevel:OverlayPulseAnimationCircleExampleDefaultZoomLevel];
    }
}

- (MTCCircleStyle *)baseStyleForState:(OverlayPulseAnimationCircleExampleFormState *)state {
    MTCCircleStyle *style = [[MTCCircleStyle alloc] init];
    style.fillColor = [self colorFromHexString:state.fillColorHex fallbackHex:@"#3F7BF9"];
    style.fillOpacity = OverlayPulseAnimationCircleExampleClamp(state.fillOpacity, 0.0, 1.0);
    style.strokeColor = UIColor.clearColor;
    style.strokeWeight = 0.0;
    style.strokeOpacity = 0.0;
    return style;
}

- (MTCCircleStyle *)rippleStyleForState:(OverlayPulseAnimationCircleExampleFormState *)state
                          minimumRadius:(double)minimumRadius
                          maximumRadius:(double)maximumRadius
                               duration:(NSTimeInterval)duration {
    MTCCircleStyle *style = [self baseStyleForState:state];
    style.strokeOpacity = 0.0;
    style.radiusAnimationMinimumRadius = minimumRadius;
    style.radiusAnimationMaximumRadius = maximumRadius;
    style.radiusAnimationDuration = duration;
    style.pulseDuration = duration;
    style.radiusAnimation = YES;
    style.pulseAnimation = YES;
    return style;
}

- (double)pulseMinimumRadiusForState:(OverlayPulseAnimationCircleExampleFormState *)state {
    return OverlayPulseAnimationCircleExampleClamp(state.pulseMinimumRadius, 1.0, 500.0);
}

- (double)pulseMaximumRadiusForState:(OverlayPulseAnimationCircleExampleFormState *)state {
    double minimumRadius = [self pulseMinimumRadiusForState:state];
    double maximumRadius = OverlayPulseAnimationCircleExampleClamp(state.pulseMaximumRadius, 1.0, 500.0);
    return MAX(maximumRadius, minimumRadius + 1.0);
}

- (NSTimeInterval)pulseDurationForState:(OverlayPulseAnimationCircleExampleFormState *)state {
    return OverlayPulseAnimationCircleExampleClamp(state.pulseDurationMilliseconds, 500.0, 10000.0) / 1000.0;
}

#pragma mark - Formatting

- (NSArray<NSString *> *)colorHexValues {
    return @[@"#3F7BF9", @"#FFFFFF", @"#2F80ED", @"#0B5CAD", @"#00A63E", @"#EF4444", @"#F59E0B", @"#111827", @"#000000"];
}

- (NSInteger)indexForColorHex:(NSString *)hexString fallbackIndex:(NSInteger)fallbackIndex {
    NSString *normalizedHex = OverlayPulseAnimationCircleExampleNormalizeHexString(hexString, @"");
    NSArray<NSString *> *hexValues = [self colorHexValues];
    for (NSUInteger index = 0; index < hexValues.count; ++index) {
        if ([normalizedHex isEqualToString:hexValues[index]]) {
            return (NSInteger)index;
        }
    }
    return fallbackIndex;
}

- (UIColor *)colorFromHexString:(NSString *)hexString fallbackHex:(NSString *)fallbackHex {
    NSString *normalizedHex = OverlayPulseAnimationCircleExampleNormalizeHexString(hexString, fallbackHex);
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

    NSInteger redValue = (NSInteger)lrint(OverlayPulseAnimationCircleExampleClamp(red, 0.0, 1.0) * 255.0);
    NSInteger greenValue = (NSInteger)lrint(OverlayPulseAnimationCircleExampleClamp(green, 0.0, 1.0) * 255.0);
    NSInteger blueValue = (NSInteger)lrint(OverlayPulseAnimationCircleExampleClamp(blue, 0.0, 1.0) * 255.0);
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
    self.title = [self localizedStringForKey:@"demo_title_OverlayPulseAnimationCircleExampleViewController"];
    if (self.mapView) {
        self.mapView.mapLanguage = [self mapLanguageForDemoLanguage:self.demoLanguage];
    }
    if ([self isSettingsSheetVisible:ExampleSettingsSheetView.class]) {
        [self showSettingsSheet];
    }
}
@end
