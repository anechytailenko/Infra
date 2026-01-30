
import Foundation
import SwiftUI

class FolderStructureViewModel: ObservableObject {
    @Published var rootNode: FolderNode

    init() {
        // Static mock data for the Home Dashboard
        self.rootNode = FolderNode(name: "Root", children: [
            FolderNode(name: "Project_Docs", children: [
                FolderNode(name: "Client_Reports", children: [
                    FolderNode(name: "Client_Report_Q1"),
                    FolderNode(name: "Client_Report_Q2")
                ]),
                FolderNode(name: "Shared_Assets", children: [
                    FolderNode(name: "Eiomnal_Assets", children: [
                        FolderNode(name: "Source_Files")
                    ]),
                    FolderNode(name: "Logos"),
                    FolderNode(name: "Templates")
                ]),
                FolderNode(name: "Marketing_Materials"),
                FolderNode(name: "Internal_Docs")
            ])
        ])
    }
}
