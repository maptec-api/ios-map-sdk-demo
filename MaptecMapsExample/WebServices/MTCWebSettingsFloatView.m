//
//  MTCWebSettingsFloatView.m
//  MaptecMapsExample
//
//  Created by ZHOUPanpan on 2026/7/14.
//

#import "MTCWebSettingsFloatView.h"

#import "MTCExampleDemoLocalization.h"

#import <Masonry/Masonry.h>
#pragma mark - Model

@interface MTCWebSettingsItem ()

@property (nonatomic, assign) MTCWebSettingsItemKind kind;
@property (nonatomic, copy, readwrite) NSString *title;
@property (nonatomic, copy, nullable) NSString *placeholder;
@property (nonatomic, copy, nullable) NSString *detail;
@property (nonatomic, assign) UIKeyboardType keyboardType;
@property (nonatomic, copy, nullable) NSArray<NSString *> *options;
@property (nonatomic, copy, nullable) NSArray<NSString *> *accessoryInputs;
@property (nonatomic, assign) MTCWebSettingsActionStyle actionStyle;
@property (nonatomic, copy, nullable) MTCWebSettingsTextGetter textGetter;
@property (nonatomic, copy, nullable) MTCWebSettingsTextSetter textSetter;
@property (nonatomic, copy, nullable) MTCWebSettingsOptionGetter optionGetter;
@property (nonatomic, copy, nullable) MTCWebSettingsOptionSetter optionSetter;
@property (nonatomic, copy, nullable) MTCWebSettingsBoolGetter boolGetter;
@property (nonatomic, copy, nullable) MTCWebSettingsBoolSetter boolSetter;
@property (nonatomic, copy, nullable) MTCWebSettingsBoolGetter selectedGetter;
@property (nonatomic, copy, nullable) MTCWebSettingsValueGetter valueGetter;
@property (nonatomic, copy, nullable) MTCWebSettingsActionHandler actionHandler;
@property (nonatomic, copy, nullable) MTCWebSettingsEnabledGetter enabledGetter;
@property (nonatomic, copy, nullable) MTCWebSettingsVisibleGetter visibleGetter;
@property (nonatomic, assign) CGFloat textViewHeight;

@end

@implementation MTCWebSettingsItem

+ (instancetype)textItemWithTitle:(NSString *)title
                      placeholder:(NSString *)placeholder
                           detail:(NSString *)detail
                     keyboardType:(UIKeyboardType)keyboardType
                           getter:(MTCWebSettingsTextGetter)getter
                           setter:(MTCWebSettingsTextSetter)setter {
    MTCWebSettingsItem *item = [[self alloc] init];
    item.kind = MTCWebSettingsItemKindText;
    item.title = title;
    item.placeholder = placeholder;
    item.detail = detail;
    item.keyboardType = keyboardType;
    item.textGetter = getter;
    item.textSetter = setter;
    return item;
}

+ (instancetype)textViewItemWithTitle:(NSString *)title
                           placeholder:(NSString *)placeholder
                                detail:(NSString *)detail
                          keyboardType:(UIKeyboardType)keyboardType
                       accessoryInputs:(NSArray<NSString *> *)accessoryInputs
                                getter:(MTCWebSettingsTextGetter)getter
                                setter:(MTCWebSettingsTextSetter)setter {
    MTCWebSettingsItem *item = [[self alloc] init];
    item.kind = MTCWebSettingsItemKindTextView;
    item.title = title;
    item.placeholder = placeholder;
    item.detail = detail;
    item.keyboardType = keyboardType;
    item.accessoryInputs = accessoryInputs;
    item.textGetter = getter;
    item.textSetter = setter;
    return item;
}

+ (instancetype)optionItemWithTitle:(NSString *)title
                             detail:(NSString *)detail
                            options:(NSArray<NSString *> *)options
                             getter:(MTCWebSettingsOptionGetter)getter
                             setter:(MTCWebSettingsOptionSetter)setter {
    MTCWebSettingsItem *item = [[self alloc] init];
    item.kind = MTCWebSettingsItemKindOption;
    item.title = title;
    item.detail = detail;
    item.options = options;
    item.optionGetter = getter;
    item.optionSetter = setter;
    return item;
}

+ (instancetype)toggleItemWithTitle:(NSString *)title
                             detail:(NSString *)detail
                             getter:(MTCWebSettingsBoolGetter)getter
                             setter:(MTCWebSettingsBoolSetter)setter {
    MTCWebSettingsItem *item = [[self alloc] init];
    item.kind = MTCWebSettingsItemKindToggle;
    item.title = title;
    item.detail = detail;
    item.boolGetter = getter;
    item.boolSetter = setter;
    return item;
}

+ (instancetype)actionItemWithTitle:(NSString *)title
                              style:(MTCWebSettingsActionStyle)style
                            handler:(MTCWebSettingsActionHandler)handler {
    MTCWebSettingsItem *item = [[self alloc] init];
    item.kind = MTCWebSettingsItemKindAction;
    item.title = title;
    item.actionStyle = style;
    item.actionHandler = handler;
    return item;
}

+ (instancetype)infoItemWithTitle:(NSString *)title
                            value:(MTCWebSettingsValueGetter)getter {
    MTCWebSettingsItem *item = [[self alloc] init];
    item.kind = MTCWebSettingsItemKindInfo;
    item.title = title;
    item.valueGetter = getter;
    return item;
}

+ (instancetype)selectableInfoItemWithTitle:(NSString *)title
                                     detail:(NSString *)detail
                                      value:(MTCWebSettingsValueGetter)getter
                                   selected:(MTCWebSettingsBoolGetter)selectedGetter
                                    handler:(MTCWebSettingsActionHandler)handler {
    MTCWebSettingsItem *item = [[self alloc] init];
    item.kind = MTCWebSettingsItemKindSelectableInfo;
    item.title = title;
    item.detail = detail;
    item.valueGetter = getter;
    item.selectedGetter = selectedGetter;
    item.actionHandler = handler;
    return item;
}

- (instancetype)enabledWhen:(MTCWebSettingsEnabledGetter)getter {
    self.enabledGetter = getter;
    return self;
}

- (instancetype)visibleWhen:(MTCWebSettingsVisibleGetter)getter {
    self.visibleGetter = getter;
    return self;
}

- (instancetype)textViewHeight:(CGFloat)height {
    self.textViewHeight = height;
    return self;
}

@end

@interface MTCWebSettingsSection ()

@property (nonatomic, copy, readwrite) NSString *title;
@property (nonatomic, copy, readwrite) NSArray<MTCWebSettingsItem *> *items;

@end

@implementation MTCWebSettingsSection

+ (instancetype)sectionWithTitle:(NSString *)title
                           items:(NSArray<MTCWebSettingsItem *> *)items {
    MTCWebSettingsSection *section = [[self alloc] init];
    section.title = title;
    section.items = items;
    return section;
}

@end

#pragma mark - Cells

@interface MTCWebSettingsTextCell : UITableViewCell

@property (nonatomic, strong, readonly) UILabel *titleLabel;
@property (nonatomic, strong, readonly) UITextField *textField;
@property (nonatomic, strong, readonly) UILabel *detailLabel;
@property (nonatomic, copy, nullable) dispatch_block_t valueDidChangeHandler;

@end

@implementation MTCWebSettingsTextCell {
    UIStackView *_stackView;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
        _titleLabel.textColor = UIColor.labelColor;

        _textField = [[UITextField alloc] init];
        _textField.borderStyle = UITextBorderStyleRoundedRect;
        _textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        [_textField addTarget:self action:@selector(textDidChange:) forControlEvents:UIControlEventEditingChanged];

        _detailLabel = [[UILabel alloc] init];
        _detailLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
        _detailLabel.textColor = UIColor.secondaryLabelColor;
        _detailLabel.numberOfLines = 0;

        _stackView = [[UIStackView alloc] initWithArrangedSubviews:@[_titleLabel, _textField, _detailLabel]];
        _stackView.axis = UILayoutConstraintAxisVertical;
        _stackView.spacing = 6.0;
        _stackView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:_stackView];

        [NSLayoutConstraint activateConstraints:@[
            [_stackView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:10.0],
            [_stackView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16.0],
            [_stackView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16.0],
            [_stackView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-10.0],
        ]];
    }
    return self;
}

- (void)textDidChange:(UITextField *)textField {
    if (self.valueDidChangeHandler) {
        self.valueDidChangeHandler();
    }
    (void)textField;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    _titleLabel.text = nil;
    _textField.text = nil;
    _textField.placeholder = nil;
    _detailLabel.text = nil;
    _detailLabel.hidden = NO;
    _valueDidChangeHandler = nil;
}

@end

@interface MTCWebSettingsTextViewCell : UITableViewCell <UITextViewDelegate>

@property (nonatomic, strong, readonly) UILabel *titleLabel;
@property (nonatomic, strong, readonly) UITextView *textView;
@property (nonatomic, strong, readonly) UILabel *placeholderLabel;
@property (nonatomic, strong, readonly) UILabel *detailLabel;
@property (nonatomic, copy, nullable) void (^valueDidChangeHandler)(NSString *value);
@property (nonatomic, copy, nullable) dispatch_block_t heightDidChangeHandler;

- (void)setTextValue:(NSString *)value;
- (void)configureAccessoryInputs:(NSArray<NSString *> *)inputs;
- (void)applyTextViewHeight:(CGFloat)height;

@end

@implementation MTCWebSettingsTextViewCell {
    UIStackView *_stackView;
    NSArray<NSString *> *_accessoryInputs;
    UIView *_textContainerView;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
        _titleLabel.textColor = UIColor.labelColor;

        _textContainerView = [[UIView alloc] init];
        _textContainerView.backgroundColor = UIColor.secondarySystemBackgroundColor;
        _textContainerView.layer.cornerRadius = 8.0;
        _textContainerView.layer.borderWidth = 1.0;
        _textContainerView.layer.borderColor = UIColor.separatorColor.CGColor;

        _textView = [[UITextView alloc] init];
        _textView.delegate = self;
        _textView.backgroundColor = UIColor.clearColor;
        _textView.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        _textView.scrollEnabled = NO;
        _textView.textContainerInset = UIEdgeInsetsMake(8.0, 8.0, 8.0, 8.0);
        _textView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
        [_textContainerView addSubview:_textView];

        _placeholderLabel = [[UILabel alloc] init];
        _placeholderLabel.font = _textView.font;
        _placeholderLabel.textColor = UIColor.placeholderTextColor;
        [_textContainerView addSubview:_placeholderLabel];

        _detailLabel = [[UILabel alloc] init];
        _detailLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
        _detailLabel.textColor = UIColor.secondaryLabelColor;
        _detailLabel.numberOfLines = 0;

        _stackView = [[UIStackView alloc] initWithArrangedSubviews:@[_titleLabel, _textContainerView, _detailLabel]];
        _stackView.axis = UILayoutConstraintAxisVertical;
        _stackView.spacing = 6.0;
        [self.contentView addSubview:_stackView];

        [_stackView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.contentView).offset(10.0);
            make.leading.equalTo(self.contentView).offset(16.0);
            make.trailing.equalTo(self.contentView).offset(-16.0);
            make.bottom.equalTo(self.contentView).offset(-10.0);
        }];
        [_textContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.greaterThanOrEqualTo(@88.0);
        }];
        [_textView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(_textContainerView);
        }];
        [_placeholderLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_textContainerView).offset(8.0);
            make.leading.equalTo(_textContainerView).offset(13.0);
            make.trailing.lessThanOrEqualTo(_textContainerView).offset(-13.0);
        }];
    }
    return self;
}

- (void)configureAccessoryInputs:(NSArray<NSString *> *)inputs {
    _accessoryInputs = [inputs copy];
    self.textView.inputAccessoryView = _accessoryInputs.count > 0 ? [self accessoryViewWithInputs:_accessoryInputs] : nil;
}

- (void)applyTextViewHeight:(CGFloat)height {
    self.textView.scrollEnabled = height > 0.0;
    [_textContainerView mas_remakeConstraints:^(MASConstraintMaker *make) {
        if (height > 0.0) {
            make.height.equalTo(@(height));
        } else {
            make.height.greaterThanOrEqualTo(@88.0);
        }
    }];
}

- (void)setTextValue:(NSString *)value {
    self.textView.text = value ?: @"";
    self.placeholderLabel.hidden = self.textView.text.length > 0;
}

- (void)textViewDidChange:(UITextView *)textView {
    self.placeholderLabel.hidden = textView.text.length > 0;
    if (self.valueDidChangeHandler) {
        self.valueDidChangeHandler(textView.text ?: @"");
    }
    if (self.heightDidChangeHandler) {
        self.heightDidChangeHandler();
    }
}

- (UIView *)accessoryViewWithInputs:(NSArray<NSString *> *)inputs {
    UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, UIScreen.mainScreen.bounds.size.width, 48.0)];
    containerView.backgroundColor = UIColor.secondarySystemBackgroundColor;

    UIScrollView *scrollView = [[UIScrollView alloc] init];
    scrollView.showsHorizontalScrollIndicator = NO;
    [containerView addSubview:scrollView];

    UIStackView *stackView = [[UIStackView alloc] init];
    stackView.axis = UILayoutConstraintAxisHorizontal;
    stackView.spacing = 8.0;
    [scrollView addSubview:stackView];

    [scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(containerView).insets(UIEdgeInsetsMake(6.0, 12.0, 6.0, 12.0));
    }];
    [stackView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(scrollView);
        make.height.equalTo(scrollView);
    }];

    for (NSString *input in inputs) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        button.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
        button.backgroundColor = UIColor.systemBackgroundColor;
        button.layer.cornerRadius = 14.0;
        button.layer.borderWidth = 1.0;
        button.layer.borderColor = UIColor.separatorColor.CGColor;
        button.contentEdgeInsets = UIEdgeInsetsMake(6.0, 10.0, 6.0, 10.0);
        [button setTitle:input forState:UIControlStateNormal];
        [button addTarget:self action:@selector(accessoryButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [stackView addArrangedSubview:button];
    }
    return containerView;
}

- (void)accessoryButtonTapped:(UIButton *)sender {
    NSString *input = sender.currentTitle ?: @"";
    if (input.length == 0) {
        return;
    }
    NSString *currentText = self.textView.text ?: @"";
    NSString *separator = currentText.length > 0 ? @"," : @"";
    [self setTextValue:[currentText stringByAppendingFormat:@"%@%@", separator, input]];
    [self textViewDidChange:self.textView];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    _titleLabel.text = nil;
    _placeholderLabel.text = nil;
    _detailLabel.text = nil;
    _detailLabel.hidden = NO;
    _valueDidChangeHandler = nil;
    _heightDidChangeHandler = nil;
    _textView.inputAccessoryView = nil;
    [self setTextValue:@""];
}

@end

@interface MTCWebSettingsSwitchCell : UITableViewCell

@property (nonatomic, strong, readonly) UILabel *titleLabel;
@property (nonatomic, strong, readonly) UILabel *detailLabel;
@property (nonatomic, strong, readonly) UISwitch *toggleSwitch;
@property (nonatomic, copy, nullable) void (^toggleHandler)(BOOL on);

@end

@implementation MTCWebSettingsSwitchCell {
    UIStackView *_stackView;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
        _titleLabel.textColor = UIColor.labelColor;

        _detailLabel = [[UILabel alloc] init];
        _detailLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
        _detailLabel.textColor = UIColor.secondaryLabelColor;
        _detailLabel.numberOfLines = 0;

        _stackView = [[UIStackView alloc] initWithArrangedSubviews:@[_titleLabel, _detailLabel]];
        _stackView.axis = UILayoutConstraintAxisVertical;
        _stackView.spacing = 4.0;
        _stackView.translatesAutoresizingMaskIntoConstraints = NO;

        _toggleSwitch = [[UISwitch alloc] init];
        [_toggleSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
        _toggleSwitch.translatesAutoresizingMaskIntoConstraints = NO;

        [self.contentView addSubview:_stackView];
        [self.contentView addSubview:_toggleSwitch];

        [NSLayoutConstraint activateConstraints:@[
            [_stackView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:10.0],
            [_stackView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16.0],
            [_stackView.trailingAnchor constraintLessThanOrEqualToAnchor:_toggleSwitch.leadingAnchor constant:-12.0],
            [_stackView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-10.0],
            [_toggleSwitch.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
            [_toggleSwitch.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16.0],
        ]];
    }
    return self;
}

- (void)switchChanged:(UISwitch *)sender {
    if (self.toggleHandler) {
        self.toggleHandler(sender.on);
    }
}

- (void)prepareForReuse {
    [super prepareForReuse];
    _titleLabel.text = nil;
    _detailLabel.text = nil;
    [_toggleSwitch setOn:NO animated:NO];
    _toggleHandler = nil;
}

@end

@interface MTCWebSettingsActionCell : UITableViewCell

@property (nonatomic, strong, readonly) UIButton *actionButton;
@property (nonatomic, copy, nullable) dispatch_block_t tapHandler;

@end

@implementation MTCWebSettingsActionCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        _actionButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _actionButton.layer.cornerRadius = 14.0;
        _actionButton.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
        _actionButton.translatesAutoresizingMaskIntoConstraints = NO;
        [_actionButton addTarget:self action:@selector(buttonTapped) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:_actionButton];

        [NSLayoutConstraint activateConstraints:@[
            [_actionButton.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:10.0],
            [_actionButton.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16.0],
            [_actionButton.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16.0],
            [_actionButton.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-10.0],
            [_actionButton.heightAnchor constraintEqualToConstant:50.0],
        ]];
    }
    return self;
}

- (void)buttonTapped {
    if (self.tapHandler) {
        self.tapHandler();
    }
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [_actionButton setTitle:@"" forState:UIControlStateNormal];
    [_actionButton setBackgroundColor:nil];
    [_actionButton setTitleColor:nil forState:UIControlStateNormal];
    _tapHandler = nil;
}

@end

@interface MTCWebSettingsSelectableInfoCell : UITableViewCell

@property (nonatomic, strong, readonly) UIView *cardView;
@property (nonatomic, strong, readonly) UILabel *titleLabel;
@property (nonatomic, strong, readonly) UILabel *detailLabel;
@property (nonatomic, strong, readonly) UILabel *valueLabel;

- (void)applySelectedAppearance:(BOOL)selected;

@end

@implementation MTCWebSettingsSelectableInfoCell {
    UIStackView *_stackView;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = UIColor.clearColor;
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        _cardView = [[UIView alloc] init];
        _cardView.translatesAutoresizingMaskIntoConstraints = NO;
        _cardView.layer.cornerRadius = 14.0;
        _cardView.layer.borderWidth = 1.0;
        [self.contentView addSubview:_cardView];

        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
        _titleLabel.textColor = UIColor.labelColor;
        _titleLabel.numberOfLines = 0;

        _detailLabel = [[UILabel alloc] init];
        _detailLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
        _detailLabel.textColor = UIColor.secondaryLabelColor;
        _detailLabel.numberOfLines = 0;

        _valueLabel = [[UILabel alloc] init];
        _valueLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
        _valueLabel.textColor = UIColor.tertiaryLabelColor;
        _valueLabel.numberOfLines = 0;

        _stackView = [[UIStackView alloc] initWithArrangedSubviews:@[_titleLabel, _detailLabel, _valueLabel]];
        _stackView.axis = UILayoutConstraintAxisVertical;
        _stackView.spacing = 4.0;
        _stackView.translatesAutoresizingMaskIntoConstraints = NO;
        [_cardView addSubview:_stackView];

        [NSLayoutConstraint activateConstraints:@[
            [_cardView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:6.0],
            [_cardView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16.0],
            [_cardView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16.0],
            [_cardView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-6.0],
            [_stackView.topAnchor constraintEqualToAnchor:_cardView.topAnchor constant:12.0],
            [_stackView.leadingAnchor constraintEqualToAnchor:_cardView.leadingAnchor constant:12.0],
            [_stackView.trailingAnchor constraintEqualToAnchor:_cardView.trailingAnchor constant:-12.0],
            [_stackView.bottomAnchor constraintEqualToAnchor:_cardView.bottomAnchor constant:-12.0],
        ]];

        [self applySelectedAppearance:NO];
    }
    return self;
}

- (void)applySelectedAppearance:(BOOL)selected {
    if (selected) {
        self.cardView.backgroundColor = [UIColor.systemBlueColor colorWithAlphaComponent:0.10];
        self.cardView.layer.borderColor = UIColor.systemBlueColor.CGColor;
        self.titleLabel.textColor = UIColor.systemBlueColor;
    } else {
        self.cardView.backgroundColor = UIColor.secondarySystemBackgroundColor;
        self.cardView.layer.borderColor = UIColor.separatorColor.CGColor;
        self.titleLabel.textColor = UIColor.labelColor;
    }
}

- (void)prepareForReuse {
    [super prepareForReuse];
    _titleLabel.text = nil;
    _detailLabel.text = nil;
    _detailLabel.hidden = NO;
    _valueLabel.text = nil;
    [self applySelectedAppearance:NO];
}

@end

#pragma mark - Float View

@interface MTCWebSettingsFloatView () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSArray<MTCWebSettingsSection *> *sections;
@property (nonatomic, copy) NSArray<MTCWebSettingsSection *> *visibleSections;
@property (nonatomic, strong) UIView *contentContainerView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UITableView *tableView;

@end

@implementation MTCWebSettingsFloatView

- (instancetype)initWithTitle:(NSString *)title
                     sections:(NSArray<MTCWebSettingsSection *> *)sections {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _title = [title copy];
        _sections = [sections copy];
        self.backgroundColor = UIColor.tertiarySystemBackgroundColor;

        _contentContainerView = [[UIView alloc] init];
        _contentContainerView.translatesAutoresizingMaskIntoConstraints = NO;
        _contentContainerView.backgroundColor = UIColor.systemBackgroundColor;
        _contentContainerView.layer.cornerRadius = 24.0;
        _contentContainerView.layer.shadowColor = UIColor.blackColor.CGColor;
        _contentContainerView.layer.shadowOpacity = 0.08;
        _contentContainerView.layer.shadowRadius = 16.0;
        _contentContainerView.layer.shadowOffset = CGSizeMake(0.0, 8.0);

        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle2];
        _titleLabel.textColor = UIColor.labelColor;
        _titleLabel.text = title;
        _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;

        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
        _tableView.translatesAutoresizingMaskIntoConstraints = NO;
        _tableView.backgroundColor = UIColor.clearColor;
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.rowHeight = UITableViewAutomaticDimension;
        _tableView.estimatedRowHeight = 72.0;
        _tableView.alwaysBounceVertical = YES;
        _tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
        [_tableView registerClass:MTCWebSettingsTextCell.class forCellReuseIdentifier:@"MTCWebSettingsTextCell"];
        [_tableView registerClass:MTCWebSettingsTextViewCell.class forCellReuseIdentifier:@"MTCWebSettingsTextViewCell"];
        [_tableView registerClass:MTCWebSettingsSwitchCell.class forCellReuseIdentifier:@"MTCWebSettingsSwitchCell"];
        [_tableView registerClass:MTCWebSettingsActionCell.class forCellReuseIdentifier:@"MTCWebSettingsActionCell"];
        [_tableView registerClass:MTCWebSettingsSelectableInfoCell.class forCellReuseIdentifier:@"MTCWebSettingsSelectableInfoCell"];
        [_tableView registerClass:UITableViewCell.class forCellReuseIdentifier:@"MTCWebSettingsOptionCell"];
        [_tableView registerClass:UITableViewCell.class forCellReuseIdentifier:@"MTCWebSettingsInfoCell"];

        [self addSubview:_contentContainerView];
        [_contentContainerView addSubview:_titleLabel];
        [_contentContainerView addSubview:_tableView];

        UILayoutGuide *safeAreaGuide = self.safeAreaLayoutGuide;

        [NSLayoutConstraint activateConstraints:@[

            [_contentContainerView.topAnchor constraintEqualToAnchor:safeAreaGuide.topAnchor constant:12.0],
            [_contentContainerView.leadingAnchor constraintEqualToAnchor:safeAreaGuide.leadingAnchor constant:12.0],
            [_contentContainerView.trailingAnchor constraintEqualToAnchor:safeAreaGuide.trailingAnchor constant:-12.0],
            [_contentContainerView.bottomAnchor constraintEqualToAnchor:safeAreaGuide.bottomAnchor constant:-12.0],

            [_titleLabel.topAnchor constraintEqualToAnchor:_contentContainerView.topAnchor constant:20.0],
            [_titleLabel.leadingAnchor constraintEqualToAnchor:_contentContainerView.leadingAnchor constant:20.0],
            [_titleLabel.trailingAnchor constraintEqualToAnchor:_contentContainerView.trailingAnchor constant:-20.0],
            [_tableView.topAnchor constraintEqualToAnchor:_titleLabel.bottomAnchor constant:8.0],
            [_tableView.leadingAnchor constraintEqualToAnchor:_contentContainerView.leadingAnchor],
            [_tableView.trailingAnchor constraintEqualToAnchor:_contentContainerView.trailingAnchor],
            [_tableView.bottomAnchor constraintEqualToAnchor:_contentContainerView.bottomAnchor constant:-12.0],
        ]];

        [self rebuildVisibleSections];
    }
    return self;
}

#pragma mark - Public

- (void)updateTitle:(NSString *)title {
    self.title = [title copy];
    self.titleLabel.text = title;
}

- (void)updateSections:(NSArray<MTCWebSettingsSection *> *)sections {
    self.sections = [sections copy];
    [self rebuildVisibleSections];
    [self.tableView reloadData];
}

- (void)reloadData {
    [self rebuildVisibleSections];
    [self.tableView reloadData];
}

#pragma mark - Life Cycle

#pragma mark - protocol

#pragma mark - Delegate
#pragma mark -- UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    (void)tableView;
    return self.visibleSections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.visibleSections[section].items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MTCWebSettingsItem *item = self.visibleSections[indexPath.section].items[indexPath.row];

    switch (item.kind) {
        case MTCWebSettingsItemKindText:
            return [self textCellForTableView:tableView item:item];
        case MTCWebSettingsItemKindTextView:
            return [self textViewCellForTableView:tableView item:item];
        case MTCWebSettingsItemKindToggle:
            return [self switchCellForTableView:tableView item:item];
        case MTCWebSettingsItemKindAction:
            return [self actionCellForTableView:tableView item:item];
        case MTCWebSettingsItemKindOption:
            return [self optionCellForTableView:tableView item:item];
        case MTCWebSettingsItemKindInfo:
            return [self infoCellForTableView:tableView item:item];
        case MTCWebSettingsItemKindSelectableInfo:
            return [self selectableInfoCellForTableView:tableView item:item];
    }
}

#pragma mark -- UITableViewDelegate

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    (void)tableView;
    NSString *title = self.visibleSections[section].title;
    return title.length > 0 ? title : nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    MTCWebSettingsItem *item = self.visibleSections[indexPath.section].items[indexPath.row];
    if (item.kind == MTCWebSettingsItemKindOption) {
        [self presentOptionsForItem:item sourceRect:[tableView rectForRowAtIndexPath:indexPath]];
    } else if (item.kind == MTCWebSettingsItemKindAction && item.actionHandler) {
        item.actionHandler();
    } else if (item.kind == MTCWebSettingsItemKindSelectableInfo && item.actionHandler) {
        item.actionHandler();
    }
}

#pragma mark - Event

#pragma mark - Private

- (void)rebuildVisibleSections {
    NSMutableArray<MTCWebSettingsSection *> *sections = [NSMutableArray array];
    for (MTCWebSettingsSection *section in self.sections) {
        NSMutableArray<MTCWebSettingsItem *> *items = [NSMutableArray array];
        for (MTCWebSettingsItem *item in section.items) {
            BOOL visible = item.visibleGetter ? item.visibleGetter() : YES;
            if (visible) {
                [items addObject:item];
            }
        }
        if (items.count > 0) {
            [sections addObject:[MTCWebSettingsSection sectionWithTitle:section.title items:items]];
        }
    }
    self.visibleSections = sections;
}

- (MTCWebSettingsTextCell *)textCellForTableView:(UITableView *)tableView item:(MTCWebSettingsItem *)item {
    MTCWebSettingsTextCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MTCWebSettingsTextCell"];
    cell.titleLabel.text = item.title;
    cell.textField.placeholder = item.placeholder;
    cell.textField.keyboardType = item.keyboardType;
    cell.textField.text = item.textGetter ? item.textGetter() : @"";
    cell.detailLabel.text = item.detail;
    cell.detailLabel.hidden = item.detail.length == 0;
    cell.userInteractionEnabled = [self itemEnabled:item];
    cell.contentView.alpha = [self itemEnabled:item] ? 1.0 : 0.45;
    __weak typeof(self) weakSelf = self;
    __weak typeof(cell) weakCell = cell;
    cell.valueDidChangeHandler = ^{
        MTCWebSettingsTextCell *strongCell = weakCell;
        if (item.textSetter) {
            item.textSetter(strongCell.textField.text ?: @"");
        }
        [weakSelf refreshVisibleEnabledStates];
    };
    return cell;
}

- (MTCWebSettingsTextViewCell *)textViewCellForTableView:(UITableView *)tableView item:(MTCWebSettingsItem *)item {
    MTCWebSettingsTextViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MTCWebSettingsTextViewCell"];
    cell.titleLabel.text = item.title;
    cell.placeholderLabel.text = item.placeholder;
    cell.textView.keyboardType = item.keyboardType;
    [cell setTextValue:item.textGetter ? item.textGetter() : @""];
    [cell configureAccessoryInputs:item.accessoryInputs ?: @[]];
    [cell applyTextViewHeight:item.textViewHeight];
    cell.detailLabel.text = item.detail;
    cell.detailLabel.hidden = item.detail.length == 0;
    cell.userInteractionEnabled = [self itemEnabled:item];
    cell.contentView.alpha = [self itemEnabled:item] ? 1.0 : 0.45;
    __weak typeof(self) weakSelf = self;
    cell.valueDidChangeHandler = ^(NSString *value) {
        if (item.textSetter) {
            item.textSetter(value ?: @"");
        }
        [weakSelf refreshVisibleEnabledStates];
    };
    cell.heightDidChangeHandler = ^{
        [weakSelf.tableView beginUpdates];
        [weakSelf.tableView endUpdates];
    };
    return cell;
}

- (UITableViewCell *)optionCellForTableView:(UITableView *)tableView item:(MTCWebSettingsItem *)item {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MTCWebSettingsOptionCell"];
    UIListContentConfiguration *configuration = [UIListContentConfiguration valueCellConfiguration];
    configuration.text = item.title;
    NSInteger index = item.optionGetter ? item.optionGetter() : NSNotFound;
    configuration.secondaryText = (index >= 0 && index < (NSInteger)item.options.count) ? item.options[index] : [MTCExampleDemoLocalization stringForKey:@"web_not_set_fe2d26" language:[MTCExampleDemoLocalization currentLanguage]];
    configuration.secondaryTextProperties.color = UIColor.secondaryLabelColor;
    cell.contentConfiguration = configuration;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.userInteractionEnabled = [self itemEnabled:item];
    cell.contentView.alpha = [self itemEnabled:item] ? 1.0 : 0.45;
    return cell;
}

- (UITableViewCell *)infoCellForTableView:(UITableView *)tableView item:(MTCWebSettingsItem *)item {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MTCWebSettingsInfoCell"];
    UIListContentConfiguration *configuration = [UIListContentConfiguration subtitleCellConfiguration];
    configuration.text = item.title;
    configuration.textProperties.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    configuration.secondaryText = item.valueGetter ? item.valueGetter() : @"";
    configuration.secondaryTextProperties.numberOfLines = 0;
    configuration.secondaryTextProperties.color = UIColor.secondaryLabelColor;
    cell.contentConfiguration = configuration;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.userInteractionEnabled = NO;
    return cell;
}

- (MTCWebSettingsSelectableInfoCell *)selectableInfoCellForTableView:(UITableView *)tableView item:(MTCWebSettingsItem *)item {
    MTCWebSettingsSelectableInfoCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MTCWebSettingsSelectableInfoCell"];
    cell.titleLabel.text = item.title;
    cell.detailLabel.text = item.detail;
    cell.detailLabel.hidden = item.detail.length == 0;
    NSString *value = item.valueGetter ? item.valueGetter() : @"";
    cell.valueLabel.text = value;
    cell.valueLabel.hidden = value.length == 0;
    BOOL selected = item.selectedGetter ? item.selectedGetter() : NO;
    [cell applySelectedAppearance:selected];
    cell.userInteractionEnabled = [self itemEnabled:item];
    cell.contentView.alpha = [self itemEnabled:item] ? 1.0 : 0.45;
    return cell;
}

- (MTCWebSettingsSwitchCell *)switchCellForTableView:(UITableView *)tableView item:(MTCWebSettingsItem *)item {
    MTCWebSettingsSwitchCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MTCWebSettingsSwitchCell"];
    cell.titleLabel.text = item.title;
    cell.detailLabel.text = item.detail;
    cell.detailLabel.hidden = item.detail.length == 0;
    cell.toggleSwitch.on = item.boolGetter ? item.boolGetter() : NO;
    BOOL enabled = [self itemEnabled:item];
    cell.toggleSwitch.enabled = enabled;
    cell.userInteractionEnabled = enabled;
    cell.contentView.alpha = enabled ? 1.0 : 0.45;
    __weak typeof(self) weakSelf = self;
    cell.toggleHandler = ^(BOOL on) {
        if (item.boolSetter) {
            item.boolSetter(on);
        }
        [weakSelf reloadData];
    };
    return cell;
}

- (MTCWebSettingsActionCell *)actionCellForTableView:(UITableView *)tableView item:(MTCWebSettingsItem *)item {
    MTCWebSettingsActionCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MTCWebSettingsActionCell"];
    [cell.actionButton setTitle:item.title forState:UIControlStateNormal];
    BOOL enabled = [self itemEnabled:item];
    cell.actionButton.enabled = enabled;
    cell.contentView.alpha = enabled ? 1.0 : 0.45;
    UIColor *backgroundColor = item.actionStyle == MTCWebSettingsActionStylePrimary ? UIColor.systemBlueColor : UIColor.systemGray5Color;
    UIColor *titleColor = item.actionStyle == MTCWebSettingsActionStylePrimary ? UIColor.whiteColor : UIColor.labelColor;
    cell.actionButton.backgroundColor = backgroundColor;
    [cell.actionButton setTitleColor:titleColor forState:UIControlStateNormal];
    cell.tapHandler = item.actionHandler;
    return cell;
}

- (void)presentOptionsForItem:(MTCWebSettingsItem *)item sourceRect:(CGRect)sourceRect {
    UIViewController *viewController = [self nearestViewController];
    if (!viewController) {
        return;
    }

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:item.title
                                                                             message:item.detail
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];
    __weak typeof(self) weakSelf = self;
    [item.options enumerateObjectsUsingBlock:^(NSString * _Nonnull option, NSUInteger idx, BOOL * _Nonnull stop) {
        (void)stop;
        UIAlertAction *action = [UIAlertAction actionWithTitle:option style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction * _Nonnull action) {
            if (item.optionSetter) {
                item.optionSetter((NSInteger)idx);
            }
            [weakSelf reloadData];
        }];
        [alertController addAction:action];
    }];
    [alertController addAction:[UIAlertAction actionWithTitle:[MTCExampleDemoLocalization stringForKey:@"web_cancel" language:[MTCExampleDemoLocalization currentLanguage]] style:UIAlertActionStyleCancel handler:nil]];

    UIPopoverPresentationController *popoverPresentationController = alertController.popoverPresentationController;
    if (popoverPresentationController) {
        popoverPresentationController.sourceView = self.tableView;
        popoverPresentationController.sourceRect = sourceRect;
    }
    [viewController presentViewController:alertController animated:YES completion:nil];
}

- (BOOL)itemEnabled:(MTCWebSettingsItem *)item {
    return item.enabledGetter ? item.enabledGetter() : YES;
}

- (void)refreshVisibleEnabledStates {
    for (NSIndexPath *indexPath in self.tableView.indexPathsForVisibleRows) {
        MTCWebSettingsItem *item = self.visibleSections[indexPath.section].items[indexPath.row];
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        BOOL enabled = [self itemEnabled:item];
        cell.contentView.alpha = enabled ? 1.0 : 0.45;
        if (item.kind == MTCWebSettingsItemKindAction) {
            MTCWebSettingsActionCell *actionCell = (MTCWebSettingsActionCell *)cell;
            actionCell.actionButton.enabled = enabled;
        } else if (item.kind == MTCWebSettingsItemKindText ||
                   item.kind == MTCWebSettingsItemKindTextView ||
                   item.kind == MTCWebSettingsItemKindOption ||
                   item.kind == MTCWebSettingsItemKindSelectableInfo) {
            cell.userInteractionEnabled = enabled;
        } else if (item.kind == MTCWebSettingsItemKindToggle) {
            MTCWebSettingsSwitchCell *switchCell = (MTCWebSettingsSwitchCell *)cell;
            switchCell.toggleSwitch.enabled = enabled;
            switchCell.userInteractionEnabled = enabled;
        }
    }
}

- (UIViewController *)nearestViewController {
    UIResponder *responder = self;
    while (responder) {
        responder = responder.nextResponder;
        if ([responder isKindOfClass:UIViewController.class]) {
            return (UIViewController *)responder;
        }
    }
    return nil;
}

#pragma mark - Getter & Setter

@end
