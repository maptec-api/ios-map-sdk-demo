//
//  MTCPolylineRouteRenderer.h
//  MaptecMapsExample
//
//  Created by ZHOUPanpan+ on 2026/8/3.
//  Copyright © 2026 ZHOUPanpan+. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MTCMapRouteRendering.h"

NS_ASSUME_NONNULL_BEGIN

/// 基于 MTCPolyline、MTCMarker 和相机 Public API 的路线预览 Renderer。
@interface MTCPolylineRouteRenderer : NSObject <MTCMapRouteRendering>

- (instancetype)initWithMapView:(MTCMapView *)mapView
                 displayOptions:(nullable MTCRouteDisplayOptions *)displayOptions;

@end

NS_ASSUME_NONNULL_END
