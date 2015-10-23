import UIKit
import PureLayout
import QuartzCore

// swiftlint:disable type_body_length
class EventsController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate,UIPickerViewDataSource, UIPickerViewDelegate
{
    let eventRepository: EventRepository
    let eventPresenter: EventPresenter
    let settingsController: SettingsController
    private let eventControllerProvider: EventControllerProvider
    private let analyticsService: AnalyticsService
    private let tabBarItemStylist: TabBarItemStylist
    let theme: Theme

    let zipCodeTextField = UITextField.newAutoLayoutView()
    let zipCodeRadiusButton:UIButton = UIButton.newAutoLayoutView();
    let zipCodeSearchButton:UIButton = UIButton.newAutoLayoutView();
    let resultsTableView = UITableView.newAutoLayoutView()
    let noResultsLabel = UILabel.newAutoLayoutView()
    let instructionsLabel = UILabel.newAutoLayoutView()
    let loadingActivityIndicatorView = UIActivityIndicatorView.newAutoLayoutView()

    var events: Array<Event>!
    
    var zipCodeRadiusFilterData = [5, 10, 20, 50, 100, 250];
    var selectedZipCodeRadius:Int!;
    var zipCodeModalPicker:ModalUIPickerView!;

    init(eventRepository: EventRepository,
        eventPresenter: EventPresenter,
        settingsController: SettingsController,
        eventControllerProvider: EventControllerProvider,
        analyticsService: AnalyticsService,
        tabBarItemStylist: TabBarItemStylist,
        theme: Theme) {

        self.eventRepository = eventRepository
        self.eventPresenter = eventPresenter
        self.settingsController = settingsController
        self.eventControllerProvider = eventControllerProvider
        self.analyticsService = analyticsService
        self.tabBarItemStylist = tabBarItemStylist
        self.theme = theme

        self.events = []

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

        navigationItem.title = NSLocalizedString("Events_navigationTitle", comment: "")
        let settingsIcon = UIImage(named: "settingsIcon")
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: settingsIcon, style: .Plain, target: self, action: "didTapSettings")
        let backBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Events_backButtonTitle", comment: ""),
            style: UIBarButtonItemStyle.Plain,
            target: nil, action: nil)

        navigationItem.backBarButtonItem = backBarButtonItem

        edgesForExtendedLayout = .None
        
        resultsTableView.dataSource = self
        resultsTableView.delegate = self
        resultsTableView.registerClass(EventListTableViewCell.self, forCellReuseIdentifier: "eventCell")

        instructionsLabel.text = NSLocalizedString("Events_instructions", comment: "")

        setNeedsStatusBarAppearanceUpdate()

        self.setupSubviews()
        self.applyTheme()
        self.setupConstraints()
    }

    // MARK: <UITableViewDataSource>

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // swiftlint:disable force_cast
        let cell = tableView.dequeueReusableCellWithIdentifier("eventCell") as! EventListTableViewCell
        // swiftlint:enable force_cast

        let event = events[indexPath.row]

        cell.addressLabel.textColor = self.theme.eventsListColor()
        cell.addressLabel.font = self.theme.eventsListFont()
        cell.attendeesLabel.textColor = self.theme.eventsListColor()
        cell.attendeesLabel.font = self.theme.eventsListFont()
        cell.nameLabel.textColor = self.theme.eventsListColor()
        cell.nameLabel.font = self.theme.eventsListFont()

        return self.eventPresenter.presentEvent(event, cell: cell)
    }

    // MARK: <UITableViewDelegate>

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 90
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let event = self.events[indexPath.row]
        let controller = self.eventControllerProvider.provideInstanceWithEvent(event)
        self.analyticsService.trackContentViewWithName(event.name, type: .Event, id: event.url.absoluteString)
        self.navigationController?.pushViewController(controller, animated: true)
    }

    // MARK: <UITextFieldDelegate>

    func textFieldDidBeginEditing(textField: UITextField) {
        self.analyticsService.trackCustomEventWithName("Tapped on ZIP Code text field on Events", customAttributes: nil)
    }
    
    // MARK: - <UIPickerViewDataSource>
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return zipCodeRadiusFilterData.count;
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return String(zipCodeRadiusFilterData[row]);
    }
    
    // MARK: - <UIPickerViewDelegate>
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        
    }
    
    // MARK: - Actions
    
    func selectRadiusForFilter(sender:UIButton!)
    {
        self.zipCodeModalPicker = ModalUIPickerView(pickerDataSource: self, pickerDelegate: self, backgroundColor: self.theme.eventsZipCodeBackgroundColor(), accentColor: self.theme.eventsInputAccessoryBackgroundColor())
        
        self.zipCodeModalPicker.open(self.zipCodeRadiusSelected);
        
    }

    func didTapSettings() {
        self.analyticsService.trackCustomEventWithName("Tapped 'Settings' in Events nav bar", customAttributes: nil)
        self.navigationController?.pushViewController(self.settingsController, animated: true)
    }

    func didTapSearch(sender: UIButton!) {
        let enteredZipCode = self.zipCodeTextField.text!
        self.analyticsService.trackSearchWithQuery(enteredZipCode, context: .Events)

        zipCodeTextField.resignFirstResponder()

        self.instructionsLabel.hidden = true
        self.resultsTableView.hidden = true
        self.noResultsLabel.hidden = true

        loadingActivityIndicatorView.startAnimating()

        self.eventRepository.fetchEventsWithZipCode(enteredZipCode, radiusMiles: Float(self.selectedZipCodeRadius),
            completion: { (events: Array<Event>) -> Void in
                let matchingEventsFound = events.count > 0
                self.events = events

                self.noResultsLabel.hidden = matchingEventsFound
                self.resultsTableView.hidden = !matchingEventsFound
                self.loadingActivityIndicatorView.stopAnimating()

                self.resultsTableView.reloadData()
            }) { (error: NSError) -> Void in
                self.analyticsService.trackError(error, context: "Events")
                self.noResultsLabel.hidden = false
                self.loadingActivityIndicatorView.stopAnimating()
        }
    }

    func didTapCancel(sender: UIButton!) {
        self.analyticsService.trackCustomEventWithName("Cancelled ZIP Code search on Events", customAttributes: nil)
        self.zipCodeTextField.resignFirstResponder()
    }
    
    func zipCodeRadiusSelected(rowSelected:Int)
    {
        self.selectedZipCodeRadius = self.zipCodeRadiusFilterData[rowSelected];
        self.zipCodeRadiusButton.setTitle(String(self.selectedZipCodeRadius) + " Miles", forState: .Normal);
    }

    // MARK: Private

    func setupSubviews() {
        view.addSubview(zipCodeTextField)
        view.addSubview(zipCodeRadiusButton)
        view.addSubview(zipCodeSearchButton)
        view.addSubview(instructionsLabel)
        view.addSubview(resultsTableView)
        view.addSubview(noResultsLabel)
        view.addSubview(loadingActivityIndicatorView)

        zipCodeTextField.delegate = self
        zipCodeTextField.placeholder = NSLocalizedString("Events_zipCodeTextBoxPlaceholder",  comment: "")
        zipCodeTextField.keyboardType = .NumberPad
        
        zipCodeRadiusButton.setTitle(NSLocalizedString("Events_zipCodeRadiusButtonPlaceholder",  comment: ""), forState: .Normal)
        zipCodeRadiusButton.addTarget(self, action: "selectRadiusForFilter:", forControlEvents: .TouchUpInside);
        
        zipCodeSearchButton.setTitle(NSLocalizedString("Events_eventSearchButtonTitle",  comment: ""), forState: .Normal)
        zipCodeSearchButton.addTarget(self, action: "didTapSearch:", forControlEvents: .TouchUpInside);

        instructionsLabel.textAlignment = .Center
        instructionsLabel.numberOfLines = 0
        noResultsLabel.textAlignment = .Center
        noResultsLabel.text = NSLocalizedString("Events_noEventsFound", comment: "")
        noResultsLabel.lineBreakMode = NSLineBreakMode.ByTruncatingTail;

        resultsTableView.hidden = true
        noResultsLabel.hidden = true
        loadingActivityIndicatorView.hidesWhenStopped = true
        loadingActivityIndicatorView.stopAnimating()

        let inputAccessoryView = UIToolbar(frame: CGRectMake(0, 0, 320, 50))
        inputAccessoryView.barTintColor = self.theme.eventsInputAccessoryBackgroundColor()

        let spacer = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
        //let searchButton = UIBarButtonItem(title: NSLocalizedString("Events_eventSearchButtonTitle", comment: ""), style: .Done, target: self, action: "didTapSearch:")
        let cancelButton = UIBarButtonItem(title: NSLocalizedString("Events_eventCloseButtonTitle", comment: ""), style: .Done, target: self, action: "didTapCancel:")

        let inputAccessoryItems = [spacer, cancelButton]
        inputAccessoryView.items = inputAccessoryItems

        zipCodeTextField.inputAccessoryView = inputAccessoryView
    }

    func applyTheme()
    {
        zipCodeTextField.textColor = self.theme.eventsZipCodeTextColor()
        zipCodeTextField.font = self.theme.eventsZipCodeFont()
        zipCodeTextField.backgroundColor = self.theme.eventsZipCodeBackgroundColor()
        zipCodeTextField.layer.borderColor = self.theme.eventsZipCodeBorderColor().CGColor
        zipCodeTextField.layer.borderWidth = self.theme.eventsZipCodeBorderWidth()
        zipCodeTextField.layer.cornerRadius = self.theme.eventsZipCodeCornerRadius()
        zipCodeTextField.layer.sublayerTransform = self.theme.eventsZipCodeTextOffset()
        
        zipCodeRadiusButton.setTitleColor(self.theme.eventsZipCodeTextColor(), forState: .Normal)
        zipCodeRadiusButton.titleLabel?.font = self.theme.eventsZipCodeFont()
        zipCodeRadiusButton.backgroundColor = self.theme.eventsZipCodeBackgroundColor()
        zipCodeRadiusButton.layer.borderColor = self.theme.eventsZipCodeBorderColor().CGColor
        zipCodeRadiusButton.layer.borderWidth = self.theme.eventsZipCodeBorderWidth()
        zipCodeRadiusButton.layer.cornerRadius = self.theme.eventsZipCodeCornerRadius()
        zipCodeRadiusButton.layer.sublayerTransform = self.theme.eventsZipCodeTextOffset()
        
        zipCodeSearchButton.setTitleColor(self.theme.eventsZipCodeTextColor(), forState: .Normal)
        zipCodeSearchButton.titleLabel?.font = self.theme.eventsZipCodeFont()
        zipCodeSearchButton.backgroundColor = self.theme.eventsZipCodeBackgroundColor()
        zipCodeSearchButton.layer.borderColor = self.theme.eventsZipCodeBorderColor().CGColor
        zipCodeSearchButton.layer.borderWidth = self.theme.eventsZipCodeBorderWidth()
        zipCodeSearchButton.layer.cornerRadius = self.theme.eventsZipCodeCornerRadius()
        zipCodeSearchButton.layer.sublayerTransform = self.theme.eventsZipCodeTextOffset()
        
        instructionsLabel.font = theme.eventsInstructionsFont()
        instructionsLabel.textColor = theme.eventsInstructionsTextColor()

        noResultsLabel.textColor = self.theme.eventsNoResultsTextColor()
        noResultsLabel.font = self.theme.eventsNoResultsFont()

        loadingActivityIndicatorView.color = self.theme.defaultSpinnerColor()
    }

    func setupConstraints() {
        zipCodeTextField.autoPinEdgeToSuperviewEdge(.Top, withInset: 24)
        zipCodeTextField.autoPinEdgeToSuperviewEdge(.Left, withInset: 8)
        zipCodeTextField.autoPinEdgeToSuperviewEdge(.Right, withInset: 8)
        zipCodeTextField.autoSetDimension(.Height, toSize: 45)
        
        zipCodeRadiusButton.autoPinEdge(.Top, toEdge: .Bottom, ofView: zipCodeTextField, withOffset:8)
        zipCodeRadiusButton.autoPinEdgeToSuperviewEdge(.Left, withInset: 8)
        zipCodeRadiusButton.autoPinEdge(.Right, toEdge: .Left, ofView: zipCodeSearchButton, withOffset:5)
        zipCodeRadiusButton.autoSetDimension(.Height, toSize: 40)
        zipCodeRadiusButton.autoSetDimension(.Width, toSize: UIScreen.mainScreen().bounds.width/2 - 5)
        
        zipCodeSearchButton.autoPinEdge(.Top, toEdge: .Bottom, ofView: zipCodeTextField, withOffset:8)
        zipCodeSearchButton.autoPinEdge(.Left, toEdge: .Right, ofView: zipCodeRadiusButton, withOffset:5)
        zipCodeSearchButton.autoPinEdgeToSuperviewEdge(.Right, withInset: 8)
        zipCodeSearchButton.autoSetDimension(.Height, toSize: 40)
        
        resultsTableView.autoPinEdge(.Top, toEdge: .Bottom, ofView: zipCodeRadiusButton, withOffset: 8)
        resultsTableView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero, excludingEdge: .Top)

        instructionsLabel.autoAlignAxisToSuperviewAxis(.Vertical)
        instructionsLabel.autoAlignAxisToSuperviewAxis(.Horizontal)
        instructionsLabel.autoSetDimension(.Width, toSize: 220)

        resultsTableView.autoPinEdge(.Top, toEdge: .Bottom, ofView: zipCodeRadiusButton, withOffset: 8)
        resultsTableView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero, excludingEdge: .Top)

        noResultsLabel.autoPinEdge(.Top, toEdge: .Bottom, ofView: zipCodeRadiusButton, withOffset: 16)
        noResultsLabel.autoPinEdgeToSuperviewEdge(.Left)
        noResultsLabel.autoPinEdgeToSuperviewEdge(.Right)

        loadingActivityIndicatorView.autoPinEdge(.Top, toEdge: .Bottom, ofView: zipCodeRadiusButton, withOffset: 16)
        loadingActivityIndicatorView.autoAlignAxisToSuperviewAxis(.Vertical)
    }
}
// swiftlint:enable type_body_length
