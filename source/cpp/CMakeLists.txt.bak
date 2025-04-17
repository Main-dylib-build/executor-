# Production-grade CMakeLists.txt for source/cpp

# Define our base component library
project(roblox_execution VERSION 1.0.0 LANGUAGES C CXX)

# Set compiler flags for production builds
set(PRODUCTION_FLAGS "-O3 -fvisibility=hidden -ffunction-sections -fdata-sections")

# Set flags based on platform
if(APPLE)
  # iOS-specific flags
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${PRODUCTION_FLAGS} -fobjc-arc")
  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${PRODUCTION_FLAGS}")
else()
  # Non-iOS platforms
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${PRODUCTION_FLAGS}")
  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${PRODUCTION_FLAGS}")
endif()

# Explicitly collect source files by component for better organization and control
# Note: library.cpp is already included in the main mylibrary target defined in root CMakeLists.txt
# Including it here would cause duplicate symbol issues
set(CORE_SOURCES
    "${CMAKE_CURRENT_SOURCE_DIR}/logging.hpp"
    "${CMAKE_CURRENT_SOURCE_DIR}/native-lib.cpp"
    "${CMAKE_CURRENT_SOURCE_DIR}/globals.hpp"
    "${CMAKE_CURRENT_SOURCE_DIR}/lua_compatibility.h"
    "${CMAKE_CURRENT_SOURCE_DIR}/dobby_wrapper.cpp"
    "${CMAKE_CURRENT_SOURCE_DIR}/dobby_defs.h"
    "${CMAKE_CURRENT_SOURCE_DIR}/filesystem_utils.h"
)

set(MEMORY_SOURCES
    "${CMAKE_CURRENT_SOURCE_DIR}/memory/mem.hpp"
    "${CMAKE_CURRENT_SOURCE_DIR}/memory/signature.hpp"
)

set(HOOKS_SOURCES
    "${CMAKE_CURRENT_SOURCE_DIR}/hooks/hooks.hpp"
)

set(EXEC_SOURCES
    "${CMAKE_CURRENT_SOURCE_DIR}/exec/funcs.hpp"
    "${CMAKE_CURRENT_SOURCE_DIR}/exec/impls.hpp"
)

set(ANTI_DETECTION_SOURCES
    "${CMAKE_CURRENT_SOURCE_DIR}/anti_detection/obfuscator.hpp"
    "${CMAKE_CURRENT_SOURCE_DIR}/anti_detection/vm_detect.hpp"
)

# iOS-specific source files
set(IOS_SOURCES "")
if(APPLE)
    set(IOS_SOURCES
        "${CMAKE_CURRENT_SOURCE_DIR}/ios/ExecutionEngine.h"
        "${CMAKE_CURRENT_SOURCE_DIR}/ios/ExecutionEngine.mm"
        "${CMAKE_CURRENT_SOURCE_DIR}/ios/ScriptManager.h"
        "${CMAKE_CURRENT_SOURCE_DIR}/ios/ScriptManager.mm"
        "${CMAKE_CURRENT_SOURCE_DIR}/ios/JailbreakBypass.h"
        "${CMAKE_CURRENT_SOURCE_DIR}/ios/JailbreakBypass.mm"
        "${CMAKE_CURRENT_SOURCE_DIR}/ios/PatternScanner.h"
        "${CMAKE_CURRENT_SOURCE_DIR}/ios/PatternScanner.mm"
        "${CMAKE_CURRENT_SOURCE_DIR}/ios/MemoryAccess.h"
        "${CMAKE_CURRENT_SOURCE_DIR}/ios/MemoryAccess.mm"
        "${CMAKE_CURRENT_SOURCE_DIR}/ios/UIController.h"
        "${CMAKE_CURRENT_SOURCE_DIR}/ios/UIController.mm"
        "${CMAKE_CURRENT_SOURCE_DIR}/ios/FloatingButtonController.h"
        "${CMAKE_CURRENT_SOURCE_DIR}/ios/FloatingButtonController.mm"
        "${CMAKE_CURRENT_SOURCE_DIR}/ios/GameDetector.h"
        "${CMAKE_CURRENT_SOURCE_DIR}/ios/GameDetector.mm"
        "${CMAKE_CURRENT_SOURCE_DIR}/ios/mach_compat.h"
    )
endif()

# AI Features source files
set(AI_SOURCES "")
if(ENABLE_AI_FEATURES)
    file(GLOB_RECURSE AI_SOURCES
        "${CMAKE_CURRENT_SOURCE_DIR}/ios/ai_features/*.h"
        "${CMAKE_CURRENT_SOURCE_DIR}/ios/ai_features/*.mm"
        "${CMAKE_CURRENT_SOURCE_DIR}/ios/ai_features/*.cpp"
    )
endif()

# Advanced bypass sources
set(BYPASS_SOURCES "")
if(ENABLE_ADVANCED_BYPASS)
    file(GLOB_RECURSE BYPASS_SOURCES
        "${CMAKE_CURRENT_SOURCE_DIR}/ios/advanced_bypass/*.h"
        "${CMAKE_CURRENT_SOURCE_DIR}/ios/advanced_bypass/*.mm"
    )
endif()

# Test sources
set(TEST_SOURCES
    "${CMAKE_CURRENT_SOURCE_DIR}/tests/integration_test.cpp"
)

# Combine all source files
set(ALL_SOURCES
    ${CORE_SOURCES}
    ${MEMORY_SOURCES}
    ${HOOKS_SOURCES}
    ${EXEC_SOURCES}
    ${ANTI_DETECTION_SOURCES}
    ${IOS_SOURCES}
    ${AI_SOURCES}
    ${BYPASS_SOURCES}
)

# Create the library
add_library(roblox_execution STATIC ${ALL_SOURCES})

# Add debug definition in debug mode
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    target_compile_definitions(roblox_execution PRIVATE DEBUG_BUILD=1)
endif()

# Add production options
target_compile_definitions(roblox_execution PRIVATE 
    PRODUCTION_BUILD=1
    ENABLE_ERROR_REPORTING=1
    ENABLE_ANTI_TAMPER=1
)

# Add CI-specific definitions for CI builds
if(DEFINED ENV{CI} OR DEFINED ENV{GITHUB_ACTIONS} OR CI_BUILD)
    target_compile_definitions(roblox_execution PRIVATE
        CI_BUILD=1
        SKIP_IOS_INTEGRATION=1
    )
    message(STATUS "CI build detected - adding CI-specific definitions")
endif()

# Set include directories
target_include_directories(roblox_execution PUBLIC
    ${CMAKE_SOURCE_DIR}/source
    ${CMAKE_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_SOURCE_DIR}/VM/include # Update to use local VM folder
    ${CMAKE_SOURCE_DIR}/external/dobby/include
)

# We now include VM sources directly in main library, no need to link against luau_vm
# instead, ensure we have the right include paths
target_include_directories(roblox_execution PRIVATE
    ${CMAKE_SOURCE_DIR}/VM/include
    ${CMAKE_SOURCE_DIR}/VM/src
)

# Link against Dobby - it's already found/built in the main CMakeLists.txt
if(USE_DOBBY)
    # Dobby is already located and configured in the main CMakeLists.txt
    # This ensures we only have one Dobby target used throughout the project
    target_link_libraries(roblox_execution Dobby::dobby)
endif()

# Build tests in debug mode
if(CMAKE_BUILD_TYPE STREQUAL "Debug" OR BUILD_TESTING)
    # Add test executable
    add_executable(integration_tests ${TEST_SOURCES})
    target_link_libraries(integration_tests roblox_execution)
    
    # Add tests to CTest if available
    include(CTest)
    if(BUILD_TESTING)
        add_test(NAME IntegrationTest COMMAND integration_tests)
    endif()
endif()

# Install targets
install(TARGETS roblox_execution
    ARCHIVE DESTINATION lib
    LIBRARY DESTINATION lib
    RUNTIME DESTINATION bin
)

# Install headers
install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/
    DESTINATION include/roblox_execution
    FILES_MATCHING 
    PATTERN "*.h"
    PATTERN "*.hpp"
    PATTERN "tests" EXCLUDE
)

# Documentation generation with Doxygen
find_package(Doxygen QUIET)
if(DOXYGEN_FOUND AND BUILD_DOCS)
    # Generate Doxyfile
    configure_file(
        ${CMAKE_CURRENT_SOURCE_DIR}/Doxyfile.in
        ${CMAKE_CURRENT_BINARY_DIR}/Doxyfile
        @ONLY
    )
    
    # Add documentation target
    add_custom_target(docs
        ${DOXYGEN_EXECUTABLE} ${CMAKE_CURRENT_BINARY_DIR}/Doxyfile
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
        COMMENT "Generating API documentation with Doxygen"
        VERBATIM
    )
endif()
