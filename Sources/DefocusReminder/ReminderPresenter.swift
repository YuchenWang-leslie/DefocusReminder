import AppKit
import SwiftUI

private final class FloatingReminderPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

@MainActor
final class ReminderPresenter {
    private var panel: FloatingReminderPanel?

    func show(model: AppModel) {
        if let panel {
            position(panel)
            panel.orderFrontRegardless()
            return
        }

        let view = FloatingReminderView(model: model)
            .frame(width: 360)

        let hosting = NSHostingView(rootView: view)
        hosting.frame = NSRect(x: 0, y: 0, width: 360, height: 300)

        let panel = FloatingReminderPanel(
            contentRect: hosting.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.contentView = hosting
        panel.collectionBehavior = [.canJoinAllSpaces, .transient]
        position(panel)
        panel.makeKeyAndOrderFront(nil)
        self.panel = panel
    }

    func hide() {
        panel?.orderOut(nil)
        panel = nil
    }

    private func position(_ panel: NSPanel) {
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { $0.frame.contains(mouse) } ?? NSScreen.main
        guard let screen else { return }
        let visible = screen.visibleFrame
        let size = panel.frame.size
        let margin: CGFloat = 18
        panel.setFrameOrigin(NSPoint(
            x: visible.maxX - size.width - margin,
            y: visible.maxY - size.height - margin
        ))
    }

    static var userIsActive: Bool {
        let mouse = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .mouseMoved)
        let keyboard = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .keyDown)
        return min(mouse, keyboard) < 3
    }
}

struct FloatingReminderView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.16))
                    Image(systemName: icon)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(color)
                }
                .frame(width: 52, height: 52)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.72))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }

            recommendation

            HStack(spacing: 10) {
                ForEach(actions, id: \.title) { action in
                    Button(action.title) {
                        action.perform()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(action.tint)
                    .controlSize(.large)
                    .frame(minWidth: action.minWidth)
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(18)
        .background {
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(red: 0.08, green: 0.09, blue: 0.11).opacity(0.92))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(.white.opacity(0.16), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.34), radius: 22, y: 12)
        }
        .padding(10)
    }

    private var recommendation: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: model.currentRecommendation.icon)
                .foregroundStyle(.mint)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 3) {
                Text(model.currentRecommendation.title(language: model.language))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                Text(model.currentRecommendation.detail(language: model.language))
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.74))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.white.opacity(0.10), lineWidth: 1)
        )
    }

    private var icon: String {
        switch model.engine.phase {
        case .breakPrompt:
            return model.engine.promptKind == .finishBreak ? "checkmark.circle.fill" : "bell.badge.fill"
        case .breaking:
            return "cup.and.saucer.fill"
        case .paused:
            return "pause.circle.fill"
        default:
            return "timer"
        }
    }

    private var color: Color {
        switch model.engine.phase {
        case .breakPrompt:
            return model.engine.promptKind == .finishBreak ? .green : .orange
        case .breaking:
            return .orange
        case .paused:
            return .secondary
        default:
            return .blue
        }
    }

    private var title: String {
        if model.engine.phase == .breaking {
            return "\(L.phase(.breaking, model.language)) \(model.formattedRemaining)"
        }
        if model.engine.promptKind == .finishBreak {
            return L.s("休息结束了", "Break is done", model.language)
        }
        return L.s("该休息了", "Time to rest", model.language)
    }

    private var subtitle: String {
        if model.engine.phase == .breaking, model.config.activityDetectionEnabled {
            return L.s("检测到操作会暂停休息倒计时", "Activity pauses the break timer", model.language)
        }
        if model.engine.promptKind == .finishBreak {
            return L.s("准备好回到工作了吗？", "Ready to return to work?", model.language)
        }
        return L.s("点击开始休息，离开屏幕一会儿。", "Start the break and step away from the screen.", model.language)
    }

    private var actions: [FloatingAction] {
        if model.engine.phase == .breaking {
            return [
                FloatingAction(title: L.s("跳过", "Skip", model.language), tint: .gray) { model.skipBreak() },
            ]
        }
        if model.engine.promptKind == .finishBreak {
            return [
                FloatingAction(title: L.s("我回来了", "I'm back", model.language), tint: .green) { model.finishBreak() },
            ]
        }
        return [
            FloatingAction(title: L.s("开始休息", "Start break", model.language), tint: .orange) { model.startBreak() },
            FloatingAction(title: L.s("稍后", "Later", model.language), tint: .blue, minWidth: 70) { model.snoozeBreak() },
            FloatingAction(title: L.s("跳过", "Skip", model.language), tint: .gray) { model.skipBreak() },
        ]
    }
}

private struct FloatingAction {
    let title: String
    let tint: Color
    var minWidth: CGFloat = 84
    let perform: () -> Void
}
