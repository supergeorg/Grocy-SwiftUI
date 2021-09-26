//
//  LogView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 16.02.21.
//

import SwiftUI
import UniformTypeIdentifiers
import OSLog

struct LogView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @State private var logEntries: [OSLogEntryLog] = []
    
    @State private var exportLog: ExportLog = ExportLog(content: Data())
    @State var isExporting: Bool = false
    
    struct ExportLog: FileDocument {
        static var readableContentTypes: [UTType] { [.plainText] }
        
        var content: Data
        init(content: Data) {
            self.content = content
        }
        init(configuration: ReadConfiguration) throws {
            guard let data = configuration.file.regularFileContents
            else {
                throw CocoaError(.fileReadCorruptFile)
            }
            content = data
        }
        func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
            return FileWrapper(regularFileWithContents: content)
        }
    }
    
    func shareFile() {
        if let logData = logEntries.map({ "\(formatDateAsString($0.date)): \($0.composedMessage)" }).joined(separator: "\n").data(using: .utf8) {
            exportLog = ExportLog(content: logData)
            isExporting = true
        } else {
            print("Error exporting log")
        }
    }
    
    func updateLog() {
        do {
            logEntries = try grocyVM.getLogEntries()
        } catch {
            logEntries = []
        }
    }
    
    var body: some View {
        #if os(macOS)
        List {
            contentmacOS
                .padding()
                .frame(width: 500, height: 500)
        }
        #elseif os(iOS)
        content
            .navigationTitle(LocalizedStringKey("str.settings.log"))
            .toolbar(content: {
                ToolbarItemGroup(placement: .automatic, content: {
                        Button(action: {
                            shareFile()
                        }, label: { Image(systemName: MySymbols.share) })
                })
            })
        #endif
    }
    
    var content: some View {
        List {
            ForEach(logEntries.reversed(), id: \.self) { logEntry in
                VStack(alignment: .leading) {
                    Text(formatDateAsString(logEntry.date))
                        .font(.caption)
                    Text(logEntry.composedMessage)
                }
            }
        }
        .onAppear(perform: updateLog)
        .refreshable {
            updateLog()
        }
        .fileExporter(
            isPresented: $isExporting,
            document: exportLog,
            contentType: .plainText,
            defaultFilename: "Grocy-SwiftUI_LOG.log"
        ) { result in
            if case .success = result {
                print("Export successful.")
            } else {
                print("Export failed.")
            }
        }
    }
}

struct LogView_Previews: PreviewProvider {
    static var previews: some View {
        #if os(iOS)
        NavigationView{
            LogView()
        }
        #else
        LogView()
        #endif
    }
}
