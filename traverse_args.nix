let
    # 
    # FIXME: errors cause this to never evaluate
    # 
        # will need to switch to a CLI/eval option for finding all non-error paths as BFS
        # then use geneated nix script to find when an attribute has already been evaluated
    
    # 
    # helpers
    # 
        necessaryPrefix = "Args_";
        necessaryPrefixLength = (builtins.stringLength 
            necessaryPrefix
        );
        getNameWithoutPrefix = name: (
            let
                endOfString = (builtins.stringLength
                    name
                );
                stringWithoutPrefix = (builtins.substring
                    necessaryPrefixLength
                    endOfString
                    name
                );
            in
                stringWithoutPrefix
        );
    # 
    # generic helpers
    # 
        print = message: value: value;
        #  (builtins.trace
        #     "\n${message}"            
        #     (builtins.trace 
        #         value
        #         value
        #     )
        # );
        doesContain = ({ list, element }:
            (builtins.any
                (each: each == element)
                list
            )
        );
        zipLists = ({list1, list2}:
            let
                indicies = (builtins.genList
                    (index: index)
                    (builtins.length
                        list1
                    )
                );
            in
                (builtins.map
                    (eachIndex: 
                        [
                            (builtins.elemAt
                                list1
                                eachIndex
                            )
                            (builtins.elemAt
                                list2
                                eachIndex
                            )
                        ]
                    )
                    indicies
                )
        );
        
        # example = (mapNamesAndValues {
        #     attrset = { a = 1; b = 2; };
        #     function = { name, value }: (
        #         {
        #             name = "${name}_${value}";
        #             value = value+1;
        #         }
        #     );
        # });
        mapNamesAndValues = ({ function, attrset }:
            (builtins.listToAttrs
                (builtins.attrValues
                    (builtins.mapAttrs
                        (key: value:
                            (function {
                                name = key;
                                value = value;
                            })
                        )
                        attrset
                    )
                )
            )
        );
        
        mapToNameValueList = attrset : (builtins.attrValues
            (mapNamesAndValues {
                attrset = attrset;
                function = ({ name, value }:
                    {
                        name=name;
                        value={
                            name = name;
                            value = value;
                        }; 
                    }
                );
            })
        );
    # 
    # main
    # 
    getArgs = (
        {
            obj,
            alreadySeen       ? [],
            argsForPath       ? {},
            packageForPath    ? {},
            attributePathList ? [],
        }:
            let
                # 
                # dont explore new values
                # 
                    newNames = print "newNames" (builtins.attrNames
                        obj
                    );
                    # { key1 = { name = key1; value = shouldBeRemoved}; key2 = { name = key2; value = shouldBeRemoved};  }
                    namesToSkipAttrset = print "namesToSkipAttrset" (builtins.mapAttrs
                        (key: value:
                            let
                                expressionWithPossibleError = print "expressionWithPossibleError" value;
                                result = (builtins.tryEval
                                    # (builtins.deepSeq
                                        (if builtins.isAttrs expressionWithPossibleError then
                                            expressionWithPossibleError
                                        else
                                            null)
                                        # expressionWithPossibleError
                                    # )
                                );
                                # if couldn't be evaluated, remove it
                                shouldBeRemoved = print "shouldBeRemoved" (!result.success || (doesContain {
                                    element = value;
                                    list = alreadySeen;
                                }));
                            in
                                {
                                    name = key;
                                    value = shouldBeRemoved;
                                }
                        )
                        obj
                    );
                    # [ { name = key1; value = shouldBeRemoved}, { name = key2; value = shouldBeRemoved }  ]
                    keyValueNamesToSkip = print "keyValueNamesToSkip" (builtins.attrValues
                        namesToSkipAttrset
                    );
                    # [ { name = key1; value = true }, { name = key2; value = true  }  ]
                    filteredKeyValueNamesToSkip = print "filteredKeyValueNamesToSkip" (builtins.filter
                        (each: each.value) # value = shouldBeRemoved
                        keyValueNamesToSkip
                    );
                    namesToSkip = print "namesToSkip" (builtins.map
                        (each: each.name)
                        filteredKeyValueNamesToSkip
                    );
                    remainingAttrsetToExplore = print "remainingAttrsetToExplore" (builtins.removeAttrs
                        obj
                        namesToSkip
                    );
                # 
                # figure out arg names
                # 
                    nameBeginsWithPrefix = (eachName: 
                        let
                            givenPrefix = (builtins.substring
                                0
                                necessaryPrefixLength
                                eachName
                            );
                        in
                            givenPrefix == necessaryPrefix
                    );
                    remainingNames = (builtins.attrNames
                        remainingAttrsetToExplore
                    );
                    argNames = (builtins.filter
                        nameBeginsWithPrefix
                        remainingNames
                    );
                    corrispondingNames = (builtins.map
                        getNameWithoutPrefix
                        argNames
                    );
                    argNamesAndCorrispondingNames = (zipLists {
                        list1 = argNames;
                        list2 = corrispondingNames;
                    });
                    argNameAttributesThatExist = (builtins.filter
                        (eachElement: 
                            let
                                argName = (builtins.elemAt
                                    eachElement
                                    0
                                );
                                corrispondingName = (builtins.elemAt
                                    eachElement
                                    1
                                );
                            in
                                (builtins.hasAttr
                                    remainingAttrsetToExplore
                                    corrispondingName
                                )
                        )
                        argNamesAndCorrispondingNames
                    );
                    argNamesFiltered = (builtins.map
                        (each:
                            let
                                argName = (builtins.elemAt
                                    each
                                    0
                                );
                            in
                                argName
                        )
                        argNameAttributesThatExist
                    );
                    nonArgNonExploredNames = (builtins.filter
                        (eachName:
                            !(doesContain {
                                element = eachName;
                                list = argNamesFiltered;
                            })
                        )
                        remainingNames
                    );
                    attrsetWithOnlyArgNames = print "attrsetWithOnlyArgNames" (builtins.removeAttrs
                        remainingAttrsetToExplore
                        nonArgNonExploredNames
                    );
                    attrsetWithoutArgNames = print "attrsetWithoutArgNames" (builtins.removeAttrs
                        remainingAttrsetToExplore
                        argNamesFiltered
                    );
                    getPathStringFor = name: (builtins.toJSON
                        (
                            attributePathList ++ [
                                (getNameWithoutPrefix name)
                            ]
                        )
                    );
                # 
                # outputs
                # 
                    # 
                    # alreadySeen
                    # 
                        newValues = (builtins.attrValues
                            remainingAttrsetToExplore
                        );
                        alreadySeen1 = alreadySeen ++ newValues;
                    # 
                    # handle argsForPath
                    # 
                        argsForPathAdditions = (mapNamesAndValues {
                            attrset = attrsetWithOnlyArgNames;
                            function = ({name, value}:
                                {
                                    name = (getPathStringFor
                                        name
                                    );
                                    value = value;
                                }
                            );
                        });
                        argsForPath1 = argsForPath // argsForPathAdditions;
                    # 
                    # handle packageForPath
                    # 
                        packageForPathAdditions = (mapNamesAndValues {
                            attrset = attrsetWithOnlyArgNames;
                            function = ({name, value}:
                                {
                                    name = (getPathStringFor
                                        name
                                    );
                                    value = (builtins.getAttr
                                        remainingAttrsetToExplore
                                        (getNameWithoutPrefix 
                                            name
                                        )
                                    );
                                }
                            );
                        });
                        packageForPath1 = print "packageForPath1" (packageForPath // packageForPathAdditions);
                # 
                # handle recursion
                # 
                    nameValueListOfUnexplored = print "nameValueListOfUnexplored" (mapToNameValueList
                        attrsetWithoutArgNames
                    );
                    recursiveOutputs = (builtins.foldl'
                        ({ alreadySeen, argsForPath, packageForPath }:
                            { name, value }:
                                if (builtins.isAttrs value) then
                                    (getArgs {
                                        obj = value;
                                        alreadySeen = alreadySeen;
                                        argsForPath = argsForPath;
                                        packageForPath = packageForPath;
                                        attributePathList = attributePathList ++ [ name ];
                                    })
                                else
                                    {
                                        alreadySeen = alreadySeen;
                                        argsForPath = argsForPath;
                                        packageForPath = packageForPath;
                                    }
                        )
                        {
                            alreadySeen = alreadySeen1;
                            argsForPath = argsForPath1;
                            packageForPath = packageForPath1;
                        }
                        nameValueListOfUnexplored
                    );
                    alreadySeen2    = recursiveOutputs.alreadySeen;
                    argsForPath2    = recursiveOutputs.argsForPath;
                    packageForPath2 = recursiveOutputs.packageForPath;
            in
                {
                    alreadySeen = alreadySeen2;
                    argsForPath = argsForPath2;
                    packageForPath = packageForPath2;
                }
    );
in
    getArgs


# n = import <nixpkgs> {}
# fromThem { obj = n.pythonPackages; }
# fromThem { obj = { b = { numpy = "howdy"; }; }; }
# fromThem { obj = { b = { numpy = n.python3Packages.numpy; }; }; }