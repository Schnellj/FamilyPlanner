import Foundation

struct Transaction: Identifiable, Codable {
    var id = UUID()
    let date: Date
    let payee: String
    let amount: Double
    let category: String
    let description: String
    let account: String
    let categoryGroup: String
    
    enum CodingKeys: String, CodingKey {
        case date = "Date"
        case payee = "Payee"
        case amount = "Amount"
        case category = "Category"
        case description = "Description"
        case account = "Account"
        case categoryGroup = "Category Group"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Parse date
        let dateString = try container.decode(String.self, forKey: .date)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        if let date = dateFormatter.date(from: dateString) {
            self.date = date
        } else {
            // Try alternative date format
            dateFormatter.dateFormat = "MM/dd/yyyy"
            if let date = dateFormatter.date(from: dateString) {
                self.date = date
            } else {
                throw DecodingError.dataCorruptedError(forKey: .date, in: container, debugDescription: "Date string does not match expected format")
            }
        }
        
        // Parse amount
        let amountString = try container.decode(String.self, forKey: .amount)
        if let amount = Double(amountString.replacingOccurrences(of: ",", with: "")) {
            self.amount = amount
        } else {
            throw DecodingError.dataCorruptedError(forKey: .amount, in: container, debugDescription: "Amount string is not a valid number")
        }
        
        // Parse other fields with defaults for missing values
        self.payee = try container.decodeIfPresent(String.self, forKey: .payee) ?? "Unknown Payee"
        self.category = try container.decodeIfPresent(String.self, forKey: .category) ?? ""
        self.description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        self.account = try container.decodeIfPresent(String.self, forKey: .account) ?? "Unknown Account"
        self.categoryGroup = try container.decodeIfPresent(String.self, forKey: .categoryGroup) ?? ""
    }
    
    // Custom initializer for testing and Core Data conversion
    init(id: UUID = UUID(), date: Date, payee: String, amount: Double, category: String, description: String, account: String, categoryGroup: String) {
        self.id = id
        self.date = date
        self.payee = payee
        self.amount = amount
        self.category = category
        self.description = description
        self.account = account
        self.categoryGroup = categoryGroup
    }
    
    var isExpense: Bool {
        return amount < 0
    }
    
    var isIncome: Bool {
        return amount > 0
    }
    
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "CAD"
        return formatter.string(from: NSNumber(value: abs(amount))) ?? "$0.00"
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
} 