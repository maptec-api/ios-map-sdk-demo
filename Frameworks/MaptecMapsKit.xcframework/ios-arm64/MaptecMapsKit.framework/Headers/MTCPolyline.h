#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>
#import <MaptecMapsKit/MTCOverlay.h>
#import <MaptecMapsKit/MTCPolylineStyle.h>

NS_ASSUME_NONNULL_BEGIN

/**
 地图折线覆盖物。

 A map polyline overlay.

 `MTCPolyline` 使用 `CLLocationCoordinate2D` 指针和数量表达有序经纬度点。SDK 在设置坐标时会深拷贝输入，因此调用方后续修改原始缓冲区不会影响已设置的折线，除非再次调用 `setCoordinates:count:`。
 `MTCPolyline` uses a `CLLocationCoordinate2D` pointer and count for ordered geographic coordinates. The SDK deep-copies coordinates when they are assigned, so later changes to the source buffer do not affect the polyline unless `setCoordinates:count:` is called again.
 */
NS_SWIFT_NAME(MTCPolyline)
@interface MTCPolyline : NSObject <MTCClickableOverlay, MTCDraggableOverlay>

/**
 使用坐标创建折线。

 Creates a polyline with coordinates.

 @param coordinates 折线坐标缓冲区。The polyline coordinate buffer.
 @param count 坐标数量。The number of coordinates.
 */
- (instancetype)initWithCoordinates:(const CLLocationCoordinate2D * _Nullable)coordinates
                              count:(NSUInteger)count NS_DESIGNATED_INITIALIZER;

/**
 使用空坐标创建折线。

 Creates a polyline with no coordinates.
 */
- (instancetype)init;

/**
 覆盖物唯一标识。

 The unique overlay identifier.
 */
@property (nonatomic, copy, readonly) NSString *identifier;

/**
 坐标数量。

 The number of coordinates.
 */
@property (nonatomic, readonly) NSUInteger coordinateCount;

/**
 设置折线坐标。

 Sets the polyline coordinates.

 SDK 会深拷贝传入坐标。`coordinates` 在 `count` 大于 0 时不能为 `NULL`，所有坐标必须有效。传入无效数据时方法返回 `NO`，并保留原有坐标。
 The SDK deep-copies the input coordinates. `coordinates` must not be `NULL` when `count` is greater than 0, and every coordinate must be valid. Invalid input returns `NO` and preserves the existing coordinates.

 @param coordinates 新的坐标缓冲区。The new coordinate buffer.
 @param count 坐标数量。The number of coordinates.
 @return 是否成功更新坐标。Whether the coordinates were updated.
 */
- (BOOL)setCoordinates:(const CLLocationCoordinate2D * _Nullable)coordinates
                 count:(NSUInteger)count;

/**
 读取指定索引处的坐标。

 Returns the coordinate at the specified index.

 @param index 坐标索引，必须小于 `coordinateCount`。The coordinate index, which must be less than `coordinateCount`.
 */
- (CLLocationCoordinate2D)coordinateAtIndex:(NSUInteger)index;

/**
 批量读取指定范围内的坐标。

 Reads coordinates in the specified range.

 @param buffer 接收坐标的缓冲区。The output buffer.
 @param range 要读取的坐标范围。The coordinate range to read.
 */
- (void)getCoordinates:(CLLocationCoordinate2D *)buffer
                 range:(NSRange)range;

/**
 是否闭合折线。

 Whether the polyline is closed.

 默认值为 `NO`。设为 `YES` 时 SDK 会首尾相连。
 The default value is `NO`. When set to `YES`, the SDK connects the last coordinate back to the first coordinate.
 */
@property (nonatomic, getter=isClosed) BOOL closed;

/**
 折线样式。

 The polyline style.

 设置时会复制传入对象。默认样式为蓝色实线。
 The assigned object is copied. The default style is a blue solid line.
 */
@property (nonatomic, copy) MTCPolylineStyle *style;

/**
 覆盖物是否可见。

 Whether the overlay is visible.
 */
@property (nonatomic, getter=isVisible) BOOL visible;

/**
 是否响应点击和长按。

 Whether the polyline responds to taps and long presses.

 默认值为 `YES`。为 `NO` 时，折线不触发 overlay 点击或长按回调。
 The default value is `YES`. When set to `NO`, the polyline does not trigger overlay tap or long-press callbacks.
 */
@property (nonatomic, getter=isClickable) BOOL clickable;

/**
 是否允许用户拖拽折线。

 Whether the polyline can be dragged by the user.

 默认值为 `NO`。为 `YES` 时，用户按住并拖动折线会由 SDK 自动整体平移该折线的所有坐标点，并触发 overlay 拖拽回调。该属性与 `clickable` 相互独立。
 The default value is `NO`. When set to `YES`, pressing and dragging the polyline causes the SDK to translate all of its coordinates as a whole and dispatch overlay drag callbacks. This property is independent from `clickable`.
 */
@property (nonatomic, getter=isDraggable) BOOL draggable;

/**
 覆盖物绘制层级。

 The overlay drawing order.
 */
@property (nonatomic) NSInteger zIndex;

/**
 业务自定义数据。

 App-specific user data.
 */
@property (nonatomic, strong, nullable) id userInfo;

@end

NS_ASSUME_NONNULL_END
