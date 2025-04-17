#!/bin/bash
# This script fixes all include paths for iOS files

# Process each .mm file to correct the include paths
find source/cpp/ios -name "*.mm" | while read file; do
  # Fix the include paths
  echo "Fixing include paths in $file"
  
  # Replace ../ios_compat.h with the correct path
  # Calculate the correct path based on directory depth
  dir=$(dirname "$file")
  depth=$(echo "$dir" | tr '/' '\n' | wc -l)
  
  # source/cpp/ios/ is depth 3, so we need 1 "../" (to get to source/cpp/)
  # source/cpp/ios/subfolder/ is depth 4, so we need 2 "../" 
  prefix=""
  for ((i=0; i<$depth-2; i++)); do
    prefix="../$prefix"
  done
  
  # Replace the include path
  sed -i "s|#include \"../ios_compat.h\"|#include \"${prefix}ios_compat.h\"|g" "$file"
  sed -i "s|#include \"ios_compat.h\"|#include \"${prefix}ios_compat.h\"|g" "$file"
done

# Fix the include paths for .h files too
find source/cpp/ios -name "*.h" | while read file; do
  echo "Fixing include paths in $file"
  
  # Calculate the correct path based on directory depth
  dir=$(dirname "$file")
  depth=$(echo "$dir" | tr '/' '\n' | wc -l)
  
  # Calculate the prefix
  prefix=""
  for ((i=0; i<$depth-2; i++)); do
    prefix="../$prefix"
  done
  
  # Replace the include path
  sed -i "s|#include \"../ios_compat.h\"|#include \"${prefix}ios_compat.h\"|g" "$file"
  sed -i "s|#include \"ios_compat.h\"|#include \"${prefix}ios_compat.h\"|g" "$file"
done
