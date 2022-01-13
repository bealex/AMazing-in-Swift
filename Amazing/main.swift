import Foundation

print("A-Mazing Program")
print("Creative computing, Morristown, New Jersey")
print()

var inputColumns: Int = 0
var inputRows: Int = 0
repeat {
    print("Please input width and length (space-separated): ", terminator: "")
    let input = readLine() ?? "0 0"
    let numbers = input.components(separatedBy: .decimalDigits.inverted)
    (inputColumns, inputRows) = (Int(numbers[0]) ?? 0, Int(numbers[1]) ?? 0)
    if inputColumns <= 1 || inputRows <= 1 {
        print("Meaningless dimensions. Try again.")
    }
} while inputColumns <= 1 && inputRows <= 1

let amazing = Amazing(columns: inputColumns, rows: inputRows)
let (dimensions, entrance, paths) = amazing.buildMaze()
let lines: [[String]] = dimensions.yRange
    .flatMap { row -> [[String]] in
        let topWalls: [String] = row == 0 ? dimensions.xRange.flatMap { $0 == entrance ? [ "•", " " ] : [ "•", "━" ] } + [ "•" ] : []
        let verticalWalls: [String] = [ "┃" ] + dimensions.xRange.flatMap { !paths[$0][row].contains(.right) ? [ " ", "┃" ] : [ " ", " " ] }
        let horizontalWalls: [String] = dimensions.xRange.flatMap { !paths[$0][row].contains(.down) ? [ "•", "━" ] : [ "•", " " ] } + [ "•" ]
        return [ topWalls, verticalWalls, horizontalWalls ].filter { !$0.isEmpty }
    }
print("Generated a maze with size \(dimensions.xRange.count)•\(dimensions.yRange.count):")
print(lines.map { $0.joined() }.joined(separator: "\n"))

print()
print(beautify(lines: lines).map { $0.joined() }.joined(separator: "\n"))

if let solution = solve(paths: paths, entrance: entrance, dimensions: dimensions) {
    var linesWithSolution = lines
    solution.enumerated().forEach { index, cursor in
        let x = cursor.x * 2 + 1
        let y = cursor.y * 2 + 1
        linesWithSolution[y][x] = "⋅"
        if index == 0 {
            linesWithSolution[0][x] = "⋅"
        } else if index == solution.count - 1 {
            linesWithSolution[linesWithSolution.count - 1][x] = "⋅"
        }
    }
    print()
    print(beautify(lines: linesWithSolution).map { $0.joined() }.joined(separator: "\n"))
}

func beautify(lines: [[String]]) -> [[String]] {
    func at(lines: [[String]], _ x: Int, _ y: Int) -> String {
        guard x >= 0, y >= 0, y < lines.count, x < lines[y].count else { return " " }
        return lines[y][x]
    }

    func rightSymbol(lines: [[String]], char: String, x: Int, y: Int) -> String? {
        let leftNotPath = at(lines: lines, x - 1, y).replacingOccurrences(of: "⋅", with: " ")
        let topNotPath = at(lines: lines, x, y - 1).replacingOccurrences(of: "⋅", with: " ")
        let rightNotPath = at(lines: lines, x + 1, y).replacingOccurrences(of: "⋅", with: " ")
        let bottomNotPath = at(lines: lines, x, y + 1).replacingOccurrences(of: "⋅", with: " ")
        let leftPath = at(lines: lines, x - 1, y).replacingOccurrences(of: "•", with: " ").replacingOccurrences(of: "─", with: " ").replacingOccurrences(of: "│", with: " ")
        let topPath = at(lines: lines, x, y - 1).replacingOccurrences(of: "•", with: " ").replacingOccurrences(of: "─", with: " ").replacingOccurrences(of: "│", with: " ")
        let rightPath = at(lines: lines, x + 1, y).replacingOccurrences(of: "•", with: " ").replacingOccurrences(of: "─", with: " ").replacingOccurrences(of: "│", with: " ")
        let bottomPath = at(lines: lines, x, y + 1).replacingOccurrences(of: "•", with: " ").replacingOccurrences(of: "─", with: " ").replacingOccurrences(of: "│", with: " ")

        let wallReplacements: [String: String] = [
            "•    ": " ",

            "•━   ": "╸", "•  ━ ": "╺",
            "• ┃  ": "╹", "•   ┃": "╻",

            "• ┃ ┃": "┃",

            "•  ━┃": "┏", "•━ ━ ": "━", "•━ ━┃": "┳", "•━  ┃": "┓",
            "• ┃━┃": "┣",               "•━┃━┃": "╋", "•━┃ ┃": "┫",
            "• ┃━ ": "┗",               "•━┃━ ": "┻", "•━┃  ": "┛",
        ]

        let pathReplacements: [String: String] = [
            "⋅ ⋅  ": "⋅", "⋅   ⋅": "⋅",
            " ⋅ ⋅ ": "⋅", "  ⋅ ⋅": "⋅",
            " ⋅⋅  ": "⋅", "  ⋅⋅ ": "⋅",
            "   ⋅⋅": "⋅", " ⋅  ⋅": "⋅",
        ]

        let wallMatch = "\(char)\(leftNotPath)\(topNotPath)\(rightNotPath)\(bottomNotPath)"
        let pathMatch = "\(char)\(leftPath)\(topPath)\(rightPath)\(bottomPath)"
        return wallReplacements[wallMatch] ?? pathReplacements[pathMatch]
    }

    func rightPathSymbol(lines: [[String]], char: String, x: Int, y: Int) -> String? {
        guard char == "⋅" else { return nil }

        let left = at(lines: lines, x - 1, y)
        let top = at(lines: lines, x, y - 1)
        let right = at(lines: lines, x + 1, y)
        let bottom = at(lines: lines, x, y + 1)
        switch (left, top, right, bottom) {
            case ("⋅", "⋅", _, _): return "╯"
            case (_, "⋅", "⋅", _): return "╰"
            case (_, _, "⋅", "⋅"): return "╭"
            case ("⋅", _, _, "⋅"): return "╮"
            case ("⋅", _, "⋅", _): return "╌"
            case (_, "⋅", _, "⋅"): return "╎"
            default: return nil
        }
    }

    let beautifyWallsAndBetterPath = lines.enumerated().map { lineIndex, line in
        line.enumerated().map { charIndex, char in
            rightSymbol(lines: lines, char: char, x: charIndex, y: lineIndex) ?? char
        }
    }
    return beautifyWallsAndBetterPath.enumerated().map { lineIndex, line in
        line.enumerated().map { charIndex, char in
            rightPathSymbol(lines: beautifyWallsAndBetterPath, char: char, x: charIndex, y: lineIndex) ?? char
        }
    }
}

func solve(paths: [[Amazing.Path]], entrance: Int, dimensions: Amazing.Dimensions) -> [Amazing.Cursor]? {
    func findPath(at cursor: Amazing.Cursor, pathStack: [Amazing.Cursor]) -> [Amazing.Cursor]? {
        if cursor.atBottomEdge && paths[cursor].contains(.down) {
            return pathStack + [ cursor ]
        }

        var currentResult: [Amazing.Cursor]?
        if !cursor.atRightEdge && paths[cursor].contains(.right) && !pathStack.contains(where: { $0.x == cursor.x + 1 && $0.y == cursor.y }) {
            currentResult = findPath(at: cursor.right, pathStack: pathStack + [ cursor ])
        }
        guard currentResult == nil else { return currentResult }

        if !cursor.atBottomEdge && paths[cursor].contains(.down) && !pathStack.contains(where: { $0.x == cursor.x && $0.y == cursor.y + 1 }) {
            currentResult = findPath(at: cursor.down, pathStack: pathStack + [ cursor ])
        }
        guard currentResult == nil else { return currentResult }

        if !cursor.atLeftEdge && paths[cursor.left].contains(.right) && !pathStack.contains(where: { $0.x == cursor.x - 1 && $0.y == cursor.y }) {
            currentResult = findPath(at: cursor.left, pathStack: pathStack + [ cursor ])
        }
        guard currentResult == nil else { return currentResult }

        if !cursor.atTopEdge && paths[cursor.up].contains(.down) && !pathStack.contains(where: { $0.x == cursor.x && $0.y == cursor.y - 1 }) {
            currentResult = findPath(at: cursor.up, pathStack: pathStack + [ cursor ])
        }
        return currentResult
    }

    return findPath(at: .init(x: entrance, y: dimensions.yRange.lowerBound, dimensions: dimensions), pathStack: [])
}
