import SwiftCompilerPlugin

@main
struct MacroDemoPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        StringifyMacro.self,
        OptionSetMacro.self,
        FourCharacterCodeMacro.self,
    ]
}

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Implementation of the `stringify` macro, which takes an expression
/// of any type and produces a tuple containing the value of that expression
/// and the source code that produced the value. For example
///
///     #stringify(x + y)
///
///  will expand to
///
///     (x + y, "x + y")
public struct StringifyMacro: ExpressionMacro {
    
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        guard let argument = node.arguments.first?.expression else {
            fatalError("compiler bug: the macro does not have any arguments")
        }

        return "(\(argument), \(literal: argument.description))"
    }
}

public struct OptionSetMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        return [
            "typealias RawValue = Int",
            "var rawValue: RawValue",
            "init() { self.rawValue = 0 }",
            "init(rawValue: RawValue) { self.rawValue = rawValue }",
            "static let nuts: Self = Self(rawValue: 1 << Options.nuts.rawValue)",
            "static let cherry: Self = Self(rawValue: 1 << Options.cherry.rawValue)",
            "static let fudge: Self = Self(rawValue: 1 << Options.fudge.rawValue)"
        ]
    }
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        return [
            
        ]
    }
}

extension OptionSetMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        return [
        ]
    }
}

public struct FourCharacterCodeMacro: ExpressionMacro {
    
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {
        
        guard let argument = node.arguments.first?.expression,
              let segments = argument.as(StringLiteralExprSyntax.self)?.segments,
              segments.count == 1,
              case .stringSegment(let literalSegment)? = segments.first
        else {
            throw CustomError.message("Need a static string")
        }
        
        let string = literalSegment.content.text
        guard let result = fourCharacterCode(for: string)
        else {
            throw CustomError.message("Invalid four-character code")
        }
        
        return "\(raw: result) as UInt32"
    }
    
    private static func fourCharacterCode(for characters: String) -> UInt32? {
        guard characters.count == 4 else { return nil }
        var result: UInt32 = 0
        for character in characters {
            result = result << 8
            guard let asciiValue = character.asciiValue else { return nil }
            result += UInt32(asciiValue)
        }
        return result
    }
    
    enum CustomError: Error { case message(String) }
}
