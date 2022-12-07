file(GLOB_RECURSE src
    ${CMAKE_CURRENT_LIST_DIR}/lib/*.h
    ${CMAKE_CURRENT_LIST_DIR}/lib/*.hpp

    ${CMAKE_CURRENT_LIST_DIR}/lib/*.c
	${CMAKE_CURRENT_LIST_DIR}/lib/*.cc
	${CMAKE_CURRENT_LIST_DIR}/lib/*.cpp
)

file(GLOB_RECURSE public_headers
    ${CMAKE_CURRENT_LIST_DIR}/lib/*.h
    ${CMAKE_CURRENT_LIST_DIR}/lib/*.hpp
)

add_library(${BUILD_TARGET_NAME}-lib STATIC ${src})
target_compile_definitions(${BUILD_TARGET_NAME}-lib
    PRIVATE -DCURL_STATICLIB
    PRIVATE -DPCRE2_STATIC
    PRIVATE -DYAML_CPP_STATIC_DEFINE
)

if(HAVE_TO_STRING)
  target_compile_definitions(${BUILD_TARGET_NAME}-lib PUBLIC -DHAVE_TO_STRING)
endif()

if(USING_MALLOC_TRIM)
  target_compile_definitions(${BUILD_TARGET_NAME}-lib PUBLIC -DMALLOC_TRIM)
endif()

target_include_directories(${BUILD_TARGET_NAME}-lib
    PUBLIC ${LIBEVENT_INCLUDE_DIR}
    PUBLIC ${PCRE2_INCLUDE_DIR}
    PUBLIC ${CMAKE_CURRENT_LIST_DIR}/lib
)
target_link_libraries(${BUILD_TARGET_NAME}-lib
    PUBLIC ${CMAKE_THREAD_LIBS_INIT}
    PUBLIC ${CXX_FILESYSTEM_LIBS}
    PUBLIC ${LIBEVENT_LIB}
    PUBLIC ${PCRE2_LIBRARY}
    PUBLIC CURL::libcurl
    # PUBLIC Rapidjson
    PUBLIC toml11::toml11
    PUBLIC yaml-cpp::yaml-cpp
    PUBLIC libcron
    PUBLIC quickjspp
    PUBLIC pantor::inja
    PUBLIC jinja2cpp
    PUBLIC jpcre2
    # PUBLIC duktape
)
if(WIN32)
    target_link_libraries(${BUILD_TARGET_NAME} 
        PUBLIC wsock32
        PUBLIC ws2_32
    )
endif()

add_library(${BUILD_TARGET_NAME}-shared SHARED ${CMAKE_CURRENT_LIST_DIR}/lib/wrapper.cpp)
target_link_libraries(${BUILD_TARGET_NAME}-shared
    PUBLIC ${BUILD_TARGET_NAME}-lib
)
target_compile_definitions(${BUILD_TARGET_NAME}-shared PRIVATE SUBCONVERTER_SHARED_LIB)

add_executable(${BUILD_TARGET_NAME} ${CMAKE_CURRENT_LIST_DIR}/exe/main.cpp)
target_link_libraries(${BUILD_TARGET_NAME}
    PUBLIC ${BUILD_TARGET_NAME}-lib
)
