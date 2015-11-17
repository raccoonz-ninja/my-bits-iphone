import Foundation
import UIKit

class TransactionsListViewController: UIViewController, PrivacyProtocol {

    var testButton: UIButton?

    var testBalanceContainer: UIView?
    var testBalancePrefixLabel: UILabel?
    var testBalanceLabel: UICurrencyLabel?
    var testBalanceSuffixLabel: UILabel?
    var testBalanceLabel2: UICurrencyLabel?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navBarCustomization()
        self.createComponents()
        self.layoutComponents()
    }

    override func viewWillAppear(animated: Bool) {
        PrivacyManager.register(self)
        self.configureComponents()
    }

    override func viewDidDisappear(animated: Bool) {
        PrivacyManager.unregister(self)
    }

    func privacyDidChange() {
        dispatch_async(dispatch_get_main_queue()) {
            self.configureComponents()
        }
    }

    func onHideCurrencyButtonTap() {
        PrivacyManager.setPrivacy(!PrivacyManager.getPrivacy())
    }


    func navBarCustomization() {
        // Left item (Privacy)
        let icon = UIImage(named: "TopBar_Privacy.png")
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: icon, landscapeImagePhone: icon, style: .Plain, target: self, action: "onHideCurrencyButtonTap")
        self.navigationItem.leftBarButtonItem?.tintColor = PrivacyManager.getPrivacy() ? UIColor.redColor() : UIColor.blackColor()

        // Right item (Bitcoin price)
        let label = UICurrencyLabel(frame: CGRectMake(0, 0, 100, 20), fromBitcoin: 1.0, displayCurrency: .Fiat)
        label.setRespectPrivacy(false)
        label.textAlignment = .Right
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: label)
    }

    func createComponents() {
        let bitcoinBalance = 3.14
        self.testBalanceContainer = UIView(frame: CGRectMake(0, 0, 100, 20))
        self.testButton = UIButton(type: UIButtonType.RoundedRect)
        self.testBalancePrefixLabel = UILabel()
        self.testBalanceLabel = UICurrencyLabel(frame: CGRectMake(0, 0, 100, 20), fromBitcoin: bitcoinBalance,
            displayCurrency: .Bitcoin)
        self.testBalanceSuffixLabel = UILabel()
        self.testBalanceLabel2 = UICurrencyLabel(frame: CGRectMake(0, 0, 100, 20), fromBitcoin: bitcoinBalance,
            displayCurrency: .Fiat)
        self.testBalanceContainer!.addSubview(self.testBalancePrefixLabel!);
        self.testBalanceContainer!.addSubview(self.testBalanceLabel!);
        self.testBalanceContainer!.addSubview(self.testBalanceSuffixLabel!);
        self.testBalanceContainer!.addSubview(self.testBalanceLabel2!);
        self.view.addSubview(self.testBalanceContainer!);
        self.view.addSubview(self.testButton!);
    }

    func configureComponents() {
        let text = "Privacy " + (PrivacyManager.getPrivacy() ? "On" : "Off")
        self.testButton?.setTitle(text, forState: UIControlState.Normal)
        self.testButton?.layer.borderColor = self.testButton?.titleColorForState(UIControlState.Normal)?.CGColor
        self.testButton?.layer.borderWidth = 1.0
        self.testButton?.layer.cornerRadius = 4.0

        let TEST_BALANCE_LABELS = [self.testBalancePrefixLabel!,
            self.testBalanceLabel!,
            self.testBalanceSuffixLabel!,
            self.testBalanceLabel2!]
        for label in TEST_BALANCE_LABELS {
            label.font = UIFont(name: label.font.familyName, size: 16)
        }

        self.testBalancePrefixLabel?.text = "Balance: "
        self.testBalanceSuffixLabel?.text = " = "

        self.view.backgroundColor = UIColor.whiteColor()
    }

    func layoutComponents() {
        var constraints:[NSLayoutConstraint] = []

        // Position button (centered in the page)
        constraints.append(NSLayoutConstraint(
            item: self.testButton!, attribute: .CenterX,
            relatedBy: .Equal,
            toItem: self.view, attribute: .CenterX,
            multiplier: 1.0, constant: 0.0))
        constraints.append(NSLayoutConstraint(
            item: self.testButton!, attribute: .CenterY,
            relatedBy: .Equal,
            toItem: self.view, attribute: .CenterY,
            multiplier: 1.0, constant: 0.0))
        constraints.append(NSLayoutConstraint(
            item: self.testButton!, attribute: .Width,
            relatedBy: .Equal,
            toItem: nil, attribute: .Width,
            multiplier: 1.0, constant: 150))
        constraints.append(NSLayoutConstraint(
            item: self.testButton!, attribute: .Height,
            relatedBy: .Equal,
            toItem: nil, attribute: .Height,
            multiplier: 1.0, constant: 50))
        self.testButton?.translatesAutoresizingMaskIntoConstraints = false

        // Position the labels in their container
        let TEST_BALANCE_LABELS = [self.testBalancePrefixLabel!,
                                   self.testBalanceLabel!,
                                   self.testBalanceSuffixLabel!,
                                   self.testBalanceLabel2!]
        for index in 0...TEST_BALANCE_LABELS.count - 1 {
            let label = TEST_BALANCE_LABELS[index]
            label.translatesAutoresizingMaskIntoConstraints = false
            // Center label in container (vertically)
            constraints.append(NSLayoutConstraint(
                item: label, attribute: .CenterY,
                relatedBy: .Equal,
                toItem: self.testBalanceContainer, attribute: .CenterY,
                multiplier: 1.0, constant: 0.0))

            if index > 0 {
                // Align the labels in sequence
                constraints.append(NSLayoutConstraint(
                    item: label, attribute: .Left,
                    relatedBy: .Equal,
                    toItem: TEST_BALANCE_LABELS[index - 1], attribute: .Right,
                    multiplier: 1.0, constant: 0.0))
            } else {
                // First label at the far left
                constraints.append(NSLayoutConstraint(
                    item: label, attribute: .Left,
                    relatedBy: .Equal,
                    toItem: testBalanceContainer, attribute: .Left,
                    multiplier: 1.0, constant: 0.0))
            }
        }
        constraints.append(NSLayoutConstraint(
            item: self.testBalanceContainer!, attribute: .Right,
            relatedBy: .Equal,
            toItem: TEST_BALANCE_LABELS.last!, attribute: .Right,
            multiplier: 1.0, constant: 0.0))

        // Place the labels container under the button with the right height
        self.testBalanceContainer!.translatesAutoresizingMaskIntoConstraints = false
        constraints.append(NSLayoutConstraint(
            item: self.testBalanceContainer!, attribute: .Top,
            relatedBy: .Equal,
            toItem: self.testButton, attribute: .Bottom,
            multiplier: 1.0, constant: 10.0))
        constraints.append(NSLayoutConstraint(
            item: self.testBalanceContainer!, attribute: .Height,
            relatedBy: .Equal,
            toItem: nil, attribute: .Height,
            multiplier: 1.0, constant: 100.0))

        // Center the labels container
        constraints.append(NSLayoutConstraint(
            item: self.testBalanceContainer!, attribute: .CenterX,
            relatedBy: .Equal,
            toItem: self.view, attribute: .CenterX,
            multiplier: 1.0, constant: 0.0))

        NSLayoutConstraint.activateConstraints(constraints)
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

