#import "MTCMapGestureZoomAnimationDurationViewController.h"

#import "ExampleSettingsSheetView.h"
#import "MTCExampleMapTestSupport.h"
#import "MTCExampleTestAccessibility.h"

#import <CoreLocation/CoreLocation.h>
#import <MaptecMapsKit/MaptecMapsKit.h>

static CLLocationDegrees const MTCGestureZoomAnimationDurationInitialLatitude = 1.3521;
static CLLocationDegrees const MTCGestureZoomAnimationDurationInitialLongitude = 103.8198;
static double const MTCGestureZoomAnimationDurationInitialZoomLevel = 11.5;
static NSTimeInterval const MTCGestureZoomAnimationDurationDefaultDuration = 0.3;
static NSTimeInterval const MTCGestureZoomAnimationDurationInitialCustomDuration = 2.0;

@interface MTCMapGestureZoomAnimationDurationViewController () <MTCMapViewDelegate>

@property (nonatomic, strong) MTCMapView *mapView;
@property (nonatomic, strong) MTCExampleMapTestSupport *mapTestSupport;
@property (nonatomic) BOOL customZoomAnimationDurationEnabled;
@property (nonatomic) NSTimeInterval customZoomAnimationDuration;
@property (nonatomic, weak) ExampleSettingsSheetView *settingsSheet;

@end

@implementation MTCMapGestureZoomAnimationDurationViewController

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = UIColor.whiteColor;
    self.view.accessibilityIdentifier = MTCExampleTestAccessibilityMapGestureZoomAnimationDurationScreen;
    self.customZoomAnimationDurationEnabled = YES;
    self.customZoomAnimationDuration = MTCGestureZoomAnimationDurationInitialCustomDuration;

    [self configureNavigationItems:NO];
    [self configureMapView];
    [self applyZoomAnimationDuration];
    [self applyLocalizedTexts];
}

#pragma mark - Delegate
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

- (void)showZoomAnimationDurationSettings {
    ExampleSettingsSheetView *sheet =
        [[ExampleSettingsSheetView alloc] initWithTitle:[self localizedStringForKey:@"common_settings_sheet_title"]
                                               sections:[self zoomAnimationDurationSections]];
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

    [self.mapView setCenterCoordinate:CLLocationCoordinate2DMake(MTCGestureZoomAnimationDurationInitialLatitude,
                                                                 MTCGestureZoomAnimationDurationInitialLongitude)
                            zoomLevel:MTCGestureZoomAnimationDurationInitialZoomLevel];
}

- (NSArray<ExampleSettingsSection *> *)zoomAnimationDurationSections {
    __weak typeof(self) weakSelf = self;
    ExampleSettingsEnabledGetter customDurationEnabled = ^BOOL{
        __strong typeof(weakSelf) self = weakSelf;
        return self.customZoomAnimationDurationEnabled;
    };

    return @[
        [ExampleSettingsSection sectionWithTitle:@"" items:@[
            [ExampleSettingsItem boolItemWithTitle:[self localizedStringForKey:@"gesture_zoom_anim_enable"]
                                            getter:^BOOL {
                __strong typeof(weakSelf) self = weakSelf;
                return self.customZoomAnimationDurationEnabled;
            } setter:^(BOOL value) {
                __strong typeof(weakSelf) self = weakSelf;
                if (!self) {
                    return;
                }
                self.customZoomAnimationDurationEnabled = value;
                [self applyZoomAnimationDuration];
                [self.settingsSheet reloadData];
            }],
            [[[ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"gesture_zoom_anim_duration"]
                                              minimum:0.0
                                              maximum:2.0
                                                 step:0.05
                                               getter:^double {
                __strong typeof(weakSelf) self = weakSelf;
                return self.customZoomAnimationDuration;
            } setter:^(double value) {
                __strong typeof(weakSelf) self = weakSelf;
                if (!self) {
                    return;
                }
                self.customZoomAnimationDuration = value;
                [self applyZoomAnimationDuration];
            } formatter:^NSString * _Nonnull(double value) {
                return [NSString stringWithFormat:@"%.0f ms", value * 1000.0];
            }] enabledWhen:customDurationEnabled] withAccessibilityIdentifier:MTCExampleTestAccessibilitySliderZoomAnimationDuration],
            [ExampleSettingsItem infoItemWithText:[self localizedStringForKey:@"gesture_zoom_anim_info"]],
        ]],
    ];
}

- (void)applyZoomAnimationDuration {
    MTCMapGestureSettings *settings = self.mapView.gestureSettings;
    settings.zoomAnimationDuration = self.customZoomAnimationDurationEnabled ? self.customZoomAnimationDuration : MTCGestureZoomAnimationDurationDefaultDuration;
}

#pragma mark -- multi-language

- (void)handleExampleSettingsAction {
    [self showZoomAnimationDurationSettings];
}

- (void)demoLanguageDidChange {
    [self applyLocalizedTexts];
}

- (void)applyLocalizedTexts {
    self.title = [self localizedStringForKey:@"demo_title_MTCMapGestureZoomAnimationDurationViewController"];
    if (self.mapView) {
        self.mapView.mapLanguage = [self mapLanguageForDemoLanguage:self.demoLanguage];
    }
    if ([self isSettingsSheetVisible:ExampleSettingsSheetView.class]) {
        [self showZoomAnimationDurationSettings];
    }
}
@end
