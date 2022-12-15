file(GLOB_RECURSE res_files CONFIGURE_DEPENDS
    "${CMAKE_CURRENT_LIST_DIR}/configuration/*"
)

foreach(res IN ITEMS ${res_files})
    file(RELATIVE_PATH buildDirRelFilePath "${CMAKE_CURRENT_LIST_DIR}/configuration" "${res}")
    get_filename_component(buildDirRelFileDir "${buildDirRelFilePath}" DIRECTORY)
    file(MAKE_DIRECTORY "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${buildDirRelFileDir}")
    # configure_file("${res}" "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${buildDirRelFilePath}" COPYONLY)
    file(COPY_FILE "${res}" "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${buildDirRelFilePath}" RESULT ASSERT_COPY_RESULT)
    if(ASSERT_COPY_RESULT EQUAL 0)
        # message(STATUS "Copying \"${res}\" to \"${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${buildDirRelFilePath}\": success")
    else()
        message(STATUS "Copying \"${res}\" to \"${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${buildDirRelFilePath}\": fail")
    endif()
endforeach()
