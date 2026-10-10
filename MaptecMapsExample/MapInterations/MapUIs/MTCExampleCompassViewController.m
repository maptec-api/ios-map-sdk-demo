//
//  MTCExampleCompassViewController.m
//  MaptecMapsExample
//
//  Created by ZHOUPanpan on 2026/6/24.
//

#import "MTCExampleCompassViewController.h"

#import "ExampleSettingsSheetView.h"
#import "MTCExampleMapBizUtil.h"
#import "MTCExampleMapTestSupport.h"
#import "MTCExampleTestAccessibility.h"

#import <MaptecMapsKit/MaptecMapsKit.h>

#include <math.h>

@interface MTCExampleCompassViewController () <MTCMapViewDelegate>

@property (nonatomic, strong) MTCMapView *mapView;
@property (nonatomic, strong) MTCExampleMapTestSupport *mapTestSupport;
@property (nonatomic, assign) NSInteger positionIndex;
@property (nonatomic, assign) CGFloat compassLength;

@end

@implementation MTCExampleCompassViewController

- (void)dealloc {
}
#pragma mark - Public

#pragma mark - Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = UIColor.whiteColor;
    self.view.accessibilityIdentifier = MTCExampleTestAccessibilityMapCompassScreen;

    [self configureNavigationItems:NO];
    [self configureMapView];
    [self applyLocalizedTexts];
}

#pragma mark - protocol

#pragma mark - Delegate
#pragma mark -- MTCMapViewDelegate

- (void)syncBearingToTestSupport {
    self.mapTestSupport.overlayCountTestView.accessibilityValue = [NSString stringWithFormat:@"bearing:%.1f", self.mapView.camera.bearing];
}

- (void)mapView:(MTCMapView *)mapView cameraDidChange:(MTCMapCamera *)camera reason:(MTCMapCameraChangeReason)reason {
    [self syncBearingToTestSupport];
}

- (void)mapViewCameraDidBecomeIdle:(MTCMapView *)mapView camera:(MTCMapCamera *)camera {
    [self syncBearingToTestSupport];
}

- (void)mapViewDidFinishLoadingMap:(MTCMapView *)mapView {
    (void)mapView;
    [self.mapTestSupport markMapRenderedReady];
    [self.mapTestSupport pauseMapRenderingIfUITesting:self.mapView];
    [self syncBearingToTestSupport];
}

- (void)mapView:(MTCMapView *)mapView didFinishSwitchingMapStyleWithID:(NSString *)mapStyleID {
    (void)mapView;
    (void)mapStyleID;
    [self.mapTestSupport markMapRenderedReady];
    [self.mapTestSupport pauseMapRenderingIfUITesting:self.mapView];
    [self syncBearingToTestSupport];
}

#pragma mark - Event

- (void)rotateClockwise {
    /// fmod 模运算可省略，但防止后续逻辑变化
    CLLocationDirection bearing = fmod(self.mapView.camera.bearing - 45.0, 360.0);
    if (bearing < 0.0) {
        bearing += 360.0;
    }
    __weak typeof(self) weakSelf = self;
    [self.mapView setBearing:bearing transition:[MTCCameraTransition easeWithDuration:0.25] completion:^(BOOL finished) {
        [weakSelf syncBearingToTestSupport];
    }];
}
#pragma mark - Private
- (void)configureMapView {
    self.mapView = [[MTCMapView alloc] initWithFrame:self.view.bounds];
    self.mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.mapView.delegate = self;
    [self.view addSubview:self.mapView];

    self.mapTestSupport = [[MTCExampleMapTestSupport alloc] init];
    [self.mapTestSupport installOnHostView:self.view];

    [self.mapView setCenterCoordinate:CLLocationCoordinate2DMake(1.315826, 103.817522) zoomLevel:15];
    
    self.mapView.uiSettings.zoomButtonsEnabled = YES;
    self.mapView.uiSettings.scaleBarEnabled = NO;

    self.mapView.uiSettings.permitShowAll = YES;
    self.mapView.uiSettings.compassEnabled = YES;
    self.mapView.uiSettings.fadeCompassFacingNorth = NO;
    self.mapView.uiSettings.compassGravity = MTCUIPositionTop | MTCUIPositionLeft;
    self.positionIndex = [MTCExampleMapBizUtil MTCIndexForUIPosition:self.mapView.uiSettings.compassGravity];
    CGFloat length = self.mapView.uiSettings.compassViewSize.width;
    self.compassLength = MIN(MAX(length, 24.0), 120.0);
}

#pragma mark -- 导航&弹层

- (void)showCompassSettings {
    ExampleSettingsSheetView *sheet =
        [[ExampleSettingsSheetView alloc] initWithTitle:[self localizedStringForKey:@"demo_title_MTCExampleCompassViewController"]
                                               sections:[self compassSections]];
    [sheet showInView:self.view animated:NO];
}

- (NSArray<ExampleSettingsSection *> *)compassSections {
    __weak typeof(self) weakSelf = self;
    return @[
        [ExampleSettingsSection sectionWithTitle:[self localizedStringForKey:@"common_section_display"] items:@[
            [[ExampleSettingsItem boolItemWithTitle:[self localizedStringForKey:@"compass_show_compass"]
                                             getter:^BOOL { return weakSelf.mapView.uiSettings.compassEnabled; }
                                             setter:^(BOOL value) {
                weakSelf.mapView.uiSettings.compassEnabled = value;
            }] withAccessibilityIdentifier:MTCExampleTestAccessibilitySwitchCompassEnabled],
            [[ExampleSettingsItem boolItemWithTitle:[self localizedStringForKey:@"compass_fade_when_facing_north"]
                                             getter:^BOOL { return weakSelf.mapView.uiSettings.fadeCompassFacingNorth; }
                                             setter:^(BOOL value) {
                weakSelf.mapView.uiSettings.fadeCompassFacingNorth = value;
            }] withAccessibilityIdentifier:MTCExampleTestAccessibilitySwitchCompassFadeWhenFacingNorth],
        ]],
        [ExampleSettingsSection sectionWithTitle:[self localizedStringForKey:@"common_section_layout"] items:@[
            [[ExampleSettingsItem listItemWithTitle:[self localizedStringForKey:@"compass_gravity_label"]
                                            options:[self localizedUIPositionTitles]
                                             getter:^NSInteger { return weakSelf.positionIndex; }
                                             setter:^(NSInteger index) {
                weakSelf.positionIndex = index;
                weakSelf.mapView.uiSettings.compassGravity = [MTCExampleMapBizUtil MTCUIPositionForIndex:weakSelf.positionIndex];
            }] withAccessibilityIdentifier:MTCExampleTestAccessibilityDropdownCompassGravity],
            [ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"compass_size_label"]
                                             minimum:24.0
                                             maximum:120.0
                                                step:1.0
                                              getter:^double { return weakSelf.compassLength; }
                                              setter:^(double value) {
                weakSelf.compassLength = (CGFloat)value;
                weakSelf.mapView.uiSettings.compassViewSize = CGSizeMake(value, value);
            } formatter:^NSString *(double value) {
                return [NSString stringWithFormat:@"%.0f dp", value];
            }],
        ]],
        [ExampleSettingsSection sectionWithTitle:[self localizedStringForKey:@"compass_section_bearing"] items:@[
            [[ExampleSettingsItem actionItemWithTitle:[self localizedStringForKey:@"compass_rotate_clockwise"] handler:^{
                [weakSelf rotateClockwise];
            }] withAccessibilityIdentifier:MTCExampleTestAccessibilityBtnCompassRotateClockwise],
        ]],
    ];
}

#pragma mark -- multi-language

- (void)handleExampleSettingsAction {
    [self showCompassSettings];
}

- (void)demoLanguageDidChange {
    [self applyLocalizedTexts];
}

- (void)applyLocalizedTexts {
    self.title = [self localizedStringForKey:@"demo_title_MTCExampleCompassViewController"];
    if (self.mapView) {
        self.mapView.mapLanguage = [self mapLanguageForDemoLanguage:self.demoLanguage];
    }
    if ([self isSettingsSheetVisible:ExampleSettingsSheetView.class]) {
        [self showCompassSettings];
    }
}

#pragma mark - Getter & Setter

@end
