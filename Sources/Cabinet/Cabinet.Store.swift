//
//  Cabinet.Store.swift
//  
//
//  Created by Ben Gottlieb on 7/16/20.
//

import Foundation
import CoreData
import Combine
import Suite

extension Cabinet {
	public class Store {
		private var container: NSPersistentContainer
		
		private var isLoaded = CurrentValueSubject<Bool, Never>(false)
		
		public var viewContext: AnyPublisher<NSManagedObjectContext, Never> {
			isLoaded
				.map { _ in self.container.viewContext }
				
				.eraseToAnyPublisher()
		}

		public var importContext: AnyPublisher<NSManagedObjectContext, Never> {
			isLoaded
				.map { _ in self.container.newBackgroundContext() }
				
				.eraseToAnyPublisher()
		}

		public func files(matching: NSPredicate = NSPredicate(value: true)) -> AnyPublisher<[File], Never> {
			let request = NSFetchRequest<File>(entityName: "File")
			request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

			return self.viewContext
				.flatMap() { ctx in
					ctx.publisher(for: request)
				}
				.eraseToAnyPublisher()
		}
		
		init() {
			let url = Bundle.module.url(forResource: "Cabinet", withExtension: "momd")!
			container = NSPersistentContainer(name: "Cabinet", managedObjectModel: NSManagedObjectModel(contentsOf: url)!)
			
			container.loadPersistentStores { stores, err in
				if let error = err {
					print("Error loading Cabinet: \(error)")
				} else {
					self.container.viewContext.registerForExternalChangeUpdates()
					self.isLoaded.value = true
				}
			}
		}
	}
}
