#import "OverlayOuterGlowCircleExampleViewController.h"

#import "ExampleSettingsSheetView.h"
#import "MTCExampleMapTestSupport.h"
#import "MTCExampleTestAccessibility.h"
#import "MTCExampleToastView.h"

#import <MaptecMapsKit/MaptecMapsKit.h>

#include <math.h>

static CLLocationDegrees const OverlayOuterGlowCircleExampleDefaultLatitude = 1.4;
static CLLocationDegrees const OverlayOuterGlowCircleExampleDefaultLongitude = 103.75;
static double const OverlayOuterGlowCircleExampleDefaultZoomLevel = 13.0;

static double OverlayOuterGlowCircleExampleClamp(double value, double minimum, double maximum) {
    return fmin(fmax(value, minimum), maximum);
}

static NSString *OverlayOuterGlowCircleExampleNormalizeHexString(NSString *hexString, NSString *fallback) {
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

@interface OverlayOuterGlowCircleExampleFormState : NSObject <NSCopying>
@property (nonatomic) CLLocationCoordinate2D center;
@property (nonatomic) double radius;
@property (nonatomic) BOOL draggable;
@property (nonatomic) BOOL outerGlow;
@property (nonatomic, copy) NSString *outerGlowColorHex;
@property (nonatomic) NSInteger outerGlowColorIndex;
@property (nonatomic) double outerGlowRadius;
@end

@implementation OverlayOuterGlowCircleExampleFormState

- (id)copyWithZone:(NSZone *)zone {
    OverlayOuterGlowCircleExampleFormState *state = [[[self class] allocWithZone:zone] init];
    state.center = self.center;
    state.radius = self.radius;
    state.draggable = self.draggable;
    state.outerGlow = self.outerGlow;
    state.outerGlowColorHex = self.outerGlowColorHex;
    state.outerGlowColorIndex = self.outerGlowColorIndex;
    state.outerGlowRadius = self.outerGlowRadius;
    return state;
}

@end

@interface OverlayOuterGlowCircleExampleViewController () <MTCMapViewDelegate>
@property (nonatomic, strong) MTCMapView *mapView;
@property (nonatomic, strong) MTCCircle *circle;
@property (nonatomic, strong) OverlayOuterGlowCircleExampleFormState *formState;
@property (nonatomic, strong, nullable) OverlayOuterGlowCircleExampleFormState *editingState;
@property (nonatomic, weak, nullable) MTCCircle *editingCircle;
@property (nonatomic, strong) MTCExampleMapTestSupport *mapTestSupport;
@end

@implementation OverlayOuterGlowCircleExampleViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = UIColor.whiteColor;
    self.view.accessibilityIdentifier = @"OverlayOuterGlowCircleExampleViewController.screen";
    self.formState = [self defaultFormState];

    [self configureNavigationItems:NO];
    [self configureMapView];
    [self configureCircle];
    [self.mapView setCenterCoordinate:[self defaultCoordinate]
                             zoomLevel:OverlayOuterGlowCircleExampleDefaultZoomLevel];
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
    MTCCircle *circle = [self circleForState:self.formState];
    self.circle = circle;
    self.editingCircle = circle;
    [self.mapView addOverlay:circle];
    [self.mapTestSupport syncOverlayCount:1];
}

#pragma mark - Sheet

- (void)showSettingsSheet {
    MTCCircle *currentCircle = [self currentCircle];
    self.editingCircle = currentCircle;
    self.editingState = currentCircle ? [self stateFromCircle:currentCircle] : [self defaultFormState];

    __weak typeof(self) weakSelf = self;
    __block ExampleSettingsSheetView *sheet = nil;
    sheet = [[ExampleSettingsSheetView alloc] initWithTitle:[self localizedStringForKey:@"common_settings_sheet_title"]
                                                   sections:[self sectionsForState:self.editingState action:^{
        [weakSelf replaceCircleWithState:weakSelf.editingState recenter:YES];
        [sheet dismissAnimated:YES];
    }]];
    [sheet showInView:self.view animated:YES];
}

- (NSArray<ExampleSettingsSection *> *)sectionsForState:(OverlayOuterGlowCircleExampleFormState *)state
                                                 action:(dispatch_block_t)action {
    __weak OverlayOuterGlowCircleExampleFormState *weakState = state;
    __weak typeof(self) weakSelf = self;
    void (^syncState)(void) = ^{
        [weakSelf syncEditingCircleForState:weakState];
    };
    NSArray<NSString *> *colorOptions = [self colorHexValues];

    ExampleSettingsItem *outerGlowColorItem =
        [[ExampleSettingsItem colorInputItemWithTitle:[self localizedStringForKey:@"overlay_glow_color"]
                                          placeholder:@"#0066FF"
                                              options:colorOptions
                                      optionHexValues:colorOptions
                                           popupSize:CGSizeMake(260.0, 280.0)
                                              getter:^NSString *{
            return weakState.outerGlowColorHex ?: @"";
        } setter:^(NSString *value) {
            NSString *hexValue = OverlayOuterGlowCircleExampleNormalizeHexString(value, @"#0066FF");
            weakState.outerGlowColorHex = hexValue;
            weakState.outerGlowColorIndex = [weakSelf indexForColorHex:hexValue fallbackIndex:weakState.outerGlowColorIndex];
            syncState();
        } optionGetter:^NSInteger {
            return weakState.outerGlowColorIndex;
        } optionSetter:^(NSInteger index) {
            if (index < 0 || index >= (NSInteger)colorOptions.count) {
                return;
            }
            weakState.outerGlowColorHex = colorOptions[index];
            weakState.outerGlowColorIndex = index;
            syncState();
        }] enabledWhen:^BOOL {
            return weakState.outerGlow;
        }];

    ExampleSettingsItem *outerGlowRadiusItem =
        [[ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"overlay_glow_radius_1_30_a42c0d"]
                                          minimum:1.0
                                          maximum:30.0
                                             step:1.0
                                           getter:^double {
            return weakState.outerGlowRadius;
        } setter:^(double value) {
            weakState.outerGlowRadius = value;
            syncState();
        } formatter:^NSString *(double value) {
            return [NSString stringWithFormat:@"%.0f", value];
        }] enabledWhen:^BOOL {
            return weakState.outerGlow;
        }];

    return @[
        [ExampleSettingsSection sectionWithTitle:@"" items:@[
            [[ExampleSettingsItem boolItemWithTitle:[self localizedStringForKey:@"overlay_enable_outer_glow"]
                                             getter:^BOOL {
                return weakState.outerGlow;
            } setter:^(BOOL value) {
                weakState.outerGlow = value;
                syncState();
            }] withAccessibilityIdentifier:MTCExampleTestAccessibilityCircleSwitchOuterGlow],
            outerGlowColorItem,
            outerGlowRadiusItem,
        ]],
        [ExampleSettingsSection sectionWithTitle:@"" items:@[
            [[ExampleSettingsItem actionItemWithTitle:[self localizedStringForKey:@"overlay_add_b58c75"] handler:action]
             withAccessibilityIdentifier:MTCExampleTestAccessibilityCircleDrawButton],
        ]],
    ];
}

#pragma mark - State

- (OverlayOuterGlowCircleExampleFormState *)defaultFormState {
    OverlayOuterGlowCircleExampleFormState *state = [[OverlayOuterGlowCircleExampleFormState alloc] init];
    state.center = [self defaultCoordinate];
    state.radius = 120.0;
    state.draggable = YES;
    state.outerGlow = YES;
    state.outerGlowColorHex = @"#0066FF";
    state.outerGlowColorIndex = [self indexForColorHex:state.outerGlowColorHex fallbackIndex:0];
    state.outerGlowRadius = 10.0;
    return state;
}

- (OverlayOuterGlowCircleExampleFormState *)stateFromCircle:(MTCCircle *)circle {
    OverlayOuterGlowCircleExampleFormState *state = [self defaultFormState];
    if (!circle) {
        return state;
    }
    state.center = circle.center;
    state.radius = circle.radius;
    state.draggable = circle.isDraggable;
    state.outerGlow = circle.style.isOuterGlowEnabled;
    state.outerGlowColorHex = [self hexStringFromColor:circle.style.outerGlowColor fallbackHex:state.outerGlowColorHex];
    state.outerGlowColorIndex = [self indexForColorHex:state.outerGlowColorHex fallbackIndex:state.outerGlowColorIndex];
    state.outerGlowRadius = circle.style.outerGlowRadius;
    return state;
}

#pragma mark - Circle

- (MTCCircle *)currentCircle {
    return self.circle;
}

- (void)replaceCircleWithState:(OverlayOuterGlowCircleExampleFormState *)state recenter:(BOOL)recenter {
    if (!state) {
        return;
    }

    CLLocationCoordinate2D center = state.center;
    [self removeCircle];
    [self addCircleWithState:state];
    if (recenter) {
        [self focusCoordinate:center animated:YES];
    }
}

- (void)addCircleWithState:(OverlayOuterGlowCircleExampleFormState *)state {
    if (!state) {
        return;
    }

    MTCCircle *circle = [self circleForState:state];
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

- (void)syncEditingCircleForState:(OverlayOuterGlowCircleExampleFormState *)state {
    MTCCircle *circle = self.editingCircle;
    if (!circle || circle != self.circle || !state) {
        return;
    }

    [self.mapView performOverlayUpdates:^{
        [self applyState:state toCircle:circle];
    }];
    self.formState = [state copy];
}

- (MTCCircle *)circleForState:(OverlayOuterGlowCircleExampleFormState *)state {
    MTCCircle *circle = [[MTCCircle alloc] initWithCenter:state.center radius:state.radius];
    [self applyState:state toCircle:circle];
    return circle;
}

- (void)applyState:(OverlayOuterGlowCircleExampleFormState *)state toCircle:(MTCCircle *)circle {
    circle.center = state.center;
    circle.radius = state.radius;
    circle.renderMode = MTCCircleRenderModeScreen;
    circle.draggable = state.draggable;
    circle.style = [self styleForState:state];
}

- (CLLocationCoordinate2D)defaultCoordinate {
    return CLLocationCoordinate2DMake(OverlayOuterGlowCircleExampleDefaultLatitude,
                                      OverlayOuterGlowCircleExampleDefaultLongitude);
}

- (void)focusCoordinate:(CLLocationCoordinate2D)coordinate animated:(BOOL)animated {
    if (animated) {
        [self.mapView setCenterCoordinate:coordinate transition:[MTCCameraTransition easeWithDuration:0.25] completion:nil];
    } else {
        [self.mapView setCenterCoordinate:coordinate zoomLevel:OverlayOuterGlowCircleExampleDefaultZoomLevel];
    }
}

- (MTCCircleStyle *)styleForState:(OverlayOuterGlowCircleExampleFormState *)state {
    MTCCircleStyle *style = [[MTCCircleStyle alloc] init];
    style.fillColor = [UIColor colorWithRed:63.0 / 255.0
                                      green:123.0 / 255.0
                                        blue:249.0 / 255.0
                                       alpha:1.0];
    style.fillOpacity = 0.5;
    style.strokeColor = UIColor.whiteColor;
    style.strokeWeight = 2.0;
    style.strokeOpacity = 0.8;
    style.outerGlow = state.outerGlow;
    style.outerGlowColor = [self colorFromHexString:state.outerGlowColorHex fallbackHex:@"#0066FF"];
    style.outerGlowRadius = OverlayOuterGlowCircleExampleClamp(state.outerGlowRadius, 1.0, 30.0);
    return style;
}

#pragma mark - Formatting

- (NSArray<NSString *> *)colorHexValues {
    return @[@"#0066FF", @"#3F7BF9", @"#000000", @"#FFFFFF", @"#2F80ED", @"#0B5CAD", @"#00A63E", @"#EF4444", @"#F59E0B", @"#111827"];
}

- (NSInteger)indexForColorHex:(NSString *)hexString fallbackIndex:(NSInteger)fallbackIndex {
    NSString *normalizedHex = OverlayOuterGlowCircleExampleNormalizeHexString(hexString, @"");
    NSArray<NSString *> *hexValues = [self colorHexValues];
    for (NSUInteger index = 0; index < hexValues.count; ++index) {
        if ([normalizedHex isEqualToString:hexValues[index]]) {
            return (NSInteger)index;
        }
    }
    return fallbackIndex;
}

- (UIColor *)colorFromHexString:(NSString *)hexString fallbackHex:(NSString *)fallbackHex {
    NSString *normalizedHex = OverlayOuterGlowCircleExampleNormalizeHexString(hexString, fallbackHex);
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

    NSInteger redValue = (NSInteger)lrint(OverlayOuterGlowCircleExampleClamp(red, 0.0, 1.0) * 255.0);
    NSInteger greenValue = (NSInteger)lrint(OverlayOuterGlowCircleExampleClamp(green, 0.0, 1.0) * 255.0);
    NSInteger blueValue = (NSInteger)lrint(OverlayOuterGlowCircleExampleClamp(blue, 0.0, 1.0) * 255.0);
    return [NSString stringWithFormat:@"#%02lX%02lX%02lX", (long)redValue, (long)greenValue, (long)blueValue];
}

#pragma mark - Toast

- (void)showToast:(NSString *)message {
    [MTCExampleToastView showMessage:message inView:self.view];
}

#pragma mark - MTCMapViewDelegate

- (void)mapView:(MTCMapView *)mapView didBeginDraggingOverlay:(id<MTCOverlay>)overlay {
    (void)mapView;
    MTCCircle *circle = [(id)overlay isKindOfClass:MTCCircle.class] ? (MTCCircle *)overlay : nil;
    if (circle == self.circle) {
        [self showToast:[self localizedStringForKey:@"overlay_started_dragging_circle"]];
    }
}

- (void)mapView:(MTCMapView *)mapView didEndDraggingOverlay:(id<MTCOverlay>)overlay {
    (void)mapView;
    MTCCircle *circle = [(id)overlay isKindOfClass:MTCCircle.class] ? (MTCCircle *)overlay : nil;
    if (circle == self.circle) {
        [self showToast:[self localizedStringForKey:@"overlay_finished_dragging_circle"]];
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
    self.title = [self localizedStringForKey:@"demo_title_OverlayOuterGlowCircleExampleViewController"];
    if (self.mapView) {
        self.mapView.mapLanguage = [self mapLanguageForDemoLanguage:self.demoLanguage];
    }
    if ([self isSettingsSheetVisible:ExampleSettingsSheetView.class]) {
        [self showSettingsSheet];
    }
}
@end
