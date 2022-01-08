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

class Amazing {
    struct Path: OptionSet {
        var rawValue: Int
        static let down: Path = .init(rawValue: 1 << 0)
        static let right: Path = .init(rawValue: 1 << 1)
    }

    struct Dimensions {
        let xRange: ClosedRange<Int>
        let yRange: ClosedRange<Int>
        var size: Int { xRange.count * yRange.count }
    }

    struct Cursor {
        let x: Int
        let y: Int
        let dimensions: Dimensions

        func with(x: Int, y: Int) -> Cursor {
            Cursor(x: x, y: y, dimensions: dimensions)
        }

        var atLeftEdge: Bool { x == dimensions.xRange.lowerBound }
        var atRightEdge: Bool { x == dimensions.xRange.upperBound }
        var atTopEdge: Bool { y == dimensions.yRange.lowerBound }
        var atBottomEdge: Bool { y == dimensions.yRange.upperBound }

        var left: Cursor { with(x: x - 1, y: y) }
        var right: Cursor { with(x: x + 1, y: y) }
        var up: Cursor { with(x: x, y: y - 1) }
        var down: Cursor { with(x: x, y: y + 1) }

        var next: Cursor {
            let nextIndex = (y * dimensions.xRange.count + x + 1) % dimensions.size
            return with(x: nextIndex % dimensions.xRange.count, y: nextIndex / dimensions.xRange.count)
        }
    }

    var startCursor: Cursor { Cursor(x: dimensions.xRange.lowerBound, y: dimensions.yRange.lowerBound, dimensions: dimensions) }

    private let dimensions: Dimensions
    private var entrancePosition: Int = -1
    private var exitPosition: Int = -1
    private var stepIndex: Int = 1
    private var data: [[(visited: Bool, paths: Path)]]
    private var cursor: Cursor = .init(x: 0, y: 0, dimensions: .init(xRange: 0 ... 1, yRange: 0 ... 1))

    init(columns: Int, rows: Int) {
        dimensions = .init(xRange: 0 ... columns - 1, yRange: 0 ... rows - 1)
        data = Array(repeating: Array(repeating: (false, []), count: dimensions.yRange.count), count: dimensions.xRange.count)
        cursor = startCursor
    }

    func buildMaze() -> (dimensions: Dimensions, entrancePosition: Int, paths: [[Path]]) {
        guard entrancePosition == -1 else { return (dimensions, entrancePosition, data.map { $0.map { $0.paths } }) }

        entrancePosition = Int.random(in: dimensions.xRange) // Create the entrance.
        cursor = cursor.with(x: entrancePosition, y: 0)
        step(cursor, add: [], at: cursor)

        while (stepIndex < dimensions.size) { // We need to fill every cell with the maze information.
            findStepOptions()
        }

        if exitPosition == -1 { // Add exit if still not found.
            exitPosition = Int.random(in: dimensions.xRange)
            cursor = cursor.with(x: exitPosition, y: dimensions.yRange.upperBound)
            step(cursor, add: .down, at: cursor)
        }

        return (dimensions, entrancePosition, data.map { $0.map { $0.paths } })
    }

    private func findStepOptions() {
        let options: [() -> Void] = [
            (cursor.atLeftEdge || data[cursor.left].visited) ? nil : { [self] in step(cursor.left, add: .right, at: cursor.left) },
            (cursor.atTopEdge || data[cursor.up].visited) ? nil : { [self] in step(cursor.up, add: .down, at: cursor.up) },
            (cursor.atRightEdge || data[cursor.right].visited) ? nil : { [self] in step(cursor.right, add: .right, at: cursor) },
            (cursor.atBottomEdge || data[cursor.down].visited) ? nil : { [self] in step(cursor.down, add: .down, at: cursor) },
            (cursor.atBottomEdge && exitPosition == -1) ? createExitAtCursor : nil,
        ].compactMap { $0 }
        (options.randomElement() ?? { [self] in moveCursorToAnotherPathCell(startSearchFrom: cursor.next) })()
    }

    private func step(_ newCursor: Cursor, add way: Path, at wayCursor: Cursor) {
        data[wayCursor].paths.insert(way)
        cursor = newCursor
        data[cursor].visited = true
        stepIndex += 1
    }

    private func createExitAtCursor() {
        exitPosition = cursor.x
        let nextCursorOrFirstCell = data[cursor].paths.isEmpty ? startCursor : cursor.next
        data[cursor].paths.insert(.down)
        moveCursorToAnotherPathCell(startSearchFrom: nextCursorOrFirstCell)
    }

    private func moveCursorToAnotherPathCell(startSearchFrom: Cursor) {
        cursor = startSearchFrom
        while (!data[cursor].visited) {
            cursor = cursor.next
        }
    }
}

fileprivate extension MutableCollection where Self.Element: MutableCollection, Index == Int, Element.Index == Int {
    subscript(_ cursor: Amazing.Cursor) -> Element.Element {
        get { self[cursor.x][cursor.y] }
        set { self[cursor.x][cursor.y] = newValue }
    }
}
