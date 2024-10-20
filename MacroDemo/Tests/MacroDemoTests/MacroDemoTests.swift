import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(MacroDemoMacros)
import MacroDemoMacros

let testMacros: [String: Macro.Type] = [
    "stringify": StringifyMacro.self,
    "fourCharacterCode": FourCharacterCodeMacro.self,
    "OptionSet": OptionSetMacro.self,
]
#endif

final class MacroDemoTests: XCTestCase {
    
    func testMacro() throws {
        #if canImport(MacroDemoMacros)
        assertMacroExpansion(
            """
            #stringify(a + b)
            """,
            expandedSource: """
            (a + b, "a + b")
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testMacroWithStringLiteral() throws {
        #if canImport(MacroDemoMacros)
        assertMacroExpansion(
            #"""
            #stringify("Hello, \(name)")
            """#,
            expandedSource: #"""
            ("Hello, \(name)", #""Hello, \(name)""#)
            """#,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func testFourCharacterCodeMacro() throws {
        #if canImport(MacroDemoMacros)
        assertMacroExpansion(
            #"""
            let abcd = #fourCharacterCode("ABCD")
            """#,
            expandedSource: #"""
            let abcd = 1094861636 as UInt32
            """#,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func testOptionSetMacro() throws {
        #if canImport(MacroDemoMacros)
        assertMacroExpansion(
            #"""
            @OptionSet<Int>
            struct SundaeToppings {
                private enum Options: Int {
                    case nuts
                    case cherry
                    case fudge
                }
            }
            """#,
            expandedSource: #"""
            struct SundaeToppings {
                private enum Options: Int {
                    case nuts
                    case cherry
                    case fudge
                }
                typealias RawValue = Int
                var rawValue: RawValue
                init() { self.rawValue = 0 }
                init(rawValue: RawValue) { self.rawValue = rawValue }
                static let nuts: Self = Self(rawValue: 1 << Options.nuts.rawValue)
                static let cherry: Self = Self(rawValue: 1 << Options.cherry.rawValue)
                static let fudge: Self = Self(rawValue: 1 << Options.fudge.rawValue)
            }
            extension SundaeToppings: OptionSet { }
            """#,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
