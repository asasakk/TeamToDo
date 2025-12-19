import SwiftUI

struct InviteQRCodeView: View {
    let organizationName: String
    let inviteCode: String
    @Environment(\.dismiss) var dismiss
    @State private var showCopyAlert = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Text(organizationName)
                    .font(.title2)
                    .fontWeight(.bold)
                
                VStack(spacing: 12) {
                    Text("招待コード")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(inviteCode)
                        .font(.system(size: 40, weight: .heavy, design: .monospaced))
                        .textSelection(.enabled) // Allow user to select and copy
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                
                // Generate QR Code for Deep Link
                Image(uiImage: QRCodeUtilities.generateQRCode(from: "teamtodo://join?code=\(inviteCode)"))
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(radius: 5)
                
                Text("このQRコードを読み取るか、招待コードを入力して組織に参加してください。")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                HStack(spacing: 20) {
                    Button {
                        UIPasteboard.general.string = inviteCode
                        showCopyAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "doc.on.doc")
                            Text("コードをコピー")
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
                    ShareLink(item: "「\(organizationName)」に招待されました。\n招待コード: \(inviteCode)\n以下のリンクから参加してください:\nteamtodo://join?code=\(inviteCode)") {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("リンクを共有")
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top, 40)
            .navigationTitle("メンバーを招待")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
            .alert("コピーしました", isPresented: $showCopyAlert) {
                Button("OK", role: .cancel) { }
            }
        }
    }
}
