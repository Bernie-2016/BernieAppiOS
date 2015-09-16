import Foundation
import Quick
import Nimble
import berniesanders

class ConcreteIssueDeserializerSpec : QuickSpec {
    var subject: ConcreteIssueDeserializer!
    
    override func spec() {
        beforeEach {
            self.subject = ConcreteIssueDeserializer()
        }
        
        it("deserializes the issues correctly") {
            let data = TestUtils.dataFromFixtureFileNamed("issue_feed", type: "json")
            var error: NSError?
            
            let jsonDictionary = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.allZeros, error: &error) as!
            NSDictionary
            
            var issues = self.subject.deserializeIssues(jsonDictionary)
            
            expect(issues.count).to(equal(2))
            var issueA = issues[0]
            expect(issueA.title).to(equal("Income and Wealth Inequality"))
            expect(issueA.body).to(equal("\nToday, we live in the richest country in the history of the world, but that reality means little because much of that wealth is controlled by a tiny handful of individuals."))
            expect(issueA.imageURL).to(beNil())
            expect(issueA.URL).to(equal(NSURL(string: "https://berniesanders.com/issues/income-and-wealth-inequality/")!))
            
            var issueB = issues[1]
            expect(issueB.title).to(equal("Getting Big Money Out of Politics"))
            expect(issueB.body).to(equal("\nFreedom of speech does not mean the freedom to buy the United States government."))
            expect(issueB.imageURL).to(beNil())
            expect(issueB.URL).to(equal(NSURL(string: "https://berniesanders.com/issues/money-in-politics/")))
        }
        
        
        context("when title, body or url are missing") {
            it("should not explode and ignore stories that lack them") {
                let data = TestUtils.dataFromFixtureFileNamed("dodgy_issue_feed", type: "json")
                
                var error: NSError?
                
                let jsonDictionary = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.allZeros, error: &error) as! NSDictionary
                var issues = self.subject.deserializeIssues(jsonDictionary)
                
                expect(issues.count).to(equal(1))
                var issue = issues[0]
                expect(issue.title).to(equal("This is good news"))
            }
            
        }
        context("when there's not enough hits") {
            it("should not explode") {
                var issues = self.subject.deserializeIssues([String: AnyObject]())
                expect(issues.count).to(equal(0))
                
                issues = self.subject.deserializeIssues(["hits": [String: AnyObject]()])
                expect(issues.count).to(equal(0))
                
                issues = self.subject.deserializeIssues(["hits": [ "hits": [String: AnyObject]()]])
                expect(issues.count).to(equal(0))
            }
        }
    }
}

