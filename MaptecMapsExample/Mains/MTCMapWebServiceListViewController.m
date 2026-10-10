//
//  MTCMapWebServiceListViewController.m
//  MaptecMapsExample
//
//  Created by ZHOUPanpan on 2026/7/10.
//

#import "MTCMapWebServiceListViewController.h"

#import "MTCExampleMarkModel.h"

#import "MTCWebGeoCodingViewController.h"
#import "MTCWebInputTipsViewController.h"
#import "MTCWebLocationDetailViewController.h"
#import "MTCWebAlongSearchViewController.h"
#import "MTCWebNearbySearchViewController.h"
#import "MTCMapRouteViewController.h"
#import "MTCWebReverseGeoCodingViewController.h"
#import "MTCWebTextSearchViewController.h"
#import "MTCWebAuthStatusViewController.h"

@interface MTCMapWebServiceListViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy) NSArray<MTCExampleMarkModel *> *items;

@end

@implementation MTCMapWebServiceListViewController

- (void)dealloc {
}
#pragma mark - Public

#pragma mark - Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureNavigationItems:YES];
    self.view.backgroundColor = UIColor.systemGroupedBackgroundColor;
    [self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:@"MTCWebServiceCell"];
    [self configureItems];
    [self.view addSubview:self.tableView];
    [self applyLocalizedTexts];
}

#pragma mark - protocol

#pragma mark - Delegate
#pragma mark -- UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MTCWebServiceCell" forIndexPath:indexPath];
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
    self.items = @[
        [self itemWithTitle:[self localizedStringForKey:@"demo_title_MTCWebTextSearchViewController"]
                      class:NSStringFromClass(MTCWebTextSearchViewController.class)],
        [self itemWithTitle:[self localizedStringForKey:@"demo_title_MTCWebNearbySearchViewController"]
                      class:NSStringFromClass(MTCWebNearbySearchViewController.class)],
        [self itemWithTitle:[self localizedStringForKey:@"demo_title_MTCWebAlongSearchViewController"]
                      class:NSStringFromClass(MTCWebAlongSearchViewController.class)],
        [self itemWithTitle:[self localizedStringForKey:@"demo_title_MTCWebInputTipsViewController"]
                      class:NSStringFromClass(MTCWebInputTipsViewController.class)],
        [self itemWithTitle:[self localizedStringForKey:@"demo_title_MTCWebLocationDetailViewController"]
                      class:NSStringFromClass(MTCWebLocationDetailViewController.class)],
        [self itemWithTitle:[self localizedStringForKey:@"demo_title_MTCWebGeoCodingViewController"]
                      class:NSStringFromClass(MTCWebGeoCodingViewController.class)],
        [self itemWithTitle:[self localizedStringForKey:@"demo_title_MTCWebReverseGeoCodingViewController"]
                      class:NSStringFromClass(MTCWebReverseGeoCodingViewController.class)],
        [self itemWithTitle:[self localizedStringForKey:@"demo_title_MTCMapRouteViewController"]
                      class:NSStringFromClass(MTCMapRouteViewController.class)],
        [self itemWithTitle:[self localizedStringForKey:@"demo_title_MTCWebAuthStatusViewController"]
                      class:NSStringFromClass(MTCWebAuthStatusViewController.class)],
    ];
}

- (MTCExampleMarkModel *)itemWithTitle:(NSString *)title class:(NSString *)className {
    MTCExampleMarkModel *model = [[MTCExampleMarkModel alloc] init];
    model.title = title;
    model.className = className;
    return model;
}

#pragma mark -- multi-language

- (void)demoLanguageDidChange {
    [self applyLocalizedTexts];
}

- (void)applyLocalizedTexts {
    self.title = [self localizedStringForKey:@"demo_title_MTCMapWebServiceListViewController"];
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
