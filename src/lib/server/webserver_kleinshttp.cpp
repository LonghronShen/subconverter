#include "webserver.h"

#include <chrono>
#include <list>
#include <string>
#include <thread>

#include <httpParser/httpParser.h>
#include <httpServer/httpServer.h>
#include <tcpSocket/tcpSocket.h>

#include "../utils/logger.h"

namespace {
kleins::httpMethod to_kleins_method(const std::string& method)
{
    if(method == "GET") return kleins::httpMethod::GET;
    if(method == "HEAD") return kleins::httpMethod::HEAD;
    if(method == "POST") return kleins::httpMethod::POST;
    if(method == "PUT") return kleins::httpMethod::PUT;
    if(method == "DELETE") return kleins::httpMethod::DELETE;
    if(method == "CONNECT") return kleins::httpMethod::CONNECT;
    if(method == "OPTIONS") return kleins::httpMethod::OPTIONS;
    if(method == "TRACE") return kleins::httpMethod::TRACE;
    return kleins::httpMethod::PATCH;
}

std::string build_argument_string(const std::map<std::string, std::string>& parameters)
{
    std::string out;
    bool first = true;
    for(const auto& kv : parameters)
    {
        if(!first)
            out += "&";
        first = false;
        out += kv.first;
        if(!kv.second.empty())
            out += "=" + kv.second;
    }
    return out;
}

std::list<std::string> make_response_headers(const Response& response)
{
    std::list<std::string> headers;
    for(const auto& kv : response.headers)
        headers.emplace_back(kv.first + ": " + kv.second);
    headers.emplace_back("Access-Control-Allow-Origin: *");
    headers.emplace_back("Connection: close");
    return headers;
}
}

int WebServer::start_web_server(void *argv)
{
    auto *args = reinterpret_cast<listener_args*>(argv);
    kleins::httpServer server;

    if(!server.addSocket(new kleins::tcpSocket(args->listen_address.c_str(), args->port)))
    {
        writeLog(0, "Failed to init kleinsHTTP server socket.", LOG_LEVEL_FATAL);
        return -1;
    }

    server.on(kleins::httpMethod::GET, "/healthz", [](kleins::httpParser* parser) {
        parser->respond("200", {}, "OK", "text/plain");
    });

    for(const auto& route : responses)
    {
        server.on(to_kleins_method(route.method), route.path, [this](kleins::httpParser* parser) {
            Request request;
            Response response;
            std::string body;

            request.method = parser->method;
            request.url = parser->path;
            request.argument = build_argument_string(parser->parameters);
            request.postdata = parser->body;
            for(const auto& kv : parser->headers)
                request.headers.emplace(kv.first, kv.second);

            int rc = process_request(request, response, body);
            auto headers = make_response_headers(response);
            const std::string content_type = response.content_type.empty() ? "text/plain" : response.content_type;

            switch(rc)
            {
            case 2:
                headers.emplace_back("Location: " + body);
                parser->respond("302", headers, "", "text/plain");
                break;
            case 1:
                headers.emplace_back("Access-Control-Allow-Headers: *");
                parser->respond(std::to_string(response.status_code), headers, "", content_type);
                break;
            case 0:
                parser->respond(std::to_string(response.status_code), headers, body, content_type);
                break;
            case -1:
            default:
                parser->respond("404", headers, "File not found.", "text/plain");
                break;
            }
        });
    }

    while(!SERVER_EXIT_FLAG.load())
    {
        if(args->looper_callback)
            args->looper_callback();
        std::this_thread::sleep_for(std::chrono::milliseconds(args->looper_interval));
    }

    return 0;
}

int WebServer::start_web_server_multi(void *argv)
{
    return start_web_server(argv);
}
