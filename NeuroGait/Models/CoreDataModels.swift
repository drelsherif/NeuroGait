//
//  CoreDataModels.swift
//  NeuroGait
//
//  Core Data entity extensions
//

import Foundation
import CoreData

// MARK: - Core Data Model Extensions
@objc(GaitSessionEntity)
public class GaitSessionEntity: NSManagedObject {
    
}

extension GaitSessionEntity {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<GaitSessionEntity> {
        return NSFetchRequest<GaitSessionEntity>(entityName: "GaitSessionEntity")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var timestamp: Date?
    @NSManaged public var duration: TimeInterval
    @NSManaged public var totalFrames: Int32
    @NSManaged public var patientId: String?
    @NSManaged public var medicationState: String?
    
    // Spatial metrics
    @NSManaged public var stepCount: Int32
    @NSManaged public var cadence: Double
    @NSManaged public var strideLength: Double
    @NSManaged public var stepWidth: Double
    @NSManaged public var walkingSpeed: Double
    @NSManaged public var armSwingAsymmetry: Double
    @NSManaged public var postualStability: Double
    @NSManaged public var doubleStanceTime: Double
    @NSManaged public var swingTime: Double
    
    // Clinical metrics
    @NSManaged public var bradykinesiaScore: Double
    @NSManaged public var festinationIndex: Double
    @NSManaged public var stepRegularity: Double
    
    // Clinical scores
    @NSManaged public var updrsGaitScore: Int16
    @NSManaged public var updrsPosturalScore: Int16
    @NSManaged public var updrsTotalScore: Int16
    @NSManaged public var fogQScore: Int16
    @NSManaged public var hoehnYahrStage: Double
    @NSManaged public var parkinsonsRisk: Double
    @NSManaged public var riskConfidence: Double
    @NSManaged public var clinicalRecommendation: String?
    
    // Relationships
    @NSManaged public var freezingEpisodes: NSSet?
    @NSManaged public var anomalies: NSSet?
}

// MARK: - Generated accessors for GaitSessionEntity
extension GaitSessionEntity {
    
    @objc(addFreezingEpisodesObject:)
    @NSManaged public func addToFreezingEpisodes(_ value: FreezingEpisodeEntity)
    
    @objc(removeFreezingEpisodesObject:)
    @NSManaged public func removeFromFreezingEpisodes(_ value: FreezingEpisodeEntity)
    
    @objc(addFreezingEpisodes:)
    @NSManaged public func addToFreezingEpisodes(_ values: NSSet)
    
    @objc(removeFreezingEpisodes:)
    @NSManaged public func removeFromFreezingEpisodes(_ values: NSSet)
    
    @objc(addAnomaliesObject:)
    @NSManaged public func addToAnomalies(_ value: GaitAnomalyEntity)
    
    @objc(removeAnomaliesObject:)
    @NSManaged public func removeFromAnomalies(_ value: GaitAnomalyEntity)
    
    @objc(addAnomalies:)
    @NSManaged public func addToAnomalies(_ values: NSSet)
    
    @objc(removeAnomalies:)
    @NSManaged public func removeFromAnomalies(_ values: NSSet)
}

@objc(FreezingEpisodeEntity)
public class FreezingEpisodeEntity: NSManagedObject {
    
}

extension FreezingEpisodeEntity {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<FreezingEpisodeEntity> {
        return NSFetchRequest<FreezingEpisodeEntity>(entityName: "FreezingEpisodeEntity")
    }
    
    @NSManaged public var startTime: Date?
    @NSManaged public var duration: TimeInterval
    @NSManaged public var severity: Int16
    @NSManaged public var triggerContext: String?
    @NSManaged public var recoveryTime: TimeInterval
    @NSManaged public var session: GaitSessionEntity?
}

@objc(GaitAnomalyEntity)
public class GaitAnomalyEntity: NSManagedObject {
    
}

extension GaitAnomalyEntity {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<GaitAnomalyEntity> {
        return NSFetchRequest<GaitAnomalyEntity>(entityName: "GaitAnomalyEntity")
    }
    
    @NSManaged public var timestamp: Date?
    @NSManaged public var type: String?
    @NSManaged public var severity: Double
    @NSManaged public var confidence: Double
    @NSManaged public var duration: TimeInterval
    @NSManaged public var session: GaitSessionEntity?
}
