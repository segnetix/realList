//
//  IAPHelper.swift
//  EnList
//
//  Created by Steven Gentry on 4/14/16.
//  Copyright © 2016 Steven Gentry. All rights reserved.
//

import StoreKit

public typealias ProductIdentifier = String
public typealias ProductsRequestCompletionHandler = (_ success: Bool, _ products: [SKProduct]?) -> ()

open class IAPHelper : NSObject {
    let productIdentifiers: Set<ProductIdentifier>
    var purchasedProductIdentifiers = Set<ProductIdentifier>()
    var productsRequest: SKProductsRequest?
    var productsRequestCompletionHandler: ProductsRequestCompletionHandler?
    
    static let IAPHelperPurchaseNotification = "IAPHelperPurchaseNotification"
    static let IAPHelperRestoreNotification  = "IAPHelperRestoreNotification"
    static let IAPHelperFailedTransaction    = "IAPHelperFailedTransaction"
    
    public init(productIds: Set<ProductIdentifier>) {
        self.productIdentifiers = productIds
        
        for productIdentifier in productIds
        {
            let purchased = UserDefaults.standard.bool(forKey: productIdentifier)
            
            if purchased {
                purchasedProductIdentifiers.insert(productIdentifier)
                print("Previously purchased: \(productIdentifier)")
            } else {
                print("Not purchased: \(productIdentifier)")
            }
        }
        
        super.init()
        
        SKPaymentQueue.default().add(self)
    }
}

// MARK: - StoreKit API

extension IAPHelper {
    public func requestProducts(_ completionHandler: @escaping ProductsRequestCompletionHandler) {
        productsRequest?.cancel()
        productsRequestCompletionHandler = completionHandler
        
        productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
        productsRequest!.delegate = self
        productsRequest!.start()
    }
    
    public func buyProduct(_ product: SKProduct)
    {
        print("Buying \(product.productIdentifier)...")
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    public func isProductPurchased(_ productIdentifier: ProductIdentifier) -> Bool {
        return purchasedProductIdentifiers.contains(productIdentifier)
    }
    
    public class func canMakePayments() -> Bool {
        return SKPaymentQueue.canMakePayments()
    }
    
    public func restorePurchases() {
        // original code
        SKPaymentQueue.default().restoreCompletedTransactions()
        
        // suggestion
        //SKPaymentQueue.default().restoreCompletedTransactions()
        //SKPaymentQueue.default().add(self)
    }
}


// MARK: - SKProductsRequestDelegate
extension IAPHelper: SKProductsRequestDelegate {
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        print("Loaded list of products...")
        let products = response.products
        productsRequestCompletionHandler?(true, products)
        clearRequestAndHandler()
        
        for p in products {
            print("Found product: \(p.productIdentifier) \(p.localizedTitle) \(p.price.floatValue)")
        }
    }
    
    public func request(_ request: SKRequest, didFailWithError error: Error) {
        print("Failed to load list of products.")
        print("IAPHelper - request - Error: \(error.localizedDescription)")
        productsRequestCompletionHandler?(false, nil)
        clearRequestAndHandler()
    }
    
    fileprivate func clearRequestAndHandler() {
        productsRequest = nil
        productsRequestCompletionHandler = nil
    }
}

// MARK: - SKPaymentTransactionObserver
extension IAPHelper: SKPaymentTransactionObserver {
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch (transaction.transactionState) {
            case .purchased:
                completeTransaction(transaction)
                break
            case .failed:
                failedTransaction(transaction)
                break
            case .restored:
                restoreTransaction(transaction)
                break
            case .deferred:
                break
            case .purchasing:
                break
            @unknown default:
                break
            }
        }
    }
    
    fileprivate func completeTransaction(_ transaction: SKPaymentTransaction) {
        print("completeTransaction...")
        deliverPurchaseNotificationForIdentifier(transaction.payment.productIdentifier)
        SKPaymentQueue.default().finishTransaction(transaction)
        NotificationCenter.default.post(name: Notification.Name(rawValue: IAPHelper.IAPHelperPurchaseNotification), object: transaction.payment.productIdentifier)
    }
    
    fileprivate func restoreTransaction(_ transaction: SKPaymentTransaction) {
        guard let productIdentifier = transaction.original?.payment.productIdentifier else { return }
        
        print("restoreTransaction... \(productIdentifier)")
        deliverPurchaseNotificationForIdentifier(productIdentifier)
        SKPaymentQueue.default().finishTransaction(transaction)
        NotificationCenter.default.post(name: Notification.Name(rawValue: IAPHelper.IAPHelperRestoreNotification), object: transaction.payment.productIdentifier)
    }
    
    fileprivate func failedTransaction(_ transaction: SKPaymentTransaction) {
        print("failedTransaction...")
        if transaction.error!._code != SKError.paymentCancelled.rawValue {
            print("Transaction Error: \(String(describing: transaction.error?.localizedDescription))")
            NotificationCenter.default.post(name: Notification.Name(rawValue: IAPHelper.IAPHelperFailedTransaction), object: transaction.error?.localizedDescription)
        }
        
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    fileprivate func deliverPurchaseNotificationForIdentifier(_ identifier: String?) {
        guard let identifier = identifier else { return }
        
        purchasedProductIdentifiers.insert(identifier)
        UserDefaults.standard.set(true, forKey: identifier)
        UserDefaults.standard.synchronize()
    }
}
