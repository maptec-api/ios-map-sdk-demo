#import "MTCWebLocationDetailViewController.h"

#import "MTCExampleMapTestSupport.h"
#import "MTCExampleTestAccessibility.h"
#import "MTCMTCWebDetailPopupView.h"
#import "MTCWebSettingsFloatView.h"
#import "MTCWebSupportUtil.h"

#import <MaptecMapsKit/MaptecMapsKit.h>

static const CLLocationDegrees MTCPlaceDetailDefaultLatitude = 1.3521;
static const CLLocationDegrees MTCPlaceDetailDefaultLongitude = 103.8198;
static const double MTCPlaceDetailSinglePlaceZoomLevel = 14.0;

@interface MTCWebLocationDetailConfigModel : NSObject

@property (nonatomic, copy) NSString *placeIDText;
@property (nonatomic, copy) NSString *languageText;
@property (nonatomic, copy) NSString *regionText;
@property (nonatomic, copy) NSArray<NSString *> *extraFields;
@property (nonatomic, assign) BOOL advancedExpanded;

@end

@implementation MTCWebLocationDetailConfigModel

- (instancetype)init {
    self = [super init];
    if (self) {
        _placeIDText = @"244737191329156445";
        _languageText = @"zh";
        _regionText = @"";
        _extraFields = @[];
        _advancedExpanded = NO;
    }
    return self;
}

@end

@interface MTCWebLocationDetailViewController () <MTCMapViewDelegate>

@property (nonatomic, strong) MTCMapView *mapView;
@property (nonatomic, strong) MTCExampleMapTestSupport *mapTestSupport;
@property (nonatomic, strong) MTCWebSettingsFloatView *floatView;
@property (nonatomic, strong) UIButton *toggleButton;
@property (nonatomic, strong, nullable) MTCMTCWebDetailPopupView *popupView;
@property (nonatomic, strong) MTCWebLocationDetailConfigModel *configModel;
@property (nonatomic, assign) BOOL loading;
@property (nonatomic, assign) BOOL listVisible;
@property (nonatomic, assign) BOOL mapReady;
@property (nonatomic, assign) MTCWebPopupPurpose activePopupPurpose;

@property (nonatomic, strong, nullable) MTCPlaceDetailResponse *response;
@property (nonatomic, copy, nullable) NSString *errorMessage;
@property (nonatomic, copy, nullable) NSString *selectedPlaceIdentifier;
@property (nonatomic, strong, nullable) MTCMarker *placeMarker;
@property (nonatomic, assign) BOOL shouldReloadMarkers;

@end

@implementation MTCWebLocationDetailViewController

- (void)dealloc {
}

#pragma mark - Public

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureNavigationItems:YES];
    self.view.backgroundColor = UIColor.systemGroupedBackgroundColor;
    self.view.accessibilityIdentifier = MTCExampleTestAccessibilityWebLocationDetailScreen;
    self.configModel = [[MTCWebLocationDetailConfigModel alloc] init];
    self.loading = NO;
    self.listVisible = YES;
    self.activePopupPurpose = MTCWebPopupPurposeNone;

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
    MTCPlace *place = self.response.place;
    if (identifier.length == 0 || !place) {
        return;
    }
    NSString *placeIdentifier = [place mtc_identifierWithFallbackIndex:NSNotFound];
    if ([placeIdentifier isEqualToString:identifier]) {
        if ([self.selectedPlaceIdentifier isEqualToString:identifier]) {
            [self presentPopupWithTitle:[place mtc_displayTitleWithFallbackIndex:NSNotFound]
                                    text:[place mtc_detailText]
                                 purpose:MTCWebPopupPurposePlaceDetail];
            [self.floatView reloadData];
            return;
        }
        [self selectPlace:place identifier:identifier presentPopup:YES];
    }
}

#pragma mark - Event

- (void)submitRequest {
    if (self.loading || self.configModel.placeIDText.length == 0) {
        return;
    }

    self.loading = YES;
    self.response = nil;
    self.errorMessage = nil;
    [self clearSelectionAndDismissPopup];
    [self.floatView updateSections:[self buildSections]];

    __weak typeof(self) weakSelf = self;
    [[MTCSearchService sharedService] fetchPlaceDetailWithPlaceID:self.configModel.placeIDText
                                                        language:self.configModel.languageText.length > 0 ? self.configModel.languageText : nil
                                                          region:self.configModel.regionText.length > 0 ? self.configModel.regionText : nil
                                                     extraFields:self.configModel.extraFields.count > 0 ? self.configModel.extraFields : nil
                                                      completion:^(MTCPlaceDetailResponse * _Nullable response, NSError * _Nullable error) {
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

    [self.mapView setCenterCoordinate:CLLocationCoordinate2DMake(MTCPlaceDetailDefaultLatitude, MTCPlaceDetailDefaultLongitude)
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
        [MTCWebSettingsItem textItemWithTitle:@"placeId"
                                  placeholder:@"places/{id}"
                                       detail:[self localizedStringForKey:@"web_get_from_search_results_or_suggestions"]
                                 keyboardType:UIKeyboardTypeASCIICapable
                                       getter:^NSString *{ return weakSelf.configModel.placeIDText ?: @""; }
                                       setter:^(NSString *value) { weakSelf.configModel.placeIDText = value ?: @""; }],
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
        [[MTCWebSettingsItem actionItemWithTitle:self.loading ? [self localizedStringForKey:@"web_requesting"] : [self localizedStringForKey:@"web_get_place_details"]
                                           style:MTCWebSettingsActionStylePrimary
                                         handler:^{ [weakSelf submitRequest]; }]
         enabledWhen:^BOOL{ return weakSelf.loading == NO && weakSelf.configModel.placeIDText.length > 0; }],
    ]]];

    if (self.errorMessage.length > 0) {
        [sections addObject:[MTCWebSettingsSection sectionWithTitle:[self localizedStringForKey:@"web_error"]
                                                              items:@[
            [MTCWebSettingsItem infoItemWithTitle:@"message" value:^NSString *{ return weakSelf.errorMessage ?: @""; }],
        ]]];
    }

    if (self.response.place) {
        MTCPlace *place = self.response.place;
        NSString *identifier = [place mtc_identifierWithFallbackIndex:NSNotFound];
        NSString *title = [place mtc_displayTitleWithFallbackIndex:NSNotFound];
        NSString *preview = [place mtc_previewText];
        NSString *hint = [self.selectedPlaceIdentifier isEqualToString:identifier] ? [self localizedStringForKey:@"web_selected_tap_again_after_closing_the_popup_to_de"] : [self localizedStringForKey:@"web_tap_to_view_details"];
        NSString *detail = preview.length > 0 ? [NSString stringWithFormat:@"%@\n%@", hint, preview] : hint;
        [sections addObject:[MTCWebSettingsSection sectionWithTitle:[self localizedStringForKey:@"web_results"]
                                                              items:@[
            [MTCWebSettingsItem selectableInfoItemWithTitle:title
                                                     detail:detail
                                                      value:nil
                                                   selected:^BOOL{
                return [weakSelf.selectedPlaceIdentifier isEqualToString:identifier];
            } handler:^{
                [weakSelf selectPlace:place identifier:identifier presentPopup:YES];
            }],
        ]]];
    }

    if (self.response) {
        NSString *summary = [NSString stringWithFormat:@"status: %@%@",
                             self.response.status ?: @"",
                             self.response.place ? @"\nplace: 1" : @"\nplace: 0"];
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

- (void)selectPlace:(MTCPlace *)place identifier:(NSString *)identifier presentPopup:(BOOL)presentPopup {
    if (identifier.length == 0) {
        return;
    }
    NSString *previousIdentifier = self.selectedPlaceIdentifier;
    if ([self.selectedPlaceIdentifier isEqualToString:identifier] && self.activePopupPurpose == MTCWebPopupPurposeNone) {
        self.selectedPlaceIdentifier = nil;
        [self applyMarkerSelectionStateChangeFromIdentifier:previousIdentifier toIdentifier:nil];
        [self dismissPopupPreservingSelection:NO];
        [self.floatView reloadData];
        return;
    }

    self.selectedPlaceIdentifier = identifier;
    [self applyMarkerSelectionStateChangeFromIdentifier:previousIdentifier toIdentifier:identifier];
    if (presentPopup) {
        [self presentPopupWithTitle:[place mtc_displayTitleWithFallbackIndex:NSNotFound]
                                text:[place mtc_detailText]
                             purpose:MTCWebPopupPurposePlaceDetail];
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
        self.selectedPlaceIdentifier = nil;
    }
    [self.floatView reloadData];
}

- (void)clearSelectionAndDismissPopup {
    NSString *previousIdentifier = self.selectedPlaceIdentifier;
    self.selectedPlaceIdentifier = nil;
    [self applyMarkerSelectionStateChangeFromIdentifier:previousIdentifier toIdentifier:nil];
    [self dismissPopupPreservingSelection:NO];
}

- (void)applyMarkerSelectionStateChangeFromIdentifier:(NSString *)previousIdentifier
                                         toIdentifier:(NSString *)currentIdentifier {
    if (!self.mapReady || !self.placeMarker) {
        return;
    }

    [self.mapView performOverlayUpdates:^{
        self.placeMarker.selected = (currentIdentifier.length > 0);
        self.placeMarker.zIndex = self.placeMarker.isSelected ? 100 : 10;
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
    self.placeMarker = nil;
    
    MTCPlace *place = self.response.place;
    if (!place.latitude || !place.longitude) {
        return;
    }

    NSString *identifier = [place mtc_identifierWithFallbackIndex:NSNotFound];
    if (identifier.length == 0) {
        return;
    }

    MTCMarker *marker = [[MTCMarker alloc] initWithCoordinate:CLLocationCoordinate2DMake(place.latitude.doubleValue, place.longitude.doubleValue)];
    NSString *title = [place mtc_displayTitleWithFallbackIndex:NSNotFound];
    marker.userInfo = identifier;
    marker.style = [self defaultMarkerStyle];
    marker.selectedStyle = [self selectedMarkerStyle];
    marker.style.title.text = title;
    marker.selectedStyle.title.text = title;
    marker.selected = [self.selectedPlaceIdentifier isEqualToString:identifier];
    marker.zIndex = marker.isSelected ? 100 : 10;
    marker.togglesSelectionOnTap = NO;
    self.placeMarker = marker;
    [self.mapView addOverlays:@[marker]];

    [self updateMapCameraFitIfNeeded];
}
- (void)updateMapCameraFitIfNeeded {
    MTCPlace *place = self.response.place;
    if (!place.latitude || !place.longitude) {
        return;
    }
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(place.latitude.doubleValue, place.longitude.doubleValue);
    [self.mapView setCenterCoordinate:coordinate
                            transition:[MTCCameraTransition easeWithDuration:0.25] completion:nil];
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

#pragma mark -- multi-language

- (void)demoLanguageDidChange {
    [self applyLocalizedTexts];
}

- (void)applyLocalizedTexts {
    self.title = [self localizedStringForKey:@"demo_title_MTCWebLocationDetailViewController"];
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
