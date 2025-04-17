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

    // Implementation of HttpClient for iOS
    
    // Cleanup previous session if exists
    void HttpClient::CleanupSession() {
        if (m_session) {
            // Use __bridge to cast the void* back to NSURLSession* with ARC
            NSURLSession* session = (__bridge_transfer NSURLSession*)m_session;
            m_session = nullptr;
            
            // No need to call release with ARC and __bridge_transfer
        }
        
        if (m_sessionConfig) {
            // Use __bridge to cast the void* back to NSURLSessionConfiguration* with ARC
            NSURLSessionConfiguration* config = (__bridge_transfer NSURLSessionConfiguration*)m_sessionConfig;
            m_sessionConfig = nullptr;
            
            // No need to call release with ARC and __bridge_transfer
        }
    }
    
    // Initialize HTTP client
    void HttpClient::Initialize() {
        // Create session configuration
        NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
        config.timeoutIntervalForRequest = 30.0;
        config.timeoutIntervalForResource = 60.0;
        config.HTTPMaximumConnectionsPerHost = 5;
        
        // Setup cache policy
        config.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
        
        // Additional headers
        config.HTTPAdditionalHeaders = @{
            @"User-Agent": @"Roblox/iOS",
            @"Accept": @"*/*",
            @"Accept-Language": @"en-us",
            @"Connection": @"keep-alive"
        };
        
        // Store the configuration with proper bridging
        m_sessionConfig = (__bridge_retained void*)config;
        
        // Create the session with the delegate
        NSURLSession* session = [NSURLSession sessionWithConfiguration:config
                                                              delegate:nil
                                                         delegateQueue:[NSOperationQueue mainQueue]];
        
        // Store the session with proper bridging
        m_session = (__bridge_retained void*)session;
    }
    
    // Perform an HTTP request
    void HttpClient::SendRequest(const std::string& url, 
                                 const std::string& method,
                                 const std::map<std::string, std::string>& headers,
                                 const std::string& body,
                                 const RequestCallback& callback) {
        // Check if session exists
        if (!m_session) {
            Initialize();
        }
        
        // Convert URL to NSString and create NSURL
        NSString* urlString = [NSString stringWithUTF8String:url.c_str()];
        NSURL* nsUrl = [NSURL URLWithString:urlString];
        
        // Create the request
        NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:nsUrl];
        
        // Set HTTP method
        [request setHTTPMethod:[NSString stringWithUTF8String:method.c_str()]];
        
        // Set headers
        for (const auto& header : headers) {
            NSString* key = [NSString stringWithUTF8String:header.first.c_str()];
            NSString* value = [NSString stringWithUTF8String:header.second.c_str()];
            [request setValue:value forHTTPHeaderField:key];
        }
        
        // Set body if not empty
        if (!body.empty()) {
            NSData* bodyData = [NSData dataWithBytes:body.c_str() length:body.size()];
            [request setHTTPBody:bodyData];
        }
        
        // Set cache policy
        bool useCache = ShouldUseCache(url, method);
        request.cachePolicy = useCache ? NSURLRequestReturnCacheDataElseLoad : NSURLRequestReloadIgnoringLocalCacheData;
        
        // Create the data task
        NSURLSession* session = (__bridge NSURLSession*)m_session;
        NSURLSessionDataTask* task = [session dataTaskWithRequest:request
                                                completionHandler:
^
(NSData* _Nullable data, NSURLResponse* _Nullable response, NSError* _Nullable error) {
            // Handle the response
            NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
            
            // Create response object
            Response resp;
            resp.statusCode = (int)httpResponse.statusCode;
            
            // Extract headers
            NSDictionary* respHeaders = httpResponse.allHeaderFields;
            for (NSString* key in respHeaders) {
                NSString* value = [respHeaders objectForKey:key];
                resp.headers[[key UTF8String]] = [value UTF8String];
            }
            
            // Extract body
            if (data) {
                resp.body = std::string((const char*)[data bytes], [data length]);
            }
            
            // Handle error
            if (error) {
                resp.error = [[error localizedDescription] UTF8String];
            }
            
            // Call the callback on the main thread
            dispatch_async(dispatch_get_main_queue(), 
^
{
                callback(resp);
            });
        }];
        
        // Start the task
        [task resume];
    }
    
    // GET request
    void HttpClient::Get(const std::string& url, const RequestCallback& callback) {
        SendRequest(url, "GET", {}, "", callback);
    }
    
    // GET request with headers
    void HttpClient::Get(const std::string& url, const std::map<std::string, std::string>& headers, const RequestCallback& callback) {
        SendRequest(url, "GET", headers, "", callback);
    }
    
    // POST request
    void HttpClient::Post(const std::string& url, const std::string& body, const RequestCallback& callback) {
        std::map<std::string, std::string> headers = {
            {"Content-Type", "application/x-www-form-urlencoded"}
        };
        SendRequest(url, "POST", headers, body, callback);
    }
    
    // POST request with custom headers
    void HttpClient::Post(const std::string& url, const std::map<std::string, std::string>& headers, 
                         const std::string& body, const RequestCallback& callback) {
        SendRequest(url, "POST", headers, body, callback);
    }
    
    // PUT request
    void HttpClient::Put(const std::string& url, const std::string& body, const RequestCallback& callback) {
        std::map<std::string, std::string> headers = {
            {"Content-Type", "application/x-www-form-urlencoded"}
        };
        SendRequest(url, "PUT", headers, body, callback);
    }
    
    // DELETE request
    void HttpClient::Delete(const std::string& url, const RequestCallback& callback) {
        SendRequest(url, "DELETE", {}, "", callback);
    }
    
    // Download file
    void HttpClient::DownloadFile(const std::string& url, const std::string& destination, 
                                  const ProgressCallback& progressCallback,
                                  const RequestCallback& callback) {
        // Check if session exists
        if (!m_session) {
            Initialize();
        }
        
        // Convert URL to NSString and create NSURL
        NSString* urlString = [NSString stringWithUTF8String:url.c_str()];
        NSURL* nsUrl = [NSURL URLWithString:urlString];
        
        // Create the request
        NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:nsUrl];
        
        // Create a download task
        NSURLSession* session = (__bridge NSURLSession*)m_session;
        NSURLSessionDownloadTask* task = [session downloadTaskWithRequest:request completionHandler:
^
(NSURL* _Nullable location, NSURLResponse* _Nullable response, NSError* _Nullable error) {
            
            Response resp;
            NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
            resp.statusCode = (int)httpResponse.statusCode;
            
            if (error) {
                resp.error = [[error localizedDescription] UTF8String];
                callback(resp);
                return;
            }
            
            if (location) {
                NSString* destPath = [NSString stringWithUTF8String:destination.c_str()];
                NSFileManager* fileManager = [NSFileManager defaultManager];
                
                // Move the downloaded file to the destination
                NSError* moveError = nil;
                [fileManager moveItemAtURL:location toURL:[NSURL fileURLWithPath:destPath] error:&moveError];
                
                if (moveError) {
                    resp.error = [[moveError localizedDescription] UTF8String];
                }
            }
            
            // Call the callback on the main thread
            dispatch_async(dispatch_get_main_queue(), 
^
{
                callback(resp);
            });
        }];
        
        // Start the task
        [task resume];
    }
    
    // Upload file
    void HttpClient::UploadFile(const std::string& url, const std::string& filePath, 
                              const std::map<std::string, std::string>& headers,
                              const ProgressCallback& progressCallback,
                              const RequestCallback& callback) {
        // Check if session exists
        if (!m_session) {
            Initialize();
        }
        
        // Create multipart form data
        NSString* boundary = [NSString stringWithFormat:@"Boundary-%@", [[NSUUID UUID] UUIDString]];
        NSString* contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
        
        // Create the request
        NSString* urlString = [NSString stringWithUTF8String:url.c_str()];
        NSURL* nsUrl = [NSURL URLWithString:urlString];
        NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:nsUrl];
        [request setHTTPMethod:@"POST"];
        [request setValue:contentType forHTTPHeaderField:@"Content-Type"];
        
        // Add custom headers
        for (const auto& header : headers) {
            NSString* key = [NSString stringWithUTF8String:header.first.c_str()];
            NSString* value = [NSString stringWithUTF8String:header.second.c_str()];
            [request setValue:value forHTTPHeaderField:key];
        }
        
        // Create the body data
        NSMutableData* body = [NSMutableData data];
        
        // Add the file data
        NSString* fileBoundary = [NSString stringWithFormat:@"--%@\r\n", boundary];
        [body appendData:[fileBoundary dataUsingEncoding:NSUTF8StringEncoding]];
        
        // Get filename from path
        NSString* nsFilePath = [NSString stringWithUTF8String:filePath.c_str()];
        NSString* fileName = [[nsFilePath lastPathComponent] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]];
        
        // Create content disposition
        NSString* contentDisposition = [NSString stringWithFormat:@"Content-Disposition: form-data; name=\"file\"; filename=\"%@\"\r\n", fileName];
        [body appendData:[contentDisposition dataUsingEncoding:NSUTF8StringEncoding]];
        
        // Add content type
        [body appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        
        // Read the file data
        NSData* fileData = [NSData dataWithContentsOfFile:nsFilePath];
        [body appendData:fileData];
        [body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        
        // Close the form data
        NSString* closingBoundary = [NSString stringWithFormat:@"--%@--\r\n", boundary];
        [body appendData:[closingBoundary dataUsingEncoding:NSUTF8StringEncoding]];
        
        // Set the body data
        [request setHTTPBody:body];
        
        // Create the upload task
        NSURLSession* session = (__bridge NSURLSession*)m_session;
        NSURLSessionUploadTask* task = [session uploadTaskWithRequest:request fromData:body completionHandler:
^
(NSData* _Nullable data, NSURLResponse* _Nullable response, NSError* _Nullable error) {
            
            Response resp;
            NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
            resp.statusCode = (int)httpResponse.statusCode;
            
            // Extract headers
            NSDictionary* respHeaders = httpResponse.allHeaderFields;
            for (NSString* key in respHeaders) {
                NSString* value = [respHeaders objectForKey:key];
                resp.headers[[key UTF8String]] = [value UTF8String];
            }
            
            // Extract body
            if (data) {
                resp.body = std::string((const char*)[data bytes], [data length]);
            }
            
            // Handle error
            if (error) {
                resp.error = [[error localizedDescription] UTF8String];
            }
            
            // Call the callback on the main thread
            dispatch_async(dispatch_get_main_queue(), 
^
{
                callback(resp);
            });
        }];
        
        // Start the task
        [task resume];
    }
    
    // Determine if we should use cache for this URL/method
    bool HttpClient::ShouldUseCache(const std::string& url, const std::string& method) {
        // Only use cache for GET requests
        if (method != "GET") {
            return false;
        }
        
        // Default to false - most requests should be fresh
        return false;
    }
    
    // Destructor
    HttpClient::~HttpClient() {
        CleanupSession();
    }
}
}
#endif // __APPLE__
