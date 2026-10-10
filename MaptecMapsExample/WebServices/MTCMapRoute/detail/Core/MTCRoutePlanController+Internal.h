//
//  MTCRoutePlanController+Internal.h
//  MaptecMapsExample
//
//  Created by ZHOUPanpan+ on 2026/8/3.
//  Copyright © 2026 ZHOUPanpan+. All rights reserved.
//

#import "MTCRoutePlanController.h"
#import "MTCRoutePlanningService.h"

NS_ASSUME_NONNULL_BEGIN

@interface MTCRoutePlanController ()

- (instancetype)initWithMapView:(MTCMapView *)mapView
                    routeService:(id<MTCRoutePlanningService>)routeService
                  displayOptions:(nullable MTCRouteDisplayOptions *)displayOptions;

@end

NS_ASSUME_NONNULL_END
