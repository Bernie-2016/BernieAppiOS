import UIKit

public class EventController : UIViewController {
    public let event : Event!
    public let eventPresenter: EventPresenter!
    public let dateFormatter : NSDateFormatter!
    public let theme : Theme!
    
    let containerView = UIView.newAutoLayoutView()
    let scrollView = UIScrollView.newAutoLayoutView()
    public let nameLabel = UILabel.newAutoLayoutView()
    public let dateLabel = UILabel.newAutoLayoutView()
    public let attendeesLabel = UILabel.newAutoLayoutView()
    public let addressLabel = UILabel.newAutoLayoutView()
    public let descriptionHeadingLabel = UILabel.newAutoLayoutView()
    public let descriptionLabel = UILabel.newAutoLayoutView()
    
    public init(
        event: Event,
        eventPresenter: EventPresenter,
        dateFormatter: NSDateFormatter,
        theme: Theme) {            
            self.event = event
            self.eventPresenter = eventPresenter
            self.dateFormatter = dateFormatter
            self.theme = theme
            
            super.init(nibName: nil, bundle: nil)
            
            self.hidesBottomBarWhenPushed = true // TODO: test this when initialized, not when viewDidLoad
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = theme.defaultBackgroundColor()
        nameLabel.textColor = theme.eventNameColor()
        nameLabel.font = theme.eventNameFont()
        
        nameLabel.text = event.name
        addressLabel.text = self.eventPresenter.presentAddressForEvent(event)
        attendeesLabel.text = self.eventPresenter.presentAttendeesForEvent(event)
        descriptionHeadingLabel.text = NSLocalizedString("Event_descriptionHeading", comment: "")
        
        view.addSubview(self.scrollView)
        scrollView.addSubview(self.containerView)
        containerView.addSubview(self.nameLabel)
        containerView.addSubview(self.dateLabel)
        containerView.addSubview(self.attendeesLabel)
        containerView.addSubview(self.addressLabel)
        containerView.addSubview(self.descriptionHeadingLabel)
        containerView.addSubview(self.descriptionLabel)
        
        let screenBounds = UIScreen.mainScreen().bounds

        scrollView.contentSize.width = self.view.bounds.width
        scrollView.autoPinEdgesToSuperviewEdges()

        containerView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero, excludingEdge: .Trailing)
        containerView.autoSetDimension(.Width, toSize: screenBounds.width)

        nameLabel.numberOfLines = 3
        nameLabel.autoPinEdgeToSuperviewMargin(.Top)
        nameLabel.autoPinEdgeToSuperviewMargin(.Left)
        nameLabel.autoPinEdgeToSuperviewMargin(.Right)
        
        dateLabel.autoPinEdge(.Top, toEdge: .Bottom, ofView: nameLabel, withOffset: 8)
        dateLabel.autoPinEdgeToSuperviewMargin(.Left)
        dateLabel.autoPinEdgeToSuperviewMargin(.Right)

        attendeesLabel.autoPinEdge(.Top, toEdge: .Bottom, ofView: dateLabel, withOffset: 8)
        attendeesLabel.autoPinEdgeToSuperviewMargin(.Left)
        attendeesLabel.autoPinEdgeToSuperviewMargin(.Right)

        addressLabel.autoPinEdge(.Top, toEdge: .Bottom, ofView: attendeesLabel, withOffset: 8)
        addressLabel.autoPinEdgeToSuperviewMargin(.Left)
        addressLabel.autoPinEdgeToSuperviewMargin(.Right)
        
        descriptionHeadingLabel.autoPinEdge(.Top, toEdge: .Bottom, ofView: addressLabel, withOffset: 8)
        descriptionHeadingLabel.autoPinEdgeToSuperviewMargin(.Left)
        descriptionHeadingLabel.autoPinEdgeToSuperviewMargin(.Right)
        
        descriptionLabel.autoPinEdge(.Top, toEdge: .Bottom, ofView: descriptionHeadingLabel, withOffset: 8)
        descriptionLabel.autoPinEdgeToSuperviewMargin(.Left)
        descriptionLabel.autoPinEdgeToSuperviewMargin(.Right)
    }

    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
