//
//  ViewController.swift
//  NeuroGait
//
//  Navigation controller that launches your original GaitAnalysisViewController
//

import UIKit
import ARKit
import RealityKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBlue
        setupUI()
        checkARKitSupport()
    }
    
    private func setupUI() {
        // Title Label
        let titleLabel = UILabel()
        titleLabel.text = "NeuroGait"
        titleLabel.textAlignment = .center
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 32, weight: .light)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Subtitle Label
        let subtitleLabel = UILabel()
        subtitleLabel.text = "Clinical Gait Analysis"
        subtitleLabel.textAlignment = .center
        subtitleLabel.textColor = .white
        subtitleLabel.font = .systemFont(ofSize: 18, weight: .regular)
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Status Label
        let statusLabel = UILabel()
        statusLabel.text = "Checking device compatibility..."
        statusLabel.textAlignment = .center
        statusLabel.textColor = .white
        statusLabel.font = .systemFont(ofSize: 16)
        statusLabel.numberOfLines = 0
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Start Button
        let startButton = UIButton(type: .system)
        startButton.setTitle("Start Gait Analysis", for: .normal)
        startButton.titleLabel?.font = .boldSystemFont(ofSize: 18)
        startButton.setTitleColor(.systemBlue, for: .normal)
        startButton.backgroundColor = .white
        startButton.layer.cornerRadius = 10
        startButton.translatesAutoresizingMaskIntoConstraints = false
        startButton.addTarget(self, action: #selector(startButtonTapped), for: .touchUpInside)
        
        // Add all views
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(statusLabel)
        view.addSubview(startButton)
        
        // Store statusLabel and startButton as properties for updates
        self.statusLabel = statusLabel
        self.startButton = startButton
        
        // Layout constraints
        NSLayoutConstraint.activate([
            // Title
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 100),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Subtitle
            subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Status
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            // Start Button
            startButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            startButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -100),
            startButton.widthAnchor.constraint(equalToConstant: 200),
            startButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    // Store references for updates
    private var statusLabel: UILabel!
    private var startButton: UIButton!
    
    private func checkARKitSupport() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if ARBodyTrackingConfiguration.isSupported {
                self.statusLabel.text = "✅ Device supports ARKit body tracking\n\nYou can proceed with gait analysis."
                self.statusLabel.textColor = .white
                self.startButton.isEnabled = true
                self.startButton.alpha = 1.0
                print("✅ ARKit Body Tracking is supported on this device")
            } else {
                self.statusLabel.text = "❌ This device does not support ARKit body tracking.\n\nYou need an iPhone XS or newer, or iPad with A12 Bionic chip."
                self.statusLabel.textColor = .white
                self.startButton.isEnabled = false
                self.startButton.alpha = 0.5
                print("❌ ARKit Body Tracking is NOT supported on this device")
            }
        }
    }
    
    // MARK: - FIX: Updated this function to load from Storyboard
    @objc private func startButtonTapped() {
        print("🚀 Launching Gait Analysis...")
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        // Instantiate the NAVIGATION CONTROLLER by its Storyboard ID
        guard let navController = storyboard.instantiateViewController(withIdentifier: "GaitAnalysisNavigationController") as? UINavigationController else {
            fatalError("Could not instantiate GaitAnalysisNavigationController from storyboard.")
        }

        // Present the entire navigation controller
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
    }
       
}
