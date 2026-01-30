import SwiftUI

// MARK: - GraphViewStyle
// Styling constants used only by GraphView and its subviews.

struct GraphViewStyle {

    // MARK: - Layout

    static let mainPadding: CGFloat = 24
    static let headerTopPadding: CGFloat = 20
    static let headerBottomPadding: CGFloat = 10
    static let graphAreaPadding: CGFloat = 50

    // MARK: - Search Bar

    static let searchBarWidth: CGFloat = 300
    static let searchBarPadding: CGFloat = 10
    static let searchBarCornerRadius: CGFloat = 12

    // MARK: - Sort Button

    static let sortButtonPaddingHorizontal: CGFloat = 20
    static let sortButtonPaddingVertical: CGFloat = 8
    static let sortButtonCornerRadius: CGFloat = 12

    // MARK: - Folder Graph

    static let folderGraphHStackSpacing: CGFloat = 80
    static let folderGraphVStackSpacing: CGFloat = 20

    // MARK: - Zoom / Scale

    static let zoomMin: CGFloat = 0.5
    static let zoomMax: CGFloat = 3.0
}
