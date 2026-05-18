import CoreData
import Foundation

final class CoreDataStack {
    static let modelName = "MemoryInk"

    let container: NSPersistentContainer

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(
            name: Self.modelName,
            managedObjectModel: Self.makeManagedObjectModel()
        )

        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [description]
        }

        container.loadPersistentStores { _, error in
            if let error {
                assertionFailure("Core Data store failed to load: \(error.localizedDescription)")
            }
        }

        viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        viewContext.automaticallyMergesChangesFromParent = true
    }

    private static func makeManagedObjectModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        let entity = NSEntityDescription()
        entity.name = "JournalEntryObject"
        entity.managedObjectClassName = NSStringFromClass(JournalEntryObject.self)

        entity.properties = [
            attribute("id", type: .UUIDAttributeType, isOptional: false),
            attribute("createdAt", type: .dateAttributeType, isOptional: false),
            attribute("photoPath", type: .stringAttributeType, isOptional: false),
            attribute("thumbnailPath", type: .stringAttributeType, isOptional: false),
            attribute("mediumPreviewPath", type: .stringAttributeType, isOptional: false),
            attribute("rawNote", type: .stringAttributeType, isOptional: true),
            attribute("voicePath", type: .stringAttributeType, isOptional: true),
            attribute("aiNarrative", type: .stringAttributeType, isOptional: true),
            attribute("moodRawValue", type: .stringAttributeType, isOptional: false),
            attribute("narrativeStyleRawValue", type: .stringAttributeType, isOptional: false),
            attribute("syncStatusRawValue", type: .stringAttributeType, isOptional: false),
            attribute("aiGenerationDate", type: .dateAttributeType, isOptional: true),
            attribute("isFavorite", type: .booleanAttributeType, isOptional: false)
        ]

        model.entities = [entity]
        return model
    }

    private static func attribute(
        _ name: String,
        type: NSAttributeType,
        isOptional: Bool
    ) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = type
        attribute.isOptional = isOptional
        return attribute
    }
}
