# Luau Source Integration Guide

This project directly compiles Luau (Roblox's Lua implementation) from source files. The build system is set up to use the Luau VM source code directly rather than pre-built libraries.

## Required Directory Structure

You need to have the Luau source code in the following structure:

```
external/luau/
└── VM/
    ├── include/
    │   ├── lua.h
    │   ├── luaconf.h
    │   └── lualib.h
    └── src/
        ├── lapi.cpp
        ├── lbaselib.cpp
        ├── ltable.cpp
        └── ... (other source files)
```

## Getting the Luau Source Code

The easiest way to set up Luau is to clone the repository:

```bash
# Create the external directory
mkdir -p external

# Clone Luau repository
git clone https://github.com/Roblox/luau.git external/luau
```

That's it! The build system will:
1. Locate the VM/include and VM/src directories
2. Compile all .cpp files in the VM/src directory
3. Link directly against the compiled Luau VM

## Custom Location for Luau Source

If you want to use a different location for the Luau source code, you can specify it when running CMake:

```bash
cmake -DLUAU_VM_DIR=/path/to/luau/VM ..
```

## Continuous Integration (CI)

For GitHub Actions and other CI systems, the build system will automatically:
1. Check if the Luau repository exists
2. Clone it from GitHub if needed
3. Use the cloned source files for compilation

This way, CI builds will always have access to the Luau source code without any manual setup.

## Troubleshooting

### VM Directory Not Found

If you get an error like:
```
Luau VM directory not found at /path/to/luau/VM
```

Make sure:
1. You have cloned the Luau repository to the expected location
2. The VM directory exists within the repository
3. Set the correct path with `-DLUAU_VM_DIR=/correct/path/to/luau/VM`

### Header Files Not Found

If you get an error like:
```
Luau header files not found at /path/to/luau/VM/include
```

Make sure:
1. The include directory exists in the VM folder
2. The header files (lua.h, etc.) are present in that directory

### Source Files Not Found

If you get an error about missing source files, verify that:
1. The src directory exists in the VM folder
2. The .cpp files are present in that directory
