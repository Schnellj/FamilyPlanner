import Foundation
import CoreData

class CoreDataManager {
    static let shared = CoreDataManager()
    
    private init() {}
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "TransactionModel")
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Unable to load persistent stores: \(error)")
            }
        }
        return container
    }()
    
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func saveContext() {
        if viewContext.hasChanges {
            do {
                try viewContext.save()
            } catch {
                let error = error as NSError
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
    }
    
    // MARK: - Transaction Operations
    
    func saveTransaction(_ transaction: Transaction, importSource: String) {
        let entity = TransactionEntity(context: viewContext)
        entity.id = transaction.id
        entity.date = transaction.date
        entity.payee = transaction.payee
        entity.amount = transaction.amount
        entity.category = transaction.category
        entity.transactionDescription = transaction.description
        entity.account = transaction.account
        entity.categoryGroup = transaction.categoryGroup
        entity.importDate = Date()
        entity.importSource = importSource
        
        saveContext()
    }
    
    func saveTransactions(_ transactions: [Transaction], importSource: String) {
        for transaction in transactions {
            saveTransaction(transaction, importSource: importSource)
        }
    }
    
    func fetchTransactions(from startDate: Date?) -> [Transaction] {
        let fetchRequest: NSFetchRequest<TransactionEntity> = TransactionEntity.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \TransactionEntity.date, ascending: false)]
        
        if let startDate = startDate {
            fetchRequest.predicate = NSPredicate(format: "date >= %@", startDate as NSDate)
        }
        
        do {
            let entities = try viewContext.fetch(fetchRequest)
            return entities.map { entity in
                Transaction(
                    id: entity.id ?? UUID(),
                    date: entity.date ?? Date(),
                    payee: entity.payee ?? "",
                    amount: entity.amount,
                    category: entity.category ?? "",
                    description: entity.transactionDescription ?? "",
                    account: entity.account ?? "",
                    categoryGroup: entity.categoryGroup ?? ""
                )
            }
        } catch {
            print("Error fetching transactions: \(error)")
            return []
        }
    }
    
    func fetchAllTransactions() -> [Transaction] {
        return fetchTransactions(from: nil)
    }
    
    func fetchTransactionsByMonth() -> [String: [Transaction]] {
        let transactions = fetchAllTransactions()
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
    
    func deleteAllTransactions() {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "TransactionEntity")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try persistentContainer.persistentStoreCoordinator.execute(deleteRequest, with: viewContext)
            saveContext()
        } catch {
            print("Error deleting all transactions: \(error)")
        }
    }
    
    func deleteTransaction(withId id: UUID) {
        let fetchRequest: NSFetchRequest<TransactionEntity> = TransactionEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            let entities = try viewContext.fetch(fetchRequest)
            for entity in entities {
                viewContext.delete(entity)
            }
            saveContext()
        } catch {
            print("Error deleting transaction: \(error)")
        }
    }
} 