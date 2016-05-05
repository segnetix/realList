//
//  IAPHelper.swift
//  EnList
//
//  Created by Steven Gentry on 4/14/16.
//  Copyright © 2016 Steven Gentry. All rights reserved.
//

import StoreKit

public typealias ProductIdentifier = String
public typealias ProductsRequestCompletionHandler = (success: Bool, products: [SKProduct]?) -> ()

public class IAPHelper : NSObject
{
    let productIdentifiers: Set<ProductIdentifier>
    var purchasedProductIdentifiers = Set<ProductIdentifier>()
    var productsRequest: SKProductsRequest?
    var productsRequestCompletionHandler: ProductsRequestCompletionHandler?
    
    static let IAPHelperPurchaseNotification = "IAPHelperPurchaseNotification"
    static let IAPHelperRestoreNotification  = "IAPHelperRestoreNotification"
    static let IAPHelperFailedTransaction    = "IAPHelperFailedTransaction"
    
    public init(productIds: Set<ProductIdentifier>)
    {
        self.productIdentifiers = productIds
        
        for productIdentifier in productIds
        {
            let purchased = NSUserDefaults.standardUserDefaults().boolForKey(productIdentifier)
            
            if purchased {
                purchasedProductIdentifiers.insert(productIdentifier)
                print("Previously purchased: \(productIdentifier)")
            } else {
                print("Not purchased: \(productIdentifier)")
            }
        }
        
        super.init()
        
        SKPaymentQueue.defaultQueue().addTransactionObserver(self)
    }
}

// MARK: - StoreKit API

extension IAPHelper
{
    public func requestProducts(completionHandler: ProductsRequestCompletionHandler)
    {
        productsRequest?.cancel()
        productsRequestCompletionHandler = completionHandler
        
        productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
        productsRequest!.delegate = self
        productsRequest!.start()
    }
    
    public func buyProduct(product: SKProduct)
    {
        print("Buying \(product.productIdentifier)...")
        let payment = SKPayment(product: product)
        SKPaymentQueue.defaultQueue().addPayment(payment)
    }
    
    public func isProductPurchased(productIdentifier: ProductIdentifier) -> Bool {
        return purchasedProductIdentifiers.contains(productIdentifier)
    }
    
    public class func canMakePayments() -> Bool
    {
        return SKPaymentQueue.canMakePayments()
    }
    
    public func restorePurchases()
    {
        SKPaymentQueue.defaultQueue().restoreCompletedTransactions()
    }
}


// MARK: - SKProductsRequestDelegate
extension IAPHelper: SKProductsRequestDelegate
{
    public func productsRequest(request: SKProductsRequest, didReceiveResponse response: SKProductsResponse) {
        print("Loaded list of products...")
        let products = response.products
        productsRequestCompletionHandler?(success: true, products: products)
        clearRequestAndHandler()
        
        for p in products {
            print("Found product: \(p.productIdentifier) \(p.localizedTitle) \(p.price.floatValue)")
        }
    }
    
    public func request(request: SKRequest, didFailWithError error: NSError) {
        print("Failed to load list of products.")
        print("IAPHelper - request - Error: \(error.localizedDescription)")
        productsRequestCompletionHandler?(success: false, products: nil)
        clearRequestAndHandler()
    }
    
    private func clearRequestAndHandler() {
        productsRequest = nil
        productsRequestCompletionHandler = nil
    }
}

// MARK: - SKPaymentTransactionObserver
extension IAPHelper: SKPaymentTransactionObserver
{
    public func paymentQueue(queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch (transaction.transactionState) {
            case .Purchased:
                completeTransaction(transaction)
                break
            case .Failed:
                failedTransaction(transaction)
                break
            case .Restored:
                restoreTransaction(transaction)
                break
            case .Deferred:
                break
            case .Purchasing:
                break
            }
        }
    }
    
    private func completeTransaction(transaction: SKPaymentTransaction)
    {
        print("completeTransaction...")
        deliverPurchaseNotificationForIdentifier(transaction.payment.productIdentifier)
        SKPaymentQueue.defaultQueue().finishTransaction(transaction)
        NSNotificationCenter.defaultCenter().postNotificationName(IAPHelper.IAPHelperPurchaseNotification, object: transaction.payment.productIdentifier)
    }
    
    private func restoreTransaction(transaction: SKPaymentTransaction)
    {
        guard let productIdentifier = transaction.originalTransaction?.payment.productIdentifier else { return }
        
        print("restoreTransaction... \(productIdentifier)")
        deliverPurchaseNotificationForIdentifier(productIdentifier)
        SKPaymentQueue.defaultQueue().finishTransaction(transaction)
        NSNotificationCenter.defaultCenter().postNotificationName(IAPHelper.IAPHelperRestoreNotification, object: transaction.payment.productIdentifier)
    }
    
    private func failedTransaction(transaction: SKPaymentTransaction)
    {
        print("failedTransaction...")
        if transaction.error!.code != SKErrorCode.PaymentCancelled.rawValue {
            print("Transaction Error: \(transaction.error?.localizedDescription)")
            NSNotificationCenter.defaultCenter().postNotificationName(IAPHelper.IAPHelperFailedTransaction, object: transaction.error?.localizedDescription)
        }
        
        SKPaymentQueue.defaultQueue().finishTransaction(transaction)
    }
    
    private func deliverPurchaseNotificationForIdentifier(identifier: String?)
    {
        guard let identifier = identifier else { return }
        
        purchasedProductIdentifiers.insert(identifier)
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: identifier)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
}
