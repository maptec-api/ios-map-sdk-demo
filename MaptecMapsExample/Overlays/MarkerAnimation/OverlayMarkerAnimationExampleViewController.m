#import "OverlayMarkerAnimationExampleViewController.h"

#import "ExampleSettingsSheetView.h"
#import "MTCExampleMapTestSupport.h"
#import "MTCExampleTestAccessibility.h"
#import "MTCExampleToastView.h"

#import <MaptecMapsKit/MaptecMapsKit.h>

#include <math.h>

static CLLocationDegrees const OverlayMarkerAnimationExampleSingaporeLatitude = 1.3048264556208515;
static CLLocationDegrees const OverlayMarkerAnimationExampleSingaporeLongitude = 103.83052199958921;
static double const OverlayMarkerAnimationExampleDefaultZoomLevel = 13.0;

static double OverlayMarkerAnimationExampleClampDouble(double value, double minimum, double maximum) {
    return fmin(fmax(value, minimum), maximum);
}

static double OverlayMarkerAnimationExampleDoubleFromString(NSString *value, double fallback, double minimum, double maximum) {
    NSString *trimmedValue = [value stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (trimmedValue.length == 0) {
        return fallback;
    }

    double parsedValue = 0.0;
    NSScanner *scanner = [NSScanner scannerWithString:trimmedValue];
    if (![scanner scanDouble:&parsedValue]) {
        return fallback;
    }
    return OverlayMarkerAnimationExampleClampDouble(parsedValue, minimum, maximum);
}

typedef NS_ENUM(NSInteger, OverlayMarkerAnimationExampleAnimationSlot) {
    OverlayMarkerAnimationExampleAnimationSlotNone = -1,
    OverlayMarkerAnimationExampleAnimationSlotEnter,
    OverlayMarkerAnimationExampleAnimationSlotSelected,
    OverlayMarkerAnimationExampleAnimationSlotExit,
};

@interface OverlayMarkerAnimationExampleFormState : NSObject <NSCopying>
@property (nonatomic) double latitude;
@property (nonatomic) double longitude;
@property (nonatomic) NSInteger enterTypeIndex;
@property (nonatomic) double enterDuration;
@property (nonatomic) NSInteger selectedTypeIndex;
@property (nonatomic) double selectedDuration;
@property (nonatomic) NSInteger exitTypeIndex;
@property (nonatomic) double exitDuration;
@property (nonatomic, copy, nullable) NSString *enterAnimationToken;
@property (nonatomic, copy, nullable) NSString *selectedAnimationToken;
@property (nonatomic, copy, nullable) NSString *exitAnimationToken;
@end

@implementation OverlayMarkerAnimationExampleFormState

- (id)copyWithZone:(NSZone *)zone {
    OverlayMarkerAnimationExampleFormState *state = [[[self class] allocWithZone:zone] init];
    state.latitude = self.latitude;
    state.longitude = self.longitude;
    state.enterTypeIndex = self.enterTypeIndex;
    state.enterDuration = self.enterDuration;
    state.selectedTypeIndex = self.selectedTypeIndex;
    state.selectedDuration = self.selectedDuration;
    state.exitTypeIndex = self.exitTypeIndex;
    state.exitDuration = self.exitDuration;
    state.enterAnimationToken = self.enterAnimationToken;
    state.selectedAnimationToken = self.selectedAnimationToken;
    state.exitAnimationToken = self.exitAnimationToken;
    return state;
}

@end

@interface OverlayMarkerAnimationExampleViewController () <MTCMapViewDelegate>
@property (nonatomic, strong) MTCMapView *mapView;
@property (nonatomic, strong) MTCExampleMapTestSupport *mapTestSupport;
@property (nonatomic, strong) NSMutableArray<MTCMarker *> *markers;
@property (nonatomic, strong) NSMapTable<MTCMarker *, OverlayMarkerAnimationExampleFormState *> *markerStates;
@property (nonatomic, strong) OverlayMarkerAnimationExampleFormState *formState;
@property (nonatomic, weak) MTCMarker *editingMarker;
@property (nonatomic, strong) NSTimer *exitRemovalTimer;
@property (nonatomic, weak) MTCMarker *pendingExitRemovalMarker;
@property (nonatomic, copy, nullable) NSString *pendingExitRemovalToken;
@end

@implementation OverlayMarkerAnimationExampleViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = UIColor.whiteColor;
    self.view.accessibilityIdentifier = MTCExampleTestAccessibilityOverlayMarkerAnimationScreen;
    self.markers = [NSMutableArray array];
    self.markerStates = [NSMapTable weakToStrongObjectsMapTable];
    self.formState = [self defaultMarkerStateAtCoordinate:[self singaporeCoordinate]];

    [self configureNavigationItems:NO];
    [self configureMapView];
    [self.mapView setCenterCoordinate:[self singaporeCoordinate] zoomLevel:OverlayMarkerAnimationExampleDefaultZoomLevel];
    [self addInitialMarker];
    [self applyLocalizedTexts];
}

- (void)dealloc {
    [self invalidateExitRemovalTimer];
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
    [self.mapTestSupport syncOverlayCount:0];
}

#pragma mark -- MTCMapViewDelegate

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

- (void)showMarkerSheet {
    MTCMarker *marker = [self currentMarker];
    self.editingMarker = marker;
    self.formState = marker ? [self stateFromMarker:marker] : [self defaultMarkerStateAtCoordinate:[self currentMapCenterCoordinate]];

    __block ExampleSettingsSheetView *sheet = nil;
    sheet = [[ExampleSettingsSheetView alloc] initWithTitle:[self localizedStringForKey:@"common_settings_sheet_title"]
                                                   sections:[self sectionsForState:self.formState
                                                                         addAction:^{
        [self replaceMarkersWithState:[self.formState copy] recenter:YES];
        [sheet dismissAnimated:YES];
    } clearAction:^{
        [self clearAllMarkers];
        [sheet dismissAnimated:YES];
    }]];
    [sheet showInView:self.view animated:YES];
}

- (NSArray<ExampleSettingsSection *> *)sectionsForState:(OverlayMarkerAnimationExampleFormState *)state
                                              addAction:(ExampleSettingsActionHandler)addAction
                                            clearAction:(ExampleSettingsActionHandler)clearAction {
    __weak typeof(self) weakSelf = self;
    __weak OverlayMarkerAnimationExampleFormState *weakState = state;
    void (^syncState)(OverlayMarkerAnimationExampleAnimationSlot slot) = ^(OverlayMarkerAnimationExampleAnimationSlot slot) {
        [weakSelf syncEditingMarkerForState:weakState updatedAnimationSlot:slot];
    };

    NSArray<ExampleSettingsItem *> *actionItems = @[
        [[ExampleSettingsItem actionItemWithTitle:[self localizedStringForKey:@"overlay_add_b58c75"] handler:addAction]
            withAccessibilityIdentifier:MTCExampleTestAccessibilitySymbolBtnAddMarker],
        [[ExampleSettingsItem actionItemWithTitle:[self localizedStringForKey:@"overlay_clear_all_3358c6"] handler:clearAction]
            withAccessibilityIdentifier:MTCExampleTestAccessibilitySymbolBtnClearAll],
        [[ExampleSettingsItem actionItemWithTitle:[self localizedStringForKey:@"overlay_stop_all_animations"] handler:^{
            [weakSelf stopAllMarkerAnimationsShowingToast:YES];
        }] withAccessibilityIdentifier:MTCExampleTestAccessibilitySymbolBtnStopAllAnimations],
    ];

    return @[
        [ExampleSettingsSection sectionWithTitle:[self localizedStringForKey:@"overlay_position"] items:@[
            [[ExampleSettingsItem textItemWithTitle:[self localizedStringForKey:@"overlay_coordinate"]
                                       placeholder:@"lat, lng"
                                      keyboardType:UIKeyboardTypeNumbersAndPunctuation
                                            getter:^NSString *{
                return [weakSelf coordinateTextForState:weakState];
            } setter:^(NSString *value) {
                [weakSelf updateCoordinateWithText:value state:weakState];
                syncState(OverlayMarkerAnimationExampleAnimationSlotNone);
            }] withAccessibilityIdentifier:MTCExampleTestAccessibilitySymbolInputLatLng],
        ]],
        [ExampleSettingsSection sectionWithTitle:@"" items:actionItems],
        [self animationSectionWithTitle:[self localizedStringForKey:@"overlay_entrance_animation"]
                            typeOptions:[self enterAnimationTitles]
                             typeGetter:^NSInteger {
            return weakState.enterTypeIndex;
        } typeSetter:^(NSInteger index) {
            weakState.enterTypeIndex = [weakSelf clampedIndex:index count:[weakSelf enterAnimationTitles].count];
            syncState(OverlayMarkerAnimationExampleAnimationSlotEnter);
        } durationGetter:^double {
            return weakState.enterDuration;
        } durationSetter:^(double value) {
            weakState.enterDuration = value;
            syncState(OverlayMarkerAnimationExampleAnimationSlotEnter);
        } playHandler:^{
            [weakSelf playEnterAnimationForCurrentMarker];
        } stopHandler:^{
            [weakSelf stopEnterAnimationForCurrentMarker];
        } typeAccessibilityIdentifier:MTCExampleTestAccessibilityAnimDropdownEnter
          playAccessibilityIdentifier:MTCExampleTestAccessibilityAnimBtnEnterStart
          stopAccessibilityIdentifier:MTCExampleTestAccessibilityAnimBtnEnterEnd],
        [self animationSectionWithTitle:[self localizedStringForKey:@"overlay_tap_animation"]
                            typeOptions:[self selectedAnimationTitles]
                             typeGetter:^NSInteger {
            return weakState.selectedTypeIndex;
        } typeSetter:^(NSInteger index) {
            weakState.selectedTypeIndex = [weakSelf clampedIndex:index count:[weakSelf selectedAnimationTitles].count];
            syncState(OverlayMarkerAnimationExampleAnimationSlotSelected);
        } durationGetter:^double {
            return weakState.selectedDuration;
        } durationSetter:^(double value) {
            weakState.selectedDuration = value;
            syncState(OverlayMarkerAnimationExampleAnimationSlotSelected);
        } playHandler:nil stopHandler:nil
          typeAccessibilityIdentifier:MTCExampleTestAccessibilityAnimDropdownSelect
          playAccessibilityIdentifier:nil
          stopAccessibilityIdentifier:nil],
        [self animationSectionWithTitle:[self localizedStringForKey:@"overlay_exit_animation"]
                            typeOptions:[self exitAnimationTitles]
                             typeGetter:^NSInteger {
            return weakState.exitTypeIndex;
        } typeSetter:^(NSInteger index) {
            weakState.exitTypeIndex = [weakSelf clampedIndex:index count:[weakSelf exitAnimationTitles].count];
            syncState(OverlayMarkerAnimationExampleAnimationSlotExit);
        } durationGetter:^double {
            return weakState.exitDuration;
        } durationSetter:^(double value) {
            weakState.exitDuration = value;
            syncState(OverlayMarkerAnimationExampleAnimationSlotExit);
        } playHandler:^{
            [weakSelf playExitAnimationForCurrentMarker];
        } stopHandler:^{
            [weakSelf stopExitAnimationForCurrentMarker];
        } typeAccessibilityIdentifier:MTCExampleTestAccessibilityAnimDropdownDisappear
          playAccessibilityIdentifier:MTCExampleTestAccessibilityAnimBtnDisappearStart
          stopAccessibilityIdentifier:MTCExampleTestAccessibilityAnimBtnDisappearEnd],
    ];
}

- (ExampleSettingsSection *)animationSectionWithTitle:(NSString *)title
                                          typeOptions:(NSArray<NSString *> *)typeOptions
                                           typeGetter:(ExampleSettingsSegmentGetter)typeGetter
                                           typeSetter:(ExampleSettingsSegmentSetter)typeSetter
                                      durationGetter:(ExampleSettingsNumberGetter)durationGetter
                                      durationSetter:(ExampleSettingsNumberSetter)durationSetter
                                         playHandler:(nullable ExampleSettingsActionHandler)playHandler
                                         stopHandler:(nullable ExampleSettingsActionHandler)stopHandler
                          typeAccessibilityIdentifier:(nullable NSString *)typeAccessibilityIdentifier
                         playAccessibilityIdentifier:(nullable NSString *)playAccessibilityIdentifier
                         stopAccessibilityIdentifier:(nullable NSString *)stopAccessibilityIdentifier {
    __weak typeof(self) weakSelf = self;
    ExampleSettingsItem *typeItem = [ExampleSettingsItem listItemWithTitle:[self localizedStringForKey:@"overlay_animation_type"]
                                                                   options:typeOptions
                                                                 popupSize:CGSizeMake(260.0, 220.0)
                                                                    getter:typeGetter
                                                                    setter:typeSetter];
    if (typeAccessibilityIdentifier) {
        [typeItem withAccessibilityIdentifier:typeAccessibilityIdentifier];
    }
    ExampleSettingsItem *durationItem = [ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"overlay_animation_duration"]
                                                                         minimum:0.1
                                                                         maximum:3.0
                                                                            step:0.1
                                                                          getter:durationGetter
                                                                          setter:durationSetter
                                                                       formatter:^NSString *(double value) {
        return [weakSelf formatDurationValue:value];
    }];

    NSMutableArray<ExampleSettingsItem *> *items = [NSMutableArray arrayWithObjects:typeItem, durationItem, nil];
    if (playHandler) {
        ExampleSettingsItem *playItem = [ExampleSettingsItem actionItemWithTitle:[self localizedStringForKey:@"overlay_play_animation"] handler:playHandler];
        if (playAccessibilityIdentifier) {
            [playItem withAccessibilityIdentifier:playAccessibilityIdentifier];
        }
        [items addObject:playItem];
    }
    if (stopHandler) {
        ExampleSettingsItem *stopItem = [ExampleSettingsItem actionItemWithTitle:[self localizedStringForKey:@"overlay_stop_animation"] handler:stopHandler];
        if (stopAccessibilityIdentifier) {
            [stopItem withAccessibilityIdentifier:stopAccessibilityIdentifier];
        }
        [items addObject:stopItem];
    }

    return [ExampleSettingsSection sectionWithTitle:title items:items];
}

#pragma mark - Marker State

- (OverlayMarkerAnimationExampleFormState *)defaultMarkerStateAtCoordinate:(CLLocationCoordinate2D)coordinate {
    OverlayMarkerAnimationExampleFormState *state = [[OverlayMarkerAnimationExampleFormState alloc] init];
    state.latitude = coordinate.latitude;
    state.longitude = coordinate.longitude;
    state.enterTypeIndex = [self enterTypeIndexForAnimationType:MTCMarkerAnimationTypeDrop fallbackIndex:2];
    state.enterDuration = 2.0;
    state.selectedTypeIndex = [self selectedTypeIndexForAnimationType:MTCMarkerAnimationTypeBounce fallbackIndex:1];
    state.selectedDuration = 1.0;
    state.exitTypeIndex = [self exitTypeIndexForAnimationType:MTCMarkerAnimationTypeFadeOut fallbackIndex:1];
    state.exitDuration = 0.4;
    return state;
}

- (OverlayMarkerAnimationExampleFormState *)stateFromMarker:(MTCMarker *)marker {
    OverlayMarkerAnimationExampleFormState *baseState = [self.markerStates objectForKey:marker];
    OverlayMarkerAnimationExampleFormState *state = baseState ? [baseState copy] : [self defaultMarkerStateAtCoordinate:marker.coordinate];
    state.latitude = marker.coordinate.latitude;
    state.longitude = marker.coordinate.longitude;
    return state;
}

- (void)addInitialMarker {
    [self addMarkerWithState:[self.formState copy] showToast:NO recenter:NO];
}

- (MTCMarker *)currentMarker {
    return self.markers.lastObject;
}

- (BOOL)isManagedMarker:(MTCMarker *)marker {
    return marker && [self.markers containsObject:marker];
}

- (OverlayMarkerAnimationExampleFormState *)stateForMarker:(MTCMarker *)marker {
    if (!marker) {
        return nil;
    }
    if (marker == self.editingMarker && self.formState) {
        self.formState.latitude = marker.coordinate.latitude;
        self.formState.longitude = marker.coordinate.longitude;
        return self.formState;
    }
    return [self stateFromMarker:marker];
}

- (void)replaceMarkersWithState:(OverlayMarkerAnimationExampleFormState *)state recenter:(BOOL)recenter {
    [self clearAllMarkersShowingToast:NO];
    [self addMarkerWithState:state showToast:YES recenter:recenter];
}

- (void)addMarkerWithState:(OverlayMarkerAnimationExampleFormState *)state
                 showToast:(BOOL)showToast
                  recenter:(BOOL)recenter {
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(state.latitude, state.longitude);
    MTCMarker *marker = [[MTCMarker alloc] initWithCoordinate:coordinate];
    [self applyState:state toMarker:marker];
    [self.markers addObject:marker];
    self.editingMarker = marker;
    self.formState = state;
    [self.mapView addOverlay:marker];
    [self.mapTestSupport syncOverlayCount:self.markers.count];
    if (recenter) {
        [self.mapView setCenterCoordinate:coordinate transition:[MTCCameraTransition easeWithDuration:0.25] completion:nil];
    }
    if (showToast) {
        [MTCExampleToastView showMessage:[self localizedStringForKey:@"overlay_added_marker_animation"] inView:self.view];
    }
    [self playEnterAnimationForMarker:marker state:state];
}

- (void)syncEditingMarkerForState:(OverlayMarkerAnimationExampleFormState *)state
              updatedAnimationSlot:(OverlayMarkerAnimationExampleAnimationSlot)slot {
    MTCMarker *editingMarker = self.editingMarker;
    if (!state || ![self isManagedMarker:editingMarker]) {
        return;
    }
    [self applyState:state toMarker:editingMarker];

    switch (slot) {
        case OverlayMarkerAnimationExampleAnimationSlotEnter:
            if (state.enterAnimationToken.length > 0) {
                [self playEnterAnimationForMarker:editingMarker state:state];
            }
            break;
        case OverlayMarkerAnimationExampleAnimationSlotSelected:
            if (state.selectedAnimationToken.length > 0) {
                [self playSelectedAnimationForMarker:editingMarker state:state];
            }
            break;
        case OverlayMarkerAnimationExampleAnimationSlotExit:
            if (state.exitAnimationToken.length > 0 || editingMarker == self.pendingExitRemovalMarker) {
                [self playExitAnimationForMarker:editingMarker state:state];
            }
            break;
        case OverlayMarkerAnimationExampleAnimationSlotNone:
        default:
            break;
    }
}

- (void)applyState:(OverlayMarkerAnimationExampleFormState *)state toMarker:(MTCMarker *)marker {
    [self.markerStates setObject:[state copy] forKey:marker];
    marker.coordinate = CLLocationCoordinate2DMake(state.latitude, state.longitude);
    marker.style = [self markerStyleWithIconType:MTCMarkerIconTypeBlueDot];
    marker.selectedStyle = [self markerStyleWithIconType:MTCMarkerIconTypeBlueDot];
    marker.selected = NO;
    marker.togglesSelectionOnTap = NO;
}

- (void)storeState:(OverlayMarkerAnimationExampleFormState *)state forMarker:(MTCMarker *)marker {
    if (!state || !marker) {
        return;
    }
    state.latitude = marker.coordinate.latitude;
    state.longitude = marker.coordinate.longitude;
    [self.markerStates setObject:[state copy] forKey:marker];
    if (marker == self.editingMarker) {
        self.formState = state;
    }
}

- (void)clearAllMarkers {
    [self clearAllMarkersShowingToast:YES];
}

- (void)clearAllMarkersShowingToast:(BOOL)showToast {
    [self invalidateExitRemovalTimer];
    NSArray<MTCMarker *> *markers = [self.markers copy];
    for (MTCMarker *marker in markers) {
        [marker stopAllAnimations];
    }
    [self.markers removeAllObjects];
    [self.markerStates removeAllObjects];
    self.editingMarker = nil;
    [self.mapView removeOverlays:markers];
    [self.mapTestSupport syncOverlayCount:0];
    if (showToast) {
        [MTCExampleToastView showMessage:[self localizedStringForKey:@"overlay_all_markers_cleared"] inView:self.view];
    }
}

- (void)removeMarker:(MTCMarker *)marker showToast:(BOOL)showToast {
    if (![self isManagedMarker:marker]) {
        return;
    }
    if (marker == self.pendingExitRemovalMarker) {
        [self invalidateExitRemovalTimer];
    }
    [marker stopAllAnimations];
    [self.markers removeObject:marker];
    [self.markerStates removeObjectForKey:marker];
    if (self.editingMarker == marker) {
        self.editingMarker = nil;
    }
    [self.mapView removeOverlay:marker];
    [self.mapTestSupport syncOverlayCount:self.markers.count];
    if (showToast) {
        [MTCExampleToastView showMessage:[self localizedStringForKey:@"overlay_marker_removed"] inView:self.view];
    }
}

- (MTCMarkerStyle *)markerStyleWithIconType:(MTCMarkerIconType)iconType {
    MTCMarkerStyle *style = [[MTCMarkerStyle alloc] init];
    style.icon.type = iconType;
    style.icon.anchor = CGPointMake(0.5, 1.0);
    return style;
}

#pragma mark - Runtime Animations

- (void)playEnterAnimationForCurrentMarker {
    MTCMarker *marker = [self currentMarker];
    [self playEnterAnimationForMarker:marker state:[self stateForMarker:marker]];
}

- (void)playEnterAnimationForMarker:(MTCMarker *)marker state:(OverlayMarkerAnimationExampleFormState *)state {
    if (![self isManagedMarker:marker] || !state) {
        return;
    }
    [self stopExitAnimationForMarker:marker state:state];

    MTCMarkerAnimationOptions *options = [self enterAnimationOptionsForState:state];
    if (!options) {
        [self stopEnterAnimationForMarker:marker state:state];
        return;
    }
    [self stopEnterAnimationForMarker:marker state:state];
    if (options.animationType == MTCMarkerAnimationTypeDrop || options.animationType == MTCMarkerAnimationTypeBounce) {
        [self stopSelectedAnimationForMarker:marker state:state];
    }

    state.enterAnimationToken = [marker startAnimation:options repeat:YES];
    [self storeState:state forMarker:marker];
}

- (void)stopEnterAnimationForCurrentMarker {
    MTCMarker *marker = [self currentMarker];
    [self stopEnterAnimationForMarker:marker state:[self stateForMarker:marker]];
}

- (void)stopEnterAnimationForMarker:(MTCMarker *)marker state:(OverlayMarkerAnimationExampleFormState *)state {
    if (![self isManagedMarker:marker] || !state) {
        return;
    }
    if (state.enterAnimationToken.length > 0) {
        [marker stopAnimationWithToken:state.enterAnimationToken];
    }
    state.enterAnimationToken = nil;
    [self storeState:state forMarker:marker];
}

- (void)playSelectedAnimationForMarker:(MTCMarker *)marker state:(OverlayMarkerAnimationExampleFormState *)state {
    if (![self isManagedMarker:marker] || !state) {
        return;
    }
    [self stopExitAnimationForMarker:marker state:state];
    [self stopEnterAnimationForMarker:marker state:state];

    MTCMarkerAnimationOptions *options = [self selectedAnimationOptionsForState:state];
    if (!options) {
        [self stopSelectedAnimationForMarker:marker state:state];
        return;
    }

    state.selectedAnimationToken = [marker startAnimation:options repeat:YES];
    [self storeState:state forMarker:marker];
}

- (void)stopSelectedAnimationForMarker:(MTCMarker *)marker state:(OverlayMarkerAnimationExampleFormState *)state {
    if (![self isManagedMarker:marker] || !state) {
        return;
    }
    if (state.selectedAnimationToken.length > 0) {
        [marker stopAnimationWithToken:state.selectedAnimationToken];
    }
    state.selectedAnimationToken = nil;
    [self storeState:state forMarker:marker];
}

- (void)playExitAnimationForCurrentMarker {
    MTCMarker *marker = [self currentMarker];
    [self playExitAnimationForMarker:marker state:[self stateForMarker:marker]];
}

- (void)playExitAnimationForMarker:(MTCMarker *)marker state:(OverlayMarkerAnimationExampleFormState *)state {
    if (![self isManagedMarker:marker] || !state) {
        return;
    }
    [self stopEnterAnimationForMarker:marker state:state];
    [self stopSelectedAnimationForMarker:marker state:state];
    [self stopExitAnimationForMarker:marker state:state];

    MTCMarkerAnimationOptions *options = [self exitAnimationOptionsForState:state];
    if (!options) {
        [self removeMarker:marker showToast:YES];
        return;
    }

    state.exitAnimationToken = [marker startAnimation:options repeat:NO];
    [self storeState:state forMarker:marker];
    if (state.exitAnimationToken.length == 0) {
        [self removeMarker:marker showToast:YES];
        return;
    }
    [self scheduleRemovalAfterExitAnimationForMarker:marker duration:options.duration token:state.exitAnimationToken];
}

- (void)stopExitAnimationForCurrentMarker {
    MTCMarker *marker = [self currentMarker];
    [self stopExitAnimationForMarker:marker state:[self stateForMarker:marker]];
}

- (void)stopExitAnimationForMarker:(MTCMarker *)marker state:(OverlayMarkerAnimationExampleFormState *)state {
    if (![self isManagedMarker:marker] || !state) {
        return;
    }
    if (marker == self.pendingExitRemovalMarker) {
        [self invalidateExitRemovalTimer];
    }
    if (state.exitAnimationToken.length > 0) {
        [marker stopAnimationWithToken:state.exitAnimationToken];
    }
    state.exitAnimationToken = nil;
    [self storeState:state forMarker:marker];
}

- (void)stopAllMarkerAnimationsShowingToast:(BOOL)showToast {
    NSArray<MTCMarker *> *markers = [self.markers copy];
    if (markers.count == 0) {
        return;
    }
    [self invalidateExitRemovalTimer];
    for (MTCMarker *marker in markers) {
        [marker stopAllAnimations];
        OverlayMarkerAnimationExampleFormState *state = [self stateForMarker:marker];
        [self clearAnimationTokensForState:state];
        [self storeState:state forMarker:marker];
    }
    if (showToast) {
        [MTCExampleToastView showMessage:[self localizedStringForKey:@"overlay_all_animations_stopped"] inView:self.view];
    }
}

- (void)clearAnimationTokensForState:(OverlayMarkerAnimationExampleFormState *)state {
    state.enterAnimationToken = nil;
    state.selectedAnimationToken = nil;
    state.exitAnimationToken = nil;
}

- (void)scheduleRemovalAfterExitAnimationForMarker:(MTCMarker *)marker
                                          duration:(NSTimeInterval)duration
                                             token:(NSString *)token {
    [self invalidateExitRemovalTimer];
    self.pendingExitRemovalMarker = marker;
    self.pendingExitRemovalToken = token;

    __weak typeof(self) weakSelf = self;
    NSTimer *timer = [NSTimer timerWithTimeInterval:MAX(duration, 0.1)
                                            repeats:NO
                                              block:^(NSTimer *firedTimer) {
        [weakSelf exitRemovalTimerFired:firedTimer];
    }];
    self.exitRemovalTimer = timer;
    [NSRunLoop.mainRunLoop addTimer:timer forMode:NSRunLoopCommonModes];
}

- (void)invalidateExitRemovalTimer {
    [self.exitRemovalTimer invalidate];
    self.exitRemovalTimer = nil;
    self.pendingExitRemovalMarker = nil;
    self.pendingExitRemovalToken = nil;
}

- (void)exitRemovalTimerFired:(NSTimer *)timer {
    if (timer != self.exitRemovalTimer) {
        return;
    }
    MTCMarker *marker = self.pendingExitRemovalMarker;
    NSString *token = self.pendingExitRemovalToken;
    self.exitRemovalTimer = nil;
    self.pendingExitRemovalMarker = nil;
    self.pendingExitRemovalToken = nil;

    if (![self isManagedMarker:marker]) {
        return;
    }
    OverlayMarkerAnimationExampleFormState *state = [self stateForMarker:marker];
    if (token.length > 0 &&
        state.exitAnimationToken.length > 0 &&
        ![state.exitAnimationToken isEqualToString:token]) {
        return;
    }
    state.exitAnimationToken = nil;
    [self storeState:state forMarker:marker];
    [self removeMarker:marker showToast:YES];
}

#pragma mark - Animation Options

- (MTCMarkerAnimationOptions *)enterAnimationOptionsForState:(OverlayMarkerAnimationExampleFormState *)state {
    if ([self isNoneAnimationIndex:state.enterTypeIndex]) {
        return nil;
    }
    return [[MTCMarkerAnimationOptions alloc] initWithAnimationType:[self enterAnimationTypeForIndex:state.enterTypeIndex]
                                                          duration:state.enterDuration];
}

- (MTCMarkerAnimationOptions *)selectedAnimationOptionsForState:(OverlayMarkerAnimationExampleFormState *)state {
    if ([self isNoneAnimationIndex:state.selectedTypeIndex]) {
        return nil;
    }
    return [[MTCMarkerAnimationOptions alloc] initWithAnimationType:[self selectedAnimationTypeForIndex:state.selectedTypeIndex]
                                                          duration:state.selectedDuration];
}

- (MTCMarkerAnimationOptions *)exitAnimationOptionsForState:(OverlayMarkerAnimationExampleFormState *)state {
    if ([self isNoneAnimationIndex:state.exitTypeIndex]) {
        return nil;
    }
    return [[MTCMarkerAnimationOptions alloc] initWithAnimationType:[self exitAnimationTypeForIndex:state.exitTypeIndex]
                                                          duration:state.exitDuration];
}

- (BOOL)isNoneAnimationIndex:(NSInteger)index {
    return index == 0;
}

- (NSArray<NSString *> *)enterAnimationTitles {
    return @[[self localizedStringForKey:@"overlay_none"], [self localizedStringForKey:@"overlay_fade_in"], [self localizedStringForKey:@"overlay_drop"], [self localizedStringForKey:@"overlay_bounce"]];
}

- (NSArray<NSString *> *)selectedAnimationTitles {
    return @[[self localizedStringForKey:@"overlay_none"], [self localizedStringForKey:@"overlay_bounce"]];
}

- (NSArray<NSString *> *)exitAnimationTitles {
    return @[[self localizedStringForKey:@"overlay_none"], [self localizedStringForKey:@"overlay_fade_out"], [self localizedStringForKey:@"overlay_shrink_out"]];
}

- (MTCMarkerAnimationType)enterAnimationTypeForIndex:(NSInteger)index {
    switch ([self clampedIndex:index count:[self enterAnimationTitles].count]) {
        case 1:
            return MTCMarkerAnimationTypeFadeIn;
        case 3:
            return MTCMarkerAnimationTypeBounce;
        case 2:
        default:
            return MTCMarkerAnimationTypeDrop;
    }
}

- (MTCMarkerAnimationType)selectedAnimationTypeForIndex:(NSInteger)index {
    (void)index;
    return MTCMarkerAnimationTypeBounce;
}

- (MTCMarkerAnimationType)exitAnimationTypeForIndex:(NSInteger)index {
    switch ([self clampedIndex:index count:[self exitAnimationTitles].count]) {
        case 2:
            return MTCMarkerAnimationTypeScaleDown;
        case 1:
        default:
            return MTCMarkerAnimationTypeFadeOut;
    }
}

- (NSInteger)enterTypeIndexForAnimationType:(MTCMarkerAnimationType)animationType fallbackIndex:(NSInteger)fallbackIndex {
    switch (animationType) {
        case MTCMarkerAnimationTypeFadeIn:
            return 1;
        case MTCMarkerAnimationTypeDrop:
            return 2;
        case MTCMarkerAnimationTypeBounce:
            return 3;
        default:
            return fallbackIndex;
    }
}

- (NSInteger)selectedTypeIndexForAnimationType:(MTCMarkerAnimationType)animationType fallbackIndex:(NSInteger)fallbackIndex {
    switch (animationType) {
        case MTCMarkerAnimationTypeBounce:
            return 1;
        default:
            return fallbackIndex;
    }
}

- (NSInteger)exitTypeIndexForAnimationType:(MTCMarkerAnimationType)animationType fallbackIndex:(NSInteger)fallbackIndex {
    switch (animationType) {
        case MTCMarkerAnimationTypeFadeOut:
            return 1;
        case MTCMarkerAnimationTypeScaleDown:
            return 2;
        default:
            return fallbackIndex;
    }
}

#pragma mark - Formatting

- (NSInteger)clampedIndex:(NSInteger)index count:(NSUInteger)count {
    if (count == 0) {
        return 0;
    }
    return MAX(0, MIN(index, (NSInteger)count - 1));
}

- (NSString *)coordinateTextForState:(OverlayMarkerAnimationExampleFormState *)state {
    return [NSString stringWithFormat:@"%@, %@",
            [self formatCoordinateValue:state.latitude],
            [self formatCoordinateValue:state.longitude]];
}

- (void)updateCoordinateWithText:(NSString *)text state:(OverlayMarkerAnimationExampleFormState *)state {
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
        return;
    }

    state.latitude = OverlayMarkerAnimationExampleDoubleFromString(values[0], state.latitude, -90.0, 90.0);
    state.longitude = OverlayMarkerAnimationExampleDoubleFromString(values[1], state.longitude, -180.0, 180.0);
}

- (NSString *)formatCoordinateValue:(double)value {
    return [NSString stringWithFormat:@"%.6f", value];
}

- (NSString *)formatDurationValue:(double)value {
    return [NSString stringWithFormat:[self localizedStringForKey:@"overlay_1f_s"], value];
}

#pragma mark - Coordinates

- (CLLocationCoordinate2D)singaporeCoordinate {
    return CLLocationCoordinate2DMake(OverlayMarkerAnimationExampleSingaporeLatitude,
                                      OverlayMarkerAnimationExampleSingaporeLongitude);
}

- (CLLocationCoordinate2D)currentMapCenterCoordinate {
    MTCMapCamera *camera = self.mapView.camera;
    if (camera) {
        return camera.centerCoordinate;
    }
    return [self singaporeCoordinate];
}

#pragma mark - MTCMapViewDelegate

- (void)mapView:(MTCMapView *)mapView didTapOverlay:(id<MTCOverlay>)overlay {
    (void)mapView;
    if (![overlay isKindOfClass:MTCMarker.class]) {
        return;
    }
    MTCMarker *marker = (MTCMarker *)overlay;
    if (![self isManagedMarker:marker]) {
        return;
    }
    self.editingMarker = marker;
    OverlayMarkerAnimationExampleFormState *state = [self stateForMarker:marker];
    self.formState = state;
    [self playSelectedAnimationForMarker:marker state:state];
}

#pragma mark -- multi-language

- (void)handleExampleSettingsAction {
    [self showMarkerSheet];
}

- (void)demoLanguageDidChange {
    [self applyLocalizedTexts];
}

- (void)applyLocalizedTexts {
    self.title = [self localizedStringForKey:@"demo_title_OverlayMarkerAnimationExampleViewController"];
    if (self.mapView) {
        self.mapView.mapLanguage = [self mapLanguageForDemoLanguage:self.demoLanguage];
    }
    if ([self isSettingsSheetVisible:ExampleSettingsSheetView.class]) {
        [self showMarkerSheet];
    }
}
@end
