import Foundation

struct SortingResponse {
    let updatedTree: FileSystemNode
    let moves: [FileMoveAction]
}

class SortingService {
    
    // Send the tree to AI and get back suggestions + updated tree with new folders
    func fetchSuggestions(for root: FileSystemNode) async throws -> SortingResponse {
        
        // ---------------------------------------------------------
        // REAL SERVER CODE (Commented out for future use)
        // ---------------------------------------------------------
        /*
        guard let url = URL(string: "http://localhost:3000/api/ai/sort") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // We send the current tree so the AI knows the context
        // request.httpBody = try JSONEncoder().encode(root)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(SortingResponse.self, from: data)
        */
        
        // ---------------------------------------------------------
                // MOCK DATA (Active)
                // ---------------------------------------------------------
                try? await Task.sleep(nanoseconds: 2 * 1_000_000_000) // Simulate AI processing time
                
                // Mock moves (Note: "important_notes.txt" is NOT listed here)
                let moves = [
                    FileMoveAction(fileName: "file_01.png", destination: "Images"),
                    FileMoveAction(fileName: "invoice.pdf", destination: "Documents")
                ]
                
                // Mock updated tree
                // "important_notes.txt" remains in the root "Downloads" list
                let updatedTree = FileSystemNode.folder(FolderItem(
                    path: "/Users/jdoe/Downloads",
                    name: "Downloads",
                    date: Date(),
                    children: [
                        .file(FileItem(path: "/path/file_01.png", name: "file_01.png", date: Date(), size: 1024)),
                        .file(FileItem(path: "/path/invoice.pdf", name: "invoice.pdf", date: Date(), size: 2048)),
                        
                        // UNMOVED FILE: Still present in the root children
                        .file(FileItem(path: "/path/important_notes.txt", name: "important_notes.txt", date: Date(), size: 512)),
                        
                        .folder(FolderItem(
                            path: "/path/Existing_Folder",
                            name: "Existing_Folder",
                            date: Date(),
                            children: []
                        )),
                        // NEW FOLDERS
                        .folder(FolderItem(
                            path: "/path/Images",
                            name: "Images",
                            date: Date(),
                            children: []
                        )),
                        .folder(FolderItem(
                            path: "/path/Documents",
                            name: "Documents",
                            date: Date(),
                            children: []
                        ))
                    ]
                ))
                
                return SortingResponse(updatedTree: updatedTree, moves: moves)
            }
        }
