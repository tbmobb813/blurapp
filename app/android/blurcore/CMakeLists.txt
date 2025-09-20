# CMake configuration for blur core native library
cmake_minimum_required(VERSION 3.22)

project(blurcore)

# Set C++17 standard for modern features and MediaPipe compatibility
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Configuration for different build phases
option(ENABLE_MEDIAPIPE "Enable MediaPipe segmentation (Phase 1)" OFF)
option(ENABLE_OPENCV "Enable OpenCV blur operations (Phase 2)" OFF)
option(ENABLE_GPU "Enable GPU acceleration (Phase 3)" OFF)

# Add the blur core library
add_library(blurcore SHARED
    # Phase 1: Enhanced stub with MediaPipe foundation
    stub.cpp
    
    # Future Phase 1: MediaPipe integration
    # src/segmentation/mediapipe_segmenter.cpp
    
    # Future Phase 2: Native blur operations  
    # src/effects/native_blur.cpp
    # src/effects/gpu_blur.cpp
    
    # Future Phase 3: Advanced mask processing
    # src/mask/mask_processor.cpp
    
    # Future Phase 4: Smart compositing
    # src/composite/smart_composite.cpp
)

# Include directories
target_include_directories(blurcore PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
    # Future: MediaPipe includes
    # Future: OpenCV includes
)

# Link with Android system libraries
target_link_libraries(blurcore 
    log  # Android logging
    # Future Phase 1: MediaPipe libraries
    # Future Phase 2: OpenCV libraries  
    # Future Phase 3: GPU libraries (OpenGL ES, Vulkan)
)

# Conditional compilation for different phases
if(ENABLE_MEDIAPIPE)
    target_compile_definitions(blurcore PRIVATE ENABLE_MEDIAPIPE=1)
    # Add MediaPipe dependencies when ready
endif()

if(ENABLE_OPENCV)
    target_compile_definitions(blurcore PRIVATE ENABLE_OPENCV=1)
    # Add OpenCV dependencies when ready
endif()

if(ENABLE_GPU)
    target_compile_definitions(blurcore PRIVATE ENABLE_GPU=1)
    # Add GPU acceleration libraries when ready
endif()

# Compiler flags for optimization
target_compile_options(blurcore PRIVATE
    -O2                    # Optimization level 2
    -ffast-math           # Fast math operations
    -fno-exceptions       # Disable exceptions for performance
    -fno-rtti            # Disable RTTI for smaller binary
)

# Debug configuration
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    target_compile_definitions(blurcore PRIVATE DEBUG=1)
    target_compile_options(blurcore PRIVATE -g)
endif()