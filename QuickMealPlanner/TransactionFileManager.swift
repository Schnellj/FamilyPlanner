import Foundation

class TransactionFileManager: ObservableObject {
    @Published var selectedDirectory: URL? = nil
    @Published var selectedFile: URL? = nil
    @Published var availableFiles: [URL] = []
    @Published var error: Error?
    @Published var transactions: [Transaction] = []
    @Published var isLoading = false
    
    private let fileManager = FileManager.default
    private let userDefaults = UserDefaults.standard
    private let directoryBookmarkKey = "selectedDirectoryBookmark"
    private let processedFolderPath = "/Users/jschnell/Documents/Code/Transactions/processed"
    
    init() {
        loadSavedDirectory()
    }
    
    func loadSavedDirectory() {
        if let bookmarkData = userDefaults.data(forKey: directoryBookmarkKey) {
            var isStale = false
            
            do {
                let url = try URL(resolvingBookmarkData: bookmarkData, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
                
                // Start accessing the security-scoped resource
                let didStartAccessing = url.startAccessingSecurityScopedResource()
                
                // Make sure we release the security-scoped resource when done
                defer {
                    if didStartAccessing {
                        url.stopAccessingSecurityScopedResource()
                    }
                }
                
                selectedDirectory = url
                loadAvailableFiles()
                
                if isStale {
                    // Bookmark is stale, update it
                    saveDirectoryBookmark(for: url)
                }
            } catch {
                print("Error resolving bookmark: \(error.localizedDescription)")
            }
        }
    }
    
    func saveDirectoryBookmark(for url: URL) {
        do {
            // Start accessing the security-scoped resource
            let didStartAccessing = url.startAccessingSecurityScopedResource()
            
            // Make sure we release the security-scoped resource when done
            defer {
                if didStartAccessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            
            let bookmarkData = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            userDefaults.set(bookmarkData, forKey: directoryBookmarkKey)
        } catch {
            print("Error saving bookmark: \(error.localizedDescription)")
        }
    }
    
    func loadAvailableFiles() {
        guard let directory = selectedDirectory else { return }
        
        // Start accessing the security-scoped resource
        let didStartAccessing = directory.startAccessingSecurityScopedResource()
        
        // Make sure we release the security-scoped resource when done
        defer {
            if didStartAccessing {
                directory.stopAccessingSecurityScopedResource()
            }
        }
        
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            availableFiles = fileURLs.filter { $0.pathExtension.lowercased() == "csv" }
        } catch {
            print("Error loading available files: \(error.localizedDescription)")
        }
    }
    
    func loadTransactions() {
        isLoading = true
        error = nil
        
        do {
            let folderURL = URL(fileURLWithPath: processedFolderPath)
            let fileURLs = try fileManager.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil)
            
            // Filter for CSV files and sort by modification date (newest first)
            let csvFiles = fileURLs.filter { $0.pathExtension.lowercased() == "csv" }
            let sortedFiles = try csvFiles.sorted { file1, file2 in
                let attributes1 = try fileManager.attributesOfItem(atPath: file1.path)
                let attributes2 = try fileManager.attributesOfItem(atPath: file2.path)
                let date1 = attributes1[.modificationDate] as? Date ?? Date.distantPast
                let date2 = attributes2[.modificationDate] as? Date ?? Date.distantPast
                return date1 > date2
            }
            
            // Load the most recent file
            if let mostRecentFile = sortedFiles.first {
                try loadTransactionsFromFile(at: mostRecentFile)
            } else {
                error = NSError(domain: "TransactionFileManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "No CSV files found in the processed folder"])
            }
        } catch {
            self.error = error
            print("Error loading transactions: \(error)")
        }
        
        isLoading = false
    }
    
    func loadTransactionsFromFile(at url: URL) throws {
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
        
        // Print the first few lines of the CSV for debugging
        if let csvString = String(data: data, encoding: .utf8) {
            let lines = csvString.components(separatedBy: .newlines)
            print("CSV file first 5 lines:")
            for (index, line) in lines.prefix(5).enumerated() {
                print("Line \(index + 1): \(line)")
            }
        }
        
        // Decode the transactions using the static method
        do {
            let decodedTransactions: [Transaction] = try CSVDecoder.decode([Transaction].self, from: data)
            
            // Sort transactions by date
            self.transactions = decodedTransactions.sorted { $0.date > $1.date }
            self.error = nil
        } catch {
            print("CSV Decoding Error: \(error)")
            throw error
        }
    }
    
    func transactionsByMonth() -> [String: [Transaction]] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM yyyy"
        
        var result: [String: [Transaction]] = [:]
        
        for transaction in transactions {
            let monthKey = dateFormatter.string(from: transaction.date)
            
            if result[monthKey] == nil {
                result[monthKey] = []
            }
            
            result[monthKey]?.append(transaction)
        }
        
        return result
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
    
    func getFileDisplayName(for url: URL) -> String {
        return url.lastPathComponent
    }
} 