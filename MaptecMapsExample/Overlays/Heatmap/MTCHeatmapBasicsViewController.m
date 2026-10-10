//
//  MTCHeatmapBasicsViewController.m
//  MaptecMapsExample
//
//  Created by ZHOUPanpan on 2026/7/27.
//  Copyright © 2026 ZHOUPanpan. All rights reserved.
//

#import "MTCHeatmapBasicsViewController.h"
#import "ExampleSettingsSheetView.h"
#import "MTCExampleMapTestSupport.h"
#import "MTCExampleTestAccessibility.h"
#import <MaptecMapsKit/MaptecMapsKit.h>

#import <math.h>

static NSString * const MTCHeatmapProviderResourceName = @"heatmap_provider";
static NSString * const MTCHeatmapProviderResourceType = @"json";

typedef struct {
    double longitude;
    double latitude;
    double baseWeight;
    NSInteger pointCount;
} MTCHeatmapDemoAnchor;

/// 基础热力图示例配置模型，收敛设置面板中的滑块状态
@interface MTCHeatmapBasicsConfigModel : NSObject

@property (nonatomic) CGFloat radiusValue;
@property (nonatomic) CGFloat weightValue;
@property (nonatomic) BOOL ignoresPointWeight;
@property (nonatomic) CGFloat pointWeightValue;
@property (nonatomic) CGFloat intensityValue;
@property (nonatomic) CGFloat opacityValue;
@property (nonatomic) CGFloat minimumZoomValue;
@property (nonatomic) CGFloat maximumZoomValue;

+ (instancetype)defaultConfig;
- (void)applyToHeatmap:(MTCHeatmap *)heatmap;

@end

@implementation MTCHeatmapBasicsConfigModel

- (void)dealloc {
}

#pragma mark - Public

+ (instancetype)defaultConfig {
    MTCHeatmapBasicsConfigModel *configModel = [[MTCHeatmapBasicsConfigModel alloc] init];
    configModel.radiusValue = 34.0;
    configModel.weightValue = 1.0;
    configModel.ignoresPointWeight = NO;
    configModel.pointWeightValue = 1.0;
    configModel.intensityValue = 0.82;
    configModel.opacityValue = 0.82;
    configModel.minimumZoomValue = 0.0;
    configModel.maximumZoomValue = 22.0;
    return configModel;
}

- (void)applyToHeatmap:(MTCHeatmap *)heatmap {
    if (!heatmap) {
        return;
    }
    heatmap.style.radius = self.radiusValue;
    heatmap.style.weight = self.weightValue;
    heatmap.style.intensity = self.intensityValue;
    heatmap.style.opacity = self.opacityValue;
    heatmap.minimumZoomLevel = self.minimumZoomValue;
    heatmap.maximumZoomLevel = self.maximumZoomValue;
}

@end

@interface MTCHeatmapBasicsViewController () <MTCMapViewDelegate>

@property (nonatomic, strong) MTCMapView *mapView;
@property (nonatomic, strong) MTCExampleMapTestSupport *mapTestSupport;
@property (nonatomic, strong) MTCHeatmap *heatmap;
@property (nonatomic, strong) MTCHeatmapBasicsConfigModel *configModel;
@property (nonatomic, copy) NSArray<MTCHeatmapPoint *> *sourceHeatmapPoints;

@end

@implementation MTCHeatmapBasicsViewController

- (void)dealloc {
}

#pragma mark - Public

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.accessibilityIdentifier = MTCExampleTestAccessibilityHeatmapBasicsScreen;
    [self configureNavigationItems:NO];
    self.view.backgroundColor = UIColor.systemBackgroundColor;
    [self setupConfigModel];
    [self setupMapView];
    [self drawHeatmap];
    [self applyLocalizedTexts];
}

#pragma mark - Protocol

#pragma mark - Delegate

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

- (void)showSettingsSheet {
    __weak typeof(self) weakSelf = self;
    __block ExampleSettingsSheetView *sheet = nil;
    __block ExampleSettingsItem *minimumZoomItem = nil;
    __block ExampleSettingsItem *maximumZoomItem = nil;

    ExampleSettingsItem *radiusItem = [[ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"overlay_heatmap_radius"]
                                                                        minimum:1.0
                                                                        maximum:50.0
                                                                           step:1.0
                                                                         getter:^double {
        return weakSelf.configModel.radiusValue;
    } setter:^(double value) {
        weakSelf.configModel.radiusValue = value;
        [weakSelf applyCurrentValuesToHeatmap];
    } formatter:^NSString *(double value) {
        return [NSString stringWithFormat:@"%.0f", value];
    }] withAccessibilityIdentifier:MTCExampleTestAccessibilityHeatmapSliderRadius];

    ExampleSettingsItem *weightItem = [[ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"overlay_heatmap_weight"]
                                                                        minimum:0.0
                                                                        maximum:1.0
                                                                           step:0.05
                                                                         getter:^double {
        return weakSelf.configModel.weightValue;
    } setter:^(double value) {
        weakSelf.configModel.weightValue = value;
        [weakSelf applyCurrentValuesToHeatmap];
    } formatter:^NSString *(double value) {
        return [NSString stringWithFormat:@"%.2f", value];
    }] withAccessibilityIdentifier:MTCExampleTestAccessibilityHeatmapSliderWeight];

    ExampleSettingsItem *pointWeightVisibleItem = [ExampleSettingsItem boolItemWithTitle:[self localizedStringForKey:@"overlay_ignore_per_point_weight"]
                                                                                  getter:^BOOL {
        return weakSelf.configModel.ignoresPointWeight;
    } setter:^(BOOL value) {
        weakSelf.configModel.ignoresPointWeight = value;
        [weakSelf applyCurrentPointsToHeatmap];
    }];
    ExampleSettingsItem *pointWeightItem = [[ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"overlay_per_point_weight"]
                                                                           minimum:0.0
                                                                           maximum:1.0
                                                                              step:0.05
                                                                            getter:^double {
        return weakSelf.configModel.pointWeightValue;
    } setter:^(double value) {
        weakSelf.configModel.pointWeightValue = value;
        [weakSelf applyCurrentPointsToHeatmap];
    } formatter:^NSString *(double value) {
        return [NSString stringWithFormat:@"%.2f", value];
    }] visibleWhen:^BOOL {
        return !weakSelf.configModel.ignoresPointWeight;
    }];

    ExampleSettingsItem *intensityItem = [[ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"overlay_heatmap_intensity"]
                                                                           minimum:0.0
                                                                           maximum:10.0
                                                                              step:0.05
                                                                            getter:^double {
        return weakSelf.configModel.intensityValue;
    } setter:^(double value) {
        weakSelf.configModel.intensityValue = value;
        [weakSelf applyCurrentValuesToHeatmap];
    } formatter:^NSString *(double value) {
        return [NSString stringWithFormat:@"%.2f", value];
    }] withAccessibilityIdentifier:MTCExampleTestAccessibilityHeatmapSliderIntensity];

    ExampleSettingsItem *opacityItem = [[ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"overlay_opacity_34dac4"]
                                                                         minimum:0.0
                                                                         maximum:1.0
                                                                            step:0.05
                                                                          getter:^double {
        return weakSelf.configModel.opacityValue;
    } setter:^(double value) {
        weakSelf.configModel.opacityValue = value;
        [weakSelf applyCurrentValuesToHeatmap];
    } formatter:^NSString *(double value) {
        return [NSString stringWithFormat:@"%.2f", value];
    }] withAccessibilityIdentifier:MTCExampleTestAccessibilityHeatmapSliderOpacity];

    minimumZoomItem = [[ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"overlay_min_level"]
                                                       minimum:0.0
                                                       maximum:24.0
                                                          step:0.5
                                                        getter:^double {
        return weakSelf.configModel.minimumZoomValue;
    } setter:^(double value) {
        weakSelf.configModel.minimumZoomValue = value;
        if (weakSelf.configModel.maximumZoomValue < weakSelf.configModel.minimumZoomValue) {
            weakSelf.configModel.maximumZoomValue = weakSelf.configModel.minimumZoomValue;
            [sheet refreshItem:maximumZoomItem];
        }
        [weakSelf applyCurrentValuesToHeatmap];
    } formatter:^NSString *(double value) {
        return [NSString stringWithFormat:@"%.1f", value];
    }] withAccessibilityIdentifier:MTCExampleTestAccessibilityHeatmapSliderMinZoom];

    maximumZoomItem = [[ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"overlay_max_level"]
                                                       minimum:0.0
                                                       maximum:24.0
                                                          step:0.5
                                                        getter:^double {
        return weakSelf.configModel.maximumZoomValue;
    } setter:^(double value) {
        weakSelf.configModel.maximumZoomValue = value;
        if (weakSelf.configModel.minimumZoomValue > weakSelf.configModel.maximumZoomValue) {
            weakSelf.configModel.minimumZoomValue = weakSelf.configModel.maximumZoomValue;
            [sheet refreshItem:minimumZoomItem];
        }
        [weakSelf applyCurrentValuesToHeatmap];
    } formatter:^NSString *(double value) {
        return [NSString stringWithFormat:@"%.1f", value];
    }] withAccessibilityIdentifier:MTCExampleTestAccessibilityHeatmapSliderMaxZoom];

    ExampleSettingsItem *drawButtonItem = [[ExampleSettingsItem actionItemWithTitle:[self localizedStringForKey:@"overlay_draw"]
                                                                            handler:^{
        [weakSelf drawHeatmap];
        [sheet dismissAnimated:YES];
    }] withAccessibilityIdentifier:MTCExampleTestAccessibilityHeatmapDrawButton];

    NSArray<ExampleSettingsSection *> *sections = @[
        [ExampleSettingsSection sectionWithTitle:[self localizedStringForKey:@"overlay_heatmap_style"]
                                           items:@[radiusItem, weightItem, pointWeightVisibleItem, pointWeightItem, intensityItem, opacityItem, drawButtonItem]],
        [ExampleSettingsSection sectionWithTitle:[self localizedStringForKey:@"overlay_zoom_range"]
                                           items:@[minimumZoomItem, maximumZoomItem]],
    ];
    sheet = [[ExampleSettingsSheetView alloc] initWithTitle:[self localizedStringForKey:@"overlay_heatmap_style"] sections:sections];
    [sheet showInView:self.view animated:YES];
}

#pragma mark - Private

- (void)setupConfigModel {
    self.configModel = [MTCHeatmapBasicsConfigModel defaultConfig];
}

- (void)setupMapView {
    self.mapView = [[MTCMapView alloc] initWithFrame:CGRectZero];
    self.mapView.delegate = self;
    self.mapView.uiSettings.zoomLevelVisible = YES;
    self.mapView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.mapView];
    [NSLayoutConstraint activateConstraints:@[
        [self.mapView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.mapView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.mapView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.mapView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];

    self.mapTestSupport = [[MTCExampleMapTestSupport alloc] init];
    self.mapTestSupport.overlayCountValueKey = MTCExampleTestAccessibilityHeatmapCountValueKey;
    self.mapTestSupport.overlayPresenceIdentifier = MTCExampleTestAccessibilityHeatmapHasHeatmaps;
    [self.mapTestSupport installOnHostView:self.view];
}

#pragma mark -- 渲染
- (void)drawHeatmap {
    [self replaceHeatmapWithPoints:[self demoHeatmapPoints]];
    [self.mapView setCenterCoordinate:CLLocationCoordinate2DMake(1.315, 103.82) zoomLevel:11.15];
}

- (void)loadExternalHeatmapData {
    NSArray<MTCHeatmapPoint *> *points = [self externalHeatmapPoints];
    if (points.count == 0) {
        [self showAlertWithMessage:[self localizedStringForKey:@"overlay_failed_to_load_external_heatmap_data"]];
        return;
    }
    [self replaceHeatmapWithPoints:points];
    [self.mapView setCenterCoordinate:CLLocationCoordinate2DMake(1.315, 103.82) zoomLevel:11.15];
}

- (void)replaceHeatmapWithPoints:(NSArray<MTCHeatmapPoint *> *)points {
    if (self.heatmap) {
        [self.mapView removeOverlay:self.heatmap];
        [self.mapTestSupport syncOverlayCount:0];
    }
    self.sourceHeatmapPoints = points;
    self.heatmap = [[MTCHeatmap alloc] initWithPoints:[self heatmapPointsForCurrentConfigWithPoints:self.sourceHeatmapPoints]];
    [self applyCurrentValuesToHeatmap];
    [self.mapView addOverlay:self.heatmap];
    [self.mapTestSupport syncOverlayCount:1];
}

- (void)applyCurrentValuesToHeatmap {
    if (!self.heatmap) {
        return;
    }
    [self.configModel applyToHeatmap:self.heatmap];
}

- (void)applyCurrentPointsToHeatmap {
    if (!self.heatmap || self.sourceHeatmapPoints.count == 0) {
        return;
    }
    self.heatmap.points = [self heatmapPointsForCurrentConfigWithPoints:self.sourceHeatmapPoints];
}

- (NSArray<MTCHeatmapPoint *> *)heatmapPointsForCurrentConfigWithPoints:(NSArray<MTCHeatmapPoint *> *)points {
    if (self.configModel.ignoresPointWeight) {
        return [self heatmapPointsByIgnoringPointWeightFromPoints:points];
    }
    return [self heatmapPointsByApplyingPointWeightToPoints:points];
}

- (NSArray<MTCHeatmapPoint *> *)heatmapPointsByIgnoringPointWeightFromPoints:(NSArray<MTCHeatmapPoint *> *)points {
    NSMutableArray<MTCHeatmapPoint *> *unweightedPoints = [NSMutableArray arrayWithCapacity:points.count];
    for (MTCHeatmapPoint *point in points) {
        [unweightedPoints addObject:[[MTCHeatmapPoint alloc] initWithCoordinate:point.coordinate]];
    }
    return unweightedPoints;
}

- (NSArray<MTCHeatmapPoint *> *)heatmapPointsByApplyingPointWeightToPoints:(NSArray<MTCHeatmapPoint *> *)points {
    NSMutableArray<MTCHeatmapPoint *> *weightedPoints = [NSMutableArray arrayWithCapacity:points.count];
    for (MTCHeatmapPoint *point in points) {
        if (!point.hasWeight) {
            [weightedPoints addObject:[point copy]];
            continue;
        }
        CGFloat weight = point.weight * self.configModel.pointWeightValue;
        [weightedPoints addObject:[[MTCHeatmapPoint alloc] initWithCoordinate:point.coordinate weight:weight]];
    }
    return weightedPoints;
}

#pragma mark -- data
- (NSArray<MTCHeatmapPoint *> *)demoHeatmapPoints {
    const MTCHeatmapDemoAnchor anchors[] = {
        {103.8519, 1.2903, 7.2, 18},
        {103.8318, 1.3048, 6.4, 16},
        {103.8198, 1.3521, 5.7, 15},
        {103.7764, 1.2966, 5.2, 15},
        {103.7955, 1.3606, 4.8, 14},
        {103.8750, 1.3250, 4.5, 14},
    };

    NSMutableArray<MTCHeatmapPoint *> *points = [NSMutableArray arrayWithCapacity:92];
    for (NSUInteger anchorIndex = 0; anchorIndex < sizeof(anchors) / sizeof(anchors[0]); ++anchorIndex) {
        MTCHeatmapDemoAnchor anchor = anchors[anchorIndex];
        for (NSInteger pointIndex = 0; pointIndex < anchor.pointCount; ++pointIndex) {
            double ring = 0.35 + (pointIndex % 6) * 0.14;
            double angle = pointIndex * 2.399 + anchorIndex * 0.72;
            double longitudeOffset = cos(angle) * 0.0135 * ring;
            double latitudeOffset = sin(angle) * 0.0102 * ring;
            double weightDrop = (pointIndex % 7) * 0.34 + (pointIndex / 7) * 0.14;
            CGFloat weight = MIN(1.0, MAX(0.0, MAX(1.2, anchor.baseWeight - weightDrop) / 8.0));
            CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(anchor.latitude + latitudeOffset,
                                                                            anchor.longitude + longitudeOffset);
            [points addObject:[[MTCHeatmapPoint alloc] initWithCoordinate:coordinate weight:weight]];
        }
    }
    return points;
}

- (NSArray<MTCHeatmapPoint *> *)externalHeatmapPoints {
    NSString *path = [NSBundle.mainBundle pathForResource:MTCHeatmapProviderResourceName ofType:MTCHeatmapProviderResourceType];
    if (path.length == 0) {
        return @[];
    }
    NSData *data = [NSData dataWithContentsOfFile:path];
    if (!data) {
        return @[];
    }
    id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    if (![jsonObject isKindOfClass:NSDictionary.class]) {
        return @[];
    }
    NSArray *features = [(NSDictionary *)jsonObject objectForKey:@"features"];
    if (![features isKindOfClass:NSArray.class]) {
        return @[];
    }

    NSMutableArray<MTCHeatmapPoint *> *points = [NSMutableArray arrayWithCapacity:features.count];
    for (id featureObject in features) {
        if (![featureObject isKindOfClass:NSDictionary.class]) {
            continue;
        }
        NSDictionary *feature = (NSDictionary *)featureObject;
        NSDictionary *geometry = [feature objectForKey:@"geometry"];
        NSArray *coordinates = [geometry isKindOfClass:NSDictionary.class] ? [geometry objectForKey:@"coordinates"] : nil;
        if (![coordinates isKindOfClass:NSArray.class] || coordinates.count < 2) {
            continue;
        }
        NSNumber *longitude = [self numberFromObject:coordinates[0]];
        NSNumber *latitude = [self numberFromObject:coordinates[1]];
        if (!longitude || !latitude) {
            continue;
        }
        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(latitude.doubleValue, longitude.doubleValue);
        if (!CLLocationCoordinate2DIsValid(coordinate)) {
            continue;
        }

        NSDictionary *properties = [feature objectForKey:@"properties"];
        NSNumber *weight = nil;
        if ([properties isKindOfClass:NSDictionary.class]) {
            weight = [self numberFromObject:[properties objectForKey:@"weight"]];
        }
        if (weight) {
            [points addObject:[[MTCHeatmapPoint alloc] initWithCoordinate:coordinate weight:weight.doubleValue]];
        } else {
            [points addObject:[[MTCHeatmapPoint alloc] initWithCoordinate:coordinate]];
        }
    }
    return points;
}

#pragma mark -- Others
- (NSNumber *)numberFromObject:(id)object {
    if ([object isKindOfClass:NSNumber.class]) {
        return object;
    }
    if (![object isKindOfClass:NSString.class]) {
        return nil;
    }
    double value = [(NSString *)object doubleValue];
    if (!isfinite(value)) {
        return nil;
    }
    return @(value);
}

- (void)showAlertWithMessage:(NSString *)message {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:[self localizedStringForKey:@"overlay_tips"]
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:[self localizedStringForKey:@"common_ok"] style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark -- multi-language

- (void)handleExampleSettingsAction {
    [self showSettingsSheet];
}

- (void)demoLanguageDidChange {
    [self applyLocalizedTexts];
}

- (void)applyLocalizedTexts {
    self.title = [self localizedStringForKey:@"demo_title_MTCHeatmapBasicsViewController"];
    if (self.mapView) {
        self.mapView.mapLanguage = [self mapLanguageForDemoLanguage:self.demoLanguage];
    }
    if ([self isSettingsSheetVisible:ExampleSettingsSheetView.class]) {
        [self showSettingsSheet];
    }
}

#pragma mark - Getter & Setter

@end
