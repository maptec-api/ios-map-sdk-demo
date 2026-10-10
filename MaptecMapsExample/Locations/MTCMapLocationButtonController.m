//
//  MTCMapLocationButtonController.m
//  MaptecMapsExample
//
//  Created by ZHOUPanpan on 2026/7/10.
//

#import "MTCMapLocationButtonController.h"

#import "ExampleSettingsSheetView.h"
#import "MTCExampleMapBizUtil.h"

#import <CoreLocation/CoreLocation.h>
#import <MaptecMapsKit/MaptecMapsKit.h>

@interface MTCMapLocationButtonController ()

@property (nonatomic, strong) MTCMapView *mapView;
@property (nonatomic, assign) NSInteger positionIndex;
@property (nonatomic, assign) CGFloat locationLength;

@end

@implementation MTCMapLocationButtonController

- (void)dealloc {
}
#pragma mark - Public

#pragma mark - Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = UIColor.whiteColor;

    [self configureNavigationItems:NO];
    [self configureMapView];
    [self applyLocalizedTexts];
}

#pragma mark - protocol

#pragma mark - Delegate

#pragma mark - Event
- (void)showLocationSettings {
    ExampleSettingsSheetView *sheet =
        [[ExampleSettingsSheetView alloc] initWithTitle:[self localizedStringForKey:@"demo_title_MTCMapLocationButtonController"]
                                               sections:[self locationSections]];
    [sheet showInView:self.view animated:NO];
}

#pragma mark - Private

- (void)configureMapView {
    self.mapView = [[MTCMapView alloc] initWithFrame:self.view.bounds];
    self.mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.mapView];

    [self.mapView setCenterCoordinate:CLLocationCoordinate2DMake(31.2304, 121.4737) zoomLevel:11.5];

    self.mapView.uiSettings.permitShowAll = YES;
    self.mapView.uiSettings.compassEnabled = NO;
    self.mapView.uiSettings.scaleBarEnabled = NO;
    self.mapView.uiSettings.logoGravity = MTCUIPositionBottom | MTCUIPositionLeft;
    self.mapView.uiSettings.zoomButtonsEnabled = YES;
    self.mapView.uiSettings.locationViewEnabled = YES;
    self.mapView.uiSettings.locationViewGravity = MTCUIPositionBottom | MTCUIPositionRight;
    self.mapView.uiSettings.locationViewSize = CGSizeMake(40.0, 40.0);
    self.mapView.uiSettings.locationViewMargins = UIEdgeInsetsMake(4.0, 4.0, 4.0, 4.0);
    self.mapView.showsUserLocation = YES;

    MTCUserLocationConfig *locationConfig = [[MTCUserLocationConfig alloc] init];
    locationConfig.renderMode = MTCUserLocationRenderModeHeading;
    locationConfig.locationTrackingMode = MTCUserLocationTrackingModeNone;
    locationConfig.bearingTrackingMode = MTCUserBearingTrackingModeNone;
    locationConfig.accuracyCircleAlpha = 0.30;
    self.mapView.userLocationConfig = locationConfig;

    self.positionIndex = [MTCExampleMapBizUtil MTCIndexForUIPosition:self.mapView.uiSettings.locationViewGravity];
    self.locationLength = self.mapView.uiSettings.locationViewSize.width;
}

- (NSArray<ExampleSettingsSection *> *)locationSections {
    __weak typeof(self) weakSelf = self;
    return @[
        [ExampleSettingsSection sectionWithTitle:[self localizedStringForKey:@"common_section_layout"] items:@[
            [ExampleSettingsItem boolItemWithTitle:[self localizedStringForKey:@"location_button_show"]
                                            getter:^BOOL { return weakSelf.mapView.uiSettings.locationViewEnabled; }
                                            setter:^(BOOL value) {
                weakSelf.mapView.uiSettings.locationViewEnabled = value;
            }],
            [ExampleSettingsItem listItemWithTitle:[self localizedStringForKey:@"location_button_gravity"]
                                           options:[self localizedUIPositionTitles]
                                            getter:^NSInteger { return weakSelf.positionIndex; }
                                            setter:^(NSInteger index) {
                weakSelf.positionIndex = index;
                weakSelf.mapView.uiSettings.locationViewGravity = [MTCExampleMapBizUtil MTCUIPositionForIndex:index];
            }],
            [ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"location_button_size"]
                                             minimum:30.0
                                             maximum:60.0
                                                step:1.0
                                              getter:^double { return weakSelf.locationLength; }
                                              setter:^(double value) {
                weakSelf.locationLength = (CGFloat)value;
                weakSelf.mapView.uiSettings.locationViewSize = CGSizeMake(value, value);
            } formatter:^NSString *(double value) {
                return [NSString stringWithFormat:@"%.0f dp", value];
            }],
        ]],
    ];
}

#pragma mark -- multi-language

- (void)handleExampleSettingsAction {
    [self showLocationSettings];
}

- (void)demoLanguageDidChange {
    [self applyLocalizedTexts];
}

- (void)applyLocalizedTexts {
    self.title = [self localizedStringForKey:@"demo_title_MTCMapLocationButtonController"];
    if (self.mapView) {
        self.mapView.mapLanguage = [self mapLanguageForDemoLanguage:self.demoLanguage];
    }
    if ([self isSettingsSheetVisible:ExampleSettingsSheetView.class]) {
        [self showLocationSettings];
    }
}
#pragma mark - Getter & Setter

@end
