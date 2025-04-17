
#include "../../ios_compat.h"
#include "MainViewController.h"
#include <chrono>
#include <iostream>
#include <algorithm>
#include <unordered_set>
#include <cmath>
#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore.h>

namespace iOS {
namespace UI {

    // Constructor
    MainViewController::MainViewController()
        : m_viewController(nullptr),
          m_tabBar(nullptr),
          m_navigationController(nullptr),
          m_floatingButton(nullptr),
          m_notificationView(nullptr),
          m_visualEffectsEngine(nullptr),
          m_memoryManager(nullptr),
          m_blurEffectView(nullptr),
          m_currentTab(Tab::Editor),
          m_visualStyle(VisualStyle::Dynamic),
          m_navigationMode(NavigationMode::Tabs),
          m_isVisible(false),
          m_isFloatingButtonVisible(true),
          m_isInGame(false),
          m_useHapticFeedback(true),
          m_useAnimations(true),
          m_reduceTransparency(false),
          m_reducedMemoryMode(false),
          m_colorScheme(1) // Default to scheme 1 (blue theme)
    {
        // Initialize with empty callbacks
        m_tabChangedCallback = [](Tab) {};
        m_visibilityChangedCallback = [](bool) {};
        m_executionCallback = [](const ScriptEditorViewController::ExecutionResult&) {};
    }

    // Destructor
    MainViewController::~MainViewController() {
        UnregisterFromNotifications();
        StoreUIState();
        
        // Release resources
        if (m_viewController) {
            CFRelease(m_viewController);
            m_viewController = nullptr;
        }
        
        if (m_floatingButton) {
            CFRelease(m_floatingButton);
            m_floatingButton = nullptr;
        }
    }

    // Initialize the view controller
    bool MainViewController::Initialize() {
        dispatch_async(dispatch_get_main_queue(), ^{
            InitializeUI();
            SetupFloatingButton();
            SetupTabBar();
            
            // Create editor view controller if not already created
            if (!m_editorViewController) {
                m_editorViewController = std::make_shared<ScriptEditorViewController>();
                m_editorViewController->Initialize();
                
                // Set script assistant if available
                if (m_scriptAssistant) {
                    m_editorViewController->SetScriptAssistant(m_scriptAssistant);
                }
            }
            
            // Set up game detection
            if (m_gameDetector) {
                SetupGameDetection();
            }
            
            // Register for notifications
            RegisterForNotifications();
        });
        
        return true;
    }

    // Show the UI
    void MainViewController::Show() {
        if (m_isVisible) return;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (m_viewController) {
                UIViewController* viewController = (__bridge UIViewController*)m_viewController;
                viewController.view.hidden = NO;
                
                // Animate appearance
                viewController.view.alpha = 0.0;
                [UIView animateWithDuration:0.3 animations:^{
                    viewController.view.alpha = 1.0;
                }];
            }
        });
        
        m_isVisible = true;
        
        // Call visibility changed callback
        if (m_visibilityChangedCallback) {
            m_visibilityChangedCallback(true);
        }
    }

    // Hide the UI
    void MainViewController::Hide() {
        if (!m_isVisible) return;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (m_viewController) {
                UIViewController* viewController = (__bridge UIViewController*)m_viewController;
                
                // Animate disappearance
                [UIView animateWithDuration:0.3 animations:^{
                    viewController.view.alpha = 0.0;
                } completion:^(BOOL finished) {
                    viewController.view.hidden = YES;
                }];
            }
        });
        
        m_isVisible = false;
        
        // Call visibility changed callback
        if (m_visibilityChangedCallback) {
            m_visibilityChangedCallback(false);
        }
    }

    // Toggle UI visibility
    bool MainViewController::Toggle() {
        if (m_isVisible) {
            Hide();
        } else {
            Show();
        }
        return m_isVisible;
    }

    // Check if UI is visible
    bool MainViewController::IsVisible() const {
        return m_isVisible;
    }

    // Show the floating button
    void MainViewController::ShowFloatingButton() {
        if (m_isFloatingButtonVisible) return;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (m_floatingButton) {
                UIView* floatingButton = (__bridge UIView*)m_floatingButton;
                floatingButton.hidden = NO;
                
                // Animate appearance
                floatingButton.alpha = 0.0;
                [UIView animateWithDuration:0.3 animations:^{
                    floatingButton.alpha = 1.0;
                }];
            }
        });
        
        m_isFloatingButtonVisible = true;
    }

    // Hide the floating button
    void MainViewController::HideFloatingButton() {
        if (!m_isFloatingButtonVisible) return;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (m_floatingButton) {
                UIView* floatingButton = (__bridge UIView*)m_floatingButton;
                
                // Animate disappearance
                [UIView animateWithDuration:0.3 animations:^{
                    floatingButton.alpha = 0.0;
                } completion:^(BOOL finished) {
                    floatingButton.hidden = YES;
                }];
            }
        });
        
        m_isFloatingButtonVisible = false;
    }

    // Set the current tab
    void MainViewController::SetTab(Tab tab) {
        if (tab == m_currentTab) return;
        
        Tab oldTab = m_currentTab;
        m_currentTab = tab;
        
        // Switch to the new tab
        SwitchToTab(tab, m_useAnimations);
        
        // Call the tab changed callback
        if (m_tabChangedCallback) {
            m_tabChangedCallback(tab);
        }
    }

    // Get the current tab
    MainViewController::Tab MainViewController::GetCurrentTab() const {
        return m_currentTab;
    }

    // Set visual style
    void MainViewController::SetVisualStyle(VisualStyle style) {
        if (style == m_visualStyle) return;
        
        m_visualStyle = style;
        ApplyVisualStyle(style);
    }

    // Get current visual style
    MainViewController::VisualStyle MainViewController::GetVisualStyle() const {
        return m_visualStyle;
    }

    // Set navigation mode
    void MainViewController::SetNavigationMode(NavigationMode mode) {
        if (mode == m_navigationMode) return;
        
        m_navigationMode = mode;
        UpdateNavigationMode(mode);
    }

    // Get current navigation mode
    MainViewController::NavigationMode MainViewController::GetNavigationMode() const {
        return m_navigationMode;
    }

    // Execute a script
    ScriptEditorViewController::ExecutionResult MainViewController::ExecuteScript(const std::string& script) {
        ScriptEditorViewController::ExecutionResult result;
        
        if (m_editorViewController) {
            // Create script object
            ScriptEditorViewController::Script scriptObj;
            scriptObj.m_content = script;
            m_editorViewController->SetScript(scriptObj);
            
            // Execute script
            result = m_editorViewController->ExecuteScript();
            
            // Call execution callback
            if (m_executionCallback) {
                m_executionCallback(result);
            }
            
            // Show notification
            if (result.m_success) {
                ShowNotification(Notification("Script executed", "Script executed successfully", false));
            } else {
                ShowNotification(Notification("Execution failed", result.m_error, true));
            }
        }
        
        return result;
    }

    // Debug a script
    std::vector<ScriptEditorViewController::DebugInfo> MainViewController::DebugScript(const std::string& script) {
        std::vector<ScriptEditorViewController::DebugInfo> debugInfo;
        
        if (m_editorViewController) {
            // Create script object
            ScriptEditorViewController::Script scriptObj;
            scriptObj.m_content = script;
            m_editorViewController->SetScript(scriptObj);
            
            // Debug script
            debugInfo = m_editorViewController->DebugCurrentScript();
        }
        
        return debugInfo;
    }

    // Set the tab changed callback
    void MainViewController::SetTabChangedCallback(const TabChangedCallback& callback) {
        if (callback) {
            m_tabChangedCallback = callback;
        }
    }

    // Set the visibility changed callback
    void MainViewController::SetVisibilityChangedCallback(const VisibilityChangedCallback& callback) {
        if (callback) {
            m_visibilityChangedCallback = callback;
        }
    }

    // Set the execution callback
    void MainViewController::SetExecutionCallback(const ExecutionCallback& callback) {
        if (callback) {
            m_executionCallback = callback;
        }
    }

    // Set the game detector
    void MainViewController::SetGameDetector(std::shared_ptr<GameDetector> gameDetector) {
        m_gameDetector = gameDetector;
        
        if (m_viewController && m_gameDetector) {
            SetupGameDetection();
        }
    }

    // Set the script assistant
    void MainViewController::SetScriptAssistant(std::shared_ptr<AIFeatures::ScriptAssistant> scriptAssistant) {
        m_scriptAssistant = scriptAssistant;
        
        if (m_editorViewController && m_scriptAssistant) {
            m_editorViewController->SetScriptAssistant(m_scriptAssistant);
        }
    }

    // Get the editor view controller
    std::shared_ptr<ScriptEditorViewController> MainViewController::GetEditorViewController() const {
        return m_editorViewController;
    }

    // Get the scripts view controller
    std::shared_ptr<ScriptManagementViewController> MainViewController::GetScriptsViewController() const {
        return m_scriptsViewController;
    }

    // Enable or disable haptic feedback
    void MainViewController::SetUseHapticFeedback(bool enable) {
        m_useHapticFeedback = enable;
    }

    // Check if haptic feedback is enabled
    bool MainViewController::GetUseHapticFeedback() const {
        return m_useHapticFeedback;
    }

    // Enable or disable animations
    void MainViewController::SetUseAnimations(bool enable) {
        m_useAnimations = enable;
    }

    // Check if animations are enabled
    bool MainViewController::GetUseAnimations() const {
        return m_useAnimations;
    }

    // Enable or disable reduced memory mode
    void MainViewController::SetReducedMemoryMode(bool enable) {
        m_reducedMemoryMode = enable;
        
        if (enable) {
            OptimizeUIForCurrentMemoryUsage();
        }
    }

    // Check if reduced memory mode is enabled
    bool MainViewController::GetReducedMemoryMode() const {
        return m_reducedMemoryMode;
    }

    // Set color scheme
    void MainViewController::SetColorScheme(int scheme) {
        if (scheme < 0 || scheme > 5) scheme = 1; // Default to scheme 1 if out of range
        
        if (scheme != m_colorScheme) {
            m_colorScheme = scheme;
            UpdateColorScheme(scheme);
        }
    }

    // Get current color scheme
    int MainViewController::GetColorScheme() const {
        return m_colorScheme;
    }

    // Reset UI settings to defaults
    void MainViewController::ResetSettings() {
        m_useHapticFeedback = true;
        m_useAnimations = true;
        m_reduceTransparency = false;
        m_reducedMemoryMode = false;
        m_colorScheme = 1;
        m_visualStyle = VisualStyle::Dynamic;
        m_navigationMode = NavigationMode::Tabs;
        
        // Apply settings
        UpdateColorScheme(m_colorScheme);
        ApplyVisualStyle(m_visualStyle);
        UpdateNavigationMode(m_navigationMode);
        
        // Reset editor settings
        if (m_editorViewController) {
            m_editorViewController->ResetSettings();
        }
        
        // Show notification
        ShowNotification(Notification("Settings Reset", "All settings have been reset to defaults", false));
    }

    // Get memory usage
    uint64_t MainViewController::GetMemoryUsage() const {
        uint64_t totalMemory = 0;
        
        // Add editor memory usage
        if (m_editorViewController) {
            totalMemory += m_editorViewController->GetMemoryUsage();
        }
        
        // Add LED effects memory usage (estimated)
        totalMemory += m_ledEffects.size() * 1024;
        
        // Add tab view controllers memory usage (estimated)
        totalMemory += m_tabViewControllers.size() * 2048;
        
        // Add notifications memory usage (estimated)
        totalMemory += m_notifications.size() * 256;
        
        return totalMemory;
    }

    // Get UI element by identifier
    void* MainViewController::GetUIElement(const std::string& identifier) const {
        // Check LED effects
        if (m_ledEffects.find(identifier) != m_ledEffects.end()) {
            return m_ledEffects.at(identifier);
        }
        
        // Check tab view controllers
        for (const auto& pair : m_tabViewControllers) {
            if (std::to_string(static_cast<int>(pair.first)) == identifier) {
                return pair.second;
            }
        }
        
        // Special identifiers
        if (identifier == "main_view_controller") return m_viewController;
        if (identifier == "floating_button") return m_floatingButton;
        if (identifier == "notification_view") return m_notificationView;
        if (identifier == "blur_effect_view") return m_blurEffectView;
        
        return nullptr;
    }

    // Register custom view
    void MainViewController::RegisterCustomView(const std::string& identifier, void* view) {
        if (!view) return;
        
        // Create a retained reference
        CFRetain(view);
        
        // Check if we already have a view with this identifier
        auto it = m_tabViewControllers.find(identifier);
        if (it != m_tabViewControllers.end()) {
            // Release the old view
            CFRelease(it->second);
        }
        
        // Store the view
        m_tabViewControllers[identifier] = view;
    }

    // Private methods

    void MainViewController::InitializeUI() {
        // Create main view controller
        UIViewController* viewController = [[UIViewController alloc] init];
        viewController.view.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:0.8];
        
        // Create blur effect for background
        UIBlurEffect* blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        UIVisualEffectView* blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        blurView.frame = viewController.view.bounds;
        blurView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [viewController.view addSubview:blurView];
        
        // Store references
        m_viewController = (__bridge_retained void*)viewController;
        m_blurEffectView = (__bridge_retained void*)blurView;
    }

    void MainViewController::SetupFloatingButton() {
        if (!m_viewController) return;
        
        UIViewController* viewController = (__bridge UIViewController*)m_viewController;
        
        // Create floating button
        UIButton* floatingButton = [UIButton buttonWithType:UIButtonTypeCustom];
        floatingButton.frame = CGRectMake(viewController.view.bounds.size.width - 70, 
                                        viewController.view.bounds.size.height - 120, 50, 50);
        floatingButton.backgroundColor = [UIColor colorWithRed:0.2 green:0.6 blue:1.0 alpha:0.8];
        floatingButton.layer.cornerRadius = 25.0;
        floatingButton.clipsToBounds = YES;
        
        // Add button icon
        [floatingButton setTitle:@"≡" forState:UIControlStateNormal];
        floatingButton.titleLabel.font = [UIFont systemFontOfSize:24.0];
        
        // Add shadow
        floatingButton.layer.shadowColor = [UIColor colorWithRed:0.2 green:0.6 blue:1.0 alpha:1.0].CGColor;
        floatingButton.layer.shadowOffset = CGSizeMake(0, 3);
        floatingButton.layer.shadowOpacity = 0.8;
        floatingButton.layer.shadowRadius = 8.0;
        
        // Add to view
        [viewController.view addSubview:floatingButton];
        
        // Add tap action
        [floatingButton addTarget:nil action:@selector(handleFloatingButtonTap:) forControlEvents:UIControlEventTouchUpInside];
        
        // Implement tap handler
        ^{
            SEL tapSelector = @selector(handleFloatingButtonTap:);
            IMP tapImp = imp_implementationWithBlock(^(id self, UIButton* sender) {
                // Find our view controller
                UIViewController* rootVC = nil;
                for (UIWindow* window in [UIApplication sharedApplication].windows) {
                    if (window.isKeyWindow) {
                        rootVC = window.rootViewController;
                        break;
                    }
                }
                
                // Find the MainViewController instance
                MainViewController* controller = (__bridge MainViewController*)objc_getAssociatedObject(rootVC, "MainViewControllerInstance");
                if (controller) {
                    controller->Toggle();
                    
                    // Provide haptic feedback if enabled
                    if (controller->GetUseHapticFeedback()) {
                        UIImpactFeedbackGenerator* generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
                        [generator prepare];
                        [generator impactOccurred];
                    }
                }
            });
            class_addMethod([floatingButton class], tapSelector, tapImp, "v@:@");
        }();
        
        // Store reference
        m_floatingButton = (__bridge_retained void*)floatingButton;
        
        // Set initial visibility
        floatingButton.hidden = !m_isFloatingButtonVisible;
    }

    void MainViewController::SetupTabBar() {
        if (!m_viewController) return;
        
        UIViewController* viewController = (__bridge UIViewController*)m_viewController;
        
        // Create tab bar
        UITabBar* tabBar = [[UITabBar alloc] initWithFrame:CGRectMake(0, viewController.view.bounds.size.height - 49, 
                                                                  viewController.view.bounds.size.width, 49)];
        tabBar.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.7];
        
        // Create tab items
        UITabBarItem* editorItem = [[UITabBarItem alloc] initWithTitle:@"Editor" image:nil tag:0];
        UITabBarItem* scriptsItem = [[UITabBarItem alloc] initWithTitle:@"Scripts" image:nil tag:1];
        UITabBarItem* consoleItem = [[UITabBarItem alloc] initWithTitle:@"Console" image:nil tag:2];
        UITabBarItem* settingsItem = [[UITabBarItem alloc] initWithTitle:@"Settings" image:nil tag:3];
        UITabBarItem* assistantItem = [[UITabBarItem alloc] initWithTitle:@"AI" image:nil tag:4];
        
        // Add items to tab bar
        tabBar.items = @[editorItem, scriptsItem, consoleItem, settingsItem, assistantItem];
        
        // Select current tab
        tabBar.selectedItem = tabBar.items[(int)m_currentTab];
        
        // Add tab bar to view
        [viewController.view addSubview:tabBar];
        
        // Store reference
        m_tabBar = (__bridge_retained void*)tabBar;
    }

    void MainViewController::SetupGameDetection() {
        if (!m_gameDetector) return;
        
        // Start the game detector
        if (!m_gameDetector->IsInGame()) {
            m_gameDetector->Start();
        }
        
        // Register callback for game state changes
        m_gameDetector->RegisterCallback([this](GameDetector::GameState oldState, GameDetector::GameState newState) {
            HandleGameStateChanged(oldState, newState);
        });
    }

    void MainViewController::ShowNotification(const Notification& notification) {
        // Store notification in history
        m_notifications.push_back(notification);
        
        // If we have too many notifications, remove oldest ones
        if (m_notifications.size() > 10) {
            m_notifications.erase(m_notifications.begin(), m_notifications.begin() + (m_notifications.size() - 10));
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!m_notificationView) {
                // Create notification view if it doesn't exist
                UIViewController* viewController = (__bridge UIViewController*)m_viewController;
                if (!viewController) return;
                
                UIView* notificationView = [[UIView alloc] initWithFrame:CGRectMake(20, 40, 
                                                                          viewController.view.bounds.size.width - 40, 60)];
                notificationView.backgroundColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:0.8];
                notificationView.layer.cornerRadius = 10;
                notificationView.clipsToBounds = YES;
                notificationView.alpha = 0.0;
                
                UILabel* titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 10, notificationView.bounds.size.width - 30, 20)];
                titleLabel.font = [UIFont boldSystemFontOfSize:16];
                titleLabel.textColor = [UIColor whiteColor];
                titleLabel.tag = 101;
                [notificationView addSubview:titleLabel];
                
                UILabel* messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 35, notificationView.bounds.size.width - 30, 20)];
                messageLabel.font = [UIFont systemFontOfSize:14];
                messageLabel.textColor = [UIColor lightGrayColor];
                messageLabel.tag = 102;
                [notificationView addSubview:messageLabel];
                
                [viewController.view addSubview:notificationView];
                
                m_notificationView = (__bridge_retained void*)notificationView;
            }
            
            // Update notification content
            UIView* notificationView = (__bridge UIView*)m_notificationView;
            UILabel* titleLabel = [notificationView viewWithTag:101];
            UILabel* messageLabel = [notificationView viewWithTag:102];
            
            titleLabel.text = [NSString stringWithUTF8String:notification.m_title.c_str()];
            messageLabel.text = [NSString stringWithUTF8String:notification.m_message.c_str()];
            
            // Use appropriate color for error/success
            if (notification.m_isError) {
                notificationView.backgroundColor = [UIColor colorWithRed:0.8 green:0.2 blue:0.2 alpha:0.8];
            } else {
                notificationView.backgroundColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:0.8];
            }
            
            // Show the notification with animation
            [UIView animateWithDuration:0.3 animations:^{
                notificationView.alpha = 1.0;
            } completion:^(BOOL finished) {
                // Auto-hide after delay
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [UIView animateWithDuration:0.3 animations:^{
                        notificationView.alpha = 0.0;
                    }];
                });
            }];
        });
    }

    void MainViewController::SwitchToTab(Tab tab, bool animated) {
        // Handle tab switch (placeholder implementation)
        m_currentTab = tab;
    }

    void MainViewController::HandleGameStateChanged(GameDetector::GameState oldState, GameDetector::GameState newState) {
        // Update game state
        m_isInGame = (newState == GameDetector::GameState::InGame);
        
        // Show/hide UI based on game state
        if (newState == GameDetector::GameState::InGame) {
            // We're in a game, show the floating button
            ShowFloatingButton();
            
            // Show notification
            ShowNotification(Notification("Game Detected", "Executor is ready", false));
        } else {
            // We're not in a game, hide the UI if visible
            if (m_isVisible) {
                Hide();
            }
            
            // Hide the floating button if we're not at the menu
            if (newState != GameDetector::GameState::Menu) {
                HideFloatingButton();
            }
        }
    }

    void MainViewController::ApplyVisualStyle(VisualStyle style) {
        // Apply visual style (placeholder implementation)
        m_visualStyle = style;
    }

    void MainViewController::UpdateNavigationMode(NavigationMode mode) {
        // Update navigation mode (placeholder implementation)
        m_navigationMode = mode;
    }

    void MainViewController::OptimizeUIForCurrentMemoryUsage() {
        // Optimize UI for current memory usage (placeholder implementation)
    }

    void MainViewController::UpdateColorScheme(int scheme) {
        // Update color scheme (placeholder implementation)
        m_colorScheme = scheme;
    }

    void MainViewController::StoreUIState() {
        // Store UI state to user defaults (placeholder implementation)
    }

    void MainViewController::RestoreUIState() {
        // Restore UI state from user defaults (placeholder implementation)
    }

    void MainViewController::RegisterForNotifications() {
        // Register for notifications (placeholder implementation)
    }

    void MainViewController::UnregisterFromNotifications() {
        // Unregister from notifications (placeholder implementation)
    }

} // namespace UI
} // namespace iOS
