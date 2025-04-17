
#include "../../../objc_isolation.h"
#pragma once

#include <string>
#include <vector>
#include <unordered_map>
#include <memory>
#include <functional>
#include <mutex>

namespace iOS {
namespace AIFeatures {
namespace LocalModels {

/**
 * @class LocalModelBase
 * @brief Base class for all locally trained AI models
 * 
 * This abstract class provides the foundation for all locally trained models.
 * Instead of using pre-built models, these models are created and trained directly
 * on the device, learning from user interactions and adapting over time.
 */
class LocalModelBase {
public:
    // Training sample structure
    struct TrainingSample {
        std::string m_input;              // Input data (query, script, etc.)
        std::string m_output;             // Expected output
        std::vector<float> m_features;    // Extracted features
        uint64_t m_timestamp;             // When the sample was collected
        float m_weight;                   // Sample importance weight
        
        TrainingSample() : m_timestamp(0), m_weight(1.0f) {}
        
        TrainingSample(const std::string& input, const std::string& output)
            : m_input(input), m_output(output), m_timestamp(0), m_weight(1.0f) {}
    };
    
    // Training progress callback
    using TrainingProgressCallback = std::function<void(float progress, float accuracy)>;
    
    // Prediction callback
    using PredictionCallback = std::function<void(const std::string& result)>;
    
protected:
    // Model parameters
    struct ModelParams {
        uint32_t m_inputDim;              // Input dimension
        uint32_t m_outputDim;             // Output dimension
        uint32_t m_hiddenLayers;          // Number of hidden layers
        uint32_t m_hiddenUnits;           // Units per hidden layer
        float m_learningRate;             // Learning rate
        float m_regularization;           // Regularization strength
        uint32_t m_batchSize;             // Batch size for training
        uint32_t m_epochs;                // Training epochs
        
        ModelParams()
            : m_inputDim(64), m_outputDim(64), m_hiddenLayers(2), m_hiddenUnits(128),
              m_learningRate(0.001f), m_regularization(0.0001f), m_batchSize(32), m_epochs(10) {}
    };
    
    // Member variables
    std::string m_modelName;              // Unique model name
    std::string m_modelDescription;       // Model description
    std::string m_modelType;              // Model type (classification, generation, etc.)
    std::string m_storagePath;            // Path for model storage
    ModelParams m_params;                 // Model parameters
    std::vector<TrainingSample> m_trainingSamples; // Training samples
    bool m_isInitialized;                 // Initialization flag
    bool m_isTrained;                     // Training flag
    uint32_t m_version;                   // Model version
    uint64_t m_lastTrainingTime;          // Last training timestamp
    uint32_t m_trainingSessions;          // Number of training sessions
    float m_currentAccuracy;              // Current model accuracy
    std::mutex m_mutex;                   // Mutex for thread safety
    
    // Virtual methods to be implemented by derived classes
    virtual bool InitializeModel() = 0;
    virtual bool TrainModel(TrainingProgressCallback progressCallback = nullptr) = 0;
    virtual std::string PredictInternal(const std::string& input) = 0;
    virtual std::vector<float> FeaturizeInput(const std::string& input) = 0;
    virtual std::string ProcessOutput(const std::vector<float>& output) = 0;
    
    // Utility methods
    bool SaveModelToFile(const std::string& filename);
    bool LoadModelFromFile(const std::string& filename);
    void LogTrainingProgress(float progress, float accuracy);
    void UpdateAccuracy(float accuracy);
    
public:
    /**
     * @brief Constructor
     * @param modelName Unique model name
     * @param modelDescription Model description
     * @param modelType Model type
     */
    LocalModelBase(const std::string& modelName, 
                  const std::string& modelDescription,
                  const std::string& modelType);
    
    /**
     * @brief Virtual destructor
     */
    virtual ~LocalModelBase();
    
    /**
     * @brief Initialize the model
     * @param storagePath Path for model storage
     * @return True if initialization succeeded
     */
    bool Initialize(const std::string& storagePath);
    
    /**
     * @brief Add a training sample
     * @param input Input data
     * @param output Expected output
     * @return True if sample was added
     */
    bool AddTrainingSample(const std::string& input, const std::string& output);
    
    /**
     * @brief Add a training sample with features
     * @param sample Training sample
     * @return True if sample was added
     */
    bool AddTrainingSample(const TrainingSample& sample);
    
    /**
     * @brief Train the model with current samples
     * @param progressCallback Optional callback for training progress
     * @return True if training succeeded
     */
    bool Train(TrainingProgressCallback progressCallback = nullptr);
    
    /**
     * @brief Predict output for input
     * @param input Input data
     * @return Predicted output
     */
    std::string Predict(const std::string& input);
    
    /**
     * @brief Predict output asynchronously
     * @param input Input data
     * @param callback Callback function
     */
    void PredictAsync(const std::string& input, PredictionCallback callback);
    
    /**
     * @brief Get model name
     * @return Model name
     */
    std::string GetModelName() const;
    
    /**
     * @brief Get model description
     * @return Model description
     */
    std::string GetModelDescription() const;
    
    /**
     * @brief Get model type
     * @return Model type
     */
    std::string GetModelType() const;
    
    /**
     * @brief Get number of training samples
     * @return Number of samples
     */
    size_t GetTrainingSampleCount() const;
    
    /**
     * @brief Check if model is trained
     * @return True if trained
     */
    bool IsTrained() const;
    
    /**
     * @brief Get model accuracy
     * @return Current accuracy (0-1)
     */
    float GetAccuracy() const;
    
    /**
     * @brief Get model version
     * @return Model version
     */
    uint32_t GetVersion() const;
    
    /**
     * @brief Set model parameters
     * @param inputDim Input dimension
     * @param outputDim Output dimension
     * @param hiddenLayers Number of hidden layers
     * @param hiddenUnits Units per hidden layer
     * @param learningRate Learning rate
     */
    void SetModelParameters(uint32_t inputDim, uint32_t outputDim,
                           uint32_t hiddenLayers, uint32_t hiddenUnits,
                           float learningRate);
    
    /**
     * @brief Save the model
     * @return True if save succeeded
     */
    bool SaveModel();
    
    /**
     * @brief Load the model
     * @return True if load succeeded
     */
    bool LoadModel();
    
    /**
     * @brief Clear training samples
     * @return Number of samples cleared
     */
    size_t ClearTrainingSamples();
    
    /**
     * @brief Export model to file
     * @param filename File to export to
     * @return True if export succeeded
     */
    bool ExportModel(const std::string& filename);
    
    /**
     * @brief Import model from file
     * @param filename File to import from
     * @return True if import succeeded
     */
    bool ImportModel(const std::string& filename);
    
    /**
     * @brief Get memory usage
     * @return Memory usage in bytes
     */
    virtual uint64_t GetMemoryUsage() const;
};

} // namespace LocalModels
} // namespace AIFeatures
} // namespace iOS
