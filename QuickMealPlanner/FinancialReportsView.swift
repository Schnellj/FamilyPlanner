import SwiftUI
import Charts

struct FinancialMetric: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct TooltipView: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.caption)
            .padding(8)
            .background(Color(.windowBackgroundColor))
            .cornerRadius(8)
            .shadow(radius: 2)
            .frame(maxWidth: 200)
    }
}

struct InfoIcon: View {
    let tooltip: String
    @State private var isHovered = false
    
    var body: some View {
        Image(systemName: "info.circle")
            .foregroundColor(.blue)
            .help(tooltip)
    }
}

struct FinancialReportsView: View {
    @State private var selectedMonth: Date = Date()
    @State private var selectedTab = 0
    
    // Sample data
    private let mrrData: [FinancialMetric] = {
        let calendar = Calendar.current
        return (0..<12).map { month in
            let date = calendar.date(byAdding: .month, value: -month, to: Date())!
            return FinancialMetric(date: date, value: Double.random(in: 5000...8000))
        }.reversed()
    }()
    
    private let burnRateData: [FinancialMetric] = {
        let calendar = Calendar.current
        return (0..<4).map { week in
            let date = calendar.date(byAdding: .weekOfYear, value: -week, to: Date())!
            return FinancialMetric(date: date, value: Double.random(in: 2000...4000))
        }.reversed()
    }()
    
    private let emergencyFundData: [FinancialMetric] = {
        let calendar = Calendar.current
        return (0..<30).map { day in
            let date = calendar.date(byAdding: .day, value: -day, to: Date())!
            return FinancialMetric(date: date, value: Double.random(in: 3...6))
        }.reversed()
    }()
    
    private let cashFlowMarginData: [FinancialMetric] = {
        let calendar = Calendar.current
        return (0..<12).map { month in
            let date = calendar.date(byAdding: .month, value: -month, to: Date())!
            return FinancialMetric(date: date, value: Double.random(in: 15...30))
        }.reversed()
    }()
    
    private let returnOnNetWorthData: [FinancialMetric] = {
        let calendar = Calendar.current
        return (0..<12).map { month in
            let date = calendar.date(byAdding: .month, value: -month, to: Date())!
            return FinancialMetric(date: date, value: Double.random(in: 5...15))
        }.reversed()
    }()
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Reports Tab
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Date Filter
                    HStack {
                        Text("Select Month:")
                        DatePicker("", selection: $selectedMonth, displayedComponents: .date)
                            .labelsHidden()
                    }
                    .padding(.horizontal)
                    
                    // Summary Tables
                    VStack(spacing: 20) {
                        FinancialMetricTable(
                            title: "Monthly Recurring Revenue",
                            value: "$6,500",
                            change: "+5.2%",
                            tooltip: "The predictable revenue you receive every month from subscriptions, memberships, or regular services."
                        )
                        FinancialMetricTable(
                            title: "Burn Rate",
                            value: "$3,200",
                            change: "-2.1%",
                            tooltip: "How quickly you're spending money each week. A lower burn rate means you're spending less and can sustain operations longer."
                        )
                        FinancialMetricTable(
                            title: "Savings Rate",
                            value: "25%",
                            change: "+1.5%",
                            tooltip: "The percentage of your income that you're saving. A higher rate means you're building wealth faster."
                        )
                        FinancialMetricTable(
                            title: "Emergency Fund Cover",
                            value: "4.5 months",
                            change: "+0.3",
                            tooltip: "How many months you could live on your current savings if you lost all income. Experts recommend 3-6 months."
                        )
                        FinancialMetricTable(
                            title: "Cash Flow Margin",
                            value: "22%",
                            change: "+2.1%",
                            tooltip: "The percentage of your revenue that turns into profit after expenses. A higher margin means more money stays in your pocket."
                        )
                        FinancialMetricTable(
                            title: "Return on Net Worth",
                            value: "8.5%",
                            change: "+0.8%",
                            tooltip: "How well your investments are performing compared to your total assets. A higher return means your money is working harder for you."
                        )
                    }
                    .padding()
                    
                    // Charts
                    VStack(spacing: 30) {
                        // MRR Chart (Monthly)
                        ChartSection(
                            title: "Monthly Recurring Revenue",
                            data: mrrData,
                            tooltip: "The predictable revenue you receive every month from subscriptions, memberships, or regular services."
                        ) { metric in
                            LineMark(
                                x: .value("Date", metric.date),
                                y: .value("MRR", metric.value)
                            )
                            .foregroundStyle(.blue)
                        }
                        
                        // Burn Rate Chart (Weekly)
                        ChartSection(
                            title: "Burn Rate",
                            data: burnRateData,
                            tooltip: "How quickly you're spending money each week. A lower burn rate means you're spending less and can sustain operations longer."
                        ) { metric in
                            LineMark(
                                x: .value("Date", metric.date),
                                y: .value("Burn Rate", metric.value)
                            )
                            .foregroundStyle(.red)
                        }
                        
                        // Emergency Fund Cover Chart (Daily)
                        ChartSection(
                            title: "Emergency Fund Cover",
                            data: emergencyFundData,
                            tooltip: "How many months you could live on your current savings if you lost all income. Experts recommend 3-6 months."
                        ) { metric in
                            LineMark(
                                x: .value("Date", metric.date),
                                y: .value("Months", metric.value)
                            )
                            .foregroundStyle(.green)
                        }
                        
                        // Cash Flow Margin Chart (Monthly)
                        ChartSection(
                            title: "Cash Flow Margin",
                            data: cashFlowMarginData,
                            tooltip: "The percentage of your revenue that turns into profit after expenses. A higher margin means more money stays in your pocket."
                        ) { metric in
                            LineMark(
                                x: .value("Date", metric.date),
                                y: .value("Margin %", metric.value)
                            )
                            .foregroundStyle(.purple)
                        }
                        
                        // Return on Net Worth Chart (Monthly)
                        ChartSection(
                            title: "Return on Net Worth",
                            data: returnOnNetWorthData,
                            tooltip: "How well your investments are performing compared to your total assets. A higher return means your money is working harder for you."
                        ) { metric in
                            LineMark(
                                x: .value("Date", metric.date),
                                y: .value("Return %", metric.value)
                            )
                            .foregroundStyle(.orange)
                        }
                    }
                    .padding()
                }
            }
            .tabItem {
                Label("Reports", systemImage: "chart.bar")
            }
            .tag(0)
            
            // Transactions Tab
            TransactionsView()
                .tabItem {
                    Label("Transactions", systemImage: "list.bullet")
                }
                .tag(1)
        }
        .navigationTitle("Financial Reports")
    }
}

struct FinancialMetricTable: View {
    let title: String
    let value: String
    let change: String
    let tooltip: String
    
    var body: some View {
        HStack {
            HStack(spacing: 4) {
                Text(title)
                    .font(.headline)
                InfoIcon(tooltip: tooltip)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text(value)
                    .font(.title3)
                    .bold()
                Text(change)
                    .foregroundColor(change.hasPrefix("+") ? .green : .red)
            }
        }
        .padding()
        .background(Color(.windowBackgroundColor))
        .cornerRadius(8)
    }
}

struct ChartSection<Content: ChartContent>: View {
    let title: String
    let data: [FinancialMetric]
    let tooltip: String
    let content: (FinancialMetric) -> Content
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.headline)
                InfoIcon(tooltip: tooltip)
            }
            
            Chart(data) { metric in
                content(metric)
            }
            .frame(height: 200)
        }
        .padding()
        .background(Color(.windowBackgroundColor))
        .cornerRadius(8)
    }
}

#Preview {
    FinancialReportsView()
} 