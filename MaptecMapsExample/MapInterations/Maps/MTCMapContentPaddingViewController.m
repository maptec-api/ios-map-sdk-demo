//
//  MTCMapContentPaddingViewController.m
//  MaptecMapsExample
//
//  Created by Codex on 2026/9/8.
//

#import "MTCMapContentPaddingViewController.h"

#import "ExampleSettingsSheetView.h"
#import "MTCExampleMapTestSupport.h"

#import <MaptecMapsKit/MaptecMapsKit.h>

#include <math.h>

static CGFloat const MTCMapContentPaddingSliderMaximum = 400.0;
static CGFloat const MTCMapContentPaddingSliderStep = 10.0;
static CGFloat const MTCMapContentPaddingCenterBadgeHeight = 30.0;
static CGFloat const MTCMapContentPaddingCenterBadgeMinimumWidth = 72.0;

static NSString * const MTCMapContentPaddingScreenAccessibilityIdentifier = @"MTCMapContentPaddingViewController.screen";
static NSString * const MTCMapContentPaddingReadoutAccessibilityIdentifier = @"content_padding_readout";
static NSString * const MTCMapContentPaddingLeftSliderAccessibilityIdentifier = @"content_padding_left_slider";
static NSString * const MTCMapContentPaddingTopSliderAccessibilityIdentifier = @"content_padding_top_slider";
static NSString * const MTCMapContentPaddingRightSliderAccessibilityIdentifier = @"content_padding_right_slider";
static NSString * const MTCMapContentPaddingBottomSliderAccessibilityIdentifier = @"content_padding_bottom_slider";
static NSString * const MTCMapContentPaddingApplyButtonAccessibilityIdentifier = @"content_padding_apply_button";
static NSString * const MTCMapContentPaddingClearButtonAccessibilityIdentifier = @"content_padding_clear_button";
static NSString * const MTCMapContentPaddingLeftOverlayAccessibilityIdentifier = @"content_padding_overlay_left";
static NSString * const MTCMapContentPaddingTopOverlayAccessibilityIdentifier = @"content_padding_overlay_top";
static NSString * const MTCMapContentPaddingRightOverlayAccessibilityIdentifier = @"content_padding_overlay_right";
static NSString * const MTCMapContentPaddingBottomOverlayAccessibilityIdentifier = @"content_padding_overlay_bottom";
static NSString * const MTCMapContentPaddingCenterBadgeAccessibilityIdentifier = @"content_padding_center_badge";

typedef NS_ENUM(NSInteger, MTCMapContentPaddingEdge) {
    MTCMapContentPaddingEdgeLeft = 0,
    MTCMapContentPaddingEdgeTop,
    MTCMapContentPaddingEdgeRight,
    MTCMapContentPaddingEdgeBottom,
};

static NSString *MTCMapContentPaddingFormattedInsets(UIEdgeInsets insets) {
    return [NSString stringWithFormat:@"[%.0f, %.0f, %.0f, %.0f]",
                                      insets.left,
                                      insets.top,
                                      insets.right,
                                      insets.bottom];
}

static CGFloat MTCMapContentPaddingClampedValue(CGFloat value, CGFloat maximum) {
    return MIN(MAX(value, 0.0), MAX(maximum, 0.0));
}

@interface MTCMapContentPaddingViewController () <MTCMapViewDelegate>

@property (nonatomic, strong) MTCMapView *mapView;
@property (nonatomic, weak) ExampleSettingsSheetView *settingsSheet;
@property (nonatomic, strong) MTCExampleMapTestSupport *mapTestSupport;
@property (nonatomic, strong) UIView *leftPaddingOverlayView;
@property (nonatomic, strong) UIView *topPaddingOverlayView;
@property (nonatomic, strong) UIView *rightPaddingOverlayView;
@property (nonatomic, strong) UIView *bottomPaddingOverlayView;
@property (nonatomic, strong) UILabel *centerBadgeLabel;
@property (nonatomic) UIEdgeInsets draftPaddingInsets;
@property (nonatomic) UIEdgeInsets appliedPaddingInsets;

@end

@implementation MTCMapContentPaddingViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = UIColor.whiteColor;
    self.view.accessibilityIdentifier = MTCMapContentPaddingScreenAccessibilityIdentifier;

    [self configureNavigationItems:NO];
    [self configureMapView];
    [self configurePaddingOverlays];
    [self configureCenterBadge];
    [self applyLocalizedTexts];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self refreshPaddingOverlays];
    [self layoutCenterBadge];
}

#pragma mark - Delegate

- (void)mapViewDidFinishLoadingMap:(MTCMapView *)mapView {
    (void)mapView;
    [self.mapTestSupport markMapRenderedReady];
    [self.mapTestSupport pauseMapRenderingIfUITesting:self.mapView];
}

- (void)mapView:(MTCMapView *)mapView didLoadMapStyleWithID:(NSString *)mapStyleID {
    (void)mapView;
    (void)mapStyleID;
    [self.mapTestSupport markMapRenderedReady];
    [self.mapTestSupport pauseMapRenderingIfUITesting:self.mapView];
}

- (void)mapView:(MTCMapView *)mapView didFinishSwitchingMapStyleWithID:(NSString *)mapStyleID {
    (void)mapView;
    (void)mapStyleID;
    [self.mapTestSupport markMapRenderedReady];
    [self.mapTestSupport pauseMapRenderingIfUITesting:self.mapView];
}

#pragma mark - Private

- (void)handleExampleSettingsAction {
    [self showSettingsSheet];
}

- (void)showSettingsSheet {
    ExampleSettingsSheetView *sheet =
        [[ExampleSettingsSheetView alloc] initWithTitle:[self localizedStringForKey:@"common_settings_sheet_title"]
                                               sections:[self settingsSections]];
    self.settingsSheet = sheet;
    [sheet showInView:self.view animated:YES];
}

- (void)configureMapView {
    self.mapTestSupport = [[MTCExampleMapTestSupport alloc] init];
    [self.mapTestSupport installOnHostView:self.view];

    self.mapView = [[MTCMapView alloc] initWithFrame:self.view.bounds];
    self.mapView.delegate = self;
    self.mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.mapView];
    
    [self.mapView setCenterCoordinate:CLLocationCoordinate2DMake(1.3521, 103.8198) zoomLevel:14];
    MTCMarker *marker = [[MTCMarker alloc] initWithCoordinate:CLLocationCoordinate2DMake(1.3521, 103.8198)];
    [self.mapView addOverlay:marker];

}

- (void)configurePaddingOverlays {
    self.leftPaddingOverlayView = [self paddingOverlayViewWithAccessibilityIdentifier:MTCMapContentPaddingLeftOverlayAccessibilityIdentifier];
    self.topPaddingOverlayView = [self paddingOverlayViewWithAccessibilityIdentifier:MTCMapContentPaddingTopOverlayAccessibilityIdentifier];
    self.rightPaddingOverlayView = [self paddingOverlayViewWithAccessibilityIdentifier:MTCMapContentPaddingRightOverlayAccessibilityIdentifier];
    self.bottomPaddingOverlayView = [self paddingOverlayViewWithAccessibilityIdentifier:MTCMapContentPaddingBottomOverlayAccessibilityIdentifier];

    [self.view addSubview:self.topPaddingOverlayView];
    [self.view addSubview:self.bottomPaddingOverlayView];
    [self.view addSubview:self.leftPaddingOverlayView];
    [self.view addSubview:self.rightPaddingOverlayView];
}

- (UIView *)paddingOverlayViewWithAccessibilityIdentifier:(NSString *)accessibilityIdentifier {
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    view.backgroundColor = [UIColor colorWithRed:0.129 green:0.588 blue:0.953 alpha:0.4];
    view.accessibilityIdentifier = accessibilityIdentifier;
    view.hidden = YES;
    view.userInteractionEnabled = NO;
    return view;
}

- (void)configureCenterBadge {
//    self.centerBadgeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
//    self.centerBadgeLabel.backgroundColor = [UIColor colorWithRed:0.125 green:0.149 blue:0.188 alpha:0.86];
//    self.centerBadgeLabel.textColor = UIColor.whiteColor;
//    self.centerBadgeLabel.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightSemibold];
//    self.centerBadgeLabel.textAlignment = NSTextAlignmentCenter;
//    self.centerBadgeLabel.layer.cornerRadius = MTCMapContentPaddingCenterBadgeHeight * 0.5;
//    self.centerBadgeLabel.layer.masksToBounds = YES;
//    self.centerBadgeLabel.accessibilityIdentifier = MTCMapContentPaddingCenterBadgeAccessibilityIdentifier;
//    self.centerBadgeLabel.userInteractionEnabled = NO;
//    [self.view addSubview:self.centerBadgeLabel];
}

- (void)refreshPaddingOverlays {
    CGRect bounds = self.view.bounds;
    CGFloat width = CGRectGetWidth(bounds);
    CGFloat height = CGRectGetHeight(bounds);

    CGFloat left = MTCMapContentPaddingClampedValue(self.appliedPaddingInsets.left, width);
    CGFloat top = MTCMapContentPaddingClampedValue(self.appliedPaddingInsets.top, height);
    CGFloat right = MTCMapContentPaddingClampedValue(self.appliedPaddingInsets.right, width);
    CGFloat bottom = MTCMapContentPaddingClampedValue(self.appliedPaddingInsets.bottom, height);

    self.topPaddingOverlayView.frame = CGRectMake(0.0, 0.0, width, top);
    self.bottomPaddingOverlayView.frame = CGRectMake(0.0, height - bottom, width, bottom);
    self.leftPaddingOverlayView.frame = CGRectMake(0.0, 0.0, left, height);
    self.rightPaddingOverlayView.frame = CGRectMake(width - right, 0.0, right, height);

    self.topPaddingOverlayView.hidden = top <= 0.0;
    self.bottomPaddingOverlayView.hidden = bottom <= 0.0;
    self.leftPaddingOverlayView.hidden = left <= 0.0;
    self.rightPaddingOverlayView.hidden = right <= 0.0;
}

- (void)layoutCenterBadge {
    if (!self.centerBadgeLabel) {
        return;
    }

    CGSize labelSize = [self.centerBadgeLabel sizeThatFits:CGSizeMake(CGFLOAT_MAX, MTCMapContentPaddingCenterBadgeHeight)];
    CGFloat width = MAX(MTCMapContentPaddingCenterBadgeMinimumWidth, ceil(labelSize.width) + 24.0);
    CGFloat height = MTCMapContentPaddingCenterBadgeHeight;
    CGRect bounds = self.view.bounds;
    self.centerBadgeLabel.frame = CGRectMake(floor((CGRectGetWidth(bounds) - width) * 0.5),
                                             floor((CGRectGetHeight(bounds) - height) * 0.5),
                                             width,
                                             height);
}

- (NSArray<ExampleSettingsSection *> *)settingsSections {
    __weak typeof(self) weakSelf = self;
    ExampleSettingsNumberFormatter formatter = ^NSString * _Nonnull(double value) {
        return [NSString stringWithFormat:@"%.0f pt", value];
    };

    return @[
        [ExampleSettingsSection sectionWithTitle:@"" items:@[
            [ExampleSettingsItem infoItemWithText:[self localizedStringForKey:@"content_padding_description"]],
            [[ExampleSettingsItem dynamicInfoItemWithGetter:^NSString * _Nonnull {
                __strong typeof(weakSelf) self = weakSelf;
                if (!self) {
                    return @"";
                }
                return [NSString stringWithFormat:[self localizedStringForKey:@"content_padding_readout"],
                                                  MTCMapContentPaddingFormattedInsets(self.appliedPaddingInsets)];
            }] withAccessibilityIdentifier:MTCMapContentPaddingReadoutAccessibilityIdentifier],
            [[ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"content_padding_left"]
                                             minimum:0.0
                                             maximum:MTCMapContentPaddingSliderMaximum
                                                step:MTCMapContentPaddingSliderStep
                                              getter:^double { return [weakSelf draftPaddingValueForEdge:MTCMapContentPaddingEdgeLeft]; }
                                              setter:^(double value) { [weakSelf setDraftPaddingValue:value forEdge:MTCMapContentPaddingEdgeLeft]; }
                                           formatter:formatter] withAccessibilityIdentifier:MTCMapContentPaddingLeftSliderAccessibilityIdentifier],
            [[ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"content_padding_top"]
                                             minimum:0.0
                                             maximum:MTCMapContentPaddingSliderMaximum
                                                step:MTCMapContentPaddingSliderStep
                                              getter:^double { return [weakSelf draftPaddingValueForEdge:MTCMapContentPaddingEdgeTop]; }
                                              setter:^(double value) { [weakSelf setDraftPaddingValue:value forEdge:MTCMapContentPaddingEdgeTop]; }
                                           formatter:formatter] withAccessibilityIdentifier:MTCMapContentPaddingTopSliderAccessibilityIdentifier],
            [[ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"content_padding_right"]
                                             minimum:0.0
                                             maximum:MTCMapContentPaddingSliderMaximum
                                                step:MTCMapContentPaddingSliderStep
                                              getter:^double { return [weakSelf draftPaddingValueForEdge:MTCMapContentPaddingEdgeRight]; }
                                              setter:^(double value) { [weakSelf setDraftPaddingValue:value forEdge:MTCMapContentPaddingEdgeRight]; }
                                           formatter:formatter] withAccessibilityIdentifier:MTCMapContentPaddingRightSliderAccessibilityIdentifier],
            [[ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"content_padding_bottom"]
                                             minimum:0.0
                                             maximum:MTCMapContentPaddingSliderMaximum
                                                step:MTCMapContentPaddingSliderStep
                                              getter:^double { return [weakSelf draftPaddingValueForEdge:MTCMapContentPaddingEdgeBottom]; }
                                              setter:^(double value) { [weakSelf setDraftPaddingValue:value forEdge:MTCMapContentPaddingEdgeBottom]; }
                                           formatter:formatter] withAccessibilityIdentifier:MTCMapContentPaddingBottomSliderAccessibilityIdentifier],
            [[ExampleSettingsItem actionItemWithTitle:[self localizedStringForKey:@"content_padding_apply"]
                                              handler:^{
                [weakSelf applySelectedPadding];
            }] withAccessibilityIdentifier:MTCMapContentPaddingApplyButtonAccessibilityIdentifier],
            [[ExampleSettingsItem actionItemWithTitle:[self localizedStringForKey:@"content_padding_clear"]
                                              handler:^{
                [weakSelf clearSelectedPadding];
            }] withAccessibilityIdentifier:MTCMapContentPaddingClearButtonAccessibilityIdentifier],
        ]],
    ];
}

- (double)draftPaddingValueForEdge:(MTCMapContentPaddingEdge)edge {
    switch (edge) {
        case MTCMapContentPaddingEdgeLeft:
            return self.draftPaddingInsets.left;
        case MTCMapContentPaddingEdgeTop:
            return self.draftPaddingInsets.top;
        case MTCMapContentPaddingEdgeRight:
            return self.draftPaddingInsets.right;
        case MTCMapContentPaddingEdgeBottom:
            return self.draftPaddingInsets.bottom;
    }
    return 0.0;
}

- (void)setDraftPaddingValue:(double)value forEdge:(MTCMapContentPaddingEdge)edge {
    UIEdgeInsets insets = self.draftPaddingInsets;
    switch (edge) {
        case MTCMapContentPaddingEdgeLeft:
            insets.left = value;
            break;
        case MTCMapContentPaddingEdgeTop:
            insets.top = value;
            break;
        case MTCMapContentPaddingEdgeRight:
            insets.right = value;
            break;
        case MTCMapContentPaddingEdgeBottom:
            insets.bottom = value;
            break;
    }
    self.draftPaddingInsets = insets;
}

- (void)applySelectedPadding {
    [self.mapView setCenterCoordinate:CLLocationCoordinate2DMake(1.3521, 103.8198) zoomLevel:14];
    self.mapView.cameraPadding = self.draftPaddingInsets;
    self.appliedPaddingInsets = self.mapView.cameraPadding;
    [self refreshPaddingOverlays];
    [self.settingsSheet refreshVisibleItems];
}

- (void)clearSelectedPadding {
    self.draftPaddingInsets = UIEdgeInsetsZero;
    self.mapView.cameraPadding = UIEdgeInsetsZero;
    self.appliedPaddingInsets = self.mapView.cameraPadding;
    [self refreshPaddingOverlays];
    [self.settingsSheet refreshVisibleItems];
}

#pragma mark -- multi-language

- (void)demoLanguageDidChange {
    [self applyLocalizedTexts];
}

- (void)applyLocalizedTexts {
    self.title = [self localizedStringForKey:@"demo_title_MTCMapContentPaddingViewController"];
    self.centerBadgeLabel.text = [self localizedStringForKey:@"content_padding_center"];
    [self layoutCenterBadge];
    if ([self isSettingsSheetVisible:ExampleSettingsSheetView.class]) {
        [self showSettingsSheet];
    }
}

@end
