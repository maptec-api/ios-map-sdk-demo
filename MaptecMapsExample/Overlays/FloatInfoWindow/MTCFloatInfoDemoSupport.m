//
//  MTCFloatInfoDemoSupport.m
//  MaptecMapsExample
//
//  Created by ZHOUPanpan on 2026/7/13.
//

#import "MTCFloatInfoDemoSupport.h"

NSString * const MTCFloatInfoDefaultLine1Text = @"24 min";
NSString * const MTCFloatInfoDefaultLine2Text = @"7.9 km";
NSString * const MTCFloatInfoDefaultBackgroundColorHex = @"#424242";
NSString * const MTCFloatInfoDefaultBorderColorHex = @"#E0E0E0";
NSString * const MTCFloatInfoDefaultRichTextHTML = @"<b>标题</b><br/><font color=\"#FF0000\">详情</font>";

@implementation MTCFloatInfoColorOption

- (instancetype)initWithTitle:(NSString *)title hexValue:(NSString *)hexValue {
    self = [super init];
    if (self) {
        _title = [title copy];
        _hexValue = [hexValue copy];
    }
    return self;
}

@end

@implementation MTCFloatInfoBubbleView {
    UILabel *_primaryLabel;
    UILabel *_secondaryLabel;
    CAShapeLayer *_shapeLayer;
}

static CGFloat const kBubbleHorizontalPadding = 18.0;
static CGFloat const kBubbleTopPadding = 14.0;
static CGFloat const kBubbleBottomPadding = 14.0;
static CGFloat const kBubbleTailHeight = 10.0;
static CGFloat const kBubbleTailHalfWidth = 9.0;
static CGFloat const kBubbleContentSpacing = 4.0;
static CGFloat const kBubbleMinimumWidth = 128.0;

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColor.clearColor;
        _shapeLayer = [CAShapeLayer layer];
        [self.layer addSublayer:_shapeLayer];

        _primaryLabel = [[UILabel alloc] init];
        _primaryLabel.textColor = UIColor.whiteColor;
        _primaryLabel.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightBold];
        _primaryLabel.numberOfLines = 0;
        [self addSubview:_primaryLabel];

        _secondaryLabel = [[UILabel alloc] init];
        _secondaryLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.92];
        _secondaryLabel.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightMedium];
        _secondaryLabel.numberOfLines = 0;
        [self addSubview:_secondaryLabel];

        self.layer.shadowColor = UIColor.blackColor.CGColor;
        self.layer.shadowOpacity = 0.14;
        self.layer.shadowRadius = 10.0;
        self.layer.shadowOffset = CGSizeMake(0.0, 4.0);

        _cornerRadius = 8.0;
        _maximumWidth = 300.0;
        _bubbleBackgroundColor = [UIColor colorWithRed:0.259 green:0.259 blue:0.259 alpha:1.0];
        _bubbleBorderColor = [UIColor colorWithWhite:0.88 alpha:1.0];
        _bubbleBorderWidth = 1.0;
    }
    return self;
}

- (void)applyPlainTextLine1:(NSString *)line1 line2:(NSString *)line2 {
    self.richTextHTML = nil;
    self.line1Text = line1.length > 0 ? line1 : MTCFloatInfoDefaultLine1Text;
    self.line2Text = line2.length > 0 ? line2 : MTCFloatInfoDefaultLine2Text;
    _primaryLabel.attributedText = nil;
    _primaryLabel.text = self.line1Text;
    _primaryLabel.textColor = UIColor.whiteColor;
    _primaryLabel.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightBold];
    _secondaryLabel.hidden = NO;
    _secondaryLabel.text = self.line2Text;
    [self invalidateIntrinsicContentSize];
    [self setNeedsLayout];
}

- (void)applyRichTextHTML:(NSString *)richTextHTML {
    self.richTextHTML = richTextHTML.length > 0 ? richTextHTML : MTCFloatInfoDefaultRichTextHTML;
    self.line1Text = @"";
    self.line2Text = @"";
    _primaryLabel.attributedText = [self attributedStringFromHTML:self.richTextHTML];
    _secondaryLabel.hidden = YES;
    _secondaryLabel.text = nil;
    [self invalidateIntrinsicContentSize];
    [self setNeedsLayout];
}

- (CGSize)sizeThatFits:(CGSize)size {
    (void)size;
    CGFloat maxWidth = self.maximumWidth > 0.0 ? self.maximumWidth : 300.0;
    CGFloat availableLabelWidth = MAX(80.0, maxWidth - kBubbleHorizontalPadding * 2.0);
    CGSize primarySize = [_primaryLabel sizeThatFits:CGSizeMake(availableLabelWidth, CGFLOAT_MAX)];
    CGSize secondarySize = _secondaryLabel.hidden ? CGSizeZero : [_secondaryLabel sizeThatFits:CGSizeMake(availableLabelWidth, CGFLOAT_MAX)];
    CGFloat width = MAX(primarySize.width, secondarySize.width) + kBubbleHorizontalPadding * 2.0;
    width = MAX(kBubbleMinimumWidth, MIN(maxWidth, ceil(width)));

    CGFloat bodyHeight = kBubbleTopPadding + ceil(primarySize.height);
    if (!_secondaryLabel.hidden) {
        bodyHeight += kBubbleContentSpacing + ceil(secondarySize.height);
    }
    bodyHeight += kBubbleBottomPadding;
    return CGSizeMake(width, ceil(bodyHeight + kBubbleTailHeight));
}

- (CGSize)intrinsicContentSize {
    return [self sizeThatFits:CGSizeMake(self.maximumWidth, CGFLOAT_MAX)];
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGSize fittedSize = [self sizeThatFits:self.bounds.size];
    CGFloat width = CGRectGetWidth(self.bounds) > 0.0 ? CGRectGetWidth(self.bounds) : fittedSize.width;
    CGFloat height = CGRectGetHeight(self.bounds) > 0.0 ? CGRectGetHeight(self.bounds) : fittedSize.height;
    CGFloat bubbleHeight = MAX(0.0, height - kBubbleTailHeight);
    CGFloat radius = MIN(self.cornerRadius, MIN(width, bubbleHeight) * 0.5);
    CGFloat borderWidth = MAX(0.0, self.bubbleBorderWidth);
    CGFloat inset = borderWidth * 0.5;
    CGFloat bodyBottom = bubbleHeight - inset;
    CGFloat centerX = width * 0.5;

    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(inset + radius, inset)];
    [path addLineToPoint:CGPointMake(width - inset - radius, inset)];
    [path addArcWithCenter:CGPointMake(width - inset - radius, inset + radius)
                    radius:radius
                startAngle:-M_PI_2
                  endAngle:0.0
                 clockwise:YES];
    [path addLineToPoint:CGPointMake(width - inset, bodyBottom - radius)];
    [path addArcWithCenter:CGPointMake(width - inset - radius, bodyBottom - radius)
                    radius:radius
                startAngle:0.0
                  endAngle:M_PI_2
                 clockwise:YES];
    [path addLineToPoint:CGPointMake(centerX + kBubbleTailHalfWidth, bodyBottom)];
    [path addLineToPoint:CGPointMake(centerX, height - inset)];
    [path addLineToPoint:CGPointMake(centerX - kBubbleTailHalfWidth, bodyBottom)];
    [path addLineToPoint:CGPointMake(inset + radius, bodyBottom)];
    [path addArcWithCenter:CGPointMake(inset + radius, bodyBottom - radius)
                    radius:radius
                startAngle:M_PI_2
                  endAngle:M_PI
                 clockwise:YES];
    [path addLineToPoint:CGPointMake(inset, inset + radius)];
    [path addArcWithCenter:CGPointMake(inset + radius, inset + radius)
                    radius:radius
                startAngle:M_PI
                  endAngle:M_PI * 1.5
                 clockwise:YES];
    [path closePath];

    _shapeLayer.path = path.CGPath;
    _shapeLayer.fillColor = self.bubbleBackgroundColor.CGColor;
    _shapeLayer.strokeColor = self.bubbleBorderColor.CGColor;
    _shapeLayer.lineWidth = borderWidth;

    CGFloat contentX = kBubbleHorizontalPadding;
    CGFloat contentWidth = MAX(0.0, width - kBubbleHorizontalPadding * 2.0);
    CGSize primarySize = [_primaryLabel sizeThatFits:CGSizeMake(contentWidth, CGFLOAT_MAX)];
    _primaryLabel.frame = CGRectMake(contentX, kBubbleTopPadding, contentWidth, ceil(primarySize.height));
    if (_secondaryLabel.hidden) {
        _secondaryLabel.frame = CGRectZero;
    } else {
        CGSize secondarySize = [_secondaryLabel sizeThatFits:CGSizeMake(contentWidth, CGFLOAT_MAX)];
        _secondaryLabel.frame = CGRectMake(contentX,
                                           CGRectGetMaxY(_primaryLabel.frame) + kBubbleContentSpacing,
                                           contentWidth,
                                           ceil(secondarySize.height));
    }
}

- (NSAttributedString *)attributedStringFromHTML:(NSString *)html {
    NSData *data = [html dataUsingEncoding:NSUTF8StringEncoding];
    if (!data) {
        return [[NSAttributedString alloc] initWithString:html];
    }

    NSDictionary *options = @{
        NSDocumentTypeDocumentAttribute : NSHTMLTextDocumentType,
        NSCharacterEncodingDocumentAttribute : @(NSUTF8StringEncoding),
    };
    NSMutableAttributedString *attributed =
        [[NSMutableAttributedString alloc] initWithData:data
                                                options:options
                                     documentAttributes:nil
                                                  error:nil];
    if (!attributed) {
        return [[NSAttributedString alloc] initWithString:html];
    }

    NSRange fullRange = NSMakeRange(0, attributed.length);
    [attributed addAttribute:NSFontAttributeName
                       value:[UIFont systemFontOfSize:14.0 weight:UIFontWeightSemibold]
                       range:fullRange];

    [attributed enumerateAttribute:NSFontAttributeName
                           inRange:fullRange
                           options:0
                        usingBlock:^(UIFont *font, NSRange range, BOOL *stop) {
        (void)stop;
        CGFloat pointSize = font ? MAX(13.0, font.pointSize) : 14.0;
        UIFontDescriptorSymbolicTraits traits = font.fontDescriptor.symbolicTraits;
        UIFontWeight weight = (traits & UIFontDescriptorTraitBold) ? UIFontWeightBold : UIFontWeightMedium;
        UIFont *resolvedFont = [UIFont systemFontOfSize:pointSize weight:weight];
        [attributed addAttribute:NSFontAttributeName value:resolvedFont range:range];
    }];

    [attributed enumerateAttribute:NSForegroundColorAttributeName
                           inRange:fullRange
                           options:0
                        usingBlock:^(UIColor *color, NSRange range, BOOL *stop) {
        (void)stop;
        if (!color || [self shouldUseDefaultWhiteTextColor:color]) {
            [attributed addAttribute:NSForegroundColorAttributeName value:UIColor.whiteColor range:range];
        }
    }];
    return attributed;
}

- (BOOL)shouldUseDefaultWhiteTextColor:(UIColor *)color {
    CGFloat red = 0.0;
    CGFloat green = 0.0;
    CGFloat blue = 0.0;
    CGFloat alpha = 0.0;
    if (![color getRed:&red green:&green blue:&blue alpha:&alpha]) {
        CGFloat white = 0.0;
        if ([color getWhite:&white alpha:&alpha]) {
            return white < 0.2;
        }
        return NO;
    }

    // HTML 默认文字通常会被解析成接近黑色，这里转成白色；
    // 显式配置的红色等高亮颜色则保留。
    return red < 0.2 && green < 0.2 && blue < 0.2;
}

@end

NSArray<MTCFloatInfoColorOption *> *MTCFloatInfoPresetColors(void) {
    static NSArray<MTCFloatInfoColorOption *> *options = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        options = @[
            [[MTCFloatInfoColorOption alloc] initWithTitle:@"#2F80ED" hexValue:@"#2F80ED"],
            [[MTCFloatInfoColorOption alloc] initWithTitle:@"#3A5EFB" hexValue:@"#3A5EFB"],
            [[MTCFloatInfoColorOption alloc] initWithTitle:@"#3F7BF9" hexValue:@"#3F7BF9"],
            [[MTCFloatInfoColorOption alloc] initWithTitle:@"#8CC8FF" hexValue:@"#8CC8FF"],
            [[MTCFloatInfoColorOption alloc] initWithTitle:@"#CFE1FF" hexValue:@"#CFE1FF"],
            [[MTCFloatInfoColorOption alloc] initWithTitle:@"#00A63E" hexValue:@"#00A63E"],
            [[MTCFloatInfoColorOption alloc] initWithTitle:@"#A5D6A7" hexValue:@"#A5D6A7"],
            [[MTCFloatInfoColorOption alloc] initWithTitle:@"#FF0000" hexValue:@"#FF0000"],
            [[MTCFloatInfoColorOption alloc] initWithTitle:@"#FF9800" hexValue:@"#FF9800"],
            [[MTCFloatInfoColorOption alloc] initWithTitle:@"#FFC107" hexValue:@"#FFC107"],
            [[MTCFloatInfoColorOption alloc] initWithTitle:@"#9C27B0" hexValue:@"#9C27B0"],
            [[MTCFloatInfoColorOption alloc] initWithTitle:@"#00BCD4" hexValue:@"#00BCD4"],
            [[MTCFloatInfoColorOption alloc] initWithTitle:@"#424242" hexValue:@"#424242"],
            [[MTCFloatInfoColorOption alloc] initWithTitle:@"#E0E0E0" hexValue:@"#E0E0E0"],
            [[MTCFloatInfoColorOption alloc] initWithTitle:@"#FFFFFF" hexValue:@"#FFFFFF"],
            [[MTCFloatInfoColorOption alloc] initWithTitle:@"#000000" hexValue:@"#000000"],
        ];
    });
    return options;
}

NSArray<NSString *> *MTCFloatInfoPresetColorTitles(void) {
    NSMutableArray<NSString *> *titles = [NSMutableArray array];
    for (MTCFloatInfoColorOption *option in MTCFloatInfoPresetColors()) {
        [titles addObject:option.title];
    }
    return titles.copy;
}

UIColor *MTCFloatInfoColorFromHexString(NSString *hexString, NSString *fallbackHex) {
    NSString *candidate = [[hexString ?: @"" stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] uppercaseString];
    if ([candidate hasPrefix:@"#"]) {
        candidate = [candidate substringFromIndex:1];
    }
    if (candidate.length != 6) {
        candidate = [fallbackHex stringByReplacingOccurrencesOfString:@"#" withString:@""];
    }

    unsigned int rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:candidate];
    if (![scanner scanHexInt:&rgbValue]) {
        scanner = [NSScanner scannerWithString:[fallbackHex stringByReplacingOccurrencesOfString:@"#" withString:@""]];
        [scanner scanHexInt:&rgbValue];
    }

    return [UIColor colorWithRed:((rgbValue >> 16) & 0xFF) / 255.0
                           green:((rgbValue >> 8) & 0xFF) / 255.0
                            blue:(rgbValue & 0xFF) / 255.0
                           alpha:1.0];
}
