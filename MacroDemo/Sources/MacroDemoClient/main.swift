import MacroDemo

// MARK: Freestanding Macro product a value

let a = 17
let b = 25
let (result, code) = #stringify(a + b)
print("The value \(result) was produced by the code \"\(code)\" in \(#function) file: \(#file)")

let magicNumber = #fourCharacterCode("ABCD")
print("magicNumber = \(magicNumber)")

// MARK: Freestanding Macro perform action

#warning("this is a warning message for demo of freestanding macro usage")

// MARK: Attached Macro usage

@OptionSet<Int>
struct SundaeToppings {
    private enum Options: Int {
        case nuts
        case cherry
        case fudge
    }
}
