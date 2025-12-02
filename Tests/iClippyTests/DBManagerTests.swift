import XCTest
@testable import iClippy

final class DBManagerTests: XCTestCase {
    var dbManager: DBManager!
    var tempDBPath: String!
    
    override func setUp() {
        super.setUp()
        // Create a temporary database file for testing
        let tempDir = FileManager.default.temporaryDirectory
        tempDBPath = tempDir.appendingPathComponent("test_iclippy_\(UUID().uuidString).sqlite3").path
        dbManager = DBManager(databasePath: tempDBPath)
    }
    
    override func tearDown() {
        // Clean up the temporary database file
        try? FileManager.default.removeItem(atPath: tempDBPath)
        super.tearDown()
    }
    
    func testAddEntry() {
        // Test adding a text entry
        dbManager.add(text: "Hello, World!")
        
        let entries = dbManager.fetchAll()
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.text, "Hello, World!")
    }
    
    func testAddEmptyTextIgnored() {
        // Empty strings should be ignored
        dbManager.add(text: "")
        dbManager.add(text: "   ")
        dbManager.add(text: "\n\t")
        
        let entries = dbManager.fetchAll()
        XCTAssertEqual(entries.count, 0)
    }
    
    func testNoDuplicates() {
        // Adding the same text multiple times should only store it once
        dbManager.add(text: "Duplicate text")
        dbManager.add(text: "Duplicate text")
        dbManager.add(text: "Duplicate text")
        
        let entries = dbManager.fetchAll()
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.text, "Duplicate text")
    }
    
    func testTrimsWhitespace() {
        // Whitespace should be trimmed
        dbManager.add(text: "  Trimmed text  ")
        
        let entries = dbManager.fetchAll()
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.text, "Trimmed text")
    }
    
    func testFetchAllLimit() {
        // Add more entries than the limit
        for i in 0..<10 {
            dbManager.add(text: "Entry \(i)")
        }
        
        let entries = dbManager.fetchAll(limit: 5)
        XCTAssertEqual(entries.count, 5)
        
        // Should be ordered by most recent first (Entry 9 should be first)
        XCTAssertEqual(entries.first?.text, "Entry 9")
    }
    
    func testSearchQuery() {
        // Add test entries
        dbManager.add(text: "Hello World")
        dbManager.add(text: "Goodbye World")
        dbManager.add(text: "Hello Swift")
        dbManager.add(text: "Testing")
        
        // Search for entries containing "Hello"
        let helloResults = dbManager.search(query: "Hello")
        XCTAssertEqual(helloResults.count, 2)
        
        // Search for entries containing "World"
        let worldResults = dbManager.search(query: "World")
        XCTAssertEqual(worldResults.count, 2)
        
        // Search for entries containing "Swift"
        let swiftResults = dbManager.search(query: "Swift")
        XCTAssertEqual(swiftResults.count, 1)
        XCTAssertEqual(swiftResults.first?.text, "Hello Swift")
    }
    
    func testSearchEmptyQuery() {
        // Empty search query should return all entries
        dbManager.add(text: "Entry 1")
        dbManager.add(text: "Entry 2")
        dbManager.add(text: "Entry 3")
        
        let results = dbManager.search(query: "")
        XCTAssertEqual(results.count, 3)
    }
    
    func testSearchNoMatches() {
        // Search with no matches should return empty array
        dbManager.add(text: "Entry 1")
        dbManager.add(text: "Entry 2")
        
        let results = dbManager.search(query: "NonExistent")
        XCTAssertEqual(results.count, 0)
    }
    
    func testDatabasePath() {
        // Test that database path is correctly returned
        XCTAssertEqual(dbManager.databasePath(), tempDBPath)
    }
    
    func testDefaultManager() {
        // Test default manager creates DB in Application Support
        let defaultManager = DBManager.defaultManager()
        let path = defaultManager.databasePath()
        
        XCTAssertTrue(path.contains("Application Support"))
        XCTAssertTrue(path.contains("iClippy"))
        XCTAssertTrue(path.hasSuffix("iclippy.sqlite3"))
    }
    
    func testOrderByMostRecent() {
        // Add entries with slight delays to ensure different timestamps.
        // Note: Using Thread.sleep here because timestamps are generated
        // internally by DBManager. To avoid this, we'd need to inject
        // a time provider into DBManager, which would complicate the API.
        dbManager.add(text: "First")
        Thread.sleep(forTimeInterval: 0.1)
        dbManager.add(text: "Second")
        Thread.sleep(forTimeInterval: 0.1)
        dbManager.add(text: "Third")
        
        let entries = dbManager.fetchAll()
        XCTAssertEqual(entries.count, 3)
        // Most recent should be first
        XCTAssertEqual(entries[0].text, "Third")
        XCTAssertEqual(entries[1].text, "Second")
        XCTAssertEqual(entries[2].text, "First")
    }
}
