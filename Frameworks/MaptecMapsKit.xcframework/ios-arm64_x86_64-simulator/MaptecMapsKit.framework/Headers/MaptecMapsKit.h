#import <Foundation/Foundation.h>

/**
 MaptecMapsKit 的运行时版本号。

 Runtime version string for MaptecMapsKit.

 该值来自 framework bundle 的 `CFBundleShortVersionString`，可用于运行时校验集成版本。
 This value comes from the framework bundle's `CFBundleShortVersionString` and can be used to verify the integrated SDK version at runtime.
 */
FOUNDATION_EXPORT NSString *MaptecMapsKitVersion(void);

#import <MaptecMapsKit/MTCGeometry.h>
#import <MaptecMapsKit/MTCPath.h>
#import <MaptecMapsKit/MTCMutablePath.h>
#import <MaptecMapsKit/MTCGeometryUtils.h>
#import <MaptecMapsKit/MTCMapCamera.h>
#import <MaptecMapsKit/MTCMapCameraConstraints.h>
#import <MaptecMapsKit/MTCMapTypes.h>
#import <MaptecMapsKit/MTCMapGestureSettings.h>
#import <MaptecMapsKit/MTCUISettings.h>
#import <MaptecMapsKit/MTCUserLocation.h>
#import <MaptecMapsKit/MTCUserLocationConfig.h>
#import <MaptecMapsKit/MTCSystemUserLocationConfig.h>
#import <MaptecMapsKit/MTCUserLocationProvider.h>
#import <MaptecMapsKit/MTCOverlay.h>
#import <MaptecMapsKit/MTCOverlayHit.h>
#import <MaptecMapsKit/MTCHollowShape.h>
#import <MaptecMapsKit/MTCLineStyle.h>
#import <MaptecMapsKit/MTCLineGradientStop.h>
#import <MaptecMapsKit/MTCLineGradient.h>
#import <MaptecMapsKit/MTCMarkerStyle.h>
#import <MaptecMapsKit/MTCMarkerAnimationOptions.h>
#import <MaptecMapsKit/MTCMarkerMovement.h>
#import <MaptecMapsKit/MTCMarker.h>

#import <MaptecMapsKit/MTCHeatmapColorStop.h>
#import <MaptecMapsKit/MTCHeatmapGradient.h>
#import <MaptecMapsKit/MTCHeatmapPoint.h>
#import <MaptecMapsKit/MTCHeatmapStyle.h>
#import <MaptecMapsKit/MTCHeatmap.h>

#import <MaptecMapsKit/MTCClusterPointStyle.h>
#import <MaptecMapsKit/MTCClusterPoint.h>
#import <MaptecMapsKit/MTCClusterStyle.h>
#import <MaptecMapsKit/MTCClusterStyleRule.h>
#import <MaptecMapsKit/MTCClusterHit.h>
#import <MaptecMapsKit/MTCCluster.h>

#import <MaptecMapsKit/MTCPOI.h>
#import <MaptecMapsKit/MTCFloatInfoWindow.h>
#import <MaptecMapsKit/MTCPolylineStyle.h>
#import <MaptecMapsKit/MTCPolyline.h>
#import <MaptecMapsKit/MTCPolygonStyle.h>
#import <MaptecMapsKit/MTCPolygon.h>
#import <MaptecMapsKit/MTCCircleStyle.h>
#import <MaptecMapsKit/MTCCircle.h>
#import <MaptecMapsKit/MTCMapView.h>
