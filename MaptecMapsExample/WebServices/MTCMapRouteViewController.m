#import "MTCMapRouteViewController.h"

#import "ExampleSettingsSheetView.h"
#import "MTCExampleDemoLocalization.h"
#import "MTCExampleMapTestSupport.h"
#import "MTCExampleTestAccessibility.h"
#import "MTCRoutePlanController.h"
#import "MTCWebRoutePanel.h"

#import <MaptecMapsKit/MaptecMapsKit.h>
#import <Masonry/Masonry.h>

@interface MTCMapRouteConfigModel : NSObject

@property (nonatomic, copy) NSString *originText;
@property (nonatomic, copy) NSString *destinationText;
@property (nonatomic, copy) NSString *waypointLatitudeText;
@property (nonatomic, copy) NSString *waypointLongitudeText;
@property (nonatomic, copy) NSArray<NSValue *> *waypointCoordinates;
@property (nonatomic, assign) NSInteger strategyIndex;
@property (nonatomic, assign) BOOL alternativesEnabled;
@property (nonatomic, assign) BOOL avoidsHighways;
@property (nonatomic, copy) NSString *statusText;

@end

@implementation MTCMapRouteConfigModel

- (instancetype)init {
    self = [super init];
    if (self) {
        _originText = @"103.8630,1.2820";
        _destinationText = @"103.8920,1.3920";
        _waypointLatitudeText = @"1.3500";
        _waypointLongitudeText = @"103.8300";
        _waypointCoordinates = @[];
        _strategyIndex = MTCMapRouteStrategyFastest;
        _alternativesEnabled = YES;
        _avoidsHighways = NO;
        _statusText = [MTCExampleDemoLocalization stringForKey:@"web_routing_not_started"
                                                      language:[MTCExampleDemoLocalization currentLanguage]];
    }
    return self;
}

@end

@interface MTCMapRouteViewController () <MTCMapViewDelegate, MTCRoutePlanControllerDelegate>

@property (nonatomic, strong) MTCMapView *mapView;
@property (nonatomic, strong) MTCExampleMapTestSupport *mapTestSupport;
@property (nonatomic, strong) MTCRoutePlanController *routePlanController;
@property (nonatomic, strong) MTCWebRoutePanel *routePanel;
@property (nonatomic, strong) MTCMapRouteConfigModel *configModel;
@property (nonatomic, weak, nullable) ExampleSettingsSheetView *settingsSheet;

@end

@implementation MTCMapRouteViewController

- (void)dealloc {
    [self.routePlanController invalidate];
    self.mapView.delegate = nil;
}

#pragma mark - Public

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = UIColor.systemBackgroundColor;
    self.view.accessibilityIdentifier = MTCExampleTestAccessibilityMapRouteScreen;
    self.configModel = [[MTCMapRouteConfigModel alloc] init];
    [self setupMapView];
    [self setupRoutePanel];
    [self configureNavigationItems:NO];
    [self applyLocalizedTexts];
}

#pragma mark - Protocol

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

#pragma mark - Protocol

#pragma mark -- MTCRoutePlanControllerDelegate

- (void)routePlanController:(MTCRoutePlanController *)controller
             didChangeState:(MTCRoutePlanState *)state {
    switch (state.phase) {
        case MTCRoutePlanPhaseIdle: {
            [self updateStatusText:[self localizedStringForKey:@"web_routing_not_started"] showPanel:NO];
        }
        break;
        case MTCRoutePlanPhaseCalculating: {
            [self updateStatusText:[self localizedStringForKey:@"web_requesting_route"] showPanel:NO];
        }
        break;
        case MTCRoutePlanPhaseReady: {
            self.routePanel.hidden = NO;
            [self reloadRouteSelector];
            [self updateSelectedRouteSummary];
            [self.routePanel updateSummaryText:self.configModel.statusText];
            [self.settingsSheet reloadData];
        }
        break;
        case MTCRoutePlanPhaseFailed: {
            [self updateStatusText:(state.error.localizedDescription ?: [self localizedStringForKey:@"web_routing_failed"]) showPanel:NO];
        }
        break;
        case MTCRoutePlanPhaseInvalidated: {
            self.routePanel.hidden = YES;
            [self.settingsSheet reloadData];
        }
        break;
    }
}

- (void)routePlanController:(MTCRoutePlanController *)controller
     didSelectRouteAtIndex:(NSInteger)index {
    [self.routePanel setSelectedSegmentIndex:index];
    [self updateSelectedRouteSummary];
    [self.routePanel updateSummaryText:self.configModel.statusText];
    [self.settingsSheet reloadData];
}

#pragma mark - Delegate

#pragma mark -- MTCMapViewDelegate

- (void)mapView:(MTCMapView *)mapView didTapOverlay:(id<MTCOverlay>)overlay {
    [self.routePlanController handleTappedOverlay:overlay];
}

#pragma mark - Event

- (void)showRouteSettings {
    ExampleSettingsSheetView *sheet =
        [[ExampleSettingsSheetView alloc] initWithTitle:[self localizedStringForKey:@"web_route_planning_settings"]
                                               sections:[self settingsSections]];
    self.settingsSheet = sheet;
    [sheet showInView:self.view animated:NO];
}

- (void)calculateRoute {
    CLLocationCoordinate2D originCoordinate =
        [self coordinateFromLngLatString:self.configModel.originText];
    CLLocationCoordinate2D destinationCoordinate =
        [self coordinateFromLngLatString:self.configModel.destinationText];
    if (!CLLocationCoordinate2DIsValid(originCoordinate) ||
        !CLLocationCoordinate2DIsValid(destinationCoordinate)) {
        [self updateStatusText:[self localizedStringForKey:@"web_invalid_origin_destination_format_expected_lng_l"] showPanel:self.routePanel.hidden == NO];
        return;
    }

    MTCRouteWaypoint *origin = [[MTCRouteWaypoint alloc] initWithCoordinate:originCoordinate];
    origin.name = [self localizedStringForKey:@"web_origin"];
    MTCRouteWaypoint *destination =
        [[MTCRouteWaypoint alloc] initWithCoordinate:destinationCoordinate];
    destination.name = [self localizedStringForKey:@"web_destination"];
    MTCRoutePlanConfiguration *configuration =
        [[MTCRoutePlanConfiguration alloc] initWithOrigin:origin destination:destination];
    configuration.strategy = (MTCMapRouteStrategy)self.configModel.strategyIndex;
    configuration.requestsAlternativeRoutes = self.configModel.alternativesEnabled;
    configuration.avoidsHighways = self.configModel.avoidsHighways;

    NSMutableArray<MTCRouteWaypoint *> *waypoints =
        [NSMutableArray arrayWithCapacity:self.configModel.waypointCoordinates.count];
    [self.configModel.waypointCoordinates enumerateObjectsUsingBlock:^(NSValue *value,
                                                                       NSUInteger index,
                                                                       BOOL *stop) {
        (void)stop;
        CLLocationCoordinate2D coordinate = [self coordinateFromValue:value];
        MTCRouteWaypoint *waypoint = [[MTCRouteWaypoint alloc] initWithCoordinate:coordinate];
        waypoint.name = [NSString stringWithFormat:[self localizedStringForKey:@"web_waypoint_lu"], (unsigned long)(index + 1)];
        [waypoints addObject:waypoint];
    }];
    configuration.waypoints = [waypoints copy];
    [self.settingsSheet dismissAnimated:YES];
    [self.routePlanController calculateRouteWithConfiguration:configuration];
}

- (void)addWaypoint {
    NSNumber *latitude = [self strictNumberFromString:self.configModel.waypointLatitudeText];
    NSNumber *longitude = [self strictNumberFromString:self.configModel.waypointLongitudeText];
    if (!latitude || !longitude) {
        [self updateStatusText:[self localizedStringForKey:@"web_enter_a_valid_waypoint_coordinate"] showPanel:self.routePanel.hidden == NO];
        return;
    }
    CLLocationCoordinate2D coordinate =
        CLLocationCoordinate2DMake(latitude.doubleValue, longitude.doubleValue);
    if (!CLLocationCoordinate2DIsValid(coordinate)) {
        [self updateStatusText:[self localizedStringForKey:@"web_invalid_waypoint_coordinate"] showPanel:self.routePanel.hidden == NO];
        return;
    }
    self.configModel.waypointCoordinates =
        [self.configModel.waypointCoordinates arrayByAddingObject:[self valueForCoordinate:coordinate]];
    [self updateStatusText:[self localizedStringForKey:@"web_waypoint_added"] showPanel:self.routePanel.hidden == NO];
}

- (void)clearWaypoints {
    self.configModel.waypointCoordinates = @[];
    [self updateStatusText:[self localizedStringForKey:@"web_waypoints_cleared"] showPanel:self.routePanel.hidden == NO];
}

- (void)showAllRoutes {
    MTCRouteOverviewOptions *options = [[MTCRouteOverviewOptions alloc] init];
    options.mode = MTCRouteOverviewModeAllRoutes;
    [self.routePlanController showOverviewWithOptions:options];
}

- (void)clearRoutes {
    [self.routePlanController clearRoutes];
}

#pragma mark - Private

- (void)setupMapView {
    self.mapView = [[MTCMapView alloc] initWithFrame:self.view.bounds];
    self.mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.mapView.delegate = self;
    [self.view addSubview:self.mapView];

    self.mapTestSupport = [[MTCExampleMapTestSupport alloc] init];
    [self.mapTestSupport installOnHostView:self.view];

    [self.mapView setCenterCoordinate:CLLocationCoordinate2DMake(1.3521, 103.8198)
                            zoomLevel:11.5];
    self.routePlanController = [[MTCRoutePlanController alloc] initWithMapView:self.mapView];
    self.routePlanController.delegate = self;
}

- (void)setupRoutePanel {
    __weak typeof(self) weakSelf = self;
    self.routePanel = [[MTCWebRoutePanel alloc] init];
    self.routePanel.onSegmentChanged = ^(NSInteger index) {
        [weakSelf.routePlanController selectRouteAtIndex:index];
    };
    self.routePanel.onOverviewTapped = ^{
        [weakSelf showAllRoutes];
    };
    self.routePanel.onClearTapped = ^{
        [weakSelf clearRoutes];
    };
    [self.view addSubview:self.routePanel];
    [self.routePanel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view.mas_safeAreaLayoutGuideLeft).offset(16.0);
        make.right.equalTo(self.view.mas_safeAreaLayoutGuideRight).offset(-16.0);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-12.0);
        make.height.mas_equalTo(96.0);
    }];
}

- (NSArray<ExampleSettingsSection *> *)settingsSections {
    __weak typeof(self) weakSelf = self;
    return @[
        [ExampleSettingsSection sectionWithTitle:[self localizedStringForKey:@"web_route"] items:@[
            [ExampleSettingsItem textItemWithTitle:[self localizedStringForKey:@"web_origin_lng_lat"]
                                       placeholder:@"103.8630,1.2820"
                                      keyboardType:UIKeyboardTypeNumbersAndPunctuation
                                            getter:^NSString *{
                return weakSelf.configModel.originText ?: @"";
            }
                                            setter:^(NSString *value) {
                weakSelf.configModel.originText = value ?: @"";
            }],
            [ExampleSettingsItem textItemWithTitle:[self localizedStringForKey:@"web_destination_lng_lat"]
                                       placeholder:@"103.8920,1.3920"
                                      keyboardType:UIKeyboardTypeNumbersAndPunctuation
                                            getter:^NSString *{
                return weakSelf.configModel.destinationText ?: @"";
            }
                                            setter:^(NSString *value) {
                weakSelf.configModel.destinationText = value ?: @"";
            }],
            [ExampleSettingsItem listItemWithTitle:[self localizedStringForKey:@"web_strategy"]
                                           options:@[[self localizedStringForKey:@"web_time_priority"], [self localizedStringForKey:@"web_distance_priority"], [self localizedStringForKey:@"web_balanced"]]
                                            getter:^NSInteger {
                return weakSelf.configModel.strategyIndex;
            }
                                            setter:^(NSInteger index) {
                weakSelf.configModel.strategyIndex = index;
            }],
            [ExampleSettingsItem boolItemWithTitle:[self localizedStringForKey:@"web_return_alternative_routes"]
                                            getter:^BOOL {
                return weakSelf.configModel.alternativesEnabled;
            }
                                            setter:^(BOOL value) {
                weakSelf.configModel.alternativesEnabled = value;
            }],
            [ExampleSettingsItem boolItemWithTitle:[self localizedStringForKey:@"web_avoid_highways"]
                                            getter:^BOOL {
                return weakSelf.configModel.avoidsHighways;
            }
                                            setter:^(BOOL value) {
                weakSelf.configModel.avoidsHighways = value;
            }],
        ]],
        [ExampleSettingsSection sectionWithTitle:[self localizedStringForKey:@"web_waypoints"] items:@[
            [ExampleSettingsItem textItemWithTitle:[self localizedStringForKey:@"web_latitude"]
                                       placeholder:@"1.3500"
                                      keyboardType:UIKeyboardTypeNumbersAndPunctuation
                                            getter:^NSString *{
                return weakSelf.configModel.waypointLatitudeText ?: @"";
            }
                                            setter:^(NSString *value) {
                weakSelf.configModel.waypointLatitudeText = value ?: @"";
            }],
            [ExampleSettingsItem textItemWithTitle:[self localizedStringForKey:@"web_longitude"]
                                       placeholder:@"103.8300"
                                      keyboardType:UIKeyboardTypeNumbersAndPunctuation
                                            getter:^NSString *{
                return weakSelf.configModel.waypointLongitudeText ?: @"";
            }
                                            setter:^(NSString *value) {
                weakSelf.configModel.waypointLongitudeText = value ?: @"";
            }],
            [ExampleSettingsItem multilineTextItemWithTitle:[self localizedStringForKey:@"web_current_waypoints"]
                                                placeholder:[self localizedStringForKey:@"overlay_none"]
                                                     getter:^NSString *{
                return [weakSelf waypointDescription];
            }
                                                     setter:nil],
            [ExampleSettingsItem actionItemWithTitle:[self localizedStringForKey:@"web_add_waypoint"] handler:^{
                [weakSelf addWaypoint];
            }],
            [ExampleSettingsItem actionItemWithTitle:[self localizedStringForKey:@"web_clear_waypoints"] handler:^{
                [weakSelf clearWaypoints];
            }],
        ]],
        [ExampleSettingsSection sectionWithTitle:[self localizedStringForKey:@"overlay_actions"] items:@[
            [ExampleSettingsItem actionItemWithTitle:[self localizedStringForKey:@"web_start_routing"] handler:^{
                [weakSelf calculateRoute];
            }],
            [ExampleSettingsItem actionItemWithTitle:[self localizedStringForKey:@"web_route_overview"] handler:^{
                [weakSelf showAllRoutes];
            }],
            [ExampleSettingsItem actionItemWithTitle:[self localizedStringForKey:@"web_clear_route"] handler:^{
                [weakSelf clearRoutes];
            }],
        ]],
        [ExampleSettingsSection sectionWithTitle:[self localizedStringForKey:@"web_status"] items:@[
            [ExampleSettingsItem dynamicInfoItemWithGetter:^NSString *{
                return weakSelf.configModel.statusText ?: @"";
            }],
        ]],
    ];
}

- (void)reloadRouteSelector {
    NSMutableArray<NSString *> *titles =
        [NSMutableArray arrayWithCapacity:self.routePlanController.routes.count];
    [self.routePlanController.routes enumerateObjectsUsingBlock:^(MTCRouteCandidate *route,
                                                                  NSUInteger index,
                                                                  BOOL *stop) {
        (void)stop;
        [titles addObject:[NSString stringWithFormat:[self localizedStringForKey:@"web_route_lu_1f_km"],
                                                     (unsigned long)(index + 1),
                                                     route.distance / 1000.0]];
    }];
    [self.routePanel reloadWithTitles:titles
                        selectedIndex:self.routePlanController.selectedRouteIndex];
}

- (void)updateSelectedRouteSummary {
    NSInteger index = self.routePlanController.selectedRouteIndex;
    if (index < 0 || index >= (NSInteger)self.routePlanController.routes.count) {
        return;
    }
    MTCRouteCandidate *route = self.routePlanController.routes[(NSUInteger)index];
    NSTimeInterval duration = route.trafficDuration > 0.0 ? route.trafficDuration : route.duration;
    self.configModel.statusText = [NSString stringWithFormat:[self localizedStringForKey:@"web_selected_route_ld_1f_km_0f_min"],
                                                            (long)(index + 1),
                                                            route.distance / 1000.0,
                                                            duration / 60.0];
}

- (void)refreshRoutePanelContent {
    switch (self.routePlanController.state.phase) {
        case MTCRoutePlanPhaseIdle: {
            [self updateStatusText:[self localizedStringForKey:@"web_routing_not_started"] showPanel:NO];
        }
        break;
        case MTCRoutePlanPhaseCalculating: {
            [self updateStatusText:[self localizedStringForKey:@"web_requesting_route"] showPanel:NO];
        }
        break;
        case MTCRoutePlanPhaseReady: {
            self.routePanel.hidden = NO;
            [self reloadRouteSelector];
            [self updateSelectedRouteSummary];
            [self.routePanel updateSummaryText:self.configModel.statusText];
            [self.settingsSheet reloadData];
        }
        break;
        case MTCRoutePlanPhaseFailed: {
            [self updateStatusText:(self.routePlanController.state.error.localizedDescription ?: [self localizedStringForKey:@"web_routing_failed"]) showPanel:NO];
        }
        break;
        case MTCRoutePlanPhaseInvalidated: {
            self.routePanel.hidden = YES;
            [self.settingsSheet reloadData];
        }
        break;
    }
}

- (void)updateStatusText:(NSString *)text showPanel:(BOOL)showPanel {
    self.configModel.statusText = text ?: @"";
    self.routePanel.hidden = !showPanel;
    [self.routePanel updateSummaryText:self.configModel.statusText];
    [self.settingsSheet reloadData];
}

- (NSString *)waypointDescription {
    if (self.configModel.waypointCoordinates.count == 0) {
        return [self localizedStringForKey:@"overlay_none"];
    }
    NSMutableArray<NSString *> *descriptions =
        [NSMutableArray arrayWithCapacity:self.configModel.waypointCoordinates.count];
    for (NSValue *value in self.configModel.waypointCoordinates) {
        CLLocationCoordinate2D coordinate = [self coordinateFromValue:value];
        [descriptions addObject:[NSString stringWithFormat:@"%.6f,%.6f",
                                                           coordinate.latitude,
                                                           coordinate.longitude]];
    }
    return [descriptions componentsJoinedByString:@"\n"];
}

- (NSNumber *)strictNumberFromString:(NSString *)string {
    NSString *trimmed =
        [string stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (trimmed.length == 0) {
        return nil;
    }
    NSScanner *scanner = [NSScanner scannerWithString:trimmed];
    double value = 0.0;
    if (![scanner scanDouble:&value] || !scanner.isAtEnd) {
        return nil;
    }
    return @(value);
}

- (CLLocationCoordinate2D)coordinateFromLngLatString:(NSString *)string {
    NSArray<NSString *> *parts = [string componentsSeparatedByString:@","];
    if (parts.count != 2) {
        return kCLLocationCoordinate2DInvalid;
    }
    NSNumber *longitude = [self strictNumberFromString:parts.firstObject];
    NSNumber *latitude = [self strictNumberFromString:parts.lastObject];
    if (!longitude || !latitude) {
        return kCLLocationCoordinate2DInvalid;
    }
    CLLocationCoordinate2D coordinate =
        CLLocationCoordinate2DMake(latitude.doubleValue, longitude.doubleValue);
    return CLLocationCoordinate2DIsValid(coordinate)
        ? coordinate
        : kCLLocationCoordinate2DInvalid;
}

- (NSValue *)valueForCoordinate:(CLLocationCoordinate2D)coordinate {
    return [NSValue value:&coordinate withObjCType:@encode(CLLocationCoordinate2D)];
}

- (CLLocationCoordinate2D)coordinateFromValue:(NSValue *)value {
    CLLocationCoordinate2D coordinate = kCLLocationCoordinate2DInvalid;
    [value getValue:&coordinate];
    return coordinate;
}

#pragma mark -- multi-language

- (void)handleExampleSettingsAction {
    [self showRouteSettings];
}

- (void)demoLanguageDidChange {
    [self applyLocalizedTexts];
}

- (void)applyLocalizedTexts {
    self.title = [self localizedStringForKey:@"demo_title_MTCMapRouteViewController"];
    if (self.mapView) {
        self.mapView.mapLanguage = [self mapLanguageForDemoLanguage:self.demoLanguage];
    }
    [self.routePanel applyLocalizedTexts];
    [self refreshRoutePanelContent];
    if ([self isSettingsSheetVisible:ExampleSettingsSheetView.class]) {
        [self showRouteSettings];
    }
}

#pragma mark - Getter & Setter

@end
