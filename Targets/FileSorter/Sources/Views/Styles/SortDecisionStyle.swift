import SwiftUI

// MARK: - SortDecisionStyle
// Styling constants for SortDecisionView and subviews. Shared tokens delegate to AppStyle.

struct SortDecisionStyle {

    // MARK: - Layout

    static let mainPadding: CGFloat = 24
    static let stackSpacing: CGFloat = 16
    static let minWidth: CGFloat = 900
    static let minHeight: CGFloat = 750
    static let proposedListHeight: CGFloat = 280
    static let cardCornerRadius: CGFloat = AppStyle.cardCornerRadius
    static let diagramInnerPadding: CGFloat = 100
    static let zoomMin: CGFloat = 0.5
    static let zoomMax: CGFloat = 3.0

    // MARK: - Background / Surface (shared from AppStyle)

    static let mainBackgroundGray = AppStyle.screenBackground
    static let cardBackground = AppStyle.cardBackground
    static let listZebraGray = Color(white: 0.97)
    static let listRowEven = Color.white

    // MARK: - Typography

    static let listHeaderFont = AppStyle.headlineFont
    static let listHeaderIconFont = Font.title3
    /// Match FolderDetailView file list row sizing.
    static let rowFileNameFont = Font.system(size: AppStyle.bodyFontSize, weight: AppStyle.bodyFontWeight)
    static let rowMovedToFont = Font.system(size: 12)
    static let rowIconFont = Font.system(size: FolderDetailStyle.listRowIconSize)
    static let buttonFont = Font.system(size: 14, weight: .semibold)
    static let nodeIconFont = AppStyle.nodeIconFont
    static let nodeTextFont = AppStyle.nodeTextFont

    // MARK: - Colors – Text / UI (shared from AppStyle where applicable)

    static let textPrimary = AppStyle.textPrimary
    static let textSecondary = AppStyle.textSecondary
    static let folderIconColor = AppStyle.folderIconColor
    static let listRowIconColor = Color.gray
    static let declineButtonRed = Color.red
    static let declineButtonGray = Color.gray.opacity(0.5)
    static let emptyListPlaceholderColor = Color.gray
    static let buttonForeground = Color.white
    static let acceptButtonColor = Color.blue
    static let declineButtonColor = Color.gray

    // MARK: - Colors – Diagram Edges

    static let edgeNormalColor = AppStyle.edgeNormalColor
    static let edgeOriginalFileColor = Color.red.opacity(0.6)
    static let edgeProposedFileColor = Color.green

    // MARK: - Colors – Diagram Nodes (shared from AppStyle where applicable)

    static let nodeFillOpacity: Double = AppStyle.nodeFillOpacity
    static let nodeBorderOpacity: Double = AppStyle.nodeBorderOpacity
    static let nodeGhostBorderOpacity: Double = 0.5
    static let nodeShadowOpacity: Double = 0.15
    static let nodeGhostShadowOpacity: Double = 0.0

    // MARK: - Edges / Connections

    static let edgeNormalLineWidth: CGFloat = AppStyle.edgeNormalLineWidth
    static let edgeOriginalFileLineWidth: CGFloat = 1.5
    static let edgeProposedFileLineWidth: CGFloat = 2
    static let edgeOriginalFileDash: [CGFloat] = [5, 5]
    static let nodeGhostDash: [CGFloat] = [4, 4]
    static let edgeCurveControlFactor: CGFloat = 0.5

    // MARK: - Node (DiagramNodeView) (shared from AppStyle where applicable)

    static let nodeHStackSpacing: CGFloat = AppStyle.nodeHStackSpacing
    static let nodePaddingHorizontal: CGFloat = AppStyle.nodePaddingHorizontal
    static let nodePaddingVertical: CGFloat = AppStyle.nodePaddingVertical
    static let nodeCornerRadius: CGFloat = AppStyle.nodeCornerRadius
    static let nodeBorderLineWidth: CGFloat = AppStyle.nodeBorderLineWidth
    static let nodeShadowRadius: CGFloat = 6
    static let nodeShadowY: CGFloat = 3

    // MARK: - Shadows (shared from AppStyle for card)

    static let cardShadowColor = AppStyle.cardShadowColor
    static let cardShadowRadius: CGFloat = AppStyle.cardShadowRadius
    static let cardShadowX: CGFloat = AppStyle.cardShadowX
    static let cardShadowY: CGFloat = AppStyle.cardShadowY
    static let buttonShadowOpacity: Double = 0.3
    static let buttonShadowRadius: CGFloat = 4
    static let buttonShadowY: CGFloat = 2

    // MARK: - List / Rows

    static let listHeaderHStackSpacing: CGFloat = 8
    static let listRowHStackSpacing: CGFloat = 12
    static let listRowPaddingHorizontal: CGFloat = 16
    /// Match FolderDetailView folder items list row height.
    static let listRowPaddingVertical: CGFloat = 5
    static let listDividerOverlayOpacity: Double = 0.1
    static let listSelectedRowTintOpacity: Double = 0.1

    // MARK: - Buttons (NiceButtonStyle)

    static let buttonPaddingHorizontal: CGFloat = 24
    static let buttonPaddingVertical: CGFloat = 10
    static let buttonPressScale: CGFloat = 0.96
    static let buttonPressAnimationDuration: Double = 0.1

    // MARK: - Animation

    static let rowSelectSpringResponse: Double = 0.4
    static let rowSelectSpringDamping: Double = 0.7
    static let rowDeclineHoverDuration: Double = 0.2
    static let rowDeclineHoverScale: CGFloat = 1.1

    // MARK: - Diagram Layout

    static let diagramRootXFactor: CGFloat = 0.2
    static let diagramRootYFactor: CGFloat = 0.5
    static let diagramFolderColumnXFactor: CGFloat = 0.6
    static let diagramFolderSpacingY: CGFloat = 100
    static let diagramFileOriginalOffsetX: CGFloat = 40
    static let diagramFileOriginalOffsetY: CGFloat = 70
    static let diagramFileProposedOffsetX: CGFloat = 160
    static let diagramFileProposedOffsetY: CGFloat = 0
    /// Minimum size used for layout so the tree stays visible when the window is small.
    static let diagramMinLayoutWidth: CGFloat = 420
    static let diagramMinLayoutHeight: CGFloat = 320
    static let diagramHorizontalMargin: CGFloat = 48
    static let diagramVerticalMargin: CGFloat = 40
    
    // MARK: - Edge Connection Offsets
    // Used to connect edges to node edges rather than centers
    
    /// Estimated half-width of a folder node (short labels like "home", "cats")
    static let folderNodeHalfWidth: CGFloat = 40
    /// Estimated half-width of a file node (can have long filenames)
    static let fileNodeHalfWidth: CGFloat = 60
}
