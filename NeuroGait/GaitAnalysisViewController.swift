//
//  GaitAnalysisViewController.swift
//  NeuroGait - Clinical Gait Analysis iOS App
//  Core ARKit + LiDAR + RealityKit Implementation
//  FIXED: Using correct ARSkeleton.JointName constants
//

import UIKit
import ARKit
import RealityKit
import SceneKit
import simd
import CoreData
import SwiftUI

// MARK: - Main AR View Controller (Storyboard-based)
class GaitAnalysisViewController: UIViewController {
    
    // MARK: - IBOutlets from Storyboard
    @IBOutlet weak var arView: ARView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var recordingButton: UIButton!
    @IBOutlet weak var metricsView: UIView!
    @IBOutlet weak var stepCountLabel: UILabel!
    @IBOutlet weak var cadenceLabel: UILabel!
    @IBOutlet weak var freezingIndicator: UIView!
    
    // MARK: - Core Components
    private let gaitAnalyzer = GaitAnalyzer()
    private let lidarProcessor = LiDARProcessor()
    private let clinicalScorer = ClinicalScorer()
    private let dataManager = GaitDataManager()
    
    // MARK: - State Management
    private var isRecording = false
    private var currentSession: GaitSession?
    private var bodyAnchor: ARBodyAnchor?
    
    // MARK: - 3D Visualization
    private var skeletonEntity: Entity?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupARView()
        setupUI()
        setupDelegates()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startARSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        arView.session.pause()
    }
}

// MARK: - AR Setup and Configuration
extension GaitAnalysisViewController {
    
    private func setupARView() {
        arView.automaticallyConfigureSession = false
        arView.debugOptions = [.showFeaturePoints, .showWorldOrigin]
        
        let anchor = AnchorEntity()
        let lightComponent = DirectionalLightComponent(color: .white, intensity: 2000)
        anchor.components.set(lightComponent)
        arView.scene.addAnchor(anchor)
    }
    
    private func startARSession() {
        guard ARBodyTrackingConfiguration.isSupported else {
            DispatchQueue.main.async {
                self.showAlert(title: "Device Not Supported", message: "This device does not support body tracking.")
            }
            return
        }
        
        let configuration = ARBodyTrackingConfiguration()
        // FIXED: Removed invalid sceneReconstruction property
        configuration.automaticSkeletonScaleEstimationEnabled = true
        
        arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    private func setupDelegates() {
        arView.session.delegate = self
        gaitAnalyzer.delegate = self
    }
}

// MARK: - ARSession Delegate
extension GaitAnalysisViewController: ARSessionDelegate {
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            if let bodyAnchor = anchor as? ARBodyAnchor {
                self.bodyAnchor = bodyAnchor
                processBodyTracking(bodyAnchor)
            }
            if let meshAnchor = anchor as? ARMeshAnchor {
                processMeshData(meshAnchor)
            }
        }
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        for anchor in anchors {
            if let bodyAnchor = anchor as? ARBodyAnchor {
                self.bodyAnchor = bodyAnchor
                processBodyTracking(bodyAnchor)
            }
            if let meshAnchor = anchor as? ARMeshAnchor {
                processMeshData(meshAnchor)
            }
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.showAlert(title: "AR Session Error", message: error.localizedDescription)
        }
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        DispatchQueue.main.async {
            self.statusLabel?.text = "Session interrupted"
            self.statusLabel?.textColor = .systemOrange
        }
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        DispatchQueue.main.async {
            self.statusLabel?.text = "Session resumed"
            self.statusLabel?.textColor = .systemGreen
        }
    }
    
    private func processBodyTracking(_ bodyAnchor: ARBodyAnchor) {
        let skeleton = bodyAnchor.skeleton
        let timestamp = Date()
        
        let jointPositions = extractJointPositions(from: skeleton)
        
        let gaitFrame = GaitFrame(
            timestamp: timestamp,
            joints: jointPositions,
            transform: bodyAnchor.transform
        )
        
        if isRecording {
            gaitAnalyzer.processFrame(gaitFrame)
        }
        
        updateSkeletonVisualization(skeleton, transform: bodyAnchor.transform)
    }
    
    private func processMeshData(_ meshAnchor: ARMeshAnchor) {
        lidarProcessor.processMeshAnchor(meshAnchor) { [weak self] environmentData in
            DispatchQueue.main.async {
                self?.updateEnvironmentVisualization(environmentData)
            }
        }
    }
}

// MARK: - Joint Position Extraction
extension GaitAnalysisViewController {
    
    private func extractJointPositions(from skeleton: ARSkeleton3D) -> [String: simd_float3] {
        var joints: [String: simd_float3] = [:]
        
        // FIXED: Use only the available ARSkeleton.JointName constants
        let availableJoints: [ARSkeleton.JointName] = [
            .head,
            .leftShoulder,
            .rightShoulder,
            .leftHand,
            .rightHand,
            .root,
            .leftFoot,
            .rightFoot
        ]
        
        // Extract positions for available joints
        for jointName in availableJoints {
            if let transform = skeleton.modelTransform(for: jointName) {
                let position = simd_float3(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
                joints[jointName.rawValue] = position
            }
        }
        
        // FIXED: Access additional joints using raw values from the skeleton definition
        let additionalJointNames = [
            "neck_1_joint",
            "left_arm_joint", "right_arm_joint",
            "left_forearm_joint", "right_forearm_joint",
            "left_upLeg_joint", "right_upLeg_joint",
            "left_leg_joint", "right_leg_joint",
            "left_toes_joint", "right_toes_joint",
            "spine_1_joint", "spine_2_joint", "spine_3_joint"
        ]
        
        for jointName in additionalJointNames {
            if let transform = skeleton.modelTransform(for: ARSkeleton.JointName(rawValue: jointName)) {
                let position = simd_float3(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
                joints[jointName] = position
            }
        }
        
        return joints
    }
}

// MARK: - 3D Visualization
extension GaitAnalysisViewController {
    
    private func updateSkeletonVisualization(_ skeleton: ARSkeleton3D, transform: simd_float4x4) {
        skeletonEntity?.removeFromParent()
        let newSkeletonEntity = Entity()
        
        // FIXED: Use only available joint names
        let availableJoints: [ARSkeleton.JointName] = [
            .head, .leftShoulder, .rightShoulder, .leftHand, .rightHand, .root, .leftFoot, .rightFoot
        ]
        
        for jointName in availableJoints {
            if let jointTransform = skeleton.modelTransform(for: jointName) {
                let jointEntity = createJointEntity(for: jointName)
                jointEntity.transform = Transform(matrix: jointTransform)
                newSkeletonEntity.addChild(jointEntity)
            }
        }
        
        addBoneConnections(to: newSkeletonEntity, skeleton: skeleton)
        
        let anchor = AnchorEntity()
        anchor.transform = Transform(matrix: transform)
        anchor.addChild(newSkeletonEntity)
        
        arView.scene.addAnchor(anchor)
        self.skeletonEntity = newSkeletonEntity
    }
    
    private func createJointEntity(for jointName: ARSkeleton.JointName) -> Entity {
        let entity = Entity()
        let color: UIColor = {
            switch jointName {
            case .leftFoot, .rightFoot: return .systemBlue
            case .leftHand, .rightHand: return .systemGreen
            case .root: return .systemRed
            case .leftShoulder, .rightShoulder: return .systemYellow
            case .head: return .systemPurple
            default: return .white
            }
        }()
        let mesh = MeshResource.generateSphere(radius: 0.02)
        let material = SimpleMaterial(color: color, isMetallic: false)
        entity.components.set(ModelComponent(mesh: mesh, materials: [material]))
        return entity
    }
    
    private func addBoneConnections(to entity: Entity, skeleton: ARSkeleton3D) {
        // FIXED: Use only available joint connections
        let boneConnections: [(ARSkeleton.JointName, ARSkeleton.JointName)] = [
            (.leftShoulder, .leftHand),
            (.rightShoulder, .rightHand),
            (.leftShoulder, .root),
            (.rightShoulder, .root),
            (.root, .leftFoot),
            (.root, .rightFoot)
        ]
        
        for (startJoint, endJoint) in boneConnections {
            if let startTransform = skeleton.modelTransform(for: startJoint),
               let endTransform = skeleton.modelTransform(for: endJoint) {
                let boneEntity = createBoneEntity(from: startTransform, to: endTransform)
                entity.addChild(boneEntity)
            }
        }
        
        // Add connections using raw value joint names for more detailed skeleton
        let rawBoneConnections = [
            ("neck_1_joint", "head"),
            ("left_arm_joint", "left_forearm_joint"),
            ("right_arm_joint", "right_forearm_joint"),
            ("left_forearm_joint", "left_hand_joint"),
            ("right_forearm_joint", "right_hand_joint"),
            ("left_upLeg_joint", "left_leg_joint"),
            ("right_upLeg_joint", "right_leg_joint"),
            ("left_leg_joint", "left_foot_joint"),
            ("right_leg_joint", "right_foot_joint")
        ]
        
        for (startJointName, endJointName) in rawBoneConnections {
            if let startTransform = skeleton.modelTransform(for: ARSkeleton.JointName(rawValue: startJointName)),
               let endTransform = skeleton.modelTransform(for: ARSkeleton.JointName(rawValue: endJointName)) {
                let boneEntity = createBoneEntity(from: startTransform, to: endTransform)
                entity.addChild(boneEntity)
            }
        }
    }
    
    private func createBoneEntity(from startTransform: simd_float4x4, to endTransform: simd_float4x4) -> Entity {
        let startPos = simd_float3(startTransform.columns.3.x, startTransform.columns.3.y, startTransform.columns.3.z)
        let endPos = simd_float3(endTransform.columns.3.x, endTransform.columns.3.y, endTransform.columns.3.z)
        let distance = simd_distance(startPos, endPos)
        
        let entity = Entity()
        let mesh = MeshResource.generateCylinder(height: distance, radius: 0.005)
        let material = SimpleMaterial(color: .lightGray, isMetallic: false)
        entity.components.set(ModelComponent(mesh: mesh, materials: [material]))
        
        let midPoint = (startPos + endPos) / 2
        entity.position = midPoint
        
        let direction = normalize(endPos - startPos)
        let up = simd_float3(0, 1, 0)
        let rotation = simd_quatf(from: up, to: direction)
        entity.orientation = rotation
        
        return entity
    }
}

// MARK: - UI Setup and Actions
extension GaitAnalysisViewController {
    
    private func setupUI() {
        recordingButton?.layer.cornerRadius = 25
        recordingButton?.backgroundColor = .systemBlue
        recordingButton?.setTitle("Start Recording", for: .normal)
        recordingButton?.setTitleColor(.white, for: .normal)
        recordingButton?.titleLabel?.font = .boldSystemFont(ofSize: 16)
        
        metricsView?.layer.cornerRadius = 10
        metricsView?.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        
        freezingIndicator?.layer.cornerRadius = 10
        freezingIndicator?.backgroundColor = .systemGreen
        freezingIndicator?.alpha = 0.8
        
        // Set initial text colors
        statusLabel?.textColor = .systemBlue
        stepCountLabel?.textColor = .white
        cadenceLabel?.textColor = .white
        
        updateUI()
    }
    
    @IBAction func recordingButtonTapped(_ sender: UIButton) {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        guard bodyAnchor != nil else {
            showAlert(title: "Body Not Detected", message: "Please ensure your full body is visible to the camera.")
            return
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        isRecording = true
        currentSession = GaitSession()
        gaitAnalyzer.startSession(currentSession!)
        
        recordingButton?.setTitle("Stop Recording", for: .normal)
        recordingButton?.backgroundColor = .systemRed
        statusLabel?.text = "Recording gait analysis..."
        statusLabel?.textColor = .systemRed
    }
    
    private func stopRecording() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        isRecording = false
        recordingButton?.setTitle("Start Recording", for: .normal)
        recordingButton?.backgroundColor = .systemBlue
        recordingButton?.isEnabled = false // Prevent multiple taps during processing
        
        statusLabel?.text = "Processing analysis..."
        statusLabel?.textColor = .systemOrange
        
        gaitAnalyzer.finalizeSession { [weak self] results in
            DispatchQueue.main.async {
                self?.recordingButton?.isEnabled = true
                self?.handleAnalysisResults(results)
            }
        }
    }
    
    private func updateUI() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let metrics = self.gaitAnalyzer.currentMetrics else { return }
            
            self.stepCountLabel?.text = "Steps: \(metrics.stepCount)"
            self.cadenceLabel?.text = String(format: "Cadence: %.1f steps/min", metrics.cadence)
            
            // Animate freezing indicator
            UIView.animate(withDuration: 0.3) {
                self.freezingIndicator?.backgroundColor = metrics.freezingEpisode ? .systemRed : .systemGreen
                self.freezingIndicator?.transform = metrics.freezingEpisode ? CGAffineTransform(scaleX: 1.2, y: 1.2) : .identity
            }
        }
    }
}

// MARK: - Gait Analyzer Delegate
extension GaitAnalysisViewController: GaitAnalyzerDelegate {
    func gaitAnalyzer(_ analyzer: GaitAnalyzer, didUpdateMetrics metrics: GaitMetrics) {
        updateUI()
    }
    
    func gaitAnalyzer(_ analyzer: GaitAnalyzer, didDetectFreezingEpisode episode: FreezingEpisode) {
        DispatchQueue.main.async { [weak self] in
            self?.handleFreezingEpisode(episode)
        }
    }
    
    func gaitAnalyzer(_ analyzer: GaitAnalyzer, didDetectGaitAnomaly anomaly: GaitAnomaly) {
        print("Gait anomaly detected: \(anomaly.type) - Severity: \(anomaly.severity)")
        
        // Optional: Show visual feedback for anomalies
        DispatchQueue.main.async { [weak self] in
            self?.showAnomalyAlert(anomaly)
        }
    }
}

// MARK: - Clinical Analysis Handling
extension GaitAnalysisViewController {
    
    private func handleAnalysisResults(_ results: GaitAnalysisResults) {
        let clinicalScores = clinicalScorer.calculateScores(from: results)
        
        dataManager.saveGaitSession(results, clinicalScores: clinicalScores) { [weak self] success in
            DispatchQueue.main.async {
                if success {
                    self?.statusLabel?.text = "Analysis complete"
                    self?.statusLabel?.textColor = .systemGreen
                    self?.presentResultsViewController(results, clinicalScores: clinicalScores)
                } else {
                    self?.statusLabel?.text = "Save failed"
                    self?.statusLabel?.textColor = .systemRed
                    self?.showAlert(title: "Save Error", message: "Failed to save analysis results.")
                }
            }
        }
    }
    
    private func handleFreezingEpisode(_ episode: FreezingEpisode) {
        // Visual feedback for freezing episode
        let alertView = UIView()
        alertView.backgroundColor = UIColor.systemRed.withAlphaComponent(0.8)
        alertView.layer.cornerRadius = 10
        alertView.translatesAutoresizingMaskIntoConstraints = false
        
        let alertLabel = UILabel()
        alertLabel.text = "FREEZING DETECTED"
        alertLabel.textColor = .white
        alertLabel.font = .boldSystemFont(ofSize: 16)
        alertLabel.textAlignment = .center
        alertLabel.translatesAutoresizingMaskIntoConstraints = false
        
        alertView.addSubview(alertLabel)
        view.addSubview(alertView)
        
        NSLayoutConstraint.activate([
            alertView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            alertView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            alertView.widthAnchor.constraint(equalToConstant: 200),
            alertView.heightAnchor.constraint(equalToConstant: 50),
            
            alertLabel.centerXAnchor.constraint(equalTo: alertView.centerXAnchor),
            alertLabel.centerYAnchor.constraint(equalTo: alertView.centerYAnchor)
        ])
        
        // Auto-remove after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            UIView.animate(withDuration: 0.5, animations: {
                alertView.alpha = 0
            }) { _ in
                alertView.removeFromSuperview()
            }
        }
        
        // Haptic feedback
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.warning)
    }
    
    private func showAnomalyAlert(_ anomaly: GaitAnomaly) {
        // Brief visual feedback for anomalies without disrupting the user
        let feedbackView = UIView()
        feedbackView.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.7)
        feedbackView.layer.cornerRadius = 5
        feedbackView.translatesAutoresizingMaskIntoConstraints = false
        
        let feedbackLabel = UILabel()
        feedbackLabel.text = anomaly.type.rawValue.capitalized
        feedbackLabel.textColor = .white
        feedbackLabel.font = .systemFont(ofSize: 12)
        feedbackLabel.textAlignment = .center
        feedbackLabel.translatesAutoresizingMaskIntoConstraints = false
        
        feedbackView.addSubview(feedbackLabel)
        view.addSubview(feedbackView)
        
        NSLayoutConstraint.activate([
            feedbackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            feedbackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 80),
            feedbackView.widthAnchor.constraint(equalToConstant: 120),
            feedbackView.heightAnchor.constraint(equalToConstant: 30),
            
            feedbackLabel.centerXAnchor.constraint(equalTo: feedbackView.centerXAnchor),
            feedbackLabel.centerYAnchor.constraint(equalTo: feedbackView.centerYAnchor)
        ])
        
        // Auto-remove after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            UIView.animate(withDuration: 0.3, animations: {
                feedbackView.alpha = 0
            }) { _ in
                feedbackView.removeFromSuperview()
            }
        }
    }
    
    private func presentResultsViewController(_ results: GaitAnalysisResults, clinicalScores: ClinicalScores) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let resultsVC = storyboard.instantiateViewController(withIdentifier: "ResultsViewController") as? ResultsViewController {
            resultsVC.analysisResults = results
            resultsVC.clinicalScores = clinicalScores
            // FIXED: Using push for proper navigation
            navigationController?.pushViewController(resultsVC, animated: true)
        }
    }
}

// MARK: - Utility Methods
extension GaitAnalysisViewController {
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func updateEnvironmentVisualization(_ environmentData: EnvironmentData) {
        // This function can be used to visualize LiDAR data if needed
        // For now, we focus on body tracking for gait analysis
        print("Environment updated: \(environmentData.obstacles.count) obstacles detected")
    }
}

// MARK: - Memory Management
extension GaitAnalysisViewController {
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        // Clear old skeleton entities to free memory
        skeletonEntity?.removeFromParent()
        skeletonEntity = nil
        
        // Force garbage collection of analysis data if not recording
        if !isRecording {
            gaitAnalyzer.clearCache()
        }
    }
}
