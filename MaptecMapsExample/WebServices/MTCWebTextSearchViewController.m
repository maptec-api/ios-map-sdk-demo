//
//  MTCWebTextSearchViewController.m
//  MaptecMapsExample
//
//  Created by ZHOUPanpan on 2026/7/14.
//

#import "MTCWebTextSearchViewController.h"

#import "MTCExampleMapTestSupport.h"
#import "MTCExampleTestAccessibility.h"
#import "MTCWebSettingsFloatView.h"
#import "MTCTextSearchRequestParams+MTCSupportFork.h"
#import "MTCMTCWebDetailPopupView.h"
#import "MTCWebSupportUtil.h"

#import <float.h>
#import <MaptecMapsKit/MaptecMapsKit.h>

static const CLLocationDegrees MTCTextSearchDefaultLatitude = 1.3521;
static const CLLocationDegrees MTCTextSearchDefaultLongitude = 103.8198;
static const double MTCTextSearchSinglePlaceZoomLevel = 14.0;

@interface MTCWebTextSearchConfigModel : NSObject

@property (nonatomic, copy) NSString *queryText;
@property (nonatomic, copy) NSString *typeText;
@property (nonatomic, copy) NSString *languageText;
@property (nonatomic, copy) NSString *regionText;
/// pageSize 分页大小
@property (nonatomic, copy) NSString *pageSizeText;
/// pageToken 分页令牌
@property (nonatomic, copy) NSString *pageTokenText;
/// extraFields 已选扩展字段标签
@property (nonatomic, copy) NSArray<NSString *> *extraFields;
/// 矩形东北角坐标
@property (nonatomic, copy) NSString *rectNorthEastText;
/// 矩形西南角坐标
@property (nonatomic, copy) NSString *rectSouthWestText;
/// 圆心坐标
@property (nonatomic, copy) NSString *circleCenterText;
/// 圆半径（米）
@property (nonatomic, copy) NSString *circleRadiusText;
/// 排序方式索引
@property (nonatomic, assign) NSInteger rankIndex;
/// 位置约束模式索引
@property (nonatomic, assign) NSInteger locationModeIndex;
@property (nonatomic, assign) BOOL advancedExpanded;

@end

@implementation MTCWebTextSearchConfigModel

- (instancetype)init {
    self = [super init];
    if (self) {
        _queryText = @"";
        _typeText = @"";
        _languageText = @"zh";
        _regionText = @"";
        _pageSizeText = @"";
        _pageTokenText = @"";
        _extraFields = @[@"aoi", @"phoneNumbers", @"emailAddresses", @"websiteUris", @"summary", @"openingHours"];
        _rectNorthEastText = @"";
        _rectSouthWestText = @"";
        _circleCenterText = @"";
        _circleRadiusText = @"";
        _rankIndex = 0;
        _locationModeIndex = MTCWebLocationModeNone;
        _advancedExpanded = NO;
    }
    return self;
}

@end

@interface MTCWebTextSearchViewController () <MTCMapViewDelegate>

@property (nonatomic, strong) MTCMapView *mapView;
@property (nonatomic, strong) MTCExampleMapTestSupport *mapTestSupport;
@property (nonatomic, strong) MTCWebSettingsFloatView *floatView;
@property (nonatomic, strong) UIButton *toggleButton;
@property (nonatomic, strong, nullable) MTCMTCWebDetailPopupView *popupView;
@property (nonatomic, strong) MTCWebTextSearchConfigModel *configModel;
@property (nonatomic, assign) BOOL loading;
@property (nonatomic, assign) BOOL listVisible;
@property (nonatomic, assign) BOOL mapReady;
@property (nonatomic, assign) MTCWebPopupPurpose activePopupPurpose;

@property (nonatomic, strong, nullable) MTCTextSearchResponse *response;
 /// 搜索结果列表
@property (nonatomic, copy) NSArray<MTCPlace *> *places;
@property (nonatomic, copy, nullable) NSString *errorMessage;
@property (nonatomic, copy, nullable) NSString *selectedPlaceID;
@property (nonatomic, strong, nullable) MTCPlace *selectedPlace;
@property (nonatomic, copy) NSDictionary<NSString *, MTCMarker *> *placeMarkers;
@property (nonatomic, assign) BOOL shouldReloadMarkers;

@end

@implementation MTCWebTextSearchViewController

- (void)dealloc {
}

#pragma mark - Public

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.accessibilityIdentifier = @"MTCWebTextSearchViewController.screen";
    [self configureNavigationItems:YES];
    self.view.backgroundColor = UIColor.systemGroupedBackgroundColor;
    self.configModel = [[MTCWebTextSearchConfigModel alloc] init];
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

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if ([NSProcessInfo.processInfo.arguments containsObject:MTCExampleTestAccessibilityUITestingArgument]) {
        if (!self.response && self.configModel.queryText.length == 0) {
            self.configModel.queryText = @"hotel";
            [self submitRequestWithPageToken:nil];
        }
    }
}

#pragma mark - protocol

#pragma mark - Delegate
#pragma mark -- MTCMapViewDelegate

- (void)mapViewDidFinishLoadingMap:(MTCMapView *)mapView {
    self.mapReady = YES;
    [self.mapTestSupport markMapRenderedReady];
    [self.mapTestSupport pauseMapRenderingIfUITesting:self.mapView];
    [self reloadMapMarkersFitIfNeeded:YES];
}

- (void)mapView:(MTCMapView *)mapView didLoadMapStyleWithID:(NSString *)mapStyleID {
    self.mapReady = YES;
    [self.mapTestSupport markMapRenderedReady];
    [self.mapTestSupport pauseMapRenderingIfUITesting:self.mapView];
    [self reloadMapMarkersFitIfNeeded:YES];
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

- (void)submitRequestWithPageToken:(nullable NSString *)pageToken {
    if (self.loading || self.configModel.queryText.length == 0) {
        return;
    }

    self.loading = YES;
    self.errorMessage = nil;
    if (pageToken.length == 0) {
        self.response = nil;
        self.places = @[];
        [self clearSelectionAndDismissPopup];
    } else {
        [self dismissPopupPreservingSelection:YES];
    }
    [self.floatView updateSections:[self buildSections]];

    MTCTextSearchRequest *request = [[MTCTextSearchRequest alloc] init];
    request.query = self.configModel.queryText;
    request.type = self.configModel.typeText.length > 0 ? self.configModel.typeText : nil;
    request.language = self.configModel.languageText.length > 0 ? self.configModel.languageText : nil;
    request.region = self.configModel.regionText.length > 0 ? self.configModel.regionText : nil;
    request.pageSize = [self numberFromString:self.configModel.pageSizeText];
    request.pageToken = pageToken.length > 0 ? pageToken : (self.configModel.pageTokenText.length > 0 ? self.configModel.pageTokenText : nil);
    request.rankType = [self rankTypeForIndex:self.configModel.rankIndex];
    request.extraFields = self.configModel.extraFields.count > 0 ? self.configModel.extraFields : nil;
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
    [[MTCSearchService sharedService] textSearchWithRequest:request completion:^(MTCTextSearchResponse * _Nullable response, NSError * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        strongSelf.loading = NO;
        strongSelf.errorMessage = error.localizedDescription;
        if (response || pageToken.length == 0) {
            strongSelf.response = response;
        }

        BOOL placesDidUpdate = NO;
        if (pageToken.length > 0 && response.places.count > 0) {
            /// 若 pageToken 非空，追加到现有结果列表（翻页）
            strongSelf.places = [strongSelf.places arrayByAddingObjectsFromArray:response.places];
            placesDidUpdate = YES;
        } else if (response) {
            strongSelf.places = response.places ?: @[];
            placesDidUpdate = YES;
        }
        if (response) {
            strongSelf.configModel.pageTokenText = response.nextPageToken ?: @"";
        }
        [strongSelf.mapTestSupport syncOverlayCount:strongSelf.places.count];
        strongSelf.shouldReloadMarkers = placesDidUpdate;
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
    self.mapTestSupport.overlayCountValueKey = @"search_place_count";
    [self.mapTestSupport installOnHostView:self.view];
    [self.mapTestSupport syncOverlayCount:0];
    [self.mapView setCenterCoordinate:CLLocationCoordinate2DMake(MTCTextSearchDefaultLatitude, MTCTextSearchDefaultLongitude)
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
    UIImage *image = [UIImage systemImageNamed:symbolName];
    [self.toggleButton setImage:image forState:UIControlStateNormal];
    NSString *accessibilityLabel = self.listVisible ? [self localizedStringForKey:@"web_switch_to_map"] : [self localizedStringForKey:@"web_switch_to_list"];
    self.toggleButton.accessibilityLabel = accessibilityLabel;
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
        [UIView animateWithDuration:0.22
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:changes
                         completion:completion];
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
                                  placeholder:[self localizedStringForKey:@"web_search_places"]
                                       detail:[self localizedStringForKey:@"web_required"]
                                 keyboardType:UIKeyboardTypeDefault
                                       getter:^NSString *{
            return weakSelf.configModel.queryText ?: @"";
        } setter:^(NSString *value) {
            weakSelf.configModel.queryText = value ?: @"";
        }],
        [MTCWebSettingsItem textItemWithTitle:@"type"
                                  placeholder:@"hotel"
                                       detail:[self localizedStringForKey:@"web_e_g_hotel_one_type_only"]
                                 keyboardType:UIKeyboardTypeDefault
                                       getter:^NSString *{
            return weakSelf.configModel.typeText ?: @"";
        } setter:^(NSString *value) {
            weakSelf.configModel.typeText = value ?: @"";
        }],
        [MTCWebSettingsItem textViewItemWithTitle:@"extraFields"
                                      placeholder:@"aoi,phoneNumbers,summary"
                                           detail:@"comma or newline-separated"
                                     keyboardType:UIKeyboardTypeASCIICapable
                                  accessoryInputs:[MTCWebSupportUtil mtc_textSearchExtraFieldOptions]
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
            [MTCWebSettingsItem textItemWithTitle:@"language"
                                      placeholder:@"zh"
                                           detail:[self localizedStringForKey:@"web_ietf_language_tag_default_zh"]
                                     keyboardType:UIKeyboardTypeASCIICapable
                                           getter:^NSString *{
                return weakSelf.configModel.languageText ?: @"";
            } setter:^(NSString *value) {
                weakSelf.configModel.languageText = value ?: @"";
            }],
            [MTCWebSettingsItem textItemWithTitle:@"region"
                                      placeholder:@"SG"
                                           detail:[self localizedStringForKey:@"web_cctld_2_chars_e_g_br"]
                                     keyboardType:UIKeyboardTypeASCIICapable
                                           getter:^NSString *{
                return weakSelf.configModel.regionText ?: @"";
            } setter:^(NSString *value) {
                weakSelf.configModel.regionText = value ?: @"";
            }],
            [MTCWebSettingsItem textItemWithTitle:@"pageSize"
                                      placeholder:@"1~20"
                                           detail:[self localizedStringForKey:@"web_1_20_default_20"]
                                     keyboardType:UIKeyboardTypeNumberPad
                                           getter:^NSString *{
                return weakSelf.configModel.pageSizeText ?: @"";
            } setter:^(NSString *value) {
                weakSelf.configModel.pageSizeText = value ?: @"";
            }],
            [MTCWebSettingsItem optionItemWithTitle:@"rank"
                                             detail:[self localizedStringForKey:@"web_default_popularity"]
                                            options:@[[self localizedStringForKey:@"web_not_set"], @"RELEVANCE", @"DISTANCE", @"POPULARITY"]
                                             getter:^NSInteger{
                return weakSelf.configModel.rankIndex;
            } setter:^(NSInteger index) {
                weakSelf.configModel.rankIndex = index;
            }],
            [MTCWebSettingsItem textItemWithTitle:@"pageToken"
                                      placeholder:@"nextPageToken"
                                           detail:[self localizedStringForKey:@"web_nextpagetoken_from_previous_page"]
                                     keyboardType:UIKeyboardTypeASCIICapable
                                           getter:^NSString *{
                return weakSelf.configModel.pageTokenText ?: @"";
            } setter:^(NSString *value) {
                weakSelf.configModel.pageTokenText = value ?: @"";
            }],
            [MTCWebSettingsItem optionItemWithTitle:@"locationBias / locationLimit"
                                             detail:[self localizedStringForKey:@"web_mutually_exclusive_if_neither_is_set_use_locatio"]
                                            options:[MTCWebSupportUtil mtc_locationModeOptions]
                                             getter:^NSInteger{
                return weakSelf.configModel.locationModeIndex;
            } setter:^(NSInteger index) {
                weakSelf.configModel.locationModeIndex = index;
            }],
            [[MTCWebSettingsItem textItemWithTitle:@"rectangle.northeast"
                                       placeholder:@"1.36,103.84"
                                            detail:[self localizedStringForKey:@"web_rectangle_ne_lat_lng"]
                                      keyboardType:UIKeyboardTypeNumbersAndPunctuation
                                            getter:^NSString *{
                return weakSelf.configModel.rectNorthEastText ?: @"";
            } setter:^(NSString *value) {
                weakSelf.configModel.rectNorthEastText = value ?: @"";
            }] visibleWhen:^BOOL{
                return [MTCWebSupportUtil mtc_usesRectangleForLocationMode:weakSelf.configModel.locationModeIndex];
            }],
            [[MTCWebSettingsItem textItemWithTitle:@"rectangle.southwest"
                                       placeholder:@"1.33,103.80"
                                            detail:[self localizedStringForKey:@"web_rectangle_sw_lat_lng"]
                                      keyboardType:UIKeyboardTypeNumbersAndPunctuation
                                            getter:^NSString *{
                return weakSelf.configModel.rectSouthWestText ?: @"";
            } setter:^(NSString *value) {
                weakSelf.configModel.rectSouthWestText = value ?: @"";
            }] visibleWhen:^BOOL{
                return [MTCWebSupportUtil mtc_usesRectangleForLocationMode:weakSelf.configModel.locationModeIndex];
            }],
            [[MTCWebSettingsItem textItemWithTitle:@"circle.center"
                                       placeholder:@"1.360879,103.732578"
                                            detail:[self localizedStringForKey:@"web_center_lat_lng"]
                                      keyboardType:UIKeyboardTypeNumbersAndPunctuation
                                            getter:^NSString *{
                return weakSelf.configModel.circleCenterText ?: @"";
            } setter:^(NSString *value) {
                weakSelf.configModel.circleCenterText = value ?: @"";
            }] visibleWhen:^BOOL{
                return [MTCWebSupportUtil mtc_usesCircleForLocationMode:weakSelf.configModel.locationModeIndex];
            }],
            [[MTCWebSettingsItem textItemWithTitle:@"circle.radius"
                                       placeholder:@"1000"
                                            detail:[self localizedStringForKey:@"web_unit_m_range_0_50000"]
                                      keyboardType:UIKeyboardTypeNumberPad
                                            getter:^NSString *{
                return weakSelf.configModel.circleRadiusText ?: @"";
            } setter:^(NSString *value) {
                weakSelf.configModel.circleRadiusText = value ?: @"";
            }] visibleWhen:^BOOL{
                return [MTCWebSupportUtil mtc_usesCircleForLocationMode:weakSelf.configModel.locationModeIndex];
            }],
        ]]];
    }

    NSMutableArray<MTCWebSettingsItem *> *actionItems = [NSMutableArray arrayWithObject:
        [[MTCWebSettingsItem actionItemWithTitle:self.loading ? [self localizedStringForKey:@"web_searching"] : [self localizedStringForKey:@"web_search"]
                                           style:MTCWebSettingsActionStylePrimary
                                         handler:^{
        [weakSelf submitRequestWithPageToken:nil];
    }] enabledWhen:^BOOL{
        return weakSelf.loading == NO && weakSelf.configModel.queryText.length > 0;
    }]
    ];
    if (self.response.nextPageToken.length > 0) {
        [actionItems addObject:[[MTCWebSettingsItem actionItemWithTitle:[self localizedStringForKey:@"web_load_next_page"]
                                                                  style:MTCWebSettingsActionStyleSecondary
                                                                handler:^{
            [weakSelf submitRequestWithPageToken:weakSelf.response.nextPageToken];
        }] enabledWhen:^BOOL{
            return weakSelf.loading == NO;
        }]];
    }
    [sections addObject:[MTCWebSettingsSection sectionWithTitle:[self localizedStringForKey:@"overlay_actions"] items:actionItems]];

    if (self.errorMessage.length > 0) {
        [sections addObject:[MTCWebSettingsSection sectionWithTitle:[self localizedStringForKey:@"web_error"]
                                                              items:@[
            [MTCWebSettingsItem infoItemWithTitle:@"message" value:^NSString *{
                return weakSelf.errorMessage ?: @"";
            }],
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
        NSString *summary = [NSString stringWithFormat:@"places: %@%@",
                             @(self.places.count),
                             self.response.nextPageToken.length > 0 ? [NSString stringWithFormat:@"\nnextPageToken: %@", self.response.nextPageToken] : @""];
        [sections addObject:[MTCWebSettingsSection sectionWithTitle:[self localizedStringForKey:@"web_response_json"]
                                                              items:@[
            [MTCWebSettingsItem selectableInfoItemWithTitle:@"raw"
                                                     detail:[self localizedStringForKey:@"web_tap_to_view_full_response_json"]
                                                      value:^NSString *{
                return summary;
            } selected:nil handler:^{
                [weakSelf presentPopupWithTitle:[self localizedStringForKey:@"web_response_json"]
                                            text:[MTCWebSupportUtil mtc_prettyJSONStringFromDictionary:weakSelf.response.rawDictionary ?: @{}]
                                         purpose:MTCWebPopupPurposeResponseRaw];
            }],
        ]]];
    }

    return sections;
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

- (void)resetSelectInfo {
    NSString *previousIdentifier = self.selectedPlaceID;
    self.selectedPlaceID = nil;
    self.selectedPlace = nil;
    [self applyMarkerSelectionStateChangeFromIdentifier:previousIdentifier toIdentifier:nil];
    [self dismissPopupPreservingSelection:NO];
}
- (void)presentPopupWithTitle:(NSString *)title
                         text:(NSString *)text
                      purpose:(MTCWebPopupPurpose)purpose {
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
        if (strongSelf.activePopupPurpose == MTCWebPopupPurposePlaceDetail) {
            strongSelf.activePopupPurpose = MTCWebPopupPurposeNone;
            [strongSelf.floatView reloadData];
        } else {
            strongSelf.activePopupPurpose = MTCWebPopupPurposeNone;
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
    NSMutableDictionary<NSString *, MTCMarker *> *markersByPlaceID = [NSMutableDictionary dictionary];

    [self.places enumerateObjectsUsingBlock:^(MTCPlace * _Nonnull place, NSUInteger idx, BOOL * _Nonnull stop) {
        (void)stop;
        if (!place.latitude || !place.longitude) {
            return;
        }
        NSString *placeID = [place mtc_identifierWithFallbackIndex:idx];
        if (placeID.length == 0) {
            return;
        }
        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(place.latitude.doubleValue, place.longitude.doubleValue);
        MTCMarker *marker = [[MTCMarker alloc] initWithCoordinate:coordinate];
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
        markersByPlaceID[placeID] = marker;
    }];

    self.placeMarkers = markersByPlaceID;
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
        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(place.latitude.doubleValue, place.longitude.doubleValue);
        [self.mapView setCenterCoordinate:coordinate
                                zoomLevel:MTCTextSearchSinglePlaceZoomLevel];
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
    self.title = [self localizedStringForKey:@"demo_title_MTCWebTextSearchViewController"];
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
