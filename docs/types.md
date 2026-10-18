# Types in Wrapture

Most programming languages classify the data and objects that it works with
using types in some way. Wrapture therefore must have a way to represent these
types in a way that is not tied to any specific language, but also can be used
from wrapped languages.


## Type Specs

Wrapture represents types independent from specific languages as instances of
the TypeSpec class.


## Language Types

For each of the languages that Wrapture supports, there are specific classes
that represent types within that language. For example, an instance of the CType
class describes a type within the C programming language.