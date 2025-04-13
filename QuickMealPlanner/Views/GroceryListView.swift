import SwiftUI

struct GroceryListView: View {
    @ObservedObject var groceryListManager: GroceryListManager
    @State private var showingRecipeSources = false
    
    var body: some View {
        VStack {
            if groceryListManager.currentList.items.isEmpty {
                VStack {
                    Text("No items in your grocery list")
                        .font(.headline)
                        .foregroundColor(.gray)
                    Text("Generate a list from your meal plan")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding()
            } else {
                List {
                    ForEach(groceryListManager.currentList.items) { item in
                        HStack {
                            Button(action: {
                                groceryListManager.toggleItemChecked(item)
                            }) {
                                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(item.isChecked ? .green : .gray)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.name.capitalized)
                                    .strikethrough(item.isChecked)
                                    .font(.body)
                                    .fontWeight(.medium)
                                
                                if !item.quantity.isEmpty {
                                    Text(item.quantity)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                
                                if !item.recipeNames.isEmpty {
                                    Text("From: \(item.recipeNames.joined(separator: ", "))")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(PlainListStyle())
                
                HStack {
                    Button(action: {
                        groceryListManager.clearCheckedItems()
                    }) {
                        Text("Clear Checked Items")
                    }
                    .disabled(groceryListManager.currentList.items.filter { $0.isChecked }.isEmpty)
                    
                    Spacer()
                    
                    Text("\(groceryListManager.currentList.items.count) items")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding()
            }
        }
    }
} 