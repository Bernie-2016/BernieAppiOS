import UIKit
import Quick
import Nimble
@testable import berniesanders
import QuartzCore

class EventsFakeTheme : FakeTheme {
    override func tabBarActiveTextColor() -> UIColor {
        return UIColor.purpleColor()
    }

    override func tabBarInactiveTextColor() -> UIColor {
        return UIColor.magentaColor()
    }

    override func tabBarFont() -> UIFont {
        return UIFont.systemFontOfSize(123)
    }

    override func eventsListFont() -> UIFont {
        return UIFont.italicSystemFontOfSize(333)
    }

    override func eventsListColor() -> UIColor {
        return UIColor.yellowColor()
    }

    override func eventsInputAccessoryBackgroundColor() -> UIColor {
        return UIColor.greenColor()
    }

    override func eventsZipCodeTextColor() -> UIColor {
        return UIColor.redColor()
    }

    override func eventsZipCodeBackgroundColor() -> UIColor {
        return UIColor.brownColor()
    }

    override func eventsZipCodeBorderColor() -> UIColor {
        return UIColor.orangeColor()
    }

    override func eventsZipCodeFont() -> UIFont {
        return UIFont.boldSystemFontOfSize(4444)
    }

    override func eventsZipCodeCornerRadius() -> CGFloat {
        return 100.0
    }

    override func eventsZipCodeBorderWidth() -> CGFloat {
        return 200.0
    }

    override func eventsZipCodeTextOffset() -> CATransform3D {
        return CATransform3DMakeTranslation(4, 5, 6);
    }

    override func eventsGoButtonCornerRadius() -> CGFloat {
        return 300
    }

    override func eventsNoResultsFont() -> UIFont {
        return UIFont.italicSystemFontOfSize(888)
    }

    override func eventsNoResultsTextColor() -> UIColor {
        return UIColor.blueColor()
    }

    override func defaultSpinnerColor() -> UIColor {
        return UIColor.blackColor()
    }

    override func eventsInstructionsFont() -> UIFont {
        return UIFont.italicSystemFontOfSize(666)
    }

    override func eventsInstructionsTextColor() -> UIColor {
        return UIColor.whiteColor()
    }
}

class FakeEventRepository : EventRepository {
    var lastReceivedZipCode : NSString?
    var lastReceivedRadiusMiles : Float?
    var lastCompletionBlock: ((Array<Event>) -> Void)?
    var lastErrorBlock: ((NSError) -> Void)?

    func fetchEventsWithZipCode(zipCode: String, radiusMiles: Float, completion: (Array<Event>) -> Void, error: (NSError) -> Void) {
        self.lastReceivedZipCode = zipCode
        self.lastReceivedRadiusMiles = radiusMiles
        self.lastCompletionBlock = completion
        self.lastErrorBlock = error
    }
}

class FakeEventControllerProvider : berniesanders.EventControllerProvider {
    let controller = EventController(
        event: TestUtils.eventWithName("some event"),
        eventPresenter: FakeEventPresenter(dateFormatter: FakeDateFormatter()),
        eventRSVPControllerProvider: FakeEventRSVPControllerProvider(),
        urlProvider: FakeURLProvider(),
        urlOpener: FakeURLOpener(),
        analyticsService: FakeAnalyticsService(),
        theme: FakeTheme())
    var lastEvent: Event?

    init() {}

    func provideInstanceWithEvent(event: Event) -> EventController {
        self.lastEvent = event
        return self.controller
    }
}

class EventsControllerSpec : QuickSpec {
    var subject : EventsController!
    var window : UIWindow!
    var eventRepository : FakeEventRepository!
    var eventPresenter : FakeEventPresenter!
    let settingsController = TestUtils.settingsController()
    var eventControllerProvider : FakeEventControllerProvider!
    var analyticsService: FakeAnalyticsService!
    var tabBarItemStylist: FakeTabBarItemStylist!
    var navigationController: UINavigationController!

    override func spec() {
        describe("EventsController") {
            beforeEach {
                self.eventRepository = FakeEventRepository()
                self.eventPresenter = FakeEventPresenter(dateFormatter: FakeDateFormatter())
                self.eventControllerProvider = FakeEventControllerProvider()
                self.tabBarItemStylist = FakeTabBarItemStylist()
                self.analyticsService = FakeAnalyticsService()

                self.window = UIWindow()

                self.subject = EventsController(
                    eventRepository: self.eventRepository,
                    eventPresenter: self.eventPresenter,
                    settingsController: self.settingsController,
                    eventControllerProvider: self.eventControllerProvider,
                    analyticsService: self.analyticsService,
                    tabBarItemStylist: self.tabBarItemStylist,
                    theme: EventsFakeTheme()
                )

                self.navigationController = UINavigationController()
                self.navigationController.pushViewController(self.subject, animated: false)

                self.window.addSubview(self.subject.view)
                self.window.makeKeyAndVisible()

                self.subject.view.layoutSubviews()
            }

            afterEach {
                self.window = nil
            }

            it("has the correct tab bar title") {
                expect(self.subject.title).to(equal("Events"))
            }

            it("has the correct navigation item title") {
                expect(self.subject.navigationItem.title).to(equal("Events"))
            }

            it("should set the back bar button item title correctly") {
                expect(self.subject.navigationItem.backBarButtonItem?.title).to(equal("Back"))
            }

            describe("tapping on the settings button") {
                beforeEach {
                    self.subject.navigationItem.rightBarButtonItem!.tap()
                }

                it("should push the settings controller onto the nav stack") {
                    expect(self.subject.navigationController!.topViewController).to(beIdenticalTo(self.settingsController))
                }

                it("tracks a custom event via the analytics service") {
                    expect(self.analyticsService.lastCustomEventName).to(equal("Tapped 'Settings' in Events nav bar"))
                    expect(self.analyticsService.lastCustomEventAttributes).to(beNil())
                }
            }

            it("uses the tab bar item stylist to style its tab bar item") {
                expect(self.tabBarItemStylist.lastReceivedTabBarItem).to(beIdenticalTo(self.subject.tabBarItem))

                expect(self.tabBarItemStylist.lastReceivedTabBarImage).to(equal(UIImage(named: "eventsTabBarIconInactive")))
                expect(self.tabBarItemStylist.lastReceivedTabBarSelectedImage).to(equal(UIImage(named: "eventsTabBarIcon")))
            }

            it("should add its view components as subviews") {
                let subViews = self.subject.view.subviews

                expect(subViews.contains(self.subject.zipCodeTextField)).to(beTrue())
                expect(subViews.contains(self.subject.instructionsLabel)).to(beTrue())
                expect(subViews.contains(self.subject.noResultsLabel)).to(beTrue())
                expect(subViews.contains(self.subject.resultsTableView)).to(beTrue())
                expect(subViews.contains(self.subject.loadingActivityIndicatorView)).to(beTrue())
            }

            it("should hide the results table view by default") {
                expect(self.subject.resultsTableView.hidden).to(beTrue())
            }

            it("should hide the no results label by default") {
                expect(self.subject.noResultsLabel.hidden).to(beTrue())
            }

            it("should hide the spinner by default") {
                expect(self.subject.loadingActivityIndicatorView.isAnimating()).to(beFalse())
            }

            it("should show the instructions by default") {
                expect(self.subject.instructionsLabel.hidden).to(beFalse())
                expect(self.subject.instructionsLabel.text).to(equal("Enter your ZIP code above to find Bernie events near you!"))
            }

            it("configures the keyboard to be a number pad") {
                expect(self.subject.zipCodeTextField.keyboardType).to(equal(UIKeyboardType.NumberPad))
            }

            it("styles the page components with the theme") {
                expect(self.subject.zipCodeTextField.backgroundColor).to(equal(UIColor.brownColor()))
                expect(self.subject.zipCodeTextField.font).to(equal(UIFont.boldSystemFontOfSize(4444)))
                expect(self.subject.zipCodeTextField.textColor).to(equal(UIColor.redColor()))
                expect(self.subject.zipCodeTextField.layer.cornerRadius).to(equal(100.0))
                expect(self.subject.zipCodeTextField.layer.borderWidth).to(equal(200.0))


                // TODO: Figure out how to test this.
                //                expect(self.subject.zipCodeTextField.layer.sublayerTransform).to(equal(CATransform3DMakeTranslation(4, 5, 6)))


                // TODO: why does this not compile?
                //                var a = self.subject.zipCodeTextField.layer.borderColor
                //                var b = UIColor.orangeColor().CGColor
                //                expect(a).to(equal(b))

                expect(self.subject.instructionsLabel.textColor).to(equal(UIColor.whiteColor()))
                expect(self.subject.instructionsLabel.font).to(equal(UIFont.italicSystemFontOfSize(666)))

                expect(self.subject.noResultsLabel.font).to(equal(UIFont.italicSystemFontOfSize(888)))
                expect(self.subject.noResultsLabel.textColor).to(equal(UIColor.blueColor()))

                expect(self.subject.loadingActivityIndicatorView.color).to(equal(UIColor.blackColor()))
            }

            it("has an input accessory view for the zip code entry field") {
                let inputToolbar = self.subject.zipCodeTextField.inputAccessoryView as! UIToolbar
                let cancelButton = inputToolbar.items![1]

                expect(cancelButton.title).to(equal("Close"))
            }

                context("when entering a valid zip code") {
                    beforeEach {
                        self.subject.zipCodeTextField.becomeFirstResponder()

                        expect(self.subject.zipCodeTextField.isFirstResponder()).to(beTrue())

                        self.subject.zipCodeTextField.text = "90210"
                    }

                    xit("should log an event via the analytics service") {
                        // TODO: test is failing on Travis, so marking as pending for now.
                        expect(self.analyticsService.lastCustomEventName).to(equal("Tapped on ZIP Code text field on Events"))
                        expect(self.analyticsService.lastCustomEventAttributes).to(beNil())
                    }

                    describe("aborting a search") {
                        beforeEach {
                            let inputToolbar = self.subject.zipCodeTextField.inputAccessoryView as! UIToolbar
                            let cancelButton = inputToolbar.items![2]
                            cancelButton.tap()
                        }

                        it("should resign first responder") {
                            expect(self.subject.zipCodeTextField.isFirstResponder()).to(beFalse())
                        }

                        xit("should log an event via the analytics service") {
                            // TODO: test is failing on Travis, so marking as pending for now.
                            expect(self.analyticsService.lastCustomEventName).to(equal("Cancelled ZIP Code search on Events"))
                            expect(self.analyticsService.lastCustomEventAttributes).to(beNil())
                        }
                    }

                    describe("and then tapping search") {
                        beforeEach {
                            let doneButton = self.subject.zipCodeSearchButton
                            doneButton.tap()
                        }

                        it("should resign first responder") {
                            expect(self.subject.zipCodeTextField.isFirstResponder()).to(beFalse())
                        }

                        it("should show the spinner") {
                            expect(self.subject.loadingActivityIndicatorView.isAnimating()).to(beTrue())
                        }

                        it("should hide the instructions") {
                            expect(self.subject.instructionsLabel.hidden).to(beTrue())
                        }

                        it("should ask the events repository for events within 50 miles") {
                            expect(self.eventRepository.lastReceivedZipCode).to(equal("90210"))
                            expect(self.eventRepository.lastReceivedRadiusMiles).to(equal(50.0))
                        }

                        it("should log an event via the analytics service") {
                            expect(self.analyticsService.lastSearchQuery).to(equal("90210"))
                            expect(self.analyticsService.lastSearchContext).to(equal(AnalyticsSearchContext.Events))
                        }

                        context("when the search results in an error") {
                            let expectedError = NSError(domain: "someerror", code: 0, userInfo: nil)
                            beforeEach {
                                self.eventRepository.lastErrorBlock!(expectedError)
                            }

                            it("should hide the spinner") {
                                expect(self.subject.loadingActivityIndicatorView.isAnimating()).to(beFalse())
                            }

                            it("should log an event via the analytics service") {
                                expect(self.analyticsService.lastError).to(beIdenticalTo(expectedError))
                                expect(self.analyticsService.lastErrorContext).to(equal("Events"))
                            }

                            it("should display a no results message") {
                                expect(self.subject.noResultsLabel.hidden).to(beFalse())
                                expect(self.subject.noResultsLabel.text).to(equal("No events match your search"))
                            }

                            it("should leave the table view hidden") {
                                expect(self.subject.resultsTableView.hidden).to(beTrue())
                            }

                            describe("making a subsequent search") {
                                beforeEach {
                                    self.subject.zipCodeTextField.text = "11111"

                                    let inputToolbar = self.subject.zipCodeTextField.inputAccessoryView as! UIToolbar
                                    let doneButton = inputToolbar.items![1]
                                    doneButton.tap()
                                }

                                it("should hide the no results message") {
                                    expect(self.subject.noResultsLabel.hidden).to(beTrue())
                                }

                                it("should show the spinner") {
                                    expect(self.subject.loadingActivityIndicatorView.isAnimating()).to(beTrue())
                                }

                                it("should ask the events repository for events within 50 miles") {
                                    expect(self.eventRepository.lastReceivedZipCode).to(equal("11111"))
                                    expect(self.eventRepository.lastReceivedRadiusMiles).to(equal(50.0))
                                }
                            }
                        }

                        context("when the search completes succesfully") {
                            context("with no results") {
                                beforeEach {
                                    let events : Array<Event> = []
                                    self.eventRepository.lastCompletionBlock!(events)
                                }

                                it("should hide the spinner") {
                                    expect(self.subject.loadingActivityIndicatorView.isAnimating()).to(beFalse())
                                }

                                it("should display a no results message") {
                                    expect(self.subject.noResultsLabel.hidden).to(beFalse())
                                    expect(self.subject.noResultsLabel.text).to(equal("No events match your search"))
                                }

                                it("should leave the table view hidden") {
                                    expect(self.subject.resultsTableView.hidden).to(beTrue())
                                }

                                describe("making a subsequent search") {
                                    beforeEach {
                                        self.subject.zipCodeTextField.text = "11111"

                                        let inputToolbar = self.subject.zipCodeTextField.inputAccessoryView as! UIToolbar
                                        let doneButton = inputToolbar.items![1]
                                        doneButton.tap()
                                    }

                                    it("should hide the no results message") {
                                        expect(self.subject.noResultsLabel.hidden).to(beTrue())
                                    }

                                    it("should show the spinner by default") {
                                        expect(self.subject.loadingActivityIndicatorView.isAnimating()).to(beTrue())
                                    }

                                    it("should ask the events repository for events within 50 miles") {
                                        expect(self.eventRepository.lastReceivedZipCode).to(equal("11111"))
                                        expect(self.eventRepository.lastReceivedRadiusMiles).to(equal(50.0))
                                    }
                                }
                            }

                            context("with some results") {
                                let eventA = TestUtils.eventWithName("Bigtime Bernie BBQ")
                                let eventB = TestUtils.eventWithName("Slammin' Sanders Salsa Serenade")

                                beforeEach {
                                    let events : Array<Event> = [eventA, eventB]
                                    self.eventRepository.lastCompletionBlock!(events)
                                }


                                it("should hide the spinner") {
                                    expect(self.subject.loadingActivityIndicatorView.isAnimating()).to(beFalse())
                                }

                                it("should leave the no results message hidden") {
                                    expect(self.subject.noResultsLabel.hidden).to(beTrue())
                                }

                                it("should show the results table") {
                                    expect(self.subject.resultsTableView.hidden).to(beFalse())
                                }


                                describe("the results table") {
                                    it("uses the presenter to set up the returned cells from the search results") {
                                        expect(self.subject.resultsTableView.numberOfSections).to(equal(1))
                                        expect(self.subject.resultsTableView.numberOfRowsInSection(0)).to(equal(2))

                                        let cellA = self.subject.resultsTableView.dataSource!.tableView(self.subject.resultsTableView, cellForRowAtIndexPath: NSIndexPath(forRow: 0, inSection: 0)) as! EventListTableViewCell

                                        expect(self.eventPresenter.lastReceivedEvent).to(beIdenticalTo(eventA))
                                        expect(self.eventPresenter.lastReceivedCell).to(beIdenticalTo(cellA))

                                        let cellB = self.subject.resultsTableView.dataSource!.tableView(self.subject.resultsTableView, cellForRowAtIndexPath: NSIndexPath(forRow: 1, inSection: 0)) as! EventListTableViewCell

                                        expect(self.eventPresenter.lastReceivedEvent).to(beIdenticalTo(eventB))
                                        expect(self.eventPresenter.lastReceivedCell).to(beIdenticalTo(cellB))
                                    }

                                    it("styles the cells from the theme") {
                                        let cell = self.subject.resultsTableView.dataSource!.tableView(self.subject.resultsTableView, cellForRowAtIndexPath:NSIndexPath(forRow: 0, inSection: 0)) as! EventListTableViewCell

                                        expect(cell.nameLabel.font).to(equal(UIFont.italicSystemFontOfSize(333)))
                                        expect(cell.addressLabel.font).to(equal(UIFont.italicSystemFontOfSize(333)))
                                        expect(cell.attendeesLabel.font).to(equal(UIFont.italicSystemFontOfSize(333)))

                                        expect(cell.nameLabel.textColor).to(equal(UIColor.yellowColor()))
                                        expect(cell.addressLabel.textColor).to(equal(UIColor.yellowColor()))
                                        expect(cell.attendeesLabel.textColor).to(equal(UIColor.yellowColor()))
                                    }

                                    describe("tapping on an event") {
                                        beforeEach {
                                            let tableView = self.subject.resultsTableView
                                            tableView.delegate!.tableView!(tableView, didSelectRowAtIndexPath: NSIndexPath(forRow: 1, inSection: 0))
                                        }

                                        it("should push a correctly configured news item view controller onto the nav stack") {
                                            expect(self.eventControllerProvider.lastEvent).to(beIdenticalTo(eventB))
                                            expect(self.subject.navigationController!.topViewController).to(beIdenticalTo(self.eventControllerProvider.controller))
                                        }

                                        it("tracks the content view with the analytics service") {
                                            expect(self.analyticsService.lastContentViewName).to(equal(eventB.name))
                                            expect(self.analyticsService.lastContentViewType).to(equal(AnalyticsServiceContentType.Event))
                                            expect(self.analyticsService.lastContentViewID).to(equal(eventB.url.absoluteString))
                                        }
                                    }
                                }

                                describe("making a subsequent search") {
                                    beforeEach {
                                        self.subject.zipCodeTextField.text = "11111"

                                        let inputToolbar = self.subject.zipCodeTextField.inputAccessoryView as! UIToolbar
                                        let doneButton = inputToolbar.items![1]
                                        doneButton.tap()
                                    }

                                    it("should hide the results table view") {
                                        expect(self.subject.resultsTableView.hidden).to(beTrue())
                                    }


                                    it("should show the spinner") {
                                        expect(self.subject.loadingActivityIndicatorView.isAnimating()).to(beTrue())
                                    }

                                    it("should ask the events repository for events within 50 miles") {
                                        expect(self.eventRepository.lastReceivedZipCode).to(equal("11111"))
                                        expect(self.eventRepository.lastReceivedRadiusMiles).to(equal(50.0))
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

