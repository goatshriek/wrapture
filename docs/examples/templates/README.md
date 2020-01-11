# Template Example

As with any programming exercise, eventually you will encounter the need to do
something repetitive. There are a lot of opportunities for this situation to
arise in Wrapture specs: classes that wrap enumerations, identical error
handling code in a library, or functions with very similar specifications.
Wrapture provides a generalized capability to avoid repeating yourself called
templates, which allow you to define any spec structure and define variables
within them that can be replaced when they are invoked.

For this example, we'll consider a fictional library that is able to answer just
about any mathematical question you ask it. We want to extend this functionality
so that it feels a little more natural in the target language. Lots of object
oriented languages expose their math functions in a class with static methods,
so we decide to do the same here:

```yaml
classes:
  - name: "MagicMath"
    namespace: "magic_math"
    functions:
      - name: "IsPrime"
        static: true
        params:
          - name: "num"
            type: "int"
        wrapped-function:
          name: "is_prime"
          params:
            - value: "num"
      - name: "IsMagical"
        static: true
        params:
          - name: "num"
            type: "int"
        wrapped-function:
          name: "is_magical"
          params:
            - value: "num"
      - name: "IsPrime"
        static: true
        params:
          - name: "num"
            type: "int"
        wrapped-function:
          name: "is_prime"
          params:
            - value: "num"
      - name: "IsRandom"
        static: true
        params:
          - name: "num"
            type: "int"
        wrapped-function:
          name: "is_random"
          params:
            - value: "num"
```

But goodness, there sure is a lot of repetition in this specification. For each
of these function, their bodies are almost identical - the only differences are
their names, their parameter names, and the names of their wrapped functions. In
the words of many an infomercial, there has to be a better way!

This is a perfect use case for Wrapture templates. We can define the repeated
specification code as a template with parameters for the changing values, and
simply invoke this template once for each function, resulting in much more
concise specifications.

Templates can be inserted in any portion of a specification, for any use. They
are defined in a separate portion of the specification from the classes, aptly
named `templates`. Let's look at the template specification for our extremely
scientific library:

```yaml
templates:
  - name: "magical-static-function"
    value:
      static: true
      params:
        - name: "num"
          type: "int"
      wrapped-function:
        name:
          is-variable: true
          name: "wrapped-name"
        params:
          - value: "num"
```

This template closely matches our function specifications above, with a few
obvious differences. First, the template has a name associated with it that is
used when we need to use it later. Second, the name of the wrapped function is
no longer a string value: it is an object with a member called `is-variable` set
to `true`. This object signifies that this is a parameterized portion of the
template that we can replace as needed when we use this template.

Now that we have this template defined, let's see how we would use it to remove
the redundancy from our previous declarations:

```yaml
functions:
  - name: "IsMagical"
    use-template:
      name: "magical-static-function"
      params:
        - name: "wrapped-name"
          value: "is_magical"
  - name: "IsPrime"
    use-template:
      name: "magical-static-function"
      params:
        - name: "wrapped-name"
          value: "is_prime"
  - name: "IsRandom"
    use-template:
      name: "magical-static-function"
      params:
        - name: "wrapped-name"
          value: "is_random"
```

The declaration code has been shortened from nine lines to six, a reduction by a
third. More importantly, we have placed the common code into a single place (the
template) where it can be modified once and reflected at all use sites, a clean
example of the DRY principle. Verbosity and ease of maintenance will continue to
improve as we add even more to the function specs, such as error handling.

If you'd like to run this example in its entirety, you can do so with the
following invocations:

```sh
# generating the wrapper source code
wrapture magic_math.yml

# assuming that you're using sh and have g++
g++ -I . \
   magic_math.c MagicMath.cpp magic_math_usage.cpp \
   -o magic_math_usage_example

./magic_match_usage_example
# generates the following output:
```
