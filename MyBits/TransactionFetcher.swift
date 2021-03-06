import Foundation
import ReachabilitySwift

class TransactionFetcher {

    private static let REFRESH_DELAY = 30.0 // In seconds
    private static let REQUEST_DELAY = 0.1 // In seconds
    private static let DEBUG = true

    private static var addressesQueue = [BitcoinAddress]()
    private static let lockQueue = dispatch_queue_create("TransactionFetcherLockQueue", nil)
    private static let backgroundQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
    private static var readyForRefresh = false
    private static var waitingForConnection = false

    static func queueAddressesForAccount(account: Account) {
        let addresses = account.getAllBitcoinAddresses()
        log("Fetching \(addresses.count) bitcoin addresses from cache")
        for address in addresses {
            BlockCypher.loadTransactionsFromCache(address, transactionsCallback: { transactions in
                for tx in transactions {
                    TransactionStore.addTransaction(tx)
                }
            })
        }
        log("Queuing \(addresses.count) bitcoin addresses")
        dispatch_sync(lockQueue) {
            addressesQueue.appendContentsOf(addresses)
            if (!readyForRefresh && !addressesQueue.isEmpty) {
                readyForRefresh = true
            }
        }
        delayRunQueue(REQUEST_DELAY)
    }

    private static func delayRunQueue(delay: Double) {
        var emptyQueue = false
        dispatch_sync(lockQueue) {
            emptyQueue = addressesQueue.isEmpty
        }
        if emptyQueue {
            if readyForRefresh {
                log("Planning refresh in \(REFRESH_DELAY) seconds")
                delayFunc(REFRESH_DELAY) {
                    for account in AccountStore.getAccounts() {
                        queueAddressesForAccount(account)
                    }
                }
            }
        } else {
            delayFunc(delay, runQueue)
        }
    }

    private static func runQueue() {
        var addressOpt: BitcoinAddress?
        dispatch_sync(lockQueue) {
            if !addressesQueue.isEmpty {
                addressOpt = addressesQueue.removeFirst()
            }
        }
        guard let address = addressOpt else {
            return
        }
        log("Fetching bitcoin address \(address)")
        BlockCypher.loadTransactions(address, transactionsCallback: { transactions in
            log("Received bitcoin address \(address)")
            for tx in transactions {
                TransactionStore.addTransaction(tx)
            }
            address.updateTimestamp = Int64(NSDate().timeIntervalSince1970)
            AccountStore.broadcastBitcoinAddressUpdate(address)
            try! DB.bitcoinAddressUpdate(address)
            delayRunQueue(REQUEST_DELAY)
        }) { error in
            log("Error with bitcoin address \(address)")
            dispatch_sync(lockQueue) {
                addressesQueue.append(address)
            }
            if InternetService.hasConnection() {
                delayRunQueue(REQUEST_DELAY * 2)
            } else if !waitingForConnection {
                waitingForConnection = true
                NSNotificationCenter.defaultCenter().addObserverForName(ReachabilityChangedNotification, object: nil, queue: NSOperationQueue.mainQueue()) { notification in
                    waitingForConnection = false
                    delayRunQueue(REQUEST_DELAY)
                }
            }
        }
    }

    private static func delayFunc(delay: Double, _ closure: () -> ()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ), backgroundQueue, closure)
    }

    private static func log(message: String) {
        if DEBUG {
            NSLog("[TransactionFetcher] \(message)")
        }
    }

}