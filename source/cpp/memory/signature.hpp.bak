#pragma once

#include <vector>
#include <string>
#include <cstdint>
#include <memory>
#include <algorithm>
#include "mem.hpp"

namespace Memory {

    // Pattern scanning utilities
    class PatternScanner {
    public:
        // Convert a pattern string like "48 8B 05 ?? ?? ?? ??" to bytes vector
        static std::vector<uint8_t> PatternToBytes(const char* pattern) {
            std::vector<uint8_t> bytes;
            char* start = const_cast<char*>(pattern);
            char* end = start + strlen(pattern);

            for (char* current = start; current < end; ++current) {
                if (*current == '?') {
                    // Skip wildcard and add a placeholder
                    bytes.push_back(0);
                    if (*(current + 1) == '?') current++; // Skip if double wildcard
                } else if (*current == ' ') {
                    // Skip spaces
                    continue;
                } else {
                    // Read a hex byte
                    char byte[3] = { current[0], current[1], 0 };
                    bytes.push_back(static_cast<uint8_t>(strtol(byte, nullptr, 16)));
                    current++;
                }
            }
            return bytes;
        }

        // Scan a memory region for a pattern
        static uintptr_t FindPattern(uintptr_t moduleBase, size_t moduleSize, const char* pattern) {
            auto patternBytes = PatternToBytes(pattern);
            auto moduleEnd = moduleBase + moduleSize - patternBytes.size();
            
            for (auto addr = moduleBase; addr < moduleEnd; addr++) {
                bool found = true;
                
                for (size_t i = 0; i < patternBytes.size(); i++) {
                    // If current pattern byte is 0, it's a wildcard - skip comparison
                    if (patternBytes[i] != 0 && *reinterpret_cast<uint8_t*>(addr + i) != patternBytes[i]) {
                        found = false;
                        break;
                    }
                }
                
                if (found) return addr;
            }
            
            return 0;
        }

        // Get Roblox function address by pattern
        static uintptr_t GetAddressByPattern(const char* pattern) {
            // Get Roblox module info
            uintptr_t base = getLibBase("libroblox.so");
            if (!base) return 0;
            
            // Approximate module size - in real implementation, should get actual size
            // This is a placeholder. In a full implementation, you'd get the actual module size
            constexpr size_t ESTIMATED_MODULE_SIZE = 50 * 1024 * 1024; // 50MB estimate
            
            // Find pattern
            return FindPattern(base, ESTIMATED_MODULE_SIZE, pattern);
        }
        
        // Get a relative address (used for x86_64 RIP-relative addressing)
        static uintptr_t GetRelativeAddress(uintptr_t address, int offset, int instructionSize) {
            return *reinterpret_cast<int*>(address + offset) + address + instructionSize;
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
