#include "AIConfig.h"
#include <fstream>
#include <iostream>

namespace iOS {
namespace AIFeatures {

// Initialize static instance
AIConfig* AIConfig::s_instance = nullptr;

// Constructor with default settings suitable for offline-only operation
AIConfig::AIConfig() {
    // Default constructor
}

// Get shared instance
AIConfig& AIConfig::GetSharedInstance() {
    if (!s_instance) {
        s_instance = new AIConfig();
    }
    return *s_instance;
}

// Initialize with default settings for local-only AI
bool AIConfig::Initialize() {
    // Set default paths and options
    if (m_options.empty()) {
        // AI data directory
        SetOption("model_path", "/var/mobile/Documents/AIData/Models");
        SetOption("config_path", "/var/mobile/Documents/AIData/config.json");
        SetOption("training_data_path", "/var/mobile/Documents/AIData/Training");
        
        // Model building settings
        SetOption("create_models_on_startup", "1");
        SetOption("rebuild_models_if_needed", "1");
        
        // Feature toggles
        SetOption("enable_ai_features", "1");
        SetOption("enable_script_analysis", "1");
        SetOption("enable_vulnerability_detection", "1");
        SetOption("enable_signature_adaptation", "1");
        
        // Learning settings
        SetOption("learning_mode", "continuous");        // Train continuously as user provides feedback
        SetOption("model_improvement", "local");         // Improve locally based on usage
        SetOption("save_training_data", "1");            // Save data for training
        SetOption("training_interval_minutes", "60");    // Retrain models every hour of active use
        
        // Network settings - disabled by default per user requirements
        SetOption("online_mode", "offline_only");        // Only use offline mode
        SetOption("api_endpoint", "");                   // No API endpoint
        SetOption("api_key", "");                        // No API key
        
        // Performance settings
        SetOption("model_quality", "medium");            // Balance between performance and accuracy
        SetOption("max_memory_usage", "100000000");      // 100MB default limit
        SetOption("prioritize_performance", "1");        // Prioritize performance over accuracy
        
        // Training settings
        SetOption("initial_model_size", "small");        // Start with small models
        SetOption("max_training_iterations", "1000");    // Limit training iterations
        SetOption("script_generation_examples", "20");   // Number of examples to keep for training
        SetOption("training_batch_size", "8");           // Small batch size for training
    }
    
    // Create necessary directories
    EnsureDirectoriesExist();
    
    return true;
}

// Check if initialized
bool AIConfig::IsInitialized() const {
    return !m_options.empty();
}

// Create necessary directories for AI data
void AIConfig::EnsureDirectoriesExist() {
    try {
        // Get directory paths
        std::string modelPath = GetModelPath();
        std::string trainingDataPath = GetOption("training_data_path", "/var/mobile/Documents/AIData/Training");
        
        // Create model directory using iOS APIs
        NSString* modelDirPath = [NSString stringWithUTF8String:modelPath.c_str()];
        NSFileManager* fileManager = [NSFileManager defaultManager];
        
        if (![fileManager fileExistsAtPath:modelDirPath]) {
            NSError* error = nil;
            BOOL success = [fileManager createDirectoryAtPath:modelDirPath
                                withIntermediateDirectories:YES
                                                attributes:nil
                                                    error:&error];
            if (!success) {
                std::cerr << "AIConfig: Failed to create model directory: "
                         << [[error localizedDescription] UTF8String] << std::endl;
            }
        }
        
        // Create training data directory
        NSString* trainingDirPath = [NSString stringWithUTF8String:trainingDataPath.c_str()];
        
        if (![fileManager fileExistsAtPath:trainingDirPath]) {
            NSError* error = nil;
            BOOL success = [fileManager createDirectoryAtPath:trainingDirPath
                                withIntermediateDirectories:YES
                                                attributes:nil
                                                    error:&error];
            if (!success) {
                std::cerr << "AIConfig: Failed to create training data directory: "
                         << [[error localizedDescription] UTF8String] << std::endl;
            }
        }
    } catch (const std::exception& e) {
        std::cerr << "AIConfig: Exception creating directories: " << e.what() << std::endl;
    }
}

// Save config to file
bool AIConfig::Save() const {
    try {
        // Get config file path
        std::string configPath = GetOption("config_path", "/var/mobile/Documents/AIData/config.json");
        
        // Create JSON structure
        NSMutableDictionary* json = [NSMutableDictionary dictionary];
        
        // Add all options
        for (const auto& option : m_options) {
            NSString* key = [NSString stringWithUTF8String:option.first.c_str()];
            NSString* value = [NSString stringWithUTF8String:option.second.c_str()];
            [json setObject:value forKey:key];
        }
        
        // Convert to JSON data
        NSError* error = nil;
        NSData* jsonData = [NSJSONSerialization dataWithJSONObject:json 
                                                          options:NSJSONWritingPrettyPrinted 
                                                            error:&error];
        
        if (error) {
            std::cerr << "AIConfig: Failed to serialize config to JSON: "
                     << [[error localizedDescription] UTF8String] << std::endl;
            return false;
        }
        
        // Write to file
        NSString* configPathNS = [NSString stringWithUTF8String:configPath.c_str()];
        BOOL success = [jsonData writeToFile:configPathNS atomically:YES];
        
        if (!success) {
            std::cerr << "AIConfig: Failed to write config to file" << std::endl;
            return false;
        }
        
        return true;
    } catch (const std::exception& e) {
        std::cerr << "AIConfig: Exception saving config: " << e.what() << std::endl;
        return false;
    }
}

// Get API endpoint - disabled in this implementation
std::string AIConfig::GetAPIEndpoint() const {
    return ""; // No API endpoint per user requirements
}

// Set API endpoint - disabled in this implementation
void AIConfig::SetAPIEndpoint(const std::string& endpoint) {
    // Ignored - we're not using API endpoints per user requirements
}

// Get API key - disabled in this implementation
std::string AIConfig::GetAPIKey() const {
    return ""; // No API key per user requirements
}

// Set API key - disabled in this implementation
void AIConfig::SetAPIKey(const std::string& key) {
    // Ignored - we're not using API keys per user requirements
}

// Get model path
std::string AIConfig::GetModelPath() const {
    return GetOption("model_path", "/var/mobile/Documents/AIData/Models");
}

// Set model path
void AIConfig::SetModelPath(const std::string& path) {
    SetOption("model_path", path);
}

// Get encrypt communication - always false for local-only
bool AIConfig::GetEncryptCommunication() const {
    return false; // No need for encryption in local-only mode
}

// Set encrypt communication - disabled
void AIConfig::SetEncryptCommunication(bool encrypt) {
    // Ignored - no network communication to encrypt
}

// Get max memory usage
uint64_t AIConfig::GetMaxMemoryUsage() const {
    std::string value = GetOption("max_memory_usage", "100000000");
    return std::stoull(value);
}

// Set max memory usage
void AIConfig::SetMaxMemoryUsage(uint64_t maxMemory) {
    SetOption("max_memory_usage", std::to_string(maxMemory));
}

// Check if models should be created on startup
bool AIConfig::ShouldCreateModelsOnStartup() const {
    return GetOption("create_models_on_startup", "1") == "1";
}

// Check if models should be rebuilt if needed
bool AIConfig::ShouldRebuildModelsIfNeeded() const {
    return GetOption("rebuild_models_if_needed", "1") == "1";
}

// Get the training data path
std::string AIConfig::GetTrainingDataPath() const {
    return GetOption("training_data_path", "/var/mobile/Documents/AIData/Training");
}

// Check if training data should be saved
bool AIConfig::ShouldSaveTrainingData() const {
    return GetOption("save_training_data", "1") == "1";
}

// Get training interval in minutes
int AIConfig::GetTrainingIntervalMinutes() const {
    std::string value = GetOption("training_interval_minutes", "60");
    return std::stoi(value);
}

// Get initial model size
std::string AIConfig::GetInitialModelSize() const {
    return GetOption("initial_model_size", "small");
}

// Get max training iterations
int AIConfig::GetMaxTrainingIterations() const {
    std::string value = GetOption("max_training_iterations", "1000");
    return std::stoi(value);
}

// Get script generation examples count
int AIConfig::GetScriptGenerationExamplesCount() const {
    std::string value = GetOption("script_generation_examples", "20");
    return std::stoi(value);
}

// Get training batch size
int AIConfig::GetTrainingBatchSize() const {
    std::string value = GetOption("training_batch_size", "8");
    return std::stoi(value);
}

} // namespace AIFeatures
} // namespace iOS
