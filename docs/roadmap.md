# The Future of Wrapture

See below for details about upcoming releases of Wrapture. If you have feedback
or want to make a suggestion, please submit an issue on the project's
[Github page](https://github.com/goatshriek/wrapture).

## What you'll find here and what you wont

Wrapture is under active development, and has a long list of new features and
improvements waiting to be implemented. Some of these are detailed in the issues
list on the project Github website, but this is certainly not a comprehensive
list of planned updates. Similarly, work that is in progress on new features is
tracked as a project on the Github repository, but future planned work does not
exist there either. Instead, the plans for future direction are kept here, in
the project roadmap.

Items are added to the roadmap once they have been identified, assessed for
level of effort, and prioritized based on community needs. Each item is assigned
to a semantic version, along with its change type, a description, and the
reasoning behind it. Where they exist, you will see references to issues on the
Github repository where you can go for more details on the origin of the
request. Once a version is in work, you will be able to find a corresponding
project on the Github repository with each roadmap item listed as a task. Once
all tasks are complete, the version will be released and the next started.

Once an item has been implemented it will be removed from the roadmap. If you
would like to see a history of changes on the existing codebase, check out the
ChangeLog (ChangeLog.md in the project root) to see what was included in each
version of the library. In most cases, roadmap items will be removed from this
document and placed there upon completion.

Note that the timelines associated with each change are vague at best. The
project team is not currently big enough to realistically make any promises, so
timing is often left out to prevent folks from feeling cheated if something
takes longer than expected.

## 0.4.0 (next minor release)
 * [ADD] **Variadic function generation**
   C++ functions may have a final parameter named `...` to allow an arbitrary
   number of arguments. This requires some special handling by Wrapture to allow
   the spec to define how the parameters should be handled, for example by
   passing them to a function expecting a `va_list` parameter that needs be
   started first. Parameter packs also handle this use case and are typically
   preferred, but these will be added in a separate feature (currently
   unallocated).
 * [ADD] **Wrapping of enumerations as enum classes in C++**
   C code may use enumerations to facilitate readable code using a known set of
   values. However, use of C-style enumerations in C++ does not provide any sort
   of type safety or scoping capability. A way to wrap native C enumerations
   into an `enum class` in C++ would allow generated code to follow C++
   standards practices and feel more native to users.
 * [ADD] **Support for function pointer types**
   Function pointers are common in C code, especially when it is trying to
   emulate object-oriented or functional programming techniques. Supporting
   these types in the library will allow target languages to wrap C libraries
   that make use of function pointers.

## 0.5.0
 * [ADD] **Python class generation**
   Python is a commonly used language in a variety of applications, and
   extension of C code into it is estimated to be a valuable feature.
   Furthermore, this feature must be added before version 1.0.0 so that any
   major changes to spec structure can be introduced while still in the initial
   development stage of [semantic versioning](https://semver.org/).

## 1.0.0 (next major release)
 * [DEPRECATE] **Use of `name` key instead of `value` in wrapped function
   parameter specs**
   The name key is equivalent to the value, and is not used for anything else
   currently. However, if it is needed for some other functionality in the
   future then this behavior will conflict, and is therefore being preemptively
   removed.

## 1.1.0
 * [ADD] **Generation of function that runs the wrapped code on everything in a
   collection**
   It is not uncommon that the same operation needs to be run on a list of
   items. It can be a convenience to have a function that accepts an array of
   items (instead of a single one) and simply runs the operation on each of the
   provided items. This change will add an option to a function spec that will
   trigger generation of a second function which takes a list parameter and runs
   the original function on each item in the list.

## 2.0.0
 * [REMOVE] **Use of `name` key instead of `value` in wrapped function parameter
   specs**
   Removing previously deprecated feature.

## Unallocated to a release
 * [ADD] **Creation of command-line interface namespace in library**
 * [ADD] **Support for JSON specifications**
 * [ADD] **Support for XML specifications**
 * [ADD] **Bidirectional language support**
   A major capability would be to write specifications that describe the source
   and target languages in generic terms, allowing wrappers to be generated to
   cross between any language (likely using C as the middle ground). This could
   be a major feature as it would open up libraries implemented in one language
   to all others supported by Wrapture with relative ease. This would be a major
   undertaking and will need to be done after multiple language support is added
   to Wrapture, currently scheduled for release 0.5.0 with the addition of
   Python wrapper generation.
 * [ADD] **Public repository of standard library specifications**
   It may be useful to have standard specifications readily available. These
   could range from common templates for things like error handling, to simply
   wrapping standard library calls for use in the target language.
 * [ADD] **Ruby class generation**
   Allowing Ruby class generation will enable this project to make use of other
   libraries that are currently available in C, such as the GNU compiler, to
   enhance functionality and testing of Wrapture itself. It will also benefit
   anyone wishing to generate Ruby bindings along with their other languages,
   and should be relatively simple once Python generation is completed
   (currently scheduled for release 0.5.0).
 * [ADD] **C# code generation**
 * [ADD] **TCL code generation**
 * [ADD] **Java code generation**
 * [ADD] **Powershell code generation**
 * [ADD] **Perl code generation**
 * [ADD] **C++ Parameter Pack Generation**
   While variadic function generation facilitates the creation of functions with
   a variable number of arguments, it is not the preferred approach in C++ code.
   Rather, parameter packs are used as they can offer some type safety. This
   addition will allow the generation of a parameter pack-based wrapper for C
   variadic function support.
 * [ADD] **Custom code insertion into generated code**
   In the event that some special behavior is desired, users may wish to insert
   their own code into the generated wrappers. This change will add several
   points for code insertion that allow users to customize the generated code to
   whatever extent they desire. However, this feature is currently not expected
   to take a high priority, as a cleaner alternative is to modify the source
   language code itself rather than injecting special behavior into the
   wrappers. If you would like to provide feedback on this decision, please
   submit an issue on the project's Github page.


## A Note about Github issues and projects

A fair question to ask is why the roadmap is not being managed within the issue
and project features of Github itself, since this is where the project is
currently hosted. Indeed, suggestions submitted by the community are tracked as
issues, and projects are already created for ongoing work. There are a few
reasons that a separate roadmap is maintained:
 * **Issues are used to exclusively track bugs and community requests.**
   This certainly isn't a hard and fast rule, and isn't followed by many other
   projects, but it is how Wrapture is managed. Keeping the issue count as a
   clear indicator of known problems and community requests lets the project
   maintainers (and anyone interested in looking at how well it is being
   maintained) immediately see how much outstanding work exists. Of course,
   the roadmap may have features requested by the community or enhancements made
   clear by bug reports, but it will also have a number of features and tweaks
   that have a lower priority.
 * **Project direction should come packaged with the product.**
   Again this isn't a commonly followed rule, but it is one that the project
   author follows. Anyone that obtains the source code of the project at a
   single point in time should be able to quickly see the current direction of
   the project. Maintaining the roadmap within the version control of the source
   itself facilitates this, the same way that licensing and copyright
   notifications are traditionally bundled with code. And if you don't care,
   you can always ignore them.
