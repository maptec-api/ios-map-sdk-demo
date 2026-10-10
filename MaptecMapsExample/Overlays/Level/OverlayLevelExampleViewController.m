#import "OverlayLevelExampleViewController.h"

#import "ExampleSettingsSheetView.h"
#import "MTCExampleMapTestSupport.h"
#import "MTCExampleTestAccessibility.h"

#import <MaptecMapsKit/MaptecMapsKit.h>

#include <math.h>

static CLLocationDegrees const OverlayLevelExampleLatitude = 1.3048264556208515;
static CLLocationDegrees const OverlayLevelExampleLongitude = 103.83052199958921;
static double const OverlayLevelExampleDefaultZoomLevel = 16.0;

@interface OverlayLevelExampleItemState : NSObject <NSCopying>
@property (nonatomic) NSInteger levelIndex;
@property (nonatomic) NSInteger zIndex;
@end

@implementation OverlayLevelExampleItemState

- (id)copyWithZone:(NSZone *)zone {
    OverlayLevelExampleItemState *state = [[[self class] allocWithZone:zone] init];
    state.levelIndex = self.levelIndex;
    state.zIndex = self.zIndex;
    return state;
}

@end

@interface OverlayLevelExampleFormState : NSObject <NSCopying>
@property (nonatomic, strong) OverlayLevelExampleItemState *marker;
@property (nonatomic, strong) OverlayLevelExampleItemState *polyline;
@property (nonatomic, strong) OverlayLevelExampleItemState *polygon;
@property (nonatomic, strong) OverlayLevelExampleItemState *circle;
@end

@implementation OverlayLevelExampleFormState

- (id)copyWithZone:(NSZone *)zone {
    OverlayLevelExampleFormState *state = [[[self class] allocWithZone:zone] init];
    state.marker = [self.marker copy];
    state.polyline = [self.polyline copy];
    state.polygon = [self.polygon copy];
    state.circle = [self.circle copy];
    return state;
}

@end

@interface OverlayLevelExampleViewController () <MTCMapViewDelegate>
@property (nonatomic, strong) MTCMapView *mapView;
@property (nonatomic, strong) MTCExampleMapTestSupport *mapTestSupport;
@property (nonatomic, strong) OverlayLevelExampleFormState *formState;
@property (nonatomic, strong) OverlayLevelExampleFormState *editingState;
@property (nonatomic, strong, nullable) MTCMarker *marker;
@property (nonatomic, strong, nullable) MTCPolyline *polyline;
@property (nonatomic, strong, nullable) MTCPolygon *polygon;
@property (nonatomic, strong, nullable) MTCCircle *circle;
@property (nonatomic, strong) UIView *markerZIndexTestView;
@end

@implementation OverlayLevelExampleViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = UIColor.whiteColor;
    self.view.accessibilityIdentifier = MTCExampleTestAccessibilityOverlayLevelScreen;
    self.formState = [self defaultFormState];

    [self configureNavigationItems:NO];
    [self configureMapView];
    [self replaceOverlaysWithState:self.formState recenter:NO];
    [self.mapView setCenterCoordinate:[self centerCoordinate]
                             zoomLevel:OverlayLevelExampleDefaultZoomLevel];
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
    self.mapTestSupport.overlayCountValueKey = @"overlay_count";
    [self.mapTestSupport installOnHostView:self.view];

    self.markerZIndexTestView = [[UIView alloc] initWithFrame:CGRectMake(8.0, 0.0, 2.0, 2.0)];
    self.markerZIndexTestView.isAccessibilityElement = YES;
    self.markerZIndexTestView.accessibilityIdentifier = MTCExampleTestAccessibilityLevelMarkerZIndex;
    self.markerZIndexTestView.alpha = 0.01;
    self.markerZIndexTestView.userInteractionEnabled = NO;
    [self.view addSubview:self.markerZIndexTestView];
}

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

#pragma mark - Sheets

- (void)showSettingsSheet {
    self.editingState = [self hasDisplayedOverlays] ? [self stateFromDisplayedOverlays] : [self defaultFormState];

    __weak typeof(self) weakSelf = self;
    __block ExampleSettingsSheetView *sheet = nil;
    sheet = [[ExampleSettingsSheetView alloc] initWithTitle:[self localizedStringForKey:@"common_settings_sheet_title"]
                                                   sections:[self sectionsForState:self.editingState
                                                                        addAction:^{
        [weakSelf replaceOverlaysWithState:weakSelf.editingState recenter:NO];
        [sheet dismissAnimated:YES];
    } clearAction:^{
        [weakSelf clearAllOverlays];
        [sheet dismissAnimated:YES];
    }]];
    [sheet showInView:self.view animated:YES];
}

- (void)moveMarkerUp {
    self.editingState.marker.zIndex += 1;
    [self syncEditingOverlaysForState:self.editingState];
}

- (void)moveMarkerDown {
    self.editingState.marker.zIndex -= 1;
    [self syncEditingOverlaysForState:self.editingState];
}

- (NSArray<ExampleSettingsSection *> *)sectionsForState:(OverlayLevelExampleFormState *)state
                                              addAction:(dispatch_block_t)addAction
                                            clearAction:(dispatch_block_t)clearAction {
    __weak typeof(self) weakSelf = self;
    return @[
        [self sectionForTitle:[self localizedStringForKey:@"overlay_section_marker"]
                         item:state.marker],
        [self sectionForTitle:[self localizedStringForKey:@"overlay_section_polyline"]
                         item:state.polyline],
        [self sectionForTitle:[self localizedStringForKey:@"overlay_section_polygon"]
                         item:state.polygon],
        [self sectionForTitle:[self localizedStringForKey:@"overlay_section_circle"]
                         item:state.circle],
        [ExampleSettingsSection sectionWithTitle:@"" items:@[
            [[ExampleSettingsItem actionItemWithTitle:@"Move Up Marker" handler:^{
                [weakSelf moveMarkerUp];
            }] withAccessibilityIdentifier:MTCExampleTestAccessibilityLevelBtnMoveUp],
            [[ExampleSettingsItem actionItemWithTitle:@"Move Down Marker" handler:^{
                [weakSelf moveMarkerDown];
            }] withAccessibilityIdentifier:MTCExampleTestAccessibilityLevelBtnMoveDown],
            [ExampleSettingsItem actionItemWithTitle:[self localizedStringForKey:@"overlay_add_b58c75"] handler:addAction],
            [ExampleSettingsItem actionItemWithTitle:[self localizedStringForKey:@"overlay_clear_all_3358c6"] handler:clearAction],
        ]],
    ];
}

- (ExampleSettingsSection *)sectionForTitle:(NSString *)title
                                       item:(OverlayLevelExampleItemState *)itemState {
    __weak typeof(self) weakSelf = self;
    __weak OverlayLevelExampleItemState *weakItemState = itemState;
    void (^syncState)(void) = ^{
        [weakSelf syncEditingOverlaysForState:weakSelf.editingState];
    };

    return [ExampleSettingsSection sectionWithTitle:title items:@[
        [ExampleSettingsItem segmentedItemWithTitle:[self localizedStringForKey:@"overlay_level_field"]
                                           segments:[self overlayLevelTitles]
                                             getter:^NSInteger {
            return weakItemState.levelIndex;
        } setter:^(NSInteger index) {
            weakItemState.levelIndex = index;
            syncState();
        }],
        [ExampleSettingsItem numberItemWithTitle:@"zIndex"
                                         minimum:-10.0
                                         maximum:10.0
                                            step:1.0
                                          getter:^double {
            return weakItemState.zIndex;
        } setter:^(double value) {
            weakItemState.zIndex = (NSInteger)llround(value);
            syncState();
        } formatter:^NSString *(double value) {
            return [NSString stringWithFormat:@"%.0f", value];
        }],
    ]];
}

#pragma mark - Overlays

- (void)replaceOverlaysWithState:(OverlayLevelExampleFormState *)state recenter:(BOOL)recenter {
    if (!state) {
        return;
    }

    [self clearAllOverlays];

    self.marker = [self markerOverlay];
    self.polyline = [self polylineOverlay];
    self.polygon = [self polygonOverlay];
    self.circle = [self circleOverlay];

    [self applyStateToDisplayedOverlays:state];
    if (recenter) {
        [self.mapView setCenterCoordinate:[self centerCoordinate]
                               transition:[MTCCameraTransition easeWithDuration:0.25] completion:nil];
    }
}

- (void)syncEditingOverlaysForState:(OverlayLevelExampleFormState *)state {
    if (!state || ![self hasDisplayedOverlays]) {
        return;
    }

    [self applyStateToDisplayedOverlays:state];
}

- (void)applyStateToDisplayedOverlays:(OverlayLevelExampleFormState *)state {
    self.formState = [state copy];

    [self applyItemState:state.marker
               toOverlay:self.marker];
    [self applyItemState:state.polyline
               toOverlay:self.polyline];
    [self applyItemState:state.polygon
               toOverlay:self.polygon];
    [self applyItemState:state.circle
               toOverlay:self.circle];

    if (self.marker) {
        self.markerZIndexTestView.accessibilityValue = [NSString stringWithFormat:@"%ld", (long)self.marker.zIndex];
    }
    [self.mapTestSupport syncOverlayCount:4];
}

- (void)applyItemState:(OverlayLevelExampleItemState *)itemState
             toOverlay:(nullable id<MTCOverlay>)overlay {
    if (!itemState || !overlay) {
        return;
    }

    overlay.zIndex = itemState.zIndex;
    [self.mapView addOverlay:overlay level:[self overlayLevelForIndex:itemState.levelIndex]];
}

- (void)clearAllOverlays {
    NSMutableArray<id<MTCOverlay>> *overlays = [NSMutableArray array];
    if (self.marker) {
        [overlays addObject:self.marker];
    }
    if (self.polyline) {
        [overlays addObject:self.polyline];
    }
    if (self.polygon) {
        [overlays addObject:self.polygon];
    }
    if (self.circle) {
        [overlays addObject:self.circle];
    }
    if (overlays.count > 0) {
        [self.mapView removeOverlays:overlays];
    }

    self.marker = nil;
    self.polyline = nil;
    self.polygon = nil;
    self.circle = nil;
    [self.mapTestSupport syncOverlayCount:0];
}

- (BOOL)hasDisplayedOverlays {
    return self.marker || self.polyline || self.polygon || self.circle;
}

- (OverlayLevelExampleFormState *)stateFromDisplayedOverlays {
    OverlayLevelExampleFormState *state = self.formState ? [self.formState copy] : [self defaultFormState];
    if (self.marker) {
        state.marker.zIndex = self.marker.zIndex;
    }
    if (self.polyline) {
        state.polyline.zIndex = self.polyline.zIndex;
    }
    if (self.polygon) {
        state.polygon.zIndex = self.polygon.zIndex;
    }
    if (self.circle) {
        state.circle.zIndex = self.circle.zIndex;
    }
    return state;
}

- (MTCMarker *)markerOverlay {
    MTCMarker *marker = [[MTCMarker alloc] initWithCoordinate:[self centerCoordinate]];
    MTCMarkerStyle *style = [[MTCMarkerStyle alloc] init];
    style.icon.type = MTCMarkerIconTypeRedDot;
    style.icon.size = CGSizeMake(36.0, 36.0);
    style.title.text = @"Marker";
    style.title.fontSize = 12.0;
    marker.style = style;
    return marker;
}

- (MTCPolyline *)polylineOverlay {
    CLLocationCoordinate2D coordinates[] = {
        CLLocationCoordinate2DMake(OverlayLevelExampleLatitude - 0.0022, OverlayLevelExampleLongitude - 0.0025),
        [self centerCoordinate],
        CLLocationCoordinate2DMake(OverlayLevelExampleLatitude + 0.0022, OverlayLevelExampleLongitude + 0.0025),
    };
    MTCPolyline *polyline = [[MTCPolyline alloc] initWithCoordinates:coordinates count:3];
    MTCPolylineStyle *style = [[MTCPolylineStyle alloc] init];
    style.strokeColor = [UIColor colorWithRed:1.0 green:0.47 blue:0.0 alpha:1.0];
    style.strokeWeight = 8.0;
    style.strokeOpacity = 0.92;
    polyline.style = style;
    return polyline;
}

- (MTCPolygon *)polygonOverlay {
    CLLocationCoordinate2D coordinates[] = {
        CLLocationCoordinate2DMake(OverlayLevelExampleLatitude - 0.0016, OverlayLevelExampleLongitude - 0.0020),
        CLLocationCoordinate2DMake(OverlayLevelExampleLatitude - 0.0016, OverlayLevelExampleLongitude + 0.0020),
        CLLocationCoordinate2DMake(OverlayLevelExampleLatitude + 0.0016, OverlayLevelExampleLongitude + 0.0020),
        CLLocationCoordinate2DMake(OverlayLevelExampleLatitude + 0.0016, OverlayLevelExampleLongitude - 0.0020),
    };
    MTCPolygon *polygon = [[MTCPolygon alloc] initWithCoordinates:coordinates count:4];
    MTCPolygonStyle *style = [[MTCPolygonStyle alloc] init];
    style.fillColor = [UIColor colorWithRed:0.32 green:0.36 blue:0.92 alpha:1.0];
    style.fillOpacity = 0.35;
    style.strokeColor = [UIColor colorWithRed:0.12 green:0.16 blue:0.72 alpha:1.0];
    style.strokeWeight = 3.0;
    style.strokeOpacity = 0.9;
    polygon.style = style;
    return polygon;
}

- (MTCCircle *)circleOverlay {
    MTCCircle *circle = [[MTCCircle alloc] initWithCenter:[self centerCoordinate] radius:220.0];
    circle.renderMode = MTCCircleRenderModeGeographic;
    MTCCircleStyle *style = [[MTCCircleStyle alloc] init];
    style.fillColor = [UIColor colorWithRed:0.0 green:0.65 blue:0.42 alpha:1.0];
    style.fillOpacity = 0.24;
    style.strokeColor = [UIColor colorWithRed:0.0 green:0.45 blue:0.31 alpha:1.0];
    style.strokeWeight = 4.0;
    style.strokeOpacity = 0.9;
    circle.style = style;
    return circle;
}

#pragma mark - State

- (OverlayLevelExampleFormState *)defaultFormState {
    OverlayLevelExampleFormState *state = [[OverlayLevelExampleFormState alloc] init];
    state.marker = [self itemStateWithLevelIndex:0 zIndex:3];
    state.polyline = [self itemStateWithLevelIndex:0 zIndex:2];
    state.polygon = [self itemStateWithLevelIndex:0 zIndex:1];
    state.circle = [self itemStateWithLevelIndex:0 zIndex:0];
    return state;
}

- (OverlayLevelExampleItemState *)itemStateWithLevelIndex:(NSInteger)levelIndex
                                                   zIndex:(NSInteger)zIndex {
    OverlayLevelExampleItemState *state = [[OverlayLevelExampleItemState alloc] init];
    state.levelIndex = levelIndex;
    state.zIndex = zIndex;
    return state;
}

- (MTCOverlayLevel)overlayLevelForIndex:(NSInteger)index {
    return index == 1 ? MTCOverlayLevelLayerAfter : MTCOverlayLevelDefault;
}

- (NSArray<NSString *> *)overlayLevelTitles {
    return @[
        [self localizedStringForKey:@"overlay_level_default"],
        [self localizedStringForKey:@"overlay_level_layer_after"],
    ];
}

- (CLLocationCoordinate2D)centerCoordinate {
    return CLLocationCoordinate2DMake(OverlayLevelExampleLatitude, OverlayLevelExampleLongitude);
}

#pragma mark - Language

- (void)handleExampleSettingsAction {
    [self showSettingsSheet];
}

- (void)demoLanguageDidChange {
    [self applyLocalizedTexts];
}

- (void)applyLocalizedTexts {
    self.title = [self localizedStringForKey:@"demo_title_OverlayLevelExampleViewController"];
    if (self.mapView) {
        self.mapView.mapLanguage = [self mapLanguageForDemoLanguage:self.demoLanguage];
    }
    if ([self isSettingsSheetVisible:ExampleSettingsSheetView.class]) {
        [self showSettingsSheet];
    }
}

@end
