#include "../objc_isolation.h"


#pragma once

#include <string>
#include <functional>
#include <vector>
#include <unordered_map>
#include <memory>
#include <mutex>
#include "ScriptManager.h"
#include "../filesystem_utils.h"

namespace iOS {
    /**
     * @class ExecutionEngine
     * @brief Handles script execution with advanced anti-detection
     * 
     * This class provides a robust execution system that works on both jailbroken
     * and non-jailbroken devices. It integrates advanced Byfron bypass techniques
     */
    class ExecutionEngine {
    public:
        // Execution result structure
        struct ExecutionResult {
            bool m_success;              // Execution succeeded
            std::string m_error;         // Error message if failed
            uint64_t m_executionTime;    // Execution time in milliseconds
            std::string m_output;        // Output from execution
            
            ExecutionResult()
                : m_success(false), m_executionTime(0) {}
            
            ExecutionResult(bool success, const std::string& error = "", 
                           uint64_t executionTime = 0, const std::string& output = "")
                : m_success(success), m_error(error), 
                  m_executionTime(executionTime), m_output(output) {}
        };
        
        // Execution context for advanced features
        struct ExecutionContext {
            bool m_isJailbroken;                 // Whether device is jailbroken
            bool m_enableObfuscation;            // Whether to enable obfuscation
            bool m_enableAntiDetection;          // Whether to enable anti-detection
            bool m_autoRetry;                    // Whether to auto-retry on failure
            int m_maxRetries;                    // Maximum number of retries
            uint64_t m_timeout;                  // Execution timeout in milliseconds
            std::string m_gameName;              // Current game name
            std::string m_placeId;               // Current place ID
            std::unordered_map<std::string, std::string> m_environment;  // Environment variables
            
            ExecutionContext()
                : m_isJailbroken(false), m_enableObfuscation(true),
                  m_enableAntiDetection(true), m_autoRetry(true),
                  m_maxRetries(3), m_timeout(5000) {}
        };
        
        // Execution event callback types
        using BeforeExecuteCallback = std::function<bool(const std::string&, ExecutionContext&)>;
        using AfterExecuteCallback = std::function<void(const std::string&, const ExecutionResult&)>;
        using OutputCallback = std::function<void(const std::string&)>;
        
    private:
        std::shared_ptr<ScriptManager> m_scriptManager;
        ExecutionContext m_defaultContext;
        std::vector<BeforeExecuteCallback> m_beforeCallbacks;
        std::vector<AfterExecuteCallback> m_afterCallbacks;
        OutputCallback m_outputCallback;
        std::mutex m_executionMutex;
        bool m_isExecuting;
        int m_retryCount;
        
        // Private methods
        std::string ObfuscateScript(const std::string& script);
        std::string PrepareScript(const std::string& script, const ExecutionContext& context);
        void ProcessOutput(const std::string& output);
        bool SetupBypassEnvironment(const ExecutionContext& context);
        bool CheckJailbreakStatus();
        void LogExecution(const std::string& script, const ExecutionResult& result);
        std::string GenerateExecutionEnvironment(const ExecutionContext& context);
        
    public:
        /**
         * @brief Constructor
         * @param scriptManager Script manager to use
         */
        ExecutionEngine(std::shared_ptr<ScriptManager> scriptManager = nullptr);
        
        /**
         * @brief Initialize the execution engine
         * @return True if initialization succeeded, false otherwise
         */
        bool Initialize();
        
        /**
         * @brief Execute a script
         * @param script Script content to execute
         * @param context Execution context (optional)
         * @return Execution result
         */
        ExecutionResult Execute(const std::string& script, const ExecutionContext& context = ExecutionContext());
        
        /**
         * @brief Execute a script by name from the script manager
         * @param scriptName Name of the script to execute
         * @param context Execution context (optional)
         * @return Execution result
         */
        ExecutionResult ExecuteByName(const std::string& scriptName, const ExecutionContext& context = ExecutionContext());
        
        /**
         * @brief Set the default execution context
         * @param context New default context
         */
        void SetDefaultContext(const ExecutionContext& context);
        
        /**
         * @brief Get the default execution context
         * @return Default execution context
         */
        ExecutionContext GetDefaultContext() const;
        
        /**
         * @brief Register a callback to be called before script execution
         * @param callback Callback function
         */
        void RegisterBeforeExecuteCallback(const BeforeExecuteCallback& callback);
        
        /**
         * @brief Register a callback to be called after script execution
         * @param callback Callback function
         */
        void RegisterAfterExecuteCallback(const AfterExecuteCallback& callback);
        
        /**
         * @brief Set the output callback function
         * @param callback Callback function
         */
        void SetOutputCallback(const OutputCallback& callback);
        
        /**
         * @brief Check if the engine is currently executing a script
         * @return True if executing, false otherwise
         */
        bool IsExecuting() const;
        
        /**
         * @brief Set the script manager
         * @param scriptManager New script manager
         */
        void SetScriptManager(std::shared_ptr<ScriptManager> scriptManager);
        
        /**
         * @brief Detect if device is jailbroken
         * @return True if jailbroken, false otherwise
         */
        static bool IsJailbroken();
        
        /**
         * @brief Get a list of available Byfron bypass methods
         * @return Vector of available method names
         */
        std::vector<std::string> GetAvailableBypassMethods() const;
        
        /**
         * @param methodName Name of the method to check
         * @return True if available, false otherwise
         */
        bool IsMethodAvailable(const std::string& methodName) const;
    };
}
