//
//  MTCMapViewPortController.m
//  MaptecMapsExample
//
//  Created by ZHOUPanpan on 2026/7/10.
//

#import "MTCMapViewPortController.h"

#import "ExampleSettingsSheetView.h"
#import "MTCExampleMapTestSupport.h"
#import "MTCExampleTestAccessibility.h"

#import <MaptecMapsKit/MaptecMapsKit.h>

#include <math.h>

static CLLocationDegrees const MTCViewPortInitialLatitude = 1.3521;
static CLLocationDegrees const MTCViewPortInitialLongitude = 103.8198;
static double const MTCViewPortInitialZoomLevel = 11.5;

static NSString *MTCViewPortFormatNumber(double value) {
    return [NSString stringWithFormat:@"%.2f", value];
}

static double MTCViewPortNormalizedBearing(double bearing) {
    double normalized = fmod(bearing, 360.0);
    if (normalized < 0.0) {
        normalized += 360.0;
    }
    return normalized;
}

@interface MTCMapViewPortController () <MTCMapViewDelegate>

@property (nonatomic, strong) MTCMapView *mapView;
@property (nonatomic, weak) ExampleSettingsSheetView *settingsSheet;
@property (nonatomic, strong) MTCExampleMapTestSupport *mapTestSupport;

@property (nonatomic, copy) NSString *pitchMaximumText;
@property (nonatomic, copy) NSString *pitchMinimumText;
@property (nonatomic, copy) NSString *pitchCurrentText;
@property (nonatomic, copy) NSString *bearingMaximumText;
@property (nonatomic, copy) NSString *bearingMinimumText;
@property (nonatomic, copy) NSString *bearingCurrentText;
@property (nonatomic, copy) NSString *zoomMaximumText;
@property (nonatomic, copy) NSString *zoomMinimumText;
@property (nonatomic, copy) NSString *zoomCurrentText;

@end

@implementation MTCMapViewPortController

#pragma mark - Public

#pragma mark - Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = UIColor.whiteColor;
    self.view.accessibilityIdentifier = MTCExampleTestAccessibilityMapViewPortScreen;

    self.mapTestSupport = [[MTCExampleMapTestSupport alloc] init];
    [self.mapTestSupport installOnHostView:self.view];

    [self configureNavigationItems:NO];
    [self configureMapView];
    [self configureInitialInputs];
    [self applyLocalizedTexts];
}

#pragma mark - protocol

#pragma mark - Delegate
#pragma mark -- MTCMapViewDelegate
- (void)mapViewDidFinishLoadingMap:(MTCMapView *)mapView {
    (void)mapView;
    [self.mapTestSupport markMapRenderedReady];
    [self.mapTestSupport pauseMapRenderingIfUITesting:self.mapView];
}

- (void)mapView:(MTCMapView *)mapView didLoadMapStyleWithID:(NSString *)mapStyleID {
    (void)mapView;
    (void)mapStyleID;
    [self.mapTestSupport markMapRenderedReady];
    [self.mapTestSupport pauseMapRenderingIfUITesting:self.mapView];
}

- (void)mapView:(MTCMapView *)mapView
cameraDidChange:(MTCMapCamera *)camera
         reason:(MTCMapCameraChangeReason)reason
       animated:(BOOL)animated {
    (void)mapView;
    (void)reason;
    (void)animated;
    [self syncCurrentInputsWithCamera:camera];
    [self.settingsSheet reloadData];
}

#pragma mark - Event
- (void)showSettingsSheet {
    [self syncCurrentInputsWithCamera:[self currentCameraSnapshot]];

    ExampleSettingsSheetView *sheet =
        [[ExampleSettingsSheetView alloc] initWithTitle:[self localizedStringForKey:@"demo_title_MTCMapViewPortController"]
                                               sections:[self settingsSections]];
    self.settingsSheet = sheet;
    [sheet showInView:self.view animated:NO];
}

#pragma mark - Private

- (void)configureMapView {
    self.mapView = [[MTCMapView alloc] initWithFrame:self.view.bounds];
    self.mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.mapView.delegate = self;
    [self.view addSubview:self.mapView];

    [self.mapView setCenterCoordinate:CLLocationCoordinate2DMake(MTCViewPortInitialLatitude, MTCViewPortInitialLongitude)
                            zoomLevel:MTCViewPortInitialZoomLevel];
}

- (void)configureInitialInputs {
    MTCMapCameraConstraints *constraints = self.mapView.cameraConstraints;
    self.pitchMaximumText = MTCViewPortFormatNumber(constraints.pitchAngleRange.maximumPitchAngle);
    self.pitchMinimumText = MTCViewPortFormatNumber(constraints.pitchAngleRange.minimumPitchAngle);
    self.bearingMaximumText = MTCViewPortFormatNumber(constraints.bearingRange.endBearing);
    self.bearingMinimumText = MTCViewPortFormatNumber(constraints.bearingRange.startBearing);
    self.zoomMaximumText = MTCViewPortFormatNumber(constraints.zoomLevelRange.maximumZoomLevel);
    self.zoomMinimumText = MTCViewPortFormatNumber(constraints.zoomLevelRange.minimumZoomLevel);
    [self syncCurrentInputsWithCamera:[self currentCameraSnapshot]];
}

- (NSArray<ExampleSettingsSection *> *)settingsSections {
    __weak typeof(self) weakSelf = self;
    MTCMapZoomLevelRange zoomPlaceholderRange = self.mapView.cameraConstraints.zoomLevelRange;
    NSString *maximumTitle = [self localizedStringForKey:@"common_value_maximum"];
    NSString *minimumTitle = [self localizedStringForKey:@"common_value_minimum"];
    NSString *currentTitle = [self localizedStringForKey:@"common_value_current"];
    return @[
        [ExampleSettingsSection sectionWithTitle:[self localizedStringForKey:@"viewport_section_pitch"] items:@[
            [self textItemWithTitle:maximumTitle propertyGetter:^NSString *{ return weakSelf.pitchMaximumText; } setter:^(NSString *value) { weakSelf.pitchMaximumText = value; } placeholder:@"60.00" accessibilityIdentifier:MTCExampleTestAccessibilityInputPitchMax],
            [self textItemWithTitle:minimumTitle propertyGetter:^NSString *{ return weakSelf.pitchMinimumText; } setter:^(NSString *value) { weakSelf.pitchMinimumText = value; } placeholder:@"0.00" accessibilityIdentifier:MTCExampleTestAccessibilityInputPitchMin],
            [self textItemWithTitle:currentTitle propertyGetter:^NSString *{ return weakSelf.pitchCurrentText; } setter:^(NSString *value) { weakSelf.pitchCurrentText = value; } placeholder:@"0.00" accessibilityIdentifier:MTCExampleTestAccessibilityInputPitchCurrent],
        ]],
        [ExampleSettingsSection sectionWithTitle:[self localizedStringForKey:@"viewport_section_bearing"] items:@[
            [self textItemWithTitle:maximumTitle propertyGetter:^NSString *{ return weakSelf.bearingMaximumText; } setter:^(NSString *value) { weakSelf.bearingMaximumText = value; } placeholder:@"360.00" accessibilityIdentifier:MTCExampleTestAccessibilityInputBearingMax],
            [self textItemWithTitle:minimumTitle propertyGetter:^NSString *{ return weakSelf.bearingMinimumText; } setter:^(NSString *value) { weakSelf.bearingMinimumText = value; } placeholder:@"0.00" accessibilityIdentifier:MTCExampleTestAccessibilityInputBearingMin],
            [self textItemWithTitle:currentTitle propertyGetter:^NSString *{ return weakSelf.bearingCurrentText; } setter:^(NSString *value) { weakSelf.bearingCurrentText = value; } placeholder:@"0.00" accessibilityIdentifier:MTCExampleTestAccessibilityInputBearingCurrent],
        ]],
        [ExampleSettingsSection sectionWithTitle:[self localizedStringForKey:@"viewport_section_zoom"] items:@[
            [self textItemWithTitle:maximumTitle propertyGetter:^NSString *{ return weakSelf.zoomMaximumText; } setter:^(NSString *value) { weakSelf.zoomMaximumText = value; } placeholder:MTCViewPortFormatNumber(zoomPlaceholderRange.maximumZoomLevel) accessibilityIdentifier:MTCExampleTestAccessibilityInputZoomMax],
            [self textItemWithTitle:minimumTitle propertyGetter:^NSString *{ return weakSelf.zoomMinimumText; } setter:^(NSString *value) { weakSelf.zoomMinimumText = value; } placeholder:MTCViewPortFormatNumber(zoomPlaceholderRange.minimumZoomLevel) accessibilityIdentifier:MTCExampleTestAccessibilityInputZoomMin],
            [self textItemWithTitle:currentTitle propertyGetter:^NSString *{ return weakSelf.zoomCurrentText; } setter:^(NSString *value) { weakSelf.zoomCurrentText = value; } placeholder:@"11.50" accessibilityIdentifier:MTCExampleTestAccessibilityInputZoomCurrent],
        ]],
        [ExampleSettingsSection sectionWithTitle:@"" items:@[
            [[ExampleSettingsItem actionItemWithTitle:[self localizedStringForKey:@"viewport_apply"] handler:^{
                [weakSelf applySettingsFromInput];
            }] withAccessibilityIdentifier:MTCExampleTestAccessibilityBtnViewPortApply],
        ]],
    ];
}

- (ExampleSettingsItem *)textItemWithTitle:(NSString *)title
                            propertyGetter:(NSString *(^)(void))getter
                                    setter:(void (^)(NSString *value))setter
                               placeholder:(NSString *)placeholder
                   accessibilityIdentifier:(NSString *)accessibilityIdentifier {
    ExampleSettingsItem *item = [ExampleSettingsItem textItemWithTitle:title
                                                           placeholder:placeholder
                                                          keyboardType:UIKeyboardTypeNumbersAndPunctuation
                                                                getter:^NSString *{
        return getter ? getter() ?: @"" : @"";
    } setter:^(NSString *value) {
        if (setter) {
            setter(value ?: @"");
        }
    }];
    return [item withAccessibilityIdentifier:accessibilityIdentifier];
}

- (void)applySettingsFromInput {
    double pitchMaximum = 0.0;
    double pitchMinimum = 0.0;
    double pitchCurrent = 0.0;
    double bearingMaximum = 0.0;
    double bearingMinimum = 0.0;
    double bearingCurrent = 0.0;
    MTCMapZoomLevelRange currentZoomRange = self.mapView.cameraConstraints.zoomLevelRange;
    double zoomMaximum = currentZoomRange.maximumZoomLevel;
    double zoomMinimum = currentZoomRange.minimumZoomLevel;
    double zoomCurrent = [self currentCameraSnapshot].zoomLevel;

    NSString *pitchMaximumTitle = [self fieldTitleForSectionKey:@"viewport_section_pitch" valueKey:@"common_value_maximum"];
    NSString *pitchMinimumTitle = [self fieldTitleForSectionKey:@"viewport_section_pitch" valueKey:@"common_value_minimum"];
    NSString *pitchCurrentTitle = [self fieldTitleForSectionKey:@"viewport_section_pitch" valueKey:@"common_value_current"];
    NSString *bearingMaximumTitle = [self fieldTitleForSectionKey:@"viewport_section_bearing" valueKey:@"common_value_maximum"];
    NSString *bearingMinimumTitle = [self fieldTitleForSectionKey:@"viewport_section_bearing" valueKey:@"common_value_minimum"];
    NSString *bearingCurrentTitle = [self fieldTitleForSectionKey:@"viewport_section_bearing" valueKey:@"common_value_current"];
    NSString *zoomMaximumTitle = [self fieldTitleForSectionKey:@"viewport_section_zoom" valueKey:@"common_value_maximum"];
    NSString *zoomMinimumTitle = [self fieldTitleForSectionKey:@"viewport_section_zoom" valueKey:@"common_value_minimum"];
    NSString *zoomCurrentTitle = [self fieldTitleForSectionKey:@"viewport_section_zoom" valueKey:@"common_value_current"];
    NSString *pitchSectionTitle = [self localizedStringForKey:@"viewport_section_pitch"];
    NSString *bearingSectionTitle = [self localizedStringForKey:@"viewport_section_bearing"];
    NSString *zoomSectionTitle = [self localizedStringForKey:@"viewport_section_zoom"];

    if (![self readDoubleFromText:self.pitchMaximumText title:pitchMaximumTitle value:&pitchMaximum] ||
        ![self readDoubleFromText:self.pitchMinimumText title:pitchMinimumTitle value:&pitchMinimum] ||
        ![self readDoubleFromText:self.pitchCurrentText title:pitchCurrentTitle value:&pitchCurrent] ||
        ![self readDoubleFromText:self.bearingMaximumText title:bearingMaximumTitle value:&bearingMaximum] ||
        ![self readDoubleFromText:self.bearingMinimumText title:bearingMinimumTitle value:&bearingMinimum] ||
        ![self readDoubleFromText:self.bearingCurrentText title:bearingCurrentTitle value:&bearingCurrent] ||
        ![self readDoubleFromText:self.zoomMaximumText title:zoomMaximumTitle value:&zoomMaximum] ||
        ![self readDoubleFromText:self.zoomMinimumText title:zoomMinimumTitle value:&zoomMinimum] ||
        ![self readDoubleFromText:self.zoomCurrentText title:zoomCurrentTitle value:&zoomCurrent]) {
        return;
    }

    if (![self validateValue:pitchMaximum title:pitchMaximumTitle minimum:0.0 maximum:60.0] ||
        ![self validateValue:pitchMinimum title:pitchMinimumTitle minimum:0.0 maximum:60.0] ||
        ![self validateValue:pitchCurrent title:pitchCurrentTitle minimum:0.0 maximum:60.0] ||
        ![self validateRangeWithMinimum:pitchMinimum maximum:pitchMaximum title:pitchSectionTitle] ||
        ![self validateCurrentValue:pitchCurrent minimum:pitchMinimum maximum:pitchMaximum title:pitchCurrentTitle] ||
        ![self validateValue:bearingMaximum title:bearingMaximumTitle minimum:0.0 maximum:360.0] ||
        ![self validateValue:bearingMinimum title:bearingMinimumTitle minimum:0.0 maximum:360.0] ||
        ![self validateValue:bearingCurrent title:bearingCurrentTitle minimum:0.0 maximum:360.0] ||
        ![self validateRangeWithMinimum:bearingMinimum maximum:bearingMaximum title:bearingSectionTitle] ||
        ![self validateCurrentValue:bearingCurrent minimum:bearingMinimum maximum:bearingMaximum title:bearingCurrentTitle] ||
        ![self validateRangeWithMinimum:zoomMinimum maximum:zoomMaximum title:zoomSectionTitle] ||
        ![self validateCurrentValue:zoomCurrent minimum:zoomMinimum maximum:zoomMaximum title:zoomCurrentTitle]) {
        return;
    }

    self.mapView.cameraConstraints.pitchAngleRange = MTCMapPitchAngleRangeMake((CGFloat)pitchMinimum, (CGFloat)pitchMaximum);
    self.mapView.cameraConstraints.bearingRange = MTCMapBearingRangeMake(bearingMinimum, bearingMaximum);
    self.mapView.cameraConstraints.zoomLevelRange = MTCMapZoomLevelRangeMake(zoomMinimum, zoomMaximum);

    MTCMapCamera *currentCamera = [self currentCameraSnapshot];
    MTCMapCamera *targetCamera = [MTCMapCamera cameraWithCenterCoordinate:currentCamera.centerCoordinate
                                                                zoomLevel:zoomCurrent
                                                                  bearing:bearingCurrent
                                                                    pitch:(CGFloat)pitchCurrent];
    [self.mapView setCamera:targetCamera transition:[MTCCameraTransition easeWithDuration:0.25] completion:^(BOOL finished) {
        NSLog(@"MTCMapViewPortController setCamera completion finished: %@", @(finished));
    }];

    [self syncLimitInputsWithCameraConstraints];
    self.pitchCurrentText = MTCViewPortFormatNumber(pitchCurrent);
    self.bearingCurrentText = MTCViewPortFormatNumber(bearingCurrent);
    self.zoomCurrentText = MTCViewPortFormatNumber(zoomCurrent);
    [self.settingsSheet reloadData];
}

- (void)syncLimitInputsWithCameraConstraints {
    MTCMapCameraConstraints *constraints = self.mapView.cameraConstraints;
    self.pitchMaximumText = MTCViewPortFormatNumber(constraints.pitchAngleRange.maximumPitchAngle);
    self.pitchMinimumText = MTCViewPortFormatNumber(constraints.pitchAngleRange.minimumPitchAngle);
    self.bearingMaximumText = MTCViewPortFormatNumber(constraints.bearingRange.endBearing);
    self.bearingMinimumText = MTCViewPortFormatNumber(constraints.bearingRange.startBearing);
    self.zoomMaximumText = MTCViewPortFormatNumber(constraints.zoomLevelRange.maximumZoomLevel);
    self.zoomMinimumText = MTCViewPortFormatNumber(constraints.zoomLevelRange.minimumZoomLevel);
}

- (void)syncCurrentInputsWithCamera:(MTCMapCamera *)camera {
    if (!camera) {
        return;
    }

    self.pitchCurrentText = MTCViewPortFormatNumber(camera.pitch);
    self.bearingCurrentText = MTCViewPortFormatNumber(MTCViewPortNormalizedBearing(camera.bearing));
    self.zoomCurrentText = MTCViewPortFormatNumber(camera.zoomLevel);
}

- (MTCMapCamera *)currentCameraSnapshot {
    MTCMapCamera *camera = self.mapView.camera;
    if (camera) {
        return camera;
    }

    return [MTCMapCamera cameraWithCenterCoordinate:CLLocationCoordinate2DMake(MTCViewPortInitialLatitude, MTCViewPortInitialLongitude)
                                         zoomLevel:MTCViewPortInitialZoomLevel
                                           bearing:0.0
                                             pitch:0.0];
}

- (NSString *)fieldTitleForSectionKey:(NSString *)sectionKey valueKey:(NSString *)valueKey {
    return [NSString stringWithFormat:[self localizedStringForKey:@"viewport_field_title_format"],
            [self localizedStringForKey:sectionKey],
            [self localizedStringForKey:valueKey]];
}

- (BOOL)readDoubleFromText:(NSString *)text title:(NSString *)title value:(double *)value {
    NSString *trimmedText = [(text ?: @"") stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    NSScanner *scanner = [NSScanner scannerWithString:trimmedText];
    scanner.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];

    double parsedValue = 0.0;
    if (trimmedText.length == 0 || ![scanner scanDouble:&parsedValue] || !scanner.isAtEnd || !isfinite(parsedValue)) {
        [self showInputError:[NSString stringWithFormat:[self localizedStringForKey:@"viewport_error_need_number"], title]];
        return NO;
    }
    if (value) {
        *value = parsedValue;
    }
    return YES;
}

- (BOOL)validateValue:(double)value title:(NSString *)title minimum:(double)minimum maximum:(double)maximum {
    if (value < minimum || value > maximum) {
        [self showInputError:[NSString stringWithFormat:[self localizedStringForKey:@"viewport_error_range"], title, minimum, maximum]];
        return NO;
    }
    return YES;
}

- (BOOL)validateRangeWithMinimum:(double)minimum maximum:(double)maximum title:(NSString *)title {
    if (minimum > maximum) {
        [self showInputError:[NSString stringWithFormat:[self localizedStringForKey:@"viewport_error_min_gt_max"], title]];
        return NO;
    }
    return YES;
}

- (BOOL)validateCurrentValue:(double)current minimum:(double)minimum maximum:(double)maximum title:(NSString *)title {
    if (current < minimum || current > maximum) {
        [self showInputError:[NSString stringWithFormat:[self localizedStringForKey:@"viewport_error_current_out"], title]];
        return NO;
    }
    return YES;
}

- (void)showInputError:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[self localizedStringForKey:@"common_invalid_input"]
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:[self localizedStringForKey:@"common_ok"] style:UIAlertActionStyleDefault handler:nil]];
    UIViewController *presenter = self.presentedViewController ?: self;
    [presenter presentViewController:alert animated:YES completion:nil];
}

#pragma mark -- multi-language

- (void)handleExampleSettingsAction {
    [self showSettingsSheet];
}

- (void)demoLanguageDidChange {
    [self applyLocalizedTexts];
}

- (void)applyLocalizedTexts {
    self.title = [self localizedStringForKey:@"demo_title_MTCMapViewPortController"];
    if (self.mapView) {
        self.mapView.mapLanguage = [self mapLanguageForDemoLanguage:self.demoLanguage];
    }
    if ([self isSettingsSheetVisible:ExampleSettingsSheetView.class]) {
        [self showSettingsSheet];
    }
}

#pragma mark - Getter & Setter

@end
