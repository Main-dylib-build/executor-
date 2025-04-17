#pragma once

// Include necessary standard headers
#include <cstdint>
#include <cstddef>

// Additional macros and utilities for CI compatibility

// Define a macro to check if we're in a CI environment
#if defined(CI_BUILD) || defined(SKIP_IOS_INTEGRATION)
    #define IN_CI_ENVIRONMENT 1
#else
    #define IN_CI_ENVIRONMENT 0
#endif

// Macro to conditionally include or exclude code in CI
#define CI_GUARD_BEGIN if (!IN_CI_ENVIRONMENT) {
#define CI_GUARD_END }

// Stubbed functions for CI
#if IN_CI_ENVIRONMENT
namespace Memory {
    // Memory functions that need to be stubbed in CI
    inline uintptr_t getLibBase(const char* name) {
        (void)name;
        return 0;
    }
    
    inline void* GetBaseAddress() {
        return nullptr;
    }
    
    inline bool IsAddressValid(void* addr) {
        (void)addr;
        return false;
    }
    
    inline bool IsAddressExecutable(void* addr) {
        (void)addr;
        return false;
    }
}
#endif
