import Foundation

class QuizManager {
    var questions: [Question] = []
    var currentUserScore: Int = 0
    var userName: String = ""

    init() {
        questions = loadQuestions()
    }

    func loadQuestions() -> [Question] {
        guard let url = Bundle.main.url(forResource: "questions", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            print("Questions JSON not found.")
            return []
        }
        
        do {
            let decoder = JSONDecoder()
            let questions = try decoder.decode([Question].self, from: data)
            return questions
        } catch {
            print("Erreur lors du chargement des questions: \(error)")
            return []
        }
    }

    func startQuiz() {
        print("Bienvenue dans le Quiz Game ! Entrez votre nom :")
        userName = readLine() ?? "Joueur Anonyme"
        print("Sélectionnez un niveau de difficulté (1 facile, 2 moyen, 3 difficile) :")
        let difficulty = Int(readLine() ?? "1") ?? 1

        let filteredQuestions = questions.filter { $0.difficulty == difficulty }.shuffled()
        filteredQuestions.forEach { question in
            askQuestion(question)
        }

        print("Quiz terminé, \(userName) ! Votre score final est : \(currentUserScore).")
        if currentUserScore > filteredQuestions.count / 2 {
            print("Félicitations \(userName)! Vous avez bien maîtrisé ce niveau de difficulté.")
            if difficulty < 3 {
                print("Pourquoi ne pas essayer le niveau de difficulté supérieur ?")
            }
        } else {
            print("Bonne tentative \(userName)! L'entraînement rend meilleur. Pourquoi ne pas retenter votre chance ou réessayer avec un niveau de difficulté inférieur ?")
        }
    }

    func editQuestionsMenu() {
    var shouldContinue = true
    while shouldContinue {
        print("\nMenu d'Édition de la Banque de Questions:")
        print("1. Ajouter une question")
        print("2. Retour")

        if let choice = readLine() {
            switch choice {
            case "1":
                addQuestion()
            case "2":
                shouldContinue = false
            default:
                print("Choix non reconnu, veuillez essayer à nouveau.")
            }
        }
    }
}

func addQuestion() {
    print("Entrez la nouvelle question :")
    let questionText = readLine() ?? ""
    print("Entrez les choix de réponse séparés par une virgule :")
    let answersText = readLine() ?? ""
    let answers = answersText.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
    print("Entrez l'indice de la bonne réponse (en commençant par 1) :")
    let correctAnswerIndex = Int(readLine() ?? "") ?? 1 - 1
    print("Entrez le niveau de difficulté (1-3) :")
    let difficulty = Int(readLine() ?? "") ?? 1
    print("Entrez la catégorie de la question :")
    let category = readLine() ?? ""

    let newQuestion = Question(question: questionText, answers: answers, correctAnswer: correctAnswerIndex, difficulty: difficulty, category: category)
    questions.append(newQuestion)
    saveQuestionsToFile()
}


func saveQuestionsToFile() {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted // Pour rendre le fichier JSON lisible
    do {
        let data = try encoder.encode(questions)
        let url = URL(fileURLWithPath: "./questions.json")
        try data.write(to: url)
        print("Les questions ont été sauvegardées avec succès.")
    } catch {
        print("Erreur lors de la sauvegarde des questions: \(error)")
    }
}


    func main() {
        var shouldContinue = true
        while shouldContinue {
            print("\nBienvenue dans le Quiz Game !")
            print("1. Jouer")
            print("2. Modifier la banque de questions")
            print("3. Quitter")

            print("\nEntrez votre choix : ", terminator: "")
            if let choice = readLine() {
                switch choice {
                case "1":
                    startQuiz()
                case "2":
                    editQuestionsMenu()
                case "3":
                    shouldContinue = false
                    print("Merci d'avoir utilisé le Quiz Game. À bientôt !")
                default:
                    print("Choix non reconnu, veuillez essayer à nouveau.")
                }
            }
        }
    }

    func askQuestion(_ question: Question) {
        print("\n\(question.question)")
        for (index, answer) in question.answers.enumerated() {
            print("\(index + 1). \(answer)")
        }

        let group = DispatchGroup()
        group.enter()

        var userAnswer: Int? = nil
        var isCorrect: Bool? = nil

        DispatchQueue.global(qos: .userInteractive).async {
            userAnswer = Int(readLine() ?? "") ?? -1
            group.leave()
        }

        let result = group.wait(timeout: .now() + 5)
        if result == .success && userAnswer != nil && userAnswer! - 1 == question.correctAnswer {
            isCorrect = true
            currentUserScore += 2
            print("Correct ! Réponse rapide. +2 points.")
        } else if result == .timedOut {
            _ = group.wait(timeout: .now() + 25) // Correction ici pour gérer le warning
            if userAnswer != nil && userAnswer! - 1 == question.correctAnswer {
                isCorrect = true
                currentUserScore += 1
                print("Correct ! +1 point.")
            }
        }

        if isCorrect == nil {
            print("Incorrect ou temps écoulé. La bonne réponse était \(question.correctAnswer + 1).")
        }

        switch question.difficulty {
            case 1:
                print("C'était une question facile.")
            case 2:
                print("Pas mal, c'était une question de niveau moyen.")
            case 3:
                print("C'était une question difficile, bien tenté !")
            default:
                print("Cette question avait un niveau de difficulté inattendu.")
        }
    }
}
