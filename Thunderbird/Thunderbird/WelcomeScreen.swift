import SwiftUI

struct WelcomeScreen: View {
    @Environment(\.openURL) private var openURL
    
    // MARK: View
    var body: some View {
        VStack {
            Spacer()
            Image.logo
                .resizable()
                .aspectRatio(contentMode: .fit)
                .accessibilityLabel(.appName)
                .frame(height: 172.0)
            Text(.onboardingWelcomeText)
                .multilineTextAlignment(.center)
                .opacity(0.75)
                .padding()
            Spacer()
            Spacer()
            Button(action: {
                openURL(.donate)
            }) {
                Text(.onboardingWelcomeStartButton)
                    .padding(5.5)
            }
            .buttonStyle(.borderedProminent)
            .padding()
            Spacer()
            Text(.onboardingWelcomeDevelopedBy)
                .multilineTextAlignment(.center)
                .font(.caption)
                .opacity(0.75)
                .padding()
        }
        .background {
            Background()
        }
    }
}

#Preview("Welcome Screen") {
    WelcomeScreen()
}

private struct Background: View {
    
    // MARK: View
    var body: some View {
        GeometryReader { proxy in
            Image.background
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: proxy.size.width, height: proxy.size.height)
                .opacity(proxy.size.width > 444.0 ? 0.0 : 1.0)
        }
        .ignoresSafeArea()
    }
}

private extension Image {
    static var background: Self { Self("Welcome/Background") }
    static var logo: Self { Self("Welcome/Logo") }
}

private extension LocalizedStringKey {
    static let appName: Self = "app_name"
    static let onboardingWelcomeText: Self = "onboarding_welcome_text"
    static let onboardingWelcomeDevelopedBy: Self = "onboarding_welcome_developed_by"
    static let onboardingWelcomeStartButton: Self = "onboarding_welcome_start_button"
}

private extension URL {
    static let donate: Self = Self(string: "https://www.thunderbird.net/donate/mobile/?form=tfi")!
}
