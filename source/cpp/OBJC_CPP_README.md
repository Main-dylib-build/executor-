# Objective-C++ Interoperability 

This document describes how C++ and Objective-C interoperability is handled in this project.

## Key Files

1. **utility.h** - Pure C++ macros and utilities that can be used anywhere without Objective-C dependencies
2. **objc_isolation.h** - Interface layer between C++ and Objective-C that properly guards Objective-C syntax
3. **include_guard.h** - Central include file that brings in the right headers based on the compilation context

## How It Works

### For C++ Files
- Include `utility.h` for basic macros (UNUSED_PARAM, etc.)
- Include `include_guard.h` if you need platform-specific features
- Use the SKIP_IOS_INTEGRATION define to prevent Objective-C includes in C++ context

### For Objective-C++ (.mm) Files
- Can directly include Objective-C headers and use Objective-C syntax
- Include `objc_isolation.h` to interact with C++ code
- Compile with `-x objective-c++` flag

## CMake Configuration

- C++ files that need to interact with Objective-C should include `utility.h` or `include_guard.h` rather than including Objective-C headers directly
- Objective-C classes are forward-declared for C++ files as opaque types
- Special compile flags are set for specific files based on their content

## Tips for Maintaining Compatibility

1. Don't include UIKit or Foundation directly in C++ files
2. Use the UNUSED_PARAM macro for unused parameters
3. Always properly guard platform-specific code with `#ifdef __APPLE__`
4. Add the SKIP_IOS_INTEGRATION define when compiling C++ files that shouldn't try to include Objective-C
