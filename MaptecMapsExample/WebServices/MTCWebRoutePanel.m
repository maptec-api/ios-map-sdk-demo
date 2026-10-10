//
//  MTCWebRoutePanel.m
//  MaptecMapsExample
//
//  Created by ZHOUPanpan on 2026/8/3.
//  Copyright © 2026 ZHOUPanpan. All rights reserved.
//

#import "MTCWebRoutePanel.h"

#import "MTCExampleDemoLocalization.h"
#import <Masonry/Masonry.h>

@interface MTCWebRoutePanel ()

@property (nonatomic, strong) UIVisualEffectView *blurView;
@property (nonatomic, strong) UISegmentedControl *routeSegmentedControl;
@property (nonatomic, strong) UILabel *summaryLabel;
@property (nonatomic, strong) UIButton *overviewButton;
@property (nonatomic, strong) UIButton *clearButton;

@end

@implementation MTCWebRoutePanel

- (void)dealloc {
}

#pragma mark - Public

- (void)reloadWithTitles:(NSArray<NSString *> *)titles selectedIndex:(NSInteger)selectedIndex {
    [self.routeSegmentedControl removeAllSegments];
    [titles enumerateObjectsUsingBlock:^(NSString *title, NSUInteger index, BOOL *stop) {
        (void)stop;
        [self.routeSegmentedControl insertSegmentWithTitle:title ?: @"" atIndex:index animated:NO];
    }];
    if (titles.count > 0 && selectedIndex >= 0 && selectedIndex < (NSInteger)titles.count) {
        self.routeSegmentedControl.selectedSegmentIndex = selectedIndex;
    }
}

- (void)updateSummaryText:(NSString *)text {
    self.summaryLabel.text = text ?: @"";
}

- (void)setSelectedSegmentIndex:(NSInteger)index {
    if (index < 0 || index >= self.routeSegmentedControl.numberOfSegments) {
        return;
    }
    self.routeSegmentedControl.selectedSegmentIndex = index;
}

#pragma mark - Life Cycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupViews];
        [self setupConstraints];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self setupViews];
        [self setupConstraints];
    }
    return self;
}

#pragma mark - Protocol

#pragma mark - Delegate

#pragma mark - Event

- (void)routeSegmentValueChanged:(UISegmentedControl *)sender {
    if (self.onSegmentChanged) {
        self.onSegmentChanged(sender.selectedSegmentIndex);
    }
}

- (void)overviewButtonTapped {
    if (self.onOverviewTapped) {
        self.onOverviewTapped();
    }
}

- (void)clearButtonTapped {
    if (self.onClearTapped) {
        self.onClearTapped();
    }
}

#pragma mark - Private

- (void)setupViews {
    self.layer.cornerRadius = 12.0;
    self.clipsToBounds = YES;
    self.hidden = YES;

    self.blurView =
        [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterial]];
    [self addSubview:self.blurView];

    self.routeSegmentedControl = [[UISegmentedControl alloc] initWithItems:@[]];
    [self.routeSegmentedControl addTarget:self
                                   action:@selector(routeSegmentValueChanged:)
                         forControlEvents:UIControlEventValueChanged];
    [self.blurView.contentView addSubview:self.routeSegmentedControl];

    self.summaryLabel = [[UILabel alloc] init];
    self.summaryLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    self.summaryLabel.textColor = UIColor.secondaryLabelColor;
    self.summaryLabel.numberOfLines = 1;
    [self.blurView.contentView addSubview:self.summaryLabel];

    self.overviewButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.overviewButton addTarget:self
                            action:@selector(overviewButtonTapped)
                  forControlEvents:UIControlEventTouchUpInside];
    [self.blurView.contentView addSubview:self.overviewButton];

    self.clearButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.clearButton addTarget:self
                         action:@selector(clearButtonTapped)
               forControlEvents:UIControlEventTouchUpInside];
    [self.blurView.contentView addSubview:self.clearButton];
    [self applyLocalizedTexts];
}

- (void)applyLocalizedTexts {
    MTCExampleDemoLanguage language = [MTCExampleDemoLocalization currentLanguage];
    [self.overviewButton setTitle:[MTCExampleDemoLocalization stringForKey:@"web_overview" language:language]
                         forState:UIControlStateNormal];
    [self.clearButton setTitle:[MTCExampleDemoLocalization stringForKey:@"web_clear" language:language]
                      forState:UIControlStateNormal];
}

- (void)setupConstraints {
    [self.blurView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];

    [self.routeSegmentedControl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.blurView.contentView).offset(10.0);
        make.leading.equalTo(self.blurView.contentView).offset(12.0);
        make.trailing.equalTo(self.blurView.contentView).offset(-12.0);
    }];

    [self.clearButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(self.blurView.contentView).offset(-12.0);
        make.bottom.equalTo(self.blurView.contentView).offset(-12.0);
    }];

    [self.overviewButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(self.clearButton.mas_leading).offset(-16.0);
        make.centerY.equalTo(self.clearButton);
    }];

    [self.summaryLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.blurView.contentView).offset(12.0);
        make.trailing.lessThanOrEqualTo(self.overviewButton.mas_leading).offset(-8.0);
        make.centerY.equalTo(self.clearButton);
        make.bottom.equalTo(self.blurView.contentView).offset(-12.0);
    }];
}

#pragma mark - Getter & Setter

@end
