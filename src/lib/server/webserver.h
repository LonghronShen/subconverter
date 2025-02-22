#ifndef WEBSERVER_H_INCLUDED
#define WEBSERVER_H_INCLUDED

#include <atomic>
#include <curl/curlver.h>
#include <event2/http.h>
#include <map>
#include <string>

#include "../utils/map_extra.h"
#include "../utils/string.h"
#include <subconverter/version.h>

struct Request {
  std::string method;
  std::string url;
  std::string argument;
  string_icase_map headers;
  std::string postdata;
};

struct Response {
  int status_code = 200;
  std::string content_type;
  string_icase_map headers;
};

using response_callback = std::string (*)(
    Request &,
    Response &); // process arguments and POST data and return served-content

#define RESPONSE_CALLBACK_ARGS Request &request, Response &response

struct responseRouteWithCallback {
  std::string method;
  std::string path;
  std::string content_type;
  response_callback rc;
};

struct listener_args {
  std::string listen_address;
  int port;
  int max_conn;
  int max_workers;
  void (*looper_callback)() = nullptr;
  uint32_t looper_interval = 200;
};

struct responseRoute {
  std::string method;
  std::string path;
  std::string content_type;
  response_callback rc;
};

class WebServer {
public:
  std::string user_agent_str = "subconverter/" VERSION " cURL/" LIBCURL_VERSION;
  std::atomic_bool SERVER_EXIT_FLAG{false};

  // file server
  bool serve_file = false;
  std::string serve_file_root;

  // basic authentication
  bool require_auth = false;
  std::string auth_user, auth_password,
      auth_realm = "Please enter username and password:";

  void append_response(const std::string &method, const std::string &uri,
                       const std::string &content_type,
                       response_callback response);
  void append_redirect(const std::string &uri, const std::string &target);
  void reset_redirect();
  int start_web_server(void *argv);
  int start_web_server_multi(void *argv);
  void stop_web_server();

private:
  int serveFile(const std::string &filename, std::string &content_type,
                std::string &return_data);
  inline int process_request(Request &request, Response &response,
                             std::string &return_data);
  void on_request(evhttp_request *req, void *args);
  std::vector<responseRoute> responses;
  string_map redirect_map;
};

#endif // WEBSERVER_H_INCLUDED
