#include <memory>
#include <cstdint>
#include <iostream>
#include <functional>
#include <thread>
#include <algorithm>
#include <string.h>

#include <evhttp.h>
#include <pthread.h>
#ifdef MALLOC_TRIM
#include <malloc.h>
#endif // MALLOC_TRIM

#include "../utils/base64/base64.h"
#include "../utils/logger.h"
#include "../utils/urlencode.h"
#include "socket.h"
#include "webserver.h"

template <typename Lambda, class Ret, class... Args, class Pointer = Ret (*)(Args...)>
Pointer deduced_wrap(
    const std::function<Ret(Args...)> &func)
{
    static auto saved = func;
    static Pointer p = [](Args... args) {
        return saved(std::forward<Args>(args)...);
    };
    return p;
}

template <typename Lambda>
auto *wrap(Lambda &&func)
{
    return deduced_wrap<Lambda>(std::function{func});
}

const char *request_header_blacklist[] = {"host", "accept", "accept-encoding"};

static inline void buffer_cleanup(struct evbuffer *eb)
{
    (void)eb;
    //evbuffer_free(eb);
#ifdef MALLOC_TRIM
    malloc_trim(0);
#endif // MALLOC_TRIM
}

void WebServer::on_request(void *req_ptr, void *args)
{
    (void)args;
    auto *req = reinterpret_cast<evhttp_request*>(req_ptr);
    static std::string auth_token = "Basic " + base64Encode(auth_user + ":" + auth_password);
    const char *req_content_type = evhttp_find_header(req->input_headers, "Content-Type"), *req_ac_method = evhttp_find_header(req->input_headers, "Access-Control-Request-Method");
    const char *uri = req->uri, *internal_flag = evhttp_find_header(req->input_headers, "SubConverter-Request");

#ifdef MSVC
    const char *client_ip;
#else
    char *client_ip;
#endif

    u_short client_port;
    evhttp_connection_get_peer(evhttp_request_get_connection(req), &client_ip, &client_port);
    //std::cerr<<"Accept connection from client "<<client_ip<<":"<<client_port<<"\n";
    writeLog(0, "Accept connection from client " + std::string(client_ip) + ":" + std::to_string(client_port), LOG_LEVEL_DEBUG);

    if (internal_flag != nullptr)
    {
        evhttp_send_error(req, 500, "Loop request detected!");
        return;
    }

    if (require_auth)
    {
        const char *auth = evhttp_find_header(req->input_headers, "Authorization");
        if (auth == nullptr || auth_token != auth)
        {
            evhttp_add_header(req->output_headers, "WWW-Authenticate", ("Basic realm=\"" + auth_realm + "\"").data());
            auto buffer = evhttp_request_get_output_buffer(req);
            evbuffer_add_printf(buffer, "Unauthorized");
            evhttp_send_reply(req, 401, nullptr, buffer);
            buffer_cleanup(buffer);
            return;
        }
    }

    Request request;
    Response response;
    size_t buffer_len = evbuffer_get_length(req->input_buffer);
    if (buffer_len != 0)
    {
        request.postdata.assign(reinterpret_cast<char*>(evbuffer_pullup(req->input_buffer, -1)), buffer_len);
        if(req_content_type != nullptr && strcmp(req_content_type, "application/x-www-form-urlencoded") == 0)
            request.postdata = urlDecode(request.postdata);
    }
    else if (req_ac_method != nullptr)
    {
        request.postdata.assign(req_ac_method);
    }

    switch (req->type)
    {
        case EVHTTP_REQ_GET: request.method = "GET"; break;
        case EVHTTP_REQ_POST: request.method = "POST"; break;
        case EVHTTP_REQ_OPTIONS: request.method = "OPTIONS"; break;
        case EVHTTP_REQ_PUT: request.method = "PUT"; break;
        case EVHTTP_REQ_PATCH: request.method = "PATCH"; break;
        case EVHTTP_REQ_DELETE: request.method = "DELETE"; break;
        case EVHTTP_REQ_HEAD: request.method = "HEAD"; break;
        default: break;
    }
    request.url = uri;

    struct evkeyval* kv = req->input_headers->tqh_first;
    while (kv)
    {
        if(std::none_of(std::begin(request_header_blacklist), std::end(request_header_blacklist), [&](auto x){ return strcasecmp(kv->key, x) == 0; }))
            request.headers.emplace(kv->key, kv->value);
        kv = kv->next.tqe_next;
    }
    request.headers.emplace("X-Client-IP", client_ip);

    std::string return_data;
    int retVal = process_request(request, response, return_data);
    std::string &content_type = response.content_type;

    auto *output_buffer = evhttp_request_get_output_buffer(req);
    if (!output_buffer)
    {
        evhttp_send_error(req, HTTP_INTERNAL, nullptr);
        return;
    }

    for (auto &x : response.headers)
        evhttp_add_header(req->output_headers, x.first.data(), x.second.data());

    switch (retVal)
    {
    case 1: //found OPTIONS
        evhttp_add_header(req->output_headers, "Access-Control-Allow-Origin", "*");
        evhttp_add_header(req->output_headers, "Access-Control-Allow-Headers", "*");
        evhttp_send_reply(req, response.status_code, nullptr, nullptr);
        break;
    case 2: //found redirect
        evhttp_add_header(req->output_headers, "Location", return_data.c_str());
        evhttp_send_reply(req, HTTP_MOVETEMP, nullptr, nullptr);
        break;
    case 0: //found normal
        if (content_type.size())
            evhttp_add_header(req->output_headers, "Content-Type", content_type.c_str());
        evhttp_add_header(req->output_headers, "Access-Control-Allow-Origin", "*");
        evhttp_add_header(req->output_headers, "Connection", "close");
        evbuffer_add(output_buffer, return_data.data(), return_data.size());
        evhttp_send_reply(req, response.status_code, nullptr, output_buffer);
        break;
    case -1: //not found
        return_data = "File not found.";
        evbuffer_add(output_buffer, return_data.data(), return_data.size());
        evhttp_send_reply(req, HTTP_NOTFOUND, nullptr, output_buffer);
        //evhttp_send_error(req, HTTP_NOTFOUND, "Resource not found");
        break;
    default: //undefined behavior
        evhttp_send_error(req, HTTP_INTERNAL, nullptr);
    }
    buffer_cleanup(output_buffer);
}

int WebServer::start_web_server(void *argv)
{
    struct listener_args *args = reinterpret_cast<listener_args*>(argv);
    std::string listen_address = args->listen_address;
    int port = args->port;
    if (!event_init())
    {
        //std::cerr << "Failed to init libevent." << std::endl;
        writeLog(0, "Failed to init libevent.", LOG_LEVEL_FATAL);
        return -1;
    }
    const char *SrvAddress = listen_address.c_str();
    std::uint16_t SrvPort = port;
    std::unique_ptr<evhttp, decltype(&evhttp_free)> server(evhttp_start(SrvAddress, SrvPort), &evhttp_free);
    if (!server)
    {
        //std::cerr << "Failed to init http server." << std::endl;
        writeLog(0, "Failed to init http server.", LOG_LEVEL_FATAL);
        return -1;
    }

    auto call_on_request = [&](evhttp_request *req, void *args) { on_request(reinterpret_cast<void*>(req), args); };

    evhttp_set_allowed_methods(server.get(), EVHTTP_REQ_GET | EVHTTP_REQ_POST | EVHTTP_REQ_OPTIONS | EVHTTP_REQ_PUT | EVHTTP_REQ_PATCH | EVHTTP_REQ_DELETE | EVHTTP_REQ_HEAD);
    evhttp_set_gencb(server.get(), wrap(call_on_request), nullptr);
    evhttp_set_timeout(server.get(), 30);
    if (event_dispatch() == -1)
    {
        //std::cerr << "Failed to run message loop." << std::endl;
        writeLog(0, "Failed to run message loop.", LOG_LEVEL_FATAL);
        return -1;
    }

    return 0;
}

void* httpserver_dispatch(void *arg)
{
    event_base_dispatch(reinterpret_cast<event_base*>(arg));
    event_base_free(reinterpret_cast<event_base*>(arg)); //free resources
    return nullptr;
}

int httpserver_bindsocket(std::string listen_address, int listen_port, int backlog)
{
    SOCKET nfd;
    nfd = socket(AF_INET, SOCK_STREAM, 0);
    if (nfd <= 0)
        return -1;

    int one = 1;
    if (setsockopt(nfd, SOL_SOCKET, SO_REUSEADDR, (char *)&one, sizeof(int)) < 0)
    {
        closesocket(nfd);
        return -1;
    }
#ifdef SO_NOSIGPIPE
    if (setsockopt(nfd, SOL_SOCKET, SO_NOSIGPIPE, (char *)&one, sizeof(int)) < 0)
    {
        closesocket(nfd);
        return -1;
    }
#endif

    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = inet_addr(listen_address.data());
    addr.sin_port = htons(listen_port);

    if (::bind(nfd, reinterpret_cast<sockaddr*>(&addr), sizeof(addr)) < 0 || listen(nfd, backlog) < 0)
    {
        closesocket(nfd);
        return -1;
    }

    unsigned long ul = 1;
    ioctlsocket(nfd, FIONBIO, &ul); //set to non-blocking mode

    return nfd;
}

int WebServer::start_web_server_multi(void *argv)
{
    struct listener_args *args = reinterpret_cast<listener_args*>(argv);
    std::string listen_address = args->listen_address;
    int port = args->port, nthreads = args->max_workers, max_conn = args->max_conn;

    auto call_on_request = [&](evhttp_request *req, void *args) { on_request(reinterpret_cast<void*>(req), args); };

    int nfd = httpserver_bindsocket(listen_address, port, max_conn);
    if (nfd < 0)
        return -1;

    std::vector<pthread_t> ths(nthreads);
    std::vector<struct event_base *> base(nthreads);
    for (int i = 0; i < nthreads; i++)
    {
        base[i] = event_init();
        if (base[i] == nullptr)
            return -1;
        struct evhttp *httpd = evhttp_new(base[i]);
        if (httpd == nullptr)
            return -1;
        if (evhttp_accept_socket(httpd, nfd) != 0)
            return -1;

        evhttp_set_allowed_methods(httpd, EVHTTP_REQ_GET | EVHTTP_REQ_POST | EVHTTP_REQ_OPTIONS | EVHTTP_REQ_PUT | EVHTTP_REQ_PATCH | EVHTTP_REQ_DELETE | EVHTTP_REQ_HEAD);
        evhttp_set_gencb(httpd, wrap(call_on_request), nullptr);
        evhttp_set_timeout(httpd, 30);
        if (pthread_create(&ths[i], nullptr, httpserver_dispatch, base[i]) != 0)
            return -1;
    }
    while (!SERVER_EXIT_FLAG)
    {
        if (args->looper_callback != nullptr)
            args->looper_callback();
        std::this_thread::sleep_for(std::chrono::milliseconds(args->looper_interval)); //block forever until receive stop signal
    }

    for (int i = 0; i < nthreads; i++)
        event_base_loopbreak(base[i]); //stop the loop

    shutdown(nfd, SD_BOTH); //stop accept call
    closesocket(nfd); //close listener socket

    return 0;
}

