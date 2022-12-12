file(GLOB_RECURSE res_files CONFIGURE_DEPENDS
    ${CMAKE_CURRENT_LIST_DIR}/configuration/*
)

foreach(res IN ITEMS ${res_files})
    file(RELATIVE_PATH buildDirRelFilePath "${CMAKE_CURRENT_LIST_DIR}/configuration" "${res}")
    message(STATUS "Copying \"${buildDirRelFilePath}\" to \"${CMAKE_RUNTIME_OUTPUT_DIRECTORY}\" ...")
    if(EXISTS "${res}")
        configure_file("${res}" "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${buildDirRelFilePath}" COPYONLY)
    endif()
endforeach()
