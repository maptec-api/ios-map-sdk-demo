#import "ExampleHomeViewController.h"

#import "MTCExampleMarkModel.h"
#import "MTCAuthConfigViewController.h"
#import "MTCMapInteractionsViewController.h"
#import "MTCMapListViewController.h"
#import "MTCMapWebServiceListViewController.h"
#import "MTCOverlayListViewController.h"
#import "MTCToolListViewController.h"

@interface ExampleHomeViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy) NSArray<MTCExampleMarkModel *> *sectionItems;

@end

@implementation ExampleHomeViewController

- (void)dealloc {
}
#pragma mark - Public

#pragma mark - Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = UIColor.systemGroupedBackgroundColor;
    [self.view addSubview:self.tableView];
    [self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:@"FeatureCell"];

    [self configureNavigationItems:YES];
    [self applyLocalizedTexts];
}

#pragma mark - protocol

#pragma mark - Delegate
#pragma mark -- UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    (void)tableView;
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    (void)tableView;
    return self.sectionItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FeatureCell" forIndexPath:indexPath];
    MTCExampleMarkModel *model = self.sectionItems[indexPath.row];
    cell.textLabel.text = model.title;
    cell.accessibilityIdentifier = model.className;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

#pragma mark -- UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    MTCExampleMarkModel *model = self.sectionItems[indexPath.row];
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
    self.sectionItems = @[
        [self markModelWithTitle:[self localizedStringForKey:@"home_item_auth"] class:MTCAuthConfigViewController.class],
        [self markModelWithTitle:[self localizedStringForKey:@"home_item_map"] class:MTCMapListViewController.class],
        [self markModelWithTitle:[self localizedStringForKey:@"home_item_overlay"] class:MTCOverlayListViewController.class],
        [self markModelWithTitle:[self localizedStringForKey:@"home_item_interactions"] class:MTCMapInteractionsViewController.class],
        [self markModelWithTitle:[self localizedStringForKey:@"home_item_web"] class:MTCMapWebServiceListViewController.class],
        [self markModelWithTitle:[self localizedStringForKey:@"home_item_tools"] class:MTCToolListViewController.class],
    ];
}

- (MTCExampleMarkModel *)markModelWithTitle:(NSString *)title class:(Class)viewControllerClass {
    MTCExampleMarkModel *model = [[MTCExampleMarkModel alloc] init];
    model.title = title;
    model.className = NSStringFromClass(viewControllerClass);
    return model;
}

#pragma mark -- multi-language

- (void)demoLanguageDidChange {
    [self applyLocalizedTexts];
}

- (void)applyLocalizedTexts {
    self.title = [self localizedStringForKey:@"home_title"];
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
