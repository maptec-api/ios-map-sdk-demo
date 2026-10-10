#import "OverlayZoomScalingMarkerExampleViewController.h"

#import "ExampleSettingsSheetView.h"
#import "MTCExampleMapTestSupport.h"
#import "MTCExampleTestAccessibility.h"

#import <MaptecMapsKit/MaptecMapsKit.h>
#import <QuartzCore/QuartzCore.h>

#include <float.h>
#include <math.h>

static CLLocationDegrees const OverlayZoomScalingMarkerExampleSingaporeLatitude = 1.3048264556208515;
static CLLocationDegrees const OverlayZoomScalingMarkerExampleSingaporeLongitude = 103.83052199958921;
static double const OverlayZoomScalingMarkerExampleDefaultZoomLevel = 13.0;
static NSInteger const OverlayZoomScalingMarkerExampleZoomScaleFramesPerSecond = 10;
static double const OverlayZoomScalingMarkerExampleZoomScaleStep = 0.12;
static NSString * const OverlayZoomScalingMarkerExampleMapBundleName = @"MTCMap";
static NSString * const OverlayZoomScalingMarkerExampleImagesDirectoryName = @"images";

static double OverlayZoomScalingMarkerExampleClampDouble(double value, double minimum, double maximum) {
    return fmin(fmax(value, minimum), maximum);
}

static double OverlayZoomScalingMarkerExampleDoubleFromString(NSString *value, double fallback, double minimum, double maximum) {
    NSString *trimmedValue = [value stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (trimmedValue.length == 0) {
        return fallback;
    }

    double parsedValue = 0.0;
    NSScanner *scanner = [NSScanner scannerWithString:trimmedValue];
    if (![scanner scanDouble:&parsedValue]) {
        return fallback;
    }
    return OverlayZoomScalingMarkerExampleClampDouble(parsedValue, minimum, maximum);
}

static NSString *OverlayZoomScalingMarkerExampleNormalizeHexString(NSString *value, NSString *fallback) {
    NSString *candidate = [[value ?: @"" stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] uppercaseString];
    if ([candidate hasPrefix:@"#"]) {
        candidate = [candidate substringFromIndex:1];
    }
    if (candidate.length != 6) {
        return fallback;
    }

    unsigned int rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:candidate];
    if (![scanner scanHexInt:&rgbValue] || !scanner.isAtEnd) {
        return fallback;
    }
    return [@"#" stringByAppendingString:candidate];
}

static UIColor *OverlayZoomScalingMarkerExampleColorFromHexString(NSString *value, NSString *fallback) {
    NSString *hexString = OverlayZoomScalingMarkerExampleNormalizeHexString(value, fallback);
    unsigned int rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:[hexString substringFromIndex:1]];
    if (![scanner scanHexInt:&rgbValue]) {
        return UIColor.blackColor;
    }

    return [UIColor colorWithRed:((rgbValue >> 16) & 0xFF) / 255.0
                           green:((rgbValue >> 8) & 0xFF) / 255.0
                            blue:(rgbValue & 0xFF) / 255.0
                           alpha:1.0];
}

static NSString *OverlayZoomScalingMarkerExampleHexStringFromColor(UIColor *color, NSString *fallback) {
    CGFloat red = 0.0;
    CGFloat green = 0.0;
    CGFloat blue = 0.0;
    CGFloat alpha = 0.0;
    if (![color getRed:&red green:&green blue:&blue alpha:&alpha]) {
        return fallback;
    }

    NSInteger redValue = (NSInteger)lrint(OverlayZoomScalingMarkerExampleClampDouble(red, 0.0, 1.0) * 255.0);
    NSInteger greenValue = (NSInteger)lrint(OverlayZoomScalingMarkerExampleClampDouble(green, 0.0, 1.0) * 255.0);
    NSInteger blueValue = (NSInteger)lrint(OverlayZoomScalingMarkerExampleClampDouble(blue, 0.0, 1.0) * 255.0);
    return [NSString stringWithFormat:@"#%02lX%02lX%02lX", (long)redValue, (long)greenValue, (long)blueValue];
}

@interface OverlayZoomScalingMarkerExampleFormState : NSObject <NSCopying>
@property (nonatomic) double latitude;
@property (nonatomic) double longitude;
@property (nonatomic, copy) NSString *title;
@property (nonatomic) double titleFontSize;
@property (nonatomic, copy) NSString *titleColorHex;
@property (nonatomic) NSInteger titleColorIndex;
@property (nonatomic, copy) NSString *titleStrokeColorHex;
@property (nonatomic) NSInteger titleStrokeColorIndex;
@property (nonatomic) double titleStrokeWidth;
@property (nonatomic) double titleAnchorX;
@property (nonatomic) double titleAnchorY;
@property (nonatomic) double titleOffsetX;
@property (nonatomic) double titleOffsetY;
@property (nonatomic) double titleRotation;
@property (nonatomic) double titleOpacity;
@property (nonatomic) double opacity;
@property (nonatomic) double anchorX;
@property (nonatomic) double anchorY;
@property (nonatomic) double iconOffsetX;
@property (nonatomic) double iconOffsetY;
@property (nonatomic) double iconRotation;
@property (nonatomic, copy) NSString *selectedTitle;
@property (nonatomic) double selectedTitleFontSize;
@property (nonatomic, copy) NSString *selectedTitleColorHex;
@property (nonatomic) NSInteger selectedTitleColorIndex;
@property (nonatomic, copy) NSString *selectedTitleStrokeColorHex;
@property (nonatomic) NSInteger selectedTitleStrokeColorIndex;
@property (nonatomic) double selectedTitleStrokeWidth;
@property (nonatomic) double selectedTitleAnchorX;
@property (nonatomic) double selectedTitleAnchorY;
@property (nonatomic) double selectedTitleOffsetX;
@property (nonatomic) double selectedTitleOffsetY;
@property (nonatomic) double selectedTitleRotation;
@property (nonatomic) double selectedTitleOpacity;
@property (nonatomic) double selectedOpacity;
@property (nonatomic) double selectedAnchorX;
@property (nonatomic) double selectedAnchorY;
@property (nonatomic) double selectedIconOffsetX;
@property (nonatomic) double selectedIconOffsetY;
@property (nonatomic) double selectedIconRotation;
@property (nonatomic) BOOL selected;
@property (nonatomic) BOOL scalesWithZoom;
@property (nonatomic) double maximumZoomScale;
@property (nonatomic) double minimumZoomScale;
@property (nonatomic) double minimumZoomLevel;
@property (nonatomic) double maximumZoomLevel;
@property (nonatomic) NSInteger iconTypeIndex;
@property (nonatomic) NSInteger selectedIconTypeIndex;
@end

@implementation OverlayZoomScalingMarkerExampleFormState

- (id)copyWithZone:(NSZone *)zone {
    OverlayZoomScalingMarkerExampleFormState *state = [[[self class] allocWithZone:zone] init];
    state.latitude = self.latitude;
    state.longitude = self.longitude;
    state.title = self.title;
    state.titleFontSize = self.titleFontSize;
    state.titleColorHex = self.titleColorHex;
    state.titleColorIndex = self.titleColorIndex;
    state.titleStrokeColorHex = self.titleStrokeColorHex;
    state.titleStrokeColorIndex = self.titleStrokeColorIndex;
    state.titleStrokeWidth = self.titleStrokeWidth;
    state.titleAnchorX = self.titleAnchorX;
    state.titleAnchorY = self.titleAnchorY;
    state.titleOffsetX = self.titleOffsetX;
    state.titleOffsetY = self.titleOffsetY;
    state.titleRotation = self.titleRotation;
    state.titleOpacity = self.titleOpacity;
    state.opacity = self.opacity;
    state.anchorX = self.anchorX;
    state.anchorY = self.anchorY;
    state.iconOffsetX = self.iconOffsetX;
    state.iconOffsetY = self.iconOffsetY;
    state.iconRotation = self.iconRotation;
    state.selectedTitle = self.selectedTitle;
    state.selectedTitleFontSize = self.selectedTitleFontSize;
    state.selectedTitleColorHex = self.selectedTitleColorHex;
    state.selectedTitleColorIndex = self.selectedTitleColorIndex;
    state.selectedTitleStrokeColorHex = self.selectedTitleStrokeColorHex;
    state.selectedTitleStrokeColorIndex = self.selectedTitleStrokeColorIndex;
    state.selectedTitleStrokeWidth = self.selectedTitleStrokeWidth;
    state.selectedTitleAnchorX = self.selectedTitleAnchorX;
    state.selectedTitleAnchorY = self.selectedTitleAnchorY;
    state.selectedTitleOffsetX = self.selectedTitleOffsetX;
    state.selectedTitleOffsetY = self.selectedTitleOffsetY;
    state.selectedTitleRotation = self.selectedTitleRotation;
    state.selectedTitleOpacity = self.selectedTitleOpacity;
    state.selectedOpacity = self.selectedOpacity;
    state.selectedAnchorX = self.selectedAnchorX;
    state.selectedAnchorY = self.selectedAnchorY;
    state.selectedIconOffsetX = self.selectedIconOffsetX;
    state.selectedIconOffsetY = self.selectedIconOffsetY;
    state.selectedIconRotation = self.selectedIconRotation;
    state.selected = self.selected;
    state.scalesWithZoom = self.scalesWithZoom;
    state.maximumZoomScale = self.maximumZoomScale;
    state.minimumZoomScale = self.minimumZoomScale;
    state.minimumZoomLevel = self.minimumZoomLevel;
    state.maximumZoomLevel = self.maximumZoomLevel;
    state.iconTypeIndex = self.iconTypeIndex;
    state.selectedIconTypeIndex = self.selectedIconTypeIndex;
    return state;
}

@end

@protocol OverlayZoomScalingMarkerExampleDisplayLinkTargetDelegate <NSObject>
- (void)handleZoomScaleDisplayLink:(CADisplayLink *)displayLink;
@end

@interface OverlayZoomScalingMarkerExampleDisplayLinkTarget : NSObject
@property (nonatomic, weak) id<OverlayZoomScalingMarkerExampleDisplayLinkTargetDelegate> target;
- (instancetype)initWithTarget:(id<OverlayZoomScalingMarkerExampleDisplayLinkTargetDelegate>)target;
- (void)displayLinkDidFire:(CADisplayLink *)displayLink;
@end

@interface OverlayZoomScalingMarkerExampleViewController () <MTCMapViewDelegate, OverlayZoomScalingMarkerExampleDisplayLinkTargetDelegate>
@property (nonatomic, strong) MTCMapView *mapView;
@property (nonatomic, strong) NSMutableArray<MTCMarker *> *markers;
@property (nonatomic, strong) NSMapTable<MTCMarker *, OverlayZoomScalingMarkerExampleFormState *> *markerBaseStates;
@property (nonatomic, strong) NSMapTable<MTCMarker *, NSNumber *> *markerAppliedZoomScales;
@property (nonatomic, strong) OverlayZoomScalingMarkerExampleFormState *formState;
@property (nonatomic, weak) MTCMarker *editingMarker;
@property (nonatomic, strong) CADisplayLink *zoomScaleDisplayLink;
@property (nonatomic, strong) OverlayZoomScalingMarkerExampleDisplayLinkTarget *zoomScaleDisplayLinkTarget;
@property (nonatomic) double pendingZoomLevel;
@property (nonatomic) BOOL hasPendingZoomScaleUpdate;
@property (nonatomic, strong) MTCExampleMapTestSupport *mapTestSupport;
@end

@implementation OverlayZoomScalingMarkerExampleDisplayLinkTarget

- (instancetype)initWithTarget:(id<OverlayZoomScalingMarkerExampleDisplayLinkTargetDelegate>)target {
    self = [super init];
    if (self) {
        _target = target;
    }
    return self;
}

- (void)displayLinkDidFire:(CADisplayLink *)displayLink {
    [self.target handleZoomScaleDisplayLink:displayLink];
}

@end

@implementation OverlayZoomScalingMarkerExampleViewController

- (void)dealloc {
    [self.zoomScaleDisplayLink invalidate];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = UIColor.whiteColor;
    self.view.accessibilityIdentifier = @"OverlayZoomScalingMarkerExampleViewController.screen";
    self.markers = [NSMutableArray array];
    self.markerBaseStates = [NSMapTable weakToStrongObjectsMapTable];
    self.markerAppliedZoomScales = [NSMapTable weakToStrongObjectsMapTable];

    [self configureNavigationItems:NO];
    [self configureMapView];
    [self addInitialMarker];
    [self applyLocalizedTexts];
}

#pragma mark - Setup

- (void)configureMapView {
    self.mapTestSupport = [[MTCExampleMapTestSupport alloc] init];
    self.mapTestSupport.overlayCountValueKey = MTCExampleTestAccessibilityMarkerCountValueKey;
    self.mapTestSupport.overlayPresenceIdentifier = MTCExampleTestAccessibilitySymbolLayerHasMarkers;
    [self.mapTestSupport installOnHostView:self.view];

    self.mapView = [[MTCMapView alloc] initWithFrame:self.view.bounds];
    self.mapView.delegate = self;
    self.mapView.uiSettings.zoomLevelVisible = YES;
    self.mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.mapView];
}

#pragma mark - Delegate

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

- (void)addInitialMarker {
    CLLocationCoordinate2D coordinate = [self singaporeCoordinate];
    OverlayZoomScalingMarkerExampleFormState *state = [self defaultMarkerStateAtCoordinate:coordinate];
    [self addMarkerWithState:state recenter:NO];
    [self.mapView setCenterCoordinate:coordinate zoomLevel:OverlayZoomScalingMarkerExampleDefaultZoomLevel];
}

#pragma mark - Sheets

- (void)showMarkerSheet {
    MTCMarker *marker = [self currentMarker];
    self.editingMarker = marker;
    self.formState = marker ? [self stateFromMarker:marker] : [self defaultMarkerStateAtCoordinate:[self currentMapCenterCoordinate]];

    __block ExampleSettingsSheetView *sheet = nil;
    sheet = [[ExampleSettingsSheetView alloc] initWithTitle:[self localizedStringForKey:@"common_settings_sheet_title"]
                                                   sections:[self sectionsForState:self.formState
                                                                       actionTitle:[self localizedStringForKey:@"overlay_add_b58c75"]
                                                                            action:^{
        [self replaceMarkersWithState:[self.formState copy] recenter:YES];
        [sheet dismissAnimated:YES];
    } removalAction:^{
        [self clearAllMarkers];
        [sheet dismissAnimated:YES];
    }]];
    [sheet showInView:self.view animated:YES];
}

- (NSArray<ExampleSettingsSection *> *)sectionsForState:(OverlayZoomScalingMarkerExampleFormState *)state
                                            actionTitle:(NSString *)actionTitle
                                                 action:(dispatch_block_t)action
                                          removalAction:(dispatch_block_t)removalAction {
    __weak typeof(self) weakSelf = self;
    __weak OverlayZoomScalingMarkerExampleFormState *weakState = state;
    void (^syncState)(void) = ^{
        [weakSelf syncEditingMarkerForState:weakState];
    };
    NSArray<ExampleSettingsListGroup *> *iconGroups = @[
        [ExampleSettingsListGroup groupWithTitle:[self localizedStringForKey:@"overlay_built_in_styles"] options:[self markerIconTitles]]
    ];

    return @[
        [ExampleSettingsSection sectionWithTitle:[self localizedStringForKey:@"overlay_position"] items:@[
            [ExampleSettingsItem textItemWithTitle:[self localizedStringForKey:@"overlay_coordinate"]
                                       placeholder:@"lat, lng"
                                      keyboardType:UIKeyboardTypeNumbersAndPunctuation
                                            getter:^NSString *{
                return [weakSelf coordinateTextForState:weakState];
            } setter:^(NSString *value) {
                [weakSelf updateCoordinateWithText:value state:weakState];
                syncState();
            }],
        ]],
        [ExampleSettingsSection collapsibleSectionWithTitle:@"icon"
                                         initiallyCollapsed:YES
                                                      items:@[]
                                              childSections:@[
            [ExampleSettingsSection collapsibleSectionWithTitle:[self localizedStringForKey:@"overlay_default_state"]
                                             initiallyCollapsed:YES
                                                          items:@[
                [ExampleSettingsItem groupedListItemWithTitle:[self localizedStringForKey:@"overlay_icon_type"]
                                                       groups:iconGroups
                                                   popupSize:CGSizeMake(260.0, 240.0)
                                                      getter:^NSInteger { return weakState.iconTypeIndex; }
                                                      setter:^(NSInteger index) {
                    weakState.iconTypeIndex = index;
                    syncState();
                }],
                [ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"overlay_icon_opacity"]
                                                 minimum:0.0
                                                 maximum:1.0
                                                    step:0.05
                                                  getter:^double { return weakState.opacity; }
                                                  setter:^(double value) {
                    weakState.opacity = value;
                    syncState();
                } formatter:^NSString *(double value) {
                    return [weakSelf formatUnitValue:value];
                }],
                [ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"overlay_icon_anchor_x"]
                                                 minimum:0.0
                                                 maximum:1.0
                                                    step:0.05
                                                  getter:^double { return weakState.anchorX; }
                                                  setter:^(double value) {
                    weakState.anchorX = value;
                    syncState();
                } formatter:^NSString *(double value) {
                    return [weakSelf formatUnitValue:value];
                }],
                [ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"overlay_icon_anchor_y"]
                                                 minimum:0.0
                                                 maximum:1.0
                                                    step:0.05
                                                  getter:^double { return weakState.anchorY; }
                                                  setter:^(double value) {
                    weakState.anchorY = value;
                    syncState();
                } formatter:^NSString *(double value) {
                    return [weakSelf formatUnitValue:value];
                }],
                [ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"overlay_icon_offset_x"]
                                                 minimum:-100.0
                                                 maximum:100.0
                                                    step:1.0
                                                  getter:^double { return weakState.iconOffsetX; }
                                                  setter:^(double value) {
                    weakState.iconOffsetX = value;
                    syncState();
                } formatter:^NSString *(double value) {
                    return [weakSelf formatPointValue:value];
                }],
                [ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"overlay_icon_offset_y"]
                                                 minimum:-100.0
                                                 maximum:100.0
                                                    step:1.0
                                                  getter:^double { return weakState.iconOffsetY; }
                                                  setter:^(double value) {
                    weakState.iconOffsetY = value;
                    syncState();
                } formatter:^NSString *(double value) {
                    return [weakSelf formatPointValue:value];
                }],
                [ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"overlay_icon_rotation"]
                                                 minimum:-180.0
                                                 maximum:180.0
                                                    step:1.0
                                                  getter:^double { return weakState.iconRotation; }
                                                  setter:^(double value) {
                    weakState.iconRotation = value;
                    syncState();
                } formatter:^NSString *(double value) {
                    return [NSString stringWithFormat:@"%.0f°", value];
                }],
            ]],
            [ExampleSettingsSection collapsibleSectionWithTitle:[self localizedStringForKey:@"overlay_selected_state"]
                                             initiallyCollapsed:YES
                                                          items:@[
                [ExampleSettingsItem boolItemWithTitle:[self localizedStringForKey:@"overlay_selected"]
                                                getter:^BOOL { return weakState.selected; }
                                                setter:^(BOOL value) {
                    weakState.selected = value;
                    syncState();
                }],
                [ExampleSettingsItem groupedListItemWithTitle:[self localizedStringForKey:@"overlay_selected_icon_type"]
                                                       groups:iconGroups
                                                   popupSize:CGSizeMake(260.0, 240.0)
                                                      getter:^NSInteger { return weakState.selectedIconTypeIndex; }
                                                      setter:^(NSInteger index) {
                    weakState.selectedIconTypeIndex = index;
                    syncState();
                }],
                [ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"overlay_selected_opacity"]
                                                 minimum:0.0
                                                 maximum:1.0
                                                    step:0.05
                                                  getter:^double { return weakState.selectedOpacity; }
                                                  setter:^(double value) {
                    weakState.selectedOpacity = value;
                    syncState();
                } formatter:^NSString *(double value) {
                    return [weakSelf formatUnitValue:value];
                }],
                [ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"overlay_selected_anchor_x"]
                                                 minimum:0.0
                                                 maximum:1.0
                                                    step:0.05
                                                  getter:^double { return weakState.selectedAnchorX; }
                                                  setter:^(double value) {
                    weakState.selectedAnchorX = value;
                    syncState();
                } formatter:^NSString *(double value) {
                    return [weakSelf formatUnitValue:value];
                }],
                [ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"overlay_selected_anchor_y"]
                                                 minimum:0.0
                                                 maximum:1.0
                                                    step:0.05
                                                  getter:^double { return weakState.selectedAnchorY; }
                                                  setter:^(double value) {
                    weakState.selectedAnchorY = value;
                    syncState();
                } formatter:^NSString *(double value) {
                    return [weakSelf formatUnitValue:value];
                }],
                [ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"overlay_selected_offset_x"]
                                                 minimum:-100.0
                                                 maximum:100.0
                                                    step:1.0
                                                  getter:^double { return weakState.selectedIconOffsetX; }
                                                  setter:^(double value) {
                    weakState.selectedIconOffsetX = value;
                    syncState();
                } formatter:^NSString *(double value) {
                    return [weakSelf formatPointValue:value];
                }],
                [ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"overlay_selected_offset_y"]
                                                 minimum:-100.0
                                                 maximum:100.0
                                                    step:1.0
                                                  getter:^double { return weakState.selectedIconOffsetY; }
                                                  setter:^(double value) {
                    weakState.selectedIconOffsetY = value;
                    syncState();
                } formatter:^NSString *(double value) {
                    return [weakSelf formatPointValue:value];
                }],
                [ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"overlay_selected_rotation"]
                                                 minimum:-180.0
                                                 maximum:180.0
                                                    step:1.0
                                                  getter:^double { return weakState.selectedIconRotation; }
                                                  setter:^(double value) {
                    weakState.selectedIconRotation = value;
                    syncState();
                } formatter:^NSString *(double value) {
                    return [NSString stringWithFormat:@"%.0f°", value];
                }],
            ]],
        ]],
        [ExampleSettingsSection collapsibleSectionWithTitle:@"title"
                                         initiallyCollapsed:YES
                                                      items:@[]
                                              childSections:@[
            [ExampleSettingsSection collapsibleSectionWithTitle:[self localizedStringForKey:@"overlay_default_state"]
                                             initiallyCollapsed:YES
                                                          items:[self titleItemsForState:state selected:NO]],
            [ExampleSettingsSection collapsibleSectionWithTitle:[self localizedStringForKey:@"overlay_selected_state"]
                                             initiallyCollapsed:YES
                                                          items:[self titleItemsForState:state selected:YES]],
        ]],
        [ExampleSettingsSection collapsibleSectionWithTitle:[self localizedStringForKey:@"overlay_scale_with_zoom"]
                                         initiallyCollapsed:YES
                                                      items:@[
            [ExampleSettingsItem boolItemWithTitle:[self localizedStringForKey:@"overlay_scale_with_zoom"]
                                            getter:^BOOL { return weakState.scalesWithZoom; }
                                            setter:^(BOOL value) {
                weakState.scalesWithZoom = value;
                syncState();
            }],
            [[ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"overlay_max_scale"]
                                              minimum:0.1
                                              maximum:5.0
                                                 step:0.1
                                               getter:^double { return weakState.maximumZoomScale; }
                                               setter:^(double value) {
                weakState.maximumZoomScale = value;
                syncState();
            } formatter:^NSString *(double value) {
                return [weakSelf formatScaleValue:value];
            }] enabledWhen:^BOOL {
                return weakState.scalesWithZoom;
            }],
            [[ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"overlay_min_scale"]
                                              minimum:0.1
                                              maximum:5.0
                                                 step:0.1
                                               getter:^double { return weakState.minimumZoomScale; }
                                               setter:^(double value) {
                weakState.minimumZoomScale = value;
                syncState();
            } formatter:^NSString *(double value) {
                return [weakSelf formatScaleValue:value];
            }] enabledWhen:^BOOL {
                return weakState.scalesWithZoom;
            }],
            [[ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"overlay_min_zoom"]
                                              minimum:0.0
                                              maximum:22.0
                                                 step:0.5
                                               getter:^double { return weakState.minimumZoomLevel; }
                                               setter:^(double value) {
                weakState.minimumZoomLevel = value;
                syncState();
            } formatter:^NSString *(double value) {
                return [weakSelf formatZoomLevelValue:value];
            }] enabledWhen:^BOOL {
                return weakState.scalesWithZoom;
            }],
            [[ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"overlay_max_zoom"]
                                              minimum:0.0
                                              maximum:22.0
                                                 step:0.5
                                               getter:^double { return weakState.maximumZoomLevel; }
                                               setter:^(double value) {
                weakState.maximumZoomLevel = value;
                syncState();
            } formatter:^NSString *(double value) {
                return [weakSelf formatZoomLevelValue:value];
            }] enabledWhen:^BOOL {
                return weakState.scalesWithZoom;
            }],
        ]],
        [ExampleSettingsSection sectionWithTitle:@"" items:@[
            [[ExampleSettingsItem actionItemWithTitle:actionTitle handler:action]
             withAccessibilityIdentifier:MTCExampleTestAccessibilitySymbolBtnAddMarker],
            [[ExampleSettingsItem actionItemWithTitle:[self localizedStringForKey:@"overlay_clear_all_3358c6"] handler:removalAction]
             withAccessibilityIdentifier:MTCExampleTestAccessibilitySymbolBtnClearAll],
        ]],
    ];
}

- (NSArray<ExampleSettingsItem *> *)titleItemsForState:(OverlayZoomScalingMarkerExampleFormState *)state
                                              selected:(BOOL)selected {
    __weak typeof(self) weakSelf = self;
    __weak OverlayZoomScalingMarkerExampleFormState *weakState = state;
    void (^syncState)(void) = ^{
        [weakSelf syncEditingMarkerForState:weakState];
    };
    NSArray<NSString *> *colorOptions = [self titleColorOptions];
    CGSize colorPopupSize = CGSizeMake(260.0, 320.0);
    NSString *textTitle = selected ? [self localizedStringForKey:@"overlay_selected_title"] : [self localizedStringForKey:@"overlay_title"];
    NSString *fontSizeTitle = selected ? [self localizedStringForKey:@"overlay_selected_font_size"] : [self localizedStringForKey:@"overlay_font_size"];
    NSString *colorTitle = selected ? [self localizedStringForKey:@"overlay_selected_text_color"] : [self localizedStringForKey:@"overlay_text_color"];
    NSString *strokeColorTitle = selected ? [self localizedStringForKey:@"overlay_selected_stroke_color"] : [self localizedStringForKey:@"overlay_stroke_color"];
    NSString *strokeWidthTitle = selected ? [self localizedStringForKey:@"overlay_selected_stroke_width"] : [self localizedStringForKey:@"overlay_stroke_width"];
    NSString *anchorXTitle = selected ? [self localizedStringForKey:@"overlay_selected_anchor_x"] : [self localizedStringForKey:@"overlay_anchor_x"];
    NSString *anchorYTitle = selected ? [self localizedStringForKey:@"overlay_selected_anchor_y"] : [self localizedStringForKey:@"overlay_anchor_y"];
    NSString *offsetXTitle = selected ? [self localizedStringForKey:@"overlay_selected_offset_x"] : [self localizedStringForKey:@"overlay_offset_x"];
    NSString *offsetYTitle = selected ? [self localizedStringForKey:@"overlay_selected_offset_y"] : [self localizedStringForKey:@"overlay_offset_y"];
    NSString *rotationTitle = selected ? [self localizedStringForKey:@"overlay_selected_rotation"] : [self localizedStringForKey:@"overlay_rotation_76815c"];
    NSString *opacityTitle = selected ? [self localizedStringForKey:@"overlay_selected_opacity"] : [self localizedStringForKey:@"overlay_opacity_34dac4"];

    return @[
        [ExampleSettingsItem textItemWithTitle:textTitle
                                   placeholder:[self localizedStringForKey:@"overlay_leave_empty_to_hide"]
                                  keyboardType:UIKeyboardTypeDefault
                                        getter:^NSString *{
            return selected ? (weakState.selectedTitle ?: @"") : (weakState.title ?: @"");
        } setter:^(NSString *value) {
            if (selected) {
                weakState.selectedTitle = value ?: @"";
            } else {
                weakState.title = value ?: @"";
            }
            syncState();
        }],
        [ExampleSettingsItem sliderItemWithTitle:fontSizeTitle
                                         minimum:8.0
                                         maximum:36.0
                                            step:1.0
                                          getter:^double {
            return selected ? weakState.selectedTitleFontSize : weakState.titleFontSize;
        } setter:^(double value) {
            if (selected) {
                weakState.selectedTitleFontSize = value;
            } else {
                weakState.titleFontSize = value;
            }
            syncState();
        } formatter:^NSString *(double value) {
            return [NSString stringWithFormat:@"%.0f pt", value];
        }],
        [ExampleSettingsItem colorInputItemWithTitle:colorTitle
                                         placeholder:@"#000000"
                                             options:colorOptions
                                      optionHexValues:colorOptions
                                           popupSize:colorPopupSize
                                              getter:^NSString *{
            return selected ? (weakState.selectedTitleColorHex ?: @"") : (weakState.titleColorHex ?: @"");
        } setter:^(NSString *value) {
            NSString *hexValue = OverlayZoomScalingMarkerExampleNormalizeHexString(value, @"#000000");
            if (selected) {
                weakState.selectedTitleColorHex = hexValue;
                weakState.selectedTitleColorIndex = [weakSelf indexForTitleColorHex:hexValue fallbackIndex:weakState.selectedTitleColorIndex];
            } else {
                weakState.titleColorHex = hexValue;
                weakState.titleColorIndex = [weakSelf indexForTitleColorHex:hexValue fallbackIndex:weakState.titleColorIndex];
            }
            syncState();
        } optionGetter:^NSInteger {
            return selected ? weakState.selectedTitleColorIndex : weakState.titleColorIndex;
        } optionSetter:^(NSInteger index) {
            if (index < 0 || index >= (NSInteger)colorOptions.count) {
                return;
            }
            if (selected) {
                weakState.selectedTitleColorHex = colorOptions[index];
                weakState.selectedTitleColorIndex = index;
            } else {
                weakState.titleColorHex = colorOptions[index];
                weakState.titleColorIndex = index;
            }
            syncState();
        }],
        [ExampleSettingsItem colorInputItemWithTitle:strokeColorTitle
                                         placeholder:@"#FFFFFF"
                                             options:colorOptions
                                      optionHexValues:colorOptions
                                           popupSize:colorPopupSize
                                              getter:^NSString *{
            return selected ? (weakState.selectedTitleStrokeColorHex ?: @"") : (weakState.titleStrokeColorHex ?: @"");
        } setter:^(NSString *value) {
            NSString *hexValue = OverlayZoomScalingMarkerExampleNormalizeHexString(value, @"#FFFFFF");
            if (selected) {
                weakState.selectedTitleStrokeColorHex = hexValue;
                weakState.selectedTitleStrokeColorIndex = [weakSelf indexForTitleColorHex:hexValue fallbackIndex:weakState.selectedTitleStrokeColorIndex];
            } else {
                weakState.titleStrokeColorHex = hexValue;
                weakState.titleStrokeColorIndex = [weakSelf indexForTitleColorHex:hexValue fallbackIndex:weakState.titleStrokeColorIndex];
            }
            syncState();
        } optionGetter:^NSInteger {
            return selected ? weakState.selectedTitleStrokeColorIndex : weakState.titleStrokeColorIndex;
        } optionSetter:^(NSInteger index) {
            if (index < 0 || index >= (NSInteger)colorOptions.count) {
                return;
            }
            if (selected) {
                weakState.selectedTitleStrokeColorHex = colorOptions[index];
                weakState.selectedTitleStrokeColorIndex = index;
            } else {
                weakState.titleStrokeColorHex = colorOptions[index];
                weakState.titleStrokeColorIndex = index;
            }
            syncState();
        }],
        [ExampleSettingsItem sliderItemWithTitle:strokeWidthTitle
                                         minimum:0.0
                                         maximum:8.0
                                            step:0.5
                                          getter:^double {
            return selected ? weakState.selectedTitleStrokeWidth : weakState.titleStrokeWidth;
        } setter:^(double value) {
            if (selected) {
                weakState.selectedTitleStrokeWidth = value;
            } else {
                weakState.titleStrokeWidth = value;
            }
            syncState();
        } formatter:^NSString *(double value) {
            return [NSString stringWithFormat:@"%.1f pt", value];
        }],
        [ExampleSettingsItem sliderItemWithTitle:anchorXTitle
                                         minimum:0.0
                                         maximum:1.0
                                            step:0.05
                                          getter:^double {
            return selected ? weakState.selectedTitleAnchorX : weakState.titleAnchorX;
        } setter:^(double value) {
            if (selected) {
                weakState.selectedTitleAnchorX = value;
            } else {
                weakState.titleAnchorX = value;
            }
            syncState();
        } formatter:^NSString *(double value) {
            return [weakSelf formatUnitValue:value];
        }],
        [ExampleSettingsItem sliderItemWithTitle:anchorYTitle
                                         minimum:0.0
                                         maximum:1.0
                                            step:0.05
                                          getter:^double {
            return selected ? weakState.selectedTitleAnchorY : weakState.titleAnchorY;
        } setter:^(double value) {
            if (selected) {
                weakState.selectedTitleAnchorY = value;
            } else {
                weakState.titleAnchorY = value;
            }
            syncState();
        } formatter:^NSString *(double value) {
            return [weakSelf formatUnitValue:value];
        }],
        [ExampleSettingsItem sliderItemWithTitle:offsetXTitle
                                         minimum:-100.0
                                         maximum:100.0
                                            step:1.0
                                          getter:^double {
            return selected ? weakState.selectedTitleOffsetX : weakState.titleOffsetX;
        } setter:^(double value) {
            if (selected) {
                weakState.selectedTitleOffsetX = value;
            } else {
                weakState.titleOffsetX = value;
            }
            syncState();
        } formatter:^NSString *(double value) {
            return [weakSelf formatPointValue:value];
        }],
        [ExampleSettingsItem sliderItemWithTitle:offsetYTitle
                                         minimum:-100.0
                                         maximum:100.0
                                            step:1.0
                                          getter:^double {
            return selected ? weakState.selectedTitleOffsetY : weakState.titleOffsetY;
        } setter:^(double value) {
            if (selected) {
                weakState.selectedTitleOffsetY = value;
            } else {
                weakState.titleOffsetY = value;
            }
            syncState();
        } formatter:^NSString *(double value) {
            return [weakSelf formatPointValue:value];
        }],
        [ExampleSettingsItem sliderItemWithTitle:rotationTitle
                                         minimum:-180.0
                                         maximum:180.0
                                            step:1.0
                                          getter:^double {
            return selected ? weakState.selectedTitleRotation : weakState.titleRotation;
        } setter:^(double value) {
            if (selected) {
                weakState.selectedTitleRotation = value;
            } else {
                weakState.titleRotation = value;
            }
            syncState();
        } formatter:^NSString *(double value) {
            return [NSString stringWithFormat:@"%.0f°", value];
        }],
        [ExampleSettingsItem sliderItemWithTitle:opacityTitle
                                         minimum:0.0
                                         maximum:1.0
                                            step:0.05
                                          getter:^double {
            return selected ? weakState.selectedTitleOpacity : weakState.titleOpacity;
        } setter:^(double value) {
            if (selected) {
                weakState.selectedTitleOpacity = value;
            } else {
                weakState.titleOpacity = value;
            }
            syncState();
        } formatter:^NSString *(double value) {
            return [weakSelf formatUnitValue:value];
        }],
    ];
}

#pragma mark - Marker State

- (OverlayZoomScalingMarkerExampleFormState *)defaultMarkerStateAtCoordinate:(CLLocationCoordinate2D)coordinate {
    OverlayZoomScalingMarkerExampleFormState *state = [[OverlayZoomScalingMarkerExampleFormState alloc] init];
    state.latitude = coordinate.latitude;
    state.longitude = coordinate.longitude;
    state.title = @"";
    state.titleFontSize = 12.0;
    state.titleColorHex = @"#000000";
    state.titleColorIndex = [self indexForTitleColorHex:state.titleColorHex fallbackIndex:0];
    state.titleStrokeColorHex = @"#FFFFFF";
    state.titleStrokeColorIndex = [self indexForTitleColorHex:state.titleStrokeColorHex fallbackIndex:1];
    state.titleStrokeWidth = 1.0;
    state.titleAnchorX = 0.5;
    state.titleAnchorY = 0.0;
    state.titleOffsetX = 0.0;
    state.titleOffsetY = 4.0;
    state.titleRotation = 0.0;
    state.titleOpacity = 1.0;
    state.opacity = 1.0;
    state.anchorX = 0.5;
    state.anchorY = 1.0;
    state.iconOffsetX = 0.0;
    state.iconOffsetY = 0.0;
    state.iconRotation = 0.0;
    state.selectedTitle = @"";
    state.selectedTitleFontSize = 12.0;
    state.selectedTitleColorHex = @"#000000";
    state.selectedTitleColorIndex = [self indexForTitleColorHex:state.selectedTitleColorHex fallbackIndex:0];
    state.selectedTitleStrokeColorHex = @"#FFFFFF";
    state.selectedTitleStrokeColorIndex = [self indexForTitleColorHex:state.selectedTitleStrokeColorHex fallbackIndex:1];
    state.selectedTitleStrokeWidth = 1.0;
    state.selectedTitleAnchorX = 0.5;
    state.selectedTitleAnchorY = 0.0;
    state.selectedTitleOffsetX = 0.0;
    state.selectedTitleOffsetY = 4.0;
    state.selectedTitleRotation = 0.0;
    state.selectedTitleOpacity = 1.0;
    state.selectedOpacity = 1.0;
    state.selectedAnchorX = 0.5;
    state.selectedAnchorY = 1.0;
    state.selectedIconOffsetX = 0.0;
    state.selectedIconOffsetY = 0.0;
    state.selectedIconRotation = 0.0;
    state.selected = NO;
    state.scalesWithZoom = YES;
    state.maximumZoomScale = 2.0;
    state.minimumZoomScale = 0.1;
    state.minimumZoomLevel = 3.0;
    state.maximumZoomLevel = 20.0;
    state.iconTypeIndex = [self indexForIconType:MTCMarkerIconTypeBlueDot];
    state.selectedIconTypeIndex = [self indexForIconType:MTCMarkerIconTypeBlueDot];
    return state;
}

- (OverlayZoomScalingMarkerExampleFormState *)stateFromMarker:(MTCMarker *)marker {
    OverlayZoomScalingMarkerExampleFormState *baseState = [self.markerBaseStates objectForKey:marker];
    if (baseState) {
        OverlayZoomScalingMarkerExampleFormState *state = [baseState copy];
        state.latitude = marker.coordinate.latitude;
        state.longitude = marker.coordinate.longitude;
        state.selected = marker.selected;
        return state;
    }

    OverlayZoomScalingMarkerExampleFormState *state = [self defaultMarkerStateAtCoordinate:marker.coordinate];
    state.opacity = marker.style.icon.opacity;
    state.anchorX = marker.style.icon.anchor.x;
    state.anchorY = marker.style.icon.anchor.y;
    state.iconOffsetX = marker.style.icon.offset.x;
    state.iconOffsetY = marker.style.icon.offset.y;
    state.iconRotation = marker.style.icon.rotation;
    state.title = marker.style.title.text ?: @"";
    [self readTitle:marker.style.title intoState:state selected:NO];
    state.iconTypeIndex = [self indexForIconType:marker.style.icon.type];
    state.selected = marker.selected;

    MTCMarkerStyle *selectedStyle = marker.selectedStyle ?: marker.style;
    state.selectedOpacity = selectedStyle.icon.opacity;
    state.selectedAnchorX = selectedStyle.icon.anchor.x;
    state.selectedAnchorY = selectedStyle.icon.anchor.y;
    state.selectedIconOffsetX = selectedStyle.icon.offset.x;
    state.selectedIconOffsetY = selectedStyle.icon.offset.y;
    state.selectedIconRotation = selectedStyle.icon.rotation;
    state.selectedTitle = selectedStyle.title.text ?: @"";
    [self readTitle:selectedStyle.title intoState:state selected:YES];
    state.selectedIconTypeIndex = [self indexForIconType:selectedStyle.icon.type];
    return state;
}

- (MTCMarker *)currentMarker {
    return self.markers.lastObject;
}

- (void)replaceMarkersWithState:(OverlayZoomScalingMarkerExampleFormState *)state recenter:(BOOL)recenter {
    [self clearAllMarkers];
    [self addMarkerWithState:state recenter:recenter];
}

- (void)addMarkerWithState:(OverlayZoomScalingMarkerExampleFormState *)state recenter:(BOOL)recenter {
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(state.latitude, state.longitude);
    MTCMarker *marker = [[MTCMarker alloc] initWithCoordinate:coordinate];
    [self applyState:state toMarker:marker];
    [self.markers addObject:marker];
    self.editingMarker = marker;
    [self.mapView addOverlay:marker];
    [self.mapTestSupport syncOverlayCount:self.markers.count];
    if (recenter) {
        [self.mapView setCenterCoordinate:coordinate transition:[MTCCameraTransition easeWithDuration:0.25] completion:nil];
    }
}

- (void)syncEditingMarkerForState:(OverlayZoomScalingMarkerExampleFormState *)state {
    MTCMarker *editingMarker = self.editingMarker;
    if (!state || !editingMarker || ![self.markers containsObject:editingMarker]) {
        return;
    }
    [self applyState:state toMarker:editingMarker];
}

- (void)applyState:(OverlayZoomScalingMarkerExampleFormState *)state toMarker:(MTCMarker *)marker {
    [self.markerBaseStates setObject:[state copy] forKey:marker];
    [self applyStoredStateForMarker:marker zoomLevel:[self currentZoomLevel] updateSelection:YES];
}

- (void)applyStoredStateForMarker:(MTCMarker *)marker
                         zoomLevel:(double)zoomLevel
                   updateSelection:(BOOL)updateSelection {
    OverlayZoomScalingMarkerExampleFormState *state = [self.markerBaseStates objectForKey:marker];
    if (!state) {
        return;
    }

    if (!updateSelection) {
        state = [state copy];
        state.selected = marker.selected;
    }

    double zoomScale = state.scalesWithZoom ? [self zoomScaleForState:state zoomLevel:zoomLevel] : 1.0;
    [self applyBaseState:state toMarker:marker zoomScale:zoomScale applyIconSize:state.scalesWithZoom];
}

- (void)applyBaseState:(OverlayZoomScalingMarkerExampleFormState *)state
              toMarker:(MTCMarker *)marker
             zoomScale:(double)zoomScale
         applyIconSize:(BOOL)applyIconSize {
    marker.coordinate = CLLocationCoordinate2DMake(state.latitude, state.longitude);

    marker.style = [self markerStyleForState:state selected:NO zoomScale:zoomScale applyIconSize:applyIconSize];
    marker.selectedStyle = [self markerStyleForState:state selected:YES zoomScale:zoomScale applyIconSize:applyIconSize];
    marker.selected = state.selected;
    if (state.scalesWithZoom) {
        [self.markerAppliedZoomScales setObject:@(zoomScale) forKey:marker];
    } else {
        [self.markerAppliedZoomScales removeObjectForKey:marker];
    }
}

- (void)applyIconState:(OverlayZoomScalingMarkerExampleFormState *)state
              selected:(BOOL)selected
                toIcon:(MTCMarkerIcon *)icon
             zoomScale:(double)zoomScale
         applyIconSize:(BOOL)applyIconSize {
    icon.type = [self iconTypeForIndex:selected ? state.selectedIconTypeIndex : state.iconTypeIndex];
    icon.opacity = selected ? state.selectedOpacity : state.opacity;
    icon.anchor = CGPointMake(selected ? state.selectedAnchorX : state.anchorX,
                              selected ? state.selectedAnchorY : state.anchorY);
    icon.offset = CGPointMake(selected ? state.selectedIconOffsetX : state.iconOffsetX,
                              selected ? state.selectedIconOffsetY : state.iconOffsetY);
    icon.rotation = selected ? state.selectedIconRotation : state.iconRotation;

    if (!applyIconSize) {
        return;
    }

    CGSize baseSize = icon.size;
    if (CGSizeEqualToSize(baseSize, CGSizeZero)) {
        baseSize = [self intrinsicIconSizeForType:icon.type selected:selected];
    }
    if (!CGSizeEqualToSize(baseSize, CGSizeZero)) {
        icon.size = CGSizeMake(baseSize.width * zoomScale, baseSize.height * zoomScale);
    }
}

- (void)readTitle:(MTCMarkerTitle *)title
        intoState:(OverlayZoomScalingMarkerExampleFormState *)state
         selected:(BOOL)selected {
    NSString *colorHex = OverlayZoomScalingMarkerExampleHexStringFromColor(title.color, @"#000000");
    NSString *strokeColorHex = OverlayZoomScalingMarkerExampleHexStringFromColor(title.strokeColor, @"#FFFFFF");
    if (selected) {
        state.selectedTitle = title.text ?: @"";
        state.selectedTitleFontSize = title.fontSize;
        state.selectedTitleColorHex = colorHex;
        state.selectedTitleColorIndex = [self indexForTitleColorHex:colorHex fallbackIndex:state.selectedTitleColorIndex];
        state.selectedTitleStrokeColorHex = strokeColorHex;
        state.selectedTitleStrokeColorIndex = [self indexForTitleColorHex:strokeColorHex fallbackIndex:state.selectedTitleStrokeColorIndex];
        state.selectedTitleStrokeWidth = title.strokeWidth;
        state.selectedTitleAnchorX = title.anchor.x;
        state.selectedTitleAnchorY = title.anchor.y;
        state.selectedTitleOffsetX = title.offset.x;
        state.selectedTitleOffsetY = title.offset.y;
        state.selectedTitleRotation = title.rotation;
        state.selectedTitleOpacity = title.opacity;
    } else {
        state.title = title.text ?: @"";
        state.titleFontSize = title.fontSize;
        state.titleColorHex = colorHex;
        state.titleColorIndex = [self indexForTitleColorHex:colorHex fallbackIndex:state.titleColorIndex];
        state.titleStrokeColorHex = strokeColorHex;
        state.titleStrokeColorIndex = [self indexForTitleColorHex:strokeColorHex fallbackIndex:state.titleStrokeColorIndex];
        state.titleStrokeWidth = title.strokeWidth;
        state.titleAnchorX = title.anchor.x;
        state.titleAnchorY = title.anchor.y;
        state.titleOffsetX = title.offset.x;
        state.titleOffsetY = title.offset.y;
        state.titleRotation = title.rotation;
        state.titleOpacity = title.opacity;
    }
}

- (void)applyTitleState:(OverlayZoomScalingMarkerExampleFormState *)state
               selected:(BOOL)selected
                toTitle:(MTCMarkerTitle *)title
              zoomScale:(double)zoomScale {
    title.text = selected ? state.selectedTitle : state.title;
    title.fontSize = (selected ? state.selectedTitleFontSize : state.titleFontSize) * zoomScale;
    title.color = OverlayZoomScalingMarkerExampleColorFromHexString(selected ? state.selectedTitleColorHex : state.titleColorHex, @"#000000");
    title.strokeColor = OverlayZoomScalingMarkerExampleColorFromHexString(selected ? state.selectedTitleStrokeColorHex : state.titleStrokeColorHex, @"#FFFFFF");
    title.strokeWidth = selected ? state.selectedTitleStrokeWidth : state.titleStrokeWidth;
    title.anchor = CGPointMake(selected ? state.selectedTitleAnchorX : state.titleAnchorX,
                               selected ? state.selectedTitleAnchorY : state.titleAnchorY);
    title.offset = CGPointMake((selected ? state.selectedTitleOffsetX : state.titleOffsetX) * zoomScale,
                               (selected ? state.selectedTitleOffsetY : state.titleOffsetY) * zoomScale);
    title.rotation = selected ? state.selectedTitleRotation : state.titleRotation;
    title.opacity = selected ? state.selectedTitleOpacity : state.titleOpacity;
}

- (void)clearAllMarkers {
    NSArray<MTCMarker *> *markers = [self.markers copy];
    [self.markers removeAllObjects];
    [self.markerBaseStates removeAllObjects];
    [self.markerAppliedZoomScales removeAllObjects];
    self.editingMarker = nil;
    self.hasPendingZoomScaleUpdate = NO;
    self.zoomScaleDisplayLink.paused = YES;
    [self.mapView removeOverlays:markers];
    [self.mapTestSupport syncOverlayCount:0];
}

#pragma mark - Zoom Scaling

- (void)requestZoomScaleUpdateForZoomLevel:(double)zoomLevel {
    self.pendingZoomLevel = zoomLevel;
    self.hasPendingZoomScaleUpdate = YES;
    [self ensureZoomScaleDisplayLink].paused = NO;
}

- (CADisplayLink *)ensureZoomScaleDisplayLink {
    if (self.zoomScaleDisplayLink) {
        return self.zoomScaleDisplayLink;
    }

    self.zoomScaleDisplayLinkTarget = [[OverlayZoomScalingMarkerExampleDisplayLinkTarget alloc] initWithTarget:self];
    CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:self.zoomScaleDisplayLinkTarget
                                                              selector:@selector(displayLinkDidFire:)];
    displayLink.preferredFramesPerSecond = OverlayZoomScalingMarkerExampleZoomScaleFramesPerSecond;
    displayLink.paused = YES;
    [displayLink addToRunLoop:NSRunLoop.mainRunLoop forMode:NSRunLoopCommonModes];
    self.zoomScaleDisplayLink = displayLink;
    return displayLink;
}

- (void)handleZoomScaleDisplayLink:(CADisplayLink *)displayLink {
    (void)displayLink;
    if (!self.hasPendingZoomScaleUpdate) {
        self.zoomScaleDisplayLink.paused = YES;
        return;
    }

    self.hasPendingZoomScaleUpdate = NO;
    [self applyZoomScaleForZoomLevel:self.pendingZoomLevel force:NO];
    if (!self.hasPendingZoomScaleUpdate) {
        self.zoomScaleDisplayLink.paused = YES;
    }
}

- (void)applyZoomScaleForZoomLevel:(double)zoomLevel force:(BOOL)force {
    NSArray<MTCMarker *> *markers = [self.markers copy];
    [self.mapView performOverlayUpdates:^{
        for (MTCMarker *marker in markers) {
            OverlayZoomScalingMarkerExampleFormState *state = [self.markerBaseStates objectForKey:marker];
            if (!state.scalesWithZoom) {
                continue;
            }
            [self applyZoomScaleForMarker:marker state:state zoomLevel:zoomLevel force:force];
        }
    }];
}

- (void)applyZoomScaleForMarker:(MTCMarker *)marker
                          state:(OverlayZoomScalingMarkerExampleFormState *)state
                      zoomLevel:(double)zoomLevel
                          force:(BOOL)force {
    double zoomScale = [self zoomScaleForState:state zoomLevel:zoomLevel];
    NSNumber *appliedZoomScale = [self.markerAppliedZoomScales objectForKey:marker];
    if (!force && appliedZoomScale && fabs(zoomScale - appliedZoomScale.doubleValue) < OverlayZoomScalingMarkerExampleZoomScaleStep) {
        return;
    }

    if (marker.isSelected) {
        marker.selectedStyle = [self markerStyleForState:state selected:YES zoomScale:zoomScale applyIconSize:YES];
    } else {
        marker.style = [self markerStyleForState:state selected:NO zoomScale:zoomScale applyIconSize:YES];
    }
    [self.markerAppliedZoomScales setObject:@(zoomScale) forKey:marker];
}

- (MTCMarkerStyle *)markerStyleForState:(OverlayZoomScalingMarkerExampleFormState *)state
                               selected:(BOOL)selected
                              zoomScale:(double)zoomScale
                          applyIconSize:(BOOL)applyIconSize {
    MTCMarkerStyle *style = [[MTCMarkerStyle alloc] init];
    [self applyIconState:state selected:selected toIcon:style.icon zoomScale:zoomScale applyIconSize:applyIconSize];
    [self applyTitleState:state selected:selected toTitle:style.title zoomScale:zoomScale];
    return style;
}

- (double)currentZoomLevel {
    MTCMapCamera *camera = self.mapView.camera;
    return camera ? camera.zoomLevel : OverlayZoomScalingMarkerExampleDefaultZoomLevel;
}

- (double)zoomScaleForState:(OverlayZoomScalingMarkerExampleFormState *)state zoomLevel:(double)zoomLevel {
    double minimumZoomLevel = state.minimumZoomLevel;
    double maximumZoomLevel = state.maximumZoomLevel;
    if (maximumZoomLevel < minimumZoomLevel) {
        double temporaryZoomLevel = minimumZoomLevel;
        minimumZoomLevel = maximumZoomLevel;
        maximumZoomLevel = temporaryZoomLevel;
    }

    double minimumZoomScale = OverlayZoomScalingMarkerExampleClampDouble(state.minimumZoomScale, 0.1, 5.0);
    double maximumZoomScale = OverlayZoomScalingMarkerExampleClampDouble(state.maximumZoomScale, 0.1, 5.0);
    if (maximumZoomScale < minimumZoomScale) {
        double temporaryZoomScale = minimumZoomScale;
        minimumZoomScale = maximumZoomScale;
        maximumZoomScale = temporaryZoomScale;
    }

    if (fabs(maximumZoomLevel - minimumZoomLevel) < DBL_EPSILON) {
        return zoomLevel >= minimumZoomLevel ? maximumZoomScale : minimumZoomScale;
    }

    double progress = (zoomLevel - minimumZoomLevel) / (maximumZoomLevel - minimumZoomLevel);
    progress = OverlayZoomScalingMarkerExampleClampDouble(progress, 0.0, 1.0);
    return minimumZoomScale + (maximumZoomScale - minimumZoomScale) * progress;
}

- (CGSize)intrinsicIconSizeForType:(MTCMarkerIconType)iconType selected:(BOOL)selected {
    UIImage *image = [self builtinMarkerImageForType:iconType selected:selected];
    return image ? image.size : CGSizeZero;
}

- (UIImage *)builtinMarkerImageForType:(MTCMarkerIconType)iconType selected:(BOOL)selected {
    NSBundle *mapBundle = [self mapResourceBundle];
    NSString *imageName = [self markerImageNameForType:iconType selected:selected];
    UIImage *image = [self imageNamed:imageName inMapBundle:mapBundle];
    if (image) {
        return image;
    }

    if (selected) {
        image = [self imageNamed:[self markerImageNameForType:iconType selected:NO] inMapBundle:mapBundle];
        if (image) {
            return image;
        }
    }

    return [self imageNamed:[self markerBaseNameForType:iconType] inMapBundle:mapBundle];
}

- (NSBundle *)mapResourceBundle {
    NSArray<NSBundle *> *candidateBundles = @[
        [NSBundle bundleForClass:[MTCMapView class]],
        NSBundle.mainBundle,
    ];
    for (NSBundle *candidateBundle in candidateBundles) {
        NSURL *mapBundleURL = [candidateBundle URLForResource:OverlayZoomScalingMarkerExampleMapBundleName withExtension:@"bundle"];
        NSBundle *mapBundle = mapBundleURL ? [NSBundle bundleWithURL:mapBundleURL] : nil;
        if (mapBundle) {
            return mapBundle;
        }
    }
    return [NSBundle bundleForClass:[MTCMapView class]];
}

- (UIImage *)imageNamed:(NSString *)imageName inMapBundle:(NSBundle *)mapBundle {
    if (imageName.length == 0 || !mapBundle) {
        return nil;
    }

    UIImage *image = [UIImage imageNamed:imageName inBundle:mapBundle compatibleWithTraitCollection:nil];
    if (image) {
        return image;
    }

    NSURL *imagesURL = [mapBundle URLForResource:OverlayZoomScalingMarkerExampleImagesDirectoryName withExtension:nil];
    NSBundle *imagesBundle = imagesURL ? [NSBundle bundleWithURL:imagesURL] : nil;
    return imagesBundle ? [UIImage imageNamed:imageName inBundle:imagesBundle compatibleWithTraitCollection:nil] : nil;
}

- (NSString *)markerImageNameForType:(MTCMarkerIconType)iconType selected:(BOOL)selected {
    NSString *baseName = [self markerBaseNameForType:iconType];
    if (baseName.length == 0) {
        return nil;
    }
    return [NSString stringWithFormat:@"mtc_marker_%@_%@", baseName, selected ? @"selected" : @"normal"];
}

- (NSString *)markerBaseNameForType:(MTCMarkerIconType)iconType {
    switch (iconType) {
        case MTCMarkerIconTypeBlueDot:
            return @"blue_dot";
        case MTCMarkerIconTypeRedDot:
            return @"red_dot";
        case MTCMarkerIconTypeGreenDot:
            return @"green_dot";
        case MTCMarkerIconTypeYellowDot:
            return @"yellow_dot";
        case MTCMarkerIconTypeCustom:
            return nil;
        default:
            return @"blue_dot";
    }
}

#pragma mark - Formatting

- (NSArray<NSString *> *)markerIconTitles {
    return @[@"blue_dot", @"red_dot", @"green_dot", @"yellow_dot"];
}

- (NSArray<NSString *> *)titleColorOptions {
    return @[
        @"#000000",
        @"#FFFFFF",
        @"#2F80ED",
        @"#00A63E",
        @"#FF0000",
        @"#FF9800",
        @"#FFC107",
        @"#9C27B0",
        @"#424242",
        @"#E0E0E0",
    ];
}

- (NSInteger)indexForTitleColorHex:(NSString *)hexValue fallbackIndex:(NSInteger)fallbackIndex {
    NSString *normalizedValue = OverlayZoomScalingMarkerExampleNormalizeHexString(hexValue, @"");
    NSArray<NSString *> *options = [self titleColorOptions];
    for (NSInteger index = 0; index < (NSInteger)options.count; ++index) {
        NSString *optionValue = OverlayZoomScalingMarkerExampleNormalizeHexString(options[index], @"");
        if ([normalizedValue isEqualToString:optionValue]) {
            return index;
        }
    }
    return fallbackIndex;
}

- (MTCMarkerIconType)iconTypeForIndex:(NSInteger)index {
    switch (index) {
        case 1:
            return MTCMarkerIconTypeRedDot;
        case 2:
            return MTCMarkerIconTypeGreenDot;
        case 3:
            return MTCMarkerIconTypeYellowDot;
        case 0:
        default:
            return MTCMarkerIconTypeBlueDot;
    }
}

- (NSInteger)indexForIconType:(MTCMarkerIconType)iconType {
    switch (iconType) {
        case MTCMarkerIconTypeRedDot:
            return 1;
        case MTCMarkerIconTypeGreenDot:
            return 2;
        case MTCMarkerIconTypeYellowDot:
            return 3;
        case MTCMarkerIconTypeBlueDot:
        default:
            return 0;
    }
}

- (NSString *)coordinateTextForState:(OverlayZoomScalingMarkerExampleFormState *)state {
    return [NSString stringWithFormat:@"%@, %@",
            [self formatCoordinateValue:state.latitude],
            [self formatCoordinateValue:state.longitude]];
}

- (void)updateCoordinateWithText:(NSString *)text state:(OverlayZoomScalingMarkerExampleFormState *)state {
    NSArray<NSString *> *components =
        [text componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@",， "]];
    NSMutableArray<NSString *> *values = [NSMutableArray arrayWithCapacity:2];
    for (NSString *component in components) {
        NSString *trimmedComponent = [component stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        if (trimmedComponent.length > 0) {
            [values addObject:trimmedComponent];
        }
    }
    if (values.count < 2) {
        return;
    }

    state.latitude = OverlayZoomScalingMarkerExampleDoubleFromString(values[0], state.latitude, -90.0, 90.0);
    state.longitude = OverlayZoomScalingMarkerExampleDoubleFromString(values[1], state.longitude, -180.0, 180.0);
}

- (NSString *)formatCoordinateValue:(double)value {
    return [NSString stringWithFormat:@"%.6f", value];
}

- (NSString *)formatUnitValue:(double)value {
    return [NSString stringWithFormat:@"%.2f", OverlayZoomScalingMarkerExampleClampDouble(value, 0.0, 1.0)];
}

- (NSString *)formatScaleValue:(double)value {
    return [NSString stringWithFormat:@"%.1f", OverlayZoomScalingMarkerExampleClampDouble(value, 0.1, 5.0)];
}

- (NSString *)formatPointValue:(double)value {
    return [NSString stringWithFormat:@"%.1f", OverlayZoomScalingMarkerExampleClampDouble(value, -200.0, 200.0)];
}

- (NSString *)formatZoomLevelValue:(double)value {
    return [NSString stringWithFormat:@"%.1f", OverlayZoomScalingMarkerExampleClampDouble(value, 0.0, 22.0)];
}

#pragma mark - Coordinates

- (CLLocationCoordinate2D)singaporeCoordinate {
    return CLLocationCoordinate2DMake(OverlayZoomScalingMarkerExampleSingaporeLatitude,
                                      OverlayZoomScalingMarkerExampleSingaporeLongitude);
}

- (CLLocationCoordinate2D)currentMapCenterCoordinate {
    MTCMapCamera *camera = self.mapView.camera;
    if (camera) {
        return camera.centerCoordinate;
    }
    return [self singaporeCoordinate];
}

#pragma mark - MTCMapViewDelegate

- (void)mapView:(MTCMapView *)mapView
cameraDidChange:(MTCMapCamera *)camera
         reason:(MTCMapCameraChangeReason)reason
       animated:(BOOL)animated {
    (void)mapView;
    (void)reason;
    (void)animated;
    [self requestZoomScaleUpdateForZoomLevel:camera.zoomLevel];
}

- (void)mapView:(MTCMapView *)mapView
cameraDidBecomeIdle:(MTCMapCamera *)camera
         reason:(MTCMapCameraChangeReason)reason
       animated:(BOOL)animated {
    (void)mapView;
    (void)reason;
    (void)animated;
    self.hasPendingZoomScaleUpdate = NO;
    self.zoomScaleDisplayLink.paused = YES;
    [self applyZoomScaleForZoomLevel:camera.zoomLevel force:YES];
}

- (void)mapView:(MTCMapView *)mapView didTapOverlay:(id<MTCOverlay>)overlay {
    (void)mapView;
    MTCMarker *marker = [(id)overlay isKindOfClass:MTCMarker.class] ? (MTCMarker *)overlay : nil;
    if (!marker) {
        return;
    }
    OverlayZoomScalingMarkerExampleFormState *state = [self.markerBaseStates objectForKey:marker];
    if (!state || !state.scalesWithZoom) {
        return;
    }

    BOOL selected = !marker.selected;
    double zoomScale = [self zoomScaleForState:state zoomLevel:[self currentZoomLevel]];
    if (selected) {
        marker.selectedStyle = [self markerStyleForState:state selected:YES zoomScale:zoomScale applyIconSize:YES];
    } else {
        marker.style = [self markerStyleForState:state selected:NO zoomScale:zoomScale applyIconSize:YES];
    }
    [self.markerAppliedZoomScales setObject:@(zoomScale) forKey:marker];
}

#pragma mark -- multi-language

- (void)handleExampleSettingsAction {
    [self showMarkerSheet];
}

- (void)demoLanguageDidChange {
    [self applyLocalizedTexts];
}

- (void)applyLocalizedTexts {
    self.title = [self localizedStringForKey:@"demo_title_OverlayZoomScalingMarkerExampleViewController"];
    if (self.mapView) {
        self.mapView.mapLanguage = [self mapLanguageForDemoLanguage:self.demoLanguage];
    }
    if ([self isSettingsSheetVisible:ExampleSettingsSheetView.class]) {
        [self showMarkerSheet];
    }
}
@end
