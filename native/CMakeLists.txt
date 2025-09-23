cmake_minimum_required(VERSION 3.10)
project(blurcore LANGUAGES C CXX)
set(CMAKE_CXX_STANDARD 17)


add_library(blurcore STATIC
src/blur.cpp
)


target_include_directories(blurcore PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)

# Build a small test binary for local/native verification
add_executable(blurcore_test
	test/test_blur_apply_regions.cpp
)

target_link_libraries(blurcore_test PRIVATE blurcore)
target_include_directories(blurcore_test PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/include)