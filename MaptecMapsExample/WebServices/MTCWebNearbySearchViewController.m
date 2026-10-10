#import "MTCWebNearbySearchViewController.h"

#import "MTCExampleMapTestSupport.h"
#import "MTCExampleTestAccessibility.h"
#import "MTCWebSettingsFloatView.h"
#import "MTCTextSearchRequestParams+MTCSupportFork.h"
#import "MTCMTCWebDetailPopupView.h"
#import "MTCWebSupportUtil.h"

#import <float.h>
#import <MaptecMapsKit/MaptecMapsKit.h>

static const CLLocationDegrees MTCNearbySearchDefaultLatitude = 1.3521;
static const CLLocationDegrees MTCNearbySearchDefaultLongitude = 103.8198;
static const double MTCNearbySearchSinglePlaceZoomLevel = 14.0;

@interface MTCWebNearbySearchConfigModel : NSObject

@property (nonatomic, copy) NSString *centerText;
@property (nonatomic, copy) NSString *radiusText;
@property (nonatomic, copy) NSString *typesText;
@property (nonatomic, assign) NSInteger typesIndex;
@property (nonatomic, copy) NSString *resultLimitText;
@property (nonatomic, copy) NSString *languageText;
@property (nonatomic, copy) NSString *regionText;
@property (nonatomic, copy) NSArray<NSString *> *extraFields;
@property (nonatomic, assign) NSInteger rankIndex;
@property (nonatomic, assign) BOOL advancedExpanded;

@end

@implementation MTCWebNearbySearchConfigModel

- (instancetype)init {
    self = [super init];
    if (self) {
        _centerText = @"1.360879,103.732578";
        _radiusText = @"";
        _typesText = @"";
        _typesIndex = 0;
        _resultLimitText = @"";
        _languageText = @"zh";
        _regionText = @"";
        _extraFields = @[];
        _rankIndex = 2;
        _advancedExpanded = NO;
    }
    return self;
}

@end

@interface MTCWebNearbySearchViewController () <MTCMapViewDelegate>

@property (nonatomic, strong) MTCMapView *mapView;
@property (nonatomic, strong) MTCExampleMapTestSupport *mapTestSupport;
@property (nonatomic, strong) MTCWebSettingsFloatView *floatView;
@property (nonatomic, strong) UIButton *toggleButton;
@property (nonatomic, strong, nullable) MTCMTCWebDetailPopupView *popupView;
@property (nonatomic, strong) MTCWebNearbySearchConfigModel *configModel;
@property (nonatomic, assign) BOOL loading;
@property (nonatomic, assign) BOOL listVisible;
@property (nonatomic, assign) BOOL mapReady;
@property (nonatomic, assign) MTCWebPopupPurpose activePopupPurpose;

@property (nonatomic, strong, nullable) MTCNearbySearchResponse *response;
 /// 搜索结果列表
@property (nonatomic, copy) NSArray<MTCPlace *> *places;
@property (nonatomic, copy, nullable) NSString *errorMessage;
@property (nonatomic, copy, nullable) NSString *selectedPlaceID;
@property (nonatomic, strong, nullable) MTCPlace *selectedPlace;
@property (nonatomic, copy) NSDictionary<NSString *, MTCMarker *> *placeMarkers;
@property (nonatomic, assign) BOOL shouldReloadMarkers;

@end

@implementation MTCWebNearbySearchViewController

- (void)dealloc {
}

#pragma mark - Public

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureNavigationItems:YES];
    self.view.backgroundColor = UIColor.systemGroupedBackgroundColor;
    self.view.accessibilityIdentifier = MTCExampleTestAccessibilityWebNearbySearchScreen;
    self.configModel = [[MTCWebNearbySearchConfigModel alloc] init];
    self.loading = NO;
    self.listVisible = YES;
    self.activePopupPurpose = MTCWebPopupPurposeNone;
    self.places = @[];
    self.placeMarkers = @{};

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
    [self reloadMapMarkersFitIfNeeded:YES];
    [self.mapTestSupport markMapRenderedReady];
    [self.mapTestSupport pauseMapRenderingIfUITesting:self.mapView];
}

- (void)mapView:(MTCMapView *)mapView didLoadMapStyleWithID:(NSString *)mapStyleID {
    (void)mapView;
    (void)mapStyleID;
    self.mapReady = YES;
    [self reloadMapMarkersFitIfNeeded:YES];
    [self.mapTestSupport markMapRenderedReady];
    [self.mapTestSupport pauseMapRenderingIfUITesting:self.mapView];
}

- (void)mapView:(MTCMapView *)mapView didFinishSwitchingMapStyleWithID:(NSString *)mapStyleID {
    (void)mapView;
    (void)mapStyleID;
    self.mapReady = YES;
    [self.mapTestSupport markMapRenderedReady];
    [self.mapTestSupport pauseMapRenderingIfUITesting:self.mapView];
}

- (void)mapView:(MTCMapView *)mapView didTapOverlay:(id<MTCOverlay>)overlay {
    (void)mapView;
    MTCMarker *marker = [(id)overlay isKindOfClass:MTCMarker.class] ? (MTCMarker *)overlay : nil;
    if (!marker) {
        return;
    }
    NSString *placeID = [marker.userInfo isKindOfClass:NSString.class] ? (NSString *)marker.userInfo : nil;
    if (placeID.length == 0) {
        return;
    }
    MTCPlace *place = [self placeForIdentifier:placeID];
    if (!place) {
        return;
    }
    if ([self.selectedPlaceID isEqualToString:placeID]) {
        self.selectedPlace = place;
        [self presentPopupWithTitle:[place mtc_displayTitleWithFallbackIndex:NSNotFound]
                                text:[place mtc_detailText]
                             purpose:MTCWebPopupPurposePlaceDetail];
        [self.floatView reloadData];
        [self focusSelectedPlaceIfNeeded];
        return;
    }
    [self selectPlace:place identifier:placeID presentPopup:YES];
}

#pragma mark - Event

- (void)submitRequest {
    if (self.loading) {
        return;
    }

    MTCCoordinate *center = [MTCCoordinate mtc_coordinateFromString:self.configModel.centerText];
    NSString *trimmedRadius = [self.configModel.radiusText stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    NSInteger radius = trimmedRadius.integerValue;
    if (!center || trimmedRadius.length == 0 || radius < 0 || radius > 50000) {
        self.errorMessage = [self localizedStringForKey:@"web_invalid_center_or_radius_radius_must_be_0_50000"];
        [self.floatView updateSections:[self buildSections]];
        return;
    }

    self.loading = YES;
    self.errorMessage = nil;
    self.response = nil;
    self.places = @[];
    [self clearSelectionAndDismissPopup];
    [self.floatView updateSections:[self buildSections]];

    MTCNearbySearchRequest *request = [[MTCNearbySearchRequest alloc] init];
    request.locationLimit = [[MTCLocationCircle alloc] initWithCenter:center radius:radius];
    request.types = self.configModel.typesText.length > 0 ? self.configModel.typesText : nil;
    request.resultLimit = [self numberFromString:self.configModel.resultLimitText];
    request.rankType = [self rankTypeForIndex:self.configModel.rankIndex];
    request.language = self.configModel.languageText.length > 0 ? self.configModel.languageText : nil;
    request.region = self.configModel.regionText.length > 0 ? self.configModel.regionText : nil;
    request.extraFields = self.configModel.extraFields.count > 0 ? self.configModel.extraFields : nil;

    __weak typeof(self) weakSelf = self;
    [[MTCSearchService sharedService] nearbySearchWithRequest:request completion:^(MTCNearbySearchResponse * _Nullable response, NSError * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        strongSelf.loading = NO;
        strongSelf.response = response;
        strongSelf.errorMessage = error.localizedDescription;
        strongSelf.places = response.places ?: @[];
        strongSelf.shouldReloadMarkers = YES;
        [strongSelf.floatView updateSections:[strongSelf buildSections]];
        [strongSelf reloadMapMarkersFitIfNeeded:(strongSelf.listVisible == NO)];
    }];
}

- (void)toggleListVisibility {
    self.listVisible = !self.listVisible;
    if (!self.listVisible) {
        [self dismissPopupPreservingSelection:YES];
        [self reloadMapMarkersFitIfNeeded:YES];
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

    [self.mapView setCenterCoordinate:CLLocationCoordinate2DMake(MTCNearbySearchDefaultLatitude, MTCNearbySearchDefaultLongitude)
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
        [MTCWebSettingsItem textItemWithTitle:@"center(lat,lng)"
                                  placeholder:@"1.360879,103.732578"
                                       detail:[self localizedStringForKey:@"web_center_coordinate"]
                                 keyboardType:UIKeyboardTypeNumbersAndPunctuation
                                       getter:^NSString *{ return weakSelf.configModel.centerText ?: @""; }
                                       setter:^(NSString *value) { weakSelf.configModel.centerText = value ?: @""; }],
        [MTCWebSettingsItem textItemWithTitle:@"radius(m)"
                                  placeholder:@"0~50000"
                                       detail:[self localizedStringForKey:@"web_required"]
                                 keyboardType:UIKeyboardTypeNumberPad
                                       getter:^NSString *{ return weakSelf.configModel.radiusText ?: @""; }
                                       setter:^(NSString *value) { weakSelf.configModel.radiusText = value ?: @""; }],
        [MTCWebSettingsItem optionItemWithTitle:@"types"
                                         detail:[self localizedStringForKey:@"web_optional_poi_subtype"]
                                        options:[MTCWebSupportUtil mtc_poiTypeOptions]
                                         getter:^NSInteger{ return weakSelf.configModel.typesIndex; }
                                         setter:^(NSInteger index) {
            weakSelf.configModel.typesIndex = index;
            weakSelf.configModel.typesText = [MTCWebSupportUtil mtc_poiTypeForIndex:index];
        }],
        [MTCWebSettingsItem textViewItemWithTitle:@"extraFields"
                                      placeholder:@"aoi,phoneNumbers,summary"
                                           detail:@"comma or newline-separated"
                                     keyboardType:UIKeyboardTypeASCIICapable
                                  accessoryInputs:[MTCWebSupportUtil mtc_placeExtraFieldOptions]
                                           getter:^NSString *{
            return [MTCWebSupportUtil mtc_textFromExtraFields:weakSelf.configModel.extraFields];
        } setter:^(NSString *value) {
            weakSelf.configModel.extraFields = [MTCWebSupportUtil mtc_extraFieldsFromText:value ?: @""] ?: @[];
        }],
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
            [MTCWebSettingsItem textItemWithTitle:@"resultLimit"
                                      placeholder:@"1~20"
                                           detail:[self localizedStringForKey:@"web_1_20_default_20"]
                                     keyboardType:UIKeyboardTypeNumberPad
                                           getter:^NSString *{ return weakSelf.configModel.resultLimitText ?: @""; }
                                           setter:^(NSString *value) { weakSelf.configModel.resultLimitText = value ?: @""; }],
            [MTCWebSettingsItem optionItemWithTitle:@"rank"
                                             detail:[self localizedStringForKey:@"web_default_distance"]
                                            options:@[[self localizedStringForKey:@"web_not_set"], @"RELEVANCE", @"DISTANCE", @"POPULARITY"]
                                             getter:^NSInteger{ return weakSelf.configModel.rankIndex; }
                                             setter:^(NSInteger index) { weakSelf.configModel.rankIndex = index; }],
            [MTCWebSettingsItem textItemWithTitle:@"language"
                                      placeholder:@"zh"
                                           detail:[self localizedStringForKey:@"web_ietf_language_tag_default_zh"]
                                     keyboardType:UIKeyboardTypeASCIICapable
                                           getter:^NSString *{ return weakSelf.configModel.languageText ?: @""; }
                                           setter:^(NSString *value) { weakSelf.configModel.languageText = value ?: @""; }],
            [MTCWebSettingsItem textItemWithTitle:@"region"
                                      placeholder:@"SG"
                                           detail:[self localizedStringForKey:@"web_cctld_2_chars_e_g_br"]
                                     keyboardType:UIKeyboardTypeASCIICapable
                                           getter:^NSString *{ return weakSelf.configModel.regionText ?: @""; }
                                           setter:^(NSString *value) { weakSelf.configModel.regionText = value ?: @""; }],
        ]]];
    }

    [sections addObject:[MTCWebSettingsSection sectionWithTitle:[self localizedStringForKey:@"overlay_actions"]
                                                          items:@[
        [[MTCWebSettingsItem actionItemWithTitle:self.loading ? [self localizedStringForKey:@"web_searching"] : [self localizedStringForKey:@"web_search"]
                                           style:MTCWebSettingsActionStylePrimary
                                         handler:^{
            NSString *radius = [weakSelf.configModel.radiusText stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
            if (weakSelf.loading || radius.length <= 0) {
                return;
            }
            [weakSelf submitRequest];
        }] enabledWhen:^BOOL{
            NSString *radius = [weakSelf.configModel.radiusText stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
            return weakSelf.loading == NO && radius.length > 0;
        }],
    ]]];

    if (self.errorMessage.length > 0) {
        [sections addObject:[MTCWebSettingsSection sectionWithTitle:[self localizedStringForKey:@"web_error"]
                                                              items:@[
            [MTCWebSettingsItem infoItemWithTitle:@"message" value:^NSString *{ return weakSelf.errorMessage ?: @""; }],
        ]]];
    }

    if (self.places.count > 0) {
        NSMutableArray<MTCWebSettingsItem *> *items = [NSMutableArray array];
        [self.places enumerateObjectsUsingBlock:^(MTCPlace * _Nonnull place, NSUInteger idx, BOOL * _Nonnull stop) {
            (void)stop;
            NSString *placeID = [place mtc_identifierWithFallbackIndex:idx];
            NSString *title = [place mtc_displayTitleWithFallbackIndex:idx];
            NSString *subtitle = [place mtc_previewText];
            NSString *selectionHint = [weakSelf.selectedPlaceID isEqualToString:placeID] ? [self localizedStringForKey:@"web_selected_tap_again_after_closing_the_popup_to_de"] : [self localizedStringForKey:@"web_tap_to_view_details"];
            NSString *detail = subtitle.length > 0 ? [NSString stringWithFormat:@"%@\n%@", selectionHint, subtitle] : selectionHint;
            [items addObject:[MTCWebSettingsItem selectableInfoItemWithTitle:title
                                                                      detail:detail
                                                                       value:nil
                                                                    selected:^BOOL{
                return [weakSelf.selectedPlaceID isEqualToString:placeID];
            } handler:^{
                [weakSelf selectPlace:place identifier:placeID presentPopup:YES];
            }]];
        }];
        [sections addObject:[MTCWebSettingsSection sectionWithTitle:[self localizedStringForKey:@"web_results"] items:items]];
    }

    if (self.response) {
        NSString *summary = [NSString stringWithFormat:@"places: %@%@%@",
                             @(self.places.count),
                             self.response.status.length > 0 ? [NSString stringWithFormat:@"\nstatus: %@", self.response.status] : @"",
                             self.response.nextPageToken.length > 0 ? [NSString stringWithFormat:@"\nnextPageToken: %@", self.response.nextPageToken] : @""];
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

- (void)resetSelectInfo {
    NSString *previousIdentifier = self.selectedPlaceID;
    self.selectedPlaceID = nil;
    self.selectedPlace = nil;
    [self applyMarkerSelectionStateChangeFromIdentifier:previousIdentifier toIdentifier:nil];
    [self dismissPopupPreservingSelection:NO];
}

- (void)selectPlace:(MTCPlace *)place identifier:(NSString *)identifier presentPopup:(BOOL)presentPopup {
    if (identifier.length == 0) {
        return;
    }
    NSString *previousIdentifier = self.selectedPlaceID;
    if ([self.selectedPlaceID isEqualToString:identifier] && self.activePopupPurpose == MTCWebPopupPurposeNone) {
        self.selectedPlaceID = nil;
        self.selectedPlace = nil;
        [self applyMarkerSelectionStateChangeFromIdentifier:previousIdentifier toIdentifier:nil];
        [self dismissPopupPreservingSelection:NO];
        [self.floatView reloadData];
        return;
    }

    self.selectedPlaceID = identifier;
    self.selectedPlace = place;
    [self applyMarkerSelectionStateChangeFromIdentifier:previousIdentifier toIdentifier:identifier];
    if (presentPopup) {
        [self presentPopupWithTitle:[place mtc_displayTitleWithFallbackIndex:NSNotFound]
                                text:[place mtc_detailText]
                             purpose:MTCWebPopupPurposePlaceDetail];
    }
    [self.floatView reloadData];
    [self focusSelectedPlaceIfNeeded];
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
        if (strongSelf.selectedPlaceID.length > 0) {
            [strongSelf.floatView reloadData];
        }
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
        self.selectedPlaceID = nil;
        self.selectedPlace = nil;
    }
    [self.floatView reloadData];
}

- (void)clearSelectionAndDismissPopup {
    NSString *previousIdentifier = self.selectedPlaceID;
    self.selectedPlaceID = nil;
    self.selectedPlace = nil;
    [self applyMarkerSelectionStateChangeFromIdentifier:previousIdentifier toIdentifier:nil];
    [self dismissPopupPreservingSelection:NO];
}

- (void)applyMarkerSelectionStateChangeFromIdentifier:(NSString *)previousIdentifier
                                         toIdentifier:(NSString *)currentIdentifier {
    if (!self.mapReady || self.placeMarkers.count == 0) {
        return;
    }

    MTCMarker *previousMarker = previousIdentifier.length > 0 ? self.placeMarkers[previousIdentifier] : nil;
    MTCMarker *currentMarker = currentIdentifier.length > 0 ? self.placeMarkers[currentIdentifier] : nil;
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

- (void)reloadMapMarkersFitIfNeeded:(BOOL)fitIfNeeded {
    if (!self.mapReady) {
        return;
    }
    if (!self.shouldReloadMarkers) {
        if (fitIfNeeded) {
            [self fitCoordinatePlacesIfNeeded];
        }
        return;
    }
    self.shouldReloadMarkers = NO;
    [self.mapView removeAllInfoWindows];
    [self.mapView removeAllOverlays];

    if (self.places.count == 0) {
        self.placeMarkers = @{};
        return;
    }

    NSMutableArray<id<MTCOverlay>> *markers = [NSMutableArray array];
    NSMutableDictionary<NSString *, MTCMarker *> *markersByIdentifier = [NSMutableDictionary dictionary];
    [self.places enumerateObjectsUsingBlock:^(MTCPlace * _Nonnull place, NSUInteger idx, BOOL * _Nonnull stop) {
        (void)stop;
        if (!place.latitude || !place.longitude) {
            return;
        }
        NSString *placeID = [place mtc_identifierWithFallbackIndex:idx];
        if (placeID.length == 0) {
            return;
        }
        MTCMarker *marker = [[MTCMarker alloc] initWithCoordinate:CLLocationCoordinate2DMake(place.latitude.doubleValue, place.longitude.doubleValue)];
        NSString *title = [place mtc_displayTitleWithFallbackIndex:idx];
        marker.userInfo = placeID;
        marker.style = [self defaultMarkerStyle];
        marker.selectedStyle = [self selectedMarkerStyle];
        marker.style.title.text = title;
        marker.selectedStyle.title.text = title;
        marker.selected = [self.selectedPlaceID isEqualToString:placeID];
        marker.zIndex = marker.isSelected ? 100 : 10;
        marker.togglesSelectionOnTap = NO;
        [markers addObject:marker];
        markersByIdentifier[placeID] = marker;
    }];
    self.placeMarkers = markersByIdentifier;
    if (markers.count > 0) {
        [self.mapView addOverlays:markers];
    }
    if (fitIfNeeded) {
        [self fitCoordinatePlacesIfNeeded];
    }
}

- (void)focusSelectedPlaceIfNeeded {
    MTCPlace *selectedPlace = self.selectedPlaceID.length > 0 ? [self placeForIdentifier:self.selectedPlaceID] : nil;
    if (!selectedPlace.latitude || !selectedPlace.longitude) {
        return;
    }

    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(selectedPlace.latitude.doubleValue, selectedPlace.longitude.doubleValue);
    [self.mapView setCenterCoordinate:coordinate
                            transition:[MTCCameraTransition easeWithDuration:0.25] completion:nil];
}

- (void)fitCoordinatePlacesIfNeeded {
    NSArray<MTCPlace *> *coordinatePlaces = [self placesWithCoordinates];
    if (coordinatePlaces.count == 0) {
        return;
    }
    if (coordinatePlaces.count == 1) {
        MTCPlace *place = coordinatePlaces.firstObject;
        [self.mapView setCenterCoordinate:CLLocationCoordinate2DMake(place.latitude.doubleValue, place.longitude.doubleValue)
                                zoomLevel:MTCNearbySearchSinglePlaceZoomLevel];
        return;
    }

    CLLocationDegrees minLatitude = DBL_MAX;
    CLLocationDegrees maxLatitude = -DBL_MAX;
    CLLocationDegrees minLongitude = DBL_MAX;
    CLLocationDegrees maxLongitude = -DBL_MAX;
    for (MTCPlace *place in coordinatePlaces) {
        minLatitude = MIN(minLatitude, place.latitude.doubleValue);
        maxLatitude = MAX(maxLatitude, place.latitude.doubleValue);
        minLongitude = MIN(minLongitude, place.longitude.doubleValue);
        maxLongitude = MAX(maxLongitude, place.longitude.doubleValue);
    }
    MTCCoordinateBounds bounds = MTCCoordinateBoundsMake(CLLocationCoordinate2DMake(minLatitude, minLongitude),
                                                         CLLocationCoordinate2DMake(maxLatitude, maxLongitude));
    [self.mapView setVisibleCoordinateBounds:bounds
                                 edgePadding:UIEdgeInsetsMake(80.0, 40.0, 160.0, 40.0)
                                  transition:[MTCCameraTransition easeWithDuration:0.25] completion:nil];
}

- (NSArray<MTCPlace *> *)placesWithCoordinates {
    NSMutableArray<MTCPlace *> *places = [NSMutableArray array];
    for (MTCPlace *place in self.places) {
        if (place.latitude && place.longitude) {
            [places addObject:place];
        }
    }
    return places;
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

- (MTCPlace *)placeForIdentifier:(NSString *)identifier {
    if (identifier.length == 0) {
        return nil;
    }
    __block MTCPlace *matchedPlace = nil;
    [self.places enumerateObjectsUsingBlock:^(MTCPlace * _Nonnull place, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *placeID = [place mtc_identifierWithFallbackIndex:idx];
        if ([placeID isEqualToString:identifier]) {
            matchedPlace = place;
            *stop = YES;
        }
    }];
    return matchedPlace;
}

- (NSNumber *)numberFromString:(NSString *)string {
    NSInteger value = string.integerValue;
    if (value < 1 || value > 20) {
        return nil;
    }
    return @(value);
}

- (MTCSearchRankType)rankTypeForIndex:(NSInteger)index {
    switch (index) {
        case 1: return MTCSearchRankTypeRelevance;
        case 2: return MTCSearchRankTypeDistance;
        case 3: return MTCSearchRankTypePopularity;
        default: return MTCSearchRankTypeUnspecified;
    }
}

#pragma mark -- multi-language

- (void)demoLanguageDidChange {
    [self applyLocalizedTexts];
}

- (void)applyLocalizedTexts {
    self.title = [self localizedStringForKey:@"demo_title_MTCWebNearbySearchViewController"];
    if (self.mapView) {
        self.mapView.mapLanguage = [self mapLanguageForDemoLanguage:self.demoLanguage];
    }
    if (self.floatView) {
        [self.floatView updateTitle:self.title];
        [self.floatView updateSections:[self buildSections]];
    }
}

#pragma mark - Getter & Setter

@end
