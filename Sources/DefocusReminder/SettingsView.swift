import SwiftUI

public struct SettingsView: View {
    @ObservedObject var model: AppModel

    public init(model: AppModel) {
        self.model = model
    }

    public var body: some View {
        TabView {
            planTab
                .tabItem { Label(L.s("时间", "Plan", model.language), systemImage: "calendar") }
            reminderTab
                .tabItem { Label(L.s("提醒", "Reminder", model.language), systemImage: "bell") }
            profileTab
                .tabItem { Label(L.s("画像", "Profile", model.language), systemImage: "person.crop.circle") }
            dataTab
                .tabItem { Label(L.s("数据", "Data", model.language), systemImage: "externaldrive") }
        }
        .padding(16)
    }

    private var planTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                sectionTitle(L.s("工作节奏", "Work rhythm", model.language))
                durationSlider(
                    title: L.s("工作时长", "Work duration", model.language),
                    value: intBinding(\.workMinutes),
                    range: 5...120,
                    tint: .blue,
                    unit: L.s("分钟", "min", model.language)
                )
                durationSlider(
                    title: L.s("休息时长", "Break duration", model.language),
                    value: intBinding(\.breakMinutes),
                    range: 1...30,
                    tint: .orange,
                    unit: L.s("分钟", "min", model.language)
                )

                Divider()
                sectionTitle(L.s("工作日期", "Work days", model.language))
                HStack(spacing: 7) {
                    ForEach([2, 3, 4, 5, 6, 7, 1], id: \.self) { day in
                        dayButton(day)
                    }
                }

                Divider()
                sectionTitle(L.s("上下班时间", "Work hours", model.language))
                HStack(spacing: 12) {
                    DatePicker(
                        "",
                        selection: Binding(
                            get: { dateFromHHmm(model.config.workStartTime) },
                            set: { value in model.updateConfig { $0.workStartTime = hhmmFromDate(value) } }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                    .labelsHidden()
                    Text("–")
                        .foregroundStyle(.secondary)
                    DatePicker(
                        "",
                        selection: Binding(
                            get: { dateFromHHmm(model.config.workEndTime) },
                            set: { value in model.updateConfig { $0.workEndTime = hhmmFromDate(value) } }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                    .labelsHidden()
                    Spacer()
                }
                helperText(L.s("非工作日期和非工作时间会自动暂停提醒。", "Reminders pause automatically outside work days and hours.", model.language))
            }
            .padding(.vertical, 8)
        }
    }

    private var reminderTab: some View {
        VStack(alignment: .leading, spacing: 18) {
            sectionTitle(L.s("提醒模式", "Reminder mode", model.language))
            Picker("", selection: binding(\.reminderMode)) {
                ForEach(ReminderMode.allCases) { mode in
                    Text(mode.label(language: model.language)).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            Toggle(isOn: binding(\.activityDetectionEnabled)) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(L.s("休息期间检测操作", "Detect activity during breaks", model.language))
                    helperText(L.s("开启后，休息中检测到键鼠操作会暂停倒计时。", "When enabled, keyboard or mouse activity pauses the break timer.", model.language))
                }
            }
            .toggleStyle(.switch)

            Spacer()
        }
        .padding(.vertical, 8)
    }

    private var profileTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                sectionTitle(L.s("职业", "Profession", model.language))
                tagGrid(ProfessionTag.allCases) { tag in
                    tagButton(
                        title: tag.label(language: model.language),
                        selected: model.config.healthProfile.profession == tag
                    ) {
                        model.updateConfig { $0.healthProfile.profession = tag }
                    }
                }

                Divider()
                sectionTitle(L.s("身体信号", "Body signals", model.language))
                helperText(L.s("休息建议会优先匹配这些标签，全部在本地完成。", "Recommendations prioritize these tags locally on your Mac.", model.language))
                tagGrid(SymptomTag.allCases) { symptom in
                    tagButton(
                        title: symptom.label(language: model.language),
                        selected: model.config.healthProfile.symptoms.contains(symptom)
                    ) {
                        model.updateConfig {
                            if $0.healthProfile.symptoms.contains(symptom) {
                                $0.healthProfile.symptoms.remove(symptom)
                            } else {
                                $0.healthProfile.symptoms.insert(symptom)
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }

    private var dataTab: some View {
        VStack(alignment: .leading, spacing: 18) {
            sectionTitle(L.s("语言", "Language", model.language))
            Picker("", selection: binding(\.language)) {
                ForEach(AppLanguage.allCases) { language in
                    Text(language.label()).tag(language)
                }
            }
            .pickerStyle(.segmented)

            Divider()
            sectionTitle(L.s("今日汇总", "Today", model.language))
            HStack(spacing: 12) {
                summaryPill(
                    title: L.s("工作", "Work", model.language),
                    value: L.duration(model.todaySummary.workSeconds, model.language),
                    color: .blue
                )
                summaryPill(
                    title: L.s("休息", "Break", model.language),
                    value: L.duration(model.todaySummary.breakSeconds, model.language),
                    color: .green
                )
                summaryPill(
                    title: L.s("完成", "Done", model.language),
                    value: "\(model.todaySummary.completedBreaks)",
                    color: .orange
                )
            }

            Text("~/Library/Application Support/DefocusReminder/state.json")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.secondary)
                .textSelection(.enabled)

            HStack {
                Button(L.s("立即保存", "Save now", model.language)) {
                    model.persist(force: true)
                }
                Button(L.s("重置当前周期", "Reset current cycle", model.language)) {
                    model.resetCycle()
                }
            }

            Spacer()
        }
        .padding(.vertical, 8)
    }

    private func binding<Value>(_ keyPath: WritableKeyPath<AppConfig, Value>) -> Binding<Value> {
        Binding(
            get: { model.config[keyPath: keyPath] },
            set: { value in model.updateConfig { $0[keyPath: keyPath] = value } }
        )
    }

    private func intBinding(_ keyPath: WritableKeyPath<AppConfig, Int>) -> Binding<Double> {
        Binding(
            get: { Double(model.config[keyPath: keyPath]) },
            set: { value in model.updateConfig { $0[keyPath: keyPath] = Int(value) } }
        )
    }

    private func durationSlider(
        title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        tint: Color,
        unit: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                Spacer()
                Text("\(Int(value.wrappedValue)) \(unit)")
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(tint)
            }
            Slider(value: value, in: range, step: 1)
                .tint(tint)
        }
    }

    private func dayButton(_ day: Int) -> some View {
        let selected = model.config.workDays.contains(day)
        return Button {
            model.updateConfig {
                if $0.workDays.contains(day) {
                    $0.workDays.remove(day)
                } else {
                    $0.workDays.insert(day)
                }
            }
        } label: {
            Text(L.weekdayName(day, model.language))
                .font(.system(size: 12, weight: .semibold))
                .frame(width: 40, height: 30)
                .foregroundStyle(selected ? .white : .primary)
                .background(selected ? Color.blue : Color.gray.opacity(0.14), in: RoundedRectangle(cornerRadius: 7))
        }
        .buttonStyle(.borderless)
    }

    private func tagGrid<Data: RandomAccessCollection, Content: View>(
        _ data: Data,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) -> some View where Data.Element: Identifiable {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 8)], spacing: 8) {
            ForEach(data) { item in
                content(item)
            }
        }
    }

    private func tagButton(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .foregroundStyle(selected ? .white : .primary)
                .background(selected ? Color.green : Color.gray.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.borderless)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.secondary)
    }

    private func helperText(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func summaryPill(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
    }
}

private func dateFromHHmm(_ value: String) -> Date {
    let parts = value.split(separator: ":").compactMap { Int($0) }
    var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
    components.hour = parts.count == 2 ? parts[0] : 9
    components.minute = parts.count == 2 ? parts[1] : 0
    components.second = 0
    return Calendar.current.date(from: components) ?? Date()
}

private func hhmmFromDate(_ date: Date) -> String {
    let components = Calendar.current.dateComponents([.hour, .minute], from: date)
    return String(format: "%02d:%02d", components.hour ?? 9, components.minute ?? 0)
}
