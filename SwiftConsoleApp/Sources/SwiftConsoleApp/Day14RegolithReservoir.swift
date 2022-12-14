
private enum Entity : Renderable {
    case air, rock, sand, sandSource
    
    static let defaultValue: Entity = .air
    
    func render() -> Character {
        switch self {
        case .air: return "."
        case .rock: return "#"
        case .sand: return "o"
        case .sandSource: return "+"
        }
    }
}

private func parse(line: String) -> [Point] {
    let components = line.components(separatedBy: " -> ")
    
    var result = [Point]()
    
    for c in components {
        let xy = c.split(separator: ",")
        guard xy.count == 2, let x = Int(xy[0]), let y = Int(xy[1]) else { fatalError("\(c) was not Int,Int") }
        
        result.append(Point(x: x, y: y))
    }
    return result
}

private func draw(path: [Point], onto grid: Grid<Entity>) {
    var pathIter = path.makeIterator()
    guard var sourcePt = pathIter.next(), var destPt = pathIter.next() else {
        // nothing to draw unless there's 2 or more points
        return
    }
    
    while true {
        // draw from p1 to p2
        var nextPt = sourcePt
        while nextPt != destPt {
            grid[nextPt] = .rock
            
            let xDiff = destPt.x > nextPt.x ? 1 : (destPt.x < nextPt.x ? -1 : 0)
            let yDiff = destPt.y > nextPt.y ? 1 : (destPt.y < nextPt.y ? -1 : 0)
            
            nextPt = Point(x: nextPt.x + xDiff, y: nextPt.y + yDiff)
        }
        grid[nextPt] = .rock
        
        sourcePt = destPt
        guard let nextDest = pathIter.next() else { break } // end of path
        destPt = nextDest
    }
}

// simulates sand falling. returns nil if we fall off the edge of the grid
private func dropSand(from: Point, on grid: Grid<Entity>) -> Point? {
    enum Fallable {
        case free, blocked, outOfBounds
    }
    func fallable(_ x: Int, _ y: Int) -> Fallable {
        if let target = grid[x, y] {
            return target == .air ? .free : .blocked
        } else {
            return .outOfBounds
        }
    }
    
    var (x, y) = (from.x, from.y)
    while true {
        switch (fallable(x-1, y+1), fallable(x, y+1), fallable(x+1, y+1)) {
        case (_, .free, _): // we can fall directly down.
            y = y + 1
        case (.free, .blocked, _): // we can't fall directly down but we can fall to the left
            x = x - 1
            y = y + 1
        case (.blocked, .blocked, .free): // we can't fall down or left but we can fall to the right
            x = x + 1
            y = y + 1
        case (.blocked, .blocked, .blocked):
            return Point(x: x, y: y) // we can't fall at all. Stop here
        default:
            return nil // other things will be out of bounds
        }
    }
}

struct Day14RegolithReservoirP1 {
    
    static func run(fileName: String) throws {
        let sandSource = Point(x: 500, y: 0)
        
        let grid = Grid<Entity>(rows: 550, cols: 550)
        grid[sandSource] = .sandSource
            
        for line in try linesInFile(fileName) {
            let path = parse(line: line)
            draw(path: path, onto: grid)
        }
                
        for i in 0..<1000 {
            guard let sandPos = dropSand(from: sandSource, on: grid) else {
                // fell off the bottom of the grid. We're done here
                print("came to rest after \(i) units of sand")
                break
            }
            grid[sandPos] = .sand
        }
        
        let frame = grid.getInterestingViewport()
        print(grid.render(frame: frame))
        
    }
}

struct Day14RegolithReservoirP2 {
    
    static func run(fileName: String) throws {
        let sandSource = Point(x: 500, y: 0)
        
        let grid = Grid<Entity>(rows: 200, cols: 700)
        grid[sandSource] = .sandSource
            
        // record the max y so we can calculate the floor
        var maxY = 0
        
        for line in try linesInFile(fileName) {
            let path = parse(line: line)
            draw(path: path, onto: grid)
            
            let maxYinPath = path.map { point in point.y }.max()!
            if maxYinPath > maxY {
                maxY = maxYinPath
            }
        }
        
        let frame = grid.getInterestingViewport()!
        let expandedFrame = Frame(x: frame.x - 8, y: 0, width: frame.width + 18, height: frame.height + 2)
        
        // add the floor AFTER we've calculated the interesting viewport
        draw(path: [Point(x: 0, y: maxY + 2), Point(x: grid.cols-1, y: maxY + 2)], onto: grid)
                
        for i in 0..<30000 {
            guard let sandPos = dropSand(from: sandSource, on: grid) else {
                // fell off the bottom of the grid. We're done here
                print("came to rest after \(i) units of sand")
                break
            }
            grid[sandPos] = .sand
            
            if sandPos == sandSource {
                print("the sand source was blocked after \(i+1) units of sand")
                break
            }
        }
        
        print(grid.render(frame: expandedFrame))
        
    }
}
