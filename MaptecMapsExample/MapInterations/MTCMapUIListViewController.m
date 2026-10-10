//
//  MTCMapUIListViewController.m
//  MaptecMapsExample
//
//  Created by ZHOUPanpan on 2026/7/10.
//

#import "MTCMapUIListViewController.h"

#import "MTCExampleMarkModel.h"
#import "MTCExampleCompassViewController.h"
#import "MTCExampleDayNightViewController.h"
#import "MTCExampleLogoViewController.h"
#import "MTCExampleScaleBarViewController.h"
#import "MTCExampleZoomViewController.h"

@interface MTCMapUIListViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy) NSArray<MTCExampleMarkModel *> *items;

@end

@implementation MTCMapUIListViewController

- (void)dealloc {
}
#pragma mark - Public

#pragma mark - Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureNavigationItems:YES];
    self.view.backgroundColor = UIColor.systemGroupedBackgroundColor;
    [self configureItems];
    [self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:@"MTCExampleMarkCell"];
    [self.view addSubview:self.tableView];
    [self applyLocalizedTexts];
}

#pragma mark - protocol

#pragma mark - Delegate
#pragma mark -- UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    (void)tableView;
    (void)section;
    return self.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MTCExampleMarkCell" forIndexPath:indexPath];
    MTCExampleMarkModel *model = self.items[indexPath.row];
    cell.textLabel.text = model.title;
    cell.accessibilityIdentifier = model.className;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

#pragma mark -- UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    MTCExampleMarkModel *model = self.items[indexPath.row];
    Class viewControllerClass = NSClassFromString(model.className);
    if (![viewControllerClass isSubclassOfClass:UIViewController.class]) {
        return;
    }

    UIViewController *viewController = [[viewControllerClass alloc] init];
    [self.navigationController pushViewController:viewController animated:YES];
}

#pragma mark - Event

#pragma mark - Private
- (void)configureItems {
    MTCExampleMarkModel *zoomModel = [[MTCExampleMarkModel alloc] init];
    zoomModel.title = [self localizedStringForKey:@"map_item_zoom"];
    zoomModel.className = NSStringFromClass(MTCExampleZoomViewController.class);

    MTCExampleMarkModel *compassModel = [[MTCExampleMarkModel alloc] init];
    compassModel.title = [self localizedStringForKey:@"demo_title_MTCExampleCompassViewController"];
    compassModel.className = NSStringFromClass(MTCExampleCompassViewController.class);

    MTCExampleMarkModel *scaleBarModel = [[MTCExampleMarkModel alloc] init];
    scaleBarModel.title = [self localizedStringForKey:@"demo_title_MTCExampleScaleBarViewController"];
    scaleBarModel.className = NSStringFromClass(MTCExampleScaleBarViewController.class);

    MTCExampleMarkModel *dayNightModel = [[MTCExampleMarkModel alloc] init];
    dayNightModel.title = [self localizedStringForKey:@"demo_title_MTCExampleDayNightViewController"];
    dayNightModel.className = NSStringFromClass(MTCExampleDayNightViewController.class);

    MTCExampleMarkModel *logoModel = [[MTCExampleMarkModel alloc] init];
    logoModel.title = [self localizedStringForKey:@"demo_title_MTCExampleLogoViewController"];
    logoModel.className = NSStringFromClass(MTCExampleLogoViewController.class);

    self.items = @[zoomModel, compassModel, scaleBarModel, dayNightModel, logoModel];
}

#pragma mark -- multi-language

- (void)demoLanguageDidChange {
    [self applyLocalizedTexts];
}

- (void)applyLocalizedTexts {
    self.title = [self localizedStringForKey:@"demo_title_MTCMapUIListViewController"];
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
