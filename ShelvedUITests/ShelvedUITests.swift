import XCTest

/// End-to-end flows through the real UI, driven like a user would.
///
/// UI tests are slow and brittle compared with unit tests, so there are
/// only a few, covering flows that cross several screens and tabs: the
/// wiring unit tests can't see. Everything else is tested at the
/// ViewModel level.
///
/// The app is launched with `-ui-testing`, which swaps in the offline
/// `PreviewCatalog` and an empty in-memory library (`Dependencies.forLaunch`).
/// No network, and every test starts from a clean slate.
///
/// XCTest, not Swift Testing: Swift Testing doesn't drive UI yet.
final class ShelvedUITests: XCTestCase {
    /// Must match `Dependencies.uiTestingArgument`. UI tests run in a separate
    /// process and can't import the app, so the string is repeated here.
    private static let uiTestingArgument = "-ui-testing"

    override func setUp() {
        continueAfterFailure = false
    }

    /// The Phase 5 flow: search → add to shelf → appears in Library.
    @MainActor
    func testAddedBookAppearsInLibrary() {
        let app = launch()

        app.tabBars.buttons["Search"].tap()
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        searchField.tap()
        searchField.typeText("dune")

        element(in: app, labelStartingWith: "Dune").tap()
        let addButton = app.buttons["Add to Shelf"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()
        app.buttons["Want to Read"].tap()

        app.tabBars.buttons["Library"].tap()
        element(in: app, labelStartingWith: "Want to Read").tap()

        XCTAssertTrue(element(in: app, labelStartingWith: "Dune").exists)
    }

    @MainActor
    func testRetappingTabPopsToRoot() {
        let app = launch()

        // Home has a shortcut to Dune.
        app.buttons["Dune"].tap()
        XCTAssertTrue(app.buttons["Add to Shelf"].waitForExistence(timeout: 5))

        app.tabBars.buttons["Home"].tap()

        XCTAssertTrue(app.navigationBars["Home"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Add to Shelf"].exists)
    }

    @MainActor
    func testCreatedShelfAppearsInMyShelves() {
        let app = launch()

        app.tabBars.buttons["Library"].tap()
        app.buttons["New Shelf"].tap()
        let nameField = app.alerts.textFields.firstMatch
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.typeText("Book Club")
        app.alerts.buttons["Create"].tap()

        XCTAssertTrue(element(in: app, labelStartingWith: "Book Club").exists)
    }

    /// Phase 5.5: search → series card → add the whole series → Library.
    @MainActor
    func testAddingASeriesFillsWantTo() {
        let app = launch()

        app.tabBars.buttons["Search"].tap()
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        searchField.tap()
        searchField.typeText("dune")

        // The card reads "Series, Dune, 3 books", so it doesn't clash with the "Dune" result row.
        element(in: app, labelStartingWith: "Series").tap()
        element(in: app, labelStartingWith: "Add").tap()

        app.tabBars.buttons["Library"].tap()
        element(in: app, labelStartingWith: "Want to Read").tap()

        XCTAssertTrue(element(in: app, labelStartingWith: "Dune Messiah").exists)
    }

    // MARK: - Helpers

    @MainActor
    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [Self.uiTestingArgument]
        app.launch()
        return app
    }

    /// Rows read as one combined label ("Dune, Frank Herbert, 1965"), so
    /// match the start rather than the whole string. Waits for it to appear.
    @MainActor
    private func element(in app: XCUIApplication, labelStartingWith prefix: String) -> XCUIElement {
        let element = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label BEGINSWITH %@", prefix))
            .firstMatch
        XCTAssertTrue(element.waitForExistence(timeout: 5), "No element starting with “\(prefix)”")
        return element
    }
}
