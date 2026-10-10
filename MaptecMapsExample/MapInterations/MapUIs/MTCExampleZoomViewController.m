//
//  MTCExampleZoomViewController.m
//  MaptecMapsExample
//
//  Created by ZHOUPanpan on 2026/6/24.
//

#import "MTCExampleZoomViewController.h"

#import "ExampleSettingsSheetView.h"
#import "MTCExampleMapBizUtil.h"
#import "MTCExampleMapTestSupport.h"
#import "MTCExampleTestAccessibility.h"

#import <MaptecMapsKit/MaptecMapsKit.h>

@interface MTCExampleZoomViewController () <MTCMapViewDelegate>

@property (nonatomic, strong) MTCMapView *mapView;
@property (nonatomic, strong) MTCExampleMapTestSupport *mapTestSupport;
@property (nonatomic, assign) NSInteger positionIndex;
@property (nonatomic, assign) NSInteger zoomLevelPositionIndex;
@property (nonatomic, assign) NSInteger zoomLevelFormatIndex;
@property (nonatomic, assign) CGFloat buttonSize;

@end

@implementation MTCExampleZoomViewController

- (void)dealloc {
}
#pragma mark - Public

#pragma mark - Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = UIColor.whiteColor;
    self.view.accessibilityIdentifier = MTCExampleTestAccessibilityMapZoomScreen;

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

- (void)showZoomSettings {
    ExampleSettingsSheetView *sheet =
        [[ExampleSettingsSheetView alloc] initWithTitle:[self localizedStringForKey:@"map_item_zoom"]
                                               sections:[self zoomSections]];
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

    self.mapView.uiSettings.compassEnabled = NO;
    self.mapView.uiSettings.scaleBarEnabled = NO;

    self.mapView.uiSettings.permitShowAll = YES;
    self.mapView.uiSettings.zoomButtonsEnabled = YES;
    self.mapView.uiSettings.zoomLevelVisible = YES;
    self.mapView.uiSettings.zoomButtonsGravity = MTCUIPositionBottom | MTCUIPositionLeft;
    self.mapView.uiSettings.buttonSize = 50.0;
    self.mapView.uiSettings.zoomLevelFormat = MTCZoomLevelPrecisionOneDecimal;
    self.mapView.uiSettings.zoomLevelPosition = MTCZoomLevelPositionMiddle;
    self.mapView.mapLanguage = [self mapLanguageForDemoLanguage:self.demoLanguage];

    self.positionIndex = [MTCExampleMapBizUtil MTCIndexForUIPosition:self.mapView.uiSettings.zoomButtonsGravity];
    self.zoomLevelPositionIndex = self.mapView.uiSettings.zoomLevelPosition;
    self.zoomLevelFormatIndex = self.mapView.uiSettings.zoomLevelFormat;
    self.buttonSize = self.mapView.uiSettings.buttonSize;
}

- (NSArray<ExampleSettingsSection *> *)zoomSections {
    __weak typeof(self) weakSelf = self;
    return @[
        [ExampleSettingsSection sectionWithTitle:[self localizedStringForKey:@"zoom_section_display"] items:@[
            [[ExampleSettingsItem boolItemWithTitle:[self localizedStringForKey:@"zoom_show_buttons"]
                                             getter:^BOOL { return weakSelf.mapView.uiSettings.zoomButtonsEnabled; }
                                             setter:^(BOOL value) {
                weakSelf.mapView.uiSettings.zoomButtonsEnabled = value;
            }] withAccessibilityIdentifier:MTCExampleTestAccessibilitySwitchZoomEnabled],
            [ExampleSettingsItem boolItemWithTitle:[self localizedStringForKey:@"zoom_show_level"]
                                            getter:^BOOL { return weakSelf.mapView.uiSettings.zoomLevelVisible; }
                                            setter:^(BOOL value) {
                weakSelf.mapView.uiSettings.zoomLevelVisible = value;
            }],
        ]],
        [ExampleSettingsSection sectionWithTitle:[self localizedStringForKey:@"zoom_section_layout"] items:@[
            [[ExampleSettingsItem listItemWithTitle:[self localizedStringForKey:@"zoom_gravity_label"]
                                            options:[self localizedPositionTitles]
                                             getter:^NSInteger { return weakSelf.positionIndex; }
                                             setter:^(NSInteger index) {
                weakSelf.positionIndex = index;
                weakSelf.mapView.uiSettings.zoomButtonsGravity = [MTCExampleMapBizUtil MTCUIPositionForIndex:index];
            }] withAccessibilityIdentifier:MTCExampleTestAccessibilityDropdownZoomGravity],
            [ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"zoom_button_size_label"]
                                             minimum:24.0
                                             maximum:60.0
                                                step:1.0
                                              getter:^double { return weakSelf.buttonSize; }
                                              setter:^(double value) {
                weakSelf.buttonSize = (CGFloat)value;
                weakSelf.mapView.uiSettings.buttonSize = (CGFloat)value;
            } formatter:^NSString *(double value) {
                return [NSString stringWithFormat:@"%.0f dp", value];
            }],
            [[ExampleSettingsItem listItemWithTitle:[self localizedStringForKey:@"zoom_precision_label"]
                                            options:[self localizedPrecisionTitles]
                                          popupSize:CGSizeMake(260.0, 176.0)
                                             getter:^NSInteger { return weakSelf.zoomLevelFormatIndex; }
                                             setter:^(NSInteger index) {
                weakSelf.zoomLevelFormatIndex = index;
                weakSelf.mapView.uiSettings.zoomLevelFormat = (MTCZoomLevelPrecision)index;
            }] enabledWhen:^BOOL{
                return weakSelf.mapView.uiSettings.zoomLevelVisible;
            }],

            [[ExampleSettingsItem listItemWithTitle:[self localizedStringForKey:@"zoom_level_position_label"]
                                            options:[self localizedZoomLevelPositionTitles]
                                          popupSize:CGSizeMake(220.0, 132.0)
                                             getter:^NSInteger { return weakSelf.zoomLevelPositionIndex; }
                                             setter:^(NSInteger index) {
                weakSelf.zoomLevelPositionIndex = index;
                weakSelf.mapView.uiSettings.zoomLevelPosition = (MTCZoomLevelPosition)index;
            }] enabledWhen:^BOOL{
                return weakSelf.mapView.uiSettings.zoomLevelVisible;
            }],
            
        ]],
    ];
}

#pragma mark -- multi-language

- (void)handleExampleSettingsAction {
    [self showZoomSettings];
}

- (void)demoLanguageDidChange {
    [self applyLocalizedTexts];
}

- (void)applyLocalizedTexts {
    self.title = [self localizedStringForKey:@"map_item_zoom"];
    self.mapView.mapLanguage = [self mapLanguageForDemoLanguage:self.demoLanguage];

    if ([self isSettingsSheetVisible:ExampleSettingsSheetView.class]) {
        [self showZoomSettings];
    }
}

- (NSArray<NSString *> *)localizedPositionTitles {
    return @[
        [self localizedStringForKey:@"zoom_gravity_top_end"],
        [self localizedStringForKey:@"zoom_gravity_top_start"],
        [self localizedStringForKey:@"zoom_gravity_top_center"],
        [self localizedStringForKey:@"zoom_gravity_middle_start"],
        [self localizedStringForKey:@"zoom_gravity_center"],
        [self localizedStringForKey:@"zoom_gravity_middle_end"],
        [self localizedStringForKey:@"zoom_gravity_bottom_end"],
        [self localizedStringForKey:@"zoom_gravity_bottom_start"],
        [self localizedStringForKey:@"zoom_gravity_bottom_center"],
    ];
}

- (NSArray<NSString *> *)localizedPrecisionTitles {
    return @[
        [self localizedStringForKey:@"zoom_precision_0"],
        [self localizedStringForKey:@"zoom_precision_1"],
        [self localizedStringForKey:@"zoom_precision_2"],
        [self localizedStringForKey:@"zoom_precision_3"],
    ];
}

- (NSArray<NSString *> *)localizedZoomLevelPositionTitles {
    return @[
        [self localizedStringForKey:@"zoom_level_position_top"],
        [self localizedStringForKey:@"zoom_level_position_middle"],
        [self localizedStringForKey:@"zoom_level_position_bottom"],
    ];
}
@end
