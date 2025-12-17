import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var isRegistering = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text(isRegistering ? "アカウント作成" : "ログイン")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.caption)
            }
            
            TextField("メールアドレス", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
            
            SecureField("パスワード", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            if isRegistering {
                TextField("表示名", text: $displayName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            Button(action: handleAction) {
                Text(isRegistering ? "登録" : "ログイン")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            Button {
                isRegistering.toggle()
                errorMessage = ""
            } label: {
                Text(isRegistering ? "すでにアカウントをお持ちの方" : "アカウントを作成")
                    .foregroundStyle(.blue)
            }
        }
        .padding()
    }
    
    private func handleAction() {
        if isRegistering {
            register()
        } else {
            login()
        }
    }
    
    private func login() {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                errorMessage = "ログインエラー: \(error.localizedDescription)"
                return
            }
            // 成功時はFirebaseManagerが検知して画面遷移する
        }
    }
    
    private func register() {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                errorMessage = "登録エラー: \(error.localizedDescription)"
                return
            }
            
            guard let uid = result?.user.uid else { return }
            
            // 下記でUserドキュメントを作成
            let newUser = AppUser(id: uid, email: email, displayName: displayName.isEmpty ? "No Name" : displayName, fcmToken: nil, createdAt: Date())
            
            do {
                try Firestore.firestore().collection("users").document(uid).setData(from: newUser)
            } catch {
                errorMessage = "データ保存エラー: \(error.localizedDescription)"
            }
        }
    }
}
