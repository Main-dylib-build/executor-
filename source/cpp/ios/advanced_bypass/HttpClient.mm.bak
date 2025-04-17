
#include "../../ios_compat.h"
#include "HttpClient.h"
#include <iostream>
#include <chrono>
#include <thread>
#include <mutex>
#include <condition_variable>

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
        // Release NSURLSession and configuration (manual memory management)
        if (m_session) {
            NSURLSession* session = (NSURLSession*)m_session;
            [session release];
            m_session = nullptr;
        }
        
        if (m_sessionConfig) {
            NSURLSessionConfiguration* config = (NSURLSessionConfiguration*)m_sessionConfig;
            [config release];
            m_sessionConfig = nullptr;
        }
    }
    
    // Initialize the HTTP client
    bool HttpClient::Initialize() {
        if (m_initialized) {
            return true;
        }
        
        @autoreleasepool {
            // Create session configuration
            NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
            config.timeoutIntervalForRequest = m_defaultTimeout;
            config.timeoutIntervalForResource = m_defaultTimeout;
            
            // Set up headers to mimic a normal browser
            config.HTTPAdditionalHeaders = @{
                @"User-Agent": @"Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1",
                @"Accept": @"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
                @"Accept-Language": @"en-US,en;q=0.9"
            };
            
            // Store configuration (manual retain)
            m_sessionConfig = (void*)config;
            [config retain];
            
            // Create session (manual retain)
            NSURLSession* session = [NSURLSession sessionWithConfiguration:config];
            m_session = (void*)session;
            [session retain];
            
            m_initialized = true;
            return true;
        }
    }
    
    // Synchronous HTTP GET request
    HttpClient::RequestResult HttpClient::Get(const std::string& url, int timeout) {
        // Initialize if needed
        if (!m_initialized && !Initialize()) {
            return RequestResult(false, 0, "Failed to initialize HTTP client", "", 0);
        }
        
        // Validate URL
        if (!ValidateUrl(url)) {
            return RequestResult(false, 0, "Invalid URL: " + url, "", 0);
        }
        
        // Check cache
        if (m_useCache) {
            RequestResult cachedResult = GetFromCacheIfAvailable(url);
            if (cachedResult.m_success) {
                return cachedResult;
            }
        }
        
        // Create semaphore for synchronous request
        std::mutex mutex;
        std::condition_variable cv;
        bool requestComplete = false;
        RequestResult result;
        
        // Send async request and wait for completion
        SendRequest(url, "GET", {}, "", timeout > 0 ? timeout : m_defaultTimeout, 
                   [&mutex, &cv, &requestComplete, &result](const RequestResult& asyncResult) {
                       std::lock_guard<std::mutex> lock(mutex);
                       result = asyncResult;
                       requestComplete = true;
                       cv.notify_one();
                   });
        
        // Wait for completion with timeout
        {
            std::unique_lock<std::mutex> lock(mutex);
            if (!cv.wait_for(lock, std::chrono::seconds(timeout > 0 ? timeout : m_defaultTimeout),
                            [&requestComplete]() { return requestComplete; })) {
                return RequestResult(false, 0, "Request timed out: " + url, "", 0);
            }
        }
        
        // Cache result if successful
        if (result.m_success && m_useCache) {
            AddToCacheIfNeeded(url, result);
        }
        
        return result;
    }
    
    // Asynchronous HTTP GET request
    void HttpClient::GetAsync(const std::string& url, CompletionCallback callback, int timeout) {
        // Initialize if needed
        if (!m_initialized && !Initialize()) {
            if (callback) {
                callback(RequestResult(false, 0, "Failed to initialize HTTP client", "", 0));
            }
            return;
        }
        
        // Validate URL
        if (!ValidateUrl(url)) {
            if (callback) {
                callback(RequestResult(false, 0, "Invalid URL: " + url, "", 0));
            }
            return;
        }
        
        // Check cache
        if (m_useCache) {
            RequestResult cachedResult = GetFromCacheIfAvailable(url);
            if (cachedResult.m_success) {
                if (callback) {
                    callback(cachedResult);
                }
                return;
            }
        }
        
        // Create completion wrapper to handle caching
        CompletionCallback wrappedCallback = [this, url, callback](const RequestResult& result) {
            // Cache result if successful
            if (result.m_success && m_useCache) {
                AddToCacheIfNeeded(url, result);
            }
            
            // Call original callback
            if (callback) {
                callback(result);
            }
        };
        
        // Send request
        SendRequest(url, "GET", {}, "", timeout > 0 ? timeout : m_defaultTimeout, wrappedCallback);
    }
    
    // Synchronous HTTP POST request
    HttpClient::RequestResult HttpClient::Post(const std::string& url, const std::string& body, int timeout) {
        // Initialize if needed
        if (!m_initialized && !Initialize()) {
            return RequestResult(false, 0, "Failed to initialize HTTP client", "", 0);
        }
        
        // Validate URL
        if (!ValidateUrl(url)) {
            return RequestResult(false, 0, "Invalid URL: " + url, "", 0);
        }
        
        // Create semaphore for synchronous request
        std::mutex mutex;
        std::condition_variable cv;
        bool requestComplete = false;
        RequestResult result;
        
        // Default headers for POST
        std::unordered_map<std::string, std::string> headers = {
            {"Content-Type", "application/x-www-form-urlencoded"}
        };
        
        // Send async request and wait for completion
        SendRequest(url, "POST", headers, body, timeout > 0 ? timeout : m_defaultTimeout, 
                   [&mutex, &cv, &requestComplete, &result](const RequestResult& asyncResult) {
                       std::lock_guard<std::mutex> lock(mutex);
                       result = asyncResult;
                       requestComplete = true;
                       cv.notify_one();
                   });
        
        // Wait for completion with timeout
        {
            std::unique_lock<std::mutex> lock(mutex);
            if (!cv.wait_for(lock, std::chrono::seconds(timeout > 0 ? timeout : m_defaultTimeout),
                            [&requestComplete]() { return requestComplete; })) {
                return RequestResult(false, 0, "Request timed out: " + url, "", 0);
            }
        }
        
        return result;
    }
    
    // Asynchronous HTTP POST request
    void HttpClient::PostAsync(const std::string& url, const std::string& body, 
                             CompletionCallback callback, int timeout) {
        // Initialize if needed
        if (!m_initialized && !Initialize()) {
            if (callback) {
                callback(RequestResult(false, 0, "Failed to initialize HTTP client", "", 0));
            }
            return;
        }
        
        // Validate URL
        if (!ValidateUrl(url)) {
            if (callback) {
                callback(RequestResult(false, 0, "Invalid URL: " + url, "", 0));
            }
            return;
        }
        
        // Default headers for POST
        std::unordered_map<std::string, std::string> headers = {
            {"Content-Type", "application/x-www-form-urlencoded"}
        };
        
        // Send request
        SendRequest(url, "POST", headers, body, timeout > 0 ? timeout : m_defaultTimeout, callback);
    }
    
    // Set the default timeout
    void HttpClient::SetDefaultTimeout(int timeout) {
        m_defaultTimeout = timeout;
        
        // Update session configuration if initialized
        if (m_initialized && m_sessionConfig) {
            NSURLSessionConfiguration* config = (__bridge NSURLSessionConfiguration*)m_sessionConfig;
            config.timeoutIntervalForRequest = timeout;
            config.timeoutIntervalForResource = timeout;
        }
    }
    
    // Get the default timeout
    int HttpClient::GetDefaultTimeout() const {
        return m_defaultTimeout;
    }
    
    // Enable or disable response caching
    void HttpClient::SetUseCache(bool useCache) {
        m_useCache = useCache;
    }
    
    // Check if response caching is enabled
    bool HttpClient::GetUseCache() const {
        return m_useCache;
    }
    
    // Clear the response cache
    void HttpClient::ClearCache() {
        m_cache.clear();
    }
    
    // Check if a URL is cached
    bool HttpClient::IsUrlCached(const std::string& url) const {
        return m_cache.find(NormalizeUrl(url)) != m_cache.end();
    }
    
    // Send HTTP request
    void HttpClient::SendRequest(const std::string& url, const std::string& method, 
                               const std::unordered_map<std::string, std::string>& headers,
                               const std::string& body, int timeout, CompletionCallback callback) {
        @autoreleasepool {
            // Start timing
            auto startTime = std::chrono::high_resolution_clock::now();
            
            // Create URL
            NSURL* nsUrl = [NSURL URLWithString:[NSString stringWithUTF8String:url.c_str()]];
            if (!nsUrl) {
                if (callback) {
                    callback(RequestResult(false, 0, "Invalid URL: " + url, "", 0));
                }
                return;
            }
            
            // Create request
            NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:nsUrl];
            request.HTTPMethod = [NSString stringWithUTF8String:method.c_str()];
            request.timeoutInterval = timeout;
            
            // Add headers
            for (const auto& header : headers) {
                [request setValue:[NSString stringWithUTF8String:header.second.c_str()] 
                  forHTTPHeaderField:[NSString stringWithUTF8String:header.first.c_str()]];
            }
            
            // Add body if needed
            if (!body.empty()) {
                request.HTTPBody = [NSData dataWithBytes:body.c_str() length:body.size()];
            }
            
            // Get session
            NSURLSession* session = (__bridge NSURLSession*)m_session;
            
            // Create data task
            NSURLSessionDataTask* task = [session dataTaskWithRequest:request 
                                                   completionHandler:^(NSData* data, NSURLResponse* response, NSError* error) {
                // Get status code
                NSInteger statusCode = 0;
                if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                    statusCode = [(NSHTTPURLResponse*)response statusCode];
                }
                
                // Check for error
                if (error) {
                    // Calculate request time
                    auto endTime = std::chrono::high_resolution_clock::now();
                    uint64_t requestTime = std::chrono::duration_cast<std::chrono::milliseconds>(endTime - startTime).count();
                    
                    // Build error result
                    std::string errorMsg = [[error localizedDescription] UTF8String];
                    if (callback) {
                        callback(RequestResult(false, statusCode, errorMsg, "", requestTime));
                    }
                    return;
                }
                
                // Get response data
                std::string content;
                if (data) {
                    content = std::string((const char*)[data bytes], [data length]);
                }
                
                // Calculate request time
                auto endTime = std::chrono::high_resolution_clock::now();
                uint64_t requestTime = std::chrono::duration_cast<std::chrono::milliseconds>(endTime - startTime).count();
                
                // Call callback with result
                if (callback) {
                    callback(RequestResult(true, statusCode, "", content, requestTime));
                }
            }];
            
            // Start task
            [task resume];
        }
    }
    
    // Validate URL
    bool HttpClient::ValidateUrl(const std::string& url) {
        @autoreleasepool {
            NSURL* nsUrl = [NSURL URLWithString:[NSString stringWithUTF8String:url.c_str()]];
            if (!nsUrl) {
                return false;
            }
            
            // Check scheme
            NSString* scheme = [nsUrl scheme];
            if (!scheme) {
                return false;
            }
            
            // Allow HTTP and HTTPS
            return [scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"];
        }
    }
    
    // Normalize URL for caching
    std::string HttpClient::NormalizeUrl(const std::string& url) const {
        @autoreleasepool {
            NSURL* nsUrl = [NSURL URLWithString:[NSString stringWithUTF8String:url.c_str()]];
            if (!nsUrl) {
                return url;
            }
            
            // Use absoluteString for normalized URL
            return [[nsUrl absoluteString] UTF8String];
        }
    }
    
    // Check if response should be cached
    bool HttpClient::ShouldUseCache(const std::string& url, const std::string& method) {
        // Only cache GET requests
        return m_useCache && method == "GET";
    }
    
    // Add response to cache
    void HttpClient::AddToCacheIfNeeded(const std::string& url, const RequestResult& result) {
        if (!m_useCache) {
            return;
        }
        
        // Only cache successful responses
        if (!result.m_success) {
            return;
        }
        
        // Add to cache
        m_cache[NormalizeUrl(url)] = result;
    }
    
    // Get response from cache
    HttpClient::RequestResult HttpClient::GetFromCacheIfAvailable(const std::string& url) {
        // Check if URL is in cache
        auto it = m_cache.find(NormalizeUrl(url));
        if (it != m_cache.end()) {
            return it->second;
        }
        
        // Not in cache
        return RequestResult();
    }
    
    // Get Lua code for HTTP functions
    std::string HttpClient::GetHttpFunctionsCode() {
        return R"(
-- Create the game table if it doesn't exist
game = game or {}

-- Implementation of game:HttpGet function
function game:HttpGet(url, cache)
    -- Default cache to true if not specified
    if cache == nil then cache = true end
    
    -- Call native HTTP GET function
    local success, result = pcall(function()
        -- In a real implementation, this would call a native C++ function
        -- For now, we'll simulate the result
        if url and type(url) == "string" and #url > 0 then
            -- Call _httpGet function if available
            if _httpGet then
                return _httpGet(url, cache)
            else
                error("HTTP request functionality not available")
            end
        else
            error("Invalid URL")
        end
    end)
    
    -- Handle errors
    if not success then
        error("HttpGet failed: " .. tostring(result), 2)
    end
    
    return result
end

-- Async variant
function game:HttpGetAsync(url, callback)
    -- Argument validation
    if type(url) ~= "string" or #url == 0 then
        error("Invalid URL", 2)
    end
    
    -- Use callback if provided
    if callback and type(callback) == "function" then
        -- Call native async function
        if _httpGetAsync then
            _httpGetAsync(url, function(success, result)
                if success then
                    callback(result)
                else
                    callback(nil, result) -- Pass error as second argument
                end
            end)
        else
            -- Fall back to sync version
            local success, result = pcall(function()
                return game:HttpGet(url)
            end)
            
            if success then
                callback(result)
            else
                callback(nil, result)
            end
        end
        
        return -- No return value for async with callback
    else
        -- If no callback, just use sync version
        return game:HttpGet(url)
    end
end

-- Implementation of game:HttpPost function
function game:HttpPost(url, data, contentType, compress)
    -- Default parameters
    contentType = contentType or "application/json"
    compress = compress or false
    
    -- Call native HTTP POST function
    local success, result = pcall(function()
        -- In a real implementation, this would call a native C++ function
        if url and type(url) == "string" and #url > 0 then
            -- Call _httpPost function if available
            if _httpPost then
                return _httpPost(url, data, contentType, compress)
            else
                error("HTTP request functionality not available")
            end
        else
            error("Invalid URL")
        end
    end)
    
    -- Handle errors
    if not success then
        error("HttpPost failed: " .. tostring(result), 2)
    end
    
    return result
end

-- Async variant
function game:HttpPostAsync(url, data, contentType, compress, callback)
    -- Default parameters
    contentType = contentType or "application/json"
    compress = compress or false
    
    -- Use callback if provided
    if callback and type(callback) == "function" then
        -- Call native async function
        if _httpPostAsync then
            _httpPostAsync(url, data, contentType, compress, function(success, result)
                if success then
                    callback(result)
                else
                    callback(nil, result) -- Pass error as second argument
                end
            end)
        else
            -- Fall back to sync version
            local success, result = pcall(function()
                return game:HttpPost(url, data, contentType, compress)
            end)
            
            if success then
                callback(result)
            else
                callback(nil, result)
            end
        end
        
        return -- No return value for async with callback
    else
        -- If no callback, just use sync version
        return game:HttpPost(url, data, contentType, compress)
    end
end

-- Create a combined loadstring + HttpGet utility function
function loadUrl(url)
    local content = game:HttpGet(url)
    local fn, err = loadstring(content)
    if not fn then
        error("Failed to load URL: " .. tostring(err), 2)
    end
    return fn
end

-- Return the implementations
return {
    HttpGet = function(...) return game:HttpGet(...) end,
    HttpGetAsync = function(...) return game:HttpGetAsync(...) end,
    HttpPost = function(...) return game:HttpPost(...) end,
    HttpPostAsync = function(...) return game:HttpPostAsync(...) end,
    loadUrl = loadUrl
}
)";
    }
    
    // Check if HTTP requests are available
    bool HttpClient::IsAvailable() {
        @autoreleasepool {
            // Check if we can create a session
            NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
            if (!config) {
                return false;
            }
            
            // Try creating a session
            NSURLSession* session = [NSURLSession sessionWithConfiguration:config];
            if (!session) {
                return false;
            }
            
            return true;
        }
    }

} // namespace AdvancedBypass
} // namespace iOS
