#include <cstdio>
#include <string>
#include <filesystem>

#include <sys/stat.h>

#ifdef _WIN32
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#endif

#include "string.h"

bool isInScope(const std::string &path)
{
#ifdef _WIN32
    if(path.find(":\\") != path.npos || path.find("..") != path.npos)
        return false;
#else
    if(startsWith(path, "/") || path.find("..") != path.npos)
        return false;
#endif // _WIN32
    return true;
}

#if !defined(SUBCONVERTER_SHARED_LIB)
// TODO: Add preprocessor option to disable (open web service safety)
std::string fileGet(const std::string &path, bool scope_limit)
{
    std::string content;

    if(scope_limit && !isInScope(path))
        return std::string();

    std::FILE *fp = std::fopen(path.c_str(), "rb");
    if(fp)
    {
        std::fseek(fp, 0, SEEK_END);
        long tot = std::ftell(fp);
        /*
        char *data = new char[tot + 1];
        data[tot] = '\0';
        std::rewind(fp);
        std::fread(&data[0], 1, tot, fp);
        std::fclose(fp);
        content.assign(data, tot);
        delete[] data;
        */
        content.resize(tot);
        std::rewind(fp);
        std::fread(&content[0], 1, tot, fp);
        std::fclose(fp);
    }

    /*
    std::stringstream sstream;
    std::ifstream infile;
    infile.open(path, std::ios::binary);
    if(infile)
    {
        sstream<<infile.rdbuf();
        infile.close();
        content = sstream.str();
    }
    */
    return content;
}

bool fileExist(const std::string &path, bool scope_limit)
{
#if defined(_MSC_VER)
    //using c++17 standard, but may cause problem on clang
    return std::filesystem::exists(path);
#else
    if(scope_limit && !isInScope(path))
        return false;
    struct stat st;
    return stat(path.data(), &st) == 0 && S_ISREG(st.st_mode);
#endif
}
#endif

bool fileCopy(const std::string &source, const std::string &dest)
{
    std::FILE *src = std::fopen(source.c_str(), "rb");
    if(!src)
        return false;

    std::FILE *dst = std::fopen(dest.c_str(), "wb");
    if(!dst)
    {
        std::fclose(src);
        return false;
    }

    char buffer[8192];
    bool ok = true;
    while(true)
    {
        size_t n = std::fread(buffer, 1, sizeof(buffer), src);
        if(n > 0)
        {
            if(std::fwrite(buffer, 1, n, dst) != n)
            {
                ok = false;
                break;
            }
        }
        if(n < sizeof(buffer))
        {
            if(std::ferror(src))
                ok = false;
            break;
        }
    }

    if(std::fclose(src) != 0)
        ok = false;
    if(std::fclose(dst) != 0)
        ok = false;

    return ok;
}

int fileWrite(const std::string &path, const std::string &content, bool overwrite)
{
    /*
    std::fstream outfile;
    std::ios_base::openmode mode = overwrite ? std::ios_base::out : std::ios_base::app;
    mode |= std::ios_base::binary;
    outfile.open(path, mode);
    outfile << content;
    outfile.close();
    return 0;
    */
    const char *mode = overwrite ? "wb" : "ab";
    std::FILE *fp = std::fopen(path.c_str(), mode);
    std::fwrite(content.c_str(), 1, content.size(), fp);
    std::fclose(fp);
    return 0;
}
