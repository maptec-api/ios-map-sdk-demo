//
//  MTCWebGeoCodingViewController.m
//  MaptecMapsExample
//
//  Created by ZHOUPanpan on 2026/7/14.
//

#import "MTCWebGeoCodingViewController.h"

#import "MTCExampleMapTestSupport.h"
#import "MTCExampleTestAccessibility.h"
#import "MTCMTCWebDetailPopupView.h"
#import "MTCTextSearchRequestParams+MTCSupportFork.h"
#import "MTCWebSettingsFloatView.h"
#import "MTCWebSupportUtil.h"

#import <float.h>
#import <MaptecMapsKit/MaptecMapsKit.h>

static const CLLocationDegrees MTCForwardGeocodeDefaultLatitude = 1.3521;
static const CLLocationDegrees MTCForwardGeocodeDefaultLongitude = 103.8198;
static const double MTCForwardGeocodeSinglePlaceZoomLevel = 14.0;

@interface MTCWebGeoCodingConfigModel : NSObject

@property (nonatomic, copy) NSString *addressText;
@property (nonatomic, copy) NSString *componentsText;
@property (nonatomic, copy) NSString *languageText;
@property (nonatomic, copy) NSString *regionText;
@property (nonatomic, copy) NSString *rectNorthEastText;
@property (nonatomic, copy) NSString *rectSouthWestText;
@property (nonatomic, assign) BOOL advancedExpanded;
@property (nonatomic, assign) BOOL biasEnabled;

@end

@implementation MTCWebGeoCodingConfigModel

- (instancetype)init {
    self = [super init];
    if (self) {
        _addressText = @"Lorong";
        _componentsText = @"";
        _languageText = @"zh";
        _regionText = @"";
        _rectNorthEastText = @"";
        _rectSouthWestText = @"";
        _advancedExpanded = NO;
        _biasEnabled = NO;
    }
    return self;
}

@end

@interface MTCWebGeoCodingViewController () <MTCMapViewDelegate>

@property (nonatomic, strong) MTCMapView *mapView;
@property (nonatomic, strong) MTCExampleMapTestSupport *mapTestSupport;
@property (nonatomic, strong) MTCWebSettingsFloatView *floatView;
@property (nonatomic, strong) UIButton *toggleButton;
@property (nonatomic, strong, nullable) MTCMTCWebDetailPopupView *popupView;
@property (nonatomic, strong) MTCWebGeoCodingConfigModel *configModel;
@property (nonatomic, assign) BOOL loading;
@property (nonatomic, assign) BOOL listVisible;
@property (nonatomic, assign) BOOL mapReady;
@property (nonatomic, assign) MTCWebPopupPurpose activePopupPurpose;

@property (nonatomic, strong, nullable) MTCGeocodeResponse *response;
@property (nonatomic, copy, nullable) NSString *errorMessage;
@property (nonatomic, copy, nullable) NSString *selectedResultIdentifier;
@property (nonatomic, copy) NSDictionary<NSString *, MTCMarker *> *resultMarkers;
@property (nonatomic, assign) BOOL shouldReloadMarkers;

@end

@implementation MTCWebGeoCodingViewController

- (void)dealloc {
}

#pragma mark - Public

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureNavigationItems:YES];
    self.view.backgroundColor = UIColor.systemGroupedBackgroundColor;
    self.view.accessibilityIdentifier = MTCExampleTestAccessibilityWebGeoCodingScreen;
    self.configModel = [[MTCWebGeoCodingConfigModel alloc] init];
    self.loading = NO;
    self.listVisible = YES;
    self.activePopupPurpose = MTCWebPopupPurposeNone;
    self.resultMarkers = @{};

    [self configureMapView];
    [self configureFloatView];
    [self configureToggleButton];
    [self updateToggleButtonAppearance];
    [self applyLocalizedTexts];
}

#pragma mark - protocol

#pragma mark - Delegate
#pragma mark -- MTCMapViewDelegate

- (void)mapViewDidFinishLoadingMap:(MTCMapView *)mapView {
    (void)mapView;
    self.mapReady = YES;
    [self reloadMapMarkersFitIfNeeded];
    [self.mapTestSupport markMapRenderedReady];
    [self.mapTestSupport pauseMapRenderingIfUITesting:self.mapView];
}

- (void)mapView:(MTCMapView *)mapView didLoadMapStyleWithID:(NSString *)mapStyleID {
    (void)mapView;
    (void)mapStyleID;
    self.mapReady = YES;
    [self reloadMapMarkersFitIfNeeded];
    [self.mapTestSupport markMapRenderedReady];
    [self.mapTestSupport pauseMapRenderingIfUITesting:self.mapView];
}

- (void)mapView:(MTCMapView *)mapView didFinishSwitchingMapStyleWithID:(NSString *)mapStyleID {
    (void)mapView;
    (void)mapStyleID;
    self.mapReady = YES;
    [self reloadMapMarkersFitIfNeeded];
    [self.mapTestSupport markMapRenderedReady];
    [self.mapTestSupport pauseMapRenderingIfUITesting:self.mapView];
}

- (void)mapView:(MTCMapView *)mapView didTapOverlay:(id<MTCOverlay>)overlay {
    (void)mapView;
    MTCMarker *marker = [(id)overlay isKindOfClass:MTCMarker.class] ? (MTCMarker *)overlay : nil;
    if (!marker) {
        return;
    }
    NSString *identifier = [marker.userInfo isKindOfClass:NSString.class] ? (NSString *)marker.userInfo : nil;
    MTCGeocodeResult *result = [self resultForIdentifier:identifier];
    if (!result) {
        return;
    }
    if ([self.selectedResultIdentifier isEqualToString:identifier]) {
        [self presentPopupWithTitle:[result mtc_displayTitleWithFallbackIndex:NSNotFound]
                                text:[result mtc_detailText]
                             purpose:MTCWebPopupPurposeGeocodeResultDetail];
        [self.floatView reloadData];
        return;
    }
    [self selectResult:result identifier:identifier presentPopup:YES];
}

#pragma mark - Event

- (void)submitRequest {
    if (self.loading) {
        return;
    }

    self.loading = YES;
    self.response = nil;
    self.errorMessage = nil;
    [self clearSelectionAndDismissPopup];
    [self.floatView updateSections:[self buildSections]];

    MTCGeocodeRequest *request = [[MTCGeocodeRequest alloc] init];
    request.address = self.configModel.addressText.length > 0 ? self.configModel.addressText : nil;
    request.components = self.configModel.componentsText.length > 0 ? self.configModel.componentsText : nil;
    request.language = self.configModel.languageText.length > 0 ? self.configModel.languageText : nil;
    request.region = self.configModel.regionText.length > 0 ? self.configModel.regionText : nil;
    request.locationBias = [MTCLocationBias mtc_currentLocationBiasWithMode:self.configModel.biasEnabled ? MTCWebLocationModeBiasRectangle : MTCWebLocationModeNone
                                                               northEastText:self.configModel.rectNorthEastText
                                                               southWestText:self.configModel.rectSouthWestText
                                                                  centerText:@""
                                                                  radiusText:@""];

    __weak typeof(self) weakSelf = self;
    [[MTCGeocodeService sharedService] geocodeWithRequest:request completion:^(MTCGeocodeResponse * _Nullable response, NSError * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        strongSelf.loading = NO;
        strongSelf.response = response;
        strongSelf.errorMessage = error.localizedDescription;
        strongSelf.shouldReloadMarkers = YES;
        [strongSelf.floatView updateSections:[strongSelf buildSections]];
        [strongSelf reloadMapMarkersFitIfNeeded];
    }];
}

- (void)toggleListVisibility {
    self.listVisible = !self.listVisible;
    if (!self.listVisible) {
        [self dismissPopupPreservingSelection:YES];
        [self reloadMapMarkersFitIfNeeded];
    }
    [self updateListVisibilityAnimated:YES];
    [self updateToggleButtonAppearance];
}

#pragma mark - Private

- (void)configureMapView {
    self.mapView = [[MTCMapView alloc] initWithFrame:CGRectZero];
    self.mapView.translatesAutoresizingMaskIntoConstraints = NO;
    self.mapView.delegate = self;
    [self.view addSubview:self.mapView];
    [NSLayoutConstraint activateConstraints:@[
        [self.mapView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.mapView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.mapView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.mapView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];

    self.mapTestSupport = [[MTCExampleMapTestSupport alloc] init];
    [self.mapTestSupport installOnHostView:self.view];

    [self.mapView setCenterCoordinate:CLLocationCoordinate2DMake(MTCForwardGeocodeDefaultLatitude, MTCForwardGeocodeDefaultLongitude)
                            zoomLevel:10.5];
}

- (void)configureFloatView {
    self.floatView = [[MTCWebSettingsFloatView alloc] initWithTitle:self.title sections:[self buildSections]];
    self.floatView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.floatView];
    [NSLayoutConstraint activateConstraints:@[
        [self.floatView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.floatView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.floatView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.floatView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];
}

- (void)configureToggleButton {
    self.toggleButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.toggleButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.toggleButton.backgroundColor = UIColor.systemBlueColor;
    self.toggleButton.tintColor = UIColor.whiteColor;
    self.toggleButton.layer.cornerRadius = 26.0;
    self.toggleButton.layer.shadowColor = UIColor.blackColor.CGColor;
    self.toggleButton.layer.shadowOpacity = 0.18;
    self.toggleButton.layer.shadowRadius = 10.0;
    self.toggleButton.layer.shadowOffset = CGSizeMake(0.0, 6.0);
    [self.toggleButton addTarget:self action:@selector(toggleListVisibility) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.toggleButton];

    UILayoutGuide *guide = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [self.toggleButton.trailingAnchor constraintEqualToAnchor:guide.trailingAnchor constant:-16.0],
        [self.toggleButton.bottomAnchor constraintEqualToAnchor:guide.bottomAnchor constant:-16.0],
        [self.toggleButton.widthAnchor constraintEqualToConstant:52.0],
        [self.toggleButton.heightAnchor constraintEqualToConstant:52.0],
    ]];
}

- (void)updateToggleButtonAppearance {
    NSString *symbolName = self.listVisible ? @"map.fill" : @"list.bullet";
    [self.toggleButton setImage:[UIImage systemImageNamed:symbolName] forState:UIControlStateNormal];
    self.toggleButton.accessibilityLabel = self.listVisible ? [self localizedStringForKey:@"web_switch_to_map"] : [self localizedStringForKey:@"web_switch_to_list"];
}

- (void)updateListVisibilityAnimated:(BOOL)animated {
    void (^changes)(void) = ^{
        self.floatView.alpha = self.listVisible ? 1.0 : 0.0;
        self.floatView.transform = self.listVisible ? CGAffineTransformIdentity : CGAffineTransformMakeTranslation(0.0, 20.0);
    };
    void (^completion)(BOOL) = ^(__unused BOOL finished) {
        self.floatView.userInteractionEnabled = self.listVisible;
    };

    self.floatView.userInteractionEnabled = self.listVisible;
    if (animated) {
        [UIView animateWithDuration:0.22 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:changes completion:completion];
    } else {
        changes();
        completion(YES);
    }
}

- (NSArray<MTCWebSettingsSection *> *)buildSections {
    __weak typeof(self) weakSelf = self;
    NSMutableArray<MTCWebSettingsSection *> *sections = [NSMutableArray array];

    [sections addObject:[MTCWebSettingsSection sectionWithTitle:[self localizedStringForKey:@"web_request_parameters"]
                                                          items:@[
        [MTCWebSettingsItem textItemWithTitle:@"address"
                                  placeholder:[self localizedStringForKey:@"web_enter_address"]
                                       detail:[self localizedStringForKey:@"web_e_g_lorong"]
                                 keyboardType:UIKeyboardTypeDefault
                                       getter:^NSString *{ return weakSelf.configModel.addressText ?: @""; }
                                       setter:^(NSString *value) { weakSelf.configModel.addressText = value ?: @""; }],
        [MTCWebSettingsItem textItemWithTitle:@"components"
                                  placeholder:@"country:SG|postal_code:238801"
                                       detail:[self localizedStringForKey:@"web_structured_address_components_optional"]
                                 keyboardType:UIKeyboardTypeDefault
                                       getter:^NSString *{ return weakSelf.configModel.componentsText ?: @""; }
                                       setter:^(NSString *value) { weakSelf.configModel.componentsText = value ?: @""; }],
        [MTCWebSettingsItem toggleItemWithTitle:@"locationBias: Rectangle"
                                         detail:[self localizedStringForKey:@"web_bias_results_by_rectangle_when_enabled"]
                                         getter:^BOOL{ return weakSelf.configModel.biasEnabled; }
                                         setter:^(BOOL value) { weakSelf.configModel.biasEnabled = value; }],
        [[MTCWebSettingsItem textItemWithTitle:@"rectangle.northeast"
                                   placeholder:@"1.36,103.84"
                                        detail:[self localizedStringForKey:@"web_effective_when_locationbias_is_on"]
                                  keyboardType:UIKeyboardTypeNumbersAndPunctuation
                                        getter:^NSString *{ return weakSelf.configModel.rectNorthEastText ?: @""; }
                                        setter:^(NSString *value) { weakSelf.configModel.rectNorthEastText = value ?: @""; }]
         visibleWhen:^BOOL{ return weakSelf.configModel.biasEnabled; }],
        [[MTCWebSettingsItem textItemWithTitle:@"rectangle.southwest"
                                   placeholder:@"1.33,103.80"
                                        detail:[self localizedStringForKey:@"web_effective_when_locationbias_is_on"]
                                  keyboardType:UIKeyboardTypeNumbersAndPunctuation
                                        getter:^NSString *{ return weakSelf.configModel.rectSouthWestText ?: @""; }
                                        setter:^(NSString *value) { weakSelf.configModel.rectSouthWestText = value ?: @""; }]
         visibleWhen:^BOOL{ return weakSelf.configModel.biasEnabled; }],
        [MTCWebSettingsItem actionItemWithTitle:self.configModel.advancedExpanded ? [self localizedStringForKey:@"web_collapse_parameters"] : [self localizedStringForKey:@"web_expand_parameters"]
                                          style:MTCWebSettingsActionStyleSecondary
                                        handler:^{
            weakSelf.configModel.advancedExpanded = !weakSelf.configModel.advancedExpanded;
            [weakSelf.floatView updateSections:[weakSelf buildSections]];
        }],
    ]]];

    if (self.configModel.advancedExpanded) {
        [sections addObject:[MTCWebSettingsSection sectionWithTitle:[self localizedStringForKey:@"web_more_parameters"]
                                                              items:@[
            [MTCWebSettingsItem textItemWithTitle:@"language"
                                      placeholder:@"zh"
                                           detail:[self localizedStringForKey:@"web_ietf_language_tag_default_zh"]
                                     keyboardType:UIKeyboardTypeASCIICapable
                                           getter:^NSString *{ return weakSelf.configModel.languageText ?: @""; }
                                           setter:^(NSString *value) { weakSelf.configModel.languageText = value ?: @""; }],
            [MTCWebSettingsItem textItemWithTitle:@"region"
                                      placeholder:@"SG"
                                           detail:[self localizedStringForKey:@"web_cctld_2_chars"]
                                     keyboardType:UIKeyboardTypeASCIICapable
                                           getter:^NSString *{ return weakSelf.configModel.regionText ?: @""; }
                                           setter:^(NSString *value) { weakSelf.configModel.regionText = value ?: @""; }],
        ]]];
    }

    [sections addObject:[MTCWebSettingsSection sectionWithTitle:[self localizedStringForKey:@"overlay_actions"]
                                                          items:@[
        [[MTCWebSettingsItem actionItemWithTitle:self.loading ? [self localizedStringForKey:@"web_requesting"] : [self localizedStringForKey:@"web_send_request"]
                                           style:MTCWebSettingsActionStylePrimary
                                         handler:^{ [weakSelf submitRequest]; }]
         enabledWhen:^BOOL{ return weakSelf.loading == NO; }],
    ]]];

    if (self.errorMessage.length > 0) {
        [sections addObject:[MTCWebSettingsSection sectionWithTitle:[self localizedStringForKey:@"web_error"]
                                                              items:@[
            [MTCWebSettingsItem infoItemWithTitle:@"message" value:^NSString *{ return weakSelf.errorMessage ?: @""; }],
        ]]];
    }

    if (self.response.results.count > 0) {
        NSMutableArray<MTCWebSettingsItem *> *items = [NSMutableArray array];
        [self.response.results enumerateObjectsUsingBlock:^(MTCGeocodeResult * _Nonnull result, NSUInteger idx, BOOL * _Nonnull stop) {
            (void)stop;
            NSString *identifier = [result mtc_identifierWithFallbackIndex:idx];
            NSString *title = [result mtc_displayTitleWithFallbackIndex:idx];
            NSString *preview = [result mtc_previewText];
            NSString *hint = [weakSelf.selectedResultIdentifier isEqualToString:identifier] ? [self localizedStringForKey:@"web_selected_tap_again_after_closing_the_popup_to_de"] : [self localizedStringForKey:@"web_tap_to_view_details"];
            NSString *detail = preview.length > 0 ? [NSString stringWithFormat:@"%@\n%@", hint, preview] : hint;
            [items addObject:[MTCWebSettingsItem selectableInfoItemWithTitle:title
                                                                      detail:detail
                                                                       value:nil
                                                                    selected:^BOOL{
                return [weakSelf.selectedResultIdentifier isEqualToString:identifier];
            } handler:^{
                [weakSelf selectResult:result identifier:identifier presentPopup:YES];
            }]];
        }];
        [sections addObject:[MTCWebSettingsSection sectionWithTitle:[self localizedStringForKey:@"web_results"] items:items]];
    }

    if (self.response) {
        NSString *summary = [NSString stringWithFormat:@"results: %@%@",
                             @(self.response.results.count),
                             self.response.status.length > 0 ? [NSString stringWithFormat:@"\nstatus: %@", self.response.status] : @""];
        [sections addObject:[MTCWebSettingsSection sectionWithTitle:[self localizedStringForKey:@"web_response_json"]
                                                              items:@[
            [MTCWebSettingsItem selectableInfoItemWithTitle:@"raw"
                                                     detail:[self localizedStringForKey:@"web_tap_to_view_full_response_json"]
                                                      value:^NSString *{ return summary; }
                                                   selected:nil
                                                    handler:^{
                [weakSelf presentPopupWithTitle:[self localizedStringForKey:@"web_response_json"]
                                            text:[MTCWebSupportUtil mtc_prettyJSONStringFromDictionary:weakSelf.response.rawDictionary ?: @{}]
                                         purpose:MTCWebPopupPurposeResponseRaw];
            }],
        ]]];
    }

    return sections;
}

- (void)selectResult:(MTCGeocodeResult *)result identifier:(NSString *)identifier presentPopup:(BOOL)presentPopup {
    if (identifier.length == 0) {
        return;
    }
    NSString *previousIdentifier = self.selectedResultIdentifier;
    if ([self.selectedResultIdentifier isEqualToString:identifier] && self.activePopupPurpose == MTCWebPopupPurposeNone) {
        self.selectedResultIdentifier = nil;
        [self applyMarkerSelectionStateChangeFromIdentifier:previousIdentifier toIdentifier:nil];
        [self dismissPopupPreservingSelection:NO];
        [self.floatView reloadData];
        return;
    }

    self.selectedResultIdentifier = identifier;
    [self applyMarkerSelectionStateChangeFromIdentifier:previousIdentifier toIdentifier:identifier];
    if (presentPopup) {
        [self presentPopupWithTitle:[result mtc_displayTitleWithFallbackIndex:NSNotFound]
                                text:[result mtc_detailText]
                             purpose:MTCWebPopupPurposeGeocodeResultDetail];
    }
    [self.floatView reloadData];
}

- (void)presentPopupWithTitle:(NSString *)title text:(NSString *)text purpose:(MTCWebPopupPurpose)purpose {
    [self dismissPopupWithoutSelectionMutation];
    self.activePopupPurpose = purpose;

    MTCMTCWebDetailPopupView *popupView = [[MTCMTCWebDetailPopupView alloc] initWithFrame:CGRectZero];
    self.popupView = popupView;

    __weak typeof(self) weakSelf = self;
    [popupView presentInView:self.view title:title text:text dismissHandler:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        strongSelf.popupView = nil;
        strongSelf.activePopupPurpose = MTCWebPopupPurposeNone;
        [strongSelf.floatView reloadData];
    }];
}

- (void)dismissPopupWithoutSelectionMutation {
    if (!self.popupView) {
        return;
    }
    dispatch_block_t dismissHandler = self.popupView.dismissHandler;
    self.popupView.dismissHandler = nil;
    [self.popupView removeFromSuperview];
    self.popupView = nil;
    if (dismissHandler) {
        dismissHandler();
    }
}

- (void)dismissPopupPreservingSelection:(BOOL)preserveSelection {
    [self dismissPopupWithoutSelectionMutation];
    self.activePopupPurpose = MTCWebPopupPurposeNone;
    if (!preserveSelection) {
        self.selectedResultIdentifier = nil;
    }
    [self.floatView reloadData];
}

- (void)clearSelectionAndDismissPopup {
    NSString *previousIdentifier = self.selectedResultIdentifier;
    self.selectedResultIdentifier = nil;
    [self applyMarkerSelectionStateChangeFromIdentifier:previousIdentifier toIdentifier:nil];
    [self dismissPopupPreservingSelection:NO];
}

- (void)applyMarkerSelectionStateChangeFromIdentifier:(NSString *)previousIdentifier
                                         toIdentifier:(NSString *)currentIdentifier {
    if (!self.mapReady || self.resultMarkers.count == 0) {
        return;
    }

    MTCMarker *previousMarker = previousIdentifier.length > 0 ? self.resultMarkers[previousIdentifier] : nil;
    MTCMarker *currentMarker = currentIdentifier.length > 0 ? self.resultMarkers[currentIdentifier] : nil;
    if (!previousMarker && !currentMarker) {
        return;
    }

    [self.mapView performOverlayUpdates:^{
        if (previousMarker && previousMarker != currentMarker) {
            previousMarker.selected = NO;
//            previousMarker.zIndex = 10;
        }
        if (currentMarker) {
            currentMarker.selected = YES;
//            currentMarker.zIndex = 100;
        }
    }];
}

- (void)reloadMapMarkersFitIfNeeded {
    if (!self.mapReady) {
        return;
    }
    if (!self.shouldReloadMarkers) {
        [self updateMapCameraFitIfNeeded];
        return;
    }
    self.shouldReloadMarkers = NO;

    [self.mapView removeAllInfoWindows];
    [self.mapView removeAllOverlays];

    if (self.response.results.count == 0) {
        self.resultMarkers = @{};
        return;
    }

    NSMutableArray<id<MTCOverlay>> *markers = [NSMutableArray array];
    NSMutableDictionary<NSString *, MTCMarker *> *markersByIdentifier = [NSMutableDictionary dictionary];
    [self.response.results enumerateObjectsUsingBlock:^(MTCGeocodeResult * _Nonnull result, NSUInteger idx, BOOL * _Nonnull stop) {
        (void)stop;
        NSNumber *latitude = result.geometry.location.latitude;
        NSNumber *longitude = result.geometry.location.longitude;
        if (!latitude || !longitude) {
            return;
        }
        NSString *identifier = [result mtc_identifierWithFallbackIndex:idx];
        if (identifier.length == 0) {
            return;
        }
        MTCMarker *marker = [[MTCMarker alloc] initWithCoordinate:CLLocationCoordinate2DMake(latitude.doubleValue, longitude.doubleValue)];
        NSString *title = [result mtc_displayTitleWithFallbackIndex:idx];
        marker.userInfo = identifier;
        marker.style = [self defaultMarkerStyle];
        marker.selectedStyle = [self selectedMarkerStyle];
        marker.style.title.text = title;
        marker.selectedStyle.title.text = title;
        marker.selected = [self.selectedResultIdentifier isEqualToString:identifier];
        marker.zIndex = marker.isSelected ? 100 : 10;
        marker.togglesSelectionOnTap = NO;
        [markers addObject:marker];
        markersByIdentifier[identifier] = marker;
    }];

    self.resultMarkers = markersByIdentifier;
    if (markers.count > 0) {
        [self.mapView addOverlays:markers];
    }
    [self updateMapCameraFitIfNeeded];
}

- (void)updateMapCameraFitIfNeeded {
    MTCGeocodeResult *selectedResult = self.selectedResultIdentifier.length > 0 ? [self resultForIdentifier:self.selectedResultIdentifier] : nil;
    NSNumber *selectedLatitude = selectedResult.geometry.location.latitude;
    NSNumber *selectedLongitude = selectedResult.geometry.location.longitude;
    if (selectedLatitude && selectedLongitude) {
        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(selectedLatitude.doubleValue, selectedLongitude.doubleValue);
        [self.mapView setCenterCoordinate:coordinate
                                transition:[MTCCameraTransition easeWithDuration:0.25] completion:nil];
        return;
    }
    NSArray<MTCGeocodeResult *> *coordinateResults = [self resultsWithCoordinates];
    if (coordinateResults.count == 0) {
        return;
    }
    if (coordinateResults.count == 1) {
        MTCGeocodeResult *result = coordinateResults.firstObject;
        [self.mapView setCenterCoordinate:CLLocationCoordinate2DMake(result.geometry.location.latitude.doubleValue, result.geometry.location.longitude.doubleValue)
                                zoomLevel:MTCForwardGeocodeSinglePlaceZoomLevel];
        return;
    }

    CLLocationDegrees minLatitude = DBL_MAX;
    CLLocationDegrees maxLatitude = -DBL_MAX;
    CLLocationDegrees minLongitude = DBL_MAX;
    CLLocationDegrees maxLongitude = -DBL_MAX;
    for (MTCGeocodeResult *result in coordinateResults) {
        minLatitude = MIN(minLatitude, result.geometry.location.latitude.doubleValue);
        maxLatitude = MAX(maxLatitude, result.geometry.location.latitude.doubleValue);
        minLongitude = MIN(minLongitude, result.geometry.location.longitude.doubleValue);
        maxLongitude = MAX(maxLongitude, result.geometry.location.longitude.doubleValue);
    }

    MTCCoordinateBounds bounds = MTCCoordinateBoundsMake(CLLocationCoordinate2DMake(minLatitude, minLongitude),
                                                         CLLocationCoordinate2DMake(maxLatitude, maxLongitude));
    [self.mapView setVisibleCoordinateBounds:bounds
                                 edgePadding:UIEdgeInsetsMake(80.0, 40.0, 160.0, 40.0)
                                  transition:[MTCCameraTransition easeWithDuration:0.25] completion:nil];
}

- (NSArray<MTCGeocodeResult *> *)resultsWithCoordinates {
    NSMutableArray<MTCGeocodeResult *> *results = [NSMutableArray array];
    for (MTCGeocodeResult *result in self.response.results) {
        if (result.geometry.location.latitude && result.geometry.location.longitude) {
            [results addObject:result];
        }
    }
    return results;
}

- (MTCMarkerStyle *)defaultMarkerStyle {
    MTCMarkerStyle *style = [[MTCMarkerStyle alloc] init];
    style.icon.type = MTCMarkerIconTypeBlueDot;
    return style;
}

- (MTCMarkerStyle *)selectedMarkerStyle {
    MTCMarkerStyle *style = [[MTCMarkerStyle alloc] init];
    style.icon.type = MTCMarkerIconTypeRedDot;
    return style;
}

- (MTCGeocodeResult *)resultForIdentifier:(NSString *)identifier {
    if (identifier.length == 0) {
        return nil;
    }
    __block MTCGeocodeResult *matchedResult = nil;
    [self.response.results enumerateObjectsUsingBlock:^(MTCGeocodeResult * _Nonnull result, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *currentIdentifier = [result mtc_identifierWithFallbackIndex:idx];
        if ([currentIdentifier isEqualToString:identifier]) {
            matchedResult = result;
            *stop = YES;
        }
    }];
    return matchedResult;
}

#pragma mark -- multi-language

- (void)demoLanguageDidChange {
    [self applyLocalizedTexts];
}

- (void)applyLocalizedTexts {
    self.title = [self localizedStringForKey:@"demo_title_MTCWebGeoCodingViewController"];
    if (self.mapView) {
        self.mapView.mapLanguage = [self mapLanguageForDemoLanguage:self.demoLanguage];
    }
    if (self.floatView) {
        [self.floatView updateTitle:self.title];
        [self.floatView updateSections:[self buildSections]];
    }
}
@end
