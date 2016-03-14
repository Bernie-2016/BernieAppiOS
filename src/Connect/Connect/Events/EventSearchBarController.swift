import UIKit

class EventSearchBarController: UIViewController {
    private let nearbyEventsUseCase: NearbyEventsUseCase
    private let eventsNearAddressUseCase: EventsNearAddressUseCase
    private let resultQueue: NSOperationQueue
    private let zipCodeValidator: ZipCodeValidator
    private let theme: Theme

    let searchBar = UISearchBar.newAutoLayoutView()
    let cancelButton = UIButton.newAutoLayoutView()
    let searchButton = UIButton.newAutoLayoutView()

    private var preEditPlaceholder: String?

    private var searchButtonSearchBarConstraint: NSLayoutConstraint!
    private var cancelButtonSearchBarConstraint: NSLayoutConstraint!
    private var textFieldHeightConstraint: NSLayoutConstraint!

    init(
        nearbyEventsUseCase: NearbyEventsUseCase,
        eventsNearAddressUseCase: EventsNearAddressUseCase,
        resultQueue: NSOperationQueue,
        zipCodeValidator: ZipCodeValidator,
        theme: Theme) {
            self.nearbyEventsUseCase = nearbyEventsUseCase
            self.eventsNearAddressUseCase = eventsNearAddressUseCase
            self.resultQueue = resultQueue
            self.zipCodeValidator = zipCodeValidator
            self.theme = theme

            super.init(nibName: nil, bundle: nil)

            nearbyEventsUseCase.addObserver(self)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        view.addSubview(searchBar)
        view.addSubview(cancelButton)
        view.addSubview(searchButton)

        searchBar.searchBarStyle = .Minimal
        searchBar.delegate = self
        searchBar.keyboardType = .NumberPad
        searchBar.accessibilityLabel = NSLocalizedString("EventsSearchBar_searchBarAccessibilityLabel", comment: "")

        cancelButton.addTarget(self, action: "didTapCancelButton", forControlEvents: .TouchUpInside)
        cancelButton.setTitle(NSLocalizedString("EventsSearchBar_cancelButtonTitle", comment: ""), forState: .Normal)
        cancelButton.hidden = true

        searchButton.addTarget(self, action: "didTapSearchButton", forControlEvents: .TouchUpInside)
        searchButton.setTitle(NSLocalizedString("EventsSearchBar_searchButtonTitle", comment: ""), forState: .Normal)
        searchButton.enabled = false
        searchButton.hidden = true

        setupConstraints()
        applyTheme()
    }

    private func setupConstraints() {
        let buttonWidth: CGFloat = 60
        let verticalShift: CGFloat = 8
        let horizontalPadding: CGFloat = 15
        let searchBarHeight: CGFloat = 34

        cancelButton.autoPinEdgeToSuperviewEdge(.Left, withInset: horizontalPadding)
        cancelButton.autoAlignAxis(.Horizontal, toSameAxisOfView: searchBar, withOffset: verticalShift)
        cancelButton.autoSetDimension(.Width, toSize: buttonWidth)

        searchButton.autoPinEdgeToSuperviewEdge(.Right, withInset: horizontalPadding)
        searchButton.autoAlignAxis(.Horizontal, toSameAxisOfView: searchBar, withOffset: verticalShift)
        searchButton.autoSetDimension(.Width, toSize: buttonWidth)

        searchBar.autoCenterInSuperview()

        NSLayoutConstraint.autoSetPriority(800) {
            self.searchBar.autoPinEdgeToSuperviewEdge(.Left, withInset: -horizontalPadding)
            self.searchBar.autoPinEdgeToSuperviewEdge(.Right, withInset: -horizontalPadding)
        }

        NSLayoutConstraint.autoSetPriority(900) {
            self.searchButtonSearchBarConstraint = self.searchButton.autoPinEdge(.Left, toEdge: .Right, ofView: self.searchBar, withOffset: -horizontalPadding)
        }
        self.searchButtonSearchBarConstraint.active = false

        NSLayoutConstraint.autoSetPriority(900) {
            self.cancelButtonSearchBarConstraint = self.cancelButton.autoPinEdge(.Right, toEdge: .Left, ofView: self.searchBar, withOffset: -horizontalPadding)
        }
        self.cancelButtonSearchBarConstraint.active = false

        if let searchBarContainer = searchBar.subviews.first {
                searchBarContainer.autoAlignAxis(.Horizontal, toSameAxisOfView: self.searchBar, withOffset: verticalShift)
                searchBarContainer.autoPinEdgeToSuperviewEdge(.Left, withInset: horizontalPadding)
                searchBarContainer.autoPinEdgeToSuperviewEdge(.Right, withInset: horizontalPadding)
                searchBarContainer.autoSetDimension(.Height, toSize: searchBarHeight)
        }
        if let textField = searchBar.valueForKey("searchField") as? UITextField {
                textField.autoAlignAxis(.Horizontal, toSameAxisOfView: self.searchBar, withOffset: verticalShift)
                textField.autoPinEdgeToSuperviewEdge(.Left, withInset: horizontalPadding)
                textField.autoPinEdgeToSuperviewEdge(.Right, withInset: horizontalPadding)

                self.textFieldHeightConstraint = textField.autoSetDimension(.Height, toSize: searchBarHeight)
        }

        if let background = searchBar.valueForKey("background") as? UIView {
                background.autoAlignAxis(.Horizontal, toSameAxisOfView: self.searchBar, withOffset: verticalShift)
                background.autoPinEdgeToSuperviewEdge(.Left)
                background.autoPinEdgeToSuperviewEdge(.Right)
                background.autoSetDimension(.Height, toSize: searchBarHeight)
        }
    }

    private func applyTheme() {
        view.backgroundColor = theme.eventsSearchBarBackgroundColor()

        searchButton.setTitleColor(theme.defaultButtonDisabledTextColor(), forState: .Disabled)
        searchButton.setTitleColor(theme.navigationBarButtonTextColor(), forState: .Normal)
        searchButton.titleLabel!.font = self.theme.eventsSearchBarFont()

        cancelButton.setTitleColor(theme.defaultButtonDisabledTextColor(), forState: .Disabled)
        cancelButton.setTitleColor(theme.navigationBarButtonTextColor(), forState: .Normal)
        cancelButton.titleLabel!.font = self.theme.eventsSearchBarFont()

        if let textField = searchBar.valueForKey("searchField") as? UITextField {
            textField.textColor = self.theme.eventsZipCodeTextColor()
            textField.font = self.theme.eventsSearchBarFont()
            textField.backgroundColor = self.theme.eventsZipCodeBackgroundColor()
            textField.layer.borderColor = self.theme.eventsZipCodeBorderColor().CGColor
            textField.layer.borderWidth = self.theme.eventsZipCodeBorderWidth()
            textField.layer.cornerRadius = self.theme.eventsZipCodeCornerRadius()
            textField.attributedPlaceholder = NSAttributedString(string: NSLocalizedString("Events_zipCodeTextBoxPlaceholder",  comment: ""),
                attributes:[NSForegroundColorAttributeName: self.theme.eventsZipCodePlaceholderTextColor()])
        }
    }
}

extension EventSearchBarController: NearbyEventsUseCaseObserver {
    func nearbyEventsUseCase(useCase: NearbyEventsUseCase, didFetchEventSearchResult: EventSearchResult) {
        setPlaceholderToCurrentLocation()
    }

    func nearbyEventsUseCaseFoundNoNearbyEvents(useCase: NearbyEventsUseCase) {
        setPlaceholderToCurrentLocation()
    }

    func nearbyEventsUseCaseDidStartFetchingEvents(useCase: NearbyEventsUseCase) {
        resultQueue.addOperationWithBlock {
            self.searchBar.placeholder = NSLocalizedString("EventsSearchBar_loadingNearbyEvents", comment: "")
        }
    }

    func nearbyEventsUseCase(useCase: NearbyEventsUseCase, didFailFetchEvents: NearbyEventsUseCaseError) {}

    private func setPlaceholderToCurrentLocation() {
        resultQueue.addOperationWithBlock {
            self.searchBar.placeholder = NSLocalizedString("EventsSearchBar_foundNearbyResults", comment: "")
        }
    }
}

extension EventSearchBarController: UISearchBarDelegate {
    func searchBarShouldBeginEditing(searchBar: UISearchBar) -> Bool {
        searchButtonSearchBarConstraint.active = true
        cancelButtonSearchBarConstraint.active = true

        preEditPlaceholder = searchBar.placeholder
        if preEditPlaceholder == NSLocalizedString("EventsSearchBar_foundNearbyResults", comment: "") {
            searchBar.text = ""
        } else {
            searchBar.text = preEditPlaceholder
        }

        searchBar.placeholder = NSLocalizedString("EventsSearchBar_searchBarPlaceholder", comment: "")

        searchButton.hidden = false
        cancelButton.hidden = false

        return true
    }

    func searchBar(searchBar: UISearchBar, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        let updatedZipCode = (searchBar.text! as NSString).stringByReplacingCharactersInRange(range, withString: text)

        if updatedZipCode.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) < 6 {
            searchButton.enabled = zipCodeValidator.validate(updatedZipCode)
        }

        return updatedZipCode.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) <= 5
    }
}

extension EventSearchBarController {
    func didTapCancelButton() {
        searchBar.resignFirstResponder()
        searchBar.placeholder = preEditPlaceholder
        searchBar.text = nil

        searchButtonSearchBarConstraint.active = false
        cancelButtonSearchBarConstraint.active = false
        cancelButton.hidden = true
        searchButton.hidden = true

        searchButton.enabled = zipCodeValidator.validate(preEditPlaceholder!)
    }

    func didTapSearchButton() {
        searchBar.resignFirstResponder()
        eventsNearAddressUseCase.fetchEventsNearAddress(searchBar.text!, radiusMiles: 10.0)
        searchBar.placeholder = searchBar.text
        searchBar.text = nil

        searchButtonSearchBarConstraint.active = false
        cancelButtonSearchBarConstraint.active = false

        cancelButton.hidden = true
        searchButton.hidden = true
    }
}
