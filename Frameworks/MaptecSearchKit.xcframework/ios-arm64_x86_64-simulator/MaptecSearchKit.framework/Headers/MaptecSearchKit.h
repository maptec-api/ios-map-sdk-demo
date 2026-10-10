//
//  MaptecSearchKit.h
//  MaptecSearchKit
//
//  Created by Codex on 2026-07-17.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT double MaptecSearchKitVersionNumber;
FOUNDATION_EXPORT const unsigned char MaptecSearchKitVersionString[];

/**
 MaptecSearchKit 的运行时版本号。

 Runtime version string for MaptecSearchKit.

 该值来自 framework bundle 的 `CFBundleShortVersionString`，可用于运行时校验集成版本。
 This value comes from the framework bundle's `CFBundleShortVersionString` and can be used to verify the integrated SDK version at runtime.
 */
FOUNDATION_EXPORT NSString *MaptecSearchKitVersion(void);

#import <MaptecSearchKit/MTCSearchTypes.h>
#import <MaptecSearchKit/MTCSearchError.h>
#import <MaptecSearchKit/MTCSearchServiceConfiguration.h>
#import <MaptecSearchKit/MTCSearchRequest.h>
#import <MaptecSearchKit/MTCSearchResponse.h>
#import <MaptecSearchKit/MTCSearchService.h>
#import <MaptecSearchKit/MTCGeocodeService.h>
#import <MaptecSearchKit/MTCRouteRequest.h>
#import <MaptecSearchKit/MTCRouteResponse.h>
#import <MaptecSearchKit/MTCRouteService.h>
