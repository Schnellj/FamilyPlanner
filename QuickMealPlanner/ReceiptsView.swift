import SwiftUI
import PhotosUI

struct Receipt: Identifiable {
    let id = UUID()
    let image: String // In a real app, this would be an actual image
    let date: Date
    let merchant: String
    let amount: Double
    let category: ReceiptCategory
    var notes: String
    var isAnalyzed: Bool
    var analyzedData: AnalyzedReceiptData?
}

struct AnalyzedReceiptData {
    var items: [AnalyzedItem]
    var totalAmount: Double
    var taxAmount: Double
    var tipAmount: Double
    var subtotal: Double
}

struct AnalyzedItem {
    var name: String
    var price: Double
    var quantity: Int
}

enum ReceiptCategory: String, CaseIterable, Identifiable {
    case groceries = "Groceries"
    case dining = "Dining"
    case retail = "Retail"
    case gas = "Gas"
    case utilities = "Utilities"
    case other = "Other"
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .groceries: return "cart"
        case .dining: return "fork.knife"
        case .retail: return "bag"
        case .gas: return "fuelpump"
        case .utilities: return "bolt"
        case .other: return "square"
        }
    }
}

struct ReceiptsView: View {
    @State private var receipts: [Receipt] = []
    @State private var selectedCategory: ReceiptCategory? = nil
    @State private var searchText = ""
    @State private var showingAddReceipt = false
    @State private var showingImagePicker = false
    @State private var selectedReceipt: Receipt? = nil
    @State private var showingReceiptDetail = false
    @State private var dateRange: DateRange = .allTime
    
    enum DateRange: String, CaseIterable, Identifiable {
        case lastWeek = "Last Week"
        case lastMonth = "Last Month"
        case last3Months = "Last 3 Months"
        case last6Months = "Last 6 Months"
        case lastYear = "Last Year"
        case allTime = "All Time"
        
        var id: String { self.rawValue }
    }
    
    var filteredReceipts: [Receipt] {
        var result = receipts
        
        // Filter by category
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            result = result.filter { 
                $0.merchant.localizedCaseInsensitiveContains(searchText) ||
                $0.notes.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Filter by date range
        let calendar = Calendar.current
        let now = Date()
        
        switch dateRange {
        case .lastWeek:
            let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: now)!
            result = result.filter { $0.date >= oneWeekAgo }
        case .lastMonth:
            let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: now)!
            result = result.filter { $0.date >= oneMonthAgo }
        case .last3Months:
            let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: now)!
            result = result.filter { $0.date >= threeMonthsAgo }
        case .last6Months:
            let sixMonthsAgo = calendar.date(byAdding: .month, value: -6, to: now)!
            result = result.filter { $0.date >= sixMonthsAgo }
        case .lastYear:
            let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: now)!
            result = result.filter { $0.date >= oneYearAgo }
        case .allTime:
            break
        }
        
        return result.sorted(by: { $0.date > $1.date })
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with stats
            HStack {
                VStack(alignment: .leading) {
                    Text("Receipts")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("\(filteredReceipts.count) receipts")
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    showingAddReceipt = true
                }) {
                    Label("Add Receipt", systemImage: "plus")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding()
            
            // Filters
            VStack(spacing: 12) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search receipts", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(8)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                
                // Category filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(ReceiptCategory.allCases) { category in
                            Button(action: {
                                if selectedCategory == category {
                                    selectedCategory = nil
                                } else {
                                    selectedCategory = category
                                }
                            }) {
                                HStack {
                                    Image(systemName: category.icon)
                                    Text(category.rawValue)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(selectedCategory == category ? Color.blue : Color(NSColor.controlBackgroundColor))
                                .foregroundColor(selectedCategory == category ? .white : .primary)
                                .cornerRadius(8)
                            }
                        }
                    }
                }
                
                // Date range picker
                Picker("Date Range", selection: $dateRange) {
                    ForEach(DateRange.allCases) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            .padding(.horizontal)
            .padding(.bottom)
            
            // Receipts list
            if filteredReceipts.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "doc.text.viewfinder")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    
                    Text("No receipts found")
                        .font(.headline)
                    
                    Text("Add your first receipt by tapping the 'Add Receipt' button")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button(action: {
                        showingAddReceipt = true
                    }) {
                        Text("Add Receipt")
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(NSColor.controlBackgroundColor))
            } else {
                List {
                    ForEach(filteredReceipts) { receipt in
                        ReceiptRow(receipt: receipt)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedReceipt = receipt
                                showingReceiptDetail = true
                            }
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .sheet(isPresented: $showingAddReceipt) {
            AddReceiptView(isPresented: $showingAddReceipt, onSave: { newReceipt in
                receipts.append(newReceipt)
            })
        }
        .sheet(isPresented: $showingReceiptDetail) {
            if let receipt = selectedReceipt {
                ReceiptDetailView(receipt: receipt)
            }
        }
        .onAppear {
            // Load sample data
            loadSampleData()
        }
    }
    
    private func loadSampleData() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        receipts = [
            Receipt(
                image: "receipt1",
                date: dateFormatter.date(from: "2023-05-15")!,
                merchant: "Walmart",
                amount: 125.42,
                category: .groceries,
                notes: "Weekly groceries",
                isAnalyzed: true,
                analyzedData: AnalyzedReceiptData(
                    items: [
                        AnalyzedItem(name: "Milk", price: 3.99, quantity: 1),
                        AnalyzedItem(name: "Bread", price: 2.49, quantity: 2),
                        AnalyzedItem(name: "Eggs", price: 4.99, quantity: 1)
                    ],
                    totalAmount: 125.42,
                    taxAmount: 8.75,
                    tipAmount: 0,
                    subtotal: 116.67
                )
            ),
            Receipt(
                image: "receipt2",
                date: dateFormatter.date(from: "2023-05-10")!,
                merchant: "Shell Gas Station",
                amount: 45.20,
                category: .gas,
                notes: "Fill up",
                isAnalyzed: false,
                analyzedData: nil
            ),
            Receipt(
                image: "receipt3",
                date: dateFormatter.date(from: "2023-05-05")!,
                merchant: "Target",
                amount: 78.33,
                category: .retail,
                notes: "Household items",
                isAnalyzed: true,
                analyzedData: AnalyzedReceiptData(
                    items: [
                        AnalyzedItem(name: "Paper Towels", price: 12.99, quantity: 1),
                        AnalyzedItem(name: "Laundry Detergent", price: 24.99, quantity: 1)
                    ],
                    totalAmount: 78.33,
                    taxAmount: 5.48,
                    tipAmount: 0,
                    subtotal: 72.85
                )
            )
        ]
    }
}

struct ReceiptRow: View {
    let receipt: Receipt
    
    var body: some View {
        HStack(spacing: 16) {
            // Receipt image placeholder
            ZStack {
                Rectangle()
                    .fill(Color(NSColor.controlBackgroundColor))
                    .frame(width: 60, height: 80)
                    .cornerRadius(8)
                
                Image(systemName: "doc.text")
                    .font(.system(size: 24))
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(receipt.merchant)
                    .font(.headline)
                
                Text(formatDate(receipt.date))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("$\(String(format: "%.2f", receipt.amount))")
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Label(receipt.category.rawValue, systemImage: receipt.category.icon)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(4)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct AddReceiptView: View {
    @Binding var isPresented: Bool
    let onSave: (Receipt) -> Void
    
    @State private var merchant = ""
    @State private var amount = ""
    @State private var category: ReceiptCategory = .other
    @State private var notes = ""
    @State private var date = Date()
    @State private var showingImagePicker = false
    @State private var selectedImage: String? = nil
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Receipt Image")) {
                    Button(action: {
                        showingImagePicker = true
                    }) {
                        HStack {
                            if let image = selectedImage {
                                Text("Image selected")
                            } else {
                                Text("Select Image")
                            }
                            Spacer()
                            Image(systemName: "photo")
                        }
                    }
                }
                
                Section(header: Text("Receipt Details")) {
                    TextField("Merchant", text: $merchant)
                    
                    TextField("Amount", text: $amount)
                        // macOS doesn't support keyboardType modifier
                    
                    Picker("Category", selection: $category) {
                        ForEach(ReceiptCategory.allCases) { category in
                            Label(category.rawValue, systemImage: category.icon)
                                .tag(category)
                        }
                    }
                    
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
                
                Section(header: Text("Notes")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Add Receipt")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveReceipt()
                    }
                    .disabled(merchant.isEmpty || amount.isEmpty)
                }
            }
        }
    }
    
    private func saveReceipt() {
        guard let amountValue = Double(amount) else { return }
        
        let newReceipt = Receipt(
            image: selectedImage ?? "default_receipt",
            date: date,
            merchant: merchant,
            amount: amountValue,
            category: category,
            notes: notes,
            isAnalyzed: false,
            analyzedData: nil
        )
        
        onSave(newReceipt)
        isPresented = false
    }
}

struct ReceiptDetailView: View {
    let receipt: Receipt
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Receipt image placeholder
                    ZStack {
                        Rectangle()
                            .fill(Color(NSColor.controlBackgroundColor))
                            .frame(height: 200)
                            .cornerRadius(12)
                        
                        Image(systemName: "doc.text")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    // Receipt details
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(receipt.merchant)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text(formatDate(receipt.date))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text("$\(String(format: "%.2f", receipt.amount))")
                                .font(.title)
                                .fontWeight(.bold)
                        }
                        
                        Divider()
                        
                        // Category
                        HStack {
                            Label("Category", systemImage: "tag")
                            Spacer()
                            Label(receipt.category.rawValue, systemImage: receipt.category.icon)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(4)
                        }
                        
                        // Notes
                        if !receipt.notes.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Notes")
                                    .font(.headline)
                                
                                Text(receipt.notes)
                                    .padding(8)
                                    .background(Color(NSColor.controlBackgroundColor))
                                    .cornerRadius(8)
                            }
                        }
                        
                        // Analyzed data
                        if receipt.isAnalyzed, let analyzedData = receipt.analyzedData {
                            Divider()
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Analyzed Data")
                                    .font(.headline)
                                
                                // Items
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Items")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    ForEach(analyzedData.items, id: \.name) { item in
                                        HStack {
                                            Text(item.name)
                                            Spacer()
                                            Text("\(item.quantity)x")
                                                .foregroundColor(.secondary)
                                            Text("$\(String(format: "%.2f", item.price))")
                                                .fontWeight(.medium)
                                        }
                                        .padding(.vertical, 4)
                                    }
                                }
                                
                                Divider()
                                
                                // Totals
                                VStack(spacing: 8) {
                                    HStack {
                                        Text("Subtotal")
                                        Spacer()
                                        Text("$\(String(format: "%.2f", analyzedData.subtotal))")
                                    }
                                    
                                    HStack {
                                        Text("Tax")
                                        Spacer()
                                        Text("$\(String(format: "%.2f", analyzedData.taxAmount))")
                                    }
                                    
                                    if analyzedData.tipAmount > 0 {
                                        HStack {
                                            Text("Tip")
                                            Spacer()
                                            Text("$\(String(format: "%.2f", analyzedData.tipAmount))")
                                        }
                                    }
                                    
                                    Divider()
                                    
                                    HStack {
                                        Text("Total")
                                            .fontWeight(.bold)
                                        Spacer()
                                        Text("$\(String(format: "%.2f", analyzedData.totalAmount))")
                                            .fontWeight(.bold)
                                    }
                                }
                            }
                            .padding()
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(12)
                        } else {
                            Button(action: {
                                // This would trigger AI analysis in a real app
                            }) {
                                HStack {
                                    Image(systemName: "wand.and.stars")
                                    Text("Analyze Receipt")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Receipt Details")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct ReceiptsView_Previews: PreviewProvider {
    static var previews: some View {
        ReceiptsView()
    }
} 