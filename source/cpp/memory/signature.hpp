#pragma once

#include "ci_compat.h"  // Include our CI compatibility header

#include <string>
#include <vector>
#include <cstdint>  // Explicitly include for uintptr_t
#include <memory>
#include <algorithm>

namespace Memory {
    // Signature scanning utility functions
    namespace Signature {
        // FindPattern function - takes a base address, size, and pattern to search for
        static uintptr_t FindPattern(uintptr_t baseAddress, size_t size, const char* pattern) {
            #ifdef CI_BUILD
                // In CI builds, just return 0 to avoid any actual memory access
                return 0;
            #else
                std::vector<uint8_t> bytes;
                std::vector<bool> mask;
                
                // Convert pattern string to bytes and mask
                for (size_t i = 0; pattern[i]; i++) {
                    // Skip spaces
                    if (pattern[i] == ' ') continue;
                    
                    // Check for wildcard
                    if (pattern[i] == '?' && pattern[i+1] == '?') {
                        bytes.push_back(0);
                        mask.push_back(false);
                        i++; // Skip the second '?'
                        continue;
                    }
                    
                    // Parse hex value
                    char hex[3] = {pattern[i], pattern[i+1], 0};
                    bytes.push_back(static_cast<uint8_t>(strtol(hex, nullptr, 16)));
                    mask.push_back(true);
                    i++; // Skip the second character of the hex byte
                }
                
                // Search memory for pattern
                for (uintptr_t addr = baseAddress; addr < baseAddress + size - bytes.size(); addr++) {
                    bool found = true;
                    
                    for (size_t i = 0; i < bytes.size(); i++) {
                        if (mask[i] && *(uint8_t*)(addr + i) != bytes[i]) {
                            found = false;
                            break;
                        }
                    }
                    
                    if (found) return addr;
                }
                
                return 0;
            #endif
        }

        // Get Roblox function address by pattern
        static uintptr_t GetAddressByPattern(const char* pattern) {
            #ifdef CI_BUILD
                // In CI builds, just return 0 to avoid any actual memory access
                return 0;
            #else
                // Get Roblox module info - getLibBase is provided by the platform-specific implementation
                uintptr_t base = getLibBase("libroblox.so");
                if (!base) return 0;
                
                // Approximate module size - in real implementation, should get actual size
                // This is a placeholder. In a full implementation, you'd get the actual module size
                constexpr size_t ESTIMATED_MODULE_SIZE = 50 * 1024 * 1024; // 50MB estimate
                
                // Find pattern
                return FindPattern(base, ESTIMATED_MODULE_SIZE, pattern);
            #endif
        }
        
        // Get a relative address (used for x86_64 RIP-relative addressing)
        static uintptr_t GetRelativeAddress(uintptr_t address, int offset, int instructionSize) {
            #ifdef CI_BUILD
                return 0;
            #else
                return *reinterpret_cast<int*>(address + offset) + address + instructionSize;
            #endif
        }
    };

    // Known patterns for Roblox functions (these would need to be updated and tested)
    namespace Patterns {
        // These are example patterns - you would need to analyze Roblox binary to find actual patterns
        constexpr const char* STARTSCRIPT = "55 8B EC 83 E4 F8 83 EC 18 56 8B 75 08 85 F6 74 ?? 57";
        constexpr const char* GETSTATE = "55 8B EC 56 8B 75 0C 83 FE 08 77 ?? 8B 45 08";
        constexpr const char* NEWTHREAD = "55 8B EC 56 8B 75 08 8B 46 ?? 83 F8 ?? 0F 8C ?? ?? ?? ??";
        constexpr const char* LUAULOAD = "55 8B EC 83 EC ?? 53 56 8B 75 08 8B 46 ?? 83 F8 ?? 0F 8C";
        constexpr const char* SPAWN = "55 8B EC 83 EC ?? 56 8B 75 08 8B 46 ?? 83 F8 ?? 0F 8C";
    }
}
