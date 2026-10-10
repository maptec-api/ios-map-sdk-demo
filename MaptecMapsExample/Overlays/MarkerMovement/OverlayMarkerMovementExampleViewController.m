#import "OverlayMarkerMovementExampleViewController.h"

#import "ExampleSettingsSheetView.h"
#import "MTCExampleMapTestSupport.h"
#import "MTCExampleTestAccessibility.h"
#import "MTCExampleToastView.h"
#import "MTCMockRouteLocationProvider.h"

#import <MaptecMapsKit/MaptecMapsKit.h>

#include <math.h>

static CLLocationDegrees const OverlayMarkerMovementExampleSingaporeLatitude = 1.3048264556208515;
static CLLocationDegrees const OverlayMarkerMovementExampleSingaporeLongitude = 103.83052199958921;
static double const OverlayMarkerMovementExampleDefaultZoomLevel = 13.0;

static double OverlayMarkerMovementExampleClampDouble(double value, double minimum, double maximum) {
    return fmin(fmax(value, minimum), maximum);
}

static double OverlayMarkerMovementExampleDoubleFromString(NSString *value, double fallback, double minimum, double maximum) {
    NSString *trimmedValue = [value stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (trimmedValue.length == 0) {
        return fallback;
    }

    double parsedValue = 0.0;
    NSScanner *scanner = [NSScanner scannerWithString:trimmedValue];
    if (![scanner scanDouble:&parsedValue]) {
        return fallback;
    }
    return OverlayMarkerMovementExampleClampDouble(parsedValue, minimum, maximum);
}

typedef NS_ENUM(NSInteger, OverlayMarkerMovementExampleMovementType) {
    OverlayMarkerMovementExampleMovementTypePoint = 0,
    OverlayMarkerMovementExampleMovementTypePath,
};

@interface OverlayMarkerMovementExampleFormState : NSObject <NSCopying>
@property (nonatomic) NSInteger movementTypeIndex;
@property (nonatomic) double startLatitude;
@property (nonatomic) double startLongitude;
@property (nonatomic) double targetLatitude;
@property (nonatomic) double targetLongitude;
@property (nonatomic) double pointDurationSeconds;
@property (nonatomic) NSInteger pathTimingModeIndex;
@property (nonatomic) double pathDurationSeconds;
@property (nonatomic) double pathSpeedMetersPerSecond;
@property (nonatomic) BOOL autoRotate;
@property (nonatomic) double headingOffset;
@property (nonatomic) double orientationSmoothingDuration;
@property (nonatomic) double progressCallbackInterval;
@property (nonatomic) NSInteger cancelBehaviorIndex;
@property (nonatomic) NSInteger backgroundBehaviorIndex;
@property (nonatomic) double progressValue;
@property (nonatomic) double currentLatitude;
@property (nonatomic) double currentLongitude;
@property (nonatomic) double currentHeading;
@property (nonatomic) BOOL headingAvailable;
@property (nonatomic, copy) NSString *statusKey;
@end

@implementation OverlayMarkerMovementExampleFormState

- (id)copyWithZone:(NSZone *)zone {
    OverlayMarkerMovementExampleFormState *state = [[[self class] allocWithZone:zone] init];
    state.movementTypeIndex = self.movementTypeIndex;
    state.startLatitude = self.startLatitude;
    state.startLongitude = self.startLongitude;
    state.targetLatitude = self.targetLatitude;
    state.targetLongitude = self.targetLongitude;
    state.pointDurationSeconds = self.pointDurationSeconds;
    state.pathTimingModeIndex = self.pathTimingModeIndex;
    state.pathDurationSeconds = self.pathDurationSeconds;
    state.pathSpeedMetersPerSecond = self.pathSpeedMetersPerSecond;
    state.autoRotate = self.autoRotate;
    state.headingOffset = self.headingOffset;
    state.orientationSmoothingDuration = self.orientationSmoothingDuration;
    state.progressCallbackInterval = self.progressCallbackInterval;
    state.cancelBehaviorIndex = self.cancelBehaviorIndex;
    state.backgroundBehaviorIndex = self.backgroundBehaviorIndex;
    state.progressValue = self.progressValue;
    state.currentLatitude = self.currentLatitude;
    state.currentLongitude = self.currentLongitude;
    state.currentHeading = self.currentHeading;
    state.headingAvailable = self.headingAvailable;
    state.statusKey = self.statusKey;
    return state;
}

@end

@interface OverlayMarkerMovementExampleViewController () <MTCMapViewDelegate>
@property (nonatomic, strong) MTCMapView *mapView;
@property (nonatomic, strong) MTCExampleMapTestSupport *mapTestSupport;
@property (nonatomic, strong) OverlayMarkerMovementExampleFormState *formState;
@property (nonatomic, strong, nullable) MTCMarker *marker;
@property (nonatomic, strong, nullable) MTCPolyline *routePolyline;
@property (nonatomic, strong, nullable) MTCMarkerMovementTask *movementTask;
@property (nonatomic, weak, nullable) ExampleSettingsSheetView *settingsSheet;
@property (nonatomic, strong) MTCMockRouteLocationProvider *mockRouteProvider;
@end

@implementation OverlayMarkerMovementExampleViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = UIColor.whiteColor;
    self.view.accessibilityIdentifier = MTCExampleTestAccessibilityOverlayMarkerMovementScreen;
    self.mockRouteProvider = [[MTCMockRouteLocationProvider alloc] initWithRouteID:@"walking_city_roads"];
    self.formState = [self defaultMovementState];

    [self configureNavigationItems:NO];
    [self configureMapView];
    [self replaceOverlaysWithState:self.formState recenter:NO showToast:NO];
    [self applyLocalizedTexts];
}

- (void)dealloc {
    [self.movementTask cancelWithError:nil];
}

#pragma mark - Setup

- (void)configureMapView {
    self.mapView = [[MTCMapView alloc] initWithFrame:self.view.bounds];
    self.mapView.delegate = self;
    self.mapView.uiSettings.zoomLevelVisible = YES;
    self.mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.mapView];

    self.mapTestSupport = [[MTCExampleMapTestSupport alloc] init];
    self.mapTestSupport.overlayCountValueKey = MTCExampleTestAccessibilityMarkerCountValueKey;
    [self.mapTestSupport installOnHostView:self.view];
    [self syncMarkerTestAccessibilityState];
}

#pragma mark - Sheets

- (void)showMovementSheet {
    self.formState = self.marker ? [self stateFromCurrentOverlays] : [self defaultMovementState];

    __weak typeof(self) weakSelf = self;
    __block ExampleSettingsSheetView *sheet = nil;
    sheet = [[ExampleSettingsSheetView alloc] initWithTitle:[self localizedStringForKey:@"common_settings_sheet_title"]
                                                   sections:[self sectionsForState:self.formState
                                                                         addAction:^{
        [weakSelf replaceOverlaysWithState:weakSelf.formState recenter:YES showToast:YES];
        [sheet dismissAnimated:YES];
    } clearAction:^{
        [weakSelf clearAllOverlaysShowingToast:YES];
        [sheet dismissAnimated:YES];
    }]];
    self.settingsSheet = sheet;
    [sheet showInView:self.view animated:YES];
}

- (NSArray<ExampleSettingsSection *> *)sectionsForState:(OverlayMarkerMovementExampleFormState *)state
                                              addAction:(ExampleSettingsActionHandler)addAction
                                            clearAction:(ExampleSettingsActionHandler)clearAction {
    __weak typeof(self) weakSelf = self;
    __weak OverlayMarkerMovementExampleFormState *weakState = state;
    void (^syncState)(void) = ^{
        [weakSelf syncEditingOverlaysForState:weakState];
    };

    return @[
        [ExampleSettingsSection sectionWithTitle:[self localizedStringForKey:@"overlay_movement"] items:@[
            [ExampleSettingsItem segmentedItemWithTitle:[self localizedStringForKey:@"overlay_movement_type"]
                                               segments:@[
                [self localizedStringForKey:@"overlay_point_to_point"],
                [self localizedStringForKey:@"overlay_path_movement"],
            ] getter:^NSInteger {
                return weakState.movementTypeIndex;
            } setter:^(NSInteger index) {
                weakState.movementTypeIndex = [weakSelf clampedIndex:index count:2];
                syncState();
                [weakSelf.settingsSheet reloadData];
            }],
            [ExampleSettingsItem dynamicInfoItemWithGetter:^NSString *{
                return [weakSelf movementStatusTextForState:weakState];
            }],
        ]],
        [ExampleSettingsSection sectionWithTitle:[self localizedStringForKey:@"overlay_position"] items:@[
            [[ExampleSettingsItem textItemWithTitle:[self localizedStringForKey:@"overlay_start_coordinate"]
                                        placeholder:@"lat, lng"
                                       keyboardType:UIKeyboardTypeNumbersAndPunctuation
                                             getter:^NSString *{
                return [weakSelf startCoordinateTextForState:weakState];
            } setter:^(NSString *value) {
                [weakSelf updateStartCoordinateWithText:value state:weakState];
                syncState();
            }] enabledWhen:^BOOL {
                return weakState.movementTypeIndex == OverlayMarkerMovementExampleMovementTypePoint &&
                       ![weakSelf movementIsActive];
            }],
            [[ExampleSettingsItem textItemWithTitle:[self localizedStringForKey:@"overlay_target_coordinate"]
                                        placeholder:@"lat, lng"
                                       keyboardType:UIKeyboardTypeNumbersAndPunctuation
                                             getter:^NSString *{
                return [weakSelf targetCoordinateTextForState:weakState];
            } setter:^(NSString *value) {
                [weakSelf updateTargetCoordinateWithText:value state:weakState];
                syncState();
            }] visibleWhen:^BOOL {
                return weakState.movementTypeIndex == OverlayMarkerMovementExampleMovementTypePoint;
            }],
        ]],
        [ExampleSettingsSection sectionWithTitle:[self localizedStringForKey:@"overlay_timing"] items:@[
            [[ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"overlay_duration"]
                                             minimum:0.5
                                             maximum:20.0
                                                step:0.5
                                              getter:^double {
                return weakState.pointDurationSeconds;
            } setter:^(double value) {
                weakState.pointDurationSeconds = value;
            } formatter:^NSString *(double value) {
                return [weakSelf formatDurationValue:value];
            }] visibleWhen:^BOOL {
                return weakState.movementTypeIndex == OverlayMarkerMovementExampleMovementTypePoint;
            }],
            [[ExampleSettingsItem segmentedItemWithTitle:[self localizedStringForKey:@"overlay_timing_mode"]
                                                segments:@[
                [self localizedStringForKey:@"overlay_duration_mode"],
                [self localizedStringForKey:@"overlay_speed_mode"],
            ] getter:^NSInteger {
                return weakState.pathTimingModeIndex;
            } setter:^(NSInteger index) {
                weakState.pathTimingModeIndex = [weakSelf clampedIndex:index count:2];
                [weakSelf.settingsSheet reloadData];
            }] visibleWhen:^BOOL {
                return weakState.movementTypeIndex == OverlayMarkerMovementExampleMovementTypePath;
            }],
            [[ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"overlay_duration"]
                                             minimum:1.0
                                             maximum:60.0
                                                step:1.0
                                              getter:^double {
                return weakState.pathDurationSeconds;
            } setter:^(double value) {
                weakState.pathDurationSeconds = value;
            } formatter:^NSString *(double value) {
                return [weakSelf formatDurationValue:value];
            }] visibleWhen:^BOOL {
                return weakState.movementTypeIndex == OverlayMarkerMovementExampleMovementTypePath &&
                       weakState.pathTimingModeIndex == MTCMarkerMovementTimingModeDuration;
            }],
            [[ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"overlay_speed_mps"]
                                             minimum:0.5
                                             maximum:20.0
                                                step:0.5
                                              getter:^double {
                return weakState.pathSpeedMetersPerSecond;
            } setter:^(double value) {
                weakState.pathSpeedMetersPerSecond = value;
            } formatter:^NSString *(double value) {
                return [NSString stringWithFormat:[weakSelf localizedStringForKey:@"overlay_1f_mps"], value];
            }] visibleWhen:^BOOL {
                return weakState.movementTypeIndex == OverlayMarkerMovementExampleMovementTypePath &&
                       weakState.pathTimingModeIndex == MTCMarkerMovementTimingModeSpeed;
            }],
        ]],
        [ExampleSettingsSection sectionWithTitle:[self localizedStringForKey:@"overlay_behavior"] items:@[
            [ExampleSettingsItem boolItemWithTitle:[self localizedStringForKey:@"overlay_auto_rotate"]
                                           getter:^BOOL {
                return weakState.autoRotate;
            } setter:^(BOOL value) {
                weakState.autoRotate = value;
            }],
            [ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"overlay_heading_offset"]
                                             minimum:-180.0
                                             maximum:180.0
                                                step:5.0
                                              getter:^double {
                return weakState.headingOffset;
            } setter:^(double value) {
                weakState.headingOffset = value;
            } formatter:^NSString *(double value) {
                return [NSString stringWithFormat:@"%.0f deg", value];
            }],
            [ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"overlay_orientation_smoothing_duration"]
                                             minimum:0.0
                                             maximum:1.0
                                                step:0.05
                                              getter:^double {
                return weakState.orientationSmoothingDuration;
            } setter:^(double value) {
                weakState.orientationSmoothingDuration = value;
            } formatter:^NSString *(double value) {
                return [weakSelf formatDurationValue:value];
            }],
            [ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"overlay_progress_callback_interval"]
                                             minimum:0.0
                                             maximum:1.0
                                                step:0.05
                                              getter:^double {
                return weakState.progressCallbackInterval;
            } setter:^(double value) {
                weakState.progressCallbackInterval = value;
            } formatter:^NSString *(double value) {
                return [weakSelf formatDurationValue:value];
            }],
            [ExampleSettingsItem listItemWithTitle:[self localizedStringForKey:@"overlay_cancel_behavior"]
                                           options:[self cancelBehaviorTitles]
                                        popupSize:CGSizeMake(280.0, 180.0)
                                            getter:^NSInteger {
                return weakState.cancelBehaviorIndex;
            } setter:^(NSInteger index) {
                weakState.cancelBehaviorIndex = [weakSelf clampedIndex:index count:[weakSelf cancelBehaviorTitles].count];
            }],
            [ExampleSettingsItem listItemWithTitle:[self localizedStringForKey:@"overlay_background_behavior"]
                                           options:[self backgroundBehaviorTitles]
                                        popupSize:CGSizeMake(280.0, 140.0)
                                            getter:^NSInteger {
                return weakState.backgroundBehaviorIndex;
            } setter:^(NSInteger index) {
                weakState.backgroundBehaviorIndex = [weakSelf clampedIndex:index count:[weakSelf backgroundBehaviorTitles].count];
            }],
        ]],
        [ExampleSettingsSection sectionWithTitle:@"" items:@[
            [[ExampleSettingsItem actionItemWithTitle:[self localizedStringForKey:@"overlay_add_b58c75"] handler:addAction]
                withAccessibilityIdentifier:MTCExampleTestAccessibilitySymbolBtnAddMarker],
            [[ExampleSettingsItem actionItemWithTitle:[self localizedStringForKey:@"overlay_start_movement"] handler:^{
                [weakSelf startMovementFromCurrentState];
            }] withAccessibilityIdentifier:MTCExampleTestAccessibilityMarkerMovementStartButton],
            [[ExampleSettingsItem actionItemWithTitle:[self localizedStringForKey:@"overlay_pause_movement"] handler:^{
                [weakSelf pauseMovement];
            }] enabledWhen:^BOOL {
                return weakSelf.movementTask.state == MTCMarkerMovementStateRunning;
            }],
            [[ExampleSettingsItem actionItemWithTitle:[self localizedStringForKey:@"overlay_resume_movement"] handler:^{
                [weakSelf resumeMovement];
            }] enabledWhen:^BOOL {
                return weakSelf.movementTask.state == MTCMarkerMovementStatePaused;
            }],
            [[ExampleSettingsItem actionItemWithTitle:[self localizedStringForKey:@"overlay_finish_movement"] handler:^{
                [weakSelf finishMovement];
            }] enabledWhen:^BOOL {
                return [weakSelf movementIsActive];
            }],
            [[ExampleSettingsItem actionItemWithTitle:[self localizedStringForKey:@"overlay_cancel_movement"] handler:^{
                [weakSelf cancelMovement];
            }] enabledWhen:^BOOL {
                return [weakSelf movementIsActive];
            }],
            [[ExampleSettingsItem actionItemWithTitle:[self localizedStringForKey:@"overlay_clear_all_3358c6"] handler:clearAction]
                withAccessibilityIdentifier:MTCExampleTestAccessibilitySymbolBtnClearAll],
        ]],
    ];
}

#pragma mark - Overlay State

- (OverlayMarkerMovementExampleFormState *)defaultMovementState {
    CLLocationCoordinate2D start = [self singaporeCoordinate];
    CLLocationCoordinate2D target = CLLocationCoordinate2DMake(1.314826, 103.844522);
    CLLocationCoordinate2D pathStart = [self firstPathCoordinate];
    if (CLLocationCoordinate2DIsValid(pathStart)) {
        start = pathStart;
    }

    OverlayMarkerMovementExampleFormState *state = [[OverlayMarkerMovementExampleFormState alloc] init];
    state.movementTypeIndex = OverlayMarkerMovementExampleMovementTypePoint;
    state.startLatitude = start.latitude;
    state.startLongitude = start.longitude;
    state.targetLatitude = target.latitude;
    state.targetLongitude = target.longitude;
    state.pointDurationSeconds = 5.0;
    state.pathTimingModeIndex = MTCMarkerMovementTimingModeDuration;
    state.pathDurationSeconds = 12.0;
    state.pathSpeedMetersPerSecond = 6.0;
    state.autoRotate = YES;
    state.headingOffset = 0.0;
    state.orientationSmoothingDuration = 0.15;
    state.progressCallbackInterval = 0.1;
    state.cancelBehaviorIndex = MTCMarkerMovementCancelBehaviorKeepCurrent;
    state.backgroundBehaviorIndex = MTCMarkerMovementBackgroundBehaviorPause;
    state.progressValue = 0.0;
    state.currentLatitude = start.latitude;
    state.currentLongitude = start.longitude;
    state.currentHeading = 0.0;
    state.headingAvailable = NO;
    state.statusKey = @"overlay_movement_status_idle";
    return state;
}

- (OverlayMarkerMovementExampleFormState *)stateFromCurrentOverlays {
    OverlayMarkerMovementExampleFormState *state = [self.formState copy] ?: [self defaultMovementState];
    CLLocationCoordinate2D coordinate = self.marker.coordinate;
    if (CLLocationCoordinate2DIsValid(coordinate)) {
        state.startLatitude = coordinate.latitude;
        state.startLongitude = coordinate.longitude;
        state.currentLatitude = coordinate.latitude;
        state.currentLongitude = coordinate.longitude;
    }
    return state;
}

- (void)replaceOverlaysWithState:(OverlayMarkerMovementExampleFormState *)state
                         recenter:(BOOL)recenter
                        showToast:(BOOL)showToast {
    if (!state) {
        return;
    }

    [self clearAllOverlaysShowingToast:NO];
    self.formState = [state copy];
    [self resetMovementProgressForState:self.formState];
    [self addOverlaysWithState:self.formState];
    if (recenter) {
        [self focusState:self.formState animated:YES];
    } else {
        [self.mapView setCenterCoordinate:[self centerCoordinateForState:self.formState]
                                 zoomLevel:OverlayMarkerMovementExampleDefaultZoomLevel];
    }
    if (showToast) {
        [MTCExampleToastView showMessage:[self localizedStringForKey:@"overlay_marker_movement_added"] inView:self.view];
    }
}

- (void)addOverlaysWithState:(OverlayMarkerMovementExampleFormState *)state {
    if (state.movementTypeIndex == OverlayMarkerMovementExampleMovementTypePath) {
        [self addRoutePolyline];
    }

    CLLocationCoordinate2D coordinate = [self startCoordinateForState:state];
    if (!CLLocationCoordinate2DIsValid(coordinate)) {
        coordinate = [self singaporeCoordinate];
    }
    MTCMarker *marker = [[MTCMarker alloc] initWithCoordinate:coordinate];
    marker.style = [self markerStyle];
    marker.selectedStyle = [self markerStyle];
    marker.togglesSelectionOnTap = NO;
    marker.zIndex = 10;
    self.marker = marker;
    [self.mapView addOverlay:marker];
    [self syncMarkerTestAccessibilityState];
}

- (void)syncEditingOverlaysForState:(OverlayMarkerMovementExampleFormState *)state {
    if (!state || !self.marker || [self movementIsActive]) {
        return;
    }
    [self resetMovementProgressForState:state];
    [self updateRoutePolylineVisibilityForState:state];
    self.marker.coordinate = [self startCoordinateForState:state];
    [self syncMarkerTestAccessibilityState];
}

- (void)updateRoutePolylineVisibilityForState:(OverlayMarkerMovementExampleFormState *)state {
    if (state.movementTypeIndex == OverlayMarkerMovementExampleMovementTypePath) {
        if (!self.routePolyline) {
            [self addRoutePolyline];
        }
        return;
    }
    if (self.routePolyline) {
        [self.mapView removeOverlay:self.routePolyline];
        self.routePolyline = nil;
    }
}

- (void)addRoutePolyline {
    NSData *routeData = self.mockRouteProvider.routeCoordinateData;
    NSUInteger count = [self coordinateCountForData:routeData];
    if (count < 2 || self.routePolyline) {
        return;
    }

    MTCPolyline *polyline = [[MTCPolyline alloc] initWithCoordinates:(const CLLocationCoordinate2D *)routeData.bytes
                                                               count:count];
    MTCPolylineStyle *style = [[MTCPolylineStyle alloc] init];
    style.strokeColor = UIColor.systemBlueColor;
    style.strokeWeight = 5.0;
    style.strokeOpacity = 0.7;
    polyline.style = style;
    self.routePolyline = polyline;
    [self.mapView addOverlay:polyline];
}

- (void)clearAllOverlaysShowingToast:(BOOL)showToast {
    [self.movementTask cancelWithError:nil];
    self.movementTask = nil;

    NSMutableArray<id<MTCOverlay>> *overlays = [NSMutableArray array];
    if (self.marker) {
        [overlays addObject:self.marker];
    }
    if (self.routePolyline) {
        [overlays addObject:self.routePolyline];
    }
    if (overlays.count > 0) {
        [self.mapView removeOverlays:overlays];
    }
    self.marker = nil;
    self.routePolyline = nil;
    [self syncMarkerTestAccessibilityState];
    if (showToast) {
        [MTCExampleToastView showMessage:[self localizedStringForKey:@"overlay_all_markers_cleared"] inView:self.view];
    }
}

- (void)syncMarkerTestAccessibilityState {
    [self.mapTestSupport syncOverlayCount:self.marker ? 1 : 0];
}

#pragma mark - Movement

- (void)startMovementFromCurrentState {
    if (!self.marker) {
        [self replaceOverlaysWithState:self.formState recenter:YES showToast:NO];
    }
    if (!self.marker) {
        return;
    }

    [self.movementTask cancelWithError:nil];
    self.movementTask = nil;

    OverlayMarkerMovementExampleFormState *state = self.formState;
    [self resetMovementProgressForState:state];
    state.statusKey = @"overlay_movement_status_running";

    NSError *error = nil;
    id<MTCMarkerMovement> movement = [self movementForState:state error:&error];
    if (!movement) {
        [self handleMovementError:error];
        return;
    }

    MTCMarkerMovementOptions *options = [self movementOptionsForState:state];
    self.movementTask = [self.marker startMovement:movement options:options error:&error];
    if (!self.movementTask) {
        [self handleMovementError:error];
        return;
    }

    [self refreshSettingsSheet];
    [MTCExampleToastView showMessage:[self localizedStringForKey:@"overlay_marker_movement_started"] inView:self.view];
}

- (id<MTCMarkerMovement>)movementForState:(OverlayMarkerMovementExampleFormState *)state error:(NSError **)error {
    if (state.movementTypeIndex == OverlayMarkerMovementExampleMovementTypePath) {
        MTCPath *path = [self mockRoutePath];
        if (!path) {
            if (error) {
                *error = [NSError errorWithDomain:@"com.maptec.maps.example.markerMovement"
                                             code:1
                                         userInfo:@{NSLocalizedDescriptionKey : @"Mock route path is invalid."}];
            }
            return nil;
        }
        CLLocationCoordinate2D pathStart = [path coordinateAtIndex:0];
        self.marker.coordinate = pathStart;
        state.startLatitude = pathStart.latitude;
        state.startLongitude = pathStart.longitude;
        state.currentLatitude = pathStart.latitude;
        state.currentLongitude = pathStart.longitude;
        [self updateRoutePolylineVisibilityForState:state];
        if (state.pathTimingModeIndex == MTCMarkerMovementTimingModeSpeed) {
            return [[MTCMarkerPathMovement alloc] initWithPath:path speed:state.pathSpeedMetersPerSecond];
        }
        return [[MTCMarkerPathMovement alloc] initWithPath:path durationMs:(NSInteger)llround(state.pathDurationSeconds * 1000.0)];
    }

    self.marker.coordinate = [self startCoordinateForState:state];
    CLLocationCoordinate2D target = CLLocationCoordinate2DMake(state.targetLatitude, state.targetLongitude);
    return [[MTCMarkerPointMovement alloc] initWithTargetCoordinate:target
                                                        durationMs:(NSInteger)llround(state.pointDurationSeconds * 1000.0)];
}

- (MTCMarkerMovementOptions *)movementOptionsForState:(OverlayMarkerMovementExampleFormState *)state {
    __weak typeof(self) weakSelf = self;
    MTCMarkerMovementOptions *options = [[MTCMarkerMovementOptions alloc] init];
    options.autoRotate = state.autoRotate;
    options.headingOffset = state.headingOffset;
    options.orientationSmoothingDuration = state.orientationSmoothingDuration;
    options.progressCallbackInterval = state.progressCallbackInterval;
    options.cancelBehavior = (MTCMarkerMovementCancelBehavior)[self clampedIndex:state.cancelBehaviorIndex
                                                                           count:[self cancelBehaviorTitles].count];
    options.backgroundBehavior = (MTCMarkerMovementBackgroundBehavior)[self clampedIndex:state.backgroundBehaviorIndex
                                                                                  count:[self backgroundBehaviorTitles].count];
    options.progressHandler = ^(MTCMarkerMovementTask *task, MTCMarkerMovementProgress *progress) {
        [weakSelf updateStateForTask:task progress:progress statusKey:@"overlay_movement_status_running"];
    };
    options.pauseHandler = ^(MTCMarkerMovementTask *task, MTCMarkerMovementProgress *progress) {
        [weakSelf updateStateForTask:task progress:progress statusKey:@"overlay_movement_status_paused"];
    };
    options.resumeHandler = ^(MTCMarkerMovementTask *task, MTCMarkerMovementProgress *progress) {
        [weakSelf updateStateForTask:task progress:progress statusKey:@"overlay_movement_status_running"];
    };
    options.finishHandler = ^(MTCMarkerMovementTask *task, MTCMarkerMovementProgress *progress, MTCMarkerMovementFinishReason reason) {
        (void)reason;
        [weakSelf updateStateForTask:task progress:progress statusKey:@"overlay_movement_status_finished"];
        if (task == weakSelf.movementTask) {
            weakSelf.movementTask = nil;
        }
    };
    options.cancelHandler = ^(MTCMarkerMovementTask *task, MTCMarkerMovementProgress *progress, MTCMarkerMovementCancelReason reason) {
        (void)reason;
        [weakSelf updateStateForTask:task progress:progress statusKey:@"overlay_movement_status_cancelled"];
        if (task == weakSelf.movementTask) {
            weakSelf.movementTask = nil;
            [weakSelf syncMarkerTestAccessibilityState];
        }
    };
    options.errorHandler = ^(MTCMarkerMovementTask *task, NSError *error) {
        [weakSelf handleMovementError:error];
        if (task == weakSelf.movementTask) {
            weakSelf.movementTask = nil;
        }
    };
    return options;
}

- (void)pauseMovement {
    NSError *error = nil;
    if (![self.movementTask pauseWithError:&error]) {
        [self handleMovementError:error];
    }
    [self refreshSettingsSheet];
}

- (void)resumeMovement {
    NSError *error = nil;
    if (![self.movementTask resumeWithError:&error]) {
        [self handleMovementError:error];
    }
    [self refreshSettingsSheet];
}

- (void)cancelMovement {
    NSError *error = nil;
    if (![self.movementTask cancelWithError:&error]) {
        [self handleMovementError:error];
    }
    [self refreshSettingsSheet];
}

- (void)finishMovement {
    NSError *error = nil;
    if (![self.movementTask finishWithError:&error]) {
        [self handleMovementError:error];
    }
    [self refreshSettingsSheet];
}

- (BOOL)movementIsActive {
    MTCMarkerMovementState state = self.movementTask.state;
    return state == MTCMarkerMovementStateRunning || state == MTCMarkerMovementStatePaused;
}

- (void)updateStateForTask:(MTCMarkerMovementTask *)task
                  progress:(MTCMarkerMovementProgress *)progress
                 statusKey:(NSString *)statusKey {
    if (task != self.movementTask || !progress) {
        return;
    }
    self.formState.progressValue = progress.progress;
    self.formState.currentLatitude = progress.coordinate.latitude;
    self.formState.currentLongitude = progress.coordinate.longitude;
    self.formState.headingAvailable = progress.headingAvailable;
    self.formState.currentHeading = progress.heading;
    self.formState.statusKey = statusKey;
    [self refreshSettingsSheet];
}

- (void)handleMovementError:(NSError *)error {
    self.formState.statusKey = @"overlay_movement_status_error";
    NSString *message = error.localizedDescription.length > 0
        ? error.localizedDescription
        : [self localizedStringForKey:@"overlay_marker_movement_failed"];
    [MTCExampleToastView showMessage:message inView:self.view];
    [self refreshSettingsSheet];
}

- (void)resetMovementProgressForState:(OverlayMarkerMovementExampleFormState *)state {
    CLLocationCoordinate2D coordinate = [self startCoordinateForState:state];
    state.startLatitude = coordinate.latitude;
    state.startLongitude = coordinate.longitude;
    state.progressValue = 0.0;
    state.currentLatitude = coordinate.latitude;
    state.currentLongitude = coordinate.longitude;
    state.currentHeading = 0.0;
    state.headingAvailable = NO;
    state.statusKey = @"overlay_movement_status_idle";
}

- (void)refreshSettingsSheet {
    [self.settingsSheet refreshVisibleItems];
}

#pragma mark - Paths

- (MTCPath *)mockRoutePath {
    NSData *routeData = self.mockRouteProvider.routeCoordinateData;
    NSUInteger count = [self coordinateCountForData:routeData];
    if (count < 2) {
        return nil;
    }
    return [[MTCPath alloc] initWithCoordinates:(const CLLocationCoordinate2D *)routeData.bytes count:count];
}

- (CLLocationCoordinate2D)firstPathCoordinate {
    NSData *routeData = self.mockRouteProvider.routeCoordinateData;
    if ([self coordinateCountForData:routeData] == 0) {
        return kCLLocationCoordinate2DInvalid;
    }
    return ((const CLLocationCoordinate2D *)routeData.bytes)[0];
}

- (NSUInteger)coordinateCountForData:(NSData *)coordinateData {
    return coordinateData.length / sizeof(CLLocationCoordinate2D);
}

- (CLLocationCoordinate2D)centerCoordinateForState:(OverlayMarkerMovementExampleFormState *)state {
    if (state.movementTypeIndex != OverlayMarkerMovementExampleMovementTypePath) {
        CLLocationCoordinate2D start = [self startCoordinateForState:state];
        CLLocationCoordinate2D target = CLLocationCoordinate2DMake(state.targetLatitude, state.targetLongitude);
        if (!CLLocationCoordinate2DIsValid(target)) {
            return start;
        }
        return CLLocationCoordinate2DMake((start.latitude + target.latitude) * 0.5,
                                          (start.longitude + target.longitude) * 0.5);
    }

    NSData *routeData = self.mockRouteProvider.routeCoordinateData;
    NSUInteger count = [self coordinateCountForData:routeData];
    if (count == 0) {
        return [self singaporeCoordinate];
    }

    const CLLocationCoordinate2D *coordinates = (const CLLocationCoordinate2D *)routeData.bytes;
    CLLocationDegrees latitude = 0.0;
    CLLocationDegrees longitude = 0.0;
    for (NSUInteger index = 0; index < count; ++index) {
        latitude += coordinates[index].latitude;
        longitude += coordinates[index].longitude;
    }
    return CLLocationCoordinate2DMake(latitude / count, longitude / count);
}

- (void)focusState:(OverlayMarkerMovementExampleFormState *)state animated:(BOOL)animated {
    CLLocationCoordinate2D center = [self centerCoordinateForState:state];
    if (animated) {
        [self.mapView setCenterCoordinate:center transition:[MTCCameraTransition easeWithDuration:0.25] completion:nil];
    } else {
        [self.mapView setCenterCoordinate:center zoomLevel:OverlayMarkerMovementExampleDefaultZoomLevel];
    }
}

#pragma mark - Styles

- (MTCMarkerStyle *)markerStyle {
    MTCMarkerStyle *style = [[MTCMarkerStyle alloc] init];
    style.icon.type = MTCMarkerIconTypeBlueDot;
    style.icon.anchor = CGPointMake(0.5, 1.0);
    return style;
}

#pragma mark - Formatting

- (NSArray<NSString *> *)cancelBehaviorTitles {
    return @[
        [self localizedStringForKey:@"overlay_cancel_keep_current"],
        [self localizedStringForKey:@"overlay_cancel_reset_to_start"],
        [self localizedStringForKey:@"overlay_cancel_remove_marker"],
    ];
}

- (NSArray<NSString *> *)backgroundBehaviorTitles {
    return @[
        [self localizedStringForKey:@"overlay_background_pause"],
        [self localizedStringForKey:@"overlay_background_continue"],
    ];
}

- (NSInteger)clampedIndex:(NSInteger)index count:(NSUInteger)count {
    if (count == 0) {
        return 0;
    }
    return MAX(0, MIN(index, (NSInteger)count - 1));
}

- (NSString *)movementStatusTextForState:(OverlayMarkerMovementExampleFormState *)state {
    NSString *headingText = state.headingAvailable
        ? [NSString stringWithFormat:@"%.0f deg", state.currentHeading]
        : @"--";
    return [NSString stringWithFormat:@"%@  %.0f%%  %@, %@  %@",
            [self localizedStringForKey:state.statusKey ?: @"overlay_movement_status_idle"],
            state.progressValue * 100.0,
            [self formatCoordinateValue:state.currentLatitude],
            [self formatCoordinateValue:state.currentLongitude],
            headingText];
}

- (NSString *)startCoordinateTextForState:(OverlayMarkerMovementExampleFormState *)state {
    return [self coordinateTextWithLatitude:state.startLatitude longitude:state.startLongitude];
}

- (NSString *)targetCoordinateTextForState:(OverlayMarkerMovementExampleFormState *)state {
    return [self coordinateTextWithLatitude:state.targetLatitude longitude:state.targetLongitude];
}

- (NSString *)coordinateTextWithLatitude:(double)latitude longitude:(double)longitude {
    return [NSString stringWithFormat:@"%@, %@",
            [self formatCoordinateValue:latitude],
            [self formatCoordinateValue:longitude]];
}

- (void)updateStartCoordinateWithText:(NSString *)text state:(OverlayMarkerMovementExampleFormState *)state {
    CLLocationCoordinate2D coordinate = [self coordinateFromText:text
                                                fallbackLatitude:state.startLatitude
                                               fallbackLongitude:state.startLongitude];
    state.startLatitude = coordinate.latitude;
    state.startLongitude = coordinate.longitude;
}

- (void)updateTargetCoordinateWithText:(NSString *)text state:(OverlayMarkerMovementExampleFormState *)state {
    CLLocationCoordinate2D coordinate = [self coordinateFromText:text
                                                fallbackLatitude:state.targetLatitude
                                               fallbackLongitude:state.targetLongitude];
    state.targetLatitude = coordinate.latitude;
    state.targetLongitude = coordinate.longitude;
}

- (CLLocationCoordinate2D)coordinateFromText:(NSString *)text
                            fallbackLatitude:(double)fallbackLatitude
                           fallbackLongitude:(double)fallbackLongitude {
    NSArray<NSString *> *components =
        [text componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@",， "]];
    NSMutableArray<NSString *> *values = [NSMutableArray arrayWithCapacity:2];
    for (NSString *component in components) {
        NSString *trimmedComponent = [component stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        if (trimmedComponent.length > 0) {
            [values addObject:trimmedComponent];
        }
    }
    if (values.count < 2) {
        return CLLocationCoordinate2DMake(fallbackLatitude, fallbackLongitude);
    }

    CLLocationDegrees latitude = OverlayMarkerMovementExampleDoubleFromString(values[0], fallbackLatitude, -90.0, 90.0);
    CLLocationDegrees longitude = OverlayMarkerMovementExampleDoubleFromString(values[1], fallbackLongitude, -180.0, 180.0);
    return CLLocationCoordinate2DMake(latitude, longitude);
}

- (NSString *)formatCoordinateValue:(double)value {
    return [NSString stringWithFormat:@"%.6f", value];
}

- (NSString *)formatDurationValue:(double)value {
    return [NSString stringWithFormat:[self localizedStringForKey:@"overlay_1f_s"], value];
}

#pragma mark - Coordinates

- (CLLocationCoordinate2D)singaporeCoordinate {
    return CLLocationCoordinate2DMake(OverlayMarkerMovementExampleSingaporeLatitude,
                                      OverlayMarkerMovementExampleSingaporeLongitude);
}

- (CLLocationCoordinate2D)startCoordinateForState:(OverlayMarkerMovementExampleFormState *)state {
    if (state.movementTypeIndex == OverlayMarkerMovementExampleMovementTypePath) {
        CLLocationCoordinate2D pathStart = [self firstPathCoordinate];
        if (CLLocationCoordinate2DIsValid(pathStart)) {
            return pathStart;
        }
    }
    return CLLocationCoordinate2DMake(state.startLatitude, state.startLongitude);
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

#pragma mark -- multi-language

- (void)handleExampleSettingsAction {
    [self showMovementSheet];
}

- (void)demoLanguageDidChange {
    [self applyLocalizedTexts];
}

- (void)applyLocalizedTexts {
    self.title = [self localizedStringForKey:@"demo_title_OverlayMarkerMovementExampleViewController"];
    if (self.mapView) {
        self.mapView.mapLanguage = [self mapLanguageForDemoLanguage:self.demoLanguage];
    }
    if ([self isSettingsSheetVisible:ExampleSettingsSheetView.class]) {
        [self showMovementSheet];
    }
}

@end
