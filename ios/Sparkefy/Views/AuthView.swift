import SwiftUI

struct AuthView: View {
    @Environment(AppViewModel.self) private var appVM
    @State private var isSignUp = false
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var selectedRole: UserRole = .customer
    @FocusState private var focusedField: AuthField?

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                VStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 48, weight: .light))
                        .foregroundStyle(SparkefyTheme.blueGreenGradient)

                    Text("Sparkefy")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(SparkefyTheme.darkNavy)

                    Text(isSignUp ? "Create your account" : "Welcome back")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 40)

                VStack(spacing: 16) {
                    if isSignUp {
                        AuthTextField(
                            icon: "person.fill",
                            placeholder: "Full Name",
                            text: $name,
                            contentType: .name
                        )
                        .focused($focusedField, equals: .name)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .email }
                    }

                    AuthTextField(
                        icon: "envelope.fill",
                        placeholder: "Email",
                        text: $email,
                        contentType: .emailAddress,
                        keyboardType: .emailAddress
                    )
                    .focused($focusedField, equals: .email)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .password }

                    AuthTextField(
                        icon: "lock.fill",
                        placeholder: "Password",
                        text: $password,
                        isSecure: true,
                        contentType: .password
                    )
                    .focused($focusedField, equals: .password)
                    .submitLabel(.done)

                    if isSignUp {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("I want to:")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.secondary)

                            HStack(spacing: 12) {
                                RoleButton(
                                    title: "Book Services",
                                    icon: "hand.tap.fill",
                                    isSelected: selectedRole == .customer
                                ) { selectedRole = .customer }

                                RoleButton(
                                    title: "Offer Services",
                                    icon: "wrench.and.screwdriver.fill",
                                    isSelected: selectedRole == .provider
                                ) { selectedRole = .provider }
                            }
                        }
                    }
                }
                .padding(.horizontal)

                VStack(spacing: 12) {
                    Button {
                        focusedField = nil
                        Task {
                            if isSignUp {
                                await appVM.signUp(name: name, email: email, password: password, role: selectedRole)
                            } else {
                                await appVM.signIn(email: email, password: password)
                            }
                        }
                    } label: {
                        Group {
                            if appVM.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text(isSignUp ? "Create Account" : "Sign In")
                            }
                        }
                    }
                    .buttonStyle(SparkefyButtonStyle())
                    .disabled(appVM.isLoading || email.isEmpty || password.isEmpty)
                    .padding(.horizontal)

                    Button {
                        withAnimation(.snappy) { isSignUp.toggle() }
                    } label: {
                        Text(isSignUp ? "Already have an account? **Sign In**" : "Don't have an account? **Sign Up**")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.bottom, 40)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color(.systemGroupedBackground))
    }
}

private enum AuthField {
    case name, email, password
}

struct AuthTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var contentType: UITextContentType?
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(width: 20)

            if isSecure {
                SecureField(placeholder, text: $text)
                    .textContentType(contentType)
            } else {
                TextField(placeholder, text: $text)
                    .textContentType(contentType)
                    .keyboardType(keyboardType)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
        }
        .padding(14)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 12))
    }
}

struct RoleButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption.weight(.medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? SparkefyTheme.primaryBlue.opacity(0.1) : Color(.tertiarySystemGroupedBackground))
            .foregroundStyle(isSelected ? SparkefyTheme.primaryBlue : .secondary)
            .clipShape(.rect(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isSelected ? SparkefyTheme.primaryBlue : .clear, lineWidth: 2)
            )
        }
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}
