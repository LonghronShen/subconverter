if(NOT SUBCONVERTER_WEBSERVER_BACKEND MATCHES "^(libevent|kleinshttp)$")
  message(FATAL_ERROR "SUBCONVERTER_WEBSERVER_BACKEND must be libevent or kleinshttp")
endif()
