#pragma once

#include "../../objc_isolation.h"
#include "AIConfig.h"
#include "AIIntegration.h"
#include "local_models/VulnerabilityDetectionModel.h"
#include "local_models/ScriptGenerationModel.h"
#include "local_models/GeneralAssistantModel.h"
#include "SelfModifyingCodeSystem.h"

#include <string>
#include <memory>
#include <mutex>
#include <functional>
#include <vector>
#include <map>

namespace iOS {
namespace AIFeatures {

/**
 * @class AISystemInitializer
 * @brief Initializes and manages the AI system lifecycle
 * 
 * This class handles the initialization of the AI system on first use,
 * ensures models are created locally, provides fallback systems during 
 * training, and coordinates continuous self-improvement. It ensures
 * the AI system works completely offline without any cloud dependencies.
 */
class AISystemInitializer {
public:
    // Initialization state enumeration
    enum class InitState {
        NotStarted,    // Initialization not started
        InProgress,    // Initialization in progress
        Completed,     // Initialization completed
        Failed         // Initialization failed
    };
    
    // Model status update callback
    using ModelStatusCallback = std::function<void(const std::string& modelName, InitState state, float progress, float accuracy)>;
    
    // Error callback
    using ErrorCallback = std::function<void(const std::string& errorMessage)>;
    
    // Model update callback
    using ModelUpdateCallback = std::function<void(const std::string& modelName, float progress)>;
    
private:
    // Singleton instance
    static std::unique_ptr<AISystemInitializer> s_instance;
    static std::mutex s_instanceMutex;
    
    // Configuration
    AIConfig m_config;
    std::string m_dataPath;
    std::string m_modelDataPath;
    
    // Initialization state
    InitState m_initState;
    float m_initProgress;
    
    // Callbacks
    ModelStatusCallback m_modelStatusCallback;
    ErrorCallback m_errorCallback;
    
    // Thread safety
    mutable std::mutex m_mutex;
    
    // Models
    std::shared_ptr<LocalModels::VulnerabilityDetectionModel> m_vulnDetectionModel;
    std::shared_ptr<LocalModels::GeneralAssistantModel> m_generalAssistantModel;
    std::shared_ptr<LocalModels::ScriptGenerationModel> m_scriptGenModel;
    
    // Self-modifying code system
    std::shared_ptr<SelfModifyingCodeSystem> m_selfModifyingSystem;
    
    // Script assistant
    std::shared_ptr<ScriptAssistant> m_scriptAssistant;
    
    // Model statuses
    struct ModelStatus {
        InitState state;
        float progress;
        float accuracy;
        
        ModelStatus() : state(InitState::NotStarted), progress(0.0f), accuracy(0.0f) {}
    };
    
    std::map<std::string, ModelStatus> m_modelStatuses;
    
    // Private constructor (singleton)
    AISystemInitializer();
    
    // Initialize components
    bool InitializeDataPaths();
    bool InitializeModels();
    bool InitializeScriptAssistant();
    
    // Update model status
    void UpdateModelStatus(const std::string& modelName, InitState state, float progress, float accuracy);
    
public:
    /**
     * @brief Destructor
     */
    ~AISystemInitializer();
    
    /**
     * @brief Get singleton instance
     * @return Instance
     */
    static AISystemInitializer* GetInstance();
    
    /**
     * @brief Initialize the AI system
     * @param config AI configuration
     * @param progressCallback Progress callback
     * @return True if initialization succeeded or was already complete
     */
    bool Initialize(const AIConfig& config, std::function<void(float)> progressCallback = nullptr);
    
    /**
     * @brief Set model status callback
     * @param callback Callback to invoke when model status changes
     */
    void SetModelStatusCallback(ModelStatusCallback callback);
    
    /**
     * @brief Set error callback
     * @param callback Callback to invoke when errors occur
     */
    void SetErrorCallback(ErrorCallback callback);
    
    /**
     * @brief Get initialization state
     * @return Current initialization state
     */
    InitState GetInitState() const;
    
    /**
     * @brief Get initialization progress
     * @return Progress value (0.0-1.0)
     */
    float GetInitProgress() const;
    
    /**
     * @brief Get configuration
     * @return AI configuration
     */
    const AIConfig& GetConfig() const;
    
    /**
     * @brief Update configuration
     * @param config New configuration
     * @return True if update was successful
     */
    bool UpdateConfig(const AIConfig& config);
    
    /**
     * @brief Get model data path
     * @return Path to model data
     */
    const std::string& GetModelDataPath() const;
    
    /**
     * @brief Get model status
     * @param modelName Model name
     * @return Model status
     */
    ModelStatus GetModelStatus(const std::string& modelName) const;
    
    /**
     * @brief Get vulnerability detection model
     * @return Shared pointer to vulnerability detection model
     */
    std::shared_ptr<LocalModels::VulnerabilityDetectionModel> GetVulnerabilityDetectionModel();
    
    /**
     * @brief Get script generation model
     * @return Shared pointer to script generation model
     */
    std::shared_ptr<LocalModels::ScriptGenerationModel> GetScriptGenerationModel();
    
    /**
     * @brief Get general assistant model
     * @return Shared pointer to general assistant model
     */
    std::shared_ptr<LocalModels::GeneralAssistantModel> GetGeneralAssistantModel() const;
    
    /**
     * @brief Get self-modifying code system
     * @return Shared pointer to self-modifying code system
     */
    std::shared_ptr<SelfModifyingCodeSystem> GetSelfModifyingSystem();
    
    /**
     * @brief Get script assistant
     * @return Shared pointer to script assistant
     */
    std::shared_ptr<ScriptAssistant> GetScriptAssistant();
    
    /**
     * @brief Detect vulnerabilities in script
     * @param script Script content
     * @param onComplete Completion callback
     */
    void DetectVulnerabilities(const std::string& script, std::function<void(const std::vector<VulnerabilityDetection::Vulnerability>&)> onComplete);
    
    /**
     * @brief Generate script from description
     * @param description Script description
     * @param onComplete Completion callback
     */
    void GenerateScript(const std::string& description, std::function<void(const std::string&)> onComplete);
    
    /**
     * @brief Improve script
     * @param script Original script
     * @param instructions Improvement instructions
     * @param onComplete Completion callback
     */
    void ImproveScript(const std::string& script, const std::string& instructions, std::function<void(const std::string&)> onComplete);
    
    /**
     * @brief Process script with AI model
     * @param script Script to process
     * @param action Action to perform
     * @param onComplete Completion callback
     */
    void ProcessScript(const std::string& script, const std::string& action, std::function<void(const std::string&)> onComplete);
    
    /**
     * @brief Release unused resources to reduce memory usage
     */
    void ReleaseUnusedResources();
    
    /**
     * @brief Calculate total memory usage of AI components
     * @return Memory usage in bytes
     */
    uint64_t CalculateMemoryUsage() const;
    
    /**
     * @brief Get the current model improvement mode
     * @return Model improvement mode
     */
    AIConfig::ModelImprovement GetModelImprovementMode() const;
    
    /**
     * @brief Set model improvement mode
     * @param mode Model improvement mode
     */
    void SetModelImprovementMode(AIConfig::ModelImprovement mode);
    
    /**
     * @brief Check if models are available for offline use
     * @return True if all required models are available
     */
    bool AreModelsAvailableOffline() const;
    
    /**
     * @brief Train models with available data
     * @param updateCallback Progress update callback
     * @return True if training started successfully
     */
    bool TrainModels(ModelUpdateCallback updateCallback = nullptr);
};

} // namespace AIFeatures
} // namespace iOS
