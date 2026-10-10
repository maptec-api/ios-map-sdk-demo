#import "MTCWebInputTipsViewController.h"

#import "MTCExampleMapTestSupport.h"
#import "MTCExampleTestAccessibility.h"
#import "MTCMTCWebDetailPopupView.h"
#import "MTCTextSearchRequestParams+MTCSupportFork.h"
#import "MTCWebSettingsFloatView.h"
#import "MTCWebSupportUtil.h"

#import <MaptecMapsKit/MaptecMapsKit.h>

static const CLLocationDegrees MTCSuggestDefaultLatitude = 1.3521;
static const CLLocationDegrees MTCSuggestDefaultLongitude = 103.8198;
static const double MTCSuggestSinglePlaceZoomLevel = 14.0;

@interface MTCWebInputTipsConfigModel : NSObject

@property (nonatomic, copy) NSString *queryText;
@property (nonatomic, copy) NSString *typesText;
@property (nonatomic, assign) NSInteger typesIndex;
@property (nonatomic, copy) NSString *resultLimitText;
@property (nonatomic, copy) NSString *languageText;
@property (nonatomic, copy) NSString *regionText;
@property (nonatomic, copy) NSString *rectNorthEastText;
@property (nonatomic, copy) NSString *rectSouthWestText;
@property (nonatomic, copy) NSString *circleCenterText;
@property (nonatomic, copy) NSString *circleRadiusText;
@property (nonatomic, assign) NSInteger locationModeIndex;
@property (nonatomic, assign) BOOL advancedExpanded;

@end

@implementation MTCWebInputTipsConfigModel

- (instancetype)init {
    self = [super init];
    if (self) {
        _queryText = @"";
        _typesText = @"";
        _typesIndex = 0;
        _resultLimitText = @"";
        _languageText = @"zh";
        _regionText = @"";
        _rectNorthEastText = @"";
        _rectSouthWestText = @"";
        _circleCenterText = @"";
        _circleRadiusText = @"";
        _locationModeIndex = MTCWebLocationModeNone;
        _advancedExpanded = NO;
    }
    return self;
}

@end

@interface MTCWebInputTipsViewController () <MTCMapViewDelegate>

@property (nonatomic, strong) MTCMapView *mapView;
@property (nonatomic, strong) MTCExampleMapTestSupport *mapTestSupport;
@property (nonatomic, strong) MTCWebSettingsFloatView *floatView;
@property (nonatomic, strong) UIButton *toggleButton;
@property (nonatomic, strong, nullable) MTCMTCWebDetailPopupView *popupView;
@property (nonatomic, strong) MTCWebInputTipsConfigModel *configModel;
@property (nonatomic, assign) BOOL loading;
@property (nonatomic, assign) BOOL loadingPlaceDetail;
@property (nonatomic, assign) BOOL listVisible;
@property (nonatomic, assign) BOOL mapReady;
@property (nonatomic, assign) MTCWebPopupPurpose activePopupPurpose;

@property (nonatomic, strong, nullable) MTCSuggestResponse *response;
@property (nonatomic, copy) NSArray<MTCSuggestion *> *suggestions;
@property (nonatomic, copy, nullable) NSString *errorMessage;
@property (nonatomic, copy, nullable) NSString *selectedSuggestionIdentifier;
@property (nonatomic, strong, nullable) MTCSuggestion *selectedSuggestion;
@property (nonatomic, strong, nullable) MTCPlace *selectedPlaceDetail;
@property (nonatomic, copy) NSDictionary<NSString *, MTCMarker *> *placeMarkers;
@property (nonatomic, assign) BOOL shouldReloadMarkers;

@end

@implementation MTCWebInputTipsViewController

- (void)dealloc {
}

#pragma mark - Public

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureNavigationItems:YES];
    self.view.backgroundColor = UIColor.systemGroupedBackgroundColor;
    self.view.accessibilityIdentifier = MTCExampleTestAccessibilityWebInputTipsScreen;
    self.configModel = [[MTCWebInputTipsConfigModel alloc] init];
    self.loading = NO;
    self.loadingPlaceDetail = NO;
    self.listVisible = YES;
    self.activePopupPurpose = MTCWebPopupPurposeNone;
    self.suggestions = @[];
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
    self.mapReady = YES;
    [self reloadMapMarkersFitIfNeeded:YES];
    [self.mapTestSupport markMapRenderedReady];
    [self.mapTestSupport pauseMapRenderingIfUITesting:self.mapView];
}

- (void)mapView:(MTCMapView *)mapView didLoadMapStyleWithID:(NSString *)mapStyleID {
    self.mapReady = YES;
    [self reloadMapMarkersFitIfNeeded:YES];
    [self.mapTestSupport markMapRenderedReady];
    [self.mapTestSupport pauseMapRenderingIfUITesting:self.mapView];
}

- (void)mapView:(MTCMapView *)mapView didFinishSwitchingMapStyleWithID:(NSString *)mapStyleID {
    self.mapReady = YES;
    [self reloadMapMarkersFitIfNeeded:YES];
    [self.mapTestSupport markMapRenderedReady];
    [self.mapTestSupport pauseMapRenderingIfUITesting:self.mapView];
}

- (void)mapView:(MTCMapView *)mapView didTapOverlay:(id<MTCOverlay>)overlay {
    MTCMarker *marker = [(id)overlay isKindOfClass:MTCMarker.class] ? (MTCMarker *)overlay : nil;
    if (!marker) {
        return;
    }
    NSString *identifier = [marker.userInfo isKindOfClass:NSString.class] ? (NSString *)marker.userInfo : nil;
    if (identifier.length == 0) {
        return;
    }
    MTCSuggestion *suggestion = [self suggestionForIdentifier:identifier];
    if (!suggestion) {
        return;
    }
    if ([self.selectedSuggestionIdentifier isEqualToString:identifier]) {
        if (self.selectedPlaceDetail) {
            [self presentPopupWithTitle:[self.selectedPlaceDetail mtc_displayTitleWithFallbackIndex:NSNotFound]
                                    text:[self.selectedPlaceDetail mtc_detailText]
                                 purpose:MTCWebPopupPurposePlaceDetail];
        } else {
            [self presentPopupWithTitle:[suggestion mtc_displayTitleWithFallbackIndex:NSNotFound]
                                    text:[suggestion mtc_detailText]
                                 purpose:MTCWebPopupPurposeSuggestionDetail];
        }
        [self.floatView reloadData];
        [self focusSelectedPlaceIfNeeded];
        return;
    }
    [self selectSuggestion:suggestion identifier:identifier presentPopup:YES];
}

#pragma mark - Event

- (void)submitRequest {
    if (self.loading || self.configModel.queryText.length == 0) {
        return;
    }

    self.loading = YES;
    self.loadingPlaceDetail = NO;
    self.errorMessage = nil;
    self.response = nil;
    self.suggestions = @[];
    [self clearSelectionAndDismissPopup];
    [self.floatView updateSections:[self buildSections]];

    MTCSuggestRequest *request = [[MTCSuggestRequest alloc] init];
    request.query = self.configModel.queryText;
    request.types = self.configModel.typesText.length > 0 ? self.configModel.typesText : nil;
    request.resultLimit = [self numberFromString:self.configModel.resultLimitText];
    request.language = self.configModel.languageText.length > 0 ? self.configModel.languageText : nil;
    request.region = self.configModel.regionText.length > 0 ? self.configModel.regionText : nil;
    request.locationBias = [MTCLocationBias mtc_currentLocationBiasWithMode:self.configModel.locationModeIndex
                                                               northEastText:self.configModel.rectNorthEastText
                                                               southWestText:self.configModel.rectSouthWestText
                                                                  centerText:self.configModel.circleCenterText
                                                                  radiusText:self.configModel.circleRadiusText];
    request.locationLimit = [MTCLocationLimit mtc_currentLocationLimitWithMode:self.configModel.locationModeIndex
                                                                  northEastText:self.configModel.rectNorthEastText
                                                                  southWestText:self.configModel.rectSouthWestText
                                                                     centerText:self.configModel.circleCenterText
                                                                     radiusText:self.configModel.circleRadiusText];

    __weak typeof(self) weakSelf = self;
    [[MTCSearchService sharedService] suggestWithRequest:request completion:^(MTCSuggestResponse * _Nullable response, NSError * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        strongSelf.loading = NO;
        strongSelf.response = response;
        strongSelf.errorMessage = error.localizedDescription;
        strongSelf.suggestions = response.suggestions ?: @[];
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

    [self.mapView setCenterCoordinate:CLLocationCoordinate2DMake(MTCSuggestDefaultLatitude, MTCSuggestDefaultLongitude)
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
        [MTCWebSettingsItem textItemWithTitle:@"query"
                                  placeholder:[self localizedStringForKey:@"web_enter_keywords_for_suggestions"]
                                       detail:[self localizedStringForKey:@"web_required"]
                                 keyboardType:UIKeyboardTypeDefault
                                       getter:^NSString *{ return weakSelf.configModel.queryText ?: @""; }
                                       setter:^(NSString *value) { weakSelf.configModel.queryText = value ?: @""; }],
        [MTCWebSettingsItem optionItemWithTitle:@"types"
                                         detail:[self localizedStringForKey:@"web_optional_poi_subtype"]
                                        options:[MTCWebSupportUtil mtc_poiTypeOptions]
                                         getter:^NSInteger{ return weakSelf.configModel.typesIndex; }
                                         setter:^(NSInteger index) {
            weakSelf.configModel.typesIndex = index;
            weakSelf.configModel.typesText = [MTCWebSupportUtil mtc_poiTypeForIndex:index];
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
                                           detail:[self localizedStringForKey:@"web_default_10"]
                                     keyboardType:UIKeyboardTypeNumberPad
                                           getter:^NSString *{ return weakSelf.configModel.resultLimitText ?: @""; }
                                           setter:^(NSString *value) { weakSelf.configModel.resultLimitText = value ?: @""; }],
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
            [MTCWebSettingsItem optionItemWithTitle:@"locationBias / locationLimit"
                                             detail:[self localizedStringForKey:@"web_mutually_exclusive"]
                                            options:[MTCWebSupportUtil mtc_locationModeOptions]
                                             getter:^NSInteger{ return weakSelf.configModel.locationModeIndex; }
                                             setter:^(NSInteger index) { weakSelf.configModel.locationModeIndex = index; }],
            [[MTCWebSettingsItem textItemWithTitle:@"rectangle.northeast"
                                       placeholder:@"1.36,103.84"
                                            detail:[self localizedStringForKey:@"web_rectangle_ne_lat_lng"]
                                      keyboardType:UIKeyboardTypeNumbersAndPunctuation
                                            getter:^NSString *{ return weakSelf.configModel.rectNorthEastText ?: @""; }
                                            setter:^(NSString *value) { weakSelf.configModel.rectNorthEastText = value ?: @""; }]
             visibleWhen:^BOOL{ return [MTCWebSupportUtil mtc_usesRectangleForLocationMode:weakSelf.configModel.locationModeIndex]; }],
            [[MTCWebSettingsItem textItemWithTitle:@"rectangle.southwest"
                                       placeholder:@"1.33,103.80"
                                            detail:[self localizedStringForKey:@"web_rectangle_sw_lat_lng"]
                                      keyboardType:UIKeyboardTypeNumbersAndPunctuation
                                            getter:^NSString *{ return weakSelf.configModel.rectSouthWestText ?: @""; }
                                            setter:^(NSString *value) { weakSelf.configModel.rectSouthWestText = value ?: @""; }]
             visibleWhen:^BOOL{ return [MTCWebSupportUtil mtc_usesRectangleForLocationMode:weakSelf.configModel.locationModeIndex]; }],
            [[MTCWebSettingsItem textItemWithTitle:@"circle.center"
                                       placeholder:@"1.360879,103.732578"
                                            detail:[self localizedStringForKey:@"web_center_lat_lng"]
                                      keyboardType:UIKeyboardTypeNumbersAndPunctuation
                                            getter:^NSString *{ return weakSelf.configModel.circleCenterText ?: @""; }
                                            setter:^(NSString *value) { weakSelf.configModel.circleCenterText = value ?: @""; }]
             visibleWhen:^BOOL{ return [MTCWebSupportUtil mtc_usesCircleForLocationMode:weakSelf.configModel.locationModeIndex]; }],
            [[MTCWebSettingsItem textItemWithTitle:@"circle.radius"
                                       placeholder:@"1000"
                                            detail:[self localizedStringForKey:@"web_unit_m"]
                                      keyboardType:UIKeyboardTypeNumberPad
                                            getter:^NSString *{ return weakSelf.configModel.circleRadiusText ?: @""; }
                                            setter:^(NSString *value) { weakSelf.configModel.circleRadiusText = value ?: @""; }]
             visibleWhen:^BOOL{ return [MTCWebSupportUtil mtc_usesCircleForLocationMode:weakSelf.configModel.locationModeIndex]; }],
        ]]];
    }

    [sections addObject:[MTCWebSettingsSection sectionWithTitle:[self localizedStringForKey:@"overlay_actions"]
                                                          items:@[
        [[MTCWebSettingsItem actionItemWithTitle:self.loading ? [self localizedStringForKey:@"web_searching"] : [self localizedStringForKey:@"web_search"]
                                           style:MTCWebSettingsActionStylePrimary
                                         handler:^{ [weakSelf submitRequest]; }]
         enabledWhen:^BOOL{ return weakSelf.loading == NO && weakSelf.configModel.queryText.length > 0; }],
    ]]];

    if (self.errorMessage.length > 0) {
        [sections addObject:[MTCWebSettingsSection sectionWithTitle:[self localizedStringForKey:@"web_error"]
                                                              items:@[
            [MTCWebSettingsItem infoItemWithTitle:@"message" value:^NSString *{ return weakSelf.errorMessage ?: @""; }],
        ]]];
    }

    if (self.suggestions.count > 0) {
        NSMutableArray<MTCWebSettingsItem *> *items = [NSMutableArray array];
        [self.suggestions enumerateObjectsUsingBlock:^(MTCSuggestion * _Nonnull suggestion, NSUInteger idx, BOOL * _Nonnull stop) {
            (void)stop;
            NSString *identifier = [suggestion mtc_identifierWithFallbackIndex:idx];
            NSString *title = [suggestion mtc_displayTitleWithFallbackIndex:idx];
            NSString *preview = [suggestion mtc_previewText];
            BOOL isSelected = [weakSelf.selectedSuggestionIdentifier isEqualToString:identifier];
            NSString *hint = [self localizedStringForKey:@"web_tap_to_view_details"];
            if (isSelected && weakSelf.loadingPlaceDetail) {
                hint = [self localizedStringForKey:@"web_fetching_place_details"];
            } else if (isSelected) {
                hint = [self localizedStringForKey:@"web_selected_tap_again_after_closing_the_popup_to_de"];
            }
            NSString *detail = preview.length > 0 ? [NSString stringWithFormat:@"%@\n%@", hint, preview] : hint;
            [items addObject:[MTCWebSettingsItem selectableInfoItemWithTitle:title
                                                                      detail:detail
                                                                       value:nil
                                                                    selected:^BOOL{
                return [weakSelf.selectedSuggestionIdentifier isEqualToString:identifier];
            } handler:^{
                [weakSelf selectSuggestion:suggestion identifier:identifier presentPopup:YES];
            }]];
        }];
        [sections addObject:[MTCWebSettingsSection sectionWithTitle:[self localizedStringForKey:@"web_suggestions"] items:items]];
    }

    if (self.response) {
        NSString *summary = [NSString stringWithFormat:@"suggestions: %@%@",
                             @(self.suggestions.count),
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

- (void)selectSuggestion:(MTCSuggestion *)suggestion identifier:(NSString *)identifier presentPopup:(BOOL)presentPopup {
    if (identifier.length == 0) {
        return;
    }
    NSString *previousIdentifier = self.selectedSuggestionIdentifier;
    if ([self.selectedSuggestionIdentifier isEqualToString:identifier] && self.activePopupPurpose == MTCWebPopupPurposeNone) {
        self.selectedSuggestionIdentifier = nil;
        self.selectedSuggestion = nil;
        self.selectedPlaceDetail = nil;
        self.loadingPlaceDetail = NO;
        [self applyMarkerSelectionStateChangeFromIdentifier:previousIdentifier toIdentifier:nil];
        [self dismissPopupPreservingSelection:NO];
        [self.floatView reloadData];
        self.shouldReloadMarkers = YES;
        [self reloadMapMarkersFitIfNeeded:NO];
        return;
    }

    self.selectedSuggestionIdentifier = identifier;
    self.selectedSuggestion = suggestion;
    self.selectedPlaceDetail = nil;
    [self applyMarkerSelectionStateChangeFromIdentifier:previousIdentifier toIdentifier:identifier];
    self.shouldReloadMarkers = YES;

    if (!presentPopup) {
        [self.floatView reloadData];
        [self reloadMapMarkersFitIfNeeded:NO];
        return;
    }

    if (suggestion.placeID.length == 0) {
        [self presentPopupWithTitle:[suggestion mtc_displayTitleWithFallbackIndex:NSNotFound]
                                text:[suggestion mtc_detailText]
                             purpose:MTCWebPopupPurposeSuggestionDetail];
        [self.floatView reloadData];
        [self reloadMapMarkersFitIfNeeded:NO];
        return;
    }

    self.loadingPlaceDetail = YES;
    [self.floatView reloadData];

    NSString *selectedIdentifier = [identifier copy];
    __weak typeof(self) weakSelf = self;
    [[MTCSearchService sharedService] fetchPlaceDetailWithPlaceID:suggestion.placeID
                                                        language:self.configModel.languageText.length > 0 ? self.configModel.languageText : nil
                                                          region:self.configModel.regionText.length > 0 ? self.configModel.regionText : nil
                                                      extraFields:nil
                                                      completion:^(MTCPlaceDetailResponse * _Nullable response, NSError * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        if (![strongSelf.selectedSuggestionIdentifier isEqualToString:selectedIdentifier]) {
            return;
        }

        strongSelf.loadingPlaceDetail = NO;
        strongSelf.selectedPlaceDetail = response.place;
        strongSelf.shouldReloadMarkers = YES;
        [strongSelf.floatView reloadData];
        [strongSelf reloadMapMarkersFitIfNeeded:NO];

        if (response.place) {
            [strongSelf presentPopupWithTitle:[response.place mtc_displayTitleWithFallbackIndex:NSNotFound]
                                          text:[response.place mtc_detailText]
                                       purpose:MTCWebPopupPurposePlaceDetail];
            return;
        }

        NSString *suggestionText = [suggestion mtc_detailText];
        if (error.localizedDescription.length > 0) {
            suggestionText = [NSString stringWithFormat:@"%@\n\nplaceDetail request failed\n%@", suggestionText, error.localizedDescription];
        }
        [strongSelf presentPopupWithTitle:[suggestion mtc_displayTitleWithFallbackIndex:NSNotFound]
                                      text:suggestionText
                                   purpose:MTCWebPopupPurposeSuggestionDetail];
    }];
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
        self.selectedSuggestionIdentifier = nil;
        self.selectedSuggestion = nil;
        self.selectedPlaceDetail = nil;
        self.loadingPlaceDetail = NO;
    }
    [self.floatView reloadData];
}

- (void)clearSelectionAndDismissPopup {
    NSString *previousIdentifier = self.selectedSuggestionIdentifier;
    self.selectedSuggestionIdentifier = nil;
    self.selectedSuggestion = nil;
    self.selectedPlaceDetail = nil;
    self.loadingPlaceDetail = NO;
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
            [self fitSelectedPlaceIfNeeded];
        }
        return;
    }
    self.shouldReloadMarkers = NO;

    [self.mapView removeAllInfoWindows];
    [self.mapView removeAllOverlays];

    MTCPlace *place = self.selectedPlaceDetail;
    if (!place.latitude || !place.longitude) {
        self.placeMarkers = @{};
        return;
    }

    NSString *identifier = self.selectedSuggestionIdentifier ?: [place mtc_identifierWithFallbackIndex:NSNotFound];
    if (identifier.length == 0) {
        self.placeMarkers = @{};
        return;
    }

    MTCMarker *marker = [[MTCMarker alloc] initWithCoordinate:CLLocationCoordinate2DMake(place.latitude.doubleValue, place.longitude.doubleValue)];
    NSString *title = [place mtc_displayTitleWithFallbackIndex:NSNotFound];
    marker.userInfo = identifier;
    marker.style = [self defaultMarkerStyle];
    marker.selectedStyle = [self selectedMarkerStyle];
    marker.style.title.text = title;
    marker.selectedStyle.title.text = title;
    marker.selected = YES;
    marker.zIndex = 100;
    marker.togglesSelectionOnTap = NO;
    self.placeMarkers = @{identifier: marker};
    [self.mapView addOverlays:@[marker]];

    if (fitIfNeeded) {
        [self fitSelectedPlaceIfNeeded];
    }
}

- (void)focusSelectedPlaceIfNeeded {
    MTCPlace *place = self.selectedPlaceDetail;
    if (!place.latitude || !place.longitude) {
        return;
    }

    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(place.latitude.doubleValue, place.longitude.doubleValue);
    [self.mapView setCenterCoordinate:coordinate
                            transition:[MTCCameraTransition easeWithDuration:0.25] completion:nil];
}

- (void)fitSelectedPlaceIfNeeded {
    MTCPlace *place = self.selectedPlaceDetail;
    if (!place.latitude || !place.longitude) {
        return;
    }

    [self.mapView setCenterCoordinate:CLLocationCoordinate2DMake(place.latitude.doubleValue, place.longitude.doubleValue)
                            zoomLevel:MTCSuggestSinglePlaceZoomLevel];
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

- (MTCSuggestion *)suggestionForIdentifier:(NSString *)identifier {
    if (identifier.length == 0) {
        return nil;
    }
    __block MTCSuggestion *matchedSuggestion = nil;
    [self.suggestions enumerateObjectsUsingBlock:^(MTCSuggestion * _Nonnull suggestion, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *currentIdentifier = [suggestion mtc_identifierWithFallbackIndex:idx];
        if ([currentIdentifier isEqualToString:identifier]) {
            matchedSuggestion = suggestion;
            *stop = YES;
        }
    }];
    return matchedSuggestion;
}

- (NSNumber *)numberFromString:(NSString *)string {
    NSInteger value = string.integerValue;
    if (value < 1 || value > 20) {
        return nil;
    }
    return @(value);
}

#pragma mark -- multi-language

- (void)demoLanguageDidChange {
    [self applyLocalizedTexts];
}

- (void)applyLocalizedTexts {
    self.title = [self localizedStringForKey:@"demo_title_MTCWebInputTipsViewController"];
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
