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

if(DEFINED ENV{SHA})
	set(VERSION "$ENV{SHA}")
else()
    execute_process(
        COMMAND
            git rev-parse HEAD
        RESULT_VARIABLE
            SUBCONVERTER_VERSION_RESULT
        OUTPUT_VARIABLE
            SUBCONVERTER_VERSION
        OUTPUT_STRIP_TRAILING_WHITESPACE)
    if(SUBCONVERTER_VERSION_RESULT AND NOT SUBCONVERTER_VERSION_RESULT EQUAL 0)
        set(VERSION "v0.7.2")
    else()
        set(VERSION "${SUBCONVERTER_VERSION}")
    endif()
endif()

message(STATUS "subconverter version: ${VERSION}")
configure_file(${CMAKE_CURRENT_LIST_DIR}/lib/version.h.in ${CMAKE_CURRENT_BINARY_DIR}/subconverter/version.h @ONLY)

add_library(${BUILD_TARGET_NAME}-lib STATIC ${src})
target_compile_definitions(${BUILD_TARGET_NAME}-lib
    PRIVATE -DCURL_STATICLIB
    PRIVATE -DPCRE2_STATIC
    PRIVATE -DYAML_CPP_STATIC_DEFINE
)

if(USE_STD_REGEX)
  target_compile_definitions(${BUILD_TARGET_NAME}-lib PUBLIC -DUSE_STD_REGEX)
endif()

if(HAVE_TO_STRING)
  target_compile_definitions(${BUILD_TARGET_NAME}-lib PUBLIC -DHAVE_TO_STRING)
endif()

if(USING_MALLOC_TRIM)
  target_compile_definitions(${BUILD_TARGET_NAME}-lib PUBLIC -DMALLOC_TRIM)
endif()

if(LibEvent_FOUND)
    target_link_libraries(${BUILD_TARGET_NAME}-lib
        PUBLIC ${LIBEVENT_LIB}
    )
else()
    target_link_libraries(${BUILD_TARGET_NAME}-lib
        PUBLIC event_core_static
        PUBLIC event_extra_static
        PUBLIC event_openssl_static
    )
endif()

target_include_directories(${BUILD_TARGET_NAME}-lib BEFORE
    PUBLIC ${LIBEVENT_INCLUDE_DIR}
)

target_include_directories(${BUILD_TARGET_NAME}-lib
    PUBLIC ${CMAKE_CURRENT_BINARY_DIR}
    PUBLIC ${PCRE2_INCLUDE_DIR}
    PUBLIC ${CMAKE_CURRENT_LIST_DIR}/lib
)

target_link_libraries(${BUILD_TARGET_NAME}-lib
    PUBLIC ${CMAKE_THREAD_LIBS_INIT}
    PUBLIC ${CXX_FILESYSTEM_LIBS}
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

if(WIN32 AND (NOT MINGW))
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

if(MINGW)
    # mingw_bundle_dll(${BUILD_TARGET_NAME})
    add_custom_command(TARGET ${BUILD_TARGET_NAME} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy "$<TARGET_RUNTIME_DLLS:${BUILD_TARGET_NAME}>" "$<TARGET_FILE_DIR:${BUILD_TARGET_NAME}>"
        COMMAND_EXPAND_LISTS
    )
endif()
