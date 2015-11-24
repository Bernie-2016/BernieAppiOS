import UIKit
import PureLayout
import QuartzCore
import CoreText

// swiftlint:disable file_length
// swiftlint:disable type_body_length

class EventsController: UIViewController {
    let eventRepository: EventRepository
    let eventPresenter: EventPresenter
    private let eventControllerProvider: EventControllerProvider
    private let eventSectionHeaderPresenter: EventSectionHeaderPresenter
    private let urlProvider: URLProvider
    private let urlOpener: URLOpener
    private let analyticsService: AnalyticsService
    private let tabBarItemStylist: TabBarItemStylist
    private let eventListTableViewCellStylist: EventListTableViewCellStylist
    private let theme: Theme

    let searchBar = UIView.newAutoLayoutView()
    let zipCodeTextField = UITextField.newAutoLayoutView()
    let cancelButton = UIButton.newAutoLayoutView()
    let searchButton = UIButton.newAutoLayoutView()
    let filterButton = ResponderButton.newAutoLayoutView()
    let radiusPickerView = UIPickerView()
    let resultsTableView = UITableView.newAutoLayoutView()
    let noResultsLabel = UILabel.newAutoLayoutView()
    let createEventCTATextView = UITextView.newAutoLayoutView()
    let instructionsLabel = UILabel.newAutoLayoutView()
    let subInstructionsLabel = UILabel.newAutoLayoutView()
    let loadingActivityIndicatorView = UIActivityIndicatorView.newAutoLayoutView()


    private let radiusPickerViewOptions = [5, 10, 20, 50, 100, 250]
    private var selectedSearchRadiusIndex = 1
    private var previouslySelectedRow: Int!
    private var eventSearchResult: EventSearchResult!
    private var searchButtonZipCodeConstraint: NSLayoutConstraint!
    private var cancelButtonZipCodeConstraint: NSLayoutConstraint!
    private var filterButtonZipCodeConstraint: NSLayoutConstraint!

    init(eventRepository: EventRepository,
        eventPresenter: EventPresenter,
        eventControllerProvider: EventControllerProvider,
        eventSectionHeaderPresenter: EventSectionHeaderPresenter,
        urlProvider: URLProvider,
        urlOpener: URLOpener,
        analyticsService: AnalyticsService,
        tabBarItemStylist: TabBarItemStylist,
        eventListTableViewCellStylist: EventListTableViewCellStylist,
        theme: Theme) {

            self.eventRepository = eventRepository
            self.eventPresenter = eventPresenter
            self.eventControllerProvider = eventControllerProvider
            self.eventSectionHeaderPresenter = eventSectionHeaderPresenter
            self.urlProvider = urlProvider
            self.urlOpener = urlOpener
            self.analyticsService = analyticsService
            self.tabBarItemStylist = tabBarItemStylist
            self.eventListTableViewCellStylist = eventListTableViewCellStylist
            self.theme = theme

            super.init(nibName: nil, bundle: nil)

            self.tabBarItemStylist.applyThemeToBarBarItem(self.tabBarItem,
                image: UIImage(named: "eventsTabBarIconInactive")!,
                selectedImage: UIImage(named: "eventsTabBarIcon")!)
            self.title = NSLocalizedString("Events_tabBarTitle", comment: "")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.setNeedsStatusBarAppearanceUpdate()

        navigationItem.title = NSLocalizedString("Events_navigationTitle", comment: "")
        let backBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Events_backButtonTitle", comment: ""),
            style: UIBarButtonItemStyle.Plain,
            target: nil, action: nil)

        navigationItem.backBarButtonItem = backBarButtonItem
        edgesForExtendedLayout = .None

        self.setupSubviews()
        self.applyTheme()
        self.setupConstraints()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        self.navigationController?.setNavigationBarHidden(true, animated: animated)

        if let selectedRowIndexPath = self.resultsTableView.indexPathForSelectedRow {
            self.resultsTableView.deselectRowAtIndexPath(selectedRowIndexPath, animated: false)
        }
    }

    override func viewDidAppear(animated: Bool) {
        self.previouslySelectedRow = selectedSearchRadiusIndex
        radiusPickerView.selectRow(self.selectedSearchRadiusIndex, inComponent: 0, animated: false)
        radiusPickerView.reloadAllComponents()
    }

    override func viewWillDisappear(animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: animated)

        super.viewWillDisappear(animated)
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }

    // MARK: Actions

    func didTapFilter() {
        self.previouslySelectedRow = self.radiusPickerView.selectedRowInComponent(0)
        self.zipCodeTextField.hidden = true
        self.filterButton.hidden = true
        self.searchButton.hidden = false
        self.cancelButton.hidden = false
        self.filterButton.becomeFirstResponder()
    }

    func didTapSearch(sender: UIButton!) {
        let enteredZipCode = self.zipCodeTextField.text!
        self.analyticsService.trackSearchWithQuery(enteredZipCode, context: .Events)

        self.searchButton.hidden = true
        self.cancelButton.hidden = true
        self.zipCodeTextField.hidden = false

        self.view.layoutIfNeeded()

        self.searchButtonZipCodeConstraint.active = false
        self.cancelButtonZipCodeConstraint.active = false

        UIView.animateWithDuration(0.2, animations: { () -> Void in
            self.view.layoutIfNeeded()
        })

        zipCodeTextField.resignFirstResponder()
        filterButton.resignFirstResponder()

        self.instructionsLabel.hidden = true
        self.subInstructionsLabel.hidden = true
        self.resultsTableView.hidden = true
        self.noResultsLabel.hidden = true
        self.createEventCTATextView.hidden = true

        self.performSearchWithZipCode(enteredZipCode)
    }

    func didTapCancel(sender: UIButton!) {
        self.searchButton.hidden = true
        self.cancelButton.hidden = true
        self.zipCodeTextField.hidden = false

        self.view.layoutIfNeeded()

        self.searchButtonZipCodeConstraint.active = false
        self.cancelButtonZipCodeConstraint.active = false
        self.filterButtonZipCodeConstraint.active = self.eventSearchResult != nil

        self.analyticsService.trackCustomEventWithName("Cancelled ZIP Code search on Events", customAttributes: nil)
        UIView.animateWithDuration(0.2, animations: { () -> Void in
            self.view.layoutIfNeeded()
            }) { (finished) -> Void in
                self.filterButton.hidden = self.eventSearchResult == nil
        }
        self.zipCodeTextField.resignFirstResponder()
        self.filterButton.resignFirstResponder()
        self.radiusPickerView.selectRow(self.previouslySelectedRow, inComponent: 0, animated: false)
        self.selectedSearchRadiusIndex = self.previouslySelectedRow
    }

    func didTapOrganize(recognizer: UIGestureRecognizer) {
        guard let textView = recognizer.view as? UITextView else { return }
        let layoutManager = textView.layoutManager
        var location = recognizer.locationInView(textView)
        location.x = location.x - textView.textContainerInset.left
        location.y = location.y - textView.textContainerInset.top

        let characterIndex = layoutManager.characterIndexForPoint(location, inTextContainer: textView.textContainer, fractionOfDistanceBetweenInsertionPoints: nil)

        if characterIndex < textView.textStorage.length {
            let organizeValue = textView.textStorage.attribute("organize", atIndex: characterIndex, effectiveRange: nil)

            if organizeValue != nil {
                self.urlOpener.openURL(self.urlProvider.createEventURL())
                return
            }
        }
    }

    // MARK: Private

    func performSearchWithZipCode(zipCode: String) {
        loadingActivityIndicatorView.startAnimating()

        self.eventRepository.fetchEventsWithZipCode(zipCode, radiusMiles: Float(self.radiusPickerViewOptions[self.selectedSearchRadiusIndex]),
            completion: { (eventSearchResult: EventSearchResult) -> Void in
                let matchingEventsFound = eventSearchResult.events.count > 0
                self.view.layoutIfNeeded()

                self.filterButtonZipCodeConstraint.active = true

                UIView.animateWithDuration(0.2, animations: { () -> Void in
                    self.view.layoutIfNeeded()
                    }) { (finished) -> Void in
                        self.filterButton.hidden = false
                }

                self.eventSearchResult = eventSearchResult

                self.noResultsLabel.hidden = matchingEventsFound
                self.createEventCTATextView.hidden = matchingEventsFound
                self.resultsTableView.hidden = !matchingEventsFound
                self.loadingActivityIndicatorView.stopAnimating()

                self.resultsTableView.reloadData()
            }) { (error: NSError) -> Void in
                self.view.layoutIfNeeded()

                self.filterButtonZipCodeConstraint.active = false

                UIView.animateWithDuration(0.2, animations: { () -> Void in
                    self.view.layoutIfNeeded()
                    }) { (finished) -> Void in
                        self.filterButton.hidden = true
                }

                self.analyticsService.trackError(error, context: "Events")
                self.noResultsLabel.hidden = false
                self.createEventCTATextView.hidden = false
                self.loadingActivityIndicatorView.stopAnimating()
        }
    }

    func setupSubviews() {
        searchBar.addSubview(zipCodeTextField)
        searchBar.addSubview(searchButton)
        searchBar.addSubview(cancelButton)
        searchBar.addSubview(filterButton)

        view.addSubview(searchBar)
        view.addSubview(instructionsLabel)
        view.addSubview(subInstructionsLabel)
        view.addSubview(resultsTableView)
        view.addSubview(noResultsLabel)
        view.addSubview(createEventCTATextView)
        view.addSubview(loadingActivityIndicatorView)

        setupSearchBar()
        setupResults()
    }

    func setupSearchBar() {
        zipCodeTextField.delegate = self

        let magnifyingGlassIcon = UIImageView(frame: CGRectMake(0, 0, 22, 17))
        let magnifyingGlassImage = UIImage(named: "searchMagnifyingGlass")!
        magnifyingGlassIcon.image = magnifyingGlassImage
        magnifyingGlassIcon.contentMode = .Left
        zipCodeTextField.leftView = magnifyingGlassIcon
        zipCodeTextField.leftViewMode = .Always
        zipCodeTextField.contentVerticalAlignment = .Center

        zipCodeTextField.attributedPlaceholder = NSAttributedString(string: NSLocalizedString("Events_zipCodeTextBoxPlaceholder",  comment: ""),
            attributes:[NSForegroundColorAttributeName: self.theme.eventsZipCodeTextColor()])
        zipCodeTextField.keyboardType = .NumberPad

        searchButton.setTitle(NSLocalizedString("Events_eventSearchButtonTitle", comment: ""), forState: .Normal)
        searchButton.hidden = true
        searchButton.addTarget(self, action: "didTapSearch:", forControlEvents: .TouchUpInside)
        cancelButton.setTitle(NSLocalizedString("Events_eventCancelButtonTitle", comment: ""), forState: .Normal)
        cancelButton.hidden = true
        cancelButton.addTarget(self, action: "didTapCancel:", forControlEvents: .TouchUpInside)

        filterButton.setImage(UIImage(named: "filterIcon"), forState: .Normal)
        filterButton.setTitleColor(self.theme.eventsZipCodeTextColor(), forState: .Normal)
        filterButton.hidden = true
        filterButton.addTarget(self, action: "didTapFilter", forControlEvents: .TouchUpInside)
        filterButton.buttonInputView = radiusPickerView

        radiusPickerView.delegate = self
        radiusPickerView.dataSource = self
        radiusPickerView.showsSelectionIndicator = true
    }

    func setupResults() {
        resultsTableView.dataSource = self
        resultsTableView.delegate = self
        resultsTableView.hidden = true
        resultsTableView.registerClass(EventListTableViewCell.self, forCellReuseIdentifier: "eventCell")

        instructionsLabel.text = NSLocalizedString("Events_instructions", comment: "")
        instructionsLabel.textAlignment = .Center
        instructionsLabel.numberOfLines = 0

        subInstructionsLabel.text = NSLocalizedString("Events_subInstructions", comment: "")
        subInstructionsLabel.textAlignment = .Center
        subInstructionsLabel.numberOfLines = 0

        noResultsLabel.numberOfLines = 0
        noResultsLabel.textAlignment = .Center
        noResultsLabel.text = NSLocalizedString("Events_noEventsFound", comment: "")
        noResultsLabel.lineBreakMode = NSLineBreakMode.ByTruncatingTail;
        noResultsLabel.hidden = true

        setupCreateEventCTATextView()

        loadingActivityIndicatorView.hidesWhenStopped = true
        loadingActivityIndicatorView.stopAnimating()
    }

    func setupCreateEventCTATextView() {
        createEventCTATextView.hidden = true
        createEventCTATextView.scrollEnabled = false
        createEventCTATextView.selectable = false
        createEventCTATextView.textAlignment = .Center

        var fullTextAttributes = [String:AnyObject]()
        let paragraphStyle: NSMutableParagraphStyle? = NSParagraphStyle.defaultParagraphStyle().mutableCopy() as? NSMutableParagraphStyle

        if paragraphStyle != nil {
            paragraphStyle!.alignment = .Center
            fullTextAttributes[NSParagraphStyleAttributeName] = paragraphStyle!
        }


        let fullText = NSMutableAttributedString(string: NSLocalizedString("Events_createEventCTAText", comment:""),
            attributes: fullTextAttributes)
        let organize = NSAttributedString(string: NSLocalizedString("Events_organizeText", comment: ""), attributes: [NSUnderlineStyleAttributeName: NSUnderlineStyle.StyleSingle.rawValue, "organize": true])

        fullText.replaceCharactersInRange((fullText.string as NSString).rangeOfString("{0}"), withAttributedString: organize)

        createEventCTATextView.attributedText = fullText

        let tapOrganizeRecognizer = UITapGestureRecognizer(target: self, action: "didTapOrganize:")
        createEventCTATextView.addGestureRecognizer(tapOrganizeRecognizer)
    }

    func applyTheme() {
        searchBar.backgroundColor = self.theme.eventsSearchBarBackgroundColor()

        zipCodeTextField.textColor = self.theme.eventsZipCodeTextColor()
        zipCodeTextField.font = self.theme.eventsSearchBarFont()
        zipCodeTextField.backgroundColor = self.theme.eventsZipCodeBackgroundColor()
        zipCodeTextField.layer.borderColor = self.theme.eventsZipCodeBorderColor().CGColor
        zipCodeTextField.layer.borderWidth = self.theme.eventsZipCodeBorderWidth()
        zipCodeTextField.layer.cornerRadius = self.theme.eventsZipCodeCornerRadius()
        zipCodeTextField.layer.sublayerTransform = self.theme.eventsZipCodeTextOffset()

        searchButton.titleLabel!.font = self.theme.eventsSearchBarFont()
        cancelButton.titleLabel!.font = self.theme.eventsSearchBarFont()

        instructionsLabel.font = theme.eventsInstructionsFont()
        instructionsLabel.textColor = theme.eventsInformationTextColor()
        subInstructionsLabel.font = theme.eventsSubInstructionsFont()
        subInstructionsLabel.textColor = theme.eventsInformationTextColor()

        noResultsLabel.textColor = self.theme.eventsInformationTextColor()
        noResultsLabel.font = self.theme.eventsNoResultsFont()

        createEventCTATextView.font = self.theme.eventsCreateEventCTAFont()
        createEventCTATextView.textColor = self.theme.eventsInformationTextColor()

        loadingActivityIndicatorView.color = self.theme.defaultSpinnerColor()
    }

    func setupConstraints() {
        self.setupSearchBarConstraints()

        instructionsLabel.autoAlignAxisToSuperviewAxis(.Vertical)
        instructionsLabel.autoAlignAxisToSuperviewAxis(.Horizontal)
        instructionsLabel.autoSetDimension(.Width, toSize: 220)

        subInstructionsLabel.autoPinEdge(.Top, toEdge: .Bottom, ofView: instructionsLabel, withOffset: 15)
        subInstructionsLabel.autoPinEdge(.Left, toEdge: .Left, ofView: instructionsLabel, withOffset: 25)
        subInstructionsLabel.autoPinEdge(.Right, toEdge: .Right, ofView: instructionsLabel, withOffset: -25)

        resultsTableView.autoPinEdge(.Top, toEdge: .Bottom, ofView: searchBar)
        resultsTableView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero, excludingEdge: .Top)

        noResultsLabel.autoAlignAxisToSuperviewAxis(.Vertical)
        noResultsLabel.autoAlignAxisToSuperviewAxis(.Horizontal)
        noResultsLabel.autoSetDimension(.Width, toSize: 220)

        createEventCTATextView.autoPinEdge(.Top, toEdge: .Bottom, ofView: noResultsLabel, withOffset: 15)
        createEventCTATextView.autoPinEdge(.Left, toEdge: .Left, ofView: noResultsLabel, withOffset: 25)
        createEventCTATextView.autoPinEdge(.Right, toEdge: .Right, ofView: noResultsLabel, withOffset: -25)

        loadingActivityIndicatorView.autoAlignAxisToSuperviewAxis(.Horizontal)
        loadingActivityIndicatorView.autoAlignAxisToSuperviewAxis(.Vertical)
    }

    func setupSearchBarConstraints() {
        searchBar.autoPinEdgeToSuperviewEdge(.Top)
        searchBar.autoPinEdgeToSuperviewEdge(.Left)
        searchBar.autoPinEdgeToSuperviewEdge(.Right)
        searchBar.autoSetDimension(.Height, toSize: 40 + 24)

        NSLayoutConstraint.autoSetPriority(900, forConstraints: { () -> Void in
            self.searchButtonZipCodeConstraint = self.searchButton.autoPinEdge(.Left, toEdge: .Right, ofView: self.zipCodeTextField, withOffset: 15)
        })
        self.searchButtonZipCodeConstraint.active = false

        searchButton.autoPinEdgeToSuperviewEdge(.Right, withInset: 15)
        searchButton.autoAlignAxis(.Horizontal, toSameAxisOfView: zipCodeTextField)
        searchButton.autoSetDimension(.Width, toSize: 60)

        NSLayoutConstraint.autoSetPriority(900, forConstraints: { () -> Void in
            self.cancelButtonZipCodeConstraint = self.cancelButton.autoPinEdge(.Right, toEdge: .Left, ofView: self.zipCodeTextField, withOffset: -15)
        })
        self.cancelButtonZipCodeConstraint.active = false
        cancelButton.autoPinEdgeToSuperviewEdge(.Left, withInset: 15)
        cancelButton.autoAlignAxis(.Horizontal, toSameAxisOfView: zipCodeTextField)
        cancelButton.autoSetDimension(.Width, toSize: 60)

        NSLayoutConstraint.autoSetPriority(800, forConstraints: { () -> Void in
            self.zipCodeTextField.autoPinEdgeToSuperviewEdge(.Left, withInset: 15)
            self.zipCodeTextField.autoPinEdgeToSuperviewEdge(.Right, withInset: 15)
        })

        zipCodeTextField.autoPinEdgeToSuperviewEdge(.Top, withInset: 27)
        zipCodeTextField.autoSetDimension(.Height, toSize: 25)

        NSLayoutConstraint.autoSetPriority(850, forConstraints: { () -> Void in
            self.filterButtonZipCodeConstraint = self.filterButton.autoPinEdge(.Left, toEdge: .Right, ofView: self.zipCodeTextField, withOffset: 15)
        })

        self.filterButton.autoPinEdgeToSuperviewEdge(.Right, withInset: 15)
        self.filterButtonZipCodeConstraint.active = false
        filterButton.autoAlignAxis(.Horizontal, toSameAxisOfView: zipCodeTextField)
        filterButton.autoSetDimension(.Width, toSize: 24)
    }
}

// swiftlint:enable type_body_length


// MARK: <UITableViewDataSource>
extension EventsController: UITableViewDataSource {
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return eventSearchResult != nil ? eventSearchResult.uniqueDaysInLocalTimeZone().count : 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return eventSearchResult != nil ? eventSearchResult.eventsWithDayIndex(section).count : 0
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // swiftlint:disable force_cast
        let cell = tableView.dequeueReusableCellWithIdentifier("eventCell") as! EventListTableViewCell
        // swiftlint:enable force_cast

        let eventsForDay = eventSearchResult.eventsWithDayIndex(indexPath.section)
        let event = eventsForDay[indexPath.row]

        self.eventListTableViewCellStylist.styleCell(cell, event: event)

        return self.eventPresenter.presentEventListCell(event, searchCentroid: eventSearchResult.searchCentroid, cell: cell)
    }
}

// MARK: <UITableViewDelegate>
extension EventsController: UITableViewDelegate {
    func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 75
    }

    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 34
    }

    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if eventSearchResult == nil {
            return nil
        }

        let sectionDate = self.eventSearchResult.uniqueDaysInLocalTimeZone()[section]
        return self.eventSectionHeaderPresenter.headerForDate(sectionDate)
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let eventsForDay = eventSearchResult.eventsWithDayIndex(indexPath.section)
        let event = eventsForDay[indexPath.row]
        let controller = self.eventControllerProvider.provideInstanceWithEvent(event)
        self.analyticsService.trackContentViewWithName(event.name, type: .Event, id: event.url.absoluteString)
        self.navigationController?.pushViewController(controller, animated: true)
    }

    func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let headerView = view as? UITableViewHeaderFooterView else { return }
        headerView.contentView.backgroundColor = self.theme.eventsListSectionHeaderBackgroundColor()
        headerView.textLabel?.textColor = self.theme.eventsListSectionHeaderTextColor()
        headerView.textLabel?.font = self.theme.eventsListSectionHeaderFont()
    }
}

// MARK: <UITextFieldDelegate>
extension EventsController: UITextFieldDelegate {
    func textFieldDidBeginEditing(textField: UITextField) {
        self.view.layoutIfNeeded()

        self.searchButtonZipCodeConstraint.active = true
        self.cancelButtonZipCodeConstraint.active = true

        UIView.animateWithDuration(0.2, animations: { () -> Void in
            self.view.layoutIfNeeded()
            }) { (finished) -> Void in
                self.searchButton.hidden = false
                self.cancelButton.hidden = false
                self.filterButton.hidden = true

        }

        analyticsService.trackCustomEventWithName("Tapped on ZIP Code text field on Events", customAttributes: nil)
    }
}

// MARK: <UIPickerViewDataSource>

extension EventsController: UIPickerViewDataSource {
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 6
    }
}

// MARK: <UIPickerViewDelegate>

extension EventsController: UIPickerViewDelegate {

    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return NSString.localizedStringWithFormat(NSLocalizedString("Events_radiusMiles", comment: ""), self.radiusPickerViewOptions[row]) as String
    }

    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.selectedSearchRadiusIndex = row
    }
}
// swiftlint:enable file_length
