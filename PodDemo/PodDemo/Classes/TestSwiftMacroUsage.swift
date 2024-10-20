import MacroDemo

public struct TestSwiftMacroUsage {
    
    public static func testFunc() {
        
        let magicNumber = #fourCharacterCode("ABCD")
        
        print("magic number = \(magicNumber)")
    }
}
