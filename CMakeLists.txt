# Root CMakeLists.txt for iOS Roblox Executor
cmake_minimum_required(VERSION 3.16)
project(roblox_executor VERSION 1.0.0 LANGUAGES C CXX)

# Configure CMake
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# Default to Release build
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
endif()

# Set output directories
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

# Add cmake modules directory
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

# Options
option(USE_DOBBY "Use Dobby for hooking" ON)
option(USE_LUAU "Use Luau (Roblox's Lua) instead of standard Lua" ON)
option(ENABLE_AI_FEATURES "Enable AI features" ON)
option(ENABLE_ADVANCED_BYPASS "Enable advanced bypass features" ON)
option(BUILD_TESTING "Build tests" OFF)
option(BUILD_DOCS "Build documentation" OFF)

# Path to the Luau source files (the VM folder directly)
set(LUAU_ROOT "${CMAKE_SOURCE_DIR}/external/luau" CACHE PATH "Root directory of Luau source code")
set(LUAU_VM_DIR "${LUAU_ROOT}/VM" CACHE PATH "Directory containing Luau VM source code")

# Platform-specific settings
if(APPLE)
    # iOS-specific settings
    set(CMAKE_OSX_DEPLOYMENT_TARGET "15.0" CACHE STRING "Minimum iOS version")
    set(IOS_TARGET TRUE)
    add_definitions(-DIOS_TARGET=1)
    add_definitions(-D__APPLE__=1)
    
    if(NOT CMAKE_SYSTEM_NAME OR CMAKE_SYSTEM_NAME MATCHES "iOS")
        set(CMAKE_SYSTEM_NAME "iOS")
        set(CMAKE_XCODE_ATTRIBUTE_ONLY_ACTIVE_ARCH NO)
        
        # Set architectures to build
        if(NOT CMAKE_OSX_ARCHITECTURES)
            set(CMAKE_OSX_ARCHITECTURES "arm64" CACHE STRING "Build architectures for iOS")
        endif()
        
        # Skip code signing
        set(CMAKE_XCODE_ATTRIBUTE_CODE_SIGNING_REQUIRED NO)
        set(CMAKE_XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY "")
    endif()
    
    # Add platform-specific flags
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fobjc-arc")
    
    # Required frameworks for iOS
    find_library(FOUNDATION_FRAMEWORK Foundation REQUIRED)
    find_library(UIKIT_FRAMEWORK UIKit REQUIRED)
    find_library(SECURITY_FRAMEWORK Security REQUIRED)
    find_library(COREDATA_FRAMEWORK CoreData REQUIRED)
    
    set(IOS_FRAMEWORKS
        ${FOUNDATION_FRAMEWORK}
        ${UIKIT_FRAMEWORK}
        ${SECURITY_FRAMEWORK}
        ${COREDATA_FRAMEWORK}
    )
endif()

# Find and setup Dobby
if(USE_DOBBY)
    find_package(Dobby REQUIRED)
    add_definitions(-DUSE_DOBBY=1)
endif()

# Build Luau directly from source files
message(STATUS "Using Luau source files from ${LUAU_VM_DIR}")

# Check if VM directory exists
if(NOT EXISTS "${LUAU_VM_DIR}")
    message(FATAL_ERROR "Luau VM directory not found at ${LUAU_VM_DIR}. Please set LUAU_VM_DIR to the VM folder.")
endif()

# Check for include directory and key header file
set(LUAU_INCLUDE_DIR "${LUAU_VM_DIR}/include")
if(NOT EXISTS "${LUAU_INCLUDE_DIR}/lua.h")
    message(FATAL_ERROR "Luau header files not found at ${LUAU_INCLUDE_DIR}. Expected lua.h in this directory.")
endif()

# Check for source files
set(LUAU_SRC_DIR "${LUAU_VM_DIR}/src")
if(NOT EXISTS "${LUAU_SRC_DIR}/lapi.cpp")
    message(FATAL_ERROR "Luau source files not found at ${LUAU_SRC_DIR}. Expected lapi.cpp and other files in this directory.")
endif()

# Define the Luau VM source files directly
file(GLOB LUAU_VM_SOURCES "${LUAU_SRC_DIR}/*.cpp")
list(LENGTH LUAU_VM_SOURCES LUAU_VM_SOURCE_COUNT)
message(STATUS "Found ${LUAU_VM_SOURCE_COUNT} Luau VM source files")

# Define include and LUA variables for compatibility
set(LUA_INCLUDE_DIR "${LUAU_INCLUDE_DIR}")

# Build the Luau VM library directly from source
add_library(luau_vm STATIC ${LUAU_VM_SOURCES})
target_include_directories(luau_vm PUBLIC
    ${LUAU_INCLUDE_DIR}
    ${LUAU_SRC_DIR}
)
set_target_properties(luau_vm PROPERTIES
    POSITION_INDEPENDENT_CODE ON
    LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib"
)

# Create compatibility aliases
add_library(Lua::lua ALIAS luau_vm)
set(LUA_LIBRARIES luau_vm)

# Create Lua interface library
add_library(lua_bundled INTERFACE)
target_include_directories(lua_bundled INTERFACE ${LUA_INCLUDE_DIR})
target_link_libraries(lua_bundled INTERFACE luau_vm)

# Add include directories
include_directories(${LUA_INCLUDE_DIR})

message(STATUS "Configured Luau VM to build from source")
message(STATUS "  Include directory: ${LUAU_INCLUDE_DIR}")
message(STATUS "  Source directory: ${LUAU_SRC_DIR}")

# Add Luau compiler definitions
add_definitions(-DUSE_LUAU=1)
add_definitions(-DLUAU_FASTINT_SUPPORT=1)

# Add subdirectories
add_subdirectory(source/cpp)
add_subdirectory(source)

# For CI builds, clone the Luau repo if needed
if(DEFINED ENV{CI})
    message(STATUS "CI build detected, fetching Luau source files")
    
    # Create parent directories
    file(MAKE_DIRECTORY ${CMAKE_SOURCE_DIR}/external)
    
    # This needs to run before we check for the VM dir existence
    execute_process(
        COMMAND git clone --depth 1 https://github.com/Roblox/luau.git ${CMAKE_SOURCE_DIR}/external/luau
        RESULT_VARIABLE GIT_RESULT
    )
    
    if(GIT_RESULT EQUAL 0)
        message(STATUS "Successfully cloned Luau for CI build")
        # Update path to make sure it reflects the new clone
        set(LUAU_ROOT "${CMAKE_SOURCE_DIR}/external/luau")
        set(LUAU_VM_DIR "${LUAU_ROOT}/VM")
    else
        message(WARNING "Failed to clone Luau repository for CI build: ${GIT_RESULT}")
    endif()
    
    # Check if clone worked
    if(EXISTS "${LUAU_VM_DIR}")
        message(STATUS "Successfully located VM directory at ${LUAU_VM_DIR}")
    else
        message(STATUS "VM directory not found after clone attempt at ${LUAU_VM_DIR}")
    endif()
endif()

# Create the final dynamic library
add_library(mylibrary SHARED 
    source/library.cpp
    source/lfs.c
)

# Set target properties
set_target_properties(mylibrary PROPERTIES
    OUTPUT_NAME "mylibrary"
    LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib"
)

# Link with our static library and dependencies
target_link_libraries(mylibrary
    PRIVATE
    roblox_execution
    luau_vm  # Link directly with the Luau VM we're building from source
)

# Additional include paths and flags
target_include_directories(mylibrary PRIVATE 
    ${LUA_INCLUDE_DIR}
    ${CMAKE_SOURCE_DIR}/source
)

# Extra compiler defines for diagnostics
target_compile_definitions(mylibrary PRIVATE
    USE_LUA=1
    USE_LUAU=1
)

# Link with iOS frameworks if on Apple platform
if(APPLE)
    target_link_libraries(mylibrary PRIVATE ${IOS_FRAMEWORKS})
endif()

if(USE_DOBBY)
    target_link_libraries(mylibrary PRIVATE Dobby::dobby)
endif()

# Install targets
install(TARGETS mylibrary
    LIBRARY DESTINATION lib
    RUNTIME DESTINATION bin
)

message(STATUS "roblox_executor CMake configuration complete")
message(STATUS "Build Type: ${CMAKE_BUILD_TYPE}")
message(STATUS "Use Dobby: ${USE_DOBBY}")
message(STATUS "Enable AI Features: ${ENABLE_AI_FEATURES}")
message(STATUS "Enable Advanced Bypass: ${ENABLE_ADVANCED_BYPASS}")