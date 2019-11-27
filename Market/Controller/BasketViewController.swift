//
//  BasketViewController.swift
//  Market
//
//  Created by Sara Sipione on 23/11/2019.
//  Copyright © 2019 Sara Sipione. All rights reserved.
//

import UIKit
import JGProgressHUD
import Stripe

class BasketViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var basketTotalPriceLabel: UILabel!
    @IBOutlet weak var totalItemsLabel: UILabel!
    @IBOutlet weak var checkOutButtonOutlet: UIButton!
    
    var basket: Basket?
    var allItems: [Item] = []
    var purchasedItemIds: [String] = []
    var totalPrice = 0
    let hud = JGProgressHUD(style: .dark)
    
//    var environment: String = PayPalEnvironmentNoNetwork {
//        willSet (newEnvironment) {
//            if (newEnvironment != environment) {
//                PayPalMobile.preconnect(withEnvironment: newEnvironment)
//            }
//        }
//    }
//    var payPalConfig = PayPalConfiguration()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = footerView
        //setUpPayPal()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if MUser.currentUser() != nil {
            loadBasketFromFirestore()
        } else {
            self.updateTotalLabels(true)
        }
    }
    
    @IBAction func checkOutButtonPressed(_ sender: Any) {
        if MUser.currentUser()!.onBoard {
            showPaymentOptions()
        } else {
            self.showNotification(text: "Please complete your profile!", isError: true)
        }
    }
    
    //MARK: - Download basket
    
    private func loadBasketFromFirestore() {
        downloadBasketFromFirestore(MUser.currentId()) { (basket) in
            self.basket = basket
            self.getBasketItems()
        }
    }
    
    private func getBasketItems() {
        if basket != nil {
            downloadItems(basket!.itemIds) { (allItems) in
                self.allItems = allItems
                self.updateTotalLabels(false)
                self.tableView.reloadData()
            }
        }
    }
    
    //MARK: - Helper functions
    
    private func updateTotalLabels(_ isEmpty: Bool) {
        if isEmpty {
            totalItemsLabel.text = "0"
            basketTotalPriceLabel.text = returnBasketTotalPrice()
        } else {
            totalItemsLabel.text = "\(allItems.count)"
            basketTotalPriceLabel.text = returnBasketTotalPrice()
        }
        checkOutButtonStatusUpdate()
    }
    
    private func returnBasketTotalPrice() -> String {
        var totalPrice = 0.0
        for item in allItems {
            totalPrice += item.price
        }
        return "Total price: " + convertToCurrency(totalPrice)
    }
    
    private func emptyTheBasket() {
        purchasedItemIds.removeAll()
        allItems.removeAll()
        tableView.reloadData()
        basket!.itemIds = []
        updateBasketInFirestore(basket!, withValues: [kITEMIDS: basket!.itemIds as Any]) { (error) in
            if error != nil {
                print("error updating basket:", error!.localizedDescription)
            }
            self.getBasketItems()
        }
    }
    
    private func addItemsToPurchaseHistory(_ itemsIds: [String]) {
        if MUser.currentUser() != nil {
            let newitemIds = MUser.currentUser()!.purchasedItemIds + itemsIds
            updateCurrentUserInFirestore(withValues: [kPURCHASEDITEMIDS : newitemIds]) { (error) in
                if error != nil {
                    print("error adding items:", error!.localizedDescription)
                }
            }
        }
    }
    
    //MARK: - Navigation
    
    private func showItemView(withItem: Item) {
        let itemVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(identifier: "itemView") as! ItemViewController
        itemVC.item = withItem
        self.navigationController?.pushViewController(itemVC, animated: true)
    }
    
    //MARK: - Control CheckOutButton
    
    private func checkOutButtonStatusUpdate() {
        checkOutButtonOutlet.isEnabled = allItems.count > 0
        if checkOutButtonOutlet.isEnabled {
            checkOutButtonOutlet.backgroundColor = #colorLiteral(red: 1, green: 0.4123216998, blue: 0.3912938784, alpha: 1)
        } else {
            disableCheckOutButton()
        }
    }
    
    private func disableCheckOutButton() {
        checkOutButtonOutlet.isEnabled = false
        checkOutButtonOutlet.backgroundColor = #colorLiteral(red: 0.6666666865, green: 0.6666666865, blue: 0.6666666865, alpha: 1)
    }
    
    private func removeItemFromBasket(itemId: String) {
        for i in 0..<basket!.itemIds.count {
            if itemId == basket!.itemIds[i] {
                basket?.itemIds.remove(at: i)
                return
            }
        }
    }
    
    //MARK: - Stripe payment
    
    private func finishPayment(token: STPToken) {
        self.totalPrice = 0
        for item in allItems {
            purchasedItemIds.append(item.id)
            self.totalPrice += Int(item.price)
        }
        self.totalPrice = self.totalPrice * 100
        StripeClient.sharedClient.createAndConfirmPayment(token, amount: totalPrice) { (error) in
            if error == nil {
                self.emptyTheBasket()
                self.addItemsToPurchaseHistory(self.purchasedItemIds)
                self.showNotification(text: "Payment Successfull", isError: false)
            } else {
                self.showNotification(text: error!.localizedDescription, isError: true)
                print("error:", error!.localizedDescription)
            }
        }
    }
    
    private func showNotification(text: String, isError: Bool) {
        if isError {
            self.hud.indicatorView = JGProgressHUDErrorIndicatorView()
        } else {
            self.hud.indicatorView = JGProgressHUDSuccessIndicatorView()
        }
        self.hud.textLabel.text = text
        self.hud.show(in: self.view)
        self.hud.dismiss(afterDelay: 2.0)
    }
    
    private func showPaymentOptions() {
        let alertController = UIAlertController(title: "Payment Options", message: "Choose prefered payment option", preferredStyle: .actionSheet)
        let cardAction = UIAlertAction(title: "Pay with card", style: .default) { (action) in
            let vc = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(identifier: "cardInfoVC") as! CardInfoViewController
            vc.delegate = self
            self.present(vc, animated: true, completion: nil)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cardAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    //MARK: - PayPal
    
//    private func setUpPayPal() {
//        payPalConfig.acceptCreditCards = false
//        payPalConfig.merchantName = "iOS Market"
//        payPalConfig.merchantPrivacyPolicyURL = URL(string: "https://www.paypal.com/webapps/mpp/ua/privacy-full")
//        payPalConfig.merchantUserAgreementURL = URL(string: "https://www.paypal.com/webapps/mpp/ua/useragreement-full")
//
//        payPalConfig.languageOrLocale = Locale.preferredLanguages[0]
//        payPalConfig.payPalShippingAddressOption = .both
//    }
//
//    private func payButtonPressed() {
//        var itemsToBuy : [PayPalItem] = []
//
//        for item in allItems {
//            let tempItem = PayPalItem(name: item.name, withQuantity: 1, withPrice: NSDecimalNumber(value: item.price), withCurrency: "GBP", withSku: nil)
//            purchasedItemIds.append(item.id)
//            itemsToBuy.append(tempItem)
//        }
//        let subTotal = PayPalItem.totalPrice(forItems: itemsToBuy)
//
//        //optional
//        let shippingCost = NSDecimalNumber(string: "50.0")
//        let tax = NSDecimalNumber(string: "5.0")
//
//        let paymentDetails = PayPalPaymentDetails(subtotal: subTotal, withShipping: shippingCost, withTax: tax)
//        let total = subTotal.adding(shippingCost).adding(tax)
//        let payment = PayPalPayment(amount: total, currencyCode: "GBP", shortDescription: "Payment to iOS Market", intent: .sale)
//
//        payment.items = itemsToBuy
//        payment.paymentDetails = paymentDetails
//
//        if payment.processable {
//            let paymentViewController = PayPalPaymentViewController(payment: payment, configuration: payPalConfig, delegate: self)
//            present(paymentViewController!, animated: true, completion: nil)
//        } else {
//            print("Payment not processable")
//        }
//    }
    
}

extension BasketViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! ItemTableViewCell
        cell.generateCell(allItems[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let itemToDelete = allItems[indexPath.row]
            allItems.remove(at: indexPath.row)
            tableView.reloadData()
            
            removeItemFromBasket(itemId: itemToDelete.id)
            updateBasketInFirestore(basket!, withValues: [kITEMIDS : basket?.itemIds as Any]) { (error) in
                if error != nil {
                    print("error updating the basket", error!.localizedDescription)
                }
                self.getBasketItems()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        showItemView(withItem: allItems[indexPath.row])
    }
}

extension BasketViewController: PayPalPaymentDelegate {
    
    func payPalPaymentDidCancel(_ paymentViewController: PayPalPaymentViewController) {
        print("paypal payment cancelled")
        paymentViewController.dismiss(animated: true, completion: nil)
    }
    
    func payPalPaymentViewController(_ paymentViewController: PayPalPaymentViewController, didComplete completedPayment: PayPalPayment) {
        paymentViewController.dismiss(animated: true) {
            self.addItemsToPurchaseHistory(self.purchasedItemIds)
            self.emptyTheBasket()
        }
    }
}

extension BasketViewController: CardInfoViewControllerDelegate {
    
    func didClickDone(_ token: STPToken) {
        print("we have a token", token)
        finishPayment(token: token)
    }
    
    func didClickCancel() {
        print("user cancelled the payment")
        showNotification(text: "Payment Cancelled", isError: true)
    }
}
