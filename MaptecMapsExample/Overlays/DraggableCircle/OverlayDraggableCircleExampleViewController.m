#import "OverlayDraggableCircleExampleViewController.h"

#import "ExampleSettingsSheetView.h"
#import "MTCExampleMapTestSupport.h"
#import "MTCExampleTestAccessibility.h"
#import "MTCExampleToastView.h"

#import <MaptecMapsKit/MaptecMapsKit.h>

static CLLocationDegrees const OverlayDraggableCircleExampleDefaultLatitude = 1.4;
static CLLocationDegrees const OverlayDraggableCircleExampleDefaultLongitude = 103.75;
static double const OverlayDraggableCircleExampleDefaultZoomLevel = 13.0;

@interface OverlayDraggableCircleExampleFormState : NSObject <NSCopying>
@property (nonatomic) CLLocationCoordinate2D center;
@property (nonatomic) double radius;
@property (nonatomic) BOOL draggable;
@end

@implementation OverlayDraggableCircleExampleFormState

- (id)copyWithZone:(NSZone *)zone {
    OverlayDraggableCircleExampleFormState *state = [[[self class] allocWithZone:zone] init];
    state.center = self.center;
    state.radius = self.radius;
    state.draggable = self.draggable;
    return state;
}

@end

@interface OverlayDraggableCircleExampleViewController () <MTCMapViewDelegate>
@property (nonatomic, strong) MTCMapView *mapView;
@property (nonatomic, strong) MTCCircle *circle;
@property (nonatomic, strong) OverlayDraggableCircleExampleFormState *formState;
@property (nonatomic, strong, nullable) OverlayDraggableCircleExampleFormState *editingState;
@property (nonatomic, weak, nullable) MTCCircle *editingCircle;
@property (nonatomic, strong) MTCExampleMapTestSupport *mapTestSupport;
@end

@implementation OverlayDraggableCircleExampleViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = UIColor.whiteColor;
    self.view.accessibilityIdentifier = @"OverlayDraggableCircleExampleViewController.screen";
    self.formState = [self defaultFormState];

    [self configureNavigationItems:NO];
    [self configureMapView];
    [self configureCircle];
    [self.mapView setCenterCoordinate:[self defaultCoordinate]
                             zoomLevel:OverlayDraggableCircleExampleDefaultZoomLevel];
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

- (NSArray<ExampleSettingsSection *> *)sectionsForState:(OverlayDraggableCircleExampleFormState *)state
                                                 action:(dispatch_block_t)action {
    __weak OverlayDraggableCircleExampleFormState *weakState = state;
    __weak typeof(self) weakSelf = self;
    void (^syncState)(void) = ^{
        [weakSelf syncEditingCircleForState:weakState];
    };
    return @[
        [ExampleSettingsSection sectionWithTitle:[self localizedStringForKey:@"overlay_behavior"] items:@[
            [[ExampleSettingsItem boolItemWithTitle:[self localizedStringForKey:@"overlay_draggable"]
                                            getter:^BOOL {
                return weakState.draggable;
            } setter:^(BOOL value) {
                weakState.draggable = value;
                syncState();
            }] withAccessibilityIdentifier:MTCExampleTestAccessibilityCircleSwitchDraggable],
        ]],
        [ExampleSettingsSection sectionWithTitle:@"" items:@[
            [[ExampleSettingsItem actionItemWithTitle:[self localizedStringForKey:@"overlay_add_b58c75"] handler:action]
             withAccessibilityIdentifier:MTCExampleTestAccessibilityCircleDrawButton],
        ]],
    ];
}

#pragma mark - State

- (OverlayDraggableCircleExampleFormState *)defaultFormState {
    OverlayDraggableCircleExampleFormState *state = [[OverlayDraggableCircleExampleFormState alloc] init];
    state.center = [self defaultCoordinate];
    state.radius = 120.0;
    state.draggable = YES;
    return state;
}

- (OverlayDraggableCircleExampleFormState *)stateFromCircle:(MTCCircle *)circle {
    OverlayDraggableCircleExampleFormState *state = [self defaultFormState];
    if (!circle) {
        return state;
    }
    state.center = circle.center;
    state.radius = circle.radius;
    state.draggable = circle.isDraggable;
    return state;
}

#pragma mark - Circle

- (MTCCircle *)currentCircle {
    return self.circle;
}

- (void)replaceCircleWithState:(OverlayDraggableCircleExampleFormState *)state recenter:(BOOL)recenter {
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

- (void)addCircleWithState:(OverlayDraggableCircleExampleFormState *)state {
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

- (void)syncEditingCircleForState:(OverlayDraggableCircleExampleFormState *)state {
    MTCCircle *circle = self.editingCircle;
    if (!circle || circle != self.circle || !state) {
        return;
    }

    [self.mapView performOverlayUpdates:^{
        [self applyState:state toCircle:circle];
    }];
    self.formState = [state copy];
}

- (MTCCircle *)circleForState:(OverlayDraggableCircleExampleFormState *)state {
    MTCCircle *circle = [[MTCCircle alloc] initWithCenter:state.center radius:state.radius];
    [self applyState:state toCircle:circle];
    return circle;
}

- (void)applyState:(OverlayDraggableCircleExampleFormState *)state toCircle:(MTCCircle *)circle {
    circle.center = state.center;
    circle.radius = state.radius;
    circle.renderMode = MTCCircleRenderModeScreen;
    circle.style = [self defaultCircleStyle];
    circle.draggable = state.draggable;
}

- (CLLocationCoordinate2D)defaultCoordinate {
    return CLLocationCoordinate2DMake(OverlayDraggableCircleExampleDefaultLatitude,
                                      OverlayDraggableCircleExampleDefaultLongitude);
}

- (void)focusCoordinate:(CLLocationCoordinate2D)coordinate animated:(BOOL)animated {
    if (animated) {
        [self.mapView setCenterCoordinate:coordinate transition:[MTCCameraTransition easeWithDuration:0.25] completion:nil];
    } else {
        [self.mapView setCenterCoordinate:coordinate zoomLevel:OverlayDraggableCircleExampleDefaultZoomLevel];
    }
}

- (MTCCircleStyle *)defaultCircleStyle {
    MTCCircleStyle *style = [[MTCCircleStyle alloc] init];
    style.fillColor = [UIColor colorWithRed:63.0 / 255.0
                                      green:123.0 / 255.0
                                       blue:249.0 / 255.0
                                      alpha:1.0];
    style.fillOpacity = 0.5;
    style.strokeColor = UIColor.whiteColor;
    style.strokeWeight = 2.0;
    style.strokeOpacity = 0.8;
    return style;
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
    self.title = [self localizedStringForKey:@"demo_title_OverlayDraggableCircleExampleViewController"];
    if (self.mapView) {
        self.mapView.mapLanguage = [self mapLanguageForDemoLanguage:self.demoLanguage];
    }
    if ([self isSettingsSheetVisible:ExampleSettingsSheetView.class]) {
        [self showSettingsSheet];
    }
}
@end
