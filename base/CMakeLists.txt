file(GLOB_RECURSE res_files
    ${CMAKE_CURRENT_LIST_DIR}/*
)

foreach(res IN ITEMS ${res_files})
    get_filename_component(res_name ${res} NAME)
    if(res_name STREQUAL "CMakeLists.txt")
        continue()
    endif()
    file(RELATIVE_PATH buildDirRelFilePath "${CMAKE_CURRENT_LIST_DIR}" "${res}")
	message(STATUS "Copying \"${buildDirRelFilePath}\" to \"${CMAKE_RUNTIME_OUTPUT_DIRECTORY}\" ...")
    if(EXISTS "${res}")
	    configure_file("${res}" "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${buildDirRelFilePath}" COPYONLY)
    endif()
endforeach()
