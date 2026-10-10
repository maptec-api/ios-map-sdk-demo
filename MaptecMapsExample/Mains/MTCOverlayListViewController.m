//
//  MTCOverlayListViewController.m
//  MaptecMapsExample
//
//  Created by ZHOUPanpan on 2026/7/10.
//

#import "MTCOverlayListViewController.h"

#import "MTCExampleMarkModel.h"
#import "OverlayBasicCircleExampleViewController.h"
#import "OverlayBasicMarkerExampleViewController.h"
#import "OverlayBasicPolygonExampleViewController.h"
#import "OverlayBasicPolylineExampleViewController.h"
#import "OverlayMarkerCollisionBehaviorExampleViewController.h"
#import "OverlayDirectionalArrowPolylineExampleViewController.h"
#import "OverlayDraggableCircleExampleViewController.h"
#import "OverlayEqualDistanceCircleExampleViewController.h"
#import "OverlayGlowPolylineExampleViewController.h"
#import "OverlayGradientPolylineExampleViewController.h"
#import "OverlayInnerShadowCircleExampleViewController.h"
#import "OverlayInteractivePolygonExampleViewController.h"
#import "OverlayLineCapPolylineExampleViewController.h"
#import "OverlayLevelExampleViewController.h"
#import "OverlayMarkerAnimationExampleViewController.h"
#import "OverlayMarkerMovementExampleViewController.h"
#import "OverlayNetworkImageMarkerExampleViewController.h"
#import "OverlayOuterGlowCircleExampleViewController.h"
#import "OverlayPatternFillPolygonExampleViewController.h"
#import "OverlayPulseAnimationCircleExampleViewController.h"
#import "OverlayRadiusBreathingCircleExampleViewController.h"
#import "OverlaySDFColorMarkerExampleViewController.h"
#import "OverlayScanAnimationCircleExampleViewController.h"
#import "OverlayTranslatePolygonExampleViewController.h"
#import "OverlayZoomScalingMarkerExampleViewController.h"
#import "MTCFloatInfoRichTextViewController.h"
#import "MTCFloatInfoSimpleViewController.h"
#import "MTCFloatInfoStyleViewController.h"

#import "MTCGEOFencingCircleViewController.h"
#import "MTCGEOFencingPolygonViewController.h"

#import "MTCHeatmapBasicsViewController.h"
#import "OverlayBasicClusterExampleViewController.h"

@interface MTCOverlayListViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy) NSArray<NSString *> *sectionTitles;
@property (nonatomic, copy) NSArray<NSArray<MTCExampleMarkModel *> *> *sectionItems;

@end

@implementation MTCOverlayListViewController

- (void)dealloc {
}
#pragma mark - Public

#pragma mark - Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureNavigationItems:YES];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = UIColor.systemGroupedBackgroundColor;
    [self configureItems];
    [self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:@"MTCExampleMarkCell"];
    [self.view addSubview:self.tableView];
    [self applyLocalizedTexts];
}

#pragma mark - protocol

#pragma mark - Delegate
#pragma mark -- UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    (void)tableView;
    return self.sectionItems.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    (void)tableView;
    return self.sectionItems[section].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MTCExampleMarkCell" forIndexPath:indexPath];
    MTCExampleMarkModel *model = self.sectionItems[indexPath.section][indexPath.row];
    cell.textLabel.text = model.title;
    cell.accessibilityIdentifier = model.className;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

#pragma mark -- UITableViewDelegate

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    (void)tableView;
    return self.sectionTitles[section];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    MTCExampleMarkModel *model = self.sectionItems[indexPath.section][indexPath.row];
    Class viewControllerClass = NSClassFromString(model.className);
    if (![viewControllerClass isSubclassOfClass:UIViewController.class]) {
        return;
    }

    UIViewController *viewController = [[viewControllerClass alloc] init];
    viewController.title = model.title;
    [self.navigationController pushViewController:viewController animated:YES];
}

#pragma mark - Event

#pragma mark - Private
- (void)configureItems {
    self.sectionTitles = @[
        [self localizedStringForKey:@"overlay_section_marker"],
        [self localizedStringForKey:@"overlay_section_infowindow"],
        [self localizedStringForKey:@"overlay_section_polyline"],
        [self localizedStringForKey:@"overlay_section_polygon"],
        [self localizedStringForKey:@"overlay_section_circle"],
        [self localizedStringForKey:@"overlay_section_geofence"],
        [self localizedStringForKey:@"overlay_section_heatmap"],
        [self localizedStringForKey:@"overlay_section_cluster"],
        [self localizedStringForKey:@"overlay_section_level"],
    ];

    self.sectionItems = @[
        @[
            [self itemWithTitle:[self localizedStringForKey:@"demo_title_OverlayBasicMarkerExampleViewController"]
                          class:NSStringFromClass(OverlayBasicMarkerExampleViewController.class)],
            [self itemWithTitle:[self localizedStringForKey:@"demo_title_OverlayZoomScalingMarkerExampleViewController"]
                          class:NSStringFromClass(OverlayZoomScalingMarkerExampleViewController.class)],
            [self itemWithTitle:[self localizedStringForKey:@"demo_title_OverlayNetworkImageMarkerExampleViewController"]
                          class:NSStringFromClass(OverlayNetworkImageMarkerExampleViewController.class)],
            [self itemWithTitle:[self localizedStringForKey:@"demo_title_OverlaySDFColorMarkerExampleViewController"]
                          class:NSStringFromClass(OverlaySDFColorMarkerExampleViewController.class)],
            [self itemWithTitle:[self localizedStringForKey:@"demo_title_OverlayMarkerAnimationExampleViewController"]
                          class:NSStringFromClass(OverlayMarkerAnimationExampleViewController.class)],
            [self itemWithTitle:[self localizedStringForKey:@"demo_title_OverlayMarkerMovementExampleViewController"]
                          class:NSStringFromClass(OverlayMarkerMovementExampleViewController.class)],
            [self itemWithTitle:[self localizedStringForKey:@"demo_title_OverlayMarkerCollisionBehaviorExampleViewController"]
                          class:NSStringFromClass(OverlayMarkerCollisionBehaviorExampleViewController.class)]
        ],
        @[
            [self itemWithTitle:[self localizedStringForKey:@"demo_title_MTCFloatInfoSimpleViewController"]
                          class:NSStringFromClass(MTCFloatInfoSimpleViewController.class)],
            [self itemWithTitle:[self localizedStringForKey:@"demo_title_MTCFloatInfoStyleViewController"]
                          class:NSStringFromClass(MTCFloatInfoStyleViewController.class)],
            [self itemWithTitle:[self localizedStringForKey:@"demo_title_MTCFloatInfoRichTextViewController"]
                          class:NSStringFromClass(MTCFloatInfoRichTextViewController.class)]
        ],
        @[
            [self itemWithTitle:[self localizedStringForKey:@"demo_title_OverlayBasicPolylineExampleViewController"]
                          class:NSStringFromClass(OverlayBasicPolylineExampleViewController.class)],
            [self itemWithTitle:[self localizedStringForKey:@"demo_title_OverlayGlowPolylineExampleViewController"]
                          class:NSStringFromClass(OverlayGlowPolylineExampleViewController.class)],
            [self itemWithTitle:[self localizedStringForKey:@"demo_title_OverlayDirectionalArrowPolylineExampleViewController"]
                          class:NSStringFromClass(OverlayDirectionalArrowPolylineExampleViewController.class)],
            [self itemWithTitle:[self localizedStringForKey:@"demo_title_OverlayLineCapPolylineExampleViewController"]
                          class:NSStringFromClass(OverlayLineCapPolylineExampleViewController.class)],
            [self itemWithTitle:[self localizedStringForKey:@"demo_title_OverlayGradientPolylineExampleViewController"]
                          class:NSStringFromClass(OverlayGradientPolylineExampleViewController.class)]
        ],
        @[
            [self itemWithTitle:[self localizedStringForKey:@"demo_title_OverlayBasicPolygonExampleViewController"]
                          class:NSStringFromClass(OverlayBasicPolygonExampleViewController.class)],
            [self itemWithTitle:[self localizedStringForKey:@"demo_title_OverlayPatternFillPolygonExampleViewController"]
                          class:NSStringFromClass(OverlayPatternFillPolygonExampleViewController.class)],
            [self itemWithTitle:[self localizedStringForKey:@"demo_title_OverlayTranslatePolygonExampleViewController"]
                          class:NSStringFromClass(OverlayTranslatePolygonExampleViewController.class)],
            [self itemWithTitle:[self localizedStringForKey:@"demo_title_OverlayInteractivePolygonExampleViewController"]
                          class:NSStringFromClass(OverlayInteractivePolygonExampleViewController.class)]
        ],
        @[
            [self itemWithTitle:[self localizedStringForKey:@"demo_title_OverlayBasicCircleExampleViewController"]
                          class:NSStringFromClass(OverlayBasicCircleExampleViewController.class)],
            [self itemWithTitle:[self localizedStringForKey:@"demo_title_OverlayEqualDistanceCircleExampleViewController"]
                          class:NSStringFromClass(OverlayEqualDistanceCircleExampleViewController.class)],
            [self itemWithTitle:[self localizedStringForKey:@"demo_title_OverlayDraggableCircleExampleViewController"]
                          class:NSStringFromClass(OverlayDraggableCircleExampleViewController.class)],
            [self itemWithTitle:[self localizedStringForKey:@"demo_title_OverlayInnerShadowCircleExampleViewController"]
                          class:NSStringFromClass(OverlayInnerShadowCircleExampleViewController.class)],
            [self itemWithTitle:[self localizedStringForKey:@"demo_title_OverlayOuterGlowCircleExampleViewController"]
                          class:NSStringFromClass(OverlayOuterGlowCircleExampleViewController.class)],
            [self itemWithTitle:[self localizedStringForKey:@"demo_title_OverlayScanAnimationCircleExampleViewController"]
                          class:NSStringFromClass(OverlayScanAnimationCircleExampleViewController.class)],
            [self itemWithTitle:[self localizedStringForKey:@"demo_title_OverlayPulseAnimationCircleExampleViewController"]
                          class:NSStringFromClass(OverlayPulseAnimationCircleExampleViewController.class)],
            [self itemWithTitle:[self localizedStringForKey:@"demo_title_OverlayRadiusBreathingCircleExampleViewController"]
                          class:NSStringFromClass(OverlayRadiusBreathingCircleExampleViewController.class)]
        ],
        @[
            [self itemWithTitle:[self localizedStringForKey:@"demo_title_MTCGEOFencingCircleViewController"]
                          class:NSStringFromClass(MTCGEOFencingCircleViewController.class)],
            [self itemWithTitle:[self localizedStringForKey:@"demo_title_MTCGEOFencingPolygonViewController"]
                          class:NSStringFromClass(MTCGEOFencingPolygonViewController.class)],
        ],
        @[
            [self itemWithTitle:[self localizedStringForKey:@"demo_title_MTCHeatmapBasicsViewController"]
                          class:NSStringFromClass(MTCHeatmapBasicsViewController.class)],
        ],
        @[
            [self itemWithTitle:[self localizedStringForKey:@"demo_title_OverlayBasicClusterExampleViewController"]
                          class:NSStringFromClass(OverlayBasicClusterExampleViewController.class)],
        ],
        @[
            [self itemWithTitle:[self localizedStringForKey:@"demo_title_OverlayLevelExampleViewController"]
                          class:NSStringFromClass(OverlayLevelExampleViewController.class)],
        ]
    ];
}

- (MTCExampleMarkModel *)itemWithTitle:(NSString *)title class:(NSString *)clzName {
    MTCExampleMarkModel *model = [[MTCExampleMarkModel alloc] init];
    model.title = title;
    model.className = clzName;
    return model;
}

#pragma mark -- multi-language

- (void)demoLanguageDidChange {
    [self applyLocalizedTexts];
}

- (void)applyLocalizedTexts {
    self.title = [self localizedStringForKey:@"demo_title_MTCOverlayListViewController"];
    [self configureItems];
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
