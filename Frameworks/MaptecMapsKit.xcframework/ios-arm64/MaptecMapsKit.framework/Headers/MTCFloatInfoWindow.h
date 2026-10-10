//
//  MTCFloatInfoWindow.h
//  MaptecMaps
//
//  Created by ZHOUPanpan on 2026/7/8.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>
#import <MaptecMapsKit/MTCMapTypes.h>

NS_ASSUME_NONNULL_BEGIN

@class MTCFloatInfoWindow;
@class MTCMarker;

@protocol MTCFloatInfoWindowDelegate <NSObject>

@optional
- (void)floatWindowDidRequestPositionUpdate:(MTCFloatInfoWindow *)floatWindow;
- (void)floatWindowDidChangeContentView:(MTCFloatInfoWindow *)floatWindow;
- (void)floatWindowDidChangeVisibility:(MTCFloatInfoWindow *)floatWindow;
- (void)floatWindowDidRequestRemoval:(MTCFloatInfoWindow *)floatWindow;

@end
/**
 信息窗口关闭回调。

 Info window close callback.

 @param infoWindow 被关闭的信息窗口。The closed info window.
 */
typedef void (^MTCFloatInfoWindowCloseHandler)(MTCFloatInfoWindow *__nullable floatWindow);

NS_SWIFT_NAME(MTCFloatInfoWindowOptions)
@interface MTCFloatInfoWindowOptions : NSObject

/**
 地理坐标。

 The geographic coordinate.

 未绑定 marker 时必须为有效坐标。绑定 marker 时默认使用 marker 当前坐标。
 This must be valid when no marker is attached. When attached to a marker, the marker's current coordinate is used by default.
 */
@property (nonatomic) CLLocationCoordinate2D coordinate;

/**
 信息窗口内容视图。

 The info window content view.
 */
@property (nonatomic, strong, nullable) UIView *contentView;

/**
 锚点类型。

 The anchor identifier.

 默认值为 `MTCFloatInfoWindowAnchorBottom`。
 The default value is `MTCFloatInfoWindowAnchorBottom`.
 */
@property (nonatomic, assign) MTCFloatInfoWindowAnchor anchor;

/**
 相对锚点的额外偏移，单位为 point。

 Additional offset relative to the anchor, in points.

 默认值为 `CGPointZero`。
 The default value is `CGPointZero`.
 */
@property (nonatomic) CGPoint contentOffset;

/**
 点击或长按地图时是否自动关闭。

 Whether tapping or long-pressing the map closes the info window automatically.

 默认值为 `YES`。
 The default value is `YES`.
 */
@property (nonatomic) BOOL autoCloseOnMapTap;

/**
 是否可见。

 Whether the info window is visible.

 默认值为 `YES`。
 The default value is `YES`.
 */
@property (nonatomic, getter=isVisible) BOOL visible;

@end

/// 信息窗口
NS_SWIFT_NAME(MTCFloatInfoWindow)
@interface MTCFloatInfoWindow : NSObject

/**
 唯一标识。

 The unique identifier.
 */
@property (nonatomic, copy, readonly) NSString *identifier;

@property (nonatomic, strong, readonly) MTCFloatInfoWindowOptions *options;

/**
 若通过 marker 绑定创建，返回关联的 marker；否则为 `nil`。

 Returns the attached marker when created with marker binding; otherwise `nil`.
 */
@property (nonatomic, weak, readonly, nullable) MTCMarker *attachedMarker;

/**
 关闭回调。

 Close callback.

 当信息窗口被显式移除、因地图交互自动关闭、或因关联 marker 被移除而关闭时触发。
 Called when the info window is removed explicitly, auto-closed by map interaction, or closed because its attached marker is removed.
 */
@property (nonatomic, copy, nullable) MTCFloatInfoWindowCloseHandler closeHandler;

- (void)refreshViaOptions:(MTCFloatInfoWindowOptions *)anotherOptions;
/**
 从地图移除信息窗口。

 Removes the info window from the map.
 */
- (void)remove;

/**
 立即刷新屏幕位置。

 Immediately refreshes the on-screen position.
 */
- (void)updatePosition;

@end

NS_ASSUME_NONNULL_END
