// ResultsViewController.swift

import UIKit
import SwiftUI
import Charts // Import Charts

class ResultsViewController: UIViewController {
    
    // IBOutlets and Properties... (no changes here)
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var riskIndicatorView: UIView!
    @IBOutlet weak var riskLabel: UILabel!
    @IBOutlet weak var recommendationLabel: UILabel!
    @IBOutlet weak var spatialMetricsView: UIView!
    @IBOutlet weak var temporalMetricsView: UIView!
    @IBOutlet weak var clinicalScoresView: UIView!
    @IBOutlet weak var keyFindingsView: UIView!
    @IBOutlet weak var chartsContainerView: UIView!
    @IBOutlet weak var exportButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var progressButton: UIButton!
    var analysisResults: GaitAnalysisResults?
    var clinicalScores: ClinicalScores?
    private let dataManager = GaitDataManager.shared
    
    // viewDidLoad and setupUI... (no changes here)
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        displayResults()
    }
    
    private func setupUI() {
        // ... same as before
        headerView?.backgroundColor = UIColor.systemBlue
        headerView?.layer.cornerRadius = 15
        headerView?.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        [spatialMetricsView, temporalMetricsView, clinicalScoresView, keyFindingsView, chartsContainerView].forEach { view in
            view?.backgroundColor = .systemBackground
            view?.layer.cornerRadius = 12
            view?.layer.shadowColor = UIColor.black.cgColor
            view?.layer.shadowOffset = CGSize(width: 0, height: 2)
            view?.layer.shadowRadius = 4
            view?.layer.shadowOpacity = 0.1
        }
        [exportButton, shareButton, progressButton].forEach { button in
            button?.layer.cornerRadius = 8
            button?.backgroundColor = UIColor.systemBlue
            button?.setTitleColor(.white, for: .normal)
        }
    }
    
    // displayResults... (no changes here)
    private func displayResults() {
        guard let results = analysisResults,
              let scores = clinicalScores else { return }
        
        titleLabel?.text = "Gait Analysis Results"
        dateLabel?.text = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short)
        
        updateRiskIndicator(scores.overallRisk)
        
        displaySpatialMetrics(results.finalMetrics)
        displayTemporalMetrics(results.temporalAnalysis)
        displayClinicalScores(scores)
        displayKeyFindings(results, scores)
        
        // This function is now simpler
        generateVisualizationCharts(results)
    }

    // This function is now much simpler.
    private func generateVisualizationCharts(_ results: GaitAnalysisResults) {
        guard let chartsContainerView = chartsContainerView else { return }
        
        // Create the new SwiftUI view, passing ONLY the chart data it needs.
        let chartView = GaitChartsView(speedData: results.speedOverTime)
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
    
    // All other functions (updateRiskIndicator, display methods, actions, etc.) remain the same.
    // ...
    private func updateRiskIndicator(_ risk: ParkinsonsRisk) {
        guard let riskIndicatorView = riskIndicatorView,
              let riskLabel = riskLabel,
              let recommendationLabel = recommendationLabel else { return }
        
        riskIndicatorView.layer.cornerRadius = 10
        riskIndicatorView.clipsToBounds = true
        
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
    
    private func displaySpatialMetrics(_ metrics: GaitMetrics) {
        guard let spatialMetricsView = spatialMetricsView else { return }
        spatialMetricsView.subviews.forEach { $0.removeFromSuperview() }
        let metricsStackView = createMetricsStackView()
        let stepCountView = createMetricRow("Step Count", value: "\(metrics.stepCount)", unit: "steps")
        let strideLengthView = createMetricRow("Stride Length", value: String(format: "%.2f", metrics.strideLength), unit: "m")
        let stepWidthView = createMetricRow("Step Width", value: String(format: "%.2f", metrics.stepWidth), unit: "m")
        let walkingSpeedView = createMetricRow("Walking Speed", value: String(format: "%.2f", metrics.walkingSpeed), unit: "m/s")
        let armSwingView = createMetricRow("Arm Swing Asymmetry", value: String(format: "%.1f", metrics.armSwingAsymmetry * 100), unit: "%")
        [stepCountView, strideLengthView, stepWidthView, walkingSpeedView, armSwingView].forEach {
            metricsStackView.addArrangedSubview($0)
        }
        addSection(to: spatialMetricsView, with: "Spatial Metrics", content: metricsStackView)
    }
    
    private func displayTemporalMetrics(_ temporal: TemporalAnalysis) {
        guard let temporalMetricsView = temporalMetricsView else { return }
        temporalMetricsView.subviews.forEach { $0.removeFromSuperview() }
        let metricsStackView = createMetricsStackView()
        let cadenceView = createMetricRow("Cadence", value: String(format: "%.1f", analysisResults?.finalMetrics.cadence ?? 0), unit: "steps/min")
        let stancePhaseView = createMetricRow("Stance Phase", value: String(format: "%.1f", temporal.stancePhase), unit: "%")
        let swingPhaseView = createMetricRow("Swing Phase", value: String(format: "%.1f", temporal.swingPhase), unit: "%")
        let doubleStanceView = createMetricRow("Double Stance", value: String(format: "%.1f", temporal.doubleStancePhase), unit: "%")
        let rhythmicityView = createMetricRow("Rhythmicity", value: String(format: "%.2f", temporal.rhythmicity), unit: "")
        [cadenceView, stancePhaseView, swingPhaseView, doubleStanceView, rhythmicityView].forEach {
            metricsStackView.addArrangedSubview($0)
        }
        addSection(to: temporalMetricsView, with: "Temporal Metrics", content: metricsStackView)
    }
    
    private func displayClinicalScores(_ scores: ClinicalScores) {
        guard let clinicalScoresView = clinicalScoresView else { return }
        clinicalScoresView.subviews.forEach { $0.removeFromSuperview() }
        let scoresStackView = createMetricsStackView()
        let updrsView = createScoreRow("UPDRS Part III", score: scores.updrsPartIII.totalScore, maxScore: 40)
        let fogView = createScoreRow("FOG-Q", score: scores.fogQ.totalScore, maxScore: 24)
        let hoehnYahrView = createMetricRow("Hoehn & Yahr Stage", value: String(format: "%.1f", scores.hoehnYahr.rawValue), unit: "")
        let riskView = createMetricRow("Parkinson's Risk", value: String(format: "%.1f", scores.overallRisk.riskScore * 100), unit: "%")
        let confidenceView = createMetricRow("Confidence", value: String(format: "%.1f", scores.overallRisk.confidence * 100), unit: "%")
        [updrsView, fogView, hoehnYahrView, riskView, confidenceView].forEach {
            scoresStackView.addArrangedSubview($0)
        }
        addSection(to: clinicalScoresView, with: "Clinical Assessment", content: scoresStackView)
    }
    
    private func displayKeyFindings(_ results: GaitAnalysisResults, _ scores: ClinicalScores) {
        guard let keyFindingsView = keyFindingsView else { return }
        keyFindingsView.subviews.forEach { $0.removeFromSuperview() }
        let findingsStackView = UIStackView()
        findingsStackView.axis = .vertical
        findingsStackView.spacing = 8
        findingsStackView.alignment = .fill
        let findings = scores.overallRisk.keyIndicators
        if findings.isEmpty {
            let label = UILabel()
            label.text = "• No significant gait abnormalities detected"
            label.font = .systemFont(ofSize: 14)
            label.textColor = .systemGreen
            label.numberOfLines = 0
            findingsStackView.addArrangedSubview(label)
        } else {
            for finding in findings {
                let label = UILabel()
                label.text = "• \(finding)"
                label.font = .systemFont(ofSize: 14)
                label.textColor = .systemOrange
                label.numberOfLines = 0
                findingsStackView.addArrangedSubview(label)
            }
        }
        addSection(to: keyFindingsView, with: "Key Findings", content: findingsStackView)
    }
    
    private func createMetricsStackView() -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.alignment = .fill
        stackView.distribution = .fill
        return stackView
    }
    
    private func addSection(to view: UIView, with title: String, content: UIView) {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .boldSystemFont(ofSize: 18)
        titleLabel.textColor = .label
        
        let containerStack = UIStackView(arrangedSubviews: [titleLabel, content])
        containerStack.axis = .vertical
        containerStack.spacing = 12
        containerStack.alignment = .fill
        
        view.addSubview(containerStack)
        containerStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            containerStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
            containerStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            containerStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            containerStack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16)
        ])
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
    
    @IBAction func exportButtonTapped(_ sender: UIButton) { }
    @IBAction func shareButtonTapped(_ sender: UIButton) { }
    @IBAction func progressButtonTapped(_ sender: UIButton) { }
}

// NOTE: The SwiftUI GaitChartsView struct is now in its own file, "GaitChartsView.swift".
// All export and sharing helper functions would also be moved to their own respective files in a larger project.
