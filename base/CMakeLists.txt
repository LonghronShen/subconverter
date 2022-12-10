file(GLOB_RECURSE res_files
    ${CMAKE_CURRENT_LIST_DIR}/*
)

foreach(res IN ITEMS ${res_files})
    get_filename_component(OUTPUT_FILE_WE ${INPUT_FILE} NAME_WE)
    file(RELATIVE_PATH buildDirRelFilePath "${CMAKE_CURRENT_LIST_DIR}" "${res}")
	message(STATUS "Copying \"${buildDirRelFilePath}\" to \"${CMAKE_RUNTIME_OUTPUT_DIRECTORY}\" ...")
	configure_file("${res}" "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${buildDirRelFilePath}" COPYONLY)
endforeach()
