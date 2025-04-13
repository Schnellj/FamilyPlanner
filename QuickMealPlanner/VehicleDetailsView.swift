import SwiftUI

struct Vehicle: Identifiable {
    let id = UUID()
    let make: String
    let model: String
    let year: Int
    let mileage: Int
    let ownershipInfo: OwnershipInfo
    let insuranceInfo: InsuranceInfo
    let maintenanceHistory: [MaintenanceRecord]
    let fuelEfficiency: Double // miles per gallon
    let lastServiceDate: Date
    let nextServiceDue: Date
    let vin: String
    let licensePlate: String
    let color: String
    let purchaseDate: Date
    let purchasePrice: Double
    let currentValue: Double
}

struct OwnershipInfo {
    let owner: String
    let purchaseDate: Date
    let purchasePrice: Double
    let currentValue: Double
    let loanInfo: LoanInfo?
}

struct LoanInfo {
    let lender: String
    let accountNumber: String
    let monthlyPayment: Double
    let interestRate: Double
    let remainingBalance: Double
    let payoffDate: Date
}

struct InsuranceInfo {
    let provider: String
    let policyNumber: String
    let coverage: String
    let deductible: Double
    let monthlyPremium: Double
    let renewalDate: Date
    let agent: String
    let agentPhone: String
}

struct MaintenanceRecord: Identifiable {
    let id = UUID()
    let date: Date
    let serviceType: String
    let mileage: Int
    let cost: Double
    let provider: String
    let notes: String
}

struct VehicleDetailsView: View {
    // Sample data for the two vehicles
    private let vehicles: [Vehicle] = [
        Vehicle(
            make: "Volkswagen",
            model: "Tiguan",
            year: 2017,
            mileage: 75000,
            ownershipInfo: OwnershipInfo(
                owner: "John Doe",
                purchaseDate: Date().addingTimeInterval(-5 * 365 * 24 * 60 * 60), // 5 years ago
                purchasePrice: 25000,
                currentValue: 15000,
                loanInfo: LoanInfo(
                    lender: "VW Credit",
                    accountNumber: "****1234",
                    monthlyPayment: 450,
                    interestRate: 3.9,
                    remainingBalance: 5000,
                    payoffDate: Date().addingTimeInterval(365 * 24 * 60 * 60) // 1 year from now
                )
            ),
            insuranceInfo: InsuranceInfo(
                provider: "State Farm",
                policyNumber: "SF-987654321",
                coverage: "Full Coverage",
                deductible: 500,
                monthlyPremium: 120,
                renewalDate: Date().addingTimeInterval(180 * 24 * 60 * 60), // 6 months from now
                agent: "Jane Smith",
                agentPhone: "(555) 123-4567"
            ),
            maintenanceHistory: [
                MaintenanceRecord(
                    date: Date().addingTimeInterval(-90 * 24 * 60 * 60),
                    serviceType: "Oil Change",
                    mileage: 73000,
                    cost: 45.99,
                    provider: "VW Service Center",
                    notes: "Regular maintenance"
                ),
                MaintenanceRecord(
                    date: Date().addingTimeInterval(-180 * 24 * 60 * 60),
                    serviceType: "Brake Service",
                    mileage: 70000,
                    cost: 350.00,
                    provider: "VW Service Center",
                    notes: "Replaced front brake pads and rotors"
                )
            ],
            fuelEfficiency: 22.5,
            lastServiceDate: Date().addingTimeInterval(-90 * 24 * 60 * 60),
            nextServiceDue: Date().addingTimeInterval(90 * 24 * 60 * 60),
            vin: "WVGBV7AX5HW123456",
            licensePlate: "ABC123",
            color: "Deep Black Pearl",
            purchaseDate: Date().addingTimeInterval(-5 * 365 * 24 * 60 * 60),
            purchasePrice: 25000,
            currentValue: 15000
        ),
        Vehicle(
            make: "Chevrolet",
            model: "Equinox",
            year: 2017,
            mileage: 82000,
            ownershipInfo: OwnershipInfo(
                owner: "John Doe",
                purchaseDate: Date().addingTimeInterval(-5 * 365 * 24 * 60 * 60), // 5 years ago
                purchasePrice: 22000,
                currentValue: 13000,
                loanInfo: LoanInfo(
                    lender: "GM Financial",
                    accountNumber: "****5678",
                    monthlyPayment: 380,
                    interestRate: 4.2,
                    remainingBalance: 3000,
                    payoffDate: Date().addingTimeInterval(180 * 24 * 60 * 60) // 6 months from now
                )
            ),
            insuranceInfo: InsuranceInfo(
                provider: "State Farm",
                policyNumber: "SF-987654322",
                coverage: "Full Coverage",
                deductible: 500,
                monthlyPremium: 110,
                renewalDate: Date().addingTimeInterval(180 * 24 * 60 * 60), // 6 months from now
                agent: "Jane Smith",
                agentPhone: "(555) 123-4567"
            ),
            maintenanceHistory: [
                MaintenanceRecord(
                    date: Date().addingTimeInterval(-60 * 24 * 60 * 60),
                    serviceType: "Oil Change",
                    mileage: 81000,
                    cost: 39.99,
                    provider: "Chevy Service Center",
                    notes: "Regular maintenance"
                ),
                MaintenanceRecord(
                    date: Date().addingTimeInterval(-120 * 24 * 60 * 60),
                    serviceType: "Tire Rotation",
                    mileage: 79000,
                    cost: 29.99,
                    provider: "Chevy Service Center",
                    notes: "Regular maintenance"
                )
            ],
            fuelEfficiency: 24.0,
            lastServiceDate: Date().addingTimeInterval(-60 * 24 * 60 * 60),
            nextServiceDue: Date().addingTimeInterval(120 * 24 * 60 * 60),
            vin: "2GNALDEK9H6123456",
            licensePlate: "XYZ789",
            color: "Silver Ice Metallic",
            purchaseDate: Date().addingTimeInterval(-5 * 365 * 24 * 60 * 60),
            purchasePrice: 22000,
            currentValue: 13000
        )
    ]
    
    var body: some View {
        List {
            ForEach(vehicles) { vehicle in
                Section(header: Text("\(vehicle.year) \(vehicle.make) \(vehicle.model)")) {
                    // Basic Information
                    Group {
                        InfoRow(title: "Mileage", value: "\(vehicle.mileage) miles")
                        InfoRow(title: "Color", value: vehicle.color)
                        InfoRow(title: "VIN", value: vehicle.vin)
                        InfoRow(title: "License Plate", value: vehicle.licensePlate)
                        InfoRow(title: "Fuel Efficiency", value: String(format: "%.1f MPG", vehicle.fuelEfficiency))
                    }
                    
                    // Ownership Information
                    Section(header: Text("Ownership Information")) {
                        InfoRow(title: "Owner", value: vehicle.ownershipInfo.owner)
                        InfoRow(title: "Purchase Date", value: formatDate(vehicle.ownershipInfo.purchaseDate))
                        InfoRow(title: "Purchase Price", value: formatCurrency(vehicle.ownershipInfo.purchasePrice))
                        InfoRow(title: "Current Value", value: formatCurrency(vehicle.ownershipInfo.currentValue))
                        
                        if let loan = vehicle.ownershipInfo.loanInfo {
                            InfoRow(title: "Lender", value: loan.lender)
                            InfoRow(title: "Monthly Payment", value: formatCurrency(loan.monthlyPayment))
                            InfoRow(title: "Interest Rate", value: String(format: "%.1f%%", loan.interestRate))
                            InfoRow(title: "Remaining Balance", value: formatCurrency(loan.remainingBalance))
                            InfoRow(title: "Payoff Date", value: formatDate(loan.payoffDate))
                        }
                    }
                    
                    // Insurance Information
                    Section(header: Text("Insurance Information")) {
                        InfoRow(title: "Provider", value: vehicle.insuranceInfo.provider)
                        InfoRow(title: "Policy Number", value: vehicle.insuranceInfo.policyNumber)
                        InfoRow(title: "Coverage", value: vehicle.insuranceInfo.coverage)
                        InfoRow(title: "Deductible", value: formatCurrency(vehicle.insuranceInfo.deductible))
                        InfoRow(title: "Monthly Premium", value: formatCurrency(vehicle.insuranceInfo.monthlyPremium))
                        InfoRow(title: "Renewal Date", value: formatDate(vehicle.insuranceInfo.renewalDate))
                        InfoRow(title: "Agent", value: vehicle.insuranceInfo.agent)
                        InfoRow(title: "Agent Phone", value: vehicle.insuranceInfo.agentPhone)
                    }
                    
                    // Maintenance History
                    Section(header: Text("Maintenance History")) {
                        ForEach(vehicle.maintenanceHistory) { record in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(record.serviceType)
                                    .font(.headline)
                                HStack {
                                    Text(formatDate(record.date))
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Text(formatCurrency(record.cost))
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                Text("Mileage: \(record.mileage)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Text(record.provider)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                if !record.notes.isEmpty {
                                    Text(record.notes)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    
                    // Service Information
                    Section(header: Text("Service Information")) {
                        InfoRow(title: "Last Service", value: formatDate(vehicle.lastServiceDate))
                        InfoRow(title: "Next Service Due", value: formatDate(vehicle.nextServiceDue))
                    }
                }
            }
        }
        .navigationTitle("Vehicle Details")
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
        }
    }
}

#Preview {
    VehicleDetailsView()
} 