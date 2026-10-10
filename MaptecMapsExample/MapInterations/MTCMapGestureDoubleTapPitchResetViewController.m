#import "MTCMapGestureDoubleTapPitchResetViewController.h"

#import "ExampleSettingsSheetView.h"
#import "MTCExampleMapTestSupport.h"
#import "MTCExampleTestAccessibility.h"

#import <CoreLocation/CoreLocation.h>
#import <MaptecMapsKit/MaptecMapsKit.h>

static CLLocationDegrees const MTCGestureDoubleTapPitchResetInitialLatitude = 1.3521;
static CLLocationDegrees const MTCGestureDoubleTapPitchResetInitialLongitude = 103.8198;
static double const MTCGestureDoubleTapPitchResetInitialZoomLevel = 11.5;
static CGFloat const MTCGestureDoubleTapPitchResetInitialPitch = 45.0;

@interface MTCMapGestureDoubleTapPitchResetViewController () <MTCMapViewDelegate>

@property (nonatomic, strong) MTCMapView *mapView;
@property (nonatomic, strong) MTCExampleMapTestSupport *mapTestSupport;
@property (nonatomic) CGFloat currentPitch;
@property (nonatomic, weak) ExampleSettingsSheetView *settingsSheet;

@end

@implementation MTCMapGestureDoubleTapPitchResetViewController

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = UIColor.whiteColor;
    self.view.accessibilityIdentifier = MTCExampleTestAccessibilityMapGestureDoubleTapTiltResetScreen;
    self.currentPitch = MTCGestureDoubleTapPitchResetInitialPitch;

    [self configureNavigationItems:NO];
    [self configureMapView];
    [self configureGestureSettings];
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

- (void)mapView:(MTCMapView *)mapView
cameraDidChange:(MTCMapCamera *)camera
         reason:(MTCMapCameraChangeReason)reason
       animated:(BOOL)animated {
    (void)reason;
    (void)animated;
    if (mapView != self.mapView) {
        return;
    }

    [self updateCurrentPitchWithCamera:camera];
    [self.settingsSheet reloadData];
}

#pragma mark - Event

- (void)showDoubleTapPitchResetSettings {
    ExampleSettingsSheetView *sheet =
        [[ExampleSettingsSheetView alloc] initWithTitle:[self localizedStringForKey:@"common_settings_sheet_title"]
                                               sections:[self doubleTapPitchResetSections]];
    self.settingsSheet = sheet;
    [sheet showInView:self.view animated:NO];
}

#pragma mark - Private

- (void)configureMapView {
    self.mapView = [[MTCMapView alloc] initWithFrame:self.view.bounds];
    self.mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.mapView.delegate = self;
    [self.view addSubview:self.mapView];

    self.mapTestSupport = [[MTCExampleMapTestSupport alloc] init];
    [self.mapTestSupport installOnHostView:self.view];

    MTCMapCamera *initialCamera =
        [MTCMapCamera cameraWithCenterCoordinate:CLLocationCoordinate2DMake(MTCGestureDoubleTapPitchResetInitialLatitude,
                                                                            MTCGestureDoubleTapPitchResetInitialLongitude)
                                       zoomLevel:MTCGestureDoubleTapPitchResetInitialZoomLevel
                                         bearing:0.0
                                           pitch:MTCGestureDoubleTapPitchResetInitialPitch];
    [self.mapView setCamera:initialCamera transition:nil completion:nil];
}

- (void)configureGestureSettings {
    self.mapView.gestureSettings.doubleTapZoomEnabled = NO;
}

- (NSArray<ExampleSettingsSection *> *)doubleTapPitchResetSections {
    __weak typeof(self) weakSelf = self;
    MTCMapGestureSettings *settings = self.mapView.gestureSettings;

    return @[
        [ExampleSettingsSection sectionWithTitle:@"" items:@[
            [[ExampleSettingsItem boolItemWithTitle:[self localizedStringForKey:@"gesture_pitch_reset_enable"]
                                             getter:^BOOL { return settings.doubleTapPitchResetEnabled; }
                                             setter:^(BOOL value) { settings.doubleTapPitchResetEnabled = value; }] withAccessibilityIdentifier:MTCExampleTestAccessibilitySwitchDoubleTapPitchReset],
            [ExampleSettingsItem dynamicInfoItemWithGetter:^NSString * _Nonnull {
                return [NSString stringWithFormat:[weakSelf localizedStringForKey:@"gesture_pitch_reset_current"], (double)weakSelf.currentPitch];
            }],
            [ExampleSettingsItem infoItemWithText:[self localizedStringForKey:@"gesture_pitch_reset_info"]],
        ]],
    ];
}

- (void)updateCurrentPitchWithCamera:(MTCMapCamera *)camera {
    self.currentPitch = camera.pitch;
}

#pragma mark -- multi-language

- (void)handleExampleSettingsAction {
    [self showDoubleTapPitchResetSettings];
}

- (void)demoLanguageDidChange {
    [self applyLocalizedTexts];
}

- (void)applyLocalizedTexts {
    self.title = [self localizedStringForKey:@"demo_title_MTCMapGestureDoubleTapPitchResetViewController"];
    if (self.mapView) {
        self.mapView.mapLanguage = [self mapLanguageForDemoLanguage:self.demoLanguage];
    }
    if ([self isSettingsSheetVisible:ExampleSettingsSheetView.class]) {
        [self showDoubleTapPitchResetSettings];
    }
}
@end
