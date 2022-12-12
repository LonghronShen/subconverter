cmake_minimum_required(VERSION 3.12)

if(POLICY CMP0074)
  cmake_policy(SET CMP0074 NEW)
endif()

if(POLICY CMP0058)
  cmake_policy(SET CMP0058 NEW)
endif()

set(project_name subconverter)
set(BUILD_TARGET_NAME ${project_name})

project(${project_name} C CXX)

if(CMAKE_COMPILER_IS_GNUCC)
  if(CMAKE_CXX_COMPILER_VERSION VERSION_GREATER 8.4)
    message(FATAL_ERROR "GCC ${CMAKE_CXX_COMPILER_VERSION} is not supported.")
  endif()
endif()

set(CMAKE_CXX_STANDARD 17 CACHE STRING "Set to 11 or 14 to enable C++11 or C++17 builds, respectively." FORCE)
set(CMAKE_C_STANDARD 11 CACHE STRING "Set to 99 or 11 to enable C99 or C11 builds, respectively." FORCE)
set_property(GLOBAL PROPERTY CXX_STANDARD_REQUIRED ON)

set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/cmake")

include_directories(${CMAKE_BINARY_DIR})

include(FixCompileFlags)

if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Release)
endif()

option(USING_JINJA2CPP "Use Jinja2Cpp as template engine." OFF)
option(USING_INJA "Use inja as template engine." ON)

# remove std::regex support since it is not compatible with group modifiers and slow 
option(USING_STD_REGEX "Use std::regex from C++ library instead of PCRE2." OFF)
option(USING_MALLOC_TRIM "Call malloc_trim after processing request to lower memory usage (Your system must support malloc_trim)." OFF)

# now using internal MD5 calculation
option(USING_MBEDTLS "Use mbedTLS instead of OpenSSL for MD5 calculation." OFF)
option(BUILD_STATIC_LIBRARY "Build a static library containing only the essential part." OFF)

add_subdirectory(assets)

include(external/InitializeExternalComponents.cmake)

add_subdirectory(src)
