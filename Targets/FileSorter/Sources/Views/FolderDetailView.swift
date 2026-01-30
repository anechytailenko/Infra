import SwiftUI
import Combine

// MARK: - View Model (Stub)
// Stub: replace with real folder detail loading. init(folder:) will drive loading of file contents for that folder.
class FolderDetailViewModel: ObservableObject {
    @Published var rootNode: SimpleNode
    @Published var files: [FileItem] = []
    @Published var history: [HistoryItem] = []
    /// Folder selected from HomeView; later used to load file contents.
    let folder: FolderNode?

    init(folder: FolderNode? = nil) {
        self.folder = folder
        self.rootNode = SimpleNode(name: "User", children: [
            SimpleNode(name: "Desktop"),
            SimpleNode(name: "Downloads"),
            SimpleNode(name: "Files")
        ])
        
        self.files = [
            FileItem(path: "/User/Desktop", name: "IMG_8032.heic", date: Date(), size: 1400000),
            FileItem(path: "/User/Downloads", name: "IMG_8031.heic", date: Date().addingTimeInterval(-300), size: 1300000),
            FileItem(path: "/User/Docs", name: "Gemini_Generated.png", date: Date().addingTimeInterval(-1200), size: 1900000)
        ]
        
        self.history = [
            HistoryItem(status: "sorted", date: "Today at 19:05", isSuccess: true),
            HistoryItem(status: "sorted", date: "Today at 18:59", isSuccess: true),
            HistoryItem(status: "sorted", date: "Today at 18:37", isSuccess: true)
        ]
    }
}

// MARK: - Main Detail View
struct FolderDetailView: View {
    let folder: FolderNode?
    @StateObject private var viewModel: FolderDetailViewModel
    @Environment(\.dismiss) private var dismiss

    init(folder: FolderNode? = nil) {
        self.folder = folder
        _viewModel = StateObject(wrappedValue: FolderDetailViewModel(folder: folder))
    }

    var body: some View {
        ZStack {
            Color(red: 0.92, green: 0.92, blue: 0.94).edgesIgnoringSafeArea(.all)

            ScrollView {
                VStack(spacing: 20) {
                    #if os(macOS)
                    HStack {
                        Button { dismiss() } label: {
                            HStack(spacing: AppStyle.backButtonHStackSpacing) {
                                Image(systemName: AppStyle.backButtonIcon)
                                    .font(AppStyle.backButtonFont)
                                Text(AppStyle.backButtonLabel)
                                    .font(AppStyle.backButtonFont)
                            }
                            .foregroundStyle(AppStyle.backButtonForegroundColor)
                            .padding(.horizontal, AppStyle.backButtonPaddingHorizontal)
                            .padding(.vertical, AppStyle.backButtonPaddingVertical)
                        }
                        .buttonStyle(.plain)
                        Spacer()
                    }
                    #endif
                    TopGraphContainer(rootNode: viewModel.rootNode)
                    FileListView(files: viewModel.files)
                    HistoryListView(history: viewModel.history)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle(folder.map { $0.name } ?? "Folder Details")
        #if os(iOS)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    HStack(spacing: AppStyle.backButtonHStackSpacing) {
                        Image(systemName: AppStyle.backButtonIcon)
                            .font(AppStyle.backButtonFont)
                        Text(AppStyle.backButtonLabel)
                            .font(AppStyle.backButtonFont)
                    }
                    .foregroundStyle(AppStyle.backButtonForegroundColor)
                }
            }
        }
        #endif
    }
}

// MARK: - MERGED COMPONENTS

// 1. Extensions for FileItem
extension FileItem {
    var iconName: String {
        switch kind {
        case .image: return "photo"
        case .archive: return "archivebox"
        case .document: return "doc.text"
        }
    }
    
    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
    
    var formattedType: String {
        switch kind {
        case .image: return "\(typeExtension.uppercased()) Image"
        case .archive: return "Archive"
        default: return "\(typeExtension.uppercased()) File"
        }
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return "Today at " + formatter.string(from: date)
    }
}

// 2. Helper Structs
struct HistoryItem: Identifiable {
    let id = UUID()
    let status: String
    let date: String
    let isSuccess: Bool
}

struct SimpleNode: Identifiable {
    let id = UUID()
    let name: String
    var children: [SimpleNode] = []
}

// 3. UI Subviews
struct TopGraphContainer: View {
    let rootNode: SimpleNode
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button(action: {}) {
                    Text("Sort").font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue).padding(.horizontal, 16).padding(.vertical, 8)
                        .background(Color.blue.opacity(0.1)).cornerRadius(8)
                }
            }.padding([.top, .horizontal], 16)
            
            HStack {
                Spacer()
                SimpleGraphLayout(root: rootNode).frame(height: 150)
                Spacer()
            }
            
            HStack(spacing: 0) {
                DepthMarker(text: "DEPTH 0"); Spacer(); DepthMarker(text: "DEPTH 1"); Spacer(); DepthMarker(text: "DEPTH 2")
            }.padding(.horizontal, 40).padding(.bottom, 10)
        }
        .background(Color(red: 0.95, green: 0.95, blue: 0.96)).cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.5), lineWidth: 1))
    }
}

struct SimpleGraphLayout: View {
    let root: SimpleNode
    var body: some View {
        HStack(spacing: 60) {
            NodeBubble(name: root.name).overlay(
                GeometryReader { geo in
                    let start = CGPoint(x: geo.size.width, y: geo.size.height / 2)
                    ZStack {
                        ForEach(0..<root.children.count, id: \.self) { i in
                            Path { path in
                                let yOffset = CGFloat(i - 1) * 60.0
                                let end = CGPoint(x: 60, y: (geo.size.height / 2) + yOffset)
                                path.move(to: start)
                                path.addCurve(to: end, control1: CGPoint(x: start.x + 30, y: start.y), control2: CGPoint(x: end.x - 30, y: end.y))
                            }.stroke(Color.blue, lineWidth: 1.5)
                        }
                    }
                }, alignment: .leading
            ).zIndex(1)
            VStack(spacing: 25) { ForEach(root.children) { child in NodeBubble(name: child.name) } }
        }
    }
}

struct NodeBubble: View {
    let name: String
    var body: some View {
        HStack(spacing: 6) { Image(systemName: "folder"); Text(name) }
            .font(.system(size: 14, weight: .regular)).foregroundColor(.blue)
            .padding(.vertical, 8).padding(.horizontal, 16).background(Color.blue.opacity(0.1)).cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.blue.opacity(0.3), lineWidth: 1))
    }
}

struct DepthMarker: View {
    let text: String
    var body: some View {
        Text(text).font(.system(size: 10, weight: .bold)).foregroundColor(.gray.opacity(0.5))
            .padding(.vertical, 4).padding(.horizontal, 8).background(Color.white.opacity(0.5)).cornerRadius(4)
    }
}

struct FileListView: View {
    let files: [FileItem]
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "doc.text").foregroundColor(.gray)
                Text("User").font(.headline).foregroundColor(.primary)
                Spacer()
                HStack(spacing: 16) { Image(systemName: "line.3.horizontal.decrease.circle"); Image(systemName: "arrow.up.arrow.down.circle") }.foregroundColor(.gray)
            }.padding().background(Color.white)
            Divider()
            ForEach(files) { file in FileRowView(file: file); Divider().padding(.leading, 50) }
        }.background(Color.white).cornerRadius(12).shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct FileRowView: View {
    let file: FileItem
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: file.iconName).font(.system(size: 20)).foregroundColor(.gray).frame(width: 30)
            Text(file.name).font(.system(size: 14)).foregroundColor(.primary)
            Spacer()
            HStack(spacing: 20) {
                Text(file.formattedSize).frame(width: 60, alignment: .trailing)
                Text(file.formattedType).frame(width: 80, alignment: .leading)
                Text(file.formattedDate).frame(width: 100, alignment: .trailing)
            }.font(.system(size: 12)).foregroundColor(.gray)
        }.padding().background(Color.white)
    }
}

struct HistoryListView: View {
    let history: [HistoryItem]
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "clock").foregroundColor(.gray)
                Text("History").font(.headline).foregroundColor(.primary)
                Spacer()
                HStack(spacing: 16) { Image(systemName: "line.3.horizontal.decrease.circle"); Image(systemName: "arrow.up.arrow.down.circle") }.foregroundColor(.gray)
            }.padding().background(Color.white)
            Divider()
            ForEach(history) { item in
                HStack {
                    ZStack {
                        Circle().stroke(Color.green.opacity(0.3), lineWidth: 1).background(Circle().fill(Color.green.opacity(0.1))).frame(width: 24, height: 24)
                        Image(systemName: "checkmark").font(.system(size: 10, weight: .bold)).foregroundColor(.green)
                    }.frame(width: 30)
                    Text(item.status).font(.system(size: 14)).foregroundColor(.primary)
                    Spacer()
                    Text(item.date).font(.system(size: 12)).foregroundColor(.gray)
                }.padding().background(Color.white)
                if item.id != history.last?.id { Divider().padding(.leading, 50) }
            }
        }.background(Color.white).cornerRadius(12).shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}
