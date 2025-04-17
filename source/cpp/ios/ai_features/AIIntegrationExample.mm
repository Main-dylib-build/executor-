
#include "../../ios_compat.h"
#include "AISystemInitializer.h"
#include "AIConfig.h"
#include <iostream>
#include <string>

/**
 * @file AIIntegrationExample.mm
 * @brief Example showing how to integrate the AI system with the main application
 * 
 * This file demonstrates how to initialize and use the AI system,
 * showing how to perform vulnerability detection and script generation,
 * and how to leverage the self-improving capabilities.
 */

namespace iOS {
namespace AIFeatures {

/**
 * @class AIIntegrationExample
 * @brief Example class showing AI integration
 */
class AIIntegrationExample {
private:
    // AISystemInitializer instance
    AISystemInitializer& m_aiSystem;
    
    // AI Configuration
    std::shared_ptr<AIConfig> m_aiConfig;
    
    // Application data path
    std::string m_appDataPath;
    
    // Flag indicating if the system is initialized
    bool m_isInitialized;
    
public:
    /**
     * @brief Constructor
     * @param appDataPath Application data path
     */
    AIIntegrationExample(const std::string& appDataPath)
        : m_aiSystem(AISystemInitializer::GetInstance()), 
          m_appDataPath(appDataPath),
          m_isInitialized(false) {
        
        // Create AI configuration
        m_aiConfig = std::make_shared<AIConfig>();
        
        // Configure AI system to be completely offline
        m_aiConfig->SetOfflineModelGenerationEnabled(true);
        m_aiConfig->SetContinuousLearningEnabled(true);
        m_aiConfig->SetModelImprovement(AIConfig::ModelImprovement::Local);
        m_aiConfig->SetVulnerabilityDetectionLevel(AIConfig::DetectionLevel::Thorough);
        
        // Initialize AI system
        std::string aiDataPath = m_appDataPath + "/AI";
        m_isInitialized = m_aiSystem.Initialize(aiDataPath, m_aiConfig);
        
        if (m_isInitialized) {
            std::cout << "AI System initialized successfully" << std::endl;
        } else {
            std::cerr << "Failed to initialize AI System" << std::endl;
        }
    }
    
    /**
     * @brief Destructor
     */
    ~AIIntegrationExample() {
        // Nothing to do, AISystemInitializer handles cleanup
    }
    
    /**
     * @brief Example method for detecting vulnerabilities in a script
     * @param script Lua/Luau script to check
     * @param gameType Type of game (for context)
     * @param isServerScript Whether this is a server script
     * @return JSON string with detected vulnerabilities
     */
    std::string DetectVulnerabilities(
        const std::string& script, 
        const std::string& gameType = "Generic",
        bool isServerScript = false) {
        
        if (!m_isInitialized) {
            return "{}";
        }
        
        // Use AI system to detect vulnerabilities
        return m_aiSystem.DetectVulnerabilities(script, gameType, isServerScript);
    }
    
    /**
     * @brief Example method for generating a script
     * @param description Script description
     * @param gameType Type of game (for context)
     * @param isServerScript Whether this is a server script
     * @return Generated script
     */
    std::string GenerateScript(
        const std::string& description,
        const std::string& gameType = "Generic",
        bool isServerScript = false) {
        
        if (!m_isInitialized) {
            return "";
        }
        
        // Use AI system to generate script
        return m_aiSystem.GenerateScript(description, gameType, isServerScript);
    }
    
    /**
     * @brief Example method for providing feedback on vulnerability detection
     * @param script Script
     * @param detectionResult Detection result from DetectVulnerabilities
     * @param correctDetections Map of detection index to correctness (true = correct, false = false positive)
     * @return True if feedback was processed
     */
    bool ProvideVulnerabilityFeedback(
        const std::string& script,
        const std::string& detectionResult,
        const std::unordered_map<int, bool>& correctDetections) {
        
        if (!m_isInitialized) {
            return false;
        }
        
        // Use AI system to provide feedback
        return m_aiSystem.ProvideVulnerabilityFeedback(script, detectionResult, correctDetections);
    }
    
    /**
     * @brief Example method for providing feedback on script generation
     * @param description Script description
     * @param generatedScript Generated script from GenerateScript
     * @param userScript User-modified script (what they actually used)
     * @param rating Rating from 0.0 to 1.0
     * @return True if feedback was processed
     */
    bool ProvideScriptGenerationFeedback(
        const std::string& description,
        const std::string& generatedScript,
        const std::string& userScript,
        float rating) {
        
        if (!m_isInitialized) {
            return false;
        }
        
        // Use AI system to provide feedback
        return m_aiSystem.ProvideScriptGenerationFeedback(
            description, generatedScript, userScript, rating);
    }
    
    /**
     * @brief Example method for forcing a self-improvement cycle
     * @return True if improvement was successful
     */
    bool ForceSelfImprovement() {
        if (!m_isInitialized) {
            return false;
        }
        
        // Use AI system to force self-improvement
        return m_aiSystem.ForceSelfImprovement();
    }
    
    /**
     * @brief Example method to get system status
     * @return JSON string with system status
     */
    std::string GetSystemStatus() {
        if (!m_isInitialized) {
            return "{}";
        }
        
        // Get system status report
        return m_aiSystem.GetSystemStatusReport();
    }
    
    /**
     * @brief Example method to check if in fallback mode
     * @return True if in fallback mode (models not fully trained)
     */
    bool IsInFallbackMode() {
        if (!m_isInitialized) {
            return true;
        }
        
        return m_aiSystem.IsInFallbackMode();
    }
    
    /**
     * @brief Example method to add custom training data for vulnerability detection
     * @param script Script
     * @param vulnerabilities JSON string with vulnerabilities
     * @return True if data was added
     */
    bool AddVulnerabilityTrainingData(
        const std::string& script, 
        const std::string& vulnerabilities) {
        
        if (!m_isInitialized) {
            return false;
        }
        
        return m_aiSystem.AddVulnerabilityTrainingData(script, vulnerabilities);
    }
    
    /**
     * @brief Example method to add custom training data for script generation
     * @param description Script description
     * @param script Generated script
     * @param rating Rating from 0.0 to 1.0
     * @return True if data was added
     */
    bool AddScriptGenerationTrainingData(
        const std::string& description,
        const std::string& script,
        float rating) {
        
        if (!m_isInitialized) {
            return false;
        }
        
        return m_aiSystem.AddScriptGenerationTrainingData(description, script, rating);
    }
};

// Example usage
void ExampleUsage() {
    // Create example instance with app data path
    AIIntegrationExample aiExample("/path/to/app/data");
    
    // Example 1: Detect vulnerabilities in a script
    std::string script = R"(
        local Players = game:GetService("Players")
        local HttpService = game:GetService("HttpService")
        
        -- Potentially vulnerable code
        local function executeCommand(cmd)
            return loadstring(cmd)()
        end
        
        -- Remote event handling
        local remote = game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvent")
        remote.OnServerEvent:Connect(function(player, data)
            executeCommand(data.command)
        end)
    )";
    
    std::string vulnerabilities = aiExample.DetectVulnerabilities(script, "RPG", true);
    std::cout << "Detected vulnerabilities: " << vulnerabilities << std::endl;
    
    // Example 2: Generate a script based on description
    std::string description = "Create a speed script that makes the player move 3x faster";
    std::string generatedScript = aiExample.GenerateScript(description, "Simulator", false);
    std::cout << "Generated script: " << generatedScript << std::endl;
    
    // Example 3: Provide feedback on vulnerability detection
    std::unordered_map<int, bool> correctDetections = {
        {0, true},   // First detection was correct
        {1, false}   // Second detection was a false positive
    };
    aiExample.ProvideVulnerabilityFeedback(script, vulnerabilities, correctDetections);
    
    // Example 4: Provide feedback on script generation
    std::string userScript = generatedScript + "\n-- User added this comment";
    aiExample.ProvideScriptGenerationFeedback(description, generatedScript, userScript, 0.9f);
    
    // Example 5: Force self-improvement
    aiExample.ForceSelfImprovement();
    
    // Example 6: Get system status
    std::string status = aiExample.GetSystemStatus();
    std::cout << "System status: " << status << std::endl;
    
    // Example 7: Check if in fallback mode
    bool fallbackMode = aiExample.IsInFallbackMode();
    std::cout << "In fallback mode: " << (fallbackMode ? "Yes" : "No") << std::endl;
}

} // namespace AIFeatures
} // namespace iOS
