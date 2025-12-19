import SwiftUI
import StoreKit

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    
    // 【追加】UpdateCheckerの変更を監視して、画面を自動更新するようにします
    @ObservedObject private var updateChecker = UpdateChecker.shared
    @StateObject private var firebaseManager = FirebaseManager.shared
    @Environment(\.requestReview) var requestReview
    
    @AppStorage("language") private var language: String = "ja"
    @AppStorage("appearanceMode") private var appearanceMode: Int = 0 // 0:Auto, 1:Light, 2:Dark
    
    // 既存設定の維持
    @AppStorage("notificationHoursBefore") private var notificationHoursBefore = 6
    
    // 通知時刻設定 (ユーザー要望コードより)
    @AppStorage("notifyAt8") private var notifyAt8: Bool = false
    @AppStorage("notifyAt12") private var notifyAt12: Bool = false
    @AppStorage("notifyAt17") private var notifyAt17: Bool = false
    
    // 現在のバージョンを取得
    let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    
    var body: some View {
        NavigationStack {
            List {
                
                // --- 外観設定 ---
                Section(header: Text("外観")) {
                    Picker("テーマ", selection: $appearanceMode) {
                        Text("自動 (システム準拠)").tag(0)
                        Text("ライトモード").tag(1)
                        Text("ダークモード").tag(2)
                    }
                    .pickerStyle(.menu)
                }
                
                // --- 通知設定 ---
                Section(header: Text("通知設定")) {
                    VStack(alignment: .leading) {
                        Stepper("期限の \(notificationHoursBefore) 時間前", value: $notificationHoursBefore, in: 0...48)
                        Text("タスク期限前の通知設定です。バックグラウンドでの通知にはアプリを定期的に開く必要があります。")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Toggle("当日のタスクを08:00 に通知", isOn: $notifyAt8)
                        .onChange(of: notifyAt8) { _, _ in requestPermissionIfNeeded() }
                    
                    Toggle("当日のタスクを12:00 に通知", isOn: $notifyAt12)
                        .onChange(of: notifyAt12) { _, _ in requestPermissionIfNeeded() }
                    
                    Toggle("当日のタスクを17:00 に通知", isOn: $notifyAt17)
                        .onChange(of: notifyAt17) { _, _ in requestPermissionIfNeeded() }
                }
                
                Section(header: Text("アプリについて")) {
                    // IDは実際のアプリIDに置き換えてください (とりあえずユーザー提供のIDを使用)
                    Link(destination: URL(string: "https://apps.apple.com/app/id6755773828?action=write-review")!) {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
                            Text("アプリをレビューして応援")
                                .foregroundColor(.primary)
                        }
                    }
                    
                    Link(destination: URL(string: "https://nowa-tech.tokyo/service/tsumiage/policy")!) {
                        HStack {
                            Image(systemName: "hand.raised.fill")
                                .foregroundStyle(.blue)
                            Text("プライバシーポリシー")
                                .foregroundColor(.primary)
                        }
                    }
                    
                    Link(destination: URL(string: "https://nowa-tech.tokyo/service/tsumiage/terms")!) {
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .foregroundStyle(.blue)
                            Text("利用規約")
                                .foregroundColor(.primary)
                        }
                    }
                }
                
                Section(header: Text("サポート（バグを報告）")) {
                    Link(destination: URL(string: "https://forms.gle/eMSi5cvLC63epdmv5")!) {
                        Text("Googleフォーム")
                    }
                }
                
                Section(header: Text("アカウント")) {
                    Button("ログアウト", role: .destructive) {
                        firebaseManager.signOut()
                    }
                }
                
                Section(header: Text("その他")) {
                    HStack {
                        Text("バージョン")
                        Spacer()
                        
                        // アップデートがあるかチェック
                        if updateChecker.isUpdateAvailable {
                            VStack(alignment: .trailing) {
                                Text(currentVersion)
                                    .foregroundStyle(.secondary)
                                
                                // ストアURLがあればリンクとして表示
                                if let url = updateChecker.appStoreURL {
                                    Link("最新: \(updateChecker.latestVersion) に更新", destination: url)
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.red)
                                } else {
                                    Text("最新: \(updateChecker.latestVersion)")
                                        .font(.caption)
                                        .foregroundStyle(.red)
                                }
                            }
                        } else {
                            // 最新の場合
                            Text(currentVersion)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("設定・情報")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
            // 【重要】画面が表示されたらバージョンチェックを実行
            .onAppear {
                updateChecker.checkForUpdate()
                NotificationManager.shared.updateDailyNotifications()
            }
            // 外観モードの適用 (onChangeはAppレベルで行うのが一般的だが、ここでも簡易的に反映可能ならする)
            // ただしSwiftUIの環境設定変更はWindowGroupレベルが必要なため、ここでは保存のみ。
        }
    }
    
    private func requestPermissionIfNeeded() {
        if notifyAt8 || notifyAt12 || notifyAt17 {
            NotificationManager.shared.requestAuthorization()
        }
        // 設定変更を反映（権限があればスケジュールされる、OFFなら削除される）
        NotificationManager.shared.updateDailyNotifications()
    }
}
