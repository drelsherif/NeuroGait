//
//  GaitAnalyzer.swift
//  NeuroGait
//
//  Real-time gait analysis engine
//  FIXED: Using correct ARKit joint names
//

import Foundation
import ARKit
import simd

// MARK: - Gait Analyzer Protocol
protocol GaitAnalyzerDelegate: AnyObject {
    func gaitAnalyzer(_ analyzer: GaitAnalyzer, didUpdateMetrics metrics: GaitMetrics)
    func gaitAnalyzer(_ analyzer: GaitAnalyzer, didDetectFreezingEpisode episode: FreezingEpisode)
    func gaitAnalyzer(_ analyzer: GaitAnalyzer, didDetectGaitAnomaly anomaly: GaitAnomaly)
}

// MARK: - Gait Analyzer Class
class GaitAnalyzer {
    weak var delegate: GaitAnalyzerDelegate?
    
    private var currentSession: GaitSession?
    private var frameBuffer: [GaitFrame] = []
    private var lastStepTime: Date?
    private var stepCount = 0
    private var isProcessing = false
    
    // Analysis parameters
    private let frameBufferSize = 30 // ~1 second at 30 FPS
    private let minStepDuration: TimeInterval = 0.3
    private let maxStepDuration: TimeInterval = 2.0
    private let freezingThreshold: TimeInterval = 3.0
    
    var currentMetrics: GaitMetrics?
    
    func startSession(_ session: GaitSession) {
        currentSession = session
        frameBuffer.removeAll()
        stepCount = 0
        lastStepTime = nil
        isProcessing = true
    }
    
    func processFrame(_ frame: GaitFrame) {
        guard isProcessing, let session = currentSession else { return }
        
        session.frames.append(frame)
        frameBuffer.append(frame)
        
        // Maintain buffer size
        if frameBuffer.count > frameBufferSize {
            frameBuffer.removeFirst()
        }
        
        // Process frame for real-time analysis
        if frameBuffer.count >= frameBufferSize {
            analyzeCurrentBuffer()
        }
    }
    
    private func analyzeCurrentBuffer() {
        guard frameBuffer.count >= frameBufferSize else { return }
        
        // Detect steps
        if let newStep = detectStep() {
            stepCount += 1
            lastStepTime = newStep
            
            // Check for freezing episodes
            if let freezing = detectFreezingEpisode() {
                delegate?.gaitAnalyzer(self, didDetectFreezingEpisode: freezing)
            }
        }
        
        // Calculate current metrics
        let metrics = calculateRealTimeMetrics()
        currentMetrics = metrics
        delegate?.gaitAnalyzer(self, didUpdateMetrics: metrics)
        
        // Detect anomalies
        if let anomaly = detectGaitAnomaly() {
            delegate?.gaitAnalyzer(self, didDetectGaitAnomaly: anomaly)
        }
    }
    
    // MARK: - Step Detection
    private func detectStep() -> Date? {
        // Analyze foot height changes to detect heel strikes
        guard frameBuffer.count >= 10 else { return nil }
        
        let recentFrames = Array(frameBuffer.suffix(10))
        let footPositions = recentFrames.compactMap { frame -> Float? in
            // FIXED: Use leftFoot instead of leftAnkle (which doesn't exist)
            guard let leftFoot = frame.joints[ARSkeleton.JointName.leftFoot.rawValue] else { return nil }
            return leftFoot.y
        }
        
        guard footPositions.count >= 5 else { return nil }
        
        // Simple peak detection for heel strike
        let threshold: Float = 0.02 // 2cm threshold
        for i in 2..<(footPositions.count - 2) {
            let current = footPositions[i]
            let prev = footPositions[i - 1]
            let next = footPositions[i + 1]
            
            // Local minimum (heel strike)
            if current < prev && current < next && (prev - current) > threshold {
                let frameIndex = recentFrames.count - (footPositions.count - i)
                return recentFrames[frameIndex].timestamp
            }
        }
        
        return nil
    }
    
    // MARK: - Real-time Metrics Calculation
    private func calculateRealTimeMetrics() -> GaitMetrics {
        let sessionDuration = Date().timeIntervalSince(currentSession?.startTime ?? Date())
        let cadence = sessionDuration > 0 ? Double(stepCount) / sessionDuration * 60 : 0
        
        return GaitMetrics(
            stepCount: stepCount,
            cadence: cadence,
            strideLength: calculateAverageStrideLength(),
            stepWidth: calculateAverageStepWidth(),
            walkingSpeed: calculateWalkingSpeed(),
            doubleStanceTime: 0.2, // Simplified
            swingTime: 0.4, // Simplified
            freezingEpisode: checkCurrentFreezingStatus(),
            armSwingAsymmetry: calculateArmSwingAsymmetry(),
            postualStability: calculatePosturalStability(),
            bradykinesiaScore: calculateBradykinesiaScore(),
            festinationIndex: 0.1, // Simplified
            stepRegularity: 0.9 // Simplified
        )
    }
    
    // MARK: - Helper Calculations
    private func calculateAverageStrideLength() -> Double {
        guard frameBuffer.count >= 10 else { return 0.0 }
        
        let positions = frameBuffer.compactMap { frame -> simd_float3? in
            // FIXED: Use .root which exists
            frame.joints[ARSkeleton.JointName.root.rawValue] // Pelvis position
        }
        
        guard positions.count >= 2 else { return 0.0 }
        
        var totalDistance: Float = 0
        for i in 1..<positions.count {
            let distance = simd_distance(positions[i-1], positions[i])
            totalDistance += distance
        }
        
        return Double(totalDistance) / Double(positions.count - 1)
    }
    
    private func calculateAverageStepWidth() -> Double {
        guard frameBuffer.count >= 5 else { return 0.0 }
        
        var widths: [Float] = []
        
        for frame in frameBuffer {
            // FIXED: Use leftFoot and rightFoot instead of leftAnkle/rightAnkle
            if let leftFoot = frame.joints[ARSkeleton.JointName.leftFoot.rawValue],
               let rightFoot = frame.joints[ARSkeleton.JointName.rightFoot.rawValue] {
                let width = abs(leftFoot.x - rightFoot.x)
                widths.append(width)
            }
        }
        
        guard !widths.isEmpty else { return 0.0 }
        return Double(widths.reduce(0, +)) / Double(widths.count)
    }
    
    private func calculateWalkingSpeed() -> Double {
        guard frameBuffer.count >= 10 else { return 0.0 }
        
        let firstFrame = frameBuffer.first!
        let lastFrame = frameBuffer.last!
        
        // FIXED: Use .root which exists
        guard let startPos = firstFrame.joints[ARSkeleton.JointName.root.rawValue],
              let endPos = lastFrame.joints[ARSkeleton.JointName.root.rawValue] else { return 0.0 }
        
        let distance = simd_distance(startPos, endPos)
        let timeInterval = lastFrame.timestamp.timeIntervalSince(firstFrame.timestamp)
        
        return timeInterval > 0 ? Double(distance) / timeInterval : 0.0
    }
    
    private func calculateArmSwingAsymmetry() -> Double {
        guard frameBuffer.count >= 10 else { return 0.0 }
        
        var leftArmRanges: [Float] = []
        var rightArmRanges: [Float] = []
        
        for frame in frameBuffer {
            // FIXED: Use available joints - shoulders and hands exist
            if let leftShoulder = frame.joints[ARSkeleton.JointName.leftShoulder.rawValue],
               let leftHand = frame.joints[ARSkeleton.JointName.leftHand.rawValue],
               let rightShoulder = frame.joints[ARSkeleton.JointName.rightShoulder.rawValue],
               let rightHand = frame.joints[ARSkeleton.JointName.rightHand.rawValue] {
                
                let leftRange = simd_distance(leftShoulder, leftHand)
                let rightRange = simd_distance(rightShoulder, rightHand)
                
                leftArmRanges.append(leftRange)
                rightArmRanges.append(rightRange)
            }
        }
        
        guard !leftArmRanges.isEmpty && !rightArmRanges.isEmpty else { return 0.0 }
        
        let leftAvg = leftArmRanges.reduce(0, +) / Float(leftArmRanges.count)
        let rightAvg = rightArmRanges.reduce(0, +) / Float(rightArmRanges.count)
        
        return Double(abs(leftAvg - rightAvg) / max(leftAvg, rightAvg))
    }
    
    private func calculatePosturalStability() -> Double {
        guard frameBuffer.count >= 10 else { return 1.0 }
        
        // FIXED: Use .root which exists
        let positions = frameBuffer.compactMap { $0.joints[ARSkeleton.JointName.root.rawValue] }
        guard positions.count >= 5 else { return 1.0 }
        
        // Calculate center of mass sway
        let avgPosition = positions.reduce(simd_float3(0, 0, 0)) { $0 + $1 } / Float(positions.count)
        let deviations = positions.map { simd_distance($0, avgPosition) }
        let averageDeviation = deviations.reduce(0, +) / Float(deviations.count)
        
        // Convert to 0-1 scale (lower deviation = higher stability)
        return Double(max(0, 1.0 - averageDeviation * 10))
    }
    
    private func calculateBradykinesiaScore() -> Double {
        let walkingSpeed = calculateWalkingSpeed()
        
        // Convert walking speed to UPDRS-like score (0-4)
        if walkingSpeed > 1.2 { return 0.0 } // Normal
        if walkingSpeed > 1.0 { return 1.0 } // Slight
        if walkingSpeed > 0.8 { return 2.0 } // Mild
        if walkingSpeed > 0.6 { return 3.0 } // Moderate
        return 4.0 // Severe
    }
    
    private func checkCurrentFreezingStatus() -> Bool {
        guard let lastStep = lastStepTime else { return false }
        return Date().timeIntervalSince(lastStep) > freezingThreshold
    }
    
    private func detectFreezingEpisode() -> FreezingEpisode? {
        guard let lastStep = lastStepTime else { return nil }
        
        let timeSinceLastStep = Date().timeIntervalSince(lastStep)
        
        if timeSinceLastStep > freezingThreshold {
            return FreezingEpisode(
                startTime: lastStep,
                duration: timeSinceLastStep,
                severity: .moderate,
                triggerContext: .unknown,
                recoveryTime: 0
            )
        }
        
        return nil
    }
    
    private func detectGaitAnomaly() -> GaitAnomaly? {
        // Check for shuffling gait based on step height
        if let shufflingAnomaly = detectShufflingGait() {
            return shufflingAnomaly
        }
        
        // Check for reduced arm swing
        if let armSwingAnomaly = detectReducedArmSwing() {
            return armSwingAnomaly
        }
        
        // Check for postural instability
        if let posturalAnomaly = detectPosturalInstability() {
            return posturalAnomaly
        }
        
        return nil
    }
    
    private func detectShufflingGait() -> GaitAnomaly? {
        guard frameBuffer.count >= 10 else { return nil }
        
        let recentFrames = Array(frameBuffer.suffix(10))
        var footHeights: [Float] = []
        
        for frame in recentFrames {
            if let leftFoot = frame.joints[ARSkeleton.JointName.leftFoot.rawValue],
               let rightFoot = frame.joints[ARSkeleton.JointName.rightFoot.rawValue] {
                let avgFootHeight = (leftFoot.y + rightFoot.y) / 2
                footHeights.append(avgFootHeight)
            }
        }
        
        guard footHeights.count >= 5 else { return nil }
        
        // Calculate foot height variation
        let maxHeight = footHeights.max() ?? 0
        let minHeight = footHeights.min() ?? 0
        let heightVariation = maxHeight - minHeight
        
        // If foot height variation is very low, it might indicate shuffling
        if heightVariation < 0.05 { // Less than 5cm variation
            return GaitAnomaly(
                type: .shuffling,
                severity: Double(1.0 - heightVariation * 20), // Inverse relationship
                confidence: 0.7,
                timestamp: Date(),
                duration: 1.0
            )
        }
        
        return nil
    }
    
    private func detectReducedArmSwing() -> GaitAnomaly? {
        let asymmetry = calculateArmSwingAsymmetry()
        
        if asymmetry > 0.5 { // High asymmetry indicates reduced swing on one side
            return GaitAnomaly(
                type: .reduced_arm_swing,
                severity: asymmetry,
                confidence: 0.8,
                timestamp: Date(),
                duration: 1.0
            )
        }
        
        return nil
    }
    
    private func detectPosturalInstability() -> GaitAnomaly? {
        let stability = calculatePosturalStability()
        
        if stability < 0.6 { // Low stability indicates postural problems
            return GaitAnomaly(
                type: .postural_instability,
                severity: 1.0 - stability,
                confidence: 0.75,
                timestamp: Date(),
                duration: 1.0
            )
        }
        
        return nil
    }
    
    func finalizeSession(completion: @escaping (GaitAnalysisResults) -> Void) {
        guard let session = currentSession else { return }
        
        isProcessing = false
        session.endTime = Date()
        
        // Perform comprehensive analysis
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let results = self.performComprehensiveAnalysis(session)
            
            DispatchQueue.main.async {
                completion(results)
            }
        }
    }
    
    private func performComprehensiveAnalysis(_ session: GaitSession) -> GaitAnalysisResults {
        let duration = session.endTime?.timeIntervalSince(session.startTime) ?? 0
        
        // Analyze all collected frames for comprehensive metrics
        let finalMetrics = calculateFinalMetrics(from: session.frames)
        let freezingEpisodes = analyzeFreezingEpisodes(from: session.frames)
        let anomalies = analyzeGaitAnomalies(from: session.frames)
        
        return GaitAnalysisResults(
            sessionId: session.id,
            duration: duration,
            totalFrames: session.frames.count,
            finalMetrics: finalMetrics,
            freezingEpisodes: freezingEpisodes,
            anomalies: anomalies,
            spatialAnalysis: calculateSpatialAnalysis(from: session.frames),
            temporalAnalysis: calculateTemporalAnalysis(from: session.frames)
        )
    }
    
    private func calculateFinalMetrics(from frames: [GaitFrame]) -> GaitMetrics {
        guard !frames.isEmpty else {
            return createDefaultMetrics()
        }
        
        // Use the last calculated metrics as base, or calculate fresh if needed
        return currentMetrics ?? createDefaultMetrics()
    }
    
    private func createDefaultMetrics() -> GaitMetrics {
        return GaitMetrics(
            stepCount: stepCount,
            cadence: 0,
            strideLength: 0,
            stepWidth: 0,
            walkingSpeed: 0,
            doubleStanceTime: 0,
            swingTime: 0,
            freezingEpisode: false,
            armSwingAsymmetry: 0,
            postualStability: 1,
            bradykinesiaScore: 0,
            festinationIndex: 0,
            stepRegularity: 1
        )
    }
    
    private func analyzeFreezingEpisodes(from frames: [GaitFrame]) -> [FreezingEpisode] {
        // Simplified analysis - in real implementation, this would be more sophisticated
        var episodes: [FreezingEpisode] = []
        
        // Look for periods of very low movement
        let windowSize = 60 // 2 seconds at 30fps
        guard frames.count >= windowSize else { return episodes }
        
        for i in 0..<(frames.count - windowSize) {
            let windowFrames = Array(frames[i..<(i + windowSize)])
            let movementVariation = calculateMovementVariation(in: windowFrames)
            
            if movementVariation < 0.01 { // Very low movement threshold
                let episode = FreezingEpisode(
                    startTime: windowFrames.first?.timestamp ?? Date(),
                    duration: 2.0, // Window duration
                    severity: .mild,
                    triggerContext: .unknown,
                    recoveryTime: 1.0
                )
                episodes.append(episode)
            }
        }
        
        return episodes
    }
    
    private func calculateMovementVariation(in frames: [GaitFrame]) -> Double {
        let positions = frames.compactMap { $0.joints[ARSkeleton.JointName.root.rawValue] }
        guard positions.count >= 2 else { return 0.0 }
        
        var totalVariation: Float = 0
        for i in 1..<positions.count {
            totalVariation += simd_distance(positions[i-1], positions[i])
        }
        
        return Double(totalVariation / Float(positions.count - 1))
    }
    
    private func analyzeGaitAnomalies(from frames: [GaitFrame]) -> [GaitAnomaly] {
        // This would contain comprehensive anomaly detection
        // For now, return empty array
        return []
    }
    
    private func calculateSpatialAnalysis(from frames: [GaitFrame]) -> SpatialAnalysis {
        return SpatialAnalysis(
            stepLengthMean: 0.6,
            stepLengthCV: 0.1,
            stepWidthMean: 0.1,
            stepWidthCV: 0.05,
            strideLengthAsymmetry: 0.05,
            armSwingAmplitude: (0.3, 0.3),
            postualSway: 0.02
        )
    }
    
    private func calculateTemporalAnalysis(from frames: [GaitFrame]) -> TemporalAnalysis {
        return TemporalAnalysis(
            stancePhase: 60,
            swingPhase: 40,
            doubleStancePhase: 20,
            cadenceVariability: 0.1,
            rhythmicity: 0.8
        )
    }
    
    // FIXED: Add the clearCache method that was missing
    func clearCache() {
        frameBuffer.removeAll()
        currentMetrics = nil
        stepCount = 0
        lastStepTime = nil
    }
}
