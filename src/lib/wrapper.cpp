#if defined(SUBCONVERTER_SHARED_LIB)

#include <string>

#include "handler/settings.h"

Settings global;

bool fileExist(const std::string &, bool) { return false; }
std::string fileGet(const std::string &, bool) { return std::string(); }

#endif