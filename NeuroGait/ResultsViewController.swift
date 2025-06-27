//
//  ResultsViewController.swift
//  NeuroGait
//
//  Clinical results presentation and export
//

import UIKit
import SwiftUI

// MARK: - Results View Controller
class ResultsViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var riskIndicatorView: UIView!
    @IBOutlet weak var riskLabel: UILabel!
    @IBOutlet weak var recommendationLabel: UILabel!
    
    // Metrics Views
    @IBOutlet weak var spatialMetricsView: UIView!
    @IBOutlet weak var temporalMetricsView: UIView!
    @IBOutlet weak var clinicalScoresView: UIView!
    @IBOutlet weak var keyFindingsView: UIView!
    @IBOutlet weak var chartsContainerView: UIView!
    
    // Action Buttons
    @IBOutlet weak var exportButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var progressButton: UIButton!
    
    // MARK: - Properties
    var analysisResults: GaitAnalysisResults?
    var clinicalScores: ClinicalScores?
    private let dataManager = GaitDataManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        displayResults()
    }
    
    private func setupUI() {
        // Configure header
        headerView?.backgroundColor = UIColor.systemBlue
        headerView?.layer.cornerRadius = 15
        headerView?.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        
        // Configure metrics views
        [spatialMetricsView, temporalMetricsView, clinicalScoresView, keyFindingsView].forEach { view in
            view?.backgroundColor = UIColor.systemBackground
            view?.layer.cornerRadius = 12
            view?.layer.shadowColor = UIColor.black.cgColor
            view?.layer.shadowOffset = CGSize(width: 0, height: 2)
            view?.layer.shadowRadius = 4
            view?.layer.shadowOpacity = 0.1
        }
        
        // Configure buttons
        [exportButton, shareButton, progressButton].forEach { button in
            button?.layer.cornerRadius = 8
            button?.backgroundColor = UIColor.systemBlue
            button?.setTitleColor(.white, for: .normal)
        }
    }
    
    private func displayResults() {
        guard let results = analysisResults,
              let scores = clinicalScores else { return }
        
        // Header information
        titleLabel?.text = "Gait Analysis Results"
        dateLabel?.text = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short)
        
        // Risk assessment
        updateRiskIndicator(scores.overallRisk)
        
        // Display metrics
        displaySpatialMetrics(results.finalMetrics)
        displayTemporalMetrics(results.temporalAnalysis)
        displayClinicalScores(scores)
        displayKeyFindings(results, scores)
        
        // Generate charts
        generateVisualizationCharts(results)
    }
    
    private func updateRiskIndicator(_ risk: ParkinsonsRisk) {
        guard let riskIndicatorView = riskIndicatorView,
              let riskLabel = riskLabel,
              let recommendationLabel = recommendationLabel else { return }
        
        riskIndicatorView.layer.cornerRadius = riskIndicatorView.frame.width / 2
        
        let riskColor: UIColor
        let riskText: String
        
        if risk.riskScore >= 0.7 {
            riskColor = .systemRed
            riskText = "HIGH RISK"
        } else if risk.riskScore >= 0.4 {
            riskColor = .systemOrange
            riskText = "MODERATE RISK"
        } else {
            riskColor = .systemGreen
            riskText = "LOW RISK"
        }
        
        riskIndicatorView.backgroundColor = riskColor
        riskLabel.text = riskText
        riskLabel.textColor = .white
        
        recommendationLabel.text = getRecommendationText(risk.recommendation)
    }
    
    private func getRecommendationText(_ recommendation: ClinicalRecommendation) -> String {
        switch recommendation {
        case .normal:
            return "Continue regular monitoring and maintain healthy lifestyle."
        case .monitor:
            return "Consider follow-up assessment in 3-6 months."
        case .consult:
            return "Recommend consultation with a neurologist."
        case .urgent:
            return "Urgent neurological evaluation recommended."
        }
    }
    
    // MARK: - Display Methods
    private func displaySpatialMetrics(_ metrics: GaitMetrics) {
        guard let spatialMetricsView = spatialMetricsView else { return }
        
        // Create spatial metrics content
        let metricsStackView = createMetricsStackView()
        
        let stepCountView = createMetricRow("Step Count", value: "\(metrics.stepCount)", unit: "steps")
        let strideLengthView = createMetricRow("Stride Length", value: String(format: "%.2f", metrics.strideLength), unit: "m")
        let stepWidthView = createMetricRow("Step Width", value: String(format: "%.2f", metrics.stepWidth), unit: "m")
        let walkingSpeedView = createMetricRow("Walking Speed", value: String(format: "%.2f", metrics.walkingSpeed), unit: "m/s")
        let armSwingView = createMetricRow("Arm Swing Asymmetry", value: String(format: "%.1f", metrics.armSwingAsymmetry * 100), unit: "%")
        
        [stepCountView, strideLengthView, stepWidthView, walkingSpeedView, armSwingView].forEach {
            metricsStackView.addArrangedSubview($0)
        }
        
        // Add title
        let titleLabel = UILabel()
        titleLabel.text = "Spatial Metrics"
        titleLabel.font = .boldSystemFont(ofSize: 18)
        titleLabel.textColor = .label
        
        let containerStack = UIStackView(arrangedSubviews: [titleLabel, metricsStackView])
        containerStack.axis = .vertical
        containerStack.spacing = 12
        containerStack.alignment = .fill
        
        spatialMetricsView.addSubview(containerStack)
        containerStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            containerStack.topAnchor.constraint(equalTo: spatialMetricsView.topAnchor, constant: 16),
            containerStack.leadingAnchor.constraint(equalTo: spatialMetricsView.leadingAnchor, constant: 16),
            containerStack.trailingAnchor.constraint(equalTo: spatialMetricsView.trailingAnchor, constant: -16),
            containerStack.bottomAnchor.constraint(equalTo: spatialMetricsView.bottomAnchor, constant: -16)
        ])
    }
    
    private func displayTemporalMetrics(_ temporal: TemporalAnalysis) {
        guard let temporalMetricsView = temporalMetricsView else { return }
        
        let metricsStackView = createMetricsStackView()
        
        let cadenceView = createMetricRow("Cadence", value: String(format: "%.1f", temporal.cadenceVariability), unit: "steps/min")
        let stancePhaseView = createMetricRow("Stance Phase", value: String(format: "%.1f", temporal.stancePhase), unit: "%")
        let swingPhaseView = createMetricRow("Swing Phase", value: String(format: "%.1f", temporal.swingPhase), unit: "%")
        let doubleStanceView = createMetricRow("Double Stance", value: String(format: "%.1f", temporal.doubleStancePhase), unit: "%")
        let rhythmicityView = createMetricRow("Rhythmicity", value: String(format: "%.2f", temporal.rhythmicity), unit: "")
        
        [cadenceView, stancePhaseView, swingPhaseView, doubleStanceView, rhythmicityView].forEach {
            metricsStackView.addArrangedSubview($0)
        }
        
        let titleLabel = UILabel()
        titleLabel.text = "Temporal Metrics"
        titleLabel.font = .boldSystemFont(ofSize: 18)
        titleLabel.textColor = .label
        
        let containerStack = UIStackView(arrangedSubviews: [titleLabel, metricsStackView])
        containerStack.axis = .vertical
        containerStack.spacing = 12
        containerStack.alignment = .fill
        
        temporalMetricsView.addSubview(containerStack)
        containerStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            containerStack.topAnchor.constraint(equalTo: temporalMetricsView.topAnchor, constant: 16),
            containerStack.leadingAnchor.constraint(equalTo: temporalMetricsView.leadingAnchor, constant: 16),
            containerStack.trailingAnchor.constraint(equalTo: temporalMetricsView.trailingAnchor, constant: -16),
            containerStack.bottomAnchor.constraint(equalTo: temporalMetricsView.bottomAnchor, constant: -16)
        ])
    }
    
    private func displayClinicalScores(_ scores: ClinicalScores) {
        guard let clinicalScoresView = clinicalScoresView else { return }
        
        let scoresStackView = createMetricsStackView()
        
        let updrsView = createScoreRow("UPDRS Part III", score: scores.updrsPartIII.totalScore, maxScore: 40)
        let fogView = createScoreRow("FOG-Q", score: scores.fogQ.totalScore, maxScore: 24)
        let hoehnYahrView = createMetricRow("Hoehn & Yahr Stage", value: String(format: "%.1f", scores.hoehnYahr.rawValue), unit: "")
        let riskView = createMetricRow("Parkinson's Risk", value: String(format: "%.1f", scores.overallRisk.riskScore * 100), unit: "%")
        let confidenceView = createMetricRow("Confidence", value: String(format: "%.1f", scores.overallRisk.confidence * 100), unit: "%")
        
        [updrsView, fogView, hoehnYahrView, riskView, confidenceView].forEach {
            scoresStackView.addArrangedSubview($0)
        }
        
        let titleLabel = UILabel()
        titleLabel.text = "Clinical Assessment"
        titleLabel.font = .boldSystemFont(ofSize: 18)
        titleLabel.textColor = .label
        
        let containerStack = UIStackView(arrangedSubviews: [titleLabel, scoresStackView])
        containerStack.axis = .vertical
        containerStack.spacing = 12
        containerStack.alignment = .fill
        
        clinicalScoresView.addSubview(containerStack)
        containerStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            containerStack.topAnchor.constraint(equalTo: clinicalScoresView.topAnchor, constant: 16),
            containerStack.leadingAnchor.constraint(equalTo: clinicalScoresView.leadingAnchor, constant: 16),
            containerStack.trailingAnchor.constraint(equalTo: clinicalScoresView.trailingAnchor, constant: -16),
            containerStack.bottomAnchor.constraint(equalTo: clinicalScoresView.bottomAnchor, constant: -16)
        ])
    }
    
    private func displayKeyFindings(_ results: GaitAnalysisResults, _ scores: ClinicalScores) {
        guard let keyFindingsView = keyFindingsView else { return }
        
        let findingsStackView = UIStackView()
        findingsStackView.axis = .vertical
        findingsStackView.spacing = 8
        findingsStackView.alignment = .fill
        
        // Generate key findings
        var findings: [String] = []
        
        if results.finalMetrics.bradykinesiaScore >= 2.0 {
            findings.append("• Significant bradykinesia detected")
        }
        
        if results.finalMetrics.armSwingAsymmetry > 0.3 {
            findings.append("• Marked arm swing asymmetry")
        }
        
        if !results.freezingEpisodes.isEmpty {
            findings.append("• \(results.freezingEpisodes.count) freezing episode(s) detected")
        }
        
        if results.finalMetrics.festinationIndex > 0.5 {
            findings.append("• Festinating gait pattern observed")
        }
        
        if results.finalMetrics.postualStability < 0.6 {
            findings.append("• Reduced postural stability")
        }
        
        if findings.isEmpty {
            findings.append("• No significant gait abnormalities detected")
        }
        
        // Create finding labels
        for finding in findings {
            let label = UILabel()
            label.text = finding
            label.font = .systemFont(ofSize: 14)
            label.textColor = finding.contains("No significant") ? .systemGreen : .systemOrange
            label.numberOfLines = 0
            findingsStackView.addArrangedSubview(label)
        }
        
        let titleLabel = UILabel()
        titleLabel.text = "Key Findings"
        titleLabel.font = .boldSystemFont(ofSize: 18)
        titleLabel.textColor = .label
        
        let containerStack = UIStackView(arrangedSubviews: [titleLabel, findingsStackView])
        containerStack.axis = .vertical
        containerStack.spacing = 12
        containerStack.alignment = .fill
        
        keyFindingsView.addSubview(containerStack)
        containerStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            containerStack.topAnchor.constraint(equalTo: keyFindingsView.topAnchor, constant: 16),
            containerStack.leadingAnchor.constraint(equalTo: keyFindingsView.leadingAnchor, constant: 16),
            containerStack.trailingAnchor.constraint(equalTo: keyFindingsView.trailingAnchor, constant: -16),
            containerStack.bottomAnchor.constraint(equalTo: keyFindingsView.bottomAnchor, constant: -16)
        ])
    }
    
    private func generateVisualizationCharts(_ results: GaitAnalysisResults) {
        guard let chartsContainerView = chartsContainerView else { return }
        
        // Create SwiftUI charts container
        let chartView = GaitChartsView(analysisResults: results)
        let hostingController = UIHostingController(rootView: chartView)
        
        addChild(hostingController)
        chartsContainerView.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: chartsContainerView.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: chartsContainerView.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: chartsContainerView.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: chartsContainerView.bottomAnchor)
        ])
        hostingController.didMove(toParent: self)
    }
    
    // MARK: - Helper Methods
    private func createMetricsStackView() -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.alignment = .fill
        stackView.distribution = .equalSpacing
        return stackView
    }
    
    private func createMetricRow(_ title: String, value: String, unit: String) -> UIView {
        let containerView = UIView()
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 14)
        titleLabel.textColor = .secondaryLabel
        
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .boldSystemFont(ofSize: 16)
        valueLabel.textColor = .label
        
        let unitLabel = UILabel()
        unitLabel.text = unit
        unitLabel.font = .systemFont(ofSize: 12)
        unitLabel.textColor = .tertiaryLabel
        
        let valueStack = UIStackView(arrangedSubviews: [valueLabel, unitLabel])
        valueStack.axis = .horizontal
        valueStack.spacing = 4
        valueStack.alignment = .lastBaseline
        
        containerView.addSubview(titleLabel)
        containerView.addSubview(valueStack)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        valueStack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            
            valueStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            valueStack.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            
            containerView.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        return containerView
    }
    
    private func createScoreRow(_ title: String, score: Int, maxScore: Int) -> UIView {
        let containerView = UIView()
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 14)
        titleLabel.textColor = .secondaryLabel
        
        let scoreLabel = UILabel()
        scoreLabel.text = "\(score)/\(maxScore)"
        scoreLabel.font = .boldSystemFont(ofSize: 16)
        scoreLabel.textColor = .label
        
        // Progress bar
        let progressView = UIProgressView(progressViewStyle: .default)
        progressView.progress = Float(score) / Float(maxScore)
        progressView.progressTintColor = score > maxScore/2 ? .systemRed : .systemGreen
        
        let scoreStack = UIStackView(arrangedSubviews: [scoreLabel, progressView])
        scoreStack.axis = .horizontal
        scoreStack.spacing = 8
        scoreStack.alignment = .center
        
        containerView.addSubview(titleLabel)
        containerView.addSubview(scoreStack)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        scoreStack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            
            scoreStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            scoreStack.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            scoreStack.widthAnchor.constraint(equalToConstant: 120),
            
            containerView.heightAnchor.constraint(equalToConstant: 32)
        ])
        
        return containerView
    }
    
    // MARK: - Action Methods
    @IBAction func exportButtonTapped(_ sender: UIButton) {
        guard let results = analysisResults else { return }
        
        dataManager.exportClinicalReport(for: results.sessionId) { [weak self] report in
            DispatchQueue.main.async {
                guard let self = self, let report = report else {
                    self?.showAlert(title: "Export Error", message: "Failed to generate clinical report.")
                    return
                }
                
                self.presentExportOptions(report: report)
            }
        }
    }
    
    @IBAction func shareButtonTapped(_ sender: UIButton) {
        guard let results = analysisResults,
              let scores = clinicalScores else { return }
        
        let shareText = generateShareText(results: results, scores: scores)
        
        let activityVC = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )
        
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = sender
            popover.sourceRect = sender.bounds
        }
        
        present(activityVC, animated: true)
    }
    
    @IBAction func progressButtonTapped(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let progressVC = storyboard.instantiateViewController(withIdentifier: "ProgressViewController") as? ProgressViewController {
            navigationController?.pushViewController(progressVC, animated: true)
        }
    }
    
    private func presentExportOptions(report: ClinicalReport) {
        let alertController = UIAlertController(
            title: "Export Options",
            message: "Choose export format",
            preferredStyle: .actionSheet
        )
        
        alertController.addAction(UIAlertAction(title: "PDF Report", style: .default) { _ in
            self.exportToPDF(report: report)
        })
        
        alertController.addAction(UIAlertAction(title: "CSV Data", style: .default) { _ in
            self.exportToCSV(report: report)
        })
        
        alertController.addAction(UIAlertAction(title: "JSON Data", style: .default) { _ in
            self.exportToJSON(report: report)
        })
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alertController.popoverPresentationController {
            popover.sourceView = exportButton
            popover.sourceRect = exportButton.bounds
        }
        
        present(alertController, animated: true)
    }
    
    private func exportToPDF(report: ClinicalReport) {
        // Generate PDF report
        let pdfGenerator = ClinicalReportPDFGenerator()
        pdfGenerator.generatePDF(from: report) { [weak self] pdfData in
            DispatchQueue.main.async {
                guard let self = self, let data = pdfData else {
                    self?.showAlert(title: "Export Error", message: "Failed to generate PDF report.")
                    return
                }
                
                self.sharePDFData(data)
            }
        }
    }
    
    private func exportToCSV(report: ClinicalReport) {
        let csvGenerator = ClinicalReportCSVGenerator()
        let csvString = csvGenerator.generateCSV(from: report)
        
        guard let data = csvString.data(using: .utf8) else {
            showAlert(title: "Export Error", message: "Failed to generate CSV data.")
            return
        }
        
        shareData(data, filename: "gait_analysis_\(report.sessionId).csv", type: "text/csv")
    }
    
    private func exportToJSON(report: ClinicalReport) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(report)
            
            shareData(data, filename: "gait_analysis_\(report.sessionId).json", type: "application/json")
        } catch {
            showAlert(title: "Export Error", message: "Failed to generate JSON data: \(error.localizedDescription)")
        }
    }
    
    private func sharePDFData(_ data: Data) {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("gait_report.pdf")
        
        do {
            try data.write(to: tempURL)
            
            let activityVC = UIActivityViewController(
                activityItems: [tempURL],
                applicationActivities: nil
            )
            
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = exportButton
                popover.sourceRect = exportButton.bounds
            }
            
            present(activityVC, animated: true)
        } catch {
            showAlert(title: "Export Error", message: "Failed to save PDF file.")
        }
    }
    
    private func shareData(_ data: Data, filename: String, type: String) {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        
        do {
            try data.write(to: tempURL)
            
            let activityVC = UIActivityViewController(
                activityItems: [tempURL],
                applicationActivities: nil
            )
            
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = exportButton
                popover.sourceRect = exportButton.bounds
            }
            
            present(activityVC, animated: true)
        } catch {
            showAlert(title: "Export Error", message: "Failed to save \(type) file.")
        }
    }
    
    private func generateShareText(results: GaitAnalysisResults, scores: ClinicalScores) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        return """
        NeuroGait Analysis Report
        Date: \(formatter.string(from: Date()))
        Duration: \(String(format: "%.1f", results.duration/60)) minutes
        
        Key Metrics:
        • Walking Speed: \(String(format: "%.2f", results.finalMetrics.walkingSpeed)) m/s
        • Step Count: \(results.finalMetrics.stepCount)
        • Stride Length: \(String(format: "%.2f", results.finalMetrics.strideLength)) m
        
        Clinical Assessment:
        • UPDRS Part III: \(scores.updrsPartIII.totalScore)/40
        • FOG-Q Score: \(scores.fogQ.totalScore)/24
        • Parkinson's Risk: \(String(format: "%.1f", scores.overallRisk.riskScore * 100))%
        
        Recommendation: \(getRecommendationText(scores.overallRisk.recommendation))
        """
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - SwiftUI Charts View
struct GaitChartsView: View {
    let analysisResults: GaitAnalysisResults
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Gait Analysis Visualizations")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding()
                
                // Walking Speed Over Time Chart
                VStack(alignment: .leading) {
                    Text("Walking Speed Trend")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    // Placeholder for walking speed chart
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.1))
                        .frame(height: 200)
                        .overlay(
                            Text("Walking Speed Chart\n(Implementation with Charts framework)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        )
                        .padding(.horizontal)
                }
                
                // Step Pattern Analysis
                VStack(alignment: .leading) {
                    Text("Step Pattern Analysis")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.green.opacity(0.1))
                        .frame(height: 200)
                        .overlay(
                            Text("Step Pattern Visualization\n(Implementation with Charts framework)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        )
                        .padding(.horizontal)
                }
                
                // Clinical Scores Radar Chart
                VStack(alignment: .leading) {
                    Text("Clinical Assessment Overview")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.orange.opacity(0.1))
                        .frame(height: 200)
                        .overlay(
                            Text("Clinical Scores Radar Chart\n(Implementation with Charts framework)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        )
                        .padding(.horizontal)
                }
            }
        }
    }
}

// MARK: - Export Generators
class ClinicalReportPDFGenerator {
    func generatePDF(from report: ClinicalReport, completion: @escaping (Data?) -> Void) {
        // PDF generation implementation
        // This would use PDFKit to create a professional clinical report
        completion(nil) // Placeholder
    }
}

class ClinicalReportCSVGenerator {
    func generateCSV(from report: ClinicalReport) -> String {
        var csv = "Metric,Value,Unit\n"
        csv += "Session ID,\(report.sessionId),\n"
        csv += "Date,\(ISO8601DateFormatter().string(from: report.date)),\n"
        csv += "Duration,\(report.duration),seconds\n"
        csv += "Step Count,\(report.spatialMetrics.stepCount),steps\n"
        csv += "Stride Length,\(report.spatialMetrics.strideLength),m\n"
        csv += "Step Width,\(report.spatialMetrics.stepWidth),m\n"
        csv += "Walking Speed,\(report.spatialMetrics.walkingSpeed),m/s\n"
        csv += "Cadence,\(report.temporalMetrics.cadence),steps/min\n"
        csv += "UPDRS Part III,\(report.clinicalAssessment.updrsPartIII),score\n"
        csv += "FOG-Q,\(report.clinicalAssessment.fogQScore),score\n"
        csv += "H&Y Stage,\(report.clinicalAssessment.hoehnYahrStage),stage\n"
        csv += "Parkinson's Risk,\(report.clinicalAssessment.parkinsonsRisk),probability\n"
        
        return csv
    }
}
