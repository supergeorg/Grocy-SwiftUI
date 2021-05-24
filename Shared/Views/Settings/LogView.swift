//
//  LogView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 16.02.21.
//

import SwiftUI
import UniformTypeIdentifiers

struct LogView: View {
    @StateObject var grocyVM: GrocyViewModel = .shared
    
    @State private var logText: [String] = []
    
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
        do {
            let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            #if os(macOS)
            let logFolder = cachesDirectory.appendingPathComponent("Grocy-SwiftUI/")
            #elseif os(iOS)
            let logFolder = cachesDirectory
            #endif
            let filePath = logFolder.appendingPathComponent("swiftybeaver.log")
            print(filePath.absoluteString)
            let fileData = try Data(contentsOf: filePath)
            exportLog = ExportLog(content: fileData)
            isExporting = true
        } catch {
            print("Error")
        }
    }
    
    func updateLog() {
        logText = grocyVM.getLog()
    }
    
    var body: some View {
        #if os(macOS)
        ScrollView{
            content
                .padding()
                .frame(width: 500, height: 500)
        }
        #elseif os(iOS)
        content
            .navigationTitle(LocalizedStringKey("str.settings.log"))
            .toolbar(content: {
                ToolbarItemGroup(placement: .automatic, content: {
                    HStack{
                        Button(action: {
                            shareFile()
                        }, label: { Image(systemName: MySymbols.share) })
                        Button(action: {
                            updateLog()
                        }, label: {
                            Label("str.settings.log.update", systemImage: MySymbols.reload)
                        })
                    }
                })
            })
        #endif
    }
    
    var content: some View {
        Form{
            #if os(macOS)
            Button(action: {
                updateLog()
            }, label: {
                Label("str.settings.log.update", systemImage: MySymbols.reload)
            })
            if !logText.isEmpty {
                Button(action: {
                    shareFile()
                }, label: {
                    Label(LocalizedStringKey("str.settings.log.share"), systemImage: MySymbols.share)
                })
            }
            #endif
            ForEach(logText, id: \.self) {text in
                Text(text)
            }
        }
        .onAppear(perform: updateLog)
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
