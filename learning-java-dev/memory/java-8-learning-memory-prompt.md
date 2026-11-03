I'm learning modern Java and preparing for Java interviews. These are the topics I've covered so far:

FUNCTIONAL PROGRAMMING
- Functional interfaces and creating a custom one with @FunctionalInterface
- Lambda expressions
- Anonymous classes
- Lambda vs anonymous class
- Built-in functional interfaces: Predicate, BiPredicate, Consumer, Supplier, Function
- Imperative vs declarative programming
- Streams: stream(), filter(), collect(Collectors.toList())

OOP BASICS
- Interfaces as contracts
- Getters and setters
- Overriding equals()
- Generics: generic classes, records, interfaces and methods
- Field hiding vs method overriding
- Method overloading (compile time) vs overriding (runtime)
- Static type vs runtime type
- Inheritance pitfalls: the fragile base class problem, using a HashSet subclass

PATTERN MATCHING
- Pattern matching with instanceof
- Flow scoping of pattern variables
- Pattern matching with switch
- Guarded patterns with `when`
- Handling null with `case null`
- Exhaustive switch without default

SEALED TYPES
- Sealed classes and interfaces with permits
- Final subclasses of a sealed class
- Combining sealed types with switch

RECORDS
- Generated fields, accessors and canonical constructor
- Generated equals(), hashCode() and toString()
- Why records can't extend a class but can implement interfaces
- Generic records
- Serialization with records

TOOLS AND OTHER
- var for local variables
- Immutable lists with List.of()
- Maven project setup
- Lombok @With
