import Foundation

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

extension MutableCollection where Self.Element: MutableCollection, Index == Int, Element.Index == Int {
    subscript(_ cursor: Amazing.Cursor) -> Element.Element {
        get { self[cursor.x][cursor.y] }
        set { self[cursor.x][cursor.y] = newValue }
    }
}
