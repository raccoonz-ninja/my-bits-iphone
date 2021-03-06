
class TxIO: CustomStringConvertible {
    var amount: BitcoinAmount
    var address: BitcoinAddress

    init(amount: BitcoinAmount, address: BitcoinAddress) {
        self.amount = amount
        self.address = address
    }

    func copy() -> TxIO {
        if let txIO = self as? AccountAddressTxIO {
            return AccountAddressTxIO(account: txIO.account.copy(), accountAddress: txIO.accountAddress.copy(), amount: txIO.amount.copy())
        } else if let txIO = self as? AccountXpubTxIO {
            return AccountXpubTxIO(account: txIO.account.copy(), accountXpub: txIO.accountXpub.copy(), address: txIO.address.copy(), amount: txIO.amount.copy())
        } else if let txIO = self as? ExternalAddressTxIO {
            return ExternalAddressTxIO(amount: txIO.amount.copy(), address: txIO.address.copy())
        } else  {
            return TxIO(amount: self.amount.copy(), address: self.address.copy())
        }
    }

    var description: String {
        get {
            if let txIO = self as? AccountAddressTxIO {
                return "AccountAddressTxIO:\n" +
                "  Amount: \(txIO.amount.description)\n" +
                "  Address: \(txIO.address.description)\n" +
                "  Account: \(txIO.account.getName())"
            } else if let txIO = self as? AccountXpubTxIO {
                return "AccountXpubTxIO:\n" +
                "  Amount: \(txIO.amount.description)\n" +
                "  Address: \(txIO.address.description)\n" +
                "  Account: \(txIO.account.getName())\n" +
                "  Xpub: \(txIO.accountXpub.getMasterPublicKey())"
            } else if let txIO = self as? ExternalAddressTxIO {
                return "ExternalAddressTxIO:\n" +
                "  Amount: \(txIO.amount.description)\n" +
                "  Address: \(txIO.address.description)"
            } else  {
                return "TxIO:\n" +
                "  Amount: \(self.amount.description)\n" +
                "  Address: \(self.address.description)"
            }
        }
    }
}

class ExternalAddressTxIO: TxIO {}

class AccountAddressTxIO: TxIO {
    private let account: Account
    private let accountAddress: AccountAddress

    init(account: Account, accountAddress: AccountAddress, amount: BitcoinAmount) {
        self.account = account
        self.accountAddress = accountAddress
        super.init(amount: amount, address: accountAddress.getBitcoinAddress())
    }

    func getAccount() -> Account {
        return self.account
    }
    func getAccountAddress() -> AccountAddress {
        return self.accountAddress
    }
}

class AccountXpubTxIO: TxIO {
    private let account: Account
    private let accountXpub: AccountXpub

    init(account: Account, accountXpub: AccountXpub, address: BitcoinAddress, amount: BitcoinAmount) {
        self.account = account
        self.accountXpub = accountXpub
        super.init(amount: amount, address: address)
    }

    func getAccount() -> Account {
        return self.account
    }
    func getAccountXpub() -> AccountXpub {
        return self.accountXpub
    }
}
