import Foundation

enum CSVError: LocalizedError {
    case invalidFormat
    case missingHeader
    case invalidData(String)
    case decodingError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "Invalid CSV format"
        case .missingHeader:
            return "Missing header row"
        case .invalidData(let message):
            return "Invalid data: \(message)"
        case .decodingError(let message):
            return "Decoding error: \(message)"
        }
    }
}

struct CSVDecoder {
    static func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        guard let csvString = String(data: data, encoding: .utf8) else {
            throw CSVError.invalidFormat
        }
        
        let rows = csvString.components(separatedBy: .newlines)
        guard rows.count > 1 else {
            throw CSVError.missingHeader
        }
        
        // Parse header row to get column names
        let headerRow = parseCSVRow(rows[0])
        print("Headers found: \(headerRow)")
        
        // Special handling for Transaction array
        if T.self == [Transaction].self {
            var transactions: [Transaction] = []
            
            for (index, row) in rows.dropFirst().enumerated() where !row.isEmpty {
                let columns = parseCSVRow(row)
                guard columns.count == headerRow.count else { 
                    print("Skipping row \(index + 1) with incorrect column count: \(columns.count) vs \(headerRow.count)")
                    continue 
                }
                
                var dictionary: [String: String] = [:]
                for (index, columnName) in headerRow.enumerated() {
                    dictionary[columnName] = columns[index]
                }
                
                print("Row \(index + 1) data: \(dictionary)")
                
                do {
                    // Create a Transaction directly from the dictionary
                    let transaction = try createTransaction(from: dictionary)
                    transactions.append(transaction)
                } catch {
                    print("Error creating transaction from row \(index + 1): \(error)")
                    // Continue with next row instead of failing completely
                    continue
                }
            }
            
            return transactions as! T
        }
        
        // For other types, use the standard JSON decoding approach
        var result: [T] = []
        for (index, row) in rows.dropFirst().enumerated() where !row.isEmpty {
            let columns = parseCSVRow(row)
            guard columns.count == headerRow.count else { 
                print("Skipping row \(index + 1) with incorrect column count: \(columns.count) vs \(headerRow.count)")
                continue 
            }
            
            var dictionary: [String: String] = [:]
            for (index, columnName) in headerRow.enumerated() {
                dictionary[columnName] = columns[index]
            }
            
            // Convert dictionary to JSON data
            let jsonData = try JSONSerialization.data(withJSONObject: dictionary)
            
            do {
                let decoder = JSONDecoder()
                let item = try decoder.decode(T.self, from: jsonData)
                result.append(item)
            } catch {
                print("Error decoding row \(index + 1): \(error)")
                throw CSVError.decodingError("Row \(index + 1): \(error.localizedDescription)")
            }
        }
        
        // If we're expecting a single object, return the first item
        if result.count == 1 {
            return result[0]
        } else if result.isEmpty {
            throw CSVError.invalidData("No valid rows found in CSV")
        } else {
            throw CSVError.invalidData("Expected a single object but found \(result.count) rows")
        }
    }
    
    private static func createTransaction(from dictionary: [String: String]) throws -> Transaction {
        // Parse date
        let dateString = dictionary["Date"] ?? ""
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        
        guard let date = dateFormatter.date(from: dateString) else {
            throw CSVError.invalidData("Invalid date format: \(dateString)")
        }
        
        // Parse amount
        let amountString = dictionary["amount"] ?? "0"
        guard let amount = Double(amountString) else {
            throw CSVError.invalidData("Invalid amount: \(amountString)")
        }
        
        // Get other fields with defaults
        let payee = dictionary["Payee"] ?? "Unknown Payee"
        let category = dictionary["category"] ?? ""
        let description = dictionary["description"] ?? ""
        let account = dictionary["Account"] ?? "Unknown Account"
        let categoryGroup = dictionary["Category Group"] ?? ""
        
        return Transaction(
            date: date,
            payee: payee,
            amount: amount,
            category: category,
            description: description,
            account: account,
            categoryGroup: categoryGroup
        )
    }
    
    private static func parseCSVRow(_ row: String) -> [String] {
        var columns: [String] = []
        var currentColumn = ""
        var insideQuotes = false
        
        for (index, char) in row.enumerated() {
            if char == "\"" {
                if insideQuotes && index + 1 < row.count {
                    // Check if this is an escaped quote
                    let nextIndex = row.index(row.startIndex, offsetBy: index + 1)
                    let nextChar = row[nextIndex]
                    if nextChar == "\"" {
                        currentColumn.append(char)
                    } else {
                        insideQuotes = false
                    }
                } else {
                    insideQuotes = true
                }
            } else if char == "," && !insideQuotes {
                columns.append(currentColumn.trimmingCharacters(in: .whitespaces))
                currentColumn = ""
            } else {
                currentColumn.append(char)
            }
        }
        
        columns.append(currentColumn.trimmingCharacters(in: .whitespaces))
        return columns
    }
} 