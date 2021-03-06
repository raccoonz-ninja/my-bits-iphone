import UIKit

class AccountsViewController : UITableViewController, AllTransactionsProtocol, BitcoinAddressProtocol {

    convenience init() {
        self.init(style: .Grouped)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = NSLocalizedString("accounts", comment: "")
        self.tableView.tableHeaderView = UIView(frame: CGRectMake(0, 0, 0, CGFloat.min))
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)

        TransactionStore.unregister(self)
        TransactionStore.register(self)

        AccountStore.unregisterBitcoinAddressProtocol(self)
        AccountStore.registerBitcoinAddressProtocol(self)
        self.tableView.reloadData()
    }

    func transactionReceived(tx: BitcoinTx) {
        dispatch_async(dispatch_get_main_queue()) {
            self.tableView.reloadData()
        }
    }

    func bitcoinAddressUpdate(bitcoinAddress: BitcoinAddress) {
        dispatch_async(dispatch_get_main_queue()) {
            self.tableView.reloadData()
        }
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return AccountStore.getAccounts().count
        }
        return 1
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 80
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // Special cell for adding new accounts
        if indexPath.section == 1 {
            var cell = tableView.dequeueReusableCellWithIdentifier("CreateAccountCell")
            if (cell == nil) {
                cell = UITableViewCell(style: .Subtitle, reuseIdentifier: "CreateAccountCell")
                cell!.accessoryType = .DisclosureIndicator
            }
            cell!.textLabel?.text = NSLocalizedString("create new account", comment: "")
            cell!.detailTextLabel?.text = NSLocalizedString("create new account description", comment: "")
            return cell!;
        }

        // Account cell
        var cell = tableView.dequeueReusableCellWithIdentifier("AccountCell")
        if (cell == nil) {
            cell = UITableViewCell(style: .Subtitle, reuseIdentifier: "AccountCell")
            cell!.accessoryType = .DisclosureIndicator
        }

        // Name
        let account = AccountStore.getAccounts()[indexPath.row];
        cell!.textLabel?.text = account.getName()

        // Last Update
        var lastUpdate: Int64?
        for address in account.getAllBitcoinAddresses() {
            if let updateTimestamp = address.updateTimestamp {
                if lastUpdate == nil {
                    lastUpdate = updateTimestamp
                } else if lastUpdate > updateTimestamp {
                    lastUpdate = updateTimestamp
                }
            } else {
                lastUpdate = nil
                break
            }
        }
        var lastUpdateString: String
        if lastUpdate == nil {
            lastUpdateString = NSLocalizedString("account never synchronized", comment: "")
        } else {
            lastUpdateString = NSDate(timeIntervalSince1970: NSTimeInterval(lastUpdate!)).description
        }
        cell!.detailTextLabel?.text = lastUpdateString

        // Amount
        cell!.viewWithTag(1)?.removeFromSuperview()
        let currencyView = UICurrencyLabel(fromBtcAmount: account.getBalance())
        currencyView.textAlignment = .Right
        currencyView.frame = CGRectMake(0, 0, self.tableView.frame.size.width - 40, 80)
        currencyView.tag = 1
        cell!.addSubview(currencyView)

        return cell!
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        var nextViewController: UIViewController
        if indexPath.section == 1 {
            nextViewController = NewAccountViewController()
        } else {
            nextViewController = TransactionTableViewController(accounts: [AccountStore.getAccounts()[indexPath.row]])
        }
        self.navigationController?.pushViewController(nextViewController, animated: true)
    }

}