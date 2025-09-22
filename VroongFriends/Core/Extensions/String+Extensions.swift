import Foundation
import CryptoKit

extension String {
    // MARK: - Validation

    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return predicate.evaluate(with: self)
    }

    var isValidPhoneNumber: Bool {
        let phoneRegex = "^01[0-9]-?[0-9]{3,4}-?[0-9]{4}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return predicate.evaluate(with: self)
    }

    var isValidPassword: Bool {
        // 최소 8자, 영문+숫자 조합
        let passwordRegex = "^(?=.*[A-Za-z])(?=.*\\d)[A-Za-z\\d@$!%*?&]{8,}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", passwordRegex)
        return predicate.evaluate(with: self)
    }

    // MARK: - Formatting

    func toPhoneFormat() -> String {
        let numbers = self.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)

        if numbers.count == 10 {
            let pattern = "(\\d{3})(\\d{3})(\\d{4})"
            return numbers.replacingOccurrences(of: pattern, with: "$1-$2-$3", options: .regularExpression)
        } else if numbers.count == 11 {
            let pattern = "(\\d{3})(\\d{4})(\\d{4})"
            return numbers.replacingOccurrences(of: pattern, with: "$1-$2-$3", options: .regularExpression)
        }

        return self
    }

    func toCurrency() -> String {
        guard let number = Double(self) else { return self }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: number)) ?? self
    }

    // MARK: - Crypto

    func toSHA256() -> String {
        let inputData = Data(self.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }

    func toBase64() -> String {
        return Data(self.utf8).base64EncodedString()
    }

    func fromBase64() -> String? {
        guard let data = Data(base64Encoded: self) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    // MARK: - Utilities

    var localized: String {
        return NSLocalizedString(self, comment: "")
    }

    func truncated(to length: Int, trailing: String = "...") -> String {
        if self.count > length {
            return String(self.prefix(length)) + trailing
        }
        return self
    }

    var trimmed: String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isNotEmpty: Bool {
        return !self.trimmed.isEmpty
    }
}