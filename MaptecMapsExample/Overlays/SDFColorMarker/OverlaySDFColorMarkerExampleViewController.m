#import "OverlaySDFColorMarkerExampleViewController.h"

#import "ExampleSettingsSheetView.h"
#import "MTCExampleMapTestSupport.h"
#import "MTCExampleTestAccessibility.h"
#import "MTCExampleToastView.h"

#import <MaptecMapsKit/MaptecMapsKit.h>

#include <math.h>

static CLLocationDegrees const OverlaySDFColorMarkerExampleSingaporeLatitude = 1.3048264556208515;
static CLLocationDegrees const OverlaySDFColorMarkerExampleSingaporeLongitude = 103.83052199958921;
static double const OverlaySDFColorMarkerExampleDefaultZoomLevel = 13.0;

static double OverlaySDFColorMarkerExampleClampDouble(double value, double minimum, double maximum) {
    return fmin(fmax(value, minimum), maximum);
}

static double OverlaySDFColorMarkerExampleDoubleFromString(NSString *value, double fallback, double minimum, double maximum) {
    NSString *trimmedValue = [value stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (trimmedValue.length == 0) {
        return fallback;
    }

    double parsedValue = 0.0;
    NSScanner *scanner = [NSScanner scannerWithString:trimmedValue];
    if (![scanner scanDouble:&parsedValue]) {
        return fallback;
    }
    return OverlaySDFColorMarkerExampleClampDouble(parsedValue, minimum, maximum);
}

static UIColor *OverlaySDFColorMarkerExampleColorFromHexString(NSString *hexString) {
    NSString *candidate = [[hexString ?: @"" stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] uppercaseString];
    if ([candidate hasPrefix:@"#"]) {
        candidate = [candidate substringFromIndex:1];
    }
    if (candidate.length != 6) {
        return UIColor.systemBlueColor;
    }

    unsigned int rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:candidate];
    if (![scanner scanHexInt:&rgbValue]) {
        return UIColor.systemBlueColor;
    }

    return [UIColor colorWithRed:((rgbValue >> 16) & 0xFF) / 255.0
                           green:((rgbValue >> 8) & 0xFF) / 255.0
                            blue:(rgbValue & 0xFF) / 255.0
                           alpha:1.0];
}

@interface OverlaySDFColorMarkerExampleFormState : NSObject <NSCopying>
@property (nonatomic) double latitude;
@property (nonatomic) double longitude;
@property (nonatomic) NSInteger colorIndex;
@end

@implementation OverlaySDFColorMarkerExampleFormState

- (id)copyWithZone:(NSZone *)zone {
    OverlaySDFColorMarkerExampleFormState *state = [[[self class] allocWithZone:zone] init];
    state.latitude = self.latitude;
    state.longitude = self.longitude;
    state.colorIndex = self.colorIndex;
    return state;
}

@end

@interface OverlaySDFColorMarkerExampleViewController () <MTCMapViewDelegate>
@property (nonatomic, strong) MTCMapView *mapView;
@property (nonatomic, strong) MTCExampleMapTestSupport *mapTestSupport;
@property (nonatomic, strong) NSMutableArray<MTCMarker *> *markers;
@property (nonatomic, strong) NSMapTable<MTCMarker *, OverlaySDFColorMarkerExampleFormState *> *markerBaseStates;
@property (nonatomic, strong) OverlaySDFColorMarkerExampleFormState *formState;
@property (nonatomic, weak) MTCMarker *editingMarker;
@end

@implementation OverlaySDFColorMarkerExampleViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = UIColor.whiteColor;
    self.view.accessibilityIdentifier = MTCExampleTestAccessibilityOverlayMarkerSdfScreen;
    self.markers = [NSMutableArray array];
    self.markerBaseStates = [NSMapTable weakToStrongObjectsMapTable];
    self.formState = [self defaultMarkerStateAtCoordinate:[self singaporeCoordinate]];

    [self configureNavigationItems:NO];
    [self configureMapView];
    [self.mapView setCenterCoordinate:[self singaporeCoordinate] zoomLevel:OverlaySDFColorMarkerExampleDefaultZoomLevel];
    [self addInitialMarker];
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
                                                   sections:[self sectionsWithAddAction:^{
        [self replaceMarkersWithState:[self.formState copy]];
        [sheet dismissAnimated:YES];
    } clearAction:^{
        [self clearAllMarkers];
        [sheet dismissAnimated:YES];
    }]];
    [sheet showInView:self.view animated:YES];
}

- (NSArray<ExampleSettingsSection *> *)sectionsWithAddAction:(dispatch_block_t)addAction
                                                 clearAction:(dispatch_block_t)clearAction {
    __weak typeof(self) weakSelf = self;
    __weak OverlaySDFColorMarkerExampleFormState *weakState = self.formState;
    void (^syncState)(void) = ^{
        [weakSelf syncEditingMarkerForState:weakState];
    };
    NSArray<NSString *> *colorNames = [self colorNames];
    NSArray<NSString *> *colorHexValues = [self colorHexValues];
    ExampleSettingsListGroup *colorGroup =
        [ExampleSettingsListGroup groupWithTitle:[self localizedStringForKey:@"overlay_colors"]
                                         options:colorNames
                                  optionHexValues:colorHexValues
                               initiallyCollapsed:NO];

    return @[
        [ExampleSettingsSection sectionWithTitle:[self localizedStringForKey:@"overlay_position"] items:@[
            [[ExampleSettingsItem textItemWithTitle:[self localizedStringForKey:@"overlay_coordinate"]
                                       placeholder:@"lat, lng"
                                      keyboardType:UIKeyboardTypeNumbersAndPunctuation
                                            getter:^NSString *{
                return [weakSelf coordinateTextForState:weakState];
            } setter:^(NSString *value) {
                [weakSelf updateCoordinateWithText:value state:weakState];
                syncState();
            }] withAccessibilityIdentifier:MTCExampleTestAccessibilitySymbolInputLatLng],
        ]],
        [ExampleSettingsSection sectionWithTitle:@"" items:@[
            [[ExampleSettingsItem groupedListItemWithTitle:[self localizedStringForKey:@"overlay_colors"]
                                                   groups:@[colorGroup]
                                               popupSize:CGSizeMake(260.0, 320.0)
                                                  getter:^NSInteger {
                return weakState.colorIndex;
            } setter:^(NSInteger index) {
                weakState.colorIndex = MAX(0, MIN(index, (NSInteger)colorHexValues.count - 1));
                syncState();
            }] withAccessibilityIdentifier:MTCExampleTestAccessibilitySymbolInputSdfIconColor],
            [[ExampleSettingsItem actionItemWithTitle:[self localizedStringForKey:@"overlay_add_b58c75"] handler:addAction]
                withAccessibilityIdentifier:MTCExampleTestAccessibilitySymbolBtnAddSdf],
            [[ExampleSettingsItem actionItemWithTitle:[self localizedStringForKey:@"overlay_clear_all_3358c6"] handler:clearAction]
                withAccessibilityIdentifier:MTCExampleTestAccessibilitySymbolBtnClearAll],
        ]],
    ];
}

#pragma mark - Marker State

- (OverlaySDFColorMarkerExampleFormState *)defaultMarkerStateAtCoordinate:(CLLocationCoordinate2D)coordinate {
    OverlaySDFColorMarkerExampleFormState *state = [[OverlaySDFColorMarkerExampleFormState alloc] init];
    state.latitude = coordinate.latitude;
    state.longitude = coordinate.longitude;
    state.colorIndex = 0;
    return state;
}

- (void)addInitialMarker {
    [self addMarkerWithState:[self.formState copy] showToast:NO recenter:NO];
}

- (OverlaySDFColorMarkerExampleFormState *)stateFromMarker:(MTCMarker *)marker {
    OverlaySDFColorMarkerExampleFormState *baseState = [self.markerBaseStates objectForKey:marker];
    OverlaySDFColorMarkerExampleFormState *state = baseState ? [baseState copy] : [self defaultMarkerStateAtCoordinate:marker.coordinate];
    state.latitude = marker.coordinate.latitude;
    state.longitude = marker.coordinate.longitude;
    return state;
}

- (MTCMarker *)currentMarker {
    return self.markers.lastObject;
}

- (void)replaceMarkersWithState:(OverlaySDFColorMarkerExampleFormState *)state {
    [self clearAllMarkersShowingToast:NO];
    [self addMarkerWithState:state];
}

- (void)addMarkerWithState:(OverlaySDFColorMarkerExampleFormState *)state {
    [self addMarkerWithState:state showToast:YES recenter:YES];
}

- (void)addMarkerWithState:(OverlaySDFColorMarkerExampleFormState *)state
                 showToast:(BOOL)showToast
                  recenter:(BOOL)recenter {
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(state.latitude, state.longitude);
    MTCMarker *marker = [[MTCMarker alloc] initWithCoordinate:coordinate];
    marker.style = [self markerStyleWithColor:[self colorForIndex:state.colorIndex]];
    [self.markerBaseStates setObject:[state copy] forKey:marker];
    [self.markers addObject:marker];
    self.editingMarker = marker;
    [self.mapView addOverlay:marker];
    [self.mapTestSupport syncOverlayCount:self.markers.count];
    if (recenter) {
        [self.mapView setCenterCoordinate:coordinate transition:[MTCCameraTransition easeWithDuration:0.25] completion:nil];
    }
    if (showToast) {
        [MTCExampleToastView showMessage:[self localizedStringForKey:@"overlay_added_sdf_color_marker"] inView:self.view];
    }
}

- (void)syncEditingMarkerForState:(OverlaySDFColorMarkerExampleFormState *)state {
    MTCMarker *editingMarker = self.editingMarker;
    if (!state || !editingMarker || ![self.markers containsObject:editingMarker]) {
        return;
    }
    [self applyState:state toMarker:editingMarker];
}

- (void)applyState:(OverlaySDFColorMarkerExampleFormState *)state toMarker:(MTCMarker *)marker {
    [self.markerBaseStates setObject:[state copy] forKey:marker];
    marker.coordinate = CLLocationCoordinate2DMake(state.latitude, state.longitude);
    marker.style = [self markerStyleWithColor:[self colorForIndex:state.colorIndex]];
}

- (MTCMarkerStyle *)markerStyleWithColor:(UIColor *)color {
    MTCMarkerStyle *style = [[MTCMarkerStyle alloc] init];
    style.icon.type = MTCMarkerIconTypeBlueDot;
    style.icon.tintColor = color;
    style.icon.anchor = CGPointMake(0.5, 1.0);
    return style;
}

- (void)clearAllMarkers {
    [self clearAllMarkersShowingToast:YES];
}

- (void)clearAllMarkersShowingToast:(BOOL)showToast {
    NSArray<MTCMarker *> *markers = [self.markers copy];
    [self.markers removeAllObjects];
    [self.markerBaseStates removeAllObjects];
    self.editingMarker = nil;
    [self.mapView removeOverlays:markers];
    [self.mapTestSupport syncOverlayCount:0];
    if (showToast) {
        [MTCExampleToastView showMessage:[self localizedStringForKey:@"overlay_all_markers_cleared"] inView:self.view];
    }
}

#pragma mark - Formatting

- (NSString *)coordinateTextForState:(OverlaySDFColorMarkerExampleFormState *)state {
    return [NSString stringWithFormat:@"%@, %@",
            [self formatCoordinateValue:state.latitude],
            [self formatCoordinateValue:state.longitude]];
}

- (void)updateCoordinateWithText:(NSString *)text state:(OverlaySDFColorMarkerExampleFormState *)state {
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

    state.latitude = OverlaySDFColorMarkerExampleDoubleFromString(values[0], state.latitude, -90.0, 90.0);
    state.longitude = OverlaySDFColorMarkerExampleDoubleFromString(values[1], state.longitude, -180.0, 180.0);
}

- (NSString *)formatCoordinateValue:(double)value {
    return [NSString stringWithFormat:@"%.6f", value];
}

#pragma mark - Colors

- (NSArray<NSString *> *)colorNames {
    return @[[self localizedStringForKey:@"overlay_blue"], [self localizedStringForKey:@"overlay_green"], [self localizedStringForKey:@"overlay_red"], [self localizedStringForKey:@"overlay_orange"], [self localizedStringForKey:@"overlay_purple"], [self localizedStringForKey:@"overlay_black"]];
}

- (NSArray<NSString *> *)colorHexValues {
    return @[@"#2F80ED", @"#00A63E", @"#E53935", @"#FF9800", @"#9C27B0", @"#111827"];
}

- (UIColor *)colorForIndex:(NSInteger)index {
    NSArray<NSString *> *hexValues = [self colorHexValues];
    NSInteger clampedIndex = MAX(0, MIN(index, (NSInteger)hexValues.count - 1));
    return OverlaySDFColorMarkerExampleColorFromHexString(hexValues[clampedIndex]);
}

#pragma mark - Coordinates

- (CLLocationCoordinate2D)singaporeCoordinate {
    return CLLocationCoordinate2DMake(OverlaySDFColorMarkerExampleSingaporeLatitude,
                                      OverlaySDFColorMarkerExampleSingaporeLongitude);
}

- (CLLocationCoordinate2D)currentMapCenterCoordinate {
    MTCMapCamera *camera = self.mapView.camera;
    if (camera) {
        return camera.centerCoordinate;
    }
    return [self singaporeCoordinate];
}

#pragma mark -- multi-language

- (void)handleExampleSettingsAction {
    [self showMarkerSheet];
}

- (void)demoLanguageDidChange {
    [self applyLocalizedTexts];
}

- (void)applyLocalizedTexts {
    self.title = [self localizedStringForKey:@"demo_title_OverlaySDFColorMarkerExampleViewController"];
    if (self.mapView) {
        self.mapView.mapLanguage = [self mapLanguageForDemoLanguage:self.demoLanguage];
    }
    if ([self isSettingsSheetVisible:ExampleSettingsSheetView.class]) {
        [self showMarkerSheet];
    }
}
@end
