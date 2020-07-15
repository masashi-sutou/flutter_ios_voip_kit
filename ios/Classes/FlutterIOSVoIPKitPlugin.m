#import "FlutterIOSVoIPKitPlugin.h"
#if __has_include(<flutter_ios_voip_kit/flutter_ios_voip_kit-Swift.h>)
#import <flutter_ios_voip_kit/flutter_ios_voip_kit-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "flutter_ios_voip_kit-Swift.h"
#endif

@implementation FlutterIOSVoIPKitPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterIOSVoIPKitPlugin registerWithRegistrar:registrar];
}
@end
