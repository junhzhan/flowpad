

pub contract StrUtility {
    pub fun splitStr(str: String, delimiter: Character): [String] {
        var lastIndex = -1 
        var index = 0
        let splitResult: [String] = []
        while index < str.length {
            if str[index] == delimiter {
                if lastIndex + 1 < index {
                    splitResult.append(str.slice(from: lastIndex + 1, upTo: index))
                }
                lastIndex = index
            }
            index = index + 1
        }
        if lastIndex + 1 < index {
            splitResult.append(str.slice(from: lastIndex + 1, upTo: index))
        }
        return splitResult
    }
    init() {}
}