import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "desktopcomputer")
                .font(.system(size: 50))
                .foregroundStyle(.blue)
            Text("File Sorter macOS")
                .font(.largeTitle)
        }
        .frame(minWidth: 400, minHeight: 300)
    }
}
