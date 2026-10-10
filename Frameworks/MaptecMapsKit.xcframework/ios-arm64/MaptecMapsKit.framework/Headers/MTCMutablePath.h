#import <MaptecMapsKit/MTCPath.h>

NS_ASSUME_NONNULL_BEGIN

/**
 可变经纬度路径。

 A mutable geographic path.

 `MTCMutablePath` 提供对 `MTCPath` 的追加、插入、替换和删除能力，适合逐点构建路径或在编辑器中动态修改路径。
 `MTCMutablePath` adds append, insert, replace, and remove operations on top of `MTCPath`, and is suitable for building or editing paths incrementally.
 */
NS_SWIFT_NAME(MTCMutablePath)
@interface MTCMutablePath : MTCPath

/**
 追加一个坐标。

 Appends one coordinate.

 @param coordinate 要追加的坐标。The coordinate to append.
 */
- (void)addCoordinate:(CLLocationCoordinate2D)coordinate;

/**
 在指定索引插入一个坐标。

 Inserts one coordinate at the specified index.

 @param coordinate 要插入的坐标。The coordinate to insert.
 @param index 插入位置，取值范围为 `0...count`。The insertion index, in the range `0...count`.
 */
- (void)insertCoordinate:(CLLocationCoordinate2D)coordinate atIndex:(NSUInteger)index;

/**
 替换指定索引处的坐标。

 Replaces the coordinate at the specified index.

 @param coordinate 新坐标。The new coordinate.
 @param index 要替换的索引，必须小于 `count`。The index to replace, which must be less than `count`.
 */
- (void)replaceCoordinateAtIndex:(NSUInteger)index
                  withCoordinate:(CLLocationCoordinate2D)coordinate;

/**
 移除指定索引处的坐标。

 Removes the coordinate at the specified index.

 @param index 要移除的索引，必须小于 `count`。The index to remove, which must be less than `count`.
 */
- (void)removeCoordinateAtIndex:(NSUInteger)index;

/**
 移除全部坐标。

 Removes all coordinates.
 */
- (void)removeAllCoordinates;

@end

NS_ASSUME_NONNULL_END
