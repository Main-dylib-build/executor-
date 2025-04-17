#!/bin/bash
# This script finds .cpp files that contain Objective-C code and renames them to .mm

# Find .cpp files in ios directory that might contain Objective-C code
find source/cpp/ios -name "*.cpp" | while read file; do
  # Check if file contains Objective-C syntax ([] method calls or NS* types)
  if grep -q "\\[.*\\]" "$file" || grep -q "NS[A-Z]" "$file"; then
    echo "Renaming $file to ${file%.cpp}.mm"
    git mv "$file" "${file%.cpp}.mm"
  fi
done
