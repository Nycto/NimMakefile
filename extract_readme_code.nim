##
## Pulls code out of the readme and compiles it
##
import ropes, strutils, os

var blob = rope("")
var within = false
var count = 1
for line in lines("README.md"):
    if not within and line.startsWith("```nim"):
        within = true
    elif within and line.startsWith("```"):
        writeFile(getAppDir() & "/readme_" & $count & ".nim", $blob)
        inc(count)
        blob = rope("")
        within = false
    elif within:
        blob.add(line)
        blob.add("\n")

