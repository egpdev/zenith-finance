import SwiftUI

#if canImport(UIKit)
    import UIKit
#endif

class HapticManager {
    static let shared = HapticManager()

    private init() {}

    // MARK: - Basic Haptics
    func light() {
        #if canImport(UIKit)
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.prepare()
            generator.impactOccurred()
        #endif
    }

    func medium() {
        #if canImport(UIKit)
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.prepare()
            generator.impactOccurred()
        #endif
    }

    func heavy() {
        #if canImport(UIKit)
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred()
        #endif
    }

    func soft() {
        #if canImport(UIKit)
            let generator = UIImpactFeedbackGenerator(style: .soft)
            generator.prepare()
            generator.impactOccurred()
        #endif
    }

    func rigid() {
        #if canImport(UIKit)
            let generator = UIImpactFeedbackGenerator(style: .rigid)
            generator.prepare()
            generator.impactOccurred()
        #endif
    }

    // MARK: - Notification Haptics
    func success() {
        #if canImport(UIKit)
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.success)
        #endif
    }

    func warning() {
        #if canImport(UIKit)
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.warning)
        #endif
    }

    func error() {
        #if canImport(UIKit)
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.error)
        #endif
    }

    // MARK: - Selection Haptic
    func selection() {
        #if canImport(UIKit)
            let generator = UISelectionFeedbackGenerator()
            generator.prepare()
            generator.selectionChanged()
        #endif
    }

    // MARK: - Custom Patterns

    /// Double tap pattern - good for confirmations
    func doubleTap() {
        #if canImport(UIKit)
            light()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.light()
            }
        #endif
    }

    /// Triple tap pattern - good for achievements
    func celebration() {
        #if canImport(UIKit)
            success()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                self.light()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.medium()
            }
        #endif
    }

    /// Transaction added feedback
    func transactionAdded() {
        #if canImport(UIKit)
            medium()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.success()
            }
        #endif
    }

    /// Goal achieved feedback
    func goalAchieved() {
        #if canImport(UIKit)
            heavy()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.success()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self.light()
            }
        #endif
    }

    /// Budget warning feedback
    func budgetWarning() {
        #if canImport(UIKit)
            warning()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.warning()
            }
        #endif
    }

    /// Swipe action feedback
    func swipe() {
        #if canImport(UIKit)
            soft()
        #endif
    }

    /// Pull to refresh feedback
    func pullToRefresh() {
        #if canImport(UIKit)
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.prepare()
            generator.impactOccurred(intensity: 0.5)
        #endif
    }

    /// Button press feedback with intensity
    func buttonPress(intensity: CGFloat = 1.0) {
        #if canImport(UIKit)
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.prepare()
            generator.impactOccurred(intensity: intensity)
        #endif
    }
}
