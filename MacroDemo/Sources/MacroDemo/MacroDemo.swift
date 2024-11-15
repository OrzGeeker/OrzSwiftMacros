// The Swift Programming Language
// https://docs.swift.org/swift-book

/// A macro that produces both a value and a string containing the
/// source code that generated the value. For example,
///
///     #stringify(x + y)
///
/// produces a tuple `(x + y, "x + y")`.
@freestanding(expression)
public macro stringify<T>(_ value: T) -> (T, String) = #externalMacro(module: "MacroDemoMacros", type: "StringifyMacro")

/// OptionSet macro that descripted in swift macro documentation:
/// https://docs.swift.org/swift-book/documentation/the-swift-programming-language/macros/#Attached-Macros
@attached(member, names: prefixed(prefix_), named(RawValue), named(rawValue), named(init), arbitrary)
@attached(extension, conformances: OptionSet)
public macro OptionSet<RawType>() = #externalMacro(module: "MacroDemoMacros", type: "OptionSetMacro")

/// A macro that takes a string that’s four characters long and returns an unsigned 32-bit integer
/// that corresponds to the ASCII values in the string joined together.
///
///     #fourCharacterCode("ABCD")
///
/// produces `1094861636 as UInt32`
@freestanding(expression)
public macro fourCharacterCode(_: String) -> UInt32 = #externalMacro(module: "MacroDemoMacros", type: "FourCharacterCodeMacro")


@attached(peer, names: suffixed(_peer))
public macro PeerValueWithSuffixName() = #externalMacro(module: "MacroDemoMacros", type: "PeerValueWithSuffixNameMacro")

@attached(peer, names: overloaded)
public macro AddAsync() = #externalMacro(module: "MacroDemoMacros", type: "AddAsyncMacro")

@attached(memberAttribute)
public macro memberDeprecated() = #externalMacro(module: "MacroDemoMacros", type: "MemberDeprecatedMacro")
