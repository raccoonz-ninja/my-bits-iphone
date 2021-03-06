import Alamofire
import Haneke

enum BlockCypherError : ErrorType {
    case RequestFailed
}

class BlockCypher {

    private static let TRANSACTIONS_KEY = "txs"
    private static let ERROR_KEY = "error"

    private static let cache = Cache<JSON>(name: "blockcypher")

    static func loadTransactions(forAddress: BitcoinAddress, transactionsCallback: [BitcoinTx] -> Void, errorCallback: BlockCypherError -> Void) {
        let url = "https://api.blockcypher.com/v1/btc/main/addrs/\(forAddress.value)/full"
        Alamofire.request(.GET, url).responseJSON { response in
            if let json = response.result.value as? NSDictionary {
                if json[ERROR_KEY] != nil {
                    errorCallback(BlockCypherError.RequestFailed)
                    return
                }
                var transactions = [BitcoinTx]()
                if let txsJson = json[TRANSACTIONS_KEY] as? [NSDictionary] {
                    cache.set(value: JSON.Array(txsJson), key: forAddress.value)
                    for txJson in txsJson {
                        transactions.append(BitcoinTx.loadFromJson(txJson))
                    }
                }
                transactionsCallback(transactions)
            } else {
                errorCallback(BlockCypherError.RequestFailed)
            }
        }
    }

    static func loadTransactionsFromCache(forAddress: BitcoinAddress, transactionsCallback: [BitcoinTx] -> Void) {
        cache.fetch(key: forAddress.value).onSuccess { json in
            var transactions = [BitcoinTx]()
            if let txsJson = json.array as? [NSDictionary] {
                for txJson in txsJson {
                    transactions.append(BitcoinTx.loadFromJson(txJson))
                }
            }
            transactionsCallback(transactions)
        }
    }

}