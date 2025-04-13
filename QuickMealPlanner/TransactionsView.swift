import SwiftUI

struct TransactionsView: View {
    @StateObject private var transactionManager = TransactionManager()
    @State private var selectedFile: URL?
    @State private var showingFilePicker = false
    @State private var showingErrorDetails = false
    @State private var showingDeleteConfirmation = false
    @State private var searchText = ""
    
    var body: some View {
        VStack {
            // Date range picker
            Picker("Date Range", selection: $transactionManager.selectedDateRange) {
                ForEach(TransactionManager.DateRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .onChange(of: transactionManager.selectedDateRange) { oldValue, newValue in
                transactionManager.loadTransactionsFromCoreData()
            }
            
            // File selection button
            HStack {
                Button(action: {
                    showingFilePicker = true
                }) {
                    HStack {
                        Image(systemName: "doc.badge.plus")
                        Text("Import CSV")
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
                
                Spacer()
                
                Button(action: {
                    showingDeleteConfirmation = true
                }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Clear All")
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }
                .disabled(transactionManager.transactions.isEmpty)
            }
            .padding(.horizontal)
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search transactions", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding(.horizontal)
            
            // Error display
            if let error = transactionManager.error {
                VStack {
                    Text("Error loading transactions")
                        .font(.headline)
                        .foregroundColor(.red)
                    
                    Button("Show Details") {
                        showingErrorDetails = true
                    }
                    .buttonStyle(.bordered)
                    .padding(.top, 4)
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
                .sheet(isPresented: $showingErrorDetails) {
                    ErrorDetailsView(error: error)
                }
            }
            
            // Loading indicator
            if transactionManager.isLoading {
                ProgressView("Loading transactions...")
                    .padding()
            }
            
            // Transactions list
            if transactionManager.transactions.isEmpty && !transactionManager.isLoading {
                Spacer()
                VStack(spacing: 20) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    
                    Text("No transactions loaded")
                        .font(.headline)
                    
                    Text("Import a CSV file to view your transactions")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                Spacer()
            } else {
                List {
                    ForEach(transactionManager.transactionsByMonth().sorted(by: { $0.key > $1.key }), id: \.key) { month, transactions in
                        Section(header: Text(month)) {
                            ForEach(filteredTransactions(from: transactions)) { transaction in
                                TransactionRow(transaction: transaction)
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            transactionManager.deleteTransaction(withId: transaction.id)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                            
                            HStack {
                                Spacer()
                                VStack(alignment: .trailing) {
                                    Text("Income: \(formatCurrency(transactionManager.totalIncome(for: month)))")
                                        .foregroundColor(.green)
                                    Text("Expenses: \(formatCurrency(transactionManager.totalExpenses(for: month)))")
                                        .foregroundColor(.red)
                                    Text("Net: \(formatCurrency(transactionManager.netIncome(for: month)))")
                                        .fontWeight(.bold)
                                        .foregroundColor(transactionManager.netIncome(for: month) >= 0 ? .green : .red)
                                }
                            }
                            .padding(.top, 8)
                        }
                    }
                }
            }
        }
        .padding()
        .navigationTitle("Transactions")
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.commaSeparatedText],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let files):
                if let file = files.first {
                    selectedFile = file
                    transactionManager.loadTransactions(from: file)
                }
            case .failure(let error):
                print("Error selecting file: \(error.localizedDescription)")
            }
        }
        .alert("Delete All Transactions", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                transactionManager.deleteAllTransactions()
            }
        } message: {
            Text("Are you sure you want to delete all transactions? This action cannot be undone.")
        }
    }
    
    private func filteredTransactions(from transactions: [Transaction]) -> [Transaction] {
        if searchText.isEmpty {
            return transactions
        } else {
            return transactions.filter { transaction in
                transaction.payee.localizedCaseInsensitiveContains(searchText) ||
                transaction.category.localizedCaseInsensitiveContains(searchText) ||
                transaction.description.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "CAD"
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}

struct TransactionRow: View {
    let transaction: Transaction
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(transaction.payee)
                    .font(.headline)
                Text(transaction.category)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text(transaction.formattedAmount)
                    .font(.headline)
                    .foregroundColor(transaction.amount >= 0 ? .green : .red)
                Text(transaction.formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ErrorDetailsView: View {
    let error: Error
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Error Details")
                    .font(.headline)
                
                Text(error.localizedDescription)
                    .font(.body)
                
                if let csvError = error as? CSVError {
                    Text("CSV Error Type: \(String(describing: csvError))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if let transactionError = error as? TransactionError {
                    Text("Transaction Error Type: \(String(describing: transactionError))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Error Information")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 400, minHeight: 300)
    }
}

#Preview {
    TransactionsView()
} 