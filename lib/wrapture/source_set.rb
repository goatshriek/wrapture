module Wrapture
  # Source sets contain source files.
  #
  # Classes can use this module by implementing +sources+ as an enumerable of
  # source files they contain.
  module SourceSet
    # Get the source file associated with a key.
    #
    # If +key+ is a Pathname, then a SourceFile with a matching path is
    # returned, if it is found.
    #
    # If +key+ is a String, then it is used to create a Pathname and then it is
    # used for a Pathname lookup.
    #
    # Otherwise, +key+ is used as a key for the sources with the find method.
    def [](key)
      case key
      when String
        sources.find { |src| src.path == Pathname.new(key) }
      when Pathname
        sources.find { |src| src.path == key }
      else
        sources.find { |src| src == key }
      end
    end

    # True if this build includes the provided source.
    #
    # If +src+ is a Pathname, then the sources list of the build is searched for
    # a SourceFile that has a matching Path.
    #
    # If +src+ is a String, then it is used to create a Pathname, and inclusion
    # is checked using the rules for paths.
    #
    # Otherwise, the source list is searched using the include? method of
    # the sources.
    def include?(src)
      case src
      when String
        sources.map(&:path).include?(Pathname.new(src))
      when Pathname
        sources.map(&:path).include?(src)
      else
        sources.include?(src)
      end
    end

    # Writes all source files to the file system, returning an Array of the
    # Pathnames created.
    #
    # +dir+ is the directory to write the files to. If not provided, files are
    # written to the current directory.
    def save(dir = '.')
      sources.map { |it| it.save(dir) }
    end
  end
end
