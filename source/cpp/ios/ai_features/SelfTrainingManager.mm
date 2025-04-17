
#include "../../ios_compat.h"
#include "SelfTrainingManager.h"
#include "local_models/LocalModelBase.h"
#include "local_models/ScriptGenerationModel.h"
#include "local_models/VulnerabilityDetectionModel.h"
#include "local_models/ScriptDebugModel.h"
#include "local_models/UIAssistanceModel.h"
#include <iostream>
#include <fstream>
#include <sstream>
#include <algorithm>
#include <random>

namespace iOS {
namespace AIFeatures {

// Constructor
SelfTrainingManager::SelfTrainingManager()
    : m_isTrainingActive(false),
      m_stopTrainingThread(false),
      m_totalMemoryUsage(0),
      m_lastEvaluation(std::chrono::system_clock::now()) {
}

// Destructor
SelfTrainingManager::~SelfTrainingManager() {
    // Stop training thread if active
    if (m_isTrainingActive) {
        StopTrainingThread();
    }
}

// Initialize the training manager
bool SelfTrainingManager::Initialize(const std::string& basePath) {
    m_modelBasePath = basePath;
    
    // Create model directories
    if (!CreateModelDirectories()) {
        std::cerr << "SelfTrainingManager: Failed to create model directories" << std::endl;
        return false;
    }
    
    // Load base templates
    if (!LoadBaseTemplates()) {
        std::cerr << "SelfTrainingManager: Failed to load base templates" << std::endl;
        // Continue anyway as we can generate templates on the fly
    }
    
    // Start training thread
    if (!StartTrainingThread()) {
        std::cerr << "SelfTrainingManager: Failed to start training thread" << std::endl;
        return false;
    }
    
    std::cout << "SelfTrainingManager: Initialized successfully" << std::endl;
    return true;
}

// Create model directories
bool SelfTrainingManager::CreateModelDirectories() {
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSString* basePath = [NSString stringWithUTF8String:m_modelBasePath.c_str()];
    
    // Create base directory if it doesn't exist
    if (![fileManager fileExistsAtPath:basePath]) {
        NSError* error = nil;
        if (![fileManager createDirectoryAtPath:basePath
                    withIntermediateDirectories:YES
                                     attributes:nil
                                          error:&error]) {
            std::cerr << "SelfTrainingManager: Failed to create base directory: "
                     << [[error localizedDescription] UTF8String] << std::endl;
            return false;
        }
    }
    
    // Create subdirectories for different model types
    NSArray* subdirs = @[
        @"script_generation",
        @"vulnerability_detection",
        @"script_debug",
        @"ui_assistance",
        @"training_data",
        @"templates"
    ];
    
    for (NSString* subdir in subdirs) {
        NSString* dirPath = [basePath stringByAppendingPathComponent:subdir];
        if (![fileManager fileExistsAtPath:dirPath]) {
            NSError* error = nil;
            if (![fileManager createDirectoryAtPath:dirPath
                        withIntermediateDirectories:YES
                                         attributes:nil
                                              error:&error]) {
                std::cerr << "SelfTrainingManager: Failed to create subdirectory "
                         << [subdir UTF8String] << ": "
                         << [[error localizedDescription] UTF8String] << std::endl;
                // Continue anyway, we'll retry as needed
            }
        }
    }
    
    return true;
}

// Load base templates
bool SelfTrainingManager::LoadBaseTemplates() {
    // Define built-in base templates for each model type
    m_baseTemplates["script_generation"] = R"(
-- Basic structure for a Roblox script
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Constants
local SPEED = 16

-- Variables
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- Functions
local function OnPlayerAdded(player)
    print("Player added: " .. player.Name)
    -- Initialize player-specific logic here
end

-- Connect events
Players.PlayerAdded:Connect(OnPlayerAdded)

-- Main functionality
local function Initialize()
    print("Script initialized")
    -- Main initialization code here
end

Initialize()
)";

    m_baseTemplates["vulnerability_detection"] = R"(
-- Vulnerability detection template
local function CheckSecurity()
    local securityIssues = {}
    
    -- Check for common vulnerabilities
    if game:GetService("HttpService").HttpEnabled then
        table.insert(securityIssues, "HttpService is enabled, potential data exfiltration risk")
    end
    
    -- Check for script injection points
    if _G.RunScript then
        table.insert(securityIssues, "Global RunScript function detected, script injection risk")
    end
    
    -- Check for insecure remote events
    for _, v in pairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
        if v:IsA("RemoteEvent") and v.Name:lower():find("admin") then
            table.insert(securityIssues, "Potentially insecure admin RemoteEvent: " .. v:GetFullName())
        end
    end
    
    return securityIssues
end

-- Returns a list of security issues
return CheckSecurity()
)";

    m_baseTemplates["script_debug"] = R"(
-- Script debugging template
local function DebugScript(script)
    local issues = {}
    local lines = {}
    
    -- Split script into lines
    for line in script:gmatch("[^\r\n]+") do
        table.insert(lines, line)
    end
    
    -- Check for common issues
    for i, line in ipairs(lines) do
        -- Check for undefined variables
        if line:match("local%s+(%w+)%s*=") then
            -- Variable declaration found
        elseif line:match("%s*(%w+)%s*=") then
            local var = line:match("%s*(%w+)%s*=")
            -- Check if variable was declared
            local isDeclared = false
            for j = 1, i-1 do
                if lines[j]:match("local%s+" .. var .. "%s*=") then
                    isDeclared = true
                    break
                end
            end
            if not isDeclared then
                table.insert(issues, {line = i, message = "Potentially undefined variable: " .. var})
            end
        end
        
        -- Check for infinite loops
        if line:match("while%s+true") and not line:match("wait") then
            local hasWait = false
            for j = i+1, math.min(i+10, #lines) do
                if lines[j]:match("wait") or lines[j]:match("break") then
                    hasWait = true
                    break
                end
                if lines[j]:match("end") then
                    break
                end
            end
            if not hasWait then
                table.insert(issues, {line = i, message = "Potential infinite loop detected"})
            end
        end
    end
    
    return issues
end

-- Returns a list of issues with line numbers
return DebugScript
)";

    m_baseTemplates["ui_assistance"] = R"(
-- UI assistance template
local function CreateUI(config)
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = config.name or "GeneratedUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, config.width or 300, 0, config.height or 200)
    MainFrame.Position = UDim2.new(0.5, -(config.width or 300)/2, 0.5, -(config.height or 200)/2)
    MainFrame.BackgroundColor3 = Color3.fromRGB(config.bgColor[1] or 45, config.bgColor[2] or 45, config.bgColor[3] or 45)
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui
    
    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Size = UDim2.new(1, 0, 0, 30)
    Title.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    Title.BorderSizePixel = 0
    Title.Text = config.title or "Generated UI"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 18
    Title.Font = Enum.Font.SourceSansBold
    Title.Parent = MainFrame
    
    -- Add dynamic elements based on config
    if config.elements then
        for i, element in ipairs(config.elements) do
            if element.type == "button" then
                local Button = Instance.new("TextButton")
                Button.Name = element.name or "Button" .. i
                Button.Size = UDim2.new(0, element.width or 100, 0, element.height or 30)
                Button.Position = UDim2.new(element.position[1] or 0.5, element.position[2] or 0, element.position[3] or 0.5, element.position[4] or 40 + (i-1)*40)
                Button.BackgroundColor3 = Color3.fromRGB(element.bgColor[1] or 65, element.bgColor[2] or 65, element.bgColor[3] or 65)
                Button.BorderSizePixel = 0
                Button.Text = element.text or "Button"
                Button.TextColor3 = Color3.fromRGB(255, 255, 255)
                Button.TextSize = 16
                Button.Font = Enum.Font.SourceSans
                Button.Parent = MainFrame
            elseif element.type == "textbox" then
                -- Add textbox element
            elseif element.type == "image" then
                -- Add image element
            end
        end
    end
    
    return ScreenGui
end

-- Returns a UI generation function
return CreateUI
)";

    // Save templates to disk for future reference
    NSString* basePathStr = [NSString stringWithUTF8String:m_modelBasePath.c_str()];
    NSString* templateDir = [basePathStr stringByAppendingPathComponent:@"templates"];
    NSFileManager* fileManager = [NSFileManager defaultManager];
    
    for (const auto& templatePair : m_baseTemplates) {
        NSString* filename = [templateDir stringByAppendingPathComponent:
                           [NSString stringWithFormat:@"%s_template.lua", templatePair.first.c_str()]];
        
        NSData* data = [NSData dataWithBytes:templatePair.second.c_str() 
                                      length:templatePair.second.length()];
        
        [data writeToFile:filename atomically:YES];
    }
    
    return true;
}

// Add a model
bool SelfTrainingManager::AddModel(const std::string& modelName, 
                                 std::shared_ptr<LocalModels::LocalModelBase> model) {
    if (!model) {
        return false;
    }
    
    std::lock_guard<std::mutex> lock(m_modelMutex);
    
    // Add model to map
    m_models[modelName] = model;
    
    // Initialize training status
    m_trainingStatus[modelName] = TrainingStatus::NotStarted;
    m_modelStatus[modelName] = model->IsTrained() ? 
        ModelInitStatus::Ready : ModelInitStatus::NotInitialized;
    m_trainingProgress[modelName] = 0.0f;
    
    // Update memory usage
    m_totalMemoryUsage += model->GetMemoryUsage();
    
    std::cout << "SelfTrainingManager: Added model " << modelName << std::endl;
    return true;
}

// Check if a model exists
bool SelfTrainingManager::HasModel(const std::string& modelName) const {
    std::lock_guard<std::mutex> lock(m_modelMutex);
    return m_models.find(modelName) != m_models.end();
}

// Get a model by name
std::shared_ptr<LocalModels::LocalModelBase> SelfTrainingManager::GetModel(const std::string& modelName) {
    std::lock_guard<std::mutex> lock(m_modelMutex);
    auto it = m_models.find(modelName);
    if (it != m_models.end()) {
        return it->second;
    }
    return nullptr;
}

// Start the training thread
bool SelfTrainingManager::StartTrainingThread() {
    if (m_isTrainingActive) {
        return true; // Already running
    }
    
    // Reset stop flag
    m_stopTrainingThread = false;
    
    // Start thread
    try {
        m_trainingThread = std::thread(&SelfTrainingManager::TrainingThreadFunction, this);
        m_isTrainingActive = true;
        std::cout << "SelfTrainingManager: Started training thread" << std::endl;
        return true;
    } catch (const std::exception& e) {
        std::cerr << "SelfTrainingManager: Failed to start training thread: " 
                 << e.what() << std::endl;
        return false;
    }
}

// Stop the training thread
void SelfTrainingManager::StopTrainingThread() {
    if (!m_isTrainingActive) {
        return; // Not running
    }
    
    // Set stop flag
    m_stopTrainingThread = true;
    
    // Wait for thread to finish
    if (m_trainingThread.joinable()) {
        m_trainingThread.join();
    }
    
    m_isTrainingActive = false;
    std::cout << "SelfTrainingManager: Stopped training thread" << std::endl;
}

// Training thread function
void SelfTrainingManager::TrainingThreadFunction() {
    std::cout << "SelfTrainingManager: Training thread started" << std::endl;
    
    while (!m_stopTrainingThread) {
        // Process training queue
        ProcessTrainingQueue();
        
        // Sleep for a short time to avoid busy-waiting
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
    }
    
    std::cout << "SelfTrainingManager: Training thread stopped" << std::endl;
}

// Process training queue
void SelfTrainingManager::ProcessTrainingQueue() {
    std::function<void()> job;
    bool hasJob = false;
    
    // Get a job from the queue
    {
        std::lock_guard<std::mutex> lock(m_queueMutex);
        if (!m_trainingQueue.empty()) {
            job = m_trainingQueue.front();
            m_trainingQueue.pop();
            hasJob = true;
        }
    }
    
    // Execute the job if we got one
    if (hasJob && job) {
        try {
            job();
        } catch (const std::exception& e) {
            std::cerr << "SelfTrainingManager: Exception during training job: " 
                     << e.what() << std::endl;
        }
    }
}

// Queue a model for training
bool SelfTrainingManager::QueueModelForTraining(const std::string& modelName) {
    // Get the model
    auto model = GetModel(modelName);
    if (!model) {
        std::cerr << "SelfTrainingManager: Model not found: " << modelName << std::endl;
        return false;
    }
    
    // Update training status
    {
        std::lock_guard<std::mutex> lock(m_modelMutex);
        m_trainingStatus[modelName] = TrainingStatus::InProgress;
        m_trainingProgress[modelName] = 0.0f;
        
        // Notify progress
        NotifyProgressUpdate(modelName, 0.0f, false);
    }
    
    // Create training job
    std::function<void()> trainingJob = [this, modelName, model]() {
        std::cout << "SelfTrainingManager: Starting training for model " << modelName << std::endl;
        
        try {
            // Check if we have training samples
            std::vector<std::pair<std::string, std::string>> samples;
            {
                std::lock_guard<std::mutex> lock(m_modelMutex);
                auto it = m_trainingSamples.find(modelName);
                if (it != m_trainingSamples.end()) {
                    samples = it->second;
                }
            }
            
            // If we don't have samples, generate some
            if (samples.empty()) {
                std::string modelType;
                
                // Determine model type from name
                if (modelName.find("script_gen") != std::string::npos) {
                    modelType = "script_generation";
                } else if (modelName.find("vuln") != std::string::npos) {
                    modelType = "vulnerability_detection";
                } else if (modelName.find("debug") != std::string::npos) {
                    modelType = "script_debug";
                } else if (modelName.find("ui") != std::string::npos) {
                    modelType = "ui_assistance";
                } else {
                    modelType = "script_generation"; // Default
                }
                
                samples = GenerateBaseSamples(modelType);
                
                // Save generated samples
                {
                    std::lock_guard<std::mutex> lock(m_modelMutex);
                    m_trainingSamples[modelName] = samples;
                }
            }
            
            // Add training samples to model
            for (const auto& sample : samples) {
                model->AddTrainingSample(sample.first, sample.second);
            }
            
            // Train the model with progress updates
            bool success = model->Train([this, modelName](float progress, float accuracy) {
                SaveTrainingProgress(modelName, progress);
                NotifyProgressUpdate(modelName, progress, false);
            });
            
            // Update training status based on result
            {
                std::lock_guard<std::mutex> lock(m_modelMutex);
                m_trainingStatus[modelName] = success ? 
                    TrainingStatus::Completed : TrainingStatus::Failed;
                m_modelStatus[modelName] = success ? 
                    ModelInitStatus::Ready : ModelInitStatus::Failed;
                m_trainingProgress[modelName] = success ? 1.0f : 0.0f;
                
                // Notify completion
                NotifyProgressUpdate(modelName, m_trainingProgress[modelName], true);
            }
            
            // Evaluate model if training succeeded
            if (success) {
                EvaluateModel(modelName);
            }
            
            std::cout << "SelfTrainingManager: " 
                     << (success ? "Completed" : "Failed") 
                     << " training for model " << modelName << std::endl;
        } catch (const std::exception& e) {
            std::cerr << "SelfTrainingManager: Exception during training: " 
                     << e.what() << std::endl;
            
            // Update training status on error
            {
                std::lock_guard<std::mutex> lock(m_modelMutex);
                m_trainingStatus[modelName] = TrainingStatus::Failed;
                
                // Notify failure
                NotifyProgressUpdate(modelName, m_trainingProgress[modelName], true);
            }
        }
    };
    
    // Queue the job
    {
        std::lock_guard<std::mutex> lock(m_queueMutex);
        m_trainingQueue.push(trainingJob);
    }
    
    return true;
}

// Queue all models for training
size_t SelfTrainingManager::QueueAllModelsForTraining() {
    std::vector<std::string> modelNames;
    
    // Get all model names
    {
        std::lock_guard<std::mutex> lock(m_modelMutex);
        for (const auto& pair : m_models) {
            modelNames.push_back(pair.first);
        }
    }
    
    // Queue each model
    size_t count = 0;
    for (const auto& name : modelNames) {
        if (QueueModelForTraining(name)) {
            count++;
        }
    }
    
    return count;
}

// Add a training sample
bool SelfTrainingManager::AddTrainingSample(const std::string& modelName, 
                                         const std::string& input, 
                                         const std::string& output) {
    std::lock_guard<std::mutex> lock(m_modelMutex);
    
    // Add to training samples
    m_trainingSamples[modelName].push_back(std::make_pair(input, output));
    
    // If we have a model, add directly to it as well
    auto it = m_models.find(modelName);
    if (it != m_models.end() && it->second) {
        it->second->AddTrainingSample(input, output);
    }
    
    return true;
}

// Generate a new model
bool SelfTrainingManager::GenerateModel(const std::string& modelType) {
    std::string modelName;
    std::shared_ptr<LocalModels::LocalModelBase> model;
    
    // Create model path
    std::string modelPath = m_modelBasePath + "/" + modelType;
    
    try {
        // Create appropriate model based on type
        if (modelType == "script_generation") {
            modelName = "script_generation_model";
            model = std::make_shared<LocalModels::ScriptGenerationModel>();
        } else if (modelType == "vulnerability_detection") {
            modelName = "vulnerability_detection_model";
            model = std::make_shared<LocalModels::VulnerabilityDetectionModel>();
        } else if (modelType == "script_debug") {
            modelName = "script_debug_model";
            model = std::make_shared<LocalModels::ScriptDebugModel>();
        } else if (modelType == "ui_assistance") {
            modelName = "ui_assistance_model";
            model = std::make_shared<LocalModels::UIAssistanceModel>();
        } else {
            std::cerr << "SelfTrainingManager: Unknown model type: " << modelType << std::endl;
            return false;
        }
        
        // Initialize model
        if (!model->Initialize(modelPath)) {
            std::cerr << "SelfTrainingManager: Failed to initialize model: " << modelName << std::endl;
            return false;
        }
        
        // Add model
        if (!AddModel(modelName, model)) {
            std::cerr << "SelfTrainingManager: Failed to add model: " << modelName << std::endl;
            return false;
        }
        
        // Queue model for training
        if (!QueueModelForTraining(modelName)) {
            std::cerr << "SelfTrainingManager: Failed to queue model for training: " << modelName << std::endl;
            return false;
        }
        
        return true;
    } catch (const std::exception& e) {
        std::cerr << "SelfTrainingManager: Exception during model generation: " 
                 << e.what() << std::endl;
        return false;
    }
}

// Get training status
SelfTrainingManager::TrainingStatus SelfTrainingManager::GetTrainingStatus(const std::string& modelName) const {
    std::lock_guard<std::mutex> lock(m_modelMutex);
    auto it = m_trainingStatus.find(modelName);
    if (it != m_trainingStatus.end()) {
        return it->second;
    }
    return TrainingStatus::NotStarted;
}

// Get model status
SelfTrainingManager::ModelInitStatus SelfTrainingManager::GetModelStatus(const std::string& modelName) const {
    std::lock_guard<std::mutex> lock(m_modelMutex);
    auto it = m_modelStatus.find(modelName);
    if (it != m_modelStatus.end()) {
        return it->second;
    }
    return ModelInitStatus::NotInitialized;
}

// Get training progress
float SelfTrainingManager::GetTrainingProgress(const std::string& modelName) const {
    std::lock_guard<std::mutex> lock(m_modelMutex);
    auto it = m_trainingProgress.find(modelName);
    if (it != m_trainingProgress.end()) {
        return it->second;
    }
    return 0.0f;
}

// Set training progress callback
void SelfTrainingManager::SetProgressCallback(TrainingProgressCallback callback) {
    m_progressCallback = callback;
}

// Save training progress
void SelfTrainingManager::SaveTrainingProgress(const std::string& modelName, float progress) {
    std::lock_guard<std::mutex> lock(m_modelMutex);
    m_trainingProgress[modelName] = progress;
}

// Save training status
void SelfTrainingManager::SaveTrainingStatus(const std::string& modelName, TrainingStatus status) {
    std::lock_guard<std::mutex> lock(m_modelMutex);
    m_trainingStatus[modelName] = status;
}

// Notify progress update
void SelfTrainingManager::NotifyProgressUpdate(const std::string& modelName, float progress, bool completed) {
    if (m_progressCallback) {
        // Call on main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            m_progressCallback(modelName, progress, completed);
        });
    }
}

// Get all model names
std::vector<std::string> SelfTrainingManager::GetAllModelNames() const {
    std::lock_guard<std::mutex> lock(m_modelMutex);
    std::vector<std::string> names;
    
    for (const auto& pair : m_models) {
        names.push_back(pair.first);
    }
    
    return names;
}

// Get total memory usage
uint64_t SelfTrainingManager::GetTotalMemoryUsage() const {
    return m_totalMemoryUsage;
}

// Prune models to reduce memory usage
uint64_t SelfTrainingManager::PruneModels(uint64_t targetUsage) {
    std::lock_guard<std::mutex> lock(m_modelMutex);
    
    if (m_totalMemoryUsage <= targetUsage) {
        return 0; // Already below target
    }
    
    uint64_t memoryBefore = m_totalMemoryUsage;
    
    // Create a list of models sorted by last used time (oldest first)
    std::vector<std::pair<std::string, std::shared_ptr<LocalModels::LocalModelBase>>> modelList;
    
    for (const auto& pair : m_models) {
        modelList.push_back(pair);
    }
    
    // Sort models by training status and last used time
    std::sort(modelList.begin(), modelList.end(), 
             [this](const auto& a, const auto& b) {
                 // Prefer to unload models that are not training
                 if (m_trainingStatus[a.first] == TrainingStatus::InProgress &&
                     m_trainingStatus[b.first] != TrainingStatus::InProgress) {
                     return false;
                 }
                 if (m_trainingStatus[a.first] != TrainingStatus::InProgress &&
                     m_trainingStatus[b.first] == TrainingStatus::InProgress) {
                     return true;
                 }
                 
                 // Otherwise unload oldest models first
                 // Note: In a real implementation, we would track last used time
                 return a.first < b.first;
             });
    
    // Unload models until we're below target
    for (const auto& pair : modelList) {
        if (m_totalMemoryUsage <= targetUsage) {
            break;
        }
        
        // Skip models that are in training
        if (m_trainingStatus[pair.first] == TrainingStatus::InProgress) {
            continue;
        }
        
        // Get memory usage of this model
        uint64_t modelMemory = pair.second->GetMemoryUsage();
        
        // Save model to disk
        pair.second->SaveModel();
        
        // Unload model (this doesn't remove it from m_models)
        m_modelStatus[pair.first] = ModelInitStatus::NotInitialized;
        
        // Update memory usage
        m_totalMemoryUsage -= modelMemory;
    }
    
    return memoryBefore - m_totalMemoryUsage;
}

// Evaluate model
bool SelfTrainingManager::EvaluateModel(const std::string& modelName) {
    // In a real implementation, we would evaluate the model's performance
    // on validation data to track how it's improving over time.
    std::cout << "SelfTrainingManager: Evaluating model " << modelName << std::endl;
    
    // For now, just update the last evaluation time
    m_lastEvaluation = std::chrono::system_clock::now();
    
    return true;
}

// Generate base training samples
std::vector<std::pair<std::string, std::string>> SelfTrainingManager::GenerateBaseSamples(const std::string& modelType) {
    std::vector<std::pair<std::string, std::string>> samples;
    
    // Get base template
    auto it = m_baseTemplates.find(modelType);
    std::string baseTemplate;
    
    if (it != m_baseTemplates.end()) {
        baseTemplate = it->second;
    } else {
        std::cerr << "SelfTrainingManager: No base template for model type: " << modelType << std::endl;
        return samples;
    }
    
    // Generate samples based on model type
    if (modelType == "script_generation") {
        // Script generation samples (simple input -> script pairs)
        samples.push_back({"Create a script that moves a character forward", baseTemplate});
        samples.push_back({"Make a simple GUI with a button", 
                       "local ScreenGui = Instance.new(\"ScreenGui\")\n"
                       "local Frame = Instance.new(\"Frame\")\n"
                       "local Button = Instance.new(\"TextButton\")\n\n"
                       "ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild(\"PlayerGui\")\n\n"
                       "Frame.Size = UDim2.new(0, 200, 0, 100)\n"
                       "Frame.Position = UDim2.new(0.5, -100, 0.5, -50)\n"
                       "Frame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)\n"
                       "Frame.BorderSizePixel = 0\n"
                       "Frame.Parent = ScreenGui\n\n"
                       "Button.Size = UDim2.new(0, 150, 0, 50)\n"
                       "Button.Position = UDim2.new(0.5, -75, 0.5, -25)\n"
                       "Button.BackgroundColor3 = Color3.fromRGB(65, 65, 65)\n"
                       "Button.BorderSizePixel = 0\n"
                       "Button.Text = \"Click Me\"\n"
                       "Button.TextColor3 = Color3.fromRGB(255, 255, 255)\n"
                       "Button.Parent = Frame\n\n"
                       "Button.MouseButton1Click:Connect(function()\n"
                       "    print(\"Button clicked!\")\n"
                       "end)"});
        samples.push_back({"Create a teleport script", 
                       "local Players = game:GetService(\"Players\")\n"
                       "local TeleportService = game:GetService(\"TeleportService\")\n\n"
                       "local DESTINATION_PLACE_ID = 12345 -- Replace with actual place ID\n\n"
                       "local function teleportPlayer(player)\n"
                       "    local success, errorMessage = pcall(function()\n"
                       "        TeleportService:Teleport(DESTINATION_PLACE_ID, player)\n"
                       "    end)\n"
                       "    \n"
                       "    if not success then\n"
                       "        warn(\"Failed to teleport player: \" .. errorMessage)\n"
                       "    end\n"
                       "end\n\n"
                       "-- Example usage:\n"
                       "-- teleportPlayer(Players.LocalPlayer)"});
    } else if (modelType == "vulnerability_detection") {
        // Vulnerability detection samples
        samples.push_back({"Check for remote event vulnerabilities", baseTemplate});
        samples.push_back({"Detect script injection vulnerabilities", 
                       "local function CheckForScriptInjection()\n"
                       "    local vulnerabilities = {}\n"
                       "    \n"
                       "    -- Check for known vulnerable patterns\n"
                       "    local scriptInjectionRisks = {\n"
                       "        _G.loadstring,\n"
                       "        _G.RunScript,\n"
                       "        _G.Execute,\n"
                       "        _G.exec,\n"
                       "        getfenv().loadstring\n"
                       "    }\n"
                       "    \n"
                       "    for name, func in pairs(scriptInjectionRisks) do\n"
                       "        if func then\n"
                       "            table.insert(vulnerabilities, \"Script injection risk: \" .. tostring(name))\n"
                       "        end\n"
                       "    end\n"
                       "    \n"
                       "    -- Check for RemoteEvent vulnerabilities\n"
                       "    for _, v in pairs(game:GetDescendants()) do\n"
                       "        if v:IsA(\"RemoteEvent\") then\n"
                       "            local connections = getconnections(v.OnServerEvent)\n"
                       "            if #connections == 0 then\n"
                       "                table.insert(vulnerabilities, \"Unhandled RemoteEvent: \" .. v:GetFullName())\n"
                       "            end\n"
                       "        end\n"
                       "    end\n"
                       "    \n"
                       "    return vulnerabilities\n"
                       "end\n\n"
                       "return CheckForScriptInjection()"});
    } else if (modelType == "script_debug") {
        // Script debug samples
        samples.push_back({"Debug a script with infinite loop", baseTemplate});
        samples.push_back({"Find errors in a script", 
                       "local function AnalyzeScript(script)\n"
                       "    local issues = {}\n"
                       "    \n"
                       "    -- Parse script into lines\n"
                       "    local lines = {}\n"
                       "    for line in script:gmatch(\"[^\\r\\n]+\") do\n"
                       "        table.insert(lines, line)\n"
                       "    end\n"
                       "    \n"
                       "    -- Variable tracking\n"
                       "    local declaredVars = {}\n"
                       "    local usedVars = {}\n"
                       "    \n"
                       "    -- Analyze each line\n"
                       "    for i, line in ipairs(lines) do\n"
                       "        -- Track declared variables\n"
                       "        for var in line:gmatch(\"local%s+([%w_]+)\") do\n"
                       "            declaredVars[var] = i\n"
                       "        end\n"
                       "        \n"
                       "        -- Track variable assignments\n"
                       "        for var in line:gmatch(\"%s*([%w_]+)%s*=%s*\") do\n"
                       "            if not declaredVars[var] and var ~= \"_\" then\n"
                       "                usedVars[var] = usedVars[var] or {}\n"
                       "                table.insert(usedVars[var], i)\n"
                       "            end\n"
                       "        end\n"
                       "        \n"
                       "        -- Check for infinite loops\n"
                       "        if line:match(\"while%s+true\") then\n"
                       "            -- Look ahead for wait/break\n"
                       "            local hasWait = false\n"
                       "            for j = i+1, math.min(i+20, #lines) do\n"
                       "                if lines[j]:match(\"wait%(%) \") or lines[j]:match(\"break\") then\n"
                       "                    hasWait = true\n"
                       "                    break\n"
                       "                end\n"
                       "                if lines[j]:match(\"end\") then\n"
                       "                    break\n"
                       "                end\n"
                       "            end\n"
                       "            \n"
                       "            if not hasWait then\n"
                       "                table.insert(issues, {line = i, message = \"Potential infinite loop\"})\n"
                       "            end\n"
                       "        end\n"
                       "    end\n"
                       "    \n"
                       "    -- Report undeclared variables\n"
                       "    for var, lines in pairs(usedVars) do\n"
                       "        if not declaredVars[var] then\n"
                       "            table.insert(issues, {line = lines[1], message = \"Using undeclared variable: \" .. var})\n"
                       "        end\n"
                       "    end\n"
                       "    \n"
                       "    return issues\n"
                       "end\n\n"
                       "return AnalyzeScript"});
    } else if (modelType == "ui_assistance") {
        // UI assistance samples
        samples.push_back({"Create a UI with buttons and labels", baseTemplate});
        samples.push_back({"Generate a sleek inventory UI", 
                       "local function CreateInventoryUI(config)\n"
                       "    local ScreenGui = Instance.new(\"ScreenGui\")\n"
                       "    ScreenGui.Name = \"InventoryUI\"\n"
                       "    ScreenGui.ResetOnSpawn = false\n"
                       "    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling\n"
                       "    \n"
                       "    local MainFrame = Instance.new(\"Frame\")\n"
                       "    MainFrame.Name = \"MainFrame\"\n"
                       "    MainFrame.Size = UDim2.new(0, 600, 0, 400)\n"
                       "    MainFrame.Position = UDim2.new(0.5, -300, 0.5, -200)\n"
                       "    MainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)\n"
                       "    MainFrame.BorderSizePixel = 0\n"
                       "    MainFrame.Parent = ScreenGui\n"
                       "    \n"
                       "    local Title = Instance.new(\"TextLabel\")\n"
                       "    Title.Name = \"Title\"\n"
                       "    Title.Size = UDim2.new(1, 0, 0, 40)\n"
                       "    Title.BackgroundColor3 = Color3.fromRGB(25, 25, 25)\n"
                       "    Title.BorderSizePixel = 0\n"
                       "    Title.Text = \"Inventory\"\n"
                       "    Title.TextColor3 = Color3.fromRGB(255, 255, 255)\n"
                       "    Title.TextSize = 24\n"
                       "    Title.Font = Enum.Font.SourceSansBold\n"
                       "    Title.Parent = MainFrame\n"
                       "    \n"
                       "    local CloseButton = Instance.new(\"TextButton\")\n"
                       "    CloseButton.Name = \"CloseButton\"\n"
                       "    CloseButton.Size = UDim2.new(0, 30, 0, 30)\n"
                       "    CloseButton.Position = UDim2.new(1, -35, 0, 5)\n"
                       "    CloseButton.BackgroundColor3 = Color3.fromRGB(255, 80, 80)\n"
                       "    CloseButton.BorderSizePixel = 0\n"
                       "    CloseButton.Text = \"X\"\n"
                       "    CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)\n"
                       "    CloseButton.TextSize = 18\n"
                       "    CloseButton.Font = Enum.Font.SourceSansBold\n"
                       "    CloseButton.Parent = MainFrame\n"
                       "    \n"
                       "    CloseButton.MouseButton1Click:Connect(function()\n"
                       "        ScreenGui:Destroy()\n"
                       "    end)\n"
                       "    \n"
                       "    local ItemsFrame = Instance.new(\"ScrollingFrame\")\n"
                       "    ItemsFrame.Name = \"ItemsFrame\"\n"
                       "    ItemsFrame.Size = UDim2.new(1, -20, 1, -60)\n"
                       "    ItemsFrame.Position = UDim2.new(0, 10, 0, 50)\n"
                       "    ItemsFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)\n"
                       "    ItemsFrame.BorderSizePixel = 0\n"
                       "    ItemsFrame.ScrollBarThickness = 6\n"
                       "    ItemsFrame.Parent = MainFrame\n"
                       "    \n"
                       "    local UIGridLayout = Instance.new(\"UIGridLayout\")\n"
                       "    UIGridLayout.CellSize = UDim2.new(0, 100, 0, 100)\n"
                       "    UIGridLayout.CellPadding = UDim2.new(0, 10, 0, 10)\n"
                       "    UIGridLayout.SortOrder = Enum.SortOrder.LayoutOrder\n"
                       "    UIGridLayout.Parent = ItemsFrame\n"
                       "    \n"
                       "    local UIPadding = Instance.new(\"UIPadding\")\n"
                       "    UIPadding.PaddingLeft = UDim.new(0, 10)\n"
                       "    UIPadding.PaddingRight = UDim.new(0, 10)\n"
                       "    UIPadding.PaddingTop = UDim.new(0, 10)\n"
                       "    UIPadding.PaddingBottom = UDim.new(0, 10)\n"
                       "    UIPadding.Parent = ItemsFrame\n"
                       "    \n"
                       "    -- Populate with sample items\n"
                       "    for i = 1, 20 do\n"
                       "        local ItemFrame = Instance.new(\"Frame\")\n"
                       "        ItemFrame.Name = \"Item\" .. i\n"
                       "        ItemFrame.BackgroundColor3 = Color3.fromRGB(65, 65, 65)\n"
                       "        ItemFrame.BorderSizePixel = 0\n"
                       "        ItemFrame.Parent = ItemsFrame\n"
                       "        \n"
                       "        local ItemImage = Instance.new(\"ImageLabel\")\n"
                       "        ItemImage.Name = \"ItemImage\"\n"
                       "        ItemImage.Size = UDim2.new(0, 60, 0, 60)\n"
                       "        ItemImage.Position = UDim2.new(0.5, -30, 0, 10)\n"
                       "        ItemImage.BackgroundTransparency = 1\n"
                       "        ItemImage.Image = \"rbxassetid://6023426926\"\n"
                       "        ItemImage.Parent = ItemFrame\n"
                       "        \n"
                       "        local ItemName = Instance.new(\"TextLabel\")\n"
                       "        ItemName.Name = \"ItemName\"\n"
                       "        ItemName.Size = UDim2.new(1, 0, 0, 20)\n"
                       "        ItemName.Position = UDim2.new(0, 0, 1, -25)\n"
                       "        ItemName.BackgroundTransparency = 1\n"
                       "        ItemName.Text = \"Item \" .. i\n"
                       "        ItemName.TextColor3 = Color3.fromRGB(255, 255, 255)\n"
                       "        ItemName.TextSize = 16\n"
                       "        ItemName.Font = Enum.Font.SourceSans\n"
                       "        ItemName.Parent = ItemFrame\n"
                       "    end\n"
                       "    \n"
                       "    -- Update grid size\n"
                       "    ItemsFrame.CanvasSize = UDim2.new(0, 0, 0, UIGridLayout.AbsoluteContentSize.Y + 20)\n"
                       "    \n"
                       "    return ScreenGui\n"
                       "end\n\n"
                       "return CreateInventoryUI"});
    }
    
    // Add a few more generic samples
    samples.push_back({"Example input 1", "Example output 1"});
    samples.push_back({"Example input 2", "Example output 2"});
    samples.push_back({"Example input 3", "Example output 3"});
    
    return samples;
}

// Get number of training samples
size_t SelfTrainingManager::GetTrainingSampleCount(const std::string& modelName) const {
    std::lock_guard<std::mutex> lock(m_modelMutex);
    auto it = m_trainingSamples.find(modelName);
    if (it != m_trainingSamples.end()) {
        return it->second.size();
    }
    return 0;
}

// Schedule automatic training
bool SelfTrainingManager::ScheduleAutomaticTraining(uint32_t intervalHours) {
    // In a real implementation, we would set up a timer to periodically train models
    // For now, just simulate it
    std::cout << "SelfTrainingManager: Scheduled automatic training every " 
             << intervalHours << " hours" << std::endl;
    
    // Queue all models for immediate training
    QueueAllModelsForTraining();
    
    return true;
}

// Generate base training samples for all models
size_t SelfTrainingManager::GenerateBaseTrainingSamples() {
    size_t totalSamples = 0;
    
    // Generate samples for each model type
    for (const auto& modelType : {"script_generation", "vulnerability_detection", 
                                "script_debug", "ui_assistance"}) {
        auto samples = GenerateBaseSamples(modelType);
        
        // Find models of this type
        std::lock_guard<std::mutex> lock(m_modelMutex);
        for (const auto& pair : m_models) {
            // Check if model matches type
            if (pair.first.find(modelType) != std::string::npos) {
                // Add samples
                m_trainingSamples[pair.first].insert(
                    m_trainingSamples[pair.first].end(),
                    samples.begin(), samples.end());
                totalSamples += samples.size();
            }
        }
    }
    
    return totalSamples;
}

} // namespace AIFeatures
} // namespace iOS
