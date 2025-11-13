import Foundation

struct DateFmt {
    static func cn(_ d: Date, includeTime: Bool = true) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = includeTime ? "yyyy年M月d日 HH:mm" : "yyyy年M月d日"
        return f.string(from: d)
    }
}

