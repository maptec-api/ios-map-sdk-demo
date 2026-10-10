//
//  MTCMapGestureCoordinationViewController.m
//  MaptecMapsExample
//
//  Created by Codex on 2026/7/13.
//

#import "MTCMapGestureCoordinationViewController.h"

#import "ExampleSettingsSheetView.h"
#import "MTCExampleMapTestSupport.h"
#import "MTCExampleTestAccessibility.h"

#import <CoreLocation/CoreLocation.h>
#import <MaptecMapsKit/MaptecMapsKit.h>

static CLLocationDegrees const MTCGestureCoordinationInitialLatitude = 1.3521;
static CLLocationDegrees const MTCGestureCoordinationInitialLongitude = 103.8198;
static double const MTCGestureCoordinationInitialZoomLevel = 11.5;

@interface MTCMapGestureCoordinationViewController () <MTCMapViewDelegate>

@property (nonatomic, strong) MTCMapView *mapView;
@property (nonatomic, strong) MTCExampleMapTestSupport *mapTestSupport;
@property (nonatomic) MTCMapGestureType pendingMutuallyExclusiveGestureTypes;
@property (nonatomic, weak) ExampleSettingsSheetView *settingsSheet;

@end

@implementation MTCMapGestureCoordinationViewController

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = UIColor.whiteColor;
    self.view.accessibilityIdentifier = MTCExampleTestAccessibilityMapGestureCoordinationScreen;

    [self configureNavigationItems:NO];
    [self configureMapView];
    [self applyLocalizedTexts];
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

#pragma mark - Event

- (void)showGestureCoordinationSettings {
    self.pendingMutuallyExclusiveGestureTypes = self.mapView.gestureSettings.mutuallyExclusiveGestureTypes;

    ExampleSettingsSheetView *sheet =
        [[ExampleSettingsSheetView alloc] initWithTitle:[self localizedStringForKey:@"common_settings_sheet_title"]
                                               sections:[self gestureCoordinationSections]];
    self.settingsSheet = sheet;
    [sheet showInView:self.view animated:NO];
}

#pragma mark - Private

- (void)configureMapView {
    self.mapView = [[MTCMapView alloc] initWithFrame:self.view.bounds];
    self.mapView.delegate = self;
    self.mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.mapView];

    self.mapTestSupport = [[MTCExampleMapTestSupport alloc] init];
    [self.mapTestSupport installOnHostView:self.view];

    [self.mapView setCenterCoordinate:CLLocationCoordinate2DMake(MTCGestureCoordinationInitialLatitude, MTCGestureCoordinationInitialLongitude)
                            zoomLevel:MTCGestureCoordinationInitialZoomLevel];
}

- (NSArray<ExampleSettingsSection *> *)gestureCoordinationSections {
    __weak typeof(self) weakSelf = self;
    MTCMapGestureSettings *settings = self.mapView.gestureSettings;
    ExampleSettingsEnabledGetter simultaneousEnabled = ^BOOL{
        return settings.simultaneousRecognitionEnabled;
    };

    return @[
        [ExampleSettingsSection sectionWithTitle:[self localizedStringForKey:@"gesture_coord_section"] items:@[
            [[ExampleSettingsItem boolItemWithTitle:[self localizedStringForKey:@"gesture_coord_allow_simultaneous"]
                                             getter:^BOOL { return settings.simultaneousRecognitionEnabled; }
                                             setter:^(BOOL value) { settings.simultaneousRecognitionEnabled = value; }]
                withAccessibilityIdentifier:MTCExampleTestAccessibilitySwitchSimultaneousGestures],
            [[ExampleSettingsItem infoItemWithText:[self localizedStringForKey:@"gesture_coord_simultaneous_hint"]] enabledWhen:simultaneousEnabled],
        ]],
        [ExampleSettingsSection sectionWithTitle:[self localizedStringForKey:@"gesture_coord_exclusive_section"] items:@[
            [[ExampleSettingsItem infoItemWithText:[self localizedStringForKey:@"gesture_coord_exclusive_hint"]] enabledWhen:simultaneousEnabled],
            [[self checkboxItemWithTitle:[self localizedStringForKey:@"gesture_type_zoom"] gestureType:MTCMapGestureTypeZoom] enabledWhen:simultaneousEnabled],
            [[self checkboxItemWithTitle:[self localizedStringForKey:@"gesture_type_rotate"] gestureType:MTCMapGestureTypeRotate] enabledWhen:simultaneousEnabled],
            [[self checkboxItemWithTitle:[self localizedStringForKey:@"gesture_type_pitch"] gestureType:MTCMapGestureTypePitch] enabledWhen:simultaneousEnabled],
            [[self checkboxItemWithTitle:[self localizedStringForKey:@"gesture_type_move"] gestureType:MTCMapGestureTypeMove] enabledWhen:simultaneousEnabled],
            [[self checkboxItemWithTitle:[self localizedStringForKey:@"gesture_type_long_press"] gestureType:MTCMapGestureTypeLongPress] enabledWhen:simultaneousEnabled],
            [[[ExampleSettingsItem actionItemWithTitle:[self localizedStringForKey:@"common_ok"] handler:^{
                __strong typeof(weakSelf) self = weakSelf;
                if (!self) {
                    return;
                }
                self.mapView.gestureSettings.mutuallyExclusiveGestureTypes = self.pendingMutuallyExclusiveGestureTypes;
                [self.settingsSheet dismissAnimated:YES];
            }] withAccessibilityIdentifier:MTCExampleTestAccessibilityBtnConfirmMutualGestures] enabledWhen:simultaneousEnabled],
        ]],
    ];
}

- (ExampleSettingsItem *)checkboxItemWithTitle:(NSString *)title
                                   gestureType:(MTCMapGestureType)gestureType {
    __weak typeof(self) weakSelf = self;
    return [ExampleSettingsItem checkboxItemWithTitle:title
                                              getter:^BOOL {
        return (weakSelf.pendingMutuallyExclusiveGestureTypes & gestureType) != 0;
    } setter:^(BOOL value) {
        if (value) {
            weakSelf.pendingMutuallyExclusiveGestureTypes |= gestureType;
        } else {
            weakSelf.pendingMutuallyExclusiveGestureTypes &= ~gestureType;
        }
    }];
}

#pragma mark -- multi-language

- (void)handleExampleSettingsAction {
    [self showGestureCoordinationSettings];
}

- (void)demoLanguageDidChange {
    [self applyLocalizedTexts];
}

- (void)applyLocalizedTexts {
    self.title = [self localizedStringForKey:@"demo_title_MTCMapGestureCoordinationViewController"];
    if (self.mapView) {
        self.mapView.mapLanguage = [self mapLanguageForDemoLanguage:self.demoLanguage];
    }
    if ([self isSettingsSheetVisible:ExampleSettingsSheetView.class]) {
        [self showGestureCoordinationSettings];
    }
}
@end
