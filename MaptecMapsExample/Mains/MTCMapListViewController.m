//
//  MTCMapListViewController.m
//  MaptecMapsExample
//
//  Created by ZHOUPanpan on 2026/7/10.
//

#import "MTCMapListViewController.h"

#import "MTCExampleMarkModel.h"
#import "MTCMapAddViewController.h"
#import "MTCRouteConditionViewController.h"
#import "MTCMapStyleViewController.h"
#import "MTCMapViewPortController.h"

@interface MTCMapListViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy) NSArray<MTCExampleMarkModel *> *items;

@end

@implementation MTCMapListViewController

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
    MTCExampleMarkModel *addModel = [[MTCExampleMarkModel alloc] init];
    addModel.title = [self localizedStringForKey:@"demo_title_MTCMapAddViewController"];
    addModel.className = NSStringFromClass(MTCMapAddViewController.class);

    MTCExampleMarkModel *mapStyleModel = [[MTCExampleMarkModel alloc] init];
    mapStyleModel.title = [self localizedStringForKey:@"demo_title_MTCMapStyleViewController"];
    mapStyleModel.className = NSStringFromClass(MTCMapStyleViewController.class);

    MTCExampleMarkModel *viewPortModel = [[MTCExampleMarkModel alloc] init];
    viewPortModel.title = [self localizedStringForKey:@"demo_title_MTCMapViewPortController"];
    viewPortModel.className = NSStringFromClass(MTCMapViewPortController.class);

    MTCExampleMarkModel *routeConditionModel = [[MTCExampleMarkModel alloc] init];
    routeConditionModel.title = [self localizedStringForKey:@"demo_title_MTCRouteConditionViewController"];
    routeConditionModel.className = NSStringFromClass(MTCRouteConditionViewController.class);

    self.items = @[addModel, mapStyleModel, viewPortModel, routeConditionModel];
}

#pragma mark -- multi-language

- (void)demoLanguageDidChange {
    [self applyLocalizedTexts];
}

- (void)applyLocalizedTexts {
    self.title = [self localizedStringForKey:@"demo_title_MTCMapListViewController"];
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
