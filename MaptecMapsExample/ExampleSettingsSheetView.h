#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef BOOL (^ExampleSettingsBoolGetter)(void);
typedef void (^ExampleSettingsBoolSetter)(BOOL value);
typedef double (^ExampleSettingsNumberGetter)(void);
typedef void (^ExampleSettingsNumberSetter)(double value);
typedef NSString *_Nonnull (^ExampleSettingsNumberFormatter)(double value);
typedef NSInteger (^ExampleSettingsSegmentGetter)(void);
typedef void (^ExampleSettingsSegmentSetter)(NSInteger index);
typedef NSString *_Nonnull (^ExampleSettingsTextGetter)(void);
typedef void (^ExampleSettingsTextSetter)(NSString *value);
typedef UIImage *_Nullable (^ExampleSettingsImageGetter)(void);
typedef NSArray<NSString *> *_Nonnull (^ExampleSettingsLogGetter)(void);
typedef void (^ExampleSettingsActionHandler)(void);
typedef BOOL (^ExampleSettingsEnabledGetter)(void);
typedef BOOL (^ExampleSettingsVisibleGetter)(void);

@interface ExampleSettingsListGroup : NSObject

+ (instancetype)groupWithTitle:(NSString *)title
                       options:(NSArray<NSString *> *)options;

+ (instancetype)groupWithTitle:(NSString *)title
                       options:(NSArray<NSString *> *)options
                optionHexValues:(nullable NSArray<NSString *> *)optionHexValues
             initiallyCollapsed:(BOOL)initiallyCollapsed;

@end

@interface ExampleSettingsItem : NSObject

+ (instancetype)boolItemWithTitle:(NSString *)title
                           getter:(ExampleSettingsBoolGetter)getter
                           setter:(ExampleSettingsBoolSetter)setter;

+ (instancetype)checkboxItemWithTitle:(NSString *)title
                                getter:(ExampleSettingsBoolGetter)getter
                                setter:(ExampleSettingsBoolSetter)setter;

+ (instancetype)radioItemWithTitle:(NSString *)title
                             getter:(ExampleSettingsBoolGetter)getter
                             setter:(ExampleSettingsBoolSetter)setter;

+ (instancetype)numberItemWithTitle:(NSString *)title
                            minimum:(double)minimum
                            maximum:(double)maximum
                               step:(double)step
                             getter:(ExampleSettingsNumberGetter)getter
                             setter:(ExampleSettingsNumberSetter)setter
                          formatter:(ExampleSettingsNumberFormatter)formatter;

+ (instancetype)sliderItemWithTitle:(NSString *)title
                            minimum:(double)minimum
                            maximum:(double)maximum
                               step:(double)step
                             getter:(ExampleSettingsNumberGetter)getter
                             setter:(ExampleSettingsNumberSetter)setter
                          formatter:(ExampleSettingsNumberFormatter)formatter;

+ (instancetype)segmentedItemWithTitle:(NSString *)title
                              segments:(NSArray<NSString *> *)segments
                                getter:(ExampleSettingsSegmentGetter)getter
                                setter:(ExampleSettingsSegmentSetter)setter;

+ (instancetype)listItemWithTitle:(NSString *)title
                          options:(NSArray<NSString *> *)options
                           getter:(ExampleSettingsSegmentGetter)getter
                           setter:(ExampleSettingsSegmentSetter)setter;

+ (instancetype)listItemWithTitle:(NSString *)title
                          options:(NSArray<NSString *> *)options
                        popupSize:(CGSize)popupSize
                           getter:(ExampleSettingsSegmentGetter)getter
                           setter:(ExampleSettingsSegmentSetter)setter;

+ (instancetype)groupedListItemWithTitle:(NSString *)title
                                  groups:(NSArray<ExampleSettingsListGroup *> *)groups
                               popupSize:(CGSize)popupSize
                                  getter:(ExampleSettingsSegmentGetter)getter
                                  setter:(ExampleSettingsSegmentSetter)setter;

+ (instancetype)textItemWithTitle:(NSString *)title
                       placeholder:(nullable NSString *)placeholder
                       keyboardType:(UIKeyboardType)keyboardType
                             getter:(ExampleSettingsTextGetter)getter
                             setter:(ExampleSettingsTextSetter)setter;

+ (instancetype)multilineTextItemWithTitle:(NSString *)title
                                placeholder:(nullable NSString *)placeholder
                                      getter:(ExampleSettingsTextGetter)getter
                                      setter:(nullable ExampleSettingsTextSetter)setter;

+ (instancetype)colorInputItemWithTitle:(NSString *)title
                             placeholder:(nullable NSString *)placeholder
                                 options:(NSArray<NSString *> *)options
                          optionHexValues:(NSArray<NSString *> *)optionHexValues
                               popupSize:(CGSize)popupSize
                                  getter:(ExampleSettingsTextGetter)getter
                                  setter:(ExampleSettingsTextSetter)setter
                           optionGetter:(ExampleSettingsSegmentGetter)getterIndex
                           optionSetter:(ExampleSettingsSegmentSetter)setterIndex;

+ (instancetype)actionItemWithTitle:(NSString *)title
                             handler:(ExampleSettingsActionHandler)handler;

+ (instancetype)infoItemWithText:(NSString *)text;

+ (instancetype)dynamicInfoItemWithGetter:(ExampleSettingsTextGetter)getter;

+ (instancetype)imagePreviewItemWithTitle:(NSString *)title
                              imageGetter:(ExampleSettingsImageGetter)imageGetter;

+ (instancetype)logItemWithTitle:(NSString *)title
                       logsGetter:(ExampleSettingsLogGetter)logsGetter
                      clearHandler:(nullable ExampleSettingsActionHandler)clearHandler;

- (instancetype)enabledWhen:(ExampleSettingsEnabledGetter)getter;
- (instancetype)visibleWhen:(ExampleSettingsVisibleGetter)getter;
- (void)updateTitle:(NSString *)title;

/// UI 测试标识，与 Android test tag / `MTCExampleTestAccessibility` 对齐。
- (instancetype)withAccessibilityIdentifier:(NSString *)accessibilityIdentifier;

@end

@interface ExampleSettingsSection : NSObject

+ (instancetype)sectionWithTitle:(NSString *)title items:(NSArray<ExampleSettingsItem *> *)items;

+ (instancetype)collapsibleSectionWithTitle:(NSString *)title
                         initiallyCollapsed:(BOOL)initiallyCollapsed
                                      items:(NSArray<ExampleSettingsItem *> *)items;

+ (instancetype)collapsibleSectionWithTitle:(NSString *)title
                         initiallyCollapsed:(BOOL)initiallyCollapsed
                                      items:(NSArray<ExampleSettingsItem *> *)items
                              childSections:(NSArray<ExampleSettingsSection *> *)childSections;

@end

@interface ExampleSettingsSheetView : UIView

- (instancetype)initWithTitle:(NSString *)title sections:(NSArray<ExampleSettingsSection *> *)sections NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithTitle:(NSString *)title items:(NSArray<ExampleSettingsItem *> *)items;
- (void)reloadData;
- (void)refreshItem:(ExampleSettingsItem *)item;
- (void)refreshVisibleItems;
- (void)showInView:(UIView *)superview animated:(BOOL)animated;
- (void)dismissAnimated:(BOOL)animated;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
