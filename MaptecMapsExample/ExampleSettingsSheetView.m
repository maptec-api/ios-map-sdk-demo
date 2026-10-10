#import "ExampleSettingsSheetView.h"
#import "MTCExampleTestAccessibility.h"

#import "MTCExampleDemoLocalization.h"

#import <Masonry/Masonry.h>

#include <float.h>
#include <math.h>

typedef NS_ENUM(NSInteger, ExampleSettingsItemKind) {
    ExampleSettingsItemKindBool = 0,
    ExampleSettingsItemKindCheckbox,
    ExampleSettingsItemKindRadio,
    ExampleSettingsItemKindNumber,
    ExampleSettingsItemKindSlider,
    ExampleSettingsItemKindSegmented,
    ExampleSettingsItemKindList,
    ExampleSettingsItemKindText,
    ExampleSettingsItemKindMultilineText,
    ExampleSettingsItemKindColorInput,
    ExampleSettingsItemKindAction,
    ExampleSettingsItemKindInfo,
    ExampleSettingsItemKindImagePreview,
    ExampleSettingsItemKindLog,
};

@interface ExampleSettingsListGroup ()
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSArray<NSString *> *options;
@property (nonatomic, copy, nullable) NSArray<NSString *> *optionHexValues;
@property (nonatomic) BOOL initiallyCollapsed;
@end

@implementation ExampleSettingsListGroup

+ (instancetype)groupWithTitle:(NSString *)title
                       options:(NSArray<NSString *> *)options {
    return [self groupWithTitle:title
                        options:options
                 optionHexValues:nil
              initiallyCollapsed:NO];
}

+ (instancetype)groupWithTitle:(NSString *)title
                       options:(NSArray<NSString *> *)options
                optionHexValues:(NSArray<NSString *> *)optionHexValues
             initiallyCollapsed:(BOOL)initiallyCollapsed {
    ExampleSettingsListGroup *group = [[self alloc] init];
    group.title = title;
    group.options = options ?: @[];
    group.optionHexValues = optionHexValues;
    group.initiallyCollapsed = initiallyCollapsed;
    return group;
}

@end

static NSArray<NSString *> *ExampleSettingsFlattenedOptionsFromGroups(NSArray<ExampleSettingsListGroup *> *groups) {
    NSMutableArray<NSString *> *options = [NSMutableArray array];
    for (ExampleSettingsListGroup *group in groups) {
        [options addObjectsFromArray:group.options ?: @[]];
    }
    return [options copy];
}

@interface ExampleSettingsItem ()
@property (nonatomic) ExampleSettingsItemKind kind;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy, nullable) ExampleSettingsBoolGetter boolGetter;
@property (nonatomic, copy, nullable) ExampleSettingsBoolSetter boolSetter;
@property (nonatomic, copy, nullable) ExampleSettingsNumberGetter numberGetter;
@property (nonatomic, copy, nullable) ExampleSettingsNumberSetter numberSetter;
@property (nonatomic, copy, nullable) ExampleSettingsNumberFormatter numberFormatter;
@property (nonatomic) double minimumValue;
@property (nonatomic) double maximumValue;
@property (nonatomic) double stepValue;
@property (nonatomic, copy, nullable) NSArray<NSString *> *segments;
@property (nonatomic, copy, nullable) NSArray<ExampleSettingsListGroup *> *listGroups;
@property (nonatomic, copy, nullable) ExampleSettingsSegmentGetter segmentGetter;
@property (nonatomic, copy, nullable) ExampleSettingsSegmentSetter segmentSetter;
@property (nonatomic) CGSize popupSize;
@property (nonatomic, copy, nullable) NSString *placeholder;
@property (nonatomic) UIKeyboardType keyboardType;
@property (nonatomic, copy, nullable) ExampleSettingsTextGetter textGetter;
@property (nonatomic, copy, nullable) ExampleSettingsTextSetter textSetter;
@property (nonatomic, copy, nullable) ExampleSettingsImageGetter imageGetter;
@property (nonatomic, copy, nullable) NSArray<NSString *> *optionHexValues;
@property (nonatomic, copy, nullable) ExampleSettingsLogGetter logGetter;
@property (nonatomic, copy, nullable) ExampleSettingsActionHandler actionHandler;
@property (nonatomic, copy, nullable) ExampleSettingsEnabledGetter enabledGetter;
@property (nonatomic, copy, nullable) ExampleSettingsVisibleGetter visibleGetter;
@property (nonatomic, copy, nullable) NSString *accessibilityIdentifier;
@end

@implementation ExampleSettingsItem

+ (instancetype)boolItemWithTitle:(NSString *)title
                           getter:(ExampleSettingsBoolGetter)getter
                           setter:(ExampleSettingsBoolSetter)setter {
    ExampleSettingsItem *item = [[self alloc] init];
    item.kind = ExampleSettingsItemKindBool;
    item.title = title;
    item.boolGetter = getter;
    item.boolSetter = setter;
    return item;
}

+ (instancetype)checkboxItemWithTitle:(NSString *)title
                                getter:(ExampleSettingsBoolGetter)getter
                                setter:(ExampleSettingsBoolSetter)setter {
    ExampleSettingsItem *item = [[self alloc] init];
    item.kind = ExampleSettingsItemKindCheckbox;
    item.title = title;
    item.boolGetter = getter;
    item.boolSetter = setter;
    return item;
}

+ (instancetype)radioItemWithTitle:(NSString *)title
                             getter:(ExampleSettingsBoolGetter)getter
                             setter:(ExampleSettingsBoolSetter)setter {
    ExampleSettingsItem *item = [[self alloc] init];
    item.kind = ExampleSettingsItemKindRadio;
    item.title = title;
    item.boolGetter = getter;
    item.boolSetter = setter;
    return item;
}

+ (instancetype)numberItemWithTitle:(NSString *)title
                            minimum:(double)minimum
                            maximum:(double)maximum
                               step:(double)step
                             getter:(ExampleSettingsNumberGetter)getter
                             setter:(ExampleSettingsNumberSetter)setter
                          formatter:(ExampleSettingsNumberFormatter)formatter {
    ExampleSettingsItem *item = [[self alloc] init];
    item.kind = ExampleSettingsItemKindNumber;
    item.title = title;
    item.minimumValue = minimum;
    item.maximumValue = maximum;
    item.stepValue = step;
    item.numberGetter = getter;
    item.numberSetter = setter;
    item.numberFormatter = formatter;
    return item;
}

+ (instancetype)sliderItemWithTitle:(NSString *)title
                            minimum:(double)minimum
                            maximum:(double)maximum
                               step:(double)step
                             getter:(ExampleSettingsNumberGetter)getter
                             setter:(ExampleSettingsNumberSetter)setter
                          formatter:(ExampleSettingsNumberFormatter)formatter {
    ExampleSettingsItem *item = [[self alloc] init];
    item.kind = ExampleSettingsItemKindSlider;
    item.title = title;
    item.minimumValue = minimum;
    item.maximumValue = maximum;
    item.stepValue = step;
    item.numberGetter = getter;
    item.numberSetter = setter;
    item.numberFormatter = formatter;
    return item;
}

+ (instancetype)segmentedItemWithTitle:(NSString *)title
                              segments:(NSArray<NSString *> *)segments
                                getter:(ExampleSettingsSegmentGetter)getter
                                setter:(ExampleSettingsSegmentSetter)setter {
    ExampleSettingsItem *item = [[self alloc] init];
    item.kind = ExampleSettingsItemKindSegmented;
    item.title = title;
    item.segments = segments;
    item.segmentGetter = getter;
    item.segmentSetter = setter;
    return item;
}

+ (instancetype)listItemWithTitle:(NSString *)title
                          options:(NSArray<NSString *> *)options
                           getter:(ExampleSettingsSegmentGetter)getter
                           setter:(ExampleSettingsSegmentSetter)setter {
    return [self listItemWithTitle:title options:options popupSize:CGSizeZero getter:getter setter:setter];
}

+ (instancetype)listItemWithTitle:(NSString *)title
                          options:(NSArray<NSString *> *)options
                        popupSize:(CGSize)popupSize
                           getter:(ExampleSettingsSegmentGetter)getter
                           setter:(ExampleSettingsSegmentSetter)setter {
    ExampleSettingsItem *item = [[self alloc] init];
    item.kind = ExampleSettingsItemKindList;
    item.title = title;
    item.segments = options;
    item.popupSize = popupSize;
    item.segmentGetter = getter;
    item.segmentSetter = setter;
    return item;
}

+ (instancetype)groupedListItemWithTitle:(NSString *)title
                                  groups:(NSArray<ExampleSettingsListGroup *> *)groups
                               popupSize:(CGSize)popupSize
                                  getter:(ExampleSettingsSegmentGetter)getter
                                  setter:(ExampleSettingsSegmentSetter)setter {
    ExampleSettingsItem *item = [[self alloc] init];
    item.kind = ExampleSettingsItemKindList;
    item.title = title;
    item.listGroups = groups;
    item.segments = ExampleSettingsFlattenedOptionsFromGroups(groups);
    item.popupSize = popupSize;
    item.segmentGetter = getter;
    item.segmentSetter = setter;
    return item;
}

+ (instancetype)textItemWithTitle:(NSString *)title
                       placeholder:(NSString *)placeholder
                       keyboardType:(UIKeyboardType)keyboardType
                             getter:(ExampleSettingsTextGetter)getter
                             setter:(ExampleSettingsTextSetter)setter {
    ExampleSettingsItem *item = [[self alloc] init];
    item.kind = ExampleSettingsItemKindText;
    item.title = title;
    item.placeholder = placeholder;
    item.keyboardType = keyboardType;
    item.textGetter = getter;
    item.textSetter = setter;
    return item;
}

+ (instancetype)multilineTextItemWithTitle:(NSString *)title
                                placeholder:(NSString *)placeholder
                                      getter:(ExampleSettingsTextGetter)getter
                                      setter:(ExampleSettingsTextSetter)setter {
    ExampleSettingsItem *item = [[self alloc] init];
    item.kind = ExampleSettingsItemKindMultilineText;
    item.title = title;
    item.placeholder = placeholder;
    item.textGetter = getter;
    item.textSetter = setter;
    return item;
}

+ (instancetype)colorInputItemWithTitle:(NSString *)title
                             placeholder:(NSString *)placeholder
                                 options:(NSArray<NSString *> *)options
                          optionHexValues:(NSArray<NSString *> *)optionHexValues
                               popupSize:(CGSize)popupSize
                                  getter:(ExampleSettingsTextGetter)getter
                                  setter:(ExampleSettingsTextSetter)setter
                            optionGetter:(ExampleSettingsSegmentGetter)getterIndex
                            optionSetter:(ExampleSettingsSegmentSetter)setterIndex {
    ExampleSettingsItem *item = [[self alloc] init];
    item.kind = ExampleSettingsItemKindColorInput;
    item.title = title;
    item.placeholder = placeholder;
    item.keyboardType = UIKeyboardTypeASCIICapable;
    item.textGetter = getter;
    item.textSetter = setter;
    item.segments = options;
    item.optionHexValues = optionHexValues;
    item.popupSize = popupSize;
    item.segmentGetter = getterIndex;
    item.segmentSetter = setterIndex;
    return item;
}

+ (instancetype)actionItemWithTitle:(NSString *)title
                             handler:(ExampleSettingsActionHandler)handler {
    ExampleSettingsItem *item = [[self alloc] init];
    item.kind = ExampleSettingsItemKindAction;
    item.title = title;
    item.actionHandler = handler;
    return item;
}

+ (instancetype)infoItemWithText:(NSString *)text {
    ExampleSettingsItem *item = [[self alloc] init];
    item.kind = ExampleSettingsItemKindInfo;
    item.title = text;
    return item;
}

+ (instancetype)dynamicInfoItemWithGetter:(ExampleSettingsTextGetter)getter {
    ExampleSettingsItem *item = [[self alloc] init];
    item.kind = ExampleSettingsItemKindInfo;
    item.textGetter = getter;
    return item;
}

+ (instancetype)imagePreviewItemWithTitle:(NSString *)title
                              imageGetter:(ExampleSettingsImageGetter)imageGetter {
    ExampleSettingsItem *item = [[self alloc] init];
    item.kind = ExampleSettingsItemKindImagePreview;
    item.title = title;
    item.imageGetter = imageGetter;
    return item;
}

+ (instancetype)logItemWithTitle:(NSString *)title
                       logsGetter:(ExampleSettingsLogGetter)logsGetter
                      clearHandler:(ExampleSettingsActionHandler)clearHandler {
    ExampleSettingsItem *item = [[self alloc] init];
    item.kind = ExampleSettingsItemKindLog;
    item.title = title;
    item.logGetter = logsGetter;
    item.actionHandler = clearHandler;
    return item;
}

- (instancetype)enabledWhen:(ExampleSettingsEnabledGetter)getter {
    self.enabledGetter = getter;
    return self;
}

- (instancetype)visibleWhen:(ExampleSettingsVisibleGetter)getter {
    self.visibleGetter = getter;
    return self;
}

- (instancetype)withAccessibilityIdentifier:(NSString *)accessibilityIdentifier {
    self.accessibilityIdentifier = accessibilityIdentifier;
    return self;
}

- (void)updateTitle:(NSString *)title {
    self.title = [title copy];
}

@end

@interface ExampleSettingsSection ()
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSArray<ExampleSettingsItem *> *items;
@property (nonatomic, copy) NSArray<ExampleSettingsSection *> *childSections;
@property (nonatomic) BOOL collapsible;
@property (nonatomic) BOOL collapsed;
@end

@implementation ExampleSettingsSection

+ (instancetype)sectionWithTitle:(NSString *)title items:(NSArray<ExampleSettingsItem *> *)items {
    ExampleSettingsSection *section = [[self alloc] init];
    section.title = title;
    section.items = items ?: @[];
    section.childSections = @[];
    return section;
}

+ (instancetype)collapsibleSectionWithTitle:(NSString *)title
                         initiallyCollapsed:(BOOL)initiallyCollapsed
                                      items:(NSArray<ExampleSettingsItem *> *)items {
    return [self collapsibleSectionWithTitle:title
                          initiallyCollapsed:initiallyCollapsed
                                       items:items
                               childSections:@[]];
}

+ (instancetype)collapsibleSectionWithTitle:(NSString *)title
                         initiallyCollapsed:(BOOL)initiallyCollapsed
                                      items:(NSArray<ExampleSettingsItem *> *)items
                              childSections:(NSArray<ExampleSettingsSection *> *)childSections {
    ExampleSettingsSection *section = [[self alloc] init];
    section.title = title;
    section.items = items ?: @[];
    section.childSections = childSections ?: @[];
    section.collapsible = YES;
    section.collapsed = initiallyCollapsed;
    return section;
}

@end

@interface ExampleSettingsSectionDisplayEntry : NSObject
@property (nonatomic, strong) ExampleSettingsSection *section;
@property (nonatomic) NSInteger indentationLevel;
@end

@implementation ExampleSettingsSectionDisplayEntry
@end

@interface ExampleSettingsCompactSwitch : UIControl
@property (nonatomic, getter=isOn) BOOL on;
- (void)setOn:(BOOL)on animated:(BOOL)animated;
@end

@implementation ExampleSettingsCompactSwitch {
    UIView *_trackView;
    UIView *_thumbView;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColor.clearColor;

        _trackView = [[UIView alloc] init];
        _trackView.userInteractionEnabled = NO;
        _trackView.layer.cornerRadius = 11.0;
        [self addSubview:_trackView];

        _thumbView = [[UIView alloc] init];
        _thumbView.userInteractionEnabled = NO;
        _thumbView.backgroundColor = UIColor.whiteColor;
        _thumbView.layer.cornerRadius = 9.0;
        _thumbView.layer.shadowColor = UIColor.blackColor.CGColor;
        _thumbView.layer.shadowOpacity = 0.14;
        _thumbView.layer.shadowRadius = 3.0;
        _thumbView.layer.shadowOffset = CGSizeMake(0.0, 1.0);
        [self addSubview:_thumbView];

        self.isAccessibilityElement = YES;
        self.accessibilityTraits = UIAccessibilityTraitButton;
    }
    return self;
}

- (CGSize)intrinsicContentSize {
    return CGSizeMake(40.0, 24.0);
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGRect bounds = self.bounds;
    CGFloat trackHeight = MIN(24.0, CGRectGetHeight(bounds));
    CGFloat trackY = floor((CGRectGetHeight(bounds) - trackHeight) * 0.5);
    CGRect trackFrame = CGRectMake(0.0, trackY, CGRectGetWidth(bounds), trackHeight);
    _trackView.frame = trackFrame;
    _trackView.layer.cornerRadius = trackHeight * 0.5;

    CGFloat thumbInset = 2.0;
    CGFloat thumbSize = MAX(12.0, trackHeight - thumbInset * 2.0);
    CGFloat thumbX = self.isOn ? CGRectGetWidth(trackFrame) - thumbInset - thumbSize : thumbInset;
    _thumbView.frame = CGRectMake(thumbX, trackY + thumbInset, thumbSize, thumbSize);
    _thumbView.layer.cornerRadius = thumbSize * 0.5;
    _thumbView.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:_thumbView.bounds cornerRadius:_thumbView.layer.cornerRadius].CGPath;

    [self updateColors];
}

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    (void)touch;
    (void)event;
    return self.enabled;
}

- (void)endTrackingWithTouch:(nullable UITouch *)touch withEvent:(nullable UIEvent *)event {
    (void)touch;
    (void)event;
    if (!self.enabled) {
        return;
    }
    [self setOn:!self.isOn animated:YES];
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

- (void)setOn:(BOOL)on {
    [self setOn:on animated:NO];
}

- (void)setOn:(BOOL)on animated:(BOOL)animated {
    _on = on;
    self.accessibilityValue = on ? @"1" : @"0";
    void (^changes)(void) = ^{
        [self setNeedsLayout];
        [self layoutIfNeeded];
    };
    if (animated) {
        [UIView animateWithDuration:0.18
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:changes
                         completion:nil];
    } else {
        changes();
    }
}

- (void)setEnabled:(BOOL)enabled {
    [super setEnabled:enabled];
    self.alpha = enabled ? 1.0 : 0.45;
    [self updateColors];
}

- (void)updateColors {
    UIColor *onColor = [UIColor colorWithRed:0.16 green:0.53 blue:0.98 alpha:1.0];
    UIColor *offColor = [UIColor colorWithRed:0.86 green:0.88 blue:0.92 alpha:1.0];
    _trackView.backgroundColor = self.isOn ? onColor : offColor;
    _thumbView.backgroundColor = self.enabled ? UIColor.whiteColor : [UIColor colorWithWhite:0.97 alpha:1.0];
}

@end

@class ExampleSettingsSheetView;
typedef void (^ExampleSettingsListSelectionHandler)(NSInteger index);

@interface ExampleSettingsSheetView (KeyboardAvoidance)
- (void)scrollActiveInputIntoVisibleAreaAnimated:(BOOL)animated;
@end
static UIColor *ExampleSettingsColorFromHexString(NSString *hexString) {
    NSString *candidate = [[hexString ?: @"" stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] uppercaseString];
    if ([candidate hasPrefix:@"#"]) {
        candidate = [candidate substringFromIndex:1];
    }
    if (candidate.length != 6) {
        return [UIColor clearColor];
    }

    unsigned int rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:candidate];
    if (![scanner scanHexInt:&rgbValue]) {
        return [UIColor clearColor];
    }

    return [UIColor colorWithRed:((rgbValue >> 16) & 0xFF) / 255.0
                           green:((rgbValue >> 8) & 0xFF) / 255.0
                            blue:(rgbValue & 0xFF) / 255.0
                           alpha:1.0];
}

static UIImage *ExampleSettingsColorSwatchImage(NSString *hexString) {
    CGSize size = CGSizeMake(20.0, 20.0);
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:size];
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext * _Nonnull rendererContext) {
        CGRect rect = CGRectMake(0.5, 0.5, size.width - 1.0, size.height - 1.0);
        UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:rect];
        [ExampleSettingsColorFromHexString(hexString) setFill];
        [path fill];
        [[UIColor colorWithWhite:0.82 alpha:1.0] setStroke];
        path.lineWidth = 1.0;
        [path stroke];
        (void)rendererContext;
    }];
}

@interface ExampleSettingsListView : UIView <UITableViewDataSource, UITableViewDelegate>
- (instancetype)initWithOptions:(NSArray<NSString *> *)options
                optionHexValues:(nullable NSArray<NSString *> *)optionHexValues
                  selectedIndex:(NSInteger)selectedIndex
                 containerBounds:(CGRect)containerBounds
                      anchorRect:(CGRect)anchorRect
                        handler:(ExampleSettingsListSelectionHandler)handler NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithGroups:(NSArray<ExampleSettingsListGroup *> *)groups
                  selectedIndex:(NSInteger)selectedIndex
                 containerBounds:(CGRect)containerBounds
                      anchorRect:(CGRect)anchorRect
                        handler:(ExampleSettingsListSelectionHandler)handler NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
@end

@implementation ExampleSettingsListView {
    NSArray<NSString *> *_options;
    NSArray<NSString *> *_optionHexValues;
    NSArray<ExampleSettingsListGroup *> *_groups;
    NSMutableIndexSet *_collapsedGroupIndexes;
    BOOL _usesGroupedOptions;
    NSInteger _selectedIndex;
    CGRect _containerBounds;
    CGRect _anchorRect;
    ExampleSettingsListSelectionHandler _handler;
    UIView *_touchView;
    UIView *_panelView;
    UITableView *_tableView;
}

- (instancetype)initWithOptions:(NSArray<NSString *> *)options
                optionHexValues:(NSArray<NSString *> *)optionHexValues
                  selectedIndex:(NSInteger)selectedIndex
                 containerBounds:(CGRect)containerBounds
                      anchorRect:(CGRect)anchorRect
                        handler:(ExampleSettingsListSelectionHandler)handler {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _options = [options copy];
        _optionHexValues = [optionHexValues copy];
        _groups = @[];
        _collapsedGroupIndexes = [NSMutableIndexSet indexSet];
        _usesGroupedOptions = NO;
        _selectedIndex = selectedIndex;
        _containerBounds = containerBounds;
        _anchorRect = anchorRect;
        _handler = [handler copy];
        [self configureViews];
    }
    return self;
}

- (instancetype)initWithGroups:(NSArray<ExampleSettingsListGroup *> *)groups
                  selectedIndex:(NSInteger)selectedIndex
                 containerBounds:(CGRect)containerBounds
                      anchorRect:(CGRect)anchorRect
                        handler:(ExampleSettingsListSelectionHandler)handler {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _groups = [groups copy];
        _options = ExampleSettingsFlattenedOptionsFromGroups(groups);
        _optionHexValues = @[];
        _collapsedGroupIndexes = [NSMutableIndexSet indexSet];
        [_groups enumerateObjectsUsingBlock:^(ExampleSettingsListGroup * _Nonnull group, NSUInteger idx, BOOL * _Nonnull stop) {
            (void)stop;
            if (group.initiallyCollapsed) {
                [_collapsedGroupIndexes addIndex:idx];
            }
        }];
        _usesGroupedOptions = YES;
        _selectedIndex = selectedIndex;
        _containerBounds = containerBounds;
        _anchorRect = anchorRect;
        _handler = [handler copy];
        [self configureViews];
    }
    return self;
}

- (void)configureViews {
    self.backgroundColor = UIColor.clearColor;

    _touchView = [[UIView alloc] init];
    _touchView.backgroundColor = UIColor.clearColor;
    [self addSubview:_touchView];

    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissList)];
    [_touchView addGestureRecognizer:tapGesture];

    _panelView = [[UIView alloc] init];
    _panelView.backgroundColor = UIColor.tertiarySystemBackgroundColor;
    _panelView.layer.cornerRadius = 8.0;
    _panelView.layer.shadowColor = UIColor.blackColor.CGColor;
    _panelView.layer.shadowOpacity = 0.12;
    _panelView.layer.shadowRadius = 10.0;
    _panelView.layer.shadowOffset = CGSizeMake(-4.0, 4.0);
    [self addSubview:_panelView];

    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _tableView.backgroundColor = UIColor.clearColor;
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.rowHeight = 44.0;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [_tableView registerClass:UITableViewCell.class forCellReuseIdentifier:@"ExampleSettingsListCell"];
    [_panelView addSubview:_tableView];

    CGFloat availableBelow = MAX(1.0, CGRectGetHeight(_containerBounds) - CGRectGetMaxY(_anchorRect) - 8.0);
    CGFloat availableAbove = MAX(1.0, CGRectGetMinY(_anchorRect) - 8.0);
    BOOL showBelow = availableBelow >= 180.0 || availableBelow >= availableAbove;
    CGFloat panelHeight = MIN([self preferredPanelHeight], showBelow ? availableBelow : availableAbove);
    CGFloat panelTop = showBelow ? CGRectGetMaxY(_anchorRect) + 4.0 : CGRectGetMinY(_anchorRect) - panelHeight - 4.0;

    [_touchView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    [_panelView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self).offset(CGRectGetMinX(_anchorRect));
        make.top.equalTo(self).offset(panelTop);
        make.width.mas_equalTo(CGRectGetWidth(_anchorRect));
        make.height.mas_equalTo(panelHeight);
    }];
    [_tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(_panelView);
    }];
}

- (CGFloat)preferredPanelHeight {
    if (!_usesGroupedOptions) {
        return 44.0 * MIN((NSInteger)_options.count, 6) + 8.0;
    }

    NSInteger optionCount = 0;
    for (ExampleSettingsListGroup *group in _groups) {
        optionCount += group.options.count;
    }
    CGFloat contentHeight = 36.0 * _groups.count + 44.0 * optionCount + 8.0;
    return MIN(contentHeight, 44.0 * 8.0 + 8.0);
}

- (void)dismissList {
    [self removeFromSuperview];
}

- (NSInteger)flatIndexForIndexPath:(NSIndexPath *)indexPath {
    if (!_usesGroupedOptions) {
        return indexPath.row;
    }

    NSInteger index = 0;
    for (NSInteger section = 0; section < indexPath.section; ++section) {
        index += _groups[section].options.count;
    }
    return index + indexPath.row;
}

- (NSString *)optionTitleAtIndexPath:(NSIndexPath *)indexPath {
    if (!_usesGroupedOptions) {
        return _options[indexPath.row];
    }
    return _groups[indexPath.section].options[indexPath.row];
}

- (NSString *)optionHexValueAtIndexPath:(NSIndexPath *)indexPath {
    if (!_usesGroupedOptions) {
        return (indexPath.row < _optionHexValues.count) ? _optionHexValues[indexPath.row] : nil;
    }

    ExampleSettingsListGroup *group = _groups[indexPath.section];
    return (indexPath.row < group.optionHexValues.count) ? group.optionHexValues[indexPath.row] : nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    (void)tableView;
    if (_usesGroupedOptions) {
        return [_collapsedGroupIndexes containsIndex:section] ? 0 : _groups[section].options.count;
    }
    (void)section;
    return _options.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    (void)tableView;
    return _usesGroupedOptions ? _groups.count : 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ExampleSettingsListCell" forIndexPath:indexPath];
    NSInteger flatIndex = [self flatIndexForIndexPath:indexPath];
    cell.backgroundColor = UIColor.clearColor;
    cell.textLabel.text = [self optionTitleAtIndexPath:indexPath];
    cell.textLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightRegular];
    cell.textLabel.textColor = UIColor.labelColor;
    cell.accessoryType = flatIndex == _selectedIndex ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    NSString *hexValue = [self optionHexValueAtIndexPath:indexPath];
    if (hexValue.length > 0) {
        cell.imageView.image = ExampleSettingsColorSwatchImage(hexValue);
    } else {
        cell.imageView.image = nil;
    }
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    (void)tableView;
    if (!_usesGroupedOptions) {
        return nil;
    }

    UIControl *headerView = [[UIControl alloc] init];
    headerView.backgroundColor = UIColor.clearColor;
    headerView.tag = section;
    [headerView addTarget:self action:@selector(handleGroupHeaderTap:) forControlEvents:UIControlEventTouchUpInside];

    UILabel *label = [[UILabel alloc] init];
    label.text = _groups[section].title;
    label.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightSemibold];
    label.textColor = UIColor.secondaryLabelColor;
    [headerView addSubview:label];

    NSString *imageName = [_collapsedGroupIndexes containsIndex:section] ? @"chevron.right" : @"chevron.down";
    UIImageView *chevronImageView = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:imageName]];
    chevronImageView.tintColor = UIColor.secondaryLabelColor;
    [headerView addSubview:chevronImageView];

    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(headerView).offset(12.0);
        make.centerY.equalTo(headerView);
        make.trailing.lessThanOrEqualTo(chevronImageView.mas_leading).offset(-8.0);
    }];
    [chevronImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(headerView).offset(-12.0);
        make.centerY.equalTo(headerView);
    }];
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    (void)tableView;
    (void)section;
    return _usesGroupedOptions ? 36.0 : 0.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    (void)tableView;
    (void)section;
    return 0.0;
}

- (void)handleGroupHeaderTap:(UIControl *)sender {
    NSInteger section = sender.tag;
    if (section < 0 || section >= _groups.count) {
        return;
    }
    if ([_collapsedGroupIndexes containsIndex:section]) {
        [_collapsedGroupIndexes removeIndex:section];
    } else {
        [_collapsedGroupIndexes addIndex:section];
    }
    [_tableView reloadSections:[NSIndexSet indexSetWithIndex:section]
               withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (_handler) {
        _handler([self flatIndexForIndexPath:indexPath]);
    }
    [self dismissList];
}

@end

typedef NS_ENUM(NSInteger, ExampleSettingsGroupPosition) {
    ExampleSettingsGroupPositionSingle = 0,
    ExampleSettingsGroupPositionTop,
    ExampleSettingsGroupPositionMiddle,
    ExampleSettingsGroupPositionBottom,
};

@interface ExampleSettingsBaseCell : UITableViewCell
@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UIView *cardContentView;
@property (nonatomic, strong) UIView *separatorView;
@property (nonatomic, strong) ExampleSettingsItem *item;
- (void)configureWithItem:(ExampleSettingsItem *)item;
- (void)applyGroupPosition:(ExampleSettingsGroupPosition)position;
- (BOOL)itemEnabled;
- (void)reloadTableView;
- (ExampleSettingsSheetView *)owningSheetView;
@end

@implementation ExampleSettingsBaseCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = UIColor.clearColor;
        self.contentView.backgroundColor = UIColor.clearColor;

        _cardView = [[UIView alloc] init];
        _cardView.backgroundColor = UIColor.systemBackgroundColor;
        _cardView.layer.borderWidth = 0.0;
        [self.contentView addSubview:_cardView];

        _cardContentView = [[UIView alloc] init];
        [_cardView addSubview:_cardContentView];

        _separatorView = [[UIView alloc] init];
        _separatorView.backgroundColor = UIColor.clearColor;
        [_cardView addSubview:_separatorView];

        [_cardView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentView);
        }];
        [_cardContentView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(_cardView).offset(10.0);
            make.trailing.equalTo(_cardView).offset(-10.0);
            make.top.bottom.equalTo(_cardView);
        }];
        [_separatorView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(_cardView).offset(12.0);
            make.trailing.equalTo(_cardView).offset(-12.0);
            make.bottom.equalTo(_cardView);
            make.height.mas_equalTo(1.0 / self.traitCollection.displayScale);
        }];
    }
    return self;
}

- (void)configureWithItem:(ExampleSettingsItem *)item {
    self.item = item;
    BOOL enabled = [self itemEnabled];
    self.contentView.alpha = enabled ? 1.0 : 0.45;
    self.userInteractionEnabled = enabled;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.item = nil;
    self.contentView.alpha = 1.0;
    self.userInteractionEnabled = YES;
}

- (void)applyGroupPosition:(ExampleSettingsGroupPosition)position {
    self.cardView.layer.cornerRadius = 8.0;
    self.cardView.layer.maskedCorners = 0;
    self.separatorView.hidden = YES;

    switch (position) {
        case ExampleSettingsGroupPositionSingle:
            self.cardView.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner |
                                                kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner;
            self.separatorView.hidden = YES;
            break;
        case ExampleSettingsGroupPositionTop:
            self.cardView.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
            break;
        case ExampleSettingsGroupPositionMiddle:
            self.cardView.layer.cornerRadius = 0.0;
            break;
        case ExampleSettingsGroupPositionBottom:
            self.cardView.layer.maskedCorners = kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner;
            break;
    }
}

- (BOOL)itemEnabled {
    return self.item.enabledGetter ? self.item.enabledGetter() : YES;
}

- (void)reloadTableView {
    UIResponder *responder = self;
    while (responder) {
        responder = responder.nextResponder;
        if ([responder isKindOfClass:UITableView.class]) {
            [(UITableView *)responder reloadData];
            return;
        }
    }
}

- (ExampleSettingsSheetView *)owningSheetView {
    UIView *view = self;
    while (view) {
        view = view.superview;
        if ([view isKindOfClass:ExampleSettingsSheetView.class]) {
            return (ExampleSettingsSheetView *)view;
        }
    }
    return nil;
}

@end

@interface ExampleSettingsTitledCell : ExampleSettingsBaseCell
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIView *controlContainer;
@property (nonatomic, strong) MASConstraint *titleTrailingConstraint;
@end

@implementation ExampleSettingsTitledCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightSemibold];
        _titleLabel.textColor = UIColor.secondaryLabelColor;
        _titleLabel.numberOfLines = 2;
        [self.cardContentView addSubview:_titleLabel];

        _controlContainer = [[UIView alloc] init];
        [self.cardContentView addSubview:_controlContainer];

        [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self.cardContentView);
            self.titleTrailingConstraint = make.trailing.equalTo(self.cardContentView);
            make.top.equalTo(self.cardContentView).offset(8.0);
        }];
        [_controlContainer mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.trailing.equalTo(self.cardContentView);
            make.top.equalTo(self.titleLabel.mas_bottom).offset(6.0);
            make.bottom.equalTo(self.cardContentView).offset(-8.0);
        }];
    }
    return self;
}

- (void)configureWithItem:(ExampleSettingsItem *)item {
    [super configureWithItem:item];
    self.titleLabel.text = item.title;
}

@end

@interface ExampleSettingsBoolCell : ExampleSettingsBaseCell
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) ExampleSettingsCompactSwitch *switchControl;
@end

@implementation ExampleSettingsBoolCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightMedium];
        _titleLabel.textColor = UIColor.labelColor;
        _titleLabel.numberOfLines = 2;
        [self.cardContentView addSubview:_titleLabel];

        _switchControl = [[ExampleSettingsCompactSwitch alloc] init];
        [_switchControl addTarget:self action:@selector(handleSwitchChanged:) forControlEvents:UIControlEventValueChanged];
        [self.cardContentView addSubview:_switchControl];

        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleCellToggle)];
        [self.cardContentView addGestureRecognizer:tapGesture];

        [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self.cardContentView);
            make.top.greaterThanOrEqualTo(self.cardContentView).offset(8.0);
            make.bottom.lessThanOrEqualTo(self.cardContentView).offset(-8.0);
            make.centerY.equalTo(self.cardContentView);
            make.trailing.lessThanOrEqualTo(_switchControl.mas_leading).offset(-6.0);
        }];
        [_switchControl mas_makeConstraints:^(MASConstraintMaker *make) {
            make.trailing.equalTo(self.cardContentView);
            make.centerY.equalTo(self.cardContentView);
            make.size.mas_equalTo(CGSizeMake(40.0, 24.0));
        }];
    }
    return self;
}

- (void)configureWithItem:(ExampleSettingsItem *)item {
    [super configureWithItem:item];
    self.titleLabel.text = item.title;
    [self.switchControl setOn:(item.boolGetter ? item.boolGetter() : NO) animated:NO];
    self.switchControl.enabled = [self itemEnabled];
    self.switchControl.accessibilityIdentifier = item.accessibilityIdentifier;
    self.switchControl.isAccessibilityElement = YES;
    self.switchControl.accessibilityLabel = item.title;
    self.switchControl.accessibilityValue = self.switchControl.isOn ? @"1" : @"0";
    self.accessibilityIdentifier = nil;
    self.isAccessibilityElement = NO;
}

- (BOOL)accessibilityActivate {
    [self handleCellToggle];
    return YES;
}

- (void)handleCellToggle {
    if (![self itemEnabled] || !self.item.boolSetter) {
        return;
    }
    [self.switchControl setOn:!self.switchControl.isOn animated:YES];
    self.item.boolSetter(self.switchControl.isOn);
    self.switchControl.accessibilityValue = self.switchControl.isOn ? @"1" : @"0";
    [self reloadTableView];
}

- (void)handleSwitchChanged:(ExampleSettingsCompactSwitch *)sender {
    if (self.item.boolSetter) {
        self.item.boolSetter(sender.isOn);
    }
    self.switchControl.accessibilityValue = sender.isOn ? @"1" : @"0";
    [self reloadTableView];
}

@end

@interface ExampleSettingsCheckboxCell : ExampleSettingsBaseCell
@property (nonatomic, strong) UIButton *checkboxButton;
@property (nonatomic, strong) UILabel *titleLabel;
@end

@implementation ExampleSettingsCheckboxCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _checkboxButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _checkboxButton.userInteractionEnabled = NO;
        _checkboxButton.layer.cornerRadius = 2.0;
        _checkboxButton.layer.borderWidth = 2.0;
        [self.cardContentView addSubview:_checkboxButton];

        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightRegular];
        _titleLabel.textColor = UIColor.labelColor;
        _titleLabel.numberOfLines = 2;
        [self.cardContentView addSubview:_titleLabel];

        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleToggle)];
        [self.cardContentView addGestureRecognizer:tapGesture];

        [_checkboxButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self.cardContentView).offset(20.0);
            make.centerY.equalTo(self.cardContentView);
            make.size.mas_equalTo(CGSizeMake(26.0, 26.0));
        }];
        [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(_checkboxButton.mas_trailing).offset(16.0);
            make.trailing.equalTo(self.cardContentView).offset(-8.0);
            make.top.greaterThanOrEqualTo(self.cardContentView).offset(8.0);
            make.bottom.lessThanOrEqualTo(self.cardContentView).offset(-8.0);
            make.centerY.equalTo(self.cardContentView);
        }];
    }
    return self;
}

- (void)configureWithItem:(ExampleSettingsItem *)item {
    [super configureWithItem:item];
    self.checkboxButton.accessibilityIdentifier = item.accessibilityIdentifier;
    self.accessibilityIdentifier = item.accessibilityIdentifier;
    self.titleLabel.text = item.title;
    [self refreshCheckbox];
}

- (void)handleToggle {
    if (![self itemEnabled] || !self.item.boolSetter) {
        return;
    }
    BOOL nextValue = !(self.item.boolGetter ? self.item.boolGetter() : NO);
    self.item.boolSetter(nextValue);
    [self refreshCheckbox];
}

- (void)refreshCheckbox {
    BOOL selected = self.item.boolGetter ? self.item.boolGetter() : NO;
    UIColor *activeColor = [UIColor colorWithRed:0.37 green:0.35 blue:0.88 alpha:1.0];
    UIColor *borderColor = selected ? activeColor : [UIColor colorWithRed:0.38 green:0.45 blue:0.50 alpha:1.0];
    self.checkboxButton.backgroundColor = selected ? activeColor : UIColor.clearColor;
    self.checkboxButton.layer.borderColor = borderColor.CGColor;

    UIImage *checkmarkImage = [UIImage systemImageNamed:@"checkmark"];
    [self.checkboxButton setImage:(selected ? checkmarkImage : nil) forState:UIControlStateNormal];
    self.checkboxButton.tintColor = UIColor.whiteColor;
}

@end

@interface ExampleSettingsRadioCell : ExampleSettingsBaseCell
@property (nonatomic, strong) UIView *radioOuterView;
@property (nonatomic, strong) UIView *radioInnerView;
@property (nonatomic, strong) UILabel *titleLabel;
@end

@implementation ExampleSettingsRadioCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _radioOuterView = [[UIView alloc] init];
        _radioOuterView.userInteractionEnabled = NO;
        _radioOuterView.layer.cornerRadius = 13.0;
        _radioOuterView.layer.borderWidth = 2.0;
        [self.cardContentView addSubview:_radioOuterView];

        _radioInnerView = [[UIView alloc] init];
        _radioInnerView.userInteractionEnabled = NO;
        _radioInnerView.layer.cornerRadius = 6.0;
        [_radioOuterView addSubview:_radioInnerView];

        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightRegular];
        _titleLabel.textColor = UIColor.labelColor;
        _titleLabel.numberOfLines = 2;
        [self.cardContentView addSubview:_titleLabel];

        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSelect)];
        [self.cardContentView addGestureRecognizer:tapGesture];

        [_radioOuterView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self.cardContentView).offset(20.0);
            make.centerY.equalTo(self.cardContentView);
            make.size.mas_equalTo(CGSizeMake(26.0, 26.0));
        }];
        [_radioInnerView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(_radioOuterView);
            make.size.mas_equalTo(CGSizeMake(12.0, 12.0));
        }];
        [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(_radioOuterView.mas_trailing).offset(16.0);
            make.trailing.equalTo(self.cardContentView).offset(-8.0);
            make.top.greaterThanOrEqualTo(self.cardContentView).offset(8.0);
            make.bottom.lessThanOrEqualTo(self.cardContentView).offset(-8.0);
            make.centerY.equalTo(self.cardContentView);
        }];
    }
    return self;
}

- (void)configureWithItem:(ExampleSettingsItem *)item {
    [super configureWithItem:item];
    self.accessibilityIdentifier = item.accessibilityIdentifier;
    self.titleLabel.text = item.title;
    [self refreshRadio];
}

- (void)handleSelect {
    if (![self itemEnabled] || !self.item.boolSetter) {
        return;
    }
    self.item.boolSetter(YES);
    [self reloadTableView];
}

- (void)refreshRadio {
    BOOL selected = self.item.boolGetter ? self.item.boolGetter() : NO;
    UIColor *activeColor = [UIColor colorWithRed:0.37 green:0.35 blue:0.88 alpha:1.0];
    UIColor *borderColor = selected ? activeColor : [UIColor colorWithRed:0.38 green:0.45 blue:0.50 alpha:1.0];
    self.radioOuterView.layer.borderColor = borderColor.CGColor;
    self.radioInnerView.backgroundColor = activeColor;
    self.radioInnerView.hidden = !selected;
}

@end

@interface ExampleSettingsInfoCell : ExampleSettingsBaseCell
@property (nonatomic, strong) UILabel *messageLabel;
@end

@implementation ExampleSettingsInfoCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _messageLabel = [[UILabel alloc] init];
        _messageLabel.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightRegular];
        _messageLabel.textColor = UIColor.secondaryLabelColor;
        _messageLabel.numberOfLines = 0;
        [self.cardContentView addSubview:_messageLabel];

        [_messageLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.trailing.equalTo(self.cardContentView);
            make.top.equalTo(self.cardContentView).offset(8.0);
            make.bottom.equalTo(self.cardContentView).offset(-8.0);
        }];
    }
    return self;
}

- (void)configureWithItem:(ExampleSettingsItem *)item {
    [super configureWithItem:item];
    self.accessibilityIdentifier = item.accessibilityIdentifier;
    self.messageLabel.accessibilityIdentifier = item.accessibilityIdentifier;
    self.messageLabel.text = item.textGetter ? item.textGetter() : item.title;
}

@end

@interface ExampleSettingsImagePreviewCell : ExampleSettingsBaseCell
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIView *previewContainerView;
@property (nonatomic, strong) UIImageView *previewImageView;
@end

@implementation ExampleSettingsImagePreviewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightSemibold];
        _titleLabel.textColor = UIColor.labelColor;
        [self.cardContentView addSubview:_titleLabel];

        _previewContainerView = [[UIView alloc] init];
        _previewContainerView.backgroundColor = UIColor.systemBackgroundColor;
        _previewContainerView.layer.cornerRadius = 8.0;
        _previewContainerView.layer.borderWidth = 1.0;
        _previewContainerView.layer.borderColor = [UIColor colorWithRed:0.82 green:0.86 blue:0.93 alpha:1.0].CGColor;
        _previewContainerView.clipsToBounds = YES;
        [self.cardContentView addSubview:_previewContainerView];

        _previewImageView = [[UIImageView alloc] init];
        _previewImageView.contentMode = UIViewContentModeScaleAspectFit;
        _previewImageView.clipsToBounds = YES;
        [_previewContainerView addSubview:_previewImageView];

        [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.trailing.equalTo(self.cardContentView);
            make.top.equalTo(self.cardContentView).offset(8.0);
        }];
        [_previewContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.trailing.equalTo(self.cardContentView);
            make.top.equalTo(_titleLabel.mas_bottom).offset(8.0);
            make.bottom.equalTo(self.cardContentView).offset(-8.0);
        }];
        [_previewImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(_previewContainerView);
        }];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.previewImageView.image = nil;
}

- (void)configureWithItem:(ExampleSettingsItem *)item {
    [super configureWithItem:item];
    self.accessibilityIdentifier = item.accessibilityIdentifier;
    self.titleLabel.text = item.title;
    self.previewImageView.image = item.imageGetter ? item.imageGetter() : nil;
}

@end

@interface ExampleSettingsLogCell : ExampleSettingsBaseCell
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *clearButton;
@property (nonatomic, strong) UIView *logContainerView;
@property (nonatomic, strong) UITextView *logTextView;
@property (nonatomic, copy) NSString *displayedLogText;
@property (nonatomic, strong) MASConstraint *titleTrailingToClearConstraint;
@property (nonatomic, strong) MASConstraint *titleTrailingToContentConstraint;
@property (nonatomic, strong) MASConstraint *logTopToClearConstraint;
@property (nonatomic, strong) MASConstraint *logTopToTitleConstraint;
@property (nonatomic, strong) MASConstraint *logTopToContentConstraint;
@end

@implementation ExampleSettingsLogCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightSemibold];
        _titleLabel.textColor = UIColor.labelColor;
        _titleLabel.numberOfLines = 2;
        [self.cardContentView addSubview:_titleLabel];

        _clearButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _clearButton.titleLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightSemibold];
        [_clearButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        [_clearButton setTitleColor:[UIColor colorWithWhite:1.0 alpha:0.6] forState:UIControlStateDisabled];
        _clearButton.backgroundColor = [UIColor colorWithRed:0.37 green:0.37 blue:0.87 alpha:1.0];
        _clearButton.layer.cornerRadius = 8.0;
        [_clearButton addTarget:self action:@selector(handleClear) forControlEvents:UIControlEventTouchUpInside];
        [self.cardContentView addSubview:_clearButton];

        _logContainerView = [[UIView alloc] init];
        _logContainerView.backgroundColor = UIColor.systemGray6Color;
        [self.cardContentView addSubview:_logContainerView];

        _logTextView = [[UITextView alloc] init];
        _logTextView.backgroundColor = UIColor.clearColor;
        _logTextView.editable = NO;
        _logTextView.selectable = NO;
        _logTextView.scrollEnabled = YES;
        _logTextView.alwaysBounceVertical = YES;
        _logTextView.showsVerticalScrollIndicator = YES;
        _logTextView.textContainerInset = UIEdgeInsetsMake(8.0, 8.0, 8.0, 8.0);
        _logTextView.textContainer.lineFragmentPadding = 0.0;
        _logTextView.font = [UIFont monospacedDigitSystemFontOfSize:12.0 weight:UIFontWeightRegular];
        _logTextView.textColor = UIColor.labelColor;
        [_logContainerView addSubview:_logTextView];

        [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self.cardContentView);
            make.top.equalTo(self.cardContentView).offset(10.0);
            self.titleTrailingToClearConstraint = make.trailing.lessThanOrEqualTo(_clearButton.mas_leading).offset(-8.0);
        }];
        [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            self.titleTrailingToContentConstraint = make.trailing.equalTo(self.cardContentView);
        }];
        [self.titleTrailingToContentConstraint deactivate];

        [_clearButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.trailing.equalTo(self.cardContentView);
            make.centerY.equalTo(_titleLabel);
            make.size.mas_equalTo(CGSizeMake(74.0, 44.0));
        }];

        [_logContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.trailing.equalTo(self.cardContentView);
            make.bottom.equalTo(self.cardContentView).offset(-10.0);
            self.logTopToClearConstraint = make.top.equalTo(_clearButton.mas_bottom).offset(6.0);
        }];
        [_logContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
            self.logTopToTitleConstraint = make.top.equalTo(_titleLabel.mas_bottom).offset(6.0);
        }];
        [_logContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
            self.logTopToContentConstraint = make.top.equalTo(self.cardContentView).offset(10.0);
        }];
        [self.logTopToTitleConstraint deactivate];
        [self.logTopToContentConstraint deactivate];

        [_logTextView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(_logContainerView);
        }];
    }
    return self;
}

- (void)configureWithItem:(ExampleSettingsItem *)item {
    [super configureWithItem:item];
    NSArray<NSString *> *logs = item.logGetter ? item.logGetter() : @[];
    BOOL enabled = [self itemEnabled];
    MTCExampleDemoLanguage language = [MTCExampleDemoLocalization currentLanguage];
    NSString *emptyLogsText = [MTCExampleDemoLocalization stringForKey:@"common_no_logs" language:language];
    NSString *clearTitle = [MTCExampleDemoLocalization stringForKey:@"common_clear" language:language];
    NSString *logText = logs.count > 0 ? [logs componentsJoinedByString:@"\n"] : emptyLogsText;
    BOOL logTextChanged = ![self.displayedLogText isEqualToString:logText];
    self.displayedLogText = logText;
    self.titleLabel.text = item.title;
    self.logTextView.text = logText;
    if (logTextChanged) {
        [self scrollLogTextViewToTop];
    }

    BOOL showsClearButton = item.actionHandler != nil;
    BOOL hasTitle = item.title.length > 0;
    self.titleLabel.hidden = !hasTitle;
    self.clearButton.hidden = !showsClearButton;
    [self.clearButton setTitle:clearTitle forState:UIControlStateNormal];
    if (showsClearButton && hasTitle) {
        [self.titleTrailingToClearConstraint activate];
    } else {
        [self.titleTrailingToClearConstraint deactivate];
    }
    if (!showsClearButton && hasTitle) {
        [self.titleTrailingToContentConstraint activate];
    } else {
        [self.titleTrailingToContentConstraint deactivate];
    }
    if (showsClearButton) {
        [self.logTopToClearConstraint activate];
    } else {
        [self.logTopToClearConstraint deactivate];
    }
    if (!showsClearButton && hasTitle) {
        [self.logTopToTitleConstraint activate];
    } else {
        [self.logTopToTitleConstraint deactivate];
    }
    if (!showsClearButton && !hasTitle) {
        [self.logTopToContentConstraint activate];
    } else {
        [self.logTopToContentConstraint deactivate];
    }
    if (showsClearButton) {
        self.clearButton.enabled = enabled && logs.count > 0;
        self.clearButton.alpha = self.clearButton.enabled ? 1.0 : 0.45;
    }
}

- (void)scrollLogTextViewToTop {
    self.logTextView.contentOffset = CGPointZero;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.logTextView setContentOffset:CGPointZero animated:NO];
    });
}

- (void)handleClear {
    if (![self itemEnabled] || !self.item.actionHandler) {
        return;
    }
    self.item.actionHandler();
    [self reloadTableView];
}

@end

@interface ExampleSettingsNumberCell : ExampleSettingsTitledCell
@property (nonatomic, strong) UIButton *decrementButton;
@property (nonatomic, strong) UILabel *valueLabel;
@property (nonatomic, strong) UIButton *incrementButton;
@end

@implementation ExampleSettingsNumberCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _decrementButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_decrementButton setTitle:@"-" forState:UIControlStateNormal];
        _decrementButton.titleLabel.font = [UIFont systemFontOfSize:18.0 weight:UIFontWeightSemibold];
        _decrementButton.layer.cornerRadius = 6.0;
        _decrementButton.layer.borderWidth = 1.0;
        _decrementButton.layer.borderColor = [UIColor colorWithWhite:0.85 alpha:1.0].CGColor;
        [_decrementButton addTarget:self action:@selector(handleDecrement) forControlEvents:UIControlEventTouchUpInside];

        _valueLabel = [[UILabel alloc] init];
        _valueLabel.font = [UIFont monospacedDigitSystemFontOfSize:12.0 weight:UIFontWeightMedium];
        _valueLabel.textAlignment = NSTextAlignmentCenter;
        _valueLabel.textColor = UIColor.secondaryLabelColor;
        _valueLabel.adjustsFontSizeToFitWidth = YES;
        _valueLabel.minimumScaleFactor = 0.8;

        _incrementButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_incrementButton setTitle:@"+" forState:UIControlStateNormal];
        _incrementButton.titleLabel.font = [UIFont systemFontOfSize:18.0 weight:UIFontWeightSemibold];
        _incrementButton.layer.cornerRadius = 6.0;
        _incrementButton.layer.borderWidth = 1.0;
        _incrementButton.layer.borderColor = [UIColor colorWithWhite:0.85 alpha:1.0].CGColor;
        [_incrementButton addTarget:self action:@selector(handleIncrement) forControlEvents:UIControlEventTouchUpInside];

        UIStackView *stackView = [[UIStackView alloc] initWithArrangedSubviews:@[_decrementButton, _valueLabel, _incrementButton]];
        stackView.axis = UILayoutConstraintAxisHorizontal;
        stackView.alignment = UIStackViewAlignmentCenter;
        stackView.spacing = 4.0;
        stackView.distribution = UIStackViewDistributionFill;
        [self.controlContainer addSubview:stackView];

        [stackView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.controlContainer);
        }];
        [_decrementButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(CGSizeMake(28.0, 28.0));
        }];
        [_incrementButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(CGSizeMake(28.0, 28.0));
        }];
        [_valueLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.mas_greaterThanOrEqualTo(54.0);
        }];
    }
    return self;
}

- (void)configureWithItem:(ExampleSettingsItem *)item {
    [super configureWithItem:item];
    [self refreshValue];
}

- (void)handleDecrement {
    [self adjustByDelta:-self.item.stepValue];
}

- (void)handleIncrement {
    [self adjustByDelta:self.item.stepValue];
}

- (void)adjustByDelta:(double)delta {
    if (!self.item.numberGetter || !self.item.numberSetter) {
        return;
    }
    double value = self.item.numberGetter() + delta;
    value = fmin(fmax(value, self.item.minimumValue), self.item.maximumValue);
    self.item.numberSetter(value);
    [self refreshValue];
}

- (void)refreshValue {
    if (!self.item.numberGetter) {
        return;
    }
    double value = self.item.numberGetter();
    self.valueLabel.text = self.item.numberFormatter ? self.item.numberFormatter(value) : [NSString stringWithFormat:@"%.2f", value];
    self.decrementButton.enabled = value > self.item.minimumValue + DBL_EPSILON;
    self.incrementButton.enabled = value < self.item.maximumValue - DBL_EPSILON;
}

@end

@interface ExampleSettingsSliderCell : ExampleSettingsTitledCell
@property (nonatomic, strong) UISlider *sliderControl;
@property (nonatomic, strong) UILabel *valueLabel;
@property (nonatomic, strong) UILabel *minimumLabel;
@property (nonatomic, strong) UILabel *maximumLabel;
@end

@implementation ExampleSettingsSliderCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.titleLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightSemibold];
        self.titleLabel.textColor = UIColor.labelColor;
        self.titleLabel.numberOfLines = 1;
        self.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        [self.titleLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultLow
                                                         forAxis:UILayoutConstraintAxisHorizontal];
        [self.titleLabel setContentHuggingPriority:UILayoutPriorityDefaultLow
                                           forAxis:UILayoutConstraintAxisHorizontal];

        [self.titleTrailingConstraint deactivate];

        _valueLabel = [[UILabel alloc] init];
        _valueLabel.font = [UIFont monospacedDigitSystemFontOfSize:12.0 weight:UIFontWeightSemibold];
        _valueLabel.textColor = UIColor.secondaryLabelColor;
        _valueLabel.textAlignment = NSTextAlignmentRight;
        [_valueLabel setContentCompressionResistancePriority:UILayoutPriorityRequired
                                                     forAxis:UILayoutConstraintAxisHorizontal];
        [_valueLabel setContentHuggingPriority:UILayoutPriorityRequired
                                       forAxis:UILayoutConstraintAxisHorizontal];
        [self.cardContentView addSubview:_valueLabel];

        _sliderControl = [[UISlider alloc] init];
        [_sliderControl addTarget:self action:@selector(handleSliderChanged:) forControlEvents:UIControlEventValueChanged];
        [self.controlContainer addSubview:_sliderControl];

        _minimumLabel = [[UILabel alloc] init];
        _minimumLabel.font = [UIFont monospacedDigitSystemFontOfSize:10.0 weight:UIFontWeightRegular];
        _minimumLabel.textColor = UIColor.secondaryLabelColor;
        [self.controlContainer addSubview:_minimumLabel];

        _maximumLabel = [[UILabel alloc] init];
        _maximumLabel.font = [UIFont monospacedDigitSystemFontOfSize:10.0 weight:UIFontWeightRegular];
        _maximumLabel.textColor = UIColor.secondaryLabelColor;
        _maximumLabel.textAlignment = NSTextAlignmentRight;
        [self.controlContainer addSubview:_maximumLabel];

        [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.trailing.lessThanOrEqualTo(_valueLabel.mas_leading).offset(-8.0);
        }];
        [_valueLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.trailing.equalTo(self.cardContentView);
            make.centerY.equalTo(self.titleLabel);
            make.leading.greaterThanOrEqualTo(self.cardContentView);
        }];
        [_sliderControl mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.trailing.top.equalTo(self.controlContainer);
        }];
        [_minimumLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self.controlContainer);
            make.top.equalTo(_sliderControl.mas_bottom).offset(2.0);
            make.bottom.equalTo(self.controlContainer);
        }];
        [_maximumLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.trailing.equalTo(self.controlContainer);
            make.top.equalTo(_sliderControl.mas_bottom).offset(2.0);
            make.bottom.equalTo(self.controlContainer);
        }];
    }
    return self;
}

- (void)configureWithItem:(ExampleSettingsItem *)item {
    [super configureWithItem:item];
    self.sliderControl.accessibilityIdentifier = item.accessibilityIdentifier;
    self.accessibilityIdentifier = item.accessibilityIdentifier;
    self.sliderControl.minimumValue = (float)item.minimumValue;
    self.sliderControl.maximumValue = (float)item.maximumValue;
    [self refreshValue];
}

- (void)handleSliderChanged:(UISlider *)sender {
    if (!self.item.numberSetter) {
        return;
    }
    double value = sender.value;
    if (self.item.stepValue > DBL_EPSILON) {
        value = round(value / self.item.stepValue) * self.item.stepValue;
    }
    value = fmin(fmax(value, self.item.minimumValue), self.item.maximumValue);
    self.item.numberSetter(value);
    [self refreshValue];
}

- (void)refreshValue {
    if (!self.item.numberGetter) {
        return;
    }
    double value = self.item.numberGetter();
    NSString *formattedValue = self.item.numberFormatter ? self.item.numberFormatter(value) : [NSString stringWithFormat:@"%.2f", value];
    self.titleLabel.text = self.item.title;
    self.valueLabel.text = formattedValue;
    self.sliderControl.value = (float)value;
    self.minimumLabel.text = [self formatRawValue:self.item.minimumValue];
    self.maximumLabel.text = [self formatRawValue:self.item.maximumValue];
}

- (NSString *)formatRawValue:(double)value {
    if (fabs(value - round(value)) < DBL_EPSILON) {
        return [NSString stringWithFormat:@"%.0f", value];
    }
    return [NSString stringWithFormat:@"%.2f", value];
}

@end

@interface ExampleSettingsSegmentedCell : ExampleSettingsTitledCell
@property (nonatomic, strong) UISegmentedControl *segmentedControl;
@end

@implementation ExampleSettingsSegmentedCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _segmentedControl = [[UISegmentedControl alloc] initWithItems:@[]];
        _segmentedControl.selectedSegmentTintColor = [UIColor colorWithRed:0.16 green:0.53 blue:0.98 alpha:1.0];
        [_segmentedControl setTitleTextAttributes:@{
            NSFontAttributeName: [UIFont systemFontOfSize:11.0 weight:UIFontWeightSemibold],
            NSForegroundColorAttributeName: UIColor.secondaryLabelColor
        } forState:UIControlStateNormal];
        [_segmentedControl setTitleTextAttributes:@{
            NSFontAttributeName: [UIFont systemFontOfSize:11.0 weight:UIFontWeightSemibold],
            NSForegroundColorAttributeName: UIColor.whiteColor
        } forState:UIControlStateSelected];
        [_segmentedControl addTarget:self action:@selector(handleSegmentChanged:) forControlEvents:UIControlEventValueChanged];
        [self.controlContainer addSubview:_segmentedControl];

        [_segmentedControl mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.controlContainer);
            make.height.mas_equalTo(30.0);
        }];
    }
    return self;
}

- (void)configureWithItem:(ExampleSettingsItem *)item {
    [super configureWithItem:item];
    self.segmentedControl.accessibilityIdentifier = item.accessibilityIdentifier;
    self.accessibilityIdentifier = item.accessibilityIdentifier;
    [self.segmentedControl removeAllSegments];
    [item.segments enumerateObjectsUsingBlock:^(NSString * _Nonnull segment, NSUInteger idx, BOOL * _Nonnull stop) {
        (void)stop;
        [self.segmentedControl insertSegmentWithTitle:segment atIndex:idx animated:NO];
    }];
    NSInteger selectedIndex = item.segmentGetter ? item.segmentGetter() : 0;
    self.segmentedControl.selectedSegmentIndex = MAX(0, MIN(selectedIndex, self.segmentedControl.numberOfSegments - 1));
}

- (void)handleSegmentChanged:(UISegmentedControl *)sender {
    if (self.item.segmentSetter) {
        self.item.segmentSetter(sender.selectedSegmentIndex);
    }
    [self reloadTableView];
}

@end

@interface ExampleSettingsListCell : ExampleSettingsTitledCell
@property (nonatomic, strong) UIView *fieldView;
@property (nonatomic, strong) UILabel *valueLabel;
@property (nonatomic, strong) UIImageView *chevronImageView;
@property (nonatomic, strong) UIButton *tapButton;
@end

@implementation ExampleSettingsListCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _fieldView = [[UIView alloc] init];
        _fieldView.backgroundColor = UIColor.clearColor;
        _fieldView.layer.cornerRadius = 8.0;
        _fieldView.layer.borderWidth = 1.0;
        _fieldView.layer.borderColor = [UIColor colorWithRed:0.82 green:0.86 blue:0.93 alpha:1.0].CGColor;
        [self.controlContainer addSubview:_fieldView];

        _valueLabel = [[UILabel alloc] init];
        _valueLabel.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightRegular];
        _valueLabel.textColor = UIColor.labelColor;
        _valueLabel.adjustsFontSizeToFitWidth = YES;
        _valueLabel.minimumScaleFactor = 0.85;
        _valueLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        [_fieldView addSubview:_valueLabel];

        _chevronImageView = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"chevron.down"]];
        _chevronImageView.tintColor = UIColor.secondaryLabelColor;
        [_fieldView addSubview:_chevronImageView];

        _tapButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_tapButton addTarget:self action:@selector(handleTap) forControlEvents:UIControlEventTouchUpInside];
        [_fieldView addSubview:_tapButton];

        [_fieldView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.controlContainer);
            make.height.mas_equalTo(36.0);
        }];
        [_valueLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(_fieldView).offset(8.0);
            make.trailing.lessThanOrEqualTo(_chevronImageView.mas_leading).offset(-6.0);
            make.centerY.equalTo(_fieldView);
        }];
        [_chevronImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.trailing.equalTo(_fieldView).offset(-8.0);
            make.centerY.equalTo(_fieldView);
        }];
        [_tapButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(_fieldView);
        }];
    }
    return self;
}

- (void)configureWithItem:(ExampleSettingsItem *)item {
    [super configureWithItem:item];
    self.tapButton.accessibilityIdentifier = item.accessibilityIdentifier;
    self.accessibilityIdentifier = item.accessibilityIdentifier;
    NSArray<NSString *> *options = item.segments ?: @[];
    NSInteger selectedIndex = item.segmentGetter ? item.segmentGetter() : 0;
    self.valueLabel.text = (selectedIndex >= 0 && selectedIndex < options.count) ? options[selectedIndex] : @"选择";
}

- (void)handleTap {
    if (![self itemEnabled]) {
        return;
    }
    NSArray<NSString *> *options = self.item.segments ?: @[];
    if (options.count == 0) {
        return;
    }
    ExampleSettingsSheetView *sheetView = [self owningSheetView];
    if (!sheetView) {
        return;
    }
    CGRect anchorRect = [self.fieldView convertRect:self.fieldView.bounds toView:sheetView];
    __weak typeof(self) weakSelf = self;
    ExampleSettingsListSelectionHandler handler = ^(NSInteger index) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }
        if (self.item.segmentSetter) {
            self.item.segmentSetter(index);
        }
        [self reloadTableView];
    };
    ExampleSettingsListView *listView = nil;
    if (self.item.listGroups.count > 0) {
        listView = [[ExampleSettingsListView alloc] initWithGroups:self.item.listGroups
                                                     selectedIndex:(self.item.segmentGetter ? self.item.segmentGetter() : 0)
                                                    containerBounds:sheetView.bounds
                                                         anchorRect:anchorRect
                                                           handler:handler];
    } else {
        listView = [[ExampleSettingsListView alloc] initWithOptions:options
                                                    optionHexValues:nil
                                                      selectedIndex:(self.item.segmentGetter ? self.item.segmentGetter() : 0)
                                                     containerBounds:sheetView.bounds
                                                          anchorRect:anchorRect
                                                            handler:handler];
    }

    [sheetView addSubview:listView];
    [listView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(sheetView);
    }];
}

@end

@interface ExampleSettingsColorInputCell : ExampleSettingsTitledCell <UITextFieldDelegate>
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) UIButton *dropdownButton;
@property (nonatomic, strong) UIImageView *chevronImageView;
@end

@implementation ExampleSettingsColorInputCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _containerView = [[UIView alloc] init];
        _containerView.layer.cornerRadius = 8.0;
        _containerView.layer.borderWidth = 1.0;
        _containerView.layer.borderColor = [UIColor colorWithRed:0.82 green:0.86 blue:0.93 alpha:1.0].CGColor;
        [self.controlContainer addSubview:_containerView];

        _textField = [[UITextField alloc] init];
        _textField.borderStyle = UITextBorderStyleNone;
        _textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        _textField.font = [UIFont monospacedDigitSystemFontOfSize:13.0 weight:UIFontWeightRegular];
        _textField.textColor = UIColor.labelColor;
        _textField.delegate = self;
        [_textField addTarget:self action:@selector(handleTextChanged:) forControlEvents:UIControlEventEditingChanged];
        [_containerView addSubview:_textField];

        _dropdownButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_dropdownButton addTarget:self action:@selector(handleDropdownTap) forControlEvents:UIControlEventTouchUpInside];
        [_containerView addSubview:_dropdownButton];

        _chevronImageView = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"chevron.down"]];
        _chevronImageView.tintColor = UIColor.secondaryLabelColor;
        [_dropdownButton addSubview:_chevronImageView];

        [_containerView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.controlContainer);
            make.height.mas_equalTo(36.0);
        }];
        [_textField mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(_containerView).offset(10.0);
            make.top.bottom.equalTo(_containerView);
            make.width.mas_greaterThanOrEqualTo(120.0);
        }];
        [_dropdownButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(_textField.mas_trailing).offset(8.0);
            make.trailing.top.bottom.equalTo(_containerView);
            make.width.mas_equalTo(36.0);
        }];
        [_chevronImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(_dropdownButton);
        }];
    }
    return self;
}

- (void)configureWithItem:(ExampleSettingsItem *)item {
    [super configureWithItem:item];
    self.textField.placeholder = item.placeholder;
    self.textField.keyboardType = item.keyboardType;
    self.textField.text = item.textGetter ? item.textGetter() : @"";
}

- (void)handleTextChanged:(UITextField *)sender {
    if (self.item.textSetter) {
        self.item.textSetter(sender.text ?: @"");
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)handleDropdownTap {
    if (![self itemEnabled]) {
        return;
    }
    NSArray<NSString *> *options = self.item.segments ?: @[];
    if (options.count == 0) {
        return;
    }
    ExampleSettingsSheetView *sheetView = [self owningSheetView];
    if (!sheetView) {
        return;
    }
    CGRect anchorRect = [self.containerView convertRect:self.containerView.bounds toView:sheetView];
    __weak typeof(self) weakSelf = self;
    ExampleSettingsListView *listView =
        [[ExampleSettingsListView alloc] initWithOptions:options
                                         optionHexValues:self.item.optionHexValues
                                           selectedIndex:(self.item.segmentGetter ? self.item.segmentGetter() : 0)
                                          containerBounds:sheetView.bounds
                                               anchorRect:anchorRect
                                                 handler:^(NSInteger index) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }
        if (self.item.segmentSetter) {
            self.item.segmentSetter(index);
        }
        [self reloadTableView];
    }];
    [sheetView addSubview:listView];
    [listView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(sheetView);
    }];
}

@end

@interface ExampleSettingsTextCell : ExampleSettingsTitledCell <UITextFieldDelegate>
@property (nonatomic, strong) UITextField *textField;
@end

@implementation ExampleSettingsTextCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _textField = [[UITextField alloc] init];
        _textField.borderStyle = UITextBorderStyleRoundedRect;
        _textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        _textField.font = [UIFont monospacedDigitSystemFontOfSize:13.0 weight:UIFontWeightRegular];
        _textField.textAlignment = NSTextAlignmentLeft;
        _textField.delegate = self;
        [_textField addTarget:self action:@selector(handleTextChanged:) forControlEvents:UIControlEventEditingChanged];
        [_textField addTarget:self action:@selector(handleTextChanged:) forControlEvents:UIControlEventEditingDidEnd];
        [self.controlContainer addSubview:_textField];

        [_textField mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.controlContainer);
            make.height.mas_equalTo(36.0);
        }];
    }
    return self;
}

- (void)configureWithItem:(ExampleSettingsItem *)item {
    [super configureWithItem:item];
    self.textField.keyboardType = item.keyboardType;
    self.textField.placeholder = item.placeholder;
    self.textField.text = item.textGetter ? item.textGetter() : @"";
    self.textField.accessibilityIdentifier = item.accessibilityIdentifier;
}

- (void)handleTextChanged:(UITextField *)sender {
    if (self.item.textSetter) {
        self.item.textSetter(sender.text ?: @"");
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (self.item.textSetter) {
        self.item.textSetter(textField.text ?: @"");
    }
    [self reloadTableView];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    (void)textField;
    [[self owningSheetView] scrollActiveInputIntoVisibleAreaAnimated:YES];
}

@end

@interface ExampleSettingsMultilineTextCell : ExampleSettingsTitledCell <UITextViewDelegate>
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) UILabel *placeholderLabel;
@end

@implementation ExampleSettingsMultilineTextCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _containerView = [[UIView alloc] init];
        _containerView.backgroundColor = UIColor.clearColor;
        _containerView.layer.cornerRadius = 8.0;
        _containerView.layer.borderWidth = 1.0;
        _containerView.layer.borderColor = [UIColor colorWithWhite:0.86 alpha:1.0].CGColor;
        [self.controlContainer addSubview:_containerView];

        _textView = [[UITextView alloc] init];
        _textView.backgroundColor = UIColor.clearColor;
        _textView.font = [UIFont monospacedSystemFontOfSize:13.0 weight:UIFontWeightRegular];
        _textView.textColor = UIColor.labelColor;
        _textView.textContainerInset = UIEdgeInsetsMake(6.0, 4.0, 6.0, 4.0);
        _textView.textContainer.lineFragmentPadding = 0.0;
        _textView.delegate = self;
        [_containerView addSubview:_textView];

        _placeholderLabel = [[UILabel alloc] init];
        _placeholderLabel.font = _textView.font;
        _placeholderLabel.textColor = UIColor.placeholderTextColor;
        _placeholderLabel.numberOfLines = 0;
        [_containerView addSubview:_placeholderLabel];

        [_containerView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.controlContainer);
        }];
        [_textView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(_containerView);
        }];
        [_placeholderLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(_containerView).offset(4.0);
            make.trailing.equalTo(_containerView).offset(-4.0);
            make.top.equalTo(_containerView).offset(6.0);
        }];
    }
    return self;
}

- (void)configureWithItem:(ExampleSettingsItem *)item {
    [super configureWithItem:item];
    self.textView.text = item.textGetter ? item.textGetter() : @"";
    self.placeholderLabel.text = item.placeholder;
    self.placeholderLabel.hidden = self.textView.text.length > 0;
    self.textView.editable = item.textSetter != nil;
    self.textView.selectable = item.textSetter != nil;
}

- (void)textViewDidChange:(UITextView *)textView {
    self.placeholderLabel.hidden = textView.text.length > 0;
    if (self.item.textSetter) {
        self.item.textSetter(textView.text ?: @"");
    }
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    (void)textView;
    [[self owningSheetView] scrollActiveInputIntoVisibleAreaAnimated:YES];
}

@end

@interface ExampleSettingsActionCell : ExampleSettingsBaseCell
@property (nonatomic, strong) UIButton *actionButton;
@end

@implementation ExampleSettingsActionCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.cardView.backgroundColor = UIColor.clearColor;
        _actionButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _actionButton.titleLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightSemibold];
        [_actionButton setTitleColor:UIColor.systemBlueColor forState:UIControlStateNormal];
        _actionButton.backgroundColor = UIColor.clearColor;
        _actionButton.layer.cornerRadius = 6.0;
        [_actionButton addTarget:self action:@selector(handleAction) forControlEvents:UIControlEventTouchUpInside];
        [self.cardContentView addSubview:_actionButton];

        [_actionButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.trailing.equalTo(self.cardContentView);
            make.top.equalTo(self.cardContentView).offset(2.0);
            make.bottom.equalTo(self.cardContentView).offset(-2.0);
        }];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.actionButton setTitle:nil forState:UIControlStateNormal];
    [self.actionButton setTitle:nil forState:UIControlStateHighlighted];
    [self.actionButton setTitle:nil forState:UIControlStateSelected];
    [self.actionButton setTitle:nil forState:UIControlStateDisabled];
}

- (void)configureWithItem:(ExampleSettingsItem *)item {
    [super configureWithItem:item];
    NSString *title = item.title ?: @"";
    BOOL isClearAction = [title containsString:@"清除"]
        || [title localizedCaseInsensitiveContainsString:@"clear"];
    UIColor *titleColor = isClearAction ? UIColor.systemRedColor : UIColor.systemBlueColor;
    [self.actionButton setTitleColor:titleColor forState:UIControlStateNormal];
    [self.actionButton setTitleColor:[titleColor colorWithAlphaComponent:0.45] forState:UIControlStateHighlighted];
    [self.actionButton setTitleColor:[titleColor colorWithAlphaComponent:0.45] forState:UIControlStateDisabled];
    [self.actionButton setTitle:item.title forState:UIControlStateNormal];
    [self.actionButton setTitle:item.title forState:UIControlStateHighlighted];
    [self.actionButton setTitle:item.title forState:UIControlStateSelected];
    [self.actionButton setTitle:item.title forState:UIControlStateDisabled];
    self.actionButton.accessibilityIdentifier = item.accessibilityIdentifier;
    self.actionButton.enabled = [self itemEnabled];
}

- (void)handleAction {
    [self endEditing:YES];
    if (self.item.actionHandler) {
        self.item.actionHandler();
    }
    [self reloadTableView];
}

@end

@interface ExampleSettingsSheetView () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, copy) NSString *sheetTitle;
@property (nonatomic, copy) NSArray<ExampleSettingsSection *> *sections;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) UIView *separatorView;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic) UIEdgeInsets tableBaseContentInset;
- (NSArray<ExampleSettingsItem *> *)visibleItemsForSection:(NSInteger)section;
- (ExampleSettingsItem *)visibleItemAtIndexPath:(NSIndexPath *)indexPath;
- (NSIndexPath *)indexPathForVisibleItem:(ExampleSettingsItem *)targetItem;
- (void)refreshCellAtIndexPath:(NSIndexPath *)indexPath;
@end

@implementation ExampleSettingsSheetView

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (instancetype)initWithTitle:(NSString *)title sections:(NSArray<ExampleSettingsSection *> *)sections {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _sheetTitle = [title copy];
        _sections = [sections copy];
        [self configureViews];
    }
    return self;
}

- (instancetype)initWithTitle:(NSString *)title items:(NSArray<ExampleSettingsItem *> *)items {
    ExampleSettingsSection *section = [ExampleSettingsSection sectionWithTitle:@"" items:items];
    return [self initWithTitle:title sections:@[section]];
}

- (void)reloadData {
    [self.tableView reloadData];
}

- (void)refreshItem:(ExampleSettingsItem *)item {
    NSIndexPath *indexPath = [self indexPathForVisibleItem:item];
    if (!indexPath) {
        return;
    }
    [self refreshCellAtIndexPath:indexPath];
}

- (void)refreshVisibleItems {
    for (NSIndexPath *indexPath in self.tableView.indexPathsForVisibleRows) {
        [self refreshCellAtIndexPath:indexPath];
    }
}

- (void)configureViews {
    self.backgroundColor = UIColor.secondarySystemGroupedBackgroundColor;
    self.layer.cornerRadius = 8.0;
    self.layer.shadowColor = UIColor.blackColor.CGColor;
    self.layer.shadowOpacity = 0.16;
    self.layer.shadowRadius = 18.0;
    self.layer.shadowOffset = CGSizeMake(-10.0, 0.0);

    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = self.sheetTitle;
    self.titleLabel.font = [UIFont systemFontOfSize:17.0 weight:UIFontWeightSemibold];
    self.titleLabel.textColor = UIColor.labelColor;
    self.titleLabel.numberOfLines = 2;
    [self addSubview:self.titleLabel];

    self.closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    UIImage *closeImage = [UIImage systemImageNamed:@"xmark"];
    if (closeImage) {
        [self.closeButton setImage:closeImage forState:UIControlStateNormal];
    } else {
        [self.closeButton setTitle:@"关闭" forState:UIControlStateNormal];
    }
    self.closeButton.tintColor = UIColor.labelColor;
    self.closeButton.accessibilityIdentifier = @"example_settings_sheet_close_button";
    [self.closeButton addTarget:self action:@selector(handleDismiss) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.closeButton];

    self.separatorView = [[UIView alloc] init];
    self.separatorView.backgroundColor = [UIColor colorWithWhite:0.88 alpha:1.0];
    [self addSubview:self.separatorView];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.backgroundColor = UIColor.clearColor;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 90.0;
    self.tableView.contentInset = UIEdgeInsetsMake(4.0, 0.0, 12.0, 0.0);
    self.tableBaseContentInset = self.tableView.contentInset;
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.alwaysBounceVertical = YES;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    self.tableView.accessibilityIdentifier = MTCExampleTestAccessibilitySettingsSheetTable;
    if (@available(iOS 15.0, *)) {
        self.tableView.sectionHeaderTopPadding = 0.0;
    }
    [self.tableView registerClass:ExampleSettingsBoolCell.class forCellReuseIdentifier:@"ExampleSettingsBoolCell"];
    [self.tableView registerClass:ExampleSettingsCheckboxCell.class forCellReuseIdentifier:@"ExampleSettingsCheckboxCell"];
    [self.tableView registerClass:ExampleSettingsRadioCell.class forCellReuseIdentifier:@"ExampleSettingsRadioCell"];
    [self.tableView registerClass:ExampleSettingsNumberCell.class forCellReuseIdentifier:@"ExampleSettingsNumberCell"];
    [self.tableView registerClass:ExampleSettingsSliderCell.class forCellReuseIdentifier:@"ExampleSettingsSliderCell"];
    [self.tableView registerClass:ExampleSettingsSegmentedCell.class forCellReuseIdentifier:@"ExampleSettingsSegmentedCell"];
    [self.tableView registerClass:ExampleSettingsListCell.class forCellReuseIdentifier:@"ExampleSettingsListCell"];
    [self.tableView registerClass:ExampleSettingsColorInputCell.class forCellReuseIdentifier:@"ExampleSettingsColorInputCell"];
    [self.tableView registerClass:ExampleSettingsTextCell.class forCellReuseIdentifier:@"ExampleSettingsTextCell"];
    [self.tableView registerClass:ExampleSettingsMultilineTextCell.class forCellReuseIdentifier:@"ExampleSettingsMultilineTextCell"];
    [self.tableView registerClass:ExampleSettingsInfoCell.class forCellReuseIdentifier:@"ExampleSettingsInfoCell"];
    [self.tableView registerClass:ExampleSettingsImagePreviewCell.class forCellReuseIdentifier:@"ExampleSettingsImagePreviewCell"];
    [self.tableView registerClass:ExampleSettingsLogCell.class forCellReuseIdentifier:@"ExampleSettingsLogCell"];
    [self addSubview:self.tableView];

    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self).offset(12.0);
        make.top.equalTo(self.mas_safeAreaLayoutGuideTop).offset(10.0);
        make.trailing.lessThanOrEqualTo(self.closeButton.mas_leading).offset(-8.0);
    }];
    [self.closeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(self).offset(-12.0);
        make.centerY.equalTo(self.titleLabel);
        make.size.mas_equalTo(CGSizeMake(30.0, 30.0));
    }];
    [self.separatorView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(self);
        make.top.equalTo(self.titleLabel.mas_bottom).offset(8.0);
        make.height.mas_equalTo(1.0 / self.traitCollection.displayScale);
    }];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self).offset(8.0);
        make.trailing.equalTo(self).offset(-8.0);
        make.top.equalTo(self.separatorView.mas_bottom);
        make.bottom.equalTo(self);
    }];

    UITapGestureRecognizer *tapToDismiss = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSheetTap:)];
    tapToDismiss.cancelsTouchesInView = NO;
    [self addGestureRecognizer:tapToDismiss];

    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(handleKeyboardWillChangeFrame:)
                                               name:UIKeyboardWillChangeFrameNotification
                                             object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(handleKeyboardWillHide:)
                                               name:UIKeyboardWillHideNotification
                                             object:nil];
}

- (void)handleSheetTap:(UITapGestureRecognizer *)gesture {
    [self endEditing:YES];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:8.0].CGPath;
}

- (void)showInView:(UIView *)superview animated:(BOOL)animated {
    if (!superview) {
        return;
    }

    for (UIView *subview in [superview.subviews copy]) {
        if ([subview isKindOfClass:ExampleSettingsSheetView.class]) {
            [subview removeFromSuperview];
        }
    }

    [superview addSubview:self];
    [self mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(superview.mas_centerX);
        make.trailing.top.bottom.equalTo(superview);
    }];
    [superview layoutIfNeeded];

    CGFloat translationX = CGRectGetWidth(superview.bounds) * 0.5;
    if (!animated) {
        self.transform = CGAffineTransformIdentity;
        return;
    }

    self.transform = CGAffineTransformMakeTranslation(translationX, 0.0);
    [UIView animateWithDuration:0.4
                          delay:0.0
         usingSpringWithDamping:0.92
          initialSpringVelocity:0.8
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
        self.transform = CGAffineTransformIdentity;
    } completion:nil];
}

- (void)dismissAnimated:(BOOL)animated {
    if (!self.superview) {
        return;
    }

    if (!animated) {
        [self removeFromSuperview];
        return;
    }

    CGFloat translationX = CGRectGetWidth(self.superview.bounds) * 0.5;
    [UIView animateWithDuration:0.2
                     animations:^{
        self.transform = CGAffineTransformMakeTranslation(translationX, 0.0);
    } completion:^(BOOL finished) {
        (void)finished;
        [self removeFromSuperview];
    }];
}

- (void)handleDismiss {
    [self dismissAnimated:YES];
}

- (void)handleKeyboardWillChangeFrame:(NSNotification *)notification {
    CGRect keyboardFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    [self updateKeyboardInsetWithKeyboardFrame:keyboardFrame notification:notification];
}

- (void)handleKeyboardWillHide:(NSNotification *)notification {
    [self updateKeyboardInsetWithOverlapHeight:0.0 notification:notification];
}

- (void)updateKeyboardInsetWithKeyboardFrame:(CGRect)keyboardFrame notification:(NSNotification *)notification {
    UIWindow *window = self.window;
    CGRect keyboardFrameInWindow = window ? [window convertRect:keyboardFrame fromWindow:nil] : keyboardFrame;
    CGRect keyboardFrameInSelf = window ? [self convertRect:keyboardFrameInWindow fromView:window] : [self convertRect:keyboardFrame fromView:nil];
    CGRect intersection = CGRectIntersection(self.bounds, keyboardFrameInSelf);
    CGFloat overlapHeight = CGRectIsNull(intersection) ? 0.0 : CGRectGetHeight(intersection);
    [self updateKeyboardInsetWithOverlapHeight:overlapHeight notification:notification];
}

- (void)updateKeyboardInsetWithOverlapHeight:(CGFloat)overlapHeight notification:(NSNotification *)notification {
    NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve curve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    UIViewAnimationOptions options = (UIViewAnimationOptions)(curve << 16);

    UIEdgeInsets contentInset = self.tableBaseContentInset;
    contentInset.bottom += overlapHeight;
    void (^updates)(void) = ^{
        self.tableView.contentInset = contentInset;
        self.tableView.scrollIndicatorInsets = contentInset;
        [self scrollActiveInputIntoVisibleAreaAnimated:NO];
    };

    if (duration > 0.0) {
        [UIView animateWithDuration:duration
                              delay:0.0
                            options:options
                         animations:updates
                         completion:nil];
    } else {
        updates();
    }
}

- (void)scrollActiveInputIntoVisibleAreaAnimated:(BOOL)animated {
    UIView *activeView = [self firstResponderInView:self];
    if (!activeView) {
        return;
    }

    [self layoutIfNeeded];
    CGRect inputRect = [activeView convertRect:activeView.bounds toView:self.tableView];
    inputRect = CGRectInset(inputRect, 0.0, -12.0);
    [self.tableView scrollRectToVisible:inputRect animated:animated];
}

- (UIView *)firstResponderInView:(UIView *)view {
    if (view.isFirstResponder) {
        return view;
    }
    for (UIView *subview in view.subviews) {
        UIView *firstResponder = [self firstResponderInView:subview];
        if (firstResponder) {
            return firstResponder;
        }
    }
    return nil;
}

- (NSArray<ExampleSettingsSectionDisplayEntry *> *)visibleSectionEntries {
    NSMutableArray<ExampleSettingsSectionDisplayEntry *> *entries = [NSMutableArray array];
    for (ExampleSettingsSection *section in self.sections) {
        [self appendVisibleSection:section indentationLevel:0 entries:entries];
    }
    return [entries copy];
}

- (void)appendVisibleSection:(ExampleSettingsSection *)section
            indentationLevel:(NSInteger)indentationLevel
                     entries:(NSMutableArray<ExampleSettingsSectionDisplayEntry *> *)entries {
    ExampleSettingsSectionDisplayEntry *entry = [[ExampleSettingsSectionDisplayEntry alloc] init];
    entry.section = section;
    entry.indentationLevel = indentationLevel;
    [entries addObject:entry];

    if (section.collapsible && section.collapsed) {
        return;
    }

    for (ExampleSettingsSection *childSection in section.childSections) {
        [self appendVisibleSection:childSection
                  indentationLevel:indentationLevel + 1
                           entries:entries];
    }
}

- (ExampleSettingsSectionDisplayEntry *)visibleSectionEntryAtIndex:(NSInteger)sectionIndex {
    return [self visibleSectionEntries][sectionIndex];
}

- (NSArray<ExampleSettingsItem *> *)visibleItemsForSection:(NSInteger)section {
    ExampleSettingsSection *settingsSection = [self visibleSectionEntryAtIndex:section].section;
    if (settingsSection.collapsible && settingsSection.collapsed) {
        return @[];
    }

    NSMutableArray<ExampleSettingsItem *> *items = [NSMutableArray array];
    for (ExampleSettingsItem *item in settingsSection.items) {
        if (!item.visibleGetter || item.visibleGetter()) {
            [items addObject:item];
        }
    }
    return [items copy];
}

- (ExampleSettingsItem *)visibleItemAtIndexPath:(NSIndexPath *)indexPath {
    return [self visibleItemsForSection:indexPath.section][indexPath.row];
}

- (NSIndexPath *)indexPathForVisibleItem:(ExampleSettingsItem *)targetItem {
    if (!targetItem) {
        return nil;
    }
    NSInteger sectionCount = [self numberOfSectionsInTableView:self.tableView];
    for (NSInteger section = 0; section < sectionCount; section++) {
        NSArray<ExampleSettingsItem *> *items = [self visibleItemsForSection:section];
        for (NSInteger row = 0; row < items.count; row++) {
            if (items[row] == targetItem) {
                return [NSIndexPath indexPathForRow:row inSection:section];
            }
        }
    }
    return nil;
}

- (void)refreshCellAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    if (![cell isKindOfClass:ExampleSettingsBaseCell.class]) {
        return;
    }
    ExampleSettingsItem *item = [self visibleItemAtIndexPath:indexPath];
    ExampleSettingsBaseCell *settingsCell = (ExampleSettingsBaseCell *)cell;
    [settingsCell configureWithItem:item];

    NSInteger rowCount = [self.tableView numberOfRowsInSection:indexPath.section];
    ExampleSettingsGroupPosition position = ExampleSettingsGroupPositionMiddle;
    if (rowCount == 1) {
        position = ExampleSettingsGroupPositionSingle;
    } else if (indexPath.row == 0) {
        position = ExampleSettingsGroupPositionTop;
    } else if (indexPath.row == rowCount - 1) {
        position = ExampleSettingsGroupPositionBottom;
    }
    [settingsCell applyGroupPosition:position];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    (void)tableView;
    return [self visibleSectionEntries].count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    (void)tableView;
    return [self visibleItemsForSection:section].count;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    (void)tableView;
    ExampleSettingsSectionDisplayEntry *entry = [self visibleSectionEntryAtIndex:section];
    ExampleSettingsSection *settingsSection = entry.section;
    NSString *title = settingsSection.title;
    UIView *headerView = [[UIView alloc] init];
    headerView.backgroundColor = UIColor.clearColor;
    if (title.length == 0) {
        return headerView;
    }

    CGFloat leadingInset = 16.0 * entry.indentationLevel;
    if (settingsSection.collapsible) {
        UIControl *control = [[UIControl alloc] init];
        control.backgroundColor = UIColor.clearColor;
        control.tag = section;
        [control addTarget:self action:@selector(handleSectionHeaderTap:) forControlEvents:UIControlEventTouchUpInside];

        UIView *containerView = [[UIView alloc] init];
        containerView.userInteractionEnabled = NO;
        containerView.backgroundColor = entry.indentationLevel == 0 ? UIColor.systemBackgroundColor : UIColor.tertiarySystemGroupedBackgroundColor;
        containerView.layer.cornerRadius = entry.indentationLevel == 0 ? 10.0 : 7.0;
        containerView.layer.borderWidth = 0.0;
        [control addSubview:containerView];

        UIView *accentView = [[UIView alloc] init];
        accentView.backgroundColor = entry.indentationLevel == 0 ? [UIColor.tertiaryLabelColor colorWithAlphaComponent:0.55] : [UIColor.quaternaryLabelColor colorWithAlphaComponent:0.65];
        accentView.layer.cornerRadius = entry.indentationLevel == 0 ? 2.0 : 1.5;
        [containerView addSubview:accentView];

        UILabel *label = [[UILabel alloc] init];
        label.text = title;
        label.font = [UIFont systemFontOfSize:(entry.indentationLevel == 0 ? 15.0 : 13.5)
                                       weight:(entry.indentationLevel == 0 ? UIFontWeightSemibold : UIFontWeightMedium)];
        label.textColor = entry.indentationLevel == 0 ? UIColor.labelColor : UIColor.secondaryLabelColor;
        [containerView addSubview:label];

        UIView *chevronContainerView = [[UIView alloc] init];
        chevronContainerView.backgroundColor = UIColor.clearColor;
        chevronContainerView.layer.cornerRadius = 13.0;
        [containerView addSubview:chevronContainerView];

        NSString *imageName = settingsSection.collapsed ? @"chevron.right" : @"chevron.down";
        UIImageView *chevronImageView = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:imageName]];
        chevronImageView.tintColor = entry.indentationLevel == 0 ? UIColor.tertiaryLabelColor : UIColor.quaternaryLabelColor;
        [chevronContainerView addSubview:chevronImageView];

        [containerView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(control).offset(leadingInset);
            make.trailing.equalTo(control);
            make.top.equalTo(control).offset(entry.indentationLevel == 0 ? 4.0 : 2.0);
            make.bottom.equalTo(control).offset(entry.indentationLevel == 0 ? -3.0 : -2.0);
        }];
        [accentView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(containerView).offset(entry.indentationLevel == 0 ? 10.0 : 12.0);
            make.centerY.equalTo(containerView);
            make.size.mas_equalTo(CGSizeMake(entry.indentationLevel == 0 ? 3.0 : 2.0,
                                             entry.indentationLevel == 0 ? 18.0 : 14.0));
        }];
        [label mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(accentView.mas_trailing).offset(entry.indentationLevel == 0 ? 10.0 : 8.0);
            make.trailing.lessThanOrEqualTo(chevronContainerView.mas_leading).offset(-8.0);
            make.centerY.equalTo(containerView);
        }];
        [chevronContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.trailing.equalTo(containerView).offset(-10.0);
            make.centerY.equalTo(containerView);
            make.size.mas_equalTo(CGSizeMake(26.0, 26.0));
        }];
        [chevronImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(chevronContainerView);
        }];
        return control;
    }

    UILabel *label = [[UILabel alloc] init];
    label.text = title;
    label.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightSemibold];
    label.textColor = UIColor.secondaryLabelColor;
    [headerView addSubview:label];

    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(headerView).offset(leadingInset);
        make.trailing.equalTo(headerView);
        make.bottom.equalTo(headerView).offset(-4.0);
    }];
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    (void)tableView;
    ExampleSettingsSectionDisplayEntry *entry = [self visibleSectionEntryAtIndex:section];
    ExampleSettingsSection *settingsSection = entry.section;
    if (settingsSection.collapsible) {
        return entry.indentationLevel == 0 ? 46.0 : 36.0;
    }
    return settingsSection.title.length > 0 ? 24.0 : 8.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    (void)tableView;
    return section == [self visibleSectionEntries].count - 1 ? 6.0 : 10.0;
}

- (void)handleSectionHeaderTap:(UIControl *)sender {
    NSInteger sectionIndex = sender.tag;
    NSArray<ExampleSettingsSectionDisplayEntry *> *entries = [self visibleSectionEntries];
    if (sectionIndex < 0 || sectionIndex >= entries.count) {
        return;
    }

    ExampleSettingsSection *section = entries[sectionIndex].section;
    if (!section.collapsible) {
        return;
    }

    section.collapsed = !section.collapsed;
    [self endEditing:YES];
    [UIView transitionWithView:self.tableView
                      duration:0.18
                       options:UIViewAnimationOptionTransitionCrossDissolve | UIViewAnimationOptionAllowUserInteraction
                    animations:^{
        [self.tableView reloadData];
    } completion:nil];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    (void)scrollView;
    [self endEditing:YES];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ExampleSettingsItem *item = [self visibleItemAtIndexPath:indexPath];
    NSString *reuseIdentifier = [self reuseIdentifierForItem:item];
    ExampleSettingsBaseCell *cell = nil;
    if (item.kind == ExampleSettingsItemKindAction) {
        cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
        if (!cell) {
            cell = [[ExampleSettingsActionCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                    reuseIdentifier:reuseIdentifier];
        }
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];
    }
    [cell configureWithItem:item];
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (![cell isKindOfClass:ExampleSettingsBaseCell.class]) {
        return;
    }
    NSInteger rowCount = [tableView numberOfRowsInSection:indexPath.section];
    ExampleSettingsGroupPosition position = ExampleSettingsGroupPositionMiddle;
    if (rowCount == 1) {
        position = ExampleSettingsGroupPositionSingle;
    } else if (indexPath.row == 0) {
        position = ExampleSettingsGroupPositionTop;
    } else if (indexPath.row == rowCount - 1) {
        position = ExampleSettingsGroupPositionBottom;
    }
    [(ExampleSettingsBaseCell *)cell applyGroupPosition:position];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    (void)tableView;
    ExampleSettingsItem *item = [self visibleItemAtIndexPath:indexPath];
    switch (item.kind) {
        case ExampleSettingsItemKindBool:
            return 52.0;
        case ExampleSettingsItemKindCheckbox:
        case ExampleSettingsItemKindRadio:
            return 58.0;
        case ExampleSettingsItemKindInfo:
            return 50.0;
        case ExampleSettingsItemKindImagePreview:
            return 252.0;
        case ExampleSettingsItemKindSlider:
            return 88.0;
        case ExampleSettingsItemKindNumber:
        case ExampleSettingsItemKindSegmented:
        case ExampleSettingsItemKindList:
        case ExampleSettingsItemKindText:
        case ExampleSettingsItemKindColorInput:
            return 72.0;
        case ExampleSettingsItemKindMultilineText:
            return 148.0;
        case ExampleSettingsItemKindAction:
            return 38.0;
        case ExampleSettingsItemKindLog:
            return 178.0;
        default:
            return 56.0;
    }
}

- (NSString *)reuseIdentifierForItem:(ExampleSettingsItem *)item {
    switch (item.kind) {
        case ExampleSettingsItemKindBool:
            return @"ExampleSettingsBoolCell";
        case ExampleSettingsItemKindCheckbox:
            return @"ExampleSettingsCheckboxCell";
        case ExampleSettingsItemKindRadio:
            return @"ExampleSettingsRadioCell";
        case ExampleSettingsItemKindNumber:
            return @"ExampleSettingsNumberCell";
        case ExampleSettingsItemKindSlider:
            return @"ExampleSettingsSliderCell";
        case ExampleSettingsItemKindSegmented:
            return @"ExampleSettingsSegmentedCell";
        case ExampleSettingsItemKindList:
            return @"ExampleSettingsListCell";
        case ExampleSettingsItemKindText:
            return @"ExampleSettingsTextCell";
        case ExampleSettingsItemKindColorInput:
            return @"ExampleSettingsColorInputCell";
        case ExampleSettingsItemKindMultilineText:
            return @"ExampleSettingsMultilineTextCell";
        case ExampleSettingsItemKindAction:
            return [@"ExampleSettingsActionCell." stringByAppendingString:item.title ?: @""];
        case ExampleSettingsItemKindInfo:
            return @"ExampleSettingsInfoCell";
        case ExampleSettingsItemKindImagePreview:
            return @"ExampleSettingsImagePreviewCell";
        case ExampleSettingsItemKindLog:
            return @"ExampleSettingsLogCell";
    }
}

@end
