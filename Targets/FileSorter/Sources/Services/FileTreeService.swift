
import Foundation

class FileTreeService {
    
    // Fetch the initial file tree from the path
    func fetchFileTree(path: String) async throws -> FileSystemNode {
        
        // ---------------------------------------------------------
        // REAL SERVER CODE (Commented out for future use)
        // ---------------------------------------------------------
        /*
        guard let url = URL(string: "http://localhost:3000/api/fs/scan") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["path": path]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode(FileSystemNode.self, from: data)
        */
        
        // ---------------------------------------------------------
        // MOCK DATA (Active)
        // ---------------------------------------------------------
        try? await Task.sleep(nanoseconds: 1 * 1_000_000_000) // Simulate network delay
                
                // LOGIC: Extract the actual folder name from the input path
                // e.g. "/Users/jdoe/Documents/Project" -> "Project"
                let folderName = URL(fileURLWithPath: path).lastPathComponent
                let safeName = folderName.isEmpty ? "Root" : folderName
                
                return .folder(FolderItem(
                    path: path,
                    name: safeName, // <--- Dynamic Name
                    date: Date(),
                    children: [
                        // Files that WILL be moved
                        .file(FileItem(path: "\(path)/file_01.png", name: "file_01.png", date: Date(), size: 1024)),
                        .file(FileItem(path: "\(path)/invoice.pdf", name: "invoice.pdf", date: Date(), size: 2048)),
                        
                        // NEW: File that will NOT be moved (Stay in current folder)
                        .file(FileItem(path: "\(path)/important_notes.txt", name: "important_notes.txt", date: Date(), size: 512)),
                        
                        .folder(FolderItem(
                            path: "\(path)/Existing_Folder",
                            name: "Existing_Folder",
                            date: Date(),
                            children: []
                        ))
                    ]
                ))
            }
        }
