//
//  ManagedFeedImage.swift
//  FeedStoreChallenge
//
//  Created by Abdul Diallo on 5/17/21.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import CoreData
import Foundation

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
