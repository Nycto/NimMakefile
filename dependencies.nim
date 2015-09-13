##
## Lists the dependencies of a nim file
##

import strutils, os, options, sequtils, sets

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

iterator directDependencies( path: string ): string =
    ## Yields the direct dependencies for a file
    var seen = initSet[string]()
    for dependency in imports(path):
        let found = locate(dependency)
        if found.isSome and not seen.contains(found.get):
            seen.incl(found.get)
            yield found.get

iterator dependencies( path: string ): string =
    ## Yields recursive dependencies for a file
    var next = toSeq(directDependencies(path))
    var seen = toSet(next)
    while next.len > 0:
        let popped = next.pop
        for depends in directDependencies(popped):
            if not seen.contains(depends):
                seen.incl(depends)
                next.add(depends)
        yield popped

for file in commandLineParams():
    for dependency in dependencies(file):
        stdout.write(" ", dependency)
    stdout.write("\n")

