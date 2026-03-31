import SwiftUI

struct PhoneVerificationView: View {
    @Environment(AppViewModel.self) private var appVM
    @State private var phone = ""
    @State private var otpCode = ""
    @State private var step: VerifyStep = .enterPhone
    @State private var isLoading = false

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                VStack(spacing: 8) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(SparkefyTheme.blueGreenGradient)

                    Text("Verify Your Phone")
                        .font(.title2.bold())

                    Text(appVM.currentUser?.role == .provider
                         ? "Phone verification is required for all providers to ensure trust and safety."
                         : "Add a phone number for account security.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding(.top, 40)

                VStack(spacing: 16) {
                    if step == .enterPhone {
                        phoneInputSection
                    } else {
                        otpInputSection
                    }
                }
                .padding(.horizontal)

                VStack(spacing: 12) {
                    Button {
                        Task { await handleAction() }
                    } label: {
                        Group {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text(step == .enterPhone ? "Send Verification Code" : "Verify Code")
                            }
                        }
                    }
                    .buttonStyle(SparkefyButtonStyle())
                    .disabled(isLoading || (step == .enterPhone ? phone.isEmpty : otpCode.count < 6))
                    .padding(.horizontal)

                    if appVM.currentUser?.role == .customer {
                        Button {
                            appVM.skip2FA()
                        } label: {
                            Text("Skip for Now")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if appVM.currentUser?.role == .provider {
                    HStack(spacing: 8) {
                        Image(systemName: "shield.checkered")
                            .font(.caption)
                            .foregroundStyle(SparkefyTheme.accentGreen)
                        Text("This helps customers trust that you're a verified provider.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 32)
                }
            }
            .padding(.bottom, 40)
        }
        .background(Color(.systemGroupedBackground))
    }

    private var phoneInputSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "phone.fill")
                .foregroundStyle(.secondary)
                .frame(width: 20)
            TextField("Phone number (+1...)", text: $phone)
                .textContentType(.telephoneNumber)
                .keyboardType(.phonePad)
        }
        .padding(14)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 12))
    }

    private var otpInputSection: some View {
        VStack(spacing: 12) {
            Text("Enter the 6-digit code sent to \(phone)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 12) {
                Image(systemName: "number")
                    .foregroundStyle(.secondary)
                    .frame(width: 20)
                TextField("000000", text: $otpCode)
                    .textContentType(.oneTimeCode)
                    .keyboardType(.numberPad)
                    .font(.title3.monospaced())
            }
            .padding(14)
            .background(Color(.tertiarySystemGroupedBackground))
            .clipShape(.rect(cornerRadius: 12))

            Button {
                step = .enterPhone
                otpCode = ""
            } label: {
                Text("Change phone number")
                    .font(.caption)
                    .foregroundStyle(SparkefyTheme.primaryBlue)
            }
        }
    }

    private func handleAction() async {
        isLoading = true
        defer { isLoading = false }

        if step == .enterPhone {
            let success = await appVM.sendPhoneOTP(phone: phone)
            if success {
                withAnimation(.snappy) { step = .verifyCode }
            }
        } else {
            let _ = await appVM.verifyPhoneOTP(code: otpCode)
        }
    }
}

private enum VerifyStep {
    case enterPhone
    case verifyCode
}
