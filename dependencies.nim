##
## Lists the dependencies of a nim file
##

import strutils, os, options, sequtils

iterator importLines( file: string ): string =
    ## Returns lines starting with 'import' or 'include'
    for line in lines(file):
        if line.startsWith("import") or line.startsWith("include"):
            yield line

iterator imports( file: string ): string =
    ## Returns the list of imports from a file
    for line in importLines(file):
        var first = true
        for tok in tokenize(line, {',', ' '}):
            if not tok.isSep:
                if first and (tok.token == "import" or tok.token == "include"):
                    first = false
                else:
                    yield tok.token

proc locate( dependency: string ): Option[string] =
    ## Finds the relative path to a dependency
    let relative = dependency & ".nim"
    if existsFile( getCurrentDir() & "/" & relative ):
        return some[string](relative)
    else:
        return none(string)

iterator dependencies( path: string ): string =
    ## Yields the dependencies for a file
    for dependency in imports(path):
        let found = locate(dependency)
        if found.isSome:
            yield found.get

for file in commandLineParams():
    for dependency in dependencies(file):
        stdout.write(" ", dependency)
    stdout.write("\n")

