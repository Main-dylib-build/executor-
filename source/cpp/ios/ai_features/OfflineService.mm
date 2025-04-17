
#include "../../ios_compat.h"
#include "OfflineService.h"
#include <iostream>
#include <sstream>
#include <fstream>
#include <chrono>
#include <thread>
#include "local_models/ScriptGenerationModel.h"

namespace iOS {
namespace AIFeatures {

// Constructor
OfflineService::OfflineService()
    : m_isInitialized(false),
      m_requestCount(0),
      m_lastTrainingTimestamp(0),
      m_isTraining(false) {
}

// Destructor
OfflineService::~OfflineService() {
    // Save any pending training data
    if (!m_trainingBuffer.empty()) {
        SaveTrainingData();
    }
}

// Initialize the service
bool OfflineService::Initialize(const std::string& modelPath, const std::string& dataPath) {
    if (m_isInitialized) {
        return true;
    }
    
    // Set paths
    m_modelPath = modelPath;
    m_dataPath = dataPath;
    
    // Create directories if they don't exist
    NSFileManager* fileManager = [NSFileManager defaultManager];
    
    // Model path
    NSString* modelDir = [NSString stringWithUTF8String:modelPath.c_str()];
    if (![fileManager fileExistsAtPath:modelDir]) {
        NSError* error = nil;
        if (![fileManager createDirectoryAtPath:modelDir
                    withIntermediateDirectories:YES
                                     attributes:nil
                                          error:&error]) {
            std::cerr << "OfflineService: Failed to create model directory: " 
                     << [[error localizedDescription] UTF8String] << std::endl;
            return false;
        }
    }
    
    // Data path
    NSString* dataDir = [NSString stringWithUTF8String:dataPath.c_str()];
    if (![fileManager fileExistsAtPath:dataDir]) {
        NSError* error = nil;
        if (![fileManager createDirectoryAtPath:dataDir
                    withIntermediateDirectories:YES
                                     attributes:nil
                                          error:&error]) {
            std::cerr << "OfflineService: Failed to create data directory: " 
                     << [[error localizedDescription] UTF8String] << std::endl;
            return false;
        }
    }
    
    // Load training data
    LoadTrainingData();
    
    m_isInitialized = true;
    return true;
}

// Check if the service is initialized
bool OfflineService::IsInitialized() const {
    return m_isInitialized;
}

// Process an inference request
void OfflineService::ProcessRequest(const Request& request, ResponseCallback callback) {
    if (!callback) {
        return;
    }
    
    // Process request in background thread
    std::thread([this, request, callback]() {
        Response response = ProcessRequestSync(request);
        callback(response);
    }).detach();
}

// Process an inference request synchronously
OfflineService::Response OfflineService::ProcessRequestSync(const Request& request) {
    Response response;
    
    if (!m_isInitialized) {
        response.m_success = false;
        response.m_output = "Service not initialized";
        return response;
    }
    
    // Start timer
    auto startTime = std::chrono::high_resolution_clock::now();
    
    try {
        // Select model based on request type
        void* model = SelectModelForRequest(request);
        
        if (!model) {
            response.m_success = false;
            response.m_output = "No suitable model found for request";
            return response;
        }
        
        // Process request based on type
        if (request.m_type == "script_generation") {
            // Use script generation model
            auto* scriptGenerator = static_cast<LocalModels::ScriptGenerationModel*>(model);
            LocalModels::ScriptGenerationModel::GeneratedScript result = 
                scriptGenerator->GenerateScript(request.m_input, request.m_context);
            
            response.m_success = true;
            response.m_output = result.m_code;
            response.m_confidence = result.m_confidence;
            response.m_modelUsed = "script_generator";
            response.m_metadata["language"] = "lua";
            response.m_metadata["type"] = "script";
        }
        else if (request.m_type == "debug") {
            // Use debug model (or script generator in debug mode)
            auto* scriptGenerator = static_cast<LocalModels::ScriptGenerationModel*>(model);
            std::string debugResult = scriptGenerator->AnalyzeScript(request.m_input);
            
            response.m_success = true;
            response.m_output = debugResult;
            response.m_modelUsed = "debug_analyzer";
            response.m_metadata["type"] = "analysis";
        }
        else if (request.m_type == "game_analysis") {
            // Use game analysis model (placeholder)
            response.m_success = true;
            response.m_output = "Game analysis not yet implemented in offline mode.";
            response.m_modelUsed = "game_analyzer";
            response.m_metadata["type"] = "analysis";
        }
        else {
            // General query - use script generator model as a fallback
            auto* scriptGenerator = static_cast<LocalModels::ScriptGenerationModel*>(model);
            std::string generalResponse = scriptGenerator->GenerateResponse(request.m_input, request.m_context);
            
            response.m_success = true;
            response.m_output = generalResponse;
            response.m_modelUsed = "script_generator";
            response.m_metadata["type"] = "response";
        }
        
        // If data collection is enabled, add to training buffer
        if (m_dataCollectionSettings.m_enabled && request.m_collectStats) {
            TrainingData trainingData;
            trainingData.m_input = request.m_input;
            trainingData.m_context = request.m_context;
            trainingData.m_type = request.m_type;
            trainingData.m_output = response.m_output;
            trainingData.m_source = "auto_collected";
            trainingData.m_timestamp = std::chrono::duration_cast<std::chrono::seconds>(
                std::chrono::system_clock::now().time_since_epoch()).count();
            
            AddTrainingData(trainingData);
        }
        
        // Increment request counter
        m_requestCount++;
    }
    catch (const std::exception& e) {
        response.m_success = false;
        response.m_output = "Error processing request: " + std::string(e.what());
    }
    
    // End timer
    auto endTime = std::chrono::high_resolution_clock::now();
    response.m_durationMs = std::chrono::duration_cast<std::chrono::milliseconds>(
        endTime - startTime).count();
    
    return response;
}

// Add training data
bool OfflineService::AddTrainingData(const TrainingData& data) {
    // Validate data
    if (!ValidateTrainingData(data)) {
        return false;
    }
    
    // Check if we're under the daily limit
    uint32_t todayCount = 0;
    uint64_t today = std::chrono::duration_cast<std::chrono::seconds>(
        std::chrono::system_clock::now().time_since_epoch()).count() / (60 * 60 * 24);
    
    for (const auto& entry : m_trainingBuffer) {
        uint64_t entryDay = entry.m_timestamp / (60 * 60 * 24);
        if (entryDay == today) {
            todayCount++;
        }
    }
    
    if (todayCount >= m_dataCollectionSettings.m_maxSamplesPerDay) {
        return false;
    }
    
    // Add to buffer
    m_trainingBuffer.push_back(data);
    
    // Save if buffer is large enough
    if (m_trainingBuffer.size() >= 50) {
        SaveTrainingData();
    }
    
    return true;
}

// Add multiple training data entries
uint32_t OfflineService::AddTrainingData(const std::vector<TrainingData>& data) {
    uint32_t addedCount = 0;
    
    for (const auto& entry : data) {
        if (AddTrainingData(entry)) {
            addedCount++;
        }
    }
    
    return addedCount;
}

// Start model update/training
bool OfflineService::StartModelUpdate(const std::string& modelName, 
                                UpdateCallback callback,
                                TrainingProgressCallback progressCallback) {
    if (m_isTraining) {
        return false;
    }
    
    if (m_trainingBuffer.empty()) {
        if (callback) {
            UpdateResult result;
            result.m_success = false;
            result.m_modelName = modelName;
            result.m_message = "No training data available";
            callback(result);
        }
        return false;
    }
    
    // Start training in background thread
    m_isTraining = true;
    
    std::thread([this, modelName, callback, progressCallback]() {
        // Start timer
        auto startTime = std::chrono::high_resolution_clock::now();
        
        // Update result
        UpdateResult result;
        result.m_modelName = modelName;
        result.m_samplesProcessed = 0;
        
        try {
            // Process training buffer
            result.m_samplesProcessed = m_trainingBuffer.size();
            
            // Simulated training for now since we're creating infrastructure
            // A real implementation would do actual model training here
            
            if (progressCallback) {
                progressCallback(0.0f, "Starting training");
            }
            
            // Simulate training steps
            for (int i = 1; i <= 10 && m_isTraining; i++) {
                if (progressCallback) {
                    progressCallback(i / 10.0f, "Training in progress: " + std::to_string(i * 10) + "%");
                }
                
                // Simulated work
                std::this_thread::sleep_for(std::chrono::milliseconds(200));
            }
            
            if (!m_isTraining) {
                // Training was cancelled
                result.m_success = false;
                result.m_message = "Training cancelled";
            } else {
                // Training completed successfully
                result.m_success = true;
                result.m_message = "Training completed successfully";
                result.m_improvement = 0.05f; // Simulated improvement metric
                
                // Update model version
                UpdateModelVersion(modelName);
                
                // Clear training buffer
                m_trainingBuffer.clear();
                
                // Update last training timestamp
                m_lastTrainingTimestamp = std::chrono::duration_cast<std::chrono::seconds>(
                    std::chrono::system_clock::now().time_since_epoch()).count();
                
                if (progressCallback) {
                    progressCallback(1.0f, "Training completed");
                }
            }
        }
        catch (const std::exception& e) {
            result.m_success = false;
            result.m_message = "Error during training: " + std::string(e.what());
        }
        
        // End timer
        auto endTime = std::chrono::high_resolution_clock::now();
        result.m_durationMs = std::chrono::duration_cast<std::chrono::milliseconds>(
            endTime - startTime).count();
        
        // Reset training flag
        m_isTraining = false;
        
        // Call callback
        if (callback) {
            callback(result);
        }
    }).detach();
    
    return true;
}

// Cancel model update/training
bool OfflineService::CancelModelUpdate() {
    if (!m_isTraining) {
        return false;
    }
    
    m_isTraining = false;
    return true;
}

// Check if model update/training is in progress
bool OfflineService::IsModelUpdateInProgress() const {
    return m_isTraining;
}

// Get available models
std::vector<std::string> OfflineService::GetAvailableModels() const {
    std::vector<std::string> models;
    
    // Add known model types
    models.push_back("script_generator");
    models.push_back("debug_analyzer");
    // We don't add game_analyzer yet as it's a placeholder
    
    return models;
}

// Get model version
std::string OfflineService::GetModelVersion(const std::string& modelName) const {
    auto it = m_modelVersions.find(modelName);
    if (it != m_modelVersions.end()) {
        return it->second;
    }
    
    return "1.0.0"; // Default version
}

// Get training data count
uint32_t OfflineService::GetTrainingDataCount(const std::string& dataType) const {
    if (dataType.empty()) {
        return m_trainingBuffer.size();
    }
    
    uint32_t count = 0;
    for (const auto& entry : m_trainingBuffer) {
        if (entry.m_type == dataType) {
            count++;
        }
    }
    
    return count;
}

// Clear training data
uint32_t OfflineService::ClearTrainingData(const std::string& dataType) {
    if (dataType.empty()) {
        uint32_t count = m_trainingBuffer.size();
        m_trainingBuffer.clear();
        return count;
    }
    
    uint32_t count = 0;
    auto it = m_trainingBuffer.begin();
    while (it != m_trainingBuffer.end()) {
        if (it->m_type == dataType) {
            it = m_trainingBuffer.erase(it);
            count++;
        } else {
            ++it;
        }
    }
    
    return count;
}

// Set data collection settings
void OfflineService::SetDataCollectionSettings(const DataCollectionSettings& settings) {
    m_dataCollectionSettings = settings;
}

// Get data collection settings
OfflineService::DataCollectionSettings OfflineService::GetDataCollectionSettings() const {
    return m_dataCollectionSettings;
}

// Create a script generation request
OfflineService::Request OfflineService::CreateScriptGenerationRequest(const std::string& description, const std::string& context) {
    Request request;
    request.m_input = description;
    request.m_context = context;
    request.m_type = "script_generation";
    request.m_collectStats = m_dataCollectionSettings.m_collectUserQueries;
    return request;
}

// Create a script debugging request
OfflineService::Request OfflineService::CreateScriptDebuggingRequest(const std::string& script) {
    Request request;
    request.m_input = script;
    request.m_type = "debug";
    request.m_collectStats = m_dataCollectionSettings.m_collectUserQueries;
    return request;
}

// Create a game analysis request
OfflineService::Request OfflineService::CreateGameAnalysisRequest(const std::string& gameData) {
    Request request;
    request.m_input = gameData;
    request.m_type = "game_analysis";
    request.m_collectStats = m_dataCollectionSettings.m_collectGameAnalysis;
    return request;
}

// Create a general query request
OfflineService::Request OfflineService::CreateGeneralQueryRequest(const std::string& query, const std::string& context) {
    Request request;
    request.m_input = query;
    request.m_context = context;
    request.m_type = "general";
    request.m_collectStats = m_dataCollectionSettings.m_collectUserQueries;
    return request;
}

// Private Methods

// Load training data
bool OfflineService::LoadTrainingData() {
    NSString* dataFile = [NSString stringWithUTF8String:(m_dataPath + "/training_data.json").c_str()];
    NSFileManager* fileManager = [NSFileManager defaultManager];
    
    if (![fileManager fileExistsAtPath:dataFile]) {
        return false;
    }
    
    NSData* data = [NSData dataWithContentsOfFile:dataFile];
    if (!data) {
        return false;
    }
    
    NSError* error = nil;
    NSArray* jsonArray = [NSJSONSerialization JSONObjectWithData:data 
                                                         options:0 
                                                           error:&error];
    
    if (error || !jsonArray || ![jsonArray isKindOfClass:[NSArray class]]) {
        return false;
    }
    
    // Clear existing data
    m_trainingBuffer.clear();
    
    // Parse entries
    for (NSDictionary* entry in jsonArray) {
        if (![entry isKindOfClass:[NSDictionary class]]) {
            continue;
        }
        
        TrainingData trainingData;
        
        NSString* input = entry[@"input"];
        if (input && [input isKindOfClass:[NSString class]]) {
            trainingData.m_input = [input UTF8String];
        }
        
        NSString* output = entry[@"output"];
        if (output && [output isKindOfClass:[NSString class]]) {
            trainingData.m_output = [output UTF8String];
        }
        
        NSString* context = entry[@"context"];
        if (context && [context isKindOfClass:[NSString class]]) {
            trainingData.m_context = [context UTF8String];
        }
        
        NSString* type = entry[@"type"];
        if (type && [type isKindOfClass:[NSString class]]) {
            trainingData.m_type = [type UTF8String];
        }
        
        NSString* source = entry[@"source"];
        if (source && [source isKindOfClass:[NSString class]]) {
            trainingData.m_source = [source UTF8String];
        }
        
        NSNumber* timestamp = entry[@"timestamp"];
        if (timestamp && [timestamp isKindOfClass:[NSNumber class]]) {
            trainingData.m_timestamp = [timestamp unsignedLongLongValue];
        }
        
        // Validate and add
        if (ValidateTrainingData(trainingData)) {
            m_trainingBuffer.push_back(trainingData);
        }
    }
    
    return true;
}

// Save training data
bool OfflineService::SaveTrainingData() {
    if (m_trainingBuffer.empty()) {
        return true;
    }
    
    NSMutableArray* jsonArray = [NSMutableArray array];
    
    // Convert entries to JSON
    for (const auto& entry : m_trainingBuffer) {
        NSMutableDictionary* jsonEntry = [NSMutableDictionary dictionary];
        
        [jsonEntry setObject:[NSString stringWithUTF8String:entry.m_input.c_str()] 
                      forKey:@"input"];
        
        [jsonEntry setObject:[NSString stringWithUTF8String:entry.m_output.c_str()] 
                      forKey:@"output"];
        
        if (!entry.m_context.empty()) {
            [jsonEntry setObject:[NSString stringWithUTF8String:entry.m_context.c_str()] 
                        forKey:@"context"];
        }
        
        if (!entry.m_type.empty()) {
            [jsonEntry setObject:[NSString stringWithUTF8String:entry.m_type.c_str()] 
                        forKey:@"type"];
        }
        
        if (!entry.m_source.empty()) {
            [jsonEntry setObject:[NSString stringWithUTF8String:entry.m_source.c_str()] 
                         forKey:@"source"];
        }
        
        [jsonEntry setObject:@(entry.m_timestamp) forKey:@"timestamp"];
        
        [jsonArray addObject:jsonEntry];
    }
    
    // Convert to JSON data
    NSError* error = nil;
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:jsonArray 
                                                      options:NSJSONWritingPrettyPrinted 
                                                        error:&error];
    
    if (error || !jsonData) {
        return false;
    }
    
    // Save to file
    NSString* dataFile = [NSString stringWithUTF8String:(m_dataPath + "/training_data.json").c_str()];
    return [jsonData writeToFile:dataFile atomically:YES];
}

// Process training buffer
void OfflineService::ProcessTrainingBuffer() {
    // This would process training data to update model parameters
    // For now, this is just a placeholder
}

// Get model path
std::string OfflineService::GetModelPath(const std::string& modelName) const {
    return m_modelPath + "/" + modelName;
}

// Get data path
std::string OfflineService::GetDataPath(const std::string& dataType) const {
    return m_dataPath + "/" + (dataType.empty() ? "" : dataType + "_");
}

// Update model version
void OfflineService::UpdateModelVersion(const std::string& modelName) {
    if (modelName.empty()) {
        // Update all models
        for (const auto& model : GetAvailableModels()) {
            UpdateModelVersion(model);
        }
        return;
    }
    
    // Get current version
    std::string version = GetModelVersion(modelName);
    
    // Parse version
    int major = 1, minor = 0, patch = 0;
    sscanf(version.c_str(), "%d.%d.%d", &major, &minor, &patch);
    
    // Increment patch version
    patch++;
    
    // Create new version string
    std::stringstream ss;
    ss << major << "." << minor << "." << patch;
    
    // Update version
    m_modelVersions[modelName] = ss.str();
}

// Validate training data
bool OfflineService::ValidateTrainingData(const TrainingData& data) const {
    // Basic validation
    if (data.m_input.empty() || data.m_output.empty()) {
        return false;
    }
    
    return true;
}

// Select model for request
void* OfflineService::SelectModelForRequest(const Request& request) {
    // For now, we'll always return a script generation model
    // In a real implementation, you would have different models for different request types
    
    // Create script generation model if needed
    static std::shared_ptr<LocalModels::ScriptGenerationModel> scriptGenerator = nullptr;
    
    if (!scriptGenerator) {
        scriptGenerator = std::make_shared<LocalModels::ScriptGenerationModel>();
        scriptGenerator->Initialize(GetModelPath("script_generator"));
    }
    
    return scriptGenerator.get();
}

} // namespace AIFeatures
} // namespace iOS
