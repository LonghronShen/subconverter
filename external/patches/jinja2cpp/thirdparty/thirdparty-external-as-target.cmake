message(STATUS "'external-as-target' dependencies mode selected for Jinja2Cpp. All dependencies are used as targets.")

add_subdirectory(thirdparty/nonstd/expected-lite EXCLUDE_FROM_ALL)
add_subdirectory(thirdparty/nonstd/variant-lite EXCLUDE_FROM_ALL)
add_subdirectory(thirdparty/nonstd/optional-lite EXCLUDE_FROM_ALL)
add_subdirectory(thirdparty/nonstd/string-view-lite EXCLUDE_FROM_ALL)

include (./thirdparty/external_boost_deps.cmake)

target_link_libraries(jinja2cpp
    PUBLIC expected-lite
    PUBLIC variant-lite
    PUBLIC optional-lite
    PUBLIC string-view-lite
    PRIVATE ${Boost_LIBRARIES}
    PRIVATE fmt::fmt
)