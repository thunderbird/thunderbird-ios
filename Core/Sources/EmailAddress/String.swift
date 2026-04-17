extension String {
    public var isEmailAddress: Bool { EmailAddress(self).isEmailAddress }

    func trimmed() -> Self {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
