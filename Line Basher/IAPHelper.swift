/*
* Copyright (c) 2016 Razeware LLC
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
*/

import StoreKit

public typealias ProductIdentifier = String
public typealias ProductsRequestCompletionHandler = (_ success: Bool, _ products: [SKProduct]?) -> ()

open class IAPHelper : NSObject
{
    var listOfProducts: [SKProduct] = []
  static let IAPHelperPurchaseNotification = "IAPHelperPurchaseNotification"
  static let IAPHelperPurchaseFailed = "IAPHelperPurchaseFailed"
  fileprivate let productIdentifiers: Set<ProductIdentifier>
  fileprivate var purchasedProductIdentifiers = Set<ProductIdentifier>()
  fileprivate var productsRequest: SKProductsRequest?
  fileprivate var productsRequestCompletionHandler: ProductsRequestCompletionHandler?

  public init(productIds: Set<ProductIdentifier>)
  {
    productIdentifiers = productIds
    for productIdentifier in productIds
    {
      let purchased = UserDefaults.standard.bool(forKey: productIdentifier)
      if purchased
      {
        purchasedProductIdentifiers.insert(productIdentifier)
        print("Previously purchased: \(productIdentifier)")
        if productIdentifier.hasSuffix("FullVersion")
        {
            fullVersionPurchased = true               ///Should be true for release of final product. False is used only for debug.
        }
      } else
      {
        //FIXME: This should be set to false if doing InApp purchase.
        fullVersionPurchased = true
        print("Not purchased: \(productIdentifier)")
      }
    }
    super.init()
    SKPaymentQueue.default().add(self)
  }
}

// MARK: - StoreKit API

extension IAPHelper
{

  public func requestProducts(completionHandler: @escaping ProductsRequestCompletionHandler)
  {
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

  public func isProductPurchased(_ productIdentifier: ProductIdentifier) -> Bool
  {
    return purchasedProductIdentifiers.contains(productIdentifier)
  }
  
  public class func canMakePayments() -> Bool
  {
    return SKPaymentQueue.canMakePayments()
  }
  
  public func restorePurchases()
  {
    SKPaymentQueue.default().restoreCompletedTransactions()
  }
}

// MARK: - SKProductsRequestDelegate

extension IAPHelper: SKProductsRequestDelegate {

  public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
    let products = response.products
    print("Loaded list of products...")
    productsRequestCompletionHandler?(true, products)
    clearRequestAndHandler()

    for p in products {
      print("Found product: \(p.productIdentifier) \(p.localizedTitle) \(p.price.floatValue)")
    }
    listOfProducts = products
  }
  
  public func request(_ request: SKRequest, didFailWithError error: Error) {
    print("Failed to load list of products.")
    print("Error: \(error.localizedDescription)")
    productsRequestCompletionHandler?(false, nil)
    clearRequestAndHandler()
  }

  private func clearRequestAndHandler() {
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
        print ("paymentQueue .purchased")
        complete(transaction: transaction)
        break
      case .failed:
        print ("paymentQueue .failed")
        fail(transaction: transaction)
        break
      case .restored:
        print ("paymentQueue .restored")
        restore(transaction: transaction)
        break
      case .deferred:
        print ("paymentQueue .deferred")
        break
      case .purchasing:
        print ("paymentQueue .purchasing")
        break
      @unknown default:
        break
      }
    }
  }
 
  private func complete(transaction: SKPaymentTransaction)
  {
    print("complete...")
    deliverPurchaseNotificationFor(identifier: transaction.payment.productIdentifier)
    SKPaymentQueue.default().finishTransaction(transaction)
    
    ///if transaction.payment.productIdentifier.hasSuffix("FullVersion")
    ///{
    fullVersionPurchased = true
    ///}
  }
 
  private func restore(transaction: SKPaymentTransaction) {
    guard let productIdentifier = transaction.original?.payment.productIdentifier else { return }
 
    fullVersionPurchased = true
    print("restore... \(productIdentifier)")
    deliverPurchaseNotificationFor(identifier: productIdentifier)
    SKPaymentQueue.default().finishTransaction(transaction)
  }
 
  private func fail(transaction: SKPaymentTransaction)
  {
    print("fail...")
    if let transactionError = transaction.error as NSError? {
      if transactionError.code != SKError.Code.paymentCancelled.rawValue {
        print("Transaction Error: \(transaction.error?.localizedDescription ?? dbObj.stringErrorString)")
      }
    }
    NotificationCenter.default.post(name: NSNotification.Name(rawValue: IAPHelper.IAPHelperPurchaseFailed), object: nil)

    SKPaymentQueue.default().finishTransaction(transaction)
  }
 
  private func deliverPurchaseNotificationFor(identifier: String?) {
    guard let identifier = identifier else { return }
 
    purchasedProductIdentifiers.insert(identifier)
    UserDefaults.standard.set(true, forKey: identifier)
    UserDefaults.standard.synchronize()
    NotificationCenter.default.post(name: NSNotification.Name(rawValue: IAPHelper.IAPHelperPurchaseNotification), object: identifier)
  }
}
