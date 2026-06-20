import SwiftUI

struct SettingsSwiftUIView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @AppStorage("appTheme") private var appTheme: Int = 0 // 0 System, 1 Light, 2 Dark
    @AppStorage("useAppleCalendar") private var useAppleCalendar: Bool = true
    @AppStorage("useAppleReminders") private var useAppleReminders: Bool = true
    @State private var showingCategorySettings = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.backgroundBase.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        Text("Calendar Settings")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .padding(.top, 10)
                            .padding(.horizontal)
                        
                        Text("Customize your calendar experience.")
                            .font(.system(size: 17, weight: .regular, design: .rounded))
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        Text("APPEARANCE")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.top, 10)
                        
                        VStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("App Theme")
                                    .font(.headline)
                                
                                Picker("Theme", selection: $appTheme) {
                                    Text("System").tag(0)
                                    Text("Light").tag(1)
                                    Text("Dark").tag(2)
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .onChange(of: appTheme) { newValue in
                                    let scenes = UIApplication.shared.connectedScenes
                                    let windowScene = scenes.first as? UIWindowScene
                                    let window = windowScene?.windows.first
                                    
                                    switch newValue {
                                    case 1: window?.overrideUserInterfaceStyle = .light
                                    case 2: window?.overrideUserInterfaceStyle = .dark
                                    default: window?.overrideUserInterfaceStyle = .unspecified
                                    }
                                }
                            }
                            
                            Divider()

                            VStack(alignment: .leading, spacing: 12) {
                                Text("Accent Color")
                                    .font(.headline)
                                
                                HStack(spacing: 16) {
                                    ForEach(0..<themeManager.accentColors.count, id: \.self) { index in
                                        let color = themeManager.accentColors[index]
                                        Circle()
                                            .fill(color)
                                            .frame(width: 36, height: 36)
                                            .overlay(
                                                Circle()
                                                    .strokeBorder(Color.white, lineWidth: themeManager.accentColorSelection == index ? 3 : 0)
                                            )
                                            .shadow(color: color.opacity(0.3), radius: 5, x: 0, y: 3)
                                            .onTapGesture {
                                                withAnimation(.spring()) {
                                                    themeManager.accentColorSelection = index
                                                }
                                            }
                                    }
                                }
                            }
                        }
                        .glassCardStyle()
                        .padding(.horizontal)
                        
                        Text("CALENDARS")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.top, 10)
                        
                        VStack(spacing: 20) {
                            Toggle("Apple Calendar Integration", isOn: $useAppleCalendar)
                                .font(.headline)
                                .onChange(of: useAppleCalendar) { _ in
                                    CalendarViewModel.shared.updateDaysInMonth()
                                }
                            Toggle("Apple Reminders Integration", isOn: $useAppleReminders)
                                .font(.headline)
                                .onChange(of: useAppleReminders) { _ in
                                    CalendarViewModel.shared.updateDaysInMonth()
                                }
                            
                            Divider().padding(.vertical, 8)
                            
                            Button(action: { showingCategorySettings = true }) {
                                HStack {
                                    Text("Manage Task Categories")
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "folder.badge.gear")
                                        .foregroundColor(themeManager.primaryAccent)
                                }
                            }
                        }
                        .glassCardStyle()
                        .padding(.horizontal)
                        
                        Spacer()
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingCategorySettings) {
                CategorySettingsView()
            }
        }
    }
}
