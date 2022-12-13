find_package(PkgConfig REQUIRED)

set(THREADS_PREFER_PTHREAD_FLAG ON)
find_package(Threads REQUIRED)

if(NOT USING_STD_REGEX)
  find_package(PCRE2 QUIET)
  if(PCRE2_FOUND)
    message(STATUS "Using system PCRE2: ${PCRE2_LIBRARY}")
  else()
    message(STATUS "Using system PCRE2: NOT_FOUND, using std::regex instead.")
    set(USING_STD_REGEX ON CACHE STRING "USING_STD_REGEX" FORCE)
  endif()
endif()

if(UNIX)
    find_package(DL REQUIRED)
endif()

set(FETCHCONTENT_UPDATES_DISCONNECTED ON CACHE STRING "FETCHCONTENT_UPDATES_DISCONNECTED" FORCE)

include(FetchContent)
include(Patch)

# boost-cmake
if(WIN32)
    set(Boost_USE_STATIC_LIBS ON CACHE STRING "Boost_USE_STATIC_LIBS" FORCE)
    set(Boost_USE_STATIC_RUNTIME ON CACHE STRING "Boost_USE_STATIC_RUNTIME" FORCE)
endif()

# variant algorithm
find_package(Boost 1.65.1 COMPONENTS thread log log_setup system program_options filesystem coroutine locale regex unit_test_framework serialization)
if(Boost_FOUND)
    message(STATUS "** Boost Include: ${Boost_INCLUDE_DIR}")
    message(STATUS "** Boost Libraries Directory: ${Boost_LIBRARY_DIRS}")
    message(STATUS "** Boost Libraries: ${Boost_LIBRARIES}")
    include_directories(${Boost_INCLUDE_DIRS})
    add_compile_definitions("SUBCONVERTER_USE_BOOST")
else()
    if(WIN32)
        message(WARNING "Plase check your vcpkg settings or global environment variables for the boost library.")
    else()
        FetchContent_Declare(boost_cmake
            GIT_REPOSITORY https://github.com/Orphis/boost-cmake.git
            GIT_TAG d3951bc7f0b9d09005f92aedcf6acfc595f050ea)

        FetchContent_GetProperties(boost_cmake)
        if(NOT boost_cmake_POPULATED)
            FetchContent_Populate(boost_cmake)
            add_subdirectory(${boost_cmake_SOURCE_DIR} ${boost_cmake_BINARY_DIR} EXCLUDE_FROM_ALL)
            add_compile_definitions("SUBCONVERTER_USE_BOOST")
        endif()
    endif()
endif()


# zlib
find_package(ZLIB QUIET)
if(ZLIB_FOUND)
    message(STATUS "Using system zlib: ${ZLIB_INCLUDE_DIRS}")
    include_directories(BEFORE SYSTEM ${ZLIB_INCLUDE_DIRS})
else()
    add_subdirectory(external/zlib)
    message(STATUS "Using local zlib: ${CMAKE_CURRENT_LIST_DIR}/zlib")
    include_directories(
        "${CMAKE_CURRENT_LIST_DIR}/zlib"
        "${zlib_BINARY_DIR}/")
    set(ZLIB_LIBRARIES zlibstatic CACHE STRING "ZLIB_LIBRARIES" FORCE)
endif()


# fmt
set(FMT_INSTALL ON CACHE BOOL "FMT_INSTALL" FORCE)
FetchContent_Declare(fmt
    GIT_REPOSITORY https://github.com/fmtlib/fmt.git
    GIT_TAG master)

FetchContent_GetProperties(fmt)
if(NOT fmt_POPULATED)
    FetchContent_Populate(fmt)
    add_subdirectory(${fmt_SOURCE_DIR} ${fmt_BINARY_DIR} EXCLUDE_FROM_ALL)
endif()


# cmrc
FetchContent_Declare(cmrc
    GIT_REPOSITORY https://github.com/vector-of-bool/cmrc.git
    GIT_TAG a64bea50c05594c8e7cf1f08e441bb9507742e2e)

FetchContent_GetProperties(cmrc)
if(NOT cmrc_POPULATED)
    FetchContent_Populate(cmrc)
    add_subdirectory(${cmrc_SOURCE_DIR} ${cmrc_BINARY_DIR} EXCLUDE_FROM_ALL)
endif()


# curl
find_package(CURL QUIET)
if(CURL_FOUND)
    message(STATUS "Using system libcurl: ${CURL_LIBRARIES}")
else()
  FetchContent_Declare(curl
      GIT_REPOSITORY https://github.com/curl/curl
      GIT_TAG master)

  FetchContent_GetProperties(curl)
  if(NOT curl_POPULATED)
      FetchContent_Populate(curl)
      add_subdirectory(${curl_SOURCE_DIR} ${curl_BINARY_DIR} EXCLUDE_FROM_ALL)
  endif()
endif()


# libevent
find_package(LibEvent QUIET)
if(LibEvent_FOUND)
    message(STATUS "Using system libevent: ${LIBEVENT_LIB}")
else()
  set(EVENT__DISABLE_MBEDTLS ON CACHE BOOL "EVENT__DISABLE_MBEDTLS" FORCE)
  set(EVENT_LIBRARY_STATIC ON CACHE BOOL "EVENT_LIBRARY_STATIC" FORCE)
  FetchContent_Declare(libevent
      GIT_REPOSITORY https://github.com/libevent/libevent.git
      GIT_TAG 02428d9a2d89ee0a595166909dd6d75b5beb777b)

  FetchContent_GetProperties(libevent)
  if(NOT libevent_POPULATED)
      FetchContent_Populate(libevent)
      add_subdirectory(${libevent_SOURCE_DIR} ${libevent_BINARY_DIR} EXCLUDE_FROM_ALL)
      set(LIBEVENT_LIB "event_core_static;event_pthreads_static")
      set(LIBEVENT_INCLUDE_DIR "${libevent_SOURCE_DIR}/include")
  endif()
endif()


# nlohmann_json
FetchContent_Declare(json
  GIT_REPOSITORY https://github.com/ArthurSonzogni/nlohmann_json_cmake_fetchcontent
  GIT_TAG v3.10.4)

FetchContent_GetProperties(json)
if(NOT json_POPULATED)
  FetchContent_Populate(json)
  add_subdirectory(${json_SOURCE_DIR} ${json_BINARY_DIR} EXCLUDE_FROM_ALL)
endif()


# rapidjson
set(RAPIDJSON_BUILD_DOC OFF CACHE BOOL "" FORCE)
set(RAPIDJSON_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(RAPIDJSON_BUILD_TESTS OFF CACHE BOOL "" FORCE)
set(RAPIDJSON_BUILD_THIRDPARTY_GTEST OFF CACHE BOOL "" FORCE)
set(RAPIDJSON_ENABLE_INSTRUMENTATION_OPT OFF CACHE BOOL "" FORCE)
FetchContent_Declare(rapidjson
  GIT_REPOSITORY https://github.com/Tencent/rapidjson.git
  GIT_TAG master)

FetchContent_GetProperties(rapidjson)
if(NOT rapidjson_POPULATED)
  FetchContent_Populate(rapidjson)
  # add_library(Rapidjson INTERFACE)
  # target_include_directories(Rapidjson INTERFACE "${rapidjson_SOURCE_DIR}/include")
  include_directories("${rapidjson_SOURCE_DIR}/include")
endif()


# quickjs
FetchContent_Declare(quickjs
  GIT_REPOSITORY https://github.com/ftk/quickjspp.git
  GIT_TAG master)

FetchContent_GetProperties(quickjs)
if(NOT quickjs_POPULATED)
  FetchContent_Populate(quickjs)

  file(GLOB quickjs_patches
    "${CMAKE_CURRENT_LIST_DIR}/patches/quickjs/*.patch"
  )

  foreach(patch_file IN ITEMS ${quickjs_patches})
    message(STATUS "Applying patch for quickjs: ${patch_file}")
    patch_directory("${quickjs_SOURCE_DIR}" "${patch_file}")
  endforeach()

  add_subdirectory(${quickjs_SOURCE_DIR} ${quickjs_BINARY_DIR} EXCLUDE_FROM_ALL)
endif()


# jpcre2
FetchContent_Declare(jpcre2
  GIT_REPOSITORY https://github.com/jpcre2/jpcre2.git
  GIT_TAG master)

FetchContent_GetProperties(jpcre2)
if(NOT jpcre2_POPULATED)
  FetchContent_Populate(jpcre2)
  add_library(jpcre2 INTERFACE)
  target_include_directories(jpcre2 INTERFACE "${jpcre2_SOURCE_DIR}/src/")
  target_link_libraries(jpcre2 INTERFACE jpcre2)
endif()


# Jinja2Cpp
set(JINJA2CPP_DEPS_MODE "external-as-target" CACHE STRING "JINJA2CPP_DEPS_MODE" FORCE)
set(JINJA2CPP_BUILD_SHARED OFF CACHE BOOL "JINJA2CPP_BUILD_SHARED" FORCE)
set(JINJA2CPP_BUILD_TESTS OFF CACHE BOOL "JINJA2CPP_BUILD_TESTS" FORCE)
set(JINJA2_PRIVATE_LIBS_INT "" CACHE STRING "JINJA2_PRIVATE_LIBS_INT" FORCE)
FetchContent_Declare(jinja2cpp
  GIT_REPOSITORY https://github.com/jinja2cpp/Jinja2Cpp.git
  GIT_SUBMODULES "thirdparty/gtest;thirdparty/fmtlib;thirdparty/nonstd/expected-lite;thirdparty/nonstd/optional-lite;thirdparty/nonstd/string-view-lite;thirdparty/nonstd/variant-lite"
  GIT_TAG 1dacf16a1f6e216f5dcb7e7b8ef9626634c29cf9)

FetchContent_GetProperties(jinja2cpp)
if(NOT jinja2cpp_POPULATED)
  FetchContent_Populate(jinja2cpp)
  file(COPY "${CMAKE_CURRENT_LIST_DIR}/patches/jinja2cpp/thirdparty" DESTINATION "${jinja2cpp_SOURCE_DIR}/")
  file(COPY "${CMAKE_CURRENT_LIST_DIR}/patches/jinja2cpp/cmake" DESTINATION "${jinja2cpp_SOURCE_DIR}/")
  add_subdirectory(${jinja2cpp_SOURCE_DIR} ${jinja2cpp_BINARY_DIR} EXCLUDE_FROM_ALL)
  if(USING_JINJA2CPP)
    add_compile_definitions("SUBCONVERTER_USE_JINJA2CPP")
  endif()
endif()


# inja
if(USING_INJA)
  set(INJA_USE_EMBEDDED_JSON OFF CACHE STRING "INJA_USE_EMBEDDED_JSON" FORCE)
  FetchContent_Declare(inja
    GIT_REPOSITORY https://github.com/pantor/inja.git
    GIT_TAG 120691339d76ed72035361927749d8d259fbe0d9)

  FetchContent_GetProperties(inja)
  if(NOT inja_POPULATED)
    FetchContent_Populate(inja)
    add_subdirectory(${inja_SOURCE_DIR} ${inja_BINARY_DIR} EXCLUDE_FROM_ALL)
    add_compile_definitions("SUBCONVERTER_USE_INJA")
  endif()
endif()


# toml11
FetchContent_Declare(toml11
  GIT_REPOSITORY https://github.com/ToruNiina/toml11.git
  GIT_TAG master)

FetchContent_GetProperties(toml11)
if(NOT toml11_POPULATED)
  FetchContent_Populate(toml11)
  add_subdirectory(${toml11_SOURCE_DIR} ${toml11_BINARY_DIR} EXCLUDE_FROM_ALL)
endif()


# libcron
FetchContent_Declare(libcron
  GIT_REPOSITORY https://github.com/PerMalmberg/libcron.git
  GIT_TAG master)

FetchContent_GetProperties(libcron)
if(NOT libcron_POPULATED)
  FetchContent_Populate(libcron)
  add_subdirectory(${libcron_SOURCE_DIR}/libcron/externals/date ${libcron_BINARY_DIR}/libcron/externals/date EXCLUDE_FROM_ALL)
  file(GLOB_RECURSE libcron_src
    ${libcron_SOURCE_DIR}/libcron/src/*.cpp
  )
  add_library(libcron STATIC ${libcron_src})
  target_link_libraries(libcron
    PUBLIC date::date)
  target_include_directories(libcron
    PUBLIC ${libcron_SOURCE_DIR}/libcron/include)
endif()


# yaml-cpp
FetchContent_Declare(yaml_cpp
  GIT_REPOSITORY https://github.com/jbeder/yaml-cpp.git
  GIT_TAG master)

FetchContent_GetProperties(yaml_cpp)
if(NOT yaml_cpp_POPULATED)
  FetchContent_Populate(yaml_cpp)
  add_subdirectory(${yaml_cpp_SOURCE_DIR} ${yaml_cpp_BINARY_DIR} EXCLUDE_FROM_ALL)
endif()


# duktape
FetchContent_Declare(duktape
  GIT_REPOSITORY https://github.com/svaarala/duktape-releases.git
  GIT_TAG v2.7.0)

FetchContent_GetProperties(duktape)
if(NOT duktape_POPULATED)
  FetchContent_Populate(duktape)
  add_library(duktape STATIC
    ${duktape_SOURCE_DIR}/src/duktape.c
    ${duktape_SOURCE_DIR}/extras/module-node/duk_module_node.c
  )
  target_include_directories(duktape
    PUBLIC "${duktape_SOURCE_DIR}/src"
    PUBLIC "${duktape_SOURCE_DIR}/extras/module-node/"
  )

  if(NOT WIN32)
    target_link_libraries(duktape
        PUBLIC m
        PUBLIC dl
        PUBLIC rt)
  endif()
endif()
