#include <string>

#include "webserver.h"

#include "../utils/file_extra.h"
#include "../utils/logger.h"
#include "../utils/stl_extra.h"
#include "../utils/string.h"

struct MIME_type
{
    std::string extension;
    std::string mimetype;
};

static MIME_type mime_types[] = {{"html htm shtml","text/html"},
                                 {"css",           "text/css"},
                                 {"jpeg jpg",      "image/jpeg"},
                                 {"js",            "application/javascript"},
                                 {"txt",           "text/plain"},
                                 {"png",           "image/png"},
                                 {"ico",           "image/x-icon"},
                                 {"svg svgz",      "image/svg+xml"},
                                 {"woff",          "application/font-woff"},
                                 {"json",          "application/json"}};

static bool matchSpaceSeparatedList(const std::string& source, const std::string &target)
{
    string_size pos_begin = 0, pos_end, total = source.size();
    while(pos_begin < total)
    {
        pos_end = source.find(' ', pos_begin);
        if(pos_end == source.npos)
            pos_end = total;
        if(source.compare(pos_begin, pos_end - pos_begin, target) == 0)
            return true;
        pos_begin = pos_end + 1;
    }
    return false;
}

static std::string checkMIMEType(const std::string &filename)
{
    string_size name_begin = 0, name_end = 0;
    name_begin = filename.rfind('/');
    if(name_begin == filename.npos)
        name_begin = 0;
    name_end = filename.rfind('.');
    if(name_end == filename.npos || name_end < name_begin || name_end == filename.size() - 1)
        return "application/octet-stream";
    std::string extension = filename.substr(name_end + 1);
    for(MIME_type &x : mime_types)
        if(matchSpaceSeparatedList(x.extension, extension))
            return x.mimetype;
    return "application/octet-stream";
}

int WebServer::serveFile(const std::string &filename, std::string &content_type, std::string &return_data)
{
    std::string realname = serve_file_root + filename;
    if(filename.compare("/") == 0)
        realname += "index.html";
    if(!fileExist(realname))
        return 1;

    return_data = fileGet(realname, false);
    content_type = checkMIMEType(realname);
    writeLog(0, "file-server: serving '" + filename + "' type '" + content_type + "'", LOG_LEVEL_INFO);
    return 0;
}

int WebServer::process_request(Request &request, Response &response, std::string &return_data)
{
    writeLog(0, "handle_cmd:    " + request.method + " handle_uri:    " + request.url, LOG_LEVEL_VERBOSE);

    string_size pos = request.url.find("?");
    if(pos != request.url.npos)
    {
        request.argument = request.url.substr(pos + 1);
        request.url.erase(pos);
    }

    if(request.method == "OPTIONS")
    {
        for(responseRoute &x : responses)
            if(matchSpaceSeparatedList(replaceAllDistinct(request.postdata, ",", ""), x.method) && x.path == request.url)
                return 1;
        return -1;
    }

    for(responseRoute &x : responses)
    {
        if(x.method == request.method && x.path == request.url)
        {
            response_callback &rc = x.rc;
            try
            {
                return_data = rc(request, response);
                response.content_type = x.content_type;
            }
            catch(std::exception &e)
            {
                return_data = "Internal server error while processing request path '" + request.url + "' with arguments '" + request.argument + "'!";
                return_data += "\n  exception: ";
                return_data += type(e);
                return_data += "\n  what(): ";
                return_data += e.what();
                response.content_type = "text/plain";
                response.status_code = 500;
                writeLog(0, return_data, LOG_LEVEL_ERROR);
            }
            return 0;
        }
    }

    auto iter = redirect_map.find(request.url);
    if(iter != redirect_map.end())
    {
        return_data = iter->second;
        if(request.argument.size())
        {
            if(return_data.find("?") != return_data.npos)
                return_data += "&" + request.argument;
            else
                return_data += "?" + request.argument;
        }
        return 2;
    }

    if(serve_file)
    {
        if(request.method.compare("GET") == 0 && serveFile(request.url, response.content_type, return_data) == 0)
            return 0;
    }

    return -1;
}

void WebServer::stop_web_server()
{
    SERVER_EXIT_FLAG = true;
}

void WebServer::append_response(const std::string &method, const std::string &uri, const std::string &content_type, response_callback response)
{
    responseRoute rr;
    rr.method = method;
    rr.path = uri;
    rr.content_type = content_type;
    rr.rc = response;
    responses.emplace_back(std::move(rr));
}

void WebServer::append_redirect(const std::string &uri, const std::string &target)
{
    redirect_map[uri] = target;
}

void WebServer::reset_redirect()
{
    eraseElements(redirect_map);
}
