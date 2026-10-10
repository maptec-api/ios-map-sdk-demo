//
//  MTCMapScreenshotViewController.m
//  MaptecMapsExample
//
//  Created by Codex on 2026/9/2.
//

#import "MTCMapScreenshotViewController.h"

#import "ExampleSettingsSheetView.h"
#import "MTCExampleToastView.h"

#import <MaptecMapsKit/MaptecMapsKit.h>

#include <math.h>

static CLLocationDegrees const MTCMapScreenshotInitialLatitude = 1.3521;
static CLLocationDegrees const MTCMapScreenshotInitialLongitude = 103.8198;
static double const MTCMapScreenshotInitialZoomLevel = 16.5;

@interface MTCMapScreenshotViewController () <MTCMapViewDelegate>

@property (nonatomic, strong) MTCMapView *mapView;
@property (nonatomic, strong, nullable) UIImage *capturedImage;
@property (nonatomic, assign) BOOL snapshotInProgress;
@property (nonatomic, weak, nullable) ExampleSettingsSheetView *settingsSheet;

@end

@implementation MTCMapScreenshotViewController

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = UIColor.whiteColor;

    [self configureNavigationItems:NO];
    [self configureMapView];
    [self applyLocalizedTexts];
}

#pragma mark - Delegate

- (void)mapViewDidFinishLoadingMap:(MTCMapView *)mapView {
    (void)mapView;
}

#pragma mark - Event

- (void)handleExampleSettingsAction {
    if ([self isSettingsSheetVisible:ExampleSettingsSheetView.class]) {
        return;
    }
    [self showScreenshotSettings];
}

#pragma mark - Private

- (void)configureMapView {
    self.mapView = [[MTCMapView alloc] initWithFrame:CGRectZero];
    self.mapView.translatesAutoresizingMaskIntoConstraints = NO;
    self.mapView.delegate = self;
    self.mapView.mapLanguage = [self mapLanguageForDemoLanguage:self.demoLanguage];
    self.mapView.mapType = MTCMapTypeStandard;
    self.mapView.uiSettings.compassEnabled = NO;
    self.mapView.uiSettings.scaleBarEnabled = NO;
    self.mapView.uiSettings.zoomButtonsEnabled = YES;
    self.mapView.uiSettings.zoomLevelVisible = NO;
    self.mapView.uiSettings.dayNightModeEnabled = NO;
    [self.view addSubview:self.mapView];

    [NSLayoutConstraint activateConstraints:@[
        [self.mapView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.mapView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.mapView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.mapView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];

    CLLocationCoordinate2D coor = CLLocationCoordinate2DMake(MTCMapScreenshotInitialLatitude, MTCMapScreenshotInitialLongitude);
    [self.mapView setCenterCoordinate:coor transition:[MTCCameraTransition jump] completion:nil];
    [self.mapView setZoomLevel:MTCMapScreenshotInitialZoomLevel transition:[MTCCameraTransition jump] completion:nil];
}

- (void)showScreenshotSettings {
    ExampleSettingsSheetView *sheet =
        [[ExampleSettingsSheetView alloc] initWithTitle:[self localizedStringForKey:@"common_settings_sheet_title"]
                                               sections:[self screenshotSections]];
    self.settingsSheet = sheet;
    [sheet showInView:self.view animated:YES];
}

- (NSArray<ExampleSettingsSection *> *)screenshotSections {
    __weak typeof(self) weakSelf = self;

    ExampleSettingsItem *captureItem =
        [[ExampleSettingsItem actionItemWithTitle:@"截取地图"
                                          handler:^{
        [weakSelf captureCurrentMapSnapshot];
    }] enabledWhen:^BOOL {
        return !weakSelf.snapshotInProgress;
    }];

    ExampleSettingsItem *saveItem =
        [[ExampleSettingsItem actionItemWithTitle:@"保存到相册"
                                          handler:^{
        [weakSelf saveCurrentSnapshotToAlbum];
    }] enabledWhen:^BOOL {
        return weakSelf.capturedImage != nil && !weakSelf.snapshotInProgress;
    }];

    ExampleSettingsItem *shareItem =
        [[ExampleSettingsItem actionItemWithTitle:@"分享图片"
                                          handler:^{
        [weakSelf shareCurrentSnapshot];
    }] enabledWhen:^BOOL {
        return weakSelf.capturedImage != nil && !weakSelf.snapshotInProgress;
    }];

    ExampleSettingsItem *previewItem =
        [[ExampleSettingsItem imagePreviewItemWithTitle:@"预览"
                                            imageGetter:^UIImage * _Nullable {
        return weakSelf.capturedImage;
    }] visibleWhen:^BOOL {
        return weakSelf.capturedImage != nil;
    }];

    return @[
        [ExampleSettingsSection sectionWithTitle:@"地图截屏" items:@[
            [ExampleSettingsItem dynamicInfoItemWithGetter:^NSString *{
                return [weakSelf snapshotStatusText];
            }],
            captureItem,
            saveItem,
            shareItem,
        ]],
        [ExampleSettingsSection sectionWithTitle:@"" items:@[
            previewItem,
        ]],
    ];
}

- (void)captureCurrentMapSnapshot {
    if (self.snapshotInProgress) {
        return;
    }

    self.snapshotInProgress = YES;
    [self.settingsSheet reloadData];

    __weak typeof(self) weakSelf = self;
    [self.mapView takeSnapshotInRect:self.mapView.bounds
                             timeout:2.5
                   afterScreenUpdates:YES
                          completion:^(UIImage *resultImage, NSInteger state) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }
        self.snapshotInProgress = NO;
        if ((MTCMapSnapshotState)state == MTCMapSnapshotStateSuccess && resultImage != nil) {
            self.capturedImage = resultImage;
        } else {
            [MTCExampleToastView showMessage:@"截图失败" inView:self.view];
        }
        [self.settingsSheet reloadData];
    }];
}

- (void)saveCurrentSnapshotToAlbum {
    if (!self.capturedImage) {
        return;
    }
    UIImageWriteToSavedPhotosAlbum(self.capturedImage,
                                   self,
                                   @selector(image:didFinishSavingWithError:contextInfo:),
                                   nil);
}

- (void)shareCurrentSnapshot {
    if (!self.capturedImage) {
        return;
    }

    UIActivityViewController *activityViewController =
        [[UIActivityViewController alloc] initWithActivityItems:@[self.capturedImage]
                                          applicationActivities:nil];
    activityViewController.popoverPresentationController.sourceView = self.view;
    activityViewController.popoverPresentationController.sourceRect = self.view.bounds;
    [self presentViewController:activityViewController animated:YES completion:nil];
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    (void)image;
    (void)contextInfo;
    NSString *message = error ? @"保存失败" : @"已保存到相册";
    [MTCExampleToastView showMessage:message inView:self.view];
}

- (NSString *)snapshotStatusText {
    if (self.snapshotInProgress) {
        return @"正在截图...";
    }
    if (!self.capturedImage) {
        return @"尚未截图";
    }

    CGSize imageSize = self.capturedImage.size;
    CGFloat imageScale = self.capturedImage.scale > 0.0 ? self.capturedImage.scale : UIScreen.mainScreen.scale;
    NSUInteger pixelWidth = (NSUInteger)llround(imageSize.width * imageScale);
    NSUInteger pixelHeight = (NSUInteger)llround(imageSize.height * imageScale);
    return [NSString stringWithFormat:@"截图成功： %lu × %lu px",
                                      (unsigned long)pixelWidth,
                                      (unsigned long)pixelHeight];
}

#pragma mark -- multi-language

- (void)demoLanguageDidChange {
    [self applyLocalizedTexts];
}

- (void)applyLocalizedTexts {
    self.title = [self localizedStringForKey:@"demo_title_MTCMapScreenshotViewController"];
    self.mapView.mapLanguage = [self mapLanguageForDemoLanguage:self.demoLanguage];
}

- (void)mapView:(MTCMapView *)mapView cameraWillChangeWithReason:(MTCMapCameraChangeReason)reason animated:(BOOL)animated {
    NSLog(@"MTCMapScreenshotViewController cameraWillChangeWithReason: reason: %@", @(reason));
    
}


- (void)mapView:(MTCMapView *)mapView cameraDidChange:(MTCMapCamera *)camera reason:(MTCMapCameraChangeReason)reason animated:(BOOL)animated {
    NSLog(@"MTCMapScreenshotViewController cameraDidChange");
}

- (void)mapView:(MTCMapView *)mapView cameraDidBecomeIdle:(MTCMapCamera *)camera reason:(MTCMapCameraChangeReason)reason animated:(BOOL)animated {
    NSLog(@"MTCMapScreenshotViewController cameraDidBecomeIdle");
}
@end
