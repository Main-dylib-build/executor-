// objc_isolation.h - Isolation layer for Objective-C and C++ interoperability
#pragma once

// Standard library includes
#include <string>
#include <vector>
#include <map>

// Include iOS compatibility header first
#include "ios_compat.h"

// Base headers for Objective-C interactions
#ifdef __APPLE__
#import <Foundation/Foundation.h>

// Hide Objective-C in C++ context
#ifdef __cplusplus
// Forward declarations of Objective-C classes to avoid including full headers in C++ code
@class UIView;
@class UIWindow;
@class UIButton;
@class UIViewController;
@class UIApplication;
@class UIControl;
@class UILabel;
@class UITextField;
@class UITextView;
@class UITableView;
@class UIScrollView;
@class UIImage;
@class UIImageView;
@class UIColor;
@class UIFont;
@class UIGestureRecognizer;
@class UIAlertController;
@class UIAlertAction;
@class UIActivityIndicatorView;
@class UISwitch;
@class CALayer;
@class NSString;
@class NSArray;
@class NSMutableArray;
@class NSDictionary;
@class NSMutableDictionary;
@class NSData;
@class NSMutableData;
@class NSNumber;
@class NSObject;
@class NSError;
@class NSTimer;
@class NSThread;
@class NSDate;
@class NSURLSession;
@class NSURLSessionDataTask;
@class NSURLRequest;
@class NSMutableURLRequest;
@class NSUserDefaults;
@class NSNotificationCenter;
@class NSCache;
@class NSFileManager;
@class NSBundle;
@class NSRunLoop;

// Helper functions to convert between C++ and Objective-C types
namespace ObjCBridge {
    // String conversion
    NSString* CPPStringToNSString(const std::string& str);
    std::string NSStringToCPPString(NSString* str);
    
    // Arrays
    NSArray* CPPVectorToNSArray(const std::vector<std::string>& vec);
    std::vector<std::string> NSArrayToCPPVector(NSArray* array);
    
    // Dictionaries
    NSDictionary* CPPMapToNSDictionary(const std::map<std::string, std::string>& map);
    std::map<std::string, std::string> NSDictionaryToCPPMap(NSDictionary* dict);
    
    // Opaque pointer wrapper for Objective-C objects to be used in C++ code
    class ObjCWrapper {
    private:
        void* m_object;
        
    public:
        ObjCWrapper() : m_object(nullptr) {}
        ObjCWrapper(void* obj) : m_object(obj) {}
        
        void* get() const { return m_object; }
        void set(void* obj) { m_object = obj; }
        
        bool isValid() const { return m_object != nullptr; }
        void release();
    };
}

// Implementation of inline functions
inline NSString* ObjCBridge::CPPStringToNSString(const std::string& str) {
    return [NSString stringWithUTF8String:str.c_str()];
}

inline std::string ObjCBridge::NSStringToCPPString(NSString* str) {
    return str ? [str UTF8String] : "";
}

inline void ObjCBridge::ObjCWrapper::release() {
    if (m_object) {
        #if __has_feature(objc_arc)
        // In ARC mode, we use CFBridgingRelease for proper memory management
        // The cast is safe because we're releasing our ownership
        CFRelease(m_object);
        #else
        // In non-ARC mode, we can call release directly
        [(NSObject*)m_object release];
        #endif
        m_object = nullptr;
    }
}

// Macro to safely bridge between C++ and Objective-C
#if __has_feature(objc_arc)
// ARC-specific bridging macros
#define OBJC_BRIDGE(objctype, cppvar) ((__bridge objctype*)(cppvar.get()))
#define OBJC_BRIDGE_CONST(objctype, cppvar) ((__bridge objctype*)(cppvar.get()))
#define CPP_BRIDGE(cppvar, objcvar) ((cppvar).set((__bridge void*)(objcvar)))
#define CPP_BRIDGE_TRANSFER(cppvar, objcvar) ((cppvar).set(CFBridgingRetain(objcvar)))
#else
// Non-ARC bridging macros
#define OBJC_BRIDGE(objctype, cppvar) ((__bridge objctype*)(cppvar.get()))
#define OBJC_BRIDGE_CONST(objctype, cppvar) ((__bridge objctype*)(cppvar.get()))
#define CPP_BRIDGE(cppvar, objcvar) ((cppvar).set((__bridge_retained void*)(objcvar)))
#define CPP_BRIDGE_TRANSFER(cppvar, objcvar) ((cppvar).set((__bridge_transfer void*)(objcvar)))
#endif

#endif // __cplusplus
#endif // __APPLE__

// Define common constants and interfaces that can be used in both C++ and Objective-C
#ifdef __cplusplus
extern "C" {
#endif

// Error codes
typedef enum {
    kErrorNone = 0,
    kErrorGeneric = -1,
    kErrorInvalidArgument = -2,
    kErrorMemoryAllocation = -3,
    kErrorNotImplemented = -4,
    kErrorNotSupported = -5,
    kErrorPermissionDenied = -6,
    kErrorTimeout = -7,
    kErrorNotFound = -8,
    kErrorAlreadyExists = -9,
    kErrorNetworkFailure = -10
} ErrorCode;

// Platform detection (using a unique name to avoid conflicts with system headers)
#ifdef __APPLE__
    #define EXECUTOR_PLATFORM_IOS 1
#else
    #define EXECUTOR_PLATFORM_IOS 0
#endif

// Common function prototypes for platform abstraction
typedef void (*CallbackFunc)(void* context, int status, const char* message);

#ifdef __cplusplus
}
#endif

// Include platform-specific headers when not in Objective-C++ mode
#if !defined(__OBJC__) && defined(__APPLE__)
    // Include minimal C declarations for iOS functions without requiring Objective-C
    #ifdef __cplusplus
    extern "C" {
    #endif
        // Declare minimal iOS functions we might need to call from C++
        int UIApplicationMain(int argc, char* argv[], void* principalClassName, void* delegateClassName);
        void* UIGraphicsGetCurrentContext(void);
        void UIGraphicsPushContext(void* context);
        void UIGraphicsPopContext(void);
        void UIGraphicsBeginImageContext(struct CGSize size);
        void* UIGraphicsGetImageFromCurrentImageContext(void);
        void UIGraphicsEndImageContext(void);
    #ifdef __cplusplus
    }
    #endif
#endif
