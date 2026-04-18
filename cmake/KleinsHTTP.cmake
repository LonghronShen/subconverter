set(SUBCONVERTER_KLEINSHTTP_SOURCE_DIR "${CMAKE_CURRENT_LIST_DIR}/../third_party/kleinsHTTP" CACHE PATH "Path to local kleinsHTTP source tree for host-side probing")

if(NOT EXISTS "${SUBCONVERTER_KLEINSHTTP_SOURCE_DIR}/source/httpServer/httpServer.cpp")
  message(FATAL_ERROR "kleinsHTTP source tree not found at ${SUBCONVERTER_KLEINSHTTP_SOURCE_DIR}")
endif()

add_library(subconverter_kleinshttp STATIC
  ${SUBCONVERTER_KLEINSHTTP_SOURCE_DIR}/source/httpParser/httpParser.cpp
  ${SUBCONVERTER_KLEINSHTTP_SOURCE_DIR}/source/httpServer/httpServer.cpp
  ${SUBCONVERTER_KLEINSHTTP_SOURCE_DIR}/source/socketBase/socketBase.cpp
  ${SUBCONVERTER_KLEINSHTTP_SOURCE_DIR}/source/packet/packet.cpp
  ${SUBCONVERTER_KLEINSHTTP_SOURCE_DIR}/source/tcpSocket/tcpSocket.cpp
  ${SUBCONVERTER_KLEINSHTTP_SOURCE_DIR}/source/sessionBase/sessionBase.cpp
  ${SUBCONVERTER_KLEINSHTTP_SOURCE_DIR}/source/tcpConnection/tcpConnection.cpp
  ${SUBCONVERTER_KLEINSHTTP_SOURCE_DIR}/source/connectionBase/connectionBase.cpp
  ${SUBCONVERTER_KLEINSHTTP_SOURCE_DIR}/source/metricsServer/metricsServer.cpp
  ${SUBCONVERTER_KLEINSHTTP_SOURCE_DIR}/source/metricBase/metricBase.cpp
  ${SUBCONVERTER_KLEINSHTTP_SOURCE_DIR}/source/counterMetric/counterMetric.cpp
  ${SUBCONVERTER_KLEINSHTTP_SOURCE_DIR}/source/histogramMetric/histogramMetric.cpp
  ${SUBCONVERTER_KLEINSHTTP_SOURCE_DIR}/source/gaugeMetric/gaugeMetric.cpp
)

target_include_directories(subconverter_kleinshttp PUBLIC
  ${SUBCONVERTER_KLEINSHTTP_SOURCE_DIR}/source
  ${SUBCONVERTER_KLEINSHTTP_SOURCE_DIR}
)

target_compile_features(subconverter_kleinshttp PUBLIC cxx_std_17)
