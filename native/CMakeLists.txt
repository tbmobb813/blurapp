cmake_minimum_required(VERSION 3.10)
project(blurcore LANGUAGES C CXX)
set(CMAKE_CXX_STANDARD 17)


add_library(blurcore STATIC
src/blur.cpp
)


target_include_directories(blurcore PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)