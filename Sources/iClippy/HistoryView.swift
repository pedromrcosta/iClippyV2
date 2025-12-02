import SwiftUI
import AppKit

/// View model for the clipboard history window
class HistoryViewModel: ObservableObject {
    @Published var entries: [ClipboardEntry] = []
    @Published var searchQuery: String = ""
    
    private let dbManager: DBManager
    
    init(dbManager: DBManager) {
        self.dbManager = dbManager
        loadEntries()
    }
    
    func loadEntries() {
        if searchQuery.isEmpty {
            entries = dbManager.fetchAll(limit: 500)
        } else {
            entries = dbManager.search(query: searchQuery, limit: 500)
        }
    }
    
    func copyToClipboard(text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}

/// SwiftUI view for displaying clipboard history
struct HistoryView: View {
    @ObservedObject var viewModel: HistoryViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search clipboard history...", text: $viewModel.searchQuery)
                    .textFieldStyle(.plain)
                    .onChange(of: viewModel.searchQuery) { _ in
                        viewModel.loadEntries()
                    }
                
                if !viewModel.searchQuery.isEmpty {
                    Button(action: {
                        viewModel.searchQuery = ""
                        viewModel.loadEntries()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Entry list
            if viewModel.entries.isEmpty {
                VStack {
                    Spacer()
                    Text(viewModel.searchQuery.isEmpty ? "No clipboard history yet" : "No matches found")
                        .foregroundColor(.gray)
                    Spacer()
                }
            } else {
                List {
                    ForEach(viewModel.entries) { entry in
                        EntryRow(entry: entry)
                            .onTapGesture {
                                viewModel.copyToClipboard(text: entry.text)
                                dismiss()
                            }
                    }
                }
                .listStyle(.plain)
            }
        }
        .frame(width: 600, height: 400)
        .onAppear {
            viewModel.loadEntries()
        }
    }
}

/// Row view for a single clipboard entry
struct EntryRow: View {
    let entry: ClipboardEntry
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: entry.date)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.text)
                .lineLimit(3)
                .font(.system(.body))
            
            Text(formattedDate)
                .font(.system(.caption))
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
    }
}
