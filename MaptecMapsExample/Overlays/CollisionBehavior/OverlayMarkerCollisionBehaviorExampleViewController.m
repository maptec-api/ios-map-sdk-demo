#import "OverlayMarkerCollisionBehaviorExampleViewController.h"

#import "ExampleSettingsSheetView.h"
#import "MTCExampleMapTestSupport.h"
#import "MTCExampleTestAccessibility.h"

#import <MaptecMapsKit/MaptecMapsKit.h>

#include <math.h>
#include <stdint.h>
#include <stdlib.h>

static CLLocationDegrees const OverlayMarkerCollisionBehaviorExampleSingaporeLatitude = 1.3521;
static CLLocationDegrees const OverlayMarkerCollisionBehaviorExampleSingaporeLongitude = 103.8198;
static double const OverlayMarkerCollisionBehaviorExampleDefaultZoomLevel = 14.0;
static double const OverlayMarkerCollisionBehaviorExampleRandomRadiusMeters = 1000.0;
static double const OverlayMarkerCollisionBehaviorExampleEarthRadiusMeters = 6371000.0;

@interface OverlayMarkerCollisionBehaviorExampleViewController () <MTCMapViewDelegate>
@property (nonatomic, strong) MTCMapView *mapView;
@property (nonatomic, strong) MTCExampleMapTestSupport *mapTestSupport;
//@property (nonatomic, strong) NSMutableArray<MTCMarker *> *markers;
@property (nonatomic, strong) NSMutableArray<MTCMarker *> *alwaysVisibleMarkers;
@property (nonatomic, strong) NSMutableArray<MTCMarker *> *optionalMarkers;
@property (nonatomic, strong) NSMutableArray<MTCMarker *> *alwaysVisibleAndHidesOptionalMarkers;
@property (nonatomic) MTCMarkerCollisionBehavior selectedCollisionBehavior;
@property (nonatomic, copy) NSString *zIndexText;

@end


//case MTCMarkerCollisionBehaviorOptional:
//    return MTCMarkerIconTypeYellowDot;
//case MTCMarkerCollisionBehaviorAlwaysVisibleAndHidesOptional:
//    return MTCMarkerIconTypeRedDot;
//case MTCMarkerCollisionBehaviorAlwaysVisible:
//default:
//    return MTCMarkerIconTypeBlueDot;

@implementation OverlayMarkerCollisionBehaviorExampleViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = UIColor.whiteColor;
    self.view.accessibilityIdentifier = MTCExampleTestAccessibilityOverlayMarkerCollisionBehaviorScreen;
    self.alwaysVisibleMarkers = [NSMutableArray array];
    self.optionalMarkers = [NSMutableArray array];
    self.alwaysVisibleAndHidesOptionalMarkers = [NSMutableArray array];
    self.selectedCollisionBehavior = MTCMarkerCollisionBehaviorAlwaysVisible;
    self.zIndexText = @"0";

    [self configureNavigationItems:NO];
    [self configureMapView];
    [self.mapView setCenterCoordinate:[self singaporeCoordinate]
                             zoomLevel:OverlayMarkerCollisionBehaviorExampleDefaultZoomLevel];
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
    self.mapTestSupport.overlayCountValueKey = MTCExampleTestAccessibilityMarkerCountValueKey;
    [self.mapTestSupport installOnHostView:self.view];
    [self.mapTestSupport syncOverlayCount:0];
}

#pragma mark - MTCMapViewDelegate

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

#pragma mark - Settings

- (void)showCollisionBehaviorSheet {
    __weak typeof(self) weakSelf = self;
    ExampleSettingsSheetView *sheet =
        [[ExampleSettingsSheetView alloc] initWithTitle:[self localizedStringForKey:@"common_settings_sheet_title"]
                                               sections:@[
            [ExampleSettingsSection sectionWithTitle:@"" items:@[
                [[ExampleSettingsItem listItemWithTitle:[self localizedStringForKey:@"overlay_marker_collision_behavior"]
                                                options:@[
                    [self localizedStringForKey:@"overlay_marker_collision_behavior_always_visible"],
                    [self localizedStringForKey:@"overlay_marker_collision_behavior_optional"],
                    [self localizedStringForKey:@"overlay_marker_collision_behavior_always_visible_hides_optional"],
                ] getter:^NSInteger {
                    return weakSelf.selectedCollisionBehavior;
                } setter:^(NSInteger index) {
                    weakSelf.selectedCollisionBehavior = (MTCMarkerCollisionBehavior)index;
                }] withAccessibilityIdentifier:@"marker_collision_behavior"],
                [[ExampleSettingsItem textItemWithTitle:@"zIndex"
                                             placeholder:nil
                                            keyboardType:UIKeyboardTypeNumbersAndPunctuation
                                                  getter:^NSString *{
                    return weakSelf.zIndexText;
                } setter:^(NSString *value) {
                    weakSelf.zIndexText = value;
                }] withAccessibilityIdentifier:@"marker_collision_z_index"],
                [[ExampleSettingsItem actionItemWithTitle:[self localizedStringForKey:@"overlay_add_b58c75"]
                                                   handler:^{
                    [weakSelf addMarkerWithCollisionBehavior:weakSelf.selectedCollisionBehavior];
                }] withAccessibilityIdentifier:@"marker_collision_add"],
                [[ExampleSettingsItem actionItemWithTitle:[self localizedStringForKey:@"overlay_clear_all_3358c6"]
                                                   handler:^{
                    [weakSelf clearAllMarkers];
                }] withAccessibilityIdentifier:MTCExampleTestAccessibilitySymbolBtnClearAll],
            ]],
        ]];
    [sheet showInView:self.view animated:YES];
}

#pragma mark - Markers

- (void)addMarkerWithCollisionBehavior:(MTCMarkerCollisionBehavior)collisionBehavior {
    MTCMarker *marker = [[MTCMarker alloc] initWithCoordinate:[self randomCoordinateAroundSingapore]];
    marker.collisionBehavior = collisionBehavior;
    marker.zIndex = self.zIndexText.integerValue;
    marker.style = [self markerStyleForCollisionBehavior:collisionBehavior];
//    [self.markers addObject:marker];
    switch (collisionBehavior) {
        case MTCMarkerCollisionBehaviorOptional: {
            [self.optionalMarkers addObject:marker];
            break;
        }
        case MTCMarkerCollisionBehaviorAlwaysVisibleAndHidesOptional: {
            [self.alwaysVisibleAndHidesOptionalMarkers addObject:marker];
            break;
        }
        case MTCMarkerCollisionBehaviorAlwaysVisible: {
            [self.alwaysVisibleMarkers addObject:marker];
            break;
        }
    }
    [self.mapView addOverlay:marker];
    [self.mapView setCenterCoordinate:marker.coordinate transition:[MTCCameraTransition easeWithDuration:0.25] completion:nil];
    [self.mapTestSupport syncOverlayCount:self.optionalMarkers.count + self.alwaysVisibleMarkers.count + self.alwaysVisibleAndHidesOptionalMarkers.count];
}

- (void)clearAllMarkers {
    NSMutableArray<MTCMarker *> *markers = [NSMutableArray array];
    [markers addObjectsFromArray:self.optionalMarkers];
    [markers addObjectsFromArray:self.alwaysVisibleMarkers];
    [markers addObjectsFromArray:self.alwaysVisibleAndHidesOptionalMarkers];
    
    [self.optionalMarkers removeAllObjects];
    [self.alwaysVisibleMarkers removeAllObjects];
    [self.alwaysVisibleAndHidesOptionalMarkers removeAllObjects];
    [self.mapView removeOverlays:markers];
    [self.mapTestSupport syncOverlayCount:0];
}

- (MTCMarkerStyle *)markerStyleForCollisionBehavior:(MTCMarkerCollisionBehavior)collisionBehavior {
    MTCMarkerStyle *style = [[MTCMarkerStyle alloc] init];
    style.icon.type = [self typeForCollisionBehavior:collisionBehavior];
    style.title.text = [self titleForCollisionBehavior:collisionBehavior];
    return style;
}

- (MTCMarkerIconType)typeForCollisionBehavior:(MTCMarkerCollisionBehavior)collisionBehavior {
    switch (collisionBehavior) {
        case MTCMarkerCollisionBehaviorOptional:
            return MTCMarkerIconTypeYellowDot;
        case MTCMarkerCollisionBehaviorAlwaysVisibleAndHidesOptional:
            return MTCMarkerIconTypeRedDot;
        case MTCMarkerCollisionBehaviorAlwaysVisible:
        default:
            return MTCMarkerIconTypeBlueDot;
    }
}

- (NSString *)titleForCollisionBehavior:(MTCMarkerCollisionBehavior)collisionBehavior {
    switch (collisionBehavior) {
        case MTCMarkerCollisionBehaviorOptional:{
            NSString *title = [self localizedStringForKey:@"overlay_marker_collision_behavior_optional"];
            return [NSString stringWithFormat:@"%@%@", title, @(self.optionalMarkers.count)];
        }
        case MTCMarkerCollisionBehaviorAlwaysVisibleAndHidesOptional: {
            
            NSString *title = [self localizedStringForKey:@"overlay_marker_collision_behavior_always_visible_hides_optional"];
            return [NSString stringWithFormat:@"%@%@", title, @(self.alwaysVisibleAndHidesOptionalMarkers.count)];
        }
        case MTCMarkerCollisionBehaviorAlwaysVisible:
        default: {
            NSString *title = [self localizedStringForKey:@"overlay_marker_collision_behavior_always_visible"];
            return [NSString stringWithFormat:@"%@%@", title, @(self.alwaysVisibleMarkers.count)];
        }
            
    }
}

#pragma mark - Coordinates

- (CLLocationCoordinate2D)singaporeCoordinate {
    return CLLocationCoordinate2DMake(OverlayMarkerCollisionBehaviorExampleSingaporeLatitude,
                                      OverlayMarkerCollisionBehaviorExampleSingaporeLongitude);
}

- (CLLocationCoordinate2D)randomCoordinateAroundSingapore {
    const double pi = acos(-1.0);
    const double latitudeRadians = [self singaporeCoordinate].latitude * pi / 180.0;
    const double distance = sqrt((double)arc4random() / (double)UINT32_MAX) *
                            OverlayMarkerCollisionBehaviorExampleRandomRadiusMeters;
    const double bearing = ((double)arc4random() / (double)UINT32_MAX) * 2.0 * pi;
    const double angularDistance = distance / OverlayMarkerCollisionBehaviorExampleEarthRadiusMeters;
    const double latitude = latitudeRadians;
    const double longitude = [self singaporeCoordinate].longitude * pi / 180.0;

    const double randomLatitude = asin(sin(latitude) * cos(angularDistance) +
                                       cos(latitude) * sin(angularDistance) * cos(bearing));
    const double randomLongitude = longitude +
                                   atan2(sin(bearing) * sin(angularDistance) * cos(latitude),
                                         cos(angularDistance) - sin(latitude) * sin(randomLatitude));
    return CLLocationCoordinate2DMake(randomLatitude * 180.0 / pi,
                                      randomLongitude * 180.0 / pi);
}

#pragma mark - Localization

- (void)handleExampleSettingsAction {
    [self showCollisionBehaviorSheet];
}

- (void)demoLanguageDidChange {
    [self applyLocalizedTexts];
}

- (void)applyLocalizedTexts {
    self.title = [self localizedStringForKey:@"demo_title_OverlayMarkerCollisionBehaviorExampleViewController"];
    if (self.mapView) {
        self.mapView.mapLanguage = [self mapLanguageForDemoLanguage:self.demoLanguage];
    }
    if ([self isSettingsSheetVisible:ExampleSettingsSheetView.class]) {
        [self showCollisionBehaviorSheet];
    }
}

- (void)mapView:(MTCMapView *)mapView didTapOverlay:(id<MTCOverlay>)overlay {
    if ([overlay isKindOfClass:[MTCMarker class]]) {
        MTCMarker *marker = (MTCMarker *)overlay;
        NSLog(@"marker zIndex: %@", @(marker.zIndex));
    }
}

@end
 
