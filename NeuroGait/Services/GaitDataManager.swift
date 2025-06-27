//
//  GaitDataManager.swift
//  NeuroGait
//
//  Core Data management for gait analysis
//

import Foundation
import CoreData

// MARK: - Gait Data Manager
class GaitDataManager {
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "NeuroGait")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data error: \(error)")
            }
        }
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func saveGaitSession(_ results: GaitAnalysisResults,
                        clinicalScores: ClinicalScores,
                        completion: @escaping (Bool) -> Void) {
        
        context.perform { [weak self] in
            guard let self = self else {
                completion(false)
                return
            }
            
            // Create a new GaitSessionEntity
            let sessionEntity = GaitSessionEntity(context: self.context)
            
            // Populate Session Details
            sessionEntity.id = results.sessionId
            sessionEntity.timestamp = Date()
            sessionEntity.duration = results.duration
            sessionEntity.totalFrames = Int32(results.totalFrames)
            
            // Populate Final Metrics
            let metrics = results.finalMetrics
            sessionEntity.stepCount = Int32(metrics.stepCount)
            sessionEntity.cadence = metrics.cadence
            sessionEntity.strideLength = metrics.strideLength
            sessionEntity.stepWidth = metrics.stepWidth
            sessionEntity.walkingSpeed = metrics.walkingSpeed
            sessionEntity.doubleStanceTime = metrics.doubleStanceTime
            sessionEntity.swingTime = metrics.swingTime
            sessionEntity.armSwingAsymmetry = metrics.armSwingAsymmetry
            sessionEntity.postualStability = metrics.postualStability
            sessionEntity.bradykinesiaScore = metrics.bradykinesiaScore
            sessionEntity.festinationIndex = metrics.festinationIndex
            sessionEntity.stepRegularity = metrics.stepRegularity
            
            // Populate Clinical Scores
            let scores = clinicalScores
            sessionEntity.updrsGaitScore = Int16(scores.updrsPartIII.gaitScore)
            sessionEntity.updrsPosturalScore = Int16(scores.updrsPartIII.posturalStabilityScore)
            sessionEntity.updrsTotalScore = Int16(scores.updrsPartIII.totalScore)
            sessionEntity.fogQScore = Int16(scores.fogQ.totalScore)
            sessionEntity.hoehnYahrStage = scores.hoehnYahr.rawValue
            sessionEntity.parkinsonsRisk = scores.overallRisk.riskScore
            sessionEntity.riskConfidence = scores.overallRisk.confidence
            sessionEntity.clinicalRecommendation = scores.overallRisk.recommendation.rawValue
            
            // Populate Freezing Episodes
            for episode in results.freezingEpisodes {
                let episodeEntity = FreezingEpisodeEntity(context: self.context)
                episodeEntity.startTime = episode.startTime
                episodeEntity.duration = episode.duration
                episodeEntity.severity = Int16(episode.severity.rawValue)
                episodeEntity.triggerContext = episode.triggerContext.rawValue
                episodeEntity.recoveryTime = episode.recoveryTime
                sessionEntity.addToFreezingEpisodes(episodeEntity)
            }
            
            // Populate Anomalies
            for anomaly in results.anomalies {
                let anomalyEntity = GaitAnomalyEntity(context: self.context)
                anomalyEntity.timestamp = anomaly.timestamp
                anomalyEntity.type = anomaly.type.rawValue
                anomalyEntity.severity = anomaly.severity
                anomalyEntity.confidence = anomaly.confidence
                anomalyEntity.duration = anomaly.duration
                sessionEntity.addToAnomalies(anomalyEntity)
            }
            
            // Save the context
            do {
                try self.context.save()
                completion(true)
            } catch {
                print("Failed to save gait session: \(error)")
                self.context.rollback()
                completion(false)
            }
        }
    }
    
    func exportClinicalReport(for sessionId: UUID, completion: @escaping (ClinicalReport?) -> Void) {
        let request = GaitSessionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", sessionId as CVarArg)
        request.fetchLimit = 1
        
        context.perform {
            do {
                guard let sessionEntity = try self.context.fetch(request).first else {
                    completion(nil)
                    return
                }
                
                // Map the Core Data entity back to the report struct
                let report = ClinicalReport(
                    sessionId: sessionEntity.id ?? UUID(),
                    date: sessionEntity.timestamp ?? Date(),
                    duration: sessionEntity.duration,
                    spatialMetrics: SpatialMetricsReport(
                        stepCount: Int(sessionEntity.stepCount),
                        strideLength: sessionEntity.strideLength,
                        stepWidth: sessionEntity.stepWidth,
                        walkingSpeed: sessionEntity.walkingSpeed
                    ),
                    temporalMetrics: TemporalMetricsReport(
                        cadence: sessionEntity.cadence,
                        stepRegularity: sessionEntity.stepRegularity,
                        doubleStanceTime: sessionEntity.doubleStanceTime,
                        swingTime: sessionEntity.swingTime
                    ),
                    clinicalAssessment: ClinicalAssessmentReport(
                        updrsPartIII: Int(sessionEntity.updrsTotalScore),
                        fogQScore: Int(sessionEntity.fogQScore),
                        hoehnYahrStage: sessionEntity.hoehnYahrStage,
                        parkinsonsRisk: sessionEntity.parkinsonsRisk,
                        recommendation: sessionEntity.clinicalRecommendation ?? "n/a"
                    ),
                    keyFindings: ["Report generated from saved session."]
                )
                completion(report)
                
            } catch {
                print("Failed to fetch session for export: \(error)")
                completion(nil)
            }
        }
    }
}

// MARK: - Report Data Structures
struct ClinicalReport: Codable {
    let sessionId: UUID
    let date: Date
    let duration: TimeInterval
    let spatialMetrics: SpatialMetricsReport
    let temporalMetrics: TemporalMetricsReport
    let clinicalAssessment: ClinicalAssessmentReport
    let keyFindings: [String]
}

struct SpatialMetricsReport: Codable {
    let stepCount: Int
    let strideLength: Double
    let stepWidth: Double
    let walkingSpeed: Double
}

struct TemporalMetricsReport: Codable {
    let cadence: Double
    let stepRegularity: Double
    let doubleStanceTime: Double
    let swingTime: Double
}

struct ClinicalAssessmentReport: Codable {
    let updrsPartIII: Int
    let fogQScore: Int
    let hoehnYahrStage: Double
    let parkinsonsRisk: Double
    let recommendation: String
}
