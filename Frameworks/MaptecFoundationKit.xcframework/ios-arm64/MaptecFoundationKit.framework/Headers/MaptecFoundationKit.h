//
//  MaptecFoundationKit.h
//  MaptecFoundationKit
//
//  Created by Codex on 2026-07-17.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT double MaptecFoundationKitVersionNumber;
FOUNDATION_EXPORT const unsigned char MaptecFoundationKitVersionString[];

/**
 MaptecFoundationKit 的运行时版本号。

 Runtime version string for MaptecFoundationKit.

 该值来自 framework bundle 的 `CFBundleShortVersionString`，可用于运行时校验集成版本。
 This value comes from the framework bundle's `CFBundleShortVersionString` and can be used to verify the integrated SDK version at runtime.
 */
FOUNDATION_EXPORT NSString *MaptecFoundationKitVersion(void);

#import <MaptecFoundationKit/MTCMapServices.h>
