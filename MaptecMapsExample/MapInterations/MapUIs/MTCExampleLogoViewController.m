//
//  MTCExampleLogoViewController.m
//  MaptecMapsExample
//
//  Created by ZHOUPanpan on 2026/6/26.
//

#import "MTCExampleLogoViewController.h"

#import "ExampleSettingsSheetView.h"
#import "MTCExampleMapBizUtil.h"
#import "MTCExampleMapTestSupport.h"
#import "MTCExampleTestAccessibility.h"

#import <MaptecMapsKit/MaptecMapsKit.h>

@interface MTCExampleLogoViewController () <MTCMapViewDelegate>

@property (nonatomic, strong) MTCMapView *mapView;
@property (nonatomic, strong) MTCExampleMapTestSupport *mapTestSupport;
@property (nonatomic, assign) NSInteger positionIndex;
@end

@implementation MTCExampleLogoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = UIColor.whiteColor;
    self.view.accessibilityIdentifier = MTCExampleTestAccessibilityMapLogoScreen;

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

- (void)showLogoSettings {
    ExampleSettingsSheetView *sheet =
        [[ExampleSettingsSheetView alloc] initWithTitle:[self localizedStringForKey:@"logo_sheet_title"]
                                               sections:[self logoSections]];
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

    [self.mapView setCenterCoordinate:CLLocationCoordinate2DMake(31.2304, 121.4737) zoomLevel:11.5];

    self.mapView.uiSettings.permitShowAll = YES;
    self.mapView.uiSettings.compassEnabled = NO;
    self.mapView.uiSettings.zoomButtonsEnabled = YES;
    self.mapView.uiSettings.scaleBarEnabled = NO;
    
    self.mapView.uiSettings.logoGravity = MTCUIPositionBottom | MTCUIPositionLeft;
    self.positionIndex = [MTCExampleMapBizUtil MTCIndexForUIPosition:self.mapView.uiSettings.logoGravity];
}

- (NSArray<ExampleSettingsSection *> *)logoSections {
    __weak typeof(self) weakSelf = self;
    return @[
        [ExampleSettingsSection sectionWithTitle:[self localizedStringForKey:@"common_section_layout"] items:@[
            [[ExampleSettingsItem listItemWithTitle:[self localizedStringForKey:@"logo_gravity_label"]
                                            options:[self localizedUIPositionTitles]
                                          popupSize:CGSizeMake(260.0, 360.0)
                                             getter:^NSInteger { return weakSelf.positionIndex; }
                                             setter:^(NSInteger index) {
                weakSelf.positionIndex = index;
                weakSelf.mapView.uiSettings.logoGravity = [MTCExampleMapBizUtil MTCUIPositionForIndex:index];
            }] withAccessibilityIdentifier:MTCExampleTestAccessibilityDropdownLogoGravity],
        ]]
    ];
}

#pragma mark -- multi-language

- (void)handleExampleSettingsAction {
    [self showLogoSettings];
}

- (void)demoLanguageDidChange {
    [self applyLocalizedTexts];
}

- (void)applyLocalizedTexts {
    self.title = [self localizedStringForKey:@"demo_title_MTCExampleLogoViewController"];
    if (self.mapView) {
        self.mapView.mapLanguage = [self mapLanguageForDemoLanguage:self.demoLanguage];
    }
    if ([self isSettingsSheetVisible:ExampleSettingsSheetView.class]) {
        [self showLogoSettings];
    }
}
@end
