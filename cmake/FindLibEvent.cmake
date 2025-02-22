# - Find LibEvent (a cross event library)
# This module defines
# LIBEVENT_INCLUDE_DIR, where to find LibEvent headers
# LIBEVENT_LIB, LibEvent libraries
# LibEvent_FOUND, If false, do not try to use libevent

set(LibEvent_EXTRA_PREFIXES /usr/local /opt/local "$ENV{HOME}")
foreach(prefix ${LibEvent_EXTRA_PREFIXES})
  list(APPEND LibEvent_INCLUDE_PATHS "${prefix}/include")
  list(APPEND LibEvent_LIB_PATHS "${prefix}/lib")
endforeach()

find_path(LIBEVENT_INCLUDE_DIR event.h HINTS ${LibEvent_INCLUDE_PATHS})
find_library(LIBEVENT_LIB NAMES event HINTS ${LibEvent_LIB_PATHS})
find_library(LIBEVENT_CORE_LIB NAMES event_core HINTS ${LibEvent_LIB_PATHS})
find_library(LIBEVENT_EXTRA_LIB NAMES event_extra HINTS ${LibEvent_LIB_PATHS})
find_library(LIBEVENT_PTHREAD_LIB NAMES event_pthreads HINTS ${LibEvent_LIB_PATHS})

if (LIBEVENT_LIB AND LIBEVENT_INCLUDE_DIR AND (LIBEVENT_LIB OR (LIBEVENT_CORE_LIB AND LIBEVENT_EXTRA_LIB) OR LIBEVENT_PTHREAD_LIB))
  set(LibEvent_FOUND TRUE)
  if(LIBEVENT_CORE_LIB AND LIBEVENT_EXTRA_LIB)
    set(LIBEVENT_LIB ${LIBEVENT_CORE_LIB} ${LIBEVENT_EXTRA_LIB})
  else()
    set(LIBEVENT_LIB ${LIBEVENT_LIB})
  endif()
  if(LIBEVENT_PTHREAD_LIB)
    list(APPEND LIBEVENT_LIB ${LIBEVENT_PTHREAD_LIB})
  endif()
else ()
  set(LibEvent_FOUND FALSE)
endif ()

if (LibEvent_FOUND)
  if (NOT LibEvent_FIND_QUIETLY)
    message(STATUS "Found libevent: ${LIBEVENT_LIB}")
  endif ()
else ()
  if (LibEvent_FIND_REQUIRED)
    message(FATAL_ERROR "Could NOT find libevent and libevent_pthread.")
  endif ()
  message(STATUS "libevent and libevent_pthread NOT found.")
endif ()

mark_as_advanced(
  LIBEVENT_LIB
  LIBEVENT_INCLUDE_DIR
)