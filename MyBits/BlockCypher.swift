import Foundation

struct BlockCypher {

    static func loadTransactions(forAddress: BitcoinAddress) {
        let url = NSURL(string: "https://api.blockcypher.com/v1/btc/main/addrs/\(forAddress.value)/full")
        let session = NSURLSession.sharedSession()

        if let url = url {
            let task = session.dataTaskWithURL(url) { (data, response, error) -> Void in
                if let error = error {
                    NSLog("Error while loading transaction for address \(forAddress.value): \(error.description).")
                    return
                } else if let data = data {
                    do {
                        if let jsonData = try NSJSONSerialization.JSONObjectWithData(data, options:NSJSONReadingOptions.MutableContainers) as? NSDictionary {
                            if let txsJson = jsonData["txs"] as? [NSDictionary] {
                                for txJson in txsJson {
                                    let tx: BitcoinTx = BitcoinTx.loadFromJson(txJson)
                                    TransactionStore.addTransaction(tx)
                                }
                            }
                        }
                    } catch let error as NSError {
                        NSLog("Error while parsing transactions for address \(forAddress.value): \(error.description). Received: \(String(data: data, encoding: NSUTF8StringEncoding)).")
                    }
                } else {
                    NSLog("No data or error received.")
                }
            }
            task.resume()
        } else {
            NSLog("Couldn't build url for address \(forAddress.value).")
        }
    }

}