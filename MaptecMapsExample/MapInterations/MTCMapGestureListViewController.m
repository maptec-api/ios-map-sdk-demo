//
//  MTCMapGestureListViewController.m
//  MaptecMapsExample
//
//  Created by ZHOUPanpan on 2026/7/10.
//

#import "MTCMapGestureListViewController.h"

#import "MTCMapGestureControlViewController.h"
#import "MTCMapGestureCoordinationViewController.h"
#import "MTCMapGestureDoubleClickDelayViewController.h"
#import "MTCMapGestureDoubleTapPitchResetViewController.h"
#import "MTCMapGestureDoubleTapZoomFactorViewController.h"
#import "MTCMapGestureInertialScrollDurationViewController.h"
#import "MTCMapGestureResistanceThresholdViewController.h"
#import "MTCMapGestureRotateBearingRangeViewController.h"
#import "MTCMapGestureTwoFingerTapZoomResetViewController.h"
#import "MTCMapGestureZoomAnimationDurationViewController.h"
#import "MTCMapGestureZoomCenterModeViewController.h"

@interface MTCMapGestureListSection : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSArray<NSString *> *items;

+ (instancetype)sectionWithTitle:(NSString *)title items:(NSArray<NSString *> *)items;

@end

@implementation MTCMapGestureListSection

+ (instancetype)sectionWithTitle:(NSString *)title items:(NSArray<NSString *> *)items {
    MTCMapGestureListSection *section = [[MTCMapGestureListSection alloc] init];
    section.title = title;
    section.items = items;
    return section;
}

@end

@interface MTCMapGestureListViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy) NSArray<MTCMapGestureListSection *> *sections;

@end

@implementation MTCMapGestureListViewController

- (void)dealloc {
}
#pragma mark - Public

#pragma mark - Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureNavigationItems:YES];
    self.view.backgroundColor = UIColor.systemGroupedBackgroundColor;

    [self configureSections];
    [self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:@"MTCMapGestureCell"];
    [self.view addSubview:self.tableView];
    [self applyLocalizedTexts];
}

#pragma mark - protocol

#pragma mark - Delegate
#pragma mark -- UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    (void)tableView;
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    (void)tableView;
    return self.sections[section].items.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    (void)tableView;
    return self.sections[section].title;
}

- (NSString *)classNameForIndexPath:(NSIndexPath *)indexPath {
    if ([self isGestureControlIndexPath:indexPath]) {
        return NSStringFromClass(MTCMapGestureControlViewController.class);
    } else if ([self isGestureCoordinationIndexPath:indexPath]) {
        return NSStringFromClass(MTCMapGestureCoordinationViewController.class);
    } else if ([self isDoubleClickDelayIndexPath:indexPath]) {
        return NSStringFromClass(MTCMapGestureDoubleClickDelayViewController.class);
    } else if ([self isTwoFingerTapZoomResetIndexPath:indexPath]) {
        return NSStringFromClass(MTCMapGestureTwoFingerTapZoomResetViewController.class);
    } else if ([self isDoubleTapZoomFactorIndexPath:indexPath]) {
        return NSStringFromClass(MTCMapGestureDoubleTapZoomFactorViewController.class);
    } else if ([self isDoubleTapPitchResetIndexPath:indexPath]) {
        return NSStringFromClass(MTCMapGestureDoubleTapPitchResetViewController.class);
    } else if ([self isZoomCenterModeIndexPath:indexPath]) {
        return NSStringFromClass(MTCMapGestureZoomCenterModeViewController.class);
    } else if ([self isZoomAnimationDurationIndexPath:indexPath]) {
        return NSStringFromClass(MTCMapGestureZoomAnimationDurationViewController.class);
    } else if ([self isRotateBearingRangeIndexPath:indexPath]) {
        return NSStringFromClass(MTCMapGestureRotateBearingRangeViewController.class);
    } else if ([self isResistanceThresholdIndexPath:indexPath]) {
        return NSStringFromClass(MTCMapGestureResistanceThresholdViewController.class);
    } else if ([self isInertialScrollDurationIndexPath:indexPath]) {
        return NSStringFromClass(MTCMapGestureInertialScrollDurationViewController.class);
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MTCMapGestureCell" forIndexPath:indexPath];
    cell.textLabel.text = self.sections[indexPath.section].items[indexPath.row];
    cell.accessibilityIdentifier = [self classNameForIndexPath:indexPath];
    cell.accessoryType = [self canOpenLandingPageAtIndexPath:indexPath] ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
    return cell;
}

#pragma mark -- UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString *className = [self classNameForIndexPath:indexPath];
    if (className.length > 0) {
        Class vcClass = NSClassFromString(className);
        if ([vcClass isSubclassOfClass:UIViewController.class]) {
            UIViewController *viewController = [[vcClass alloc] init];
            [self.navigationController pushViewController:viewController animated:YES];
        }
    }
}

#pragma mark - Event

#pragma mark - Private
- (void)configureSections {
    self.sections = @[
        [MTCMapGestureListSection sectionWithTitle:[self localizedStringForKey:@"gesture_section_basic"] items:@[
            [self localizedStringForKey:@"demo_title_MTCMapGestureControlViewController"],
            [self localizedStringForKey:@"demo_title_MTCMapGestureCoordinationViewController"],
        ]],
        [MTCMapGestureListSection sectionWithTitle:[self localizedStringForKey:@"gesture_section_double_tap"] items:@[
            [self localizedStringForKey:@"demo_title_MTCMapGestureDoubleClickDelayViewController"],
            [self localizedStringForKey:@"demo_title_MTCMapGestureTwoFingerTapZoomResetViewController"],
            [self localizedStringForKey:@"demo_title_MTCMapGestureDoubleTapZoomFactorViewController"],
            [self localizedStringForKey:@"demo_title_MTCMapGestureDoubleTapPitchResetViewController"],
        ]],
        [MTCMapGestureListSection sectionWithTitle:[self localizedStringForKey:@"gesture_section_zoom"] items:@[
            [self localizedStringForKey:@"demo_title_MTCMapGestureZoomCenterModeViewController"],
            [self localizedStringForKey:@"demo_title_MTCMapGestureZoomAnimationDurationViewController"],
        ]],
        [MTCMapGestureListSection sectionWithTitle:[self localizedStringForKey:@"gesture_section_rotate"] items:@[
            [self localizedStringForKey:@"demo_title_MTCMapGestureRotateBearingRangeViewController"],
        ]],
        [MTCMapGestureListSection sectionWithTitle:[self localizedStringForKey:@"gesture_section_resistance"] items:@[
            [self localizedStringForKey:@"demo_title_MTCMapGestureResistanceThresholdViewController"],
            [self localizedStringForKey:@"demo_title_MTCMapGestureInertialScrollDurationViewController"],
        ]],
    ];
}

- (BOOL)isGestureControlIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == 0 && indexPath.row == 0;
}

- (BOOL)isGestureCoordinationIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == 0 && indexPath.row == 1;
}

- (BOOL)isDoubleClickDelayIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == 1 && indexPath.row == 0;
}

- (BOOL)isTwoFingerTapZoomResetIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == 1 && indexPath.row == 1;
}

- (BOOL)isDoubleTapZoomFactorIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == 1 && indexPath.row == 2;
}

- (BOOL)isDoubleTapPitchResetIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == 1 && indexPath.row == 3;
}

- (BOOL)isZoomCenterModeIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == 2 && indexPath.row == 0;
}

- (BOOL)isZoomAnimationDurationIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == 2 && indexPath.row == 1;
}

- (BOOL)isRotateBearingRangeIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == 3 && indexPath.row == 0;
}

- (BOOL)isResistanceThresholdIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == 4 && indexPath.row == 0;
}

- (BOOL)isInertialScrollDurationIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == 4 && indexPath.row == 1;
}

- (BOOL)canOpenLandingPageAtIndexPath:(NSIndexPath *)indexPath {
    return [self isGestureControlIndexPath:indexPath] ||
           [self isGestureCoordinationIndexPath:indexPath] ||
           [self isDoubleClickDelayIndexPath:indexPath] ||
           [self isTwoFingerTapZoomResetIndexPath:indexPath] ||
           [self isDoubleTapZoomFactorIndexPath:indexPath] ||
           [self isDoubleTapPitchResetIndexPath:indexPath] ||
           [self isZoomCenterModeIndexPath:indexPath] ||
           [self isZoomAnimationDurationIndexPath:indexPath] ||
           [self isRotateBearingRangeIndexPath:indexPath] ||
           [self isResistanceThresholdIndexPath:indexPath] ||
           [self isInertialScrollDurationIndexPath:indexPath];
}

#pragma mark -- multi-language

- (void)demoLanguageDidChange {
    [self applyLocalizedTexts];
}

- (void)applyLocalizedTexts {
    self.title = [self localizedStringForKey:@"demo_title_MTCMapGestureListViewController"];
    [self configureSections];
    [self.tableView reloadData];
}

#pragma mark - Getter & Setter
- (UITableView *)tableView {
    if (_tableView) {
        return _tableView;
    }

    _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleInsetGrouped];
    _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _tableView.dataSource = self;
    _tableView.delegate = self;
    return _tableView;
}

@end
