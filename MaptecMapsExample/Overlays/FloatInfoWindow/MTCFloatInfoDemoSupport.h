//
//  MTCFloatInfoDemoSupport.h
//  MaptecMapsExample
//
//  Created by ZHOUPanpan on 2026/7/13.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const MTCFloatInfoDefaultLine1Text;
extern NSString * const MTCFloatInfoDefaultLine2Text;
extern NSString * const MTCFloatInfoDefaultBackgroundColorHex;
extern NSString * const MTCFloatInfoDefaultBorderColorHex;
extern NSString * const MTCFloatInfoDefaultRichTextHTML;

@interface MTCFloatInfoColorOption : NSObject

@property (nonatomic, copy, readonly) NSString *title;
@property (nonatomic, copy, readonly) NSString *hexValue;

- (instancetype)initWithTitle:(NSString *)title hexValue:(NSString *)hexValue;

@end

@interface MTCFloatInfoBubbleView : UIControl

@property (nonatomic, copy) NSString *line1Text;
@property (nonatomic, copy) NSString *line2Text;
@property (nonatomic, copy, nullable) NSString *richTextHTML;
@property (nonatomic) CGFloat cornerRadius;
@property (nonatomic) CGFloat maximumWidth;
@property (nonatomic, strong) UIColor *bubbleBackgroundColor;
@property (nonatomic, strong) UIColor *bubbleBorderColor;
@property (nonatomic) CGFloat bubbleBorderWidth;

- (void)applyPlainTextLine1:(NSString *)line1 line2:(NSString *)line2;
- (void)applyRichTextHTML:(NSString *)richTextHTML;

@end

FOUNDATION_EXTERN NSArray<MTCFloatInfoColorOption *> *MTCFloatInfoPresetColors(void);
FOUNDATION_EXTERN NSArray<NSString *> *MTCFloatInfoPresetColorTitles(void);
FOUNDATION_EXTERN UIColor *MTCFloatInfoColorFromHexString(NSString *hexString, NSString *fallbackHex);

NS_ASSUME_NONNULL_END
