import Foundation

// if head and tail are in the same space we just show head so no need to track both specifically
private enum RopePosition {
    case none, head, body(Int), tail
}

private struct Point : Equatable {
    let x: Int
    let y: Int
}

private struct Grid {
    let rows: Int
    let cols: Int
    var rawBuffer: [RopePosition]
    
    init(rows: Int, cols: Int) {
        self.rows = rows
        self.cols = cols
        self.rawBuffer = Array(repeating: .none, count: rows * cols)
    }
    
    subscript(x: Int, y: Int) -> RopePosition {
        get {
            if x < 0 || y < 0 || x >= cols || y >= rows { fatalError("x or y out of range") }
            return rawBuffer[y * cols + x]
        }
        set {
            if x < 0 || y < 0 || x >= cols || y >= rows { fatalError("x or y out of range") }
            rawBuffer[y * cols + x] = newValue
        }
    }
    
    subscript(point: Point) -> RopePosition {
        get { self[point.x, point.y] }
        set { self[point.x, point.y] = newValue }
    }
    
    func render() -> String {
        var output = ""
        for i in rawBuffer.indices {
            switch rawBuffer[i] {
            case .head:
                output += "H"
            case .body(let n):
                output += "\(n)"
            case .tail:
                output += "T"
            default:
                output += "."
            }
            
            if i % cols == cols-1 {
                output += "\n"
            }
        }
        return output
    }
}

// an instruction to move but only ever by one position at a time
private enum Instruction {
    case left, right, up, down
}

private func parseInstruction(text: String) -> [Instruction] {
    let components = text.split(separator: " ")
    guard components.count == 2, let num = Int(components[1]) else {
        fatalError("can't deal with line \(text)")
    }
    switch components[0] {
    case "L": return Array(repeating: .left, count: num)
    case "R": return Array(repeating: .right, count: num)
    case "U": return Array(repeating: .up, count: num)
    case "D": return Array(repeating: .down, count: num)
    default: fatalError("can't deal with line \(text)")
    }
}

struct Day9RopeBridgeP1 {
    public static func run(fileName: String) throws {
        let lines = try linesInFile(fileName)
        
        var grid = Grid(rows: 26, cols: 20)
//        let startPosition = Point(x: grid.cols / 2, y: grid.rows / 2)
        let startPosition = Point(x: 11, y: 15)
        
        var headPos = startPosition
        var tailPos = startPosition
        
        grid[startPosition] = .head
        print(grid.render())

        // at the end of each frame, record where the tail was at the end of the frame and keep the record
        var tailTrailGrid = Grid(rows: grid.rows, cols: grid.cols)
        tailTrailGrid[startPosition] = .tail
        
        for instruction in lines.flatMap({ parseInstruction(text: $0) }) {
            switch instruction {
            case .left:
                headPos = Point(x: headPos.x-1, y: headPos.y)
            case .right:
                headPos = Point(x: headPos.x+1, y: headPos.y)
            case .up:
                headPos = Point(x: headPos.x, y: headPos.y-1)
            case .down:
                headPos = Point(x: headPos.x, y: headPos.y+1)
            }
            tailPos = pull(head: headPos, tail: tailPos)
                        
            tailTrailGrid[tailPos] = .tail

            var frame = Grid(rows: grid.rows, cols: grid.cols)
            frame[tailPos] = .tail
            frame[headPos] = .head
            print(frame.render())
        }
        print(tailTrailGrid.render())
        
        let positionCount = tailTrailGrid.rawBuffer.reduce(0, { memo, pos in
            switch pos {
            case .tail: return memo + 1
            default: return memo
            }
        })
        
        print("tail visited \(positionCount) positions at least once")
    }
}

// tail is the knot we are moving
// head is the knot that pulled us
private func pull(head: Point, tail: Point) -> Point {
    let xDistance = head.x - tail.x
    let yDistance = head.y - tail.y
    
    switch (xDistance, yDistance) {
    case (-1...1, -1...1): return tail // no need to move, it's already close enough
        
    // If the head is ever two steps directly up, down, left, or right from the tail, the tail must also move one step in that direction so it remains close enough:
    case (1..., 0): return Point(x: tail.x+1, y: tail.y)
    case (...0, 0): return Point(x: tail.x-1, y: tail.y)
    case (0, 1...): return Point(x: tail.x, y: tail.y+1)
    case (0, ...0): return Point(x: tail.x, y: tail.y-1)
        
    // Otherwise, if the head and tail aren't touching and aren't in the same row or column, the tail always moves one step diagonally to keep up:
    case (1..., 1...): return Point(x: tail.x+1, y: tail.y+1)
    case (...0, ...0): return Point(x: tail.x-1, y: tail.y-1)
    case (...0, 1...): return Point(x: tail.x-1, y: tail.y+1)
    case (1..., ...0): return Point(x: tail.x+1, y: tail.y-1)
        
    default: fatalError("unhandled xDistance,yDistance of (\(xDistance), \(yDistance)")
    }
}

struct Day9RopeBridgeP2 {
    public static func run(fileName: String) throws {
        let lines = try linesInFile(fileName)
        
        var grid = Grid(rows: 700, cols: 700)
        let startPosition = Point(x: grid.cols / 2 - 100, y: grid.rows / 2 - 100)
        
        // head is the first element in this array, tail is the last
        var rope = Array(repeating: startPosition, count: 10)
        func toRopePosition(_ i: Int) -> RopePosition {
            switch i {
            case 0: return .head
            case 1...8: return .body(i)
            case 9: return .tail
            default: fatalError("toRopePosition unhandled \(i)")
            }
        }
        
        grid[startPosition] = .head

        // at the end of each frame, record where the tail was at the end of the frame and keep the record
        var tailTrailGrid = Grid(rows: grid.rows, cols: grid.cols)
        tailTrailGrid[startPosition] = .tail
        
        for instruction in lines.flatMap({ parseInstruction(text: $0) }) {
            
            var knotPos = rope[0]
            
            switch instruction {
            case .left:
                knotPos = Point(x: knotPos.x-1, y: knotPos.y)
            case .right:
                knotPos = Point(x: knotPos.x+1, y: knotPos.y)
            case .up:
                knotPos = Point(x: knotPos.x, y: knotPos.y-1)
            case .down:
                knotPos = Point(x: knotPos.x, y: knotPos.y+1)
            }
            rope[0] = knotPos

            // now pull the next knot
            var prevPos = knotPos
            for idx in 1..<rope.count {

                let nextKnotPos = pull(head: prevPos, tail: rope[idx])
                rope[idx] = nextKnotPos
                prevPos = nextKnotPos
            }
            
            // after we've pulled all the knots the last one is the tail; record its position
            tailTrailGrid[prevPos] = .tail
            
//            var frame = Grid(rows: grid.rows, cols: grid.cols)
//            for i in rope.indices.reversed() {
//                frame[rope[i]] = toRopePosition(i)
//            }
//            print(frame.render())
        }
        
        print(tailTrailGrid.render())
        
        let positionCount = tailTrailGrid.rawBuffer.reduce(0, { memo, pos in
            switch pos {
            case .tail: return memo + 1
            default: return memo
            }
        })
        
        print("tail visited \(positionCount) positions at least once")
    }
}