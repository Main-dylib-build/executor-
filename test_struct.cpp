#include <cstdio>
#include <string>
#include <unordered_map>

struct RequestResult {
    bool m_success;              // Request succeeded
    int m_statusCode;            // HTTP status code
    std::string m_error;         // Error message if any
    std::string m_content;       // Response content
    uint64_t m_requestTime;      // Request time in ms
    std::unordered_map<std::string, std::string> m_headers; // Response headers

    // Constructor for success case
    RequestResult(bool success = false, int statusCode = 0, const std::string& error = "",
                 const std::string& content = "", uint64_t requestTime = 0)
        : m_success(success), m_statusCode(statusCode), m_error(error),
          m_content(content), m_requestTime(requestTime) {}
};

int main() {
    printf("RequestResult structure layout:\n");
    printf("- m_success: %zu\n", offsetof(RequestResult, m_success));
    printf("- m_statusCode: %zu\n", offsetof(RequestResult, m_statusCode));
    printf("- m_error: %zu\n", offsetof(RequestResult, m_error));
    printf("- m_content: %zu\n", offsetof(RequestResult, m_content));
    printf("- m_requestTime: %zu\n", offsetof(RequestResult, m_requestTime));
    printf("- m_headers: %zu\n", offsetof(RequestResult, m_headers));
    return 0;
}
