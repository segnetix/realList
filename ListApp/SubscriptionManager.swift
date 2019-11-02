//
//  SubscriptionManager.swift
//  EnList
//
//  Created by Steven Gentry on 11/2/19.
//  Copyright © 2019 Steven Gentry. All rights reserved.
//

import Foundation
import CloudKit

class SubscriptionManager {
    private static let appDelegate = UIApplication.shared.delegate as! AppDelegate
    private static let key_subscribedToPrivateData = "subscribedToPrivateData"
    
    private static let listSubID: CKSubscription.ID = "ListSubscription"
    private static let categorySubID: CKSubscription.ID = "CategorySubscription"
    private static let itemSubID: CKSubscription.ID = "ItemSubscription"
    private static let imageSubID: CKSubscription.ID = "ImageSubscription"
    private static let deleteSubID: CKSubscription.ID = "DeleteSubscription"

    typealias SubscriptionInfo = (recordType: String, subscriptionId: String)

    /// Creates a clean set of subscriptions on the iCloud server for the user.
    static func manageSubscriptions() {
        guard !UserDefaults.standard.bool(forKey: key_subscribedToPrivateData) else { return }
        guard let database = appDelegate.privateDatabase else { return }
        
        // fetch any current subscriptions
        var deleteSubscriptionIDs = [String]()
        database.fetchAllSubscriptions { subscriptions, error in
            if let subscriptions = subscriptions {
                deleteSubscriptionIDs = subscriptions.map { $0.subscriptionID }
            } else {
                print("**** subscription fetch error: \(error.debugDescription)")
            }
        }
        
        // delete any current subscriptions
        var deleteOperation: CKModifySubscriptionsOperation?
        if !deleteSubscriptionIDs.isEmpty {
            deleteOperation = deleteSubscriptionOperation(subscriptionIds: deleteSubscriptionIDs)
            
            deleteOperation?.modifySubscriptionsCompletionBlock = { (subscriptions, deletedIds, error) in
                if error == nil, let subscriptions = subscriptions {
                    print("**** subscriptions deleted count: \(subscriptions.count)")
                } else {
                    print("**** subscription delete error: \(error.debugDescription)")
                }
            }
            
            if let deleteOperation = deleteOperation {
                database.add(deleteOperation)
            }
        }

        // create new subscriptions
        var subscriptions = [CKQuerySubscription]()
        subscriptions.append(createSubscription(with: SubscriptionInfo(ListsRecordType, listSubID)))
        subscriptions.append(createSubscription(with: SubscriptionInfo(CategoriesRecordType, categorySubID)))
        subscriptions.append(createSubscription(with: SubscriptionInfo(ItemsRecordType, itemSubID)))
        subscriptions.append(createSubscription(with: SubscriptionInfo(ImagesRecordType, imageSubID)))
        subscriptions.append(createSubscription(with: SubscriptionInfo(DeletesRecordType, deleteSubID)))
        
        let createOperation = CKModifySubscriptionsOperation(subscriptionsToSave: subscriptions, subscriptionIDsToDelete: nil)
        createOperation.modifySubscriptionsCompletionBlock = { (subscriptions, deletedIds, error) in
            if error == nil {
                // update the flag to note that we are subscribed
                UserDefaults.standard.set(true, forKey: key_subscribedToPrivateData)
            } else {
                print("**** subscription add error: \(error.debugDescription)")
            }
        }
        
        // set QoS and dependency
        createOperation.qualityOfService = .utility
        if let deleteOperation = deleteOperation {
            createOperation.addDependency(deleteOperation)
        }
        
        database.add(createOperation)
    }
    
    private static func deleteSubscriptionOperation(subscriptionIds: [String]) -> CKModifySubscriptionsOperation {
        let operation = CKModifySubscriptionsOperation(subscriptionsToSave: [], subscriptionIDsToDelete: subscriptionIds)
        operation.qualityOfService = .utility
        return operation
    }
    
    private static func createSubscription(with subscriptionInfo: SubscriptionInfo) -> CKQuerySubscription {
        let predicate = NSPredicate(format: "TRUEPREDICATE")
        
        let info = CKSubscription.NotificationInfo()
        info.shouldSendContentAvailable = true
        
        let options = CKQuerySubscription.Options(arrayLiteral: CKQuerySubscription.Options.firesOnRecordCreation,
                                                                CKQuerySubscription.Options.firesOnRecordUpdate,
                                                                CKQuerySubscription.Options.firesOnRecordDeletion)
        
        let subscription = CKQuerySubscription(recordType: subscriptionInfo.recordType, predicate: predicate, subscriptionID: subscriptionInfo.subscriptionId, options: options)
        subscription.notificationInfo = info
        
        return subscription
    }
}

