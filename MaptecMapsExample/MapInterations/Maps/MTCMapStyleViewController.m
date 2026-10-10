//
//  MTCMapStyleViewController.m
//  MaptecMapsExample
//
//  Created by ZHOUPanpan on 2026/6/29.
//

#import "MTCMapStyleViewController.h"

#import "MTCExampleMapTestSupport.h"
#import "MTCExampleTestAccessibility.h"
#import "MTCExampleToastView.h"

#import <MaptecMapsKit/MaptecMapsKit.h>

static NSString *const MTCExampleStandardMapStyleID = @"light";
static NSString *const MTCExampleNightMapStyleID = @"dark";
static CGFloat const MTCMapStyleSwitcherHeight = 56.0;
static CGFloat const MTCMapStyleSwitcherHorizontalInset = 16.0;
static CGFloat const MTCMapStyleSwitcherBottomInset = 48.0;

@interface MTCMapStyleViewController () <MTCMapViewDelegate>

@property (nonatomic, strong) MTCMapView *mapView;
@property (nonatomic, strong) MTCExampleMapTestSupport *mapTestSupport;
@property (nonatomic, strong) UIView *styleSwitcherView;
@property (nonatomic, strong) UIButton *standardStyleButton;
@property (nonatomic, strong) UIButton *nightStyleButton;
@property (nonatomic, copy, nullable) NSString *currentMapStyleID;
@property (nonatomic, copy, nullable) NSString *pendingLoadMapStyleID;

@end

@implementation MTCMapStyleViewController

- (void)dealloc {
}
#pragma mark - Public

#pragma mark - Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureNavigationItems:YES];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = UIColor.whiteColor;
    self.view.accessibilityIdentifier = MTCExampleTestAccessibilityMapStyleScreen;

    [self configureMapView];
    [self configureStyleSwitcherView];
    [self refreshStyleButtons];
    [self applyLocalizedTexts];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self layoutStyleSwitcherView];
}
#pragma mark - protocol

#pragma mark - Delegate
#pragma mark -- MTCMapViewDelegate
- (void)mapView:(MTCMapView *)mapView willStartLoadingMapStyleWithID:(NSString *)mapStyleID {
    (void)mapView;
    self.pendingLoadMapStyleID = mapStyleID;
    [self.mapTestSupport clearMapRenderedReady];
    [self.mapTestSupport pauseMapRenderingIfUITesting:self.mapView];
}

- (void)mapView:(MTCMapView *)mapView didLoadMapStyleWithID:(NSString *)mapStyleID {
    (void)mapView;
    [self.mapTestSupport markMapRenderedReady];
    [self.mapTestSupport pauseMapRenderingIfUITesting:self.mapView];
}

- (void)mapView:(MTCMapView *)mapView didFinishSwitchingMapStyleWithID:(NSString *)mapStyleID {
    self.currentMapStyleID = mapStyleID;
    self.pendingLoadMapStyleID = nil;
    [self.mapTestSupport markMapRenderedReady];
    [self.mapTestSupport pauseMapRenderingIfUITesting:self.mapView];
    [self refreshStyleButtons];
    [self showToastWithMessage:[NSString stringWithFormat:[self localizedStringForKey:@"map_style_switch_success"], mapStyleID]];
}
- (void)mapView:(MTCMapView *)mapView didFailLoadingMapStyleWithID:(NSString *)mapStyleID message:(NSString *)message {
    (void)mapView;
    self.pendingLoadMapStyleID = nil;
    [self refreshStyleButtons];
    NSString *errorMessage = message.length > 0 ? message : [self localizedStringForKey:@"common_unknown_error"];
    [self showToastWithMessage:[NSString stringWithFormat:[self localizedStringForKey:@"map_style_switch_failure"], mapStyleID, errorMessage]];
}

- (void)mapViewDidFinishLoadingMap:(MTCMapView *)mapView {
    (void)mapView;
    [self.mapTestSupport markMapRenderedReady];
    [self.mapTestSupport pauseMapRenderingIfUITesting:self.mapView];
}

#pragma mark - Event
- (void)didTapStandardStyleButton {
    [self loadMapStyleWithID:MTCExampleStandardMapStyleID];
}

- (void)didTapNightStyleButton {
    [self loadMapStyleWithID:MTCExampleNightMapStyleID];
}

#pragma mark - Private
- (void)configureMapView {
    self.mapView = [[MTCMapView alloc] initWithFrame:self.view.bounds];
    self.mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.mapView.delegate = self;
    [self.view addSubview:self.mapView];

    self.mapTestSupport = [[MTCExampleMapTestSupport alloc] init];
    [self.mapTestSupport installOnHostView:self.view];

    [self.mapView setCenterCoordinate:CLLocationCoordinate2DMake(31.2304, 121.4737) zoomLevel:11.5];
    [self loadMapStyleWithID:MTCExampleStandardMapStyleID];

    self.mapView.uiSettings.compassEnabled = NO;
    self.mapView.uiSettings.zoomButtonsEnabled = NO;
    self.mapView.uiSettings.scaleBarEnabled = NO;
    self.mapView.uiSettings.dayNightModeEnabled = NO;
}

- (void)configureStyleSwitcherView {
    [self.view addSubview:self.styleSwitcherView];
    [self.styleSwitcherView addSubview:self.standardStyleButton];
    [self.styleSwitcherView addSubview:self.nightStyleButton];
    self.standardStyleButton.accessibilityIdentifier = MTCExampleTestAccessibilityStyleLightButton;
    self.nightStyleButton.accessibilityIdentifier = MTCExampleTestAccessibilityStyleDarkButton;
}

- (void)layoutStyleSwitcherView {
    CGSize boundsSize = self.view.bounds.size;
    CGFloat containerWidth = boundsSize.width - MTCMapStyleSwitcherHorizontalInset * 2.0;
    CGFloat containerY = boundsSize.height - MTCMapStyleSwitcherBottomInset - MTCMapStyleSwitcherHeight;
    self.styleSwitcherView.frame = CGRectMake(MTCMapStyleSwitcherHorizontalInset,
                                              containerY,
                                              containerWidth,
                                              MTCMapStyleSwitcherHeight);

    CGFloat buttonWidth = (containerWidth - MTCMapStyleSwitcherHorizontalInset) * 0.5;
    self.standardStyleButton.frame = CGRectMake(0.0, 0.0, buttonWidth, MTCMapStyleSwitcherHeight);
    self.nightStyleButton.frame = CGRectMake(containerWidth - buttonWidth - MTCMapStyleSwitcherHorizontalInset * 0.5, 0.0, buttonWidth, MTCMapStyleSwitcherHeight);
}

- (void)loadMapStyleWithID:(NSString *)mapStyleID {
    if (mapStyleID.length == 0) {
        return;
    }
    if ([self.pendingLoadMapStyleID isEqualToString:mapStyleID]) {
        return;
    }
    if ([self.currentMapStyleID isEqualToString:mapStyleID]) {
        return;
    }

    self.pendingLoadMapStyleID = mapStyleID;
    [self.mapTestSupport clearMapRenderedReady];
    [self.mapTestSupport pauseMapRenderingIfUITesting:self.mapView];
    [self.mapView loadMapStyleWithID:mapStyleID];
}

- (void)refreshStyleButtons {
    [self applySelectedState:[self isStandardStyleSelected] toButton:self.standardStyleButton];
    [self applySelectedState:[self isNightStyleSelected] toButton:self.nightStyleButton];
}

- (void)applySelectedState:(BOOL)selected toButton:(UIButton *)button {
    UIColor *selectedBackgroundColor = [UIColor colorWithRed:0.17 green:0.45 blue:0.71 alpha:1.0];
    UIColor *normalBackgroundColor = UIColor.whiteColor;
    UIColor *selectedTextColor = UIColor.whiteColor;
    UIColor *normalTextColor = [UIColor colorWithRed:0.12 green:0.43 blue:0.72 alpha:1.0];

    button.backgroundColor = selected ? selectedBackgroundColor : normalBackgroundColor;
    [button setTitleColor:selected ? selectedTextColor : normalTextColor forState:UIControlStateNormal];
}

- (BOOL)isStandardStyleSelected {
    return [self.currentMapStyleID isEqualToString:MTCExampleStandardMapStyleID];
}

- (BOOL)isNightStyleSelected {
    return [self.currentMapStyleID isEqualToString:MTCExampleNightMapStyleID];
}

- (void)showToastWithMessage:(NSString *)message {
    [MTCExampleToastView showMessage:message inView:(self.view.window ?: self.view)];
}

#pragma mark -- multi-language

- (void)demoLanguageDidChange {
    [self applyLocalizedTexts];
}

- (void)applyLocalizedTexts {
    self.title = [self localizedStringForKey:@"demo_title_MTCMapStyleViewController"];
    if (self.mapView) {
        self.mapView.mapLanguage = [self mapLanguageForDemoLanguage:self.demoLanguage];
    }
    [self.standardStyleButton setTitle:[self localizedStringForKey:@"map_style_button_light"] forState:UIControlStateNormal];
    [self.nightStyleButton setTitle:[self localizedStringForKey:@"map_style_button_dark"] forState:UIControlStateNormal];
}

#pragma mark - Getter & Setter

- (UIView *)styleSwitcherView {
    if (_styleSwitcherView) {
        return _styleSwitcherView;
    }

    _styleSwitcherView = [[UIView alloc] initWithFrame:CGRectZero];
    _styleSwitcherView.backgroundColor = UIColor.clearColor;
    _styleSwitcherView.layer.cornerRadius = MTCMapStyleSwitcherHeight * 0.5;
    _styleSwitcherView.layer.masksToBounds = NO;
    return _styleSwitcherView;
}

- (UIButton *)standardStyleButton {
    if (_standardStyleButton) {
        return _standardStyleButton;
    }

    _standardStyleButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _standardStyleButton.layer.cornerRadius = MTCMapStyleSwitcherHeight * 0.5;
    _standardStyleButton.layer.borderWidth = 1.0;
    _standardStyleButton.layer.borderColor = [UIColor colorWithWhite:0.85 alpha:1.0].CGColor;
    _standardStyleButton.titleLabel.font = [UIFont systemFontOfSize:18.0 weight:UIFontWeightSemibold];
    _standardStyleButton.titleLabel.numberOfLines = 2;
    _standardStyleButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    [_standardStyleButton setTitle:@"浅色\nlight" forState:UIControlStateNormal];
    [_standardStyleButton addTarget:self action:@selector(didTapStandardStyleButton) forControlEvents:UIControlEventTouchUpInside];
    return _standardStyleButton;
}

- (UIButton *)nightStyleButton {
    if (_nightStyleButton) {
        return _nightStyleButton;
    }

    _nightStyleButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _nightStyleButton.layer.cornerRadius = MTCMapStyleSwitcherHeight * 0.5;
    _nightStyleButton.layer.borderWidth = 1.0;
    _nightStyleButton.layer.borderColor = [UIColor colorWithWhite:0.85 alpha:1.0].CGColor;
    _nightStyleButton.titleLabel.font = [UIFont systemFontOfSize:18.0 weight:UIFontWeightSemibold];
    _nightStyleButton.titleLabel.numberOfLines = 2;
    _nightStyleButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    [_nightStyleButton setTitle:@"深色\ndark" forState:UIControlStateNormal];
    [_nightStyleButton addTarget:self action:@selector(didTapNightStyleButton) forControlEvents:UIControlEventTouchUpInside];
    return _nightStyleButton;
}

@end
