#import "MTCFloatInfoRichTextViewController.h"

#import "ExampleSettingsSheetView.h"
#import "MTCExampleMapTestSupport.h"
#import "MTCExampleTestAccessibility.h"
#import "MTCExampleToastView.h"
#import "MTCFloatInfoDemoSupport.h"
#import <MaptecMapsKit/MaptecMapsKit.h>

static CLLocationDegrees const kInfoWindowDemoLatitude = 1.360879;
static CLLocationDegrees const kInfoWindowDemoLongitude = 103.732578;
static double const kInfoWindowDemoZoomLevel = 15.0;

@interface MTCFloatInfoRichTextViewController () <MTCMapViewDelegate>

@property (nonatomic, strong) MTCMapView *mapView;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UIButton *clearButton;
@property (nonatomic, strong, nullable) MTCFloatInfoWindow *infoWindow;
@property (nonatomic, strong, nullable) MTCFloatInfoWindowOptions *options;
@property (nonatomic, strong) MTCFloatInfoBubbleView *bubbleView;
@property (nonatomic) BOOL autoCloseOnMapTapEnabled;
@property (nonatomic) BOOL hasPresentedInitialWindow;
@property (nonatomic, copy) NSString *richTextHTML;
@property (nonatomic) CGFloat bubbleCornerRadius;
@property (nonatomic) CGFloat bubbleMaximumWidth;
@property (nonatomic, copy) NSString *backgroundColorHex;
@property (nonatomic, copy) NSString *borderColorHex;
@property (nonatomic) CGFloat bubbleBorderWidth;
@property (nonatomic) NSInteger backgroundColorPresetIndex;
@property (nonatomic) NSInteger borderColorPresetIndex;
@property (nonatomic, strong) MTCExampleMapTestSupport *mapTestSupport;

@end

@implementation MTCFloatInfoRichTextViewController

- (void)dealloc {
}

#pragma mark - Public

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = UIColor.whiteColor;
    self.view.accessibilityIdentifier = @"MTCFloatInfoRichTextViewController.screen";
    self.autoCloseOnMapTapEnabled = NO;
    self.richTextHTML = [self localizedStringForKey:@"overlay_default_rich_text_html"];
    self.bubbleCornerRadius = 8.0;
    self.bubbleMaximumWidth = 300.0;
    self.backgroundColorHex = MTCFloatInfoDefaultBackgroundColorHex;
    self.borderColorHex = MTCFloatInfoDefaultBorderColorHex;
    self.bubbleBorderWidth = 1.0;
    self.backgroundColorPresetIndex = 0;
    self.borderColorPresetIndex = 7;
    [self configureNavigationItems:NO];
    [self configureMapView];
//    [self configureTopBar];
    [self focusMap];
    [self applyLocalizedTexts];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.hasPresentedInitialWindow) {
        return;
    }
    self.hasPresentedInitialWindow = YES;
    [self addInfoWindow];
}

#pragma mark - protocol

- (void)mapView:(MTCMapView *)mapView didTapAtCoordinate:(CLLocationCoordinate2D)coordinate {
    (void)mapView;
    if (!CLLocationCoordinate2DIsValid(coordinate)) {
        return;
    }
    [self updateStatus:[NSString stringWithFormat:[self localizedStringForKey:@"overlay_map_tap_6f_6f"], coordinate.latitude, coordinate.longitude] showToast:NO];
}

- (void)mapViewDidFinishLoadingMap:(MTCMapView *)mapView {
    dispatch_async(dispatch_get_main_queue(), ^{
        (void)mapView;
        [self.mapTestSupport markMapRenderedReady];
        [self.mapTestSupport pauseMapRenderingIfUITesting:self.mapView];
    });
}

- (void)mapView:(MTCMapView *)mapView didLoadMapStyleWithID:(NSString *)mapStyleID {
    dispatch_async(dispatch_get_main_queue(), ^{
        (void)mapView;
        (void)mapStyleID;
        [self.mapTestSupport markMapRenderedReady];
        [self.mapTestSupport pauseMapRenderingIfUITesting:self.mapView];
    });
}

- (void)mapView:(MTCMapView *)mapView didFinishSwitchingMapStyleWithID:(NSString *)mapStyleID {
    dispatch_async(dispatch_get_main_queue(), ^{
        (void)mapView;
        (void)mapStyleID;
        [self.mapTestSupport markMapRenderedReady];
        [self.mapTestSupport pauseMapRenderingIfUITesting:self.mapView];
    });
}

#pragma mark - Delegate

#pragma mark - Event

- (void)showSettings {
    __weak typeof(self) weakSelf = self;
    ExampleSettingsSheetView *sheet =
        [[ExampleSettingsSheetView alloc] initWithTitle:self.title
                                               sections:@[
        [ExampleSettingsSection sectionWithTitle:[self localizedStringForKey:@"overlay_actions"] items:@[
            [[ExampleSettingsItem actionItemWithTitle:[self localizedStringForKey:@"overlay_add_b58c75"] handler:^{
                [weakSelf addInfoWindow];
            }] withAccessibilityIdentifier:MTCExampleTestAccessibilitySymbolBtnAddMarker],
            [[ExampleSettingsItem actionItemWithTitle:[self localizedStringForKey:@"overlay_remove"] handler:^{
                [weakSelf clearInfoWindowAndReport:YES];
            }] withAccessibilityIdentifier:MTCExampleTestAccessibilitySymbolBtnClearAll],
        ]],
        [ExampleSettingsSection sectionWithTitle:[self localizedStringForKey:@"overlay_window_behavior"] items:@[
            [ExampleSettingsItem boolItemWithTitle:[self localizedStringForKey:@"overlay_auto_close"]
                                            getter:^BOOL {
                return weakSelf.autoCloseOnMapTapEnabled;
            } setter:^(BOOL value) {
                weakSelf.autoCloseOnMapTapEnabled = value;
                [weakSelf updateExistingInfoWindowConfiguration];
            }],
        ]],
        [ExampleSettingsSection sectionWithTitle:[self localizedStringForKey:@"overlay_rich_text_settings"] items:@[
            [[ExampleSettingsItem multilineTextItemWithTitle:[self localizedStringForKey:@"overlay_rich_text_content"]
                                                 placeholder:[self localizedStringForKey:@"overlay_default_rich_text_html"]
                                                      getter:^NSString *{
                return weakSelf.richTextHTML ?: @"";
            } setter:^(NSString *value) {
                weakSelf.richTextHTML = value.length > 0 ? value : [weakSelf localizedStringForKey:@"overlay_default_rich_text_html"];
                [weakSelf updateExistingInfoWindowConfiguration];
            }] enabledWhen:^BOOL {
                return weakSelf.infoWindow != nil;
            }],
        ]],
        [ExampleSettingsSection sectionWithTitle:[self localizedStringForKey:@"overlay_style"] items:@[
            [[ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"overlay_corner_radius"]
                                              minimum:0.0
                                              maximum:50.0
                                                 step:1.0
                                               getter:^double {
                return weakSelf.bubbleCornerRadius;
            } setter:^(double value) {
                weakSelf.bubbleCornerRadius = value;
                [weakSelf updateExistingInfoWindowConfiguration];
            } formatter:^NSString *(double value) {
                return [NSString stringWithFormat:@"%.0f px", value];
            }] enabledWhen:^BOOL {
                return weakSelf.infoWindow != nil;
            }],
            [[ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"overlay_max_width"]
                                              minimum:50.0
                                              maximum:800.0
                                                 step:1.0
                                               getter:^double {
                return weakSelf.bubbleMaximumWidth;
            } setter:^(double value) {
                weakSelf.bubbleMaximumWidth = floor(value);
                [weakSelf updateExistingInfoWindowConfiguration];
            } formatter:^NSString *(double value) {
                return [NSString stringWithFormat:@"%.0f px", value];
            }] enabledWhen:^BOOL {
                return weakSelf.infoWindow != nil;
            }],
            [[ExampleSettingsItem colorInputItemWithTitle:[self localizedStringForKey:@"overlay_background_color"]
                                              placeholder:MTCFloatInfoDefaultBackgroundColorHex
                                                  options:MTCFloatInfoPresetColorTitles()
                                           optionHexValues:MTCFloatInfoPresetColorTitles()
                                                popupSize:CGSizeMake(260.0, 360.0)
                                                   getter:^NSString *{
                return weakSelf.backgroundColorHex ?: @"";
            } setter:^(NSString *value) {
                weakSelf.backgroundColorHex = value.length > 0 ? value : MTCFloatInfoDefaultBackgroundColorHex;
                weakSelf.backgroundColorPresetIndex = [weakSelf presetIndexForHexValue:weakSelf.backgroundColorHex fallbackIndex:weakSelf.backgroundColorPresetIndex];
                [weakSelf updateExistingInfoWindowConfiguration];
            } optionGetter:^NSInteger {
                return weakSelf.backgroundColorPresetIndex;
            } optionSetter:^(NSInteger index) {
                weakSelf.backgroundColorPresetIndex = index;
                weakSelf.backgroundColorHex = MTCFloatInfoPresetColors()[index].hexValue;
                [weakSelf updateExistingInfoWindowConfiguration];
            }] enabledWhen:^BOOL {
                return weakSelf.infoWindow != nil;
            }],
            [[ExampleSettingsItem colorInputItemWithTitle:[self localizedStringForKey:@"overlay_border_color"]
                                              placeholder:MTCFloatInfoDefaultBorderColorHex
                                                  options:MTCFloatInfoPresetColorTitles()
                                           optionHexValues:MTCFloatInfoPresetColorTitles()
                                                popupSize:CGSizeMake(260.0, 360.0)
                                                   getter:^NSString *{
                return weakSelf.borderColorHex ?: @"";
            } setter:^(NSString *value) {
                weakSelf.borderColorHex = value.length > 0 ? value : MTCFloatInfoDefaultBorderColorHex;
                weakSelf.borderColorPresetIndex = [weakSelf presetIndexForHexValue:weakSelf.borderColorHex fallbackIndex:weakSelf.borderColorPresetIndex];
                [weakSelf updateExistingInfoWindowConfiguration];
            } optionGetter:^NSInteger {
                return weakSelf.borderColorPresetIndex;
            } optionSetter:^(NSInteger index) {
                weakSelf.borderColorPresetIndex = index;
                weakSelf.borderColorHex = MTCFloatInfoPresetColors()[index].hexValue;
                [weakSelf updateExistingInfoWindowConfiguration];
            }] enabledWhen:^BOOL {
                return weakSelf.infoWindow != nil;
            }],
            [[ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"overlay_border_width"]
                                              minimum:0.0
                                              maximum:8.0
                                                 step:1.0
                                               getter:^double {
                return weakSelf.bubbleBorderWidth;
            } setter:^(double value) {
                weakSelf.bubbleBorderWidth = value;
                [weakSelf updateExistingInfoWindowConfiguration];
            } formatter:^NSString *(double value) {
                return [NSString stringWithFormat:@"%.0f px", value];
            }] enabledWhen:^BOOL {
                return weakSelf.infoWindow != nil;
            }],
        ]],
    ]];
    [sheet showInView:self.view animated:NO];
}

- (void)didTapClearAll {
    [self clearInfoWindowAndReport:YES];
}

- (void)didTapBubbleView {
    [self updateStatus:[self localizedStringForKey:@"overlay_rich_text_click"] showToast:YES];
}

#pragma mark - Private

- (void)configureMapView {
    self.mapTestSupport = [[MTCExampleMapTestSupport alloc] init];
    [self.mapTestSupport installOnHostView:self.view];

    self.mapView = [[MTCMapView alloc] initWithFrame:self.view.bounds];
    self.mapView.delegate = self;
    self.mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.mapView];
}

- (void)configureTopBar {
    UIView *topBar = [[UIView alloc] init];
    topBar.translatesAutoresizingMaskIntoConstraints = NO;
    topBar.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.95];
    [self.view addSubview:topBar];
    [topBar addSubview:self.statusLabel];
    [topBar addSubview:self.clearButton];

    [NSLayoutConstraint activateConstraints:@[
        [topBar.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [topBar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [topBar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [topBar.heightAnchor constraintEqualToConstant:64.0],

        [self.statusLabel.topAnchor constraintEqualToAnchor:topBar.topAnchor constant:4.0],
        [self.statusLabel.leadingAnchor constraintEqualToAnchor:topBar.leadingAnchor constant:10.0],
        [self.statusLabel.trailingAnchor constraintEqualToAnchor:topBar.trailingAnchor constant:-10.0],

        [self.clearButton.topAnchor constraintEqualToAnchor:self.statusLabel.bottomAnchor constant:4.0],
        [self.clearButton.centerXAnchor constraintEqualToAnchor:topBar.centerXAnchor],
        [self.clearButton.widthAnchor constraintEqualToConstant:132.0],
        [self.clearButton.heightAnchor constraintEqualToConstant:30.0],
    ]];
}

- (void)addInfoWindow {
    [self clearInfoWindowAndReport:NO];
    [self refreshOptionsAndBubble];
    self.options.coordinate = CLLocationCoordinate2DMake(kInfoWindowDemoLatitude, kInfoWindowDemoLongitude);
    __weak typeof(self) weakSelf = self;
    self.infoWindow = [self.mapView addInfoWindow:self.options];
    self.infoWindow.closeHandler = ^(MTCFloatInfoWindow *infoWindow) {
        if (weakSelf.infoWindow == infoWindow) {
            weakSelf.infoWindow = nil;
            [weakSelf updateStatus:[weakSelf localizedStringForKey:@"overlay_info_window_closed"] showToast:NO];
        }
    };
    [self updateStatus:[self localizedStringForKey:@"overlay_rich_text_info_window_created"] showToast:NO];
}

- (void)clearInfoWindowAndReport:(BOOL)report {
    if (self.infoWindow) {
        [self.mapView removeInfoWindow:self.infoWindow];
        self.infoWindow = nil;
    }
    if (report) {
        [self updateStatus:[self localizedStringForKey:@"overlay_info_window_removed"] showToast:YES];
    }
}

- (void)refreshOptionsAndBubble {
    self.options.autoCloseOnMapTap = self.autoCloseOnMapTapEnabled;
    self.options.contentView = self.bubbleView;
    self.options.anchor = MTCFloatInfoWindowAnchorBottom;
    self.options.visible = YES;
    self.bubbleView.cornerRadius = self.bubbleCornerRadius;
    self.bubbleView.maximumWidth = self.bubbleMaximumWidth;
    self.bubbleView.bubbleBackgroundColor = MTCFloatInfoColorFromHexString(self.backgroundColorHex, MTCFloatInfoDefaultBackgroundColorHex);
    self.bubbleView.bubbleBorderColor = MTCFloatInfoColorFromHexString(self.borderColorHex, MTCFloatInfoDefaultBorderColorHex);
    self.bubbleView.bubbleBorderWidth = self.bubbleBorderWidth;
    [self.bubbleView applyRichTextHTML:self.richTextHTML];
    CGSize size = [self.bubbleView intrinsicContentSize];
    self.bubbleView.bounds = CGRectMake(0.0, 0.0, size.width, size.height);
    [self.bubbleView setNeedsLayout];
    [self.bubbleView layoutIfNeeded];
}

- (void)updateExistingInfoWindowConfiguration {
    if (!self.infoWindow) {
        return;
    }
    [self refreshOptionsAndBubble];
    [self.infoWindow refreshViaOptions:self.options];
    [self.infoWindow updatePosition];
    [self updateStatus:[self localizedStringForKey:@"overlay_info_window_config_updated"] showToast:NO];
}

- (NSInteger)presetIndexForHexValue:(NSString *)hexValue fallbackIndex:(NSInteger)fallbackIndex {
    NSString *normalized = [[hexValue ?: @"" uppercaseString] stringByReplacingOccurrencesOfString:@"#" withString:@""];
    NSArray<MTCFloatInfoColorOption *> *options = MTCFloatInfoPresetColors();
    for (NSInteger index = 0; index < options.count; index++) {
        NSString *candidate = [[options[index].hexValue uppercaseString] stringByReplacingOccurrencesOfString:@"#" withString:@""];
        if ([candidate isEqualToString:normalized]) {
            return index;
        }
    }
    return fallbackIndex;
}

- (void)focusMap {
    [self.mapView setCenterCoordinate:CLLocationCoordinate2DMake(kInfoWindowDemoLatitude, kInfoWindowDemoLongitude)
                            zoomLevel:kInfoWindowDemoZoomLevel];
}

- (void)updateStatus:(NSString *)status showToast:(BOOL)showToast {
    self.statusLabel.text = status;
    if (showToast) {
        [MTCExampleToastView showMessage:status inView:self.view];
    }
}

#pragma mark -- multi-language

- (void)handleExampleSettingsAction {
    [self showSettings];
}

- (void)demoLanguageDidChange {
    [self applyLocalizedTexts];
}

- (void)applyLocalizedTexts {
    self.title = [self localizedStringForKey:@"demo_title_MTCFloatInfoRichTextViewController"];
    if (self.mapView) {
        self.mapView.mapLanguage = [self mapLanguageForDemoLanguage:self.demoLanguage];
    }
    if ([self isSettingsSheetVisible:ExampleSettingsSheetView.class]) {
        [self showSettings];
    }
}

#pragma mark - Getter & Setter

- (UILabel *)statusLabel {
    if (_statusLabel) {
        return _statusLabel;
    }
    _statusLabel = [[UILabel alloc] init];
    _statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _statusLabel.numberOfLines = 2;
    _statusLabel.textAlignment = NSTextAlignmentCenter;
    _statusLabel.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightRegular];
    _statusLabel.textColor = UIColor.darkTextColor;
    return _statusLabel;
}

- (UIButton *)clearButton {
    if (_clearButton) {
        return _clearButton;
    }
    _clearButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _clearButton.translatesAutoresizingMaskIntoConstraints = NO;
    _clearButton.backgroundColor = [UIColor colorWithRed:0.941 green:0.296 blue:0.217 alpha:1.0];
    [_clearButton setTitle:[self localizedStringForKey:@"overlay_remove_info_window"] forState:UIControlStateNormal];
    [_clearButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    _clearButton.titleLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightMedium];
    _clearButton.layer.cornerRadius = 8.0;
    [_clearButton addTarget:self action:@selector(didTapClearAll) forControlEvents:UIControlEventTouchUpInside];
    return _clearButton;
}

- (MTCFloatInfoWindowOptions *)options {
    if (_options) {
        return _options;
    }
    _options = [[MTCFloatInfoWindowOptions alloc] init];
    _options.contentOffset = CGPointZero;
    _options.visible = YES;
    _options.anchor = MTCFloatInfoWindowAnchorBottom;
    return _options;
}

- (MTCFloatInfoBubbleView *)bubbleView {
    if (_bubbleView) {
        return _bubbleView;
    }
    _bubbleView = [[MTCFloatInfoBubbleView alloc] init];
    _bubbleView.isAccessibilityElement = YES;
    _bubbleView.accessibilityIdentifier = MTCExampleTestAccessibilityInfoWindowBubble;
    [_bubbleView addTarget:self action:@selector(didTapBubbleView) forControlEvents:UIControlEventTouchUpInside];
    return _bubbleView;
}

@end
