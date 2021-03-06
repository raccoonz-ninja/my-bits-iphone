import Foundation

enum AccountStoreException: ErrorType {
    case AddressAlreadyInAccount, XpubAlreadyInAccount
}

protocol AccountProtocol: class {

    func accountReceivedNewAddress(account: Account, newAccountAddress: AccountAddress)
    func accountReceivedNewXpub(account: Account, newAccountXpub: AccountXpub)

}

protocol BitcoinAddressProtocol : class {
    func bitcoinAddressUpdate(bitcoinAddress: BitcoinAddress)
}

class AccountStore {

    private static var accountDelegates = [AccountId: [AccountProtocol]]()
    private static var accounts = [Account]()
    private static var bitcoinAddressProtocols = [BitcoinAddressProtocol]()

    static func initialize() throws {
        // Accounts
        let accounts = DB.getAccounts()
        AccountStore.accounts = accounts

        // Public addresses
        for account in accounts {
            for address in DB.getBitcoinAddresses(account) {
                try AccountStore.addAddress(account, accountAddress: AccountAddress(bitcoinAddress: address), saveToDisk: false)
            }
        }

        // Master Public Keys
        for account in accounts {
            for mpk in DB.getMasterPublicKeys(account) {
                let accountXpub = AccountXpub(masterPublicKey: mpk, addresses: DB.getBitcoinAddresses(mpk), generateAddresses: false)
                try AccountStore.addXpub(account, accountXpub: accountXpub, saveToDisk: false)
            }
        }
    }

    static func register(delegate: AccountProtocol, forAccount: Account) {
        if var delegatesForAccount = AccountStore.accountDelegates[forAccount.accountId] {
            delegatesForAccount.append(delegate)
        } else {
            AccountStore.accountDelegates[forAccount.accountId] = [delegate]
        }
    }

    static func unregister(delegate: AccountProtocol) {
        for (accountId, delegates) in AccountStore.accountDelegates {
            AccountStore.accountDelegates[accountId] = delegates.filter({ d in
                return d !== delegate
            })
        }
    }

    static func registerBitcoinAddressProtocol(bitcoinAddressProtocol: BitcoinAddressProtocol) {
        self.bitcoinAddressProtocols.append(bitcoinAddressProtocol)
    }

    static func unregisterBitcoinAddressProtocol(bitcoinAddressProtocol: BitcoinAddressProtocol) {
        for (index, p) in self.bitcoinAddressProtocols.enumerate() {
            if p === bitcoinAddressProtocol {
                self.bitcoinAddressProtocols.removeAtIndex(index)
                break
            }
        }
    }

    static func broadcastBitcoinAddressUpdate(bitcoinAddress: BitcoinAddress) {
        for p in self.bitcoinAddressProtocols {
            p.bitcoinAddressUpdate(bitcoinAddress)
        }
    }

    static func getAccounts() -> [Account] {
        return AccountStore.accounts
    }

    static func addAccount(account: Account) throws {
        if !AccountStore.accounts.contains({ acct in return acct.accountId == account.accountId }) {
            try DB.insertAccount(account)
            AccountStore.accounts.append(account)
        }
    }

    // TODO - throw AddressAlreadyInXpub
    static func addAddress(account: Account, accountAddress: AccountAddress, saveToDisk: Bool = true) throws {
        try account.addAddress(accountAddress)
        if saveToDisk {
            try DB.insertBitcoinAddress(accountAddress.getBitcoinAddress(), account: account)
        }
        AddressManager.rebuildAddressPool()
        if let delegates = AccountStore.accountDelegates[account.getId()] {
            for delegate in delegates {
                delegate.accountReceivedNewAddress(account, newAccountAddress: accountAddress)
            }
        }
    }

    static func addXpub(account: Account, accountXpub: AccountXpub, saveToDisk: Bool = true) throws {
        try account.addXpub(accountXpub)
        if saveToDisk {
            try DB.insertMasterPublicKey(accountXpub.getMasterPublicKey(), account: account)
        }
        AddressManager.rebuildAddressPool()
        if let delegates = AccountStore.accountDelegates[account.getId()] {
            for delegate in delegates {
                delegate.accountReceivedNewXpub(account, newAccountXpub: accountXpub)
            }
        }
    }

}


// Models

class AccountId: GenericId {}

class Account: Hashable {

    private var accountId: AccountId
    private var accountName: String
    private var accountCreationTimestamp: Int64
    private var accountAddresses: [AccountAddress]
    private var accountXpubs: [AccountXpub]

    init(accountId: AccountId, accountName: String, accountCreationTimestamp: Int64) {
        self.accountId = accountId
        self.accountName = accountName
        self.accountAddresses = [AccountAddress]()
        self.accountXpubs = [AccountXpub]()
        self.accountCreationTimestamp = accountCreationTimestamp
    }

    convenience init(accountName: String) {
        self.init(accountId: AccountId(), accountName: accountName, accountCreationTimestamp: Int64(NSDate().timeIntervalSince1970))
    }

    internal func addAddress(accountAddress: AccountAddress) throws {
        if self.accountAddresses.contains({ address in return address.getBitcoinAddress() == accountAddress.getBitcoinAddress() }) {
            throw AccountStoreException.AddressAlreadyInAccount
        }
        self.accountAddresses.append(accountAddress)
    }

    internal func addXpub(accountXpub: AccountXpub) throws {
        if self.accountXpubs.contains(accountXpub) {
            throw AccountStoreException.XpubAlreadyInAccount
        }
        self.accountXpubs.append(accountXpub)
    }

    func getId() -> AccountId {
        return self.accountId
    }

    func getName() -> String {
        return self.accountName
    }

    func getCreationTimestamp() -> Int64 {
        return self.accountCreationTimestamp
    }

    func getAddresses() -> [AccountAddress] {
        return self.accountAddresses
    }

    func getXpubs() -> [AccountXpub] {
        return self.accountXpubs
    }

    func getBalance() -> BitcoinAmount {
        var balance = BitcoinAmount(satoshis: 0)
        for address in self.accountAddresses {
            balance = balance + address.getBalance()
        }
        for xpub in self.accountXpubs {
            balance = balance + xpub.getBalance()
        }
        return balance
    }

    var hashValue: Int {
        get {
            return self.getId().hashValue
        }
    }

    func copy() -> Account {
        let account = Account(accountId: self.accountId, accountName: self.accountName, accountCreationTimestamp: self.accountCreationTimestamp)
        account.accountAddresses = self.accountAddresses
        account.accountXpubs = self.accountXpubs
        return account
    }

    func getAllBitcoinAddresses() -> [BitcoinAddress] {
        var res = [BitcoinAddress]()
        for address in accountAddresses {
            res.append(address.getBitcoinAddress())
        }
        for xpub in accountXpubs {
            res.appendContentsOf(xpub.getAddresses())
        }
        return res
    }

}

func ==(left: Account, right: Account) -> Bool {
    return left.getId() == right.getId()
}
