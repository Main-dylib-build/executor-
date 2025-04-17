
#include "../../../objc_isolation.h"
#pragma once

#include "LocalModelBase.h"
#include <string>
#include <vector>
#include <unordered_map>
#include <memory>
#include <functional>

namespace iOS {
namespace AIFeatures {
namespace LocalModels {

/**
 * @class ScriptGenerationModel
 * @brief Model for generating Lua scripts based on user descriptions
 * 
 * This model learns from user interactions to generate custom Lua scripts
 * for Roblox games. It's trained locally on device with script samples
 * collected during normal usage.
 */
class ScriptGenerationModel : public LocalModelBase {
public:
    // Script category enumeration
    enum class ScriptCategory {
        Movement,      // Speed, teleport, noclip, etc.
        Combat,        // Aimbot, ESP, hitbox extenders, etc.
        Visual,        // ESP, wallhack, chams, etc.
        Automation,    // Auto farm, auto collect, etc.
        ServerSide,    // Server-side execution exploits
        Utility,       // General purpose utility scripts
        Custom         // User-defined category
    };
    
    // Script template structure
    struct ScriptTemplate {
        std::string m_name;                  // Template name
        std::string m_description;           // Template description
        std::string m_code;                  // Template code
        std::vector<std::string> m_tags;     // Template tags
        ScriptCategory m_category;           // Script category
        float m_complexity;                  // Script complexity (0-1)
        
        ScriptTemplate()
            : m_category(ScriptCategory::Utility), m_complexity(0.5f) {}
    };
    
    // Generated script structure
    struct GeneratedScript {
        std::string m_code;                  // Generated code
        std::string m_description;           // Script description
        ScriptCategory m_category;           // Script category
        std::vector<std::string> m_tags;     // Script tags
        float m_confidence;                  // Generation confidence (0-1)
        std::string m_basedOn;               // Source template if applicable
        
        GeneratedScript()
            : m_category(ScriptCategory::Utility), m_confidence(0.0f) {}
    };
    
private:
    // Training data
    std::unordered_map<std::string, ScriptTemplate> m_templates; // Script templates
    std::vector<std::pair<std::string, std::string>> m_patternPairs; // Intent-script pairs
    std::unordered_map<std::string, uint32_t> m_wordFrequency; // Vocabulary
    uint32_t m_vocabularySize;               // Vocabulary size
    std::vector<float> m_weights;            // Model weights
    
    // Model state
    std::unordered_map<std::string, float> m_featureWeights; // Feature weights
    std::unordered_map<std::string, float> m_categoryWeights; // Category weights
    
    // Implementation of abstract methods
    bool InitializeModel() override;
    bool TrainModel(TrainingProgressCallback progressCallback = nullptr) override;
    std::string PredictInternal(const std::string& input) override;
    std::vector<float> FeaturizeInput(const std::string& input) override;
    std::string ProcessOutput(const std::vector<float>& output) override;
    
    // Helper methods
    void AddDefaultTemplates();
    void BuildVocabulary();
    ScriptTemplate FindBestTemplateMatch(const std::string& description);
    GeneratedScript GenerateScriptFromTemplate(const ScriptTemplate& templ, const std::string& description);
    GeneratedScript GenerateScriptFromScratch(const std::string& description);
    std::vector<std::string> ExtractKeywords(const std::string& text);
    ScriptCategory DetermineCategory(const std::string& description);
    std::vector<std::string> GenerateTags(const std::string& description);
    std::vector<std::string> TokenizeInput(const std::string& input);
    float CalculateSimilarity(const std::vector<float>& v1, const std::vector<float>& v2);
    std::string CustomizeScript(const std::string& templateCode, const std::string& description);
    std::string ExtractIntents(const std::string& description);
    
public:
    /**
     * @brief Constructor
     */
    ScriptGenerationModel();
    
    /**
     * @brief Destructor
     */
    ~ScriptGenerationModel();
    
    /**
     * @brief Generate a script based on description
     * @param description Script description
     * @param context Optional context information
     * @return Generated script
     */
    GeneratedScript GenerateScript(const std::string& description, const std::string& context = "");
    
    /**
     * @brief Analyze a script for bugs or improvements
     * @param script Script to analyze
     * @return Analysis result
     */
    std::string AnalyzeScript(const std::string& script);
    
    /**
     * @brief Generate a response to a general query
     * @param query User's query
     * @param context Optional context information
     * @return Generated response
     */
    std::string GenerateResponse(const std::string& query, const std::string& context = "");
    
    /**
     * @brief Add a script template
     * @param templ Script template
     * @return True if template was added
     */
    bool AddTemplate(const ScriptTemplate& templ);
    
    /**
     * @brief Get all script templates
     * @return Map of template names to templates
     */
    std::unordered_map<std::string, ScriptTemplate> GetTemplates() const;
    
    /**
     * @brief Get templates by category
     * @param category Script category
     * @return Vector of templates
     */
    std::vector<ScriptTemplate> GetTemplatesByCategory(ScriptCategory category);
    
    /**
     * @brief Get templates by tag
     * @param tag Template tag
     * @return Vector of templates
     */
    std::vector<ScriptTemplate> GetTemplatesByTag(const std::string& tag);
    
    /**
     * @brief Add an intent-script pair
     * @param intent User intent
     * @param script Script code
     * @return True if pair was added
     */
    bool AddIntentScriptPair(const std::string& intent, const std::string& script);
    
    /**
     * @brief Learn from user feedback
     * @param description Script description
     * @param generatedScript Generated script
     * @param userScript User-modified script
     * @param rating User rating (0-1)
     * @return True if learning succeeded
     */
    bool LearnFromFeedback(const std::string& description, 
                          const std::string& generatedScript,
                          const std::string& userScript,
                          float rating);
    
    /**
     * @brief Get vocabulary size
     * @return Vocabulary size
     */
    uint32_t GetVocabularySize() const;
    
    /**
     * @brief Convert category to string
     * @param category Script category
     * @return String representation
     */
    static std::string CategoryToString(ScriptCategory category);
    
    /**
    /**
     * @brief Check if the model is initialized
     * @return True if initialized
     */
    bool IsInitialized() const;

    /**
     * @brief Set model path
     * @param path Path to model files
     * @return True if path was valid and set
     */
    bool SetModelPath(const std::string& path);
     * @brief Convert string to category
     * @param str String representation
     * @return Script category
     */
} // namespace LocalModels
} // namespace AIFeatures
} // namespace iOS
    /**
     * @brief Check if the model is initialized
     * @return True if initialized
     */
    
    /**
     * @brief Set model path
     * @param path Path to model files
     * @return True if path was valid and set
     */
