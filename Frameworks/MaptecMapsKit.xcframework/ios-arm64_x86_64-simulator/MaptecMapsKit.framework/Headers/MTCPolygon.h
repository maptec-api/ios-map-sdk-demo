#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>
#import <MaptecMapsKit/MTCHollowShape.h>
#import <MaptecMapsKit/MTCOverlay.h>
#import <MaptecMapsKit/MTCPolygonStyle.h>

NS_ASSUME_NONNULL_BEGIN

/**
 地图多边形覆盖物。

 A map polygon overlay.

 `MTCPolygon` 使用一个外环表达面边界，并通过 `MTCHollowShape` 管理可选中空区域。SDK 在设置坐标时会深拷贝输入，因此调用方后续修改原始缓冲区不会影响已设置的多边形，除非再次调用 `setCoordinates:count:`。
 `MTCPolygon` uses one outer ring for the area boundary and manages optional hollow areas with `MTCHollowShape`. The SDK deep-copies coordinates when they are assigned, so later changes to the source buffer do not affect the polygon unless `setCoordinates:count:` is called again.
 */
NS_SWIFT_NAME(MTCPolygon)
@interface MTCPolygon : NSObject <MTCClickableOverlay, MTCDraggableOverlay>

/**
 使用外环坐标创建多边形。

 Creates a polygon with outer-ring coordinates.

 @param coordinates 多边形外环坐标缓冲区。The polygon outer-ring coordinate buffer.
 @param count 坐标数量。The number of coordinates.
 */
- (instancetype)initWithCoordinates:(const CLLocationCoordinate2D * _Nullable)coordinates
                              count:(NSUInteger)count NS_DESIGNATED_INITIALIZER;

/**
 使用空坐标创建多边形。

 Creates a polygon with no coordinates.
 */
- (instancetype)init;

/**
 覆盖物唯一标识。

 The unique overlay identifier.
 */
@property (nonatomic, copy, readonly) NSString *identifier;

/**
 外环坐标数量。

 The number of coordinates in the outer ring.
 */
@property (nonatomic, readonly) NSUInteger outerRingCoordinateCount;

/**
 设置多边形外环坐标。

 Sets the polygon outer-ring coordinates.

 SDK 会深拷贝传入坐标。`coordinates` 在 `count` 大于 0 时不能为 `NULL`，外环至少需要 3 个有效坐标且不能自相交。更新成功后会清除已有中空形状；传入无效数据时方法返回 `NO`，并保留原有外环和中空形状。
 The SDK deep-copies the input coordinates. `coordinates` must not be `NULL` when `count` is greater than 0, and the outer ring needs at least 3 valid, non-self-intersecting coordinates. A successful update clears existing hollow shapes; invalid input returns `NO` and preserves the existing outer ring and hollow shapes.

 @param coordinates 新的外环坐标缓冲区。The new outer-ring coordinate buffer.
 @param count 坐标数量。The number of coordinates.
 @return 是否成功更新坐标。Whether the coordinates were updated.
 */
- (BOOL)setCoordinates:(const CLLocationCoordinate2D * _Nullable)coordinates
                 count:(NSUInteger)count;

/**
 读取外环指定索引处的坐标。

 Returns the outer-ring coordinate at the specified index.

 @param index 外环坐标索引，必须小于 `outerRingCoordinateCount`。The outer-ring coordinate index, which must be less than `outerRingCoordinateCount`.
 */
- (CLLocationCoordinate2D)outerRingCoordinateAtIndex:(NSUInteger)index;

/**
 批量读取外环指定范围内的坐标。

 Reads outer-ring coordinates in the specified range.

 @param buffer 接收坐标的缓冲区。The output buffer.
 @param range 要读取的坐标范围。The coordinate range to read.
 */
- (void)getOuterRingCoordinates:(CLLocationCoordinate2D *)buffer
                          range:(NSRange)range;

/**
 中空形状列表。

 The hollow shapes.

 返回数组为不可变快照。调用 `setCoordinates:count:` 成功更新外环后，已有中空形状会被清除。
 The returned array is an immutable snapshot. Existing hollow shapes are cleared after a successful `setCoordinates:count:` outer-ring update.
 */
@property (nonatomic, copy, readonly) NSArray<MTCHollowShape *> *hollowShapes;

/**
 添加中空形状。

 Adds a hollow shape.

 SDK 会在方法开始时校验形状。如果校验失败，不会修改已有中空形状，也不会触发渲染同步。支持多次添加中空形状，但不支持与外环相交、位于外环外部、与已有中空形状相交或嵌套的形状。
 The SDK validates the shape at the start of this method. If validation fails, existing hollow shapes are not modified and render synchronization is not triggered. Multiple hollow shapes are supported, but shapes intersecting the outer ring, outside the outer ring, intersecting existing hollows, or nested with existing hollows are not supported.

 @param hollowShape 要添加的中空形状。The hollow shape to add.
 @return 添加结果。The add result.
 */
- (MTCHollowShapeAddResult)addHollowShape:(MTCHollowShape *)hollowShape;

/**
 移除中空形状。

 Removes a hollow shape.

 只按对象 identity 匹配，不按几何内容匹配。
 Matching uses object identity only, not geometric equality.

 @param hollowShape 要移除的中空形状。The hollow shape to remove.
 @return 是否找到并移除了该对象。Whether the object was found and removed.
 */
- (BOOL)removeHollowShape:(MTCHollowShape *)hollowShape;

/**
 移除全部中空形状。

 Removes all hollow shapes.
 */
- (void)removeAllHollowShapes;

/**
 多边形样式。

 The polygon style.

 设置时会复制传入对象。默认样式为半透明蓝色填充和蓝色实线边框。
 The assigned object is copied. The default style is a translucent blue fill with a blue solid stroke.
 */
@property (nonatomic, copy) MTCPolygonStyle *style;

/**
覆盖物是否可见。

Whether the overlay is visible.
*/
@property (nonatomic, getter=isVisible) BOOL visible;

/**
 是否响应点击和长按。

 Whether the polygon responds to taps and long presses.

 默认值为 `YES`。为 `NO` 时，多边形不触发 overlay 点击或长按回调。
 The default value is `YES`. When set to `NO`, the polygon does not trigger overlay tap or long-press callbacks.
 */
@property (nonatomic, getter=isClickable) BOOL clickable;

/**
是否允许用户拖拽多边形。

Whether the polygon can be dragged by the user.

默认值为 `NO`。为 `YES` 时，用户按住并拖动多边形会由 SDK 自动整体平移外环和全部中空区域，并触发 overlay 拖拽回调。该属性与 `clickable` 相互独立。
The default value is `NO`. When set to `YES`, pressing and dragging the polygon causes the SDK to translate its outer ring and all hollow areas as a whole and dispatch overlay drag callbacks. This property is independent from `clickable`.
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
