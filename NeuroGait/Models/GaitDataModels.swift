// GaitDataModels.swift

import Foundation
import simd
import ARKit
import CoreData

// NEW: A simple data structure for our charts.
struct SpeedDataPoint: Identifiable {
    let id = UUID()
    let time: Double // X-axis value (e.g., time in seconds)
    let speed: Double  // Y-axis value (e.g., walking speed)
}

struct GaitFrame {
    // ... (rest of this struct is unchanged)
    let timestamp: Date
    let joints: [String: simd_float3]
    let transform: simd_float4x4
    let frameNumber: Int
    
    init(timestamp: Date, joints: [String: simd_float3], transform: simd_float4x4, frameNumber: Int = 0) {
        self.timestamp = timestamp
        self.joints = joints
        self.transform = transform
        self.frameNumber = frameNumber
    }
}

struct GaitMetrics {
    // ... (this struct is unchanged)
    let stepCount: Int
    let cadence: Double // steps per minute
    let strideLength: Double // meters
    let stepWidth: Double // meters
    let walkingSpeed: Double // m/s
    let doubleStanceTime: Double // seconds
    let swingTime: Double // seconds
    let freezingEpisode: Bool
    let armSwingAsymmetry: Double // 0-1 scale
    let postualStability: Double // 0-1 scale
    
    // Clinical metrics
    let bradykinesiaScore: Double // 0-4 UPDRS scale
    let festinationIndex: Double // 0-1 scale
    let stepRegularity: Double // coefficient of variation
}

struct GaitAnalysisResults {
    let sessionId: UUID
    let duration: TimeInterval
    let totalFrames: Int
    let finalMetrics: GaitMetrics
    let freezingEpisodes: [FreezingEpisode]
    let anomalies: [GaitAnomaly]
    let spatialAnalysis: SpatialAnalysis
    let temporalAnalysis: TemporalAnalysis
    // NEW: Add a property to hold the data for the speed chart.
    let speedOverTime: [SpeedDataPoint]
}

// ... (The rest of the file: FreezingEpisode, GaitAnomaly, ClinicalScores, etc., remains unchanged)
struct FreezingEpisode {
    let startTime: Date
    let duration: TimeInterval
    let severity: FreezingSeverity
    let triggerContext: FreezingTrigger
    let recoveryTime: TimeInterval
}

enum FreezingSeverity: Int, CaseIterable {
    case mild = 1
    case moderate = 2
    case severe = 3
}

enum FreezingTrigger: String, CaseIterable {
    case doorway = "doorway"
    case turnInitiation = "turn_initiation"
    case dualTask = "dual_task"
    case anxiety = "anxiety"
    case unknown = "unknown"
}

struct GaitAnomaly {
    let type: AnomalyType
    let severity: Double // 0-1 scale
    let confidence: Double // 0-1 scale
    let timestamp: Date
    let duration: TimeInterval
}

enum AnomalyType: String, CaseIterable {
    case shuffling = "shuffling"
    case reduced_arm_swing = "reduced_arm_swing"
    case festination = "festination"
    case tremor_gait = "tremor_gait"
    case freezing = "freezing"
    case postural_instability = "postural_instability"
}

// MARK: - Clinical Scoring Models
struct ClinicalScores {
    let updrsPartIII: UPDRSPartIII
    let fogQ: FOGQuestionnaire
    let hoehnYahr: HoehnYahrStage
    let overallRisk: ParkinsonsRisk
}

struct UPDRSPartIII {
    let gaitScore: Int // 0-4
    let posturalStabilityScore: Int // 0-4
    let bradykinesiaScore: Int // 0-4
    let rigidityScore: Int // 0-4
    let totalScore: Int
}

struct FOGQuestionnaire {
    let totalScore: Int // 0-24
    let riskLevel: FOGRiskLevel
}

enum FOGRiskLevel: String, CaseIterable {
    case low = "low"
    case moderate = "moderate"
    case high = "high"
}

enum HoehnYahrStage: Double, CaseIterable {
    case stage0 = 0
    case stage1 = 1
    case stage1_5 = 1.5
    case stage2 = 2
    case stage2_5 = 2.5
    case stage3 = 3
    case stage4 = 4
    case stage5 = 5
}

struct ParkinsonsRisk {
    let riskScore: Double // 0-1 probability
    let confidence: Double // 0-1 confidence
    let keyIndicators: [String]
    let recommendation: ClinicalRecommendation
}

enum ClinicalRecommendation: String, CaseIterable {
    case normal = "normal_gait"
    case monitor = "continue_monitoring"
    case consult = "consult_neurologist"
    case urgent = "urgent_evaluation"
}

// MARK: - Session and Results Models
class GaitSession {
    let id: UUID
    let startTime: Date
    var endTime: Date?
    var frames: [GaitFrame] = []
    var environment: EnvironmentData?
    
    init() {
        self.id = UUID()
        self.startTime = Date()
    }
}

struct SpatialAnalysis {
    let stepLengthMean: Double
    let stepLengthCV: Double // coefficient of variation
    let stepWidthMean: Double
    let stepWidthCV: Double
    let strideLengthAsymmetry: Double
    let armSwingAmplitude: (left: Double, right: Double)
    let postualSway: Double
}

struct TemporalAnalysis {
    let stancePhase: Double // percentage of gait cycle
    let swingPhase: Double // percentage of gait cycle
    let doubleStancePhase: Double
    let cadenceVariability: Double
    let rhythmicity: Double // 0-1 scale
}

struct EnvironmentData {
    let meshAnchors: [ARMeshAnchor]
    let obstacles: [Obstacle]
    let walkingPath: [simd_float3]
    let roomDimensions: simd_float3
}

struct Obstacle {
    let position: simd_float3
    let type: ObstacleType
    let dimensions: simd_float3
}

enum ObstacleType: String, CaseIterable {
    case doorway = "doorway"
    case furniture = "furniture"
    case wall = "wall"
    case stairs = "stairs"
    case corner = "corner"
}
