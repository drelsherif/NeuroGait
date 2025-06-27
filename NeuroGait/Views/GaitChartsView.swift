// GaitChartsView.swift

import SwiftUI
import Charts

struct GaitChartsView: View {
    // This view now only needs the pre-processed chart data
    let speedData: [SpeedDataPoint]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Walking Speed Trend")
                .font(.headline)
                .padding(.horizontal)
            
            if speedData.isEmpty {
                // Show a message if there's no data
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                    Text("Not enough data to display speed trend.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(height: 200)
                .padding(.horizontal)
            } else {
                // Create the Chart view.
                Chart(speedData) { dataPoint in
                    // Use LineMark to create a line graph.
                    LineMark(
                        x: .value("Time (s)", dataPoint.time),
                        y: .value("Speed (m/s)", dataPoint.speed)
                    )
                    .foregroundStyle(Color.blue)
                    
                    // Add a nice gradient area below the line
                    AreaMark(
                        x: .value("Time (s)", dataPoint.time),
                        y: .value("Speed (m/s)", dataPoint.speed)
                    )
                    .foregroundStyle(LinearGradient(colors: [.blue.opacity(0.4), .clear], startPoint: .top, endPoint: .bottom))
                }
                .chartYScale(domain: 0...2.0) // Set a consistent Y-axis scale
                .chartYAxis { AxisMarks(position: .leading) }
                .frame(height: 200)
                .padding(.horizontal)
            }
        }
    }
}
