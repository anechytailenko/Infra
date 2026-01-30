import SwiftUI

// MARK: - GraphViewStyle
// Styling constants used only by GraphView and its subviews.

struct GraphViewStyle {

    // MARK: - Layout

    static let mainPadding: CGFloat = 24
    static let headerTopPadding: CGFloat = 20
    static let headerBottomPadding: CGFloat = 10
    /// Spacing above the "Select any folder…" title (larger than bottom).
    static let titleTopPadding: CGFloat = 18
    static let titleBottomPadding: CGFloat = 0
    static let graphAreaPadding: CGFloat = 50

    // MARK: - Search Bar

    static let searchBarWidth: CGFloat = 300
    static let searchBarPadding: CGFloat = 10
    static let searchBarCornerRadius: CGFloat = 12

    // MARK: - Sort Button (enter/submit next to search field)

    static let sortButtonPaddingHorizontal: CGFloat = 12
    static let sortButtonPaddingVertical: CGFloat = 6
    static let sortButtonCornerRadius: CGFloat = 10
    static let sortButtonIconFontSize: CGFloat = 14

    // MARK: - Folder Graph

    static let folderGraphHStackSpacing: CGFloat = 80
    static let folderGraphVStackSpacing: CGFloat = 20

    // MARK: - Zoom / Scale

    static let zoomMin: CGFloat = 0.5
    static let zoomMax: CGFloat = 3.0

    // MARK: - Column Layout (for graph grid view)

    static let visibleColumns: Int = 5
    static let nodeWidthMultiplier: CGFloat = 0.85
    static let minNodeWidth: CGFloat = 100.0
    static let verticalSpacing: CGFloat = 20.0

    // MARK: - Footer Depth Pills

    static let footerBottomPadding: CGFloat = 30
    static let depthPillPaddingHorizontal: CGFloat = 16
    static let depthPillPaddingVertical: CGFloat = 8
    static let depthPillCornerRadius: CGFloat = 10
    static let depthPillFont = Font.caption
    static let depthPillFontWeight: Font.Weight = .semibold
    static let depthPillTextOpacity: Double = 0.7

    // MARK: - Grid Lines

    static let gridLineOpacity: Double = 0.3
    static let gridLineDash: [CGFloat] = [4, 4]

    // MARK: - HUD Buttons (Accept/Decline overlay)

    static let hudButtonPadding: CGFloat = 10
    static let hudButtonCornerRadius: CGFloat = 8
    static let hudButtonSpacing: CGFloat = 12
    static let hudPadding: CGFloat = 24

    // MARK: - Drag Layer

    static let dragLineDash: [CGFloat] = [5, 5]
    static let dragConnectionColor = Color.green
    static let dragShadowRadius: CGFloat = 8

    // MARK: - File Node

    static let fileNodeColor = Color.green
    static let fileNodeBorderWidth: CGFloat = 2
    static let fileNodeShadowOpacity: Double = 0.2
    static let fileNodeShadowRadius: CGFloat = 4

    // MARK: - New Folder Highlight

    static let newFolderColor = Color.green
    static let newFolderBorderOpacity: Double = 0.5
}
