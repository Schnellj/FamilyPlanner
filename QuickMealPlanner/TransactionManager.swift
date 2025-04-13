import Foundation

class TransactionManager: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var error: Error?
    @Published var isLoading = false
    @Published var selectedDateRange: DateRange = .allTime
    
    private let coreDataManager = CoreDataManager.shared
    
    enum DateRange: String, CaseIterable {
        case lastMonth = "Last Month"
        case last3Months = "Last 3 Months"
        case last6Months = "Last 6 Months"
        case lastYear = "Last Year"
        case allTime = "All Time"
        
        var startDate: Date? {
            let calendar = Calendar.current
            let now = Date()
            
            switch self {
            case .lastMonth:
                return calendar.date(byAdding: .month, value: -1, to: now)
            case .last3Months:
                return calendar.date(byAdding: .month, value: -3, to: now)
            case .last6Months:
                return calendar.date(byAdding: .month, value: -6, to: now)
            case .lastYear:
                return calendar.date(byAdding: .year, value: -1, to: now)
            case .allTime:
                return nil
            }
        }
    }
    
    init() {
        loadTransactionsFromCoreData()
    }
    
    func loadTransactionsFromCoreData() {
        isLoading = true
        transactions = coreDataManager.fetchTransactions(from: selectedDateRange.startDate)
        isLoading = false
    }
    
    func loadTransactions(from url: URL) {
        isLoading = true
        error = nil
        
        do {
            // Start accessing the security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                throw TransactionError.fileAccessDenied
            }
            
            defer {
                url.stopAccessingSecurityScopedResource()
            }
            
            // Read the file using FileHandle
            let fileHandle = try FileHandle(forReadingFrom: url)
            defer {
                try? fileHandle.close()
            }
            
            let data = try fileHandle.readToEnd() ?? Data()
            
            // Decode the transactions
            let decodedTransactions: [Transaction] = try CSVDecoder.decode([Transaction].self, from: data)
            
            // Save to Core Data
            coreDataManager.saveTransactions(decodedTransactions, importSource: url.lastPathComponent)
            
            // Reload from Core Data to get all transactions
            loadTransactionsFromCoreData()
            
            self.error = nil
        } catch let error as CSVError {
            self.error = error
            print("CSV Error: \(error)")
        } catch {
            self.error = TransactionError.loadingFailed(error)
            print("Loading Error: \(error)")
        }
        
        isLoading = false
    }
    
    func transactionsByMonth() -> [String: [Transaction]] {
        return coreDataManager.fetchTransactionsByMonth()
    }
    
    func totalIncome(for month: String) -> Double {
        let monthTransactions = transactionsByMonth()[month] ?? []
        return monthTransactions.filter { $0.amount > 0 }.reduce(0) { $0 + $1.amount }
    }
    
    func totalExpenses(for month: String) -> Double {
        let monthTransactions = transactionsByMonth()[month] ?? []
        return abs(monthTransactions.filter { $0.amount < 0 }.reduce(0) { $0 + $1.amount })
    }
    
    func netIncome(for month: String) -> Double {
        let monthTransactions = transactionsByMonth()[month] ?? []
        return monthTransactions.reduce(0) { $0 + $1.amount }
    }
    
    func deleteTransaction(withId id: UUID) {
        coreDataManager.deleteTransaction(withId: id)
        loadTransactionsFromCoreData()
    }
    
    func deleteAllTransactions() {
        coreDataManager.deleteAllTransactions()
        loadTransactionsFromCoreData()
    }
}

enum TransactionError: LocalizedError {
    case fileAccessDenied
    case loadingFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .fileAccessDenied:
            return "Access to the file was denied"
        case .loadingFailed(let error):
            return "Failed to load transactions: \(error.localizedDescription)"
        }
    }
} 