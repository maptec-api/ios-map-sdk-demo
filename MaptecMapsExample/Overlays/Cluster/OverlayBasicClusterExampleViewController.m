#import "OverlayBasicClusterExampleViewController.h"

#import "ExampleSettingsSheetView.h"
#import "MTCExampleMapTestSupport.h"
#import "MTCExampleTestAccessibility.h"
#import "MTCExampleToastView.h"

#import <MaptecMapsKit/MaptecMapsKit.h>

#include <math.h>

static NSString *const OverlayBasicClusterExampleLightStyleID = @"light";
static NSString *const OverlayBasicClusterExampleDarkStyleID = @"dark";
static NSString *const OverlayBasicClusterExampleExternalDataName = @"cluster_sample_points";
static CLLocationDegrees const OverlayBasicClusterExampleLatitude = 1.31;
static CLLocationDegrees const OverlayBasicClusterExampleLongitude = 103.8125;
static double const OverlayBasicClusterExampleDefaultZoomLevel = 11.15;
static CGFloat const OverlayBasicClusterExampleBaseVisualRadius = 24.0;
static void *const OverlayBasicClusterLifecycleObservationContext = (void *)&OverlayBasicClusterLifecycleObservationContext;

typedef NS_ENUM(NSInteger, OverlayBasicClusterStyleDemoMode) {
    OverlayBasicClusterStyleDemoModeDefault = 0,
    OverlayBasicClusterStyleDemoModeSimple,
    OverlayBasicClusterStyleDemoModeIconSteps,
};

typedef NS_ENUM(NSInteger, OverlayBasicClusterVisualRadiusMode) {
    OverlayBasicClusterVisualRadiusModeFixed = 0,
    OverlayBasicClusterVisualRadiusModeAdaptive,
};

typedef NS_ENUM(NSInteger, OverlayBasicClusterLeafIconMode) {
    OverlayBasicClusterLeafIconModeByFeature = 0,
    OverlayBasicClusterLeafIconModeFixed,
};

typedef NS_ENUM(NSInteger, OverlayBasicClusterLeafTextMode) {
    OverlayBasicClusterLeafTextModeByFeature = 0,
    OverlayBasicClusterLeafTextModeFixed,
};

typedef NS_ENUM(NSInteger, OverlayBasicClusterCustomIconMode) {
    OverlayBasicClusterCustomIconModeUnified = 0,
    OverlayBasicClusterCustomIconModeStepped,
};

typedef struct {
    CLLocationDegrees longitude;
    CLLocationDegrees latitude;
    NSInteger pointCount;
} OverlayBasicClusterAnchor;

static NSString *OverlayBasicClusterExampleNormalizeHexString(NSString *hexString, NSString *fallback) {
    NSString *candidate = [[hexString ?: @"" stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] uppercaseString];
    if (![candidate hasPrefix:@"#"]) {
        candidate = [@"#" stringByAppendingString:candidate];
    }
    if (candidate.length == 4 || candidate.length == 7 || candidate.length == 9) {
        unsigned int ignored = 0;
        NSString *scanString = [candidate substringFromIndex:1];
        if ([[NSScanner scannerWithString:scanString] scanHexInt:&ignored]) {
            return candidate;
        }
    }
    return fallback;
}

@interface OverlayBasicClusterExampleFormState : NSObject <NSCopying>
@property (nonatomic) BOOL mapStyleDark;
@property (nonatomic) NSInteger clusterRadius;
@property (nonatomic) double maximumClusterZoomLevel;
@property (nonatomic) NSInteger minimumClusterPointCount;
@property (nonatomic) BOOL clusteringEnabled;
@property (nonatomic) BOOL countAbbreviationEnabled;
@property (nonatomic) BOOL visible;
@property (nonatomic) NSInteger clickBehaviorIndex;
@property (nonatomic) OverlayBasicClusterStyleDemoMode styleDemoMode;
@property (nonatomic) BOOL clusterCustomIconEnabled;
@property (nonatomic) OverlayBasicClusterCustomIconMode clusterCustomIconMode;
@property (nonatomic, copy) NSString *clusterFillColorHex;
@property (nonatomic) NSInteger clusterFillColorIndex;
@property (nonatomic) double clusterIconOpacity;
@property (nonatomic, copy) NSString *clusterStrokeColorHex;
@property (nonatomic) NSInteger clusterStrokeColorIndex;
@property (nonatomic) double clusterStrokeWidth;
@property (nonatomic) OverlayBasicClusterVisualRadiusMode clusterVisualRadiusMode;
@property (nonatomic) double clusterVisualRadius;
@property (nonatomic) double clusterMinimumVisualRadius;
@property (nonatomic) double clusterMaximumVisualRadius;
@property (nonatomic) NSInteger clusterRadiusMaximumReference;
@property (nonatomic) double clusterTextFontSize;
@property (nonatomic, copy) NSString *clusterTextColorHex;
@property (nonatomic) NSInteger clusterTextColorIndex;
@property (nonatomic) double minimumClusterZoomLevel;
@property (nonatomic) double maximumVisibleClusterZoomLevel;
@property (nonatomic) OverlayBasicClusterLeafIconMode leafIconMode;
@property (nonatomic) double leafIconSize;
@property (nonatomic) double leafIconRotation;
@property (nonatomic) double leafIconOpacity;
@property (nonatomic) BOOL leafShowText;
@property (nonatomic) OverlayBasicClusterLeafTextMode leafTextMode;
@property (nonatomic, copy) NSString *leafFixedText;
@property (nonatomic) double leafTextSize;
@property (nonatomic) double minimumPointZoomLevel;
@property (nonatomic) double maximumPointZoomLevel;
@end

@implementation OverlayBasicClusterExampleFormState

- (id)copyWithZone:(NSZone *)zone {
    OverlayBasicClusterExampleFormState *state = [[[self class] allocWithZone:zone] init];
    state.mapStyleDark = self.mapStyleDark;
    state.clusterRadius = self.clusterRadius;
    state.maximumClusterZoomLevel = self.maximumClusterZoomLevel;
    state.minimumClusterPointCount = self.minimumClusterPointCount;
    state.clusteringEnabled = self.clusteringEnabled;
    state.countAbbreviationEnabled = self.countAbbreviationEnabled;
    state.visible = self.visible;
    state.clickBehaviorIndex = self.clickBehaviorIndex;
    state.styleDemoMode = self.styleDemoMode;
    state.clusterCustomIconEnabled = self.clusterCustomIconEnabled;
    state.clusterCustomIconMode = self.clusterCustomIconMode;
    state.clusterFillColorHex = self.clusterFillColorHex;
    state.clusterFillColorIndex = self.clusterFillColorIndex;
    state.clusterIconOpacity = self.clusterIconOpacity;
    state.clusterStrokeColorHex = self.clusterStrokeColorHex;
    state.clusterStrokeColorIndex = self.clusterStrokeColorIndex;
    state.clusterStrokeWidth = self.clusterStrokeWidth;
    state.clusterVisualRadiusMode = self.clusterVisualRadiusMode;
    state.clusterVisualRadius = self.clusterVisualRadius;
    state.clusterMinimumVisualRadius = self.clusterMinimumVisualRadius;
    state.clusterMaximumVisualRadius = self.clusterMaximumVisualRadius;
    state.clusterRadiusMaximumReference = self.clusterRadiusMaximumReference;
    state.clusterTextFontSize = self.clusterTextFontSize;
    state.clusterTextColorHex = self.clusterTextColorHex;
    state.clusterTextColorIndex = self.clusterTextColorIndex;
    state.minimumClusterZoomLevel = self.minimumClusterZoomLevel;
    state.maximumVisibleClusterZoomLevel = self.maximumVisibleClusterZoomLevel;
    state.leafIconMode = self.leafIconMode;
    state.leafIconSize = self.leafIconSize;
    state.leafIconRotation = self.leafIconRotation;
    state.leafIconOpacity = self.leafIconOpacity;
    state.leafShowText = self.leafShowText;
    state.leafTextMode = self.leafTextMode;
    state.leafFixedText = self.leafFixedText;
    state.leafTextSize = self.leafTextSize;
    state.minimumPointZoomLevel = self.minimumPointZoomLevel;
    state.maximumPointZoomLevel = self.maximumPointZoomLevel;
    return state;
}

@end

@interface OverlayBasicClusterExampleViewController () <MTCMapViewDelegate>
@property (nonatomic, strong) MTCMapView *mapView;
@property (nonatomic, strong) MTCExampleMapTestSupport *mapTestSupport;
@property (nonatomic, strong, nullable) MTCCluster *cluster;
@property (nonatomic, weak, nullable) MTCCluster *observedLifecycleCluster;
@property (nonatomic, weak, nullable) ExampleSettingsSheetView *settingsSheet;
@property (nonatomic, weak, nullable) ExampleSettingsItem *mapStyleItem;
@property (nonatomic, strong) OverlayBasicClusterExampleFormState *formState;
@property (nonatomic, strong) OverlayBasicClusterExampleFormState *editingState;
@property (nonatomic, weak, nullable) MTCCluster *editingCluster;
@property (nonatomic, copy, nullable) NSArray<MTCClusterPoint *> *pendingStyleSwitchPoints;
@property (nonatomic, copy, nullable) MTCMapCamera *pendingStyleSwitchCamera;
@property (nonatomic) MTCClusterLifecycleState lastLifecycleToastState;
@end

@implementation OverlayBasicClusterExampleViewController

- (void)dealloc {
    [self stopObservingClusterLifecycle];
    _mapView.delegate = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = UIColor.whiteColor;
    self.view.accessibilityIdentifier = MTCExampleTestAccessibilityPointClusterScreen;
    self.formState = [self defaultFormState];

    [self configureNavigationItems:NO];
    [self configureMapView];
    [self replaceClusterWithState:self.formState
                            points:[self defaultPointsForState:self.formState]
                          recenter:NO];
    [self.mapView setCenterCoordinate:[self centerCoordinate]
                             zoomLevel:OverlayBasicClusterExampleDefaultZoomLevel];
    [self applyLocalizedTexts];
}

#pragma mark - Setup

- (void)configureMapView {
    self.mapView = [[MTCMapView alloc] initWithFrame:self.view.bounds];
    self.mapView.delegate = self;
    self.mapView.uiSettings.zoomLevelVisible = YES;
    self.mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.mapView];

    self.mapTestSupport = [[MTCExampleMapTestSupport alloc] init];
    self.mapTestSupport.overlayCountValueKey = MTCExampleTestAccessibilityClusterCountValueKey;
    self.mapTestSupport.overlayPresenceIdentifier = MTCExampleTestAccessibilityClusterHasCluster;
    [self.mapTestSupport installOnHostView:self.view];
}

- (void)mapViewDidFinishLoadingMap:(MTCMapView *)mapView {
    (void)mapView;
    [self.mapTestSupport markMapRenderedReady];
    [self.mapTestSupport pauseMapRenderingIfUITesting:self.mapView];
}

#pragma mark - Settings

- (void)showSettingsSheet {
    self.editingCluster = self.cluster;
    self.editingState = self.cluster ? [self stateFromCluster:self.cluster] : [self defaultFormState];

    __weak typeof(self) weakSelf = self;
    __block ExampleSettingsSheetView *sheet = nil;

    NSArray<ExampleSettingsSection *> *sections =
        [self sectionsForState:self.editingState
                          sheet:^ExampleSettingsSheetView *{
        return sheet;
    } defaultDataAction:^{
        NSArray<MTCClusterPoint *> *points = [weakSelf defaultPointsForState:weakSelf.editingState];
        [weakSelf replaceClusterWithState:weakSelf.editingState points:points recenter:YES];
        [sheet dismissAnimated:YES];
    } externalDataAction:^{
        [weakSelf useExternalDataForState:weakSelf.editingState];
        [sheet dismissAnimated:YES];
    } clearAction:^{
        [weakSelf clearAllClusters];
        [sheet dismissAnimated:YES];
    }];

    sheet = [[ExampleSettingsSheetView alloc] initWithTitle:[self localizedStringForKey:@"common_settings_sheet_title"]
                                                   sections:sections];
    self.settingsSheet = sheet;
    [sheet showInView:self.view animated:YES];
}

- (NSArray<ExampleSettingsSection *> *)sectionsForState:(OverlayBasicClusterExampleFormState *)state
                                                  sheet:(ExampleSettingsSheetView *(^)(void))sheetGetter
                                      defaultDataAction:(dispatch_block_t)defaultDataAction
                                     externalDataAction:(dispatch_block_t)externalDataAction
                                           clearAction:(dispatch_block_t)clearAction {
    __weak typeof(self) weakSelf = self;
    __weak OverlayBasicClusterExampleFormState *weakState = state;
    void (^syncState)(void) = ^{
        [weakSelf syncEditingClusterForState:weakState];
    };
    void (^reloadSheet)(void) = ^{
        [sheetGetter() reloadData];
    };
    void (^markSimpleStyle)(void) = ^{
        weakState.styleDemoMode = weakState.clusterCustomIconEnabled ? OverlayBasicClusterStyleDemoModeIconSteps : OverlayBasicClusterStyleDemoModeSimple;
    };

    ExampleSettingsItem *mapStyleItem =
        [[ExampleSettingsItem boolItemWithTitle:[self mapStyleTitleForState:state]
                                         getter:^BOOL {
        return weakState.mapStyleDark;
    } setter:^(BOOL value) {
        weakState.mapStyleDark = value;
        [weakSelf switchMapStyleDark:value preservingState:weakState];
    }] enabledWhen:^BOOL {
        return YES;
    }];
    self.mapStyleItem = mapStyleItem;

    ExampleSettingsItem *clusterCustomIconItem = [ExampleSettingsItem boolItemWithTitle:[self localizedStringForKey:@"point_cluster_input_cluster_custom_icon_label"]
                                                                                 getter:^BOOL {
        return weakState.clusterCustomIconEnabled;
    } setter:^(BOOL value) {
        weakState.clusterCustomIconEnabled = value;
        weakState.styleDemoMode = value ? OverlayBasicClusterStyleDemoModeIconSteps : OverlayBasicClusterStyleDemoModeSimple;
        weakState.clusterTextColorHex = value ? @"#000000" : @"#FFFFFF";
        weakState.clusterTextColorIndex = [weakSelf indexForColorHex:weakState.clusterTextColorHex fallbackIndex:1];
        reloadSheet();
        syncState();
    }];

    ExampleSettingsItem *clusterIconStepsItem =
        [ExampleSettingsItem boolItemWithTitle:[self localizedStringForKey:@"point_cluster_input_cluster_icon_steps_label"]
                                        getter:^BOOL {
        return weakState.clusterCustomIconMode == OverlayBasicClusterCustomIconModeStepped;
    } setter:^(BOOL value) {
        weakState.clusterCustomIconMode = value ? OverlayBasicClusterCustomIconModeStepped : OverlayBasicClusterCustomIconModeUnified;
        markSimpleStyle();
        syncState();
    }];

    ExampleSettingsItem *clusterFillColorItem =
        [[[ExampleSettingsItem colorInputItemWithTitle:[self localizedStringForKey:@"point_cluster_input_cluster_fill_color_label"]
                                           placeholder:@"#2F80ED"
                                               options:[self colorOptionTitles]
                                        optionHexValues:[self colorOptionHexValues]
                                             popupSize:CGSizeMake(260.0, 300.0)
                                                getter:^NSString *{
        return weakState.clusterFillColorHex;
    } setter:^(NSString *value) {
        weakState.clusterFillColorHex = OverlayBasicClusterExampleNormalizeHexString(value, @"#2F80ED");
        weakState.clusterFillColorIndex = [weakSelf indexForColorHex:weakState.clusterFillColorHex fallbackIndex:0];
        markSimpleStyle();
        syncState();
    } optionGetter:^NSInteger {
        return weakState.clusterFillColorIndex;
    } optionSetter:^(NSInteger index) {
        NSString *hexValue = [weakSelf colorOptionHexValueAtIndex:index fallback:@"#2F80ED"];
        weakState.clusterFillColorHex = hexValue;
        weakState.clusterFillColorIndex = index;
        markSimpleStyle();
        syncState();
    }] visibleWhen:^BOOL {
        return !weakState.clusterCustomIconEnabled;
    }] enabledWhen:^BOOL {
        return weakSelf.editingCluster != nil;
    }];

    ExampleSettingsItem *clusterIconOpacityItem =
        [[[ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"point_cluster_input_cluster_icon_opacity_label"]
                                           minimum:0.0
                                           maximum:1.0
                                              step:0.05
                                            getter:^double {
        return weakState.clusterIconOpacity;
    } setter:^(double value) {
        weakState.clusterIconOpacity = value;
        markSimpleStyle();
        syncState();
    } formatter:^NSString *(double value) {
        return [NSString stringWithFormat:@"%.2f", value];
    }] visibleWhen:^BOOL {
        return !weakState.clusterCustomIconEnabled;
    }] enabledWhen:^BOOL {
        return weakSelf.editingCluster != nil;
    }];

    ExampleSettingsItem *clusterStrokeColorItem =
        [[[ExampleSettingsItem colorInputItemWithTitle:[self localizedStringForKey:@"point_cluster_input_cluster_stroke_color_label"]
                                           placeholder:@"#FFFFFF"
                                               options:[self colorOptionTitles]
                                        optionHexValues:[self colorOptionHexValues]
                                             popupSize:CGSizeMake(260.0, 300.0)
                                                getter:^NSString *{
        return weakState.clusterStrokeColorHex;
    } setter:^(NSString *value) {
        weakState.clusterStrokeColorHex = OverlayBasicClusterExampleNormalizeHexString(value, @"#FFFFFF");
        weakState.clusterStrokeColorIndex = [weakSelf indexForColorHex:weakState.clusterStrokeColorHex fallbackIndex:1];
        markSimpleStyle();
        syncState();
    } optionGetter:^NSInteger {
        return weakState.clusterStrokeColorIndex;
    } optionSetter:^(NSInteger index) {
        NSString *hexValue = [weakSelf colorOptionHexValueAtIndex:index fallback:@"#FFFFFF"];
        weakState.clusterStrokeColorHex = hexValue;
        weakState.clusterStrokeColorIndex = index;
        markSimpleStyle();
        syncState();
    }] visibleWhen:^BOOL {
        return !weakState.clusterCustomIconEnabled;
    }] enabledWhen:^BOOL {
        return weakSelf.editingCluster != nil;
    }];

    ExampleSettingsItem *clusterStrokeWidthItem =
        [[[ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"point_cluster_input_cluster_stroke_width_label"]
                                           minimum:0.0
                                           maximum:8.0
                                              step:0.1
                                            getter:^double {
        return weakState.clusterStrokeWidth;
    } setter:^(double value) {
        weakState.clusterStrokeWidth = value;
        markSimpleStyle();
        syncState();
    } formatter:^NSString *(double value) {
        return [NSString stringWithFormat:@"%.1f", value];
    }] visibleWhen:^BOOL {
        return !weakState.clusterCustomIconEnabled;
    }] enabledWhen:^BOOL {
        return weakSelf.editingCluster != nil;
    }];

    ExampleSettingsItem *adaptiveRadiusItem =
        [[ExampleSettingsItem boolItemWithTitle:[self localizedStringForKey:@"point_cluster_input_cluster_adaptive_radius_label"]
                                         getter:^BOOL {
        return weakState.clusterVisualRadiusMode == OverlayBasicClusterVisualRadiusModeAdaptive;
    } setter:^(BOOL value) {
        weakState.clusterVisualRadiusMode = value ? OverlayBasicClusterVisualRadiusModeAdaptive : OverlayBasicClusterVisualRadiusModeFixed;
        markSimpleStyle();
        reloadSheet();
        syncState();
    }] enabledWhen:^BOOL {
        return weakSelf.editingCluster != nil;
    }];

    ExampleSettingsItem *fixedRadiusHintItem =
        [[ExampleSettingsItem infoItemWithText:[self localizedStringForKey:@"point_cluster_fixed_radius_hint"]] visibleWhen:^BOOL {
        return weakState.clusterVisualRadiusMode == OverlayBasicClusterVisualRadiusModeFixed;
    }];

    ExampleSettingsItem *adaptiveRadiusHintItem =
        [[ExampleSettingsItem infoItemWithText:[self localizedStringForKey:@"point_cluster_adaptive_radius_hint"]] visibleWhen:^BOOL {
        return weakState.clusterVisualRadiusMode == OverlayBasicClusterVisualRadiusModeAdaptive;
    }];

    ExampleSettingsItem *clusterVisualRadiusItem =
        [[[ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"point_cluster_input_cluster_visual_radius_label"]
                                           minimum:8.0
                                           maximum:48.0
                                              step:0.5
                                            getter:^double {
        return weakState.clusterVisualRadius;
    } setter:^(double value) {
        weakState.clusterVisualRadius = value;
        markSimpleStyle();
        syncState();
    } formatter:^NSString *(double value) {
        return [NSString stringWithFormat:@"%.1f", value];
    }] visibleWhen:^BOOL {
        return weakState.clusterVisualRadiusMode == OverlayBasicClusterVisualRadiusModeFixed;
    }] enabledWhen:^BOOL {
        return weakSelf.editingCluster != nil;
    }];

    ExampleSettingsItem *clusterMinRadiusItem =
        [[[ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"point_cluster_input_cluster_min_radius_label"]
                                           minimum:8.0
                                           maximum:48.0
                                              step:0.5
                                            getter:^double {
        return weakState.clusterMinimumVisualRadius;
    } setter:^(double value) {
        weakState.clusterMinimumVisualRadius = value;
        if (weakState.clusterMaximumVisualRadius < value) {
            weakState.clusterMaximumVisualRadius = value;
        }
        markSimpleStyle();
        syncState();
    } formatter:^NSString *(double value) {
        return [NSString stringWithFormat:@"%.1f", value];
    }] visibleWhen:^BOOL {
        return weakState.clusterVisualRadiusMode == OverlayBasicClusterVisualRadiusModeAdaptive;
    }] enabledWhen:^BOOL {
        return weakSelf.editingCluster != nil;
    }];

    ExampleSettingsItem *clusterMaxRadiusItem =
        [[[ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"point_cluster_input_cluster_max_radius_label"]
                                           minimum:8.0
                                           maximum:48.0
                                              step:0.5
                                            getter:^double {
        return weakState.clusterMaximumVisualRadius;
    } setter:^(double value) {
        weakState.clusterMaximumVisualRadius = value;
        if (weakState.clusterMinimumVisualRadius > value) {
            weakState.clusterMinimumVisualRadius = value;
        }
        markSimpleStyle();
        syncState();
    } formatter:^NSString *(double value) {
        return [NSString stringWithFormat:@"%.1f", value];
    }] visibleWhen:^BOOL {
        return weakState.clusterVisualRadiusMode == OverlayBasicClusterVisualRadiusModeAdaptive;
    }] enabledWhen:^BOOL {
        return weakSelf.editingCluster != nil;
    }];

    ExampleSettingsItem *clusterMaxReferenceItem =
        [[[ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"point_cluster_input_cluster_max_reference_label"]
                                           minimum:10.0
                                           maximum:5000.0
                                              step:10.0
                                            getter:^double {
        return weakState.clusterRadiusMaximumReference;
    } setter:^(double value) {
        weakState.clusterRadiusMaximumReference = MAX(weakState.minimumClusterPointCount + 1, (NSInteger)llround(value));
        markSimpleStyle();
        syncState();
    } formatter:^NSString *(double value) {
        return [NSString stringWithFormat:@"%.0f", value];
    }] visibleWhen:^BOOL {
        return weakState.clusterVisualRadiusMode == OverlayBasicClusterVisualRadiusModeAdaptive;
    }] enabledWhen:^BOOL {
        return weakSelf.editingCluster != nil;
    }];

    ExampleSettingsItem *clusterTextColorItem =
        [[ExampleSettingsItem colorInputItemWithTitle:[self localizedStringForKey:@"point_cluster_input_cluster_text_color_label"]
                                          placeholder:@"#FFFFFF"
                                              options:[self colorOptionTitles]
                                       optionHexValues:[self colorOptionHexValues]
                                            popupSize:CGSizeMake(260.0, 300.0)
                                               getter:^NSString *{
        return weakState.clusterTextColorHex;
    } setter:^(NSString *value) {
        weakState.clusterTextColorHex = OverlayBasicClusterExampleNormalizeHexString(value, @"#FFFFFF");
        weakState.clusterTextColorIndex = [weakSelf indexForColorHex:weakState.clusterTextColorHex fallbackIndex:1];
        markSimpleStyle();
        syncState();
    } optionGetter:^NSInteger {
        return weakState.clusterTextColorIndex;
    } optionSetter:^(NSInteger index) {
        NSString *hexValue = [weakSelf colorOptionHexValueAtIndex:index fallback:@"#FFFFFF"];
        weakState.clusterTextColorHex = hexValue;
        weakState.clusterTextColorIndex = index;
        markSimpleStyle();
        syncState();
    }] enabledWhen:^BOOL {
        return weakSelf.editingCluster != nil;
    }];

    ExampleSettingsItem *leafFixedTextItem =
        [[[ExampleSettingsItem textItemWithTitle:[self localizedStringForKey:@"point_cluster_input_leaf_fixed_text_label"]
                                     placeholder:[self localizedStringForKey:@"point_cluster_input_leaf_fixed_text_label"]
                                    keyboardType:UIKeyboardTypeDefault
                                          getter:^NSString *{
        return weakState.leafFixedText ?: @"";
    } setter:^(NSString *value) {
        weakState.leafFixedText = value ?: @"";
        syncState();
    }] visibleWhen:^BOOL {
        return weakState.leafShowText && weakState.leafTextMode == OverlayBasicClusterLeafTextModeFixed;
    }] enabledWhen:^BOOL {
        return weakSelf.editingCluster != nil;
    }];

    return @[
        [ExampleSettingsSection sectionWithTitle:@"" items:@[
            mapStyleItem,
            [[ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"point_cluster_input_radius_label"]
                                              minimum:0.0
                                              maximum:512.0
                                                 step:1.0
                                               getter:^double {
                return weakState.clusterRadius;
            } setter:^(double value) {
                weakState.clusterRadius = (NSInteger)llround(value);
                syncState();
            } formatter:^NSString *(double value) {
                return [NSString stringWithFormat:@"%.0f", value];
            }] withAccessibilityIdentifier:MTCExampleTestAccessibilityPointClusterSliderRadius],
            [[ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"point_cluster_input_max_zoom_label"]
                                              minimum:0.0
                                              maximum:22.0
                                                 step:0.5
                                               getter:^double {
                return weakState.maximumClusterZoomLevel;
            } setter:^(double value) {
                weakState.maximumClusterZoomLevel = value;
                syncState();
            } formatter:^NSString *(double value) {
                return [NSString stringWithFormat:@"%.1f", value];
            }] withAccessibilityIdentifier:MTCExampleTestAccessibilityPointClusterSliderMaxZoom],
            [[ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"point_cluster_input_min_points_label"]
                                              minimum:2.0
                                              maximum:50.0
                                                 step:1.0
                                               getter:^double {
                return weakState.minimumClusterPointCount;
            } setter:^(double value) {
                weakState.minimumClusterPointCount = (NSInteger)llround(value);
                if (weakState.clusterRadiusMaximumReference <= weakState.minimumClusterPointCount) {
                    weakState.clusterRadiusMaximumReference = weakState.minimumClusterPointCount + 1;
                }
                syncState();
            } formatter:^NSString *(double value) {
                return [NSString stringWithFormat:@"%.0f", value];
            }] withAccessibilityIdentifier:MTCExampleTestAccessibilityPointClusterSliderMinPoints],
            [[ExampleSettingsItem boolItemWithTitle:[self localizedStringForKey:@"point_cluster_input_enable_label"]
                                             getter:^BOOL {
                return weakState.clusteringEnabled;
            } setter:^(BOOL value) {
                weakState.clusteringEnabled = value;
                syncState();
            }] withAccessibilityIdentifier:MTCExampleTestAccessibilityPointClusterSwitchEnable],
            [[ExampleSettingsItem boolItemWithTitle:[self localizedStringForKey:@"point_cluster_input_count_abbreviate_label"]
                                             getter:^BOOL {
                return weakState.countAbbreviationEnabled;
            } setter:^(BOOL value) {
                weakState.countAbbreviationEnabled = value;
                syncState();
            }] withAccessibilityIdentifier:MTCExampleTestAccessibilityPointClusterSwitchAbbreviate],
            [[ExampleSettingsItem boolItemWithTitle:[self localizedStringForKey:@"point_cluster_input_visible_label"]
                                             getter:^BOOL {
                return weakState.visible;
            } setter:^(BOOL value) {
                weakState.visible = value;
                syncState();
            }] withAccessibilityIdentifier:MTCExampleTestAccessibilityPointClusterSwitchVisible],
            [ExampleSettingsItem listItemWithTitle:[self localizedStringForKey:@"point_cluster_input_click_behavior_label"]
                                           options:[self clickBehaviorTitles]
                                         popupSize:CGSizeMake(280.0, 180.0)
                                            getter:^NSInteger {
                return weakState.clickBehaviorIndex;
            } setter:^(NSInteger index) {
                weakState.clickBehaviorIndex = index;
                syncState();
            }],
        ]],
        [ExampleSettingsSection collapsibleSectionWithTitle:[self localizedStringForKey:@"point_cluster_cluster_style_section"]
                                         initiallyCollapsed:YES
                                                      items:@[
            clusterIconStepsItem,
            adaptiveRadiusItem,
            fixedRadiusHintItem,
            adaptiveRadiusHintItem,
            clusterVisualRadiusItem,
            clusterMinRadiusItem,
            clusterMaxRadiusItem,
            clusterMaxReferenceItem,
            clusterCustomIconItem,
            clusterFillColorItem,
            clusterIconOpacityItem,
            clusterStrokeColorItem,
            clusterStrokeWidthItem,
            [ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"point_cluster_input_cluster_text_size_label"]
                                             minimum:8.0
                                             maximum:32.0
                                                step:0.5
                                              getter:^double {
                return weakState.clusterTextFontSize;
            } setter:^(double value) {
                weakState.clusterTextFontSize = value;
                markSimpleStyle();
                syncState();
            } formatter:^NSString *(double value) {
                return [NSString stringWithFormat:@"%.1f", value];
            }],
            clusterTextColorItem,
            [ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"point_cluster_input_cluster_layer_min_zoom_label"]
                                             minimum:0.0
                                             maximum:22.0
                                                step:0.5
                                              getter:^double {
                return weakState.minimumClusterZoomLevel;
            } setter:^(double value) {
                weakState.minimumClusterZoomLevel = value;
                syncState();
            } formatter:^NSString *(double value) {
                return [NSString stringWithFormat:@"%.1f", value];
            }],
            [ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"point_cluster_input_cluster_layer_max_zoom_label"]
                                             minimum:0.0
                                             maximum:22.0
                                                step:0.5
                                              getter:^double {
                return weakState.maximumVisibleClusterZoomLevel;
            } setter:^(double value) {
                weakState.maximumVisibleClusterZoomLevel = value;
                syncState();
            } formatter:^NSString *(double value) {
                return [NSString stringWithFormat:@"%.1f", value];
            }],
        ]],
        [ExampleSettingsSection collapsibleSectionWithTitle:[self localizedStringForKey:@"point_cluster_leaf_style_section"]
                                         initiallyCollapsed:YES
                                                      items:@[
            [[ExampleSettingsItem boolItemWithTitle:[self localizedStringForKey:@"point_cluster_input_leaf_icon_mode_label"]
                                             getter:^BOOL {
                return weakState.leafIconMode == OverlayBasicClusterLeafIconModeFixed;
            } setter:^(BOOL value) {
                weakState.leafIconMode = value ? OverlayBasicClusterLeafIconModeFixed : OverlayBasicClusterLeafIconModeByFeature;
                syncState();
            }] enabledWhen:^BOOL {
                return weakSelf.editingCluster != nil;
            }],
            [[ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"point_cluster_input_leaf_icon_size_label"]
                                              minimum:0.1
                                              maximum:4.0
                                                 step:0.1
                                               getter:^double {
                return weakState.leafIconSize;
            } setter:^(double value) {
                weakState.leafIconSize = value;
                syncState();
            } formatter:^NSString *(double value) {
                return [NSString stringWithFormat:@"%.1f", value];
            }] enabledWhen:^BOOL {
                return weakSelf.editingCluster != nil;
            }],
            [[ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"point_cluster_input_leaf_icon_rotation_label"]
                                              minimum:0.0
                                              maximum:360.0
                                                 step:1.0
                                               getter:^double {
                return weakState.leafIconRotation;
            } setter:^(double value) {
                weakState.leafIconRotation = value;
                syncState();
            } formatter:^NSString *(double value) {
                return [NSString stringWithFormat:@"%.0f", value];
            }] enabledWhen:^BOOL {
                return weakSelf.editingCluster != nil;
            }],
            [[ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"point_cluster_input_leaf_icon_opacity_label"]
                                              minimum:0.0
                                              maximum:1.0
                                                 step:0.05
                                               getter:^double {
                return weakState.leafIconOpacity;
            } setter:^(double value) {
                weakState.leafIconOpacity = value;
                syncState();
            } formatter:^NSString *(double value) {
                return [NSString stringWithFormat:@"%.2f", value];
            }] enabledWhen:^BOOL {
                return weakSelf.editingCluster != nil;
            }],
            [[ExampleSettingsItem boolItemWithTitle:[self localizedStringForKey:@"point_cluster_input_leaf_show_text_label"]
                                             getter:^BOOL {
                return weakState.leafShowText;
            } setter:^(BOOL value) {
                weakState.leafShowText = value;
                reloadSheet();
                syncState();
            }] enabledWhen:^BOOL {
                return weakSelf.editingCluster != nil;
            }],
            [[[ExampleSettingsItem boolItemWithTitle:[self localizedStringForKey:@"point_cluster_input_leaf_text_mode_label"]
                                              getter:^BOOL {
                return weakState.leafTextMode == OverlayBasicClusterLeafTextModeFixed;
            } setter:^(BOOL value) {
                weakState.leafTextMode = value ? OverlayBasicClusterLeafTextModeFixed : OverlayBasicClusterLeafTextModeByFeature;
                reloadSheet();
                syncState();
            }] visibleWhen:^BOOL {
                return weakState.leafShowText;
            }] enabledWhen:^BOOL {
                return weakSelf.editingCluster != nil;
            }],
            leafFixedTextItem,
            [[[ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"point_cluster_input_leaf_text_size_label"]
                                               minimum:8.0
                                               maximum:32.0
                                                  step:0.5
                                                getter:^double {
                return weakState.leafTextSize;
            } setter:^(double value) {
                weakState.leafTextSize = value;
                syncState();
            } formatter:^NSString *(double value) {
                return [NSString stringWithFormat:@"%.1f", value];
            }] visibleWhen:^BOOL {
                return weakState.leafShowText;
            }] enabledWhen:^BOOL {
                return weakSelf.editingCluster != nil;
            }],
            [[ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"point_cluster_input_point_min_zoom_label"]
                                              minimum:0.0
                                              maximum:22.0
                                                 step:0.5
                                               getter:^double {
                return weakState.minimumPointZoomLevel;
            } setter:^(double value) {
                weakState.minimumPointZoomLevel = value;
                syncState();
            } formatter:^NSString *(double value) {
                return [NSString stringWithFormat:@"%.1f", value];
            }] enabledWhen:^BOOL {
                return weakSelf.editingCluster != nil;
            }],
            [[ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"point_cluster_input_point_max_zoom_label"]
                                              minimum:0.0
                                              maximum:22.0
                                                 step:0.5
                                               getter:^double {
                return weakState.maximumPointZoomLevel;
            } setter:^(double value) {
                weakState.maximumPointZoomLevel = value;
                syncState();
            } formatter:^NSString *(double value) {
                return [NSString stringWithFormat:@"%.1f", value];
            }] enabledWhen:^BOOL {
                return weakSelf.editingCluster != nil;
            }],
        ]],
        [ExampleSettingsSection sectionWithTitle:@"" items:@[
            [[ExampleSettingsItem actionItemWithTitle:[self localizedStringForKey:@"point_cluster_draw_button"] handler:defaultDataAction] withAccessibilityIdentifier:MTCExampleTestAccessibilityPointClusterDrawButton],
            [ExampleSettingsItem actionItemWithTitle:[self localizedStringForKey:@"point_cluster_load_external_button"] handler:externalDataAction],
            [[ExampleSettingsItem actionItemWithTitle:[self localizedStringForKey:@"point_cluster_remove_button"] handler:clearAction] withAccessibilityIdentifier:MTCExampleTestAccessibilityPointClusterRemoveButton],
        ]],
    ];
}

#pragma mark - Cluster

- (void)startObservingClusterLifecycle:(MTCCluster *)cluster {
    [self stopObservingClusterLifecycle];
    if (!cluster) {
        self.lastLifecycleToastState = MTCClusterLifecycleStateDetached;
        return;
    }
    self.observedLifecycleCluster = cluster;
    self.lastLifecycleToastState = cluster.lifecycleState;
    [cluster addObserver:self
              forKeyPath:@"lifecycleState"
                 options:NSKeyValueObservingOptionNew
                 context:OverlayBasicClusterLifecycleObservationContext];
}

- (void)stopObservingClusterLifecycle {
    MTCCluster *cluster = self.observedLifecycleCluster;
    if (!cluster) {
        return;
    }
    [cluster removeObserver:self forKeyPath:@"lifecycleState"];
    self.observedLifecycleCluster = nil;
}

- (void)replaceClusterWithState:(OverlayBasicClusterExampleFormState *)state
                         points:(NSArray<MTCClusterPoint *> *)points
                       recenter:(BOOL)recenter {
    if (!state) {
        return;
    }

    [self clearAllClusters];

    MTCCluster *cluster = [[MTCCluster alloc] initWithPoints:[self restyledPointsFromPoints:points state:state]];
    self.cluster = cluster;
    self.editingCluster = cluster;
    [self startObservingClusterLifecycle:cluster];
    [self applyState:state toCluster:cluster updatePoints:NO];
    [self.mapView addOverlay:cluster];
    [self.mapTestSupport syncOverlayCount:1];

    if (recenter) {
        [self.mapView setCenterCoordinate:[self centerCoordinate]
                                zoomLevel:OverlayBasicClusterExampleDefaultZoomLevel];
    }
}

- (void)syncEditingClusterForState:(OverlayBasicClusterExampleFormState *)state {
    if (!state || !self.editingCluster || self.editingCluster != self.cluster) {
        return;
    }

    [self applyState:state toCluster:self.editingCluster updatePoints:YES];
}

- (void)applyState:(OverlayBasicClusterExampleFormState *)state
         toCluster:(MTCCluster *)cluster
      updatePoints:(BOOL)updatePoints {
    if (!state || !cluster) {
        return;
    }

    if (updatePoints) {
        cluster.points = [self restyledPointsFromPoints:cluster.points state:state];
    }
    cluster.clusteringEnabled = state.clusteringEnabled;
    cluster.clusterRadius = (NSUInteger)MAX(0, MIN(512, state.clusterRadius));
    cluster.maximumClusterZoomLevel = MIN(22.0, MAX(0.0, state.maximumClusterZoomLevel));
    cluster.minimumClusterPointCount = (NSUInteger)MAX(2, state.minimumClusterPointCount);
    cluster.countAbbreviationEnabled = state.countAbbreviationEnabled;
    cluster.minimumClusterZoomLevel = MIN(22.0, MAX(0.0, state.minimumClusterZoomLevel));
    cluster.maximumVisibleClusterZoomLevel = MIN(22.0, MAX(0.0, state.maximumVisibleClusterZoomLevel));
    cluster.minimumPointZoomLevel = MIN(22.0, MAX(0.0, state.minimumPointZoomLevel));
    cluster.maximumPointZoomLevel = MIN(22.0, MAX(0.0, state.maximumPointZoomLevel));
    cluster.visible = state.visible;
    cluster.clickable = YES;
    cluster.clusterClickBehavior = [self clickBehaviorForIndex:state.clickBehaviorIndex];
    cluster.defaultPointStyle = [self pointStyleForState:state];

    NSError *styleError = nil;
    if (![self applyStyleModeForState:state toCluster:cluster error:&styleError]) {
        [MTCExampleToastView showMessage:styleError.localizedDescription ?: @"Invalid cluster style" inView:self.view];
    }
    self.formState = [state copy];
}

- (BOOL)applyStyleModeForState:(OverlayBasicClusterExampleFormState *)state
                     toCluster:(MTCCluster *)cluster
                         error:(NSError **)error {
    switch (state.styleDemoMode) {
        case OverlayBasicClusterStyleDemoModeSimple:
            cluster.iconRadius = [self iconRadiusForState:state];
            cluster.style = [self simpleClusterStyleForState:state color:[self simpleLowColorForState:state]];
            return [cluster setStyleRules:[self simpleStyleRulesForState:state] error:error];
        case OverlayBasicClusterStyleDemoModeIconSteps:
            cluster.iconRadius = [self iconRadiusForState:state];
            cluster.style = [self customClusterStyleWithColor:[self colorFromHexString:@"#2F80ED" fallbackHex:@"#2F80ED"]
                                                   identifier:@"example_cluster_custom_fallback"
                                                     iconScale:1.5
                                                        state:state];
            return [cluster setStyleRules:[self customIconStyleRulesForState:state] error:error];
        case OverlayBasicClusterStyleDemoModeDefault:
        default:
            cluster.style = [MTCClusterStyle defaultStyle];
            return [cluster setStyleRules:nil error:error];
    }
}

- (void)useExternalDataForState:(OverlayBasicClusterExampleFormState *)state {
    NSError *error = nil;
    NSArray<MTCClusterPoint *> *points = [self externalPointsForState:state error:&error];
    if (points.count == 0) {
        NSString *message = error.localizedDescription ?: [self localizedStringForKey:@"point_cluster_load_external_failed"];
        [MTCExampleToastView showMessage:message inView:self.view];
        return;
    }

    if (self.cluster) {
        self.cluster.points = [self restyledPointsFromPoints:points state:state];
        [self applyState:state toCluster:self.cluster updatePoints:NO];
    } else {
        [self replaceClusterWithState:state points:points recenter:YES];
    }
}

- (void)clearAllClusters {
    if (self.cluster) {
        [self.mapView removeOverlay:self.cluster];
    }
    [self stopObservingClusterLifecycle];
    self.cluster = nil;
    self.editingCluster = nil;
    [self.mapTestSupport syncOverlayCount:0];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context {
    if (context != OverlayBasicClusterLifecycleObservationContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }
    if (![keyPath isEqualToString:@"lifecycleState"] || object != self.observedLifecycleCluster) {
        return;
    }

    MTCCluster *cluster = (MTCCluster *)object;
    MTCClusterLifecycleState newState = [change[NSKeyValueChangeNewKey] integerValue];
    if (newState == self.lastLifecycleToastState) {
        return;
    }
    self.lastLifecycleToastState = newState;

    NSString *message = [NSString stringWithFormat:@"聚合状态：%@", [self lifecycleStateName:newState]];
    if (newState == MTCClusterLifecycleStateError && cluster.lifecycleError.localizedDescription.length > 0) {
        message = [message stringByAppendingFormat:@"\n%@", cluster.lifecycleError.localizedDescription];
    }
    [MTCExampleToastView showMessage:message inView:self.view];
}

- (NSArray<MTCClusterPoint *> *)defaultPointsForState:(OverlayBasicClusterExampleFormState *)state {
    NSMutableArray<MTCClusterPoint *> *points = [NSMutableArray arrayWithCapacity:80];
    OverlayBasicClusterAnchor anchors[] = {
        {103.8519, 1.2903, 48},
        {103.8318, 1.3048, 32},
    };
    for (NSUInteger anchorIndex = 0; anchorIndex < sizeof(anchors) / sizeof(OverlayBasicClusterAnchor); anchorIndex++) {
        OverlayBasicClusterAnchor anchor = anchors[anchorIndex];
        for (NSInteger pointIndex = 0; pointIndex < anchor.pointCount; pointIndex++) {
            double ring = 0.35 + (pointIndex % 6) * 0.14;
            double angle = pointIndex * 2.399 + anchorIndex * 0.72;
            CLLocationDegrees longitude = anchor.longitude + cos(angle) * 0.0135 * ring;
            CLLocationDegrees latitude = anchor.latitude + sin(angle) * 0.0102 * ring;
            NSString *identifier = [NSString stringWithFormat:@"demo-%lu-%ld", (unsigned long)anchorIndex + 1, (long)pointIndex + 1];
            MTCClusterPoint *point = [[MTCClusterPoint alloc] initWithCoordinate:CLLocationCoordinate2DMake(latitude, longitude)
                                                                      identifier:identifier];
            [points addObject:point];
        }
    }
    return [self restyledPointsFromPoints:points state:state];
}

- (NSArray<MTCClusterPoint *> *)externalPointsForState:(OverlayBasicClusterExampleFormState *)state error:(NSError **)error {
    NSURL *url = [NSBundle.mainBundle URLForResource:OverlayBasicClusterExampleExternalDataName withExtension:@"json"];
    if (!url) {
        if (error) {
            *error = [NSError errorWithDomain:@"OverlayBasicClusterExample"
                                         code:1
                                     userInfo:@{NSLocalizedDescriptionKey: [self localizedStringForKey:@"point_cluster_load_external_failed"]}];
        }
        return @[];
    }

    NSData *data = [NSData dataWithContentsOfURL:url options:0 error:error];
    if (!data) {
        return @[];
    }

    id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:error];
    if (![json isKindOfClass:NSDictionary.class]) {
        return @[];
    }

    NSArray *features = ((NSDictionary *)json)[@"features"];
    if (![features isKindOfClass:NSArray.class]) {
        return @[];
    }

    NSMutableArray<MTCClusterPoint *> *points = [NSMutableArray arrayWithCapacity:features.count];
    for (id feature in features) {
        if (![feature isKindOfClass:NSDictionary.class]) {
            continue;
        }
        NSDictionary *featureDictionary = (NSDictionary *)feature;
        NSDictionary *geometry = [featureDictionary[@"geometry"] isKindOfClass:NSDictionary.class] ? featureDictionary[@"geometry"] : nil;
        NSArray *coordinates = [geometry[@"coordinates"] isKindOfClass:NSArray.class] ? geometry[@"coordinates"] : nil;
        if (coordinates.count < 2) {
            continue;
        }
        NSNumber *longitude = [coordinates[0] isKindOfClass:NSNumber.class] ? coordinates[0] : nil;
        NSNumber *latitude = [coordinates[1] isKindOfClass:NSNumber.class] ? coordinates[1] : nil;
        if (!longitude || !latitude) {
            continue;
        }
        NSDictionary *properties = [featureDictionary[@"properties"] isKindOfClass:NSDictionary.class] ? featureDictionary[@"properties"] : nil;
        NSString *identifier = [properties[@"id"] isKindOfClass:NSString.class] ? properties[@"id"] : nil;
        if (identifier.length == 0) {
            identifier = [NSString stringWithFormat:@"external-%lu", (unsigned long)points.count + 1];
        }
        MTCClusterPoint *point = [[MTCClusterPoint alloc] initWithCoordinate:CLLocationCoordinate2DMake(latitude.doubleValue, longitude.doubleValue)
                                                                  identifier:identifier];
        [points addObject:point];
    }
    return [self restyledPointsFromPoints:points state:state];
}

- (NSArray<MTCClusterPoint *> *)restyledPointsFromPoints:(NSArray<MTCClusterPoint *> *)points
                                                   state:(OverlayBasicClusterExampleFormState *)state {
    if (points.count == 0) {
        return @[];
    }

    NSMutableArray<MTCClusterPoint *> *styledPoints = [NSMutableArray arrayWithCapacity:points.count];
    for (MTCClusterPoint *sourcePoint in points) {
        MTCClusterPoint *point = [[MTCClusterPoint alloc] initWithCoordinate:sourcePoint.coordinate
                                                                  identifier:sourcePoint.identifier];
        if (state.leafShowText && state.leafTextMode == OverlayBasicClusterLeafTextModeByFeature) {
            point.title = sourcePoint.identifier ?: sourcePoint.title;
        }
        [styledPoints addObject:point];
    }
    return [styledPoints copy];
}

- (MTCClusterPointStyle *)pointStyleForState:(OverlayBasicClusterExampleFormState *)state {
    MTCClusterPointStyle *style = [[MTCClusterPointStyle alloc] init];
    style.iconType = state.leafIconMode == OverlayBasicClusterLeafIconModeFixed ? MTCClusterPointIconTypeRedDot : MTCClusterPointIconTypeBlueDot;
    CGFloat pointSize = 22.0 * MAX(0.1, state.leafIconSize);
    style.size = CGSizeMake(pointSize, pointSize);
    style.rotation = state.leafIconRotation;
    style.opacity = MIN(1.0, MAX(0.0, state.leafIconOpacity));
    style.textFontSize = state.leafTextSize;
    style.textColor = UIColor.darkTextColor;
    style.textOffset = CGPointMake(0.0, 4.0);
    style.text = (state.leafShowText && state.leafTextMode == OverlayBasicClusterLeafTextModeFixed) ? state.leafFixedText : nil;
    return style;
}

#pragma mark - Styles

- (NSArray<MTCClusterStyleRule *> *)simpleStyleRulesForState:(OverlayBasicClusterExampleFormState *)state {
    UIColor *lowColor = [self simpleLowColorForState:state];
    UIColor *midColor = [self simpleMidColorForState:state];
    UIColor *highColor = [self simpleHighColorForState:state];
    return @[
        [[MTCClusterStyleRule alloc] initWithMinimumPointCount:2
                                            maximumPointCount:@30
                                                        style:[self simpleClusterStyleForState:state color:lowColor]],
        [[MTCClusterStyleRule alloc] initWithMinimumPointCount:31
                                            maximumPointCount:@99
                                                        style:[self simpleClusterStyleForState:state color:midColor]],
        [[MTCClusterStyleRule alloc] initWithMinimumPointCount:100
                                            maximumPointCount:nil
                                                        style:[self simpleClusterStyleForState:state color:highColor]],
    ];
}

- (NSArray<MTCClusterStyleRule *> *)customIconStyleRulesForState:(OverlayBasicClusterExampleFormState *)state {
    BOOL stepped = state.clusterCustomIconMode == OverlayBasicClusterCustomIconModeStepped;
    UIColor *smallColor = [self colorFromHexString:stepped ? @"#F2C94C" : @"#2F80ED" fallbackHex:@"#2F80ED"];
    UIColor *mediumColor = [self colorFromHexString:stepped ? @"#27AE60" : @"#2F80ED" fallbackHex:@"#2F80ED"];
    UIColor *largeColor = [self colorFromHexString:stepped ? @"#EB5757" : @"#2F80ED" fallbackHex:@"#2F80ED"];
    return @[
        [[MTCClusterStyleRule alloc] initWithMinimumPointCount:2
                                            maximumPointCount:@99
                                                        style:[self customClusterStyleWithColor:smallColor identifier:@"example_cluster_custom_low" iconScale:1.5 state:state]],
        [[MTCClusterStyleRule alloc] initWithMinimumPointCount:100
                                            maximumPointCount:@999
                                                        style:[self customClusterStyleWithColor:mediumColor identifier:@"example_cluster_custom_mid" iconScale:1.8 state:state]],
        [[MTCClusterStyleRule alloc] initWithMinimumPointCount:1000
                                            maximumPointCount:nil
                                                        style:[self customClusterStyleWithColor:largeColor identifier:@"example_cluster_custom_high" iconScale:2.1 state:state]],
    ];
}

- (MTCClusterStyle *)simpleClusterStyleForState:(OverlayBasicClusterExampleFormState *)state
                                          color:(UIColor *)color {
    MTCClusterBadgeStyle *style = [[MTCClusterBadgeStyle alloc] init];
    style.fillColor = color;
    style.opacity = state.clusterIconOpacity;
    style.strokeColor = [self colorFromHexString:state.clusterStrokeColorHex fallbackHex:@"#FFFFFF"];
    style.strokeWidth = state.clusterStrokeWidth;
    style.textColor = [self colorFromHexString:state.clusterTextColorHex fallbackHex:@"#FFFFFF"];
    style.textFontSize = state.clusterTextFontSize;
    return style;
}

- (MTCClusterStyle *)customClusterStyleWithColor:(UIColor *)color
                                      identifier:(NSString *)identifier
                                       iconScale:(CGFloat)iconScale
                                           state:(OverlayBasicClusterExampleFormState *)state {
    MTCClusterCustomIconStyle *style = [[MTCClusterCustomIconStyle alloc] init];
    style.image = [self customClusterIconImageWithColor:color];
    style.imageIdentifier = identifier;
    style.renderingMode = MTCClusterIconRenderingModeOriginal;
    style.scale = iconScale;
    style.textColor = [self colorFromHexString:state.clusterTextColorHex fallbackHex:@"#000000"];
    style.textFontSize = state.clusterTextFontSize;
    return style;
}

- (MTCClusterIconRadius *)iconRadiusForState:(OverlayBasicClusterExampleFormState *)state {
    if (state.clusterVisualRadiusMode == OverlayBasicClusterVisualRadiusModeFixed) {
        return [MTCClusterIconRadius fixedRadius:[self iconScaleForVisualRadius:state.clusterVisualRadius]];
    }
    return [MTCClusterIconRadius adaptiveWithMinimumRadius:[self iconScaleForVisualRadius:state.clusterMinimumVisualRadius]
                                             maximumRadius:[self iconScaleForVisualRadius:state.clusterMaximumVisualRadius]
                                          maximumReference:(NSUInteger)MAX(1, state.clusterRadiusMaximumReference)];
}

- (CGFloat)iconScaleForVisualRadius:(CGFloat)visualRadius {
    return MAX(0.1, visualRadius / OverlayBasicClusterExampleBaseVisualRadius);
}

- (UIColor *)simpleLowColorForState:(OverlayBasicClusterExampleFormState *)state {
    return [self colorFromHexString:state.clusterFillColorHex fallbackHex:@"#2F80ED"];
}

- (UIColor *)simpleMidColorForState:(OverlayBasicClusterExampleFormState *)state {
    if (state.clusterCustomIconMode != OverlayBasicClusterCustomIconModeStepped) {
        return [self simpleLowColorForState:state];
    }
    if ([OverlayBasicClusterExampleNormalizeHexString(state.clusterFillColorHex, @"#2F80ED") isEqualToString:@"#2F80ED"]) {
        return [self colorFromHexString:@"#F2C94C" fallbackHex:@"#F2C94C"];
    }
    return [self simpleLowColorForState:state];
}

- (UIColor *)simpleHighColorForState:(OverlayBasicClusterExampleFormState *)state {
    if (state.clusterCustomIconMode != OverlayBasicClusterCustomIconModeStepped) {
        return [self simpleLowColorForState:state];
    }
    if ([OverlayBasicClusterExampleNormalizeHexString(state.clusterFillColorHex, @"#2F80ED") isEqualToString:@"#2F80ED"]) {
        return [self colorFromHexString:@"#EB5757" fallbackHex:@"#EB5757"];
    }
    return [self simpleLowColorForState:state];
}

- (UIImage *)customClusterIconImageWithColor:(UIColor *)fillColor {
    CGSize size = CGSizeMake(72.0, 72.0);
    UIGraphicsBeginImageContextWithOptions(size, NO, UIScreen.mainScreen.scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (context) {
        CGPoint points[] = {
            CGPointMake(36.0, 3.0),
            CGPointMake(64.0, 19.0),
            CGPointMake(64.0, 53.0),
            CGPointMake(36.0, 69.0),
            CGPointMake(8.0, 53.0),
            CGPointMake(8.0, 19.0),
        };
        UIBezierPath *path = [UIBezierPath bezierPath];
        [path moveToPoint:points[0]];
        for (NSUInteger index = 1; index < sizeof(points) / sizeof(CGPoint); index++) {
            [path addLineToPoint:points[index]];
        }
        [path closePath];
        CGContextSetFillColorWithColor(context, fillColor.CGColor);
        CGContextAddPath(context, path.CGPath);
        CGContextFillPath(context);
        CGContextSetStrokeColorWithColor(context, UIColor.whiteColor.CGColor);
        CGContextSetLineWidth(context, 4.0);
        CGContextAddPath(context, path.CGPath);
        CGContextStrokePath(context);

        CGContextSetFillColorWithColor(context, [[UIColor whiteColor] colorWithAlphaComponent:0.22].CGColor);
        UIBezierPath *highlight = [UIBezierPath bezierPath];
        [highlight moveToPoint:CGPointMake(20.0, 17.0)];
        [highlight addLineToPoint:CGPointMake(53.0, 17.0)];
        [highlight addLineToPoint:CGPointMake(45.0, 28.0)];
        [highlight addLineToPoint:CGPointMake(25.0, 28.0)];
        [highlight closePath];
        CGContextAddPath(context, highlight.CGPath);
        CGContextFillPath(context);
    }
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

#pragma mark - State

- (OverlayBasicClusterExampleFormState *)defaultFormState {
    OverlayBasicClusterExampleFormState *state = [[OverlayBasicClusterExampleFormState alloc] init];
    state.mapStyleDark = NO;
    state.clusterRadius = 50;
    state.maximumClusterZoomLevel = 16.0;
    state.minimumClusterPointCount = 2;
    state.clusteringEnabled = YES;
    state.countAbbreviationEnabled = YES;
    state.visible = YES;
    state.clickBehaviorIndex = 0;
    state.styleDemoMode = OverlayBasicClusterStyleDemoModeSimple;
    state.clusterCustomIconEnabled = NO;
    state.clusterCustomIconMode = OverlayBasicClusterCustomIconModeStepped;
    state.clusterFillColorHex = @"#2F80ED";
    state.clusterFillColorIndex = [self indexForColorHex:state.clusterFillColorHex fallbackIndex:0];
    state.clusterIconOpacity = 1.0;
    state.clusterStrokeColorHex = @"#FFFFFF";
    state.clusterStrokeColorIndex = [self indexForColorHex:state.clusterStrokeColorHex fallbackIndex:1];
    state.clusterStrokeWidth = 1.0;
    state.clusterVisualRadiusMode = OverlayBasicClusterVisualRadiusModeAdaptive;
    state.clusterVisualRadius = 24.0;
    state.clusterMinimumVisualRadius = 18.0;
    state.clusterMaximumVisualRadius = 30.0;
    state.clusterRadiusMaximumReference = 100;
    state.clusterTextFontSize = 12.0;
    state.clusterTextColorHex = @"#FFFFFF";
    state.clusterTextColorIndex = [self indexForColorHex:state.clusterTextColorHex fallbackIndex:1];
    state.minimumClusterZoomLevel = 0.0;
    state.maximumVisibleClusterZoomLevel = 16.0;
    state.leafIconMode = OverlayBasicClusterLeafIconModeByFeature;
    state.leafIconSize = 1.0;
    state.leafIconRotation = 0.0;
    state.leafIconOpacity = 1.0;
    state.leafShowText = NO;
    state.leafTextMode = OverlayBasicClusterLeafTextModeByFeature;
    state.leafFixedText = @"统一文案";
    state.leafTextSize = 12.0;
    state.minimumPointZoomLevel = 0.0;
    state.maximumPointZoomLevel = 22.0;
    return state;
}

- (OverlayBasicClusterExampleFormState *)stateFromCluster:(MTCCluster *)cluster {
    OverlayBasicClusterExampleFormState *state = self.formState ? [self.formState copy] : [self defaultFormState];
    state.clusterRadius = (NSInteger)cluster.clusterRadius;
    state.maximumClusterZoomLevel = cluster.maximumClusterZoomLevel;
    state.minimumClusterPointCount = (NSInteger)cluster.minimumClusterPointCount;
    state.clusteringEnabled = cluster.isClusteringEnabled;
    state.countAbbreviationEnabled = cluster.isCountAbbreviationEnabled;
    state.visible = cluster.isVisible;
    state.clickBehaviorIndex = [self indexForClickBehavior:cluster.clusterClickBehavior];
    state.minimumClusterZoomLevel = cluster.minimumClusterZoomLevel;
    state.maximumVisibleClusterZoomLevel = cluster.maximumVisibleClusterZoomLevel;
    state.minimumPointZoomLevel = cluster.minimumPointZoomLevel;
    state.maximumPointZoomLevel = cluster.maximumPointZoomLevel;
    return state;
}

#pragma mark - Map Style

- (void)switchMapStyleDark:(BOOL)dark preservingState:(OverlayBasicClusterExampleFormState *)state {
    NSString *styleID = dark ? OverlayBasicClusterExampleDarkStyleID : OverlayBasicClusterExampleLightStyleID;
    self.pendingStyleSwitchCamera = self.mapView.camera;
    self.pendingStyleSwitchPoints = self.cluster.points;
    self.formState = [state copy];
    [self.mapView loadMapStyleWithID:styleID];
}

- (void)mapView:(MTCMapView *)mapView didFinishSwitchingMapStyleWithID:(NSString *)mapStyleID {
    (void)mapView;
    self.formState.mapStyleDark = [mapStyleID isEqualToString:OverlayBasicClusterExampleDarkStyleID];
    NSArray<MTCClusterPoint *> *points = self.pendingStyleSwitchPoints ?: self.cluster.points;
    MTCMapCamera *camera = self.pendingStyleSwitchCamera;
    self.pendingStyleSwitchPoints = nil;
    self.pendingStyleSwitchCamera = nil;
    if (points.count > 0) {
        [self replaceClusterWithState:self.formState points:points recenter:NO];
    }
    if (camera) {
        [self.mapView setCamera:camera transition:[MTCCameraTransition jump] completion:nil];
    }
    [self.mapTestSupport markMapRenderedReady];
    [self.mapTestSupport pauseMapRenderingIfUITesting:self.mapView];
    [self.mapStyleItem updateTitle:[self mapStyleTitleForState:self.formState]];
    [self.settingsSheet refreshItem:self.mapStyleItem];
}

- (void)mapView:(MTCMapView *)mapView didFailLoadingMapStyleWithID:(NSString *)mapStyleID message:(NSString *)message {
    (void)mapView;
    self.pendingStyleSwitchPoints = nil;
    self.pendingStyleSwitchCamera = nil;
    NSString *errorMessage = message.length > 0 ? message : [self localizedStringForKey:@"common_unknown_error"];
    [MTCExampleToastView showMessage:[NSString stringWithFormat:[self localizedStringForKey:@"map_style_switch_failure"], mapStyleID, errorMessage]
                              inView:self.view];
}

#pragma mark - Values

- (MTCClusterClickBehavior)clickBehaviorForIndex:(NSInteger)index {
    switch (index) {
        case 1:
            return MTCClusterClickBehaviorZoomToExpansion;
        case 2:
            return MTCClusterClickBehaviorNone;
        case 0:
        default:
            return MTCClusterClickBehaviorCallbackOnly;
    }
}

- (NSInteger)indexForClickBehavior:(MTCClusterClickBehavior)behavior {
    switch (behavior) {
        case MTCClusterClickBehaviorZoomToExpansion:
            return 1;
        case MTCClusterClickBehaviorNone:
            return 2;
        case MTCClusterClickBehaviorCallbackOnly:
        default:
            return 0;
    }
}

- (NSArray<NSString *> *)clickBehaviorTitles {
    return @[
        @"CALLBACK_ONLY",
        @"ZOOM_TO_EXPANSION",
        @"NONE",
    ];
}

- (NSArray<NSString *> *)colorOptionTitles {
    return @[
        @"#2F80ED",
        @"#FFFFFF",
        @"#000000",
        @"#F2C94C",
        @"#27AE60",
        @"#EB5757",
    ];
}

- (NSArray<NSString *> *)colorOptionHexValues {
    return @[
        @"#2F80ED",
        @"#FFFFFF",
        @"#000000",
        @"#F2C94C",
        @"#27AE60",
        @"#EB5757",
    ];
}

- (NSString *)colorOptionHexValueAtIndex:(NSInteger)index fallback:(NSString *)fallback {
    NSArray<NSString *> *hexValues = [self colorOptionHexValues];
    if (index < 0 || index >= (NSInteger)hexValues.count) {
        return fallback;
    }
    return hexValues[(NSUInteger)index];
}

- (NSInteger)indexForColorHex:(NSString *)hexString fallbackIndex:(NSInteger)fallbackIndex {
    NSString *normalizedHex = OverlayBasicClusterExampleNormalizeHexString(hexString, @"");
    NSArray<NSString *> *hexValues = [self colorOptionHexValues];
    for (NSUInteger index = 0; index < hexValues.count; index++) {
        if ([normalizedHex caseInsensitiveCompare:hexValues[index]] == NSOrderedSame) {
            return (NSInteger)index;
        }
    }
    return fallbackIndex;
}

- (UIColor *)colorFromHexString:(NSString *)hexString fallbackHex:(NSString *)fallbackHex {
    NSString *normalizedHex = OverlayBasicClusterExampleNormalizeHexString(hexString, fallbackHex);
    NSString *candidate = [normalizedHex substringFromIndex:1];
    unsigned int rgbValue = 0;
    if (![[NSScanner scannerWithString:candidate] scanHexInt:&rgbValue]) {
        return UIColor.systemBlueColor;
    }
    if (candidate.length == 8) {
        CGFloat alpha = ((rgbValue & 0xFF000000) >> 24) / 255.0;
        CGFloat red = ((rgbValue & 0x00FF0000) >> 16) / 255.0;
        CGFloat green = ((rgbValue & 0x0000FF00) >> 8) / 255.0;
        CGFloat blue = (rgbValue & 0x000000FF) / 255.0;
        return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
    }
    CGFloat red = ((rgbValue & 0xFF0000) >> 16) / 255.0;
    CGFloat green = ((rgbValue & 0x00FF00) >> 8) / 255.0;
    CGFloat blue = (rgbValue & 0x0000FF) / 255.0;
    return [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
}

- (NSString *)mapStyleTitleForState:(OverlayBasicClusterExampleFormState *)state {
    NSString *styleName = [self localizedStringForKey:state.mapStyleDark ? @"point_cluster_map_style_dark" : @"point_cluster_map_style_light"];
    return [NSString stringWithFormat:[self localizedStringForKey:@"point_cluster_input_map_style_label"], styleName];
}

- (NSString *)lifecycleStateName:(MTCClusterLifecycleState)state {
    switch (state) {
        case MTCClusterLifecycleStateLoading:
            return @"LOADING";
        case MTCClusterLifecycleStateReady:
            return @"READY";
        case MTCClusterLifecycleStateEmpty:
            return @"EMPTY";
        case MTCClusterLifecycleStateError:
            return @"ERROR";
        case MTCClusterLifecycleStateDetached:
        default:
            return @"DETACHED";
    }
}

- (CLLocationCoordinate2D)centerCoordinate {
    return CLLocationCoordinate2DMake(OverlayBasicClusterExampleLatitude, OverlayBasicClusterExampleLongitude);
}

#pragma mark - MTCMapViewDelegate

- (void)mapView:(MTCMapView *)mapView didTapOverlay:(id<MTCOverlay>)overlay hit:(MTCOverlayHit *)hit {
    (void)mapView;
    if (overlay != self.cluster || ![hit isKindOfClass:MTCClusterHit.class]) {
        return;
    }

    MTCClusterHit *clusterHit = (MTCClusterHit *)hit;
    NSString *message = clusterHit.isCluster
        ? [NSString stringWithFormat:[self localizedStringForKey:@"point_cluster_callback_cluster"],
           clusterHit.clusterID.stringValue ?: @"-",
           [NSString stringWithFormat:@"%lu", (unsigned long)clusterHit.pointCount],
           self.mapView.camera.zoomLevel,
           hit.coordinate.latitude,
           hit.coordinate.longitude]
        : [NSString stringWithFormat:[self localizedStringForKey:@"point_cluster_callback_leaf"],
           clusterHit.pointIdentifier ?: @"-",
           @"-",
           hit.coordinate.latitude,
           hit.coordinate.longitude];
    [MTCExampleToastView showMessage:message inView:self.view];
}

- (void)mapView:(MTCMapView *)mapView didLongPressOverlay:(id<MTCOverlay>)overlay hit:(MTCOverlayHit *)hit {
    (void)mapView;
    if (overlay != self.cluster || ![hit isKindOfClass:MTCClusterHit.class]) {
        return;
    }

    MTCClusterHit *clusterHit = (MTCClusterHit *)hit;
    NSString *message = clusterHit.isCluster
        ? [NSString stringWithFormat:[self localizedStringForKey:@"point_cluster_callback_cluster"],
           clusterHit.clusterID.stringValue ?: @"-",
           [NSString stringWithFormat:@"%lu", (unsigned long)clusterHit.pointCount],
           self.mapView.camera.zoomLevel,
           hit.coordinate.latitude,
           hit.coordinate.longitude]
        : [NSString stringWithFormat:[self localizedStringForKey:@"point_cluster_callback_leaf"],
           clusterHit.pointIdentifier ?: @"-",
           @"-",
           hit.coordinate.latitude,
           hit.coordinate.longitude];
    [MTCExampleToastView showMessage:message inView:self.view];
}

#pragma mark - Language

- (void)handleExampleSettingsAction {
    [self showSettingsSheet];
}

- (void)demoLanguageDidChange {
    [self applyLocalizedTexts];
}

- (void)applyLocalizedTexts {
    self.title = [self localizedStringForKey:@"demo_title_OverlayBasicClusterExampleViewController"];
    if (self.mapView) {
        self.mapView.mapLanguage = [self mapLanguageForDemoLanguage:self.demoLanguage];
    }
    if ([self isSettingsSheetVisible:ExampleSettingsSheetView.class]) {
        [self showSettingsSheet];
    }
}

@end
