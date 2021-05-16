//
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import CoreData

public final class CoreDataFeedStore: FeedStore {
	private static let modelName = "FeedStore"
	private static let model = NSManagedObjectModel(name: modelName, in: Bundle(for: CoreDataFeedStore.self))

	private let container: NSPersistentContainer
	private let context: NSManagedObjectContext

	struct ModelNotFound: Error {
		let modelName: String
	}

	public init(storeURL: URL) throws {
		guard let model = CoreDataFeedStore.model else {
			throw ModelNotFound(modelName: CoreDataFeedStore.modelName)
		}

		container = try NSPersistentContainer.load(
			name: CoreDataFeedStore.modelName,
			model: model,
			url: storeURL
		)
		context = container.newBackgroundContext()
	}

	public func retrieve(completion: @escaping RetrievalCompletion) {
		let localContext = context
		localContext.perform {
			let request = NSFetchRequest<ManagedCache>(entityName: ManagedCache.entity().name!)
			request.returnsObjectsAsFaults = false
			if let cache = try! localContext.fetch(request).first {
				let localFeed = cache.feed.compactMap { ($0 as? ManagedFeedImage)?.local }
				completion(.found(feed: localFeed, timestamp: cache.timestamp))
			} else {
				completion(.empty)
			}
		}
	}

	public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
		let localContext = context
		localContext.perform {
			let cache = ManagedCache(context: localContext)
			cache.feed = ManagedFeedImage.images(from: feed, in: localContext)
			cache.timestamp = timestamp
			try! localContext.save()
			completion(nil)
		}
	}

	public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
		fatalError("Must be implemented")
	}
}

@objc(ManagedCache)
class ManagedCache: NSManagedObject {
	@NSManaged var timestamp: Date
	@NSManaged var feed: NSOrderedSet
}

@objc(ManagedFeedImage)
class ManagedFeedImage: NSManagedObject {
	@NSManaged var id: UUID
	@NSManaged var imageDescription: String?
	@NSManaged var location: String?
	@NSManaged var url: URL
	@NSManaged var cache: ManagedCache

	static func images(from localFeed: [LocalFeedImage],
	                   in context: NSManagedObjectContext) -> NSOrderedSet {
		NSOrderedSet(array: localFeed.map { local in
			let managed = ManagedFeedImage(context: context)
			managed.id = local.id
			managed.imageDescription = local.description
			managed.location = local.location
			managed.url = local.url
			return managed
		})
	}

	var local: LocalFeedImage {
		LocalFeedImage(id: id,
		               description: imageDescription,
		               location: location,
		               url: url)
	}
}
