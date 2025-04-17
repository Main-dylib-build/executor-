#include "../../ios_compat.h"
#include "HttpClient.h"
#include <iostream>
#include <string>
#include <vector>
#include <map>
#include <functional>
#include <chrono>
#include <thread>
#include <atomic>
#include <mutex>

#ifdef __APPLE__
#import <Foundation/Foundation.h>

namespace iOS {
namespace AdvancedBypass {

    // Constructor
    HttpClient::HttpClient(int defaultTimeout, bool useCache)
        : m_initialized(false),
          m_defaultTimeout(defaultTimeout),
          m_useCache(useCache),
          m_sessionConfig(nullptr),
          m_session(nullptr) {
    }
    
    // Destructor
    HttpClient::~HttpClient() {
        // Release NSURLSession and configuration with ARC-compatible bridging
        if (m_session) {
            // Use __bridge_transfer to transfer ownership from C++ to ARC
            NSURLSession* session = (__bridge_transfer NSURLSession*)m_session;
            m_session = nullptr;
            
            // No need to call release with ARC and __bridge_transfer
        }
        
        if (m_sessionConfig) {
            // Use __bridge_transfer to transfer ownership from C++ to ARC
            NSURLSessionConfiguration* config = (__bridge_transfer NSURLSessionConfiguration*)m_sessionConfig;
            m_sessionConfig = nullptr;
            
            // No need to call release with ARC and __bridge_transfer
        }
    }
    
    // Initialize the HTTP client
    bool HttpClient::Initialize() {
        // Check if already initialized
        if (m_initialized) {
            return true;
        }
        
        @try {
            // Create session configuration
            NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
            config.timeoutIntervalForRequest = m_defaultTimeout;
            config.timeoutIntervalForResource = m_defaultTimeout * 2;
            config.HTTPMaximumConnectionsPerHost = 5;
            
            // Setup cache policy based on settings
            config.requestCachePolicy = m_useCache ? 
                NSURLRequestReturnCacheDataElseLoad : 
                NSURLRequestReloadIgnoringLocalCacheData;
            
            // Set up headers to mimic a normal browser
            config.HTTPAdditionalHeaders = @{
                @"User-Agent": @"Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1",
                @"Accept": @"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
                @"Accept-Language": @"en-US,en;q=0.9"
            };
            
            // Store configuration with ARC-compatible bridging
            m_sessionConfig = (__bridge_retained void*)config;
            
            // Create session with ARC-compatible bridging
            NSURLSession* session = [NSURLSession sessionWithConfiguration:config];
            m_session = (__bridge_retained void*)session;
            
            m_initialized = true;
            return true;
        }
        @catch (NSException* exception) {
            std::cerr << "HttpClient::Initialize failed: " << [[exception reason] UTF8String] << std::endl;
            return false;
        }
    }
    
    // Send HTTP request with all parameters
    void HttpClient::SendRequest(const std::string& url, 
                               const std::string& method, 
                               const std::unordered_map<std::string, std::string>& headers,
                               const std::string& body, 
                               int timeout,
                               CompletionCallback callback) {
        // Ensure initialized
        if (!m_initialized && !Initialize()) {
            RequestResult result;
            result.success = false;
            result.errorCode = -1;
            result.errorMessage = "HTTP client failed to initialize";
            callback(result);
            return;
        }
        
        // Perform on background thread to avoid blocking
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), 
^
{
            @try {
                // Create URL
                NSString* urlString = [NSString stringWithUTF8String:url.c_str()];
                NSURL* nsUrl = [NSURL URLWithString:urlString];
                
                if (!nsUrl) {
                    RequestResult result;
                    result.success = false;
                    result.errorCode = -1;
                    result.errorMessage = "Invalid URL: " + url;
                    dispatch_async(dispatch_get_main_queue(), 
^
{
                        callback(result);
                    });
                    return;
                }
                
                // Create request
                NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:nsUrl];
                
                // Set method
                [request setHTTPMethod:[NSString stringWithUTF8String:method.c_str()]];
                
                // Set timeout
                if (timeout > 0) {
                    [request setTimeoutInterval:timeout];
                }
                
                // Set headers
                for (const auto& header : headers) {
                    NSString* key = [NSString stringWithUTF8String:header.first.c_str()];
                    NSString* value = [NSString stringWithUTF8String:header.second.c_str()];
                    [request setValue:value forHTTPHeaderField:key];
                }
                
                // Set body if not empty
                if (!body.empty()) {
                    NSData* bodyData = [NSData dataWithBytes:body.c_str() length:body.length()];
                    [request setHTTPBody:bodyData];
                }
                
                // Get session using proper ARC bridging
                NSURLSession* session = (__bridge NSURLSession*)m_session;
                
                // Create data task
                NSURLSessionDataTask* task = [session dataTaskWithRequest:request
                                                       completionHandler:
^
(NSData* data, NSURLResponse* response, NSError* error) {
                    // Create result object
                    RequestResult result;
                    
                    if (error) {
                        // Handle error
                        result.success = false;
                        result.errorCode = (int)[error code];
                        result.errorMessage = [[error localizedDescription] UTF8String];
                    } else {
                        // Handle success
                        NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
                        result.success = (httpResponse.statusCode >= 200 && httpResponse.statusCode < 300);
                        result.statusCode = (int)httpResponse.statusCode;
                        
                        // Get response data
                        if (data) {
                            result.data = std::vector<uint8_t>((uint8_t*)[data bytes], (uint8_t*)[data bytes] + [data length]);
                            result.text = std::string((const char*)[data bytes], [data length]);
                        }
                        
                        // Get headers
                        NSDictionary* respHeaders = httpResponse.allHeaderFields;
                        for (NSString* key in respHeaders) {
                            NSString* value = [respHeaders objectForKey:key];
                            result.headers[[key UTF8String]] = [value UTF8String];
                        }
                    }
                    
                    // Call callback on main thread
                    dispatch_async(dispatch_get_main_queue(), 
^
{
                        callback(result);
                    });
                }];
                
                // Start task
                [task resume];
            }
            @catch (NSException* exception) {
                RequestResult result;
                result.success = false;
                result.errorCode = -1;
                result.errorMessage = [[exception reason] UTF8String];
                
                dispatch_async(dispatch_get_main_queue(), 
^
{
                    callback(result);
                });
            }
        });
    }
    
    // GET request
    void HttpClient::Get(const std::string& url, CompletionCallback callback) {
        SendRequest(url, "GET", {}, "", m_defaultTimeout, callback);
    }
    
    // GET request with timeout
    void HttpClient::Get(const std::string& url, int timeout, CompletionCallback callback) {
        SendRequest(url, "GET", {}, "", timeout, callback);
    }
    
    // GET request with headers
    void HttpClient::Get(const std::string& url, 
                         const std::unordered_map<std::string, std::string>& headers,
                         CompletionCallback callback) {
        SendRequest(url, "GET", headers, "", m_defaultTimeout, callback);
    }
    
    // GET request with headers and timeout
    void HttpClient::Get(const std::string& url, 
                         const std::unordered_map<std::string, std::string>& headers,
                         int timeout,
                         CompletionCallback callback) {
        SendRequest(url, "GET", headers, "", timeout, callback);
    }
    
    // POST request
    void HttpClient::Post(const std::string& url, 
                         const std::string& body,
                         CompletionCallback callback) {
        std::unordered_map<std::string, std::string> headers = {
            {"Content-Type", "application/x-www-form-urlencoded"}
        };
        SendRequest(url, "POST", headers, body, m_defaultTimeout, callback);
    }
    
    // POST request with timeout
    void HttpClient::Post(const std::string& url, 
                         const std::string& body,
                         int timeout,
                         CompletionCallback callback) {
        std::unordered_map<std::string, std::string> headers = {
            {"Content-Type", "application/x-www-form-urlencoded"}
        };
        SendRequest(url, "POST", headers, body, timeout, callback);
    }
    
    // POST request with headers
    void HttpClient::Post(const std::string& url, 
                         const std::unordered_map<std::string, std::string>& headers,
                         const std::string& body,
                         CompletionCallback callback) {
        SendRequest(url, "POST", headers, body, m_defaultTimeout, callback);
    }
    
    // POST request with headers and timeout
    void HttpClient::Post(const std::string& url, 
                         const std::unordered_map<std::string, std::string>& headers,
                         const std::string& body,
                         int timeout,
                         CompletionCallback callback) {
        SendRequest(url, "POST", headers, body, timeout, callback);
    }
    
    // Upload file
    void HttpClient::UploadFile(const std::string& url, 
                               const std::string& filePath,
                               CompletionCallback callback) {
        UploadFile(url, filePath, {}, m_defaultTimeout, callback);
    }
    
    // Upload file with headers
    void HttpClient::UploadFile(const std::string& url,
                               const std::string& filePath,
                               const std::unordered_map<std::string, std::string>& headers,
                               CompletionCallback callback) {
        UploadFile(url, filePath, headers, m_defaultTimeout, callback);
    }
    
    // Upload file with headers and timeout
    void HttpClient::UploadFile(const std::string& url,
                               const std::string& filePath,
                               const std::unordered_map<std::string, std::string>& headers,
                               int timeout,
                               CompletionCallback callback) {
        // Ensure initialized
        if (!m_initialized && !Initialize()) {
            RequestResult result;
            result.success = false;
            result.errorCode = -1;
            result.errorMessage = "HTTP client failed to initialize";
            callback(result);
            return;
        }
        
        // Check if file exists
        NSString* nsFilePath = [NSString stringWithUTF8String:filePath.c_str()];
        if (![[NSFileManager defaultManager] fileExistsAtPath:nsFilePath]) {
            RequestResult result;
            result.success = false;
            result.errorCode = -1;
            result.errorMessage = "File not found: " + filePath;
            callback(result);
            return;
        }
        
        // Perform on background thread
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), 
^
{
            @try {
                // Create URL
                NSString* urlString = [NSString stringWithUTF8String:url.c_str()];
                NSURL* nsUrl = [NSURL URLWithString:urlString];
                
                if (!nsUrl) {
                    RequestResult result;
                    result.success = false;
                    result.errorCode = -1;
                    result.errorMessage = "Invalid URL: " + url;
                    dispatch_async(dispatch_get_main_queue(), 
^
{
                        callback(result);
                    });
                    return;
                }
                
                // Create request
                NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:nsUrl];
                [request setHTTPMethod:@"POST"];
                
                // Set timeout
                if (timeout > 0) {
                    [request setTimeoutInterval:timeout];
                }
                
                // Create boundary string for multipart
                NSString* boundary = [NSString stringWithFormat:@"Boundary-%@", [[NSUUID UUID] UUIDString]];
                NSString* contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
                [request setValue:contentType forHTTPHeaderField:@"Content-Type"];
                
                // Set custom headers
                for (const auto& header : headers) {
                    NSString* key = [NSString stringWithUTF8String:header.first.c_str()];
                    NSString* value = [NSString stringWithUTF8String:header.second.c_str()];
                    [request setValue:value forHTTPHeaderField:key];
                }
                
                // Create body data
                NSMutableData* body = [NSMutableData data];
                
                // Add start boundary
                [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
                
                // Get filename from path
                NSString* fileName = [[nsFilePath lastPathComponent] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]];
                
                // Add content disposition
                [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"file\"; filename=\"%@\"\r\n", fileName] dataUsingEncoding:NSUTF8StringEncoding]];
                
                // Add content type
                [body appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
                
                // Add file data
                NSData* fileData = [NSData dataWithContentsOfFile:nsFilePath];
                [body appendData:fileData];
                [body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
                
                // Add end boundary
                [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
                
                // Set body
                [request setHTTPBody:body];
                
                // Get session using proper ARC bridging
                NSURLSession* session = (__bridge NSURLSession*)m_session;
                
                // Create upload task
                NSURLSessionUploadTask* task = [session uploadTaskWithRequest:request
                                                                    fromData:body
                                                            completionHandler:
^
(NSData* data, NSURLResponse* response, NSError* error) {
                    // Create result object
                    RequestResult result;
                    
                    if (error) {
                        // Handle error
                        result.success = false;
                        result.errorCode = (int)[error code];
                        result.errorMessage = [[error localizedDescription] UTF8String];
                    } else {
                        // Handle success
                        NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
                        result.success = (httpResponse.statusCode >= 200 && httpResponse.statusCode < 300);
                        result.statusCode = (int)httpResponse.statusCode;
                        
                        // Get response data
                        if (data) {
                            result.data = std::vector<uint8_t>((uint8_t*)[data bytes], (uint8_t*)[data bytes] + [data length]);
                            result.text = std::string((const char*)[data bytes], [data length]);
                        }
                        
                        // Get headers
                        NSDictionary* respHeaders = httpResponse.allHeaderFields;
                        for (NSString* key in respHeaders) {
                            NSString* value = [respHeaders objectForKey:key];
                            result.headers[[key UTF8String]] = [value UTF8String];
                        }
                    }
                    
                    // Call callback on main thread
                    dispatch_async(dispatch_get_main_queue(), 
^
{
                        callback(result);
                    });
                }];
                
                // Start task
                [task resume];
            }
            @catch (NSException* exception) {
                RequestResult result;
                result.success = false;
                result.errorCode = -1;
                result.errorMessage = [[exception reason] UTF8String];
                
                dispatch_async(dispatch_get_main_queue(), 
^
{
                    callback(result);
                });
            }
        });
    }
}
}
#endif // __APPLE__
