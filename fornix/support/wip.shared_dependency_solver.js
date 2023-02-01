const store = {
    thing9: {
        name: "thing9",
        version: [1,2,3],
        dependencies: {
            thing3v1: [1,2,3],
            thing3v2: [1,2,3],
            thing4: [1,2,3],
            thing5: [1,2,3],
        }
    },
    thing10: {
        name: "thing10",
        version: [3],
        dependencies: {
            thing5: [2,3,1],
            thing6: [2,3,1],
            thing7: [2,3,1],
        }
    },
}
const dependencies = [ store.thing9, store.thing10 ]


// start building a tree
// try to find peer-dependencies

const needs = {}
const isNeededBy = {}
const isDirectDependency = {}
function explore(...directDependencies) {
    const versionChoices = {}
    let frontier = []
    let seen = new Set()
    for (const each of directDependencies) {
        isDirectDependency[each.name] = true
        needs[each.name] = each.dependencies
        seen.add(each.name)
        for (const [key, value] of Object.entries(each.dependencies)) {
            frontier.push(key)
            isNeededBy[key] = each.name
        }
    }
    // explore the whole tree
    while (frontier.length) {
        let dependencyName = frontier.shift()
        if (seen.has(dependencyName)) {
            continue
        }
        seen.add(dependencyName)
        needs[dependencyName] = store[dependencyName].dependencies
        const dependencyNames = Object.keys(store[dependencyName].dependencies)
        for (let eachName of dependencyNames) {
            isNeededBy[eachName] = 
        }
        // get frontier
        frontier = frontier.concat(dependencyNames)
    }
}

