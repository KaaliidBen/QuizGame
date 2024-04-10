import Foundation

struct Question: Codable {
    let question: String
    let answers: [String]
    let correctAnswer: Int
    let difficulty: Int
    let category: String
}
