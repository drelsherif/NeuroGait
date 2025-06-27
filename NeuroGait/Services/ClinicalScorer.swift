
//
//  ClinicalScorer.swift
//  NeuroGait
//
//  Clinical assessment and scoring algorithms
//

import Foundation

// MARK: - Clinical Scorer
class ClinicalScorer {
    
    func calculateScores(from results: GaitAnalysisResults) -> ClinicalScores {
        let updrsScore = calculateUPDRSPartIII(results)
        let fogScore = calculateFOGQuestionnaire(results)
        let hoehnYahrStage = calculateHoehnYahrStage(results)
        let riskAssessment = calculateParkinsonsRisk(results, updrsScore, fogScore, hoehnYahrStage)
        
        return ClinicalScores(
            updrsPartIII: updrsScore,
            fogQ: fogScore,
            hoehnYahr: hoehnYahrStage,
            overallRisk: riskAssessment
        )
    }
    
    private func calculateUPDRSPartIII(_ results: GaitAnalysisResults) -> UPDRSPartIII {
        let metrics = results.finalMetrics
        
        // Calculate individual UPDRS scores based on gait analysis
        let gaitScore = calculateGaitScore(metrics)
        let posturalStabilityScore = calculatePosturalStabilityScore(metrics)
        let bradykinesiaScore = Int(metrics.bradykinesiaScore)
        let rigidityScore = calculateRigidityScore(results)
        
        let totalScore = gaitScore + posturalStabilityScore + bradykinesiaScore + rigidityScore
        
        return UPDRSPartIII(
            gaitScore: gaitScore,
            posturalStabilityScore: posturalStabilityScore,
            bradykinesiaScore: bradykinesiaScore,
            rigidityScore: rigidityScore,
            totalScore: totalScore
        )
    }
    
    private func calculateGaitScore(_ metrics: GaitMetrics) -> Int {
        // UPDRS Item 3.10 - Gait (0-4 scale)
        if metrics.walkingSpeed > 1.2 && metrics.strideLength > 0.6 {
            return 0 // Normal
        } else if metrics.walkingSpeed > 1.0 && metrics.strideLength > 0.5 {
            return 1 // Slight
        } else if metrics.walkingSpeed > 0.8 && metrics.strideLength > 0.4 {
            return 2 // Mild
        } else if metrics.walkingSpeed > 0.6 && metrics.strideLength > 0.3 {
            return 3 // Moderate
        } else {
            return 4 // Severe
        }
    }
    
    private func calculatePosturalStabilityScore(_ metrics: GaitMetrics) -> Int {
        // UPDRS Item 3.12 - Postural Stability (0-4 scale)
        let stability = metrics.postualStability
        
        if stability > 0.9 {
            return 0 // Normal
        } else if stability > 0.8 {
            return 1 // Recovers unaided
        } else if stability > 0.6 {
            return 2 // Would fall if not caught
        } else if stability > 0.4 {
            return 3 // Falls spontaneously
        } else {
            return 4 // Unable to stand without assistance
        }
    }
    
    private func calculateRigidityScore(_ results: GaitAnalysisResults) -> Int {
        // Estimate rigidity from arm swing analysis
        let armSwingAsymmetry = results.finalMetrics.armSwingAsymmetry
        
        if armSwingAsymmetry < 0.1 {
            return 0 // Absent
        } else if armSwingAsymmetry < 0.3 {
            return 1 // Slight
        } else if armSwingAsymmetry < 0.5 {
            return 2 // Mild
        } else if armSwingAsymmetry < 0.7 {
            return 3 // Moderate
        } else {
            return 4 // Severe
        }
    }
    
    private func calculateFOGQuestionnaire(_ results: GaitAnalysisResults) -> FOGQuestionnaire {
        var totalScore = 0
        
        // Calculate FOG-Q score based on freezing episodes detected
        let freezingEpisodes = results.freezingEpisodes
        
        if !freezingEpisodes.isEmpty {
            // Simplified scoring based on episode count and duration
            totalScore += min(12, freezingEpisodes.count * 2)
        }
        
        let riskLevel: FOGRiskLevel = {
            if totalScore >= 15 { return .high }
            if totalScore >= 8 { return .moderate }
            return .low
        }()
        
        return FOGQuestionnaire(totalScore: totalScore, riskLevel: riskLevel)
    }
    
    private func calculateHoehnYahrStage(_ results: GaitAnalysisResults) -> HoehnYahrStage {
        let metrics = results.finalMetrics
        let freezingPresent = !results.freezingEpisodes.isEmpty
        
        // Determine H&Y stage based on gait characteristics
        if metrics.walkingSpeed > 1.2 && metrics.postualStability > 0.9 && !freezingPresent {
            return .stage0 // No signs
        } else if metrics.walkingSpeed > 1.0 && metrics.armSwingAsymmetry < 0.3 {
            return .stage1 // Unilateral involvement
        } else if metrics.walkingSpeed > 0.8 && metrics.postualStability > 0.7 {
            return .stage2 // Bilateral involvement without impairment of balance
        } else if metrics.walkingSpeed > 0.6 && metrics.postualStability > 0.5 {
            return .stage3 // Mild to moderate bilateral disease
        } else if metrics.walkingSpeed > 0.4 {
            return .stage4 // Severe disability
        } else {
            return .stage5 // Wheelchair bound
        }
    }
    
    private func calculateParkinsonsRisk(_ results: GaitAnalysisResults,
                                       _ updrs: UPDRSPartIII,
                                       _ fog: FOGQuestionnaire,
                                       _ hy: HoehnYahrStage) -> ParkinsonsRisk {
        
        var riskFactors: [String] = []
        var riskScore = 0.0
        
        // Evaluate key Parkinson's indicators
        if results.finalMetrics.bradykinesiaScore >= 2 {
            riskFactors.append("Significant bradykinesia detected")
            riskScore += 0.25
        }
        
        if results.finalMetrics.armSwingAsymmetry > 0.3 {
            riskFactors.append("Asymmetric arm swing")
            riskScore += 0.2
        }
        
        if !results.freezingEpisodes.isEmpty {
            riskFactors.append("Freezing episodes detected")
            riskScore += 0.3
        }
        
        if results.finalMetrics.stepRegularity < 0.7 {
            riskFactors.append("Irregular step patterns")
            riskScore += 0.15
        }
        
        if results.finalMetrics.postualStability < 0.6 {
            riskFactors.append("Postural instability")
            riskScore += 0.2
        }
        
        // Determine clinical recommendation
        let recommendation: ClinicalRecommendation = {
            if riskScore >= 0.8 {
                return .urgent
            } else if riskScore >= 0.6 {
                return .consult
            } else if riskScore >= 0.3 {
                return .monitor
            } else {
                return .normal
            }
        }()
        
        return ParkinsonsRisk(
            riskScore: min(1.0, riskScore),
            confidence: 0.85, // Simplified confidence
            keyIndicators: riskFactors,
            recommendation: recommendation
        )
    }
}
