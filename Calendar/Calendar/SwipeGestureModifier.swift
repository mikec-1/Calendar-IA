import SwiftUI

// MARK: - Edge threshold for tab switching
// Apple's back-swipe gesture uses roughly the leftmost ~20pt but allows up to ~40pt.
// We use a comfortable margin that matches native iOS feel.
private let edgeSwipeThreshold: CGFloat = 44.0

// MARK: - Tab-switching helper
private func switchTab(direction: SwipeDirection, viewModel: CalendarViewModel) {
    let generator = UIImpactFeedbackGenerator(style: .light)
    generator.impactOccurred()
    
    switch direction {
    case .left:
        // next tab
        viewModel.navigatingForward = true
        withAnimation(.easeInOut(duration: 0.3)) {
            if viewModel.calendarMode == .month {
                viewModel.calendarMode = .week
            } else if viewModel.calendarMode == .week {
                viewModel.calendarMode = .agenda
            }
        }
    case .right:
        // previous tab
        viewModel.navigatingForward = false
        withAnimation(.easeInOut(duration: 0.3)) {
            if viewModel.calendarMode == .agenda {
                viewModel.calendarMode = .week
            } else if viewModel.calendarMode == .week {
                viewModel.calendarMode = .month
            }
        }
    }
}

private enum SwipeDirection {
    case left, right
}

// MARK: - CustomSwipeModifier
// Used on calendar grids (Month grid, Week strip) where:
// - Edge swipes switch tabs
// - Inner swipes navigate dates (next/prev month or week)
struct CustomSwipeModifier: ViewModifier {
    @EnvironmentObject var viewModel: CalendarViewModel
    
    var onInnerSwipeLeft: () -> Void
    var onInnerSwipeRight: () -> Void
    
    func body(content: Content) -> some View {
        let screenWidth = UIScreen.main.bounds.width
        
        content
            .contentShape(Rectangle())
            .highPriorityGesture(
                DragGesture(minimumDistance: 25, coordinateSpace: .global)
                    .onEnded { value in
                        let startX = value.startLocation.x
                        let isLeftEdge = startX <= edgeSwipeThreshold
                        let isRightEdge = startX >= screenWidth - edgeSwipeThreshold
                        
                        let dx = value.translation.width
                        let dy = value.translation.height
                        
                        // Must be primarily horizontal
                        guard abs(dx) > abs(dy), abs(dx) > 25 else { return }
                        
                        if dx < 0 {
                            if isRightEdge {
                                switchTab(direction: .left, viewModel: viewModel)
                            } else {
                                viewModel.navigatingForward = true
                                viewModel.navigationID += 1
                                onInnerSwipeLeft()
                            }
                        } else {
                            if isLeftEdge {
                                switchTab(direction: .right, viewModel: viewModel)
                            } else {
                                viewModel.navigatingForward = false
                                viewModel.navigationID += 1
                                onInnerSwipeRight()
                            }
                        }
                    }
            )
    }
}

// MARK: - TabSwipeModifier
// Used on views where ANY horizontal swipe should switch tabs
// (Agenda view, Day timeline section in Week view)
struct TabSwipeModifier: ViewModifier {
    @EnvironmentObject var viewModel: CalendarViewModel
    
    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .simultaneousGesture(
                DragGesture(minimumDistance: 30, coordinateSpace: .global)
                    .onEnded { value in
                        let dx = value.translation.width
                        let dy = value.translation.height
                        
                        // Must be clearly horizontal (at least 2x more horizontal than vertical)
                        guard abs(dx) > abs(dy) * 2, abs(dx) > 50 else { return }
                        
                        if dx < 0 {
                            switchTab(direction: .left, viewModel: viewModel)
                        } else {
                            switchTab(direction: .right, viewModel: viewModel)
                        }
                    }
            )
    }
}

// MARK: - View extensions
extension View {
    /// For calendar grids: inner swipe = date nav, edge swipe = tab switch
    func customHorizontalSwipe(
        onInnerSwipeLeft: @escaping () -> Void,
        onInnerSwipeRight: @escaping () -> Void
    ) -> some View {
        self.modifier(CustomSwipeModifier(
            onInnerSwipeLeft: onInnerSwipeLeft,
            onInnerSwipeRight: onInnerSwipeRight
        ))
    }
    
    /// For content areas: any horizontal swipe switches tabs
    func tabSwipeGesture() -> some View {
        self.modifier(TabSwipeModifier())
    }
}
