#!/bin/bash
# Script to fix all paths that include objc_isolation.h based on their depth in the directory structure

# Process files in source/cpp/ios directly - they should include "../objc_isolation.h"
find source/cpp/ios -maxdepth 1 -type f \( -name "*.h" -o -name "*.mm" -o -name "*.cpp" -o -name "*.m" \) -print0 | xargs -0 grep -l "objc_isolation.h" | while read file; do
  echo "Fixing $file => #include \"../objc_isolation.h\""
  # If the file uses "objc_isolation.h", change to "../objc_isolation.h"
  sed -i 's|#include "objc_isolation.h"|#include "../objc_isolation.h"|g' "$file"
  # If it already had "../objc_isolation.h", no change needed
done

# Process files in first-level subdirectories of source/cpp/ios - they should include "../../objc_isolation.h"
find source/cpp/ios/* -maxdepth 1 -type f \( -name "*.h" -o -name "*.mm" -o -name "*.cpp" -o -name "*.m" \) -print0 | xargs -0 grep -l "../objc_isolation.h" | while read file; do
  echo "Fixing $file => #include \"../../objc_isolation.h\""
  # Fix the path to use "../../objc_isolation.h"
  sed -i 's|#include "../objc_isolation.h"|#include "../../objc_isolation.h"|g' "$file"
done

# Process files in second-level subdirectories of source/cpp/ios - they should include "../../../objc_isolation.h"
find source/cpp/ios/*/*/* -type f \( -name "*.h" -o -name "*.mm" -o -name "*.cpp" -o -name "*.m" \) -print0 | xargs -0 grep -l "../../objc_isolation.h" | while read file; do
  echo "Fixing $file => #include \"../../../objc_isolation.h\""
  # Fix the path to use "../../../objc_isolation.h"
  sed -i 's|#include "../../objc_isolation.h"|#include "../../../objc_isolation.h"|g' "$file"
done
