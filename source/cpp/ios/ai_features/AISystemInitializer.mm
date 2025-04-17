#include "../../ios_compat.h"
#include "AISystemInitializer.h"
#include <iostream>
#include <fstream>
#include <sstream>
#include <chrono>
#include <algorithm>
#include <thread>
#include <regex>
#include "local_models/GeneralAssistantModel.h"

namespace iOS {
namespace AIFeatures {

// Initialize static members
std::unique_ptr<AISystemInitializer> AISystemInitializer::s_instance = nullptr;
std::mutex AISystemInitializer::s_instanceMutex;

// Constructor
AISystemInitializer::AISystemInitializer()
    : m_initState(InitState::NotStarted),
      m_initProgress(0.0f) {
    
    // Initialize data paths to defaults
    m_dataPath = "/var/mobile/Documents/AIData";
    m_modelDataPath = m_dataPath + "/Models";
    
    std::cout << "AISystemInitializer: Created new instance" << std::endl;
}

// Destructor
AISystemInitializer::~AISystemInitializer() {
    std::cout << "AISystemInitializer: Instance destroyed" << std::endl;
}

// Get singleton instance
AISystemInitializer* AISystemInitializer::GetInstance() {
    std::lock_guard<std::mutex> lock(s_instanceMutex);
    
    if (!s_instance) {
        s_instance = std::unique_ptr<AISystemInitializer>(new AISystemInitializer());
    }
    
    return s_instance.get();
}

// Initialize the AI system
bool AISystemInitializer::Initialize(const AIConfig& config, std::function<void(float)> progressCallback) {
    std::lock_guard<std::mutex> lock(m_mutex);
    
    // Check if already initialized
    if (m_initState == InitState::Completed) {
        std::cout << "AISystemInitializer: Already initialized" << std::endl;
        return true;
    }
    
    // Check if initialization in progress
    if (m_initState == InitState::InProgress) {
        std::cout << "AISystemInitializer: Initialization already in progress" << std::endl;
        return true;
    }
    
    // Set state to in progress
    m_initState = InitState::InProgress;
    m_initProgress = 0.0f;
    
    // Store config
    m_config = config;
    
    // Initialize data paths
    if (!InitializeDataPaths()) {
        std::cerr << "AISystemInitializer: Failed to initialize data paths" << std::endl;
        m_initState = InitState::Failed;
        return false;
    }
    
    // Report progress
    m_initProgress = 0.1f;
    if (progressCallback) {
        progressCallback(m_initProgress);
    }
    
    // Initialize models (can be asynchronous)
    if (!InitializeModels()) {
        std::cerr << "AISystemInitializer: Failed to initialize models" << std::endl;
        m_initState = InitState::Failed;
        return false;
    }
    
    // Report progress
    m_initProgress = 0.6f;
    if (progressCallback) {
        progressCallback(m_initProgress);
    }
    
    // Initialize script assistant
    if (!InitializeScriptAssistant()) {
        std::cerr << "AISystemInitializer: Failed to initialize script assistant" << std::endl;
        m_initState = InitState::Failed;
        return false;
    }
    
    // Report progress
    m_initProgress = 0.9f;
    if (progressCallback) {
        progressCallback(m_initProgress);
    }
    
    // Set state to completed
    m_initState = InitState::Completed;
    m_initProgress = 1.0f;
    
    // Final progress report
    if (progressCallback) {
        progressCallback(m_initProgress);
    }
    
    std::cout << "AISystemInitializer: Initialization complete" << std::endl;
    return true;
}

// Set model status callback
void AISystemInitializer::SetModelStatusCallback(ModelStatusCallback callback) {
    std::lock_guard<std::mutex> lock(m_mutex);
    m_modelStatusCallback = callback;
}

// Set error callback
void AISystemInitializer::SetErrorCallback(ErrorCallback callback) {
    std::lock_guard<std::mutex> lock(m_mutex);
    m_errorCallback = callback;
}

// Get initialization state
AISystemInitializer::InitState AISystemInitializer::GetInitState() const {
    std::lock_guard<std::mutex> lock(m_mutex);
    return m_initState;
}

// Get initialization progress
float AISystemInitializer::GetInitProgress() const {
    std::lock_guard<std::mutex> lock(m_mutex);
    return m_initProgress;
}

// Get configuration
const AIConfig& AISystemInitializer::GetConfig() const {
    std::lock_guard<std::mutex> lock(m_mutex);
    return m_config;
}

// Update configuration
bool AISystemInitializer::UpdateConfig(const AIConfig& config) {
    std::lock_guard<std::mutex> lock(m_mutex);
    
    // Store config
    m_config = config;
    
    // Apply changes to components
    if (m_vulnDetectionModel) {
        // Update model settings
    }
    
    if (m_scriptGenModel) {
        // Update model settings
    }
    
    if (m_generalAssistantModel) {
        // Update model settings
    }
    
    std::cout << "AISystemInitializer: Updated configuration" << std::endl;
    return true;
}

// Get model data path
const std::string& AISystemInitializer::GetModelDataPath() const {
    std::lock_guard<std::mutex> lock(m_mutex);
    return m_modelDataPath;
}

// Get model status
AISystemInitializer::ModelStatus AISystemInitializer::GetModelStatus(const std::string& modelName) const {
    std::lock_guard<std::mutex> lock(m_mutex);
    
    auto it = m_modelStatuses.find(modelName);
    if (it != m_modelStatuses.end()) {
        return it->second;
    }
    
    return ModelStatus();
}

// Update model status
void AISystemInitializer::UpdateModelStatus(const std::string& modelName, InitState state, float progress, float accuracy) {
    std::lock_guard<std::mutex> lock(m_mutex);
    
    // Update model status
    ModelStatus& status = m_modelStatuses[modelName];
    status.state = state;
    status.progress = progress;
    status.accuracy = accuracy;
    
    // Call callback if registered
    if (m_modelStatusCallback) {
        m_modelStatusCallback(modelName, state, progress, accuracy);
    }
}

// Initialize data paths
bool AISystemInitializer::InitializeDataPaths() {
    // Check if custom paths are provided in config
    if (!m_config.GetDataPath().empty()) {
        m_dataPath = m_config.GetDataPath();
    }
    
    // Set model data path
    m_modelDataPath = m_dataPath + "/Models";
    
    // Create directories if they don't exist
    std::string command = "mkdir -p \"" + m_dataPath + "\"";
    int result = system(command.c_str());
    if (result != 0) {
        if (m_errorCallback) {
            m_errorCallback("Failed to create data directory: " + m_dataPath);
        }
        return false;
    }
    
    command = "mkdir -p \"" + m_modelDataPath + "\"";
    result = system(command.c_str());
    if (result != 0) {
        if (m_errorCallback) {
            m_errorCallback("Failed to create model data directory: " + m_modelDataPath);
        }
        return false;
    }
    
    return true;
}

// Initialize models
bool AISystemInitializer::InitializeModels() {
    // Create vulnerability detection model
    m_vulnDetectionModel = std::make_shared<LocalModels::VulnerabilityDetectionModel>();
    
    // Create general assistant model
    m_generalAssistantModel = std::make_shared<LocalModels::GeneralAssistantModel>();
    
    // Set model data path
    std::string vulnModelPath = m_modelDataPath + "/vulnerability_detection";
    
    // Initialize model
    if (!m_vulnDetectionModel->SetModelPath(vulnModelPath)) {
        std::cerr << "AISystemInitializer: Failed to set vulnerability detection model path" << std::endl;
        return false;
    }
    
    // Lazy initialization - don't load full model yet
    UpdateModelStatus("VulnerabilityDetectionModel", InitState::NotStarted, 0.0f, 0.0f);
    
    // Initialize general assistant model with model path
    std::string assistantModelPath = m_modelDataPath + "/assistant";
    if (!m_generalAssistantModel->Initialize(assistantModelPath)) {
        std::cerr << "AISystemInitializer: Failed to initialize general assistant model" << std::endl;
        // Non-critical, continue
    } else {
        std::cout << "AISystemInitializer: General assistant model initialized successfully" << std::endl;
        
        // Make the general assistant aware of other models
        m_generalAssistantModel->AddModelAwareness(
            "VulnerabilityDetectionModel",
            "AI model that analyzes scripts for potential security vulnerabilities in Roblox games",
            {"Detect script injection vulnerabilities", 
             "Identify memory corruption issues", 
             "Find insecure RemoteEvent usage"}
        );
        
        m_generalAssistantModel->AddModelAwareness(
            "ScriptGenerationModel",
            "AI model that generates and helps debug Lua scripts for Roblox games",
            {"Create custom scripts based on descriptions", 
             "Help optimize existing scripts", 
             "Provide code suggestions and improvements"}
        );
        
        m_generalAssistantModel->AddModelAwareness(
            "SignatureAdaptation",
            "AI system that helps bypass Byfron anti-cheat detection",
            {"Adapt to new detection patterns", 
             "Modify signatures to avoid detection", 
             "Learn from successful and failed bypass attempts"}
        );
    }

    // Create script generation model
    m_scriptGenModel = std::make_shared<LocalModels::ScriptGenerationModel>();
    
    // Set model data path
    std::string scriptGenModelPath = m_modelDataPath + "/script_generation";
    
    // Initialize model
    if (!m_scriptGenModel->SetModelPath(scriptGenModelPath)) {
        std::cerr << "AISystemInitializer: Failed to set script generation model path" << std::endl;
        return false;
    }
    
    // Lazy initialization - don't load full model yet
    UpdateModelStatus("ScriptGenerationModel", InitState::NotStarted, 0.0f, 0.0f);
    
    // Create self-modifying code system
    m_selfModifyingSystem = std::make_shared<SelfModifyingCodeSystem>();
    
    // Initialize self-modifying code system
    if (!m_selfModifyingSystem->Initialize(m_config)) {
        std::cerr << "AISystemInitializer: Failed to initialize self-modifying code system" << std::endl;
        return false;
    }
    
    return true;
}

// Initialize script assistant
bool AISystemInitializer::InitializeScriptAssistant() {
    // Create script assistant
    m_scriptAssistant = std::make_shared<ScriptAssistant>();
    
    // Initialize script assistant
    if (!m_scriptAssistant->Initialize(m_config)) {
        std::cerr << "AISystemInitializer: Failed to initialize script assistant" << std::endl;
        return false;
    }
    
    return true;
}

// Get vulnerability detection model
std::shared_ptr<LocalModels::VulnerabilityDetectionModel> AISystemInitializer::GetVulnerabilityDetectionModel() {
    std::lock_guard<std::mutex> lock(m_mutex);
    
    // Initialize model if needed
    if (m_vulnDetectionModel && !m_vulnDetectionModel->IsInitialized()) {
        std::string vulnModelPath = m_modelDataPath + "/vulnerability_detection";
        m_vulnDetectionModel->Initialize(vulnModelPath);
        
        // Report status
        UpdateModelStatus("VulnerabilityDetectionModel", InitState::Completed, 1.0f, 0.0f);
    }
    
    return m_vulnDetectionModel;
}

// Get script generation model
std::shared_ptr<LocalModels::ScriptGenerationModel> AISystemInitializer::GetScriptGenerationModel() {
    std::lock_guard<std::mutex> lock(m_mutex);
    
    // Initialize model if needed
    if (m_scriptGenModel && !m_scriptGenModel->IsInitialized()) {
        std::string scriptGenModelPath = m_modelDataPath + "/script_generation";
        m_scriptGenModel->Initialize(scriptGenModelPath);
        
        // Report status
        UpdateModelStatus("ScriptGenerationModel", InitState::Completed, 1.0f, 0.0f);
    }
    
    return m_scriptGenModel;
}

// Get general assistant model
std::shared_ptr<LocalModels::GeneralAssistantModel> AISystemInitializer::GetGeneralAssistantModel() const {
    return m_generalAssistantModel;
}

// Get self-modifying code system
std::shared_ptr<SelfModifyingCodeSystem> AISystemInitializer::GetSelfModifyingSystem() {
    std::lock_guard<std::mutex> lock(m_mutex);
    return m_selfModifyingSystem;
}

// Get script assistant
std::shared_ptr<ScriptAssistant> AISystemInitializer::GetScriptAssistant() {
    std::lock_guard<std::mutex> lock(m_mutex);
    return m_scriptAssistant;
}

// Detect vulnerabilities in script
void AISystemInitializer::DetectVulnerabilities(const std::string& script, std::function<void(const std::vector<VulnerabilityDetection::Vulnerability>&)> onComplete) {
    // Get vulnerability detection model
    auto vulnDetectionModel = GetVulnerabilityDetectionModel();
    
    // Check if model is available
    if (!vulnDetectionModel) {
        if (onComplete) {
            onComplete({});
        }
        return;
    }
    
    // Run detection asynchronously
    std::thread([this, script, onComplete, vulnDetectionModel]() {
        // Create detector
        VulnerabilityDetection::VulnerabilityDetector detector(vulnDetectionModel);
        
        // Detect vulnerabilities
        auto vulnerabilities = detector.DetectVulnerabilities(script);
        
        // Call completion callback
        if (onComplete) {
            onComplete(vulnerabilities);
        }
    }).detach();
}

// Generate script from description
void AISystemInitializer::GenerateScript(const std::string& description, std::function<void(const std::string&)> onComplete) {
    // Get script generation model
    auto scriptGenModel = GetScriptGenerationModel();
    
    // Check if model is available
    if (!scriptGenModel) {
        if (onComplete) {
            onComplete("");
        }
        return;
    }
    
    // Run generation asynchronously
    std::thread([this, description, onComplete, scriptGenModel]() {
        // Generate script
        std::string script = m_scriptAssistant->GenerateScript(description, scriptGenModel);
        
        // Call completion callback
        if (onComplete) {
            onComplete(script);
        }
    }).detach();
}

// Improve script
void AISystemInitializer::ImproveScript(const std::string& script, const std::string& instructions, std::function<void(const std::string&)> onComplete) {
    // Get script generation model
    auto scriptGenModel = GetScriptGenerationModel();
    
    // Check if model is available
    if (!scriptGenModel) {
        if (onComplete) {
            onComplete(script);
        }
        return;
    }
    
    // Run improvement asynchronously
    std::thread([this, script, instructions, onComplete, scriptGenModel]() {
        // Improve script
        std::string improvedScript = m_scriptAssistant->ImproveScript(script, instructions, scriptGenModel);
        
        // Call completion callback
        if (onComplete) {
            onComplete(improvedScript);
        }
    }).detach();
}

// Process script with AI model
void AISystemInitializer::ProcessScript(const std::string& script, const std::string& action, std::function<void(const std::string&)> onComplete) {
    // Get script generation model
    auto scriptGenModel = GetScriptGenerationModel();
    
    // Check if model is available
    if (!scriptGenModel) {
        if (onComplete) {
            onComplete(script);
        }
        return;
    }
    
    // Run processing asynchronously
    std::thread([this, script, action, onComplete, scriptGenModel]() {
        // Process script
        std::string processedScript = m_scriptAssistant->ProcessScript(script, action, scriptGenModel);
        
        // Call completion callback
        if (onComplete) {
            onComplete(processedScript);
        }
    }).detach();
}

// Release unused resources to reduce memory usage
void AISystemInitializer::ReleaseUnusedResources() {
    std::lock_guard<std::mutex> lock(m_mutex);
    
    // Release resources from vulnerability detection model
    if (m_vulnDetectionModel) {
        m_vulnDetectionModel->ReleaseUnusedResources();
    }
    
    // Release resources from script generation model
    if (m_scriptGenModel) {
        m_scriptGenModel->ReleaseUnusedResources();
    }
    
    // Release resources from general assistant model
    if (m_generalAssistantModel) {
        m_generalAssistantModel->ReleaseUnusedResources();
    }
    
    // Release resources from self-modifying code system
    if (m_selfModifyingSystem) {
        m_selfModifyingSystem->ReleaseUnusedResources();
    }
    
    std::cout << "AISystemInitializer: Released unused resources" << std::endl;
}

// Calculate total memory usage of AI components
uint64_t AISystemInitializer::CalculateMemoryUsage() const {
    std::lock_guard<std::mutex> lock(m_mutex);
    
    uint64_t totalUsage = 0;
    
    // Add up memory usage from all components
    if (m_vulnDetectionModel) {
        totalUsage += m_vulnDetectionModel->GetMemoryUsage();
    }
    
    if (m_scriptGenModel) {
        totalUsage += m_scriptGenModel->GetMemoryUsage();
    }
    
    if (m_generalAssistantModel) {
        totalUsage += m_generalAssistantModel->GetMemoryUsage();
    }
    
    if (m_selfModifyingSystem) {
        totalUsage += m_selfModifyingSystem->GetMemoryUsage();
    }
    
    if (m_scriptAssistant) {
        totalUsage += m_scriptAssistant->GetMemoryUsage();
    }
    
    return totalUsage;
}

// Get the current model improvement mode
AIConfig::ModelImprovement AISystemInitializer::GetModelImprovementMode() const {
    std::lock_guard<std::mutex> lock(m_mutex);
    return m_config.GetModelImprovement();
}

// Set model improvement mode
void AISystemInitializer::SetModelImprovementMode(AIConfig::ModelImprovement mode) {
    std::lock_guard<std::mutex> lock(m_mutex);
    
    // Update config
    m_config.SetModelImprovement(mode);
    
    // Apply change to components
    if (m_vulnDetectionModel) {
        // Update model improvement mode
    }
    
    if (m_scriptGenModel) {
        // Update model improvement mode
    }
    
    if (m_generalAssistantModel) {
        // Update model improvement mode
    }
    
    std::cout << "AISystemInitializer: Updated model improvement mode to: " << static_cast<int>(mode) << std::endl;
}

// Check if models are available for offline use
bool AISystemInitializer::AreModelsAvailableOffline() const {
    std::lock_guard<std::mutex> lock(m_mutex);
    
    // Check if vulnerability detection model is available
    if (m_vulnDetectionModel && !m_vulnDetectionModel->IsAvailableOffline()) {
        return false;
    }
    
    // Check if script generation model is available
    if (m_scriptGenModel && !m_scriptGenModel->IsAvailableOffline()) {
        return false;
    }
    
    // General Assistant model is always available offline
    
    return true;
}

// Train models with available data
bool AISystemInitializer::TrainModels(ModelUpdateCallback updateCallback) {
    std::lock_guard<std::mutex> lock(m_mutex);
    
    // Check if initialization is complete
    if (m_initState != InitState::Completed) {
        if (m_errorCallback) {
            m_errorCallback("Cannot train models before initialization is complete");
        }
        return false;
    }
    
    // Start training asynchronously
    std::thread([this, updateCallback]() {
        // Train vulnerability detection model
        if (m_vulnDetectionModel) {
            if (updateCallback) {
                updateCallback("VulnerabilityDetectionModel", 0.0f);
            }
            
            // Train model
            m_vulnDetectionModel->Train([&](float progress, float accuracy) {
                if (updateCallback) {
                    updateCallback("VulnerabilityDetectionModel", progress);
                }
            });
            
            if (updateCallback) {
                updateCallback("VulnerabilityDetectionModel", 1.0f);
            }
        }
        
        // Train script generation model
        if (m_scriptGenModel) {
            if (updateCallback) {
                updateCallback("ScriptGenerationModel", 0.0f);
            }
            
            // Train model
            m_scriptGenModel->Train([&](float progress, float accuracy) {
                if (updateCallback) {
                    updateCallback("ScriptGenerationModel", progress);
                }
            });
            
            if (updateCallback) {
                updateCallback("ScriptGenerationModel", 1.0f);
            }
        }
        
        // Train general assistant model
        if (m_generalAssistantModel) {
            if (updateCallback) {
                updateCallback("GeneralAssistantModel", 0.0f);
            }
            
            // Train model
            m_generalAssistantModel->Train();
            
            if (updateCallback) {
                updateCallback("GeneralAssistantModel", 1.0f);
            }
        }
        
        std::cout << "AISystemInitializer: Model training complete" << std::endl;
    }).detach();
    
    return true;
}

} // namespace AIFeatures
} // namespace iOS
