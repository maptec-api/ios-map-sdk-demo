//
//  MTCExampleScaleBarViewController.m
//  MaptecMapsExample
//
//  Created by ZHOUPanpan on 2026/6/25.
//

#import "MTCExampleScaleBarViewController.h"

#import "ExampleSettingsSheetView.h"
#import "MTCExampleMapBizUtil.h"
#import "MTCExampleMapTestSupport.h"
#import "MTCExampleTestAccessibility.h"

#import <MaptecMapsKit/MaptecMapsKit.h>

@interface MTCExampleScaleBarViewController () <MTCMapViewDelegate>

@property (nonatomic, strong) MTCMapView *mapView;
@property (nonatomic, strong) MTCExampleMapTestSupport *mapTestSupport;
@property (nonatomic, assign) NSInteger positionIndex;
@property (nonatomic, assign) CGFloat scaleBarMaxWidth;

@end

@implementation MTCExampleScaleBarViewController

#pragma mark - Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = UIColor.whiteColor;
    self.view.accessibilityIdentifier = MTCExampleTestAccessibilityMapScaleScreen;

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
- (void)showScaleBarSettings {
    ExampleSettingsSheetView *sheet =
        [[ExampleSettingsSheetView alloc] initWithTitle:[self localizedStringForKey:@"scale_sheet_title"]
                                               sections:[self scaleBarSections]];
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
    self.mapView.uiSettings.scaleBarEnabled = YES;
    self.mapView.uiSettings.scaleBarGravity = MTCUIPositionBottom | MTCUIPositionLeft;
    self.mapView.uiSettings.scaleBarMaxWidth = 100.0;

    self.positionIndex = [MTCExampleMapBizUtil MTCIndexForUIPosition:self.mapView.uiSettings.scaleBarGravity];
    self.scaleBarMaxWidth = self.mapView.uiSettings.scaleBarMaxWidth;
}

- (NSArray<ExampleSettingsSection *> *)scaleBarSections {
    __weak typeof(self) weakSelf = self;
    return @[
        [ExampleSettingsSection sectionWithTitle:[self localizedStringForKey:@"common_section_display"] items:@[
            [[ExampleSettingsItem boolItemWithTitle:[self localizedStringForKey:@"scale_show_bar"]
                                             getter:^BOOL { return weakSelf.mapView.uiSettings.scaleBarEnabled; }
                                             setter:^(BOOL value) {
                weakSelf.mapView.uiSettings.scaleBarEnabled = value;
            }] withAccessibilityIdentifier:MTCExampleTestAccessibilitySwitchScaleEnabled],
        ]],
        [ExampleSettingsSection sectionWithTitle:[self localizedStringForKey:@"common_section_layout"] items:@[
            [ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"scale_bar_max_width_label"]
                                             minimum:50.0
                                             maximum:200.0
                                                step:1.0
                                              getter:^double { return weakSelf.scaleBarMaxWidth; }
                                              setter:^(double value) {
                weakSelf.scaleBarMaxWidth = (CGFloat)value;
                weakSelf.mapView.uiSettings.scaleBarMaxWidth = (CGFloat)value;
            } formatter:^NSString *(double value) {
                return [NSString stringWithFormat:@"%.0f px", value];
            }],
            [[ExampleSettingsItem listItemWithTitle:[self localizedStringForKey:@"scale_bar_gravity_label"]
                                            options:[self localizedUIPositionTitles]
                                          popupSize:CGSizeMake(260.0, 360.0)
                                             getter:^NSInteger { return weakSelf.positionIndex; }
                                             setter:^(NSInteger index) {
                weakSelf.positionIndex = index;
                weakSelf.mapView.uiSettings.scaleBarGravity = [MTCExampleMapBizUtil MTCUIPositionForIndex:index];
            }] withAccessibilityIdentifier:MTCExampleTestAccessibilityDropdownScaleGravity],
        ]],
    ];
}

#pragma mark -- multi-language

- (void)handleExampleSettingsAction {
    [self showScaleBarSettings];
}

- (void)demoLanguageDidChange {
    [self applyLocalizedTexts];
}

- (void)applyLocalizedTexts {
    self.title = [self localizedStringForKey:@"demo_title_MTCExampleScaleBarViewController"];
    if (self.mapView) {
        self.mapView.mapLanguage = [self mapLanguageForDemoLanguage:self.demoLanguage];
    }
    if ([self isSettingsSheetVisible:ExampleSettingsSheetView.class]) {
        [self showScaleBarSettings];
    }
}
@end
