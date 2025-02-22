if(WIN32)
    add_compile_definitions("WIN32_LEAN_AND_MEAN" "_CRT_SECURE_NO_WARNINGS" "NOMINMAX")
    if(MSVC)
        add_compile_options("/source-charset:utf-8")

        if(NOT CMAKE_BUILD_TYPE)
            add_compile_options("/MT")
        else()
            add_compile_options("/MTd")
        endif()

        set(CompilerFlags
            CMAKE_CXX_FLAGS
            CMAKE_CXX_FLAGS_DEBUG
            CMAKE_CXX_FLAGS_RELEASE
            CMAKE_CXX_FLAGS_MINSIZEREL
            CMAKE_CXX_FLAGS_RELWITHDEBINFO
            CMAKE_C_FLAGS
            CMAKE_C_FLAGS_DEBUG
            CMAKE_C_FLAGS_RELEASE
            CMAKE_C_FLAGS_MINSIZEREL
            CMAKE_C_FLAGS_RELWITHDEBINFO)
        foreach(CompilerFlag ${CompilerFlags})
            string(REPLACE "/MD" "/MT" ${CompilerFlag} "${${CompilerFlag}}")
            set(${CompilerFlag} "${${CompilerFlag}}" CACHE STRING "msvc compiler flags" FORCE)
            message("MSVC flags: ${CompilerFlag}:${${CompilerFlag}}")
        endforeach()
    elseif(MINGW)
        add_compile_definitions("WIN32" "_WIN32")
    endif()
else()
    if(UNIX)
        if(APPLE)
            add_compile_options("-m64" "-fPIC" "-march=native")
            if(CMAKE_BUILD_TYPE STREQUAL "Debug")
                add_compile_options("-g" "-O0")
            else()
                add_compile_options("-O3")
            endif()
            set(CMAKE_MACOSX_RPATH 1 CACHE STRING "CMAKE_MACOSX_RPATH" FORCE)
            option(DISABLE_COTIRE "DISABLE_COTIRE" on)
            if(DISABLE_COTIRE)
                set(__COTIRE_INCLUDED TRUE CACHE BOOL "__COTIRE_INCLUDED" FORCE)
                function (cotire)
                endfunction()
            endif()
        else()
            add_compile_options("-fPIC")
            if(CMAKE_BUILD_TYPE STREQUAL "Debug")
                add_compile_options("-g")
            else()
                # add_compile_options("-O3")
            endif()
            if(CMAKE_SYSTEM_PROCESSOR MATCHES "(amd64)|(AMD64)")
                add_compile_options("-march=westmere")
            endif()
        endif()
    endif()
endif()

if(NOT MSVC)
  add_compile_options(-Wextra -Wno-unused-parameter -Wno-unused-result)
else()
  add_compile_options(/W4)
endif()

include(CheckCXXSourceCompiles)

check_cxx_source_compiles("
    #include<string>
    int main() {
        std::to_string(0);
    }" HAVE_TO_STRING)

include(find_filesystem)

include(CheckIPOSupported)
check_ipo_supported(RESULT lto_supported OUTPUT lto_error)

if(lto_supported)
    message(STATUS "IPO / LTO enabled")
    set(INTERPROCEDURAL_OPTIMIZATION TRUE CACHE BOOL "INTERPROCEDURAL_OPTIMIZATION" FORCE)
else()
    message(STATUS "IPO / LTO not supported: <${lto_error}>")
    set(INTERPROCEDURAL_OPTIMIZATION FALSE CACHE BOOL "INTERPROCEDURAL_OPTIMIZATION" FORCE)
endif()