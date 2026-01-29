import Foundation

// MARK: - The Interface
protocol ContentGeneratorService {
    func generateDescription(for fileName: String) -> String
}

// MARK: - The Mock Implementation
class MockAIContentGenerator: ContentGeneratorService {
    
    private static var globalCounter = 0
    
    func generateDescription(for fileName: String) -> String {
        MockAIContentGenerator.globalCounter += 1
        return "Generation content model: content number \(MockAIContentGenerator.globalCounter)"
    }
}
