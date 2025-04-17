#!/bin/bash
# Script to correctly fix all paths that include objc_isolation.h based on their depth in the directory structure

# Find all files that include objc_isolation.h
find source/cpp/ios -type f \( -name "*.h" -o -name "*.mm" -o -name "*.cpp" -o -name "*.m" \) -print0 | xargs -0 grep -l "objc_isolation.h" | while read file; do
  # Get the directory depth relative to source/cpp
  dir=$(dirname "$file")
  depth=$(echo "$dir" | tr '/' '\n' | wc -l)
  
  # Calculate the correct path prefix
  # source/cpp is depth 2, so files directly in source/cpp need no "../"
  # source/cpp/ios is depth 3, so we need 1 "../" from there
  # source/cpp/ios/something is depth 4, so we need 2 "../" from there
  # etc.
  
  rel_path=""
  for ((i=0; i<$depth-2; i++)); do
    rel_path="../$rel_path"
  done
  
  rel_path="${rel_path}objc_isolation.h"
  
  echo "Fixing $file => #include \"$rel_path\""
  
  # First, normalize all objc_isolation.h includes to a common pattern
  sed -i 's|#include\s*"[./]*objc_isolation.h"|#include "TEMP_PLACEHOLDER"|g' "$file"
  
  # Then replace with the correct path
  sed -i "s|#include \"TEMP_PLACEHOLDER\"|#include \"$rel_path\"|g" "$file"
done
