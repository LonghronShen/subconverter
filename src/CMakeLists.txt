file(GLOB_RECURSE src
    ${CMAKE_CURRENT_LIST_DIR}/lib/*.h
    ${CMAKE_CURRENT_LIST_DIR}/lib/*.hpp

    ${CMAKE_CURRENT_LIST_DIR}/lib/*.c
	${CMAKE_CURRENT_LIST_DIR}/lib/*.cc
	${CMAKE_CURRENT_LIST_DIR}/lib/*.cpp
)

list(REMOVE_ITEM src
    ${CMAKE_CURRENT_LIST_DIR}/lib/server/webserver.cpp
    ${CMAKE_CURRENT_LIST_DIR}/lib/server/webserver_libevent.cpp
    ${CMAKE_CURRENT_LIST_DIR}/lib/server/webserver_kleinshttp.cpp
)

set(WEBSERVER_BACKEND_SRC "")
if(SUBCONVERTER_WEBSERVER_BACKEND STREQUAL "libevent")
    set(WEBSERVER_BACKEND_SRC ${CMAKE_CURRENT_LIST_DIR}/lib/server/webserver_libevent.cpp)
elseif(SUBCONVERTER_WEBSERVER_BACKEND STREQUAL "kleinshttp")
    set(WEBSERVER_BACKEND_SRC ${CMAKE_CURRENT_LIST_DIR}/lib/server/webserver_kleinshttp.cpp)
    if(NOT EXISTS ${WEBSERVER_BACKEND_SRC})
        message(FATAL_ERROR "Selected WebServer backend '${SUBCONVERTER_WEBSERVER_BACKEND}' requires missing implementation: ${WEBSERVER_BACKEND_SRC}")
    endif()
endif()

list(APPEND src ${WEBSERVER_BACKEND_SRC})

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

if(USING_STD_REGEX)
  target_compile_definitions(${BUILD_TARGET_NAME}-lib PUBLIC -DUSE_STD_REGEX)
endif()

if(HAVE_TO_STRING)
  target_compile_definitions(${BUILD_TARGET_NAME}-lib PUBLIC -DHAVE_TO_STRING)
endif()

if(USING_MALLOC_TRIM)
  target_compile_definitions(${BUILD_TARGET_NAME}-lib PUBLIC -DMALLOC_TRIM)
endif()

if(ATOMIC_FOUND)
    target_link_libraries(${BUILD_TARGET_NAME}-lib
        PUBLIC ${ATOMIC_LIBRARIES}
    )
endif()

if(SUBCONVERTER_WEBSERVER_BACKEND STREQUAL "libevent")
    if(LibEvent_FOUND)
        target_link_libraries(${BUILD_TARGET_NAME}-lib
            PUBLIC ${LIBEVENT_LIB}
        )
        target_include_directories(${BUILD_TARGET_NAME}-lib BEFORE
            PUBLIC ${LIBEVENT_INCLUDE_DIR}
        )
    else()
        target_link_libraries(${BUILD_TARGET_NAME}-lib
            PUBLIC event_core
            PUBLIC event_extra
        )
        if(NOT EVENT__DISABLE_OPENSSL)
            target_link_libraries(${BUILD_TARGET_NAME}-lib
                PUBLIC event_openssl
            )
        endif()
    endif()
elseif(SUBCONVERTER_WEBSERVER_BACKEND STREQUAL "kleinshttp")
    target_link_libraries(${BUILD_TARGET_NAME}-lib
        PUBLIC subconverter_kleinshttp
    )
endif()

target_include_directories(${BUILD_TARGET_NAME}-lib
    PUBLIC ${CMAKE_CURRENT_BINARY_DIR}
    PUBLIC ${CMAKE_CURRENT_LIST_DIR}/lib
)

if(NOT USING_STD_REGEX)
    target_include_directories(${BUILD_TARGET_NAME}-lib
        PUBLIC ${PCRE2_INCLUDE_DIR}
    )
endif()

target_link_libraries(${BUILD_TARGET_NAME}-lib
    PUBLIC ${CMAKE_THREAD_LIBS_INIT}
    PUBLIC ${CXX_FILESYSTEM_LIBS}
    PUBLIC CURL::libcurl
    # PUBLIC Rapidjson
    PUBLIC toml11::toml11
    PUBLIC yaml-cpp::yaml-cpp
    PUBLIC libcron
    PUBLIC quickjspp
    PUBLIC pantor::inja
    PUBLIC jpcre2
    # PUBLIC duktape
)

if(NOT USING_STD_REGEX)
    target_link_libraries(${BUILD_TARGET_NAME}-lib
        PUBLIC ${PCRE2_LIBRARY}
    )
endif()

if(USING_JINJA2CPP)
    target_link_libraries(${BUILD_TARGET_NAME}-lib
        PUBLIC jinja2cpp
    )
endif()

if(WIN32)
    target_link_libraries(${BUILD_TARGET_NAME}-lib
        PUBLIC wsock32
        PUBLIC ws2_32
        PUBLIC iphlpapi
    )
    if(MSVC)
        if(PThreads4W_FOUND)
            target_link_libraries(${BUILD_TARGET_NAME}-lib
                PUBLIC PThreads4W::PThreads4W
            )
        else()
            target_link_libraries(${BUILD_TARGET_NAME}-lib
                PUBLIC pthreads
            )
            target_compile_definitions(${BUILD_TARGET_NAME}-lib
                PUBLIC "PTW32_STATIC_LIB"
            )
        endif()
    endif()
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
    mingw_bundle_dll(${BUILD_TARGET_NAME})
    # add_custom_command(TARGET ${BUILD_TARGET_NAME} POST_BUILD
    #     COMMAND ${CMAKE_COMMAND} -E copy "$<TARGET_RUNTIME_DLLS:${BUILD_TARGET_NAME}>" "$<TARGET_FILE_DIR:${BUILD_TARGET_NAME}>"
    #     COMMAND_EXPAND_LISTS
    # )
endif()
