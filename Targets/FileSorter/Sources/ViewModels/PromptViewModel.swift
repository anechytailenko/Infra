import Foundation
import SwiftUI

// 1. Define the Contract Structure
struct MatchedFilesResponse: Codable {
    let matched_files: [String]
}

class PromptViewModel: ObservableObject {
    
    // MARK: - Hardcoded User Prompt
    let userPrompt: String = "Organize my downloads by file type"
    
    // MARK: - Graph State
    @Published var rootNode: FolderNode?
    @Published var activeFile: PromptFile?
    
    // MARK: - List State
    @Published var folderName: String = "Matched Results"
    @Published var files: [PromptFile] = []
    
    // Helpers
    var selectedCount: Int {
        files.filter { $0.isSelected }.count
    }
    
    var isAllSelected: Bool {
        !files.isEmpty && files.allSatisfy { $0.isSelected }
    }
    
    init() {
        loadData()
    }
    
    // MARK: - Actions
    
    func setActiveFile(_ file: PromptFile) {
        self.activeFile = file
    }
    
    func getParentFolder(for file: PromptFile) -> String? {
        let components = file.fullPath.components(separatedBy: "/")
        if components.count > 2 {
            return components[1]
        }
        return nil
    }
    
    func loadData() {
        // Initial Tree
        var root = FolderNode(name: "System", children: [
            FolderNode(name: "documents"),
            FolderNode(name: "downloads"),
            
            // TRICK STUB: "Projects" has child folders AND will contain a matched file
            FolderNode(name: "Projects", children: [
                FolderNode(name: "Old_Work"),
                FolderNode(name: "Pending")
            ]),
            
            FolderNode(name: "archives"),
            FolderNode(name: "music")
        ])
        
        let mockJSONResponse = """
        {
          "matched_files": [
            "/documents/report.pdf",
            "/downloads/invoice.pdf",
            "/Projects/urgent_specs.pdf", 
            "/archives/old-doc.pdf",
            "/documents/summary_q1.docx"
          ]
        }
        """
        
        if let data = mockJSONResponse.data(using: .utf8) {
            do {
                let decodedResponse = try JSONDecoder().decode(MatchedFilesResponse.self, from: data)
                
                self.files = decodedResponse.matched_files.map { path in
                    let randomSize = "\(Int.random(in: 100...5000)) KB"
                    return PromptFile(
                        path: path,
                        size: randomSize,
                        isSelected: false,
                        isMatched: true
                    )
                }
                
                let matchedFolderNames = Set(decodedResponse.matched_files.compactMap { path -> String? in
                    let components = path.components(separatedBy: "/")
                    if components.count > 2 { return components[1] }
                    return nil
                })
                
                updateMatches(in: &root, matchedNames: matchedFolderNames)
                self.rootNode = root
                
            } catch {
                print("Error decoding mock contract: \(error)")
                self.files = []
                self.rootNode = root
            }
        }
    }
    
    private func updateMatches(in node: inout FolderNode, matchedNames: Set<String>) {
        if matchedNames.contains(node.name) {
            node.isMatched = true
        }
        for i in 0..<node.children.count {
            updateMatches(in: &node.children[i], matchedNames: matchedNames)
        }
    }
    
    func toggleSelection(for id: UUID) {
        if let index = files.firstIndex(where: { $0.id == id }) {
            files[index].isSelected.toggle()
        }
    }
    
    func toggleSelectAll() {
        if isAllSelected {
            deselectAll()
        } else {
            selectAll()
        }
    }
    
    func selectAll() {
        for i in 0..<files.count { files[i].isSelected = true }
    }
    
    func deselectAll() {
        for i in 0..<files.count { files[i].isSelected = false }
    }
    
    func deleteSelected() {
        withAnimation {
            files.removeAll { $0.isSelected }
        }
    }
}
