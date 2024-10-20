import SwiftCompilerPlugin

@main
struct MacroDemoPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        StringifyMacro.self,
        OptionSetMacro.self,
        FourCharacterCodeMacro.self,
        PeerValueWithSuffixNameMacro.self,
        AddAsyncMacro.self,
        MemberDeprecatedMacro.self,
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
        
        guard let typeSyntax = node.attributeName.as(IdentifierTypeSyntax.self),
              let rawType = typeSyntax.genericArgumentClause?.arguments.first?.argument.as(IdentifierTypeSyntax.self)?.name
        else {
            return []
        }
        
        guard let structDecl = declaration.as(StructDeclSyntax.self)
        else {
            return []
        }
        
        guard let enumsMembersDeclSyntax = structDecl.memberBlock.members.compactMap({ member -> EnumDeclSyntax? in
            guard let enumDecl = member.decl.as(EnumDeclSyntax.self)
            else {
                return nil
            }
            return enumDecl
        }).map({ enumDeclSyntax in
            let enumName = enumDeclSyntax.name.text
            let ret = enumDeclSyntax.memberBlock.members.compactMap({ member -> EnumCaseElementListSyntax? in
                guard let caseDecl = member.decl.as(EnumCaseDeclSyntax.self)?.elements
                else {
                    return nil
                }
                return caseDecl
            }).flatMap ({ caseElement in
                let casesMember: [DeclSyntax] = caseElement.map { $0.name.text }.map { caseName in
                    return """
                    static let \(raw: caseName): Self = Self(rawValue: 1 << \(raw: enumName).\(raw: caseName).rawValue)
                    """
                }
                return casesMember
            })
            return ret
        }).first
        else {
            return []
        }
        
        let ret: [DeclSyntax] = [
            "typealias RawValue = \(rawType)",
            "var rawValue: RawValue",
            "init() { self.rawValue = 0 }",
            "init(rawValue: RawValue) { self.rawValue = rawValue }",
        ]
        return ret + enumsMembersDeclSyntax
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
        
        let optionSetConform: DeclSyntax = """
        extension \(type.trimmed): OptionSet {}
        """
        
        guard let extensionDecl = optionSetConform.as(ExtensionDeclSyntax.self)
        else {
            return []
        }
        
        return [extensionDecl]
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
    
}


/// Peer 'var' with the name suffixed with '_peer'.
public enum PeerValueWithSuffixNameMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let identified = declaration.asProtocol(NamedDeclSyntax.self) else {
            return []
        }
        return ["var \(raw: identified.name.text)_peer: Int { 1 }"]
    }
}

public struct AddAsyncMacro: PeerMacro {
    public static func expansion<Context: MacroExpansionContext, Declaration: DeclSyntaxProtocol>(
        of node: AttributeSyntax,
        providingPeersOf declaration: Declaration,
        in context: Context
    ) throws -> [DeclSyntax] {
        
        // Only on functions at the moment.
        guard var funcDecl = declaration.as(FunctionDeclSyntax.self) else {
            throw CustomError.message("@addAsync only works on functions")
        }
        
        // This only makes sense for non async functions.
        if funcDecl.signature.effectSpecifiers?.asyncSpecifier != nil {
            throw CustomError.message(
                "@addAsync requires an non async function"
            )
        }
        
        // This only makes sense void functions
        if funcDecl.signature.returnClause?.type.as(IdentifierTypeSyntax.self)?.name.text != "Void" {
            throw CustomError.message(
                "@addAsync requires an function that returns void"
            )
        }
        
        // Requires a completion handler block as last parameter
        let completionHandlerParameter = funcDecl
            .signature
            .parameterClause
            .parameters.last?
            .type.as(AttributedTypeSyntax.self)?
            .baseType.as(FunctionTypeSyntax.self)
        guard let completionHandlerParameter else {
            throw CustomError.message(
                "@addAsync requires an function that has a completion handler as last parameter"
            )
        }
        
        // Completion handler needs to return Void
        if completionHandlerParameter.returnClause.type.as(IdentifierTypeSyntax.self)?.name.text != "Void" {
            throw CustomError.message(
                "@addAsync requires an function that has a completion handler that returns Void"
            )
        }
        
        let returnType = completionHandlerParameter.parameters.first?.type
        
        let isResultReturn = returnType?.children(viewMode: .all).first?.description == "Result"
        let successReturnType =
        if isResultReturn {
            returnType!.as(IdentifierTypeSyntax.self)!.genericArgumentClause?.arguments.first!.argument
        } else {
            returnType
        }
        
        // Remove completionHandler and comma from the previous parameter
        var newParameterList = funcDecl.signature.parameterClause.parameters
        newParameterList.removeLast()
        var newParameterListLastParameter = newParameterList.last!
        newParameterList.removeLast()
        newParameterListLastParameter.trailingTrivia = []
        newParameterListLastParameter.trailingComma = nil
        newParameterList.append(newParameterListLastParameter)
        
        // Drop the @addAsync attribute from the new declaration.
        let newAttributeList = funcDecl.attributes.filter {
            guard case let .attribute(attribute) = $0,
                  let attributeType = attribute.attributeName.as(IdentifierTypeSyntax.self),
                  let nodeType = node.attributeName.as(IdentifierTypeSyntax.self)
            else {
                return true
            }
            
            return attributeType.name.text != nodeType.name.text
        }
        
        let callArguments: [String] = newParameterList.map { param in
            let argName = param.secondName ?? param.firstName
            
            let paramName = param.firstName
            if paramName.text != "_" {
                return "\(paramName.text): \(argName.text)"
            }
            
            return "\(argName.text)"
        }
        
        let switchBody: ExprSyntax = """
            switch returnValue {
            case .success(let value):
              continuation.resume(returning: value)
            case .failure(let error):
              continuation.resume(throwing: error)
            }
        """
        
        let newBody: ExprSyntax = """
        
        \(raw: isResultReturn ? "try await withCheckedThrowingContinuation { continuation in" : "await withCheckedContinuation { continuation in")
          \(raw: funcDecl.name)(\(raw: callArguments.joined(separator: ", "))) { \(raw: returnType != nil ? "returnValue in" : "")
        
        \(raw: isResultReturn ? switchBody : "continuation.resume(returning: \(raw: returnType != nil ? "returnValue" : "()"))")
          }
        }
        
        """
        
        // add async
        funcDecl.signature.effectSpecifiers = FunctionEffectSpecifiersSyntax(
            leadingTrivia: .space,
            asyncSpecifier: .keyword(.async),
            throwsClause: isResultReturn ? ThrowsClauseSyntax(throwsSpecifier: .keyword(.throws)) : nil
        )
        
        // add result type
        if let successReturnType {
            funcDecl.signature.returnClause = ReturnClauseSyntax(
                leadingTrivia: .space,
                type: successReturnType.with(\.leadingTrivia, .space)
            )
        } else {
            funcDecl.signature.returnClause = nil
        }
        
        // drop completion handler
        funcDecl.signature.parameterClause.parameters = newParameterList
        funcDecl.signature.parameterClause.trailingTrivia = []
        
        funcDecl.body = CodeBlockSyntax(
            leftBrace: .leftBraceToken(leadingTrivia: .space),
            statements: CodeBlockItemListSyntax(
                [CodeBlockItemSyntax(item: .expr(newBody))]
            ),
            rightBrace: .rightBraceToken(leadingTrivia: .newline)
        )
        
        funcDecl.attributes = newAttributeList
        
        funcDecl.leadingTrivia = .newlines(2)
        
        return [DeclSyntax(funcDecl)]
    }
}


enum CustomError: Error { case message(String) }

extension SyntaxCollection {
    mutating func removeLast() {
        self.remove(at: self.index(before: self.endIndex))
    }
}

/// Add '@available(*, deprecated)' to members.
public enum MemberDeprecatedMacro: MemberAttributeMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingAttributesFor member: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AttributeSyntax] {
        return ["@available(*, deprecated)"]
    }
}
