#import "OverlayNetworkImageMarkerExampleViewController.h"

#import "ExampleSettingsSheetView.h"
#import "MTCExampleMapTestSupport.h"
#import "MTCExampleTestAccessibility.h"
#import "MTCExampleToastView.h"

#import <MaptecMapsKit/MaptecMapsKit.h>

#include <math.h>

static CLLocationDegrees const OverlayNetworkImageMarkerExampleSingaporeLatitude = 1.3048264556208515;
static CLLocationDegrees const OverlayNetworkImageMarkerExampleSingaporeLongitude = 103.83052199958921;
static double const OverlayNetworkImageMarkerExampleDefaultZoomLevel = 13.0;
static CGFloat const OverlayNetworkImageMarkerExampleMaximumIconDimension = 72.0;
static NSString * const OverlayNetworkImageMarkerExampleDefaultImageURLString = @"https://hellorfimg.zcool.cn/preview260/1291884748.jpg?x-image-process=image/resize,h_380";

static double OverlayNetworkImageMarkerExampleClampDouble(double value, double minimum, double maximum) {
    return fmin(fmax(value, minimum), maximum);
}

static double OverlayNetworkImageMarkerExampleDoubleFromString(NSString *value, double fallback, double minimum, double maximum) {
    NSString *trimmedValue = [value stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (trimmedValue.length == 0) {
        return fallback;
    }

    double parsedValue = 0.0;
    NSScanner *scanner = [NSScanner scannerWithString:trimmedValue];
    if (![scanner scanDouble:&parsedValue]) {
        return fallback;
    }
    return OverlayNetworkImageMarkerExampleClampDouble(parsedValue, minimum, maximum);
}

@interface OverlayNetworkImageMarkerExampleFormState : NSObject <NSCopying>
@property (nonatomic) double latitude;
@property (nonatomic) double longitude;
@property (nonatomic, copy) NSString *imageURLString;
@property (nonatomic) double maximumIconDimension;
@property (nonatomic) double opacity;
@end

@implementation OverlayNetworkImageMarkerExampleFormState

- (id)copyWithZone:(NSZone *)zone {
    OverlayNetworkImageMarkerExampleFormState *state = [[[self class] allocWithZone:zone] init];
    state.latitude = self.latitude;
    state.longitude = self.longitude;
    state.imageURLString = self.imageURLString;
    state.maximumIconDimension = self.maximumIconDimension;
    state.opacity = self.opacity;
    return state;
}

@end

@interface OverlayNetworkImageMarkerExampleViewController () <MTCMapViewDelegate>
@property (nonatomic, strong) MTCMapView *mapView;
@property (nonatomic, strong) NSMutableArray<MTCMarker *> *markers;
@property (nonatomic, strong) NSMapTable<MTCMarker *, OverlayNetworkImageMarkerExampleFormState *> *markerBaseStates;
@property (nonatomic, strong) OverlayNetworkImageMarkerExampleFormState *formState;
@property (nonatomic, weak) MTCMarker *editingMarker;
@property (nonatomic) NSUInteger markerGeneration;
@property (nonatomic, strong) MTCExampleMapTestSupport *mapTestSupport;
@end

@implementation OverlayNetworkImageMarkerExampleViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = UIColor.whiteColor;
    self.view.accessibilityIdentifier = @"OverlayNetworkImageMarkerExampleViewController.screen";
    self.markers = [NSMutableArray array];
    self.markerBaseStates = [NSMapTable weakToStrongObjectsMapTable];
    self.formState = [self defaultMarkerStateAtCoordinate:[self singaporeCoordinate]];

    [self configureNavigationItems:NO];
    [self configureMapView];
    [self.mapView setCenterCoordinate:[self singaporeCoordinate] zoomLevel:OverlayNetworkImageMarkerExampleDefaultZoomLevel];
    [self addInitialMarker];
    [self applyLocalizedTexts];
}

#pragma mark - Setup

- (void)configureMapView {
    self.mapTestSupport = [[MTCExampleMapTestSupport alloc] init];
    self.mapTestSupport.overlayPresenceIdentifier = MTCExampleTestAccessibilitySymbolLayerHasMarkers;
    [self.mapTestSupport installOnHostView:self.view];
    [self.mapTestSupport syncOverlayCount:0];

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

#pragma mark - Sheets

- (void)showMarkerSheet {
    MTCMarker *marker = [self currentMarker];
    self.editingMarker = marker;
    self.formState = marker ? [self stateFromMarker:marker] : [self defaultMarkerStateAtCoordinate:[self currentMapCenterCoordinate]];

    __block ExampleSettingsSheetView *sheet = nil;
    sheet = [[ExampleSettingsSheetView alloc] initWithTitle:[self localizedStringForKey:@"common_settings_sheet_title"]
                                                   sections:[self sectionsWithAddAction:^{
        [self replaceMarkersWithState:[self.formState copy]];
        [sheet dismissAnimated:YES];
    } clearAction:^{
        [self clearAllMarkers];
        [sheet dismissAnimated:YES];
    }]];
    [sheet showInView:self.view animated:YES];
}

- (NSArray<ExampleSettingsSection *> *)sectionsWithAddAction:(dispatch_block_t)addAction
                                                 clearAction:(dispatch_block_t)clearAction {
    __weak typeof(self) weakSelf = self;
    __weak OverlayNetworkImageMarkerExampleFormState *weakState = self.formState;
    void (^syncState)(void) = ^{
        [weakSelf syncEditingMarkerForState:weakState];
    };

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
        [ExampleSettingsSection sectionWithTitle:[self localizedStringForKey:@"overlay_image"] items:@[
            [ExampleSettingsItem multilineTextItemWithTitle:[self localizedStringForKey:@"overlay_image_url"]
                                                placeholder:OverlayNetworkImageMarkerExampleDefaultImageURLString
                                                     getter:^NSString *{
                return weakState.imageURLString ?: @"";
            } setter:^(NSString *value) {
                weakState.imageURLString = value ?: @"";
                syncState();
            }],
        ]],
        [ExampleSettingsSection sectionWithTitle:[self localizedStringForKey:@"overlay_style"] items:@[
            [ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"overlay_icon_max_size"]
                                             minimum:24.0
                                             maximum:160.0
                                                step:4.0
                                              getter:^double {
                return weakState.maximumIconDimension;
            } setter:^(double value) {
                weakState.maximumIconDimension = value;
                syncState();
            } formatter:^NSString *(double value) {
                return [weakSelf formatPointValue:value];
            }],
            [ExampleSettingsItem sliderItemWithTitle:[self localizedStringForKey:@"overlay_opacity_34dac4"]
                                             minimum:0.0
                                             maximum:1.0
                                                step:0.05
                                              getter:^double {
                return weakState.opacity;
            } setter:^(double value) {
                weakState.opacity = value;
                syncState();
            } formatter:^NSString *(double value) {
                return [weakSelf formatUnitValue:value];
            }],
        ]],
        [ExampleSettingsSection sectionWithTitle:@"" items:@[
            [[ExampleSettingsItem actionItemWithTitle:[self localizedStringForKey:@"overlay_add_b58c75"] handler:addAction]
             withAccessibilityIdentifier:MTCExampleTestAccessibilitySymbolBtnAddMarker],
            [[ExampleSettingsItem actionItemWithTitle:[self localizedStringForKey:@"overlay_clear_all_3358c6"] handler:clearAction]
             withAccessibilityIdentifier:MTCExampleTestAccessibilitySymbolBtnClearAll],
        ]],
    ];
}

#pragma mark - Marker State

- (OverlayNetworkImageMarkerExampleFormState *)defaultMarkerStateAtCoordinate:(CLLocationCoordinate2D)coordinate {
    OverlayNetworkImageMarkerExampleFormState *state = [[OverlayNetworkImageMarkerExampleFormState alloc] init];
    state.latitude = coordinate.latitude;
    state.longitude = coordinate.longitude;
    state.imageURLString = OverlayNetworkImageMarkerExampleDefaultImageURLString;
    state.maximumIconDimension = OverlayNetworkImageMarkerExampleMaximumIconDimension;
    state.opacity = 1.0;
    return state;
}

- (void)addInitialMarker {
    [self addMarkerWithState:[self.formState copy] showToast:NO recenter:NO];
}

- (OverlayNetworkImageMarkerExampleFormState *)stateFromMarker:(MTCMarker *)marker {
    OverlayNetworkImageMarkerExampleFormState *baseState = [self.markerBaseStates objectForKey:marker];
    OverlayNetworkImageMarkerExampleFormState *state = baseState ? [baseState copy] : [self defaultMarkerStateAtCoordinate:marker.coordinate];
    state.latitude = marker.coordinate.latitude;
    state.longitude = marker.coordinate.longitude;
    CGSize iconSize = marker.style.icon.size;
    CGFloat maximumDimension = MAX(iconSize.width, iconSize.height);
    if (maximumDimension > 0.0) {
        state.maximumIconDimension = maximumDimension;
    }
    state.opacity = marker.style.icon.opacity;
    return state;
}

- (MTCMarker *)currentMarker {
    return self.markers.lastObject;
}

- (void)replaceMarkersWithState:(OverlayNetworkImageMarkerExampleFormState *)state {
    [self clearAllMarkersShowingToast:NO];
    [self addMarkerWithState:state];
}

- (void)addMarkerWithState:(OverlayNetworkImageMarkerExampleFormState *)state {
    [self addMarkerWithState:state showToast:YES recenter:YES];
}

- (void)addMarkerWithState:(OverlayNetworkImageMarkerExampleFormState *)state
                 showToast:(BOOL)showToast
                  recenter:(BOOL)recenter {
    NSURL *URL = [self imageURLFromString:state.imageURLString];
    if (!URL) {
        if (showToast) {
            [MTCExampleToastView showMessage:[self localizedStringForKey:@"overlay_enter_a_valid_image_url"] inView:self.view];
        }
        return;
    }

    NSUInteger generation = self.markerGeneration;
    if (showToast) {
        [MTCExampleToastView showMessage:[self localizedStringForKey:@"overlay_downloading_image"] inView:self.view];
    }

    __weak typeof(self) weakSelf = self;
    NSURLSessionDataTask *dataTask = [[NSURLSession sharedSession] dataTaskWithURL:URL
                                                                 completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        UIImage *image = nil;
        NSString *errorMessage = nil;

        if (error) {
            errorMessage = [self localizedStringForKey:@"overlay_image_download_failed"];
        } else if ([response isKindOfClass:NSHTTPURLResponse.class]) {
            NSInteger statusCode = ((NSHTTPURLResponse *)response).statusCode;
            if (statusCode < 200 || statusCode >= 300) {
                errorMessage = [self localizedStringForKey:@"overlay_image_download_failed"];
            }
        }

        if (!errorMessage) {
            image = data.length > 0 ? [UIImage imageWithData:data] : nil;
            if (!image) {
                errorMessage = [self localizedStringForKey:@"overlay_invalid_image_data"];
            }
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf || generation != strongSelf.markerGeneration) {
                return;
            }
            if (!image) {
                if (showToast) {
                    [MTCExampleToastView showMessage:errorMessage ?: [self localizedStringForKey:@"overlay_image_download_failed"] inView:strongSelf.view];
                }
                return;
            }

            [strongSelf addMarkerWithImage:image state:state recenter:recenter];
            if (showToast) {
                [MTCExampleToastView showMessage:[self localizedStringForKey:@"overlay_added_network_image_marker"] inView:strongSelf.view];
            }
        });
    }];
    [dataTask resume];
}

- (void)addMarkerWithImage:(UIImage *)image
                     state:(OverlayNetworkImageMarkerExampleFormState *)state
                  recenter:(BOOL)recenter {
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(state.latitude, state.longitude);
    MTCMarker *marker = [[MTCMarker alloc] initWithCoordinate:coordinate];
    marker.style = [self markerStyleWithImage:image state:state];
    [self.markerBaseStates setObject:[state copy] forKey:marker];
    [self.markers addObject:marker];
    self.editingMarker = marker;
    [self.mapView addOverlay:marker];
    [self.mapTestSupport syncOverlayCount:self.markers.count];
    if (recenter) {
        [self.mapView setCenterCoordinate:coordinate transition:[MTCCameraTransition easeWithDuration:0.25] completion:nil];
    }
}

- (void)syncEditingMarkerForState:(OverlayNetworkImageMarkerExampleFormState *)state {
    MTCMarker *editingMarker = self.editingMarker;
    if (!state || !editingMarker || ![self.markers containsObject:editingMarker]) {
        return;
    }

    OverlayNetworkImageMarkerExampleFormState *previousState = [self.markerBaseStates objectForKey:editingMarker];
    BOOL imageURLChanged = ![previousState.imageURLString isEqualToString:state.imageURLString];
    [self applyState:state toMarker:editingMarker];
    if (imageURLChanged) {
        [self reloadImageForMarker:editingMarker state:[state copy]];
    }
}

- (void)applyState:(OverlayNetworkImageMarkerExampleFormState *)state toMarker:(MTCMarker *)marker {
    [self.markerBaseStates setObject:[state copy] forKey:marker];
    marker.coordinate = CLLocationCoordinate2DMake(state.latitude, state.longitude);

    UIImage *image = marker.style.icon.customImage;
    if (image) {
        marker.style = [self markerStyleWithImage:image state:state];
    }
}

- (void)reloadImageForMarker:(MTCMarker *)marker state:(OverlayNetworkImageMarkerExampleFormState *)state {
    NSURL *URL = [self imageURLFromString:state.imageURLString];
    if (!URL) {
        return;
    }

    NSUInteger generation = ++self.markerGeneration;
    __weak typeof(self) weakSelf = self;
    NSURLSessionDataTask *dataTask = [[NSURLSession sharedSession] dataTaskWithURL:URL
                                                                 completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        UIImage *image = nil;
        if (!error) {
            BOOL validResponse = ![response isKindOfClass:NSHTTPURLResponse.class] ||
                (((NSHTTPURLResponse *)response).statusCode >= 200 && ((NSHTTPURLResponse *)response).statusCode < 300);
            image = validResponse && data.length > 0 ? [UIImage imageWithData:data] : nil;
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf || generation != strongSelf.markerGeneration || !image || ![strongSelf.markers containsObject:marker]) {
                return;
            }
            OverlayNetworkImageMarkerExampleFormState *currentState = [strongSelf.markerBaseStates objectForKey:marker];
            if (![currentState.imageURLString isEqualToString:state.imageURLString]) {
                return;
            }
            marker.style = [strongSelf markerStyleWithImage:image state:currentState];
        });
    }];
    [dataTask resume];
}

- (MTCMarkerStyle *)markerStyleWithImage:(UIImage *)image
                                   state:(OverlayNetworkImageMarkerExampleFormState *)state {
    MTCMarkerStyle *style = [[MTCMarkerStyle alloc] init];
    style.icon.type = MTCMarkerIconTypeCustom;
    style.icon.customImage = image;
    style.icon.size = [self markerIconSizeForImage:image maximumDimension:state.maximumIconDimension];
    style.icon.anchor = CGPointMake(0.5, 1.0);
    style.icon.opacity = state.opacity;
    return style;
}

- (CGSize)markerIconSizeForImage:(UIImage *)image
                maximumDimension:(double)maximumDimension {
    CGSize imageSize = image.size;
    if (imageSize.width <= 0.0 || imageSize.height <= 0.0) {
        return CGSizeZero;
    }

    CGFloat clampedMaximumDimension = OverlayNetworkImageMarkerExampleClampDouble(maximumDimension, 1.0, 240.0);
    CGFloat scale = MIN(clampedMaximumDimension / imageSize.width,
                        clampedMaximumDimension / imageSize.height);
    scale = MIN(scale, 1.0);
    return CGSizeMake(round(imageSize.width * scale), round(imageSize.height * scale));
}

- (void)clearAllMarkers {
    [self clearAllMarkersShowingToast:YES];
}

- (void)clearAllMarkersShowingToast:(BOOL)showToast {
    self.markerGeneration += 1;
    NSArray<MTCMarker *> *markers = [self.markers copy];
    [self.markers removeAllObjects];
    [self.markerBaseStates removeAllObjects];
    self.editingMarker = nil;
    [self.mapView removeOverlays:markers];
    [self.mapTestSupport syncOverlayCount:0];
    if (showToast) {
        [MTCExampleToastView showMessage:[self localizedStringForKey:@"overlay_all_markers_cleared"] inView:self.view];
    }
}

#pragma mark - Formatting

- (NSString *)coordinateTextForState:(OverlayNetworkImageMarkerExampleFormState *)state {
    return [NSString stringWithFormat:@"%@, %@",
            [self formatCoordinateValue:state.latitude],
            [self formatCoordinateValue:state.longitude]];
}

- (void)updateCoordinateWithText:(NSString *)text state:(OverlayNetworkImageMarkerExampleFormState *)state {
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

    state.latitude = OverlayNetworkImageMarkerExampleDoubleFromString(values[0], state.latitude, -90.0, 90.0);
    state.longitude = OverlayNetworkImageMarkerExampleDoubleFromString(values[1], state.longitude, -180.0, 180.0);
}

- (NSString *)formatCoordinateValue:(double)value {
    return [NSString stringWithFormat:@"%.6f", value];
}

- (NSString *)formatUnitValue:(double)value {
    return [NSString stringWithFormat:@"%.2f", OverlayNetworkImageMarkerExampleClampDouble(value, 0.0, 1.0)];
}

- (NSString *)formatPointValue:(double)value {
    return [NSString stringWithFormat:@"%.0f pt", OverlayNetworkImageMarkerExampleClampDouble(value, 1.0, 240.0)];
}

#pragma mark - URL

- (NSURL *)imageURLFromString:(NSString *)URLString {
    NSString *trimmedURLString = [URLString stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (trimmedURLString.length == 0) {
        return nil;
    }

    NSURL *URL = [NSURL URLWithString:trimmedURLString];
    NSString *scheme = URL.scheme.lowercaseString;
    if (!URL.host || (![@"http" isEqualToString:scheme] && ![@"https" isEqualToString:scheme])) {
        return nil;
    }
    return URL;
}

#pragma mark - Coordinates

- (CLLocationCoordinate2D)singaporeCoordinate {
    return CLLocationCoordinate2DMake(OverlayNetworkImageMarkerExampleSingaporeLatitude,
                                      OverlayNetworkImageMarkerExampleSingaporeLongitude);
}

- (CLLocationCoordinate2D)currentMapCenterCoordinate {
    MTCMapCamera *camera = self.mapView.camera;
    if (camera) {
        return camera.centerCoordinate;
    }
    return [self singaporeCoordinate];
}

#pragma mark -- multi-language

- (void)handleExampleSettingsAction {
    [self showMarkerSheet];
}

- (void)demoLanguageDidChange {
    [self applyLocalizedTexts];
}

- (void)applyLocalizedTexts {
    self.title = [self localizedStringForKey:@"demo_title_OverlayNetworkImageMarkerExampleViewController"];
    if (self.mapView) {
        self.mapView.mapLanguage = [self mapLanguageForDemoLanguage:self.demoLanguage];
    }
    if ([self isSettingsSheetVisible:ExampleSettingsSheetView.class]) {
        [self showMarkerSheet];
    }
}
@end
