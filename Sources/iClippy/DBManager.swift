import Foundation
import SQLite3

/// Manages the SQLite database for clipboard history
class DBManager {
    private var db: OpaquePointer?
    private let dbPath: String
    
    /// Initialize with a custom database path
    init(databasePath: String) {
        self.dbPath = databasePath
        openDatabase()
        createTableIfNeeded()
    }
    
    /// Create a default manager using Application Support directory
    static func defaultManager() -> DBManager {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let clippyDir = appSupport.appendingPathComponent("iClippy")
        
        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: clippyDir, withIntermediateDirectories: true)
        
        let dbPath = clippyDir.appendingPathComponent("iclippy.sqlite3").path
        return DBManager(databasePath: dbPath)
    }
    
    /// Get the database file path
    func databasePath() -> String {
        return dbPath
    }
    
    private func openDatabase() {
        if sqlite3_open(dbPath, &db) != SQLITE_OK {
            print("Error opening database at \(dbPath)")
        }
    }
    
    private func createTableIfNeeded() {
        let createTableSQL = """
        CREATE TABLE IF NOT EXISTS entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            text TEXT UNIQUE NOT NULL,
            created_at INTEGER NOT NULL
        );
        CREATE INDEX IF NOT EXISTS idx_created_at ON entries(created_at DESC);
        """
        
        var createTableStatement: OpaquePointer?
        if sqlite3_prepare_v2(db, createTableSQL, -1, &createTableStatement, nil) == SQLITE_OK {
            if sqlite3_step(createTableStatement) != SQLITE_DONE {
                print("Error creating table")
            }
        }
        sqlite3_finalize(createTableStatement)
    }
    
    /// Add a text entry to the database (ignores duplicates)
    func add(text: String) {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        let insertSQL = "INSERT OR IGNORE INTO entries (text, created_at) VALUES (?, ?);"
        var insertStatement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, insertSQL, -1, &insertStatement, nil) == SQLITE_OK {
            let timestamp = Int(Date().timeIntervalSince1970)
            sqlite3_bind_text(insertStatement, 1, (trimmedText as NSString).utf8String, -1, nil)
            sqlite3_bind_int64(insertStatement, 2, Int64(timestamp))
            
            if sqlite3_step(insertStatement) != SQLITE_DONE {
                print("Error inserting entry")
            }
        }
        sqlite3_finalize(insertStatement)
    }
    
    /// Fetch all entries, limited by count, ordered by most recent first
    func fetchAll(limit: Int = 500) -> [ClipboardEntry] {
        let querySQL = "SELECT id, text, created_at FROM entries ORDER BY created_at DESC LIMIT ?;"
        var queryStatement: OpaquePointer?
        var entries: [ClipboardEntry] = []
        
        if sqlite3_prepare_v2(db, querySQL, -1, &queryStatement, nil) == SQLITE_OK {
            sqlite3_bind_int(queryStatement, 1, Int32(limit))
            
            while sqlite3_step(queryStatement) == SQLITE_ROW {
                let id = Int(sqlite3_column_int64(queryStatement, 0))
                let text = String(cString: sqlite3_column_text(queryStatement, 1))
                let createdAt = Int(sqlite3_column_int64(queryStatement, 2))
                
                entries.append(ClipboardEntry(id: id, text: text, createdAt: createdAt))
            }
        }
        sqlite3_finalize(queryStatement)
        return entries
    }
    
    /// Search for entries matching the query string
    func search(query: String, limit: Int = 500) -> [ClipboardEntry] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            return fetchAll(limit: limit)
        }
        
        let searchSQL = "SELECT id, text, created_at FROM entries WHERE text LIKE ? ORDER BY created_at DESC LIMIT ?;"
        var searchStatement: OpaquePointer?
        var entries: [ClipboardEntry] = []
        
        if sqlite3_prepare_v2(db, searchSQL, -1, &searchStatement, nil) == SQLITE_OK {
            let searchPattern = "%\(trimmedQuery)%"
            sqlite3_bind_text(searchStatement, 1, (searchPattern as NSString).utf8String, -1, nil)
            sqlite3_bind_int(searchStatement, 2, Int32(limit))
            
            while sqlite3_step(searchStatement) == SQLITE_ROW {
                let id = Int(sqlite3_column_int64(searchStatement, 0))
                let text = String(cString: sqlite3_column_text(searchStatement, 1))
                let createdAt = Int(sqlite3_column_int64(searchStatement, 2))
                
                entries.append(ClipboardEntry(id: id, text: text, createdAt: createdAt))
            }
        }
        sqlite3_finalize(searchStatement)
        return entries
    }
    
    deinit {
        sqlite3_close(db)
    }
}

/// Represents a clipboard entry
struct ClipboardEntry: Identifiable, Equatable {
    let id: Int
    let text: String
    let createdAt: Int
    
    var date: Date {
        Date(timeIntervalSince1970: TimeInterval(createdAt))
    }
}
