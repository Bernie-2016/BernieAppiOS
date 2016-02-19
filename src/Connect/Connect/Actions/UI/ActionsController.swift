import UIKit

class ActionsController: UIViewController {
    private let urlProvider: URLProvider
    private let urlOpener: URLOpener
    private let analyticsService: AnalyticsService
    private let actionAlertService: ActionAlertService
    private let actionAlertControllerProvider: ActionAlertControllerProvider
    private let actionsTableViewCellPresenter: ActionsTableViewCellPresenter
    private let tabBarItemStylist: TabBarItemStylist
    private let theme: Theme

    private let tableView = UITableView.newAutoLayoutView()
    let loadingIndicatorView = UIActivityIndicatorView.newAutoLayoutView()

    private var actionAlerts = [ActionAlert]()

    init(urlProvider: URLProvider,
        urlOpener: URLOpener,
        actionAlertService: ActionAlertService,
        actionAlertControllerProvider: ActionAlertControllerProvider,
        actionsTableViewCellPresenter: ActionsTableViewCellPresenter,
        analyticsService: AnalyticsService,
        tabBarItemStylist: TabBarItemStylist,
        theme: Theme) {

        self.urlProvider = urlProvider
        self.urlOpener = urlOpener
        self.actionAlertService = actionAlertService
        self.actionAlertControllerProvider = actionAlertControllerProvider
        self.actionsTableViewCellPresenter = actionsTableViewCellPresenter
        self.analyticsService = analyticsService
        self.tabBarItemStylist = tabBarItemStylist
        self.theme = theme

        super.init(nibName: nil, bundle: nil)

        title = NSLocalizedString("Actions_title", comment: "")
        tabBarItemStylist.applyThemeToBarBarItem(tabBarItem,
            image: UIImage(named: "actionsTabBarIconInactive")!,
            selectedImage: UIImage(named: "actionsTabBarIcon")!)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tableView)
        view.addSubview(loadingIndicatorView)

        tableView.hidden = true
        tableView.dataSource = self
        tableView.delegate = self
        tableView.registerClass(ActionAlertTableViewCell.self, forCellReuseIdentifier: "actionAlertCell")
        tableView.registerClass(ActionTableViewCell.self, forCellReuseIdentifier: "actionCell")
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        tableView.backgroundColor = theme.defaultBackgroundColor()

        setupConstraints()
        loadingIndicatorView.startAnimating()
        loadingIndicatorView.hidesWhenStopped = true
        loadingIndicatorView.color = theme.defaultSpinnerColor()

    }

    override func viewWillAppear(animated: Bool) {
        actionAlertService.fetchActionAlerts().then { actionAlerts in
            self.actionAlerts = actionAlerts
            self.tableView.reloadData()
            self.loadingIndicatorView.stopAnimating()
            self.tableView.hidden = false
            }.error { _ in
                self.tableView.hidden = false
                self.loadingIndicatorView.stopAnimating()
        }
    }

    // MARK: Private

    private func setupConstraints() {
        tableView.autoPinEdgesToSuperviewEdges()

        loadingIndicatorView.autoAlignAxisToSuperviewAxis(.Vertical)
        loadingIndicatorView.autoAlignAxisToSuperviewAxis(.Horizontal)
    }
}

extension ActionsController: UITableViewDataSource {
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return actionAlerts.count > 0 ? 3 : 2
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if actionAlerts.count == 0 {
            return section == 0 ? 2 : 1
        }

        if section == 0 {
            return actionAlerts.count
        } else {
            return section == 1 ? 2 : 1
        }
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if actionAlerts.count > 0 && indexPath.section == 0 {
            return actionsTableViewCellPresenter.presentActionAlertTableViewCell(actionAlerts[indexPath.row], tableView: tableView)
        }

        return actionsTableViewCellPresenter.presentActionTableViewCell(actionAlerts, indexPath: indexPath, tableView: tableView)
    }

    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if actionAlerts.count == 0 {
            return NSLocalizedString(section == 0 ? "Actions_fundraiseHeader" : "Actions_organizeHeader", comment: "")
        } else {
            switch section {
            case 0:
                return NSLocalizedString("Actions_actionAlertsHeader", comment: "")
            case 1:
                return NSLocalizedString("Actions_fundraiseHeader", comment: "")
            case 2:
                return NSLocalizedString("Actions_organizeHeader", comment: "")
            default:
                return ""
            }
        }
    }


    func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let headerView = view as? UITableViewHeaderFooterView else { return }
        headerView.contentView.backgroundColor = self.theme.defaultTableSectionHeaderBackgroundColor()
        headerView.textLabel!.textColor = self.theme.defaultTableSectionHeaderTextColor()
        headerView.textLabel!.font = self.theme.defaultTableSectionHeaderFont()
    }
}

extension ActionsController: UITableViewDelegate {
    func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 75
    }

    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 41
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if actionAlerts.count > 0 && indexPath.section == 0 {
            let controller = actionAlertControllerProvider.provideInstanceWithActionAlert(actionAlerts[indexPath.row])
            navigationController?.pushViewController(controller, animated: true)
            return
        }

        let sectionOffset = actionAlerts.count > 0 ? 1 : 0

        if indexPath.section == (0 + sectionOffset) {
            if indexPath.row == 0 {
                openFormInSafari("Donate Form", url: urlProvider.donateFormURL())
            } else {
                shareDonateForm()
            }
        } else {
            openFormInSafari("Host Event Form", url: urlProvider.hostEventFormURL())
        }
    }

    private func openFormInSafari(name: String, url: NSURL) {
        urlOpener.openURL(url)
        analyticsService.trackContentViewWithName(name, type: .Actions, identifier: name)
    }

    private func shareDonateForm() {
        let name = "Donate Form"
        let url = urlProvider.donateFormURL()
        self.analyticsService.trackCustomEventWithName("Began Share", customAttributes: [
        AnalyticsServiceConstants.contentIDKey: url.absoluteString,
        AnalyticsServiceConstants.contentNameKey: name,
        AnalyticsServiceConstants.contentTypeKey: AnalyticsServiceContentType.Actions.description
        ])
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)

        activityVC.completionWithItemsHandler = { activity, success, items, error in
            if error != nil {
                self.analyticsService.trackError(error!, context: "Failed to share \(name)")
            } else {
                if success == true {
                    self.analyticsService.trackShareWithActivityType(activity!, contentName: name, contentType: .Actions, identifier: url.absoluteString)
                } else {
                    self.analyticsService.trackCustomEventWithName("Cancelled Share", customAttributes: [AnalyticsServiceConstants.contentIDKey: url.absoluteString,
                        AnalyticsServiceConstants.contentNameKey: name,
                        AnalyticsServiceConstants.contentTypeKey: AnalyticsServiceContentType.Actions.description
                        ])
                }
            }
        }

        presentViewController(activityVC, animated: true, completion: nil)
    }
}