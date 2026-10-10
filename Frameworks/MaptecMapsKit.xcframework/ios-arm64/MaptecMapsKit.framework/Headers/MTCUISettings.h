//
//  MTCUISettings.h
//  MaptecMaps
//
//  Created by ZHOUPanpan on 2026/6/23.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MaptecMapsKit/MTCMapTypes.h>

NS_ASSUME_NONNULL_BEGIN

/**
 `MTCMapView` 的统一 UI 配置对象。

 A unified built-in UI configuration object owned by `MTCMapView`.

 `MTCMapView` 在初始化时创建默认配置对象，并通过只读 `uiSettings` 属性暴露。直接修改该对象的属性会立即应用到地图视图的内建 UI 布局与显隐策略。
 `MTCMapView` creates a default settings object during initialization and exposes it through its read-only `uiSettings` property. Mutating these properties applies changes to the built-in map UI layout and visibility policy immediately.
 
 @note 除特别说明外，所有属性应在主线程访问和修改。
 Unless otherwise documented, access and mutate these properties on the main thread.
 */
@interface MTCUISettings : NSObject

/**
 地图内建 UI 的总开关。

 Master switch for built-in map UI elements.

 默认值为 `YES`。设置为 `NO` 时，缩放、指南针、比例尺、Logo 和日夜间模式控件都会被隐藏；重新开启后，各支持独立开关的控件会恢复之前的显隐状态。
 The default is `YES`. When set to `NO`, the zoom, compass, scale bar, logo, and day/night mode controls are hidden. When re-enabled, controls that support individual visibility flags restore their previous state.
 */
@property (nonatomic, assign, getter=isPermitShowAll) BOOL permitShowAll;

#pragma mark - 缩放控件

/**
 是否显示缩放按钮。

 Whether the built-in zoom buttons are shown.

 默认值为 `YES`。仅在 `permitShowAll` 为 `YES` 时生效。
 The default is `YES`. This only takes effect when `permitShowAll` is `YES`.
 */
@property (nonatomic, assign, getter=isZoomButtonsEnabled) BOOL zoomButtonsEnabled;

/**
 是否显示中间的缩放级别文字块。

 Whether the center zoom level tile is shown.

 默认值为 `NO`。仅在 `zoomButtonsEnabled` 与 `permitShowAll` 都为 `YES` 时可见。
 The default is `NO`. This is only visible when both `zoomButtonsEnabled` and `permitShowAll` are `YES`.
 */
@property (nonatomic, assign, getter=isZoomLevelVisible) BOOL zoomLevelVisible;
/**
 缩放控件位置。

 Position of the built-in zoom control.

 默认值为 `MTCUIPositionBottom | MTCUIPositionRight`。位置语义与 `compassGravity` 一致。
 The default is `MTCUIPositionBottom | MTCUIPositionRight`. Position semantics match `compassGravity`.
 */
@property (nonatomic, assign) MTCUIPosition zoomButtonsGravity;

/**
 缩放按钮四边距，单位为 point。

 Margins for the built-in zoom buttons, in points.

 默认四边均为 `4`。设置负值会被裁剪为 `0`。
 Each edge defaults to `4`. Negative values are clamped to `0`.
 */
@property (nonatomic, assign) UIEdgeInsets zoomButtonsMargins;

/**
 缩放按钮单个方块边长，单位为 point。

 Side length of each built-in zoom button tile, in points.

 默认值为 `32`，有效范围为 `[24, 60]`。设置非正数会回退到默认值。
 The default is `32`. The valid range is `[24, 60]`; non-positive values fall back to the default.
 */
@property (nonatomic, assign) CGFloat buttonSize;

/**
 缩放级别文字显示精度。

 Display precision for the zoom level tile.

 默认值为 `MTCZoomLevelPrecisionOneDecimal`，对应格式 `%.1f`。
 The default is `MTCZoomLevelPrecisionOneDecimal`, which maps to format `%.1f`.
 */
@property (nonatomic, assign) MTCZoomLevelPrecision zoomLevelFormat;

/**
 缩放级别文字块在缩放按钮组中的位置。

 Position of the zoom level tile inside the built-in zoom button group.

 默认值为 `MTCZoomLevelPositionMiddle`。
 The default is `MTCZoomLevelPositionMiddle`.
 */
@property (nonatomic, assign) MTCZoomLevelPosition zoomLevelPosition;

#pragma mark - 罗盘控件 compass
/**
 是否显示指南针。

 Whether the compass is shown.

 默认值为 `YES`。仅在 `permitShowAll` 为 `YES` 时生效。
 The default is `YES`. This only takes effect when `permitShowAll` is `YES`.
 */
@property (nonatomic, assign, getter=isCompassEnabled) BOOL compassEnabled;

/**
 罗盘朝向正北时是否自动隐藏。

 Whether the compass automatically hides when the map faces north.

 默认值为 `YES`。正北判断使用约 `1` 度容差，隐藏前会短暂等待并淡出。
 The default is `YES`. North detection uses about a `1` degree tolerance; the compass waits briefly and fades out before hiding.
 */
@property (nonatomic, assign, getter=isFadeCompassFacingNorth) BOOL fadeCompassFacingNorth;

/**
 指南针对齐位置。

 Alignment gravity for the built-in compass.

 默认值为 `MTCUIPositionTop | MTCUIPositionRight`。位置语义与 `zoomButtonsGravity`、`scaleBarGravity`、`logoGravity` 一致。
 The default is `MTCUIPositionTop | MTCUIPositionRight`. Position semantics match `zoomButtonsGravity`, `scaleBarGravity`, and `logoGravity`.
 */
@property (nonatomic, assign) MTCUIPosition compassGravity;

/**
 指南针四边距，单位为 point。

 Margins for the built-in compass, in points.

 默认四边均为 `4`。设置负值会被裁剪为 `0`。
 Each edge defaults to `4`. Negative values are clamped to `0`.
 */
@property (nonatomic, assign) UIEdgeInsets compassMargins;

/**
 指南针尺寸，单位为 point。

 Size of the built-in compass, in points.

 默认值为 `48 x 48`，宽高会归一为较小值，有效范围为 `[24, 120]`。
 The default is `48 x 48`; width and height are normalized to the smaller side. The valid range is `[24, 120]`.
 */
@property (nonatomic, assign) CGSize compassViewSize;

/**
 自定义指南针图片。

 Custom image for the built-in compass.

 默认值为 `nil`。设置为 `nil` 时回退到 SDK 内置指南针图片，并继续保留 2D/3D 默认图切换逻辑。
 The default is `nil`. Set this to `nil` to fall back to the SDK built-in compass image while keeping the default 2D/3D image switching behavior.
 */
@property (nonatomic, strong, nullable) UIImage *compassImage;

#pragma mark - 定位控件 location

/**
 是否显示定位控件。

 Whether the built-in location button is shown.

 默认值为 `NO`，开启后，点击控件会请求定位权限并将相机移动到最近一次定位结果。
 The default is `NO`. When enabled, tapping the button requests location permission and moves the camera to the latest location fix.
 */
@property (nonatomic, assign, getter=isLocationViewEnabled) BOOL locationViewEnabled;


/**
 定位控件位置。

 Position of the built-in location button.

 默认值为 `MTCUIPositionBottom | MTCUIPositionRight`。
 The default is `MTCUIPositionBottom | MTCUIPositionRight`.
 */
@property (nonatomic, assign) MTCUIPosition locationViewGravity;


/**
 定位控件边距，单位为 point。

 Margins for the built-in location button, in points.

 默认四边均为 `4`。设置负值会被裁剪为 `0`。
 Each edge defaults to `4`. Negative values are clamped to `0`.
 */
@property (nonatomic, assign) UIEdgeInsets locationViewMargins;



/**
 定位控件尺寸，单位为 point。

 Size of the built-in location button, in points.

 默认值为 `40 x 40`。设置非正数会回退到默认值；宽高会归一为较小值。
 The default is `40 x 40`. Non-positive values fall back to the default; width and height are normalized to the smaller side.
 */
@property (nonatomic, assign) CGSize locationViewSize;



#pragma mark - 徽标控件

/**
 品牌 Logo 控件位置。

 Position of the built-in brand logo.

 默认值为 `MTCUIPositionBottom | MTCUIPositionLeft`。
 The default is `MTCUIPositionBottom | MTCUIPositionLeft`.
 */
@property (nonatomic, assign) MTCUIPosition logoGravity;

/**
 品牌 Logo 控件边距，单位为 point。

 Margins for the built-in brand logo, in points.

 默认四边均为 `4`。设置负值会被裁剪为 `0`。
 Each edge defaults to `4`. Negative values are clamped to `0`.
 */
@property (nonatomic, assign) UIEdgeInsets logoMargins;

/**
 品牌 Logo 控件尺寸，单位为 point。

 Size of the built-in brand logo, in points.

 默认值为 `68 x 17`。设置非正数会回退到默认尺寸。
 The default is `68 x 17`. Non-positive values fall back to the default size.
 */
@property (nonatomic, assign) CGSize logoSize;

/**
 品牌 Logo 图片资源名。

 Image resource name used by the built-in brand logo.

 */
@property (nonatomic, copy) NSString *logoImageName;

#pragma mark - 显示模式 display mode

/**
 地图显示模式。

 Map display mode.

 默认值为 `MTCMapDisplayMode2D`。该属性影响内建 UI 对 2D/3D 状态的展示，不切换地图类型。
 The default is `MTCMapDisplayMode2D`. This property affects how built-in UI represents 2D/3D state and does not switch the map type.
 */
@property (nonatomic, assign) MTCMapDisplayMode mapDisplayMode;

#pragma mark - 比例尺控件 scale bar

/**
 是否显示比例尺控件。

 Whether the built-in scale bar is shown.

 默认值为 `NO`。仅在 `permitShowAll` 为 `YES` 时生效。
 The default is `NO`. This only takes effect when `permitShowAll` is `YES`.
 */
@property (nonatomic, assign, getter=isScaleBarEnabled) BOOL scaleBarEnabled;

/**
 比例尺控件位置。

 Position of the built-in scale bar.

 默认值为 `MTCUIPositionBottom | MTCUIPositionLeft`。位置语义与 `compassGravity` 一致。
 The default is `MTCUIPositionBottom | MTCUIPositionLeft`. Position semantics match `compassGravity`.
 */
@property (nonatomic, assign) MTCUIPosition scaleBarGravity;

/**
 比例尺控件边距，单位为 point。

 Margins for the built-in scale bar, in points.

 默认四边均为 `4`。设置负值会被裁剪为 `0`。
 Each edge defaults to `4`. Negative values are clamped to `0`.
 */
@property (nonatomic, assign) UIEdgeInsets scaleBarMargins;

/**
 比例尺最大宽度，单位为像素。

 Maximum scale bar width, in pixels.

 默认值为 `100`，有效范围为 `[50, 200]`。设置超出范围的值会被自动裁剪到有效区间。
 The default is `100`. The valid range is `[50, 200]`; values outside the range are clamped automatically.
 */
@property (nonatomic, assign) CGFloat scaleBarMaxWidth;

#pragma mark - 日夜间模式控件

/**
 是否显示日夜间模式切换控件。

 Whether the built-in day/night mode control is shown.

 默认值为 `NO`。仅在 `permitShowAll` 为 `YES` 时生效。
 The default is `NO`. This only takes effect when `permitShowAll` is `YES`.
 */
@property (nonatomic, assign, getter=isDayNightModeEnabled) BOOL dayNightModeEnabled;

/**
 日夜间模式控件位置。

 Position of the built-in day/night mode control.

 默认值为 `MTCUIPositionTop | MTCUIPositionLeft`。位置语义与 `compassGravity` 一致。
 The default is `MTCUIPositionTop | MTCUIPositionLeft`. Position semantics match `compassGravity`.
 */
@property (nonatomic, assign) MTCUIPosition dayNightModeGravity;

/**
 日夜间模式控件边距，单位为 point。

 Margins for the built-in day/night mode control, in points.

 默认四边均为 `4`。设置负值会被裁剪为 `0`。
 Each edge defaults to `4`. Negative values are clamped to `0`.
 */
@property (nonatomic, assign) UIEdgeInsets dayNightModeMargins;

#pragma mark - 车标控件

@end

NS_ASSUME_NONNULL_END
