//
//  MTCWebSettingsFloatView.h
//  MaptecMapsExample
//
//  Created by ZHOUPanpan on 2026/7/14.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NSString *_Nonnull (^MTCWebSettingsTextGetter)(void);
typedef void (^MTCWebSettingsTextSetter)(NSString *value);
typedef NSInteger (^MTCWebSettingsOptionGetter)(void);
typedef void (^MTCWebSettingsOptionSetter)(NSInteger index);
typedef BOOL (^MTCWebSettingsBoolGetter)(void);
typedef void (^MTCWebSettingsBoolSetter)(BOOL value);
typedef NSString *_Nonnull (^MTCWebSettingsValueGetter)(void);
typedef void (^MTCWebSettingsActionHandler)(void);
typedef BOOL (^MTCWebSettingsEnabledGetter)(void);
typedef BOOL (^MTCWebSettingsVisibleGetter)(void);

typedef NS_ENUM(NSInteger, MTCWebSettingsItemKind) {
    MTCWebSettingsItemKindText = 0,
    MTCWebSettingsItemKindTextView,
    MTCWebSettingsItemKindOption,
    MTCWebSettingsItemKindToggle,
    MTCWebSettingsItemKindAction,
    MTCWebSettingsItemKindInfo,
    MTCWebSettingsItemKindSelectableInfo,
};

typedef NS_ENUM(NSInteger, MTCWebSettingsActionStyle) {
    MTCWebSettingsActionStylePrimary = 0,
    MTCWebSettingsActionStyleSecondary,
};

@interface MTCWebSettingsItem : NSObject

@property (nonatomic, copy, readonly) NSString *title;

+ (instancetype)textItemWithTitle:(NSString *)title
                      placeholder:(nullable NSString *)placeholder
                           detail:(nullable NSString *)detail
                     keyboardType:(UIKeyboardType)keyboardType
                           getter:(MTCWebSettingsTextGetter)getter
                           setter:(MTCWebSettingsTextSetter)setter;

+ (instancetype)textViewItemWithTitle:(NSString *)title
                           placeholder:(nullable NSString *)placeholder
                                detail:(nullable NSString *)detail
                          keyboardType:(UIKeyboardType)keyboardType
                       accessoryInputs:(NSArray<NSString *> *)accessoryInputs
                                getter:(MTCWebSettingsTextGetter)getter
                                setter:(MTCWebSettingsTextSetter)setter;

+ (instancetype)optionItemWithTitle:(NSString *)title
                             detail:(nullable NSString *)detail
                            options:(NSArray<NSString *> *)options
                             getter:(MTCWebSettingsOptionGetter)getter
                             setter:(MTCWebSettingsOptionSetter)setter;

+ (instancetype)toggleItemWithTitle:(NSString *)title
                             detail:(nullable NSString *)detail
                             getter:(MTCWebSettingsBoolGetter)getter
                             setter:(MTCWebSettingsBoolSetter)setter;

+ (instancetype)actionItemWithTitle:(NSString *)title
                              style:(MTCWebSettingsActionStyle)style
                            handler:(MTCWebSettingsActionHandler)handler;

+ (instancetype)infoItemWithTitle:(NSString *)title
                            value:(MTCWebSettingsValueGetter)getter;

+ (instancetype)selectableInfoItemWithTitle:(NSString *)title
                                     detail:(nullable NSString *)detail
                                      value:(nullable MTCWebSettingsValueGetter)getter
                                   selected:(nullable MTCWebSettingsBoolGetter)selectedGetter
                                    handler:(MTCWebSettingsActionHandler)handler;

- (instancetype)enabledWhen:(MTCWebSettingsEnabledGetter)getter;
- (instancetype)visibleWhen:(MTCWebSettingsVisibleGetter)getter;
- (instancetype)textViewHeight:(CGFloat)height;

@end

@interface MTCWebSettingsSection : NSObject

@property (nonatomic, copy, readonly) NSString *title;
@property (nonatomic, copy, readonly) NSArray<MTCWebSettingsItem *> *items;

+ (instancetype)sectionWithTitle:(NSString *)title
                           items:(NSArray<MTCWebSettingsItem *> *)items;

@end

@interface MTCWebSettingsFloatView : UIView

- (instancetype)initWithTitle:(NSString *)title
                     sections:(NSArray<MTCWebSettingsSection *> *)sections NS_DESIGNATED_INITIALIZER;
- (void)updateTitle:(NSString *)title;
- (void)updateSections:(NSArray<MTCWebSettingsSection *> *)sections;
- (void)reloadData;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
