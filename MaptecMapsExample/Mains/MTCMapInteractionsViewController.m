//
//  MTCMapInteractionsViewController.m
//  MaptecMapsExample
//
//  Created by ZHOUPanpan on 2026/7/10.
//

#import "MTCMapInteractionsViewController.h"

#import "MTCExampleMarkModel.h"
#import "MTCMapEventListViewController.h"
#import "MTCMapGestureListViewController.h"
#import "MTCMapContentPaddingViewController.h"
#import "MTCMapLimitViewController.h"
#import "MTCMapLocationViewController.h"
#import "MTCMapPOIsViewController.h"
#import "MTCMapScreenshotViewController.h"
#import "MTCMapUIListViewController.h"

@interface MTCMapInteractionsViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy) NSArray<MTCExampleMarkModel *> *items;

@end

@implementation MTCMapInteractionsViewController

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
    MTCExampleMarkModel *uiModel = [[MTCExampleMarkModel alloc] init];
    uiModel.title = [self localizedStringForKey:@"demo_title_MTCMapUIListViewController"];
    uiModel.className = NSStringFromClass(MTCMapUIListViewController.class);

    MTCExampleMarkModel *gestureModel = [[MTCExampleMarkModel alloc] init];
    gestureModel.title = [self localizedStringForKey:@"demo_title_MTCMapGestureListViewController"];
    gestureModel.className = NSStringFromClass(MTCMapGestureListViewController.class);

    MTCExampleMarkModel *locationModel = [[MTCExampleMarkModel alloc] init];
    locationModel.title = [self localizedStringForKey:@"demo_title_MTCMapLocationViewController"];
    locationModel.className = NSStringFromClass(MTCMapLocationViewController.class);

    MTCExampleMarkModel *eventModel = [[MTCExampleMarkModel alloc] init];
    eventModel.title = [self localizedStringForKey:@"demo_title_MTCMapEventListViewController"];
    eventModel.className = NSStringFromClass(MTCMapEventListViewController.class);

    MTCExampleMarkModel *poiModel = [[MTCExampleMarkModel alloc] init];
    poiModel.title = [self localizedStringForKey:@"demo_title_MTCMapPOIsViewController"];
    poiModel.className = NSStringFromClass(MTCMapPOIsViewController.class);

    MTCExampleMarkModel *screenshotModel = [[MTCExampleMarkModel alloc] init];
    screenshotModel.title = [self localizedStringForKey:@"demo_title_MTCMapScreenshotViewController"];
    screenshotModel.className = NSStringFromClass(MTCMapScreenshotViewController.class);

    MTCExampleMarkModel *limitModel = [[MTCExampleMarkModel alloc] init];
    limitModel.title = [self localizedStringForKey:@"demo_title_MTCMapLimitViewController"];
    limitModel.className = NSStringFromClass(MTCMapLimitViewController.class);

    MTCExampleMarkModel *contentPaddingModel = [[MTCExampleMarkModel alloc] init];
    contentPaddingModel.title = [self localizedStringForKey:@"demo_title_MTCMapContentPaddingViewController"];
    contentPaddingModel.className = NSStringFromClass(MTCMapContentPaddingViewController.class);

    self.items = @[uiModel, gestureModel, locationModel, eventModel, poiModel, screenshotModel, limitModel, contentPaddingModel];
}

#pragma mark -- multi-language

- (void)demoLanguageDidChange {
    [self applyLocalizedTexts];
}

- (void)applyLocalizedTexts {
    self.title = [self localizedStringForKey:@"demo_title_MTCMapInteractionsViewController"];
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
