(rec {
  _-_06294632224836068_-_ = {
    "/Users/jeffhykin/repos/nixpkgs/lib/fixed-points.nix" = (# "/Users/jeffhykin/repos/nixpkgs/lib/fixed-points.nix"
      { lib, ... }:
      rec {
        # Compute the fixed point of the given function `f`, which is usually an
        # attribute set that expects its final, non-recursive representation as an
        # argument:
        #
        #     f = self: { foo = "foo"; bar = "bar"; foobar = self.foo + self.bar; }
        #
        # Nix evaluates this recursion until all references to `self` have been
        # resolved. At that point, the final result is returned and `f x = x` holds:
        #
        #     nix-repl> fix f
        #     { bar = "bar"; foo = "foo"; foobar = "foobar"; }
        #
        #  Type: fix :: (a -> a) -> a
        #
        # See https://en.wikipedia.org/wiki/Fixed-point_combinator for further
        # details.
        fix = f: let x = f x; in x;
      
        # A variant of `fix` that records the original recursive attribute set in the
        # result. This is useful in combination with the `extends` function to
        # implement deep overriding. See pkgs/development/haskell-modules/default.nix
        # for a concrete example.
        fix' = f: let x = f x // { __unfix__ = f; }; in x;
      
        # Return the fixpoint that `f` converges to when called recursively, starting
        # with the input `x`.
        #
        #     nix-repl> converge (x: x / 2) 16
        #     0
        converge = f: x:
          let
            x' = f x;
          in
            if x' == x
            then x
            else converge f x';
      
        # Modify the contents of an explicitly recursive attribute set in a way that
        # honors `self`-references. This is accomplished with a function
        #
        #     g = self: super: { foo = super.foo + " + "; }
        #
        # that has access to the unmodified input (`super`) as well as the final
        # non-recursive representation of the attribute set (`self`). `extends`
        # differs from the native `//` operator insofar as that it's applied *before*
        # references to `self` are resolved:
        #
        #     nix-repl> fix (extends g f)
        #     { bar = "bar"; foo = "foo + "; foobar = "foo + bar"; }
        #
        # The name of the function is inspired by object-oriented inheritance, i.e.
        # think of it as an infix operator `g extends f` that mimics the syntax from
        # Java. It may seem counter-intuitive to have the "base class" as the second
        # argument, but it's nice this way if several uses of `extends` are cascaded.
        #
        # To get a better understanding how `extends` turns a function with a fix
        # point (the package set we start with) into a new function with a different fix
        # point (the desired packages set) lets just see, how `extends g f`
        # unfolds with `g` and `f` defined above:
        #
        # extends g f = self: let super = f self; in super // g self super;
        #             = self: let super = { foo = "foo"; bar = "bar"; foobar = self.foo + self.bar; }; in super // g self super
        #             = self: { foo = "foo"; bar = "bar"; foobar = self.foo + self.bar; } // g self { foo = "foo"; bar = "bar"; foobar = self.foo + self.bar; }
        #             = self: { foo = "foo"; bar = "bar"; foobar = self.foo + self.bar; } // { foo = "foo" + " + "; }
        #             = self: { foo = "foo + "; bar = "bar"; foobar = self.foo + self.bar; }
        #
        extends = f: rattrs: self: let super = rattrs self; in super // f self super;
      
        # Compose two extending functions of the type expected by 'extends'
        # into one where changes made in the first are available in the
        # 'super' of the second
        composeExtensions =
          f: g: final: prev:
            let fApplied = f final prev;
                prev' = prev // fApplied;
            in fApplied // g final prev';
      
        # Compose several extending functions of the type expected by 'extends' into
        # one where changes made in preceding functions are made available to
        # subsequent ones.
        #
        # composeManyExtensions : [packageSet -> packageSet -> packageSet] -> packageSet -> packageSet -> packageSet
        #                          ^final        ^prev         ^overrides     ^final        ^prev         ^overrides
        composeManyExtensions =
          lib.foldr (x: y: composeExtensions x y) (final: prev: {});
      
        # Create an overridable, recursive attribute set. For example:
        #
        #     nix-repl> obj = makeExtensible (self: { })
        #
        #     nix-repl> obj
        #     { __unfix__ = «lambda»; extend = «lambda»; }
        #
        #     nix-repl> obj = obj.extend (self: super: { foo = "foo"; })
        #
        #     nix-repl> obj
        #     { __unfix__ = «lambda»; extend = «lambda»; foo = "foo"; }
        #
        #     nix-repl> obj = obj.extend (self: super: { foo = super.foo + " + "; bar = "bar"; foobar = self.foo + self.bar; })
        #
        #     nix-repl> obj
        #     { __unfix__ = «lambda»; bar = "bar"; extend = «lambda»; foo = "foo + "; foobar = "foo + bar"; }
        makeExtensible = makeExtensibleWithCustomName "extend";
      
        # Same as `makeExtensible` but the name of the extending attribute is
        # customized.
        makeExtensibleWithCustomName = extenderName: rattrs:
          fix' (self: (rattrs self) // {
            ${extenderName} = f: makeExtensibleWithCustomName extenderName (extends f rattrs);
          });
      }
    );
    "/Users/jeffhykin/repos/nixpkgs/lib/lists.nix" = (# "/Users/jeffhykin/repos/nixpkgs/lib/lists.nix"
      # General list operations.
      
      { lib }:
      let
        inherit (lib.strings) toInt;
        inherit (lib.trivial) compare min;
        inherit (lib.attrsets) mapAttrs;
      in
      rec {
      
        inherit (builtins) head tail length isList elemAt concatLists filter elem genList map;
      
        /*  Create a list consisting of a single element.  `singleton x` is
            sometimes more convenient with respect to indentation than `[x]`
            when x spans multiple lines.
      
            Type: singleton :: a -> [a]
      
            Example:
              singleton "foo"
              => [ "foo" ]
        */
        singleton = x: [x];
      
        /*  Apply the function to each element in the list. Same as `map`, but arguments
            flipped.
      
            Type: forEach :: [a] -> (a -> b) -> [b]
      
            Example:
              forEach [ 1 2 ] (x:
                toString x
              )
              => [ "1" "2" ]
        */
        forEach = xs: f: map f xs;
      
        /* “right fold” a binary function `op` between successive elements of
           `list` with `nul` as the starting value, i.e.,
           `foldr op nul [x_1 x_2 ... x_n] == op x_1 (op x_2 ... (op x_n nul))`.
      
           Type: foldr :: (a -> b -> b) -> b -> [a] -> b
      
           Example:
             concat = foldr (a: b: a + b) "z"
             concat [ "a" "b" "c" ]
             => "abcz"
             # different types
             strange = foldr (int: str: toString (int + 1) + str) "a"
             strange [ 1 2 3 4 ]
             => "2345a"
        */
        foldr = op: nul: list:
          let
            len = length list;
            fold' = n:
              if n == len
              then nul
              else op (elemAt list n) (fold' (n + 1));
          in fold' 0;
      
        /* `fold` is an alias of `foldr` for historic reasons */
        # FIXME(Profpatsch): deprecate?
        fold = foldr;
      
      
        /* “left fold”, like `foldr`, but from the left:
           `foldl op nul [x_1 x_2 ... x_n] == op (... (op (op nul x_1) x_2) ... x_n)`.
      
           Type: foldl :: (b -> a -> b) -> b -> [a] -> b
      
           Example:
             lconcat = foldl (a: b: a + b) "z"
             lconcat [ "a" "b" "c" ]
             => "zabc"
             # different types
             lstrange = foldl (str: int: str + toString (int + 1)) "a"
             lstrange [ 1 2 3 4 ]
             => "a2345"
        */
        foldl = op: nul: list:
          let
            foldl' = n:
              if n == -1
              then nul
              else op (foldl' (n - 1)) (elemAt list n);
          in foldl' (length list - 1);
      
        /* Strict version of `foldl`.
      
           The difference is that evaluation is forced upon access. Usually used
           with small whole results (in contrast with lazily-generated list or large
           lists where only a part is consumed.)
      
           Type: foldl' :: (b -> a -> b) -> b -> [a] -> b
        */
        foldl' = builtins.foldl' or foldl;
      
        /* Map with index starting from 0
      
           Type: imap0 :: (int -> a -> b) -> [a] -> [b]
      
           Example:
             imap0 (i: v: "${v}-${toString i}") ["a" "b"]
             => [ "a-0" "b-1" ]
        */
        imap0 = f: list: genList (n: f n (elemAt list n)) (length list);
      
        /* Map with index starting from 1
      
           Type: imap1 :: (int -> a -> b) -> [a] -> [b]
      
           Example:
             imap1 (i: v: "${v}-${toString i}") ["a" "b"]
             => [ "a-1" "b-2" ]
        */
        imap1 = f: list: genList (n: f (n + 1) (elemAt list n)) (length list);
      
        /* Map and concatenate the result.
      
           Type: concatMap :: (a -> [b]) -> [a] -> [b]
      
           Example:
             concatMap (x: [x] ++ ["z"]) ["a" "b"]
             => [ "a" "z" "b" "z" ]
        */
        concatMap = builtins.concatMap or (f: list: concatLists (map f list));
      
        /* Flatten the argument into a single list; that is, nested lists are
           spliced into the top-level lists.
      
           Example:
             flatten [1 [2 [3] 4] 5]
             => [1 2 3 4 5]
             flatten 1
             => [1]
        */
        flatten = x:
          if isList x
          then concatMap (y: flatten y) x
          else [x];
      
        /* Remove elements equal to 'e' from a list.  Useful for buildInputs.
      
           Type: remove :: a -> [a] -> [a]
      
           Example:
             remove 3 [ 1 3 4 3 ]
             => [ 1 4 ]
        */
        remove =
          # Element to remove from the list
          e: filter (x: x != e);
      
        /* Find the sole element in the list matching the specified
           predicate, returns `default` if no such element exists, or
           `multiple` if there are multiple matching elements.
      
           Type: findSingle :: (a -> bool) -> a -> a -> [a] -> a
      
           Example:
             findSingle (x: x == 3) "none" "multiple" [ 1 3 3 ]
             => "multiple"
             findSingle (x: x == 3) "none" "multiple" [ 1 3 ]
             => 3
             findSingle (x: x == 3) "none" "multiple" [ 1 9 ]
             => "none"
        */
        findSingle =
          # Predicate
          pred:
          # Default value to return if element was not found.
          default:
          # Default value to return if more than one element was found
          multiple:
          # Input list
          list:
          let found = filter pred list; len = length found;
          in if len == 0 then default
            else if len != 1 then multiple
            else head found;
      
        /* Find the first element in the list matching the specified
           predicate or return `default` if no such element exists.
      
           Type: findFirst :: (a -> bool) -> a -> [a] -> a
      
           Example:
             findFirst (x: x > 3) 7 [ 1 6 4 ]
             => 6
             findFirst (x: x > 9) 7 [ 1 6 4 ]
             => 7
        */
        findFirst =
          # Predicate
          pred:
          # Default value to return
          default:
          # Input list
          list:
          let found = filter pred list;
          in if found == [] then default else head found;
      
        /* Return true if function `pred` returns true for at least one
           element of `list`.
      
           Type: any :: (a -> bool) -> [a] -> bool
      
           Example:
             any isString [ 1 "a" { } ]
             => true
             any isString [ 1 { } ]
             => false
        */
        any = builtins.any or (pred: foldr (x: y: if pred x then true else y) false);
      
        /* Return true if function `pred` returns true for all elements of
           `list`.
      
           Type: all :: (a -> bool) -> [a] -> bool
      
           Example:
             all (x: x < 3) [ 1 2 ]
             => true
             all (x: x < 3) [ 1 2 3 ]
             => false
        */
        all = builtins.all or (pred: foldr (x: y: if pred x then y else false) true);
      
        /* Count how many elements of `list` match the supplied predicate
           function.
      
           Type: count :: (a -> bool) -> [a] -> int
      
           Example:
             count (x: x == 3) [ 3 2 3 4 6 ]
             => 2
        */
        count =
          # Predicate
          pred: foldl' (c: x: if pred x then c + 1 else c) 0;
      
        /* Return a singleton list or an empty list, depending on a boolean
           value.  Useful when building lists with optional elements
           (e.g. `++ optional (system == "i686-linux") firefox`).
      
           Type: optional :: bool -> a -> [a]
      
           Example:
             optional true "foo"
             => [ "foo" ]
             optional false "foo"
             => [ ]
        */
        optional = cond: elem: if cond then [elem] else [];
      
        /* Return a list or an empty list, depending on a boolean value.
      
           Type: optionals :: bool -> [a] -> [a]
      
           Example:
             optionals true [ 2 3 ]
             => [ 2 3 ]
             optionals false [ 2 3 ]
             => [ ]
        */
        optionals =
          # Condition
          cond:
          # List to return if condition is true
          elems: if cond then elems else [];
      
      
        /* If argument is a list, return it; else, wrap it in a singleton
           list.  If you're using this, you should almost certainly
           reconsider if there isn't a more "well-typed" approach.
      
           Example:
             toList [ 1 2 ]
             => [ 1 2 ]
             toList "hi"
             => [ "hi "]
        */
        toList = x: if isList x then x else [x];
      
        /* Return a list of integers from `first` up to and including `last`.
      
           Type: range :: int -> int -> [int]
      
           Example:
             range 2 4
             => [ 2 3 4 ]
             range 3 2
             => [ ]
        */
        range =
          # First integer in the range
          first:
          # Last integer in the range
          last:
          if first > last then
            []
          else
            genList (n: first + n) (last - first + 1);
      
        /* Splits the elements of a list in two lists, `right` and
           `wrong`, depending on the evaluation of a predicate.
      
           Type: (a -> bool) -> [a] -> { right :: [a], wrong :: [a] }
      
           Example:
             partition (x: x > 2) [ 5 1 2 3 4 ]
             => { right = [ 5 3 4 ]; wrong = [ 1 2 ]; }
        */
        partition = builtins.partition or (pred:
          foldr (h: t:
            if pred h
            then { right = [h] ++ t.right; wrong = t.wrong; }
            else { right = t.right; wrong = [h] ++ t.wrong; }
          ) { right = []; wrong = []; });
      
        /* Splits the elements of a list into many lists, using the return value of a predicate.
           Predicate should return a string which becomes keys of attrset `groupBy` returns.
      
           `groupBy'` allows to customise the combining function and initial value
      
           Example:
             groupBy (x: boolToString (x > 2)) [ 5 1 2 3 4 ]
             => { true = [ 5 3 4 ]; false = [ 1 2 ]; }
             groupBy (x: x.name) [ {name = "icewm"; script = "icewm &";}
                                   {name = "xfce";  script = "xfce4-session &";}
                                   {name = "icewm"; script = "icewmbg &";}
                                   {name = "mate";  script = "gnome-session &";}
                                 ]
             => { icewm = [ { name = "icewm"; script = "icewm &"; }
                            { name = "icewm"; script = "icewmbg &"; } ];
                  mate  = [ { name = "mate";  script = "gnome-session &"; } ];
                  xfce  = [ { name = "xfce";  script = "xfce4-session &"; } ];
                }
      
             groupBy' builtins.add 0 (x: boolToString (x > 2)) [ 5 1 2 3 4 ]
             => { true = 12; false = 3; }
        */
        groupBy' = op: nul: pred: lst: mapAttrs (name: foldl op nul) (groupBy pred lst);
      
        groupBy = builtins.groupBy or (
          pred: foldl' (r: e:
             let
               key = pred e;
             in
               r // { ${key} = (r.${key} or []) ++ [e]; }
          ) {});
      
        /* Merges two lists of the same size together. If the sizes aren't the same
           the merging stops at the shortest. How both lists are merged is defined
           by the first argument.
      
           Type: zipListsWith :: (a -> b -> c) -> [a] -> [b] -> [c]
      
           Example:
             zipListsWith (a: b: a + b) ["h" "l"] ["e" "o"]
             => ["he" "lo"]
        */
        zipListsWith =
          # Function to zip elements of both lists
          f:
          # First list
          fst:
          # Second list
          snd:
          genList
            (n: f (elemAt fst n) (elemAt snd n)) (min (length fst) (length snd));
      
        /* Merges two lists of the same size together. If the sizes aren't the same
           the merging stops at the shortest.
      
           Type: zipLists :: [a] -> [b] -> [{ fst :: a, snd :: b}]
      
           Example:
             zipLists [ 1 2 ] [ "a" "b" ]
             => [ { fst = 1; snd = "a"; } { fst = 2; snd = "b"; } ]
        */
        zipLists = zipListsWith (fst: snd: { inherit fst snd; });
      
        /* Reverse the order of the elements of a list.
      
           Type: reverseList :: [a] -> [a]
      
           Example:
      
             reverseList [ "b" "o" "j" ]
             => [ "j" "o" "b" ]
        */
        reverseList = xs:
          let l = length xs; in genList (n: elemAt xs (l - n - 1)) l;
      
        /* Depth-First Search (DFS) for lists `list != []`.
      
           `before a b == true` means that `b` depends on `a` (there's an
           edge from `b` to `a`).
      
           Example:
               listDfs true hasPrefix [ "/home/user" "other" "/" "/home" ]
                 == { minimal = "/";                  # minimal element
                      visited = [ "/home/user" ];     # seen elements (in reverse order)
                      rest    = [ "/home" "other" ];  # everything else
                    }
      
               listDfs true hasPrefix [ "/home/user" "other" "/" "/home" "/" ]
                 == { cycle   = "/";                  # cycle encountered at this element
                      loops   = [ "/" ];              # and continues to these elements
                      visited = [ "/" "/home/user" ]; # elements leading to the cycle (in reverse order)
                      rest    = [ "/home" "other" ];  # everything else
      
         */
        listDfs = stopOnCycles: before: list:
          let
            dfs' = us: visited: rest:
              let
                c = filter (x: before x us) visited;
                b = partition (x: before x us) rest;
              in if stopOnCycles && (length c > 0)
                 then { cycle = us; loops = c; inherit visited rest; }
                 else if length b.right == 0
                      then # nothing is before us
                           { minimal = us; inherit visited rest; }
                      else # grab the first one before us and continue
                           dfs' (head b.right)
                                ([ us ] ++ visited)
                                (tail b.right ++ b.wrong);
          in dfs' (head list) [] (tail list);
      
        /* Sort a list based on a partial ordering using DFS. This
           implementation is O(N^2), if your ordering is linear, use `sort`
           instead.
      
           `before a b == true` means that `b` should be after `a`
           in the result.
      
           Example:
      
               toposort hasPrefix [ "/home/user" "other" "/" "/home" ]
                 == { result = [ "/" "/home" "/home/user" "other" ]; }
      
               toposort hasPrefix [ "/home/user" "other" "/" "/home" "/" ]
                 == { cycle = [ "/home/user" "/" "/" ]; # path leading to a cycle
                      loops = [ "/" ]; }                # loops back to these elements
      
               toposort hasPrefix [ "other" "/home/user" "/home" "/" ]
                 == { result = [ "other" "/" "/home" "/home/user" ]; }
      
               toposort (a: b: a < b) [ 3 2 1 ] == { result = [ 1 2 3 ]; }
      
         */
        toposort = before: list:
          let
            dfsthis = listDfs true before list;
            toporest = toposort before (dfsthis.visited ++ dfsthis.rest);
          in
            if length list < 2
            then # finish
                 { result =  list; }
            else if dfsthis ? cycle
                 then # there's a cycle, starting from the current vertex, return it
                      { cycle = reverseList ([ dfsthis.cycle ] ++ dfsthis.visited);
                        inherit (dfsthis) loops; }
                 else if toporest ? cycle
                      then # there's a cycle somewhere else in the graph, return it
                           toporest
                      # Slow, but short. Can be made a bit faster with an explicit stack.
                      else # there are no cycles
                           { result = [ dfsthis.minimal ] ++ toporest.result; };
      
        /* Sort a list based on a comparator function which compares two
           elements and returns true if the first argument is strictly below
           the second argument.  The returned list is sorted in an increasing
           order.  The implementation does a quick-sort.
      
           Example:
             sort (a: b: a < b) [ 5 3 7 ]
             => [ 3 5 7 ]
        */
        sort = builtins.sort or (
          strictLess: list:
          let
            len = length list;
            first = head list;
            pivot' = n: acc@{ left, right }: let el = elemAt list n; next = pivot' (n + 1); in
              if n == len
                then acc
              else if strictLess first el
                then next { inherit left; right = [ el ] ++ right; }
              else
                next { left = [ el ] ++ left; inherit right; };
            pivot = pivot' 1 { left = []; right = []; };
          in
            if len < 2 then list
            else (sort strictLess pivot.left) ++  [ first ] ++  (sort strictLess pivot.right));
      
        /* Compare two lists element-by-element.
      
           Example:
             compareLists compare [] []
             => 0
             compareLists compare [] [ "a" ]
             => -1
             compareLists compare [ "a" ] []
             => 1
             compareLists compare [ "a" "b" ] [ "a" "c" ]
             => -1
        */
        compareLists = cmp: a: b:
          if a == []
          then if b == []
               then 0
               else -1
          else if b == []
               then 1
               else let rel = cmp (head a) (head b); in
                    if rel == 0
                    then compareLists cmp (tail a) (tail b)
                    else rel;
      
        /* Sort list using "Natural sorting".
           Numeric portions of strings are sorted in numeric order.
      
           Example:
             naturalSort ["disk11" "disk8" "disk100" "disk9"]
             => ["disk8" "disk9" "disk11" "disk100"]
             naturalSort ["10.46.133.149" "10.5.16.62" "10.54.16.25"]
             => ["10.5.16.62" "10.46.133.149" "10.54.16.25"]
             naturalSort ["v0.2" "v0.15" "v0.0.9"]
             => [ "v0.0.9" "v0.2" "v0.15" ]
        */
        naturalSort = lst:
          let
            vectorise = s: map (x: if isList x then toInt (head x) else x) (builtins.split "(0|[1-9][0-9]*)" s);
            prepared = map (x: [ (vectorise x) x ]) lst; # remember vectorised version for O(n) regex splits
            less = a: b: (compareLists compare (head a) (head b)) < 0;
          in
            map (x: elemAt x 1) (sort less prepared);
      
        /* Return the first (at most) N elements of a list.
      
           Type: take :: int -> [a] -> [a]
      
           Example:
             take 2 [ "a" "b" "c" "d" ]
             => [ "a" "b" ]
             take 2 [ ]
             => [ ]
        */
        take =
          # Number of elements to take
          count: sublist 0 count;
      
        /* Remove the first (at most) N elements of a list.
      
           Type: drop :: int -> [a] -> [a]
      
           Example:
             drop 2 [ "a" "b" "c" "d" ]
             => [ "c" "d" ]
             drop 2 [ ]
             => [ ]
        */
        drop =
          # Number of elements to drop
          count:
          # Input list
          list: sublist count (length list) list;
      
        /* Return a list consisting of at most `count` elements of `list`,
           starting at index `start`.
      
           Type: sublist :: int -> int -> [a] -> [a]
      
           Example:
             sublist 1 3 [ "a" "b" "c" "d" "e" ]
             => [ "b" "c" "d" ]
             sublist 1 3 [ ]
             => [ ]
        */
        sublist =
          # Index at which to start the sublist
          start:
          # Number of elements to take
          count:
          # Input list
          list:
          let len = length list; in
          genList
            (n: elemAt list (n + start))
            (if start >= len then 0
             else if start + count > len then len - start
             else count);
      
        /* Return the last element of a list.
      
           This function throws an error if the list is empty.
      
           Type: last :: [a] -> a
      
           Example:
             last [ 1 2 3 ]
             => 3
        */
        last = list:
          assert lib.assertMsg (list != []) "lists.last: list must not be empty!";
          elemAt list (length list - 1);
      
        /* Return all elements but the last.
      
           This function throws an error if the list is empty.
      
           Type: init :: [a] -> [a]
      
           Example:
             init [ 1 2 3 ]
             => [ 1 2 ]
        */
        init = list:
          assert lib.assertMsg (list != []) "lists.init: list must not be empty!";
          take (length list - 1) list;
      
      
        /* Return the image of the cross product of some lists by a function.
      
          Example:
            crossLists (x:y: "${toString x}${toString y}") [[1 2] [3 4]]
            => [ "13" "14" "23" "24" ]
        */
        crossLists = builtins.trace
          "lib.crossLists is deprecated, use lib.cartesianProductOfSets instead"
          (f: foldl (fs: args: concatMap (f: map f args) fs) [f]);
      
      
        /* Remove duplicate elements from the list. O(n^2) complexity.
      
           Type: unique :: [a] -> [a]
      
           Example:
             unique [ 3 2 3 4 ]
             => [ 3 2 4 ]
         */
        unique = foldl' (acc: e: if elem e acc then acc else acc ++ [ e ]) [];
      
        /* Intersects list 'e' and another list. O(nm) complexity.
      
           Example:
             intersectLists [ 1 2 3 ] [ 6 3 2 ]
             => [ 3 2 ]
        */
        intersectLists = e: filter (x: elem x e);
      
        /* Subtracts list 'e' from another list. O(nm) complexity.
      
           Example:
             subtractLists [ 3 2 ] [ 1 2 3 4 5 3 ]
             => [ 1 4 5 ]
        */
        subtractLists = e: filter (x: !(elem x e));
      
        /* Test if two lists have no common element.
           It should be slightly more efficient than (intersectLists a b == [])
        */
        mutuallyExclusive = a: b: length a == 0 || !(any (x: elem x a) b);
      
      }
    );
    "/Users/jeffhykin/repos/nixpkgs/lib/zip-int-bits.nix" = (# "/Users/jeffhykin/repos/nixpkgs/lib/zip-int-bits.nix"
      /* Helper function to implement a fallback for the bit operators
         `bitAnd`, `bitOr` and `bitXor` on older nix version.
         See ./trivial.nix
      */
      f: x: y:
        let
          # (intToBits 6) -> [ 0 1 1 ]
          intToBits = x:
            if x == 0 || x == -1 then
              []
            else
              let
                headbit  = if (x / 2) * 2 != x then 1 else 0;          # x & 1
                tailbits = if x < 0 then ((x + 1) / 2) - 1 else x / 2; # x >> 1
              in
                [headbit] ++ (intToBits tailbits);
      
          # (bitsToInt [ 0 1 1 ] 0) -> 6
          # (bitsToInt [ 0 1 0 ] 1) -> -6
          bitsToInt = l: signum:
            if l == [] then
              (if signum == 0 then 0 else -1)
            else
              (builtins.head l) + (2 * (bitsToInt (builtins.tail l) signum));
      
          xsignum = if x < 0 then 1 else 0;
          ysignum = if y < 0 then 1 else 0;
          zipListsWith' = fst: snd:
            if fst==[] && snd==[] then
              []
            else if fst==[] then
              [(f xsignum             (builtins.head snd))] ++ (zipListsWith' []                  (builtins.tail snd))
            else if snd==[] then
              [(f (builtins.head fst) ysignum            )] ++ (zipListsWith' (builtins.tail fst) []                 )
            else
              [(f (builtins.head fst) (builtins.head snd))] ++ (zipListsWith' (builtins.tail fst) (builtins.tail snd));
        in
          assert (builtins.isInt x) && (builtins.isInt y);
          bitsToInt (zipListsWith' (intToBits x) (intToBits y)) (f xsignum ysignum)
    );
    "/Users/jeffhykin/repos/nixpkgs/lib/attrsets.nix" = (# "/Users/jeffhykin/repos/nixpkgs/lib/attrsets.nix"
      { lib }:
      # Operations on attribute sets.
      
      let
        inherit (builtins) head tail length;
        inherit (lib.trivial) flip id mergeAttrs pipe;
        inherit (lib.strings) concatStringsSep concatMapStringsSep escapeNixIdentifier sanitizeDerivationName;
        inherit (lib.lists) foldr foldl' concatMap concatLists elemAt all partition groupBy take foldl;
      in
      
      rec {
        inherit (builtins) attrNames listToAttrs hasAttr isAttrs getAttr;
      
      
        /* Return an attribute from nested attribute sets.
      
           Example:
             x = { a = { b = 3; }; }
             # ["a" "b"] is equivalent to x.a.b
             # 6 is a default value to return if the path does not exist in attrset
             attrByPath ["a" "b"] 6 x
             => 3
             attrByPath ["z" "z"] 6 x
             => 6
      
           Type:
             attrByPath :: [String] -> Any -> AttrSet -> Any
      
        */
        attrByPath =
          # A list of strings representing the attribute path to return from `set`
          attrPath:
          # Default value if `attrPath` does not resolve to an existing value
          default:
          # The nested attribute set to select values from
          set:
          let attr = head attrPath;
          in
            if attrPath == [] then set
            else if set ? ${attr}
            then attrByPath (tail attrPath) default set.${attr}
            else default;
      
        /* Return if an attribute from nested attribute set exists.
      
           Example:
             x = { a = { b = 3; }; }
             hasAttrByPath ["a" "b"] x
             => true
             hasAttrByPath ["z" "z"] x
             => false
      
          Type:
            hasAttrByPath :: [String] -> AttrSet -> Bool
        */
        hasAttrByPath =
          # A list of strings representing the attribute path to check from `set`
          attrPath:
          # The nested attribute set to check
          e:
          let attr = head attrPath;
          in
            if attrPath == [] then true
            else if e ? ${attr}
            then hasAttrByPath (tail attrPath) e.${attr}
            else false;
      
      
        /* Create a new attribute set with `value` set at the nested attribute location specified in `attrPath`.
      
           Example:
             setAttrByPath ["a" "b"] 3
             => { a = { b = 3; }; }
      
           Type:
             setAttrByPath :: [String] -> Any -> AttrSet
        */
        setAttrByPath =
          # A list of strings representing the attribute path to set
          attrPath:
          # The value to set at the location described by `attrPath`
          value:
          let
            len = length attrPath;
            atDepth = n:
              if n == len
              then value
              else { ${elemAt attrPath n} = atDepth (n + 1); };
          in atDepth 0;
      
        /* Like `attrByPath`, but without a default value. If it doesn't find the
           path it will throw an error.
      
           Example:
             x = { a = { b = 3; }; }
             getAttrFromPath ["a" "b"] x
             => 3
             getAttrFromPath ["z" "z"] x
             => error: cannot find attribute `z.z'
      
           Type:
             getAttrFromPath :: [String] -> AttrSet -> Any
        */
        getAttrFromPath =
          # A list of strings representing the attribute path to get from `set`
          attrPath:
          # The nested attribute set to find the value in.
          set:
          let errorMsg = "cannot find attribute `" + concatStringsSep "." attrPath + "'";
          in attrByPath attrPath (abort errorMsg) set;
      
        /* Map each attribute in the given set and merge them into a new attribute set.
      
           Type:
             concatMapAttrs :: (String -> a -> AttrSet) -> AttrSet -> AttrSet
      
           Example:
             concatMapAttrs
               (name: value: {
                 ${name} = value;
                 ${name + value} = value;
               })
               { x = "a"; y = "b"; }
             => { x = "a"; xa = "a"; y = "b"; yb = "b"; }
        */
        concatMapAttrs = f: flip pipe [ (mapAttrs f) attrValues (foldl' mergeAttrs { }) ];
      
      
        /* Update or set specific paths of an attribute set.
      
           Takes a list of updates to apply and an attribute set to apply them to,
           and returns the attribute set with the updates applied. Updates are
           represented as `{ path = ...; update = ...; }` values, where `path` is a
           list of strings representing the attribute path that should be updated,
           and `update` is a function that takes the old value at that attribute path
           as an argument and returns the new
           value it should be.
      
           Properties:
      
           - Updates to deeper attribute paths are applied before updates to more
             shallow attribute paths
      
           - Multiple updates to the same attribute path are applied in the order
             they appear in the update list
      
           - If any but the last `path` element leads into a value that is not an
             attribute set, an error is thrown
      
           - If there is an update for an attribute path that doesn't exist,
             accessing the argument in the update function causes an error, but
             intermediate attribute sets are implicitly created as needed
      
           Example:
             updateManyAttrsByPath [
               {
                 path = [ "a" "b" ];
                 update = old: { d = old.c; };
               }
               {
                 path = [ "a" "b" "c" ];
                 update = old: old + 1;
               }
               {
                 path = [ "x" "y" ];
                 update = old: "xy";
               }
             ] { a.b.c = 0; }
             => { a = { b = { d = 1; }; }; x = { y = "xy"; }; }
      
          Type: updateManyAttrsByPath :: [{ path :: [String], update :: (Any -> Any) }] -> AttrSet -> AttrSet
        */
        updateManyAttrsByPath = let
          # When recursing into attributes, instead of updating the `path` of each
          # update using `tail`, which needs to allocate an entirely new list,
          # we just pass a prefix length to use and make sure to only look at the
          # path without the prefix length, so that we can reuse the original list
          # entries.
          go = prefixLength: hasValue: value: updates:
            let
              # Splits updates into ones on this level (split.right)
              # And ones on levels further down (split.wrong)
              split = partition (el: length el.path == prefixLength) updates;
      
              # Groups updates on further down levels into the attributes they modify
              nested = groupBy (el: elemAt el.path prefixLength) split.wrong;
      
              # Applies only nested modification to the input value
              withNestedMods =
                # Return the value directly if we don't have any nested modifications
                if split.wrong == [] then
                  if hasValue then value
                  else
                    # Throw an error if there is no value. This `head` call here is
                    # safe, but only in this branch since `go` could only be called
                    # with `hasValue == false` for nested updates, in which case
                    # it's also always called with at least one update
                    let updatePath = (head split.right).path; in
                    throw
                    ( "updateManyAttrsByPath: Path '${showAttrPath updatePath}' does "
                    + "not exist in the given value, but the first update to this "
                    + "path tries to access the existing value.")
                else
                  # If there are nested modifications, try to apply them to the value
                  if ! hasValue then
                    # But if we don't have a value, just use an empty attribute set
                    # as the value, but simplify the code a bit
                    mapAttrs (name: go (prefixLength + 1) false null) nested
                  else if isAttrs value then
                    # If we do have a value and it's an attribute set, override it
                    # with the nested modifications
                    value //
                    mapAttrs (name: go (prefixLength + 1) (value ? ${name}) value.${name}) nested
                  else
                    # However if it's not an attribute set, we can't apply the nested
                    # modifications, throw an error
                    let updatePath = (head split.wrong).path; in
                    throw
                    ( "updateManyAttrsByPath: Path '${showAttrPath updatePath}' needs to "
                    + "be updated, but path '${showAttrPath (take prefixLength updatePath)}' "
                    + "of the given value is not an attribute set, so we can't "
                    + "update an attribute inside of it.");
      
              # We get the final result by applying all the updates on this level
              # after having applied all the nested updates
              # We use foldl instead of foldl' so that in case of multiple updates,
              # intermediate values aren't evaluated if not needed
            in foldl (acc: el: el.update acc) withNestedMods split.right;
      
        in updates: value: go 0 true value updates;
      
        /* Return the specified attributes from a set.
      
           Example:
             attrVals ["a" "b" "c"] as
             => [as.a as.b as.c]
      
           Type:
             attrVals :: [String] -> AttrSet -> [Any]
        */
        attrVals =
          # The list of attributes to fetch from `set`. Each attribute name must exist on the attrbitue set
          nameList:
          # The set to get attribute values from
          set: map (x: set.${x}) nameList;
      
      
        /* Return the values of all attributes in the given set, sorted by
           attribute name.
      
           Example:
             attrValues {c = 3; a = 1; b = 2;}
             => [1 2 3]
      
           Type:
             attrValues :: AttrSet -> [Any]
        */
        attrValues = builtins.attrValues or (attrs: attrVals (attrNames attrs) attrs);
      
      
        /* Given a set of attribute names, return the set of the corresponding
           attributes from the given set.
      
           Example:
             getAttrs [ "a" "b" ] { a = 1; b = 2; c = 3; }
             => { a = 1; b = 2; }
      
           Type:
             getAttrs :: [String] -> AttrSet -> AttrSet
        */
        getAttrs =
          # A list of attribute names to get out of `set`
          names:
          # The set to get the named attributes from
          attrs: genAttrs names (name: attrs.${name});
      
        /* Collect each attribute named `attr` from a list of attribute
           sets.  Sets that don't contain the named attribute are ignored.
      
           Example:
             catAttrs "a" [{a = 1;} {b = 0;} {a = 2;}]
             => [1 2]
      
           Type:
             catAttrs :: String -> [AttrSet] -> [Any]
        */
        catAttrs = builtins.catAttrs or
          (attr: l: concatLists (map (s: if s ? ${attr} then [s.${attr}] else []) l));
      
      
        /* Filter an attribute set by removing all attributes for which the
           given predicate return false.
      
           Example:
             filterAttrs (n: v: n == "foo") { foo = 1; bar = 2; }
             => { foo = 1; }
      
           Type:
             filterAttrs :: (String -> Any -> Bool) -> AttrSet -> AttrSet
        */
        filterAttrs =
          # Predicate taking an attribute name and an attribute value, which returns `true` to include the attribute, or `false` to exclude the attribute.
          pred:
          # The attribute set to filter
          set:
          listToAttrs (concatMap (name: let v = set.${name}; in if pred name v then [(nameValuePair name v)] else []) (attrNames set));
      
      
        /* Filter an attribute set recursively by removing all attributes for
           which the given predicate return false.
      
           Example:
             filterAttrsRecursive (n: v: v != null) { foo = { bar = null; }; }
             => { foo = {}; }
      
           Type:
             filterAttrsRecursive :: (String -> Any -> Bool) -> AttrSet -> AttrSet
        */
        filterAttrsRecursive =
          # Predicate taking an attribute name and an attribute value, which returns `true` to include the attribute, or `false` to exclude the attribute.
          pred:
          # The attribute set to filter
          set:
          listToAttrs (
            concatMap (name:
              let v = set.${name}; in
              if pred name v then [
                (nameValuePair name (
                  if isAttrs v then filterAttrsRecursive pred v
                  else v
                ))
              ] else []
            ) (attrNames set)
          );
      
        /* Apply fold functions to values grouped by key.
      
           Example:
             foldAttrs (item: acc: [item] ++ acc) [] [{ a = 2; } { a = 3; }]
             => { a = [ 2 3 ]; }
      
           Type:
             foldAttrs :: (Any -> Any -> Any) -> Any -> [AttrSets] -> Any
      
        */
        foldAttrs =
          # A function, given a value and a collector combines the two.
          op:
          # The starting value.
          nul:
          # A list of attribute sets to fold together by key.
          list_of_attrs:
          foldr (n: a:
              foldr (name: o:
                o // { ${name} = op n.${name} (a.${name} or nul); }
              ) a (attrNames n)
          ) {} list_of_attrs;
      
      
        /* Recursively collect sets that verify a given predicate named `pred`
           from the set `attrs`.  The recursion is stopped when the predicate is
           verified.
      
           Example:
             collect isList { a = { b = ["b"]; }; c = [1]; }
             => [["b"] [1]]
      
             collect (x: x ? outPath)
                { a = { outPath = "a/"; }; b = { outPath = "b/"; }; }
             => [{ outPath = "a/"; } { outPath = "b/"; }]
      
           Type:
             collect :: (AttrSet -> Bool) -> AttrSet -> [x]
        */
        collect =
        # Given an attribute's value, determine if recursion should stop.
        pred:
        # The attribute set to recursively collect.
        attrs:
          if pred attrs then
            [ attrs ]
          else if isAttrs attrs then
            concatMap (collect pred) (attrValues attrs)
          else
            [];
      
        /* Return the cartesian product of attribute set value combinations.
      
          Example:
            cartesianProductOfSets { a = [ 1 2 ]; b = [ 10 20 ]; }
            => [
                 { a = 1; b = 10; }
                 { a = 1; b = 20; }
                 { a = 2; b = 10; }
                 { a = 2; b = 20; }
               ]
           Type:
             cartesianProductOfSets :: AttrSet -> [AttrSet]
        */
        cartesianProductOfSets =
          # Attribute set with attributes that are lists of values
          attrsOfLists:
          foldl' (listOfAttrs: attrName:
            concatMap (attrs:
              map (listValue: attrs // { ${attrName} = listValue; }) attrsOfLists.${attrName}
            ) listOfAttrs
          ) [{}] (attrNames attrsOfLists);
      
      
        /* Utility function that creates a `{name, value}` pair as expected by `builtins.listToAttrs`.
      
           Example:
             nameValuePair "some" 6
             => { name = "some"; value = 6; }
      
           Type:
             nameValuePair :: String -> Any -> { name :: String, value :: Any }
        */
        nameValuePair =
          # Attribute name
          name:
          # Attribute value
          value:
          { inherit name value; };
      
      
        /* Apply a function to each element in an attribute set, creating a new attribute set.
      
           Example:
             mapAttrs (name: value: name + "-" + value)
                { x = "foo"; y = "bar"; }
             => { x = "x-foo"; y = "y-bar"; }
      
           Type:
             mapAttrs :: (String -> Any -> Any) -> AttrSet -> AttrSet
        */
        mapAttrs = builtins.mapAttrs or
          (f: set:
            listToAttrs (map (attr: { name = attr; value = f attr set.${attr}; }) (attrNames set)));
      
      
        /* Like `mapAttrs`, but allows the name of each attribute to be
           changed in addition to the value.  The applied function should
           return both the new name and value as a `nameValuePair`.
      
           Example:
             mapAttrs' (name: value: nameValuePair ("foo_" + name) ("bar-" + value))
                { x = "a"; y = "b"; }
             => { foo_x = "bar-a"; foo_y = "bar-b"; }
      
           Type:
             mapAttrs' :: (String -> Any -> { name = String; value = Any }) -> AttrSet -> AttrSet
        */
        mapAttrs' =
          # A function, given an attribute's name and value, returns a new `nameValuePair`.
          f:
          # Attribute set to map over.
          set:
          listToAttrs (map (attr: f attr set.${attr}) (attrNames set));
      
      
        /* Call a function for each attribute in the given set and return
           the result in a list.
      
           Example:
             mapAttrsToList (name: value: name + value)
                { x = "a"; y = "b"; }
             => [ "xa" "yb" ]
      
           Type:
             mapAttrsToList :: (String -> a -> b) -> AttrSet -> [b]
      
        */
        mapAttrsToList =
          # A function, given an attribute's name and value, returns a new value.
          f:
          # Attribute set to map over.
          attrs:
          map (name: f name attrs.${name}) (attrNames attrs);
      
      
        /* Like `mapAttrs`, except that it recursively applies itself to
           attribute sets.  Also, the first argument of the argument
           function is a *list* of the names of the containing attributes.
      
           Example:
             mapAttrsRecursive (path: value: concatStringsSep "-" (path ++ [value]))
               { n = { a = "A"; m = { b = "B"; c = "C"; }; }; d = "D"; }
             => { n = { a = "n-a-A"; m = { b = "n-m-b-B"; c = "n-m-c-C"; }; }; d = "d-D"; }
      
           Type:
             mapAttrsRecursive :: ([String] -> a -> b) -> AttrSet -> AttrSet
        */
        mapAttrsRecursive =
          # A function, given a list of attribute names and a value, returns a new value.
          f:
          # Set to recursively map over.
          set:
          mapAttrsRecursiveCond (as: true) f set;
      
      
        /* Like `mapAttrsRecursive`, but it takes an additional predicate
           function that tells it whether to recurse into an attribute
           set.  If it returns false, `mapAttrsRecursiveCond` does not
           recurse, but does apply the map function.  If it returns true, it
           does recurse, and does not apply the map function.
      
           Example:
             # To prevent recursing into derivations (which are attribute
             # sets with the attribute "type" equal to "derivation"):
             mapAttrsRecursiveCond
               (as: !(as ? "type" && as.type == "derivation"))
               (x: ... do something ...)
               attrs
      
           Type:
             mapAttrsRecursiveCond :: (AttrSet -> Bool) -> ([String] -> a -> b) -> AttrSet -> AttrSet
        */
        mapAttrsRecursiveCond =
          # A function, given the attribute set the recursion is currently at, determine if to recurse deeper into that attribute set.
          cond:
          # A function, given a list of attribute names and a value, returns a new value.
          f:
          # Attribute set to recursively map over.
          set:
          let
            recurse = path:
              let
                g =
                  name: value:
                  if isAttrs value && cond value
                    then recurse (path ++ [name]) value
                    else f (path ++ [name]) value;
              in mapAttrs g;
          in recurse [] set;
      
      
        /* Generate an attribute set by mapping a function over a list of
           attribute names.
      
           Example:
             genAttrs [ "foo" "bar" ] (name: "x_" + name)
             => { foo = "x_foo"; bar = "x_bar"; }
      
           Type:
             genAttrs :: [ String ] -> (String -> Any) -> AttrSet
        */
        genAttrs =
          # Names of values in the resulting attribute set.
          names:
          # A function, given the name of the attribute, returns the attribute's value.
          f:
          listToAttrs (map (n: nameValuePair n (f n)) names);
      
      
        /* Check whether the argument is a derivation. Any set with
           `{ type = "derivation"; }` counts as a derivation.
      
           Example:
             nixpkgs = import <nixpkgs> {}
             isDerivation nixpkgs.ruby
             => true
             isDerivation "foobar"
             => false
      
           Type:
             isDerivation :: Any -> Bool
        */
        isDerivation =
          # Value to check.
          value: value.type or null == "derivation";
      
         /* Converts a store path to a fake derivation.
      
            Type:
              toDerivation :: Path -> Derivation
         */
         toDerivation =
           # A store path to convert to a derivation.
           path:
           let
             path' = builtins.storePath path;
             res =
               { type = "derivation";
                 name = sanitizeDerivationName (builtins.substring 33 (-1) (baseNameOf path'));
                 outPath = path';
                 outputs = [ "out" ];
                 out = res;
                 outputName = "out";
               };
          in res;
      
      
        /* If `cond` is true, return the attribute set `as`,
           otherwise an empty attribute set.
      
           Example:
             optionalAttrs (true) { my = "set"; }
             => { my = "set"; }
             optionalAttrs (false) { my = "set"; }
             => { }
      
           Type:
             optionalAttrs :: Bool -> AttrSet -> AttrSet
        */
        optionalAttrs =
          # Condition under which the `as` attribute set is returned.
          cond:
          # The attribute set to return if `cond` is `true`.
          as:
          if cond then as else {};
      
      
        /* Merge sets of attributes and use the function `f` to merge attributes
           values.
      
           Example:
             zipAttrsWithNames ["a"] (name: vs: vs) [{a = "x";} {a = "y"; b = "z";}]
             => { a = ["x" "y"]; }
      
           Type:
             zipAttrsWithNames :: [ String ] -> (String -> [ Any ] -> Any) -> [ AttrSet ] -> AttrSet
        */
        zipAttrsWithNames =
          # List of attribute names to zip.
          names:
          # A function, accepts an attribute name, all the values, and returns a combined value.
          f:
          # List of values from the list of attribute sets.
          sets:
          listToAttrs (map (name: {
            inherit name;
            value = f name (catAttrs name sets);
          }) names);
      
      
        /* Merge sets of attributes and use the function f to merge attribute values.
           Like `lib.attrsets.zipAttrsWithNames` with all key names are passed for `names`.
      
           Implementation note: Common names appear multiple times in the list of
           names, hopefully this does not affect the system because the maximal
           laziness avoid computing twice the same expression and `listToAttrs` does
           not care about duplicated attribute names.
      
           Example:
             zipAttrsWith (name: values: values) [{a = "x";} {a = "y"; b = "z";}]
             => { a = ["x" "y"]; b = ["z"] }
      
           Type:
             zipAttrsWith :: (String -> [ Any ] -> Any) -> [ AttrSet ] -> AttrSet
        */
        zipAttrsWith =
          builtins.zipAttrsWith or (f: sets: zipAttrsWithNames (concatMap attrNames sets) f sets);
      
      
        /* Merge sets of attributes and combine each attribute value in to a list.
      
           Like `lib.attrsets.zipAttrsWith` with `(name: values: values)` as the function.
      
           Example:
             zipAttrs [{a = "x";} {a = "y"; b = "z";}]
             => { a = ["x" "y"]; b = ["z"] }
      
           Type:
             zipAttrs :: [ AttrSet ] -> AttrSet
        */
        zipAttrs =
          # List of attribute sets to zip together.
          sets:
          zipAttrsWith (name: values: values) sets;
      
      
        /* Does the same as the update operator '//' except that attributes are
           merged until the given predicate is verified.  The predicate should
           accept 3 arguments which are the path to reach the attribute, a part of
           the first attribute set and a part of the second attribute set.  When
           the predicate is satisfied, the value of the first attribute set is
           replaced by the value of the second attribute set.
      
           Example:
             recursiveUpdateUntil (path: l: r: path == ["foo"]) {
               # first attribute set
               foo.bar = 1;
               foo.baz = 2;
               bar = 3;
             } {
               #second attribute set
               foo.bar = 1;
               foo.quz = 2;
               baz = 4;
             }
      
             => {
               foo.bar = 1; # 'foo.*' from the second set
               foo.quz = 2; #
               bar = 3;     # 'bar' from the first set
               baz = 4;     # 'baz' from the second set
             }
      
           Type:
             recursiveUpdateUntil :: ( [ String ] -> AttrSet -> AttrSet -> Bool ) -> AttrSet -> AttrSet -> AttrSet
        */
        recursiveUpdateUntil =
          # Predicate, taking the path to the current attribute as a list of strings for attribute names, and the two values at that path from the original arguments.
          pred:
          # Left attribute set of the merge.
          lhs:
          # Right attribute set of the merge.
          rhs:
          let f = attrPath:
            zipAttrsWith (n: values:
              let here = attrPath ++ [n]; in
              if length values == 1
              || pred here (elemAt values 1) (head values) then
                head values
              else
                f here values
            );
          in f [] [rhs lhs];
      
      
        /* A recursive variant of the update operator ‘//’.  The recursion
           stops when one of the attribute values is not an attribute set,
           in which case the right hand side value takes precedence over the
           left hand side value.
      
           Example:
             recursiveUpdate {
               boot.loader.grub.enable = true;
               boot.loader.grub.device = "/dev/hda";
             } {
               boot.loader.grub.device = "";
             }
      
             returns: {
               boot.loader.grub.enable = true;
               boot.loader.grub.device = "";
             }
      
           Type:
             recursiveUpdate :: AttrSet -> AttrSet -> AttrSet
        */
        recursiveUpdate =
          # Left attribute set of the merge.
          lhs:
          # Right attribute set of the merge.
          rhs:
          recursiveUpdateUntil (path: lhs: rhs: !(isAttrs lhs && isAttrs rhs)) lhs rhs;
      
      
        /* Returns true if the pattern is contained in the set. False otherwise.
      
           Example:
             matchAttrs { cpu = {}; } { cpu = { bits = 64; }; }
             => true
      
           Type:
             matchAttrs :: AttrSet -> AttrSet -> Bool
        */
        matchAttrs =
          # Attribute set structure to match
          pattern:
          # Attribute set to find patterns in
          attrs:
              assert isAttrs pattern; (
                  (all
                      id
                      (attrValues
                          (zipAttrsWithNames
                              (attrNames
                                  pattern
                              )
                              (n: values:
                                  let
                                      pat = (head
                                          values
                                      );
                                      val = (elemAt
                                          values
                                          1
                                      );
                                  in
                                      if length values == 1 then
                                          false
                                      else if isAttrs pat then
                                          isAttrs val && matchAttrs pat val
                                      else
                                          pat == val
                              )
                              [pattern attrs]
                          )
                      )
                  )
              );
      
      
        /* Override only the attributes that are already present in the old set
          useful for deep-overriding.
      
          Example:
            overrideExisting {} { a = 1; }
            => {}
            overrideExisting { b = 2; } { a = 1; }
            => { b = 2; }
            overrideExisting { a = 3; b = 2; } { a = 1; }
            => { a = 1; b = 2; }
      
          Type:
            overrideExisting :: AttrSet -> AttrSet -> AttrSet
        */
        overrideExisting =
          # Original attribute set
          old:
          # Attribute set with attributes to override in `old`.
          new:
          mapAttrs (name: value: new.${name} or value) old;
      
      
        /* Turns a list of strings into a human-readable description of those
          strings represented as an attribute path. The result of this function is
          not intended to be machine-readable.
          Create a new attribute set with `value` set at the nested attribute location specified in `attrPath`.
      
          Example:
            showAttrPath [ "foo" "10" "bar" ]
            => "foo.\"10\".bar"
            showAttrPath []
            => "<root attribute path>"
      
          Type:
            showAttrPath :: [String] -> String
        */
        showAttrPath =
          # Attribute path to render to a string
          path:
          if path == [] then "<root attribute path>"
          else concatMapStringsSep "." escapeNixIdentifier path;
      
      
        /* Get a package output.
           If no output is found, fallback to `.out` and then to the default.
      
           Example:
             getOutput "dev" pkgs.openssl
             => "/nix/store/9rz8gxhzf8sw4kf2j2f1grr49w8zx5vj-openssl-1.0.1r-dev"
      
           Type:
             getOutput :: String -> Derivation -> String
        */
        getOutput = output: pkg:
          if ! pkg ? outputSpecified || ! pkg.outputSpecified
            then pkg.${output} or pkg.out or pkg
            else pkg;
      
        /* Get a package's `bin` output.
           If the output does not exist, fallback to `.out` and then to the default.
      
           Example:
             getBin pkgs.openssl
             => "/nix/store/9rz8gxhzf8sw4kf2j2f1grr49w8zx5vj-openssl-1.0.1r"
      
           Type:
             getBin :: Derivation -> String
        */
        getBin = getOutput "bin";
      
      
        /* Get a package's `lib` output.
           If the output does not exist, fallback to `.out` and then to the default.
      
           Example:
             getLib pkgs.openssl
             => "/nix/store/9rz8gxhzf8sw4kf2j2f1grr49w8zx5vj-openssl-1.0.1r-lib"
      
           Type:
             getLib :: Derivation -> String
        */
        getLib = getOutput "lib";
      
      
        /* Get a package's `dev` output.
           If the output does not exist, fallback to `.out` and then to the default.
      
           Example:
             getDev pkgs.openssl
             => "/nix/store/9rz8gxhzf8sw4kf2j2f1grr49w8zx5vj-openssl-1.0.1r-dev"
      
           Type:
             getDev :: Derivation -> String
        */
        getDev = getOutput "dev";
      
      
        /* Get a package's `man` output.
           If the output does not exist, fallback to `.out` and then to the default.
      
           Example:
             getMan pkgs.openssl
             => "/nix/store/9rz8gxhzf8sw4kf2j2f1grr49w8zx5vj-openssl-1.0.1r-man"
      
           Type:
             getMan :: Derivation -> String
        */
        getMan = getOutput "man";
      
        /* Pick the outputs of packages to place in `buildInputs`
      
         Type: chooseDevOutputs :: [Derivation] -> [String]
      
        */
        chooseDevOutputs =
          # List of packages to pick `dev` outputs from
          drvs:
          builtins.map getDev drvs;
      
        /* Make various Nix tools consider the contents of the resulting
           attribute set when looking for what to build, find, etc.
      
           This function only affects a single attribute set; it does not
           apply itself recursively for nested attribute sets.
      
           Example:
             { pkgs ? import <nixpkgs> {} }:
             {
               myTools = pkgs.lib.recurseIntoAttrs {
                 inherit (pkgs) hello figlet;
               };
             }
      
           Type:
             recurseIntoAttrs :: AttrSet -> AttrSet
      
         */
        recurseIntoAttrs =
          # An attribute set to scan for derivations.
          attrs:
          attrs // { recurseForDerivations = true; };
      
        /* Undo the effect of recurseIntoAttrs.
      
           Type:
             dontRecurseIntoAttrs :: AttrSet -> AttrSet
         */
        dontRecurseIntoAttrs =
          # An attribute set to not scan for derivations.
          attrs:
          attrs // { recurseForDerivations = false; };
      
        /* `unionOfDisjoint x y` is equal to `x // y // z` where the
           attrnames in `z` are the intersection of the attrnames in `x` and
           `y`, and all values `assert` with an error message.  This
            operator is commutative, unlike (//).
      
           Type: unionOfDisjoint :: AttrSet -> AttrSet -> AttrSet
        */
        unionOfDisjoint = x: y:
          let
            intersection = builtins.intersectAttrs x y;
            collisions = lib.concatStringsSep " " (builtins.attrNames intersection);
            mask = builtins.mapAttrs (name: value: builtins.throw
              "unionOfDisjoint: collision on ${name}; complete list: ${collisions}")
              intersection;
          in
            (x // y) // mask;
      
        # DEPRECATED
        zipWithNames = zipAttrsWithNames;
      
        # DEPRECATED
        zip = builtins.trace
          "lib.zip is deprecated, use lib.zipAttrsWith instead" zipAttrsWith;
      }
    );
    "/Users/jeffhykin/repos/nixpkgs/lib/trivial.nix" = (# "/Users/jeffhykin/repos/nixpkgs/lib/trivial.nix"
      { lib }:
      
      rec {
      
        ## Simple (higher order) functions
      
        /* The identity function
           For when you need a function that does “nothing”.
      
           Type: id :: a -> a
        */
        id =
          # The value to return
          x: x;
      
        /* The constant function
      
           Ignores the second argument. If called with only one argument,
           constructs a function that always returns a static value.
      
           Type: const :: a -> b -> a
           Example:
             let f = const 5; in f 10
             => 5
        */
        const =
          # Value to return
          x:
          # Value to ignore
          y: x;
      
        /* Pipes a value through a list of functions, left to right.
      
           Type: pipe :: a -> [<functions>] -> <return type of last function>
           Example:
             pipe 2 [
               (x: x + 2)  # 2 + 2 = 4
               (x: x * 2)  # 4 * 2 = 8
             ]
             => 8
      
             # ideal to do text transformations
             pipe [ "a/b" "a/c" ] [
      
               # create the cp command
               (map (file: ''cp "${src}/${file}" $out\n''))
      
               # concatenate all commands into one string
               lib.concatStrings
      
               # make that string into a nix derivation
               (pkgs.runCommand "copy-to-out" {})
      
             ]
             => <drv which copies all files to $out>
      
           The output type of each function has to be the input type
           of the next function, and the last function returns the
           final value.
        */
        pipe = val: functions:
          let reverseApply = x: f: f x;
          in builtins.foldl' reverseApply val functions;
      
        # note please don’t add a function like `compose = flip pipe`.
        # This would confuse users, because the order of the functions
        # in the list is not clear. With pipe, it’s obvious that it
        # goes first-to-last. With `compose`, not so much.
      
        ## Named versions corresponding to some builtin operators.
      
        /* Concatenate two lists
      
           Type: concat :: [a] -> [a] -> [a]
      
           Example:
             concat [ 1 2 ] [ 3 4 ]
             => [ 1 2 3 4 ]
        */
        concat = x: y: x ++ y;
      
        /* boolean “or” */
        or = x: y: x || y;
      
        /* boolean “and” */
        and = x: y: x && y;
      
        /* bitwise “and” */
        bitAnd = builtins.bitAnd
          or (/*import:first*/ _-_06294632224836068_-_."/Users/jeffhykin/repos/nixpkgs/lib/zip-int-bits.nix"
              (a: b: if a==1 && b==1 then 1 else 0));
      
        /* bitwise “or” */
        bitOr = builtins.bitOr
          or (/*import:normal*/ _-_06294632224836068_-_."/Users/jeffhykin/repos/nixpkgs/lib/zip-int-bits.nix"
              (a: b: if a==1 || b==1 then 1 else 0));
      
        /* bitwise “xor” */
        bitXor = builtins.bitXor
          or (/*import:normal*/ _-_06294632224836068_-_."/Users/jeffhykin/repos/nixpkgs/lib/zip-int-bits.nix"
              (a: b: if a!=b then 1 else 0));
      
        /* bitwise “not” */
        bitNot = builtins.sub (-1);
      
        /* Convert a boolean to a string.
      
           This function uses the strings "true" and "false" to represent
           boolean values. Calling `toString` on a bool instead returns "1"
           and "" (sic!).
      
           Type: boolToString :: bool -> string
        */
        boolToString = b: if b then "true" else "false";
      
        /* Merge two attribute sets shallowly, right side trumps left
      
           mergeAttrs :: attrs -> attrs -> attrs
      
           Example:
             mergeAttrs { a = 1; b = 2; } { b = 3; c = 4; }
             => { a = 1; b = 3; c = 4; }
        */
        mergeAttrs =
          # Left attribute set
          x:
          # Right attribute set (higher precedence for equal keys)
          y: x // y;
      
        /* Flip the order of the arguments of a binary function.
      
           Type: flip :: (a -> b -> c) -> (b -> a -> c)
      
           Example:
             flip concat [1] [2]
             => [ 2 1 ]
        */
        flip = f: a: b: f b a;
      
        /* Apply function if the supplied argument is non-null.
      
           Example:
             mapNullable (x: x+1) null
             => null
             mapNullable (x: x+1) 22
             => 23
        */
        mapNullable =
          # Function to call
          f:
          # Argument to check for null before passing it to `f`
          a: if a == null then a else f a;
      
        # Pull in some builtins not included elsewhere.
        inherit (builtins)
          pathExists readFile isBool
          isInt isFloat add sub lessThan
          seq deepSeq genericClosure;
      
      
        ## nixpkgs version strings
      
        /* Returns the current full nixpkgs version number. */
        version = release + versionSuffix;
      
        /* Returns the current nixpkgs release number as string. */
        release = lib.strings.fileContents ../.version;
      
        /* The latest release that is supported, at the time of release branch-off,
           if applicable.
      
           Ideally, out-of-tree modules should be able to evaluate cleanly with all
           supported Nixpkgs versions (master, release and old release until EOL).
           So if possible, deprecation warnings should take effect only when all
           out-of-tree expressions/libs/modules can upgrade to the new way without
           losing support for supported Nixpkgs versions.
      
           This release number allows deprecation warnings to be implemented such that
           they take effect as soon as the oldest release reaches end of life. */
        oldestSupportedRelease =
          # Update on master only. Do not backport.
          2211;
      
        /* Whether a feature is supported in all supported releases (at the time of
           release branch-off, if applicable). See `oldestSupportedRelease`. */
        isInOldestRelease =
          /* Release number of feature introduction as an integer, e.g. 2111 for 21.11.
             Set it to the upcoming release, matching the nixpkgs/.version file.
          */
          release:
            release <= lib.trivial.oldestSupportedRelease;
      
        /* Returns the current nixpkgs release code name.
      
           On each release the first letter is bumped and a new animal is chosen
           starting with that new letter.
        */
        codeName = "Stoat";
      
        /* Returns the current nixpkgs version suffix as string. */
        versionSuffix =
          let suffixFile = ../.version-suffix;
          in if pathExists suffixFile
          then lib.strings.fileContents suffixFile
          else "pre-git";
      
        /* Attempts to return the the current revision of nixpkgs and
           returns the supplied default value otherwise.
      
           Type: revisionWithDefault :: string -> string
        */
        revisionWithDefault =
          # Default value to return if revision can not be determined
          default:
          let
            revisionFile = "${toString ./..}/.git-revision";
            gitRepo      = "${toString ./..}/.git";
          in if lib.pathIsGitRepo gitRepo
             then lib.commitIdFromGitRepo gitRepo
             else if lib.pathExists revisionFile then lib.fileContents revisionFile
             else default;
      
        nixpkgsVersion = builtins.trace "`lib.nixpkgsVersion` is deprecated, use `lib.version` instead!" version;
      
        /* Determine whether the function is being called from inside a Nix
           shell.
      
           Type: inNixShell :: bool
        */
        inNixShell = builtins.getEnv "IN_NIX_SHELL" != "";
      
        /* Determine whether the function is being called from inside pure-eval mode
           by seeing whether `builtins` contains `currentSystem`. If not, we must be in
           pure-eval mode.
      
           Type: inPureEvalMode :: bool
        */
        inPureEvalMode = ! builtins ? currentSystem;
      
        ## Integer operations
      
        /* Return minimum of two numbers. */
        min = x: y: if x < y then x else y;
      
        /* Return maximum of two numbers. */
        max = x: y: if x > y then x else y;
      
        /* Integer modulus
      
           Example:
             mod 11 10
             => 1
             mod 1 10
             => 1
        */
        mod = base: int: base - (int * (builtins.div base int));
      
      
        ## Comparisons
      
        /* C-style comparisons
      
           a < b,  compare a b => -1
           a == b, compare a b => 0
           a > b,  compare a b => 1
        */
        compare = a: b:
          if a < b
          then -1
          else if a > b
               then 1
               else 0;
      
        /* Split type into two subtypes by predicate `p`, take all elements
           of the first subtype to be less than all the elements of the
           second subtype, compare elements of a single subtype with `yes`
           and `no` respectively.
      
           Type: (a -> bool) -> (a -> a -> int) -> (a -> a -> int) -> (a -> a -> int)
      
           Example:
             let cmp = splitByAndCompare (hasPrefix "foo") compare compare; in
      
             cmp "a" "z" => -1
             cmp "fooa" "fooz" => -1
      
             cmp "f" "a" => 1
             cmp "fooa" "a" => -1
             # while
             compare "fooa" "a" => 1
        */
        splitByAndCompare =
          # Predicate
          p:
          # Comparison function if predicate holds for both values
          yes:
          # Comparison function if predicate holds for neither value
          no:
          # First value to compare
          a:
          # Second value to compare
          b:
          if p a
          then if p b then yes a b else -1
          else if p b then 1 else no a b;
      
      
        /* Reads a JSON file.
      
           Type :: path -> any
        */
        importJSON = path:
          builtins.fromJSON (builtins.readFile path);
      
        /* Reads a TOML file.
      
           Type :: path -> any
        */
        importTOML = path:
          builtins.fromTOML (builtins.readFile path);
      
        ## Warnings
      
        # See https://github.com/NixOS/nix/issues/749. Eventually we'd like these
        # to expand to Nix builtins that carry metadata so that Nix can filter out
        # the INFO messages without parsing the message string.
        #
        # Usage:
        # {
        #   foo = lib.warn "foo is deprecated" oldFoo;
        #   bar = lib.warnIf (bar == "") "Empty bar is deprecated" bar;
        # }
        #
        # TODO: figure out a clever way to integrate location information from
        # something like __unsafeGetAttrPos.
      
        /*
          Print a warning before returning the second argument. This function behaves
          like `builtins.trace`, but requires a string message and formats it as a
          warning, including the `warning: ` prefix.
      
          To get a call stack trace and abort evaluation, set the environment variable
          `NIX_ABORT_ON_WARN=true` and set the Nix options `--option pure-eval false --show-trace`
      
          Type: string -> a -> a
        */
        warn =
          if lib.elem (builtins.getEnv "NIX_ABORT_ON_WARN") ["1" "true" "yes"]
          then msg: builtins.trace "[1;31mwarning: ${msg}[0m" (abort "NIX_ABORT_ON_WARN=true; warnings are treated as unrecoverable errors.")
          else msg: builtins.trace "[1;31mwarning: ${msg}[0m";
      
        /*
          Like warn, but only warn when the first argument is `true`.
      
          Type: bool -> string -> a -> a
        */
        warnIf = cond: msg: if cond then warn msg else x: x;
      
        /*
          Like warnIf, but negated (warn if the first argument is `false`).
      
          Type: bool -> string -> a -> a
        */
        warnIfNot = cond: msg: if cond then x: x else warn msg;
      
        /*
          Like the `assert b; e` expression, but with a custom error message and
          without the semicolon.
      
          If true, return the identity function, `r: r`.
      
          If false, throw the error message.
      
          Calls can be juxtaposed using function application, as `(r: r) a = a`, so
          `(r: r) (r: r) a = a`, and so forth.
      
          Type: bool -> string -> a -> a
      
          Example:
      
              throwIfNot (lib.isList overlays) "The overlays argument to nixpkgs must be a list."
              lib.foldr (x: throwIfNot (lib.isFunction x) "All overlays passed to nixpkgs must be functions.") (r: r) overlays
              pkgs
      
        */
        throwIfNot = cond: msg: if cond then x: x else throw msg;
      
        /*
          Like throwIfNot, but negated (throw if the first argument is `true`).
      
          Type: bool -> string -> a -> a
        */
        throwIf = cond: msg: if cond then throw msg else x: x;
      
        /* Check if the elements in a list are valid values from a enum, returning the identity function, or throwing an error message otherwise.
      
           Example:
             let colorVariants = ["bright" "dark" "black"]
             in checkListOfEnum "color variants" [ "standard" "light" "dark" ] colorVariants;
             =>
             error: color variants: bright, black unexpected; valid ones: standard, light, dark
      
           Type: String -> List ComparableVal -> List ComparableVal -> a -> a
        */
        checkListOfEnum = msg: valid: given:
          let
            unexpected = lib.subtractLists valid given;
          in
            lib.throwIfNot (unexpected == [])
              "${msg}: ${builtins.concatStringsSep ", " (builtins.map builtins.toString unexpected)} unexpected; valid ones: ${builtins.concatStringsSep ", " (builtins.map builtins.toString valid)}";
      
        info = msg: builtins.trace "INFO: ${msg}";
      
        showWarnings = warnings: res: lib.foldr (w: x: warn w x) res warnings;
      
        ## Function annotations
      
        /* Add metadata about expected function arguments to a function.
           The metadata should match the format given by
           builtins.functionArgs, i.e. a set from expected argument to a bool
           representing whether that argument has a default or not.
           setFunctionArgs : (a → b) → Map String Bool → (a → b)
      
           This function is necessary because you can't dynamically create a
           function of the { a, b ? foo, ... }: format, but some facilities
           like callPackage expect to be able to query expected arguments.
        */
        setFunctionArgs = f: args:
          { # TODO: Should we add call-time "type" checking like built in?
            __functor = self: f;
            __functionArgs = args;
          };
      
        /* Extract the expected function arguments from a function.
           This works both with nix-native { a, b ? foo, ... }: style
           functions and functions with args set with 'setFunctionArgs'. It
           has the same return type and semantics as builtins.functionArgs.
           setFunctionArgs : (a → b) → Map String Bool.
        */
        functionArgs = f:
          if f ? __functor
          then f.__functionArgs or (lib.functionArgs (f.__functor f))
          else builtins.functionArgs f;
      
        /* Check whether something is a function or something
           annotated with function args.
        */
        isFunction = f: builtins.isFunction f ||
          (f ? __functor && isFunction (f.__functor f));
      
        /*
          Turns any non-callable values into constant functions.
          Returns callable values as is.
      
          Example:
      
            nix-repl> lib.toFunction 1 2
            1
      
            nix-repl> lib.toFunction (x: x + 1) 2
            3
        */
        toFunction =
          # Any value
          v:
          if isFunction v
          then v
          else k: v;
      
        /* Convert the given positive integer to a string of its hexadecimal
           representation. For example:
      
           toHexString 0 => "0"
      
           toHexString 16 => "10"
      
           toHexString 250 => "FA"
        */
        toHexString = i:
          let
            toHexDigit = d:
              if d < 10
              then toString d
              else
                {
                  "10" = "A";
                  "11" = "B";
                  "12" = "C";
                  "13" = "D";
                  "14" = "E";
                  "15" = "F";
                }.${toString d};
          in
            lib.concatMapStrings toHexDigit (toBaseDigits 16 i);
      
        /* `toBaseDigits base i` converts the positive integer i to a list of its
           digits in the given base. For example:
      
           toBaseDigits 10 123 => [ 1 2 3 ]
      
           toBaseDigits 2 6 => [ 1 1 0 ]
      
           toBaseDigits 16 250 => [ 15 10 ]
        */
        toBaseDigits = base: i:
          let
            go = i:
              if i < base
              then [i]
              else
                let
                  r = i - ((i / base) * base);
                  q = (i - r) / base;
                in
                  [r] ++ go q;
          in
            assert (isInt base);
            assert (isInt i);
            assert (base >= 2);
            assert (i >= 0);
            lib.reverseList (go i);
      }
    );
    "/Users/jeffhykin/repos/nixpkgs/lib/ascii-table.nix" = (# "/Users/jeffhykin/repos/nixpkgs/lib/ascii-table.nix"
      { " "  = 32;
        "!"  = 33;
        "\"" = 34;
        "#"  = 35;
        "$"  = 36;
        "%"  = 37;
        "&"  = 38;
        "'"  = 39;
        "("  = 40;
        ")"  = 41;
        "*"  = 42;
        "+"  = 43;
        ","  = 44;
        "-"  = 45;
        "."  = 46;
        "/"  = 47;
        "0"  = 48;
        "1"  = 49;
        "2"  = 50;
        "3"  = 51;
        "4"  = 52;
        "5"  = 53;
        "6"  = 54;
        "7"  = 55;
        "8"  = 56;
        "9"  = 57;
        ":"  = 58;
        ";"  = 59;
        "<"  = 60;
        "="  = 61;
        ">"  = 62;
        "?"  = 63;
        "@"  = 64;
        "A"  = 65;
        "B"  = 66;
        "C"  = 67;
        "D"  = 68;
        "E"  = 69;
        "F"  = 70;
        "G"  = 71;
        "H"  = 72;
        "I"  = 73;
        "J"  = 74;
        "K"  = 75;
        "L"  = 76;
        "M"  = 77;
        "N"  = 78;
        "O"  = 79;
        "P"  = 80;
        "Q"  = 81;
        "R"  = 82;
        "S"  = 83;
        "T"  = 84;
        "U"  = 85;
        "V"  = 86;
        "W"  = 87;
        "X"  = 88;
        "Y"  = 89;
        "Z"  = 90;
        "["  = 91;
        "\\" = 92;
        "]"  = 93;
        "^"  = 94;
        "_"  = 95;
        "`"  = 96;
        "a"  = 97;
        "b"  = 98;
        "c"  = 99;
        "d"  = 100;
        "e"  = 101;
        "f"  = 102;
        "g"  = 103;
        "h"  = 104;
        "i"  = 105;
        "j"  = 106;
        "k"  = 107;
        "l"  = 108;
        "m"  = 109;
        "n"  = 110;
        "o"  = 111;
        "p"  = 112;
        "q"  = 113;
        "r"  = 114;
        "s"  = 115;
        "t"  = 116;
        "u"  = 117;
        "v"  = 118;
        "w"  = 119;
        "x"  = 120;
        "y"  = 121;
        "z"  = 122;
        "{"  = 123;
        "|"  = 124;
        "}"  = 125;
        "~"  = 126;
      }
    );
    "/Users/jeffhykin/repos/nixpkgs/lib/strings-with-deps.nix" = (# "/Users/jeffhykin/repos/nixpkgs/lib/strings-with-deps.nix"
      { lib }:
      /*
      Usage:
      
        You define you custom builder script by adding all build steps to a list.
        for example:
             builder = writeScript "fsg-4.4-builder"
                     (textClosure [doUnpack addInputs preBuild doMake installPhase doForceShare]);
      
        a step is defined by noDepEntry, fullDepEntry or packEntry.
        To ensure that prerequisite are met those are added before the task itself by
        textClosureDupList. Duplicated items are removed again.
      
        See trace/nixpkgs/trunk/pkgs/top-level/builder-defs.nix for some predefined build steps
      
        Attention:
      
        let
          pkgs = (import <nixpkgs>) {};
        in let
          inherit (pkgs.stringsWithDeps) fullDepEntry packEntry noDepEntry textClosureMap;
          inherit (pkgs.lib) id;
      
          nameA = noDepEntry "Text a";
          nameB = fullDepEntry "Text b" ["nameA"];
          nameC = fullDepEntry "Text c" ["nameA"];
      
          stages = {
            nameHeader = noDepEntry "#! /bin/sh \n";
            inherit nameA nameB nameC;
          };
        in
          textClosureMap id stages
          [ "nameHeader" "nameA" "nameB" "nameC"
            nameC # <- added twice. add a dep entry if you know that it will be added once only [1]
            "nameB" # <- this will not be added again because the attr name (reference) is used
          ]
      
        # result: Str("#! /bin/sh \n\nText a\nText b\nText c\nText c",[])
      
        [1] maybe this behaviour should be removed to keep things simple (?)
      */
      
      let
        inherit (lib)
          concatStringsSep
          head
          isAttrs
          listToAttrs
          tail
          ;
      in
      rec {
      
        /* !!! The interface of this function is kind of messed up, since
           it's way too overloaded and almost but not quite computes a
           topological sort of the depstrings. */
      
        textClosureList = predefined: arg:
          let
            f = done: todo:
              if todo == [] then {result = []; inherit done;}
              else
                let entry = head todo; in
                if isAttrs entry then
                  let x = f done entry.deps;
                      y = f x.done (tail todo);
                  in { result = x.result ++ [entry.text] ++ y.result;
                       done = y.done;
                     }
                else if done ? ${entry} then f done (tail todo)
                else f (done // listToAttrs [{name = entry; value = 1;}]) ([predefined.${entry}] ++ tail todo);
          in (f {} arg).result;
      
        textClosureMap = f: predefined: names:
          concatStringsSep "\n" (map f (textClosureList predefined names));
      
        noDepEntry = text: {inherit text; deps = [];};
        fullDepEntry = text: deps: {inherit text deps;};
        packEntry = deps: {inherit deps; text="";};
      
        stringAfter = deps: text: { inherit text deps; };
      
      }
    );
    "/Users/jeffhykin/repos/nixpkgs/lib/strings.nix" = (# "/Users/jeffhykin/repos/nixpkgs/lib/strings.nix"
      /* String manipulation functions. */
      { lib }:
      let
      
      inherit (builtins) length;
      
      in
      
      rec {
      
        inherit (builtins)
          compareVersions
          elem
          elemAt
          filter
          fromJSON
          head
          isInt
          isList
          isAttrs
          isPath
          isString
          match
          parseDrvName
          readFile
          replaceStrings
          split
          storeDir
          stringLength
          substring
          tail
          toJSON
          typeOf
          unsafeDiscardStringContext
          ;
      
        /* Concatenate a list of strings.
      
          Type: concatStrings :: [string] -> string
      
           Example:
             concatStrings ["foo" "bar"]
             => "foobar"
        */
        concatStrings = builtins.concatStringsSep "";
      
        /* Map a function over a list and concatenate the resulting strings.
      
          Type: concatMapStrings :: (a -> string) -> [a] -> string
      
           Example:
             concatMapStrings (x: "a" + x) ["foo" "bar"]
             => "afooabar"
        */
        concatMapStrings = f: list: concatStrings (map f list);
      
        /* Like `concatMapStrings` except that the f functions also gets the
           position as a parameter.
      
           Type: concatImapStrings :: (int -> a -> string) -> [a] -> string
      
           Example:
             concatImapStrings (pos: x: "${toString pos}-${x}") ["foo" "bar"]
             => "1-foo2-bar"
        */
        concatImapStrings = f: list: concatStrings (lib.imap1 f list);
      
        /* Place an element between each element of a list
      
           Type: intersperse :: a -> [a] -> [a]
      
           Example:
             intersperse "/" ["usr" "local" "bin"]
             => ["usr" "/" "local" "/" "bin"].
        */
        intersperse =
          # Separator to add between elements
          separator:
          # Input list
          list:
          if list == [] || length list == 1
          then list
          else tail (lib.concatMap (x: [separator x]) list);
      
        /* Concatenate a list of strings with a separator between each element
      
           Type: concatStringsSep :: string -> [string] -> string
      
           Example:
              concatStringsSep "/" ["usr" "local" "bin"]
              => "usr/local/bin"
        */
        concatStringsSep = builtins.concatStringsSep or (separator: list:
          lib.foldl' (x: y: x + y) "" (intersperse separator list));
      
        /* Maps a function over a list of strings and then concatenates the
           result with the specified separator interspersed between
           elements.
      
           Type: concatMapStringsSep :: string -> (a -> string) -> [a] -> string
      
           Example:
              concatMapStringsSep "-" (x: toUpper x)  ["foo" "bar" "baz"]
              => "FOO-BAR-BAZ"
        */
        concatMapStringsSep =
          # Separator to add between elements
          sep:
          # Function to map over the list
          f:
          # List of input strings
          list: concatStringsSep sep (map f list);
      
        /* Same as `concatMapStringsSep`, but the mapping function
           additionally receives the position of its argument.
      
           Type: concatIMapStringsSep :: string -> (int -> a -> string) -> [a] -> string
      
           Example:
             concatImapStringsSep "-" (pos: x: toString (x / pos)) [ 6 6 6 ]
             => "6-3-2"
        */
        concatImapStringsSep =
          # Separator to add between elements
          sep:
          # Function that receives elements and their positions
          f:
          # List of input strings
          list: concatStringsSep sep (lib.imap1 f list);
      
        /* Construct a Unix-style, colon-separated search path consisting of
           the given `subDir` appended to each of the given paths.
      
           Type: makeSearchPath :: string -> [string] -> string
      
           Example:
             makeSearchPath "bin" ["/root" "/usr" "/usr/local"]
             => "/root/bin:/usr/bin:/usr/local/bin"
             makeSearchPath "bin" [""]
             => "/bin"
        */
        makeSearchPath =
          # Directory name to append
          subDir:
          # List of base paths
          paths:
          concatStringsSep ":" (map (path: path + "/" + subDir) (filter (x: x != null) paths));
      
        /* Construct a Unix-style search path by appending the given
           `subDir` to the specified `output` of each of the packages. If no
           output by the given name is found, fallback to `.out` and then to
           the default.
      
           Type: string -> string -> [package] -> string
      
           Example:
             makeSearchPathOutput "dev" "bin" [ pkgs.openssl pkgs.zlib ]
             => "/nix/store/9rz8gxhzf8sw4kf2j2f1grr49w8zx5vj-openssl-1.0.1r-dev/bin:/nix/store/wwh7mhwh269sfjkm6k5665b5kgp7jrk2-zlib-1.2.8/bin"
        */
        makeSearchPathOutput =
          # Package output to use
          output:
          # Directory name to append
          subDir:
          # List of packages
          pkgs: makeSearchPath subDir (map (lib.getOutput output) pkgs);
      
        /* Construct a library search path (such as RPATH) containing the
           libraries for a set of packages
      
           Example:
             makeLibraryPath [ "/usr" "/usr/local" ]
             => "/usr/lib:/usr/local/lib"
             pkgs = import <nixpkgs> { }
             makeLibraryPath [ pkgs.openssl pkgs.zlib ]
             => "/nix/store/9rz8gxhzf8sw4kf2j2f1grr49w8zx5vj-openssl-1.0.1r/lib:/nix/store/wwh7mhwh269sfjkm6k5665b5kgp7jrk2-zlib-1.2.8/lib"
        */
        makeLibraryPath = makeSearchPathOutput "lib" "lib";
      
        /* Construct a binary search path (such as $PATH) containing the
           binaries for a set of packages.
      
           Example:
             makeBinPath ["/root" "/usr" "/usr/local"]
             => "/root/bin:/usr/bin:/usr/local/bin"
        */
        makeBinPath = makeSearchPathOutput "bin" "bin";
      
        /* Normalize path, removing extraneous /s
      
           Type: normalizePath :: string -> string
      
           Example:
             normalizePath "/a//b///c/"
             => "/a/b/c/"
        */
        normalizePath = s: (builtins.foldl' (x: y: if y == "/" && hasSuffix "/" x then x else x+y) "" (stringToCharacters s));
      
        /* Depending on the boolean `cond', return either the given string
           or the empty string. Useful to concatenate against a bigger string.
      
           Type: optionalString :: bool -> string -> string
      
           Example:
             optionalString true "some-string"
             => "some-string"
             optionalString false "some-string"
             => ""
        */
        optionalString =
          # Condition
          cond:
          # String to return if condition is true
          string: if cond then string else "";
      
        /* Determine whether a string has given prefix.
      
           Type: hasPrefix :: string -> string -> bool
      
           Example:
             hasPrefix "foo" "foobar"
             => true
             hasPrefix "foo" "barfoo"
             => false
        */
        hasPrefix =
          # Prefix to check for
          pref:
          # Input string
          str: substring 0 (stringLength pref) str == pref;
      
        /* Determine whether a string has given suffix.
      
           Type: hasSuffix :: string -> string -> bool
      
           Example:
             hasSuffix "foo" "foobar"
             => false
             hasSuffix "foo" "barfoo"
             => true
        */
        hasSuffix =
          # Suffix to check for
          suffix:
          # Input string
          content:
          let
            lenContent = stringLength content;
            lenSuffix = stringLength suffix;
          in lenContent >= lenSuffix &&
             substring (lenContent - lenSuffix) lenContent content == suffix;
      
        /* Determine whether a string contains the given infix
      
          Type: hasInfix :: string -> string -> bool
      
          Example:
            hasInfix "bc" "abcd"
            => true
            hasInfix "ab" "abcd"
            => true
            hasInfix "cd" "abcd"
            => true
            hasInfix "foo" "abcd"
            => false
        */
        hasInfix = infix: content:
          builtins.match ".*${escapeRegex infix}.*" "${content}" != null;
      
        /* Convert a string to a list of characters (i.e. singleton strings).
           This allows you to, e.g., map a function over each character.  However,
           note that this will likely be horribly inefficient; Nix is not a
           general purpose programming language. Complex string manipulations
           should, if appropriate, be done in a derivation.
           Also note that Nix treats strings as a list of bytes and thus doesn't
           handle unicode.
      
           Type: stringToCharacters :: string -> [string]
      
           Example:
             stringToCharacters ""
             => [ ]
             stringToCharacters "abc"
             => [ "a" "b" "c" ]
             stringToCharacters "🦄"
             => [ "�" "�" "�" "�" ]
        */
        stringToCharacters = s:
          map (p: substring p 1 s) (lib.range 0 (stringLength s - 1));
      
        /* Manipulate a string character by character and replace them by
           strings before concatenating the results.
      
           Type: stringAsChars :: (string -> string) -> string -> string
      
           Example:
             stringAsChars (x: if x == "a" then "i" else x) "nax"
             => "nix"
        */
        stringAsChars =
          # Function to map over each individual character
          f:
          # Input string
          s: concatStrings (
            map f (stringToCharacters s)
          );
      
        /* Convert char to ascii value, must be in printable range
      
           Type: charToInt :: string -> int
      
           Example:
             charToInt "A"
             => 65
             charToInt "("
             => 40
      
        */
        charToInt = let
          table = /*import:first*/ _-_06294632224836068_-_."/Users/jeffhykin/repos/nixpkgs/lib/ascii-table.nix";
        in c: builtins.getAttr c table;
      
        /* Escape occurrence of the elements of `list` in `string` by
           prefixing it with a backslash.
      
           Type: escape :: [string] -> string -> string
      
           Example:
             escape ["(" ")"] "(foo)"
             => "\\(foo\\)"
        */
        escape = list: replaceStrings list (map (c: "\\${c}") list);
      
        /* Escape occurrence of the element of `list` in `string` by
           converting to its ASCII value and prefixing it with \\x.
           Only works for printable ascii characters.
      
           Type: escapeC = [string] -> string -> string
      
           Example:
             escapeC [" "] "foo bar"
             => "foo\\x20bar"
      
        */
        escapeC = list: replaceStrings list (map (c: "\\x${ toLower (lib.toHexString (charToInt c))}") list);
      
        /* Quote string to be used safely within the Bourne shell.
      
           Type: escapeShellArg :: string -> string
      
           Example:
             escapeShellArg "esc'ape\nme"
             => "'esc'\\''ape\nme'"
        */
        escapeShellArg = arg: "'${replaceStrings ["'"] ["'\\''"] (toString arg)}'";
      
        /* Quote all arguments to be safely passed to the Bourne shell.
      
           Type: escapeShellArgs :: [string] -> string
      
           Example:
             escapeShellArgs ["one" "two three" "four'five"]
             => "'one' 'two three' 'four'\\''five'"
        */
        escapeShellArgs = concatMapStringsSep " " escapeShellArg;
      
        /* Test whether the given name is a valid POSIX shell variable name.
      
           Type: string -> bool
      
           Example:
             isValidPosixName "foo_bar000"
             => true
             isValidPosixName "0-bad.jpg"
             => false
        */
        isValidPosixName = name: match "[a-zA-Z_][a-zA-Z0-9_]*" name != null;
      
        /* Translate a Nix value into a shell variable declaration, with proper escaping.
      
           The value can be a string (mapped to a regular variable), a list of strings
           (mapped to a Bash-style array) or an attribute set of strings (mapped to a
           Bash-style associative array). Note that "string" includes string-coercible
           values like paths or derivations.
      
           Strings are translated into POSIX sh-compatible code; lists and attribute sets
           assume a shell that understands Bash syntax (e.g. Bash or ZSH).
      
           Type: string -> (string | listOf string | attrsOf string) -> string
      
           Example:
             ''
               ${toShellVar "foo" "some string"}
               [[ "$foo" == "some string" ]]
             ''
        */
        toShellVar = name: value:
          lib.throwIfNot (isValidPosixName name) "toShellVar: ${name} is not a valid shell variable name" (
          if isAttrs value && ! isStringLike value then
            "declare -A ${name}=(${
              concatStringsSep " " (lib.mapAttrsToList (n: v:
                "[${escapeShellArg n}]=${escapeShellArg v}"
              ) value)
            })"
          else if isList value then
            "declare -a ${name}=(${escapeShellArgs value})"
          else
            "${name}=${escapeShellArg value}"
          );
      
        /* Translate an attribute set into corresponding shell variable declarations
           using `toShellVar`.
      
           Type: attrsOf (string | listOf string | attrsOf string) -> string
      
           Example:
             let
               foo = "value";
               bar = foo;
             in ''
               ${toShellVars { inherit foo bar; }}
               [[ "$foo" == "$bar" ]]
             ''
        */
        toShellVars = vars: concatStringsSep "\n" (lib.mapAttrsToList toShellVar vars);
      
        /* Turn a string into a Nix expression representing that string
      
           Type: string -> string
      
           Example:
             escapeNixString "hello\${}\n"
             => "\"hello\\\${}\\n\""
        */
        escapeNixString = s: escape ["$"] (toJSON s);
      
        /* Turn a string into an exact regular expression
      
           Type: string -> string
      
           Example:
             escapeRegex "[^a-z]*"
             => "\\[\\^a-z]\\*"
        */
        escapeRegex = escape (stringToCharacters "\\[{()^$?*+|.");
      
        /* Quotes a string if it can't be used as an identifier directly.
      
           Type: string -> string
      
           Example:
             escapeNixIdentifier "hello"
             => "hello"
             escapeNixIdentifier "0abc"
             => "\"0abc\""
        */
        escapeNixIdentifier = s:
          # Regex from https://github.com/NixOS/nix/blob/d048577909e383439c2549e849c5c2f2016c997e/src/libexpr/lexer.l#L91
          if match "[a-zA-Z_][a-zA-Z0-9_'-]*" s != null
          then s else escapeNixString s;
      
        /* Escapes a string such that it is safe to include verbatim in an XML
           document.
      
           Type: string -> string
      
           Example:
             escapeXML ''"test" 'test' < & >''
             => "&quot;test&quot; &apos;test&apos; &lt; &amp; &gt;"
        */
        escapeXML = builtins.replaceStrings
          ["\"" "'" "<" ">" "&"]
          ["&quot;" "&apos;" "&lt;" "&gt;" "&amp;"];
      
        # warning added 12-12-2022
        replaceChars = lib.warn "replaceChars is a deprecated alias of replaceStrings, replace usages of it with replaceStrings." builtins.replaceStrings;
      
        # Case conversion utilities.
        lowerChars = stringToCharacters "abcdefghijklmnopqrstuvwxyz";
        upperChars = stringToCharacters "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
      
        /* Converts an ASCII string to lower-case.
      
           Type: toLower :: string -> string
      
           Example:
             toLower "HOME"
             => "home"
        */
        toLower = replaceStrings upperChars lowerChars;
      
        /* Converts an ASCII string to upper-case.
      
           Type: toUpper :: string -> string
      
           Example:
             toUpper "home"
             => "HOME"
        */
        toUpper = replaceStrings lowerChars upperChars;
      
        /* Appends string context from another string.  This is an implementation
           detail of Nix and should be used carefully.
      
           Strings in Nix carry an invisible `context` which is a list of strings
           representing store paths.  If the string is later used in a derivation
           attribute, the derivation will properly populate the inputDrvs and
           inputSrcs.
      
           Example:
             pkgs = import <nixpkgs> { };
             addContextFrom pkgs.coreutils "bar"
             => "bar"
        */
        addContextFrom = a: b: substring 0 0 a + b;
      
        /* Cut a string with a separator and produces a list of strings which
           were separated by this separator.
      
           Example:
             splitString "." "foo.bar.baz"
             => [ "foo" "bar" "baz" ]
             splitString "/" "/usr/local/bin"
             => [ "" "usr" "local" "bin" ]
        */
        splitString = sep: s:
          let
            splits = builtins.filter builtins.isString (builtins.split (escapeRegex (toString sep)) (toString s));
          in
            map (addContextFrom s) splits;
      
        /* Return a string without the specified prefix, if the prefix matches.
      
           Type: string -> string -> string
      
           Example:
             removePrefix "foo." "foo.bar.baz"
             => "bar.baz"
             removePrefix "xxx" "foo.bar.baz"
             => "foo.bar.baz"
        */
        removePrefix =
          # Prefix to remove if it matches
          prefix:
          # Input string
          str:
          let
            preLen = stringLength prefix;
            sLen = stringLength str;
          in
            if hasPrefix prefix str then
              substring preLen (sLen - preLen) str
            else
              str;
      
        /* Return a string without the specified suffix, if the suffix matches.
      
           Type: string -> string -> string
      
           Example:
             removeSuffix "front" "homefront"
             => "home"
             removeSuffix "xxx" "homefront"
             => "homefront"
        */
        removeSuffix =
          # Suffix to remove if it matches
          suffix:
          # Input string
          str:
          let
            sufLen = stringLength suffix;
            sLen = stringLength str;
          in
            if sufLen <= sLen && suffix == substring (sLen - sufLen) sufLen str then
              substring 0 (sLen - sufLen) str
            else
              str;
      
        /* Return true if string v1 denotes a version older than v2.
      
           Example:
             versionOlder "1.1" "1.2"
             => true
             versionOlder "1.1" "1.1"
             => false
        */
        versionOlder = v1: v2: compareVersions v2 v1 == 1;
      
        /* Return true if string v1 denotes a version equal to or newer than v2.
      
           Example:
             versionAtLeast "1.1" "1.0"
             => true
             versionAtLeast "1.1" "1.1"
             => true
             versionAtLeast "1.1" "1.2"
             => false
        */
        versionAtLeast = v1: v2: !versionOlder v1 v2;
      
        /* This function takes an argument that's either a derivation or a
           derivation's "name" attribute and extracts the name part from that
           argument.
      
           Example:
             getName "youtube-dl-2016.01.01"
             => "youtube-dl"
             getName pkgs.youtube-dl
             => "youtube-dl"
        */
        getName = x:
         let
           parse = drv: (parseDrvName drv).name;
         in if isString x
            then parse x
            else x.pname or (parse x.name);
      
        /* This function takes an argument that's either a derivation or a
           derivation's "name" attribute and extracts the version part from that
           argument.
      
           Example:
             getVersion "youtube-dl-2016.01.01"
             => "2016.01.01"
             getVersion pkgs.youtube-dl
             => "2016.01.01"
        */
        getVersion = x:
         let
           parse = drv: (parseDrvName drv).version;
         in if isString x
            then parse x
            else x.version or (parse x.name);
      
        /* Extract name with version from URL. Ask for separator which is
           supposed to start extension.
      
           Example:
             nameFromURL "https://nixos.org/releases/nix/nix-1.7/nix-1.7-x86_64-linux.tar.bz2" "-"
             => "nix"
             nameFromURL "https://nixos.org/releases/nix/nix-1.7/nix-1.7-x86_64-linux.tar.bz2" "_"
             => "nix-1.7-x86"
        */
        nameFromURL = url: sep:
          let
            components = splitString "/" url;
            filename = lib.last components;
            name = head (splitString sep filename);
          in assert name != filename; name;
      
        /* Create a -D<feature>=<value> string that can be passed to typical Meson
           invocations.
      
          Type: mesonOption :: string -> string -> string
      
           @param feature The feature to be set
           @param value The desired value
      
           Example:
             mesonOption "engine" "opengl"
             => "-Dengine=opengl"
        */
        mesonOption = feature: value:
          assert (lib.isString feature);
          assert (lib.isString value);
          "-D${feature}=${value}";
      
        /* Create a -D<condition>={true,false} string that can be passed to typical
           Meson invocations.
      
          Type: mesonBool :: string -> bool -> string
      
           @param condition The condition to be made true or false
           @param flag The controlling flag of the condition
      
           Example:
             mesonBool "hardened" true
             => "-Dhardened=true"
             mesonBool "static" false
             => "-Dstatic=false"
        */
        mesonBool = condition: flag:
          assert (lib.isString condition);
          assert (lib.isBool flag);
          mesonOption condition (lib.boolToString flag);
      
        /* Create a -D<feature>={enabled,disabled} string that can be passed to
           typical Meson invocations.
      
          Type: mesonEnable :: string -> bool -> string
      
           @param feature The feature to be enabled or disabled
           @param flag The controlling flag
      
           Example:
             mesonEnable "docs" true
             => "-Ddocs=enabled"
             mesonEnable "savage" false
             => "-Dsavage=disabled"
        */
        mesonEnable = feature: flag:
          assert (lib.isString feature);
          assert (lib.isBool flag);
          mesonOption feature (if flag then "enabled" else "disabled");
      
        /* Create an --{enable,disable}-<feat> string that can be passed to
           standard GNU Autoconf scripts.
      
           Example:
             enableFeature true "shared"
             => "--enable-shared"
             enableFeature false "shared"
             => "--disable-shared"
        */
        enableFeature = enable: feat:
          assert isString feat; # e.g. passing openssl instead of "openssl"
          "--${if enable then "enable" else "disable"}-${feat}";
      
        /* Create an --{enable-<feat>=<value>,disable-<feat>} string that can be passed to
           standard GNU Autoconf scripts.
      
           Example:
             enableFeatureAs true "shared" "foo"
             => "--enable-shared=foo"
             enableFeatureAs false "shared" (throw "ignored")
             => "--disable-shared"
        */
        enableFeatureAs = enable: feat: value: enableFeature enable feat + optionalString enable "=${value}";
      
        /* Create an --{with,without}-<feat> string that can be passed to
           standard GNU Autoconf scripts.
      
           Example:
             withFeature true "shared"
             => "--with-shared"
             withFeature false "shared"
             => "--without-shared"
        */
        withFeature = with_: feat:
          assert isString feat; # e.g. passing openssl instead of "openssl"
          "--${if with_ then "with" else "without"}-${feat}";
      
        /* Create an --{with-<feat>=<value>,without-<feat>} string that can be passed to
           standard GNU Autoconf scripts.
      
           Example:
             withFeatureAs true "shared" "foo"
             => "--with-shared=foo"
             withFeatureAs false "shared" (throw "ignored")
             => "--without-shared"
        */
        withFeatureAs = with_: feat: value: withFeature with_ feat + optionalString with_ "=${value}";
      
        /* Create a fixed width string with additional prefix to match
           required width.
      
           This function will fail if the input string is longer than the
           requested length.
      
           Type: fixedWidthString :: int -> string -> string -> string
      
           Example:
             fixedWidthString 5 "0" (toString 15)
             => "00015"
        */
        fixedWidthString = width: filler: str:
          let
            strw = lib.stringLength str;
            reqWidth = width - (lib.stringLength filler);
          in
            assert lib.assertMsg (strw <= width)
              "fixedWidthString: requested string length (${
                toString width}) must not be shorter than actual length (${
                  toString strw})";
            if strw == width then str else filler + fixedWidthString reqWidth filler str;
      
        /* Format a number adding leading zeroes up to fixed width.
      
           Example:
             fixedWidthNumber 5 15
             => "00015"
        */
        fixedWidthNumber = width: n: fixedWidthString width "0" (toString n);
      
        /* Convert a float to a string, but emit a warning when precision is lost
           during the conversion
      
           Example:
             floatToString 0.000001
             => "0.000001"
             floatToString 0.0000001
             => trace: warning: Imprecise conversion from float to string 0.000000
                "0.000000"
        */
        floatToString = float: let
          result = toString float;
          precise = float == fromJSON result;
        in lib.warnIf (!precise) "Imprecise conversion from float to string ${result}"
          result;
      
        /* Soft-deprecated function. While the original implementation is available as
           isConvertibleWithToString, consider using isStringLike instead, if suitable. */
        isCoercibleToString = lib.warnIf (lib.isInOldestRelease 2305)
          "lib.strings.isCoercibleToString is deprecated in favor of either isStringLike or isConvertibleWithToString. Only use the latter if it needs to return true for null, numbers, booleans and list of similarly coercibles."
          isConvertibleWithToString;
      
        /* Check whether a list or other value can be passed to toString.
      
           Many types of value are coercible to string this way, including int, float,
           null, bool, list of similarly coercible values.
        */
        isConvertibleWithToString = x:
          isStringLike x ||
          elem (typeOf x) [ "null" "int" "float" "bool" ] ||
          (isList x && lib.all isConvertibleWithToString x);
      
        /* Check whether a value can be coerced to a string.
           The value must be a string, path, or attribute set.
      
           String-like values can be used without explicit conversion in
           string interpolations and in most functions that expect a string.
         */
        isStringLike = x:
          isString x ||
          isPath x ||
          x ? outPath ||
          x ? __toString;
      
        /* Check whether a value is a store path.
      
           Example:
             isStorePath "/nix/store/d945ibfx9x185xf04b890y4f9g3cbb63-python-2.7.11/bin/python"
             => false
             isStorePath "/nix/store/d945ibfx9x185xf04b890y4f9g3cbb63-python-2.7.11"
             => true
             isStorePath pkgs.python
             => true
             isStorePath [] || isStorePath 42 || isStorePath {} || …
             => false
        */
        isStorePath = x:
          if isStringLike x then
            let str = toString x; in
            substring 0 1 str == "/"
            && dirOf str == storeDir
          else
            false;
      
        /* Parse a string as an int. Does not support parsing of integers with preceding zero due to
        ambiguity between zero-padded and octal numbers. See toIntBase10.
      
           Type: string -> int
      
           Example:
      
             toInt "1337"
             => 1337
      
             toInt "-4"
             => -4
      
             toInt " 123 "
             => 123
      
             toInt "00024"
             => error: Ambiguity in interpretation of 00024 between octal and zero padded integer.
      
             toInt "3.14"
             => error: floating point JSON numbers are not supported
        */
        toInt = str:
          let
            # RegEx: Match any leading whitespace, possibly a '-', one or more digits,
            # and finally match any trailing whitespace.
            strippedInput = match "[[:space:]]*(-?[[:digit:]]+)[[:space:]]*" str;
      
            # RegEx: Match a leading '0' then one or more digits.
            isLeadingZero = match "0[[:digit:]]+" (head strippedInput) == [];
      
            # Attempt to parse input
            parsedInput = fromJSON (head strippedInput);
      
            generalError = "toInt: Could not convert ${escapeNixString str} to int.";
      
            octalAmbigError = "toInt: Ambiguity in interpretation of ${escapeNixString str}"
            + " between octal and zero padded integer.";
      
          in
            # Error on presence of non digit characters.
            if strippedInput == null
            then throw generalError
            # Error on presence of leading zero/octal ambiguity.
            else if isLeadingZero
            then throw octalAmbigError
            # Error if parse function fails.
            else if !isInt parsedInput
            then throw generalError
            # Return result.
            else parsedInput;
      
      
        /* Parse a string as a base 10 int. This supports parsing of zero-padded integers.
      
           Type: string -> int
      
           Example:
             toIntBase10 "1337"
             => 1337
      
             toIntBase10 "-4"
             => -4
      
             toIntBase10 " 123 "
             => 123
      
             toIntBase10 "00024"
             => 24
      
             toIntBase10 "3.14"
             => error: floating point JSON numbers are not supported
        */
        toIntBase10 = str:
          let
            # RegEx: Match any leading whitespace, then match any zero padding,
            # capture possibly a '-' followed by one or more digits,
            # and finally match any trailing whitespace.
            strippedInput = match "[[:space:]]*0*(-?[[:digit:]]+)[[:space:]]*" str;
      
            # RegEx: Match at least one '0'.
            isZero = match "0+" (head strippedInput) == [];
      
            # Attempt to parse input
            parsedInput = fromJSON (head strippedInput);
      
            generalError = "toIntBase10: Could not convert ${escapeNixString str} to int.";
      
          in
            # Error on presence of non digit characters.
            if strippedInput == null
            then throw generalError
            # In the special case zero-padded zero (00000), return early.
            else if isZero
            then 0
            # Error if parse function fails.
            else if !isInt parsedInput
            then throw generalError
            # Return result.
            else parsedInput;
      
        /* Read a list of paths from `file`, relative to the `rootPath`.
           Lines beginning with `#` are treated as comments and ignored.
           Whitespace is significant.
      
           NOTE: This function is not performant and should be avoided.
      
           Example:
             readPathsFromFile /prefix
               ./pkgs/development/libraries/qt-5/5.4/qtbase/series
             => [ "/prefix/dlopen-resolv.patch" "/prefix/tzdir.patch"
                  "/prefix/dlopen-libXcursor.patch" "/prefix/dlopen-openssl.patch"
                  "/prefix/dlopen-dbus.patch" "/prefix/xdg-config-dirs.patch"
                  "/prefix/nix-profiles-library-paths.patch"
                  "/prefix/compose-search-path.patch" ]
        */
        readPathsFromFile = lib.warn "lib.readPathsFromFile is deprecated, use a list instead"
          (rootPath: file:
            let
              lines = lib.splitString "\n" (readFile file);
              removeComments = lib.filter (line: line != "" && !(lib.hasPrefix "#" line));
              relativePaths = removeComments lines;
              absolutePaths = map (path: rootPath + "/${path}") relativePaths;
            in
              absolutePaths);
      
        /* Read the contents of a file removing the trailing \n
      
           Type: fileContents :: path -> string
      
           Example:
             $ echo "1.0" > ./version
      
             fileContents ./version
             => "1.0"
        */
        fileContents = file: removeSuffix "\n" (readFile file);
      
      
        /* Creates a valid derivation name from a potentially invalid one.
      
           Type: sanitizeDerivationName :: String -> String
      
           Example:
             sanitizeDerivationName "../hello.bar # foo"
             => "-hello.bar-foo"
             sanitizeDerivationName ""
             => "unknown"
             sanitizeDerivationName pkgs.hello
             => "-nix-store-2g75chlbpxlrqn15zlby2dfh8hr9qwbk-hello-2.10"
        */
        sanitizeDerivationName =
        let okRegex = match "[[:alnum:]+_?=-][[:alnum:]+._?=-]*";
        in
        string:
        # First detect the common case of already valid strings, to speed those up
        if stringLength string <= 207 && okRegex string != null
        then unsafeDiscardStringContext string
        else lib.pipe string [
          # Get rid of string context. This is safe under the assumption that the
          # resulting string is only used as a derivation name
          unsafeDiscardStringContext
          # Strip all leading "."
          (x: elemAt (match "\\.*(.*)" x) 0)
          # Split out all invalid characters
          # https://github.com/NixOS/nix/blob/2.3.2/src/libstore/store-api.cc#L85-L112
          # https://github.com/NixOS/nix/blob/2242be83c61788b9c0736a92bb0b5c7bbfc40803/nix-rust/src/store/path.rs#L100-L125
          (split "[^[:alnum:]+._?=-]+")
          # Replace invalid character ranges with a "-"
          (concatMapStrings (s: if lib.isList s then "-" else s))
          # Limit to 211 characters (minus 4 chars for ".drv")
          (x: substring (lib.max (stringLength x - 207) 0) (-1) x)
          # If the result is empty, replace it with "unknown"
          (x: if stringLength x == 0 then "unknown" else x)
        ];
      
        /* Computes the Levenshtein distance between two strings.
           Complexity O(n*m) where n and m are the lengths of the strings.
           Algorithm adjusted from https://stackoverflow.com/a/9750974/6605742
      
           Type: levenshtein :: string -> string -> int
      
           Example:
             levenshtein "foo" "foo"
             => 0
             levenshtein "book" "hook"
             => 1
             levenshtein "hello" "Heyo"
             => 3
        */
        levenshtein = a: b: let
          # Two dimensional array with dimensions (stringLength a + 1, stringLength b + 1)
          arr = lib.genList (i:
            lib.genList (j:
              dist i j
            ) (stringLength b + 1)
          ) (stringLength a + 1);
          d = x: y: lib.elemAt (lib.elemAt arr x) y;
          dist = i: j:
            let c = if substring (i - 1) 1 a == substring (j - 1) 1 b
              then 0 else 1;
            in
            if j == 0 then i
            else if i == 0 then j
            else lib.min
              ( lib.min (d (i - 1) j + 1) (d i (j - 1) + 1))
              ( d (i - 1) (j - 1) + c );
        in d (stringLength a) (stringLength b);
      
        /* Returns the length of the prefix common to both strings.
        */
        commonPrefixLength = a: b:
          let
            m = lib.min (stringLength a) (stringLength b);
            go = i: if i >= m then m else if substring i 1 a == substring i 1 b then go (i + 1) else i;
          in go 0;
      
        /* Returns the length of the suffix common to both strings.
        */
        commonSuffixLength = a: b:
          let
            m = lib.min (stringLength a) (stringLength b);
            go = i: if i >= m then m else if substring (stringLength a - i - 1) 1 a == substring (stringLength b - i - 1) 1 b then go (i + 1) else i;
          in go 0;
      
        /* Returns whether the levenshtein distance between two strings is at most some value
           Complexity is O(min(n,m)) for k <= 2 and O(n*m) otherwise
      
           Type: levenshteinAtMost :: int -> string -> string -> bool
      
           Example:
             levenshteinAtMost 0 "foo" "foo"
             => true
             levenshteinAtMost 1 "foo" "boa"
             => false
             levenshteinAtMost 2 "foo" "boa"
             => true
             levenshteinAtMost 2 "This is a sentence" "this is a sentense."
             => false
             levenshteinAtMost 3 "This is a sentence" "this is a sentense."
             => true
      
        */
        levenshteinAtMost = let
          infixDifferAtMost1 = x: y: stringLength x <= 1 && stringLength y <= 1;
      
          # This function takes two strings stripped by their common pre and suffix,
          # and returns whether they differ by at most two by Levenshtein distance.
          # Because of this stripping, if they do indeed differ by at most two edits,
          # we know that those edits were (if at all) done at the start or the end,
          # while the middle has to have stayed the same. This fact is used in the
          # implementation.
          infixDifferAtMost2 = x: y:
            let
              xlen = stringLength x;
              ylen = stringLength y;
              # This function is only called with |x| >= |y| and |x| - |y| <= 2, so
              # diff is one of 0, 1 or 2
              diff = xlen - ylen;
      
              # Infix of x and y, stripped by the left and right most character
              xinfix = substring 1 (xlen - 2) x;
              yinfix = substring 1 (ylen - 2) y;
      
              # x and y but a character deleted at the left or right
              xdelr = substring 0 (xlen - 1) x;
              xdell = substring 1 (xlen - 1) x;
              ydelr = substring 0 (ylen - 1) y;
              ydell = substring 1 (ylen - 1) y;
            in
              # A length difference of 2 can only be gotten with 2 delete edits,
              # which have to have happened at the start and end of x
              # Example: "abcdef" -> "bcde"
              if diff == 2 then xinfix == y
              # A length difference of 1 can only be gotten with a deletion on the
              # right and a replacement on the left or vice versa.
              # Example: "abcdef" -> "bcdez" or "zbcde"
              else if diff == 1 then xinfix == ydelr || xinfix == ydell
              # No length difference can either happen through replacements on both
              # sides, or a deletion on the left and an insertion on the right or
              # vice versa
              # Example: "abcdef" -> "zbcdez" or "bcdefz" or "zabcde"
              else xinfix == yinfix || xdelr == ydell || xdell == ydelr;
      
          in k: if k <= 0 then a: b: a == b else
            let f = a: b:
              let
                alen = stringLength a;
                blen = stringLength b;
                prelen = commonPrefixLength a b;
                suflen = commonSuffixLength a b;
                presuflen = prelen + suflen;
                ainfix = substring prelen (alen - presuflen) a;
                binfix = substring prelen (blen - presuflen) b;
              in
              # Make a be the bigger string
              if alen < blen then f b a
              # If a has over k more characters than b, even with k deletes on a, b can't be reached
              else if alen - blen > k then false
              else if k == 1 then infixDifferAtMost1 ainfix binfix
              else if k == 2 then infixDifferAtMost2 ainfix binfix
              else levenshtein ainfix binfix <= k;
            in f;
      }
    );
    "/Users/jeffhykin/repos/nixpkgs/lib/customisation.nix" = (# "/Users/jeffhykin/repos/nixpkgs/lib/customisation.nix"
      { lib }:
      
      rec {
      
      
        /* `overrideDerivation drv f` takes a derivation (i.e., the result
           of a call to the builtin function `derivation`) and returns a new
           derivation in which the attributes of the original are overridden
           according to the function `f`.  The function `f` is called with
           the original derivation attributes.
      
           `overrideDerivation` allows certain "ad-hoc" customisation
           scenarios (e.g. in ~/.config/nixpkgs/config.nix).  For instance,
           if you want to "patch" the derivation returned by a package
           function in Nixpkgs to build another version than what the
           function itself provides, you can do something like this:
      
             mySed = overrideDerivation pkgs.gnused (oldAttrs: {
               name = "sed-4.2.2-pre";
               src = fetchurl {
                 url = ftp://alpha.gnu.org/gnu/sed/sed-4.2.2-pre.tar.bz2;
                 sha256 = "11nq06d131y4wmf3drm0yk502d2xc6n5qy82cg88rb9nqd2lj41k";
               };
               patches = [];
             });
      
           For another application, see build-support/vm, where this
           function is used to build arbitrary derivations inside a QEMU
           virtual machine.
      
           Note that in order to preserve evaluation errors, the new derivation's
           outPath depends on the old one's, which means that this function cannot
           be used in circular situations when the old derivation also depends on the
           new one.
      
           You should in general prefer `drv.overrideAttrs` over this function;
           see the nixpkgs manual for more information on overriding.
        */
        overrideDerivation = drv: f:
          let
            newDrv = derivation (drv.drvAttrs // (f drv));
          in lib.flip (extendDerivation (builtins.seq drv.drvPath true)) newDrv (
            { meta = drv.meta or {};
              passthru = if drv ? passthru then drv.passthru else {};
            }
            //
            (drv.passthru or {})
            //
            # TODO(@Artturin): remove before release 23.05 and only have __spliced.
            (lib.optionalAttrs (drv ? crossDrv && drv ? nativeDrv) {
              crossDrv = overrideDerivation drv.crossDrv f;
              nativeDrv = overrideDerivation drv.nativeDrv f;
            })
            //
            lib.optionalAttrs (drv ? __spliced) {
              __spliced = {} // (lib.mapAttrs (_: sDrv: overrideDerivation sDrv f) drv.__spliced);
            });
      
      
        /* `makeOverridable` takes a function from attribute set to attribute set and
           injects `override` attribute which can be used to override arguments of
           the function.
      
             nix-repl> x = {a, b}: { result = a + b; }
      
             nix-repl> y = lib.makeOverridable x { a = 1; b = 2; }
      
             nix-repl> y
             { override = «lambda»; overrideDerivation = «lambda»; result = 3; }
      
             nix-repl> y.override { a = 10; }
             { override = «lambda»; overrideDerivation = «lambda»; result = 12; }
      
           Please refer to "Nixpkgs Contributors Guide" section
           "<pkg>.overrideDerivation" to learn about `overrideDerivation` and caveats
           related to its use.
        */
        makeOverridable = f: origArgs:
          let
            result = f origArgs;
      
            # Creates a functor with the same arguments as f
            copyArgs = g: lib.setFunctionArgs g (lib.functionArgs f);
            # Changes the original arguments with (potentially a function that returns) a set of new attributes
            overrideWith = newArgs: origArgs // (if lib.isFunction newArgs then newArgs origArgs else newArgs);
      
            # Re-call the function but with different arguments
            overrideArgs = copyArgs (newArgs: makeOverridable f (overrideWith newArgs));
            # Change the result of the function call by applying g to it
            overrideResult = g: makeOverridable (copyArgs (args: g (f args))) origArgs;
          in
            if builtins.isAttrs result then
              result // {
                override = overrideArgs;
                overrideDerivation = fdrv: overrideResult (x: overrideDerivation x fdrv);
                ${if result ? overrideAttrs then "overrideAttrs" else null} = fdrv:
                  overrideResult (x: x.overrideAttrs fdrv);
              }
            else if lib.isFunction result then
              # Transform the result into a functor while propagating its arguments
              lib.setFunctionArgs result (lib.functionArgs result) // {
                override = overrideArgs;
              }
            else result;
      
      
        /* Call the package function in the file `fn` with the required
          arguments automatically.  The function is called with the
          arguments `args`, but any missing arguments are obtained from
          `autoArgs`.  This function is intended to be partially
          parameterised, e.g.,
      
            callPackage = callPackageWith pkgs;
            pkgs = {
              libfoo = callPackage ./foo.nix { };
              libbar = callPackage ./bar.nix { };
            };
      
          If the `libbar` function expects an argument named `libfoo`, it is
          automatically passed as an argument.  Overrides or missing
          arguments can be supplied in `args`, e.g.
      
            libbar = callPackage ./bar.nix {
              libfoo = null;
              enableX11 = true;
            };
        */
        callPackageWith = autoArgs: fn: args:
          let
            f = if lib.isFunction fn then fn else import fn;
            fargs = lib.functionArgs f;
      
            # All arguments that will be passed to the function
            # This includes automatic ones and ones passed explicitly
            allArgs = builtins.intersectAttrs fargs autoArgs // args;
      
            # A list of argument names that the function requires, but
            # wouldn't be passed to it
            missingArgs = lib.attrNames
              # Filter out arguments that have a default value
              (lib.filterAttrs (name: value: ! value)
              # Filter out arguments that would be passed
              (removeAttrs fargs (lib.attrNames allArgs)));
      
            # Get a list of suggested argument names for a given missing one
            getSuggestions = arg: lib.pipe (autoArgs // args) [
              lib.attrNames
              # Only use ones that are at most 2 edits away. While mork would work,
              # levenshteinAtMost is only fast for 2 or less.
              (lib.filter (lib.strings.levenshteinAtMost 2 arg))
              # Put strings with shorter distance first
              (lib.sort (x: y: lib.strings.levenshtein x arg < lib.strings.levenshtein y arg))
              # Only take the first couple results
              (lib.take 3)
              # Quote all entries
              (map (x: "\"" + x + "\""))
            ];
      
            prettySuggestions = suggestions:
              if suggestions == [] then ""
              else if lib.length suggestions == 1 then ", did you mean ${lib.elemAt suggestions 0}?"
              else ", did you mean ${lib.concatStringsSep ", " (lib.init suggestions)} or ${lib.last suggestions}?";
      
            errorForArg = arg:
              let
                loc = builtins.unsafeGetAttrPos arg fargs;
                # loc' can be removed once lib/minver.nix is >2.3.4, since that includes
                # https://github.com/NixOS/nix/pull/3468 which makes loc be non-null
                loc' = if loc != null then loc.file + ":" + toString loc.line
                  else if ! lib.isFunction fn then
                    toString fn + lib.optionalString (lib.sources.pathIsDirectory fn) "/default.nix"
                  else "<unknown location>";
              in "Function called without required argument \"${arg}\" at "
              + "${loc'}${prettySuggestions (getSuggestions arg)}";
      
            # Only show the error for the first missing argument
            error = errorForArg (lib.head missingArgs);
      
          in if missingArgs == [] then makeOverridable f allArgs else throw error;
      
      
        /* Like callPackage, but for a function that returns an attribute
           set of derivations. The override function is added to the
           individual attributes. */
        callPackagesWith = autoArgs: fn: args:
          let
            f = if lib.isFunction fn then fn else import fn;
            auto = builtins.intersectAttrs (lib.functionArgs f) autoArgs;
            origArgs = auto // args;
            pkgs = f origArgs;
            mkAttrOverridable = name: _: makeOverridable (newArgs: (f newArgs).${name}) origArgs;
          in
            if lib.isDerivation pkgs then throw
              ("function `callPackages` was called on a *single* derivation "
                + ''"${pkgs.name or "<unknown-name>"}";''
                + " did you mean to use `callPackage` instead?")
            else lib.mapAttrs mkAttrOverridable pkgs;
      
      
        /* Add attributes to each output of a derivation without changing
           the derivation itself and check a given condition when evaluating. */
        extendDerivation = condition: passthru: drv:
          let
            outputs = drv.outputs or [ "out" ];
      
            commonAttrs = drv // (builtins.listToAttrs outputsList) //
              ({ all = map (x: x.value) outputsList; }) // passthru;
      
            outputToAttrListElement = outputName:
              { name = outputName;
                value = commonAttrs // {
                  inherit (drv.${outputName}) type outputName;
                  outputSpecified = true;
                  drvPath = assert condition; drv.${outputName}.drvPath;
                  outPath = assert condition; drv.${outputName}.outPath;
                };
              };
      
            outputsList = map outputToAttrListElement outputs;
          in commonAttrs // {
            drvPath = assert condition; drv.drvPath;
            outPath = assert condition; drv.outPath;
          };
      
        /* Strip a derivation of all non-essential attributes, returning
           only those needed by hydra-eval-jobs. Also strictly evaluate the
           result to ensure that there are no thunks kept alive to prevent
           garbage collection. */
        hydraJob = drv:
          let
            outputs = drv.outputs or ["out"];
      
            commonAttrs =
              { inherit (drv) name system meta; inherit outputs; }
              // lib.optionalAttrs (drv._hydraAggregate or false) {
                _hydraAggregate = true;
                constituents = map hydraJob (lib.flatten drv.constituents);
              }
              // (lib.listToAttrs outputsList);
      
            makeOutput = outputName:
              let output = drv.${outputName}; in
              { name = outputName;
                value = commonAttrs // {
                  outPath = output.outPath;
                  drvPath = output.drvPath;
                  type = "derivation";
                  inherit outputName;
                };
              };
      
            outputsList = map makeOutput outputs;
      
            drv' = (lib.head outputsList).value;
          in lib.deepSeq drv' drv';
      
        /* Make a set of packages with a common scope. All packages called
           with the provided `callPackage` will be evaluated with the same
           arguments. Any package in the set may depend on any other. The
           `overrideScope'` function allows subsequent modification of the package
           set in a consistent way, i.e. all packages in the set will be
           called with the overridden packages. The package sets may be
           hierarchical: the packages in the set are called with the scope
           provided by `newScope` and the set provides a `newScope` attribute
           which can form the parent scope for later package sets. */
        makeScope = newScope: f:
          let self = f self // {
                newScope = scope: newScope (self // scope);
                callPackage = self.newScope {};
                overrideScope = g: lib.warn
                  "`overrideScope` (from `lib.makeScope`) is deprecated. Do `overrideScope' (self: super: { … })` instead of `overrideScope (super: self: { … })`. All other overrides have the parameters in that order, including other definitions of `overrideScope`. This was the only definition violating the pattern."
                  (makeScope newScope (lib.fixedPoints.extends (lib.flip g) f));
                overrideScope' = g: makeScope newScope (lib.fixedPoints.extends g f);
                packages = f;
              };
          in self;
      
        /* Like the above, but aims to support cross compilation. It's still ugly, but
           hopefully it helps a little bit. */
        makeScopeWithSplicing = splicePackages: newScope: otherSplices: keep: extra: f:
          let
            spliced0 = splicePackages {
              pkgsBuildBuild = otherSplices.selfBuildBuild;
              pkgsBuildHost = otherSplices.selfBuildHost;
              pkgsBuildTarget = otherSplices.selfBuildTarget;
              pkgsHostHost = otherSplices.selfHostHost;
              pkgsHostTarget = self; # Not `otherSplices.selfHostTarget`;
              pkgsTargetTarget = otherSplices.selfTargetTarget;
            };
            spliced = extra spliced0 // spliced0 // keep self;
            self = f self // {
              newScope = scope: newScope (spliced // scope);
              callPackage = newScope spliced; # == self.newScope {};
              # N.B. the other stages of the package set spliced in are *not*
              # overridden.
              overrideScope = g: makeScopeWithSplicing
                splicePackages
                newScope
                otherSplices
                keep
                extra
                (lib.fixedPoints.extends g f);
              packages = f;
            };
          in self;
      
      }
    );
    "/Users/jeffhykin/repos/nixpkgs/lib/derivations.nix" = (# "/Users/jeffhykin/repos/nixpkgs/lib/derivations.nix"
      { lib }:
      
      let
        inherit (lib) throwIfNot;
      in
      {
        /*
          Restrict a derivation to a predictable set of attribute names, so
          that the returned attrset is not strict in the actual derivation,
          saving a lot of computation when the derivation is non-trivial.
      
          This is useful in situations where a derivation might only be used for its
          passthru attributes, improving evaluation performance.
      
          The returned attribute set is lazy in `derivation`. Specifically, this
          means that the derivation will not be evaluated in at least the
          situations below.
      
          For illustration and/or testing, we define derivation such that its
          evaluation is very noticeable.
      
              let derivation = throw "This won't be evaluated.";
      
          In the following expressions, `derivation` will _not_ be evaluated:
      
              (lazyDerivation { inherit derivation; }).type
      
              attrNames (lazyDerivation { inherit derivation; })
      
              (lazyDerivation { inherit derivation; } // { foo = true; }).foo
      
              (lazyDerivation { inherit derivation; meta.foo = true; }).meta
      
          In these expressions, it `derivation` _will_ be evaluated:
      
              "${lazyDerivation { inherit derivation }}"
      
              (lazyDerivation { inherit derivation }).outPath
      
              (lazyDerivation { inherit derivation }).meta
      
          And the following expressions are not valid, because the refer to
          implementation details and/or attributes that may not be present on
          some derivations:
      
              (lazyDerivation { inherit derivation }).buildInputs
      
              (lazyDerivation { inherit derivation }).passthru
      
              (lazyDerivation { inherit derivation }).pythonPath
      
        */
        lazyDerivation =
          args@{
            # The derivation to be wrapped.
            derivation
          , # Optional meta attribute.
            #
            # While this function is primarily about derivations, it can improve
            # the `meta` package attribute, which is usually specified through
            # `mkDerivation`.
            meta ? null
          , # Optional extra values to add to the returned attrset.
            #
            # This can be used for adding package attributes, such as `tests`.
            passthru ? { }
          }:
          let
            # These checks are strict in `drv` and some `drv` attributes, but the
            # attrset spine returned by lazyDerivation does not depend on it.
            # Instead, the individual derivation attributes do depend on it.
            checked =
              throwIfNot (derivation.type or null == "derivation")
                "lazySimpleDerivation: input must be a derivation."
                throwIfNot
                (derivation.outputs == [ "out" ])
                # Supporting multiple outputs should be a matter of inheriting more attrs.
                "The derivation ${derivation.name or "<unknown>"} has multiple outputs. This is not supported by lazySimpleDerivation yet. Support could be added, and be useful as long as the set of outputs is known in advance, without evaluating the actual derivation."
                derivation;
          in
          {
            # Hardcoded `type`
            #
            # `lazyDerivation` requires its `derivation` argument to be a derivation,
            # so if it is not, that is a programming error by the caller and not
            # something that `lazyDerivation` consumers should be able to correct
            # for after the fact.
            # So, to improve laziness, we assume correctness here and check it only
            # when actual derivation values are accessed later.
            type = "derivation";
      
            # A fixed set of derivation values, so that `lazyDerivation` can return
            # its attrset before evaluating `derivation`.
            # This must only list attributes that are available on _all_ derivations.
            inherit (checked) outputs out outPath outputName drvPath name system;
      
            # The meta attribute can either be taken from the derivation, or if the
            # `lazyDerivation` caller knew a shortcut, be taken from there.
            meta = args.meta or checked.meta;
          } // passthru;
      }
    );
    "/Users/jeffhykin/repos/nixpkgs/maintainers/maintainer-list.nix" = (# "/Users/jeffhykin/repos/nixpkgs/maintainers/maintainer-list.nix"
      /* List of NixOS maintainers.
          ```nix
          handle = {
            # Required
            name = "Your name";
            email = "address@example.org";
      
            # Optional
            matrix = "@user:example.org";
            github = "GithubUsername";
            githubId = your-github-id;
            keys = [{
              fingerprint = "AAAA BBBB CCCC DDDD EEEE  FFFF 0000 1111 2222 3333";
            }];
          };
          ```
      
          where
      
          - `handle` is the handle you are going to use in nixpkgs expressions,
          - `name` is your, preferably real, name,
          - `email` is your maintainer email address,
          - `matrix` is your Matrix user ID,
          - `github` is your GitHub handle (as it appears in the URL of your profile page, `https://github.com/<userhandle>`),
          - `githubId` is your GitHub user ID, which can be found at `https://api.github.com/users/<userhandle>`,
          - `keys` is a list of your PGP/GPG key fingerprints.
      
          `handle == github` is strongly preferred whenever `github` is an acceptable attribute name and is short and convenient.
      
          If `github` begins with a numeral, `handle` should be prefixed with an underscore.
          ```nix
          _1example = {
            github = "1example";
          };
          ```
      
          Add PGP/GPG keys only if you actually use them to sign commits and/or mail.
      
          To get the required PGP/GPG values for a key run
          ```shell
          gpg --fingerprint <email> | head -n 2
          ```
      
          !!! Note that PGP/GPG values stored here are for informational purposes only, don't use this file as a source of truth.
      
          More fields may be added in the future, however, in order to comply with GDPR this file should stay as minimal as possible.
      
          When editing this file:
           * keep the list alphabetically sorted
           * test the validity of the format with:
               nix-build lib/tests/maintainers.nix
      
          See `./scripts/check-maintainer-github-handles.sh` for an example on how to work with this data.
      */
      {
        _0qq = {
          email = "0qqw0qqw@gmail.com";
          github = "0qq";
          githubId = 64707304;
          name = "Dmitry Kulikov";
        };
        _0x4A6F = {
          email = "mail-maintainer@0x4A6F.dev";
          matrix = "@0x4a6f:matrix.org";
          name = "Joachim Ernst";
          github = "0x4A6F";
          githubId = 9675338;
          keys = [{
            fingerprint = "F466 A548 AD3F C1F1 8C88  4576 8702 7528 B006 D66D";
          }];
        };
        _0xB10C = {
          email = "nixpkgs@b10c.me";
          name = "0xB10C";
          github = "0xb10c";
          githubId = 19157360;
        };
        _0xbe7a = {
          email = "nix@be7a.de";
          name = "Bela Stoyan";
          github = "0xbe7a";
          githubId = 6232980;
          keys = [{
            fingerprint = "2536 9E86 1AA5 9EB7 4C47  B138 6510 870A 77F4 9A99";
          }];
        };
        _0xC45 = {
          email = "jason@0xc45.com";
          name = "Jason Vigil";
          github = "0xC45";
          githubId = 56617252;
          matrix = "@oxc45:matrix.org";
        };
        _0xd61 = {
          email = "dgl@degit.co";
          name = "Daniel Glinka";
          github = "0xd61";
          githubId = 8351869;
        };
        _1000101 = {
          email = "b1000101@pm.me";
          github = "1000101";
          githubId = 791309;
          name = "Jan Hrnko";
        };
        _1000teslas = {
          name = "Kevin Tran";
          email = "47207223+1000teslas@users.noreply.github.com";
          github = "1000teslas";
          githubId = 47207223;
        };
        _2gn = {
          name = "Hiram Tanner";
          email = "101851090+2gn@users.noreply.github.com";
          github = "2gn";
          githubId = 101851090;
        };
        _3699n = {
          email = "nicholas@nvk.pm";
          github = "3699n";
          githubId = 7414843;
          name = "Nicholas von Klitzing";
        };
        _3JlOy-PYCCKUi = {
          name = "3JlOy-PYCCKUi";
          email = "3jl0y_pycckui@riseup.net";
          github = "3JlOy-PYCCKUi";
          githubId = 46464602;
        };
        _360ied = {
          name = "Brian Zhu";
          email = "therealbarryplayer@gmail.com";
          github = "360ied";
          githubId = 19516527;
        };
        _13r0ck = {
          name = "Brock Szuszczewicz";
          email = "bnr@tuta.io";
          github = "13r0ck";
          githubId = 58987761;
        };
        _3noch = {
          email = "eacameron@gmail.com";
          github = "3noch";
          githubId = 882455;
          name = "Elliot Cameron";
        };
        _414owen = {
          email = "owen@owen.cafe";
          github = "414owen";
          githubId = 1714287;
          name = "Owen Shepherd";
        };
        _4825764518 = {
          email = "4825764518@purelymail.com";
          matrix = "@kenzie:matrix.kenzi.dev";
          github = "4825764518";
          githubId = 100122841;
          name = "Kenzie";
          keys = [{
            fingerprint = "D292 365E 3C46 A5AA 75EE  B30B 78DB 7EDE 3540 794B";
          }];
        };
        _6AA4FD = {
          email = "f6442954@gmail.com";
          github = "6AA4FD";
          githubId = 12578560;
          name = "Quinn Bohner";
        };
        a1russell = {
          email = "adamlr6+pub@gmail.com";
          github = "a1russell";
          githubId = 241628;
          name = "Adam Russell";
        };
        aacebedo = {
          email = "alexandre@acebedo.fr";
          github = "aacebedo";
          githubId = 1217680;
          name = "Alexandre Acebedo";
        };
        aadibajpai = {
          email = "hello@aadibajpai.com";
          github = "aadibajpai";
          githubId = 27063113;
          name = "Aadi Bajpai";
        };
        aanderse = {
          email = "aaron@fosslib.net";
          matrix = "@aanderse:nixos.dev";
          github = "aanderse";
          githubId = 7755101;
          name = "Aaron Andersen";
        };
        aaqaishtyaq = {
          email = "aaqaishtyaq@gmail.com";
          github = "aaqaishtyaq";
          githubId = 22131756;
          name = "Aaqa Ishtyaq";
        };
        aaronjanse = {
          email = "aaron@ajanse.me";
          matrix = "@aaronjanse:matrix.org";
          github = "aaronjanse";
          githubId = 16829510;
          name = "Aaron Janse";
        };
        aaronjheng = {
          email = "wentworth@outlook.com";
          github = "aaronjheng";
          githubId = 806876;
          name = "Aaron Jheng";
        };
        aaronschif = {
          email = "aaronschif@gmail.com";
          github = "aaronschif";
          githubId = 2258953;
          name = "Aaron Schif";
        };
        aaschmid = {
          email = "service@aaschmid.de";
          github = "aaschmid";
          githubId = 567653;
          name = "Andreas Schmid";
        };
        abaldeau = {
          email = "andreas@baldeau.net";
          github = "baldo";
          githubId = 178750;
          name = "Andreas Baldeau";
        };
        abathur = {
          email = "travis.a.everett+nixpkgs@gmail.com";
          github = "abathur";
          githubId = 2548365;
          name = "Travis A. Everett";
        };
        abbe = {
          email = "ashish.is@lostca.se";
          matrix = "@abbe:badti.me";
          github = "wahjava";
          githubId = 2255192;
          name = "Ashish SHUKLA";
          keys = [{
            fingerprint = "F682 CDCC 39DC 0FEA E116  20B6 C746 CFA9 E74F A4B0";
          }];
        };
        abbradar = {
          email = "ab@fmap.me";
          github = "abbradar";
          githubId = 1174810;
          name = "Nikolay Amiantov";
        };
        abhi18av = {
          email = "abhi18av@gmail.com";
          github = "abhi18av";
          githubId = 12799326;
          name = "Abhinav Sharma";
        };
        abigailbuccaneer = {
          email = "abigailbuccaneer@gmail.com";
          github = "AbigailBuccaneer";
          githubId = 908758;
          name = "Abigail Bunyan";
        };
        aborsu = {
          email = "a.borsu@gmail.com";
          github = "aborsu";
          githubId = 5033617;
          name = "Augustin Borsu";
        };
        aboseley = {
          email = "adam.boseley@gmail.com";
          github = "aboseley";
          githubId = 13504599;
          name = "Adam Boseley";
        };
        abuibrahim = {
          email = "ruslan@babayev.com";
          github = "abuibrahim";
          githubId = 2321000;
          name = "Ruslan Babayev";
        };
        acairncross = {
          email = "acairncross@gmail.com";
          github = "acairncross";
          githubId = 1517066;
          name = "Aiken Cairncross";
        };
        aciceri = {
          name = "Andrea Ciceri";
          email = "andrea.ciceri@autistici.org";
          github = "aciceri";
          githubId = 2318843;
        };
        acowley = {
          email = "acowley@gmail.com";
          github = "acowley";
          githubId = 124545;
          name = "Anthony Cowley";
        };
        adamcstephens = {
          email = "happy.plan4249@valkor.net";
          matrix = "@adam:valkor.net";
          github = "adamcstephens";
          githubId = 2071575;
          name = "Adam C. Stephens";
        };
        adamlwgriffiths = {
          email = "adam.lw.griffiths@gmail.com";
          github = "adamlwgriffiths";
          githubId = 1239156;
          name = "Adam Griffiths";
        };
        adamt = {
          email = "mail@adamtulinius.dk";
          github = "adamtulinius";
          githubId = 749381;
          name = "Adam Tulinius";
        };
        adelbertc = {
          email = "adelbertc@gmail.com";
          github = "adelbertc";
          githubId = 1332980;
          name = "Adelbert Chang";
        };
        adev = {
          email = "adev@adev.name";
          github = "adevress";
          githubId = 1773511;
          name = "Adrien Devresse";
        };
        addict3d = {
          email = "nickbathum@gmail.com";
          matrix = "@nbathum:matrix.org";
          github = "addict3d";
          githubId = 49227;
          name = "Nick Bathum";
        };
        adisbladis = {
          email = "adisbladis@gmail.com";
          matrix = "@adis:blad.is";
          github = "adisbladis";
          githubId = 63286;
          name = "Adam Hose";
        };
        Adjective-Object = {
          email = "mhuan13@gmail.com";
          github = "Adjective-Object";
          githubId = 1174858;
          name = "Maxwell Huang-Hobbs";
        };
        adjacentresearch = {
          email = "nate@adjacentresearch.xyz";
          github = "0xperp";
          githubId = 96147421;
          name = "0xperp";
        };
        adnelson = {
          email = "ithinkican@gmail.com";
          github = "adnelson";
          githubId = 5091511;
          name = "Allen Nelson";
        };
        adolfogc = {
          email = "adolfo.garcia.cr@gmail.com";
          github = "adolfogc";
          githubId = 1250775;
          name = "Adolfo E. García Castro";
        };
        AdsonCicilioti = {
          name = "Adson Cicilioti";
          email = "adson.cicilioti@live.com";
          github = "AdsonCicilioti";
          githubId = 6278398;
        };
        adsr = {
          email = "as@php.net";
          github = "adsr";
          githubId = 315003;
          name = "Adam Saponara";
        };
        aerialx = {
          email = "aaron+nixos@aaronlindsay.com";
          github = "AerialX";
          githubId = 117295;
          name = "Aaron Lindsay";
        };
        aespinosa = {
          email = "allan.espinosa@outlook.com";
          github = "aespinosa";
          githubId = 58771;
          name = "Allan Espinosa";
        };
        aethelz = {
          email = "aethelz@protonmail.com";
          github = "eugenezastrogin";
          githubId = 10677343;
          name = "Eugene";
        };
        afh = {
          email = "surryhill+nix@gmail.com";
          github = "afh";
          githubId = 16507;
          name = "Alexis Hildebrandt";
        };
        aflatter = {
          email = "flatter@fastmail.fm";
          github = "aflatter";
          githubId = 168;
          name = "Alexander Flatter";
        };
        afldcr = {
          email = "alex@fldcr.com";
          github = "afldcr";
          githubId = 335271;
          name = "James Alexander Feldman-Crough";
        };
        afontain = {
          email = "antoine.fontaine@epfl.ch";
          github = "necessarily-equal";
          githubId = 59283660;
          name = "Antoine Fontaine";
        };
        aforemny = {
          email = "aforemny@posteo.de";
          github = "aforemny";
          githubId = 610962;
          name = "Alexander Foremny";
        };
        afranchuk = {
          email = "alex.franchuk@gmail.com";
          github = "afranchuk";
          githubId = 4296804;
          name = "Alex Franchuk";
        };
        agbrooks = {
          email = "andrewgrantbrooks@gmail.com";
          github = "agbrooks";
          githubId = 19290901;
          name = "Andrew Brooks";
        };
        aherrmann = {
          email = "andreash87@gmx.ch";
          github = "aherrmann";
          githubId = 732652;
          name = "Andreas Herrmann";
        };
        ahrzb = {
          email = "ahrzb5@gmail.com";
          github = "ahrzb";
          githubId = 5220438;
          name = "AmirHossein Roozbahani";
        };
        ahuzik = {
          email = "ah1990au@gmail.com";
          github = "alesya-h";
          githubId = 209175;
          name = "Alesya Huzik";
        };
        aidalgol = {
          email = "aidalgol+nixpkgs@fastmail.net";
          github = "aidalgol";
          githubId = 2313201;
          name = "Aidan Gauland";
        };
        aij = {
          email = "aij+git@mrph.org";
          github = "aij";
          githubId = 4732885;
          name = "Ivan Jager";
        };
        aiotter = {
          email = "git@aiotter.com";
          github = "aiotter";
          githubId = 37664775;
          name = "Yuto Oguchi";
        };
        airwoodix = {
          email = "airwoodix@posteo.me";
          github = "airwoodix";
          githubId = 44871469;
          name = "Etienne Wodey";
        };
        ajs124 = {
          email = "nix@ajs124.de";
          matrix = "@andreas.schraegle:helsinki-systems.de";
          github = "ajs124";
          githubId = 1229027;
          name = "Andreas Schrägle";
        };
        ajgrf = {
          email = "a@ajgrf.com";
          github = "ajgrf";
          githubId = 10733175;
          name = "Alex Griffin";
        };
        ak = {
          email = "ak@formalprivacy.com";
          github = "alexanderkjeldaas";
          githubId = 339369;
          name = "Alexander Kjeldaas";
        };
        akavel = {
          email = "czapkofan@gmail.com";
          github = "akavel";
          githubId = 273837;
          name = "Mateusz Czapliński";
        };
        akamaus = {
          email = "dmitryvyal@gmail.com";
          github = "akamaus";
          githubId = 58955;
          name = "Dmitry Vyal";
        };
        akaWolf = {
          email = "akawolf0@gmail.com";
          github = "akaWolf";
          githubId = 5836586;
          name = "Artjom Vejsel";
        };
        akc = {
          email = "akc@akc.is";
          github = "akc";
          githubId = 1318982;
          name = "Anders Claesson";
        };
        akho = {
          name = "Alexander Khodyrev";
          email = "a@akho.name";
          github = "akho";
          githubId = 104951;
        };
        akkesm = {
          name = "Alessandro Barenghi";
          email = "alessandro.barenghi@tuta.io";
          github = "akkesm";
          githubId = 56970006;
          keys = [{
            fingerprint = "50E2 669C AB38 2F4A 5F72  1667 0D6B FC01 D45E DADD";
          }];
        };
        akru = {
          email = "mail@akru.me";
          github = "akru";
          githubId = 786394;
          name = "Alexander Krupenkin ";
        };
        akshgpt7 = {
          email = "akshgpt7@gmail.com";
          github = "akshgpt7";
          githubId = 20405311;
          name = "Aksh Gupta";
        };
        alapshin = {
          email = "alapshin@fastmail.com";
          github = "alapshin";
          githubId = 321946;
          name = "Andrei Lapshin";
        };
        albakham = {
          email = "dev@geber.ga";
          github = "albakham";
          githubId = 43479487;
          name = "Titouan Biteau";
        };
        alekseysidorov = {
          email = "sauron1987@gmail.com";
          github = "alekseysidorov";
          githubId = 83360;
          name = "Aleksey Sidorov";
        };
        alerque = {
          email = "caleb@alerque.com";
          github = "alerque";
          githubId = 173595;
          name = "Caleb Maclennan";
        };
        ALEX11BR = {
          email = "alexioanpopa11@gmail.com";
          github = "ALEX11BR";
          githubId = 49609151;
          name = "Popa Ioan Alexandru";
        };
        alexarice = {
          email = "alexrice999@hotmail.co.uk";
          github = "alexarice";
          githubId = 17208985;
          name = "Alex Rice";
        };
        alexbakker = {
          email = "ab@alexbakker.me";
          github = "alexbakker";
          githubId = 2387841;
          name = "Alexander Bakker";
        };
        alexbiehl = {
          email = "alexbiehl@gmail.com";
          github = "alexbiehl";
          githubId = 1876617;
          name = "Alex Biehl";
        };
        alexchapman = {
          email = "alex@farfromthere.net";
          github = "AJChapman";
          githubId = 8316672;
          name = "Alex Chapman";
        };
        alexfmpe = {
          email = "alexandre.fmp.esteves@gmail.com";
          github = "alexfmpe";
          githubId = 2335822;
          name = "Alexandre Esteves";
        };
        alexnortung = {
          name = "alexnortung";
          email = "alex_nortung@live.dk";
          github = "Alexnortung";
          githubId = 1552267;
        };
        alexshpilkin = {
          email = "ashpilkin@gmail.com";
          github = "alexshpilkin";
          githubId = 1010468;
          keys = [{
            fingerprint = "B595 D74D 6615 C010 469F  5A13 73E9 AA11 4B3A 894B";
          }];
          matrix = "@alexshpilkin:matrix.org";
          name = "Alexander Shpilkin";
        };
        alexvorobiev = {
          email = "alexander.vorobiev@gmail.com";
          github = "alexvorobiev";
          githubId = 782180;
          name = "Alex Vorobiev";
        };
        alexwinter = {
          email = "git@alexwinter.net";
          github = "lxwntr";
          githubId = 50754358;
          name = "Alex Winter";
        };
        alexeyre = {
          email = "A.Eyre@sms.ed.ac.uk";
          github = "alexeyre";
          githubId = 38869148;
          name = "Alex Eyre";
        };
        algram = {
          email = "aliasgram@gmail.com";
          github = "Algram";
          githubId = 5053729;
          name = "Alias Gram";
        };
        alibabzo = {
          email = "alistair.bill@gmail.com";
          github = "alistairbill";
          githubId = 2822871;
          name = "Alistair Bill";
        };
        alirezameskin = {
          email = "alireza.meskin@gmail.com";
          github = "alirezameskin";
          githubId = 36147;
          name = "Alireza Meskin";
        };
        alkasm = {
          email = "alexreynolds00@gmail.com";
          github = "alkasm";
          githubId = 9651002;
          name = "Alexander Reynolds";
        };
        alkeryn = {
          email = "plbraundev@gmail.com";
          github = "alkeryn";
          githubId = 11599075;
          name = "Pierre-Louis Braun";
        };
        allonsy = {
          email = "linuxbash8@gmail.com";
          github = "allonsy";
          githubId = 5892756;
          name = "Alec Snyder";
        };
        AluisioASG = {
          name = "Aluísio Augusto Silva Gonçalves";
          email = "aluisio@aasg.name";
          github = "AluisioASG";
          githubId = 1904165;
          keys = [{
            fingerprint = "7FDB 17B3 C29B 5BA6 E5A9  8BB2 9FAA 63E0 9750 6D9D";
          }];
        };
        almac = {
          email = "alma.cemerlic@gmail.com";
          github = "a1mac";
          githubId = 60479013;
          name = "Alma Cemerlic";
        };
        alternateved = {
          email = "alternateved@pm.me";
          github = "alternateved";
          githubId = 45176912;
          name = "Tomasz Hołubowicz";
        };
        alunduil = {
          email = "alunduil@gmail.com";
          github = "alunduil";
          githubId = 169249;
          name = "Alex Brandt";
        };
        alva = {
          email = "alva@skogen.is";
          github = "illfygli";
          githubId = 42881386;
          name = "Alva";
          keys = [{
            fingerprint = "B422 CFB1 C9EF 73F7 E1E2 698D F53E 3233 42F7 A6D3A";
          }];
        };
        alyaeanyx = {
          email = "alexandra.hollmeier@mailbox.org";
          github = "alyaeanyx";
          githubId = 74795488;
          name = "Alexandra Hollmeier";
          keys = [{
            fingerprint = "1F73 8879 5E5A 3DFC E2B3 FA32 87D1 AADC D25B 8DEE";
          }];
        };
        amanjeev = {
          email = "aj@amanjeev.com";
          github = "amanjeev";
          githubId = 160476;
          name = "Amanjeev Sethi";
        };
        amar1729 = {
          email = "amar.paul16@gmail.com";
          github = "Amar1729";
          githubId = 15623522;
          name = "Amar Paul";
        };
        amarshall = {
          email = "andrew@johnandrewmarshall.com";
          github = "amarshall";
          githubId = 153175;
          name = "Andrew Marshall";
        };
        ambroisie = {
          email = "bruno.nixpkgs@belanyi.fr";
          github = "ambroisie";
          githubId = 12465195;
          name = "Bruno BELANYI";
        };
        ambrop72 = {
          email = "ambrop7@gmail.com";
          github = "ambrop72";
          githubId = 2626481;
          name = "Ambroz Bizjak";
        };
        amesgen = {
          email = "amesgen@amesgen.de";
          github = "amesgen";
          githubId = 15369874;
          name = "Alexander Esgen";
          matrix = "@amesgen:amesgen.de";
        };
        ametrine = {
          name = "Matilde Ametrine";
          email = "matilde@diffyq.xyz";
          github = "matilde-ametrine";
          githubId = 90799677;
          keys = [{
            fingerprint = "7931 EB4E 4712 D7BE 04F8  6D34 07EE 1FFC A58A 11C5";
          }];
        };
        amfl = {
          email = "amfl@none.none";
          github = "amfl";
          githubId = 382798;
          name = "amfl";
        };
        amiddelk = {
          email = "amiddelk@gmail.com";
          github = "amiddelk";
          githubId = 1358320;
          name = "Arie Middelkoop";
        };
        amiloradovsky = {
          email = "miloradovsky@gmail.com";
          github = "amiloradovsky";
          githubId = 20530052;
          name = "Andrew Miloradovsky";
        };
        notbandali = {
          name = "Amin Bandali";
          email = "bandali@gnu.org";
          github = "notbandali";
          githubId = 1254858;
          keys = [{
            fingerprint = "BE62 7373 8E61 6D6D 1B3A  08E8 A21A 0202 4881 6103";
          }];
        };
        aminechikhaoui = {
          email = "amine.chikhaoui91@gmail.com";
          github = "AmineChikhaoui";
          githubId = 5149377;
          name = "Amine Chikhaoui";
        };
        amorsillo = {
          email = "andrew.morsillo@gmail.com";
          github = "evelant";
          githubId = 858965;
          name = "Andrew Morsillo";
        };
        an-empty-string = {
          name = "Tris Emmy Wilson";
          email = "tris@tris.fyi";
          github = "an-empty-string";
          githubId = 681716;
        };
        AnatolyPopov = {
          email = "aipopov@live.ru";
          github = "AnatolyPopov";
          githubId = 2312534;
          name = "Anatolii Popov";
        };
        andehen = {
          email = "git@andehen.net";
          github = "andehen";
          githubId = 754494;
          name = "Anders Asheim Hennum";
        };
        andersk = {
          email = "andersk@mit.edu";
          github = "andersk";
          githubId = 26471;
          name = "Anders Kaseorg";
        };
        anderslundstedt = {
          email = "git@anderslundstedt.se";
          github = "anderslundstedt";
          githubId = 4514101;
          name = "Anders Lundstedt";
        };
        AndersonTorres = {
          email = "torres.anderson.85@protonmail.com";
          matrix = "@anderson_torres:matrix.org";
          github = "AndersonTorres";
          githubId = 5954806;
          name = "Anderson Torres";
        };
        anderspapitto = {
          email = "anderspapitto@gmail.com";
          github = "anderspapitto";
          githubId = 1388690;
          name = "Anders Papitto";
        };
        andir = {
          email = "andreas@rammhold.de";
          github = "andir";
          githubId = 638836;
          name = "Andreas Rammhold";
        };
        andreasfelix = {
          email = "fandreas@physik.hu-berlin.de";
          github = "andreasfelix";
          githubId = 24651767;
          name = "Felix Andreas";
        };
        andres = {
          email = "ksnixos@andres-loeh.de";
          github = "kosmikus";
          githubId = 293191;
          name = "Andres Loeh";
        };
        andresilva = {
          email = "andre.beat@gmail.com";
          github = "andresilva";
          githubId = 123550;
          name = "André Silva";
        };
        andrestylianos = {
          email = "andre.stylianos@gmail.com";
          github = "andrestylianos";
          githubId = 7112447;
          name = "Andre S. Ramos";
        };
        andrevmatos = {
          email = "andrevmatos@gmail.com";
          github = "andrevmatos";
          githubId = 587021;
          name = "André V L Matos";
        };
        andrew-d = {
          email = "andrew@du.nham.ca";
          github = "andrew-d";
          githubId = 1079173;
          name = "Andrew Dunham";
        };
        andrewchambers = {
          email = "ac@acha.ninja";
          github = "andrewchambers";
          githubId = 962885;
          name = "Andrew Chambers";
        };
        andrewrk = {
          email = "superjoe30@gmail.com";
          github = "andrewrk";
          githubId = 106511;
          name = "Andrew Kelley";
        };
        andsild = {
          email = "andsild@gmail.com";
          github = "andsild";
          githubId = 3808928;
          name = "Anders Sildnes";
        };
        andys8 = {
          email = "andys8@users.noreply.github.com";
          github = "andys8";
          githubId = 13085980;
          name = "Andy";
        };
        aneeshusa = {
          email = "aneeshusa@gmail.com";
          github = "aneeshusa";
          githubId = 2085567;
          name = "Aneesh Agrawal";
        };
        angristan = {
          email = "angristan@pm.me";
          github = "angristan";
          githubId = 11699655;
          name = "Stanislas Lange";
        };
        AngryAnt = {
          name = "Emil Johansen";
          email = "git@eej.dk";
          matrix = "@angryant:envs.net";
          github = "AngryAnt";
          githubId = 102513;
          keys = [{
            fingerprint = "B7B7 582E 564E 789B FCB8  71AB 0C6D FE2F B234 534A";
          }];
        };
        anhdle14 = {
          name = "Le Anh Duc";
          email = "anhdle14@icloud.com";
          github = "anhdle14";
          githubId = 9645992;
          keys = [{
            fingerprint = "AA4B 8EC3 F971 D350 482E  4E20 0299 AFF9 ECBB 5169";
          }];
        };
        anhduy = {
          email = "vo@anhduy.io";
          github = "voanhduy1512";
          githubId = 1771266;
          name = "Vo Anh Duy";
        };
        Anillc = {
          name = "Anillc";
          email = "i@anillc.cn";
          github = "Anillc";
          githubId = 23411248;
          keys = [{
            fingerprint = "6141 1E4F FE10 CE7B 2E14  CD76 0BE8 A88F 47B2 145C";
          }];
        };
        anirrudh = {
          email = "anik597@gmail.com";
          github = "anirrudh";
          githubId = 6091755;
          name = "Anirrudh Krishnan";
        };
        ankhers = {
          email = "me@ankhers.dev";
          github = "ankhers";
          githubId = 750786;
          name = "Justin Wood";
        };
        anna328p = {
          email = "anna328p@gmail.com";
          github = "anna328p";
          githubId = 9790772;
          name = "Anna";
        };
        anmonteiro = {
          email = "anmonteiro@gmail.com";
          github = "anmonteiro";
          githubId = 661909;
          name = "Antonio Nuno Monteiro";
        };
        anoa = {
          matrix = "@andrewm:amorgan.xyz";
          email = "andrew@amorgan.xyz";
          github = "anoadragon453";
          githubId = 1342360;
          name = "Andrew Morgan";
        };
        anpryl = {
          email = "anpryl@gmail.com";
          github = "anpryl";
          githubId = 5327697;
          name = "Anatolii Prylutskyi";
        };
        anselmschueler = {
          email = "mail@anselmschueler.com";
          github = "schuelermine";
          githubId = 48802534;
          name = "Anselm Schüler";
          matrix = "@schuelermine:matrix.org";
        };
        anthonyroussel = {
          email = "anthony@roussel.dev";
          github = "anthonyroussel";
          githubId = 220084;
          name = "Anthony Roussel";
          keys = [{
            fingerprint = "472D 368A F107 F443 F3A5  C712 9DC4 987B 1A55 E75E";
          }];
        };
        antoinerg = {
          email = "roygobeil.antoine@gmail.com";
          github = "antoinerg";
          githubId = 301546;
          name = "Antoine Roy-Gobeil";
        };
        anton-dessiatov = {
          email = "anton.dessiatov@gmail.com";
          github = "anton-dessiatov";
          githubId = 2873280;
          name = "Anton Desyatov";
        };
        Anton-Latukha = {
          email = "anton.latuka+nixpkgs@gmail.com";
          github = "Anton-Latukha";
          githubId = 20933385;
          name = "Anton Latukha";
        };
        antono = {
          email = "self@antono.info";
          github = "antono";
          githubId = 7622;
          name = "Antono Vasiljev";
        };
        antonxy = {
          email = "anton.schirg@posteo.de";
          github = "antonxy";
          githubId = 4194320;
          name = "Anton Schirg";
        };
        apeschar = {
          email = "albert@peschar.net";
          github = "apeschar";
          githubId = 122977;
          name = "Albert Peschar";
        };
        apeyroux = {
          email = "alex@px.io";
          github = "apeyroux";
          githubId = 1078530;
          name = "Alexandre Peyroux";
        };
        applePrincess = {
          email = "appleprincess@appleprincess.io";
          github = "applePrincess";
          githubId = 17154507;
          name = "Lein Matsumaru";
          keys = [{
            fingerprint = "BF8B F725 DA30 E53E 7F11  4ED8 AAA5 0652 F047 9205";
          }];
        };
        apraga = {
          email = "alexis.praga@proton.me";
          github = "apraga";
          githubId = 914687;
          name = "Alexis Praga";
        };
        ar1a = {
          email = "aria@ar1as.space";
          github = "ar1a";
          githubId = 8436007;
          name = "Aria Edmonds";
        };
        arcadio = {
          email = "arc@well.ox.ac.uk";
          github = "arcadio";
          githubId = 56009;
          name = "Arcadio Rubio García";
        };
        archer-65 = {
          email = "mario.liguori.056@gmail.com";
          github = "archer-65";
          githubId = 76066109;
          name = "Mario Liguori";
        };
        archseer = {
          email = "blaz@mxxn.io";
          github = "archseer";
          githubId = 1372918;
          name = "Blaž Hrastnik";
        };
        arcnmx = {
          email = "arcnmx@users.noreply.github.com";
          github = "arcnmx";
          githubId = 13426784;
          name = "arcnmx";
        };
        arcticlimer = {
          email = "vinigm.nho@gmail.com";
          github = "viniciusmuller";
          githubId = 59743220;
          name = "Vinícius Müller";
        };
        ardumont = {
          email = "eniotna.t@gmail.com";
          github = "ardumont";
          githubId = 718812;
          name = "Antoine R. Dumont";
        };
        arezvov = {
          email = "alex@rezvov.ru";
          github = "arezvov";
          githubId = 58516559;
          name = "Alexander Rezvov";
        };
        arianvp = {
          email = "arian.vanputten@gmail.com";
          github = "arianvp";
          githubId = 628387;
          name = "Arian van Putten";
        };
        arikgrahl = {
          email = "mail@arik-grahl.de";
          github = "arikgrahl";
          githubId = 8049011;
          name = "Arik Grahl";
        };
        aristid = {
          email = "aristidb@gmail.com";
          github = "aristidb";
          githubId = 30712;
          name = "Aristid Breitkreuz";
        };
        ariutta = {
          email = "anders.riutta@gmail.com";
          github = "ariutta";
          githubId = 1296771;
          name = "Anders Riutta";
        };
        arjan-s = {
          email = "github@anymore.nl";
          github = "arjan-s";
          githubId = 10400299;
          name = "Arjan Schrijver";
        };
        arkivm = {
          email = "vikram186@gmail.com";
          github = "arkivm";
          githubId = 1118815;
          name = "Vikram Narayanan";
        };
        armeenm = {
          email = "mahdianarmeen@gmail.com";
          github = "armeenm";
          githubId = 29145250;
          name = "Armeen Mahdian";
        };
        armijnhemel = {
          email = "armijn@tjaldur.nl";
          github = "armijnhemel";
          githubId = 10587952;
          name = "Armijn Hemel";
        };
        arnarg = {
          email = "arnarg@fastmail.com";
          github = "arnarg";
          githubId = 1291396;
          name = "Arnar Ingason";
        };
        arnoldfarkas = {
          email = "arnold.farkas@gmail.com";
          github = "arnoldfarkas";
          githubId = 59696216;
          name = "Arnold Farkas";
        };
        arnoutkroeze = {
          email = "nixpkgs@arnoutkroeze.nl";
          github = "ArnoutKroeze";
          githubId = 37151054;
          name = "Arnout Kroeze";
        };
        arobyn = {
          email = "shados@shados.net";
          github = "Shados";
          githubId = 338268;
          name = "Alexei Robyn";
        };
        artemist = {
          email = "me@artem.ist";
          github = "artemist";
          githubId = 1226638;
          name = "Artemis Tosini";
          keys = [{
            fingerprint = "3D2B B230 F9FA F0C5 1832  46DD 4FDC 96F1 61E7 BA8A";
          }];
        };
        arthur = {
          email = "me@arthur.li";
          github = "arthurl";
          githubId = 3965744;
          name = "Arthur Lee";
        };
        arthurteisseire = {
          email = "arthurteisseire33@gmail.com";
          github = "arthurteisseire";
          githubId = 37193992;
          name = "Arthur Teisseire";
        };
        arturcygan = {
          email = "arczicygan@gmail.com";
          github = "arcz";
          githubId = 4679721;
          name = "Artur Cygan";
        };
        artuuge = {
          email = "artuuge@gmail.com";
          github = "artuuge";
          githubId = 10285250;
          name = "Artur E. Ruuge";
        };
        asbachb = {
          email = "asbachb-nixpkgs-5c2a@impl.it";
          matrix = "@asbachb:matrix.org";
          github = "asbachb";
          githubId = 1482768;
          name = "Benjamin Asbach";
        };
        ashalkhakov = {
          email = "artyom.shalkhakov@gmail.com";
          github = "ashalkhakov";
          githubId = 1270502;
          name = "Artyom Shalkhakov";
        };
        ashgillman = {
          email = "gillmanash@gmail.com";
          github = "ashgillman";
          githubId = 816777;
          name = "Ashley Gillman";
        };
        ashkitten = {
          email = "ashlea@protonmail.com";
          github = "ashkitten";
          githubId = 9281956;
          name = "ash lea";
        };
        aske = {
          email = "aske@fmap.me";
          github = "aske";
          githubId = 869771;
          name = "Kirill Boltaev";
        };
        ashley = {
          email = "ashley@kira64.xyz";
          github = "kira64xyz";
          githubId = 84152630;
          name = "Ashley Chiara";
        };
        asppsa = {
          email = "asppsa@gmail.com";
          github = "asppsa";
          githubId = 453170;
          name = "Alastair Pharo";
        };
        astro = {
          email = "astro@spaceboyz.net";
          github = "astro";
          githubId = 12923;
          name = "Astro";
        };
        astrobeastie = {
          email = "fischervincent98@gmail.com";
          github = "astrobeastie";
          githubId = 26362368;
          name = "Vincent Fischer";
          keys = [{
            fingerprint = "BF47 81E1 F304 1ADF 18CE  C401 DE16 C7D1 536D A72F";
          }];
        };
        astsmtl = {
          email = "astsmtl@yandex.ru";
          github = "astsmtl";
          githubId = 2093941;
          name = "Alexander Tsamutali";
        };
        asymmetric = {
          email = "lorenzo@mailbox.org";
          github = "asymmetric";
          githubId = 101816;
          name = "Lorenzo Manacorda";
        };
        aszlig = {
          email = "aszlig@nix.build";
          github = "aszlig";
          githubId = 192147;
          name = "aszlig";
          keys = [{
            fingerprint = "DD52 6BC7 767D BA28 16C0 95E5 6840 89CE 67EB B691";
          }];
        };
        ataraxiasjel = {
          email = "nix@ataraxiadev.com";
          github = "AtaraxiaSjel";
          githubId = 5314145;
          name = "Dmitriy";
          keys = [{
            fingerprint = "922D A6E7 58A0 FE4C FAB4 E4B2 FD26 6B81 0DF4 8DF2";
          }];
        };
        atemu = {
          name = "Atemu";
          email = "atemu.main+nixpkgs@gmail.com";
          github = "Atemu";
          githubId = 18599032;
        };
        athas = {
          email = "athas@sigkill.dk";
          github = "athas";
          githubId = 55833;
          name = "Troels Henriksen";
        };
        atila = {
          name = "Átila Saraiva";
          email = "atilasaraiva@gmail.com";
          github = "AtilaSaraiva";
          githubId = 29521461;
        };
        atkinschang = {
          email = "atkinschang+nixpkgs@gmail.com";
          github = "AtkinsChang";
          githubId = 5193600;
          name = "Atkins Chang";
        };
        atnnn = {
          email = "etienne@atnnn.com";
          github = "AtnNn";
          githubId = 706854;
          name = "Etienne Laurin";
        };
        atry = {
          name = "Bo Yang";
          email = "atry@fb.com";
          github = "Atry";
          githubId = 601530;
        };
        attila-lendvai = {
          name = "Attila Lendvai";
          email = "attila@lendvai.name";
          github = "attila-lendvai";
          githubId = 840345;
        };
        auchter = {
          name = "Michael Auchter";
          email = "a@phire.org";
          github = "auchter";
          githubId = 1190483;
        };
        auntie = {
          email = "auntieNeo@gmail.com";
          github = "auntieNeo";
          githubId = 574938;
          name = "Jonathan Glines";
        };
        austinbutler = {
          email = "austinabutler@gmail.com";
          github = "austinbutler";
          githubId = 354741;
          name = "Austin Butler";
        };
        autophagy = {
          email = "mail@autophagy.io";
          github = "autophagy";
          githubId = 12958979;
          name = "Mika Naylor";
        };
        avaq = {
          email = "nixpkgs@account.avaq.it";
          github = "Avaq";
          githubId = 1217745;
          name = "Aldwin Vlasblom";
        };
        aveltras = {
          email = "romain.viallard@outlook.fr";
          github = "aveltras";
          githubId = 790607;
          name = "Romain Viallard";
        };
        avery = {
          email = "averyl+nixos@protonmail.com";
          github = "AveryLychee";
          githubId = 9147625;
          name = "Avery Lychee";
        };
        averelld = {
          email = "averell+nixos@rxd4.com";
          github = "averelld";
          githubId = 687218;
          name = "averelld";
        };
        avh4 = {
          email = "gruen0aermel@gmail.com";
          github = "avh4";
          githubId = 1222;
          name = "Aaron VonderHaar";
        };
        avitex = {
          email = "theavitex@gmail.com";
          github = "avitex";
          githubId = 5110816;
          name = "avitex";
          keys = [{
            fingerprint = "271E 136C 178E 06FA EA4E  B854 8B36 6C44 3CAB E942";
          }];
        };
        avnik = {
          email = "avn@avnik.info";
          github = "avnik";
          githubId = 153538;
          name = "Alexander V. Nikolaev";
        };
        aw = {
          email = "aw-nixos@meterriblecrew.net";
          github = "herrwiese";
          githubId = 206242;
          name = "Andreas Wiese";
        };
        aycanirican = {
          email = "iricanaycan@gmail.com";
          github = "aycanirican";
          githubId = 135230;
          name = "Aycan iRiCAN";
        };
        arjix = {
          email = "arjix@protonmail.com";
          github = "arjix";
          githubId = 62168569;
          name = "arjix";
        };
        artturin = {
          email = "artturin@artturin.com";
          matrix = "@artturin:matrix.org";
          github = "Artturin";
          githubId = 56650223;
          name = "Artturi N";
        };
        azahi = {
          name = "Azat Bahawi";
          email = "azat@bahawi.net";
          matrix = "@azahi:azahi.cc";
          github = "azahi";
          githubId = 22211000;
          keys = [{
            fingerprint = "2688 0377 C31D 9E81 9BDF  83A8 C8C6 BDDB 3847 F72B";
          }];
        };
        ayazhafiz = {
          email = "ayaz.hafiz.1@gmail.com";
          github = "hafiz";
          githubId = 262763;
          name = "Ayaz Hafiz";
        };
        azuwis = {
          email = "azuwis@gmail.com";
          github = "azuwis";
          githubId = 9315;
          name = "Zhong Jianxin";
        };
        a-kenji = {
          email = "aks.kenji@protonmail.com";
          github = "a-kenji";
          githubId = 65275785;
          name = "Alexander Kenji Berthold";
        };
        b4dm4n = {
          email = "fabianm88@gmail.com";
          github = "B4dM4n";
          githubId = 448169;
          name = "Fabian Möller";
          keys = [{
            fingerprint = "6309 E212 29D4 DA30 AF24  BDED 754B 5C09 63C4 2C50";
          }];
        };
        babariviere = {
          email = "me@babariviere.com";
          github = "babariviere";
          githubId = 12128029;
          name = "Bastien Rivière";
          keys = [{
            fingerprint = "74AA 9AB4 E6FF 872B 3C5A  CB3E 3903 5CC0 B75D 1142";
          }];
        };
        babbaj = {
          name = "babbaj";
          email = "babbaj45@gmail.com";
          github = "babbaj";
          githubId = 12820770;
          keys = [{
            fingerprint = "6FBC A462 4EAF C69C A7C4  98C1 F044 3098 48A0 7CAC";
          }];
        };
        bachp = {
          email = "pascal.bach@nextrem.ch";
          matrix = "@bachp:matrix.org";
          github = "bachp";
          githubId = 333807;
          name = "Pascal Bach";
        };
        backuitist = {
          email = "biethb@gmail.com";
          github = "backuitist";
          githubId = 1017537;
          name = "Bruno Bieth";
        };
        badmutex = {
          email = "github@badi.sh";
          github = "badmutex";
          githubId = 35324;
          name = "Badi' Abdul-Wahid";
        };
        baduhai = {
          email = "baduhai@pm.me";
          github = "baduhai";
          githubId = 31864305;
          name = "William";
        };
        baitinq = {
          email = "manuelpalenzuelamerino@gmail.com";
          name = "Baitinq";
          github = "Baitinq";
          githubId = 30861839;
        };
        balodja = {
          email = "balodja@gmail.com";
          github = "balodja";
          githubId = 294444;
          name = "Vladimir Korolev";
        };
        baloo = {
          email = "nixpkgs@superbaloo.net";
          github = "baloo";
          githubId = 59060;
          name = "Arthur Gautier";
        };
        balsoft = {
          email = "balsoft75@gmail.com";
          github = "balsoft";
          githubId = 18467667;
          name = "Alexander Bantyev";
        };
        bandresen = {
          email = "bandresen@gmail.com";
          github = "bennyandresen";
          githubId = 80325;
          name = "Benjamin Andresen";
        };
        baracoder = {
          email = "baracoder@googlemail.com";
          github = "baracoder";
          githubId = 127523;
          name = "Herman Fries";
        };
        BarinovMaxim = {
          name = "Barinov Maxim";
          email = "barinov274@gmail.com";
          github = "barinov274";
          githubId = 54442153;
        };
        barrucadu = {
          email = "mike@barrucadu.co.uk";
          github = "barrucadu";
          githubId = 75235;
          name = "Michael Walker";
        };
        bartsch = {
          email = "consume.noise@gmail.com";
          github = "bartsch";
          githubId = 3390885;
          name = "Daniel Martin";
        };
        bartuka = {
          email = "wand@hey.com";
          github = "wandersoncferreira";
          githubId = 17708295;
          name = "Wanderson Ferreira";
          keys = [{
            fingerprint = "A3E1 C409 B705 50B3 BF41  492B 5684 0A61 4DBE 37AE";
          }];
        };
        basvandijk = {
          email = "v.dijk.bas@gmail.com";
          github = "basvandijk";
          githubId = 576355;
          name = "Bas van Dijk";
        };
        BattleCh1cken = {
          email = "BattleCh1cken@larkov.de";
          github = "BattleCh1cken";
          githubId = 75806385;
          name = "Felix Hass";
        };
        Baughn = {
          email = "sveina@gmail.com";
          github = "Baughn";
          githubId = 45811;
          name = "Svein Ove Aas";
        };
        bb010g = {
          email = "me@bb010g.com";
          matrix = "@bb010g:matrix.org";
          github = "bb010g";
          githubId = 340132;
          name = "Brayden Banks";
        };
        bbarker = {
          email = "brandon.barker@gmail.com";
          github = "bbarker";
          githubId = 916366;
          name = "Brandon Elam Barker";
        };
        bbenno = {
          email = "nix@bbenno.com";
          github = "bbenno";
          githubId = 32938211;
          name = "Benno Bielmeier";
        };
        bbigras = {
          email = "bigras.bruno@gmail.com";
          github = "bbigras";
          githubId = 24027;
          name = "Bruno Bigras";
        };
        bcarrell = {
          email = "brandoncarrell@gmail.com";
          github = "bcarrell";
          githubId = 1015044;
          name = "Brandon Carrell";
        };
        bcc32 = {
          email = "me@bcc32.com";
          github = "bcc32";
          githubId = 1239097;
          name = "Aaron Zeng";
        };
        bcdarwin = {
          email = "bcdarwin@gmail.com";
          github = "bcdarwin";
          githubId = 164148;
          name = "Ben Darwin";
        };
        bdd = {
          email = "bdd@mindcast.org";
          github = "bdd";
          githubId = 11135;
          name = "Berk D. Demir";
        };
        bdesham = {
          email = "benjamin@esham.io";
          github = "bdesham";
          githubId = 354230;
          name = "Benjamin Esham";
        };
        bdimcheff = {
          email = "brandon@dimcheff.com";
          github = "bdimcheff";
          githubId = 14111;
          name = "Brandon Dimcheff";
        };
        beardhatcode = {
          name = "Robbert Gurdeep Singh";
          email = "nixpkgs@beardhatcode.be";
          github = "beardhatcode";
          githubId = 662538;
        };
        beezow = {
          name = "beezow";
          email = "zbeezow@gmail.com";
          github = "beezow";
          githubId = 42082156;
        };
        bendlas = {
          email = "herwig@bendlas.net";
          matrix = "@bendlas:matrix.org";
          github = "bendlas";
          githubId = 214787;
          name = "Herwig Hochleitner";
        };
        benediktbroich = {
          name = "Benedikt Broich";
          email = "b.broich@posteo.de";
          github = "BenediktBroich";
          githubId = 32903896;
          keys = [{
            fingerprint = "CB5C 7B3C 3E6F 2A59 A583  A90A 8A60 0376 7BE9 5976";
          }];
        };
        benesim = {
          name = "Benjamin Isbarn";
          email = "benjamin.isbarn@gmail.com";
          github = "benesim";
          githubId = 29384538;
          keys = [{
            fingerprint = "D35E C9CE E631 638F F1D8  B401 6F0E 410D C3EE D02";
          }];
        };
        benjaminedwardwebb = {
          name = "Ben Webb";
          email = "benjaminedwardwebb@gmail.com";
          github = "benjaminedwardwebb";
          githubId = 7118777;
          keys = [{
            fingerprint = "E9A3 7864 2165 28CE 507C  CA82 72EA BF75 C331 CD25";
          }];
        };
        benley = {
          email = "benley@gmail.com";
          github = "benley";
          githubId = 1432730;
          name = "Benjamin Staffin";
        };
        benneti = {
          name = "Benedikt Tissot";
          email = "benedikt.tissot@googlemail.com";
          github = "benneti";
          githubId = 11725645;
        };
        bertof = {
          name = "Filippo Berto";
          email = "berto.f@protonmail.com";
          github = "bertof";
          githubId = 9915675;
          keys = [{
            fingerprint = "17C5 1EF9 C0FE 2EB2 FE56  BB53 FE98 AE5E C52B 1056";
          }];
        };
        bennofs = {
          email = "benno.fuenfstueck@gmail.com";
          github = "bennofs";
          githubId = 3192959;
          name = "Benno Fünfstück";
        };
        benpye = {
          email = "ben@curlybracket.co.uk";
          github = "benpye";
          githubId = 442623;
          name = "Ben Pye";
        };
        berberman = {
          email = "berberman@yandex.com";
          matrix = "@berberman:mozilla.org";
          github = "berberman";
          githubId = 26041945;
          name = "Potato Hatsue";
        };
        berce = {
          email = "bert.moens@gmail.com";
          github = "berce";
          githubId = 10439709;
          name = "Bert Moens";
        };
        berdario = {
          email = "berdario@gmail.com";
          github = "berdario";
          githubId = 752835;
          name = "Dario Bertini";
        };
        bergey = {
          email = "bergey@teallabs.org";
          github = "bergey";
          githubId = 251106;
          name = "Daniel Bergey";
        };
        bergkvist = {
          email = "tobias@bergkv.ist";
          github = "bergkvist";
          githubId = 410028;
          name = "Tobias Bergkvist";
        };
        berryp = {
          email = "berryphillips@gmail.com";
          github = "berryp";
          githubId = 19911;
          name = "Berry Phillips";
        };
        betaboon = {
          email = "betaboon@0x80.ninja";
          github = "betaboon";
          githubId = 7346933;
          name = "betaboon";
        };
        bew = {
          email = "benoit.dechezelles@gmail.com";
          github = "bew";
          githubId = 9730330;
          name = "Benoit de Chezelles";
        };
        bfortz = {
          email = "bernard.fortz@gmail.com";
          github = "bfortz";
          githubId = 16426882;
          name = "Bernard Fortz";
        };
        bgamari = {
          email = "ben@smart-cactus.org";
          github = "bgamari";
          githubId = 1010174;
          name = "Ben Gamari";
        };
        bhall = {
          email = "brendan.j.hall@bath.edu";
          github = "brendan-hall";
          githubId = 34919100;
          name = "Brendan Hall";
        };
        bhipple = {
          email = "bhipple@protonmail.com";
          github = "bhipple";
          githubId = 2071583;
          name = "Benjamin Hipple";
        };
        bhougland = {
          email = "benjamin.hougland@gmail.com";
          github = "bhougland18";
          githubId = 28444296;
          name = "Benjamin Hougland";
        };
        bigzilla = {
          email = "m.billyzaelani@gmail.com";
          github = "bigzilla";
          githubId = 20436235;
          name = "Billy Zaelani Malik";
        };
        billewanick = {
          email = "bill@ewanick.com";
          github = "billewanick";
          githubId = 13324165;
          name = "Bill Ewanick";
        };
        billhuang = {
          email = "bill.huang2001@gmail.com";
          github = "BillHuang2001";
          githubId = 11801831;
          name = "Bill Huang";
        };
        binarin = {
          email = "binarin@binarin.ru";
          github = "binarin";
          githubId = 185443;
          name = "Alexey Lebedeff";
        };
        binsky = {
          email = "timo@binsky.org";
          github = "binsky08";
          githubId = 30630233;
          name = "Timo Triebensky";
        };
        bjornfor = {
          email = "bjorn.forsman@gmail.com";
          github = "bjornfor";
          githubId = 133602;
          name = "Bjørn Forsman";
        };
        bkchr = {
          email = "nixos@kchr.de";
          github = "bkchr";
          githubId = 5718007;
          name = "Bastian Köcher";
        };
        blaggacao = {
          name = "David Arnold";
          email = "dar@xoe.solutions";
          github = "blaggacao";
          githubId = 7548295;
        };
        blanky0230 = {
          email = "blanky0230@gmail.com";
          github = "blanky0230";
          githubId = 5700358;
          name = "Thomas Blank";
        };
        blitz = {
          email = "js@alien8.de";
          matrix = "@js:ukvly.org";
          github = "blitz";
          githubId = 37907;
          name = "Julian Stecklina";
        };
        bluescreen303 = {
          email = "mathijs@bluescreen303.nl";
          github = "bluescreen303";
          githubId = 16330;
          name = "Mathijs Kwik";
        };
        bmilanov = {
          name = "Biser Milanov";
          email = "bmilanov11+nixpkgs@gmail.com";
          github = "bmilanov";
          githubId = 30090366;
        };
        bmwalters = {
          name = "Bradley Walters";
          email = "oss@walters.app";
          github = "bmwalters";
          githubId = 4380777;
        };
        bobakker = {
          email = "bobakk3r@gmail.com";
          github = "bobakker";
          githubId = 10221570;
          name = "Bo Bakker";
        };
        bobby285271 = {
          name = "Bobby Rong";
          email = "rjl931189261@126.com";
          matrix = "@bobby285271:matrix.org";
          github = "bobby285271";
          githubId = 20080233;
        };
        bobvanderlinden = {
          email = "bobvanderlinden@gmail.com";
          github = "bobvanderlinden";
          githubId = 6375609;
          name = "Bob van der Linden";
        };
        bodil = {
          email = "nix@bodil.org";
          github = "bodil";
          githubId = 17880;
          name = "Bodil Stokke";
        };
        boj = {
          email = "brian@uncannyworks.com";
          github = "boj";
          githubId = 50839;
          name = "Brian Jones";
        };
        booklearner = {
          name = "booklearner";
          email = "booklearner@proton.me";
          matrix = "@booklearner:matrix.org";
          github = "booklearner";
          githubId = 103979114;
          keys = [{
            fingerprint = "17C7 95D4 871C 2F87 83C8  053D 0C61 C4E5 907F 76C8";
          }];
        };
        bootstrap-prime = {
          email = "bootstrap.prime@gmail.com";
          github = "bootstrap-prime";
          githubId = 68566724;
          name = "bootstrap-prime";
        };
        commandodev = {
          email = "ben@perurbis.com";
          github = "commandodev";
          githubId = 87764;
          name = "Ben Ford";
        };
        boppyt = {
          email = "boppy@nwcpz.com";
          github = "boppyt";
          githubId = 71049646;
          name = "Zack A";
          keys = [{
            fingerprint = "E8D7 5C19 9F65 269B 439D  F77B 6310 C97D E31D 1545";
          }];
        };
        borisbabic = {
          email = "boris.ivan.babic@gmail.com";
          github = "borisbabic";
          githubId = 1743184;
          name = "Boris Babić";
        };
        borlaag = {
          email = "borlaag@proton.me";
          github = "Borlaag";
          githubId = 114830266;
          name = "Børlaag";
        };
        bosu = {
          email = "boriss@gmail.com";
          github = "bosu";
          githubId = 3465841;
          name = "Boris Sukholitko";
        };
        bouk = {
          name = "Bouke van der Bijl";
          email = "i@bou.ke";
          github = "bouk";
          githubId = 97820;
        };
        bradediger = {
          email = "brad@bradediger.com";
          github = "bradediger";
          githubId = 4621;
          name = "Brad Ediger";
        };
        brainrape = {
          email = "martonboros@gmail.com";
          github = "brainrake";
          githubId = 302429;
          name = "Marton Boros";
        };
        bramd = {
          email = "bram@bramd.nl";
          github = "bramd";
          githubId = 86652;
          name = "Bram Duvigneau";
        };
        braydenjw = {
          email = "nixpkgs@willenborg.ca";
          github = "braydenjw";
          githubId = 2506621;
          name = "Brayden Willenborg";
        };
        brendanreis = {
          email = "brendanreis@gmail.com";
          name = "Brendan Reis";
          github = "brendanreis";
          githubId = 10686906;
        };
        brian-dawn = {
          email = "brian.t.dawn@gmail.com";
          github = "brian-dawn";
          githubId = 1274409;
          name = "Brian Dawn";
        };
        brianhicks = {
          email = "brian@brianthicks.com";
          github = "BrianHicks";
          githubId = 355401;
          name = "Brian Hicks";
        };
        brianmcgee = {
          name = "Brian McGee";
          email = "brian@41north.dev";
          github = "brianmcgee";
          githubId = 1173648;
        };
        Br1ght0ne = {
          email = "brightone@protonmail.com";
          github = "Br1ght0ne";
          githubId = 12615679;
          name = "Oleksii Filonenko";
          keys = [{
            fingerprint = "F549 3B7F 9372 5578 FDD3  D0B8 A1BC 8428 323E CFE8";
          }];
        };
        bsima = {
          email = "ben@bsima.me";
          github = "bsima";
          githubId = 200617;
          name = "Ben Sima";
        };
        bstrik = {
          email = "dutchman55@gmx.com";
          github = "bstrik";
          githubId = 7716744;
          name = "Berno Strik";
        };
        breakds = {
          email = "breakds@gmail.com";
          github = "breakds";
          githubId = 1111035;
          name = "Break Yang";
        };
        brecht = {
          email = "brecht.savelkoul@alumni.lse.ac.uk";
          github = "brechtcs";
          githubId = 6107054;
          name = "Brecht Savelkoul";
        };
        brettlyons = {
          email = "blyons@fastmail.com";
          github = "brettlyons";
          githubId = 3043718;
          name = "Brett Lyons";
        };
        brodes = {
          email = "me@brod.es";
          github = "brhoades";
          githubId = 4763746;
          name = "Billy Rhoades";
          keys = [{
            fingerprint = "BF4FCB85C69989B4ED95BF938AE74787A4B7C07E";
          }];
        };
        broke = {
          email = "broke@in-fucking.space";
          github = "broke";
          githubId = 1071610;
          name = "Gunnar Nitsche";
        };
        bryanasdev000 = {
          email = "bryanasdev000@gmail.com";
          matrix = "@bryanasdev000:matrix.org";
          github = "bryanasdev000";
          githubId = 53131727;
          name = "Bryan Albuquerque";
        };
        btlvr = {
          email = "btlvr@protonmail.com";
          github = "btlvr";
          githubId = 32319131;
          name = "Brett L";
        };
        buckley310 = {
          email = "sean.bck@gmail.com";
          matrix = "@buckley310:matrix.org";
          github = "buckley310";
          githubId = 2379774;
          name = "Sean Buckley";
        };
        buffet = {
          email = "niclas@countingsort.com";
          github = "buffet";
          githubId = 33751841;
          name = "Niclas Meyer";
        };
        bugworm = {
          email = "bugworm@zoho.com";
          github = "bugworm";
          githubId = 7214361;
          name = "Roman Gerasimenko";
        };
        builditluc = {
          email = "builditluc@icloud.com";
          github = "Builditluc";
          githubId = 37375448;
          name = "Buildit";
        };
        bburdette = {
          email = "bburdette@protonmail.com";
          github = "bburdette";
          githubId = 157330;
          name = "Ben Burdette";
        };
        bwlang = {
          email = "brad@langhorst.com";
          github = "bwlang";
          githubId = 61636;
          name = "Brad Langhorst";
        };
        bzizou = {
          email = "Bruno@bzizou.net";
          github = "bzizou";
          githubId = 2647566;
          name = "Bruno Bzeznik";
        };
        c0bw3b = {
          email = "c0bw3b@gmail.com";
          github = "c0bw3b";
          githubId = 24417923;
          name = "Renaud";
        };
        c00w = {
          email = "nix@daedrum.net";
          github = "c00w";
          githubId = 486199;
          name = "Colin";
        };
        c0deaddict = {
          email = "josvanbakel@protonmail.com";
          github = "c0deaddict";
          githubId = 510553;
          name = "Jos van Bakel";
        };
        c4605 = {
          email = "bolasblack@gmail.com";
          github = "bolasblack";
          githubId = 382011;
          name = "c4605";
        };
        caadar = {
          email = "v88m@posteo.net";
          github = "caadar";
          githubId = 15320726;
          name = "Car Cdr";
        };
        cab404 = {
          email = "cab404@mailbox.org";
          github = "cab404";
          githubId = 6453661;
          name = "Vladimir Serov";
          keys = [
            # compare with https://keybase.io/cab404
            {
              fingerprint = "1BB96810926F4E715DEF567E6BA7C26C3FDF7BB3";
            }
            {
              fingerprint = "1EBC648C64D6045463013B3EB7EFFC271D55DB8A";
            }
          ];
        };
        calbrecht = {
          email = "christian.albrecht@mayflower.de";
          github = "calbrecht";
          githubId = 1516457;
          name = "Christian Albrecht";
        };
        CactiChameleon9 = {
          email = "h19xjkkp@duck.com";
          github = "CactiChameleon9";
          githubId = 51231053;
          name = "Daniel";
        };
        calavera = {
          email = "david.calavera@gmail.com";
          github = "calavera";
          githubId = 1050;
          matrix = "@davidcalavera:matrix.org";
          name = "David Calavera";
        };
        callahad = {
          email = "dan.callahan@gmail.com";
          github = "callahad";
          githubId = 24193;
          name = "Dan Callahan";
        };
        calvertvl = {
          email = "calvertvl@gmail.com";
          github = "calvertvl";
          githubId = 7435854;
          name = "Victor Calvert";
        };
        cameronfyfe = {
          email = "cameron.j.fyfe@gmail.com";
          github = "cameronfyfe";
          githubId = 21013281;
          name = "Cameron Fyfe";
        };
        cameronnemo = {
          email = "cnemo@tutanota.com";
          github = "CameronNemo";
          githubId = 3212452;
          name = "Cameron Nemo";
        };
        campadrenalin = {
          email = "campadrenalin@gmail.com";
          github = "campadrenalin";
          githubId = 289492;
          name = "Philip Horger";
        };
        candeira = {
          email = "javier@candeira.com";
          github = "candeira";
          githubId = 91694;
          name = "Javier Candeira";
        };
        candyc1oud = {
          email = "candyc1oud@outlook.com";
          github = "candyc1oud";
          githubId = 113157395;
          name = "Candy Cloud";
        };
        canndrew = {
          email = "shum@canndrew.org";
          github = "canndrew";
          githubId = 5555066;
          name = "Andrew Cann";
        };
        cap = {
          name = "cap";
          email = "nixos_xasenw9@digitalpostkasten.de";
          github = "scaredmushroom";
          githubId = 45340040;
        };
        CaptainJawZ = {
          email = "CaptainJawZ@outlook.com";
          name = "Danilo Reyes";
          github = "CaptainJawZ";
          githubId = 43111068;
        };
        carlosdagos = {
          email = "m@cdagostino.io";
          github = "carlosdagos";
          githubId = 686190;
          name = "Carlos D'Agostino";
        };
        carlsverre = {
          email = "accounts@carlsverre.com";
          github = "carlsverre";
          githubId = 82591;
          name = "Carl Sverre";
        };
        carpinchomug = {
          email = "aki.suda@protonmail.com";
          github = "carpinchomug";
          githubId = 101536256;
          name = "Akiyoshi Suda";
        };
        cartr = {
          email = "carter.sande@duodecima.technology";
          github = "cartr";
          githubId = 5241813;
          name = "Carter Sande";
        };
        casey = {
          email = "casey@rodarmor.net";
          github = "casey";
          githubId = 1945;
          name = "Casey Rodarmor";
        };
        catap = {
          email = "kirill@korins.ky";
          github = "catap";
          githubId = 37775;
          name = "Kirill A. Korinsky";
        };
        catern = {
          email = "sbaugh@catern.com";
          github = "catern";
          githubId = 5394722;
          name = "Spencer Baugh";
        };
        catouc = {
          email = "catouc@philipp.boeschen.me";
          github = "catouc";
          githubId = 25623213;
          name = "Philipp Böschen";
        };
        caugner = {
          email = "nixos@caugner.de";
          github = "caugner";
          githubId = 495429;
          name = "Claas Augner";
        };
        cawilliamson = {
          email = "home@chrisaw.com";
          github = "cawilliamson";
          githubId = 1141769;
          matrix = "@cawilliamson:nixos.dev";
          name = "Christopher A. Williamson";
        };
        cbley = {
          email = "claudio.bley@gmail.com";
          github = "avdv";
          githubId = 3471749;
          name = "Claudio Bley";
        };
        cburstedde = {
          email = "burstedde@ins.uni-bonn.de";
          github = "cburstedde";
          githubId = 109908;
          name = "Carsten Burstedde";
          keys = [{
            fingerprint = "1127 A432 6524 BF02 737B  544E 0704 CD9E 550A 6BCD";
          }];
        };
        cdepillabout = {
          email = "cdep.illabout@gmail.com";
          matrix = "@cdepillabout:matrix.org";
          github = "cdepillabout";
          githubId = 64804;
          name = "Dennis Gosnell";
        };
        ccellado = {
          email = "annplague@gmail.com";
          github = "ccellado";
          githubId = 44584960;
          name = "Denis Khalmatov";
        };
        ceedubs = {
          email = "ceedubs@gmail.com";
          github = "ceedubs";
          githubId = 977929;
          name = "Cody Allen";
        };
        centromere = {
          email = "nix@centromere.net";
          github = "centromere";
          githubId = 543423;
          name = "Alex Wied";
        };
        cfhammill = {
          email = "cfhammill@gmail.com";
          github = "cfhammill";
          githubId = 7467038;
          name = "Chris Hammill";
        };
        cfouche = {
          email = "chaddai.fouche@gmail.com";
          github = "Chaddai";
          githubId = 5771456;
          name = "Chaddaï Fouché";
        };
        cfsmp3 = {
          email = "carlos@sanz.dev";
          github = "cfsmp3";
          githubId = 5949913;
          name = "Carlos Fernandez Sanz";
        };
        cge = {
          email = "cevans@evanslabs.org";
          github = "cgevans";
          githubId = 2054509;
          name = "Constantine Evans";
          keys = [
            {
              fingerprint = "32B1 6EE7 DBA5 16DE 526E  4C5A B67D B1D2 0A93 A9F9";
            }
            {
              fingerprint = "669C 1D24 5A87 DB34 6BE4  3216 1A1D 58B8 6AE2 AABD";
            }
          ];
        };
        chaduffy = {
          email = "charles@dyfis.net";
          github = "charles-dyfis-net";
          githubId = 22370;
          name = "Charles Duffy";
        };
        changlinli = {
          email = "mail@changlinli.com";
          github = "changlinli";
          githubId = 1762540;
          name = "Changlin Li";
        };
        chanley = {
          email = "charlieshanley@gmail.com";
          github = "charlieshanley";
          githubId = 8228888;
          name = "Charlie Hanley";
        };
        charlesbaynham = {
          email = "charlesbaynham@gmail.com";
          github = "charlesbaynham";
          githubId = 4397637;
          name = "Charles Baynham";
        };
        CharlesHD = {
          email = "charleshdespointes@gmail.com";
          github = "CharlesHD";
          githubId = 6608071;
          name = "Charles Huyghues-Despointes";
        };
        chaoflow = {
          email = "flo@chaoflow.net";
          github = "chaoflow";
          githubId = 89596;
          name = "Florian Friesdorf";
        };
        chekoopa = {
          email = "chekoopa@mail.ru";
          github = "chekoopa";
          githubId = 1689801;
          name = "Mikhail Chekan";
        };
        ChengCat = {
          email = "yu@cheng.cat";
          github = "ChengCat";
          githubId = 33503784;
          name = "Yucheng Zhang";
        };
        cheriimoya = {
          email = "github@hausch.xyz";
          github = "cheriimoya";
          githubId = 28303440;
          name = "Max Hausch";
        };
        chessai = {
          email = "chessai1996@gmail.com";
          github = "chessai";
          githubId = 18648043;
          name = "Daniel Cartwright";
        };
        Chili-Man = {
          email = "dr.elhombrechile@gmail.com";
          name = "Diego Rodriguez";
          github = "Chili-Man";
          githubId = 631802;
          keys = [{
            fingerprint = "099E 3F97 FA08 3D47 8C75  EBEC E0EB AD78 F019 0BD9";
          }];
        };
        chiroptical = {
          email = "chiroptical@gmail.com";
          github = "chiroptical";
          githubId = 3086255;
          name = "Barry Moore II";
        };
        chisui = {
          email = "chisui.pd@gmail.com";
          github = "chisui";
          githubId = 4526429;
          name = "Philipp Dargel";
        };
        chivay = {
          email = "hubert.jasudowicz@gmail.com";
          github = "chivay";
          githubId = 14790226;
          name = "Hubert Jasudowicz";
        };
        chkno = {
          email = "chuck@intelligence.org";
          github = "chkno";
          githubId = 1118859;
          name = "Scott Worley";
        };
        choochootrain = {
          email = "hurshal@imap.cc";
          github = "choochootrain";
          githubId = 803961;
          name = "Hurshal Patel";
        };
        chpatrick = {
          email = "chpatrick@gmail.com";
          github = "chpatrick";
          githubId = 832719;
          name = "Patrick Chilton";
        };
        chreekat = {
          email = "b@chreekat.net";
          github = "chreekat";
          githubId = 538538;
          name = "Bryan Richter";
        };
        chris-martin = {
          email = "ch.martin@gmail.com";
          github = "chris-martin";
          githubId = 399718;
          name = "Chris Martin";
        };
        chrisjefferson = {
          email = "chris@bubblescope.net";
          github = "ChrisJefferson";
          githubId = 811527;
          name = "Christopher Jefferson";
        };
        chrispattison = {
          email = "chpattison@gmail.com";
          github = "ChrisPattison";
          githubId = 641627;
          name = "Chris Pattison";
        };
        chrispickard = {
          email = "chrispickard9@gmail.com";
          github = "chrispickard";
          githubId = 1438690;
          name = "Chris Pickard";
        };
        chrisrosset = {
          email = "chris@rosset.org.uk";
          github = "chrisrosset";
          githubId = 1103294;
          name = "Christopher Rosset";
        };
        christianharke = {
          email = "christian@harke.ch";
          github = "christianharke";
          githubId = 13007345;
          name = "Christian Harke";
          keys = [{
            fingerprint = "4EBB 30F1 E89A 541A A7F2  52BE 830A 9728 6309 66F4";
          }];
        };
        christophcharles = {
          email = "23055925+christophcharles@users.noreply.github.com";
          github = "christophcharles";
          githubId = 23055925;
          name = "Christoph Charles";
        };
        christopherpoole = {
          email = "mail@christopherpoole.net";
          github = "christopherpoole";
          githubId = 2245737;
          name = "Christopher Mark Poole";
        };
        chuahou = {
          email = "human+github@chuahou.dev";
          github = "chuahou";
          githubId = 12386805;
          name = "Chua Hou";
        };
        chuangzhu = {
          name = "Chuang Zhu";
          email = "chuang@melty.land";
          matrix = "@chuangzhu:matrix.org";
          github = "chuangzhu";
          githubId = 31200881;
          keys = [{
            fingerprint = "5D03 A5E6 0754 A3E3 CA57 5037 E838 CED8 1CFF D3F9";
          }];
        };
        chvp = {
          email = "nixpkgs@cvpetegem.be";
          matrix = "@charlotte:vanpetegem.me";
          github = "chvp";
          githubId = 42220376;
          name = "Charlotte Van Petegem";
        };
        ciferkey = {
          name = "Matthew Brunelle";
          email = "ciferkey@gmail.com";
          github = "ciferkey";
          githubId = 101422;
        };
        cigrainger = {
          name = "Christopher Grainger";
          email = "chris@amplified.ai";
          github = "cigrainger";
          githubId = 3984794;
        };
        ciil = {
          email = "simon@lackerbauer.com";
          github = "ciil";
          githubId = 3956062;
          name = "Simon Lackerbauer";
        };
        cimm = {
          email = "8k9ft8m5gv@astil.be";
          github = "cimm";
          githubId = 68112;
          name = "Simon";
        };
        cirno-999 = {
          email = "reverene@protonmail.com";
          github = "cirno-999";
          githubId = 73712874;
          name = "cirno-999";
        };
        citadelcore = {
          email = "alex@arctarus.co.uk";
          github = "CitadelCore";
          githubId = 5567402;
          name = "Alex Zero";
          keys = [{
            fingerprint = "A0AA 4646 B8F6 9D45 4553  5A88 A515 50ED B450 302C";
          }];
        };
        cizra = {
          email = "todurov+nix@gmail.com";
          github = "cizra";
          githubId = 2131991;
          name = "Elmo Todurov";
        };
        cjab = {
          email = "chad+nixpkgs@jablonski.xyz";
          github = "cjab";
          githubId = 136485;
          name = "Chad Jablonski";
        };
        ck3d = {
          email = "ck3d@gmx.de";
          github = "ck3d";
          githubId = 25088352;
          name = "Christian Kögler";
        };
        ckie = {
          email = "nixpkgs-0efe364@ckie.dev";
          github = "ckiee";
          githubId = 25263210;
          keys = [{
            fingerprint = "539F 0655 4D35 38A5 429A  E253 13E7 9449 C052 5215";
          }];
          name = "ckie";
          matrix = "@ckie:ckie.dev";
        };
        clkamp = {
          email = "c@lkamp.de";
          github = "clkamp";
          githubId = 46303707;
          name = "Christian Lütke-Stetzkamp";
        };
        ckauhaus = {
          email = "kc@flyingcircus.io";
          github = "ckauhaus";
          githubId = 1448923;
          name = "Christian Kauhaus";
        };
        cko = {
          email = "christine.koppelt@gmail.com";
          github = "cko";
          githubId = 68239;
          name = "Christine Koppelt";
        };
        clacke = {
          email = "claes.wallin@greatsinodevelopment.com";
          github = "clacke";
          githubId = 199180;
          name = "Claes Wallin";
        };
        cleeyv = {
          email = "cleeyv@riseup.net";
          github = "cleeyv";
          githubId = 71959829;
          name = "Cleeyv";
        };
        clerie = {
          email = "nix@clerie.de";
          github = "clerie";
          githubId = 9381848;
          name = "clerie";
        };
        cleverca22 = {
          email = "cleverca22@gmail.com";
          matrix = "@cleverca22:matrix.org";
          github = "cleverca22";
          githubId = 848609;
          name = "Michael Bishop";
        };
        cmacrae = {
          email = "hi@cmacr.ae";
          github = "cmacrae";
          githubId = 3392199;
          name = "Calum MacRae";
        };
        cmars = {
          email = "nix@cmars.tech";
          github = "cmars";
          githubId = 23741;
          name = "Casey Marshall";
          keys = [{
            fingerprint = "6B78 7E5F B493 FA4F D009  5D10 6DEC 2758 ACD5 A973";
          }];
        };
        cmcdragonkai = {
          email = "roger.qiu@matrix.ai";
          github = "CMCDragonkai";
          githubId = 640797;
          name = "Roger Qiu";
        };
        cmfwyp = {
          email = "cmfwyp@riseup.net";
          github = "cmfwyp";
          githubId = 20808761;
          name = "cmfwyp";
        };
        cmm = {
          email = "repo@cmm.kakpryg.net";
          github = "cmm";
          githubId = 718298;
          name = "Michael Livshin";
        };
        cobbal = {
          email = "andrew.cobb@gmail.com";
          github = "cobbal";
          githubId = 180339;
          name = "Andrew Cobb";
        };
        coconnor = {
          email = "coreyoconnor@gmail.com";
          github = "coreyoconnor";
          githubId = 34317;
          name = "Corey O'Connor";
        };
        CodeLongAndProsper90 = {
          github = "CodeLongAndProsper90";
          githubId = 50145141;
          email = "jupiter@m.rdis.dev";
          name = "Scott Little";
        };
        codsl = {
          email = "codsl@riseup.net";
          github = "codsl";
          githubId = 6402559;
          name = "codsl";
        };
        codyopel = {
          email = "codyopel@gmail.com";
          github = "codyopel";
          githubId = 5561189;
          name = "Cody Opel";
        };
        cofob = {
          name = "Egor Ternovoy";
          email = "cofob@riseup.net";
          matrix = "@cofob:matrix.org";
          github = "cofob";
          githubId = 49928332;
          keys = [{
            fingerprint = "5F3D 9D3D ECE0 8651 DE14  D29F ACAD 4265 E193 794D";
          }];
        };
        Cogitri = {
          email = "oss@cogitri.dev";
          github = "Cogitri";
          githubId = 8766773;
          matrix = "@cogitri:cogitri.dev";
          name = "Rasmus Thomsen";
        };
        cohei = {
          email = "a.d.xvii.kal.mai@gmail.com";
          github = "cohei";
          githubId = 3477497;
          name = "TANIGUCHI Kohei";
        };
        cohencyril = {
          email = "cyril.cohen@inria.fr";
          github = "CohenCyril";
          githubId = 298705;
          name = "Cyril Cohen";
        };
        colemickens = {
          email = "cole.mickens@gmail.com";
          matrix = "@colemickens:matrix.org";
          github = "colemickens";
          githubId = 327028;
          name = "Cole Mickens";
        };
        colescott = {
          email = "colescottsf@gmail.com";
          github = "colescott";
          githubId = 5684605;
          name = "Cole Scott";
        };
        cole-h = {
          name = "Cole Helbling";
          email = "cole.e.helbling@outlook.com";
          matrix = "@cole-h:matrix.org";
          github = "cole-h";
          githubId = 28582702;
          keys = [{
            fingerprint = "68B8 0D57 B2E5 4AC3 EC1F  49B0 B37E 0F23 7101 6A4C";
          }];
        };
        colinsane = {
          name = "Colin Sane";
          email = "colin@uninsane.org";
          matrix = "@colin:uninsane.org";
          github = "uninsane";
          githubId = 106709944;
        };
        collares = {
          email = "mauricio@collares.org";
          github = "collares";
          githubId = 244239;
          name = "Mauricio Collares";
        };
        CompEng0001 = {
          email = "sb1501@canterbury.ac.uk";
          github = "CompEng0001";
          githubId = 40290417;
          name = "Seb Blair";
        };
        considerate = {
          email = "viktor.kronvall@gmail.com";
          github = "considerate";
          githubId = 217918;
          name = "Viktor Kronvall";
        };
        copumpkin = {
          email = "pumpkingod@gmail.com";
          github = "copumpkin";
          githubId = 2623;
          name = "Dan Peebles";
        };
        corngood = {
          email = "corngood@gmail.com";
          github = "corngood";
          githubId = 3077118;
          name = "David McFarland";
        };
        coroa = {
          email = "jonas@chaoflow.net";
          github = "coroa";
          githubId = 2552981;
          name = "Jonas Hörsch";
        };
        costrouc = {
          email = "chris.ostrouchov@gmail.com";
          github = "costrouc";
          githubId = 1740337;
          name = "Chris Ostrouchov";
        };
        confus = {
          email = "con-f-use@gmx.net";
          github = "con-f-use";
          githubId = 11145016;
          name = "J.C.";
        };
        congee = {
          email = "changshengwu@pm.me";
          matrix = "@congeec:matrix.org";
          github = "Congee";
          name = "Changsheng Wu";
          githubId = 2083950;
        };
        contrun = {
          email = "uuuuuu@protonmail.com";
          github = "contrun";
          githubId = 32609395;
          name = "B YI";
        };
        conradmearns = {
          email = "conradmearns+github@pm.me";
          github = "ConradMearns";
          githubId = 5510514;
          name = "Conrad Mearns";
        };
        corbanr = {
          email = "corban@raunco.co";
          github = "CorbanR";
          githubId = 1918683;
          matrix = "@corbansolo:matrix.org";
          name = "Corban Raun";
          keys = [
            {
              fingerprint = "6607 0B24 8CE5 64ED 22CE  0950 A697 A56F 1F15 1189";
            }
            {
              fingerprint = "D8CB 816A B678 A4E6 1EC7  5325 230F 4AC1 53F9 0F29";
            }
          ];
        };
        couchemar = {
          email = "couchemar@yandex.ru";
          github = "couchemar";
          githubId = 1573344;
          name = "Andrey Pavlov";
        };
        cpages = {
          email = "page@ruiec.cat";
          github = "cpages";
          githubId = 411324;
          name = "Carles Pagès";
        };
        cpu = {
          email = "daniel@binaryparadox.net";
          github = "cpu";
          githubId = 292650;
          name = "Daniel McCarney";
          keys = [{
            fingerprint = "8026 D24A A966 BF9C D3CD  CB3C 08FB 2BFC 470E 75B4";
          }];
        };
        Crafter = {
          email = "crafter@crafter.rocks";
          github = "Craftzman7";
          githubId = 70068692;
          name = "Crafter";
        };
        craigem = {
          email = "craige@mcwhirter.io";
          github = "craigem";
          githubId = 6470493;
          name = "Craige McWhirter";
        };
        cransom = {
          email = "cransom@hubns.net";
          github = "cransom";
          githubId = 1957293;
          name = "Casey Ransom";
        };
        CrazedProgrammer = {
          email = "crazedprogrammer@gmail.com";
          github = "CrazedProgrammer";
          githubId = 12202789;
          name = "CrazedProgrammer";
        };
        creator54 = {
          email = "hi.creator54@gmail.com";
          github = "Creator54";
          githubId = 34543609;
          name = "creator54";
        };
        crinklywrappr = {
          email = "crinklywrappr@pm.me";
          name = "Daniel Fitzpatrick";
          github = "crinklywrappr";
          githubId = 56522;
        };
        cript0nauta = {
          email = "shareman1204@gmail.com";
          github = "cript0nauta";
          githubId = 1222362;
          name = "Matías Lang";
        };
        CRTified = {
          email = "carl.schneider+nixos@rub.de";
          matrix = "@schnecfk:ruhr-uni-bochum.de";
          github = "CRTified";
          githubId = 2440581;
          name = "Carl Richard Theodor Schneider";
          keys = [{
            fingerprint = "2017 E152 BB81 5C16 955C  E612 45BC C1E2 709B 1788";
          }];
        };
        cryptix = {
          email = "cryptix@riseup.net";
          github = "cryptix";
          githubId = 111202;
          name = "Henry Bubert";
        };
        CrystalGamma = {
          email = "nixos@crystalgamma.de";
          github = "CrystalGamma";
          githubId = 6297001;
          name = "Jona Stubbe";
        };
        csingley = {
          email = "csingley@gmail.com";
          github = "csingley";
          githubId = 398996;
          name = "Christopher Singley";
        };
        cstrahan = {
          email = "charles@cstrahan.com";
          github = "cstrahan";
          githubId = 143982;
          name = "Charles Strahan";
        };
        cswank = {
          email = "craigswank@gmail.com";
          github = "cswank";
          githubId = 490965;
          name = "Craig Swank";
        };
        cust0dian = {
          email = "serg@effectful.software";
          github = "cust0dian";
          githubId = 389387;
          name = "Serg Nesterov";
          keys = [{
            fingerprint = "6E7D BA30 DB5D BA60 693C  3BE3 1512 F6EB 84AE CC8C";
          }];
        };
        cwoac = {
          email = "oliver@codersoffortune.net";
          github = "cwoac";
          githubId = 1382175;
          name = "Oliver Matthews";
        };
        cwyc = {
          email = "hello@cwyc.page";
          github = "cwyc";
          githubId = 16950437;
          name = "cwyc";
        };
        cynerd = {
          name = "Karel Kočí";
          email = "cynerd@email.cz";
          github = "Cynerd";
          githubId = 3811900;
          keys = [{
            fingerprint = "2B1F 70F9 5F1B 48DA 2265 A7FA A6BC 8B8C EB31 659B";
          }];
        };
        cyounkins = {
          name = "Craig Younkins";
          email = "cyounkins@gmail.com";
          github = "cyounkins";
          githubId = 346185;
        };
        cypherpunk2140 = {
          email = "stefan.mihaila@pm.me";
          github = "stefan-mihaila";
          githubId = 2217136;
          name = "Ștefan D. Mihăilă";
          keys = [
            {
              fingerprint = "CBC9 C7CC 51F0 4A61 3901 C723 6E68 A39B F16A 3ECB";
            }
            {
              fingerprint = "7EAB 1447 5BBA 7DDE 7092 7276 6220 AD78 4622 0A52";
            }
          ];
        };
        cyplo = {
          email = "nixos@cyplo.dev";
          matrix = "@cyplo:cyplo.dev";
          github = "cyplo";
          githubId = 217899;
          name = "Cyryl Płotnicki";
        };
        d-goldin = {
          email = "dgoldin+github@protonmail.ch";
          github = "d-goldin";
          githubId = 43349662;
          name = "Dima";
          keys = [{
            fingerprint = "1C4E F4FE 7F8E D8B7 1E88 CCDF BAB1 D15F B7B4 D4CE";
          }];
        };
        d-xo = {
          email = "hi@d-xo.org";
          github = "d-xo";
          githubId = 6689924;
          name = "David Terry";
        };
        dadada = {
          name = "dadada";
          email = "dadada@dadada.li";
          github = "dadada";
          githubId = 7216772;
          keys = [{
            fingerprint = "D68C 8469 5C08 7E0F 733A  28D0 EEB8 D1CE 62C4 DFEA";
          }];
        };
        dalance = {
          email = "dalance@gmail.com";
          github = "dalance";
          githubId = 4331004;
          name = "Naoya Hatta";
        };
        dalpd = {
          email = "denizalpd@ogr.iu.edu.tr";
          github = "dalpd";
          githubId = 16895361;
          name = "Deniz Alp Durmaz";
        };
        DAlperin = {
          email = "git@dov.dev";
          github = "DAlperin";
          githubId = 16063713;
          name = "Dov Alperin";
          keys = [{
            fingerprint = "4EED 5096 B925 86FA 1101  6673 7F2C 07B9 1B52 BB61";
          }];
        };
        DamienCassou = {
          email = "damien@cassou.me";
          github = "DamienCassou";
          githubId = 217543;
          name = "Damien Cassou";
        };
        danbst = {
          email = "abcz2.uprola@gmail.com";
          github = "danbst";
          githubId = 743057;
          name = "Danylo Hlynskyi";
        };
        danc86 = {
          name = "Dan Callaghan";
          email = "djc@djc.id.au";
          github = "danc86";
          githubId = 398575;
          keys = [{
            fingerprint = "1C56 01F1 D70A B56F EABB  6BC0 26B5 AA2F DAF2 F30A";
          }];
        };
        dancek = {
          email = "hannu.hartikainen@gmail.com";
          github = "dancek";
          githubId = 245394;
          name = "Hannu Hartikainen";
        };
        danderson = {
          email = "dave@natulte.net";
          github = "danderson";
          githubId = 1918;
          name = "David Anderson";
        };
        dandellion = {
          email = "daniel@dodsorf.as";
          matrix = "@dandellion:dodsorf.as";
          github = "dali99";
          githubId = 990767;
          name = "Daniel Olsen";
        };
        daneads = {
          email = "me@daneads.com";
          github = "daneads";
          githubId = 24708079;
          name = "Dan Eads";
        };
        danielbarter = {
          email = "danielbarter@gmail.com";
          github = "danielbarter";
          githubId = 8081722;
          name = "Daniel Barter";
        };
        danieldk = {
          email = "me@danieldk.eu";
          github = "danieldk";
          githubId = 49398;
          name = "Daniël de Kok";
        };
        danielfullmer = {
          email = "danielrf12@gmail.com";
          github = "danielfullmer";
          githubId = 1298344;
          name = "Daniel Fullmer";
        };
        danth = {
          name = "Daniel Thwaites";
          email = "danthwaites30@btinternet.com";
          matrix = "@danth:danth.me";
          github = "danth";
          githubId = 28959268;
          keys = [{
            fingerprint = "4779 D1D5 3C97 2EAE 34A5  ED3D D8AF C4BF 0567 0F9D";
          }];
        };
        dan4ik605743 = {
          email = "6057430gu@gmail.com";
          github = "dan4ik605743";
          githubId = 86075850;
          name = "Danil Danevich";
        };
        darkonion0 = {
          name = "Alexandre Peruggia";
          email = "darkgenius1@protonmail.com";
          matrix = "@alexoo:matrix.org";
          github = "DarkOnion0";
          githubId = 68606322;
        };
        das-g = {
          email = "nixpkgs@raphael.dasgupta.ch";
          github = "das-g";
          githubId = 97746;
          name = "Raphael Das Gupta";
        };
        das_j = {
          email = "janne@hess.ooo";
          matrix = "@janne.hess:helsinki-systems.de";
          github = "dasJ";
          githubId = 4971975;
          name = "Janne Heß";
        };
        dasisdormax = {
          email = "dasisdormax@mailbox.org";
          github = "dasisdormax";
          githubId = 3714905;
          keys = [{
            fingerprint = "E59B A198 61B0 A9ED C1FA  3FB2 02BA 0D44 80CA 6C44";
          }];
          name = "Maximilian Wende";
        };
        dasj19 = {
          email = "daniel@serbanescu.dk";
          github = "dasj19";
          githubId = 7589338;
          name = "Daniel Șerbănescu";
        };
        datafoo = {
          email = "34766150+datafoo@users.noreply.github.com";
          github = "datafoo";
          githubId = 34766150;
          name = "datafoo";
        };
        davhau = {
          email = "d.hauer.it@gmail.com";
          name = "David Hauer";
          github = "DavHau";
          githubId = 42246742;
        };
        david-sawatzke = {
          email = "d-nix@sawatzke.dev";
          github = "david-sawatzke";
          githubId = 11035569;
          name = "David Sawatzke";
        };
        david50407 = {
          email = "me@davy.tw";
          github = "david50407";
          githubId = 841969;
          name = "David Kuo";
        };
        davidak = {
          email = "post@davidak.de";
          matrix = "@davidak:matrix.org";
          github = "davidak";
          githubId = 91113;
          name = "David Kleuker";
        };
        davidarmstronglewis = {
          email = "davidlewis@mac.com";
          github = "davidarmstronglewis";
          githubId = 6754950;
          name = "David Armstrong Lewis";
        };
        davidrusu = {
          email = "davidrusu.me@gmail.com";
          github = "davidrusu";
          githubId = 1832378;
          name = "David Rusu";
        };
        davidtwco = {
          email = "david@davidtw.co";
          github = "davidtwco";
          githubId = 1295100;
          name = "David Wood";
          keys = [{
            fingerprint = "5B08 313C 6853 E5BF FA91  A817 0176 0B4F 9F53 F154";
          }];
        };
        davorb = {
          email = "davor@davor.se";
          github = "davorb";
          githubId = 798427;
          name = "Davor Babic";
        };
        davsanchez = {
          email = "davidslt+nixpkgs@pm.me";
          github = "davsanchez";
          githubId = 11422515;
          name = "David Sánchez";
        };
        dawidsowa = {
          email = "dawid_sowa@posteo.net";
          github = "dawidsowa";
          githubId = 49904992;
          name = "Dawid Sowa";
        };
        dbeckwith = {
          email = "djbsnx@gmail.com";
          github = "dbeckwith";
          githubId = 1279939;
          name = "Daniel Beckwith";
        };
        dbirks = {
          email = "david@birks.dev";
          github = "dbirks";
          githubId = 7545665;
          name = "David Birks";
          keys = [{
            fingerprint = "B26F 9AD8 DA20 3392 EF87  C61A BB99 9F83 D9A1 9A36";
          }];
        };
        dbohdan = {
          email = "dbohdan@dbohdan.com";
          github = "dbohdan";
          githubId = 3179832;
          name = "D. Bohdan";
        };
        dbrock = {
          email = "daniel@brockman.se";
          github = "dbrock";
          githubId = 14032;
          name = "Daniel Brockman";
        };
        ddelabru = {
          email = "ddelabru@redhat.com";
          github = "ddelabru";
          githubId = 39909293;
          name = "Dominic Delabruere";
        };
        dduan = {
          email = "daniel@duan.ca";
          github = "dduan";
          githubId = 75067;
          name = "Daniel Duan";
        };
        dearrude = {
          name = "Ebrahim Nejati";
          email = "dearrude@tfwno.gf";
          github = "DearRude";
          githubId = 30749142;
          keys = [{
            fingerprint = "4E35 F2E5 2132 D654 E815  A672 DB2C BC24 2868 6000";
          }];
        };
        deejayem = {
          email = "nixpkgs.bu5hq@simplelogin.com";
          github = "deejayem";
          githubId = 2564003;
          name = "David Morgan";
          keys = [{
            fingerprint = "9B43 6B14 77A8 79C2 6CDB  6604 C171 2510 02C2 00F2";
          }];
        };
        deepfire = {
          email = "_deepfire@feelingofgreen.ru";
          github = "deepfire";
          githubId = 452652;
          name = "Kosyrev Serge";
        };
        DeeUnderscore = {
          email = "d.anzorge@gmail.com";
          github = "DeeUnderscore";
          githubId = 156239;
          name = "D Anzorge";
        };
        delan = {
          name = "Delan Azabani";
          email = "delan@azabani.com";
          github = "delan";
          githubId = 465303;
        };
        delehef = {
          name = "Franklin Delehelle";
          email = "nix@odena.eu";
          github = "delehef";
          githubId = 1153808;
        };
        deliciouslytyped = {
          email = "47436522+deliciouslytyped@users.noreply.github.com";
          github = "deliciouslytyped";
          githubId = 47436522;
          name = "deliciouslytyped";
        };
        delroth = {
          email = "delroth@gmail.com";
          github = "delroth";
          githubId = 202798;
          name = "Pierre Bourdon";
        };
        delta = {
          email = "d4delta@outlook.fr";
          github = "D4Delta";
          githubId = 12224254;
          name = "Delta";
        };
        deltadelta = {
          email = "contact@libellules.eu";
          name = "Dara Ly";
          github = "tournemire";
          githubId = 20159432;
        };
        deltaevo = {
          email = "deltaduartedavid@gmail.com";
          github = "DeltaEvo";
          githubId = 8864716;
          name = "Duarte David";
        };
        demin-dmitriy = {
          email = "demindf@gmail.com";
          github = "demin-dmitriy";
          githubId = 5503422;
          name = "Dmitriy Demin";
        };
        demize = {
          email = "johannes@kyriasis.com";
          github = "kyrias";
          githubId = 2285387;
          name = "Johannes Löthberg";
        };
        demyanrogozhin = {
          email = "demyan.rogozhin@gmail.com";
          github = "demyanrogozhin";
          githubId = 62989;
          name = "Demyan Rogozhin";
        };
        derchris = {
          email = "derchris@me.com";
          github = "derchrisuk";
          githubId = 706758;
          name = "Christian Gerbrandt";
        };
        derekcollison = {
          email = "derek@nats.io";
          github = "derekcollison";
          githubId = 90097;
          name = "Derek Collison";
        };
        DerGuteMoritz = {
          email = "moritz@twoticketsplease.de";
          github = "DerGuteMoritz";
          githubId = 19733;
          name = "Moritz Heidkamp";
        };
        DerickEddington = {
          email = "derick.eddington@pm.me";
          github = "DerickEddington";
          githubId = 4731128;
          name = "Derick Eddington";
        };
        dermetfan = {
          email = "serverkorken@gmail.com";
          github = "dermetfan";
          githubId = 4956158;
          name = "Robin Stumm";
        };
        DerTim1 = {
          email = "tim.digel@active-group.de";
          github = "DerTim1";
          githubId = 21953890;
          name = "Tim Digel";
        };
        desiderius = {
          email = "didier@devroye.name";
          github = "desiderius";
          githubId = 1311761;
          name = "Didier J. Devroye";
        };
        desttinghim = {
          email = "opensource@louispearson.work";
          matrix = "@desttinghim:matrix.org";
          github = "desttinghim";
          githubId = 10042482;
          name = "Louis Pearson";
        };
        Dettorer = {
          name = "Paul Hervot";
          email = "paul.hervot@dettorer.net";
          matrix = "@dettorer:matrix.org";
          github = "Dettorer";
          githubId = 2761682;
        };
        devhell = {
          email = ''"^"@regexmail.net'';
          github = "devhell";
          githubId = 896182;
          name = "devhell";
        };
        devins2518 = {
          email = "drsingh2518@icloud.com";
          github = "devins2518";
          githubId = 17111639;
          name = "Devin Singh";
        };
        devusb = {
          email = "mhelton@devusb.us";
          github = "devusb";
          githubId = 4951663;
          name = "Morgan Helton";
        };
        dezgeg = {
          email = "tuomas.tynkkynen@iki.fi";
          github = "dezgeg";
          githubId = 579369;
          name = "Tuomas Tynkkynen";
        };
        dfordivam = {
          email = "dfordivam+nixpkgs@gmail.com";
          github = "dfordivam";
          githubId = 681060;
          name = "Divam";
        };
        dfoxfranke = {
          email = "dfoxfranke@gmail.com";
          github = "dfoxfranke";
          githubId = 4708206;
          name = "Daniel Fox Franke";
        };
        dgliwka = {
          email = "dawid.gliwka@gmail.com";
          github = "dgliwka";
          githubId = 33262214;
          name = "Dawid Gliwka";
        };
        dgonyeo = {
          email = "derek@gonyeo.com";
          github = "dgonyeo";
          githubId = 2439413;
          name = "Derek Gonyeo";
        };
        dguenther = {
          email = "dguenther9@gmail.com";
          github = "dguenther";
          githubId = 767083;
          name = "Derek Guenther";
        };
        dhkl = {
          email = "david@davidslab.com";
          github = "dhl";
          githubId = 265220;
          name = "David Leung";
        };
        DianaOlympos = {
          email = "DianaOlympos@noreply.github.com";
          github = "DianaOlympos";
          githubId = 15774340;
          name = "Thomas Depierre";
        };
        diegolelis = {
          email = "diego.o.lelis@gmail.com";
          github = "DiegoLelis";
          githubId = 8404455;
          name = "Diego Lelis";
        };
        DieracDelta = {
          email = "justin@restivo.me";
          github = "DieracDelta";
          githubId = 13730968;
          name = "Justin Restivo";
        };
        diffumist = {
          email = "git@diffumist.me";
          github = "Diffumist";
          githubId = 32810399;
          name = "Diffumist";
        };
        diogox = {
          name = "Diogo Xavier";
          email = "13244408+diogox@users.noreply.github.com";
          github = "diogox";
          githubId = 13244408;
        };
        dipinhora = {
          email = "dipinhora+github@gmail.com";
          github = "dipinhora";
          githubId = 11946442;
          name = "Dipin Hora";
        };
        dirkx = {
          email = "dirkx@webweaving.org";
          github = "dirkx";
          githubId = 392583;
          name = "Dirk-Willem van Gulik";
        };
        disassembler = {
          email = "disasm@gmail.com";
          github = "disassembler";
          githubId = 651205;
          name = "Samuel Leathers";
        };
        disserman = {
          email = "disserman@gmail.com";
          github = "divi255";
          githubId = 40633781;
          name = "Sergei S.";
        };
        dit7ya = {
          email = "7rat13@gmail.com";
          github = "dit7ya";
          githubId = 14034137;
          name = "Mostly Void";
        };
        dizfer = {
          email = "david@izquierdofernandez.com";
          github = "DIzFer";
          githubId = 8852888;
          name = "David Izquierdo";
        };
        djacu = {
          email = "daniel.n.baker@gmail.com";
          github = "djacu";
          githubId = 7043297;
          name = "Daniel Baker";
        };
        djanatyn = {
          email = "djanatyn@gmail.com";
          github = "djanatyn";
          githubId = 523628;
          name = "Jonathan Strickland";
        };
        Dje4321 = {
          email = "dje4321@gmail.com";
          github = "dje4321";
          githubId = 10913120;
          name = "Dje4321";
        };
        djwf = {
          email = "dave@weller-fahy.com";
          github = "djwf";
          githubId = 73162;
          name = "David J. Weller-Fahy";
        };
        dkabot = {
          email = "dkabot@dkabot.com";
          github = "dkabot";
          githubId = 1316469;
          name = "Naomi Morse";
        };
        dlesl = {
          email = "dlesl@dlesl.com";
          github = "dlesl";
          githubId = 28980797;
          name = "David Leslie";
        };
        dlip = {
          email = "dane@lipscombe.com.au";
          github = "dlip";
          githubId = 283316;
          name = "Dane Lipscombe";
        };
        dmalikov = {
          email = "malikov.d.y@gmail.com";
          github = "dmalikov";
          githubId = 997543;
          name = "Dmitry Malikov";
        };
        DmitryTsygankov = {
          email = "dmitry.tsygankov@gmail.com";
          github = "DmitryTsygankov";
          githubId = 425354;
          name = "Dmitry Tsygankov";
        };
        dmjio = {
          email = "djohnson.m@gmail.com";
          github = "dmjio";
          githubId = 875324;
          name = "David Johnson";
        };
        dmrauh = {
          email = "dmrauh@posteo.de";
          github = "dmrauh";
          githubId = 37698547;
          name = "Dominik Michael Rauh";
        };
        dmvianna = {
          email = "dmlvianna@gmail.com";
          github = "dmvianna";
          githubId = 1708810;
          name = "Daniel Vianna";
        };
        dnr = {
          email = "dnr@dnr.im";
          github = "dnr";
          githubId = 466723;
          name = "David Reiss";
        };
        dochang = {
          email = "dochang@gmail.com";
          github = "dochang";
          githubId = 129093;
          name = "Desmond O. Chang";
        };
        domenkozar = {
          email = "domen@dev.si";
          github = "domenkozar";
          githubId = 126339;
          name = "Domen Kozar";
        };
        DomesticMoth = {
          name = "Andrew";
          email = "silkmoth@protonmail.com";
          github = "DomesticMoth";
          githubId = 91414737;
          keys = [{
            fingerprint = "7D6B AE0A A98A FDE9 3396  E721 F87E 15B8 3AA7 3087";
          }];
        };
        dominikh = {
          email = "dominik@honnef.co";
          github = "dominikh";
          githubId = 39825;
          name = "Dominik Honnef";
        };
        doronbehar = {
          email = "me@doronbehar.com";
          github = "doronbehar";
          githubId = 10998835;
          name = "Doron Behar";
        };
        dotlambda = {
          email = "rschuetz17@gmail.com";
          matrix = "@robert:funklause.de";
          github = "dotlambda";
          githubId = 6806011;
          name = "Robert Schütz";
        };
        dottedmag = {
          email = "dottedmag@dottedmag.net";
          github = "dottedmag";
          githubId = 16120;
          name = "Misha Gusarov";
          keys = [{
            fingerprint = "A8DF 1326 9E5D 9A38 E57C  FAC2 9D20 F650 3E33 8888";
          }];
        };
        doublec = {
          email = "chris.double@double.co.nz";
          github = "doublec";
          githubId = 16599;
          name = "Chris Double";
        };
        dpaetzel = {
          email = "david.paetzel@posteo.de";
          github = "dpaetzel";
          githubId = 974130;
          name = "David Pätzel";
        };
        dpausp = {
          email = "dpausp@posteo.de";
          github = "dpausp";
          githubId = 1965950;
          name = "Tobias Stenzel";
          keys = [{
            fingerprint = "4749 0887 CF3B 85A1 6355  C671 78C7 DD40 DF23 FB16";
          }];
        };
        DPDmancul = {
          name = "Davide Peressoni";
          email = "davide.peressoni@tuta.io";
          matrix = "@dpd-:matrix.org";
          githubId = 3186857;
        };
        dpercy = {
          email = "dpercy@dpercy.dev";
          github = "dpercy";
          githubId = 349909;
          name = "David Percy";
        };
        dpflug = {
          email = "david@pflug.email";
          github = "dpflug";
          githubId = 108501;
          name = "David Pflug";
        };
        dramaturg = {
          email = "seb@ds.ag";
          github = "dramaturg";
          githubId = 472846;
          name = "Sebastian Krohn";
        };
        drets = {
          email = "dmitryrets@gmail.com";
          github = "drets";
          githubId = 6199462;
          name = "Dmytro Rets";
        };
        drewrisinger = {
          email = "drisinger+nixpkgs@gmail.com";
          github = "drewrisinger";
          githubId = 10198051;
          name = "Drew Risinger";
        };
        dritter = {
          email = "dritter03@googlemail.com";
          github = "dritter";
          githubId = 1544760;
          name = "Dominik Ritter";
        };
        drperceptron = {
          email = "92106371+drperceptron@users.noreply.github.com";
          github = "drperceptron";
          githubId = 92106371;
          name = "Dr Perceptron";
          keys = [{
            fingerprint = "7E38 89D9 B1A8 B381 C8DE  A15F 95EB 6DFF 26D1 CEB0";
          }];
        };
        drupol = {
          name = "Pol Dellaiera";
          email = "pol.dellaiera@protonmail.com";
          matrix = "@drupol:matrix.org";
          github = "drupol";
          githubId = 252042;
          keys = [{
            fingerprint = "85F3 72DF 4AF3 EF13 ED34  72A3 0AAF 2901 E804 0715";
          }];
        };
        drzoidberg = {
          email = "jakob@mast3rsoft.com";
          github = "jakobneufeld";
          githubId = 24791219;
          name = "Jakob Neufeld";
        };
        dsalaza4 = {
          email = "podany270895@gmail.com";
          github = "dsalaza4";
          githubId = 11205987;
          name = "Daniel Salazar";
        };
        dschrempf = {
          name = "Dominik Schrempf";
          email = "dominik.schrempf@gmail.com";
          github = "dschrempf";
          githubId = 5596239;
          keys = [{
            fingerprint = "62BC E2BD 49DF ECC7 35C7  E153 875F 2BCF 163F 1B29";
          }];
        };
        dsferruzza = {
          email = "david.sferruzza@gmail.com";
          github = "dsferruzza";
          githubId = 1931963;
          name = "David Sferruzza";
        };
        dtzWill = {
          email = "w@wdtz.org";
          github = "dtzWill";
          githubId = 817330;
          name = "Will Dietz";
          keys = [{
            fingerprint = "389A 78CB CD88 5E0C 4701  DEB9 FD42 C7D0 D414 94C8";
          }];
        };
        dukc = {
          email = "ajieskola@gmail.com";
          github = "dukc";
          githubId = 24233408;
          name = "Ate Eskola";
        };
        dump_stack = {
          email = "root@dumpstack.io";
          github = "jollheef";
          githubId = 1749762;
          name = "Mikhail Klementev";
          keys = [{
            fingerprint = "5DD7 C6F6 0630 F08E DAE7  4711 1525 585D 1B43 C62A";
          }];
        };
        dwarfmaster = {
          email = "nixpkgs@dwarfmaster.net";
          github = "dwarfmaster";
          githubId = 2025623;
          name = "Luc Chabassier";
        };
        dxf = {
          email = "dingxiangfei2009@gmail.com";
          github = "dingxiangfei2009";
          githubId = 6884440;
          name = "Ding Xiang Fei";
        };
        dysinger = {
          email = "tim@dysinger.net";
          github = "dysinger";
          githubId = 447;
          name = "Tim Dysinger";
        };
        dywedir = {
          email = "dywedir@gra.red";
          matrix = "@dywedir:matrix.org";
          github = "dywedir";
          githubId = 399312;
          name = "Vladyslav M.";
        };
        dzabraev = {
          email = "dzabraew@gmail.com";
          github = "dzabraev";
          githubId = 15128988;
          name = "Maksim Dzabraev";
        };
        e1mo = {
          email = "nixpkgs@e1mo.de";
          matrix = "@e1mo:chaos.jetzt";
          github = "e1mo";
          githubId = 61651268;
          name = "Moritz Fromm";
          keys = [{
            fingerprint = "67BE E563 43B6 420D 550E  DF2A 6D61 7FD0 A85B AADA";
          }];
        };
        eadwu = {
          email = "edmund.wu@protonmail.com";
          github = "eadwu";
          githubId = 22758444;
          name = "Edmund Wu";
        };
        ealasu = {
          email = "emanuel.alasu@gmail.com";
          github = "ealasu";
          githubId = 1362096;
          name = "Emanuel Alasu";
        };
        eamsden = {
          email = "edward@blackriversoft.com";
          github = "eamsden";
          githubId = 54573;
          name = "Edward Amsden";
        };
        earldouglas = {
          email = "james@earldouglas.com";
          github = "earldouglas";
          githubId = 424946;
          name = "James Earl Douglas";
        };
        erikarvstedt = {
          email = "erik.arvstedt@gmail.com";
          matrix = "@erikarvstedt:matrix.org";
          github = "erikarvstedt";
          githubId = 36110478;
          name = "Erik Arvstedt";
        };
        ebbertd = {
          email = "daniel@ebbert.nrw";
          github = "ebbertd";
          githubId = 20522234;
          name = "Daniel Ebbert";
          keys = [{
            fingerprint = "E765 FCA3 D9BF 7FDB 856E  AD73 47BC 1559 27CB B9C7";
          }];
        };
        ebzzry = {
          email = "ebzzry@ebzzry.io";
          github = "ebzzry";
          githubId = 7875;
          name = "Rommel Martinez";
        };
        edanaher = {
          email = "nixos@edanaher.net";
          github = "edanaher";
          githubId = 984691;
          name = "Evan Danaher";
        };
        edbentley = {
          email = "hello@edbentley.dev";
          github = "edbentley";
          githubId = 15923595;
          name = "Ed Bentley";
        };
        edcragg = {
          email = "ed.cragg@eipi.xyz";
          github = "nuxeh";
          githubId = 1516017;
          name = "Ed Cragg";
        };
        edef = {
          email = "edef@edef.eu";
          github = "edef1c";
          githubId = 50854;
          name = "edef";
        };
        edlimerkaj = {
          name = "Edli Merkaj";
          email = "edli.merkaj@identinet.io";
          github = "edlimerkaj";
          githubId = 71988351;
        };
        edrex = {
          email = "ericdrex@gmail.com";
          github = "edrex";
          githubId = 14615;
          keys = [{
            fingerprint = "AC47 2CCC 9867 4644 A9CF  EB28 1C5C 1ED0 9F66 6824";
          }];
          matrix = "@edrex:matrix.org";
          name = "Eric Drechsel";
        };
        ehllie = {
          email = "me@ehllie.xyz";
          github = "ehllie";
          githubId = 20847625;
          name = "Elizabeth Paź";
        };
        elliottslaughter = {
          name = "Elliott Slaughter";
          email = "elliottslaughter@gmail.com";
          github = "elliottslaughter";
          githubId = 3129;
        };
        emantor = {
          email = "rouven+nixos@czerwinskis.de";
          github = "Emantor";
          githubId = 934284;
          name = "Rouven Czerwinski";
        };
        embr = {
          email = "hi@liclac.eu";
          github = "liclac";
          githubId = 428026;
          name = "embr";
        };
        emily = {
          email = "nixpkgs@emily.moe";
          github = "emilazy";
          githubId = 18535642;
          name = "Emily";
        };
        emilytrau = {
          name = "Emily Trau";
          email = "nix@angus.ws";
          github = "emilytrau";
          githubId = 13267947;
        };
        enderger = {
          email = "endergeryt@gmail.com";
          github = "enderger";
          githubId = 36283171;
          name = "Daniel";
        };
        endocrimes = {
          email = "dani@builds.terrible.systems";
          github = "endocrimes";
          githubId = 1330683;
          name = "Danielle Lancashire";
        };
        ederoyd46 = {
          email = "matt@ederoyd.co.uk";
          github = "ederoyd46";
          githubId = 119483;
          name = "Matthew Brown";
        };
        eduarrrd = {
          email = "e.bachmakov@gmail.com";
          github = "eduarrrd";
          githubId = 1181393;
          name = "Eduard Bachmakov";
        };
        edude03 = {
          email = "michael@melenion.com";
          github = "edude03";
          githubId = 494483;
          name = "Michael Francis";
        };
        edwtjo = {
          email = "ed@cflags.cc";
          github = "edwtjo";
          githubId = 54799;
          name = "Edward Tjörnhammar";
        };
        eelco = {
          email = "edolstra+nixpkgs@gmail.com";
          github = "edolstra";
          githubId = 1148549;
          name = "Eelco Dolstra";
        };
        ehegnes = {
          email = "eric.hegnes@gmail.com";
          github = "ehegnes";
          githubId = 884970;
          name = "Eric Hegnes";
        };
        ehmry = {
          email = "ehmry@posteo.net";
          github = "ehmry";
          githubId = 537775;
          name = "Emery Hemingway";
        };
        eigengrau = {
          email = "seb@schattenkopie.de";
          name = "Sebastian Reuße";
          github = "eigengrau";
          githubId = 4939947;
        };
        eikek = {
          email = "eike.kettner@posteo.de";
          github = "eikek";
          githubId = 701128;
          name = "Eike Kettner";
        };
        ekleog = {
          email = "leo@gaspard.io";
          matrix = "@leo:gaspard.ninja";
          github = "Ekleog";
          githubId = 411447;
          name = "Leo Gaspard";
        };
        elasticdog = {
          email = "aaron@elasticdog.com";
          github = "elasticdog";
          githubId = 4742;
          name = "Aaron Bull Schaefer";
        };
        elatov = {
          email = "elatov@gmail.com";
          github = "elatov";
          githubId = 7494394;
          name = "Karim Elatov";
        };
        eleanor = {
          email = "dejan@proteansec.com";
          github = "proteansec";
          githubId = 1753498;
          name = "Dejan Lukan";
        };
        electrified = {
          email = "ed@maidavale.org";
          github = "electrified";
          githubId = 103082;
          name = "Ed Brindley";
        };
        elizagamedev = {
          email = "eliza@eliza.sh";
          github = "elizagamedev";
          githubId = 4576666;
          name = "Eliza Velasquez";
        };
        elliot = {
          email = "hack00mind@gmail.com";
          github = "Eliot00";
          githubId = 18375468;
          name = "Elliot Xu";
        };
        elliottvillars = {
          email = "elliottvillars@gmail.com";
          github = "elliottvillars";
          githubId = 48104179;
          name = "Elliott Villars";
        };
        eliasp = {
          email = "mail@eliasprobst.eu";
          matrix = "@eliasp:kde.org";
          github = "eliasp";
          githubId = 48491;
          name = "Elias Probst";
        };
        elijahcaine = {
          email = "elijahcainemv@gmail.com";
          github = "pop";
          githubId = 1897147;
          name = "Elijah Caine";
        };
        Elinvention = {
          email = "elia@elinvention.ovh";
          github = "Elinvention";
          githubId = 5737945;
          name = "Elia Argentieri";
        };
        elitak = {
          email = "elitak@gmail.com";
          github = "elitak";
          githubId = 769073;
          name = "Eric Litak";
        };
        ellis = {
          email = "nixos@ellisw.net";
          github = "ellis";
          githubId = 97852;
          name = "Ellis Whitehead";
        };
        elkowar = {
          email = "thereal.elkowar@gmail.com";
          github = "elkowar";
          githubId = 5300871;
          name = "Leon Kowarschick";
        };
        elnudev = {
          email = "elnu@elnu.com";
          github = "elnudev";
          githubId = 9874955;
          name = "Elnu";
        };
        elohmeier = {
          email = "elo-nixos@nerdworks.de";
          github = "elohmeier";
          githubId = 2536303;
          name = "Enno Lohmeier";
        };
        elvishjerricco = {
          email = "elvishjerricco@gmail.com";
          github = "ElvishJerricco";
          githubId = 1365692;
          name = "Will Fancher";
        };
        emattiza = {
          email = "nix@mattiza.dev";
          github = "emattiza";
          githubId = 11719476;
          name = "Evan Mattiza";
        };
        emmabastas = {
          email = "emma.bastas@protonmail.com";
          matrix = "@emmabastas:matrix.org";
          github = "emmabastas";
          githubId = 22533224;
          name = "Emma Bastås";
        };
        emmanuelrosa = {
          email = "emmanuelrosa@protonmail.com";
          matrix = "@emmanuelrosa:matrix.org";
          github = "emmanuelrosa";
          githubId = 13485450;
          name = "Emmanuel Rosa";
        };
        emptyflask = {
          email = "jon@emptyflask.dev";
          github = "emptyflask";
          githubId = 28287;
          name = "Jon Roberts";
        };
        endgame = {
          email = "jack@jackkelly.name";
          github = "endgame";
          githubId = 231483;
          name = "Jack Kelly";
        };
        enorris = {
          name = "Eric Norris";
          email = "erictnorris@gmail.com";
          github = "ericnorris";
          githubId = 1906605;
        };
        Enteee = {
          email = "nix@duckpond.ch";
          github = "Enteee";
          githubId = 5493775;
          name = "Ente";
        };
        Enzime = {
          email = "enzime@users.noreply.github.com";
          github = "Enzime";
          githubId = 10492681;
          name = "Michael Hoang";
        };
        eonpatapon = {
          email = "eon@patapon.info";
          github = "eonpatapon";
          githubId = 418227;
          name = "Jean-Philippe Braun";
        };
        eperuffo = {
          email = "info@emanueleperuffo.com";
          github = "emanueleperuffo";
          githubId = 5085029;
          name = "Emanuele Peruffo";
        };
        equirosa = {
          email = "eduardo@eduardoquiros.com";
          github = "equirosa";
          githubId = 39096810;
          name = "Eduardo Quiros";
        };
        eqyiel = {
          email = "ruben@maher.fyi";
          github = "eqyiel";
          githubId = 3422442;
          name = "Ruben Maher";
        };
        eraserhd = {
          email = "jason.m.felice@gmail.com";
          github = "eraserhd";
          githubId = 147284;
          name = "Jason Felice";
        };
        ercao = {
          email = "vip@ercao.cn";
          github = "ercao";
          githubId = 51725284;
          name = "ercao";
          keys = [{
            fingerprint = "F3B0 36F7 B0CB 0964 3C12  D3C7 FFAB D125 7ECF 0889";
          }];
        };
        erdnaxe = {
          email = "erdnaxe@crans.org";
          github = "erdnaxe";
          githubId = 2663216;
          name = "Alexandre Iooss";
          keys = [{
            fingerprint = "2D37 1AD2 7E2B BC77 97E1  B759 6C79 278F 3FCD CC02";
          }];
        };
        ereslibre = {
          email = "ereslibre@ereslibre.es";
          matrix = "@ereslibre:matrix.org";
          github = "ereslibre";
          githubId = 8706;
          name = "Rafael Fernández López";
        };
        ericbmerritt = {
          email = "eric@afiniate.com";
          github = "ericbmerritt";
          githubId = 4828;
          name = "Eric Merritt";
        };
        ericdallo = {
          email = "ercdll1337@gmail.com";
          github = "ericdallo";
          githubId = 7820865;
          name = "Eric Dallo";
        };
        ericsagnes = {
          email = "eric.sagnes@gmail.com";
          github = "ericsagnes";
          githubId = 367880;
          name = "Eric Sagnes";
        };
        ericson2314 = {
          email = "John.Ericson@Obsidian.Systems";
          matrix = "@ericson2314:matrix.org";
          github = "Ericson2314";
          githubId = 1055245;
          name = "John Ericson";
        };
        erictapen = {
          email = "kerstin@erictapen.name";
          github = "erictapen";
          githubId = 11532355;
          name = "Kerstin Humm";
          keys = [{
            fingerprint = "F178 B4B4 6165 6D1B 7C15  B55D 4029 3358 C7B9 326B";
          }];
        };
        erikbackman = {
          email = "contact@ebackman.net";
          github = "erikbackman";
          githubId = 46724898;
          name = "Erik Backman";
        };
        erikryb = {
          email = "erik.rybakken@math.ntnu.no";
          github = "erikryb";
          githubId = 3787281;
          name = "Erik Rybakken";
        };
        erin = {
          name = "Erin van der Veen";
          email = "erin@erinvanderveen.nl";
          github = "ErinvanderVeen";
          githubId = 10973664;
        };
        erosennin = {
          email = "ag@sologoc.com";
          github = "erosennin";
          githubId = 1583484;
          name = "Andrey Golovizin";
        };
        ersin = {
          email = "me@ersinakinci.com";
          github = "ersinakinci";
          githubId = 5427394;
          name = "Ersin Akinci";
        };
        ertes = {
          email = "esz@posteo.de";
          github = "ertes";
          githubId = 1855930;
          name = "Ertugrul Söylemez";
        };
        esclear = {
          email = "esclear@users.noreply.github.com";
          github = "esclear";
          githubId = 7432848;
          name = "Daniel Albert";
        };
        eskytthe = {
          email = "eskytthe@gmail.com";
          github = "eskytthe";
          githubId = 2544204;
          name = "Erik Skytthe";
        };
        ethancedwards8 = {
          email = "ethan@ethancedwards.com";
          github = "ethancedwards8";
          githubId = 60861925;
          name = "Ethan Carter Edwards";
          keys = [{
            fingerprint = "0E69 0F46 3457 D812 3387  C978 F93D DAFA 26EF 2458";
          }];
        };
        ethercrow = {
          email = "ethercrow@gmail.com";
          github = "ethercrow";
          githubId = 222467;
          name = "Dmitry Ivanov";
        };
        ethindp = {
          name = "Ethin Probst";
          email = "harlydavidsen@gmail.com";
          matrix = "@ethindp:the-gdn.net";
          github = "ethindp";
          githubId = 8030501;
        };
        Etjean = {
          email = "et.jean@outlook.fr";
          github = "Etjean";
          githubId = 32169529;
          name = "Etienne Jean";
        };
        etu = {
          email = "elis@hirwing.se";
          matrix = "@etu:semi.social";
          github = "etu";
          githubId = 461970;
          name = "Elis Hirwing";
          keys = [{
            fingerprint = "67FE 98F2 8C44 CF22 1828  E12F D57E FA62 5C9A 925F";
          }];
        };
        euank = {
          email = "euank-nixpkg@euank.com";
          github = "euank";
          githubId = 2147649;
          name = "Euan Kemp";
        };
        evalexpr = {
          name = "Jonathan Wilkins";
          email = "nixos@wilkins.tech";
          matrix = "@evalexpr:matrix.org";
          github = "evalexpr";
          githubId = 23485511;
          keys = [{
            fingerprint = "8129 5B85 9C5A F703 C2F4  1E29 2D1D 402E 1776 3DD6";
          }];
        };
        evanjs = {
          email = "evanjsx@gmail.com";
          github = "evanjs";
          githubId = 1847524;
          name = "Evan Stoll";
        };
        evax = {
          email = "nixos@evax.fr";
          github = "evax";
          githubId = 599997;
          name = "evax";
        };
        evck = {
          email = "eric@evenchick.com";
          github = "ericevenchick";
          githubId = 195032;
          name = "Eric Evenchick";
        };
        evenbrenden = {
          email = "evenbrenden@gmail.com";
          github = "evenbrenden";
          githubId = 2512008;
          name = "Even Brenden";
        };
        evils = {
          email = "evils.devils@protonmail.com";
          matrix = "@evils:nixos.dev";
          github = "evils";
          githubId = 30512529;
          name = "Evils";
        };
        ewok = {
          email = "ewok@ewok.ru";
          github = "ewok";
          githubId = 454695;
          name = "Artur Taranchiev";
        };
        exarkun = {
          email = "exarkun@twistedmatrix.com";
          github = "exarkun";
          githubId = 254565;
          name = "Jean-Paul Calderone";
        };
        exfalso = {
          email = "0slemi0@gmail.com";
          github = "exFalso";
          githubId = 1042674;
          name = "Andras Slemmer";
        };
        exi = {
          email = "nixos@reckling.org";
          github = "exi";
          githubId = 449463;
          name = "Reno Reckling";
        };
        exlevan = {
          email = "exlevan@gmail.com";
          github = "exlevan";
          githubId = 873530;
          name = "Alexey Levan";
        };
        expipiplus1 = {
          email = "nix@monoid.al";
          matrix = "@ellie:monoid.al";
          github = "expipiplus1";
          githubId = 857308;
          name = "Ellie Hermaszewska";
          keys = [{
            fingerprint = "FC1D 3E4F CBCA 80DF E870  6397 C811 6E3A 0C1C A76A";
          }];
        };
        extends = {
          email = "sharosari@gmail.com";
          github = "ImExtends";
          githubId = 55919390;
          name = "Vincent VILLIAUMEY";
        };
        eyjhb = {
          email = "eyjhbb@gmail.com";
          matrix = "@eyjhb:eyjhb.dk";
          github = "eyJhb";
          githubId = 25955146;
          name = "eyJhb";
        };
        f--t = {
          email = "git@f-t.me";
          github = "f--t";
          githubId = 2817965;
          name = "f--t";
        };
        f4814n = {
          email = "me@f4814n.de";
          github = "f4814";
          githubId = 11909469;
          name = "Fabian Geiselhart";
        };
        fab = {
          email = "mail@fabian-affolter.ch";
          matrix = "@fabaff:matrix.org";
          name = "Fabian Affolter";
          github = "fabaff";
          githubId = 116184;
          keys = [{
            fingerprint = "2F6C 930F D3C4 7E38 6AFA  4EB4 E23C D2DD 36A4 397F";
          }];
        };
        fabiangd = {
          email = "fabian.g.droege@gmail.com";
          name = "Fabian G. Dröge";
          github = "FabianGD";
          githubId = 40316600;
        };
        fabianhauser = {
          email = "fabian.nixos@fh2.ch";
          github = "fabianhauser";
          githubId = 368799;
          name = "Fabian Hauser";
          keys = [{
            fingerprint = "50B7 11F4 3DFD 2018 DCE6  E8D0 8A52 A140 BEBF 7D2C";
          }];
        };
        fabianhjr = {
          email = "fabianhjr@protonmail.com";
          github = "fabianhjr";
          githubId = 303897;
          name = "Fabián Heredia Montiel";
        };
        fadenb = {
          email = "tristan.helmich+nixos@gmail.com";
          github = "fadenb";
          githubId = 878822;
          name = "Tristan Helmich";
        };
        falsifian = {
          email = "james.cook@utoronto.ca";
          github = "falsifian";
          githubId = 225893;
          name = "James Cook";
        };
        farcaller = {
          name = "Vladimir Pouzanov";
          email = "farcaller@gmail.com";
          github = "farcaller";
          githubId = 693;
        };
        fare = {
          email = "fahree@gmail.com";
          github = "fare";
          githubId = 8073;
          name = "Francois-Rene Rideau";
        };
        farlion = {
          email = "florian.peter@gmx.at";
          github = "workflow";
          githubId = 1276854;
          name = "Florian Peter";
        };
        farnoy = {
          email = "jakub@okonski.org";
          github = "farnoy";
          githubId = 345808;
          name = "Jakub Okoński";
        };
        fbeffa = {
          email = "beffa@fbengineering.ch";
          github = "fedeinthemix";
          githubId = 7670450;
          name = "Federico Beffa";
        };
        fbergroth = {
          email = "fbergroth@gmail.com";
          github = "fbergroth";
          githubId = 1211003;
          name = "Fredrik Bergroth";
        };
        fbrs = {
          email = "yuuki@protonmail.com";
          github = "cideM";
          githubId = 4246921;
          name = "Florian Beeres";
        };
        fdns = {
          email = "fdns02@gmail.com";
          github = "fdns";
          githubId = 541748;
          name = "Felipe Espinoza";
        };
        federicoschonborn = {
          name = "Federico Damián Schonborn";
          email = "fdschonborn@gmail.com";
          github = "FedericoSchonborn";
          githubId = 62166915;
          matrix = "@FedericoDSchonborn:matrix.org";
          keys = [
            { fingerprint = "517A 8A6A 09CA A11C 9667  CEE3 193F 70F1 5C9A B0A0"; }
          ];
        };
        fedx-sudo = {
          email = "fedx-sudo@pm.me";
          github = "FedX-sudo";
          githubId = 66258975;
          name = "Fedx sudo";
          matrix = "fedx:matrix.org";
        };
        fee1-dead = {
          email = "ent3rm4n@gmail.com";
          github = "fee1-dead";
          githubId = 43851243;
          name = "Deadbeef";
        };
        fehnomenal = {
          email = "fehnomenal@fehn.systems";
          github = "fehnomenal";
          githubId = 9959940;
          name = "Andreas Fehn";
        };
        felipeqq2 = {
          name = "Felipe Silva";
          email = "nixpkgs@felipeqq2.rocks";
          github = "felipeqq2";
          githubId = 71830138;
          keys = [{ fingerprint = "F5F0 2BCE 3580 BF2B 707A  AA8C 2FD3 4A9E 2671 91B8"; }];
          matrix = "@felipeqq2:pub.solar";
        };
        felixscheinost = {
          name = "Felix Scheinost";
          email = "felix.scheinost@posteo.de";
          github = "felixscheinost";
          githubId = 31761492;
        };
        felixsinger = {
          email = "felixsinger@posteo.net";
          github = "felixsinger";
          githubId = 628359;
          name = "Felix Singer";
        };
        felschr = {
          email = "dev@felschr.com";
          matrix = "@felschr:matrix.org";
          github = "felschr";
          githubId = 3314323;
          name = "Felix Schröter";
          keys = [
            {
              # historical
              fingerprint = "6AB3 7A28 5420 9A41 82D9  0068 910A CB9F 6BD2 6F58";
            }
            {
              fingerprint = "7E08 6842 0934 AA1D 6821  1F2A 671E 39E6 744C 807D";
            }
          ];
        };
        ffinkdevs = {
          email = "fink@h0st.space";
          github = "ffinkdevs";
          githubId = 45924649;
          name = "Fabian Fink";
        };
        fgaz = {
          email = "fgaz@fgaz.me";
          matrix = "@fgaz:matrix.org";
          github = "fgaz";
          githubId = 8182846;
          name = "Francesco Gazzetta";
        };
        figsoda = {
          email = "figsoda@pm.me";
          matrix = "@figsoda:matrix.org";
          github = "figsoda";
          githubId = 40620903;
          name = "figsoda";
        };
        fionera = {
          email = "nix@fionera.de";
          github = "fionera";
          githubId = 5741401;
          name = "Tim Windelschmidt";
        };
        FireyFly = {
          email = "nix@firefly.nu";
          github = "FireyFly";
          githubId = 415760;
          name = "Jonas Höglund";
        };
        firefly-cpp = {
          email = "iztok@iztok-jr-fister.eu";
          github = "firefly-cpp";
          githubId = 1633361;
          name = "Iztok Fister Jr.";
        };
        fishi0x01 = {
          email = "fishi0x01@gmail.com";
          github = "fishi0x01";
          githubId = 10799507;
          name = "Karl Fischer";
        };
        fitzgibbon = {
          name = "Niall FitzGibbon";
          email = "fitzgibbon.niall@gmail.com";
          github = "fitzgibbon";
          githubId = 617048;
        };
        fkautz = {
          name = "Frederick F. Kautz IV";
          email = "fkautz@alumni.cmu.edu";
          github = "fkautz";
          githubId = 135706;
        };
        Flakebi = {
          email = "flakebi@t-online.de";
          github = "Flakebi";
          githubId = 6499211;
          name = "Sebastian Neubauer";
          keys = [{
            fingerprint = "2F93 661D AC17 EA98 A104  F780 ECC7 55EE 583C 1672";
          }];
        };
        fleaz = {
          email = "mail@felixbreidenstein.de";
          matrix = "@fleaz:rainbownerds.de";
          github = "fleaz";
          githubId = 2489598;
          name = "Felix Breidenstein";
        };
        flexagoon = {
          email = "flexagoon@pm.me";
          github = "flexagoon";
          githubId = 66178592;
          name = "Pavel Zolotarevskiy";
        };
        fliegendewurst = {
          email = "arne.keller@posteo.de";
          github = "FliegendeWurst";
          githubId = 12560461;
          name = "Arne Keller";
        };
        flokli = {
          email = "flokli@flokli.de";
          github = "flokli";
          githubId = 183879;
          name = "Florian Klink";
        };
        florentc = {
          email = "florentc@users.noreply.github.com";
          github = "florentc";
          githubId = 1149048;
          name = "Florent Ch.";
        };
        FlorianFranzen = {
          email = "Florian.Franzen@gmail.com";
          github = "FlorianFranzen";
          githubId = 781077;
          name = "Florian Franzen";
        };
        florianjacob = {
          email = "projects+nixos@florianjacob.de";
          github = "florianjacob";
          githubId = 1109959;
          name = "Florian Jacob";
        };
        flosse = {
          email = "mail@markus-kohlhase.de";
          github = "flosse";
          githubId = 276043;
          name = "Markus Kohlhase";
        };
        fluffynukeit = {
          email = "dan@fluffynukeit.com";
          github = "fluffynukeit";
          githubId = 844574;
          name = "Daniel Austin";
        };
        flyfloh = {
          email = "nix@halbmastwurf.de";
          github = "flyfloh";
          githubId = 74379;
          name = "Florian Pester";
        };
        fmoda3 = {
          email = "fmoda3@mac.com";
          github = "fmoda3";
          githubId = 1746471;
          name = "Frank Moda III";
        };
        fmthoma = {
          email = "f.m.thoma@googlemail.com";
          github = "fmthoma";
          githubId = 5918766;
          name = "Franz Thoma";
        };
        fooker = {
          email = "fooker@lab.sh";
          github = "fooker";
          githubId = 405105;
          name = "Dustin Frisch";
        };
        foo-dogsquared = {
          email = "foo.dogsquared@gmail.com";
          github = "foo-dogsquared";
          githubId = 34962634;
          name = "Gabriel Arazas";
        };
        foolnotion = {
          email = "bogdan.burlacu@pm.me";
          github = "foolnotion";
          githubId = 844222;
          name = "Bogdan Burlacu";
          keys = [{
            fingerprint = "B722 6464 838F 8BDB 2BEA  C8C8 5B0E FDDF BA81 6105";
          }];
        };
        forkk = {
          email = "forkk@forkk.net";
          github = "Forkk";
          githubId = 1300078;
          name = "Andrew Okin";
        };
        fornever = {
          email = "friedrich@fornever.me";
          github = "ForNeVeR";
          githubId = 92793;
          name = "Friedrich von Never";
        };
        fortuneteller2k = {
          email = "lythe1107@gmail.com";
          matrix = "@fortuneteller2k:matrix.org";
          github = "fortuneteller2k";
          githubId = 20619776;
          name = "fortuneteller2k";
        };
        fpletz = {
          email = "fpletz@fnordicwalking.de";
          github = "fpletz";
          githubId = 114159;
          name = "Franz Pletz";
          keys = [{
            fingerprint = "8A39 615D CE78 AF08 2E23  F303 846F DED7 7926 17B4";
          }];
        };
        fps = {
          email = "mista.tapas@gmx.net";
          github = "fps";
          githubId = 84968;
          name = "Florian Paul Schmidt";
        };
      
        fragamus = {
          email = "innovative.engineer@gmail.com";
          github = "fragamus";
          githubId = 119691;
          name = "Michael Gough";
        };
        freax13 = {
          email = "erbse.13@gmx.de";
          github = "Freax13";
          githubId = 14952658;
          name = "Tom Dohrmann";
        };
        fredeb = {
          email = "im@fredeb.dev";
          github = "FredeEB";
          githubId = 7551358;
          name = "Frede Emil";
        };
        freezeboy = {
          email = "freezeboy@users.noreply.github.com";
          github = "freezeboy";
          githubId = 13279982;
          name = "freezeboy";
        };
        Fresheyeball = {
          email = "fresheyeball@gmail.com";
          github = "Fresheyeball";
          githubId = 609279;
          name = "Isaac Shapira";
        };
        fridh = {
          email = "fridh@fridh.nl";
          github = "FRidh";
          githubId = 2129135;
          name = "Frederik Rietdijk";
        };
        friedelino = {
          email = "friede.mann@posteo.de";
          github = "friedelino";
          githubId = 46672819;
          name = "Frido Friedemann";
        };
        frlan = {
          email = "frank@frank.uvena.de";
          github = "frlan";
          githubId = 1010248;
          name = "Frank Lanitz";
        };
        fro_ozen = {
          email = "fro_ozen@gmx.de";
          github = "froozen";
          githubId = 1943632;
          name = "fro_ozen";
        };
        frogamic = {
          email = "frogamic@protonmail.com";
          github = "frogamic";
          githubId = 10263813;
          name = "Dominic Shelton";
        };
        Frostman = {
          email = "me@slukjanov.name";
          github = "Frostman";
          githubId = 134872;
          name = "Sergei Lukianov";
        };
        frontsideair = {
          email = "photonia@gmail.com";
          github = "frontsideair";
          githubId = 868283;
          name = "Fatih Altinok";
        };
        fstamour = {
          email = "fr.st-amour@gmail.com";
          github = "fstamour";
          githubId = 2881922;
          name = "Francis St-Amour";
        };
        ftrvxmtrx = {
          email = "ftrvxmtrx@gmail.com";
          github = "ftrvxmtrx";
          githubId = 248148;
          name = "Sigrid Solveig Haflínudóttir";
        };
        fuerbringer = {
          email = "severin@fuerbringer.info";
          github = "fuerbringer";
          githubId = 10528737;
          name = "Severin Fürbringer";
        };
        fufexan = {
          email = "fufexan@protonmail.com";
          github = "fufexan";
          githubId = 36706276;
          name = "Fufezan Mihai";
        };
        fusion809 = {
          email = "brentonhorne77@gmail.com";
          github = "fusion809";
          githubId = 4717341;
          name = "Brenton Horne";
        };
        fuuzetsu = {
          email = "fuuzetsu@fuuzetsu.co.uk";
          github = "Fuuzetsu";
          githubId = 893115;
          name = "Mateusz Kowalczyk";
        };
        fuzen = {
          email = "me@fuzen.cafe";
          github = "Fuzen-py";
          githubId = 17859309;
          name = "Fuzen";
        };
        fxfactorial = {
          email = "edgar.factorial@gmail.com";
          github = "fxfactorial";
          githubId = 3036816;
          name = "Edgar Aroutiounian";
        };
        gabesoft = {
          email = "gabesoft@gmail.com";
          github = "gabesoft";
          githubId = 606000;
          name = "Gabriel Adomnicai";
        };
        Gabriel439 = {
          email = "Gabriel439@gmail.com";
          github = "Gabriella439";
          githubId = 1313787;
          name = "Gabriel Gonzalez";
        };
        gador = {
          email = "florian.brandes@posteo.de";
          github = "gador";
          githubId = 1883533;
          name = "Florian Brandes";
          keys = [{
            fingerprint = "0200 3EF8 8D2B CF2D 8F00  FFDC BBB3 E40E 5379 7FD9";
          }];
        };
        GaetanLepage = {
          email = "gaetan@glepage.com";
          github = "GaetanLepage";
          githubId = 33058747;
          name = "Gaetan Lepage";
        };
        gal_bolle = {
          email = "florent.becker@ens-lyon.org";
          github = "FlorentBecker";
          githubId = 7047019;
          name = "Florent Becker";
        };
        galagora = {
          email = "lightningstrikeiv@gmail.com";
          github = "Galagora";
          githubId = 45048741;
          name = "Alwanga Oyango";
        };
        gamb = {
          email = "adam.gamble@pm.me";
          github = "gamb";
          githubId = 293586;
          name = "Adam Gamble";
        };
        garbas = {
          email = "rok@garbas.si";
          github = "garbas";
          githubId = 20208;
          name = "Rok Garbas";
        };
        gardspirito = {
          name = "gardspirito";
          email = "nyxoroso@gmail.com";
          github = "gardspirito";
          githubId = 29687558;
        };
        garrison = {
          email = "jim@garrison.cc";
          github = "garrison";
          githubId = 91987;
          name = "Jim Garrison";
        };
        gavin = {
          email = "gavin.rogers@holo.host";
          github = "gavinrogers";
          githubId = 2430469;
          name = "Gavin Rogers";
        };
        gazally = {
          email = "gazally@runbox.com";
          github = "gazally";
          githubId = 16470252;
          name = "Gemini Lasswell";
        };
        gbpdt = {
          email = "nix@pdtpartners.com";
          github = "gbpdt";
          githubId = 25106405;
          name = "Graham Bennett";
        };
        gbtb = {
          email = "goodbetterthebeast3@gmail.com";
          github = "gbtb";
          githubId = 37017396;
          name = "gbtb";
        };
        gdamjan = {
          email = "gdamjan@gmail.com";
          matrix = "@gdamjan:spodeli.org";
          github = "gdamjan";
          githubId = 81654;
          name = "Damjan Georgievski";
        };
        gdinh = {
          email = "nix@contact.dinh.ai";
          github = "gdinh";
          githubId = 34658064;
          name = "Grace Dinh";
        };
        gebner = {
          email = "gebner@gebner.org";
          github = "gebner";
          githubId = 313929;
          name = "Gabriel Ebner";
        };
        genofire = {
          name = "genofire";
          email = "geno+dev@fireorbit.de";
          github = "genofire";
          githubId = 6905586;
          keys = [{
            fingerprint = "386E D1BF 848A BB4A 6B4A  3C45 FC83 907C 125B C2BC";
          }];
        };
        georgesalkhouri = {
          name = "Georges Alkhouri";
          email = "incense.stitch_0w@icloud.com";
          github = "GeorgesAlkhouri";
          githubId = 6077574;
          keys = [{
            fingerprint = "1608 9E8D 7C59 54F2 6A7A 7BD0 8BD2 09DC C54F D339";
          }];
        };
        georgewhewell = {
          email = "georgerw@gmail.com";
          github = "georgewhewell";
          githubId = 1176131;
          name = "George Whewell";
        };
        georgyo = {
          email = "george@shamm.as";
          github = "georgyo";
          githubId = 19374;
          name = "George Shammas";
          keys = [{
            fingerprint = "D0CF 440A A703 E0F9 73CB  A078 82BB 70D5 41AE 2DB4";
          }];
        };
        gerschtli = {
          email = "tobias.happ@gmx.de";
          github = "Gerschtli";
          githubId = 10353047;
          name = "Tobias Happ";
        };
        gfrascadorio = {
          email = "gfrascadorio@tutanota.com";
          github = "gfrascadorio";
          githubId = 37602871;
          name = "Galois";
        };
        ggpeti = {
          email = "ggpeti@gmail.com";
          matrix = "@ggpeti:ggpeti.com";
          github = "ggPeti";
          githubId = 3217744;
          name = "Peter Ferenczy";
        };
        ghostbuster91 = {
          name = "Kasper Kondzielski";
          email = "kghost0@gmail.com";
          github = "ghostbuster91";
          githubId = 5662622;
        };
        ghuntley = {
          email = "ghuntley@ghuntley.com";
          github = "ghuntley";
          githubId = 127353;
          name = "Geoffrey Huntley";
        };
        gila = {
          email = "jeffry.molanus@gmail.com";
          github = "gila";
          githubId = 15957973;
          name = "Jeffry Molanus";
        };
        gilice = {
          email = "gilice@proton.me";
          github = "gilice";
          githubId = 104317939;
          name = "gilice";
        };
        gilligan = {
          email = "tobias.pflug@gmail.com";
          github = "gilligan";
          githubId = 27668;
          name = "Tobias Pflug";
        };
        gin66 = {
          email = "jochen@kiemes.de";
          github = "gin66";
          githubId = 5549373;
          name = "Jochen Kiemes";
        };
        giogadi = {
          email = "lgtorres42@gmail.com";
          github = "giogadi";
          githubId = 1713676;
          name = "Luis G. Torres";
        };
        GKasparov = {
          email = "mizozahr@gmail.com";
          github = "GKasparov";
          githubId = 60962839;
          name = "Mazen Zahr";
        };
        gleber = {
          email = "gleber.p@gmail.com";
          github = "gleber";
          githubId = 33185;
          name = "Gleb Peregud";
        };
        glenns = {
          email = "glenn.searby@gmail.com";
          github = "GlennS";
          githubId = 615606;
          name = "Glenn Searby";
        };
        glittershark = {
          name = "Griffin Smith";
          email = "root@gws.fyi";
          github = "glittershark";
          githubId = 1481027;
          keys = [{
            fingerprint = "0F11 A989 879E 8BBB FDC1  E236 44EF 5B5E 861C 09A7";
          }];
        };
        gloaming = {
          email = "ch9871@gmail.com";
          github = "gloaming";
          githubId = 10156748;
          name = "Craig Hall";
        };
        globin = {
          email = "mail@glob.in";
          github = "globin";
          githubId = 1447245;
          name = "Robin Gloster";
        };
        gnxlxnxx = {
          email = "gnxlxnxx@web.de";
          github = "gnxlxnxx";
          githubId = 25820499;
          name = "Roman Kretschmer";
        };
        goertzenator = {
          email = "daniel.goertzen@gmail.com";
          github = "goertzenator";
          githubId = 605072;
          name = "Daniel Goertzen";
        };
        goibhniu = {
          email = "cillian.deroiste@gmail.com";
          github = "cillianderoiste";
          githubId = 643494;
          name = "Cillian de Róiste";
        };
        GoldsteinE = {
          email = "root@goldstein.rs";
          github = "GoldsteinE";
          githubId = 12019211;
          name = "Maximilian Siling";
          keys = [{
            fingerprint = "0BAF 2D87 CB43 746F 6237  2D78 DE60 31AB A0BB 269A";
          }];
        };
        Gonzih = {
          email = "gonzih@gmail.com";
          github = "Gonzih";
          githubId = 266275;
          name = "Max Gonzih";
        };
        goodrone = {
          email = "goodrone@gmail.com";
          github = "goodrone";
          githubId = 1621335;
          name = "Andrew Trachenko";
        };
        gordias = {
          name = "Gordias";
          email = "gordias@disroot.org";
          github = "gordiasdot";
          githubId = 94724133;
          keys = [{
            fingerprint = "C006 B8A0 0618 F3B6 E0E4  2ECD 5D47 2848 30FA A4FA";
          }];
        };
        gotcha = {
          email = "gotcha@bubblenet.be";
          github = "gotcha";
          githubId = 105204;
          name = "Godefroid Chapelle";
        };
        govanify = {
          name = "Gauvain 'GovanifY' Roussel-Tarbouriech";
          email = "gauvain@govanify.com";
          github = "GovanifY";
          githubId = 6375438;
          keys = [{
            fingerprint = "5214 2D39 A7CE F8FA 872B  CA7F DE62 E1E2 A614 5556";
          }];
        };
        gp2112 = {
          email = "me@guip.dev";
          github = "gp2112";
          githubId = 26512375;
          name = "Guilherme Paixão";
          keys = [{
            fingerprint = "4382 7E28 86E5 C34F 38D5  7753 8C81 4D62 5FBD 99D1";
          }];
        };
        gpanders = {
          name = "Gregory Anders";
          email = "greg@gpanders.com";
          github = "gpanders";
          githubId = 8965202;
          keys = [{
            fingerprint = "B9D5 0EDF E95E ECD0 C135  00A9 56E9 3C2F B6B0 8BDB";
          }];
        };
        gpl = {
          email = "nixos-6c64ce18-bbbc-414f-8dcb-f9b6b47fe2bc@isopleth.org";
          github = "gpl";
          githubId = 39648069;
          name = "isogram";
        };
        gpyh = {
          email = "yacine.hmito@gmail.com";
          github = "yacinehmito";
          githubId = 6893840;
          name = "Yacine Hmito";
        };
        graham33 = {
          email = "graham@grahambennett.org";
          github = "graham33";
          githubId = 10908649;
          name = "Graham Bennett";
        };
        grahamc = {
          email = "graham@grahamc.com";
          github = "grahamc";
          githubId = 76716;
          name = "Graham Christensen";
        };
        gravndal = {
          email = "gaute.ravndal+nixos@gmail.com";
          github = "gravndal";
          githubId = 4656860;
          name = "Gaute Ravndal";
        };
        graysonhead = {
          email = "grayson@graysonhead.net";
          github = "graysonhead";
          githubId = 6179496;
          name = "Grayson Head";
        };
        grburst = {
          email = "GRBurst@protonmail.com";
          github = "GRBurst";
          githubId = 4647221;
          name = "GRBurst";
          keys = [{
            fingerprint = "7FC7 98AB 390E 1646 ED4D  8F1F 797F 6238 68CD 00C2";
          }];
        };
        greizgh = {
          email = "greizgh@ephax.org";
          github = "greizgh";
          githubId = 1313624;
          name = "greizgh";
        };
        greydot = {
          email = "lanablack@amok.cc";
          github = "greydot";
          githubId = 7385287;
          name = "Lana Black";
        };
        gridaphobe = {
          email = "eric@seidel.io";
          github = "gridaphobe";
          githubId = 201997;
          name = "Eric Seidel";
        };
        grindhold = {
          name = "grindhold";
          email = "grindhold+nix@skarphed.org";
          github = "grindhold";
          githubId = 2592640;
        };
        gspia = {
          email = "iahogsp@gmail.com";
          github = "gspia";
          githubId = 3320792;
          name = "gspia";
        };
        guibert = {
          email = "david.guibert@gmail.com";
          github = "dguibert";
          githubId = 1178864;
          name = "David Guibert";
        };
        groodt = {
          email = "groodt@gmail.com";
          github = "groodt";
          githubId = 343415;
          name = "Greg Roodt";
        };
        grnnja = {
          email = "grnnja@gmail.com";
          github = "grnnja";
          githubId = 31556469;
          name = "Prem Netsuwan";
        };
        gruve-p = {
          email = "groestlcoin@gmail.com";
          github = "gruve-p";
          githubId = 11212268;
          name = "gruve-p";
        };
        gschwartz = {
          email = "gsch@pennmedicine.upenn.edu";
          github = "GregorySchwartz";
          githubId = 2490088;
          name = "Gregory Schwartz";
        };
        gtrunsec = {
          email = "gtrunsec@hardenedlinux.org";
          github = "GTrunSec";
          githubId = 21156405;
          name = "GuangTao Zhang";
        };
        guibou = {
          email = "guillaum.bouchard@gmail.com";
          github = "guibou";
          githubId = 9705357;
          name = "Guillaume Bouchard";
        };
        GuillaumeDesforges = {
          email = "aceus02@gmail.com";
          github = "GuillaumeDesforges";
          githubId = 1882000;
          name = "Guillaume Desforges";
        };
        guillaumekoenig = {
          email = "guillaume.edward.koenig@gmail.com";
          github = "guillaumekoenig";
          githubId = 10654650;
          name = "Guillaume Koenig";
        };
        guserav = {
          email = "guserav@users.noreply.github.com";
          github = "guserav";
          githubId = 28863828;
          name = "guserav";
        };
        guyonvarch = {
          email = "joris@guyonvarch.me";
          github = "guyonvarch";
          githubId = 6768842;
          name = "Joris Guyonvarch";
        };
        gvolpe = {
          email = "volpegabriel@gmail.com";
          github = "gvolpe";
          githubId = 443978;
          name = "Gabriel Volpe";
        };
        gytis-ivaskevicius = {
          name = "Gytis Ivaskevicius";
          email = "me@gytis.io";
          matrix = "@gytis-ivaskevicius:matrix.org";
          github = "gytis-ivaskevicius";
          githubId = 23264966;
        };
        h7x4 = {
          name = "h7x4";
          email = "h7x4@nani.wtf";
          matrix = "@h7x4:nani.wtf";
          github = "h7x4";
          githubId = 14929991;
          keys = [{
            fingerprint = "F7D3 7890 228A 9074 40E1  FD48 46B9 228E 814A 2AAC";
          }];
        };
        hagl = {
          email = "harald@glie.be";
          github = "hagl";
          githubId = 1162118;
          name = "Harald Gliebe";
        };
        hakuch = {
          email = "hakuch@gmail.com";
          github = "hakuch";
          githubId = 1498782;
          name = "Jesse Haber-Kucharsky";
        };
        hamburger1984 = {
          email = "hamburger1984@gmail.com";
          github = "hamburger1984";
          githubId = 438976;
          name = "Andreas Krohn";
        };
        hamhut1066 = {
          email = "github@hamhut1066.com";
          github = "moredhel";
          githubId = 1742172;
          name = "Hamish Hutchings";
        };
        hanemile = {
          email = "mail@emile.space";
          github = "HanEmile";
          githubId = 22756350;
          name = "Emile Hansmaennel";
        };
        hansjoergschurr = {
          email = "commits@schurr.at";
          github = "hansjoergschurr";
          githubId = 9850776;
          name = "Hans-Jörg Schurr";
        };
        HaoZeke = {
          email = "r95g10@gmail.com";
          github = "HaoZeke";
          githubId = 4336207;
          name = "Rohit Goswami";
          keys = [{
            fingerprint = "74B1 F67D 8E43 A94A 7554  0768 9CCC E364 02CB 49A6";
          }];
        };
        happyalu = {
          email = "alok@parlikar.com";
          github = "happyalu";
          githubId = 231523;
          name = "Alok Parlikar";
        };
        happysalada = {
          email = "raphael@megzari.com";
          matrix = "@happysalada:matrix.org";
          github = "happysalada";
          githubId = 5317234;
          name = "Raphael Megzari";
        };
        happy-river = {
          email = "happyriver93@runbox.com";
          github = "happy-river";
          githubId = 54728477;
          name = "Happy River";
        };
        hardselius = {
          email = "martin@hardselius.dev";
          github = "hardselius";
          githubId = 1422583;
          name = "Martin Hardselius";
          keys = [{
            fingerprint = "3F35 E4CA CBF4 2DE1 2E90  53E5 03A6 E6F7 8693 6619";
          }];
        };
        harrisonthorne = {
          email = "harrisonthorne@proton.me";
          github = "harrisonthorne";
          githubId = 33523827;
          name = "Harrison Thorne";
        };
        harvidsen = {
          email = "harvidsen@gmail.com";
          github = "harvidsen";
          githubId = 62279738;
          name = "Håkon Arvidsen";
        };
        haslersn = {
          email = "haslersn@fius.informatik.uni-stuttgart.de";
          github = "haslersn";
          githubId = 33969028;
          name = "Sebastian Hasler";
        };
        havvy = {
          email = "ryan.havvy@gmail.com";
          github = "Havvy";
          githubId = 731722;
          name = "Ryan Scheel";
        };
        hawkw = {
          email = "eliza@elizas.website";
          github = "hawkw";
          githubId = 2796466;
          name = "Eliza Weisman";
        };
        hax404 = {
          email = "hax404foogit@hax404.de";
          matrix = "@hax404:hax404.de";
          github = "hax404";
          githubId = 1379411;
          name = "Georg Haas";
        };
        hbunke = {
          email = "bunke.hendrik@gmail.com";
          github = "hbunke";
          githubId = 1768793;
          name = "Hendrik Bunke";
        };
        hce = {
          email = "hc@hcesperer.org";
          github = "hce";
          githubId = 147689;
          name = "Hans-Christian Esperer";
        };
        hdhog = {
          name = "Serg Larchenko";
          email = "hdhog@hdhog.ru";
          github = "hdhog";
          githubId = 386666;
          keys = [{
            fingerprint = "A25F 6321 AAB4 4151 4085  9924 952E ACB7 6703 BA63";
          }];
        };
        hectorj = {
          email = "hector.jusforgues+nixos@gmail.com";
          github = "hectorj";
          githubId = 2427959;
          name = "Hector Jusforgues";
        };
        hedning = {
          email = "torhedinbronner@gmail.com";
          github = "hedning";
          githubId = 71978;
          name = "Tor Hedin Brønner";
        };
        heel = {
          email = "parizhskiy@gmail.com";
          github = "HeeL";
          githubId = 287769;
          name = "Sergii Paryzhskyi";
        };
        helkafen = {
          email = "arnaudpourseb@gmail.com";
          github = "Helkafen";
          githubId = 2405974;
          name = "Sébastian Méric de Bellefon";
        };
        helium = {
          email = "helium.dev@tuta.io";
          github = "helium18";
          githubId = 86223025;
          name = "helium";
        };
        henkkalkwater = {
          email = "chris+nixpkgs@netsoj.nl";
          github = "HenkKalkwater";
          githubId = 4262067;
          matrix = "@chris:netsoj.nl";
          name = "Chris Josten";
        };
        henkery = {
          email = "jim@reupload.nl";
          github = "henkery";
          githubId = 1923309;
          name = "Jim van Abkoude";
        };
        henrikolsson = {
          email = "henrik@fixme.se";
          github = "henrikolsson";
          githubId = 982322;
          name = "Henrik Olsson";
        };
        henrytill = {
          email = "henrytill@gmail.com";
          github = "henrytill";
          githubId = 6430643;
          name = "Henry Till";
        };
        heph2 = {
          email = "srht@mrkeebs.eu";
          github = "heph2";
          githubId = 87579883;
          name = "Marco";
        };
        herberteuler = {
          email = "herberteuler@gmail.com";
          github = "herberteuler";
          githubId = 1401179;
          name = "Guanpeng Xu";
        };
        hexa = {
          email = "hexa@darmstadt.ccc.de";
          matrix = "@hexa:lossy.network";
          github = "mweinelt";
          githubId = 131599;
          name = "Martin Weinelt";
        };
        hexagonal-sun = {
          email = "dev@mattleach.net";
          github = "hexagonal-sun";
          githubId = 222664;
          name = "Matthew Leach";
        };
        hexchen = {
          email = "nix@lilwit.ch";
          github = "hexchen";
          githubId = 41522204;
          name = "hexchen";
        };
        hh = {
          email = "hh@m-labs.hk";
          github = "HarryMakes";
          githubId = 66358631;
          name = "Harry Ho";
        };
        hhm = {
          email = "heehooman+nixpkgs@gmail.com";
          github = "hhm0";
          githubId = 3656888;
          name = "hhm";
        };
        hhydraa = {
          email = "hcurfman@keemail.me";
          github = "hhydraa";
          githubId = 58676303;
          name = "hhydraa";
        };
        higebu = {
          name = "Yuya Kusakabe";
          email = "yuya.kusakabe@gmail.com";
          github = "higebu";
          githubId = 733288;
        };
        hiljusti = {
          name = "J.R. Hill";
          email = "hiljusti@so.dang.cool";
          github = "hiljusti";
          githubId = 17605298;
        };
        hirenashah = {
          email = "hiren@hiren.io";
          github = "hirenashah";
          githubId = 19825977;
          name = "Hiren Shah";
        };
        hiro98 = {
          email = "hiro@protagon.space";
          github = "vale981";
          githubId = 4025991;
          name = "Valentin Boettcher";
          keys = [{
            fingerprint = "45A9 9917 578C D629 9F5F  B5B4 C22D 4DE4 D7B3 2D19";
          }];
        };
        hjones2199 = {
          email = "hjones2199@gmail.com";
          github = "hjones2199";
          githubId = 5525217;
          name = "Hunter Jones";
        };
        hkjn = {
          email = "me@hkjn.me";
          name = "Henrik Jonsson";
          github = "hkjn";
          githubId = 287215;
          keys = [{
            fingerprint = "D618 7A03 A40A 3D56 62F5  4B46 03EF BF83 9A5F DC15";
          }];
        };
        hleboulanger = {
          email = "hleboulanger@protonmail.com";
          name = "Harold Leboulanger";
          github = "thbkrshw";
          githubId = 33122;
        };
        hlolli = {
          email = "hlolli@gmail.com";
          github = "hlolli";
          githubId = 6074754;
          name = "Hlodver Sigurdsson";
        };
        huantian = {
          name = "David Li";
          email = "davidtianli@gmail.com";
          matrix = "@huantian:huantian.dev";
          github = "huantianad";
          githubId = 20760920;
          keys = [{
            fingerprint = "731A 7A05 AD8B 3AE5 956A  C227 4A03 18E0 4E55 5DE5";
          }];
        };
        hugoreeves = {
          email = "hugo@hugoreeves.com";
          github = "HugoReeves";
          githubId = 20039091;
          name = "Hugo Reeves";
          keys = [{
            fingerprint = "78C2 E81C 828A 420B 269A  EBC1 49FA 39F8 A7F7 35F9";
          }];
        };
        humancalico = {
          email = "humancalico@disroot.org";
          github = "humancalico";
          githubId = 51334444;
          name = "Akshat Agarwal";
        };
        hodapp = {
          email = "hodapp87@gmail.com";
          github = "Hodapp87";
          githubId = 896431;
          name = "Chris Hodapp";
        };
        hollowman6 = {
          email = "hollowman@hollowman.ml";
          github = "HollowMan6";
          githubId = 43995067;
          name = "Songlin Jiang";
        };
        holymonson = {
          email = "holymonson@gmail.com";
          github = "holymonson";
          githubId = 902012;
          name = "Monson Shao";
        };
        hongchangwu = {
          email = "wuhc85@gmail.com";
          github = "hongchangwu";
          githubId = 362833;
          name = "Hongchang Wu";
        };
        hoppla20 = {
          email = "privat@vincentcui.de";
          github = "hoppla20";
          githubId = 25618740;
          name = "Vincent Cui";
        };
        houstdav000 = {
          email = "houstdav000@gmail.com";
          github = "houstdav000";
          githubId = 17628961;
          matrix = "@houstdav000:gh0st.ems.host";
          name = "David Houston";
        };
        hoverbear = {
          email = "operator+nix@hoverbear.org";
          matrix = "@hoverbear:matrix.org";
          github = "Hoverbear";
          githubId = 130903;
          name = "Ana Hobden";
        };
        holgerpeters = {
          name = "Holger Peters";
          email = "holger.peters@posteo.de";
          github = "HolgerPeters";
          githubId = 4097049;
        };
        hqurve = {
          email = "hqurve@outlook.com";
          github = "hqurve";
          githubId = 53281855;
          name = "hqurve";
        };
        hrdinka = {
          email = "c.nix@hrdinka.at";
          github = "hrdinka";
          githubId = 1436960;
          name = "Christoph Hrdinka";
        };
        hrhino = {
          email = "hora.rhino@gmail.com";
          github = "hrhino";
          githubId = 28076058;
          name = "Harrison Houghton";
        };
        hschaeidt = {
          email = "he.schaeidt@gmail.com";
          github = "hschaeidt";
          githubId = 1614615;
          name = "Hendrik Schaeidt";
        };
        htr = {
          email = "hugo@linux.com";
          github = "htr";
          githubId = 39689;
          name = "Hugo Tavares Reis";
        };
        hufman = {
          email = "hufman@gmail.com";
          github = "hufman";
          githubId = 1592375;
          name = "Walter Huf";
        };
        hugolgst = {
          email = "hugo.lageneste@pm.me";
          github = "hugolgst";
          githubId = 15371828;
          name = "Hugo Lageneste";
        };
        huyngo = {
          email = "huyngo@disroot.org";
          github = "Huy-Ngo";
          name = "Ngô Ngọc Đức Huy";
          githubId = 19296926;
          keys = [{
            fingerprint = "DF12 23B1 A9FD C5BE 3DA5  B6F7 904A F1C7 CDF6 95C3";
          }];
        };
        hypersw = {
          email = "baltic@hypersw.net";
          github = "hypersw";
          githubId = 2332070;
          name = "Serge Baltic";
        };
        hyphon81 = {
          email = "zero812n@gmail.com";
          github = "hyphon81";
          githubId = 12491746;
          name = "Masato Yonekawa";
        };
        hyshka = {
          name = "Bryan Hyshka";
          email = "bryan@hyshka.com";
          github = "hyshka";
          githubId = 2090758;
          keys = [{
            fingerprint = "24F4 1925 28C4 8797 E539  F247 DB2D 93D1 BFAA A6EA";
          }];
        };
        hyzual = {
          email = "hyzual@gmail.com";
          github = "Hyzual";
          githubId = 2051507;
          name = "Joris Masson";
        };
        hzeller = {
          email = "h.zeller@acm.org";
          github = "hzeller";
          githubId = 140937;
          name = "Henner Zeller";
        };
        i077 = {
          email = "nixpkgs@imranhossa.in";
          github = "i077";
          githubId = 2789926;
          name = "Imran Hossain";
        };
        iagoq = {
          email = "18238046+iagocq@users.noreply.github.com";
          github = "iagocq";
          githubId = 18238046;
          name = "Iago Manoel Brito";
          keys = [{
            fingerprint = "DF90 9D58 BEE4 E73A 1B8C  5AF3 35D3 9F9A 9A1B C8DA";
          }];
        };
        iammrinal0 = {
          email = "nixpkgs@mrinalpurohit.in";
          matrix = "@iammrinal0:nixos.dev";
          github = "iAmMrinal0";
          githubId = 890062;
          name = "Mrinal";
        };
        iand675 = {
          email = "ian@iankduncan.com";
          github = "iand675";
          githubId = 69209;
          name = "Ian Duncan";
        };
        ianmjones = {
          email = "ian@ianmjones.com";
          github = "ianmjones";
          githubId = 4710;
          name = "Ian M. Jones";
        };
        ianwookim = {
          email = "ianwookim@gmail.com";
          github = "wavewave";
          githubId = 1031119;
          name = "Ian-Woo Kim";
        };
        ibizaman = {
          email = "ibizapeanut@gmail.com";
          github = "ibizaman";
          githubId = 1044950;
          name = "Pierre Penninckx";
          keys = [{
            fingerprint = "A01F 10C6 7176 B2AE 2A34  1A56 D4C5 C37E 6031 A3FE";
          }];
        };
        iblech = {
          email = "iblech@speicherleck.de";
          github = "iblech";
          githubId = 3661115;
          name = "Ingo Blechschmidt";
        };
        icewind1991 = {
          name = "Robin Appelman";
          email = "robin@icewind.nl";
          github = "icewind1991";
          githubId = 1283854;
        };
        icy-thought = {
          name = "Icy-Thought";
          email = "gilganyx@pm.me";
          matrix = "@gilganix:matrix.org";
          github = "Icy-Thought";
          githubId = 53710398;
        };
        idontgetoutmuch = {
          email = "dominic@steinitz.org";
          github = "idontgetoutmuch";
          githubId = 1550265;
          name = "Dominic Steinitz";
        };
        ifurther = {
          email = "55025025+ifurther@users.noreply.github.com";
          github = "ifurther";
          githubId = 55025025;
          name = "Feather Lin";
        };
        igsha = {
          email = "igor.sharonov@gmail.com";
          github = "igsha";
          githubId = 5345170;
          name = "Igor Sharonov";
        };
        iimog = {
          email = "iimog@iimog.org";
          github = "iimog";
          githubId = 7403236;
          name = "Markus J. Ankenbrand";
        };
        ikervagyok = {
          email = "ikervagyok@gmail.com";
          github = "ikervagyok";
          githubId = 7481521;
          name = "Balázs Lengyel";
        };
        ilian = {
          email = "ilian@tuta.io";
          github = "ilian";
          githubId = 25505957;
          name = "Ilian";
        };
        ilikeavocadoes = {
          email = "ilikeavocadoes@hush.com";
          github = "ilikeavocadoes";
          githubId = 36193715;
          name = "Lassi Haasio";
        };
        ilkecan = {
          email = "ilkecan@protonmail.com";
          matrix = "@ilkecan:matrix.org";
          github = "ilkecan";
          githubId = 40234257;
          name = "ilkecan bozdogan";
        };
        imincik = {
          email = "ivan.mincik@gmail.com";
          matrix = "@imincik:matrix.org";
          github = "imincik";
          githubId = 476346;
          name = "Ivan Mincik";
        };
        not-my-segfault = {
          email = "michal@tar.black";
          matrix = "@michal:tar.black";
          github = "not-my-segfault";
          githubId = 30374463;
          name = "Michal S.";
        };
        illegalprime = {
          email = "themichaeleden@gmail.com";
          github = "illegalprime";
          githubId = 4401220;
          name = "Michael Eden";
        };
        illiusdope = {
          email = "mat@marini.ca";
          github = "illiusdope";
          githubId = 61913481;
          name = "Mat Marini";
        };
        illustris = {
          email = "me@illustris.tech";
          github = "illustris";
          githubId = 3948275;
          name = "Harikrishnan R";
        };
        ilya-fedin = {
          email = "fedin-ilja2010@ya.ru";
          github = "ilya-fedin";
          githubId = 17829319;
          name = "Ilya Fedin";
        };
        ilya-kolpakov = {
          email = "ilya.kolpakov@gmail.com";
          github = "ilya-kolpakov";
          githubId = 592849;
          name = "Ilya Kolpakov";
        };
        ilyakooo0 = {
          name = "Ilya Kostyuchenko";
          email = "ilyakooo0@gmail.com";
          github = "ilyakooo0";
          githubId = 6209627;
        };
        imalison = {
          email = "IvanMalison@gmail.com";
          github = "IvanMalison";
          githubId = 1246619;
          name = "Ivan Malison";
        };
        imalsogreg = {
          email = "imalsogreg@gmail.com";
          github = "imalsogreg";
          githubId = 993484;
          name = "Greg Hale";
        };
        imgabe = {
          email = "gabrielpmonte@hotmail.com";
          github = "ImGabe";
          githubId = 24387926;
          name = "Gabriel Pereira";
        };
        imlonghao = {
          email = "nixos@esd.cc";
          github = "imlonghao";
          githubId = 4951333;
          name = "Hao Long";
        };
        immae = {
          email = "ismael@bouya.org";
          matrix = "@immae:immae.eu";
          github = "immae";
          githubId = 510202;
          name = "Ismaël Bouya";
        };
        impl = {
          email = "noah@noahfontes.com";
          matrix = "@impl:matrix.org";
          github = "impl";
          githubId = 41129;
          name = "Noah Fontes";
          keys = [{
            fingerprint = "F5B2 BE1B 9AAD 98FE 2916  5597 3665 FFF7 9D38 7BAA";
          }];
        };
        imsofi = {
          email = "sofi+git@mailbox.org";
          github = "imsofi";
          githubId = 20756843;
          name = "Sofi";
        };
        imuli = {
          email = "i@imu.li";
          github = "imuli";
          githubId = 4085046;
          name = "Imuli";
        };
        ineol = {
          email = "leo.stefanesco@gmail.com";
          github = "ineol";
          githubId = 37965;
          name = "Léo Stefanesco";
        };
        indeednotjames = {
          email = "nix@indeednotjames.com";
          github = "IndeedNotJames";
          githubId = 55066419;
          name = "Emily Lange";
        };
        infinidoge = {
          name = "Infinidoge";
          email = "infinidoge@inx.moe";
          github = "Infinidoge";
          githubId = 22727114;
        };
        infinisil = {
          email = "contact@infinisil.com";
          matrix = "@infinisil:matrix.org";
          github = "infinisil";
          githubId = 20525370;
          name = "Silvan Mosberger";
          keys = [{
            fingerprint = "6C2B 55D4 4E04 8266 6B7D  DA1A 422E 9EDA E015 7170";
          }];
        };
        ingenieroariel = {
          email = "ariel@nunez.co";
          github = "ingenieroariel";
          githubId = 54999;
          name = "Ariel Nunez";
        };
        iopq = {
          email = "iop_jr@yahoo.com";
          github = "iopq";
          githubId = 1817528;
          name = "Igor Polyakov";
        };
        irenes = {
          name = "Irene Knapp";
          email = "ireneista@gmail.com";
          matrix = "@irenes:matrix.org";
          github = "IreneKnapp";
          githubId = 157678;
          keys = [{
            fingerprint = "E864 BDFA AB55 36FD C905  5195 DBF2 52AF FB26 19FD";
          }];
        };
        ironpinguin = {
          email = "michele@catalano.de";
          github = "ironpinguin";
          githubId = 137306;
          name = "Michele Catalano";
        };
        isgy = {
          name = "isgy";
          email = "isgy@teiyg.com";
          github = "tgys";
          githubId = 13622947;
          keys = [{
            fingerprint = "1412 816B A9FA F62F D051 1975 D3E1 B013 B463 1293";
          }];
        };
        ius = {
          email = "j.de.gram@gmail.com";
          name = "Joerie de Gram";
          matrix = "@ius:nltrix.net";
          github = "ius";
          githubId = 529626;
        };
        ivan = {
          email = "ivan@ludios.org";
          github = "ivan";
          githubId = 4458;
          name = "Ivan Kozik";
        };
        ivan-babrou = {
          email = "nixpkgs@ivan.computer";
          name = "Ivan Babrou";
          github = "bobrik";
          githubId = 89186;
        };
        ivan-timokhin = {
          email = "nixpkgs@ivan.timokhin.name";
          name = "Ivan Timokhin";
          github = "ivan-timokhin";
          githubId = 9802104;
        };
        ivan-tkatchev = {
          email = "tkatchev@gmail.com";
          github = "ivan-tkatchev";
          githubId = 650601;
          name = "Ivan Tkatchev";
        };
        ivanbrennan = {
          email = "ivan.brennan@gmail.com";
          github = "ivanbrennan";
          githubId = 1672874;
          name = "Ivan Brennan";
          keys = [{
            fingerprint = "7311 2700 AB4F 4CDF C68C  F6A5 79C3 C47D C652 EA54";
          }];
        };
        ivankovnatsky = {
          email = "75213+ivankovnatsky@users.noreply.github.com";
          github = "ivankovnatsky";
          githubId = 75213;
          name = "Ivan Kovnatsky";
          keys = [{
            fingerprint = "6BD3 7248 30BD 941E 9180  C1A3 3A33 FA4C 82ED 674F";
          }];
        };
        ivar = {
          email = "ivar.scholten@protonmail.com";
          github = "IvarWithoutBones";
          githubId = 41924494;
          name = "Ivar";
        };
        iwanb = {
          email = "tracnar@gmail.com";
          github = "iwanb";
          githubId = 4035835;
          name = "Iwan";
        };
        ixmatus = {
          email = "parnell@digitalmentat.com";
          github = "ixmatus";
          githubId = 30714;
          name = "Parnell Springmeyer";
        };
        ixxie = {
          email = "matan@fluxcraft.net";
          github = "ixxie";
          githubId = 20320695;
          name = "Matan Bendix Shenhav";
        };
        izorkin = {
          email = "Izorkin@gmail.com";
          github = "Izorkin";
          githubId = 26877687;
          name = "Yurii Izorkin";
        };
        j0xaf = {
          email = "j0xaf@j0xaf.de";
          name = "Jörn Gersdorf";
          github = "j0xaf";
          githubId = 932697;
        };
        j0hax = {
          name = "Johannes Arnold";
          email = "johannes.arnold@stud.uni-hannover.de";
          github = "j0hax";
          githubId = 3802620;
        };
        j0lol = {
          name = "Jo";
          email = "me@j0.lol";
          github = "j0lol";
          githubId = 24716467;
        };
        j4m3s = {
          name = "James Landrein";
          email = "github@j4m3s.eu";
          github = "j4m3s-s";
          githubId = 9413812;
        };
        jacg = {
          name = "Jacek Generowicz";
          email = "jacg@my-post-office.net";
          github = "jacg";
          githubId = 2570854;
        };
        jakehamilton = {
          name = "Jake Hamilton";
          email = "jake.hamilton@hey.com";
          matrix = "@jakehamilton:matrix.org";
          github = "jakehamilton";
          githubId = 7005773;
          keys = [{
            fingerprint = "B982 0250 1720 D540 6A18  2DA8 188E 4945 E85B 2D21";
          }];
        };
        jasoncarr = {
          email = "jcarr250@gmail.com";
          github = "jasoncarr0";
          githubId = 6874204;
          name = "Jason Carr";
        };
        j-brn = {
          email = "me@bricker.io";
          github = "j-brn";
          githubId = 40566146;
          name = "Jonas Braun";
        };
        j-hui = {
          email = "j-hui@cs.columbia.edu";
          github = "j-hui";
          githubId = 11800204;
          name = "John Hui";
        };
        j-keck = {
          email = "jhyphenkeck@gmail.com";
          github = "j-keck";
          githubId = 3081095;
          name = "Jürgen Keck";
        };
        j03 = {
          email = "github@johannesloetzsch.de";
          github = "johannesloetzsch";
          githubId = 175537;
          name = "Johannes Lötzsch";
        };
        jackgerrits = {
          email = "jack@jackgerrits.com";
          github = "jackgerrits";
          githubId = 7558482;
          name = "Jack Gerrits";
        };
        jagajaga = {
          email = "ars.seroka@gmail.com";
          github = "jagajaga";
          githubId = 2179419;
          name = "Arseniy Seroka";
        };
        jakeisnt = {
          name = "Jacob Chvatal";
          email = "jake@isnt.online";
          github = "jakeisnt";
          githubId = 29869612;
        };
        jakelogemann = {
          email = "jake.logemann@gmail.com";
          github = "jakelogemann";
          githubId = 820715;
          name = "Jake Logemann";
        };
        jakestanger = {
          email = "mail@jstanger.dev";
          github = "JakeStanger";
          githubId = 5057870;
          name = "Jake Stanger";
        };
        jakewaksbaum = {
          email = "jake.waksbaum@gmail.com";
          github = "jbaum98";
          githubId = 5283991;
          name = "Jake Waksbaum";
        };
        jakubgs = {
          email = "jakub@gsokolowski.pl";
          github = "jakubgs";
          githubId = 2212681;
          name = "Jakub Grzgorz Sokołowski";
        };
        jamiemagee = {
          email = "jamie.magee@gmail.com";
          github = "JamieMagee";
          githubId = 1358764;
          name = "Jamie Magee";
        };
        jammerful = {
          email = "jammerful@gmail.com";
          github = "jammerful";
          githubId = 20176306;
          name = "jammerful";
        };
        jansol = {
          email = "jan.solanti@paivola.fi";
          github = "jansol";
          githubId = 2588851;
          name = "Jan Solanti";
        };
        jappie = {
          email = "jappieklooster@hotmail.com";
          github = "jappeace";
          githubId = 3874017;
          name = "Jappie Klooster";
        };
        javaguirre = {
          email = "contacto@javaguirre.net";
          github = "javaguirre";
          githubId = 488556;
          name = "Javier Aguirre";
        };
        jayesh-bhoot = {
          name = "Jayesh Bhoot";
          email = "jayesh@bhoot.sh";
          github = "jayeshbhoot";
          githubId = 1915507;
        };
        jb55 = {
          email = "jb55@jb55.com";
          github = "jb55";
          githubId = 45598;
          name = "William Casarin";
        };
        jbcrail = {
          name = "Joseph Crail";
          email = "jbcrail@gmail.com";
          github = "jbcrail";
          githubId = 6038;
        };
        jbedo = {
          email = "cu@cua0.org";
          matrix = "@jb:vk3.wtf";
          github = "jbedo";
          githubId = 372912;
          name = "Justin Bedő";
        };
        jbgi = {
          email = "jb@giraudeau.info";
          github = "jbgi";
          githubId = 221929;
          name = "Jean-Baptiste Giraudeau";
        };
        jc = {
          name = "Josh Cooper";
          email = "josh@cooper.is";
          github = "joshua-cooper";
          githubId = 35612334;
        };
        jceb = {
          name = "Jan Christoph Ebersbach";
          email = "jceb@e-jc.de";
          github = "jceb";
          githubId = 101593;
        };
        jchw = {
          email = "johnwchadwick@gmail.com";
          github = "jchv";
          githubId = 938744;
          name = "John Chadwick";
        };
        jcouyang = {
          email = "oyanglulu@gmail.com";
          github = "jcouyang";
          githubId = 1235045;
          name = "Jichao Ouyang";
          keys = [{
            fingerprint = "A506 C38D 5CC8 47D0 DF01  134A DA8B 833B 5260 4E63";
          }];
        };
        jcs090218 = {
          email = "jcs090218@gmail.com";
          github = "jcs090218";
          githubId = 8685505;
          name = "Jen-Chieh Shen";
        };
        jcumming = {
          email = "jack@mudshark.org";
          github = "jcumming";
          githubId = 1982341;
          name = "Jack Cummings";
        };
        jdagilliland = {
          email = "jdagilliland@gmail.com";
          github = "jdagilliland";
          githubId = 1383440;
          name = "Jason Gilliland";
        };
        jdahm = {
          email = "johann.dahm@gmail.com";
          github = "jdahm";
          githubId = 68032;
          name = "Johann Dahm";
        };
        jdanek = {
          email = "jdanek@redhat.com";
          github = "jirkadanek";
          githubId = 17877663;
          keys = [{
            fingerprint = "D4A6 F051 AD58 2E7C BCED  5439 6927 5CAD F15D 872E";
          }];
          name = "Jiri Daněk";
        };
        jdbaldry = {
          email = "jack.baldry@grafana.com";
          github = "jdbaldry";
          githubId = 4599384;
          name = "Jack Baldry";
        };
        jdehaas = {
          email = "qqlq@nullptr.club";
          github = "jeroendehaas";
          githubId = 117874;
          name = "Jeroen de Haas";
        };
        jdelStrother = {
          email = "me@delstrother.com";
          github = "jdelStrother";
          githubId = 2377;
          name = "Jonathan del Strother";
        };
        jdreaver = {
          email = "johndreaver@gmail.com";
          github = "jdreaver";
          githubId = 1253071;
          name = "David Reaver";
        };
        jduan = {
          name = "Jingjing Duan";
          email = "duanjingjing@gmail.com";
          github = "jduan";
          githubId = 452450;
        };
        jdupak = {
          name = "Jakub Dupak";
          email = "dev@jakubdupak.com";
          github = "jdupak";
          githubId = 22683640;
        };
        jecaro = {
          email = "jeancharles.quillet@gmail.com";
          github = "jecaro";
          githubId = 17029738;
          name = "Jean-Charles Quillet";
        };
        jefdaj = {
          email = "jefdaj@gmail.com";
          github = "jefdaj";
          githubId = 1198065;
          name = "Jeffrey David Johnson";
        };
        jefflabonte = {
          email = "grimsleepless@protonmail.com";
          github = "JeffLabonte";
          githubId = 9425955;
          name = "Jean-François Labonté";
        };
        jensbin = {
          email = "jensbin+git@pm.me";
          github = "jensbin";
          githubId = 1608697;
          name = "Jens Binkert";
        };
        jeremyschlatter = {
          email = "github@jeremyschlatter.com";
          github = "jeremyschlatter";
          githubId = 5741620;
          name = "Jeremy Schlatter";
        };
        jerith666 = {
          email = "github@matt.mchenryfamily.org";
          github = "jerith666";
          githubId = 854319;
          name = "Matt McHenry";
        };
        jeschli = {
          email = "jeschli@gmail.com";
          github = "0mbi";
          githubId = 10786794;
          name = "Markus Hihn";
        };
        jethro = {
          email = "jethrokuan95@gmail.com";
          github = "jethrokuan";
          githubId = 1667473;
          name = "Jethro Kuan";
        };
        jevy = {
          email = "jevin@quickjack.ca";
          github = "jevy";
          githubId = 110620;
          name = "Jevin Maltais";
        };
        jfb = {
          email = "james@yamtime.com";
          github = "tftio";
          githubId = 143075;
          name = "James Felix Black";
        };
        jfchevrette = {
          email = "jfchevrette@gmail.com";
          github = "jfchevrette";
          githubId = 3001;
          name = "Jean-Francois Chevrette";
          keys = [{
            fingerprint = "B612 96A9 498E EECD D5E9  C0F0 67A0 5858 0129 0DC6";
          }];
        };
        jflanglois = {
          email = "yourstruly@julienlanglois.me";
          github = "jflanglois";
          githubId = 18501;
          name = "Julien Langlois";
        };
        jfrankenau = {
          email = "johannes@frankenau.net";
          github = "jfrankenau";
          githubId = 2736480;
          name = "Johannes Frankenau";
        };
        jfroche = {
          name = "Jean-François Roche";
          email = "jfroche@pyxel.be";
          matrix = "@jfroche:matrix.pyxel.cloud";
          github = "jfroche";
          githubId = 207369;
          keys = [{
            fingerprint = "7EB1 C02A B62B B464 6D7C  E4AE D1D0 9DE1 69EA 19A0";
          }];
        };
        jgart = {
          email = "jgart@dismail.de";
          github = "jgarte";
          githubId = 47760695;
          name = "Jorge Gomez";
        };
        jgeerds = {
          email = "jascha@geerds.org";
          github = "jgeerds";
          githubId = 1473909;
          name = "Jascha Geerds";
        };
        jgertm = {
          email = "jger.tm@gmail.com";
          github = "jgertm";
          githubId = 6616642;
          name = "Tim Jaeger";
        };
        jgillich = {
          email = "jakob@gillich.me";
          github = "jgillich";
          githubId = 347965;
          name = "Jakob Gillich";
        };
        jglukasik = {
          email = "joseph@jgl.me";
          github = "jglukasik";
          githubId = 6445082;
          name = "Joseph Lukasik";
        };
        jhh = {
          email = "jeff@j3ff.io";
          github = "jhh";
          githubId = 14412;
          name = "Jeff Hutchison";
        };
        jhhuh = {
          email = "jhhuh.note@gmail.com";
          github = "jhhuh";
          githubId = 5843245;
          name = "Ji-Haeng Huh";
        };
        jhillyerd = {
          email = "james+nixos@hillyerd.com";
          github = "jhillyerd";
          githubId = 2502736;
          name = "James Hillyerd";
        };
        jiegec = {
          name = "Jiajie Chen";
          email = "c@jia.je";
          github = "jiegec";
          githubId = 6127678;
        };
        jiehong = {
          email = "nixos@majiehong.com";
          github = "Jiehong";
          githubId = 1061229;
          name = "Jiehong Ma";
        };
        jirkamarsik = {
          email = "jiri.marsik89@gmail.com";
          github = "jirkamarsik";
          githubId = 184898;
          name = "Jirka Marsik";
        };
        jitwit = {
          email = "jrn@bluefarm.ca";
          github = "jitwit";
          githubId = 51518420;
          name = "jitwit";
        };
        jjjollyjim = {
          email = "jamie@kwiius.com";
          github = "JJJollyjim";
          githubId = 691552;
          name = "Jamie McClymont";
        };
        jk = {
          email = "hello+nixpkgs@j-k.io";
          matrix = "@j-k:matrix.org";
          github = "06kellyjac";
          githubId = 9866621;
          name = "Jack";
        };
        jkarlson = {
          email = "jekarlson@gmail.com";
          github = "jkarlson";
          githubId = 1204734;
          name = "Emil Karlson";
        };
        jlamur = {
          email = "contact@juleslamur.fr";
          github = "jlamur";
          githubId = 7054317;
          name = "Jules Lamur";
          keys = [{
            fingerprint = "B768 6CD7 451A 650D 9C54  4204 6710 CF0C 1CBD 7762";
          }];
        };
        jlesquembre = {
          email = "jl@lafuente.me";
          github = "jlesquembre";
          githubId = 1058504;
          name = "José Luis Lafuente";
        };
        jloyet = {
          email = "ml@fatbsd.com";
          github = "fatpat";
          githubId = 822436;
          name = "Jérôme Loyet";
        };
        jluttine = {
          email = "jaakko.luttinen@iki.fi";
          github = "jluttine";
          githubId = 2195834;
          name = "Jaakko Luttinen";
        };
        jm2dev = {
          email = "jomarcar@gmail.com";
          github = "jm2dev";
          githubId = 474643;
          name = "José Miguel Martínez Carrasco";
        };
        jmagnusj = {
          email = "jmagnusj@gmail.com";
          github = "magnusjonsson";
          githubId = 8900;
          name = "Johan Magnus Jonsson";
        };
        jmc-figueira = {
          email = "business+nixos@jmc-figueira.dev";
          github = "jmc-figueira";
          githubId = 6634716;
          name = "João Figueira";
          keys = [
            # GitHub signing key
            {
              fingerprint = "EC08 7AA3 DEAD A972 F015  6371 DC7A E56A E98E 02D7";
            }
            # Email encryption
            {
              fingerprint = "816D 23F5 E672 EC58 7674  4A73 197F 9A63 2D13 9E30";
            }
          ];
        };
        jmettes = {
          email = "jonathan@jmettes.com";
          github = "jmettes";
          githubId = 587870;
          name = "Jonathan Mettes";
        };
        jmgilman = {
          email = "joshuagilman@gmail.com";
          github = "jmgilman";
          githubId = 2308444;
          name = "Joshua Gilman";
        };
        jo1gi = {
          email = "joakimholm@protonmail.com";
          github = "jo1gi";
          githubId = 26695750;
          name = "Joakim Holm";
        };
        joachifm = {
          email = "joachifm@fastmail.fm";
          github = "joachifm";
          githubId = 41977;
          name = "Joachim Fasting";
        };
        joachimschmidt557 = {
          email = "joachim.schmidt557@outlook.com";
          github = "joachimschmidt557";
          githubId = 28556218;
          name = "Joachim Schmidt";
        };
        joamaki = {
          email = "joamaki@gmail.com";
          github = "joamaki";
          githubId = 1102396;
          name = "Jussi Maki";
        };
        jobojeha = {
          email = "jobojeha@jeppener.de";
          github = "jobojeha";
          githubId = 60272884;
          name = "Jonathan Jeppener-Haltenhoff";
        };
        jocelynthode = {
          email = "jocelyn.thode@gmail.com";
          github = "jocelynthode";
          githubId = 3967312;
          name = "Jocelyn Thode";
        };
        joedevivo = {
           email = "55951+joedevivo@users.noreply.github.com";
           github = "joedevivo";
           githubId = 55951;
           name = "Joe DeVivo";
         };
        joelancaster = {
          email = "joe.a.lancas@gmail.com";
          github = "JoeLancaster";
          githubId = 16760945;
          name = "Joe Lancaster";
        };
        joelburget = {
          email = "joelburget@gmail.com";
          github = "joelburget";
          githubId = 310981;
          name = "Joel Burget";
        };
        joelkoen = {
          email = "mail@joelkoen.com";
          github = "joelkoen";
          githubId = 122502655;
          name = "Joel Koen";
        };
        joelmo = {
          email = "joel.moberg@gmail.com";
          github = "joelmo";
          githubId = 336631;
          name = "Joel Moberg";
        };
        joepie91 = {
          email = "admin@cryto.net";
          matrix = "@joepie91:pixie.town";
          name = "Sven Slootweg";
          github = "joepie91";
          githubId = 1663259;
        };
        joesalisbury = {
          email = "salisbury.joseph@gmail.com";
          github = "JosephSalisbury";
          githubId = 297653;
          name = "Joe Salisbury";
        };
        john-shaffer = {
          email = "jdsha@proton.me";
          github = "john-shaffer";
          githubId = 53870456;
          name = "John Shaffer";
        };
        johanot = {
          email = "write@ownrisk.dk";
          github = "johanot";
          githubId = 998763;
          name = "Johan Thomsen";
        };
        johbo = {
          email = "johannes@bornhold.name";
          github = "johbo";
          githubId = 117805;
          name = "Johannes Bornhold";
        };
        johnazoidberg = {
          email = "git@danielschaefer.me";
          github = "JohnAZoidberg";
          githubId = 5307138;
          name = "Daniel Schäfer";
        };
        johnchildren = {
          email = "john.a.children@gmail.com";
          github = "johnchildren";
          githubId = 32305209;
          name = "John Children";
        };
        johnmh = {
          email = "johnmh@openblox.org";
          github = "JohnMH";
          githubId = 2576152;
          name = "John M. Harris, Jr.";
        };
        johnramsden = {
          email = "johnramsden@riseup.net";
          github = "johnramsden";
          githubId = 8735102;
          name = "John Ramsden";
        };
        johnrichardrinehart = {
          email = "johnrichardrinehart@gmail.com";
          github = "johnrichardrinehart";
          githubId = 6321578;
          name = "John Rinehart";
        };
        johntitor = {
          email = "huyuumi.dev@gmail.com";
          github = "JohnTitor";
          githubId = 25030997;
          name = "Yuki Okushi";
        };
        jojosch = {
          name = "Johannes Schleifenbaum";
          email = "johannes@js-webcoding.de";
          matrix = "@jojosch:jswc.de";
          github = "jojosch";
          githubId = 327488;
          keys = [{
            fingerprint = "7249 70E6 A661 D84E 8B47  678A 0590 93B1 A278 BCD0";
          }];
        };
        joko = {
          email = "ioannis.koutras@gmail.com";
          github = "jokogr";
          githubId = 1252547;
          keys = [{
            # compare with https://keybase.io/joko
            fingerprint = "B154 A8F9 0610 DB45 0CA8  CF39 85EA E7D9 DF56 C5CA";
          }];
          name = "Ioannis Koutras";
        };
        jonaenz = {
          name = "Jona Enzinger";
          email = "5xt3zyy5l@mozmail.com";
          matrix = "@jona:matrix.jonaenz.de";
          github = "JonaEnz";
          githubId = 57130301;
          keys = [{
            fingerprint = "1CC5 B67C EB9A 13A5 EDF6 F10E 0B4A 3662 FC58 9202";
          }];
        };
        jonafato = {
          email = "jon@jonafato.com";
          github = "jonafato";
          githubId = 392720;
          name = "Jon Banafato";
        };
        jonathanmarler = {
          email = "johnnymarler@gmail.com";
          github = "marler8997";
          githubId = 304904;
          name = "Jonathan Marler";
        };
        jonathanreeve = {
          email = "jon.reeve@gmail.com";
          github = "JonathanReeve";
          githubId = 1843676;
          name = "Jonathan Reeve";
        };
        jonnybolton = {
          email = "jonnybolton@gmail.com";
          github = "jonnybolton";
          githubId = 8580434;
          name = "Jonny Bolton";
        };
        jonringer = {
          email = "jonringer117@gmail.com";
          matrix = "@jonringer:matrix.org";
          github = "jonringer";
          githubId = 7673602;
          name = "Jonathan Ringer";
        };
        jordanisaacs = {
          name = "Jordan Isaacs";
          email = "nix@jdisaacs.com";
          github = "jordanisaacs";
          githubId = 19742638;
        };
        jorise = {
          email = "info@jorisengbers.nl";
          github = "JorisE";
          githubId = 1767283;
          name = "Joris Engbers";
        };
        jorsn = {
          name = "Johannes Rosenberger";
          email = "johannes@jorsn.eu";
          github = "jorsn";
          githubId = 4646725;
        };
        joshuafern = {
          name = "Joshua Fern";
          email = "joshuafern@protonmail.com";
          github = "JoshuaFern";
          githubId = 4300747;
        };
        joshvanl = {
          email = " me@joshvanl.dev ";
          github = "JoshVanL";
          githubId = 15893072;
          name = "Josh van Leeuwen";
        };
        jpas = {
          name = "Jarrod Pas";
          email = "jarrod@jarrodpas.com";
          github = "jpas";
          githubId = 5689724;
        };
        jpdoyle = {
          email = "joethedoyle@gmail.com";
          github = "jpdoyle";
          githubId = 1918771;
          name = "Joe Doyle";
        };
        jperras = {
          email = "joel@nerderati.com";
          github = "jperras";
          githubId = 20675;
          name = "Joël Perras";
        };
        jpetrucciani = {
          email = "j@cobi.dev";
          github = "jpetrucciani";
          githubId = 8117202;
          name = "Jacobi Petrucciani";
        };
        jpierre03 = {
          email = "nix@prunetwork.fr";
          github = "jpierre03";
          githubId = 954536;
          name = "Jean-Pierre PRUNARET";
        };
        jpotier = {
          email = "jpo.contributes.to.nixos@marvid.fr";
          github = "jpotier";
          githubId = 752510;
          name = "Martin Potier";
        };
        jqqqqqqqqqq = {
          email = "jqqqqqqqqqq@gmail.com";
          github = "jqqqqqqqqqq";
          githubId = 12872927;
          name = "Curtis Jiang";
        };
        jqueiroz = {
          email = "nixos@johnjq.com";
          github = "jqueiroz";
          githubId = 4968215;
          name = "Jonathan Queiroz";
        };
        jraygauthier = {
          email = "jraygauthier@gmail.com";
          github = "jraygauthier";
          githubId = 4611077;
          name = "Raymond Gauthier";
        };
        jrpotter = {
          email = "jrpotter2112@gmail.com";
          github = "jrpotter";
          githubId = 3267697;
          name = "Joshua Potter";
        };
        jshcmpbll = {
          email = "me@joshuadcampbell.com";
          github = "jshcmpbll";
          githubId = 16374374;
          name = "Joshua Campbell";
        };
        jshholland = {
          email = "josh@inv.alid.pw";
          github = "jshholland";
          githubId = 107689;
          name = "Josh Holland";
        };
        jsierles = {
          email = "joshua@hey.com";
          matrix = "@jsierles:matrix.org";
          name = "Joshua Sierles";
          github = "jsierles";
          githubId = 82;
        };
        jsimonetti = {
          email = "jeroen+nixpkgs@simonetti.nl";
          matrix = "@jeroen:simonetti.nl";
          name = "Jeroen Simonetti";
          github = "jsimonetti";
          githubId = 5478838;
        };
        jsoo1 = {
          email = "jsoo1@asu.edu";
          github = "jsoo1";
          name = "John Soo";
          githubId = 10039785;
        };
        jtcoolen = {
          email = "jtcoolen@pm.me";
          name = "Julien Coolen";
          github = "jtcoolen";
          githubId = 54635632;
          keys = [{
            fingerprint = "4C68 56EE DFDA 20FB 77E8  9169 1964 2151 C218 F6F5";
          }];
        };
        jtobin = {
          email = "jared@jtobin.io";
          github = "jtobin";
          githubId = 1414434;
          name = "Jared Tobin";
        };
        jtojnar = {
          email = "jtojnar@gmail.com";
          matrix = "@jtojnar:matrix.org";
          github = "jtojnar";
          githubId = 705123;
          name = "Jan Tojnar";
        };
        jtrees = {
          email = "me@jtrees.io";
          github = "jtrees";
          githubId = 5802758;
          name = "Joshua Trees";
        };
        juaningan = {
          email = "juaningan@gmail.com";
          github = "uningan";
          githubId = 810075;
          name = "Juan Rodal";
        };
        juboba = {
          email = "juboba@gmail.com";
          github = "juboba";
          githubId = 1189739;
          name = "Julio Borja Barra";
        };
        jugendhacker = {
          name = "j.r";
          email = "j.r@jugendhacker.de";
          github = "jugendhacker";
          githubId = 12773748;
          matrix = "@j.r:chaos.jetzt";
        };
        juliendehos = {
          email = "dehos@lisic.univ-littoral.fr";
          github = "juliendehos";
          githubId = 11947756;
          name = "Julien Dehos";
        };
        julienmalka = {
          email = "julien.malka@me.com";
          github = "JulienMalka";
          githubId = 1792886;
          name = "Julien Malka";
        };
        julm = {
          email = "julm+nixpkgs@sourcephile.fr";
          github = "ju1m";
          githubId = 21160136;
          name = "Julien Moutinho";
        };
        jumper149 = {
          email = "felixspringer149@gmail.com";
          github = "jumper149";
          githubId = 39434424;
          name = "Felix Springer";
        };
        junjihashimoto = {
          email = "junji.hashimoto@gmail.com";
          github = "junjihashimoto";
          githubId = 2469618;
          name = "Junji Hashimoto";
        };
        justinas = {
          email = "justinas@justinas.org";
          github = "justinas";
          githubId = 662666;
          name = "Justinas Stankevičius";
        };
        justinlovinger = {
          email = "git@justinlovinger.com";
          github = "JustinLovinger";
          githubId = 7183441;
          name = "Justin Lovinger";
        };
        justinwoo = {
          email = "moomoowoo@gmail.com";
          github = "justinwoo";
          githubId = 2396926;
          name = "Justin Woo";
        };
        jvanbruegge = {
          email = "supermanitu@gmail.com";
          github = "jvanbruegge";
          githubId = 1529052;
          name = "Jan van Brügge";
          keys = [{
            fingerprint = "3513 5CE5 77AD 711F 3825  9A99 3665 72BE 7D6C 78A2";
          }];
        };
        jwatt = {
          email = "jwatt@broken.watch";
          github = "jjwatt";
          githubId = 2397327;
          name = "Jesse Wattenbarger";
        };
        jwiegley = {
          email = "johnw@newartisans.com";
          github = "jwiegley";
          githubId = 8460;
          name = "John Wiegley";
        };
        jwijenbergh = {
          email = "jeroenwijenbergh@protonmail.com";
          github = "jwijenbergh";
          githubId = 46386452;
          name = "Jeroen Wijenbergh";
        };
        jwoudenberg = {
          email = "nixpkgs@jasperwoudenberg.com";
          github = "jwoudenberg";
          githubId = 1525551;
          name = "Jasper Woudenberg";
        };
        jwygoda = {
          email = "jaroslaw@wygoda.me";
          github = "jwygoda";
          githubId = 20658981;
          name = "Jarosław Wygoda";
        };
        jyp = {
          email = "jeanphilippe.bernardy@gmail.com";
          github = "jyp";
          githubId = 27747;
          name = "Jean-Philippe Bernardy";
        };
        jzellner = {
          email = "jeffz@eml.cc";
          github = "sofuture";
          githubId = 66669;
          name = "Jeff Zellner";
        };
        k3a = {
          email = "git+nix@catmail.app";
          name = "Mario Hros";
          github = "k3a";
          githubId = 966992;
        };
        k900 = {
          name = "Ilya K.";
          email = "me@0upti.me";
          github = "K900";
          githubId = 386765;
          matrix = "@k900:0upti.me";
        };
        kaction = {
          name = "Dmitry Bogatov";
          email = "KAction@disroot.org";
          github = "KAction";
          githubId = 44864956;
          keys = [{
            fingerprint = "3F87 0A7C A7B4 3731 2F13  6083 749F D4DF A2E9 4236";
          }];
        };
        kaiha = {
          email = "kai.harries@gmail.com";
          github = "KaiHa";
          githubId = 6544084;
          name = "Kai Harries";
        };
        kalbasit = {
          email = "wael.nasreddine@gmail.com";
          matrix = "@kalbasit:matrix.org";
          github = "kalbasit";
          githubId = 87115;
          name = "Wael Nasreddine";
        };
        kalekseev = {
          email = "mail@kalekseev.com";
          github = "kalekseev";
          githubId = 367259;
          name = "Konstantin Alekseev";
        };
        kamadorueda = {
          name = "Kevin Amado";
          email = "kamadorueda@gmail.com";
          github = "kamadorueda";
          githubId = 47480384;
          keys = [{
            fingerprint = "2BE3 BAFD 793E A349 ED1F  F00F 04D0 CEAF 916A 9A40";
          }];
        };
        kamilchm = {
          email = "kamil.chm@gmail.com";
          github = "kamilchm";
          githubId = 1621930;
          name = "Kamil Chmielewski";
        };
        kampfschlaefer = {
          email = "arnold@arnoldarts.de";
          github = "kampfschlaefer";
          githubId = 3831860;
          name = "Arnold Krille";
        };
        kanashimia = {
          email = "chad@redpilled.dev";
          github = "kanashimia";
          githubId = 56224949;
          name = "Mia Kanashi";
        };
        karantan = {
          name = "Gasper Vozel";
          email = "karantan@gmail.com";
          github = "karantan";
          githubId = 7062631;
        };
        KarlJoad = {
          email = "karl@hallsby.com";
          github = "KarlJoad";
          githubId = 34152449;
          name = "Karl Hallsby";
        };
        karolchmist = {
          email = "info+nix@chmist.com";
          github = "karolchmist";
          githubId = 1927188;
          name = "karolchmist";
        };
        kayhide = {
          email = "kayhide@gmail.com";
          github = "kayhide";
          githubId = 1730718;
          name = "Hideaki Kawai";
        };
        kazcw = {
          email = "kaz@lambdaverse.org";
          github = "kazcw";
          githubId = 1047859;
          name = "Kaz Wesley";
        };
        kcalvinalvin = {
          email = "calvin@kcalvinalvin.info";
          github = "kcalvinalvin";
          githubId = 37185887;
          name = "Calvin Kim";
        };
        keksbg = {
          email = "keksbg@riseup.net";
          name = "Stella";
          github = "keksbg";
          githubId = 10682187;
          keys = [{
            fingerprint = "AB42 1F18 5A19 A160 AD77  9885 3D6D CA5B 6F2C 2A7A";
          }];
        };
        keldu = {
          email = "mail@keldu.de";
          github = "keldu";
          githubId = 15373888;
          name = "Claudius Holeksa";
        };
        ken-matsui = {
          email = "nix@kmatsui.me";
          github = "ken-matsui";
          githubId = 26405363;
          name = "Ken Matsui";
          keys = [{
            fingerprint = "3611 8CD3 6DE8 3334 B44A  DDE4 1033 60B3 298E E433";
          }];
        };
        kennyballou = {
          email = "kb@devnulllabs.io";
          github = "kennyballou";
          githubId = 2186188;
          name = "Kenny Ballou";
          keys = [{
            fingerprint = "932F 3E8E 1C0F 4A98 95D7  B8B8 B0CA A28A 0295 8308";
          }];
        };
        kenran = {
          email = "johannes.maier@mailbox.org";
          github = "kenranunderscore";
          githubId = 5188977;
          matrix = "@kenran_:matrix.org";
          name = "Johannes Maier";
        };
        kentjames = {
          email = "jameschristopherkent@gmail.com";
          github = "KentJames";
          githubId = 2029444;
          name = "James Kent";
        };
        kephasp = {
          email = "pierre@nothos.net";
          github = "kephas";
          githubId = 762421;
          name = "Pierre Thierry";
        };
        ketzacoatl = {
          email = "ketzacoatl@protonmail.com";
          github = "ketzacoatl";
          githubId = 10122937;
          name = "ketzacoatl";
        };
        kevincox = {
          email = "kevincox@kevincox.ca";
          matrix = "@kevincox:matrix.org";
          github = "kevincox";
          githubId = 494012;
          name = "Kevin Cox";
        };
        kevingriffin = {
          email = "me@kevin.jp";
          github = "kevingriffin";
          githubId = 209729;
          name = "Kevin Griffin";
        };
        kevink = {
          email = "kevin@kevink.dev";
          github = "Unkn0wnCat";
          githubId = 8211181;
          name = "Kevin Kandlbinder";
        };
        kfears = {
          email = "kfearsoff@gmail.com";
          github = "KFearsoff";
          githubId = 66781795;
          matrix = "@kfears:matrix.org";
          name = "KFears";
        };
        kfollesdal = {
          email = "kfollesdal@gmail.com";
          github = "kfollesdal";
          githubId = 546087;
          name = "Kristoffer K. Føllesdal";
        };
        kho-dialga = {
          email = "ivandashenyou@gmail.com";
          github = "Kho-Dialga";
          githubId = 55767703;
          name = "Iván Brito";
        };
        khumba = {
          email = "bog@khumba.net";
          github = "khumba";
          githubId = 788813;
          name = "Bryan Gardiner";
        };
        khushraj = {
          email = "khushraj.rathod@gmail.com";
          github = "khrj";
          githubId = 44947946;
          name = "Khushraj Rathod";
          keys = [{
            fingerprint = "1988 3FD8 EA2E B4EC 0A93  1E22 B77B 2A40 E770 2F19";
          }];
        };
        KibaFox = {
          email = "kiba.fox@foxypossibilities.com";
          github = "KibaFox";
          githubId = 16481032;
          name = "Kiba Fox";
        };
        kidd = {
          email = "raimonster@gmail.com";
          github = "kidd";
          githubId = 25607;
          name = "Raimon Grau";
        };
        kidonng = {
          email = "hi@xuann.wang";
          github = "kidonng";
          githubId = 44045911;
          name = "Kid";
        };
        kierdavis = {
          email = "kierdavis@gmail.com";
          github = "kierdavis";
          githubId = 845652;
          name = "Kier Davis";
        };
        kilimnik = {
          email = "mail@kilimnik.de";
          github = "kilimnik";
          githubId = 5883283;
          name = "Daniel Kilimnik";
        };
        killercup = {
          email = "killercup@gmail.com";
          github = "killercup";
          githubId = 20063;
          name = "Pascal Hertleif";
        };
        kiloreux = {
          email = "kiloreux@gmail.com";
          github = "kiloreux";
          githubId = 6282557;
          name = "Kiloreux Emperex";
        };
        kim0 = {
          email = "email.ahmedkamal@googlemail.com";
          github = "kim0";
          githubId = 59667;
          name = "Ahmed Kamal";
        };
        kimat = {
          email = "mail@kimat.org";
          github = "kimat";
          githubId = 3081769;
          name = "Kimat Boven";
        };
        kimburgess = {
          email = "kim@acaprojects.com";
          github = "kimburgess";
          githubId = 843652;
          name = "Kim Burgess";
        };
        kini = {
          email = "keshav.kini@gmail.com";
          github = "kini";
          githubId = 691290;
          name = "Keshav Kini";
        };
        kirelagin = {
          email = "kirelagin@gmail.com";
          matrix = "@kirelagin:matrix.org";
          github = "kirelagin";
          githubId = 451835;
          name = "Kirill Elagin";
        };
        kirikaza = {
          email = "k@kirikaza.ru";
          github = "kirikaza";
          githubId = 804677;
          name = "Kirill Kazakov";
        };
        kisonecat = {
          email = "kisonecat@gmail.com";
          github = "kisonecat";
          githubId = 148352;
          name = "Jim Fowler";
        };
        kittywitch = {
          email = "kat@inskip.me";
          github = "kittywitch";
          githubId = 67870215;
          name = "Kat Inskip";
          keys = [{
            fingerprint = "9CC6 44B5 69CD A59B C874  C4C9 E8DD E3ED 1C90 F3A0";
          }];
        };
        kiwi = {
          email = "envy1988@gmail.com";
          github = "Kiwi";
          githubId = 35715;
          name = "Robert Djubek";
          keys = [{
            fingerprint = "8992 44FC D291 5CA2 0A97  802C 156C 88A5 B0A0 4B2A";
          }];
        };
        kjeremy = {
          email = "kjeremy@gmail.com";
          name = "Jeremy Kolb";
          github = "kjeremy";
          githubId = 4325700;
        };
        klden = {
          name = "Kenzyme Le";
          email = "kl@kenzymele.com";
          github = "klDen";
          githubId = 5478260;
        };
        klntsky = {
          email = "klntsky@gmail.com";
          name = "Vladimir Kalnitsky";
          github = "klntsky";
          githubId = 18447310;
        };
        kloenk = {
          email = "me@kloenk.dev";
          matrix = "@kloenk:petabyte.dev";
          name = "Finn Behrens";
          github = "Kloenk";
          githubId = 12898828;
          keys = [{
            fingerprint = "6881 5A95 D715 D429 659B  48A4 B924 45CF C954 6F9D";
          }];
        };
        kmcopper = {
          email = "kmcopper@danwin1210.me";
          name = "Kyle Copperfield";
          github = "kmcopper";
          githubId = 57132115;
        };
        kmeakin = {
          email = "karlwfmeakin@gmail.com";
          name = "Karl Meakin";
          github = "Kmeakin";
          githubId = 19665139;
        };
      
        kmein = {
          email = "kmein@posteo.de";
          name = "Kierán Meinhardt";
          github = "kmein";
          githubId = 10352507;
        };
        kmicklas = {
          email = "maintainer@kmicklas.com";
          name = "Ken Micklas";
          github = "kmicklas";
          githubId = 929096;
        };
        knairda = {
          email = "adrian@kummerlaender.eu";
          name = "Adrian Kummerlaender";
          github = "KnairdA";
          githubId = 498373;
        };
        knedlsepp = {
          email = "josef.kemetmueller@gmail.com";
          github = "knedlsepp";
          githubId = 3287933;
          name = "Josef Kemetmüller";
        };
        knl = {
          email = "nikola@knezevic.co";
          github = "knl";
          githubId = 361496;
          name = "Nikola Knežević";
        };
        kolaente = {
          email = "k@knt.li";
          github = "kolaente";
          githubId = 13721712;
          name = "Konrad Langenberg";
        };
        kolbycrouch = {
          email = "kjc.devel@gmail.com";
          github = "kolbycrouch";
          githubId = 6346418;
          name = "Kolby Crouch";
        };
        kolloch = {
          email = "info@eigenvalue.net";
          github = "kolloch";
          githubId = 339354;
          name = "Peter Kolloch";
        };
        konimex = {
          email = "herdiansyah@netc.eu";
          github = "konimex";
          githubId = 15692230;
          name = "Muhammad Herdiansyah";
        };
        koozz = {
          email = "koozz@linux.com";
          github = "koozz";
          githubId = 264372;
          name = "Jan van den Berg";
        };
        koral = {
          email = "koral@mailoo.org";
          github = "k0ral";
          githubId = 524268;
          name = "Koral";
        };
        koslambrou = {
          email = "koslambrou@gmail.com";
          github = "koslambrou";
          githubId = 2037002;
          name = "Konstantinos";
        };
        kototama = {
          email = "kototama@posteo.jp";
          github = "kototama";
          githubId = 128620;
          name = "Kototama";
        };
        kouyk = {
          email = "skykinetic@stevenkou.xyz";
          github = "kouyk";
          githubId = 1729497;
          name = "Steven Kou";
        };
        kovirobi = {
          email = "kovirobi@gmail.com";
          github = "KoviRobi";
          githubId = 1903418;
          name = "Kovacsics Robert";
        };
        kquick = {
          email = "quick@sparq.org";
          github = "kquick";
          githubId = 787421;
          name = "Kevin Quick";
        };
        kradalby = {
          name = "Kristoffer Dalby";
          email = "kristoffer@dalby.cc";
          github = "kradalby";
          githubId = 98431;
        };
        kraem = {
          email = "me@kraem.xyz";
          github = "kraem";
          githubId = 26622971;
          name = "Ronnie Ebrin";
        };
        kragniz = {
          email = "louis@kragniz.eu";
          github = "kragniz";
          githubId = 735008;
          name = "Louis Taylor";
        };
        kranzes = {
          email = "personal@ilanjoselevich.com";
          github = "Kranzes";
          githubId = 56614642;
          name = "Ilan Joselevich";
        };
        krav = {
          email = "kristoffer@microdisko.no";
          github = "krav";
          githubId = 4032;
          name = "Kristoffer Thømt Ravneberg";
        };
        kritnich = {
          email = "kritnich@kritni.ch";
          github = "Kritnich";
          githubId = 22116767;
          name = "Kritnich";
        };
        kroell = {
          email = "nixosmainter@makroell.de";
          github = "rokk4";
          githubId = 17659803;
          name = "Matthias Axel Kröll";
        };
        kristian-brucaj = {
          email = "kbrucaj@gmail.com";
          github = "Kristian-Brucaj";
          githubId = 8893110;
          name = "Kristian Brucaj";
        };
        kristoff3r = {
          email = "k.soeholm@gmail.com";
          github = "kristoff3r";
          githubId = 160317;
          name = "Kristoffer Søholm";
        };
        ktf = {
          email = "giulio.eulisse@cern.ch";
          github = "ktf";
          githubId = 10544;
          name = "Giuluo Eulisse";
        };
        kthielen = {
          email = "kthielen@gmail.com";
          github = "kthielen";
          githubId = 1409287;
          name = "Kalani Thielen";
        };
        ktor = {
          email = "kruszewsky@gmail.com";
          github = "ktor";
          githubId = 99639;
          name = "Pawel Kruszewski";
        };
        kubukoz = {
          email = "kubukoz@gmail.com";
          github = "kubukoz";
          githubId = 894884;
          name = "Jakub Kozłowski";
        };
        kurnevsky = {
          email = "kurnevsky@gmail.com";
          github = "kurnevsky";
          githubId = 2943605;
          name = "Evgeny Kurnevsky";
        };
        kuznero = {
          email = "roman@kuznero.com";
          github = "kuznero";
          githubId = 449813;
          name = "Roman Kuznetsov";
        };
        kwohlfahrt = {
          email = "kai.wohlfahrt@gmail.com";
          github = "kwohlfahrt";
          githubId = 2422454;
          name = "Kai Wohlfahrt";
        };
        kyleondy = {
          email = "kyle@ondy.org";
          github = "KyleOndy";
          githubId = 1640900;
          name = "Kyle Ondy";
          keys = [{
            fingerprint = "3C79 9D26 057B 64E6 D907  B0AC DB0E 3C33 491F 91C9";
          }];
        };
        kylesferrazza = {
          name = "Kyle Sferrazza";
          email = "nixpkgs@kylesferrazza.com";
      
          github = "kylesferrazza";
          githubId = 6677292;
      
          keys = [{
            fingerprint = "5A9A 1C9B 2369 8049 3B48  CF5B 81A1 5409 4816 2372";
          }];
        };
        l-as = {
          email = "las@protonmail.ch";
          matrix = "@Las:matrix.org";
          github = "L-as";
          githubId = 22075344;
          keys = [{
            fingerprint = "A093 EA17 F450 D4D1 60A0  1194 AC45 8A7D 1087 D025";
          }];
          name = "Las Safin";
        };
        l3af = {
          email = "L3afMeAlon3@gmail.com";
          matrix = "@L3afMe:matrix.org";
          github = "L3afMe";
          githubId = 72546287;
          name = "L3af";
        };
        laalsaas = {
          email = "laalsaas@systemli.org";
          github = "laalsaas";
          githubId = 43275254;
          name = "laalsaas";
        };
        lach = {
          email = "iam@lach.pw";
          github = "CertainLach";
          githubId = 6235312;
          keys = [{
            fingerprint = "323C 95B5 DBF7 2D74 8570  C0B7 40B5 D694 8143 175F";
          }];
          name = "Yaroslav Bolyukin";
        };
        lafrenierejm = {
          email = "joseph@lafreniere.xyz";
          github = "lafrenierejm";
          githubId = 11155300;
          keys = [{
            fingerprint = "0375 DD9A EDD1 68A3 ADA3  9EBA EE23 6AA0 141E FCA3";
          }];
          name = "Joseph LaFreniere";
        };
        laikq = {
          email = "gwen@quasebarth.de";
          github = "laikq";
          githubId = 55911173;
          name = "Gwendolyn Quasebarth";
        };
        lammermann = {
          email = "k.o.b.e.r@web.de";
          github = "lammermann";
          githubId = 695526;
          name = "Benjamin Kober";
        };
        larsr = {
          email = "Lars.Rasmusson@gmail.com";
          github = "larsr";
          githubId = 182024;
          name = "Lars Rasmusson";
        };
        lasandell = {
          email = "lasandell@gmail.com";
          github = "lasandell";
          githubId = 2034420;
          name = "Luke Sandell";
        };
        lambda-11235 = {
          email = "taranlynn0@gmail.com";
          github = "lambda-11235";
          githubId = 16354815;
          name = "Taran Lynn";
        };
        lassulus = {
          email = "lassulus@gmail.com";
          matrix = "@lassulus:lassul.us";
          github = "Lassulus";
          githubId = 621759;
          name = "Lassulus";
        };
        layus = {
          email = "layus.on@gmail.com";
          github = "layus";
          githubId = 632767;
          name = "Guillaume Maudoux";
        };
        lblasc = {
          email = "lblasc@znode.net";
          github = "lblasc";
          githubId = 32152;
          name = "Luka Blaskovic";
        };
        lbpdt = {
          email = "nix@pdtpartners.com";
          github = "lbpdt";
          githubId = 45168934;
          name = "Louis Blin";
        };
        lucc = {
          email = "lucc+nix@posteo.de";
          github = "lucc";
          githubId = 1104419;
          name = "Lucas Hoffmann";
        };
        lucasew = {
          email = "lucas59356@gmail.com";
          github = "lucasew";
          githubId = 15693688;
          name = "Lucas Eduardo Wendt";
        };
        lde = {
          email = "lilian.deloche@puck.fr";
          github = "lde";
          githubId = 1447020;
          name = "Lilian Deloche";
        };
        ldelelis = {
          email = "ldelelis@est.frba.utn.edu.ar";
          github = "ldelelis";
          githubId = 20250323;
          name = "Lucio Delelis";
        };
        ldenefle = {
          email = "ldenefle@gmail.com";
          github = "ldenefle";
          githubId = 20558127;
          name = "Lucas Denefle";
        };
        ldesgoui = {
          email = "ldesgoui@gmail.com";
          matrix = "@ldesgoui:matrix.org";
          github = "ldesgoui";
          githubId = 2472678;
          name = "Lucas Desgouilles";
        };
        league = {
          email = "league@contrapunctus.net";
          github = "league";
          githubId = 50286;
          name = "Christopher League";
        };
        leahneukirchen = {
          email = "leah@vuxu.org";
          github = "leahneukirchen";
          githubId = 139;
          name = "Leah Neukirchen";
        };
        lebastr = {
          email = "lebastr@gmail.com";
          github = "lebastr";
          githubId = 887072;
          name = "Alexander Lebedev";
        };
        ledif = {
          email = "refuse@gmail.com";
          github = "ledif";
          githubId = 307744;
          name = "Adam Fidel";
        };
        leemachin = {
          email = "me@mrl.ee";
          github = "leemeichin";
          githubId = 736291;
          name = "Lee Machin";
        };
        leenaars = {
          email = "ml.software@leenaa.rs";
          github = "leenaars";
          githubId = 4158274;
          name = "Michiel Leenaars";
        };
        logo = {
          email = "logo4poop@protonmail.com";
          matrix = "@logo4poop:matrix.org";
          github = "logo4poop";
          githubId = 24994565;
          name = "Isaac Silverstein";
        };
        lom = {
          email = "legendofmiracles@protonmail.com";
          matrix = "@legendofmiracles:matrix.org";
          github = "legendofmiracles";
          githubId = 30902201;
          name = "legendofmiracles";
          keys = [{
            fingerprint = "CC50 F82C 985D 2679 0703  AF15 19B0 82B3 DEFE 5451";
          }];
        };
        leifhelm = {
          email = "jakob.leifhelm@gmail.com";
          github = "leifhelm";
          githubId = 31693262;
          name = "Jakob Leifhelm";
          keys =[{
            fingerprint = "4A82 F68D AC07 9FFD 8BF0  89C4 6817 AA02 3810 0822";
          }];
        };
        leixb = {
          email = "abone9999+nixpkgs@gmail.com";
          matrix = "@leix_b:matrix.org";
          github = "Leixb";
          githubId = 17183803;
          name = "Aleix Boné";
          keys = [{
            fingerprint = "63D3 F436 EDE8 7E1F 1292  24AF FC03 5BB2 BB28 E15D";
          }];
        };
        lejonet = {
          email = "daniel@kuehn.se";
          github = "lejonet";
          githubId = 567634;
          name = "Daniel Kuehn";
        };
        leo60228 = {
          email = "leo@60228.dev";
          matrix = "@leo60228:matrix.org";
          github = "leo60228";
          githubId = 8355305;
          name = "leo60228";
          keys = [{
            fingerprint = "5BE4 98D5 1C24 2CCD C21A  4604 AC6F 4BA0 78E6 7833";
          }];
        };
        leona = {
          email = "nix@leona.is";
          github = "leona-ya";
          githubId = 11006031;
          name = "Leona Maroni";
        };
        leonardoce = {
          email = "leonardo.cecchi@gmail.com";
          github = "leonardoce";
          githubId = 1572058;
          name = "Leonardo Cecchi";
        };
        leshainc = {
          email = "leshainc@fomalhaut.me";
          github = "LeshaInc";
          githubId = 42153076;
          name = "Alexey Nikashkin";
        };
        lesuisse = {
          email = "thomas@gerbet.me";
          github = "LeSuisse";
          githubId = 737767;
          name = "Thomas Gerbet";
        };
        lethalman = {
          email = "lucabru@src.gnome.org";
          github = "lethalman";
          githubId = 480920;
          name = "Luca Bruno";
        };
        leungbk = {
          email = "leungbk@mailfence.com";
          github = "leungbk";
          githubId = 29217594;
          name = "Brian Leung";
        };
        lewo = {
          email = "lewo@abesis.fr";
          matrix = "@lewo:matrix.org";
          github = "nlewo";
          githubId = 3425311;
          name = "Antoine Eiche";
        };
        lexuge = {
          name = "Harry Ying";
          email = "lexugeyky@outlook.com";
          github = "LEXUGE";
          githubId = 13804737;
          keys = [{
            fingerprint = "7FE2 113A A08B 695A C8B8  DDE6 AE53 B4C2 E58E DD45";
          }];
        };
        lf- = {
          email = "nix-maint@lfcode.ca";
          github = "lf-";
          githubId = 6652840;
          name = "Jade";
        };
        lgcl = {
          email = "dev@lgcl.de";
          name = "Leon Vack";
          github = "LogicalOverflow";
          githubId = 5919957;
        };
        lheckemann = {
          email = "git@sphalerite.org";
          github = "lheckemann";
          githubId = 341954;
          name = "Linus Heckemann";
        };
        lhvwb = {
          email = "nathaniel.baxter@gmail.com";
          github = "nathanielbaxter";
          githubId = 307589;
          name = "Nathaniel Baxter";
        };
        liamdiprose = {
          email = "liam@liamdiprose.com";
          github = "liamdiprose";
          githubId = 1769386;
          name = "Liam Diprose";
        };
        libjared = {
          email = "jared@perrycode.com";
          github = "libjared";
          githubId = 3746656;
          matrix = "@libjared:matrix.org";
          name = "Jared Perry";
        };
        liff = {
          email = "liff@iki.fi";
          github = "liff";
          githubId = 124475;
          name = "Olli Helenius";
        };
        lightbulbjim = {
          email = "chris@killred.net";
          github = "lightbulbjim";
          githubId = 4312404;
          name = "Chris Rendle-Short";
        };
        lightdiscord = {
          email = "root@arnaud.sh";
          github = "lightdiscord";
          githubId = 24509182;
          name = "Arnaud Pascal";
        };
        lightquantum = {
          email = "self@lightquantum.me";
          github = "PhotonQuantum";
          githubId = 18749973;
          name = "Yanning Chen";
          matrix = "@self:lightquantum.me";
        };
        lihop = {
          email = "nixos@leroy.geek.nz";
          github = "lihop";
          githubId = 3696783;
          name = "Leroy Hopson";
        };
        lilyball = {
          email = "lily@sb.org";
          github = "lilyball";
          githubId = 714;
          name = "Lily Ballard";
        };
        lilyinstarlight = {
          email = "lily@lily.flowers";
          matrix = "@lily:lily.flowers";
          github = "lilyinstarlight";
          githubId = 298109;
          name = "Lily Foster";
        };
        limeytexan = {
          email = "limeytexan@gmail.com";
          github = "limeytexan";
          githubId = 36448130;
          name = "Michael Brantley";
        };
        linc01n = {
          email = "git@lincoln.hk";
          github = "linc01n";
          githubId = 667272;
          name = "Lincoln Lee";
        };
        linj = {
          name = "Lin Jian";
          email = "me@linj.tech";
          matrix = "@me:linj.tech";
          github = "jian-lin";
          githubId = 75130626;
          keys = [{
            fingerprint = "80EE AAD8 43F9 3097 24B5  3D7E 27E9 7B91 E63A 7FF8";
          }];
        };
        linquize = {
          email = "linquize@yahoo.com.hk";
          github = "linquize";
          githubId = 791115;
          name = "Linquize";
        };
        linsui = {
          email = "linsui555@gmail.com";
          github = "linsui";
          githubId = 36977733;
          name = "linsui";
        };
        linus = {
          email = "linusarver@gmail.com";
          github = "listx";
          githubId = 725613;
          name = "Linus Arver";
        };
        livnev = {
          email = "lev@liv.nev.org.uk";
          github = "livnev";
          githubId = 3964494;
          name = "Lev Livnev";
          keys = [{
            fingerprint = "74F5 E5CC 19D3 B5CB 608F  6124 68FF 81E6 A785 0F49";
          }];
        };
        lourkeur = {
          name = "Louis Bettens";
          email = "louis@bettens.info";
          github = "lourkeur";
          githubId = 15657735;
          keys = [{
            fingerprint = "5B93 9CFA E8FC 4D8F E07A  3AEA DFE1 D4A0 1733 7E2A";
          }];
        };
        lorenzleutgeb = {
          email = "lorenz@leutgeb.xyz";
          github = "lorenzleutgeb";
          githubId = 542154;
          name = "Lorenz Leutgeb";
        };
        luis = {
          email = "luis.nixos@gmail.com";
          github = "Luis-Hebendanz";
          githubId = 22085373;
          name = "Luis Hebendanz";
        };
        luizribeiro = {
          email = "nixpkgs@l9o.dev";
          matrix = "@luizribeiro:matrix.org";
          name = "Luiz Ribeiro";
          github = "luizribeiro";
          githubId = 112069;
          keys = [{
            fingerprint = "97A0 AE5E 03F3 499B 7D7A  65C6 76A4 1432 37EF 5817";
          }];
        };
        lunarequest = {
          email = "nullarequest@vivlaid.net";
          github = "Lunarequest";
          githubId = 30698906;
          name = "Luna D Dragon";
        };
        LunNova = {
          email = "nixpkgs-maintainer@lunnova.dev";
          github = "LunNova";
          githubId = 782440;
          name = "Luna Nova";
        };
        lionello = {
          email = "lio@lunesu.com";
          github = "lionello";
          githubId = 591860;
          name = "Lionello Lunesu";
        };
        lluchs = {
          email = "lukas.werling@gmail.com";
          github = "lluchs";
          githubId = 516527;
          name = "Lukas Werling";
        };
        lnl7 = {
          email = "daiderd@gmail.com";
          github = "LnL7";
          githubId = 689294;
          name = "Daiderd Jordan";
        };
        lo1tuma = {
          email = "schreck.mathias@gmail.com";
          github = "lo1tuma";
          githubId = 169170;
          name = "Mathias Schreck";
        };
        loewenheim = {
          email = "loewenheim@mailbox.org";
          github = "loewenheim";
          githubId = 7622248;
          name = "Sebastian Zivota";
        };
        locallycompact = {
          email = "dan.firth@homotopic.tech";
          github = "locallycompact";
          githubId = 1267527;
          name = "Daniel Firth";
        };
        lockejan = {
          email = "git@smittie.de";
          matrix = "@jan:smittie.de";
          github = "lockejan";
          githubId = 25434434;
          name = "Jan Schmitt";
          keys = [{
            fingerprint = "1763 9903 2D7C 5B82 5D5A  0EAD A2BC 3C6F 1435 1991";
          }];
        };
        lodi = {
          email = "anthony.lodi@gmail.com";
          github = "lodi";
          githubId = 918448;
          name = "Anthony Lodi";
        };
        loicreynier = {
          email = "loic@loicreynier.fr";
          github = "loicreynier";
          githubId = 88983487;
          name = "Loïc Reynier";
        };
        lopsided98 = {
          email = "benwolsieffer@gmail.com";
          github = "lopsided98";
          githubId = 5624721;
          name = "Ben Wolsieffer";
        };
        loskutov = {
          email = "ignat.loskutov@gmail.com";
          github = "loskutov";
          githubId = 1202012;
          name = "Ignat Loskutov";
        };
        lostnet = {
          email = "lost.networking@gmail.com";
          github = "lostnet";
          githubId = 1422781;
          name = "Will Young";
        };
        louisdk1 = {
          email = "louis@louis.dk";
          github = "LouisDK1";
          githubId = 4969294;
          name = "Louis Tim Larsen";
        };
        lovek323 = {
          email = "jason@oconal.id.au";
          github = "lovek323";
          githubId = 265084;
          name = "Jason O'Conal";
        };
        lovesegfault = {
          email = "meurerbernardo@gmail.com";
          matrix = "@lovesegfault:matrix.org";
          github = "lovesegfault";
          githubId = 7243783;
          name = "Bernardo Meurer";
          keys = [{
            fingerprint = "F193 7596 57D5 6DA4 CCD4  786B F4C0 D53B 8D14 C246";
          }];
        };
        lowfatcomputing = {
          email = "andreas.wagner@lowfatcomputing.org";
          github = "lowfatcomputing";
          githubId = 10626;
          name = "Andreas Wagner";
        };
        lrewega = {
          email = "lrewega@c32.ca";
          github = "lrewega";
          githubId = 639066;
          name = "Luke Rewega";
        };
        lromor = {
          email = "leonardo.romor@gmail.com";
          github = "lromor";
          githubId = 1597330;
          name = "Leonardo Romor";
        };
        lschuermann = {
          email = "leon.git@is.currently.online";
          matrix = "@leons:is.currently.online";
          github = "lschuermann";
          githubId = 5341193;
          name = "Leon Schuermann";
        };
        lsix = {
          email = "lsix@lancelotsix.com";
          github = "lsix";
          githubId = 724339;
          name = "Lancelot SIX";
        };
        ltavard = {
          email = "laure.tavard@univ-grenoble-alpes.fr";
          github = "ltavard";
          githubId = 8555953;
          name = "Laure Tavard";
        };
        luc65r = {
          email = "lucas@ransan.tk";
          github = "luc65r";
          githubId = 59375051;
          name = "Lucas Ransan";
        };
        lucperkins = {
          email = "lucperkins@gmail.com";
          github = "lucperkins";
          githubId = 1523104;
          name = "Luc Perkins";
        };
        lucus16 = {
          email = "lars.jellema@gmail.com";
          github = "Lucus16";
          githubId = 2487922;
          name = "Lars Jellema";
        };
        ludo = {
          email = "ludo@gnu.org";
          github = "civodul";
          githubId = 1168435;
          name = "Ludovic Courtès";
        };
        lufia = {
          email = "lufia@lufia.org";
          github = "lufia";
          githubId = 1784379;
          name = "Kyohei Kadota";
        };
        Luflosi = {
          name = "Luflosi";
          email = "luflosi@luflosi.de";
          github = "Luflosi";
          githubId = 15217907;
          keys = [{
            fingerprint = "66D1 3048 2B5F 2069 81A6  6B83 6F98 7CCF 224D 20B9";
          }];
        };
        luispedro = {
          email = "luis@luispedro.org";
          github = "luispedro";
          githubId = 79334;
          name = "Luis Pedro Coelho";
        };
        lukeadams = {
          email = "luke.adams@belljar.io";
          github = "lukeadams";
          githubId = 3508077;
          name = "Luke Adams";
        };
        lukebfox = {
          email = "lbentley-fox1@sheffield.ac.uk";
          github = "lukebfox";
          githubId = 34683288;
          name = "Luke Bentley-Fox";
        };
        lukegb = {
          email = "nix@lukegb.com";
          matrix = "@lukegb:zxcvbnm.ninja";
          github = "lukegb";
          githubId = 246745;
          name = "Luke Granger-Brown";
        };
        lukego = {
          email = "luke@snabb.co";
          github = "lukego";
          githubId = 13791;
          name = "Luke Gorrie";
        };
        luker = {
          email = "luker@fenrirproject.org";
          github = "LucaFulchir";
          githubId = 2486026;
          name = "Luca Fulchir";
        };
        lumi = {
          email = "lumi@pew.im";
          github = "lumi-me-not";
          githubId = 26020062;
          name = "lumi";
        };
        lunik1 = {
          email = "ch.nixpkgs@themaw.xyz";
          matrix = "@lunik1:lunik.one";
          github = "lunik1";
          githubId = 13547699;
          name = "Corin Hoad";
          keys = [{
            fingerprint = "BA3A 5886 AE6D 526E 20B4  57D6 6A37 DF94 8318 8492";
          }];
        };
        lux = {
          email = "lux@lux.name";
          github = "luxferresum";
          githubId = 1208273;
          matrix = "@lux:ontheblueplanet.com";
          name = "Lux";
        };
        luz = {
          email = "luz666@daum.net";
          github = "Luz";
          githubId = 208297;
          name = "Luz";
        };
        lw = {
          email = "lw@fmap.me";
          github = "lolwat97";
          githubId = 2057309;
          name = "Sergey Sofeychuk";
        };
        lxea = {
          email = "nix@amk.ie";
          github = "lxea";
          githubId = 7910815;
          name = "Alex McGrath";
        };
        lynty = {
          email = "ltdong93+nix@gmail.com";
          github = "Lynty";
          githubId = 39707188;
          name = "Lynn Dong";
        };
        m00wl = {
          name = "Moritz Lumme";
          email = "moritz.lumme@gmail.com";
          github = "m00wl";
          githubId = 46034439;
        };
        m1cr0man = {
          email = "lucas+nix@m1cr0man.com";
          github = "m1cr0man";
          githubId = 3044438;
          name = "Lucas Savva";
        };
        ma27 = {
          email = "maximilian@mbosch.me";
          matrix = "@ma27:nicht-so.sexy";
          github = "Ma27";
          githubId = 6025220;
          name = "Maximilian Bosch";
        };
        ma9e = {
          email = "sean@lfo.team";
          github = "furrycatherder";
          githubId = 36235154;
          name = "Sean Haugh";
        };
        maaslalani = {
          email = "maaslalani0@gmail.com";
          github = "maaslalani";
          githubId = 42545625;
          name = "Maas Lalani";
        };
        maddiethecafebabe = {
          email = "maddie@cafebabe.date";
          github = "maddiethecafebabe";
          githubId = 75337286;
          name = "Madeline S.";
        };
        madjar = {
          email = "georges.dubus@compiletoi.net";
          github = "madjar";
          githubId = 109141;
          name = "Georges Dubus";
        };
        madonius = {
          email = "nixos@madoni.us";
          github = "madonius";
          githubId = 1246752;
          name = "madonius";
          matrix = "@madonius:entropia.de";
        };
        Madouura = {
          email = "madouura@gmail.com";
          github = "Madouura";
          githubId = 93990818;
          name = "Madoura";
        };
        mafo = {
          email = "Marc.Fontaine@gmx.de";
          github = "MarcFontaine";
          githubId = 1433367;
          name = "Marc Fontaine";
        };
        magenbluten = {
          email = "magenbluten@codemonkey.cc";
          github = "magenbluten";
          githubId = 1140462;
          name = "magenbluten";
        };
        magnetophon = {
          email = "bart@magnetophon.nl";
          github = "magnetophon";
          githubId = 7645711;
          name = "Bart Brouns";
        };
        magnouvean = {
          email = "rg0zjsyh@anonaddy.me";
          github = "magnouvean";
          githubId = 85435692;
          name = "Maxwell Berg";
        };
        mahe = {
          email = "matthias.mh.herrmann@gmail.com";
          github = "2chilled";
          githubId = 1238350;
          name = "Matthias Herrmann";
        };
        majesticmullet = {
          email = "hoccthomas@gmail.com.au";
          github = "MajesticMullet";
          githubId = 31056089;
          name = "Tom Ho";
        };
        majewsky = {
          email = "majewsky@gmx.net";
          github = "majewsky";
          githubId = 24696;
          name = "Stefan Majewsky";
        };
        majiir = {
          email = "majiir@nabaal.net";
          github = "Majiir";
          githubId = 963511;
          name = "Majiir Paktu";
        };
        makefu = {
          email = "makefu@syntax-fehler.de";
          github = "makefu";
          githubId = 115218;
          name = "Felix Richter";
        };
        malo = {
          email = "mbourgon@gmail.com";
          github = "malob";
          githubId = 2914269;
          name = "Malo Bourgon";
        };
        malvo = {
          email = "malte@malvo.org";
          github = "malte-v";
          githubId = 34393802;
          name = "Malte Voos";
        };
        malbarbo = {
          email = "malbarbo@gmail.com";
          github = "malbarbo";
          githubId = 1678126;
          name = "Marco A L Barbosa";
        };
        malyn = {
          email = "malyn@strangeGizmo.com";
          github = "malyn";
          githubId = 346094;
          name = "Michael Alyn Miller";
        };
        manojkarthick = {
          email = "smanojkarthick@gmail.com";
          github = "manojkarthick";
          githubId = 7802795;
          name = "Manoj Karthick";
        };
        manveru = {
          email = "m.fellinger@gmail.com";
          matrix = "@manveru:matrix.org";
          github = "manveru";
          githubId = 3507;
          name = "Michael Fellinger";
        };
        maralorn = {
          email = "mail@maralorn.de";
          matrix = "@maralorn:maralorn.de";
          github = "maralorn";
          githubId = 1651325;
          name = "maralorn";
        };
        marcweber = {
          email = "marco-oweber@gmx.de";
          github = "MarcWeber";
          githubId = 34086;
          name = "Marc Weber";
        };
        marcus7070 = {
          email = "marcus@geosol.com.au";
          github = "marcus7070";
          githubId = 50230945;
          name = "Marcus Boyd";
        };
        marenz = {
          email = "marenz@arkom.men";
          github = "marenz2569";
          githubId = 12773269;
          name = "Markus Schmidl";
        };
        markus1189 = {
          email = "markus1189@gmail.com";
          github = "markus1189";
          githubId = 591567;
          name = "Markus Hauck";
        };
        markuskowa = {
          email = "markus.kowalewski@gmail.com";
          github = "markuskowa";
          githubId = 26470037;
          name = "Markus Kowalewski";
        };
        mariaa144 = {
          email = "speechguard_intensivist@aleeas.com";
          github = "mariaa144";
          githubId = 105451387;
          name = "Maria";
        };
        marijanp = {
          name = "Marijan Petričević";
          email = "marijan.petricevic94@gmail.com";
          github = "marijanp";
          githubId = 13599169;
        };
        marius851000 = {
          email = "mariusdavid@laposte.net";
          name = "Marius David";
          github = "marius851000";
          githubId = 22586596;
        };
        marsam = {
          email = "marsam@users.noreply.github.com";
          github = "marsam";
          githubId = 65531;
          name = "Mario Rodas";
        };
        marsupialgutz = {
          email = "mars@possums.xyz";
          github = "pupbrained";
          githubId = 33522919;
          name = "Marshall Arruda";
        };
        martijnvermaat = {
          email = "martijn@vermaat.name";
          github = "martijnvermaat";
          githubId = 623509;
          name = "Martijn Vermaat";
        };
        martinetd = {
          email = "f.ktfhrvnznqxacf@noclue.notk.org";
          github = "martinetd";
          githubId = 1729331;
          name = "Dominique Martinet";
        };
        martingms = {
          email = "martin@mg.am";
          github = "martingms";
          githubId = 458783;
          name = "Martin Gammelsæter";
        };
        martfont = {
          name = "Martino Fontana";
          email = "tinozzo123@tutanota.com";
          github = "SuperSamus";
          githubId = 40663462;
        };
        marzipankaiser = {
          email = "nixos@gaisseml.de";
          github = "marzipankaiser";
          githubId = 2551444;
          name = "Marcial Gaißert";
          keys = [{
            fingerprint = "B573 5118 0375 A872 FBBF  7770 B629 036B E399 EEE9";
          }];
        };
        masipcat = {
          email = "jordi@masip.cat";
          github = "masipcat";
          githubId = 775189;
          name = "Jordi Masip";
        };
        MaskedBelgian = {
          email = "michael.colicchia@imio.be";
          github = "MaskedBelgian";
          githubId = 29855073;
          name = "Michael Colicchia";
        };
        matejc = {
          email = "cotman.matej@gmail.com";
          github = "matejc";
          githubId = 854770;
          name = "Matej Cotman";
        };
        mathnerd314 = {
          email = "mathnerd314.gph+hs@gmail.com";
          github = "Mathnerd314";
          githubId = 322214;
          name = "Mathnerd314";
        };
        math-42 = {
          email = "matheus.4200@gmail.com";
          github = "Math-42";
          githubId = 43853194;
          name = "Matheus Vieira";
        };
        matklad = {
          email = "aleksey.kladov@gmail.com";
          github = "matklad";
          githubId = 1711539;
          name = "matklad";
        };
        matrss = {
          name = "Matthias Riße";
          email = "matthias.risze@t-online.de";
          github = "matrss";
          githubId = 9308656;
        };
        matt-snider = {
          email = "matt.snider@protonmail.com";
          github = "matt-snider";
          githubId = 11810057;
          name = "Matt Snider";
        };
        mattchrist = {
          email = "nixpkgs-matt@christ.systems";
          github = "mattchrist";
          githubId = 952712;
          name = "Matt Christ";
        };
        matthewbauer = {
          email = "mjbauer95@gmail.com";
          github = "matthewbauer";
          githubId = 19036;
          name = "Matthew Bauer";
        };
        matthiasbenaets = {
          email = "matthias.benaets@gmail.com";
          github = "MatthiasBenaets";
          githubId = 89214559;
          name = "Matthias Benaets";
        };
        matthiasbeyer = {
          email = "mail@beyermatthias.de";
          matrix = "@musicmatze:beyermatthi.as";
          github = "matthiasbeyer";
          githubId = 427866;
          name = "Matthias Beyer";
        };
        MatthieuBarthel = {
          email = "matthieu@imatt.ch";
          name = "Matthieu Barthel";
          github = "MatthieuBarthel";
          githubId = 435534;
          keys = [{
            fingerprint = "80EB 0F2B 484A BB80 7BEF  4145 BA23 F10E AADC 2E26";
          }];
        };
        matthuszagh = {
          email = "huszaghmatt@gmail.com";
          github = "matthuszagh";
          githubId = 7377393;
          name = "Matt Huszagh";
        };
        matti-kariluoma = {
          email = "matti@kariluo.ma";
          github = "matti-kariluoma";
          githubId = 279868;
          name = "Matti Kariluoma";
        };
        matthewpi = {
          email = "me+nix@matthewp.io";
          github = "matthewpi";
          githubId = 26559841;
          name = "Matthew Penner";
          keys = [{
            fingerprint = "5118 F1CC B7B0 6C17 4DD1  5267 3131 1906 AD4C F6D6";
          }];
        };
        maurer = {
          email = "matthew.r.maurer+nix@gmail.com";
          github = "maurer";
          githubId = 136037;
          name = "Matthew Maurer";
        };
        mausch = {
          email = "mauricioscheffer@gmail.com";
          github = "mausch";
          githubId = 95194;
          name = "Mauricio Scheffer";
        };
        maxhero = {
          email = "contact@maxhero.dev";
          github = "themaxhero";
          githubId = 4708337;
          name = "Marcelo A. de L. Santos";
        };
        max-niederman = {
          email = "max@maxniederman.com";
          github = "max-niederman";
          githubId = 19580458;
          name = "Max Niederman";
          keys = [{
            fingerprint = "1DE4 424D BF77 1192 5DC4  CF5E 9AED 8814 81D8 444E";
          }];
        };
         maxbrunet = {
          email = "max@brnt.mx";
          github = "maxbrunet";
          githubId = 32458727;
          name = "Maxime Brunet";
          keys = [{
            fingerprint = "E9A2 EE26 EAC6 B3ED 6C10  61F3 4379 62FF 87EC FE2B";
          }];
        };
        maxdamantus = {
          email = "maxdamantus@gmail.com";
          github = "Maxdamantus";
          githubId = 502805;
          name = "Max Zerzouri";
        };
        maxeaubrey = {
          email = "maxeaubrey@gmail.com";
          github = "maxeaubrey";
          githubId = 35892750;
          name = "Maxine Aubrey";
        };
        maxhille = {
          email = "mh@lambdasoup.com";
          github = "maxhille";
          githubId = 693447;
          name = "Max Hille";
        };
        maxhbr = {
          email = "nixos@maxhbr.dev";
          github = "maxhbr";
          githubId = 1187050;
          name = "Maximilian Huber";
        };
        maximsmol = {
          email = "maximsmol@gmail.com";
          github = "maximsmol";
          githubId = 1472826;
          name = "Max Smolin";
        };
        maxux = {
          email = "root@maxux.net";
          github = "maxux";
          githubId = 4141584;
          name = "Maxime Daniel";
        };
        maxwell-lt = {
          email = "maxwell.lt@live.com";
          github = "maxwell-lt";
          githubId = 17859747;
          name = "Maxwell L-T";
        };
        maxxk = {
          email = "maxim.krivchikov@gmail.com";
          github = "maxxk";
          githubId = 1191859;
          name = "Maxim Krivchikov";
        };
        MayNiklas = {
          email = "info@niklas-steffen.de";
          github = "MayNiklas";
          githubId = 44636701;
          name = "Niklas Steffen";
        };
        mazurel = {
          email = "mateusz.mazur@yahoo.com";
          github = "Mazurel";
          githubId = 22836301;
          name = "Mateusz Mazur";
        };
        mbaeten = {
          email = "mbaeten@users.noreply.github.com";
          github = "mbaeten";
          githubId = 2649304;
          name = "M. Baeten";
        };
        mbaillie = {
          email = "martin@baillie.id";
          github = "martinbaillie";
          githubId = 613740;
          name = "Martin Baillie";
        };
        mbbx6spp = {
          email = "me@susanpotter.net";
          github = "mbbx6spp";
          githubId = 564;
          name = "Susan Potter";
        };
        mbe = {
          email = "brandonedens@gmail.com";
          github = "brandonedens";
          githubId = 396449;
          name = "Brandon Edens";
        };
        mbode = {
          email = "maxbode@gmail.com";
          github = "mbode";
          githubId = 9051309;
          name = "Maximilian Bode";
        };
        mboes = {
          email = "mboes@tweag.net";
          github = "mboes";
          githubId = 51356;
          name = "Mathieu Boespflug";
        };
        mbprtpmnr = {
          name = "mbprtpmnr";
          email = "mbprtpmnr@pm.me";
          github = "mbprtpmnr";
          githubId = 88109321;
        };
        mbrgm = {
          email = "marius@yeai.de";
          github = "mbrgm";
          githubId = 2971615;
          name = "Marius Bergmann";
        };
        mcaju = {
          email = "cajum.bugs@yandex.com";
          github = "CajuM";
          githubId = 10420834;
          name = "Mihai-Drosi Caju";
        };
        mcbeth = {
          email = "mcbeth@broggs.org";
          github = "mcbeth";
          githubId = 683809;
          name = "Jeffrey Brent McBeth";
        };
        mcmtroffaes = {
          email = "matthias.troffaes@gmail.com";
          github = "mcmtroffaes";
          githubId = 158568;
          name = "Matthias C. M. Troffaes";
        };
        McSinyx = {
          email = "mcsinyx@disroot.org";
          github = "McSinyx";
          githubId = 13689192;
          name = "Nguyễn Gia Phong";
          keys = [{
            fingerprint = "E90E 11B8 0493 343B 6132  E394 2714 8B2C 06A2 224B";
          }];
        };
        mcwitt = {
          email = "mcwitt@gmail.com";
          github = "mcwitt";
          githubId = 319411;
          name = "Matt Wittmann";
        };
        mdaiter = {
          email = "mdaiter8121@gmail.com";
          github = "mdaiter";
          githubId = 1377571;
          name = "Matthew S. Daiter";
        };
        mdarocha = {
          email = "marek@mdarocha.pl";
          github = "mdarocha";
          githubId = 11572618;
          name = "Marek Darocha";
        };
        mdevlamynck = {
          email = "matthias.devlamynck@mailoo.org";
          github = "mdevlamynck";
          githubId = 4378377;
          name = "Matthias Devlamynck";
        };
        mdlayher = {
          email = "mdlayher@gmail.com";
          github = "mdlayher";
          githubId = 1926905;
          name = "Matt Layher";
          keys = [{
            fingerprint = "D709 03C8 0BE9 ACDC 14F0  3BFB 77BF E531 397E DE94";
          }];
        };
        meain = {
          email = "mail@meain.io";
          matrix = "@meain:matrix.org";
          github = "meain";
          githubId = 14259816;
          name = "Abin Simon";
        };
        meatcar = {
          email = "nixpkgs@denys.me";
          github = "meatcar";
          githubId = 191622;
          name = "Denys Pavlov";
        };
        meditans = {
          email = "meditans@gmail.com";
          github = "meditans";
          githubId = 4641445;
          name = "Carlo Nucera";
        };
        megheaiulian = {
          email = "iulian.meghea@gmail.com";
          github = "megheaiulian";
          githubId = 1788114;
          name = "Meghea Iulian";
        };
        meisternu = {
          email = "meister@krutt.org";
          github = "meisternu";
          githubId = 8263431;
          name = "Matt Miemiec";
        };
        melchips = {
          email = "truphemus.francois@gmail.com";
          github = "melchips";
          githubId = 365721;
          name = "Francois Truphemus";
        };
        melsigl = {
          email = "melanie.bianca.sigl@gmail.com";
          github = "melsigl";
          githubId = 15093162;
          name = "Melanie B. Sigl";
        };
        melkor333 = {
          email = "samuel@ton-kunst.ch";
          github = "Melkor333";
          githubId = 6412377;
          name = "Samuel Ruprecht";
        };
        kira-bruneau = {
          email = "kira.bruneau@pm.me";
          name = "Kira Bruneau";
          github = "kira-bruneau";
          githubId = 382041;
        };
        mephistophiles = {
          email = "mussitantesmortem@gmail.com";
          name = "Maxim Zhukov";
          github = "Mephistophiles";
          githubId = 4850908;
        };
        mfossen = {
          email = "msfossen@gmail.com";
          github = "mfossen";
          githubId = 3300322;
          name = "Mitchell Fossen";
        };
        mgdelacroix = {
          email = "mgdelacroix@gmail.com";
          github = "mgdelacroix";
          githubId = 223323;
          name = "Miguel de la Cruz";
        };
        mgdm = {
          email = "michael@mgdm.net";
          github = "mgdm";
          githubId = 71893;
          name = "Michael Maclean";
        };
        mglolenstine = {
          email = "mglolenstine@gmail.com";
          github = "MGlolenstine";
          githubId = 9406770;
          matrix = "@mglolenstine:matrix.org";
          name = "MGlolenstine";
        };
        mgregoire = {
          email = "gregoire@martinache.net";
          github = "M-Gregoire";
          githubId = 9469313;
          name = "Gregoire Martinache";
        };
        mgttlinger = {
          email = "megoettlinger@gmail.com";
          github = "mgttlinger";
          githubId = 5120487;
          name = "Merlin Humml";
        };
        mguentner = {
          email = "code@klandest.in";
          github = "mguentner";
          githubId = 668926;
          name = "Maximilian Güntner";
        };
        mh = {
          email = "68288772+markus-heinrich@users.noreply.github.com";
          github = "markus-heinrich";
          githubId = 68288772;
          name = "Markus Heinrich";
        };
        mhaselsteiner = {
          email = "magdalena.haselsteiner@gmx.at";
          github = "mhaselsteiner";
          githubId = 20536514;
          name = "Magdalena Haselsteiner";
        };
        mh182 = {
          email = "mh182@chello.at";
          github = "mh182";
          githubId = 9980864;
          name = "Max Hofer";
        };
        miangraham = {
          email = "miangraham@users.noreply.github.com";
          github = "miangraham";
          githubId = 704580;
          name = "M. Ian Graham";
          keys = [{
            fingerprint = "8CE3 2906 516F C4D8 D373  308A E189 648A 55F5 9A9F";
          }];
        };
        mic92 = {
          email = "joerg@thalheim.io";
          matrix = "@mic92:nixos.dev";
          github = "Mic92";
          githubId = 96200;
          name = "Jörg Thalheim";
          keys = [{
            # compare with https://keybase.io/Mic92
            fingerprint = "3DEE 1C55 6E1C 3DC5 54F5  875A 003F 2096 411B 5F92";
          }];
        };
        michaeladler = {
          email = "therisen06@gmail.com";
          github = "michaeladler";
          githubId = 1575834;
          name = "Michael Adler";
        };
        michaelBelsanti = {
          email = "mbels03@protonmail.com";
          name = "Mike Belsanti";
          github = "michaelBelsanti";
          githubId = 62124625;
        };
        michaelpj = {
          email = "michaelpj@gmail.com";
          github = "michaelpj";
          githubId = 1699466;
          name = "Michael Peyton Jones";
        };
        michalrus = {
          email = "m@michalrus.com";
          github = "michalrus";
          githubId = 4366292;
          name = "Michal Rus";
        };
        michelk = {
          email = "michel@kuhlmanns.info";
          github = "michelk";
          githubId = 1404919;
          name = "Michel Kuhlmann";
        };
        michojel = {
          email = "mic.liamg@gmail.com";
          github = "michojel";
          githubId = 21156022;
          name = "Michal Minář";
        };
        michzappa = {
          email = "me@michzappa.com";
          github = "michzappa";
          githubId = 59343378;
          name = "Michael Zappa";
        };
        mickours = {
          email = "mickours@gmail.com<";
          github = "mickours";
          githubId = 837312;
          name = "Michael Mercier";
        };
        midchildan = {
          email = "git@midchildan.org";
          matrix = "@midchildan:matrix.org";
          github = "midchildan";
          githubId = 7343721;
          name = "midchildan";
          keys = [{
            fingerprint = "FEF0 AE2D 5449 3482 5F06  40AA 186A 1EDA C5C6 3F83";
          }];
        };
        mightyiam = {
          email = "mightyiampresence@gmail.com";
          github = "mightyiam";
          githubId = 635591;
          name = "Shahar Dawn Or";
        };
        mihnea-s = {
          email = "mihn.stn@gmail.com";
          github = "mihnea-s";
          githubId = 43088426;
          name = "Mihnea Stoian";
        };
        mikefaille = {
          email = "michael@faille.io";
          github = "mikefaille";
          githubId = 978196;
          name = "Michaël Faille";
        };
        mikoim = {
          email = "ek@esh.ink";
          github = "mikoim";
          githubId = 3958340;
          name = "Eshin Kunishima";
        };
        mikesperber = {
          email = "sperber@deinprogramm.de";
          github = "mikesperber";
          githubId = 1387206;
          name = "Mike Sperber";
        };
        mikroskeem = {
          email = "mikroskeem@mikroskeem.eu";
          github = "mikroskeem";
          githubId = 3490861;
          name = "Mark Vainomaa";
          keys = [{
            fingerprint = "DB43 2895 CF68 F0CE D4B7  EF60 DA01 5B05 B5A1 1B22";
          }];
        };
        milahu = {
          email = "milahu@gmail.com";
          github = "milahu";
          githubId = 12958815;
          name = "Milan Hauth";
        };
        milesbreslin = {
          email = "milesbreslin@gmail.com";
          github = "MilesBreslin";
          githubId = 38543128;
          name = "Miles Breslin";
        };
        milibopp = {
          email = "contact@ebopp.de";
          github = "milibopp";
          githubId = 3098430;
          name = "Emilia Bopp";
        };
        millerjason = {
          email = "mailings-github@millerjason.com";
          github = "millerjason";
          githubId = 7610974;
          name = "Jason Miller";
        };
        milogert = {
          email = "milo@milogert.com";
          github = "milogert";
          githubId = 5378535;
          name = "Milo Gertjejansen";
        };
        mimame = {
          email = "miguel.madrid.mencia@gmail.com";
          github = "mimame";
          githubId = 3269878;
          name = "Miguel Madrid Mencía";
        };
        mindavi = {
          email = "rol3517@gmail.com";
          github = "Mindavi";
          githubId = 9799623;
          name = "Rick van Schijndel";
        };
        minijackson = {
          email = "minijackson@riseup.net";
          github = "minijackson";
          githubId = 1200507;
          name = "Rémi Nicole";
          keys = [{
            fingerprint = "3196 83D3 9A1B 4DE1 3DC2  51FD FEA8 88C9 F5D6 4F62";
          }];
        };
        minion3665 = {
          name = "Skyler Grey";
          email = "skyler3665@gmail.com";
          matrix = "@minion3665:matrix.org";
          github = "Minion3665";
          githubId = 34243578;
          keys = [{
            fingerprint = "D520 AC8D 7C96 9212 5B2B  BD3A 1AFD 1025 6B3C 714D";
          }];
        };
        mir06 = {
          email = "armin.leuprecht@uni-graz.at";
          github = "mir06";
          githubId = 8479244;
          name = "Armin Leuprecht";
        };
        mirdhyn = {
          email = "mirdhyn@gmail.com";
          github = "mirdhyn";
          githubId = 149558;
          name = "Merlin Gaillard";
        };
        mirrexagon = {
          email = "mirrexagon@mirrexagon.com";
          github = "mirrexagon";
          githubId = 1776903;
          name = "Andrew Abbott";
        };
        mislavzanic = {
          email = "mislavzanic3@gmail.com";
          github = "mislavzanic";
          githubId = 48838244;
          name = "Mislav Zanic";
        };
        misterio77 = {
          email = "eu@misterio.me";
          github = "Misterio77";
          githubId = 5727578;
          matrix = "@misterio:matrix.org";
          name = "Gabriel Fontes";
          keys = [{
            fingerprint = "7088 C742 1873 E0DB 97FF  17C2 245C AB70 B4C2 25E9";
          }];
        };
        mitchmindtree = {
          email = "mail@mitchellnordine.com";
          github = "mitchmindtree";
          githubId = 4587373;
          name = "Mitchell Nordine";
        };
        mjanczyk = {
          email = "m@dragonvr.pl";
          github = "mjanczyk";
          githubId = 1001112;
          name = "Marcin Janczyk";
        };
        mjp = {
          email = "mike@mythik.co.uk";
          github = "MikePlayle";
          githubId = 16974598;
          name = "Mike Playle";
        };
        mkaito = {
          email = "chris@mkaito.net";
          github = "mkaito";
          githubId = 20434;
          name = "Christian Höppner";
        };
        mkazulak = {
          email = "kazulakm@gmail.com";
          github = "mulderr";
          githubId = 5698461;
          name = "Maciej Kazulak";
        };
        mkf = {
          email = "m@mikf.pl";
          github = "mkf";
          githubId = 7753506;
          name = "Michał Krzysztof Feiler";
          keys = [{
            fingerprint = "1E36 9940 CC7E 01C4 CFE8  F20A E35C 2D7C 2C6A C724";
          }];
        };
        mkg = {
          email = "mkg@vt.edu";
          github = "mkgvt";
          githubId = 22477669;
          name = "Mark K Gardner";
        };
        mkg20001 = {
          email = "mkg20001+nix@gmail.com";
          matrix = "@mkg20001:matrix.org";
          github = "mkg20001";
          githubId = 7735145;
          name = "Maciej Krüger";
          keys = [{
            fingerprint = "E90C BA34 55B3 6236 740C  038F 0D94 8CE1 9CF4 9C5F";
          }];
        };
        mktip = {
          email = "mo.issa.ok+nix@gmail.com";
          github = "mktip";
          githubId = 45905717;
          name = "Mohammad Issa";
          keys = [{
            fingerprint = "64BE BF11 96C3 DD7A 443E  8314 1DC0 82FA DE5B A863";
          }];
        };
        mlieberman85 = {
          email = "mlieberman85@gmail.com";
          github = "mlieberman85";
          githubId = 622577;
          name = "Michael Lieberman";
        };
        mlvzk = {
          name = "mlvzk";
          email = "mlvzk@users.noreply.github.com";
          github = "mlvzk";
          githubId = 44906333;
        };
        mmahut = {
          email = "marek.mahut@gmail.com";
          github = "mmahut";
          githubId = 104795;
          name = "Marek Mahut";
        };
        mmai = {
          email = "henri.bourcereau@gmail.com";
          github = "mmai";
          githubId = 117842;
          name = "Henri Bourcereau";
        };
        mmesch = {
          email = "mmesch@noreply.github.com";
          github = "MMesch";
          githubId = 2597803;
          name = "Matthias Meschede";
        };
        mmilata = {
          email = "martin@martinmilata.cz";
          github = "mmilata";
          githubId = 85857;
          name = "Martin Milata";
        };
        mmlb = {
          email = "manny@peekaboo.mmlb.icu";
          github = "mmlb";
          githubId = 708570;
          name = "Manuel Mendez";
        };
        mnacamura = {
          email = "m.nacamura@gmail.com";
          github = "mnacamura";
          githubId = 45770;
          name = "Mitsuhiro Nakamura";
        };
        moaxcp = {
          email = "moaxcp@gmail.com";
          github = "moaxcp";
          githubId = 7831184;
          name = "John Mercier";
        };
        modulistic = {
          email = "modulistic@gmail.com";
          github = "modulistic";
          githubId = 1902456;
          name = "Pablo Costa";
        };
        mog = {
          email = "mog-lists@rldn.net";
          github = "mogorman";
          githubId = 64710;
          name = "Matthew O'Gorman";
        };
        Mogria = {
          email = "m0gr14@gmail.com";
          github = "mogria";
          githubId = 754512;
          name = "Mogria";
        };
        mohe2015 = {
          name = "Moritz Hedtke";
          email = "Moritz.Hedtke@t-online.de";
          matrix = "@moritz.hedtke:matrix.org";
          github = "mohe2015";
          githubId = 13287984;
          keys = [{
            fingerprint = "1248 D3E1 1D11 4A85 75C9  8934 6794 D45A 488C 2EDE";
          }];
        };
        monaaraj = {
          name = "Mon Aaraj";
          email = "owo69uwu69@gmail.com";
          matrix = "@mon:tchncs.de";
          github = "MonAaraj";
          githubId = 46468162;
        };
        monsieurp = {
          email = "monsieurp@gentoo.org";
          github = "monsieurp";
          githubId = 350116;
          name = "Patrice Clement";
        };
        montag451 = {
          email = "montag451@laposte.net";
          github = "montag451";
          githubId = 249317;
          name = "montag451";
        };
        montchr = {
          name = "Chris Montgomery";
          email = "chris@cdom.io";
          github = "montchr";
          githubId = 1757914;
          keys = [{
            fingerprint = "6460 4147 C434 F65E C306  A21F 135E EDD0 F719 34F3";
          }];
        };
        moosingin3space = {
          email = "moosingin3space@gmail.com";
          github = "moosingin3space";
          githubId = 830082;
          name = "Nathan Moos";
        };
        moredread = {
          email = "code@apb.name";
          github = "Moredread";
          githubId = 100848;
          name = "André-Patrick Bubel";
          keys = [{
            fingerprint = "4412 38AD CAD3 228D 876C  5455 118C E7C4 24B4 5728";
          }];
        };
        moretea = {
          email = "maarten@moretea.nl";
          github = "moretea";
          githubId = 99988;
          name = "Maarten Hoogendoorn";
        };
        MoritzBoehme = {
          email = "mail@moritzboeh.me";
          github = "MoritzBoehme";
          githubId = 42215704;
          name = "Moritz Böhme";
        };
        MostAwesomeDude = {
          email = "cds@corbinsimpson.com";
          github = "MostAwesomeDude";
          githubId = 118035;
          name = "Corbin Simpson";
        };
        mothsart = {
          email = "jerem.ferry@gmail.com";
          github = "mothsART";
          githubId = 10601196;
          name = "Jérémie Ferry";
        };
        mounium = {
          email = "muoniurn@gmail.com";
          github = "Mounium";
          githubId = 20026143;
          name = "Katona László";
        };
        MP2E = {
          email = "MP2E@archlinux.us";
          github = "MP2E";
          githubId = 167708;
          name = "Cray Elliott";
        };
        mpcsh = {
          email = "m@mpc.sh";
          github = "mpcsh";
          githubId = 2894019;
          name = "Mark Cohen";
        };
        mpickering = {
          email = "matthewtpickering@gmail.com";
          github = "mpickering";
          githubId = 1216657;
          name = "Matthew Pickering";
        };
        mpoquet = {
          email = "millian.poquet@gmail.com";
          github = "mpoquet";
          githubId = 3502831;
          name = "Millian Poquet";
        };
        mpscholten = {
          email = "marc@digitallyinduced.com";
          github = "mpscholten";
          githubId = 2072185;
          name = "Marc Scholten";
        };
        mtrsk = {
          email = "marcos.schonfinkel@protonmail.com";
          github = "mtrsk";
          githubId = 16356569;
          name = "Marcos Benevides";
        };
        mredaelli = {
          email = "massimo@typish.io";
          github = "mredaelli";
          githubId = 3073833;
          name = "Massimo Redaelli";
        };
        mrkkrp = {
          email = "markkarpov92@gmail.com";
          github = "mrkkrp";
          githubId = 8165792;
          name = "Mark Karpov";
        };
        mrmebelman = {
          email = "burzakovskij@protonmail.com";
          github = "MrMebelMan";
          githubId = 15896005;
          name = "Vladyslav Burzakovskyy";
        };
        mrtarantoga = {
          email = "goetz-dev@web.de";
          name = "Götz Grimmer";
          github = "MrTarantoga";
          githubId = 53876219;
        };
        mrVanDalo = {
          email = "contact@ingolf-wagner.de";
          github = "mrVanDalo";
          githubId = 839693;
          name = "Ingolf Wanger";
        };
        mschristiansen = {
          email = "mikkel@rheosystems.com";
          github = "mschristiansen";
          githubId = 437005;
          name = "Mikkel Christiansen";
        };
        mschuwalow = {
          github = "mschuwalow";
          githubId = 16665913;
          name = "Maxim Schuwalow";
          email = "maxim.schuwalow@gmail.com";
        };
        msfjarvis = {
          github = "msfjarvis";
          githubId = 13348378;
          name = "Harsh Shandilya";
          email = "nixos@msfjarvis.dev";
          keys = [{
            fingerprint = "8F87 050B 0F9C B841 1515  7399 B784 3F82 3355 E9B9";
          }];
        };
        msiedlarek = {
          email = "mikolaj@siedlarek.pl";
          github = "msiedlarek";
          githubId = 133448;
          name = "Mikołaj Siedlarek";
        };
        msm = {
          email = "msm@tailcall.net";
          github = "msm-code";
          githubId = 7026881;
          name = "Jarosław Jedynak";
        };
        mstarzyk = {
          email = "mstarzyk@gmail.com";
          github = "mstarzyk";
          githubId = 111304;
          name = "Maciek Starzyk";
        };
        msteen = {
          email = "emailmatthijs@gmail.com";
          github = "msteen";
          githubId = 788953;
          name = "Matthijs Steen";
        };
        mstrangfeld = {
          email = "marvin@strangfeld.io";
          github = "mstrangfeld";
          githubId = 36842980;
          name = "Marvin Strangfeld";
        };
        mt-caret = {
          email = "mtakeda.enigsol@gmail.com";
          github = "mt-caret";
          githubId = 4996739;
          name = "Masayuki Takeda";
        };
        mtesseract = {
          email = "moritz@stackrox.com";
          github = "mtesseract";
          githubId = 11706080;
          name = "Moritz Clasmeier";
        };
        mtoohey = {
          name = "Matthew Toohey";
          email = "contact@mtoohey.com";
          github = "mtoohey31";
          githubId = 36740602;
        };
        MtP = {
          email = "marko.nixos@poikonen.de";
          github = "MtP76";
          githubId = 2176611;
          name = "Marko Poikonen";
        };
        mtreca = {
          email = "maxime.treca@gmail.com";
          github = "mtreca";
          githubId = 16440823;
          name = "Maxime Tréca";
        };
        mtreskin = {
          email = "zerthurd@gmail.com";
          github = "Zert";
          githubId = 39034;
          name = "Max Treskin";
        };
        mudri = {
          email = "lamudri@gmail.com";
          github = "laMudri";
          githubId = 5139265;
          name = "James Wood";
        };
        mudrii = {
          email = "mudreac@gmail.com";
          github = "mudrii";
          githubId = 220262;
          name = "Ion Mudreac";
        };
        multun = {
          email = "victor.collod@epita.fr";
          github = "multun";
          githubId = 5047140;
          name = "Victor Collod";
        };
        munksgaard = {
          name = "Philip Munksgaard";
          email = "philip@munksgaard.me";
          github = "munksgaard";
          githubId = 230613;
          matrix = "@philip:matrix.munksgaard.me";
          keys = [{
            fingerprint = "5658 4D09 71AF E45F CC29 6BD7 4CE6 2A90 EFC0 B9B2";
          }];
        };
        muscaln = {
          email = "muscaln@protonmail.com";
          github = "muscaln";
          githubId = 96225281;
          name = "Mustafa Çalışkan";
        };
        mupdt = {
          email = "nix@pdtpartners.com";
          github = "mupdt";
          githubId = 25388474;
          name = "Matej Urbas";
        };
        mvisonneau = {
          name = "Maxime VISONNEAU";
          email = "maxime@visonneau.fr";
          matrix = "@maxime:visonneau.fr";
          github = "mvisonneau";
          githubId = 1761583;
          keys = [{
            fingerprint = "EC63 0CEA E8BC 5EE5 5C58  F2E3 150D 6F0A E919 8D24";
          }];
        };
        mvnetbiz = {
          email = "mvnetbiz@gmail.com";
          matrix = "@mvtva:matrix.org";
          github = "mvnetbiz";
          githubId = 6455574;
          name = "Matt Votava";
        };
        mvs = {
          email = "mvs@nya.yt";
          github = "illdefined";
          githubId = 772914;
          name = "Mikael Voss";
        };
        mwolfe = {
          email = "corp@m0rg.dev";
          github = "m0rg-dev";
          githubId = 38578268;
          name = "Morgan Wolfe";
        };
        maxwilson = {
          email = "nixpkgs@maxwilson.dev";
          github = "mwilsoncoding";
          githubId = 43796009;
          name = "Max Wilson";
        };
        myaats = {
          email = "mats@mats.sh";
          github = "Myaats";
          githubId = 6295090;
          name = "Mats";
        };
        myrl = {
          email = "myrl.0xf@gmail.com";
          github = "Myrl";
          githubId = 9636071;
          name = "Myrl Hex";
        };
        n0emis = {
          email = "nixpkgs@n0emis.network";
          github = "n0emis";
          githubId = 22817873;
          name = "Ember Keske";
        };
        nadrieril = {
          email = "nadrieril@gmail.com";
          github = "Nadrieril";
          githubId = 6783654;
          name = "Nadrieril Feneanar";
        };
        nagy = {
          email = "danielnagy@posteo.de";
          github = "nagy";
          githubId = 692274;
          name = "Daniel Nagy";
          keys = [{
            fingerprint = "F6AE 2C60 9196 A1BC ECD8  7108 1B8E 8DCB 576F B671";
          }];
        };
        nalbyuites = {
          email = "ashijit007@gmail.com";
          github = "nalbyuites";
          githubId = 1009523;
          name = "Ashijit Pramanik";
        };
        namore = {
          email = "namor@hemio.de";
          github = "namore";
          githubId = 1222539;
          name = "Roman Naumann";
        };
        naphta = {
          email = "naphta@noreply.github.com";
          github = "naphta";
          githubId = 6709831;
          name = "Jake Hill";
        };
        nasirhm = {
          email = "nasirhussainm14@gmail.com";
          github = "nasirhm";
          githubId = 35005234;
          name = "Nasir Hussain";
          keys = [{
            fingerprint = "7A10 AB8E 0BEC 566B 090C  9BE3 D812 6E55 9CE7 C35D";
          }];
        };
        nat-418 = {
          email = "93013864+nat-418@users.noreply.github.com";
          github = "nat-418";
          githubId = 93013864;
          name = "nat-418";
        };
        nathanruiz = {
          email = "nathanruiz@protonmail.com";
          github = "nathanruiz";
          githubId = 18604892;
          name = "Nathan Ruiz";
        };
        nathan-gs = {
          email = "nathan@nathan.gs";
          github = "nathan-gs";
          githubId = 330943;
          name = "Nathan Bijnens";
        };
        nathyong = {
          email = "nathyong@noreply.github.com";
          github = "nathyong";
          githubId = 818502;
          name = "Nathan Yong";
        };
        natsukium = {
          email = "nixpkgs@natsukium.com";
          github = "natsukium";
          githubId = 25083790;
          name = "Tomoya Otabi";
          keys = [{
            fingerprint = "3D14 6004 004C F882 D519  6CD4 9EA4 5A31 DB99 4C53";
          }];
        };
        natto1784 = {
          email = "natto@weirdnatto.in";
          github = "natto1784";
          githubId = 56316606;
          name = "Amneesh Singh";
        };
        nazarewk = {
          name = "Krzysztof Nazarewski";
          email = "3494992+nazarewk@users.noreply.github.com";
          matrix = "@nazarewk:matrix.org";
          github = "nazarewk";
          githubId = 3494992;
          keys = [{
            fingerprint = "4BFF 0614 03A2 47F0 AA0B 4BC4 916D 8B67 2418 92AE";
          }];
        };
        nbr = {
          email = "nbr@users.noreply.github.com";
          github = "nbr";
          githubId = 3819225;
          name = "Nick Braga";
        };
        nbren12 = {
          email = "nbren12@gmail.com";
          github = "nbren12";
          githubId = 1386642;
          name = "Noah Brenowitz";
        };
        ncfavier = {
          email = "n@monade.li";
          matrix = "@ncfavier:matrix.org";
          github = "ncfavier";
          githubId = 4323933;
          name = "Naïm Favier";
          keys = [{
            fingerprint = "F3EB 4BBB 4E71 99BC 299C  D4E9 95AF CE82 1190 8325";
          }];
        };
        nckx = {
          email = "github@tobias.gr";
          github = "nckx";
          githubId = 364510;
          name = "Tobias Geerinckx-Rice";
        };
        ndl = {
          email = "ndl@endl.ch";
          github = "ndl";
          githubId = 137805;
          name = "Alexander Tsvyashchenko";
        };
        Necior = {
          email = "adrian@sadlocha.eu";
          github = "Necior";
          githubId = 2404518;
          matrix = "@n3t:matrix.org";
          name = "Adrian Sadłocha";
        };
        neeasade = {
          email = "nathanisom27@gmail.com";
          github = "neeasade";
          githubId = 3747396;
          name = "Nathan Isom";
        };
        necrophcodr = {
          email = "nc@scalehost.eu";
          github = "necrophcodr";
          githubId = 575887;
          name = "Steffen Rytter Postas";
        };
        neilmayhew = {
          email = "nix@neil.mayhew.name";
          github = "neilmayhew";
          githubId = 166791;
          name = "Neil Mayhew";
        };
        nek0 = {
          email = "nek0@nek0.eu";
          github = "nek0";
          githubId = 1859691;
          name = "Amedeo Molnár";
        };
        nelsonjeppesen = {
          email = "nix@jeppesen.io";
          github = "NelsonJeppesen";
          githubId = 50854675;
          name = "Nelson Jeppesen";
        };
        neonfuz = {
          email = "neonfuz@gmail.com";
          github = "neonfuz";
          githubId = 2590830;
          name = "Sage Raflik";
        };
        neosimsim = {
          email = "me@abn.sh";
          github = "neosimsim";
          githubId = 1771772;
          name = "Alexander Ben Nasrallah";
        };
        nequissimus = {
          email = "tim@nequissimus.com";
          github = "NeQuissimus";
          githubId = 628342;
          name = "Tim Steinbach";
        };
        nerdypepper = {
          email = "nerdy@peppe.rs";
          github = "nerdypepper";
          githubId = 23743547;
          name = "Akshay Oppiliappan";
        };
        ners = {
          name = "ners";
          email = "ners@gmx.ch";
          matrix = "@ners:ners.ch";
          github = "ners";
          githubId = 50560955;
        };
        nessdoor = {
          name = "Tomas Antonio Lopez";
          email = "entropy.overseer@protonmail.com";
          github = "nessdoor";
          githubId = 25993494;
        };
        net-mist = {
          email = "archimist.linux@gmail.com";
          github = "Net-Mist";
          githubId = 13920346;
          name = "Sébastien Iooss";
        };
        netali = {
          name = "Jennifer Graul";
          email = "me@netali.de";
          github = "NetaliDev";
          githubId = 15304894;
          keys = [{
            fingerprint = "F729 2594 6F58 0B05 8FB3  F271 9C55 E636 426B 40A9";
          }];
        };
        netcrns = {
          email = "jason.wing@gmx.de";
          github = "netcrns";
          githubId = 34162313;
          name = "Jason Wing";
        };
        netixx = {
          email = "dev.espinetfrancois@gmail.com";
          github = "netixx";
          githubId = 1488603;
          name = "François Espinet";
        };
        neverbehave = {
          email = "i@never.pet";
          github = "NeverBehave";
          githubId = 17120571;
          name = "Xinhao Luo";
        };
        newam = {
          email = "alex@thinglab.org";
          github = "newAM";
          githubId = 7845120;
          name = "Alex Martens";
        };
        nialov = {
          email = "nikolasovaskainen@gmail.com";
          github = "nialov";
          githubId = 47318483;
          name = "Nikolas Ovaskainen";
        };
        nikitavoloboev = {
          email = "nikita.voloboev@gmail.com";
          github = "nikitavoloboev";
          githubId = 6391776;
          name = "Nikita Voloboev";
        };
        ngiger = {
          email = "niklaus.giger@member.fsf.org";
          github = "ngiger";
          githubId = 265800;
          name = "Niklaus Giger";
        };
        nh2 = {
          email = "mail@nh2.me";
          matrix = "@nh2:matrix.org";
          github = "nh2";
          githubId = 399535;
          name = "Niklas Hambüchen";
        };
        nhooyr = {
          email = "anmol@aubble.com";
          github = "nhooyr";
          githubId = 10180857;
          name = "Anmol Sethi";
        };
        nicbk = {
          email = "nicolas@nicbk.com";
          github = "nicbk";
          githubId = 77309427;
          name = "Nicolás Kennedy";
          keys = [{
            fingerprint = "7BC1 77D9 C222 B1DC FB2F  0484 C061 089E FEBF 7A35";
          }];
        };
        nichtsfrei = {
          email = "philipp.eder@posteo.net";
          github = "nichtsfrei";
          githubId = 1665818;
          name = "Philipp Eder";
        };
        nickcao = {
          name = "Nick Cao";
          email = "nickcao@nichi.co";
          github = "NickCao";
          githubId = 15247171;
        };
        nickhu = {
          email = "me@nickhu.co.uk";
          github = "NickHu";
          githubId = 450276;
          name = "Nick Hu";
        };
        nicknovitski = {
          email = "nixpkgs@nicknovitski.com";
          github = "nicknovitski";
          githubId = 151337;
          name = "Nick Novitski";
        };
        nico202 = {
          email = "anothersms@gmail.com";
          github = "nico202";
          githubId = 8214542;
          name = "Nicolò Balzarotti";
        };
        nidabdella = {
          name = "Mohamed Nidabdella";
          email = "nidabdella.mohamed@gmail.com";
          github = "nidabdella";
          githubId = 8083813;
        };
        NieDzejkob = {
          email = "kuba@kadziolka.net";
          github = "meithecatte";
          githubId = 23580910;
          name = "Jakub Kądziołka";
          keys = [{
            fingerprint = "E576 BFB2 CF6E B13D F571  33B9 E315 A758 4613 1564";
          }];
        };
        NikolaMandic = {
          email = "nikola@mandic.email";
          github = "NikolaMandic";
          githubId = 4368690;
          name = "Ratko Mladic";
        };
        nilp0inter = {
          email = "robertomartinezp@gmail.com";
          github = "nilp0inter";
          githubId = 1224006;
          name = "Roberto Abdelkader Martínez Pérez";
        };
        nilsirl = {
          email = "nils@nilsand.re";
          github = "NilsIrl";
          githubId = 26231126;
          name = "Nils ANDRÉ-CHANG";
        };
        nils-degroot = {
          email = "nils@peeko.nl";
          github = "nils-degroot";
          githubId = 53556985;
          name = "Nils de Groot";
        };
        ninjatrappeur = {
          email = "felix@alternativebit.fr";
          matrix = "@ninjatrappeur:matrix.org";
          github = "NinjaTrappeur";
          githubId = 1219785;
          name = "Félix Baylac-Jacqué";
        };
        ninjin = {
          email = "pontus@stenetorp.se";
          github = "ninjin";
          githubId = 354934;
          name = "Pontus Stenetorp";
          keys = [{
            fingerprint = "0966 2F9F 3FDA C22B C22E  4CE1 D430 2875 00E6 483C";
          }];
        };
        nioncode = {
          email = "nioncode+github@gmail.com";
          github = "nioncode";
          githubId = 3159451;
          name = "Nicolas Schneider";
        };
        nkje = {
          name = "Niels Kristian Lyshøj Jensen";
          email = "n@nk.je";
          github = "NKJe";
          githubId = 1102306;
          keys = [{
            fingerprint = "B956 C6A4 22AF 86A0 8F77  A8CA DE3B ADFE CD31 A89D";
          }];
        };
        nitsky = {
          name = "nitsky";
          email = "492793+nitsky@users.noreply.github.com";
          github = "nitsky";
          githubId = 492793;
        };
        nkpvk = {
          email = "niko.pavlinek@gmail.com";
          github = "npavlinek";
          githubId = 16385648;
          name = "Niko Pavlinek";
        };
        nixbitcoin = {
          email = "nixbitcoin@i2pmail.org";
          github = "nixbitcoin";
          githubId = 45737139;
          name = "nixbitcoindev";
          keys = [{
            fingerprint = "577A 3452 7F3E 2A85 E80F  E164 DD11 F9AD 5308 B3BA";
          }];
        };
        nixinator = {
          email = "33lockdown33@protonmail.com";
          matrix = "@nixinator:nixos.dev";
          github = "nixinator";
          githubId = 66913205;
          name = "Rick Sanchez";
        };
        nixy = {
          email = "nixy@nixy.moe";
          github = "nixy";
          githubId = 7588406;
          name = "Andrew R. M.";
        };
        nkalupahana = {
          email = "hello@nisa.la";
          github = "nkalupahana";
          githubId = 7347290;
          name = "Nisala Kalupahana";
        };
        nloomans = {
          email = "noah@nixos.noahloomans.com";
          github = "nloomans";
          githubId = 7829481;
          name = "Noah Loomans";
        };
        nmattia = {
          email = "nicolas@nmattia.com";
          github = "nmattia";
          githubId = 6930756;
          name = "Nicolas Mattia";
        };
        nobbz = {
          name = "Norbert Melzer";
          email = "timmelzer+nixpkgs@gmail.com";
          github = "NobbZ";
          githubId = 58951;
        };
        nocoolnametom = {
          email = "nocoolnametom@gmail.com";
          github = "nocoolnametom";
          githubId = 810877;
          name = "Tom Doggett";
        };
        noisersup = {
          email = "patryk@kwiatek.xyz";
          github = "noisersup";
          githubId = 42322511;
          name = "Patryk Kwiatek";
        };
        nomeata = {
          email = "mail@joachim-breitner.de";
          github = "nomeata";
          githubId = 148037;
          name = "Joachim Breitner";
        };
        nomisiv = {
          email = "simon@nomisiv.com";
          github = "NomisIV";
          githubId = 47303199;
          name = "Simon Gutgesell";
        };
        noneucat = {
          email = "andy@lolc.at";
          matrix = "@noneucat:lolc.at";
          github = "noneucat";
          githubId = 40049608;
          name = "Andy Chun";
        };
        nook = {
          name = "Tom Nook";
          email = "0xnook@protonmail.com";
          github = "0xnook";
          githubId = 88323754;
        };
        noreferences = {
          email = "norkus@norkus.net";
          github = "jozuas";
          githubId = 13085275;
          name = "Juozas Norkus";
        };
        norfair = {
          email = "syd@cs-syd.eu";
          github = "NorfairKing";
          githubId = 3521180;
          name = "Tom Sydney Kerckhove";
        };
        notthemessiah = {
          email = "brian.cohen.88@gmail.com";
          github = "NOTtheMessiah";
          githubId = 2946283;
          name = "Brian Cohen";
        };
        novoxd = {
          email = "radnovox@gmail.com";
          github = "novoxd";
          githubId = 6052922;
          name = "Kirill Struokov";
        };
        np = {
          email = "np.nix@nicolaspouillard.fr";
          github = "np";
          githubId = 5548;
          name = "Nicolas Pouillard";
        };
        nphilou = {
          email = "nphilou@gmail.com";
          github = "nphilou";
          githubId = 9939720;
          name = "Philippe Nguyen";
        };
        nrdxp = {
          email = "tim.deh@pm.me";
          matrix = "@timdeh:matrix.org";
          github = "nrdxp";
          githubId = 34083928;
          name = "Tim DeHerrera";
        };
        nshalman = {
          email = "nahamu@gmail.com";
          github = "nshalman";
          githubId = 20391;
          name = "Nahum Shalman";
        };
        nsnelson = {
          email = "noah.snelson@protonmail.com";
          github = "peeley";
          githubId = 30942198;
          name = "Noah Snelson";
        };
        nthorne = {
          email = "notrupertthorne@gmail.com";
          github = "nthorne";
          githubId = 1839979;
          name = "Niklas Thörne";
        };
        nukaduka = {
          email = "ksgokte@gmail.com";
          github = "NukaDuka";
          githubId = 22592293;
          name = "Kartik Gokte";
        };
        nullx76 = {
          email = "nix@xirion.net";
          github = "NULLx76";
          githubId = 1809198;
          name = "Victor Roest";
        };
        nullishamy = {
          email = "amy.codes@null.net";
          name = "nullishamy";
          github = "nullishamy";
          githubId = 99221043;
        };
        numinit = {
          email = "me@numin.it";
          github = "numinit";
          githubId = 369111;
          name = "Morgan Jones";
        };
        numkem = {
          name = "Sebastien Bariteau";
          email = "numkem@numkem.org";
          matrix = "@numkem:matrix.org";
          github = "numkem";
          githubId = 332423;
        };
        nviets = {
          email = "nathan.g.viets@gmail.com";
          github = "nviets";
          githubId = 16027994;
          name = "Nathan Viets";
        };
        nyanloutre = {
          email = "paul@nyanlout.re";
          github = "nyanloutre";
          githubId = 7677321;
          name = "Paul Trehiou";
        };
        nyanotech = {
          name = "nyanotech";
          email = "nyanotechnology@gmail.com";
          github = "nyanotech";
          githubId = 33802077;
        };
        nyarly = {
          email = "nyarly@gmail.com";
          github = "nyarly";
          githubId = 127548;
          name = "Judson Lester";
        };
        nzbr = {
          email = "nixos@nzbr.de";
          github = "nzbr";
          githubId = 7851175;
          name = "nzbr";
          matrix = "@nzbr:nzbr.de";
          keys = [{
            fingerprint = "BF3A 3EE6 3144 2C5F C9FB  39A7 6C78 B50B 97A4 2F8A";
          }];
        };
        nzhang-zh = {
          email = "n.zhang.hp.au@gmail.com";
          github = "nzhang-zh";
          githubId = 30825096;
          name = "Ning Zhang";
        };
        obadz = {
          email = "obadz-nixos@obadz.com";
          github = "obadz";
          githubId = 3359345;
          name = "obadz";
        };
        oberblastmeister = {
          email = "littlebubu.shu@gmail.com";
          github = "oberblastmeister";
          githubId = 61095988;
          name = "Brian Shu";
        };
        obsidian-systems-maintenance = {
          name = "Obsidian Systems Maintenance";
          email = "maintainer@obsidian.systems";
          github = "obsidian-systems-maintenance";
          githubId = 80847921;
        };
        obfusk = {
          email = "flx@obfusk.net";
          matrix = "@obfusk:matrix.org";
          github = "obfusk";
          githubId = 1260687;
          name = "FC Stegerman";
          keys = [{
            fingerprint = "D5E4 A51D F8D2 55B9 FAC6  A9BB 2F96 07F0 9B36 0F2D";
          }];
        };
        ocfox = {
          email = "i@ocfox.me";
          github = "ocfox";
          githubId = 47410251;
          name = "ocfox";
          keys = [{
            fingerprint = "939E F8A5 CED8 7F50 5BB5  B2D0 24BC 2738 5F70 234F";
          }];
        };
        odi = {
          email = "oliver.dunkl@gmail.com";
          github = "odi";
          githubId = 158758;
          name = "Oliver Dunkl";
        };
        ofek = {
          email = "oss@ofek.dev";
          github = "ofek";
          githubId = 9677399;
          name = "Ofek Lev";
        };
        offline = {
          email = "jaka@x-truder.net";
          github = "offlinehacker";
          githubId = 585547;
          name = "Jaka Hudoklin";
        };
        oida = {
          email = "oida@posteo.de";
          github = "oida";
          githubId = 7249506;
          name = "oida";
        };
        olcai = {
          email = "dev@timan.info";
          github = "olcai";
          githubId = 20923;
          name = "Erik Timan";
        };
        olebedev = {
          email = "ole6edev@gmail.com";
          github = "olebedev";
          githubId = 848535;
          name = "Oleg Lebedev";
        };
        olejorgenb = {
          email = "olejorgenb@yahoo.no";
          github = "olejorgenb";
          githubId = 72201;
          name = "Ole Jørgen Brønner";
        };
        ollieB = {
          email = "1237862+oliverbunting@users.noreply.github.com";
          github = "oliverbunting";
          githubId = 1237862;
          name = "Ollie Bunting";
        };
        oluceps = {
          email = "nixos@oluceps.uk";
          github = "oluceps";
          githubId = 35628088;
          name = "oluceps";
        };
        olynch = {
          email = "owen@olynch.me";
          github = "olynch";
          githubId = 4728903;
          name = "Owen Lynch";
        };
        omasanori = {
          email = "167209+omasanori@users.noreply.github.com";
          github = "omasanori";
          githubId = 167209;
          name = "Masanori Ogino";
        };
        omgbebebe = {
          email = "omgbebebe@gmail.com";
          github = "omgbebebe";
          githubId = 588167;
          name = "Sergey Bubnov";
        };
        omnipotententity = {
          email = "omnipotententity@gmail.com";
          github = "OmnipotentEntity";
          githubId = 1538622;
          name = "Michael Reilly";
        };
        onixie = {
          email = "onixie@gmail.com";
          github = "onixie";
          githubId = 817073;
          name = "Yc. Shen";
        };
        onsails = {
          email = "andrey@onsails.com";
          github = "onsails";
          githubId = 107261;
          name = "Andrey Kuznetsov";
        };
        onny = {
          email = "onny@project-insanity.org";
          github = "onny";
          githubId = 757752;
          name = "Jonas Heinrich";
        };
        onthestairs = {
          email = "austinplatt@gmail.com";
          github = "onthestairs";
          githubId = 915970;
          name = "Austin Platt";
        };
        ony = {
          name = "Mykola Orliuk";
          email = "virkony@gmail.com";
          github = "ony";
          githubId = 11265;
        };
        OPNA2608 = {
          email = "christoph.neidahl@gmail.com";
          github = "OPNA2608";
          githubId = 23431373;
          name = "Christoph Neidahl";
        };
        opeik = {
          email = "sandro@stikic.com";
          github = "opeik";
          githubId = 11566773;
          name = "Sandro Stikić";
        };
        orbekk = {
          email = "kjetil.orbekk@gmail.com";
          github = "orbekk";
          githubId = 19862;
          name = "KJ Ørbekk";
        };
        orbitz = {
          email = "mmatalka@gmail.com";
          github = "orbitz";
          githubId = 75299;
          name = "Malcolm Matalka";
        };
        orivej = {
          email = "orivej@gmx.fr";
          github = "orivej";
          githubId = 101514;
          name = "Orivej Desh";
        };
        ornxka = {
          email = "ornxka@littledevil.sh";
          github = "ornxka";
          githubId = 52086525;
          name = "ornxka";
        };
        oro = {
          email = "marco@orovecchia.at";
          github = "Oro";
          githubId = 357005;
          name = "Marco Orovecchia";
        };
        osener = {
          email = "ozan@ozansener.com";
          github = "osener";
          githubId = 111265;
          name = "Ozan Sener";
        };
        otavio = {
          email = "otavio.salvador@ossystems.com.br";
          github = "otavio";
          githubId = 25278;
          name = "Otavio Salvador";
        };
        otini = {
          name = "Olivier Nicole";
          email = "olivier@chnik.fr";
          github = "OlivierNicole";
          githubId = 14031333;
        };
        otwieracz = {
          email = "slawek@otwiera.cz";
          github = "otwieracz";
          githubId = 108072;
          name = "Slawomir Gonet";
        };
        oxalica = {
          email = "oxalicc@pm.me";
          github = "oxalica";
          githubId = 14816024;
          name = "oxalica";
          keys = [{
            fingerprint = "F90F FD6D 585C 2BA1 F13D  E8A9 7571 654C F88E 31C2";
          }];
        };
        oxapentane = {
          email = "blame@oxapentane.com";
          github = "oxapentane";
          githubId = 1297357;
          name = "Grigory Shipunov";
          keys = [{
            fingerprint = "DD09 98E6 CDF2 9453 7FC6  04F9 91FA 5E5B F9AA 901C";
          }];
        };
        oxij = {
          email = "oxij@oxij.org";
          github = "oxij";
          githubId = 391919;
          name = "Jan Malakhovski";
          keys = [{
            fingerprint = "514B B966 B46E 3565 0508  86E8 0E6C A66E 5C55 7AA8";
          }];
        };
        oxzi = {
          email = "post@0x21.biz";
          github = "oxzi";
          githubId = 8402811;
          name = "Alvar Penning";
          keys = [{
            fingerprint = "EB14 4E67 E57D 27E2 B5A4  CD8C F32A 4563 7FA2 5E31";
          }];
        };
        oyren = {
          email = "m.scheuren@oyra.eu";
          github = "oyren";
          githubId = 15930073;
          name = "Moritz Scheuren";
        };
        ovlach = {
          email = "ondrej@vlach.xyz";
          name = "Ondrej Vlach";
          github = "ovlach";
          githubId = 4405107;
        };
        ozkutuk = {
          email = "ozkutuk@protonmail.com";
          github = "ozkutuk";
          githubId = 5948762;
          name = "Berk Özkütük";
        };
        pablovsky = {
          email = "dealberapablo07@gmail.com";
          github = "Pablo1107";
          githubId = 17091659;
          name = "Pablo Andres Dealbera";
        };
        pacien = {
          email = "b4gx3q.nixpkgs@pacien.net";
          github = "pacien";
          githubId = 1449319;
          name = "Pacien Tran-Girard";
        };
        pacman99 = {
          email = "pachum99@gmail.com";
          matrix = "@pachumicchu:myrdd.info";
          github = "Pacman99";
          githubId = 16345849;
          name = "Parthiv Seetharaman";
        };
        paddygord = {
          email = "pgpatrickgordon@gmail.com";
          github = "paddygord";
          githubId = 10776658;
          name = "Patrick Gordon";
        };
        paholg = {
          email = "paho@paholg.com";
          github = "paholg";
          githubId = 4908217;
          name = "Paho Lurie-Gregg";
        };
        pakhfn = {
          email = "pakhfn@gmail.com";
          github = "pakhfn";
          githubId = 11016164;
          name = "Fedor Pakhomov";
        };
        paluh = {
          email = "paluho@gmail.com";
          github = "paluh";
          githubId = 190249;
          name = "Tomasz Rybarczyk";
        };
        pamplemousse = {
          email = "xav.maso@gmail.com";
          matrix = "@pamplemouss_:matrix.org";
          github = "Pamplemousse";
          githubId = 2647236;
          name = "Xavier Maso";
        };
        panaeon = {
          email = "vitalii.voloshyn@gmail.com";
          github = "PanAeon";
          githubId = 686076;
          name = "Vitalii Voloshyn";
        };
        pandaman = {
          email = "kointosudesuyo@infoseek.jp";
          github = "pandaman64";
          githubId = 1788628;
          name = "pandaman";
        };
        panicgh = {
          email = "nbenes.gh@xandea.de";
          github = "panicgh";
          githubId = 79252025;
          name = "Nicolas Benes";
        };
        paperdigits = {
          email = "mica@silentumbrella.com";
          github = "paperdigits";
          githubId = 71795;
          name = "Mica Semrick";
        };
        annaaurora = {
          email = "anna@annaaurora.eu";
          matrix = "@papojari:artemislena.eu";
          github = "auroraanna";
          githubId = 81317317;
          name = "Anna Aurora";
        };
        paraseba = {
          email = "paraseba@gmail.com";
          github = "paraseba";
          githubId = 20792;
          name = "Sebastian Galkin";
        };
        parasrah = {
          email = "nixos@parasrah.com";
          github = "Parasrah";
          githubId = 14935550;
          name = "Brad Pfannmuller";
        };
        parras = {
          email = "c@philipp-arras.de";
          github = "phiadaarr";
          githubId = 33826198;
          name = "Philipp Arras";
        };
        pashashocky = {
          email = "pashashocky@gmail.com";
          github = "pashashocky";
          githubId = 673857;
          name = "Pash Shocky";
        };
        pashev = {
          email = "pashev.igor@gmail.com";
          github = "ip1981";
          githubId = 131844;
          name = "Igor Pashev";
        };
        pasqui23 = {
          email = "p3dimaria@hotmail.it";
          github = "pasqui23";
          githubId = 6931743;
          name = "pasqui23";
        };
        patricksjackson = {
          email = "patrick@jackson.dev";
          github = "patricksjackson";
          githubId = 160646;
          name = "Patrick Jackson";
        };
        patryk27 = {
          email = "pwychowaniec@pm.me";
          github = "Patryk27";
          githubId = 3395477;
          name = "Patryk Wychowaniec";
          keys = [{
            fingerprint = "196A BFEC 6A1D D1EC 7594  F8D1 F625 47D0 75E0 9767";
          }];
        };
        patryk4815 = {
          email = "patryk.sondej@gmail.com";
          github = "patryk4815";
          githubId = 3074260;
          name = "Patryk Sondej";
        };
        patternspandemic = {
          email = "patternspandemic@live.com";
          github = "patternspandemic";
          githubId = 15645854;
          name = "Brad Christensen";
        };
        payas = {
          email = "relekarpayas@gmail.com";
          github = "bhankas";
          githubId = 24254289;
          name = "Payas Relekar";
        };
        pawelpacana = {
          email = "pawel.pacana@gmail.com";
          github = "pawelpacana";
          githubId = 116740;
          name = "Paweł Pacana";
        };
        pb- = {
          email = "pbaecher@gmail.com";
          github = "pb-";
          githubId = 84886;
          name = "Paul Baecher";
        };
        pbar = {
          email = "piercebartine@gmail.com";
          github = "pbar1";
          githubId = 26949935;
          name = "Pierce Bartine";
        };
        pbogdan = {
          email = "ppbogdan@gmail.com";
          github = "pbogdan";
          githubId = 157610;
          name = "Piotr Bogdan";
        };
        pborzenkov = {
          email = "pavel@borzenkov.net";
          github = "pborzenkov";
          githubId = 434254;
          name = "Pavel Borzenkov";
        };
        pblkt = {
          email = "pebblekite@gmail.com";
          github = "pblkt";
          githubId = 6498458;
          name = "pebble kite";
        };
        pbsds = {
          name = "Peder Bergebakken Sundt";
          email = "pbsds@hotmail.com";
          github = "pbsds";
          githubId = 140964;
        };
        pcarrier = {
          email = "pc@rrier.ca";
          github = "pcarrier";
          githubId = 8641;
          name = "Pierre Carrier";
        };
        pedrohlc = {
          email = "root@pedrohlc.com";
          github = "PedroHLC";
          githubId = 1368952;
          name = "Pedro Lara Campos";
        };
        penguwin = {
          email = "penguwin@penguwin.eu";
          github = "penguwin";
          githubId = 13225611;
          name = "Nicolas Martin";
        };
        pennae = {
          name = "pennae";
          email = "github@quasiparticle.net";
          github = "pennae";
          githubId = 82953136;
        };
        p3psi = {
          name = "Elliot Boo";
          email = "p3psi.boo@gmail.com";
          github = "p3psi-boo";
          githubId = 43925055;
        };
        periklis = {
          email = "theopompos@gmail.com";
          github = "periklis";
          githubId = 152312;
          name = "Periklis Tsirakidis";
        };
        petercommand = {
          email = "petercommand@gmail.com";
          github = "petercommand";
          githubId = 1260660;
          name = "petercommand";
        };
        peterhoeg = {
          email = "peter@hoeg.com";
          matrix = "@peter:hoeg.com";
          github = "peterhoeg";
          githubId = 722550;
          name = "Peter Hoeg";
        };
        peterromfeldhk = {
          email = "peter.romfeld.hk@gmail.com";
          github = "peterromfeldhk";
          githubId = 5515707;
          name = "Peter Romfeld";
        };
        petersjt014 = {
          email = "petersjt014@gmail.com";
          github = "petersjt014";
          githubId = 29493551;
          name = "Josh Peters";
        };
        peterwilli = {
          email = "peter@codebuffet.co";
          github = "peterwilli";
          githubId = 1212814;
          name = "Peter Willemsen";
          keys = [{
            fingerprint = "A37F D403 88E2 D026 B9F6  9617 5C9D D4BF B96A 28F0";
          }];
        };
        peti = {
          email = "simons@cryp.to";
          github = "peti";
          githubId = 28323;
          name = "Peter Simons";
        };
        petrosagg = {
          email = "petrosagg@gmail.com";
          github = "petrosagg";
          githubId = 939420;
          name = "Petros Angelatos";
        };
        petterstorvik = {
          email = "petterstorvik@gmail.com";
          github = "storvik";
          githubId = 3438604;
          name = "Petter Storvik";
        };
        p-h = {
          email = "p@hurlimann.org";
          github = "p-h";
          githubId = 645664;
          name = "Philippe Hürlimann";
        };
        phaer = {
          name = "Paul Haerle";
          email = "nix@phaer.org";
      
          matrix = "@phaer:matrix.org";
          github = "phaer";
          githubId = 101753;
          keys = [{
            fingerprint = "5D69 CF04 B7BC 2BC1 A567  9267 00BC F29B 3208 0700";
          }];
        };
        phdcybersec = {
          name = "Léo Lavaur";
          email = "phdcybersec@pm.me";
      
          github = "phdcybersec";
          githubId = 82591009;
          keys = [{
            fingerprint = "7756 E88F 3C6A 47A5 C5F0  CDFB AB54 6777 F93E 20BF";
          }];
        };
        phfroidmont = {
          name = "Paul-Henri Froidmont";
          email = "nix.contact-j9dw4d@froidmont.org";
      
          github = "phfroidmont";
          githubId = 8150907;
          keys = [{
            fingerprint = "3AC6 F170 F011 33CE 393B  CD94 BE94 8AFD 7E78 73BE";
          }];
        };
        philandstuff = {
          email = "philip.g.potter@gmail.com";
          github = "philandstuff";
          githubId = 581269;
          name = "Philip Potter";
        };
        phile314 = {
          email = "nix@314.ch";
          github = "phile314";
          githubId = 1640697;
          name = "Philipp Hausmann";
        };
        Philipp-M = {
          email = "philipp@mildenberger.me";
          github = "Philipp-M";
          githubId = 9267430;
          name = "Philipp Mildenberger";
        };
        Phlogistique = {
          email = "noe.rubinstein@gmail.com";
          github = "Phlogistique";
          githubId = 421510;
          name = "Noé Rubinstein";
        };
        photex = {
          email = "photex@gmail.com";
          github = "photex";
          githubId = 301903;
          name = "Chip Collier";
        };
        phryneas = {
          email = "mail@lenzw.de";
          github = "phryneas";
          githubId = 4282439;
          name = "Lenz Weber";
        };
        phunehehe = {
          email = "phunehehe@gmail.com";
          github = "phunehehe";
          githubId = 627831;
          name = "Hoang Xuan Phu";
        };
        piegames = {
          name = "piegames";
          email = "nix@piegames.de";
          matrix = "@piegames:matrix.org";
          github = "piegamesde";
          githubId = 14054505;
        };
        pierrechevalier83 = {
          email = "pierrechevalier83@gmail.com";
          github = "pierrechevalier83";
          githubId = 5790907;
          name = "Pierre Chevalier";
        };
        pierreis = {
          email = "pierre@pierre.is";
          github = "pierreis";
          githubId = 203973;
          name = "Pierre Matri";
        };
        pierrer = {
          email = "pierrer@pi3r.be";
          github = "PierreR";
          githubId = 93115;
          name = "Pierre Radermecker";
        };
        pierron = {
          email = "nixos@nbp.name";
          github = "nbp";
          githubId = 1179566;
          name = "Nicolas B. Pierron";
        };
        pimeys = {
          email = "julius@nauk.io";
          github = "pimeys";
          githubId = 34967;
          name = "Julius de Bruijn";
        };
        pingiun = {
          email = "nixos@pingiun.com";
          github = "pingiun";
          githubId = 1576660;
          name = "Jelle Besseling";
          keys = [{
            fingerprint = "A3A3 65AE 16ED A7A0 C29C  88F1 9712 452E 8BE3 372E";
          }];
        };
        pinpox = {
          email = "mail@pablo.tools";
          github = "pinpox";
          githubId = 1719781;
          name = "Pablo Ovelleiro Corral";
          keys = [{
            fingerprint = "D03B 218C AE77 1F77 D7F9  20D9 823A 6154 4264 08D3";
          }];
        };
        piperswe = {
          email = "contact@piperswe.me";
          github = "piperswe";
          githubId = 1830959;
          name = "Piper McCorkle";
        };
        pjbarnoy = {
          email = "pjbarnoy@gmail.com";
          github = "pjbarnoy";
          githubId = 119460;
          name = "Perry Barnoy";
        };
        pjjw = {
          email = "peter@shortbus.org";
          github = "pjjw";
          githubId = 638;
          name = "Peter Woodman";
        };
        pjones = {
          email = "pjones@devalot.com";
          github = "pjones";
          githubId = 3737;
          name = "Peter Jones";
        };
        pkharvey = {
          email = "kayharvey@protonmail.com";
          github = "pkharvey";
          githubId = 50750875;
          name = "Paul Harvey";
        };
        pkmx = {
          email = "pkmx.tw@gmail.com";
          github = "PkmX";
          githubId = 610615;
          name = "Chih-Mao Chen";
        };
        plabadens = {
          name = "Pierre Labadens";
          email = "labadens.pierre+nixpkgs@gmail.com";
          github = "plabadens";
          githubId = 4303706;
          keys = [{
            fingerprint = "B00F E582 FD3F 0732 EA48  3937 F558 14E4 D687 4375";
          }];
        };
        PlayerNameHere = {
          name = "Dixon Sean Low Yan Feng";
          email = "dixonseanlow@protonmail.com";
          github = "PlayerNameHere";
          githubId = 56017218;
          keys = [{
            fingerprint = "E6F4 BFB4 8DE3 893F 68FC  A15F FF5F 4B30 A41B BAC8";
          }];
        };
        plchldr = {
          email = "mail@oddco.de";
          github = "plchldr";
          githubId = 11639001;
          name = "Jonas Beyer";
        };
        plcplc = {
          email = "plcplc@gmail.com";
          github = "plcplc";
          githubId = 358550;
          name = "Philip Lykke Carlsen";
        };
        pleshevskiy = {
          email = "dmitriy@pleshevski.ru";
          github = "pleshevskiy";
          githubId = 7839004;
          name = "Dmitriy Pleshevskiy";
        };
        plumps = {
          email = "maks.bronsky@web.de";
          github = "plumps";
          githubId = 13000278;
          name = "Maksim Bronsky";
        };
        PlushBeaver = {
          name = "Dmitry Kozlyuk";
          email = "dmitry.kozliuk+nixpkgs@gmail.com";
          github = "PlushBeaver";
          githubId = 8988269;
        };
        pmahoney = {
          email = "pat@polycrystal.org";
          github = "pmahoney";
          githubId = 103822;
          name = "Patrick Mahoney";
        };
        pmenke = {
          email = "nixos@pmenke.de";
          github = "pmenke-de";
          githubId = 898922;
          name = "Philipp Menke";
          keys = [{
            fingerprint = "ED54 5EFD 64B6 B5AA EC61 8C16 EB7F 2D4C CBE2 3B69";
          }];
        };
        pmeunier = {
          email = "pierre-etienne.meunier@inria.fr";
          github = "P-E-Meunier";
          githubId = 17021304;
          name = "Pierre-Étienne Meunier";
        };
        pmiddend = {
          email = "pmidden@secure.mailbox.org";
          github = "pmiddend";
          githubId = 178496;
          name = "Philipp Middendorf";
        };
        pmw = {
          email = "philip@mailworks.org";
          matrix = "@philip4g:matrix.org";
          name = "Philip White";
          github = "philipmw";
          githubId = 1379645;
          keys = [{
            fingerprint = "9AB0 6C94 C3D1 F9D0 B9D9  A832 BC54 6FB3 B16C 8B0B";
          }];
        };
        pmy = {
          email = "pmy@xqzp.net";
          github = "pmeiyu";
          githubId = 8529551;
          name = "Peng Mei Yu";
        };
        pmyjavec = {
          email = "pauly@myjavec.com";
          github = "pmyjavec";
          githubId = 315096;
          name = "Pauly Myjavec";
        };
        pnelson = {
          email = "me@pnelson.ca";
          github = "pnelson";
          githubId = 579773;
          name = "Philip Nelson";
        };
        pneumaticat = {
          email = "kevin@potatofrom.space";
          github = "kliu128";
          githubId = 11365056;
          name = "Kevin Liu";
        };
        pnmadelaine = {
          name = "Paul-Nicolas Madelaine";
          email = "pnm@pnm.tf";
          github = "pnmadelaine";
          githubId = 21977014;
        };
        pnotequalnp = {
          email = "kevin@pnotequalnp.com";
          github = "pnotequalnp";
          githubId = 46154511;
          name = "Kevin Mullins";
          keys = [{
            fingerprint = "2CD2 B030 BD22 32EF DF5A  008A 3618 20A4 5DB4 1E9A";
          }];
        };
        podocarp = {
          email = "xdjiaxd@gmail.com";
          github = "podocarp";
          githubId = 10473184;
          name = "Jia Xiaodong";
        };
        pogobanane = {
          email = "mail@peter-okelmann.de";
          github = "pogobanane";
          githubId = 38314551;
          name = "Peter Okelmann";
        };
        polarmutex = {
          email = "brian@brianryall.xyz";
          github = "polarmutex";
          githubId = 115141;
          name = "Brian Ryall";
        };
        polendri = {
          email = "paul@ijj.li";
          github = "polendri";
          githubId = 1829032;
          name = "Paul Hendry";
        };
        polygon = {
          email = "polygon@wh2.tu-dresden.de";
          name = "Polygon";
          github = "polygon";
          githubId = 51489;
        };
        polykernel = {
          email = "81340136+polykernel@users.noreply.github.com";
          github = "polykernel";
          githubId = 81340136;
          name = "polykernel";
        };
        poelzi = {
          email = "nix@poelzi.org";
          github = "poelzi";
          githubId = 66107;
          name = "Daniel Poelzleithner";
        };
        polyrod = {
          email = "dc1mdp@gmail.com";
          github = "polyrod";
          githubId = 24878306;
          name = "Maurizio Di Pietro";
        };
        pombeirp = {
          email = "nix@endgr.33mail.com";
          github = "pedropombeiro";
          githubId = 138074;
          name = "Pedro Pombeiro";
        };
        poscat = {
          email = "poscat@mail.poscat.moe";
          github = "poscat0x04";
          githubId = 53291983;
          name = "Poscat Tarski";
          keys = [{
            fingerprint = "48AD DE10 F27B AFB4 7BB0  CCAF 2D25 95A0 0D08 ACE0";
          }];
        };
        posch = {
          email = "tp@fonz.de";
          github = "posch";
          githubId = 146413;
          name = "Tobias Poschwatta";
        };
        ppenguin = {
          name = "Jeroen Versteeg";
          email = "hieronymusv@gmail.com";
          github = "ppenguin";
          githubId = 17690377;
        };
        ppom = {
          name = "Paco Pompeani";
          email = "paco@ecomail.io";
          github = "aopom";
          githubId = 38916722;
        };
        pradeepchhetri = {
          email = "pradeep.chhetri89@gmail.com";
          github = "pradeepchhetri";
          githubId = 2232667;
          name = "Pradeep Chhetri";
        };
        pradyuman = {
          email = "me@pradyuman.co";
          github = "pradyuman";
          githubId = 9904569;
          name = "Pradyuman Vig";
          keys = [{
            fingerprint = "240B 57DE 4271 2480 7CE3  EAC8 4F74 D536 1C4C A31E";
          }];
        };
        preisschild = {
          email = "florian@florianstroeger.com";
          github = "Preisschild";
          githubId = 11898437;
          name = "Florian Ströger";
        };
        priegger = {
          email = "philipp@riegger.name";
          github = "priegger";
          githubId = 228931;
          name = "Philipp Riegger";
        };
        prikhi = {
          email = "pavan.rikhi@gmail.com";
          github = "prikhi";
          githubId = 1304102;
          name = "Pavan Rikhi";
        };
        primeos = {
          email = "dev.primeos@gmail.com";
          matrix = "@primeos:matrix.org";
          github = "primeos";
          githubId = 7537109;
          name = "Michael Weiss";
          keys = [
            {
              # Git only
              fingerprint = "86A7 4A55 07D0 58D1 322E  37FD 1308 26A6 C2A3 89FD";
            }
            {
              # Email, etc.
              fingerprint = "AF85 991C C950 49A2 4205  1933 BCA9 943D D1DF 4C04";
            }
          ];
        };
        prtzl = {
          email = "matej.blagsic@protonmail.com";
          github = "prtzl";
          githubId = 32430344;
          name = "Matej Blagsic";
        };
        ProducerMatt = {
          name = "Matthew Pherigo";
          email = "ProducerMatt42@gmail.com";
          github = "ProducerMatt";
          githubId = 58014742;
        };
        Profpatsch = {
          email = "mail@profpatsch.de";
          github = "Profpatsch";
          githubId = 3153638;
          name = "Profpatsch";
        };
        proglodyte = {
          email = "proglodyte23@gmail.com";
          github = "proglodyte";
          githubId = 18549627;
          name = "Proglodyte";
        };
        progval = {
          email = "progval+nix@progval.net";
          github = "progval";
          githubId = 406946;
          name = "Valentin Lorentz";
        };
        proofofkeags = {
          email = "keagan.mcclelland@gmail.com";
          github = "ProofOfKeags";
          githubId = 4033651;
          name = "Keagan McClelland";
        };
        protoben = {
          email = "protob3n@gmail.com";
          github = "protoben";
          githubId = 4633847;
          name = "Ben Hamlin";
        };
        prusnak = {
          email = "pavol@rusnak.io";
          github = "prusnak";
          githubId = 42201;
          name = "Pavol Rusnak";
          keys = [{
            fingerprint = "86E6 792F C27B FD47 8860  C110 91F3 B339 B9A0 2A3D";
          }];
        };
        psanford = {
          email = "psanford@sanford.io";
          github = "psanford";
          githubId = 33375;
          name = "Peter Sanford";
        };
        pshirshov = {
          email = "pshirshov@eml.cc";
          github = "pshirshov";
          githubId = 295225;
          name = "Pavel Shirshov";
        };
        psibi = {
          email = "sibi@psibi.in";
          matrix = "@psibi:matrix.org";
          github = "psibi";
          githubId = 737477;
          name = "Sibi Prabakaran";
        };
        pstn = {
          email = "philipp@xndr.de";
          github = "pstn";
          githubId = 1329940;
          name = "Philipp Steinpaß";
        };
        pSub = {
          email = "mail@pascal-wittmann.de";
          github = "pSub";
          githubId = 83842;
          name = "Pascal Wittmann";
        };
        psyanticy = {
          email = "iuns@outlook.fr";
          github = "PsyanticY";
          githubId = 20524473;
          name = "Psyanticy";
        };
        psydvl = {
          email = "psydvl@fea.st";
          github = "psydvl";
          githubId = 43755002;
          name = "Dmitriy P";
        };
        ptival = {
          email = "valentin.robert.42@gmail.com";
          github = "Ptival";
          githubId = 478606;
          name = "Valentin Robert";
        };
        ptrhlm = {
          email = "ptrhlm0@gmail.com";
          github = "ptrhlm";
          githubId = 9568176;
          name = "Piotr Halama";
        };
        puckipedia = {
          email = "puck@puckipedia.com";
          github = "puckipedia";
          githubId = 488734;
          name = "Puck Meerburg";
        };
        puffnfresh = {
          email = "brian@brianmckenna.org";
          github = "puffnfresh";
          githubId = 37715;
          name = "Brian McKenna";
        };
        purcell = {
          email = "steve@sanityinc.com";
          github = "purcell";
          githubId = 5636;
          name = "Steve Purcell";
        };
        putchar = {
          email = "slim.cadoux@gmail.com";
          matrix = "@putch4r:matrix.org";
          github = "putchar";
          githubId = 8208767;
          name = "Slim Cadoux";
        };
        puzzlewolf = {
          email = "nixos@nora.pink";
          github = "puzzlewolf";
          githubId = 23097564;
          name = "Nora Widdecke";
        };
        pyrolagus = {
          email = "pyrolagus@gmail.com";
          github = "PyroLagus";
          githubId = 4579165;
          name = "Danny Bautista";
        };
        peelz = {
          email = "peelz.dev+nixpkgs@gmail.com";
          github = "notpeelz";
          githubId = 920910;
          name = "peelz";
        };
        q3k = {
          email = "q3k@q3k.org";
          github = "q3k";
          githubId = 315234;
          name = "Serge Bazanski";
        };
        qknight = {
          email = "js@lastlog.de";
          github = "qknight";
          githubId = 137406;
          name = "Joachim Schiele";
        };
        qoelet = {
          email = "kenny@machinesung.com";
          github = "qoelet";
          githubId = 115877;
          name = "Kenny Shen";
        };
        quag = {
          email = "quaggy@gmail.com";
          github = "quag";
          githubId = 35086;
          name = "Jonathan Wright";
        };
        quantenzitrone = {
          email = "quantenzitrone@protonmail.com";
          github = "Quantenzitrone";
          githubId = 74491719;
          matrix = "@quantenzitrone:matrix.org";
          name = "quantenzitrone";
        };
        queezle = {
          email = "git@queezle.net";
          github = "queezle42";
          githubId = 1024891;
          name = "Jens Nolte";
        };
        quentini = {
          email = "quentini@airmail.cc";
          github = "QuentinI";
          githubId = 18196237;
          name = "Quentin Inkling";
        };
        qyliss = {
          email = "hi@alyssa.is";
          github = "alyssais";
          githubId = 2768870;
          name = "Alyssa Ross";
          keys = [{
            fingerprint = "7573 56D7 79BB B888 773E  415E 736C CDF9 EF51 BD97";
          }];
        };
        r-burns = {
          email = "rtburns@protonmail.com";
          github = "r-burns";
          githubId = 52847440;
          name = "Ryan Burns";
        };
        r3dl3g = {
          email = "redleg@rothfuss-web.de";
          github = "r3dl3g";
          githubId = 35229674;
          name = "Armin Rothfuss";
        };
        raboof = {
          email = "arnout@bzzt.net";
          matrix = "@raboof:matrix.org";
          github = "raboof";
          githubId = 131856;
          name = "Arnout Engelen";
        };
        rafael = {
          name = "Rafael";
          email = "pr9@tuta.io";
          github = "rafa-dot-el";
          githubId = 104688305;
          keys = [{
            fingerprint = "5F0B 3EAC F1F9 8155 0946 CDF5 469E 3255 A40D 2AD6";
          }];
        };
        RaghavSood = {
          email = "r@raghavsood.com";
          github = "RaghavSood";
          githubId = 903072;
          name = "Raghav Sood";
        };
        rafaelgg = {
          email = "rafael.garcia.gallego@gmail.com";
          github = "rafaelgg";
          githubId = 1016742;
          name = "Rafael García";
        };
        raitobezarius = {
          email = "ryan@lahfa.xyz";
          matrix = "@raitobezarius:matrix.org";
          github = "RaitoBezarius";
          githubId = 314564;
          name = "Ryan Lahfa";
        };
        raphaelr = {
          email = "raphael-git@tapesoftware.net";
          matrix = "@raphi:tapesoftware.net";
          github = "raphaelr";
          githubId = 121178;
          name = "Raphael Robatsch";
        };
        raquelgb = {
          email = "raquel.garcia.bautista@gmail.com";
          github = "raquelgb";
          githubId = 1246959;
          name = "Raquel García";
        };
        ragge = {
          email = "r.dahlen@gmail.com";
          github = "ragnard";
          githubId = 882;
          name = "Ragnar Dahlen";
        };
        ralith = {
          email = "ben.e.saunders@gmail.com";
          matrix = "@ralith:ralith.com";
          github = "Ralith";
          githubId = 104558;
          name = "Benjamin Saunders";
        };
        ramkromberg = {
          email = "ramkromberg@mail.com";
          github = "RamKromberg";
          githubId = 14829269;
          name = "Ram Kromberg";
        };
        ranfdev = {
          email = "ranfdev@gmail.com";
          name = "Lorenzo Miglietta";
          github = "ranfdev";
          githubId = 23294184;
        };
        rardiol = {
          email = "ricardo.ardissone@gmail.com";
          github = "rardiol";
          githubId = 11351304;
          name = "Ricardo Ardissone";
        };
        rasendubi = {
          email = "rasen.dubi@gmail.com";
          github = "rasendubi";
          githubId = 1366419;
          name = "Alexey Shmalko";
        };
        raskin = {
          email = "7c6f434c@mail.ru";
          github = "7c6f434c";
          githubId = 1891350;
          name = "Michael Raskin";
        };
        ratsclub = {
          email = "victor@freire.dev.br";
          github = "vtrf";
          githubId = 25647735;
          name = "Victor Freire";
        };
        rawkode = {
          email = "david.andrew.mckay@gmail.com";
          github = "rawkode";
          githubId = 145816;
          name = "David McKay";
        };
        razvan = {
          email = "razvan.panda@gmail.com";
          github = "razvan-flavius-panda";
          githubId = 1758708;
          name = "Răzvan Flavius Panda";
        };
        rb2k = {
          email = "nix@marc-seeger.com";
          github = "rb2k";
          githubId = 9519;
          name = "Marc Seeger";
        };
        rbasso = {
          email = "rbasso@sharpgeeks.net";
          github = "rbasso";
          githubId = 16487165;
          name = "Rafael Basso";
        };
        rbreslow = {
          name = "Rocky Breslow";
          email = "1774125+rbreslow@users.noreply.github.com";
          github = "rbreslow";
          githubId = 1774125;
          keys = [{
            fingerprint = "B5B7 BCA0 EE6F F31E 263A  69E3 A0D3 2ACC A38B 88ED";
          }];
        };
        rbrewer = {
          email = "rwb123@gmail.com";
          github = "rbrewer123";
          githubId = 743058;
          name = "Rob Brewer";
        };
        rdnetto = {
          email = "rdnetto@gmail.com";
          github = "rdnetto";
          githubId = 1973389;
          name = "Reuben D'Netto";
        };
        realsnick = {
          name = "Ido Samuelson";
          email = "ido.samuelson@gmail.com";
          github = "realsnick";
          githubId = 1440852;
        };
        redbaron = {
          email = "ivanov.maxim@gmail.com";
          github = "redbaron";
          githubId = 16624;
          name = "Maxim Ivanov";
        };
        reckenrode = {
          name = "Randy Eckenrode";
          email = "randy@largeandhighquality.com";
          matrix = "@reckenrode:matrix.org";
          github = "reckenrode";
          githubId = 7413633;
          keys = [
            # compare with https://keybase.io/reckenrode
            {
              fingerprint = "01D7 5486 3A6D 64EA AC77 0D26 FBF1 9A98 2CCE 0048";
            }
          ];
        };
        redfish64 = {
          email = "engler@gmail.com";
          github = "redfish64";
          githubId = 1922770;
          name = "Tim Engler";
        };
        redvers = {
          email = "red@infect.me";
          github = "redvers";
          githubId = 816465;
          name = "Redvers Davies";
        };
        reedrw = {
          email = "reedrw5601@gmail.com";
          github = "reedrw";
          githubId = 21069876;
          name = "Reed Williams";
        };
        refnil = {
          email = "broemartino@gmail.com";
          github = "refnil";
          githubId = 1142322;
          name = "Martin Lavoie";
        };
        regadas = {
          email = "oss@regadas.email";
          name = "Filipe Regadas";
          github = "regadas";
          githubId = 163899;
        };
        regnat = {
          email = "regnat@regnat.ovh";
          github = "thufschmitt";
          githubId = 7226587;
          name = "Théophane Hufschmitt";
        };
        rehno-lindeque = {
          email = "rehno.lindeque+code@gmail.com";
          github = "rehno-lindeque";
          githubId = 337811;
          name = "Rehno Lindeque";
        };
        relrod = {
          email = "ricky@elrod.me";
          github = "relrod";
          githubId = 43930;
          name = "Ricky Elrod";
        };
        rembo10 = {
          email = "rembo10@users.noreply.github.com";
          github = "rembo10";
          githubId = 801525;
          name = "rembo10";
        };
        renatoGarcia = {
          email = "fgarcia.renato@gmail.com";
          github = "renatoGarcia";
          githubId = 220211;
          name = "Renato Garcia";
        };
        rencire = {
          email = "546296+rencire@users.noreply.github.com";
          github = "rencire";
          githubId = 546296;
          name = "Eric Ren";
        };
        renesat = {
          name = "Ivan Smolyakov";
          email = "smol.ivan97@gmail.com";
          github = "renesat";
          githubId = 11363539;
        };
        renzo = {
          email = "renzocarbonara@gmail.com";
          github = "k0001";
          githubId = 3302;
          name = "Renzo Carbonara";
        };
        retrry = {
          email = "retrry@gmail.com";
          github = "retrry";
          githubId = 500703;
          name = "Tadas Barzdžius";
        };
        revol-xut = {
          email = "revol-xut@protonmail.com";
          name = "Tassilo Tanneberger";
          github = "revol-xut";
          githubId = 32239737;
          keys = [{
            fingerprint = "91EB E870 1639 1323 642A  6803 B966 009D 57E6 9CC6";
          }];
        };
        rexim = {
          email = "reximkut@gmail.com";
          github = "rexim";
          githubId = 165283;
          name = "Alexey Kutepov";
        };
        rewine = {
          email = "lhongxu@outlook.com";
          github = "wineee";
          githubId = 22803888;
          name = "Lu Hongxu";
        };
        rgnns = {
          email = "jglievano@gmail.com";
          github = "rgnns";
          githubId = 811827;
          name = "Gabriel Lievano";
        };
        rgrinberg = {
          name = "Rudi Grinberg";
          email = "me@rgrinberg.com";
          github = "rgrinberg";
          githubId = 139003;
        };
        rgrunbla = {
          email = "remy@grunblatt.org";
          github = "rgrunbla";
          githubId = 42433779;
          name = "Rémy Grünblatt";
        };
        rguevara84 = {
          email = "fuzztkd@gmail.com";
          github = "rguevara84";
          githubId = 12279531;
          name = "Ricardo Guevara";
        };
        rht = {
          email = "rhtbot@protonmail.com";
          github = "rht";
          githubId = 395821;
          name = "rht";
        };
        rhoriguchi = {
          email = "ryan.horiguchi@gmail.com";
          github = "rhoriguchi";
          githubId = 6047658;
          name = "Ryan Horiguchi";
        };
        rhysmdnz = {
          email = "rhys@memes.nz";
          matrix = "@rhys:memes.nz";
          github = "rhysmdnz";
          githubId = 2162021;
          name = "Rhys Davies";
        };
        ribose-jeffreylau = {
          name = "Jeffrey Lau";
          email = "jeffrey.lau@ribose.com";
          github = "ribose-jeffreylau";
          githubId = 2649467;
        };
        richardipsum = {
          email = "richardipsum@fastmail.co.uk";
          github = "richardipsum";
          githubId = 10631029;
          name = "Richard Ipsum";
        };
        rick68 = {
          email = "rick68@gmail.com";
          github = "rick68";
          githubId = 42619;
          name = "Wei-Ming Yang";
        };
        rickynils = {
          email = "rickynils@gmail.com";
          github = "rickynils";
          githubId = 16779;
          name = "Rickard Nilsson";
        };
        ricochet = {
          email = "behayes2@gmail.com";
          github = "ricochet";
          githubId = 974323;
          matrix = "@ricochetcode:matrix.org";
          name = "Bailey Hayes";
        };
        riey = {
          email = "creeper844@gmail.com";
          github = "Riey";
          githubId = 14910534;
          name = "Riey";
        };
        rika = {
          email = "rika@paymentswit.ch";
          github = "NekomimiScience";
          githubId = 1810487;
          name = "Rika";
        };
        rileyinman = {
          email = "rileyminman@gmail.com";
          github = "rileyinman";
          githubId = 37246692;
          name = "Riley Inman";
        };
        riotbib = {
          email = "github-nix@lnrt.de";
          github = "riotbib";
          githubId = 43172581;
          name = "Lennart Mühlenmeier";
        };
        ris = {
          email = "code@humanleg.org.uk";
          github = "risicle";
          githubId = 807447;
          name = "Robert Scott";
        };
        risson = {
          name = "Marc Schmitt";
          email = "marc.schmitt@risson.space";
          matrix = "@risson:lama-corp.space";
          github = "rissson";
          githubId = 18313093;
          keys = [
            {
              fingerprint = "8A0E 6A7C 08AB B9DE 67DE  2A13 F6FD 87B1 5C26 3EC9";
            }
            {
              fingerprint = "C0A7 A9BB 115B C857 4D75  EA99 BBB7 A680 1DF1 E03F";
            }
          ];
        };
        rixed = {
          email = "rixed-github@happyleptic.org";
          github = "rixed";
          githubId = 449990;
          name = "Cedric Cellier";
        };
        rkitover = {
          email = "rkitover@gmail.com";
          github = "rkitover";
          githubId = 77611;
          name = "Rafael Kitover";
        };
        rkoe = {
          email = "rk@simple-is-better.org";
          github = "rkoe";
          githubId = 2507744;
          name = "Roland Koebler";
        };
        rizary = {
          email = "andika@numtide.com";
          github = "Rizary";
          githubId = 7221768;
          name = "Andika Demas Riyandi";
        };
        rkrzr = {
          email = "ops+nixpkgs@channable.com";
          github = "rkrzr";
          githubId = 82817;
          name = "Robert Kreuzer";
        };
        rlupton20 = {
          email = "richard.lupton@gmail.com";
          github = "rlupton20";
          githubId = 13752145;
          name = "Richard Lupton";
        };
        rmcgibbo = {
          email = "rmcgibbo@gmail.com";
          matrix = "@rmcgibbo:matrix.org";
          github = "rmcgibbo";
          githubId = 641278;
          name = "Robert T. McGibbon";
        };
        rnhmjoj = {
          email = "rnhmjoj@inventati.org";
          matrix = "@rnhmjoj:maxwell.ydns.eu";
          github = "rnhmjoj";
          githubId = 2817565;
          name = "Michele Guerini Rocco";
          keys = [{
            fingerprint = "92B2 904F D293 C94D C4C9  3E6B BFBA F4C9 75F7 6450";
          }];
        };
        roastiek = {
          email = "r.dee.b.b@gmail.com";
          github = "roastiek";
          githubId = 422802;
          name = "Rostislav Beneš";
        };
        rob = {
          email = "rob.vermaas@gmail.com";
          github = "rbvermaa";
          githubId = 353885;
          name = "Rob Vermaas";
        };
        robaca = {
          email = "carsten@r0hrbach.de";
          github = "robaca";
          githubId = 580474;
          name = "Carsten Rohrbach";
        };
        robberer = {
          email = "robberer@freakmail.de";
          github = "robberer";
          githubId = 6204883;
          name = "Longrin Wischnewski";
        };
        robbinch = {
          email = "robbinch33@gmail.com";
          github = "robbinch";
          githubId = 12312980;
          name = "Robbin C.";
        };
        robbins = {
          email = "nejrobbins@gmail.com";
          github = "robbins";
          githubId = 31457698;
          name = "Nathanael Robbins";
        };
        roberth = {
          email = "nixpkgs@roberthensing.nl";
          matrix = "@roberthensing:matrix.org";
          github = "roberth";
          githubId = 496447;
          name = "Robert Hensing";
        };
        robertodr = {
          email = "roberto.diremigio@gmail.com";
          github = "robertodr";
          githubId = 3708689;
          name = "Roberto Di Remigio";
        };
        robertoszek = {
          email = "robertoszek@robertoszek.xyz";
          github = "robertoszek";
          githubId = 1080963;
          name = "Roberto";
        };
        robgssp = {
          email = "robgssp@gmail.com";
          github = "robgssp";
          githubId = 521306;
          name = "Rob Glossop";
        };
        roblabla = {
          email = "robinlambertz+dev@gmail.com";
          github = "roblabla";
          githubId = 1069318;
          name = "Robin Lambertz";
        };
        roconnor = {
          email = "roconnor@theorem.ca";
          github = "roconnor";
          githubId = 852967;
          name = "Russell O'Connor";
        };
        rodrgz = {
          email = "erik@rodgz.com";
          github = "rodrgz";
          githubId = 53882428;
          name = "Erik Rodriguez";
        };
        roelvandijk = {
          email = "roel@lambdacube.nl";
          github = "roelvandijk";
          githubId = 710906;
          name = "Roel van Dijk";
        };
        romildo = {
          email = "malaquias@gmail.com";
          github = "romildo";
          githubId = 1217934;
          name = "José Romildo Malaquias";
        };
        ronanmacf = {
          email = "macfhlar@tcd.ie";
          github = "RonanMacF";
          githubId = 25930627;
          name = "Ronan Mac Fhlannchadha";
        };
        rongcuid = {
          email = "rongcuid@outlook.com";
          github = "rongcuid";
          githubId = 1312525;
          name = "Rongcui Dong";
        };
        roosemberth = {
          email = "roosembert.palacios+nixpkgs@posteo.ch";
          matrix = "@roosemberth:orbstheorem.ch";
          github = "roosemberth";
          githubId = 3621083;
          name = "Roosembert (Roosemberth) Palacios";
          keys = [{
            fingerprint = "78D9 1871 D059 663B 6117  7532 CAAA ECE5 C224 2BB7";
          }];
        };
        rople380 = {
          name = "rople380";
          email = "55679162+rople380@users.noreply.github.com";
          github = "rople380";
          githubId = 55679162;
          keys = [{
            fingerprint = "1401 1B63 393D 16C1 AA9C  C521 8526 B757 4A53 6236";
          }];
        };
        rowanG077 = {
          email = "goemansrowan@gmail.com";
          github = "rowanG077";
          githubId = 7439756;
          name = "Rowan Goemans";
        };
        royneary = {
          email = "christian@ulrich.earth";
          github = "royneary";
          githubId = 1942810;
          name = "Christian Ulrich";
        };
        rpearce = {
          email = "me@robertwpearce.com";
          github = "rpearce";
          githubId = 592876;
          name = "Robert W. Pearce";
        };
        rprecenth = {
          email = "rasmus@precenth.eu";
          github = "Prillan";
          githubId = 1675190;
          name = "Rasmus Précenth";
        };
        rprospero = {
          email = "rprospero+nix@gmail.com";
          github = "rprospero";
          githubId = 1728853;
          name = "Adam Washington";
        };
        rps = {
          email = "robbpseaton@gmail.com";
          github = "robertseaton";
          githubId = 221121;
          name = "Robert P. Seaton";
        };
        rraval = {
          email = "ronuk.raval@gmail.com";
          github = "rraval";
          githubId = 373566;
          name = "Ronuk Raval";
        };
        rrbutani = {
          email = "rrbutani+nix@gmail.com";
          github = "rrbutani";
          githubId = 7833358;
          keys = [{
            fingerprint = "7DCA 5615 8AB2 621F 2F32  9FF4 1C7C E491 479F A273";
          }];
          name = "Rahul Butani";
        };
        rski = {
          name = "rski";
          email = "rom.skiad+nix@gmail.com";
          github = "rski";
          githubId = 2960312;
        };
        rszibele = {
          email = "richard@szibele.com";
          github = "rszibele";
          githubId = 1387224;
          name = "Richard Szibele";
        };
        rsynnest = {
          email = "contact@rsynnest.com";
          github = "rsynnest";
          githubId = 4392850;
          name = "Roland Synnestvedt";
        };
        rtburns-jpl = {
          email = "rtburns@jpl.nasa.gov";
          github = "rtburns-jpl";
          githubId = 47790121;
          name = "Ryan Burns";
        };
        rtreffer = {
          email = "treffer+nixos@measite.de";
          github = "rtreffer";
          githubId = 61306;
          name = "Rene Treffer";
        };
        rushmorem = {
          email = "rushmore@webenchanter.com";
          github = "rushmorem";
          githubId = 4958190;
          name = "Rushmore Mushambi";
        };
        russell = {
          email = "russell.sim@gmail.com";
          github = "russell";
          githubId = 2660;
          name = "Russell Sim";
        };
        ruuda = {
          email = "dev+nix@veniogames.com";
          github = "ruuda";
          githubId = 506953;
          name = "Ruud van Asseldonk";
        };
        rvarago = {
          email = "rafael.varago@gmail.com";
          github = "rvarago";
          githubId = 7365864;
          name = "Rafael Varago";
        };
        rvl = {
          email = "dev+nix@rodney.id.au";
          github = "rvl";
          githubId = 1019641;
          name = "Rodney Lorrimar";
        };
        rvlander = {
          email = "rvlander@gaetanandre.eu";
          github = "rvlander";
          githubId = 5236428;
          name = "Gaëtan André";
        };
        rvolosatovs = {
          email = "rvolosatovs@riseup.net";
          github = "rvolosatovs";
          githubId = 12877905;
          name = "Roman Volosatovs";
        };
        ryanartecona = {
          email = "ryanartecona@gmail.com";
          github = "ryanartecona";
          githubId = 889991;
          name = "Ryan Artecona";
        };
        ryanorendorff = {
          email = "12442942+ryanorendorff@users.noreply.github.com";
          github = "ryanorendorff";
          githubId = 12442942;
          name = "Ryan Orendorff";
        };
        ryansydnor = {
          email = "ryan.t.sydnor@gmail.com";
          github = "ryansydnor";
          githubId = 1832096;
          name = "Ryan Sydnor";
        };
        ryantm = {
          email = "ryan@ryantm.com";
          matrix = "@ryantm:matrix.org";
          github = "ryantm";
          githubId = 4804;
          name = "Ryan Mulligan";
        };
        ryantrinkle = {
          email = "ryan.trinkle@gmail.com";
          github = "ryantrinkle";
          githubId = 1156448;
          name = "Ryan Trinkle";
        };
        rybern = {
          email = "ryan.bernstein@columbia.edu";
          github = "rybern";
          githubId = 4982341;
          name = "Ryan Bernstein";
        };
        rycee = {
          email = "robert@rycee.net";
          github = "rycee";
          githubId = 798147;
          name = "Robert Helgesson";
          keys = [{
            fingerprint = "36CA CF52 D098 CC0E 78FB  0CB1 3573 356C 25C4 24D4";
          }];
        };
        ryneeverett = {
          email = "ryneeverett@gmail.com";
          github = "ryneeverett";
          githubId = 3280280;
          name = "Ryne Everett";
        };
        rytone = {
          email = "max@ryt.one";
          github = "rastertail";
          githubId = 8082305;
          name = "Maxwell Beck";
          keys = [{
            fingerprint = "D260 79E3 C2BC 2E43 905B  D057 BB3E FA30 3760 A0DB";
          }];
        };
        rzetterberg = {
          email = "richard.zetterberg@gmail.com";
          github = "rzetterberg";
          githubId = 766350;
          name = "Richard Zetterberg";
        };
        s1341 = {
          email = "s1341@shmarya.net";
          matrix = "@s1341:matrix.org";
          name = "Shmarya Rubenstein";
          github = "s1341";
          githubId = 5682183;
        };
        sagikazarmark = {
          name = "Mark Sagi-Kazar";
          email = "mark.sagikazar@gmail.com";
          matrix = "@mark.sagikazar:matrix.org";
          github = "sagikazarmark";
          githubId = 1226384;
          keys = [{
            fingerprint = "E628 C811 6FB8 1657 F706  4EA4 F251 ADDC 9D04 1C7E";
          }];
        };
        samalws = {
          email = "sam@samalws.com";
          name = "Sam Alws";
          github = "samalws";
          githubId = 20981725;
        };
        samb96 = {
          email = "samb96@gmail.com";
          github = "samb96";
          githubId = 819426;
          name = "Sam Bickley";
        };
        samdoshi = {
          email = "sam@metal-fish.co.uk";
          github = "samdoshi";
          githubId = 112490;
          name = "Sam Doshi";
        };
        samdroid-apps = {
          email = "sam@sam.today";
          github = "samdroid-apps";
          githubId = 6022042;
          name = "Sam Parkinson";
        };
        samlich = {
          email = "nixos@samli.ch";
          github = "samlich";
          githubId = 1349989;
          name = "samlich";
          keys = [{
            fingerprint = "AE8C 0836 FDF6 3FFC 9580  C588 B156 8953 B193 9F1C";
          }];
        };
        samlukeyes123 = {
          email = "samlukeyes123@gmail.com";
          github = "SamLukeYes";
          githubId = 12882091;
          name = "Sam L. Yes";
        };
        samrose = {
          email = "samuel.rose@gmail.com";
          github = "samrose";
          githubId = 115821;
          name = "Sam Rose";
        };
        samuela = {
          email = "skainsworth@gmail.com";
          github = "samuela";
          githubId = 226872;
          name = "Samuel Ainsworth";
        };
        samueldr = {
          email = "samuel@dionne-riel.com";
          matrix = "@samueldr:matrix.org";
          github = "samueldr";
          githubId = 132835;
          name = "Samuel Dionne-Riel";
        };
        samuelrivas = {
          email = "samuelrivas@gmail.com";
          github = "samuelrivas";
          githubId = 107703;
          name = "Samuel Rivas";
        };
        samw = {
          email = "sam@wlcx.cc";
          github = "wlcx";
          githubId = 3065381;
          name = "Sam Willcocks";
        };
        samyak = {
          name = "Samyak Sarnayak";
          email = "samyak201@gmail.com";
          github = "Samyak2";
          githubId = 34161949;
          keys = [{
            fingerprint = "155C F413 0129 C058 9A5F  5524 3658 73F2 F0C6 153B";
          }];
        };
        sander = {
          email = "s.vanderburg@tudelft.nl";
          github = "svanderburg";
          githubId = 1153271;
          name = "Sander van der Burg";
        };
        sarcasticadmin = {
          email = "rob@sarcasticadmin.com";
          github = "sarcasticadmin";
          githubId = 30531572;
          name = "Robert James Hernandez";
        };
        sargon = {
          email = "danielehlers@mindeye.net";
          github = "sargon";
          githubId = 178904;
          name = "Daniel Ehlers";
        };
        saschagrunert = {
          email = "mail@saschagrunert.de";
          github = "saschagrunert";
          githubId = 695473;
          name = "Sascha Grunert";
        };
        sauyon = {
          email = "s@uyon.co";
          github = "sauyon";
          githubId = 2347889;
          name = "Sauyon Lee";
        };
        savannidgerinel = {
          email = "savanni@luminescent-dreams.com";
          github = "savannidgerinel";
          githubId = 8534888;
          name = "Savanni D'Gerinel";
        };
        sayanarijit = {
          email = "sayanarijit@gmail.com";
          github = "sayanarijit";
          githubId = 11632726;
          name = "Arijit Basu";
        };
        sb0 = {
          email = "sb@m-labs.hk";
          github = "sbourdeauducq";
          githubId = 720864;
          name = "Sébastien Bourdeauducq";
        };
        sbellem = {
          email = "sbellem@gmail.com";
          github = "sbellem";
          githubId = 125458;
          name = "Sylvain Bellemare";
        };
        sbond75 = {
          name = "sbond75";
          email = "43617712+sbond75@users.noreply.github.com";
          github = "sbond75";
          githubId = 43617712;
        };
        sboosali = {
          email = "SamBoosalis@gmail.com";
          github = "sboosali";
          githubId = 2320433;
          name = "Sam Boosalis";
        };
        sbruder = {
          email = "nixos@sbruder.de";
          github = "sbruder";
          githubId = 15986681;
          name = "Simon Bruder";
        };
        scalavision = {
          email = "scalavision@gmail.com";
          github = "scalavision";
          githubId = 3958212;
          name = "Tom Sorlie";
        };
        sioodmy = {
          name = "Antoni Sokołowski";
          email = "81568712+sioodmy@users.noreply.github.com";
          github = "sioodmy";
          githubId = 81568712;
        };
        siph = {
          name = "Chris Dawkins";
          email = "dawkins.chris.dev@gmail.com";
          github = "siph";
          githubId = 6619112;
        };
        schmitthenner = {
          email = "development@schmitthenner.eu";
          github = "fkz";
          githubId = 354463;
          name = "Fabian Schmitthenner";
        };
        schmittlauch = {
          name = "Trolli Schmittlauch";
          email = "t.schmittlauch+nixos@orlives.de";
          github = "schmittlauch";
          githubId = 1479555;
        };
        schneefux = {
          email = "schneefux+nixos_pkg@schneefux.xyz";
          github = "schneefux";
          githubId = 15379000;
          name = "schneefux";
        };
        schnusch = {
          email = "schnusch@users.noreply.github.com";
          github = "schnusch";
          githubId = 5104601;
          name = "schnusch";
        };
        sciencentistguy = {
          email = "jamie@quigley.xyz";
          name = "Jamie Quigley";
          github = "Sciencentistguy";
          githubId = 4983935;
          keys = [{
            fingerprint = "30BB FF3F AB0B BB3E 0435  F83C 8E8F F66E 2AE8 D970";
          }];
        };
        scode = {
          email = "peter.schuller@infidyne.com";
          github = "scode";
          githubId = 59476;
          name = "Peter Schuller";
        };
        scoder12 = {
          name = "Spencer Pogorzelski";
          email = "34356756+Scoder12@users.noreply.github.com";
          github = "Scoder12";
          githubId = 34356756;
        };
        scolobb = {
          email = "sivanov@colimite.fr";
          github = "scolobb";
          githubId = 11320;
          name = "Sergiu Ivanov";
        };
        screendriver = {
          email = "nix@echooff.de";
          github = "screendriver";
          githubId = 149248;
          name = "Christian Rackerseder";
        };
        Scriptkiddi = {
          email = "nixos@scriptkiddi.de";
          matrix = "@fritz.otlinghaus:helsinki-systems.de";
          github = "Scriptkiddi";
          githubId = 3598650;
          name = "Fritz Otlinghaus";
        };
        Scrumplex = {
          name = "Sefa Eyeoglu";
          email = "contact@scrumplex.net";
          matrix = "@Scrumplex:duckhub.io";
          github = "Scrumplex";
          githubId = 11587657;
          keys = [{
            fingerprint = "AF1F B107 E188 CB97 9A94  FD7F C104 1129 4912 A422";
          }];
        };
        scubed2 = {
          email = "scubed2@gmail.com";
          github = "scubed2";
          githubId = 7401858;
          name = "Sterling Stein";
        };
        sdier = {
          email = "scott@dier.name";
          matrix = "@sdier:matrix.org";
          github = "sdier";
          githubId = 11613056;
          name = "Scott Dier";
        };
        SeanZicari = {
          email = "sean.zicari@gmail.com";
          github = "SeanZicari";
          githubId = 2343853;
          name = "Sean Zicari";
        };
        seb314 = {
          email = "sebastian@seb314.com";
          github = "seb314";
          githubId = 19472270;
          name = "Sebastian";
        };
        sebastianblunt = {
          name = "Sebastian Blunt";
          email = "nix@sebastianblunt.com";
          github = "sebastianblunt";
          githubId = 47431204;
        };
        sebbadk = {
          email = "sebastian@sebba.dk";
          github = "SEbbaDK";
          githubId = 1567527;
          name = "Sebastian Hyberts";
        };
        sebbel = {
          email = "hej@sebastian-ball.de";
          github = "sebbel";
          githubId = 1940568;
          name = "Sebastian Ball";
        };
        seberm = {
          email = "seberm@seberm.com";
          github = "seberm";
          githubId = 212597;
          name = "Otto Sabart";
          keys = [{
            fingerprint = "0AF6 4C3B 1F12 14B3 8C8C  5786 1FA2 DBE6 7438 7CC3";
          }];
        };
        sebtm = {
          email = "mail@sebastian-sellmeier.de";
          github = "SebTM";
          githubId = 17243347;
          name = "Sebastian Sellmeier";
        };
        sellout = {
          email = "greg@technomadic.org";
          github = "sellout";
          githubId = 33031;
          name = "Greg Pfeil";
        };
        sengaya = {
          email = "tlo@sengaya.de";
          github = "sengaya";
          githubId = 1286668;
          name = "Thilo Uttendorfer";
        };
        sephalon = {
          email = "me@sephalon.net";
          github = "sephalon";
          githubId = 893474;
          name = "Stefan Wiehler";
        };
        sephi = {
          name = "Sylvain Fankhauser";
          email = "sephi@fhtagn.top";
          github = "sephii";
          githubId = 754333;
          keys = [{
            fingerprint = "2A9D 8E76 5EE2 237D 7B6B  A2A5 4228 AB9E C061 2ADA";
          }];
        };
        sepi = {
          email = "raffael@mancini.lu";
          github = "sepi";
          githubId = 529649;
          name = "Raffael Mancini";
        };
        seppeljordan = {
          email = "sebastian.jordan.mail@googlemail.com";
          github = "seppeljordan";
          githubId = 4805746;
          name = "Sebastian Jordan";
        };
        seqizz = {
          email = "seqizz@gmail.com";
          github = "seqizz";
          githubId = 307899;
          name = "Gurkan Gur";
        };
        serge = {
          email = "sb@canva.com";
          github = "serge-belov";
          githubId = 38824235;
          name = "Serge Belov";
        };
        sersorrel = {
          email = "ash@sorrel.sh";
          github = "sersorrel";
          githubId = 9433472;
          name = "ash";
        };
        servalcatty = {
          email = "servalcat@pm.me";
          github = "servalcatty";
          githubId = 51969817;
          name = "Serval";
          keys = [{
            fingerprint = "A317 37B3 693C 921B 480C  C629 4A2A AAA3 82F8 294C";
          }];
        };
        seylerius = {
          name = "Sable Seyler";
          email = "sable@seyleri.us";
          github = "seylerius";
          githubId = 1145981;
          keys = [{
            fingerprint = "7246 B6E1 ABB9 9A48 4395  FD11 DC26 B921 A9E9 DBDE";
          }];
        };
        sfrijters = {
          email = "sfrijters@gmail.com";
          github = "SFrijters";
          githubId = 918365;
          name = "Stefan Frijters";
        };
        sgo = {
          email = "stig@stig.io";
          github = "stigtsp";
          githubId = 75371;
          name = "Stig Palmquist";
        };
        sgraf = {
          email = "sgraf1337@gmail.com";
          github = "sgraf812";
          githubId = 1151264;
          name = "Sebastian Graf";
        };
        shadaj = {
          email = "shadaj@users.noreply.github.com";
          github = "shadaj";
          githubId = 543055;
          name = "Shadaj Laddad";
        };
        shadowrz = {
          email = "shadowrz+nixpkgs@disroot.org";
          matrix = "@ShadowRZ:matrixim.cc";
          github = "ShadowRZ";
          githubId = 23130178;
          name = "夜坂雅";
        };
        shahrukh330 = {
          email = "shahrukh330@gmail.com";
          github = "shahrukh330";
          githubId = 1588288;
          name = "Shahrukh Khan";
        };
        shamilton = {
          email = "sgn.hamilton@protonmail.com";
          github = "SCOTT-HAMILTON";
          githubId = 24496705;
          name = "Scott Hamilton";
        };
        ShamrockLee = {
          name = "Shamrock Lee";
          email = "44064051+ShamrockLee@users.noreply.github.com";
          github = "ShamrockLee";
          githubId = 44064051;
        };
        shanemikel = {
          email = "shanepearlman@pm.me";
          github = "shanemikel";
          githubId = 6720672;
          name = "Shane Pearlman";
        };
        shanesveller = {
          email = "shane@sveller.dev";
          github = "shanesveller";
          githubId = 831;
          keys = [{
            fingerprint = "F83C 407C ADC4 5A0F 1F2F  44E8 9210 C218 023C 15CD";
          }];
          name = "Shane Sveller";
        };
        shawndellysse = {
          email = "sdellysse@gmail.com";
          github = "sdellysse";
          githubId = 293035;
          name = "Shawn Dellysse";
        };
        shawn8901 = {
          email = "shawn8901@googlemail.com";
          github = "Shawn8901";
          githubId = 12239057;
          name = "Shawn8901";
        };
        shazow = {
          email = "andrey.petrov@shazow.net";
          github = "shazow";
          githubId = 6292;
          name = "Andrey Petrov";
        };
        sheenobu = {
          email = "sheena.artrip@gmail.com";
          github = "sheenobu";
          githubId = 1443459;
          name = "Sheena Artrip";
        };
        sheepforce = {
          email = "phillip.seeber@googlemail.com";
          github = "sheepforce";
          githubId = 16844216;
          name = "Phillip Seeber";
        };
        sheganinans = {
          email = "sheganinans@gmail.com";
          github = "sheganinans";
          githubId = 2146203;
          name = "Aistis Raulinaitis";
        };
        shell = {
          email = "cam.turn@gmail.com";
          github = "VShell";
          githubId = 251028;
          name = "Shell Turner";
        };
        shikanime = {
          name = "William Phetsinorath";
          email = "deva.shikanime@protonmail.com";
          github = "shikanime";
          githubId = 22115108;
        };
        shiryel = {
          email = "contact@shiryel.com";
          name = "Shiryel";
          github = "shiryel";
          githubId = 35617139;
          keys = [{
            fingerprint = "AB63 4CD9 3322 BD42 6231  F764 C404 1EA6 B326 33DE";
          }];
        };
        shlevy = {
          email = "shea@shealevy.com";
          github = "shlevy";
          githubId = 487050;
          name = "Shea Levy";
        };
        shmish111 = {
          email = "shmish111@gmail.com";
          github = "shmish111";
          githubId = 934267;
          name = "David Smith";
        };
        shnarazk = {
          email = "shujinarazaki@protonmail.com";
          github = "shnarazk";
          githubId = 997855;
          name = "Narazaki Shuji";
        };
        shofius = {
          name = "Sam Hofius";
          email = "sam@samhofi.us";
          github = "kf5grd";
          githubId = 18297490;
        };
        shou = {
          email = "x+g@shou.io";
          github = "Shou";
          githubId = 819413;
          name = "Benedict Aas";
        };
        shreerammodi = {
          name = "Shreeram Modi";
          email = "shreerammodi10@gmail.com";
          github = "Shrimpram";
          githubId = 67710369;
          keys = [{
            fingerprint = "EA88 EA07 26E9 6CBF 6365  3966 163B 16EE 76ED 24CE";
          }];
        };
        shyim = {
          email = "s.sayakci@gmail.com";
          github = "shyim";
          githubId = 6224096;
          name = "Soner Sayakci";
        };
        siddharthist = {
          email = "langston.barrett@gmail.com";
          github = "langston-barrett";
          githubId = 4294323;
          name = "Langston Barrett";
        };
        sielicki = {
          name = "Nicholas Sielicki";
          email = "nix@opensource.nslick.com";
          github = "sielicki";
          githubId = 4522995;
          matrix = "@sielicki:matrix.org";
        };
        siers = {
          email = "veinbahs+nixpkgs@gmail.com";
          github = "siers";
          githubId = 235147;
          name = "Raitis Veinbahs";
        };
        sifmelcara = {
          email = "ming@culpring.com";
          github = "sifmelcara";
          githubId = 10496191;
          name = "Ming Chuan";
        };
        sigma = {
          email = "yann.hodique@gmail.com";
          github = "sigma";
          githubId = 16090;
          name = "Yann Hodique";
        };
        sikmir = {
          email = "sikmir@disroot.org";
          github = "sikmir";
          githubId = 688044;
          name = "Nikolay Korotkiy";
          keys = [{
            fingerprint = "ADF4 C13D 0E36 1240 BD01  9B51 D1DE 6D7F 6936 63A5";
          }];
        };
        simarra = {
          name = "simarra";
          email = "loic.martel@protonmail.com";
          github = "Simarra";
          githubId = 14372987;
        };
        simoneruffini = {
          email = "simone.ruffini@tutanota.com";
          github = "simoneruffini";
          githubId = 50401154;
          name = "Simone Ruffini";
        };
        simonchatts = {
          email = "code@chatts.net";
          github = "simonchatts";
          githubId = 11135311;
          name = "Simon Chatterjee";
        };
        simonkampe = {
          email = "simon.kampe+nix@gmail.com";
          github = "simonkampe";
          githubId = 254799;
          name = "Simon Kämpe";
        };
        simonvandel = {
          email = "simon.vandel@gmail.com";
          github = "simonvandel";
          githubId = 2770647;
          name = "Simon Vandel Sillesen";
        };
        sir4ur0n = {
          email = "sir4ur0n@users.noreply.github.com";
          github = "sir4ur0n";
          githubId = 1204125;
          name = "sir4ur0n";
        };
        siraben = {
          email = "bensiraphob@gmail.com";
          matrix = "@siraben:matrix.org";
          github = "siraben";
          githubId = 8219659;
          name = "Siraphob Phipathananunth";
        };
        siriobalmelli = {
          email = "sirio@b-ad.ch";
          github = "siriobalmelli";
          githubId = 23038812;
          name = "Sirio Balmelli";
          keys = [{
            fingerprint = "B234 EFD4 2B42 FE81 EE4D  7627 F72C 4A88 7F9A 24CA";
          }];
        };
        sirseruju = {
          email = "sir.seruju@yandex.ru";
          github = "SirSeruju";
          githubId = 74881555;
          name = "Fofanov Sergey";
        };
        sivteck = {
          email = "sivaram1992@gmail.com";
          github = "sivteck";
          githubId = 8017899;
          name = "Sivaram Balakrishnan";
        };
        sjagoe = {
          email = "simon@simonjagoe.com";
          github = "sjagoe";
          githubId = 80012;
          name = "Simon Jagoe";
        };
        sjau = {
          email = "nixos@sjau.ch";
          github = "sjau";
          githubId = 848812;
          name = "Stephan Jau";
        };
        sjfloat = {
          email = "steve+nixpkgs@jonescape.com";
          github = "sjfloat";
          githubId = 216167;
          name = "Steve Jones";
        };
        sjmackenzie = {
          email = "setori88@gmail.com";
          github = "sjmackenzie";
          githubId = 158321;
          name = "Stewart Mackenzie";
        };
        skeidel = {
          email = "svenkeidel@gmail.com";
          github = "svenkeidel";
          githubId = 266500;
          name = "Sven Keidel";
        };
        skykanin = {
          email = "skykanin@users.noreply.github.com";
          github = "skykanin";
          githubId = 3789764;
          name = "skykanin";
        };
        sleexyz = {
          email = "freshdried@gmail.com";
          github = "sleexyz";
          githubId = 1505617;
          name = "Sean Lee";
        };
        SlothOfAnarchy = {
          email = "slothofanarchy1@gmail.com";
          matrix = "@michel.weitbrecht:helsinki-systems.de";
          github = "SlothOfAnarchy";
          githubId = 12828415;
          name = "Michel Weitbrecht";
        };
        smakarov = {
          email = "setser200018@gmail.com";
          github = "SeTSeR";
          githubId = 12733495;
          name = "Sergey Makarov";
          keys = [{
            fingerprint = "6F8A 18AE 4101 103F 3C54  24B9 6AA2 3A11 93B7 064B";
          }];
        };
        smancill = {
          email = "smancill@smancill.dev";
          github = "smancill";
          githubId = 238528;
          name = "Sebastián Mancilla";
        };
        smaret = {
          email = "sebastien.maret@icloud.com";
          github = "smaret";
          githubId = 95471;
          name = "Sébastien Maret";
          keys = [{
            fingerprint = "4242 834C D401 86EF 8281  4093 86E3 0E5A 0F5F C59C";
          }];
        };
        smasher164 = {
          email = "aindurti@gmail.com";
          github = "smasher164";
          githubId = 12636891;
          name = "Akhil Indurti";
        };
        smironov = {
          email = "grrwlf@gmail.com";
          github = "grwlf";
          githubId = 4477729;
          name = "Sergey Mironov";
        };
        smitop = {
          name = "Smitty van Bodegom";
          email = "me@smitop.com";
          matrix = "@smitop:kde.org";
          github = "Smittyvb";
          githubId = 10530973;
        };
        sna = {
          email = "abouzahra.9@wright.edu";
          github = "S-NA";
          githubId = 20214715;
          name = "S. Nordin Abouzahra";
        };
        snaar = {
          email = "snaar@snaar.net";
          github = "snaar";
          githubId = 602439;
          name = "Serguei Narojnyi";
        };
        snapdgn = {
          email = "snapdgn@proton.me";
          name = "Nitish Kumar";
          github = "snapdgn";
          githubId = 85608760;
        };
        snicket2100 = {
          email = "57048005+snicket2100@users.noreply.github.com";
          github = "snicket2100";
          githubId = 57048005;
          name = "snicket2100";
        };
        snyh = {
          email = "snyh@snyh.org";
          github = "snyh";
          githubId = 1437166;
          name = "Xia Bin";
        };
        softinio = {
          email = "code@softinio.com";
          github = "softinio";
          githubId = 3371635;
          name = "Salar Rahmanian";
        };
        sohalt = {
          email = "nixos@sohalt.net";
          github = "Sohalt";
          githubId = 2157287;
          name = "sohalt";
        };
        solson = {
          email = "scott@solson.me";
          matrix = "@solson:matrix.org";
          github = "solson";
          githubId = 26806;
          name = "Scott Olson";
        };
        somasis = {
          email = "kylie@somas.is";
          github = "somasis";
          githubId = 264788;
          name = "Kylie McClain";
        };
        SomeoneSerge = {
          email = "sergei.kozlukov@aalto.fi";
          matrix = "@ss:someonex.net";
          github = "SomeoneSerge";
          githubId = 9720532;
          name = "Sergei K";
        };
        sophrosyne = {
          email = "joshuaortiz@tutanota.com";
          github = "sophrosyne97";
          githubId = 53029739;
          name = "Joshua Ortiz";
        };
        sorki = {
          email = "srk@48.io";
          github = "sorki";
          githubId = 115308;
          name = "Richard Marko";
        };
        sorpaas = {
          email = "hi@that.world";
          github = "sorpaas";
          githubId = 6277322;
          name = "Wei Tang";
        };
        spacefrogg = {
          email = "spacefrogg-nixos@meterriblecrew.net";
          github = "spacefrogg";
          githubId = 167881;
          name = "Michael Raitza";
        };
        spacekookie = {
          email = "kookie@spacekookie.de";
          github = "spacekookie";
          githubId = 7669898;
          name = "Katharina Fey";
        };
        spease = {
          email = "peasteven@gmail.com";
          github = "spease";
          githubId = 2825204;
          name = "Steven Pease";
        };
        spencerjanssen = {
          email = "spencerjanssen@gmail.com";
          matrix = "@sjanssen:matrix.org";
          github = "spencerjanssen";
          githubId = 2600039;
          name = "Spencer Janssen";
        };
        spinus = {
          email = "tomasz.czyz@gmail.com";
          github = "spinus";
          githubId = 950799;
          name = "Tomasz Czyż";
        };
        sprock = {
          email = "rmason@mun.ca";
          github = "sprock";
          githubId = 6391601;
          name = "Roger Mason";
        };
        spwhitt = {
          email = "sw@swhitt.me";
          github = "spwhitt";
          githubId = 1414088;
          name = "Spencer Whitt";
        };
        squalus = {
          email = "squalus@squalus.net";
          github = "squalus";
          githubId = 36899624;
          name = "squalus";
        };
        squarepear = {
          email = "contact@jeffreyharmon.dev";
          github = "SquarePear";
          githubId = 16364318;
          name = "Jeffrey Harmon";
        };
        srapenne = {
          email = "solene@perso.pw";
          github = "rapenne-s";
          githubId = 248016;
          name = "Solène Rapenne";
        };
        srghma = {
          email = "srghma@gmail.com";
          github = "srghma";
          githubId = 7573215;
          name = "Sergei Khoma";
        };
        srgom = {
          email = "srgom@users.noreply.github.com";
          github = "SRGOM";
          githubId = 8103619;
          name = "SRGOM";
        };
        srhb = {
          email = "sbrofeldt@gmail.com";
          matrix = "@srhb:matrix.org";
          github = "srhb";
          githubId = 219362;
          name = "Sarah Brofeldt";
        };
        SShrike = {
          email = "severen@shrike.me";
          github = "severen";
          githubId = 4061736;
          name = "Severen Redwood";
        };
        sstef = {
          email = "stephane@nix.frozenid.net";
          github = "haskelious";
          githubId = 8668915;
          name = "Stephane Schitter";
        };
        staccato = {
          name = "staccato";
          email = "moveq@riseup.net";
          github = "braaandon";
          githubId = 86573128;
        };
        stackshadow = {
          email = "stackshadow@evilbrain.de";
          github = "stackshadow";
          githubId = 7512804;
          name = "Martin Langlotz";
        };
        stargate01 = {
          email = "christoph.honal@web.de";
          github = "StarGate01";
          githubId = 6362238;
          name = "Christoph Honal";
        };
        stasjok = {
          name = "Stanislav Asunkin";
          email = "nixpkgs@stasjok.ru";
          github = "stasjok";
          githubId = 1353637;
        };
        steamwalker = {
          email = "steamwalker@xs4all.nl";
          github = "steamwalker";
          githubId = 94006354;
          name = "steamwalker";
        };
        steell = {
          email = "steve@steellworks.com";
          github = "Steell";
          githubId = 1699155;
          name = "Steve Elliott";
        };
        stehessel = {
          email = "stephan@stehessel.de";
          github = "stehessel";
          githubId = 55607356;
          name = "Stephan Heßelmann";
        };
        steinybot = {
          name = "Jason Pickens";
          email = "jasonpickensnz@gmail.com";
          matrix = "@steinybot:matrix.org";
          github = "steinybot";
          githubId = 4659562;
          keys = [{
            fingerprint = "2709 1DEC CC42 4635 4299  569C 21DE 1CAE 5976 2A0F";
          }];
        };
        stelcodes = {
          email = "stel@stel.codes";
          github = "stelcodes";
          githubId = 22163194;
          name = "Stel Abrego";
        };
        stephank = {
          email = "nix@stephank.nl";
          matrix = "@skochen:matrix.org";
          github = "stephank";
          githubId = 89950;
          name = "Stéphan Kochen";
        };
        stephenmw = {
          email = "stephen@q5comm.com";
          github = "stephenmw";
          githubId = 231788;
          name = "Stephen Weinberg";
        };
        stephenwithph = {
          name = "StephenWithPH";
          email = "StephenWithPH@users.noreply.github.com";
          github = "StephenWithPH";
          githubId = 2990492;
        };
        sterfield = {
          email = "sterfield@gmail.com";
          github = "sterfield";
          githubId = 5747061;
          name = "Guillaume Loetscher";
        };
        sternenseemann = {
          email = "sternenseemann@systemli.org";
          github = "sternenseemann";
          githubId = 3154475;
          name = "Lukas Epple";
        };
        steshaw = {
          name = "Steven Shaw";
          email = "steven@steshaw.org";
          github = "steshaw";
          githubId = 45735;
          keys = [{
            fingerprint = "0AFE 77F7 474D 1596 EE55  7A29 1D9A 17DF D23D CB91";
          }];
        };
        stesie = {
          email = "stesie@brokenpipe.de";
          github = "stesie";
          githubId = 113068;
          name = "Stefan Siegl";
        };
        steve-chavez = {
          email = "stevechavezast@gmail.com";
          github = "steve-chavez";
          githubId = 1829294;
          name = "Steve Chávez";
        };
        stevebob = {
          email = "stephen@sherra.tt";
          github = "gridbugs";
          githubId = 417118;
          name = "Stephen Sherratt";
        };
        steveej = {
          email = "mail@stefanjunker.de";
          github = "steveeJ";
          githubId = 1181362;
          name = "Stefan Junker";
        };
        stevenroose = {
          email = "github@stevenroose.org";
          github = "stevenroose";
          githubId = 853468;
          name = "Steven Roose";
        };
        stianlagstad = {
          email = "stianlagstad@gmail.com";
          github = "stianlagstad";
          githubId = 4340859;
          name = "Stian Lågstad";
        };
        StijnDW = {
          email = "nixdev@rinsa.eu";
          github = "Stekke";
          githubId = 1751956;
          name = "Stijn DW";
        };
        StillerHarpo = {
          email = "florianengel39@gmail.com";
          github = "StillerHarpo";
          githubId = 25526706;
          name = "Florian Engel";
        };
        stites = {
          email = "sam@stites.io";
          github = "stites";
          githubId = 1694705;
          name = "Sam Stites";
        };
        strager = {
          email = "strager.nds@gmail.com";
          github = "strager";
          githubId = 48666;
          name = "Matthew \"strager\" Glazar";
        };
        strikerlulu = {
          email = "strikerlulu7@gmail.com";
          github = "strikerlulu";
          githubId = 38893265;
          name = "StrikerLulu";
        };
        stumoss = {
          email = "samoss@gmail.com";
          github = "stumoss";
          githubId = 638763;
          name = "Stuart Moss";
        };
        stunkymonkey = {
          email = "account@buehler.rocks";
          github = "Stunkymonkey";
          githubId = 1315818;
          name = "Felix Bühler";
        };
        stupremee = {
          email = "jutus.k@protonmail.com";
          github = "Stupremee";
          githubId = 39732259;
          name = "Justus K";
        };
        SubhrajyotiSen = {
          email = "subhrajyoti12@gmail.com";
          github = "SubhrajyotiSen";
          githubId = 12984845;
          name = "Subhrajyoti Sen";
        };
        sudosubin = {
          email = "sudosubin@gmail.com";
          github = "sudosubin";
          githubId = 32478597;
          name = "Subin Kim";
        };
        suhr = {
          email = "suhr@i2pmail.org";
          github = "suhr";
          githubId = 65870;
          name = "Сухарик";
        };
        sumnerevans = {
          email = "me@sumnerevans.com";
          github = "sumnerevans";
          githubId = 16734772;
          name = "Sumner Evans";
        };
        suominen = {
          email = "kimmo@suominen.com";
          github = "suominen";
          githubId = 1939855;
          name = "Kimmo Suominen";
        };
        superbo = {
          email = "supernbo@gmail.com";
          github = "SuperBo";
          githubId = 2666479;
          name = "Y Nguyen";
        };
        SuperSandro2000 = {
          email = "sandro.jaeckel@gmail.com";
          matrix = "@sandro:supersandro.de";
          github = "SuperSandro2000";
          githubId = 7258858;
          name = "Sandro Jäckel";
        };
        SuprDewd = {
          email = "suprdewd@gmail.com";
          github = "SuprDewd";
          githubId = 187109;
          name = "Bjarki Ágúst Guðmundsson";
        };
        suryasr007 = {
          email = "94suryateja@gmail.com";
          github = "suryasr007";
          githubId = 10533926;
          name = "Surya Teja V";
        };
        suvash = {
          email = "suvash+nixpkgs@gmail.com";
          github = "suvash";
          githubId = 144952;
          name = "Suvash Thapaliya";
        };
        sveitser = {
          email = "sveitser@gmail.com";
          github = "sveitser";
          githubId = 1040871;
          name = "Mathis Antony";
        };
        sven-of-cord = {
          email = "sven@cord.com";
          github = "sven-of-cord";
          githubId = 98333944;
          name = "Sven Over";
        };
        svend = {
          email = "svend@svends.net";
          github = "svend";
          githubId = 306190;
          name = "Svend Sorensen";
        };
        svrana = {
          email = "shaw@vranix.com";
          github = "svrana";
          githubId = 850665;
          name = "Shaw Vrana";
        };
        svsdep = {
          email = "svsdep@gmail.com";
          github = "svsdep";
          githubId = 36695359;
          name = "Vasyl Solovei";
        };
        swarren83 = {
          email = "shawn.w.warren@gmail.com";
          github = "swarren83";
          githubId = 4572854;
          name = "Shawn Warren";
        };
        swdunlop = {
          email = "swdunlop@gmail.com";
          github = "swdunlop";
          githubId = 120188;
          name = "Scott W. Dunlop";
        };
        sweber = {
          email = "sweber2342+nixpkgs@gmail.com";
          github = "sweber83";
          githubId = 19905904;
          name = "Simon Weber";
        };
        sweenu = {
          name = "sweenu";
          email = "contact@sweenu.xyz";
          github = "sweenu";
          githubId = 7051978;
        };
        swflint = {
          email = "swflint@flintfam.org";
          github = "swflint";
          githubId = 1771109;
          name = "Samuel W. Flint";
        };
        swistak35 = {
          email = "me@swistak35.com";
          github = "swistak35";
          githubId = 332289;
          name = "Rafał Łasocha";
        };
        syberant = {
          email = "sybrand@neuralcoding.com";
          github = "syberant";
          githubId = 20063502;
          name = "Sybrand Aarnoutse";
        };
        symphorien = {
          email = "symphorien_nixpkgs@xlumurb.eu";
          matrix = "@symphorien:xlumurb.eu";
          github = "symphorien";
          githubId = 12595971;
          name = "Guillaume Girol";
        };
        synthetica = {
          email = "nix@hilhorst.be";
          github = "Synthetica9";
          githubId = 7075751;
          name = "Patrick Hilhorst";
        };
        szczyp = {
          email = "qb@szczyp.com";
          github = "Szczyp";
          githubId = 203195;
          name = "Szczyp";
        };
        szlend = {
          email = "pub.nix@zlender.si";
          github = "szlend";
          githubId = 7301807;
          name = "Simon Žlender";
        };
        sztupi = {
          email = "attila.sztupak@gmail.com";
          github = "sztupi";
          githubId = 143103;
          name = "Attila Sztupak";
        };
        t184256 = {
          email = "monk@unboiled.info";
          github = "t184256";
          githubId = 5991987;
          name = "Alexander Sosedkin";
        };
        tadeokondrak = {
          email = "me@tadeo.ca";
          github = "tadeokondrak";
          githubId = 4098453;
          name = "Tadeo Kondrak";
          keys = [{
            fingerprint = "0F2B C0C7 E77C 5B42 AC5B  4C18 FBE6 07FC C495 16D3";
          }];
        };
        tadfisher = {
          email = "tadfisher@gmail.com";
          github = "tadfisher";
          githubId = 129148;
          name = "Tad Fisher";
        };
        taeer = {
          email = "taeer@necsi.edu";
          github = "Radvendii";
          githubId = 1239929;
          name = "Taeer Bar-Yam";
        };
        taha = {
          email = "xrcrod@gmail.com";
          github = "tgharib";
          githubId = 6457015;
          name = "Taha Gharib";
        };
        tailhook = {
          email = "paul@colomiets.name";
          github = "tailhook";
          githubId = 321799;
          name = "Paul Colomiets";
        };
        taikx4 = {
          email = "taikx4@taikx4szlaj2rsdupcwabg35inbny4jk322ngeb7qwbbhd5i55nf5yyd.onion";
          github = "taikx4";
          githubId = 94917129;
          name = "taikx4";
          keys = [{
            fingerprint = "6B02 8103 C4E5 F68C D77C  9E54 CCD5 2C7B 37BB 837E";
          }];
        };
        takagiy = {
          email = "takagiy.4dev@gmail.com";
          github = "takagiy";
          githubId = 18656090;
          name = "Yuki Takagi";
        };
        taketwo = {
          email = "alexandrov88@gmail.com";
          github = "taketwo";
          githubId = 1241736;
          name = "Sergey Alexandrov";
        };
        takikawa = {
          email = "asumu@igalia.com";
          github = "takikawa";
          githubId = 64192;
          name = "Asumu Takikawa";
        };
        taktoa = {
          email = "taktoa@gmail.com";
          matrix = "@taktoa:matrix.org";
          github = "taktoa";
          githubId = 553443;
          name = "Remy Goldschmidt";
        };
        taku0 = {
          email = "mxxouy6x3m_github@tatapa.org";
          github = "taku0";
          githubId = 870673;
          name = "Takuo Yonezawa";
        };
        talkara = {
          email = "taito.horiuchi@relexsolutions.com";
          github = "talkara";
          githubId = 51232929;
          name = "Taito Horiuchi";
        };
        talyz = {
          email = "kim.lindberger@gmail.com";
          matrix = "@talyz:matrix.org";
          github = "talyz";
          githubId = 63433;
          name = "Kim Lindberger";
        };
        taneb = {
          email = "nvd1234@gmail.com";
          github = "Taneb";
          githubId = 1901799;
          name = "Nathan van Doorn";
        };
        tari = {
          email = "peter@taricorp.net";
          github = "tari";
          githubId = 506181;
          name = "Peter Marheine";
        };
        tasmo = {
          email = "tasmo@tasmo.de";
          github = "tasmo";
          githubId = 102685;
          name = "Thomas Friese";
        };
        taylor1791 = {
          email = "nixpkgs@tayloreverding.com";
          github = "taylor1791";
          githubId = 555003;
          name = "Taylor Everding";
        };
        tazjin = {
          email = "mail@tazj.in";
          github = "tazjin";
          githubId = 1552853;
          name = "Vincent Ambo";
        };
        tbenst = {
          email = "nix@tylerbenster.com";
          github = "tbenst";
          githubId = 863327;
          name = "Tyler Benster";
        };
        tboerger = {
          email = "thomas@webhippie.de";
          matrix = "@tboerger:matrix.org";
          github = "tboerger";
          githubId = 156964;
          name = "Thomas Boerger";
        };
        tcbravo = {
          email = "tomas.bravo@protonmail.ch";
          github = "tcbravo";
          githubId = 66133083;
          name = "Tomas Bravo";
        };
        tchab = {
          email = "dev@chabs.name";
          github = "t-chab";
          githubId = 2120966;
          name = "t-chab";
        };
        tchekda = {
          email = "contact@tchekda.fr";
          github = "Tchekda";
          githubId = 23559888;
          keys = [{
            fingerprint = "44CE A8DD 3B31 49CD 6246  9D8F D0A0 07ED A4EA DA0F";
          }];
          name = "David Tchekachev";
        };
        tckmn = {
          email = "andy@tck.mn";
          github = "tckmn";
          githubId = 2389333;
          name = "Andy Tockman";
        };
        techknowlogick = {
          email = "techknowlogick@gitea.io";
          github = "techknowlogick";
          githubId = 164197;
          name = "techknowlogick";
        };
        Technical27 = {
          email = "38222826+Technical27@users.noreply.github.com";
          github = "Technical27";
          githubId = 38222826;
          name = "Aamaruvi Yogamani";
        };
        teh = {
          email = "tehunger@gmail.com";
          github = "teh";
          githubId = 139251;
          name = "Tom Hunger";
        };
        tejasag = {
          name = "Tejas Agarwal";
          email = "tejasagarwalbly@gmail.com";
          github = "tejasag";
          githubId = 67542663;
        };
        tejing = {
          name = "Jeff Huffman";
          email = "tejing@tejing.com";
          matrix = "@tejing:matrix.org";
          github = "tejing1";
          githubId = 5663576;
          keys = [{ fingerprint = "6F0F D43B 80E5 583E 60FC  51DC 4936 D067 EB12 AB32"; }];
        };
        telotortium = {
          email = "rirelan@gmail.com";
          github = "telotortium";
          githubId = 1755789;
          name = "Robert Irelan";
        };
        teozkr = {
          email = "teo@nullable.se";
          github = "teozkr";
          githubId = 649832;
          name = "Teo Klestrup Röijezon";
        };
        terin = {
          email = "terinjokes@gmail.com";
          github = "terinjokes";
          githubId = 273509;
          name = "Terin Stock";
        };
        terlar = {
          email = "terlar@gmail.com";
          github = "terlar";
          githubId = 280235;
          name = "Terje Larsen";
        };
        terrorjack = {
          email = "astrohavoc@gmail.com";
          github = "TerrorJack";
          githubId = 3889585;
          name = "Cheng Shao";
        };
        tesq0 = {
          email = "mikolaj.galkowski@gmail.com";
          github = "tesq0";
          githubId = 26417242;
          name = "Mikolaj Galkowski";
        };
        TethysSvensson = {
          email = "freaken@freaken.dk";
          github = "TethysSvensson";
          githubId = 4294434;
          name = "Tethys Svensson";
        };
        teto = {
          email = "mcoudron@hotmail.com";
          github = "teto";
          githubId = 886074;
          name = "Matthieu Coudron";
        };
        teutat3s = {
          email = "teutates@mailbox.org";
          matrix = "@teutat3s:pub.solar";
          github = "teutat3s";
          githubId = 10206665;
          name = "teutat3s";
          keys = [{
            fingerprint = "81A1 1C61 F413 8C84 9139  A4FA 18DA E600 A6BB E705";
          }];
        };
        tex = {
          email = "milan.svoboda@centrum.cz";
          github = "tex";
          githubId = 27386;
          name = "Milan Svoboda";
        };
        tfc = {
          email = "jacek@galowicz.de";
          matrix = "@jonge:ukvly.org";
          github = "tfc";
          githubId = 29044;
          name = "Jacek Galowicz";
        };
        tg-x = {
          email = "*@tg-x.net";
          github = "tg-x";
          githubId = 378734;
          name = "TG ⊗ Θ";
        };
        tgunnoe = {
          email = "t@gvno.net";
          github = "tgunnoe";
          githubId = 7254833;
          name = "Taylor Gunnoe";
        };
        th0rgal = {
          email = "thomas.marchand@tuta.io";
          github = "Th0rgal";
          githubId = 41830259;
          name = "Thomas Marchand";
        };
        thall = {
          email = "niclas.thall@gmail.com";
          github = "thall";
          githubId = 102452;
          name = "Niclas Thall";
        };
        thammers = {
          email = "jawr@gmx.de";
          github = "tobias-hammerschmidt";
          githubId = 2543259;
          name = "Tobias Hammerschmidt";
        };
        thanegill = {
          email = "me@thanegill.com";
          github = "thanegill";
          githubId = 1141680;
          name = "Thane Gill";
        };
        thblt = {
          name = "Thibault Polge";
          email = "thibault@thb.lt";
          matrix = "@thbltp:matrix.org";
          github = "thblt";
          githubId = 2453136;
          keys = [{
            fingerprint = "D2A2 F0A1 E7A8 5E6F B711  DEE5 63A4 4817 A52E AB7B";
          }];
        };
        TheBrainScrambler = {
          email = "esthromeris@riseup.net";
          github = "TheBrainScrambler";
          githubId = 34945377;
          name = "John Smith";
        };
        thedavidmeister = {
          email = "thedavidmeister@gmail.com";
          github = "thedavidmeister";
          githubId = 629710;
          name = "David Meister";
        };
        thefloweringash = {
          email = "lorne@cons.org.nz";
          github = "thefloweringash";
          githubId = 42933;
          name = "Andrew Childs";
        };
        thefenriswolf = {
          email = "stefan.rohrbacher97@gmail.com";
          github = "thefenriswolf";
          githubId = 8547242;
          name = "Stefan Rohrbacher";
        };
        thehedgeh0g = {
          name = "The Hedgehog";
          email = "hedgehog@mrhedgehog.xyz";
          matrix = "@mrhedgehog:jupiterbroadcasting.com";
          github = "theHedgehog0";
          githubId = 35778371;
          keys = [{
            fingerprint = "38A0 29B0 4A7E 4C13 A4BB  86C8 7D51 0786 6B1C 6752";
          }];
        };
        thelegy = {
          email = "mail+nixos@0jb.de";
          github = "thelegy";
          githubId = 3105057;
          name = "Jan Beinke";
        };
        thenonameguy = {
          email = "thenonameguy24@gmail.com";
          name = "Krisztian Szabo";
          github = "thenonameguy";
          githubId = 2217181;
        };
        therealansh = {
          email = "tyagiansh23@gmail.com";
          github = "therealansh";
          githubId = 57180880;
          name = "Ansh Tyagi";
        };
        therishidesai = {
          email = "desai.rishi1@gmail.com";
          github = "therishidesai";
          githubId = 5409166;
          name = "Rishi Desai";
        };
        thesola10 = {
          email = "me@thesola.io";
          github = "Thesola10";
          githubId = 7287268;
          keys = [{
            fingerprint = "1D05 13A6 1AC4 0D8D C6D6  5F2C 8924 5619 BEBB 95BA";
          }];
          name = "Karim Vergnes";
        };
        thetallestjj = {
          email = "me+nixpkgs@jeroen-jetten.com";
          github = "TheTallestJJ";
          githubId = 6579555;
          name = "Jeroen Jetten";
        };
        theuni = {
          email = "ct@flyingcircus.io";
          github = "ctheune";
          githubId = 1220572;
          name = "Christian Theune";
        };
        thiagokokada = {
          email = "thiagokokada@gmail.com";
          github = "thiagokokada";
          githubId = 844343;
          name = "Thiago K. Okada";
          matrix = "@k0kada:matrix.org";
        };
        thibaultlemaire = {
          email = "thibault.lemaire@protonmail.com";
          github = "ThibaultLemaire";
          githubId = 21345269;
          name = "Thibault Lemaire";
        };
        thibautmarty = {
          email = "github@thibautmarty.fr";
          matrix = "@thibaut:thibautmarty.fr";
          github = "ThibautMarty";
          githubId = 3268082;
          name = "Thibaut Marty";
        };
        thyol = {
          name = "thyol";
          email = "thyol@pm.me";
          github = "thyol";
          githubId = 81481634;
        };
        thmzlt = {
          email = "git@thomazleite.com";
          github = "thmzlt";
          githubId = 7709;
          name = "Thomaz Leite";
        };
        thomasdesr = {
          email = "git@hive.pw";
          github = "thomasdesr";
          githubId = 681004;
          name = "Thomas Desrosiers";
        };
        ThomasMader = {
          email = "thomas.mader@gmail.com";
          github = "ThomasMader";
          githubId = 678511;
          name = "Thomas Mader";
        };
        thomasjm = {
          email = "tom@codedown.io";
          github = "thomasjm";
          githubId = 1634990;
          name = "Tom McLaughlin";
        };
        thoughtpolice = {
          email = "aseipp@pobox.com";
          github = "thoughtpolice";
          githubId = 3416;
          name = "Austin Seipp";
        };
        thpham = {
          email = "thomas.pham@ithings.ch";
          github = "thpham";
          githubId = 224674;
          name = "Thomas Pham";
        };
        Thra11 = {
          email = "tahall256@protonmail.ch";
          github = "Thra11";
          githubId = 1391883;
          name = "Tom Hall";
        };
        Thunderbottom = {
          email = "chinmaydpai@gmail.com";
          github = "Thunderbottom";
          githubId = 11243138;
          name = "Chinmay D. Pai";
          keys = [{
            fingerprint = "7F3E EEAA EE66 93CC 8782  042A 7550 7BE2 56F4 0CED";
          }];
        };
        tiagolobocastro = {
          email = "tiagolobocastro@gmail.com";
          github = "tiagolobocastro";
          githubId = 1618946;
          name = "Tiago Castro";
        };
        tilcreator = {
          name = "TilCreator";
          email = "contact.nixos@tc-j.de";
          matrix = "@tilcreator:matrix.org";
          github = "TilCreator";
          githubId = 18621411;
        };
        tilpner = {
          email = "till@hoeppner.ws";
          github = "tilpner";
          githubId = 4322055;
          name = "Till Höppner";
        };
        timbertson = {
          email = "tim@gfxmonk.net";
          github = "timbertson";
          githubId = 14172;
          name = "Tim Cuthbertson";
        };
        timma = {
          email = "kunduru.it.iitb@gmail.com";
          github = "ktrsoft";
          githubId = 12712927;
          name = "Timma";
        };
        timokau = {
          email = "timokau@zoho.com";
          github = "timokau";
          githubId = 3799330;
          name = "Timo Kaufmann";
        };
        timor = {
          email = "timor.dd@googlemail.com";
          github = "timor";
          githubId = 174156;
          name = "timor";
        };
        timput = {
          email = "tim@timput.com";
          github = "TimPut";
          githubId = 2845239;
          name = "Tim Put";
        };
        timstott = {
          email = "stott.timothy@gmail.com";
          github = "timstott";
          githubId = 1334474;
          name = "Timothy Stott";
        };
        tiramiseb = {
          email = "sebastien@maccagnoni.eu";
          github = "tiramiseb";
          githubId = 1292007;
          name = "Sébastien Maccagnoni";
        };
        tirex = {
          email = "szymon@kliniewski.pl";
          name = "Szymon Kliniewski";
          github = "NoneTirex";
          githubId = 26038207;
        };
        titanous = {
          email = "jonathan@titanous.com";
          github = "titanous";
          githubId = 13026;
          name = "Jonathan Rudenberg";
        };
        tkerber = {
          email = "tk@drwx.org";
          github = "tkerber";
          githubId = 5722198;
          name = "Thomas Kerber";
          keys = [{
            fingerprint = "556A 403F B0A2 D423 F656  3424 8489 B911 F9ED 617B";
          }];
        };
        tljuniper = {
          email = "tljuniper1@gmail.com";
          github = "tljuniper";
          githubId = 48209000;
          name = "Anna Gillert";
        };
        tmarkovski = {
          email = "tmarkovski@gmail.com";
          github = "tmarkovski";
          githubId = 1280118;
          name = "Tomislav Markovski";
        };
        tmountain = {
          email = "tinymountain@gmail.com";
          github = "tmountain";
          githubId = 135297;
          name = "Travis Whitton";
        };
        tmplt = {
          email = "tmplt@dragons.rocks";
          github = "tmplt";
          githubId = 6118602;
          name = "Viktor";
        };
        tnias = {
          email = "phil@grmr.de";
          matrix = "@tnias:stratum0.org";
          github = "tnias";
          githubId = 9853194;
          name = "Philipp Bartsch";
        };
        toastal = {
          email = "toastal+nix@posteo.net";
          matrix = "@toastal:matrix.org";
          github = "toastal";
          githubId = 561087;
          name = "toastal";
          keys = [{
            fingerprint = "7944 74B7 D236 DAB9 C9EF  E7F9 5CCE 6F14 66D4 7C9E";
          }];
        };
        tobim = {
          email = "nix@tobim.fastmail.fm";
          github = "tobim";
          githubId = 858790;
          name = "Tobias Mayer";
        };
        tobiasBora = {
          email = "tobias.bora.list@gmail.com";
          github = "tobiasBora";
          githubId = 2164118;
          name = "Tobias Bora";
        };
        tokudan = {
          email = "git@danielfrank.net";
          github = "tokudan";
          githubId = 692610;
          name = "Daniel Frank";
        };
        tomahna = {
          email = "kevin.rauscher@tomahna.fr";
          github = "Tomahna";
          githubId = 8577941;
          name = "Kevin Rauscher";
        };
        tomberek = {
          email = "tomberek@gmail.com";
          matrix = "@tomberek:matrix.org";
          github = "tomberek";
          githubId = 178444;
          name = "Thomas Bereknyei";
        };
        tomfitzhenry = {
          email = "tom@tom-fitzhenry.me.uk";
          github = "tomfitzhenry";
          githubId = 61303;
          name = "Tom Fitzhenry";
        };
        tomhoule = {
          email = "secondary+nixpkgs@tomhoule.com";
          github = "tomhoule";
          githubId = 13155277;
          name = "Tom Houle";
        };
        tomodachi94 = {
          email = "tomodachi94+nixpkgs@protonmail.com";
          matrix = "@tomodachi94:matrix.org";
          github = "tomodachi94";
          githubId = 68489118;
          name = "Tomodachi94";
        };
        tomsmeets = {
          email = "tom.tsmeets@gmail.com";
          github = "TomSmeets";
          githubId = 6740669;
          name = "Tom Smeets";
        };
        tomsiewert = {
          email = "tom@siewert.io";
          matrix = "@tom:frickel.earth";
          github = "tomsiewert";
          githubId = 8794235;
          name = "Tom Siewert";
        };
        tonyshkurenko = {
          email = "support@twingate.com";
          github = "tonyshkurenko";
          githubId = 8597964;
          name = "Anton Shkurenko";
        };
        toonn = {
          email = "nixpkgs@toonn.io";
          matrix = "@toonn:matrix.org";
          github = "toonn";
          githubId = 1486805;
          name = "Toon Nolten";
        };
        toschmidt = {
          email = "tobias.schmidt@in.tum.de";
          github = "toschmidt";
          githubId = 27586264;
          name = "Tobias Schmidt";
        };
        totoroot = {
          name = "Matthias Thym";
          email = "git@thym.at";
          github = "totoroot";
          githubId = 39650930;
        };
        ToxicFrog = {
          email = "toxicfrog@ancilla.ca";
          github = "ToxicFrog";
          githubId = 90456;
          name = "Rebecca (Bex) Kelly";
        };
        tpw_rules = {
          name = "Thomas Watson";
          email = "twatson52@icloud.com";
          matrix = "@tpw_rules:matrix.org";
          github = "tpwrules";
          githubId = 208010;
        };
        travisbhartwell = {
          email = "nafai@travishartwell.net";
          github = "travisbhartwell";
          githubId = 10110;
          name = "Travis B. Hartwell";
        };
        travisdavis-ops = {
          email = "travisdavismedia@gmail.com";
          github = "TravisDavis-ops";
          githubId = 52011418;
          name = "Travis Davis";
        };
        traxys = {
          email = "quentin+dev@familleboyer.net";
          github = "traxys";
          githubId = 5623227;
          name = "Quentin Boyer";
        };
        TredwellGit = {
          email = "tredwell@tutanota.com";
          github = "TredwellGit";
          githubId = 61860346;
          name = "Tredwell";
        };
        treemo = {
          email = "matthieu.chevrier@treemo.fr";
          github = "treemo";
          githubId = 207457;
          name = "Matthieu Chevrier";
        };
        trepetti = {
          email = "trepetti@cs.columbia.edu";
          github = "trepetti";
          githubId = 25440339;
          name = "Tom Repetti";
        };
        trevorj = {
          email = "nix@trevor.joynson.io";
          github = "akatrevorjay";
          githubId = 1312290;
          name = "Trevor Joynson";
        };
        tricktron = {
          email = "tgagnaux@gmail.com";
          github = "tricktron";
          githubId = 16036882;
          name = "Thibault Gagnaux";
        };
        trino = {
          email = "muehlhans.hubert@ekodia.de";
          github = "hmuehlhans";
          githubId = 9870613;
          name = "Hubert Mühlhans";
        };
        trobert = {
          email = "thibaut.robert@gmail.com";
          github = "trobert";
          githubId = 504580;
          name = "Thibaut Robert";
        };
        troydm = {
          email = "d.geurkov@gmail.com";
          github = "troydm";
          githubId = 483735;
          name = "Dmitry Geurkov";
        };
        truh = {
          email = "jakob-nixos@truh.in";
          github = "truh";
          githubId = 1183303;
          name = "Jakob Klepp";
        };
        trundle = {
          name = "Andreas Stührk";
          email = "andy@hammerhartes.de";
          github = "Trundle";
          githubId = 332418;
        };
        tscholak = {
          email = "torsten.scholak@googlemail.com";
          github = "tscholak";
          githubId = 1568873;
          name = "Torsten Scholak";
        };
        tshaynik = {
          email = "tshaynik@protonmail.com";
          github = "tshaynik";
          githubId = 15064765;
          name = "tshaynik";
        };
        ttuegel = {
          email = "ttuegel@mailbox.org";
          github = "ttuegel";
          githubId = 563054;
          name = "Thomas Tuegel";
        };
        turion = {
          email = "programming@manuelbaerenz.de";
          github = "turion";
          githubId = 303489;
          name = "Manuel Bärenz";
        };
        tu-maurice = {
          email = "valentin.gehrke+nixpkgs@zom.bi";
          github = "tu-maurice";
          githubId = 16151097;
          name = "Valentin Gehrke";
        };
        tuxinaut = {
          email = "trash4you@tuxinaut.de";
          github = "tuxinaut";
          githubId = 722482;
          name = "Denny Schäfer";
          keys = [{
            fingerprint = "C752 0E49 4D92 1740 D263  C467 B057 455D 1E56 7270";
          }];
        };
        tv = {
          email = "tv@krebsco.de";
          github = "4z3";
          githubId = 427872;
          name = "Tomislav Viljetić";
        };
        tvestelind = {
          email = "tomas.vestelind@fripost.org";
          github = "tvestelind";
          githubId = 699403;
          name = "Tomas Vestelind";
        };
        tviti = {
          email = "tviti@hawaii.edu";
          github = "tviti";
          githubId = 2251912;
          name = "Taylor Viti";
        };
        tvorog = {
          email = "marszaripov@gmail.com";
          github = "TvoroG";
          githubId = 1325161;
          name = "Marsel Zaripov";
        };
        tweber = {
          email = "tw+nixpkgs@360vier.de";
          github = "thorstenweber83";
          githubId = 9413924;
          name = "Thorsten Weber";
        };
        twey = {
          email = "twey@twey.co.uk";
          github = "Twey";
          githubId = 101639;
          name = "James ‘Twey’ Kay";
        };
        twhitehead = {
          name = "Tyson Whitehead";
          email = "twhitehead@gmail.com";
          github = "twhitehead";
          githubId = 787843;
          keys = [{
            fingerprint = "E631 8869 586F 99B4 F6E6  D785 5942 58F0 389D 2802";
          }];
        };
        twitchyliquid64 = {
          name = "Tom";
          email = "twitchyliquid64@ciphersink.net";
          github = "twitchyliquid64";
          githubId = 6328589;
        };
        tylerjl = {
          email = "tyler+nixpkgs@langlois.to";
          github = "tylerjl";
          githubId = 1733846;
          matrix = "@ty:tjll.net";
          name = "Tyler Langlois";
        };
        typetetris = {
          email = "ericwolf42@mail.com";
          github = "typetetris";
          githubId = 1983821;
          name = "Eric Wolf";
        };
        uakci = {
          name = "uakci";
          email = "uakci@uakci.pl";
          github = "uakci";
          githubId = 6961268;
        };
        udono = {
          email = "udono@virtual-things.biz";
          github = "udono";
          githubId = 347983;
          name = "Udo Spallek";
        };
        ulrikstrid = {
          email = "ulrik.strid@outlook.com";
          github = "ulrikstrid";
          githubId = 1607770;
          name = "Ulrik Strid";
        };
        unclechu = {
          name = "Viacheslav Lotsmanov";
          email = "lotsmanov89@gmail.com";
          github = "unclechu";
          githubId = 799353;
          keys = [{
            fingerprint = "EE59 5E29 BB5B F2B3 5ED2  3F1C D276 FF74 6700 7335";
          }];
        };
        unhammer = {
          email = "unhammer@fsfe.org";
          github = "unhammer";
          githubId = 56868;
          name = "Kevin Brubeck Unhammer";
          keys = [{
            fingerprint = "50D4 8796 0B86 3F05 4B6A  12F9 7426 06DE 766A C60C";
          }];
        };
        uniquepointer = {
          email = "uniquepointer@mailbox.org";
          matrix = "@uniquepointer:matrix.org";
          github = "uniquepointer";
          githubId = 71751817;
          name = "uniquepointer";
        };
        unode = {
          email = "alves.rjc@gmail.com";
          matrix = "@renato_alves:matrix.org";
          github = "unode";
          githubId = 122319;
          name = "Renato Alves";
        };
        unrooted = {
          name = "Konrad Klawikowski";
          email = "konrad.root.klawikowski@gmail.com";
          github = "unrooted";
          githubId = 30440603;
        };
        uralbash = {
          email = "root@uralbash.ru";
          github = "uralbash";
          githubId = 619015;
          name = "Svintsov Dmitry";
        };
        urandom = {
          email = "colin@urandom.co.uk";
          matrix = "@urandom0:matrix.org";
          github = "urandom2";
          githubId = 2526260;
          keys = [{
            fingerprint = "04A3 A2C6 0042 784A AEA7  D051 0447 A663 F7F3 E236";
          }];
          name = "Colin Arnott";
        };
        urbas = {
          email = "matej.urbas@gmail.com";
          github = "urbas";
          githubId = 771193;
          name = "Matej Urbas";
        };
        uri-canva = {
          email = "uri@canva.com";
          github = "uri-canva";
          githubId = 33242106;
          name = "Uri Baghin";
        };
        urlordjames = {
          email = "urlordjames@gmail.com";
          github = "urlordjames";
          githubId = 32751441;
          name = "urlordjames";
        };
        ursi = {
          email = "masondeanm@aol.com";
          github = "ursi";
          githubId = 17836748;
          name = "Mason Mackaman";
        };
        uskudnik = {
          email = "urban.skudnik@gmail.com";
          github = "uskudnik";
          githubId = 120451;
          name = "Urban Skudnik";
        };
        usrfriendly = {
          name = "Arin Lares";
          email = "arinlares@gmail.com";
          github = "usrfriendly";
          githubId = 2502060;
        };
        utdemir = {
          email = "me@utdemir.com";
          github = "utdemir";
          githubId = 928084;
          name = "Utku Demir";
        };
        uthar = {
          email = "galkowskikasper@gmail.com";
          github = "uthar";
          githubId = 15697697;
          name = "Kasper Gałkowski";
        };
        uvnikita = {
          email = "uv.nikita@gmail.com";
          github = "uvNikita";
          githubId = 1084748;
          name = "Nikita Uvarov";
        };
        uwap = {
          email = "me@uwap.name";
          github = "uwap";
          githubId = 2212422;
          name = "uwap";
        };
        V = {
          name = "V";
          email = "v@anomalous.eu";
          github = "deviant";
          githubId = 68829907;
        };
        vaibhavsagar = {
          email = "vaibhavsagar@gmail.com";
          matrix = "@vaibhavsagar:matrix.org";
          github = "vaibhavsagar";
          githubId = 1525767;
          name = "Vaibhav Sagar";
        };
        valebes = {
          email = "valebes@gmail.com";
          github = "valebes";
          githubId = 10956211;
          name = "Valerio Besozzi";
        };
        valeriangalliat = {
          email = "val@codejam.info";
          github = "valeriangalliat";
          githubId = 3929133;
          name = "Valérian Galliat";
        };
        valodim = {
          email = "look@my.amazin.horse";
          matrix = "@Valodim:stratum0.org";
          github = "Valodim";
          githubId = 27813;
          name = "Vincent Breitmoser";
        };
        vandenoever = {
          email = "jos@vandenoever.info";
          github = "vandenoever";
          githubId = 608417;
          name = "Jos van den Oever";
        };
        vanilla = {
          email = "osu_vanilla@126.com";
          github = "VergeDX";
          githubId = 25173827;
          name = "Vanilla";
          keys = [{
            fingerprint = "2649 340C C909 F821 D251  6714 3750 028E D04F A42E";
          }];
        };
        vanschelven = {
          email = "klaas@vanschelven.com";
          github = "vanschelven";
          githubId = 223833;
          name = "Klaas van Schelven";
        };
        vanzef = {
          email = "vanzef@gmail.com";
          github = "vanzef";
          githubId = 12428837;
          name = "Ivan Solyankin";
        };
        varunpatro = {
          email = "varun.kumar.patro@gmail.com";
          github = "varunpatro";
          githubId = 6943308;
          name = "Varun Patro";
        };
        vbgl = {
          email = "Vincent.Laporte@gmail.com";
          github = "vbgl";
          githubId = 2612464;
          name = "Vincent Laporte";
        };
        vbmithr = {
          email = "vb@luminar.eu.org";
          github = "vbmithr";
          githubId = 797581;
          name = "Vincent Bernardoff";
        };
        vcanadi = {
          email = "vito.canadi@gmail.com";
          github = "vcanadi";
          githubId = 8889722;
          name = "Vitomir Čanadi";
        };
        vcunat = {
          name = "Vladimír Čunát";
          # vcunat@gmail.com predominated in commits before 2019/03
          email = "v@cunat.cz";
          matrix = "@vcunat:matrix.org";
          github = "vcunat";
          githubId = 1785925;
          keys = [{
            fingerprint = "B600 6460 B60A 80E7 8206  2449 E747 DF1F 9575 A3AA";
          }];
        };
        vdemeester = {
          email = "vincent@sbr.pm";
          github = "vdemeester";
          githubId = 6508;
          name = "Vincent Demeester";
        };
        veehaitch = {
          name = "Vincent Haupert";
          email = "mail@vincent-haupert.de";
          github = "veehaitch";
          githubId = 15069839;
          keys = [{
            fingerprint = "4D23 ECDF 880D CADF 5ECA  4458 874B D6F9 16FA A742";
          }];
        };
        vel = {
          email = "llathasa@outlook.com";
          github = "q60";
          githubId = 61933599;
          name = "vel";
        };
        velovix = {
          email = "xaviosx@gmail.com";
          github = "velovix";
          githubId = 2856634;
          name = "Tyler Compton";
        };
        veprbl = {
          email = "veprbl@gmail.com";
          github = "veprbl";
          githubId = 245573;
          name = "Dmitry Kalinkin";
        };
        victormignot = {
          email = "root@victormignot.fr";
          github = "victormignot";
          githubId = 58660971;
          name = "Victor Mignot";
          keys = [{
            fingerprint = "CA5D F91A D672 683A 1F65  BBC9 0317 096D 20E0 067B";
          }];
        };
        vidbina = {
          email = "vid@bina.me";
          github = "vidbina";
          githubId = 335406;
          name = "David Asabina";
        };
        vidister = {
          email = "v@vidister.de";
          github = "vidister";
          githubId = 11413574;
          name = "Fiona Weber";
        };
        vifino = {
          email = "vifino@tty.sh";
          github = "vifino";
          githubId = 5837359;
          name = "Adrian Pistol";
        };
        vikanezrimaya = {
          email = "vika@fireburn.ru";
          github = "vikanezrimaya";
          githubId = 7953163;
          name = "Vika Shleina";
          keys = [{
            fingerprint = "B3C0 DA1A C18B 82E8 CA8B  B1D1 4F62 CD07 CE64 796A";
          }];
        };
        vincentbernat = {
          email = "vincent@bernat.ch";
          github = "vincentbernat";
          githubId = 631446;
          name = "Vincent Bernat";
          keys = [{
            fingerprint = "AEF2 3487 66F3 71C6 89A7  3600 95A4 2FE8 3535 25F9";
          }];
        };
        vinymeuh = {
          email = "vinymeuh@gmail.com";
          github = "vinymeuh";
          githubId = 118959;
          name = "VinyMeuh";
        };
        virchau13 = {
          email = "virchau13@hexular.net";
          github = "virchau13";
          githubId = 16955157;
          name = "Vir Chaudhury";
        };
        viraptor = {
          email = "nix@viraptor.info";
          github = "viraptor";
          githubId = 188063;
          name = "Stanisław Pitucha";
        };
        viric = {
          email = "viric@viric.name";
          github = "viric";
          githubId = 66664;
          name = "Lluís Batlle i Rossell";
        };
        virusdave = {
          email = "dave.nicponski@gmail.com";
          github = "virusdave";
          githubId = 6148271;
          name = "Dave Nicponski";
        };
        vizanto = {
          email = "danny@prime.vc";
          github = "vizanto";
          githubId = 326263;
          name = "Danny Wilson";
        };
        vklquevs = {
          email = "vklquevs@gmail.com";
          github = "vklquevs";
          githubId = 1771234;
          name = "vklquevs";
        };
        vlaci = {
          email = "laszlo.vasko@outlook.com";
          github = "vlaci";
          githubId = 1771332;
          name = "László Vaskó";
        };
        vlinkz = {
          email = "vmfuentes64@gmail.com";
          github = "vlinkz";
          githubId = 20145996;
          name = "Victor Fuentes";
        };
        vlstill = {
          email = "xstill@fi.muni.cz";
          github = "vlstill";
          githubId = 4070422;
          name = "Vladimír Štill";
        };
        vmandela = {
          email = "venkat.mandela@gmail.com";
          github = "vmandela";
          githubId = 849772;
          name = "Venkateswara Rao Mandela";
        };
        vmchale = {
          email = "tmchale@wisc.edu";
          github = "vmchale";
          githubId = 13259982;
          name = "Vanessa McHale";
        };
      
        voidless = {
          email = "julius.schmitt@yahoo.de";
          github = "voidIess";
          githubId = 45292658;
          name = "Julius Schmitt";
        };
        vojta001 = {
          email = "vojtech.kane@gmail.com";
          github = "vojta001";
          githubId = 7038383;
          name = "Vojta Káně";
        };
        volhovm = {
          email = "volhovm.cs@gmail.com";
          github = "volhovm";
          githubId = 5604643;
          name = "Mikhail Volkhov";
        };
        vonfry = {
          email = "nixos@vonfry.name";
          github = "Vonfry";
          githubId = 3413119;
          name = "Vonfry";
        };
        vq = {
          email = "vq@erq.se";
          github = "vq";
          githubId = 230381;
          name = "Daniel Nilsson";
        };
        vrinek = {
          email = "vrinek@hey.com";
          github = "vrinek";
          name = "Kostas Karachalios";
          githubId = 81346;
        };
        vrthra = {
          email = "rahul@gopinath.org";
          github = "vrthra";
          githubId = 70410;
          name = "Rahul Gopinath";
        };
        vskilet = {
          email = "victor@sene.ovh";
          github = "Vskilet";
          githubId = 7677567;
          name = "Victor SENE";
        };
        vtuan10 = {
          email = "mail@tuan-vo.de";
          github = "vtuan10";
          githubId = 16415673;
          name = "Van Tuan Vo";
        };
        vyorkin = {
          email = "vasiliy.yorkin@gmail.com";
          github = "vyorkin";
          githubId = 988849;
          name = "Vasiliy Yorkin";
        };
        vyp = {
          email = "elisp.vim@gmail.com";
          github = "vyp";
          githubId = 3889405;
          name = "vyp";
        };
        wackbyte = {
          name = "wackbyte";
          email = "wackbyte@pm.me";
          github = "wackbyte";
          githubId = 29505620;
          keys = [{
            fingerprint = "E595 7FE4 FEF6 714B 1AD3  1483 937F 2AE5 CCEF BF59";
          }];
        };
        wakira = {
          name = "Sheng Wang";
          email = "sheng@a64.work";
          github = "wakira";
          githubId = 2338339;
          keys = [{
            fingerprint = "47F7 009E 3AE3 1DA7 988E  12E1 8C9B 0A8F C0C0 D862";
          }];
        };
        wamserma = {
          name = "Markus S. Wamser";
          email = "github-dev@mail2013.wamser.eu";
          github = "wamserma";
          githubId = 60148;
        };
        water-sucks = {
          email = "varun@cvte.org";
          name = "Varun Narravula";
          github = "water-sucks";
          githubId = 68445574;
        };
        waynr = {
          name = "Wayne Warren";
          email = "wayne.warren.s@gmail.com";
          github = "waynr";
          githubId = 1441126;
        };
        wchresta = {
          email = "wchresta.nix@chrummibei.ch";
          github = "wchresta";
          githubId = 34962284;
          name = "wchresta";
        };
        wdavidw = {
          name = "David Worms";
          email = "david@adaltas.com";
          github = "wdavidw";
          githubId = 46896;
        };
        WeebSorceress = {
          name = "WeebSorceress";
          email = "hello@weebsorceress.anonaddy.me";
          matrix = "@weebsorceress:matrix.org";
          github = "WeebSorceress";
          githubId = 106774777;
          keys = [{
            fingerprint = "659A 9BC3 F904 EC24 1461  2EFE 7F57 3443 17F0 FA43";
          }];
        };
        wegank = {
          name = "Weijia Wang";
          email = "contact@weijia.wang";
          github = "wegank";
          githubId = 9713184;
        };
        weihua = {
          email = "luwh364@gmail.com";
          github = "weihua-lu";
          githubId = 9002575;
          name = "Weihua Lu";
        };
        welteki = {
          email = "welteki@pm.me";
          github = "welteki";
          githubId = 16267532;
          name = "Han Verstraete";
          keys = [{
            fingerprint = "2145 955E 3F5E 0C95 3458  41B5 11F7 BAEA 8567 43FF";
          }];
        };
        wentam = {
          name = "Matt Egeler";
          email = "wentam42@gmail.com";
          github = "wentam";
          githubId = 901583;
        };
        wentasah = {
          name = "Michal Sojka";
          email = "wsh@2x.cz";
          github = "wentasah";
          githubId = 140542;
        };
        wesnel = {
          name = "Wesley Nelson";
          email = "wgn@wesnel.dev";
          github = "wesnel";
          githubId = 43357387;
          keys = [{
            fingerprint = "F844 80B2 0CA9 D6CC C7F5  2479 A776 D2AD 099E 8BC0";
          }];
        };
        wheelsandmetal = {
          email = "jakob@schmutz.co.uk";
          github = "wheelsandmetal";
          githubId = 13031455;
          name = "Jakob Schmutz";
        };
        WhittlesJr = {
          email = "alex.joseph.whitt@gmail.com";
          github = "WhittlesJr";
          githubId = 19174984;
          name = "Alex Whitt";
        };
        whonore = {
          email = "wolfhonore@gmail.com";
          github = "whonore";
          githubId = 7121530;
          name = "Wolf Honoré";
        };
        wildsebastian = {
          name = "Sebastian Wild";
          email = "sebastian@wild-siena.com";
          github = "wildsebastian";
          githubId = 1215623;
          keys = [{
            fingerprint = "DA03 D6C6 3F58 E796 AD26  E99B 366A 2940 479A 06FC";
          }];
        };
        willibutz = {
          email = "willibutz@posteo.de";
          github = "WilliButz";
          githubId = 20464732;
          name = "Willi Butz";
        };
        willcohen = {
          email = "willcohen@users.noreply.github.com";
          github = "willcohen";
          githubId = 5185341;
          name = "Will Cohen";
        };
        winpat = {
          email = "patrickwinter@posteo.ch";
          github = "winpat";
          githubId = 6016963;
          name = "Patrick Winter";
        };
        winter = {
          email = "nixos@winter.cafe";
          github = "winterqt";
          githubId = 78392041;
          name = "Winter";
        };
        wintrmvte = {
          name = "Jakub Lutczyn";
          email = "kubalutczyn@gmail.com";
          github = "wintrmvte";
          githubId = 41823252;
        };
        wirew0rm = {
          email = "alex@wirew0rm.de";
          github = "wirew0rm";
          githubId = 1202371;
          name = "Alexander Krimm";
        };
        wishfort36 = {
          email = "42300264+wishfort36@users.noreply.github.com";
          github = "wishfort36";
          githubId = 42300264;
          name = "wishfort36";
        };
        wizeman = {
          email = "rcorreia@wizy.org";
          github = "wizeman";
          githubId = 168610;
          name = "Ricardo M. Correia";
        };
        wjlroe = {
          email = "willroe@gmail.com";
          github = "wjlroe";
          githubId = 43315;
          name = "William Roe";
        };
        wldhx = {
          email = "wldhx+nixpkgs@wldhx.me";
          github = "wldhx";
          githubId = 15619766;
          name = "wldhx";
        };
        wmertens = {
          email = "Wout.Mertens@gmail.com";
          github = "wmertens";
          githubId = 54934;
          name = "Wout Mertens";
        };
        wnklmnn = {
          email = "pascal@wnklmnn.de";
          github = "wnklmnn";
          githubId = 9423014;
          name = "Pascal Winkelmann";
        };
        woffs = {
          email = "github@woffs.de";
          github = "woffs";
          githubId = 895853;
          name = "Frank Doepper";
        };
        wohanley = {
          email = "me@wohanley.com";
          github = "wohanley";
          githubId = 1322287;
          name = "William O'Hanley";
        };
        woky = {
          email = "pampu.andrei@pm.me";
          github = "andreisergiu98";
          githubId = 11740700;
          name = "Andrei Pampu";
        };
        wolfangaukang = {
          email = "clone.gleeful135+nixpkgs@anonaddy.me";
          github = "WolfangAukang";
          githubId = 8378365;
          name = "P. R. d. O.";
        };
        womfoo = {
          email = "kranium@gikos.net";
          github = "womfoo";
          githubId = 1595132;
          name = "Kranium Gikos Mendoza";
        };
        worldofpeace = {
          email = "worldofpeace@protonmail.ch";
          github = "worldofpeace";
          githubId = 28888242;
          name = "WORLDofPEACE";
        };
        wozeparrot = {
          email = "wozeparrot@gmail.com";
          github = "wozeparrot";
          githubId = 25372613;
          name = "Woze Parrot";
        };
        wr0belj = {
          name = "Jakub Wróbel";
          email = "wrobel.jakub@protonmail.com";
          github = "wr0belj";
          githubId = 40501814;
        };
        wrmilling = {
          name = "Winston R. Milling";
          email = "Winston@Milli.ng";
          github = "wrmilling";
          githubId = 6162814;
          keys = [{
            fingerprint = "21E1 6B8D 2EE8 7530 6A6C  9968 D830 77B9 9F8C 6643";
          }];
        };
        wscott = {
          email = "wsc9tt@gmail.com";
          github = "wscott";
          githubId = 31487;
          name = "Wayne Scott";
        };
        wucke13 = {
          email = "wucke13@gmail.com";
          github = "wucke13";
          githubId = 20400405;
          name = "Wucke";
        };
        wykurz = {
          email = "wykurz@gmail.com";
          github = "wykurz";
          githubId = 483465;
          name = "Mateusz Wykurz";
        };
        wulfsta = {
          email = "wulfstawulfsta@gmail.com";
          github = "Wulfsta";
          githubId = 13378502;
          name = "Wulfsta";
        };
        wunderbrick = {
          name = "Andrew Phipps";
          email = "lambdafuzz@tutanota.com";
          github = "wunderbrick";
          githubId = 52174714;
        };
        wyndon = {
          email = "72203260+wyndon@users.noreply.github.com";
          matrix = "@wyndon:envs.net";
          github = "wyndon";
          githubId = 72203260;
          name = "wyndon";
        };
        wyvie = {
          email = "elijahrum@gmail.com";
          github = "alicerum";
          githubId = 3992240;
          name = "Elijah Rum";
        };
        x3ro = {
          name = "^x3ro";
          email = "nix@x3ro.dev";
          github = "x3rAx";
          githubId = 2268851;
        };
        xanderio = {
          name = "Alexander Sieg";
          email = "alex@xanderio.de";
          github = "xanderio";
          githubId = 6298052;
        };
        xaverdh = {
          email = "hoe.dom@gmx.de";
          github = "xaverdh";
          githubId = 11050617;
          name = "Dominik Xaver Hörl";
        };
        xbreak = {
          email = "xbreak@alphaware.se";
          github = "xbreak";
          githubId = 13489144;
          name = "Calle Rosenquist";
        };
        xdhampus = {
          name = "Hampus";
          email = "16954508+xdHampus@users.noreply.github.com";
          github = "xdHampus";
          githubId = 16954508;
        };
        xe = {
          email = "me@christine.website";
          matrix = "@withoutwithin:matrix.org";
          github = "Xe";
          githubId = 529003;
          name = "Christine Dodrill";
        };
        xeji = {
          email = "xeji@cat3.de";
          github = "xeji";
          githubId = 36407913;
          name = "Uli Baum";
        };
        xfnw = {
          email = "xfnw+nixos@riseup.net";
          github = "xfnw";
          githubId = 66233223;
          name = "Owen";
        };
        xfix = {
          email = "konrad@borowski.pw";
          matrix = "@xfix:matrix.org";
          github = "xfix";
          githubId = 1297598;
          name = "Konrad Borowski";
        };
        xgroleau = {
          email = "xgroleau@gmail.com";
          github = "xgroleau";
          githubId = 31734358;
          name = "Xavier Groleau";
        };
        xiorcale = {
          email = "quentin.vaucher@pm.me";
          github = "xiorcale";
          githubId = 17534323;
          name = "Quentin Vaucher";
        };
        xnaveira = {
          email = "xnaveira@gmail.com";
          github = "xnaveira";
          githubId = 2534411;
          name = "Xavier Naveira";
        };
        xnwdd = {
          email = "nwdd+nixos@no.team";
          github = "xNWDD";
          githubId = 3028542;
          name = "Guillermo NWDD";
        };
        xrelkd = {
          email = "46590321+xrelkd@users.noreply.github.com";
          github = "xrelkd";
          githubId = 46590321;
          name = "xrelkd";
        };
        xurei = {
          email = "olivier.bourdoux@gmail.com";
          github = "xurei";
          githubId = 621695;
          name = "Olivier Bourdoux";
        };
        xvapx = {
          email = "marti.serra.coscollano@gmail.com";
          github = "xvapx";
          githubId = 11824817;
          name = "Marti Serra";
        };
        xworld21 = {
          email = "1962985+xworld21@users.noreply.github.com";
          github = "xworld21";
          githubId = 1962985;
          name = "Vincenzo Mantova";
        };
        xyenon = {
          name = "XYenon";
          email = "i@xyenon.bid";
          github = "XYenon";
          githubId = 20698483;
        };
        xzfc = {
          email = "xzfcpw@gmail.com";
          github = "xzfc";
          githubId = 5121426;
          name = "Albert Safin";
        };
        y0no = {
          email = "y0no@y0no.fr";
          github = "y0no";
          githubId = 2242427;
          name = "Yoann Ono";
        };
        yana = {
          email = "yana@riseup.net";
          github = "yanalunaterra";
          githubId = 1643293;
          name = "Yana Timoshenko";
        };
        yarny = {
          email = "41838844+Yarny0@users.noreply.github.com";
          github = "Yarny0";
          githubId = 41838844;
          name = "Yarny";
        };
        yarr = {
          email = "savraz@gmail.com";
          github = "Eternity-Yarr";
          githubId = 3705333;
          name = "Dmitry V.";
        };
        yayayayaka = {
          email = "nixpkgs@uwu.is";
          matrix = "@lara:uwu.is";
          github = "yayayayaka";
          githubId = 73759599;
          name = "Lara A.";
        };
        yesbox = {
          email = "jesper.geertsen.jonsson@gmail.com";
          github = "yesbox";
          githubId = 4113027;
          name = "Jesper Geertsen Jonsson";
        };
        yinfeng = {
          email = "lin.yinfeng@outlook.com";
          github = "linyinfeng";
          githubId = 11229748;
          name = "Lin Yinfeng";
        };
        ylecornec = {
          email = "yves.stan.lecornec@tweag.io";
          github = "ylecornec";
          githubId = 5978566;
          name = "Yves-Stan Le Cornec";
        };
        ylh = {
          email = "nixpkgs@ylh.io";
          github = "ylh";
          githubId = 9125590;
          name = "Yestin L. Harrison";
        };
        ylwghst = {
          email = "ylwghst@onionmail.info";
          github = "ylwghst";
          githubId = 26011724;
          name = "Burim Augustin Berisa";
        };
        yl3dy = {
          email = "aleksandr.kiselyov@gmail.com";
          github = "yl3dy";
          githubId = 1311192;
          name = "Alexander Kiselyov";
        };
        yochai = {
          email = "yochai@titat.info";
          github = "yochai";
          githubId = 1322201;
          name = "Yochai";
        };
        yoctocell = {
          email = "public@yoctocell.xyz";
          github = "yoctocell";
          githubId = 40352765;
          name = "Yoctocell";
        };
        yorickvp = {
          email = "yorickvanpelt@gmail.com";
          matrix = "@yorickvp:matrix.org";
          github = "yorickvP";
          githubId = 647076;
          name = "Yorick van Pelt";
        };
        yrashk = {
          email = "yrashk@gmail.com";
          github = "yrashk";
          githubId = 452;
          name = "Yurii Rashkovskii";
        };
        yrd = {
          name = "Yannik Rödel";
          email = "nix@yannik.info";
          github = "yrd";
          githubId = 1820447;
        };
        ysndr = {
          email = "me@ysndr.de";
          github = "ysndr";
          githubId = 7040031;
          name = "Yannik Sander";
        };
        yureien = {
          email = "contact@sohamsen.me";
          github = "Yureien";
          githubId = 17357089;
          name = "Soham Sen";
        };
        yuriaisaka = {
          email = "yuri.aisaka+nix@gmail.com";
          github = "yuriaisaka";
          githubId = 687198;
          name = "Yuri Aisaka";
        };
        yurkobb = {
          name = "Yury Bulka";
          email = "setthemfree@privacyrequired.com";
          github = "yurkobb";
          githubId = 479389;
        };
        yurrriq = {
          email = "eric@ericb.me";
          github = "yurrriq";
          githubId = 1866448;
          name = "Eric Bailey";
        };
        Yumasi = {
          email = "gpagnoux@gmail.com";
          github = "Yumasi";
          githubId = 24368641;
          name = "Guillaume Pagnoux";
          keys = [{
            fingerprint = "85F8 E850 F8F2 F823 F934  535B EC50 6589 9AEA AF4C";
          }];
        };
        yuka = {
          email = "yuka@yuka.dev";
          matrix = "@yuka:yuka.dev";
          github = "yu-re-ka";
          githubId = 86169957;
          name = "Yureka";
        };
        yusdacra = {
          email = "y.bera003.06@protonmail.com";
          matrix = "@yusdacra:nixos.dev";
          github = "yusdacra";
          githubId = 19897088;
          name = "Yusuf Bera Ertan";
          keys = [{
            fingerprint = "9270 66BD 8125 A45B 4AC4 0326 6180 7181 F60E FCB2";
          }];
        };
        yuu = {
          email = "yuuyin@protonmail.com";
          github = "yuuyins";
          githubId = 86538850;
          name = "Yuu Yin";
          keys = [{
            fingerprint = "9F19 3AE8 AA25 647F FC31  46B5 416F 303B 43C2 0AC3";
          }];
        };
        yvesf = {
          email = "yvesf+nix@xapek.org";
          github = "yvesf";
          githubId = 179548;
          name = "Yves Fischer";
        };
        yvt = {
          email = "i@yvt.jp";
          github = "yvt";
          githubId = 5253988;
          name = "yvt";
        };
        maggesi = {
          email = "marco.maggesi@gmail.com";
          github = "maggesi";
          githubId = 1809783;
          name = "Marco Maggesi";
        };
        zachcoyle = {
          email = "zach.coyle@gmail.com";
          github = "zachcoyle";
          githubId = 908716;
          name = "Zach Coyle";
        };
        zagy = {
          email = "cz@flyingcircus.io";
          github = "zagy";
          githubId = 568532;
          name = "Christian Zagrodnick";
        };
        zakame = {
          email = "zakame@zakame.net";
          github = "zakame";
          githubId = 110625;
          name = "Zak B. Elep";
        };
        zalakain = {
          email = "ping@umazalakain.info";
          github = "umazalakain";
          githubId = 1319905;
          name = "Uma Zalakain";
        };
        zaninime = {
          email = "francesco@zanini.me";
          github = "zaninime";
          githubId = 450885;
          name = "Francesco Zanini";
        };
        zarelit = {
          email = "david@zarel.net";
          github = "zarelit";
          githubId = 3449926;
          name = "David Costa";
        };
        zauberpony = {
          email = "elmar@athmer.org";
          github = "elmarx";
          githubId = 250877;
          name = "Elmar Athmer";
        };
        zakkor = {
          email = "edward.dalbon@gmail.com";
          github = "zakkor";
          githubId = 6191421;
          name = "Edward d'Albon";
        };
        zebreus = {
          matrix = "@lennart:cicen.net";
          email = "lennarteichhorn+nixpkgs@gmail.com";
          github = "Zebreus";
          githubId = 1557253;
          name = "Lennart Eichhorn";
        };
        zeratax = {
          email = "mail@zera.tax";
          github = "zeratax";
          githubId = 5024958;
          name = "Jona Abdinghoff";
          keys = [{
            fingerprint = "44F7 B797 9D3A 27B1 89E0  841E 8333 735E 784D F9D4";
          }];
        };
        zfnmxt = {
          name = "zfnmxt";
          email = "zfnmxt@zfnmxt.com";
          github = "zfnmxt";
          githubId = 37446532;
        };
        zgrannan = {
          email = "zgrannan@gmail.com";
          github = "zgrannan";
          githubId = 1141948;
          name = "Zack Grannan";
        };
        zhaofengli = {
          email = "hello@zhaofeng.li";
          matrix = "@zhaofeng:zhaofeng.li";
          github = "zhaofengli";
          githubId = 2189609;
          name = "Zhaofeng Li";
        };
        zimbatm = {
          email = "zimbatm@zimbatm.com";
          github = "zimbatm";
          githubId = 3248;
          name = "zimbatm";
        };
        Zimmi48 = {
          email = "theo.zimmermann@univ-paris-diderot.fr";
          github = "Zimmi48";
          githubId = 1108325;
          name = "Théo Zimmermann";
        };
        zohl = {
          email = "zohl@fmap.me";
          github = "zohl";
          githubId = 6067895;
          name = "Al Zohali";
        };
        zookatron = {
          email = "tim@zookatron.com";
          github = "zookatron";
          githubId = 1772064;
          name = "Tim Zook";
        };
        zopieux = {
          email = "zopieux@gmail.com";
          github = "zopieux";
          githubId = 81353;
          name = "Alexandre Macabies";
        };
        zowoq = {
          email = "59103226+zowoq@users.noreply.github.com";
          github = "zowoq";
          githubId = 59103226;
          name = "zowoq";
        };
        zraexy = {
          email = "zraexy@gmail.com";
          github = "zraexy";
          githubId = 8100652;
          name = "David Mell";
        };
        ztzg = {
          email = "dd@crosstwine.com";
          github = "ztzg";
          githubId = 393108;
          name = "Damien Diederen";
        };
        zx2c4 = {
          email = "Jason@zx2c4.com";
          github = "zx2c4";
          githubId = 10643;
          name = "Jason A. Donenfeld";
        };
        zyansheep = {
          email = "zyansheep@protonmail.com";
          github = "zyansheep";
          githubId = 20029431;
          name = "Zyansheep";
        };
        zzamboni = {
          email = "diego@zzamboni.org";
          github = "zzamboni";
          githubId = 32876;
          name = "Diego Zamboni";
        };
        turbomack = {
          email = "marek.faj@gmail.com";
          github = "turboMaCk";
          githubId = 2130305;
          name = "Marek Fajkus";
        };
        melling = {
          email = "mattmelling@fastmail.com";
          github = "mattmelling";
          githubId = 1215331;
          name = "Matt Melling";
        };
        wd15 = {
          email = "daniel.wheeler2@gmail.com";
          github = "wd15";
          githubId = 1986844;
          name = "Daniel Wheeler";
        };
        misuzu = {
          email = "bakalolka@gmail.com";
          github = "misuzu";
          githubId = 248143;
          name = "misuzu";
        };
        zokrezyl = {
          email = "zokrezyl@gmail.com";
          github = "zokrezyl";
          githubId = 51886259;
          name = "Zokre Zyl";
        };
        rakesh4g = {
          email = "rakeshgupta4u@gmail.com";
          github = "Rakesh4G";
          githubId = 50867187;
          name = "Rakesh Gupta";
        };
        mlatus = {
          email = "wqseleven@gmail.com";
          github = "Ninlives";
          githubId = 17873203;
          name = "mlatus";
        };
        waiting-for-dev = {
          email = "marc@lamarciana.com";
          github = "waiting-for-dev";
          githubId = 52650;
          name = "Marc Busqué";
        };
        snglth = {
          email = "illia@ishestakov.com";
          github = "snglth";
          githubId = 8686360;
          name = "Illia Shestakov";
        };
        masaeedu = {
          email = "masaeedu@gmail.com";
          github = "masaeedu";
          githubId = 3674056;
          name = "Asad Saeeduddin";
        };
        matthewcroughan = {
          email = "matt@croughan.sh";
          github = "MatthewCroughan";
          githubId = 26458780;
          name = "Matthew Croughan";
        };
        ngerstle = {
          name = "Nicholas Gerstle";
          email = "ngerstle@gmail.com";
          github = "ngerstle";
          githubId = 1023752;
        };
        shardy = {
          email = "shardul@baral.ca";
          github = "shardulbee";
          githubId = 16765155;
          name = "Shardul Baral";
        };
        xavierzwirtz = {
          email = "me@xavierzwirtz.com";
          github = "xavierzwirtz";
          githubId = 474343;
          name = "Xavier Zwirtz";
        };
        ymarkus = {
          name = "Yannick Markus";
          email = "nixpkgs@ymarkus.dev";
          github = "ymarkus";
          githubId = 62380378;
        };
        ymatsiuk = {
          name = "Yurii Matsiuk";
          email = "ymatsiuk@users.noreply.github.com";
          github = "ymatsiuk";
          githubId = 24990891;
          keys = [{
            fingerprint = "7BB8 84B5 74DA FDB1 E194  ED21 6130 2290 2986 01AA";
          }];
        };
        ymeister = {
          name = "Yuri Meister";
          email = "47071325+ymeister@users.noreply.github.com";
          github = "ymeister";
          githubId = 47071325;
        };
        cpcloud = {
          name = "Phillip Cloud";
          email = "417981+cpcloud@users.noreply.github.com";
          github = "cpcloud";
          githubId = 417981;
        };
        davegallant = {
          name = "Dave Gallant";
          email = "davegallant@gmail.com";
          github = "davegallant";
          githubId = 4519234;
        };
        saulecabrera = {
          name = "Saúl Cabrera";
          email = "saulecabrera@gmail.com";
          github = "saulecabrera";
          githubId = 1423601;
        };
        tfmoraes = {
          name = "Thiago Franco de Moraes";
          email = "351108+tfmoraes@users.noreply.github.com";
          github = "tfmoraes";
          githubId = 351108;
        };
        deifactor = {
          name = "Ash Zahlen";
          email = "ext0l@riseup.net";
          github = "deifactor";
          githubId = 30192992;
        };
        deinferno = {
          name = "deinferno";
          email = "14363193+deinferno@users.noreply.github.com";
          github = "deinferno";
          githubId = 14363193;
        };
        fzakaria = {
          name = "Farid Zakaria";
          email = "farid.m.zakaria@gmail.com";
          matrix = "@fzakaria:matrix.org";
          github = "fzakaria";
          githubId = 605070;
        };
        nagisa = {
          name = "Simonas Kazlauskas";
          email = "nixpkgs@kazlauskas.me";
          github = "nagisa";
          githubId = 679122;
        };
        yshym = {
          name = "Yevhen Shymotiuk";
          email = "yshym@pm.me";
          github = "yshym";
          githubId = 44244245;
        };
        hmenke = {
          name = "Henri Menke";
          email = "henri@henrimenke.de";
          matrix = "@hmenke:matrix.org";
          github = "hmenke";
          githubId = 1903556;
          keys = [{
            fingerprint = "F1C5 760E 45B9 9A44 72E9  6BFB D65C 9AFB 4C22 4DA3";
          }];
        };
        berbiche = {
          name = "Nicolas Berbiche";
          email = "nicolas@normie.dev";
          github = "berbiche";
          githubId = 20448408;
          keys = [{
            fingerprint = "D446 E58D 87A0 31C7 EC15  88D7 B461 2924 45C6 E696";
          }];
        };
        wenngle = {
          name = "Zeke Stephens";
          email = "zekestephens@gmail.com";
          github = "wenngle";
          githubId = 63376671;
        };
        yanganto = {
          name = "Antonio Yang";
          email = "yanganto@gmail.com";
          github = "yanganto";
          githubId = 10803111;
        };
        starcraft66 = {
          name = "Tristan Gosselin-Hane";
          email = "starcraft66@gmail.com";
          github = "starcraft66";
          githubId = 1858154;
          keys = [{
            fingerprint = "8597 4506 EC69 5392 0443  0805 9D98 CDAC FF04 FD78";
          }];
        };
        hloeffler = {
          name = "Hauke Löffler";
          email = "nix@hauke-loeffler.de";
          github = "hloeffler";
          githubId = 6627191;
        };
        wilsonehusin = {
          name = "Wilson E. Husin";
          email = "wilsonehusin@gmail.com";
          github = "wilsonehusin";
          githubId = 14004487;
        };
        bb2020 = {
          email = "bb2020@users.noreply.github.com";
          github = "bb2020";
          githubId = 19290397;
          name = "Tunc Uzlu";
        };
        pulsation = {
          name = "Philippe Sam-Long";
          email = "1838397+pulsation@users.noreply.github.com";
          github = "pulsation";
          githubId = 1838397;
        };
        princemachiavelli = {
          name = "Josh Hoffer";
          email = "jhoffer@sansorgan.es";
          matrix = "@princemachiavelli:matrix.org";
          github = "Princemachiavelli";
          githubId = 2730968;
          keys = [{
            fingerprint = "DD54 130B ABEC B65C 1F6B  2A38 8312 4F97 A318 EA18";
          }];
        };
        ydlr = {
          name = "ydlr";
          email = "ydlr@ydlr.io";
          github = "ydlr";
          githubId = 58453832;
          keys = [{
            fingerprint = "FD0A C425 9EF5 4084 F99F 9B47 2ACC 9749 7C68 FAD4";
          }];
        };
        zane = {
          name = "Zane van Iperen";
          email = "zane@zanevaniperen.com";
          github = "vs49688";
          githubId = 4423262;
          keys = [{
            fingerprint = "61AE D40F 368B 6F26 9DAE  3892 6861 6B2D 8AC4 DCC5";
          }];
        };
        zbioe = {
          name = "Iury Fukuda";
          email = "zbioe@protonmail.com";
          github = "zbioe";
          githubId = 7332055;
        };
        zendo = {
          name = "zendo";
          email = "linzway@qq.com";
          github = "zendo";
          githubId = 348013;
        };
        zenithal = {
          name = "zenithal";
          email = "i@zenithal.me";
          github = "ZenithalHourlyRate";
          githubId = 19512674;
          keys = [{
            fingerprint = "1127 F188 280A E312 3619  3329 87E1 7EEF 9B18 B6C9";
          }];
        };
        zeri = {
          name = "zeri";
          email = "68825133+zeri42@users.noreply.github.com";
          matrix = "@zeri:matrix.org";
          github = "zeri42";
          githubId = 68825133;
        };
        zoedsoupe = {
          github = "zoedsoupe";
          githubId = 44469426;
          name = "Zoey de Souza Pessanha";
          email = "zoey.spessanha@outlook.com";
          keys = [{
            fingerprint = "EAA1 51DB 472B 0122 109A  CB17 1E1E 889C DBD6 A315";
          }];
        };
        zombiezen = {
          name = "Ross Light";
          email = "ross@zombiezen.com";
          github = "zombiezen";
          githubId = 181535;
        };
        zseri = {
          name = "zseri";
          email = "zseri.devel@ytrizja.de";
          github = "zseri";
          githubId = 1618343;
          keys = [{
            fingerprint = "7AFB C595 0D3A 77BD B00F  947B 229E 63AE 5644 A96D";
          }];
        };
        zupo = {
          name = "Nejc Zupan";
          email = "nejczupan+nix@gmail.com";
          github = "zupo";
          githubId = 311580;
        };
        sei40kr = {
          name = "Seong Yong-ju";
          email = "sei40kr@gmail.com";
          github = "sei40kr";
          githubId = 11665236;
        };
        vdot0x23 = {
          name = "Victor Büttner";
          email = "nix.victor@0x23.dk";
          github = "vdot0x23";
          githubId = 40716069;
        };
        jpagex = {
          name = "Jérémy Pagé";
          email = "contact@jeremypage.me";
          github = "jpagex";
          githubId = 635768;
        };
        vbrandl = {
          name = "Valentin Brandl";
          email = "mail+nixpkgs@vbrandl.net";
          github = "vbrandl";
          githubId = 20639051;
        };
        portothree = {
          name = "Gustavo Porto";
          email = "gus@p8s.co";
          github = "portothree";
          githubId = 3718120;
        };
        pwoelfel = {
          name = "Philipp Woelfel";
          email = "philipp.woelfel@gmail.com";
          github = "PhilippWoelfel";
          githubId = 19400064;
        };
        qbit = {
          name = "Aaron Bieber";
          email = "aaron@bolddaemon.com";
          github = "qbit";
          githubId = 68368;
          matrix = "@qbit:tapenet.org";
          keys = [{
            fingerprint = "3586 3350 BFEA C101 DB1A 4AF0 1F81 112D 62A9 ADCE";
          }];
        };
        ameer = {
          name = "Ameer Taweel";
          email = "ameertaweel2002@gmail.com";
          github = "AmeerTaweel";
          githubId = 20538273;
        };
        nigelgbanks = {
          name = "Nigel Banks";
          email = "nigel.g.banks@gmail.com";
          github = "nigelgbanks";
          githubId = 487373;
        };
        zanculmarktum = {
          name = "Azure Zanculmarktum";
          email = "zanculmarktum@gmail.com";
          github = "zanculmarktum";
          githubId = 16958511;
        };
        kuwii = {
          name = "kuwii";
          email = "kuwii.someone@gmail.com";
          github = "kuwii";
          githubId = 10705175;
        };
        kkharji = {
          name = "kkharji";
          email = "kkharji@protonmail.com";
          github = "kkharji";
          githubId = 65782666;
        };
        melias122 = {
          name = "Martin Elias";
          email = "martin+nixpkgs@elias.sx";
          github = "melias122";
          githubId = 1027766;
        };
        bryanhonof = {
          name = "Bryan Honof";
          email = "bryanhonof@gmail.com";
          github = "bryanhonof";
          githubId = 5932804;
        };
        bbenne10 = {
          email = "Bryan.Bennett@protonmail.com";
          matrix = "@bryan.bennett:matrix.org";
          github = "bbenne10";
          githubId = 687376;
          name = "Bryan Bennett";
          keys = [{
            # compare with https://keybase.io/bbenne10
            fingerprint = "41EA 00B4 00F9 6970 1CB2  D3AF EF90 E3E9 8B8F 5C0B";
          }];
        };
        snpschaaf = {
          email = "philipe.schaaf@secunet.com";
          name = "Philippe Schaaf";
          github = "snpschaaf";
          githubId = 105843013;
        };
        SohamG = {
          email = "sohamg2@gmail.com";
          name = "Soham S Gumaste";
          github = "SohamG";
          githubId = 7116239;
          keys = [{
            fingerprint = "E067 520F 5EF2 C175 3F60  50C0 BA46 725F 6A26 7442";
          }];
        };
        jali-clarke = {
          email = "jinnah.ali-clarke@outlook.com";
          name = "Jinnah Ali-Clarke";
          github = "jali-clarke";
          githubId = 17733984;
        };
        wesleyjrz = {
          email = "dev@wesleyjrz.com";
          name = "Wesley V. Santos Jr.";
          github = "wesleyjrz";
          githubId = 60184588;
        };
        npatsakula = {
          email = "nikita.patsakula@gmail.com";
          name = "Patsakula Nikita";
          github = "npatsakula";
          githubId = 23001619;
        };
        dfithian = {
          email = "daniel.m.fithian@gmail.com";
          name = "Daniel Fithian";
          github = "dfithian";
          githubId = 8409320;
        };
        nikstur = {
          email = "nikstur@outlook.com";
          name = "nikstur";
          github = "nikstur";
          githubId = 61635709;
        };
        yisuidenghua = {
          email = "bileiner@gmail.com";
          name = "Milena Yisui";
          github = "YisuiDenghua";
          githubId = 102890144;
        };
        macalinao = {
          email = "me@ianm.com";
          name = "Ian Macalinao";
          github = "macalinao";
          githubId = 401263;
          keys = [{
            fingerprint = "1147 43F1 E707 6F3E 6F4B  2C96 B9A8 B592 F126 F8E8";
          }];
        };
        tjni = {
          email = "43ngvg@masqt.com";
          matrix = "@tni:matrix.org";
          name = "Theodore Ni";
          github = "tjni";
          githubId = 3806110;
          keys = [{
            fingerprint = "4384 B8E1 299F C028 1641  7B8F EC30 EFBE FA7E 84A4";
          }];
        };
        bezmuth = {
          email = "benkel97@protonmail.com";
          name = "Ben Kelly";
          github = "bezmuth";
          githubId = 31394095;
        };
        cafkafk = {
          email = "christina@cafkafk.com";
          matrix = "@cafkafk:matrix.cafkafk.com";
          name = "Christina Sørensen";
          github = "cafkafk";
          githubId = 89321978;
          keys = [
            {
              fingerprint = "7B9E E848 D074 AE03 7A0C  651A 8ED4 DEF7 375A 30C8";
            }
            {
              fingerprint = "208A 2A66 8A2F CDE7 B5D3 8F64 CDDC 792F 6552 51ED";
            }
          ];
        };
        rb = {
          email = "maintainers@cloudposse.com";
          github = "nitrocode";
          githubId = 7775707;
          name = "RB";
        };
        bpaulin = {
          email = "brunopaulin@bpaulin.net";
          github = "bpaulin";
          githubId = 115711;
          name = "bpaulin";
        };
        zuzuleinen = {
          email = "andrey.boar@gmail.com";
          name = "Andrei Boar";
          github = "zuzuleinen";
          githubId = 944919;
        };
        waelwindows = {
          email = "waelwindows9922@gmail.com";
          github = "Waelwindows";
          githubId = 5228243;
          name = "waelwindows";
        };
        witchof0x20 = {
          name = "Jade";
          email = "jade@witchof.space";
          github = "witchof0x20";
          githubId = 36118348;
          keys = [{
            fingerprint = "69C9 876B 5797 1B2E 11C5  7C39 80A1 F76F C9F9 54AE";
          }];
        };
        WhiteBlackGoose = {
          email = "wbg@angouri.org";
          github = "WhiteBlackGoose";
          githubId = 31178401;
          name = "WhiteBlackGoose";
          keys = [{
            fingerprint = "640B EDDE 9734 310A BFA3  B257 52ED AE6A 3995 AFAB";
          }];
        };
        wuyoli = {
          name = "wuyoli";
          email = "wuyoli@tilde.team";
          github = "wuyoli";
          githubId = 104238274;
        };
        ziguana = {
          name = "Zig Uana";
          email = "git@ziguana.dev";
          github = "ziguana";
          githubId = 45833444;
        };
        detegr = {
          name = "Antti Keränen";
          email = "detegr@rbx.email";
          github = "Detegr";
          githubId = 724433;
        };
        RossComputerGuy = {
          name = "Tristan Ross";
          email = "tristan.ross@midstall.com";
          github = "RossComputerGuy";
          githubId = 19699320;
        };
        franzmondlichtmann = {
          name = "Franz Schroepf";
          email = "franz-schroepf@t-online.de";
          github = "franzmondlichtmann";
          githubId = 105480088;
        };
      }
    );
    "/Users/jeffhykin/repos/nixpkgs/maintainers/team-list.nix" = (# "/Users/jeffhykin/repos/nixpkgs/maintainers/team-list.nix"
      /* List of maintainer teams.
          name = {
            # Required
            members = [ maintainer1 maintainer2 ];
            scope = "Maintain foo packages.";
            shortName = "foo";
            # Optional
            enableFeatureFreezePing = true;
            githubTeams = [ "my-subsystem" ];
          };
      
        where
      
        - `members` is the list of maintainers belonging to the group,
        - `scope` describes the scope of the group.
        - `shortName` short human-readable name
        - `enableFeatureFreezePing` will ping this team during the Feature Freeze announcements on releases
          - There is limited mention capacity in a single post, so this should be reserved for critical components
            or larger ecosystems within nixpkgs.
        - `githubTeams` will ping specified GitHub teams as well
      
        More fields may be added in the future.
      
        When editing this file:
         * keep the list alphabetically sorted
         * test the validity of the format with:
             nix-build lib/tests/teams.nix
        */
      
      { lib }:
      with lib.maintainers; {
        acme = {
          members = [
            aanderse
            andrew-d
            arianvp
            emily
            flokli
            m1cr0man
          ];
          scope = "Maintain ACME-related packages and modules.";
          shortName = "ACME";
          enableFeatureFreezePing = true;
        };
      
        bazel = {
          members = [
            mboes
            marsam
            uri-canva
            cbley
            olebedev
            groodt
            aherrmann
            ylecornec
          ];
          scope = "Bazel build tool & related tools https://bazel.build/";
          shortName = "Bazel";
          enableFeatureFreezePing = true;
        };
      
        beam = {
          members = [
            ankhers
            Br1ght0ne
            DianaOlympos
            gleber
            happysalada
            minijackson
            yurrriq
          ];
          githubTeams = [
            "beam"
          ];
          scope = "Maintain BEAM-related packages and modules.";
          shortName = "BEAM";
          enableFeatureFreezePing = true;
        };
      
        bitnomial = {
          # Verify additions to this team with at least one already existing member of the team.
          members = [
            cdepillabout
          ];
          scope = "Group registration for packages maintained by Bitnomial.";
          shortName = "Bitnomial employees";
        };
      
        blockchains = {
          members = [
            mmahut
            RaghavSood
          ];
          scope = "Maintain Blockchain packages and modules.";
          shortName = "Blockchains";
        };
      
        c = {
          members = [
            matthewbauer
            mic92
          ];
          scope = "Maintain C libraries and tooling.";
          shortName = "C";
          enableFeatureFreezePing = true;
        };
      
        c3d2 = {
          members = [
            astro
            SuperSandro2000
            revol-xut
            oxapentane
          ];
          scope = "Maintain packages used in the C3D2 hackspace";
          shortName = "c3d2";
        };
      
        cinnamon = {
          members = [
            bobby285271
            mkg20001
          ];
          scope = "Maintain Cinnamon desktop environment and applications made by the Linux Mint team.";
          shortName = "Cinnamon";
          enableFeatureFreezePing = true;
        };
      
        chia = {
          members = [
            lourkeur
          ];
          scope = "Maintain the Chia blockchain and its dependencies";
          shortName = "Chia Blockchain";
        };
      
        coq = {
          members = [
            cohencyril
            Zimmi48
            # gares has no entry in the maintainers list
            siraben
            vbgl
          ];
          scope = "Maintain the Coq theorem prover and related packages.";
          shortName = "Coq";
          enableFeatureFreezePing = true;
        };
      
        darwin = {
          members = [
            toonn
          ];
          githubTeams = [
            "darwin-maintainers"
          ];
          scope = "Maintain Darwin compatibility of packages and Darwin-only packages.";
          shortName = "Darwin";
          enableFeatureFreezePing = true;
        };
      
        cosmopolitan = {
          members = [
            lourkeur
            tomberek
          ];
          scope = "Maintain the Cosmopolitan LibC and related programs.";
          shortName = "Cosmopolitan";
        };
      
        deshaw = {
          # Verify additions to this team with at least one already existing member of the team.
          members = [
            limeytexan
          ];
          scope = "Group registration for D. E. Shaw employees who collectively maintain packages.";
          shortName = "Shaw employees";
        };
      
        determinatesystems = {
          # Verify additions to this team with at least one already existing member of the team.
          members = [
            cole-h
            grahamc
            hoverbear
            lheckemann
          ];
          scope = "Group registration for packages maintained by Determinate Systems.";
          shortName = "Determinate Systems employees";
        };
      
        dhall = {
          members = [
            Gabriel439
            ehmry
          ];
          scope = "Maintain Dhall and related packages.";
          shortName = "Dhall";
          enableFeatureFreezePing = true;
        };
      
        docker = {
          members = [
            roberth
            utdemir
          ];
          scope = "Maintain Docker and related tools.";
          shortName = "DockerTools";
        };
      
        docs = {
          members = [
            ryantm
          ];
          scope = "Maintain nixpkgs/NixOS documentation and tools for building it.";
          shortName = "Docs";
          enableFeatureFreezePing = true;
        };
      
        emacs = {
          members = [
            adisbladis
          ];
          scope = "Maintain the Emacs editor and packages.";
          shortName = "Emacs";
        };
      
        enlightenment = {
          members = [
            romildo
          ];
          githubTeams = [
            "enlightenment"
          ];
          scope = "Maintain Enlightenment desktop environment and related packages.";
          shortName = "Enlightenment";
          enableFeatureFreezePing = true;
        };
      
        # Dummy group for the "everyone else" section
        feature-freeze-everyone-else = {
          members = [ ];
          githubTeams = [
            "nixpkgs-committers"
            "release-engineers"
          ];
          scope = "Dummy team for the #everyone else' section during feture freezes, not to be used as package maintainers!";
          shortName = "Everyone else";
          enableFeatureFreezePing = true;
        };
      
        freedesktop = {
          members = [ jtojnar ];
          scope = "Maintain Freedesktop.org packages for graphical desktop.";
          shortName = "freedesktop.org packaging";
        };
      
        gcc = {
          members = [
            synthetica
            vcunat
            ericson2314
          ];
          scope = "Maintain GCC (GNU Compiler Collection) compilers";
          shortName = "GCC";
        };
      
        geospatial = {
          members = [
            imincik
            sikmir
          ];
          scope = "Maintain geospatial packages.";
          shortName = "Geospatial";
        };
      
        golang = {
          members = [
            c00w
            kalbasit
            mic92
            zowoq
            qbit
          ];
          scope = "Maintain Golang compilers.";
          shortName = "Go";
          enableFeatureFreezePing = true;
        };
      
        gnome = {
          members = [
            bobby285271
            hedning
            jtojnar
            dasj19
            maxeaubrey
          ];
          githubTeams = [
            "gnome"
          ];
          scope = "Maintain GNOME desktop environment and platform.";
          shortName = "GNOME";
          enableFeatureFreezePing = true;
        };
      
        haskell = {
          members = [
            cdepillabout
            expipiplus1
            maralorn
            sternenseemann
          ];
          githubTeams = [
            "haskell"
          ];
          scope = "Maintain Haskell packages and infrastructure.";
          shortName = "Haskell";
          enableFeatureFreezePing = true;
        };
      
        home-assistant = {
          members = [
            fab
            globin
            hexa
            mic92
          ];
          scope = "Maintain the Home Assistant ecosystem";
          shortName = "Home Assistant";
        };
      
        iog = {
          members = [
            cleverca22
            disassembler
            jonringer
            manveru
            nrdxp
          ];
          scope = "Input-Output Global employees, which maintain critical software";
          shortName = "Input-Output Global employees";
        };
      
        jitsi = {
          members = [
            cleeyv
            ryantm
            yuka
          ];
          scope = "Maintain Jitsi.";
          shortName = "Jitsi";
        };
      
        kubernetes = {
          members = [
            johanot
            offline
            saschagrunert
            srhb
            zowoq
          ];
          scope = "Maintain the Kubernetes package and module";
          shortName = "Kubernetes";
        };
      
        kodi = {
          members = [
            aanderse
            cpages
            edwtjo
            minijackson
            peterhoeg
            sephalon
          ];
          scope = "Maintain Kodi and related packages.";
          shortName = "Kodi";
        };
      
        libretro = {
          members = [
            aanderse
            edwtjo
            MP2E
            thiagokokada
          ];
          scope = "Maintain Libretro, RetroArch and related packages.";
          shortName = "Libretro";
        };
      
        linux-kernel = {
          members = [
            TredwellGit
            ma27
            nequissimus
            qyliss
          ];
          scope = "Maintain the Linux kernel.";
          shortName = "Linux Kernel";
        };
      
        lumiguide = {
          # Verify additions by approval of an already existing member of the team.
          members = [
            roelvandijk
            lucus16
          ];
          scope = "Group registration for LumiGuide employees who collectively maintain packages.";
          shortName = "Lumiguide employees";
        };
      
        lua = {
          githubTeams = [
            "lua"
          ];
          scope = "Maintain the lua ecosystem.";
          shortName = "lua";
          enableFeatureFreezePing = true;
        };
      
        lumina = {
          members = [
            romildo
          ];
          githubTeams = [
            "lumina"
          ];
          scope = "Maintain lumina desktop environment and related packages.";
          shortName = "Lumina";
          enableFeatureFreezePing = true;
        };
      
        lxqt = {
          members = [
            romildo
          ];
          githubTeams = [
            "lxqt"
          ];
          scope = "Maintain LXQt desktop environment and related packages.";
          shortName = "LXQt";
          enableFeatureFreezePing = true;
        };
      
        marketing = {
          members = [
            garbas
            tomberek
          ];
          scope = "Marketing of Nix/NixOS/nixpkgs.";
          shortName = "Marketing";
          enableFeatureFreezePing = true;
        };
      
        mate = {
          members = [
            j03
            romildo
          ];
          scope = "Maintain Mate desktop environment and related packages.";
          shortName = "MATE";
          enableFeatureFreezePing = true;
        };
      
        matrix = {
          members = [
            ma27
            fadenb
            mguentner
            ekleog
            ralith
            dandellion
            sumnerevans
          ];
          scope = "Maintain the ecosystem around Matrix, a decentralized messenger.";
          shortName = "Matrix";
        };
      
        mobile = {
          members = [
            samueldr
          ];
          scope = "Maintain Mobile NixOS.";
          shortName = "Mobile";
        };
      
        nix = {
          members = [
            Profpatsch
            eelco
            grahamc
            pierron
          ];
          scope = "Maintain the Nix package manager.";
          shortName = "Nix/nix-cli ecosystem";
          enableFeatureFreezePing = true;
        };
      
        nixos-modules = {
          members = [
            ericson2314
            infinisil
            qyliss
            roberth
          ];
          scope = "Maintain nixpkgs module system internals.";
          shortName = "NixOS Modules / internals";
          enableFeatureFreezePing = true;
        };
      
        node = {
          members = [
            lilyinstarlight
            marsam
            winter
            yuka
          ];
          scope = "Maintain Node.js runtimes and build tooling.";
          shortName = "Node.js";
          enableFeatureFreezePing = true;
        };
      
        numtide = {
          members = [
            mic92
            flokli
            jfroche
            tazjin
            zimbatm
          ];
          scope = "Group registration for Numtide team members who collectively maintain packages.";
          shortName = "Numtide team";
        };
      
        openstack = {
          members = [
            emilytrau
            SuperSandro2000
          ];
          scope = "Maintain the ecosystem around OpenStack";
          shortName = "OpenStack";
        };
      
        pantheon = {
          members = [
            davidak
            bobby285271
          ];
          githubTeams = [
            "pantheon"
          ];
          scope = "Maintain Pantheon desktop environment and platform.";
          shortName = "Pantheon";
          enableFeatureFreezePing = true;
        };
      
        perl = {
          members = [
            sgo
          ];
          scope = "Maintain the Perl interpreter and Perl packages.";
          shortName = "Perl";
          enableFeatureFreezePing = true;
        };
      
        php = {
          members = [
            aanderse
            drupol
            etu
            globin
            ma27
            talyz
          ];
          githubTeams = [
            "php"
          ];
          scope = "Maintain PHP related packages and extensions.";
          shortName = "PHP";
          enableFeatureFreezePing = true;
        };
      
        podman = {
          members = [
            adisbladis
            saschagrunert
            vdemeester
            zowoq
          ];
          githubTeams = [
            "podman"
          ];
          scope = "Maintain Podman and CRI-O related packages and modules.";
          shortName = "Podman";
        };
      
        postgres = {
          members = [
            thoughtpolice
          ];
          scope = "Maintain the PostgreSQL package and plugins along with the NixOS module.";
          shortName = "PostgreSQL";
        };
      
        python = {
          members = [
            fridh
            hexa
            jonringer
          ];
          scope = "Maintain the Python interpreter and related packages.";
          shortName = "Python";
          enableFeatureFreezePing = true;
        };
      
        qt-kde = {
          members = [
            ttuegel
          ];
          githubTeams = [
            "qt-kde"
          ];
          scope = "Maintain the KDE desktop environment and Qt.";
          shortName = "Qt / KDE";
          enableFeatureFreezePing = true;
        };
      
        r = {
          members = [
            bcdarwin
            jbedo
          ];
          scope = "Maintain the R programming language and related packages.";
          shortName = "R";
          enableFeatureFreezePing = true;
        };
      
        redcodelabs = {
          members = [
            unrooted
            wr0belj
            wintrmvte
          ];
          scope = "Maintain Red Code Labs related packages and modules.";
          shortName = "Red Code Labs";
        };
      
        release = {
          members = [ ];
          githubTeams = [
            "nixos-release-managers"
          ];
          scope = "Manage the current nixpkgs/NixOS release.";
          shortName = "Release";
        };
      
        rocm = {
          members = [
            Madouura
            Flakebi
          ];
          githubTeams = [
            "rocm-maintainers"
          ];
          scope = "Maintain ROCm and related packages.";
          shortName = "ROCm";
        };
      
        ruby = {
          members = [
            marsam
          ];
          scope = "Maintain the Ruby interpreter and related packages.";
          shortName = "Ruby";
          enableFeatureFreezePing = true;
        };
      
        rust = {
          members = [
            andir
            lnl7
            mic92
            zowoq
          ];
          scope = "Maintain the Rust compiler toolchain and nixpkgs integration.";
          shortName = "Rust";
          enableFeatureFreezePing = true;
        };
      
        sage = {
          members = [
            timokau
            omasanori
            raskin
            collares
          ];
          scope = "Maintain SageMath and the dependencies that are likely to break it.";
          shortName = "SageMath";
        };
      
        sphinx = {
          members = [
            SuperSandro2000
          ];
          scope = "Maintain Sphinx related packages.";
          shortName = "Sphinx";
        };
      
        serokell = {
          # Verify additions by approval of an already existing member of the team.
          members = [
            balsoft
          ];
          scope = "Group registration for Serokell employees who collectively maintain packages.";
          shortName = "Serokell employees";
        };
      
        systemd = {
          members = [ ];
          githubTeams = [
            "systemd"
          ];
          scope = "Maintain systemd for NixOS.";
          shortName = "systemd";
          enableFeatureFreezePing = true;
        };
      
        tests = {
          members = [
            tfc
          ];
          scope = "Maintain the NixOS VM test runner.";
          shortName = "NixOS tests";
          enableFeatureFreezePing = true;
        };
      
        tts = {
          members = [
            hexa
            mic92
          ];
          scope = "coqui-ai TTS (formerly Mozilla TTS) and leaf packages";
          shortName = "coqui-ai TTS";
        };
      
        vim = {
          members = [
            figsoda
            jonringer
            softinio
            teto
          ];
          scope = "Maintain the vim and neovim text editors and related packages.";
          shortName = "Vim/Neovim";
        };
      
        xfce = {
          members = [
            romildo
            muscaln
          ];
          scope = "Maintain Xfce desktop environment and related packages.";
          shortName = "Xfce";
          enableFeatureFreezePing = true;
        };
      }
    );
    "/Users/jeffhykin/repos/nixpkgs/lib/meta.nix" = (# "/Users/jeffhykin/repos/nixpkgs/lib/meta.nix"
      /* Some functions for manipulating meta attributes, as well as the
         name attribute. */
      
      { lib }:
      
      rec {
      
      
        /* Add to or override the meta attributes of the given
           derivation.
      
           Example:
             addMetaAttrs {description = "Bla blah";} somePkg
        */
        addMetaAttrs = newAttrs: drv:
          drv // { meta = (drv.meta or {}) // newAttrs; };
      
      
        /* Disable Hydra builds of given derivation.
        */
        dontDistribute = drv: addMetaAttrs { hydraPlatforms = []; } drv;
      
      
        /* Change the symbolic name of a package for presentation purposes
           (i.e., so that nix-env users can tell them apart).
        */
        setName = name: drv: drv // {inherit name;};
      
      
        /* Like `setName`, but takes the previous name as an argument.
      
           Example:
             updateName (oldName: oldName + "-experimental") somePkg
        */
        updateName = updater: drv: drv // {name = updater (drv.name);};
      
      
        /* Append a suffix to the name of a package (before the version
           part). */
        appendToName = suffix: updateName (name:
          let x = builtins.parseDrvName name; in "${x.name}-${suffix}-${x.version}");
      
      
        /* Apply a function to each derivation and only to derivations in an attrset.
        */
        mapDerivationAttrset = f: set: lib.mapAttrs (name: pkg: if lib.isDerivation pkg then (f pkg) else pkg) set;
      
        /* Set the nix-env priority of the package.
        */
        setPrio = priority: addMetaAttrs { inherit priority; };
      
        /* Decrease the nix-env priority of the package, i.e., other
           versions/variants of the package will be preferred.
        */
        lowPrio = setPrio 10;
      
        /* Apply lowPrio to an attrset with derivations
        */
        lowPrioSet = set: mapDerivationAttrset lowPrio set;
      
      
        /* Increase the nix-env priority of the package, i.e., this
           version/variant of the package will be preferred.
        */
        hiPrio = setPrio (-10);
      
        /* Apply hiPrio to an attrset with derivations
        */
        hiPrioSet = set: mapDerivationAttrset hiPrio set;
      
      
        /* Check to see if a platform is matched by the given `meta.platforms`
           element.
      
           A `meta.platform` pattern is either
      
             1. (legacy) a system string.
      
             2. (modern) a pattern for the platform `parsed` field.
      
           We can inject these into a pattern for the whole of a structured platform,
           and then match that.
        */
        platformMatch = platform: elem: let
            pattern =
              if builtins.isString elem
              then { system = elem; }
              else { parsed = elem; };
          in lib.matchAttrs pattern platform;
      
        /* Check if a package is available on a given platform.
      
           A package is available on a platform if both
      
             1. One of `meta.platforms` pattern matches the given
                platform, or `meta.platforms` is not present.
      
             2. None of `meta.badPlatforms` pattern matches the given platform.
        */
        availableOn = platform: pkg:
          ((!pkg?meta.platforms) || lib.any (platformMatch platform) pkg.meta.platforms) &&
          lib.all (elem: !platformMatch platform elem) (pkg.meta.badPlatforms or []);
      
        /* Get the corresponding attribute in lib.licenses
           from the SPDX ID.
           For SPDX IDs, see
           https://spdx.org/licenses
      
           Type:
             getLicenseFromSpdxId :: str -> AttrSet
      
           Example:
             lib.getLicenseFromSpdxId "MIT" == lib.licenses.mit
             => true
             lib.getLicenseFromSpdxId "mIt" == lib.licenses.mit
             => true
             lib.getLicenseFromSpdxId "MY LICENSE"
             => trace: warning: getLicenseFromSpdxId: No license matches the given SPDX ID: MY LICENSE
             => { shortName = "MY LICENSE"; }
        */
        getLicenseFromSpdxId =
          let
            spdxLicenses = lib.mapAttrs (id: ls: assert lib.length ls == 1; builtins.head ls)
              (lib.groupBy (l: lib.toLower l.spdxId) (lib.filter (l: l ? spdxId) (lib.attrValues lib.licenses)));
          in licstr:
            spdxLicenses.${ lib.toLower licstr } or (
              lib.warn "getLicenseFromSpdxId: No license matches the given SPDX ID: ${licstr}"
              { shortName = licstr; }
            );
      
        /* Get the path to the main program of a derivation with either
           meta.mainProgram or pname or name
      
           Type: getExe :: derivation -> string
      
           Example:
             getExe pkgs.hello
             => "/nix/store/g124820p9hlv4lj8qplzxw1c44dxaw1k-hello-2.12/bin/hello"
             getExe pkgs.mustache-go
             => "/nix/store/am9ml4f4ywvivxnkiaqwr0hyxka1xjsf-mustache-go-1.3.0/bin/mustache"
        */
        getExe = x:
          "${lib.getBin x}/bin/${x.meta.mainProgram or (lib.getName x)}";
      }
    );
    "/Users/jeffhykin/repos/nixpkgs/lib/versions.nix" = (# "/Users/jeffhykin/repos/nixpkgs/lib/versions.nix"
      /* Version string functions. */
      { lib }:
      
      rec {
      
        /* Break a version string into its component parts.
      
           Example:
             splitVersion "1.2.3"
             => ["1" "2" "3"]
        */
        splitVersion = builtins.splitVersion or (lib.splitString ".");
      
        /* Get the major version string from a string.
      
          Example:
            major "1.2.3"
            => "1"
        */
        major = v: builtins.elemAt (splitVersion v) 0;
      
        /* Get the minor version string from a string.
      
          Example:
            minor "1.2.3"
            => "2"
        */
        minor = v: builtins.elemAt (splitVersion v) 1;
      
        /* Get the patch version string from a string.
      
          Example:
            patch "1.2.3"
            => "3"
        */
        patch = v: builtins.elemAt (splitVersion v) 2;
      
        /* Get string of the first two parts (major and minor)
           of a version string.
      
           Example:
             majorMinor "1.2.3"
             => "1.2"
        */
        majorMinor = v:
          builtins.concatStringsSep "."
          (lib.take 2 (splitVersion v));
      
        /* Pad a version string with zeros to match the given number of components.
      
           Example:
             pad 3 "1.2"
             => "1.2.0"
             pad 3 "1.3-rc1"
             => "1.3.0-rc1"
             pad 3 "1.2.3.4"
             => "1.2.3"
        */
        pad = n: version: let
          numericVersion = lib.head (lib.splitString "-" version);
          versionSuffix = lib.removePrefix numericVersion version;
        in lib.concatStringsSep "." (lib.take n (lib.splitVersion numericVersion ++ lib.genList (_: "0") n)) + versionSuffix;
      
      }
    );
    "/Users/jeffhykin/repos/nixpkgs/lib/modules.nix" = (# "/Users/jeffhykin/repos/nixpkgs/lib/modules.nix"
      { lib }:
      
      let
        inherit (lib)
          all
          any
          attrByPath
          attrNames
          catAttrs
          concatLists
          concatMap
          concatStringsSep
          elem
          filter
          foldl'
          getAttrFromPath
          head
          id
          imap1
          isAttrs
          isBool
          isFunction
          isList
          isString
          length
          mapAttrs
          mapAttrsToList
          mapAttrsRecursiveCond
          min
          optional
          optionalAttrs
          optionalString
          recursiveUpdate
          reverseList sort
          setAttrByPath
          types
          warnIf
          zipAttrsWith
          ;
        inherit (lib.options)
          isOption
          mkOption
          showDefs
          showFiles
          showOption
          unknownModule
          ;
      
        showDeclPrefix = loc: decl: prefix:
          " - option(s) with prefix `${showOption (loc ++ [prefix])}' in module `${decl._file}'";
        showRawDecls = loc: decls:
          concatStringsSep "\n"
            (sort (a: b: a < b)
              (concatMap
                (decl: map
                  (showDeclPrefix loc decl)
                  (attrNames decl.options)
                )
                decls
            ));
      
      in
      
      rec {
      
        /*
          Evaluate a set of modules.  The result is a set with the attributes:
      
            ‘options’: The nested set of all option declarations,
      
            ‘config’: The nested set of all option values.
      
            ‘type’: A module system type representing the module set as a submodule,
                  to be extended by configuration from the containing module set.
      
                  This is also available as the module argument ‘moduleType’.
      
            ‘extendModules’: A function similar to ‘evalModules’ but building on top
                  of the module set. Its arguments, ‘modules’ and ‘specialArgs’ are
                  added to the existing values.
      
                  Using ‘extendModules’ a few times has no performance impact as long
                  as you only reference the final ‘options’ and ‘config’.
                  If you do reference multiple ‘config’ (or ‘options’) from before and
                  after ‘extendModules’, performance is the same as with multiple
                  ‘evalModules’ invocations, because the new modules' ability to
                  override existing configuration fundamentally requires a new
                  fixpoint to be constructed.
      
                  This is also available as a module argument.
      
            ‘_module’: A portion of the configuration tree which is elided from
                  ‘config’. It contains some values that are mostly internal to the
                  module system implementation.
      
           !!! Please think twice before adding to this argument list! The more
           that is specified here instead of in the modules themselves the harder
           it is to transparently move a set of modules to be a submodule of another
           config (as the proper arguments need to be replicated at each call to
           evalModules) and the less declarative the module set is. */
        evalModules = evalModulesArgs@
                      { modules
                      , prefix ? []
                      , # This should only be used for special arguments that need to be evaluated
                        # when resolving module structure (like in imports). For everything else,
                        # there's _module.args. If specialArgs.modulesPath is defined it will be
                        # used as the base path for disabledModules.
                        specialArgs ? {}
                      , # This would be remove in the future, Prefer _module.args option instead.
                        args ? {}
                      , # This would be remove in the future, Prefer _module.check option instead.
                        check ? true
                      }:
          let
            withWarnings = x:
              lib.warnIf (evalModulesArgs?args) "The args argument to evalModules is deprecated. Please set config._module.args instead."
              lib.warnIf (evalModulesArgs?check) "The check argument to evalModules is deprecated. Please set config._module.check instead."
              x;
      
            legacyModules =
              optional (evalModulesArgs?args) {
                config = {
                  _module.args = args;
                };
              }
              ++ optional (evalModulesArgs?check) {
                config = {
                  _module.check = mkDefault check;
                };
              };
            regularModules = modules ++ legacyModules;
      
            # This internal module declare internal options under the `_module'
            # attribute.  These options are fragile, as they are used by the
            # module system to change the interpretation of modules.
            #
            # When extended with extendModules or moduleType, a fresh instance of
            # this module is used, to avoid conflicts and allow chaining of
            # extendModules.
            internalModule = rec {
              _file = "lib/modules.nix";
      
              key = _file;
      
              options = {
                _module.args = mkOption {
                  # Because things like `mkIf` are entirely useless for
                  # `_module.args` (because there's no way modules can check which
                  # arguments were passed), we'll use `lazyAttrsOf` which drops
                  # support for that, in turn it's lazy in its values. This means e.g.
                  # a `_module.args.pkgs = import (fetchTarball { ... }) {}` won't
                  # start a download when `pkgs` wasn't evaluated.
                  type = types.lazyAttrsOf types.raw;
                  # Only render documentation once at the root of the option tree,
                  # not for all individual submodules.
                  # Allow merging option decls to make this internal regardless.
                  ${if prefix == []
                    then null  # unset => visible
                    else "internal"} = true;
                  # TODO: hidden during the markdown transition to not expose downstream
                  # users of the docs infra to markdown if they're not ready for it.
                  # we don't make this visible conditionally because it can impact
                  # performance (https://github.com/NixOS/nixpkgs/pull/208407#issuecomment-1368246192)
                  visible = false;
                  # TODO: Change the type of this option to a submodule with a
                  # freeformType, so that individual arguments can be documented
                  # separately
                  description = lib.mdDoc ''
                    Additional arguments passed to each module in addition to ones
                    like `lib`, `config`,
                    and `pkgs`, `modulesPath`.
      
                    This option is also available to all submodules. Submodules do not
                    inherit args from their parent module, nor do they provide args to
                    their parent module or sibling submodules. The sole exception to
                    this is the argument `name` which is provided by
                    parent modules to a submodule and contains the attribute name
                    the submodule is bound to, or a unique generated name if it is
                    not bound to an attribute.
      
                    Some arguments are already passed by default, of which the
                    following *cannot* be changed with this option:
                    - {var}`lib`: The nixpkgs library.
                    - {var}`config`: The results of all options after merging the values from all modules together.
                    - {var}`options`: The options declared in all modules.
                    - {var}`specialArgs`: The `specialArgs` argument passed to `evalModules`.
                    - All attributes of {var}`specialArgs`
      
                      Whereas option values can generally depend on other option values
                      thanks to laziness, this does not apply to `imports`, which
                      must be computed statically before anything else.
      
                      For this reason, callers of the module system can provide `specialArgs`
                      which are available during import resolution.
      
                      For NixOS, `specialArgs` includes
                      {var}`modulesPath`, which allows you to import
                      extra modules from the nixpkgs package tree without having to
                      somehow make the module aware of the location of the
                      `nixpkgs` or NixOS directories.
                      ```
                      { modulesPath, ... }: {
                        imports = [
                          (modulesPath + "/profiles/minimal.nix")
                        ];
                      }
                      ```
      
                    For NixOS, the default value for this option includes at least this argument:
                    - {var}`pkgs`: The nixpkgs package set according to
                      the {option}`nixpkgs.pkgs` option.
                  '';
                };
      
                _module.check = mkOption {
                  type = types.bool;
                  internal = true;
                  default = true;
                  description = lib.mdDoc "Whether to check whether all option definitions have matching declarations.";
                };
      
                _module.freeformType = mkOption {
                  type = types.nullOr types.optionType;
                  internal = true;
                  default = null;
                  description = lib.mdDoc ''
                    If set, merge all definitions that don't have an associated option
                    together using this type. The result then gets combined with the
                    values of all declared options to produce the final `
                    config` value.
      
                    If this is `null`, definitions without an option
                    will throw an error unless {option}`_module.check` is
                    turned off.
                  '';
                };
      
                _module.specialArgs = mkOption {
                  readOnly = true;
                  internal = true;
                  description = lib.mdDoc ''
                    Externally provided module arguments that can't be modified from
                    within a configuration, but can be used in module imports.
                  '';
                };
              };
      
              config = {
                _module.args = {
                  inherit extendModules;
                  moduleType = type;
                };
                _module.specialArgs = specialArgs;
              };
            };
      
            merged =
              let collected = collectModules
                (specialArgs.modulesPath or "")
                (regularModules ++ [ internalModule ])
                ({ inherit lib options config specialArgs; } // specialArgs);
              in mergeModules prefix (reverseList collected);
      
            options = merged.matchedOptions;
      
            config =
              let
      
                # For definitions that have an associated option
                declaredConfig = mapAttrsRecursiveCond (v: ! isOption v) (_: v: v.value) options;
      
                # If freeformType is set, this is for definitions that don't have an associated option
                freeformConfig =
                  let
                    defs = map (def: {
                      file = def.file;
                      value = setAttrByPath def.prefix def.value;
                    }) merged.unmatchedDefns;
                  in if defs == [] then {}
                  else declaredConfig._module.freeformType.merge prefix defs;
      
              in if declaredConfig._module.freeformType == null then declaredConfig
                # Because all definitions that had an associated option ended in
                # declaredConfig, freeformConfig can only contain the non-option
                # paths, meaning recursiveUpdate will never override any value
                else recursiveUpdate freeformConfig declaredConfig;
      
            checkUnmatched =
              if config._module.check && config._module.freeformType == null && merged.unmatchedDefns != [] then
                let
                  firstDef = head merged.unmatchedDefns;
                  baseMsg =
                    let
                      optText = showOption (prefix ++ firstDef.prefix);
                      defText =
                        builtins.addErrorContext
                          "while evaluating the error message for definitions for `${optText}', which is an option that does not exist"
                          (builtins.addErrorContext
                            "while evaluating a definition from `${firstDef.file}'"
                            ( showDefs [ firstDef ])
                          );
                    in
                      "The option `${optText}' does not exist. Definition values:${defText}";
                in
                  if attrNames options == [ "_module" ]
                    then
                      let
                        optionName = showOption prefix;
                      in
                        if optionName == ""
                          then throw ''
                            ${baseMsg}
      
                            It seems as if you're trying to declare an option by placing it into `config' rather than `options'!
                          ''
                        else
                          throw ''
                            ${baseMsg}
      
                            However there are no options defined in `${showOption prefix}'. Are you sure you've
                            declared your options properly? This can happen if you e.g. declared your options in `types.submodule'
                            under `config' rather than `options'.
                          ''
                  else throw baseMsg
              else null;
      
            checked = builtins.seq checkUnmatched;
      
            extendModules = extendArgs@{
              modules ? [],
              specialArgs ? {},
              prefix ? [],
              }:
                evalModules (evalModulesArgs // {
                  modules = regularModules ++ modules;
                  specialArgs = evalModulesArgs.specialArgs or {} // specialArgs;
                  prefix = extendArgs.prefix or evalModulesArgs.prefix or [];
                });
      
            type = lib.types.submoduleWith {
              inherit modules specialArgs;
            };
      
            result = withWarnings {
              options = checked options;
              config = checked (removeAttrs config [ "_module" ]);
              _module = checked (config._module);
              inherit extendModules type;
            };
          in result;
      
        # collectModules :: (modulesPath: String) -> (modules: [ Module ]) -> (args: Attrs) -> [ Module ]
        #
        # Collects all modules recursively through `import` statements, filtering out
        # all modules in disabledModules.
        collectModules = let
      
            # Like unifyModuleSyntax, but also imports paths and calls functions if necessary
            loadModule = args: fallbackFile: fallbackKey: m:
              if isFunction m || isAttrs m then
                unifyModuleSyntax fallbackFile fallbackKey (applyModuleArgsIfFunction fallbackKey m args)
              else if isList m then
                let defs = [{ file = fallbackFile; value = m; }]; in
                throw "Module imports can't be nested lists. Perhaps you meant to remove one level of lists? Definitions: ${showDefs defs}"
              else unifyModuleSyntax (toString m) (toString m) (applyModuleArgsIfFunction (toString m) (import m) args);
      
            /*
            Collects all modules recursively into the form
      
              {
                disabled = [ <list of disabled modules> ];
                # All modules of the main module list
                modules = [
                  {
                    key = <key1>;
                    module = <module for key1>;
                    # All modules imported by the module for key1
                    modules = [
                      {
                        key = <key1-1>;
                        module = <module for key1-1>;
                        # All modules imported by the module for key1-1
                        modules = [ ... ];
                      }
                      ...
                    ];
                  }
                  ...
                ];
              }
            */
            collectStructuredModules =
              let
                collectResults = modules: {
                  disabled = concatLists (catAttrs "disabled" modules);
                  inherit modules;
                };
              in parentFile: parentKey: initialModules: args: collectResults (imap1 (n: x:
                let
                  module = loadModule args parentFile "${parentKey}:anon-${toString n}" x;
                  collectedImports = collectStructuredModules module._file module.key module.imports args;
                in {
                  key = module.key;
                  module = module;
                  modules = collectedImports.modules;
                  disabled = module.disabledModules ++ collectedImports.disabled;
                }) initialModules);
      
            # filterModules :: String -> { disabled, modules } -> [ Module ]
            #
            # Filters a structure as emitted by collectStructuredModules by removing all disabled
            # modules recursively. It returns the final list of unique-by-key modules
            filterModules = modulesPath: { disabled, modules }:
              let
                moduleKey = m: if isString m && (builtins.substring 0 1 m != "/")
                  then toString modulesPath + "/" + m
                  else toString m;
                disabledKeys = map moduleKey disabled;
                keyFilter = filter (attrs: ! elem attrs.key disabledKeys);
              in map (attrs: attrs.module) (builtins.genericClosure {
                startSet = keyFilter modules;
                operator = attrs: keyFilter attrs.modules;
              });
      
          in modulesPath: initialModules: args:
            filterModules modulesPath (collectStructuredModules unknownModule "" initialModules args);
      
        /* Wrap a module with a default location for reporting errors. */
        setDefaultModuleLocation = file: m:
          { _file = file; imports = [ m ]; };
      
        /* Massage a module into canonical form, that is, a set consisting
           of ‘options’, ‘config’ and ‘imports’ attributes. */
        unifyModuleSyntax = file: key: m:
          let
            addMeta = config: if m ? meta
              then mkMerge [ config { meta = m.meta; } ]
              else config;
            addFreeformType = config: if m ? freeformType
              then mkMerge [ config { _module.freeformType = m.freeformType; } ]
              else config;
          in
          if m ? config || m ? options then
            let badAttrs = removeAttrs m ["_file" "key" "disabledModules" "imports" "options" "config" "meta" "freeformType"]; in
            if badAttrs != {} then
              throw "Module `${key}' has an unsupported attribute `${head (attrNames badAttrs)}'. This is caused by introducing a top-level `config' or `options' attribute. Add configuration attributes immediately on the top level instead, or move all of them (namely: ${toString (attrNames badAttrs)}) into the explicit `config' attribute."
            else
              { _file = toString m._file or file;
                key = toString m.key or key;
                disabledModules = m.disabledModules or [];
                imports = m.imports or [];
                options = m.options or {};
                config = addFreeformType (addMeta (m.config or {}));
              }
          else
            # shorthand syntax
            lib.throwIfNot (isAttrs m) "module ${file} (${key}) does not look like a module."
            { _file = toString m._file or file;
              key = toString m.key or key;
              disabledModules = m.disabledModules or [];
              imports = m.require or [] ++ m.imports or [];
              options = {};
              config = addFreeformType (removeAttrs m ["_file" "key" "disabledModules" "require" "imports" "freeformType"]);
            };
      
        applyModuleArgsIfFunction = key: f: args@{ config, options, lib, ... }: if isFunction f then
          let
            # Module arguments are resolved in a strict manner when attribute set
            # deconstruction is used.  As the arguments are now defined with the
            # config._module.args option, the strictness used on the attribute
            # set argument would cause an infinite loop, if the result of the
            # option is given as argument.
            #
            # To work-around the strictness issue on the deconstruction of the
            # attributes set argument, we create a new attribute set which is
            # constructed to satisfy the expected set of attributes.  Thus calling
            # a module will resolve strictly the attributes used as argument but
            # not their values.  The values are forwarding the result of the
            # evaluation of the option.
            context = name: ''while evaluating the module argument `${name}' in "${key}":'';
            extraArgs = builtins.mapAttrs (name: _:
              builtins.addErrorContext (context name)
                (args.${name} or config._module.args.${name})
            ) (lib.functionArgs f);
      
            # Note: we append in the opposite order such that we can add an error
            # context on the explicit arguments of "args" too. This update
            # operator is used to make the "args@{ ... }: with args.lib;" notation
            # works.
          in f (args // extraArgs)
        else
          f;
      
        /* Merge a list of modules.  This will recurse over the option
           declarations in all modules, combining them into a single set.
           At the same time, for each option declaration, it will merge the
           corresponding option definitions in all machines, returning them
           in the ‘value’ attribute of each option.
      
           This returns a set like
             {
               # A recursive set of options along with their final values
               matchedOptions = {
                 foo = { _type = "option"; value = "option value of foo"; ... };
                 bar.baz = { _type = "option"; value = "option value of bar.baz"; ... };
                 ...
               };
               # A list of definitions that weren't matched by any option
               unmatchedDefns = [
                 { file = "file.nix"; prefix = [ "qux" ]; value = "qux"; }
                 ...
               ];
             }
        */
        mergeModules = prefix: modules:
          mergeModules' prefix modules
            (concatMap (m: map (config: { file = m._file; inherit config; }) (pushDownProperties m.config)) modules);
      
        mergeModules' = prefix: options: configs:
          let
           /* byName is like foldAttrs, but will look for attributes to merge in the
              specified attribute name.
      
              byName "foo" (module: value: ["module.hidden=${module.hidden},value=${value}"])
              [
                {
                  hidden="baz";
                  foo={qux="bar"; gla="flop";};
                }
                {
                  hidden="fli";
                  foo={qux="gne"; gli="flip";};
                }
              ]
              ===>
              {
                gla = [ "module.hidden=baz,value=flop" ];
                gli = [ "module.hidden=fli,value=flip" ];
                qux = [ "module.hidden=baz,value=bar" "module.hidden=fli,value=gne" ];
              }
            */
            byName = attr: f: modules:
              zipAttrsWith (n: concatLists)
                (map (module: let subtree = module.${attr}; in
                    if !(builtins.isAttrs subtree) then
                      throw ''
                        You're trying to declare a value of type `${builtins.typeOf subtree}'
                        rather than an attribute-set for the option
                        `${builtins.concatStringsSep "." prefix}'!
      
                        This usually happens if `${builtins.concatStringsSep "." prefix}' has option
                        definitions inside that are not matched. Please check how to properly define
                        this option by e.g. referring to `man 5 configuration.nix'!
                      ''
                    else
                      mapAttrs (n: f module) subtree
                    ) modules);
            # an attrset 'name' => list of submodules that declare ‘name’.
            declsByName = byName "options" (module: option:
                [{ inherit (module) _file; options = option; }]
              ) options;
            # an attrset 'name' => list of submodules that define ‘name’.
            defnsByName = byName "config" (module: value:
                map (config: { inherit (module) file; inherit config; }) (pushDownProperties value)
              ) configs;
            # extract the definitions for each loc
            defnsByName' = byName "config" (module: value:
                [{ inherit (module) file; inherit value; }]
              ) configs;
      
            # Convert an option tree decl to a submodule option decl
            optionTreeToOption = decl:
              if isOption decl.options
              then decl
              else decl // {
                  options = mkOption {
                    type = types.submoduleWith {
                      modules = [ { options = decl.options; } ];
                      # `null` is not intended for use by modules. It is an internal
                      # value that means "whatever the user has declared elsewhere".
                      # This might become obsolete with https://github.com/NixOS/nixpkgs/issues/162398
                      shorthandOnlyDefinesConfig = null;
                    };
                  };
                };
      
            resultsByName = mapAttrs (name: decls:
              # We're descending into attribute ‘name’.
              let
                loc = prefix ++ [name];
                defns = defnsByName.${name} or [];
                defns' = defnsByName'.${name} or [];
                optionDecls = filter (m: isOption m.options) decls;
              in
                if length optionDecls == length decls then
                  let opt = fixupOptionType loc (mergeOptionDecls loc decls);
                  in {
                    matchedOptions = evalOptionValue loc opt defns';
                    unmatchedDefns = [];
                  }
                else if optionDecls != [] then
                    if all (x: x.options.type.name == "submodule") optionDecls
                    # Raw options can only be merged into submodules. Merging into
                    # attrsets might be nice, but ambiguous. Suppose we have
                    # attrset as a `attrsOf submodule`. User declares option
                    # attrset.foo.bar, this could mean:
                    #  a. option `bar` is only available in `attrset.foo`
                    #  b. option `foo.bar` is available in all `attrset.*`
                    #  c. reject and require "<name>" as a reminder that it behaves like (b).
                    #  d. magically combine (a) and (c).
                    # All of the above are merely syntax sugar though.
                    then
                      let opt = fixupOptionType loc (mergeOptionDecls loc (map optionTreeToOption decls));
                      in {
                        matchedOptions = evalOptionValue loc opt defns';
                        unmatchedDefns = [];
                      }
                    else
                      let
                        nonOptions = filter (m: !isOption m.options) decls;
                      in
                      throw "The option `${showOption loc}' in module `${(lib.head optionDecls)._file}' would be a parent of the following options, but its type `${(lib.head optionDecls).options.type.description or "<no description>"}' does not support nested options.\n${
                        showRawDecls loc nonOptions
                      }"
                else
                  mergeModules' loc decls defns) declsByName;
      
            matchedOptions = mapAttrs (n: v: v.matchedOptions) resultsByName;
      
            # an attrset 'name' => list of unmatched definitions for 'name'
            unmatchedDefnsByName =
              # Propagate all unmatched definitions from nested option sets
              mapAttrs (n: v: v.unmatchedDefns) resultsByName
              # Plus the definitions for the current prefix that don't have a matching option
              // removeAttrs defnsByName' (attrNames matchedOptions);
          in {
            inherit matchedOptions;
      
            # Transforms unmatchedDefnsByName into a list of definitions
            unmatchedDefns =
              if configs == []
              then
                # When no config values exist, there can be no unmatched config, so
                # we short circuit and avoid evaluating more _options_ than necessary.
                []
              else
                concatLists (mapAttrsToList (name: defs:
                  map (def: def // {
                    # Set this so we know when the definition first left unmatched territory
                    prefix = [name] ++ (def.prefix or []);
                  }) defs
                ) unmatchedDefnsByName);
          };
      
        /* Merge multiple option declarations into a single declaration.  In
           general, there should be only one declaration of each option.
           The exception is the ‘options’ attribute, which specifies
           sub-options.  These can be specified multiple times to allow one
           module to add sub-options to an option declared somewhere else
           (e.g. multiple modules define sub-options for ‘fileSystems’).
      
           'loc' is the list of attribute names where the option is located.
      
           'opts' is a list of modules.  Each module has an options attribute which
           correspond to the definition of 'loc' in 'opt.file'. */
        mergeOptionDecls =
         loc: opts:
          foldl' (res: opt:
            let t  = res.type;
                t' = opt.options.type;
                mergedType = t.typeMerge t'.functor;
                typesMergeable = mergedType != null;
                typeSet = if (bothHave "type") && typesMergeable
                             then { type = mergedType; }
                             else {};
                bothHave = k: opt.options ? ${k} && res ? ${k};
            in
            if bothHave "default" ||
               bothHave "example" ||
               bothHave "description" ||
               bothHave "apply" ||
               (bothHave "type" && (! typesMergeable))
            then
              throw "The option `${showOption loc}' in `${opt._file}' is already declared in ${showFiles res.declarations}."
            else
              let
                getSubModules = opt.options.type.getSubModules or null;
                submodules =
                  if getSubModules != null then map (setDefaultModuleLocation opt._file) getSubModules ++ res.options
                  else res.options;
              in opt.options // res //
                { declarations = res.declarations ++ [opt._file];
                  options = submodules;
                } // typeSet
          ) { inherit loc; declarations = []; options = []; } opts;
      
        /* Merge all the definitions of an option to produce the final
           config value. */
        evalOptionValue = loc: opt: defs:
          let
            # Add in the default value for this option, if any.
            defs' =
                (optional (opt ? default)
                  { file = head opt.declarations; value = mkOptionDefault opt.default; }) ++ defs;
      
            # Handle properties, check types, and merge everything together.
            res =
              if opt.readOnly or false && length defs' > 1 then
                let
                  # For a better error message, evaluate all readOnly definitions as
                  # if they were the only definition.
                  separateDefs = map (def: def // {
                    value = (mergeDefinitions loc opt.type [ def ]).mergedValue;
                  }) defs';
                in throw "The option `${showOption loc}' is read-only, but it's set multiple times. Definition values:${showDefs separateDefs}"
              else
                mergeDefinitions loc opt.type defs';
      
            # Apply the 'apply' function to the merged value. This allows options to
            # yield a value computed from the definitions
            value = if opt ? apply then opt.apply res.mergedValue else res.mergedValue;
      
            warnDeprecation =
              warnIf (opt.type.deprecationMessage != null)
                "The type `types.${opt.type.name}' of option `${showOption loc}' defined in ${showFiles opt.declarations} is deprecated. ${opt.type.deprecationMessage}";
      
          in warnDeprecation opt //
            { value = builtins.addErrorContext "while evaluating the option `${showOption loc}':" value;
              inherit (res.defsFinal') highestPrio;
              definitions = map (def: def.value) res.defsFinal;
              files = map (def: def.file) res.defsFinal;
              definitionsWithLocations = res.defsFinal;
              inherit (res) isDefined;
              # This allows options to be correctly displayed using `${options.path.to.it}`
              __toString = _: showOption loc;
            };
      
        # Merge definitions of a value of a given type.
        mergeDefinitions = loc: type: defs: rec {
          defsFinal' =
            let
              # Process mkMerge and mkIf properties.
              defs' = concatMap (m:
                map (value: { inherit (m) file; inherit value; }) (builtins.addErrorContext "while evaluating definitions from `${m.file}':" (dischargeProperties m.value))
              ) defs;
      
              # Process mkOverride properties.
              defs'' = filterOverrides' defs';
      
              # Sort mkOrder properties.
              defs''' =
                # Avoid sorting if we don't have to.
                if any (def: def.value._type or "" == "order") defs''.values
                then sortProperties defs''.values
                else defs''.values;
            in {
              values = defs''';
              inherit (defs'') highestPrio;
            };
          defsFinal = defsFinal'.values;
      
          # Type-check the remaining definitions, and merge them. Or throw if no definitions.
          mergedValue =
            if isDefined then
              if all (def: type.check def.value) defsFinal then type.merge loc defsFinal
              else let allInvalid = filter (def: ! type.check def.value) defsFinal;
              in throw "A definition for option `${showOption loc}' is not of type `${type.description}'. Definition values:${showDefs allInvalid}"
            else
              # (nixos-option detects this specific error message and gives it special
              # handling.  If changed here, please change it there too.)
              throw "The option `${showOption loc}' is used but not defined.";
      
          isDefined = defsFinal != [];
      
          optionalValue =
            if isDefined then { value = mergedValue; }
            else {};
        };
      
        /* Given a config set, expand mkMerge properties, and push down the
           other properties into the children.  The result is a list of
           config sets that do not have properties at top-level.  For
           example,
      
             mkMerge [ { boot = set1; } (mkIf cond { boot = set2; services = set3; }) ]
      
           is transformed into
      
             [ { boot = set1; } { boot = mkIf cond set2; services = mkIf cond set3; } ].
      
           This transform is the critical step that allows mkIf conditions
           to refer to the full configuration without creating an infinite
           recursion.
        */
        pushDownProperties = cfg:
          if cfg._type or "" == "merge" then
            concatMap pushDownProperties cfg.contents
          else if cfg._type or "" == "if" then
            map (mapAttrs (n: v: mkIf cfg.condition v)) (pushDownProperties cfg.content)
          else if cfg._type or "" == "override" then
            map (mapAttrs (n: v: mkOverride cfg.priority v)) (pushDownProperties cfg.content)
          else # FIXME: handle mkOrder?
            [ cfg ];
      
        /* Given a config value, expand mkMerge properties, and discharge
           any mkIf conditions.  That is, this is the place where mkIf
           conditions are actually evaluated.  The result is a list of
           config values.  For example, ‘mkIf false x’ yields ‘[]’,
           ‘mkIf true x’ yields ‘[x]’, and
      
             mkMerge [ 1 (mkIf true 2) (mkIf true (mkIf false 3)) ]
      
           yields ‘[ 1 2 ]’.
        */
        dischargeProperties = def:
          if def._type or "" == "merge" then
            concatMap dischargeProperties def.contents
          else if def._type or "" == "if" then
            if isBool def.condition then
              if def.condition then
                dischargeProperties def.content
              else
                [ ]
            else
              throw "‘mkIf’ called with a non-Boolean condition"
          else
            [ def ];
      
        /* Given a list of config values, process the mkOverride properties,
           that is, return the values that have the highest (that is,
           numerically lowest) priority, and strip the mkOverride
           properties.  For example,
      
             [ { file = "/1"; value = mkOverride 10 "a"; }
               { file = "/2"; value = mkOverride 20 "b"; }
               { file = "/3"; value = "z"; }
               { file = "/4"; value = mkOverride 10 "d"; }
             ]
      
           yields
      
             [ { file = "/1"; value = "a"; }
               { file = "/4"; value = "d"; }
             ]
      
           Note that "z" has the default priority 100.
        */
        filterOverrides = defs: (filterOverrides' defs).values;
      
        filterOverrides' = defs:
          let
            getPrio = def: if def.value._type or "" == "override" then def.value.priority else defaultOverridePriority;
            highestPrio = foldl' (prio: def: min (getPrio def) prio) 9999 defs;
            strip = def: if def.value._type or "" == "override" then def // { value = def.value.content; } else def;
          in {
            values = concatMap (def: if getPrio def == highestPrio then [(strip def)] else []) defs;
            inherit highestPrio;
          };
      
        /* Sort a list of properties.  The sort priority of a property is
           defaultOrderPriority by default, but can be overridden by wrapping the property
           using mkOrder. */
        sortProperties = defs:
          let
            strip = def:
              if def.value._type or "" == "order"
              then def // { value = def.value.content; inherit (def.value) priority; }
              else def;
            defs' = map strip defs;
            compare = a: b: (a.priority or defaultOrderPriority) < (b.priority or defaultOrderPriority);
          in sort compare defs';
      
        # This calls substSubModules, whose entire purpose is only to ensure that
        # option declarations in submodules have accurate position information.
        # TODO: Merge this into mergeOptionDecls
        fixupOptionType = loc: opt:
          if opt.type.getSubModules or null == null
          then opt // { type = opt.type or types.unspecified; }
          else opt // { type = opt.type.substSubModules opt.options; options = []; };
      
      
        /* Properties. */
      
        mkIf = condition: content:
          { _type = "if";
            inherit condition content;
          };
      
        mkAssert = assertion: message: content:
          mkIf
            (if assertion then true else throw "\nFailed assertion: ${message}")
            content;
      
        mkMerge = contents:
          { _type = "merge";
            inherit contents;
          };
      
        mkOverride = priority: content:
          { _type = "override";
            inherit priority content;
          };
      
        mkOptionDefault = mkOverride 1500; # priority of option defaults
        mkDefault = mkOverride 1000; # used in config sections of non-user modules to set a default
        defaultOverridePriority = 100;
        mkImageMediaOverride = mkOverride 60; # image media profiles can be derived by inclusion into host config, hence needing to override host config, but do allow user to mkForce
        mkForce = mkOverride 50;
        mkVMOverride = mkOverride 10; # used by ‘nixos-rebuild build-vm’
      
        defaultPriority = lib.warnIf (lib.isInOldestRelease 2305) "lib.modules.defaultPriority is deprecated, please use lib.modules.defaultOverridePriority instead." defaultOverridePriority;
      
        mkFixStrictness = lib.warn "lib.mkFixStrictness has no effect and will be removed. It returns its argument unmodified, so you can just remove any calls." id;
      
        mkOrder = priority: content:
          { _type = "order";
            inherit priority content;
          };
      
        mkBefore = mkOrder 500;
        defaultOrderPriority = 1000;
        mkAfter = mkOrder 1500;
      
        # Convenient property used to transfer all definitions and their
        # properties from one option to another. This property is useful for
        # renaming options, and also for including properties from another module
        # system, including sub-modules.
        #
        #   { config, options, ... }:
        #
        #   {
        #     # 'bar' might not always be defined in the current module-set.
        #     config.foo.enable = mkAliasDefinitions (options.bar.enable or {});
        #
        #     # 'barbaz' has to be defined in the current module-set.
        #     config.foobar.paths = mkAliasDefinitions options.barbaz.paths;
        #   }
        #
        # Note, this is different than taking the value of the option and using it
        # as a definition, as the new definition will not keep the mkOverride /
        # mkDefault properties of the previous option.
        #
        mkAliasDefinitions = mkAliasAndWrapDefinitions id;
        mkAliasAndWrapDefinitions = wrap: option:
          mkAliasIfDef option (wrap (mkMerge option.definitions));
      
        # Similar to mkAliasAndWrapDefinitions but copies over the priority from the
        # option as well.
        #
        # If a priority is not set, it assumes a priority of defaultOverridePriority.
        mkAliasAndWrapDefsWithPriority = wrap: option:
          let
            prio = option.highestPrio or defaultOverridePriority;
            defsWithPrio = map (mkOverride prio) option.definitions;
          in mkAliasIfDef option (wrap (mkMerge defsWithPrio));
      
        mkAliasIfDef = option:
          mkIf (isOption option && option.isDefined);
      
        /* Compatibility. */
        fixMergeModules = modules: args: evalModules { inherit modules args; check = false; };
      
      
        /* Return a module that causes a warning to be shown if the
           specified option is defined. For example,
      
             mkRemovedOptionModule [ "boot" "loader" "grub" "bootDevice" ] "<replacement instructions>"
      
           causes a assertion if the user defines boot.loader.grub.bootDevice.
      
           replacementInstructions is a string that provides instructions on
           how to achieve the same functionality without the removed option,
           or alternatively a reasoning why the functionality is not needed.
           replacementInstructions SHOULD be provided!
        */
        mkRemovedOptionModule = optionName: replacementInstructions:
          { options, ... }:
          { options = setAttrByPath optionName (mkOption {
              visible = false;
              apply = x: throw "The option `${showOption optionName}' can no longer be used since it's been removed. ${replacementInstructions}";
            });
            config.assertions =
              let opt = getAttrFromPath optionName options; in [{
                assertion = !opt.isDefined;
                message = ''
                  The option definition `${showOption optionName}' in ${showFiles opt.files} no longer has any effect; please remove it.
                  ${replacementInstructions}
                '';
              }];
          };
      
        /* Return a module that causes a warning to be shown if the
           specified "from" option is defined; the defined value is however
           forwarded to the "to" option. This can be used to rename options
           while providing backward compatibility. For example,
      
             mkRenamedOptionModule [ "boot" "copyKernels" ] [ "boot" "loader" "grub" "copyKernels" ]
      
           forwards any definitions of boot.copyKernels to
           boot.loader.grub.copyKernels while printing a warning.
      
           This also copies over the priority from the aliased option to the
           non-aliased option.
        */
        mkRenamedOptionModule = from: to: doRename {
          inherit from to;
          visible = false;
          warn = true;
          use = builtins.trace "Obsolete option `${showOption from}' is used. It was renamed to `${showOption to}'.";
        };
      
        mkRenamedOptionModuleWith = {
          /* Old option path as list of strings. */
          from,
          /* New option path as list of strings. */
          to,
      
          /*
            Release number of the first release that contains the rename, ignoring backports.
            Set it to the upcoming release, matching the nixpkgs/.version file.
          */
          sinceRelease,
      
        }: doRename {
          inherit from to;
          visible = false;
          warn = lib.isInOldestRelease sinceRelease;
          use = lib.warnIf (lib.isInOldestRelease sinceRelease)
            "Obsolete option `${showOption from}' is used. It was renamed to `${showOption to}'.";
        };
      
        /* Return a module that causes a warning to be shown if any of the "from"
           option is defined; the defined values can be used in the "mergeFn" to set
           the "to" value.
           This function can be used to merge multiple options into one that has a
           different type.
      
           "mergeFn" takes the module "config" as a parameter and must return a value
           of "to" option type.
      
             mkMergedOptionModule
               [ [ "a" "b" "c" ]
                 [ "d" "e" "f" ] ]
               [ "x" "y" "z" ]
               (config:
                 let value = p: getAttrFromPath p config;
                 in
                 if      (value [ "a" "b" "c" ]) == true then "foo"
                 else if (value [ "d" "e" "f" ]) == true then "bar"
                 else "baz")
      
           - options.a.b.c is a removed boolean option
           - options.d.e.f is a removed boolean option
           - options.x.y.z is a new str option that combines a.b.c and d.e.f
             functionality
      
           This show a warning if any a.b.c or d.e.f is set, and set the value of
           x.y.z to the result of the merge function
        */
        mkMergedOptionModule = from: to: mergeFn:
          { config, options, ... }:
          {
            options = foldl' recursiveUpdate {} (map (path: setAttrByPath path (mkOption {
              visible = false;
              # To use the value in mergeFn without triggering errors
              default = "_mkMergedOptionModule";
            })) from);
      
            config = {
              warnings = filter (x: x != "") (map (f:
                let val = getAttrFromPath f config;
                    opt = getAttrFromPath f options;
                in
                optionalString
                  (val != "_mkMergedOptionModule")
                  "The option `${showOption f}' defined in ${showFiles opt.files} has been changed to `${showOption to}' that has a different type. Please read `${showOption to}' documentation and update your configuration accordingly."
              ) from);
            } // setAttrByPath to (mkMerge
                   (optional
                     (any (f: (getAttrFromPath f config) != "_mkMergedOptionModule") from)
                     (mergeFn config)));
          };
      
        /* Single "from" version of mkMergedOptionModule.
           Return a module that causes a warning to be shown if the "from" option is
           defined; the defined value can be used in the "mergeFn" to set the "to"
           value.
           This function can be used to change an option into another that has a
           different type.
      
           "mergeFn" takes the module "config" as a parameter and must return a value of
           "to" option type.
      
             mkChangedOptionModule [ "a" "b" "c" ] [ "x" "y" "z" ]
               (config:
                 let value = getAttrFromPath [ "a" "b" "c" ] config;
                 in
                 if   value > 100 then "high"
                 else "normal")
      
           - options.a.b.c is a removed int option
           - options.x.y.z is a new str option that supersedes a.b.c
      
           This show a warning if a.b.c is set, and set the value of x.y.z to the
           result of the change function
        */
        mkChangedOptionModule = from: to: changeFn:
          mkMergedOptionModule [ from ] to changeFn;
      
        /* Like ‘mkRenamedOptionModule’, but doesn't show a warning. */
        mkAliasOptionModule = from: to: doRename {
          inherit from to;
          visible = true;
          warn = false;
          use = id;
        };
      
        /* Transitional version of mkAliasOptionModule that uses MD docs. */
        mkAliasOptionModuleMD = from: to: doRename {
          inherit from to;
          visible = true;
          warn = false;
          use = id;
          markdown = true;
        };
      
        /* mkDerivedConfig : Option a -> (a -> Definition b) -> Definition b
      
          Create config definitions with the same priority as the definition of another option.
          This should be used for option definitions where one option sets the value of another as a convenience.
          For instance a config file could be set with a `text` or `source` option, where text translates to a `source`
          value using `mkDerivedConfig options.text (pkgs.writeText "filename.conf")`.
      
          It takes care of setting the right priority using `mkOverride`.
        */
        # TODO: make the module system error message include information about `opt` in
        # error messages about conflicts. E.g. introduce a variation of `mkOverride` which
        # adds extra location context to the definition object. This will allow context to be added
        # to all messages that report option locations "this value was derived from <full option name>
        # which was defined in <locations>". It can provide a trace of options that contributed
        # to definitions.
        mkDerivedConfig = opt: f:
          mkOverride
            (opt.highestPrio or defaultOverridePriority)
            (f opt.value);
      
        doRename = { from, to, visible, warn, use, withPriority ? true, markdown ? false }:
          { config, options, ... }:
          let
            fromOpt = getAttrFromPath from options;
            toOf = attrByPath to
              (abort "Renaming error: option `${showOption to}' does not exist.");
            toType = let opt = attrByPath to {} options; in opt.type or (types.submodule {});
          in
          {
            options = setAttrByPath from (mkOption {
              inherit visible;
              description = if markdown
                then lib.mdDoc "Alias of {option}`${showOption to}`."
                else "Alias of <option>${showOption to}</option>.";
              apply = x: use (toOf config);
            } // optionalAttrs (toType != null) {
              type = toType;
            });
            config = mkMerge [
              (optionalAttrs (options ? warnings) {
                warnings = optional (warn && fromOpt.isDefined)
                  "The option `${showOption from}' defined in ${showFiles fromOpt.files} has been renamed to `${showOption to}'.";
              })
              (if withPriority
                then mkAliasAndWrapDefsWithPriority (setAttrByPath to) fromOpt
                else mkAliasAndWrapDefinitions (setAttrByPath to) fromOpt)
            ];
          };
      
        /* Use this function to import a JSON file as NixOS configuration.
      
           modules.importJSON :: path -> attrs
        */
        importJSON = file: {
          _file = file;
          config = lib.importJSON file;
        };
      
        /* Use this function to import a TOML file as NixOS configuration.
      
           modules.importTOML :: path -> attrs
        */
        importTOML = file: {
          _file = file;
          config = lib.importTOML file;
        };
      }
    );
    "/Users/jeffhykin/repos/nixpkgs/lib/options.nix" = (# "/Users/jeffhykin/repos/nixpkgs/lib/options.nix"
      # Nixpkgs/NixOS option handling.
      { lib }:
      
      let
        inherit (lib)
          all
          collect
          concatLists
          concatMap
          concatMapStringsSep
          filter
          foldl'
          head
          tail
          isAttrs
          isBool
          isDerivation
          isFunction
          isInt
          isList
          isString
          length
          mapAttrs
          optional
          optionals
          take
          ;
        inherit (lib.attrsets)
          attrByPath
          optionalAttrs
          ;
        inherit (lib.strings)
          concatMapStrings
          concatStringsSep
          ;
        inherit (lib.types)
          mkOptionType
          ;
      in
      rec {
      
        /* Returns true when the given argument is an option
      
           Type: isOption :: a -> bool
      
           Example:
             isOption 1             // => false
             isOption (mkOption {}) // => true
        */
        isOption = lib.isType "option";
      
        /* Creates an Option attribute set. mkOption accepts an attribute set with the following keys:
      
           All keys default to `null` when not given.
      
           Example:
             mkOption { }  // => { _type = "option"; }
             mkOption { default = "foo"; } // => { _type = "option"; default = "foo"; }
        */
        mkOption =
          {
          # Default value used when no definition is given in the configuration.
          default ? null,
          # Textual representation of the default, for the manual.
          defaultText ? null,
          # Example value used in the manual.
          example ? null,
          # String describing the option.
          description ? null,
          # Related packages used in the manual (see `genRelatedPackages` in ../nixos/lib/make-options-doc/default.nix).
          relatedPackages ? null,
          # Option type, providing type-checking and value merging.
          type ? null,
          # Function that converts the option value to something else.
          apply ? null,
          # Whether the option is for NixOS developers only.
          internal ? null,
          # Whether the option shows up in the manual. Default: true. Use false to hide the option and any sub-options from submodules. Use "shallow" to hide only sub-options.
          visible ? null,
          # Whether the option can be set only once
          readOnly ? null,
          } @ attrs:
          attrs // { _type = "option"; };
      
        /* Creates an Option attribute set for a boolean value option i.e an
           option to be toggled on or off:
      
           Example:
             mkEnableOption "foo"
             => { _type = "option"; default = false; description = "Whether to enable foo."; example = true; type = { ... }; }
        */
        mkEnableOption =
          # Name for the created option
          name: mkOption {
          default = false;
          example = true;
          description =
            if name ? _type && name._type == "mdDoc"
            then lib.mdDoc "Whether to enable ${name.text}."
            else "Whether to enable ${name}.";
          type = lib.types.bool;
        };
      
        /* Creates an Option attribute set for an option that specifies the
           package a module should use for some purpose.
      
           The package is specified as a list of strings representing its attribute path in nixpkgs.
      
           Because of this, you need to pass nixpkgs itself as the first argument.
      
           The second argument is the name of the option, used in the description "The <name> package to use.".
      
           You can also pass an example value, either a literal string or a package's attribute path.
      
           You can omit the default path if the name of the option is also attribute path in nixpkgs.
      
           Type: mkPackageOption :: pkgs -> string -> { default :: [string], example :: null | string | [string] } -> option
      
           Example:
             mkPackageOption pkgs "hello" { }
             => { _type = "option"; default = «derivation /nix/store/3r2vg51hlxj3cx5vscp0vkv60bqxkaq0-hello-2.10.drv»; defaultText = { ... }; description = "The hello package to use."; type = { ... }; }
      
           Example:
             mkPackageOption pkgs "GHC" {
               default = [ "ghc" ];
               example = "pkgs.haskell.packages.ghc92.ghc.withPackages (hkgs: [ hkgs.primes ])";
             }
             => { _type = "option"; default = «derivation /nix/store/jxx55cxsjrf8kyh3fp2ya17q99w7541r-ghc-8.10.7.drv»; defaultText = { ... }; description = "The GHC package to use."; example = { ... }; type = { ... }; }
        */
        mkPackageOption =
          # Package set (a specific version of nixpkgs)
          pkgs:
            # Name for the package, shown in option description
            name:
            { default ? [ name ], example ? null }:
            let default' = if !isList default then [ default ] else default;
            in mkOption {
              type = lib.types.package;
              description = "The ${name} package to use.";
              default = attrByPath default'
                (throw "${concatStringsSep "." default'} cannot be found in pkgs") pkgs;
              defaultText = literalExpression ("pkgs." + concatStringsSep "." default');
              ${if example != null then "example" else null} = literalExpression
                (if isList example then "pkgs." + concatStringsSep "." example else example);
            };
      
        /* Like mkPackageOption, but emit an mdDoc description instead of DocBook. */
        mkPackageOptionMD = args: name: extra:
          let option = mkPackageOption args name extra;
          in option // { description = lib.mdDoc option.description; };
      
        /* This option accepts anything, but it does not produce any result.
      
           This is useful for sharing a module across different module sets
           without having to implement similar features as long as the
           values of the options are not accessed. */
        mkSinkUndeclaredOptions = attrs: mkOption ({
          internal = true;
          visible = false;
          default = false;
          description = "Sink for option definitions.";
          type = mkOptionType {
            name = "sink";
            check = x: true;
            merge = loc: defs: false;
          };
          apply = x: throw "Option value is not readable because the option is not declared.";
        } // attrs);
      
        mergeDefaultOption = loc: defs:
          let list = getValues defs; in
          if length list == 1 then head list
          else if all isFunction list then x: mergeDefaultOption loc (map (f: f x) list)
          else if all isList list then concatLists list
          else if all isAttrs list then foldl' lib.mergeAttrs {} list
          else if all isBool list then foldl' lib.or false list
          else if all isString list then lib.concatStrings list
          else if all isInt list && all (x: x == head list) list then head list
          else throw "Cannot merge definitions of `${showOption loc}'. Definition values:${showDefs defs}";
      
        mergeOneOption = mergeUniqueOption { message = ""; };
      
        mergeUniqueOption = { message }: loc: defs:
          if length defs == 1
          then (head defs).value
          else assert length defs > 1;
            throw "The option `${showOption loc}' is defined multiple times.\n${message}\nDefinition values:${showDefs defs}";
      
        /* "Merge" option definitions by checking that they all have the same value. */
        mergeEqualOption = loc: defs:
          if defs == [] then abort "This case should never happen."
          # Return early if we only have one element
          # This also makes it work for functions, because the foldl' below would try
          # to compare the first element with itself, which is false for functions
          else if length defs == 1 then (head defs).value
          else (foldl' (first: def:
            if def.value != first.value then
              throw "The option `${showOption loc}' has conflicting definition values:${showDefs [ first def ]}"
            else
              first) (head defs) (tail defs)).value;
      
        /* Extracts values of all "value" keys of the given list.
      
           Type: getValues :: [ { value :: a } ] -> [a]
      
           Example:
             getValues [ { value = 1; } { value = 2; } ] // => [ 1 2 ]
             getValues [ ]                               // => [ ]
        */
        getValues = map (x: x.value);
      
        /* Extracts values of all "file" keys of the given list
      
           Type: getFiles :: [ { file :: a } ] -> [a]
      
           Example:
             getFiles [ { file = "file1"; } { file = "file2"; } ] // => [ "file1" "file2" ]
             getFiles [ ]                                         // => [ ]
        */
        getFiles = map (x: x.file);
      
        # Generate documentation template from the list of option declaration like
        # the set generated with filterOptionSets.
        optionAttrSetToDocList = optionAttrSetToDocList' [];
      
        optionAttrSetToDocList' = _: options:
          concatMap (opt:
            let
              name = showOption opt.loc;
              docOption = rec {
                loc = opt.loc;
                inherit name;
                description = opt.description or null;
                declarations = filter (x: x != unknownModule) opt.declarations;
                internal = opt.internal or false;
                visible =
                  if (opt?visible && opt.visible == "shallow")
                  then true
                  else opt.visible or true;
                readOnly = opt.readOnly or false;
                type = opt.type.description or "unspecified";
              }
              // optionalAttrs (opt ? example) {
                example =
                  builtins.addErrorContext "while evaluating the example of option `${name}`" (
                    renderOptionValue opt.example
                  );
              }
              // optionalAttrs (opt ? default) {
                default =
                  builtins.addErrorContext "while evaluating the default value of option `${name}`" (
                    renderOptionValue (opt.defaultText or opt.default)
                  );
              }
              // optionalAttrs (opt ? relatedPackages && opt.relatedPackages != null) { inherit (opt) relatedPackages; };
      
              subOptions =
                let ss = opt.type.getSubOptions opt.loc;
                in if ss != {} then optionAttrSetToDocList' opt.loc ss else [];
              subOptionsVisible = docOption.visible && opt.visible or null != "shallow";
            in
              # To find infinite recursion in NixOS option docs:
              # builtins.trace opt.loc
              [ docOption ] ++ optionals subOptionsVisible subOptions) (collect isOption options);
      
      
        /* This function recursively removes all derivation attributes from
           `x` except for the `name` attribute.
      
           This is to make the generation of `options.xml` much more
           efficient: the XML representation of derivations is very large
           (on the order of megabytes) and is not actually used by the
           manual generator.
      
           This function was made obsolete by renderOptionValue and is kept for
           compatibility with out-of-tree code.
        */
        scrubOptionValue = x:
          if isDerivation x then
            { type = "derivation"; drvPath = x.name; outPath = x.name; name = x.name; }
          else if isList x then map scrubOptionValue x
          else if isAttrs x then mapAttrs (n: v: scrubOptionValue v) (removeAttrs x ["_args"])
          else x;
      
      
        /* Ensures that the given option value (default or example) is a `_type`d string
           by rendering Nix values to `literalExpression`s.
        */
        renderOptionValue = v:
          if v ? _type && v ? text then v
          else literalExpression (lib.generators.toPretty {
            multiline = true;
            allowPrettyValues = true;
          } v);
      
      
        /* For use in the `defaultText` and `example` option attributes. Causes the
           given string to be rendered verbatim in the documentation as Nix code. This
           is necessary for complex values, e.g. functions, or values that depend on
           other values or packages.
        */
        literalExpression = text:
          if ! isString text then throw "literalExpression expects a string."
          else { _type = "literalExpression"; inherit text; };
      
        literalExample = lib.warn "literalExample is deprecated, use literalExpression instead, or use literalDocBook for a non-Nix description." literalExpression;
      
      
        /* For use in the `defaultText` and `example` option attributes. Causes the
           given DocBook text to be inserted verbatim in the documentation, for when
           a `literalExpression` would be too hard to read.
        */
        literalDocBook = text:
          if ! isString text then throw "literalDocBook expects a string."
          else
            lib.warnIf (lib.isInOldestRelease 2211)
              "literalDocBook is deprecated, use literalMD instead"
              { _type = "literalDocBook"; inherit text; };
      
        /* Transition marker for documentation that's already migrated to markdown
           syntax.
        */
        mdDoc = text:
          if ! isString text then throw "mdDoc expects a string."
          else { _type = "mdDoc"; inherit text; };
      
        /* For use in the `defaultText` and `example` option attributes. Causes the
           given MD text to be inserted verbatim in the documentation, for when
           a `literalExpression` would be too hard to read.
        */
        literalMD = text:
          if ! isString text then throw "literalMD expects a string."
          else { _type = "literalMD"; inherit text; };
      
        # Helper functions.
      
        /* Convert an option, described as a list of the option parts in to a
           safe, human readable version.
      
           Example:
             (showOption ["foo" "bar" "baz"]) == "foo.bar.baz"
             (showOption ["foo" "bar.baz" "tux"]) == "foo.bar.baz.tux"
      
           Placeholders will not be quoted as they are not actual values:
             (showOption ["foo" "*" "bar"]) == "foo.*.bar"
             (showOption ["foo" "<name>" "bar"]) == "foo.<name>.bar"
      
           Unlike attributes, options can also start with numbers:
             (showOption ["windowManager" "2bwm" "enable"]) == "windowManager.2bwm.enable"
        */
        showOption = parts: let
          escapeOptionPart = part:
            let
              # We assume that these are "special values" and not real configuration data.
              # If it is real configuration data, it is rendered incorrectly.
              specialIdentifiers = [
                "<name>"          # attrsOf (submodule {})
                "*"               # listOf (submodule {})
                "<function body>" # functionTo
              ];
            in if builtins.elem part specialIdentifiers
               then part
               else lib.strings.escapeNixIdentifier part;
          in (concatStringsSep ".") (map escapeOptionPart parts);
        showFiles = files: concatStringsSep " and " (map (f: "`${f}'") files);
      
        showDefs = defs: concatMapStrings (def:
          let
            # Pretty print the value for display, if successful
            prettyEval = builtins.tryEval
              (lib.generators.toPretty { }
                (lib.generators.withRecursion { depthLimit = 10; throwOnDepthLimit = false; } def.value));
            # Split it into its lines
            lines = filter (v: ! isList v) (builtins.split "\n" prettyEval.value);
            # Only display the first 5 lines, and indent them for better visibility
            value = concatStringsSep "\n    " (take 5 lines ++ optional (length lines > 5) "...");
            result =
              # Don't print any value if evaluating the value strictly fails
              if ! prettyEval.success then ""
              # Put it on a new line if it consists of multiple
              else if length lines > 1 then ":\n    " + value
              else ": " + value;
          in "\n- In `${def.file}'${result}"
        ) defs;
      
        showOptionWithDefLocs = opt: ''
            ${showOption opt.loc}, with values defined in:
            ${concatMapStringsSep "\n" (defFile: "  - ${defFile}") opt.files}
          '';
      
        unknownModule = "<unknown-file>";
      
      }
    );
    "/Users/jeffhykin/repos/nixpkgs/lib/types.nix" = (# "/Users/jeffhykin/repos/nixpkgs/lib/types.nix"
      # Definitions related to run-time type checking.  Used in particular
      # to type-check NixOS configurations.
      { lib }:
      
      let
        inherit (lib)
          elem
          flip
          isAttrs
          isBool
          isDerivation
          isFloat
          isFunction
          isInt
          isList
          isString
          isStorePath
          toDerivation
          toList
          ;
        inherit (lib.lists)
          all
          concatLists
          count
          elemAt
          filter
          foldl'
          head
          imap1
          last
          length
          tail
          ;
        inherit (lib.attrsets)
          attrNames
          filterAttrs
          hasAttr
          mapAttrs
          optionalAttrs
          zipAttrsWith
          ;
        inherit (lib.options)
          getFiles
          getValues
          mergeDefaultOption
          mergeEqualOption
          mergeOneOption
          mergeUniqueOption
          showFiles
          showOption
          ;
        inherit (lib.strings)
          concatMapStringsSep
          concatStringsSep
          escapeNixString
          hasInfix
          isStringLike
          ;
        inherit (lib.trivial)
          boolToString
          ;
      
        inherit (lib.modules)
          mergeDefinitions
          fixupOptionType
          mergeOptionDecls
          ;
        outer_types =
      rec {
        isType = type: x: (x._type or "") == type;
      
        setType = typeName: value: value // {
          _type = typeName;
        };
      
      
        # Default type merging function
        # takes two type functors and return the merged type
        defaultTypeMerge = f: f':
          let wrapped = f.wrapped.typeMerge f'.wrapped.functor;
              payload = f.binOp f.payload f'.payload;
          in
          # cannot merge different types
          if f.name != f'.name
             then null
          # simple types
          else if    (f.wrapped == null && f'.wrapped == null)
                  && (f.payload == null && f'.payload == null)
             then f.type
          # composed types
          else if (f.wrapped != null && f'.wrapped != null) && (wrapped != null)
             then f.type wrapped
          # value types
          else if (f.payload != null && f'.payload != null) && (payload != null)
             then f.type payload
          else null;
      
        # Default type functor
        defaultFunctor = name: {
          inherit name;
          type    = types.${name} or null;
          wrapped = null;
          payload = null;
          binOp   = a: b: null;
        };
      
        isOptionType = isType "option-type";
        mkOptionType =
          { # Human-readable representation of the type, should be equivalent to
            # the type function name.
            name
          , # Description of the type, defined recursively by embedding the wrapped type if any.
            description ? null
            # A hint for whether or not this description needs parentheses. Possible values:
            #  - "noun": a simple noun phrase such as "positive integer"
            #  - "conjunction": a phrase with a potentially ambiguous "or" connective.
            #  - "composite": a phrase with an "of" connective
            # See the `optionDescriptionPhrase` function.
          , descriptionClass ? null
          , # DO NOT USE WITHOUT KNOWING WHAT YOU ARE DOING!
            # Function applied to each definition that must return false when a definition
            # does not match the type. It should not check more than the root of the value,
            # because checking nested values reduces laziness, leading to unnecessary
            # infinite recursions in the module system.
            # Further checks of nested values should be performed by throwing in
            # the merge function.
            # Strict and deep type checking can be performed by calling lib.deepSeq on
            # the merged value.
            #
            # See https://github.com/NixOS/nixpkgs/pull/6794 that introduced this change,
            # https://github.com/NixOS/nixpkgs/pull/173568 and
            # https://github.com/NixOS/nixpkgs/pull/168295 that attempted to revert this,
            # https://github.com/NixOS/nixpkgs/issues/191124 and
            # https://github.com/NixOS/nixos-search/issues/391 for what happens if you ignore
            # this disclaimer.
            check ? (x: true)
          , # Merge a list of definitions together into a single value.
            # This function is called with two arguments: the location of
            # the option in the configuration as a list of strings
            # (e.g. ["boot" "loader "grub" "enable"]), and a list of
            # definition values and locations (e.g. [ { file = "/foo.nix";
            # value = 1; } { file = "/bar.nix"; value = 2 } ]).
            merge ? mergeDefaultOption
          , # Whether this type has a value representing nothingness. If it does,
            # this should be a value of the form { value = <the nothing value>; }
            # If it doesn't, this should be {}
            # This may be used when a value is required for `mkIf false`. This allows the extra laziness in e.g. `lazyAttrsOf`.
            emptyValue ? {}
          , # Return a flat list of sub-options.  Used to generate
            # documentation.
            getSubOptions ? prefix: {}
          , # List of modules if any, or null if none.
            getSubModules ? null
          , # Function for building the same option type with a different list of
            # modules.
            substSubModules ? m: null
          , # Function that merge type declarations.
            # internal, takes a functor as argument and returns the merged type.
            # returning null means the type is not mergeable
            typeMerge ? defaultTypeMerge functor
          , # The type functor.
            # internal, representation of the type as an attribute set.
            #   name: name of the type
            #   type: type function.
            #   wrapped: the type wrapped in case of compound types.
            #   payload: values of the type, two payloads of the same type must be
            #            combinable with the binOp binary operation.
            #   binOp: binary operation that merge two payloads of the same type.
            functor ? defaultFunctor name
          , # The deprecation message to display when this type is used by an option
            # If null, the type isn't deprecated
            deprecationMessage ? null
          , # The types that occur in the definition of this type. This is used to
            # issue deprecation warnings recursively. Can also be used to reuse
            # nested types
            nestedTypes ? {}
          }:
          { _type = "option-type";
            inherit
              name check merge emptyValue getSubOptions getSubModules substSubModules
              typeMerge functor deprecationMessage nestedTypes descriptionClass;
            description = if description == null then name else description;
          };
      
        # optionDescriptionPhrase :: (str -> bool) -> optionType -> str
        #
        # Helper function for producing unambiguous but readable natural language
        # descriptions of types.
        #
        # Parameters
        #
        #     optionDescriptionPhase unparenthesize optionType
        #
        # `unparenthesize`: A function from descriptionClass string to boolean.
        #   It must return true when the class of phrase will fit unambiguously into
        #   the description of the caller.
        #
        # `optionType`: The option type to parenthesize or not.
        #   The option whose description we're returning.
        #
        # Return value
        #
        # The description of the `optionType`, with parentheses if there may be an
        # ambiguity.
        optionDescriptionPhrase = unparenthesize: t:
          if unparenthesize (t.descriptionClass or null)
          then t.description
          else "(${t.description})";
      
        # When adding new types don't forget to document them in
        # nixos/doc/manual/development/option-types.xml!
        types = rec {
      
          raw = mkOptionType rec {
            name = "raw";
            description = "raw value";
            descriptionClass = "noun";
            check = value: true;
            merge = mergeOneOption;
          };
      
          anything = mkOptionType {
            name = "anything";
            description = "anything";
            descriptionClass = "noun";
            check = value: true;
            merge = loc: defs:
              let
                getType = value:
                  if isAttrs value && isStringLike value
                  then "stringCoercibleSet"
                  else builtins.typeOf value;
      
                # Returns the common type of all definitions, throws an error if they
                # don't have the same type
                commonType = foldl' (type: def:
                  if getType def.value == type
                  then type
                  else throw "The option `${showOption loc}' has conflicting option types in ${showFiles (getFiles defs)}"
                ) (getType (head defs).value) defs;
      
                mergeFunction = {
                  # Recursively merge attribute sets
                  set = (attrsOf anything).merge;
                  # Safe and deterministic behavior for lists is to only accept one definition
                  # listOf only used to apply mkIf and co.
                  list =
                    if length defs > 1
                    then throw "The option `${showOption loc}' has conflicting definitions, in ${showFiles (getFiles defs)}."
                    else (listOf anything).merge;
                  # This is the type of packages, only accept a single definition
                  stringCoercibleSet = mergeOneOption;
                  lambda = loc: defs: arg: anything.merge
                    (loc ++ [ "<function body>" ])
                    (map (def: {
                      file = def.file;
                      value = def.value arg;
                    }) defs);
                  # Otherwise fall back to only allowing all equal definitions
                }.${commonType} or mergeEqualOption;
              in mergeFunction loc defs;
          };
      
          unspecified = mkOptionType {
            name = "unspecified";
            description = "unspecified value";
            descriptionClass = "noun";
          };
      
          bool = mkOptionType {
            name = "bool";
            description = "boolean";
            descriptionClass = "noun";
            check = isBool;
            merge = mergeEqualOption;
          };
      
          int = mkOptionType {
            name = "int";
            description = "signed integer";
            descriptionClass = "noun";
            check = isInt;
            merge = mergeEqualOption;
          };
      
          # Specialized subdomains of int
          ints =
            let
              betweenDesc = lowest: highest:
                "${toString lowest} and ${toString highest} (both inclusive)";
              between = lowest: highest:
                assert lib.assertMsg (lowest <= highest)
                  "ints.between: lowest must be smaller than highest";
                addCheck int (x: x >= lowest && x <= highest) // {
                  name = "intBetween";
                  description = "integer between ${betweenDesc lowest highest}";
                };
              ign = lowest: highest: name: docStart:
                between lowest highest // {
                  inherit name;
                  description = docStart + "; between ${betweenDesc lowest highest}";
                };
              unsign = bit: range: ign 0 (range - 1)
                "unsignedInt${toString bit}" "${toString bit} bit unsigned integer";
              sign = bit: range: ign (0 - (range / 2)) (range / 2 - 1)
                "signedInt${toString bit}" "${toString bit} bit signed integer";
      
            in {
              /* An int with a fixed range.
              *
              * Example:
              *   (ints.between 0 100).check (-1)
              *   => false
              *   (ints.between 0 100).check (101)
              *   => false
              *   (ints.between 0 0).check 0
              *   => true
              */
              inherit between;
      
              unsigned = addCheck types.int (x: x >= 0) // {
                name = "unsignedInt";
                description = "unsigned integer, meaning >=0";
              };
              positive = addCheck types.int (x: x > 0) // {
                name = "positiveInt";
                description = "positive integer, meaning >0";
              };
              u8 = unsign 8 256;
              u16 = unsign 16 65536;
              # the biggest int Nix accepts is 2^63 - 1 (9223372036854775808)
              # the smallest int Nix accepts is -2^63 (-9223372036854775807)
              u32 = unsign 32 4294967296;
              # u64 = unsign 64 18446744073709551616;
      
              s8 = sign 8 256;
              s16 = sign 16 65536;
              s32 = sign 32 4294967296;
            };
      
          # Alias of u16 for a port number
          port = ints.u16;
      
          float = mkOptionType {
            name = "float";
            description = "floating point number";
            descriptionClass = "noun";
            check = isFloat;
            merge = mergeEqualOption;
          };
      
          number = either int float;
      
          numbers = let
            betweenDesc = lowest: highest:
              "${builtins.toJSON lowest} and ${builtins.toJSON highest} (both inclusive)";
          in {
            between = lowest: highest:
              assert lib.assertMsg (lowest <= highest)
                "numbers.between: lowest must be smaller than highest";
              addCheck number (x: x >= lowest && x <= highest) // {
                name = "numberBetween";
                description = "integer or floating point number between ${betweenDesc lowest highest}";
              };
      
            nonnegative = addCheck number (x: x >= 0) // {
              name = "numberNonnegative";
              description = "nonnegative integer or floating point number, meaning >=0";
            };
            positive = addCheck number (x: x > 0) // {
              name = "numberPositive";
              description = "positive integer or floating point number, meaning >0";
            };
          };
      
          str = mkOptionType {
            name = "str";
            description = "string";
            descriptionClass = "noun";
            check = isString;
            merge = mergeEqualOption;
          };
      
          nonEmptyStr = mkOptionType {
            name = "nonEmptyStr";
            description = "non-empty string";
            descriptionClass = "noun";
            check = x: str.check x && builtins.match "[ \t\n]*" x == null;
            inherit (str) merge;
          };
      
          # Allow a newline character at the end and trim it in the merge function.
          singleLineStr =
            let
              inherit (strMatching "[^\n\r]*\n?") check merge;
            in
            mkOptionType {
              name = "singleLineStr";
              description = "(optionally newline-terminated) single-line string";
              descriptionClass = "noun";
              inherit check;
              merge = loc: defs:
                lib.removeSuffix "\n" (merge loc defs);
            };
      
          strMatching = pattern: mkOptionType {
            name = "strMatching ${escapeNixString pattern}";
            description = "string matching the pattern ${pattern}";
            descriptionClass = "noun";
            check = x: str.check x && builtins.match pattern x != null;
            inherit (str) merge;
          };
      
          # Merge multiple definitions by concatenating them (with the given
          # separator between the values).
          separatedString = sep: mkOptionType rec {
            name = "separatedString";
            description = if sep == ""
              then "Concatenated string" # for types.string.
              else "strings concatenated with ${builtins.toJSON sep}"
            ;
            descriptionClass = "noun";
            check = isString;
            merge = loc: defs: concatStringsSep sep (getValues defs);
            functor = (defaultFunctor name) // {
              payload = sep;
              binOp = sepLhs: sepRhs:
                if sepLhs == sepRhs then sepLhs
                else null;
            };
          };
      
          lines = separatedString "\n";
          commas = separatedString ",";
          envVar = separatedString ":";
      
          # Deprecated; should not be used because it quietly concatenates
          # strings, which is usually not what you want.
          string = separatedString "" // {
            name = "string";
            deprecationMessage = "See https://github.com/NixOS/nixpkgs/pull/66346 for better alternative types.";
          };
      
          passwdEntry = entryType: addCheck entryType (str: !(hasInfix ":" str || hasInfix "\n" str)) // {
            name = "passwdEntry ${entryType.name}";
            description = "${optionDescriptionPhrase (class: class == "noun") entryType}, not containing newlines or colons";
          };
      
          attrs = mkOptionType {
            name = "attrs";
            description = "attribute set";
            check = isAttrs;
            merge = loc: foldl' (res: def: res // def.value) {};
            emptyValue = { value = {}; };
          };
      
          # A package is a top-level store path (/nix/store/hash-name). This includes:
          # - derivations
          # - more generally, attribute sets with an `outPath` or `__toString` attribute
          #   pointing to a store path, e.g. flake inputs
          # - strings with context, e.g. "${pkgs.foo}" or (toString pkgs.foo)
          # - hardcoded store path literals (/nix/store/hash-foo) or strings without context
          #   ("/nix/store/hash-foo"). These get a context added to them using builtins.storePath.
          package = mkOptionType {
            name = "package";
            descriptionClass = "noun";
            check = x: isDerivation x || isStorePath x;
            merge = loc: defs:
              let res = mergeOneOption loc defs;
              in if builtins.isPath res || (builtins.isString res && ! builtins.hasContext res)
                then toDerivation res
                else res;
          };
      
          shellPackage = package // {
            check = x: isDerivation x && hasAttr "shellPath" x;
          };
      
          path = mkOptionType {
            name = "path";
            descriptionClass = "noun";
            check = x: isStringLike x && builtins.substring 0 1 (toString x) == "/";
            merge = mergeEqualOption;
          };
      
          listOf = elemType: mkOptionType rec {
            name = "listOf";
            description = "list of ${optionDescriptionPhrase (class: class == "noun" || class == "composite") elemType}";
            descriptionClass = "composite";
            check = isList;
            merge = loc: defs:
              map (x: x.value) (filter (x: x ? value) (concatLists (imap1 (n: def:
                imap1 (m: def':
                  (mergeDefinitions
                    (loc ++ ["[definition ${toString n}-entry ${toString m}]"])
                    elemType
                    [{ inherit (def) file; value = def'; }]
                  ).optionalValue
                ) def.value
              ) defs)));
            emptyValue = { value = []; };
            getSubOptions = prefix: elemType.getSubOptions (prefix ++ ["*"]);
            getSubModules = elemType.getSubModules;
            substSubModules = m: listOf (elemType.substSubModules m);
            functor = (defaultFunctor name) // { wrapped = elemType; };
            nestedTypes.elemType = elemType;
          };
      
          nonEmptyListOf = elemType:
            let list = addCheck (types.listOf elemType) (l: l != []);
            in list // {
              description = "non-empty ${optionDescriptionPhrase (class: class == "noun") list}";
              emptyValue = { }; # no .value attr, meaning unset
            };
      
          attrsOf = elemType: mkOptionType rec {
            name = "attrsOf";
            description = "attribute set of ${optionDescriptionPhrase (class: class == "noun" || class == "composite") elemType}";
            descriptionClass = "composite";
            check = isAttrs;
            merge = loc: defs:
              mapAttrs (n: v: v.value) (filterAttrs (n: v: v ? value) (zipAttrsWith (name: defs:
                  (mergeDefinitions (loc ++ [name]) elemType defs).optionalValue
                )
                # Push down position info.
                (map (def: mapAttrs (n: v: { inherit (def) file; value = v; }) def.value) defs)));
            emptyValue = { value = {}; };
            getSubOptions = prefix: elemType.getSubOptions (prefix ++ ["<name>"]);
            getSubModules = elemType.getSubModules;
            substSubModules = m: attrsOf (elemType.substSubModules m);
            functor = (defaultFunctor name) // { wrapped = elemType; };
            nestedTypes.elemType = elemType;
          };
      
          # A version of attrsOf that's lazy in its values at the expense of
          # conditional definitions not working properly. E.g. defining a value with
          # `foo.attr = mkIf false 10`, then `foo ? attr == true`, whereas with
          # attrsOf it would correctly be `false`. Accessing `foo.attr` would throw an
          # error that it's not defined. Use only if conditional definitions don't make sense.
          lazyAttrsOf = elemType: mkOptionType rec {
            name = "lazyAttrsOf";
            description = "lazy attribute set of ${optionDescriptionPhrase (class: class == "noun" || class == "composite") elemType}";
            descriptionClass = "composite";
            check = isAttrs;
            merge = loc: defs:
              zipAttrsWith (name: defs:
                let merged = mergeDefinitions (loc ++ [name]) elemType defs;
                # mergedValue will trigger an appropriate error when accessed
                in merged.optionalValue.value or elemType.emptyValue.value or merged.mergedValue
              )
              # Push down position info.
              (map (def: mapAttrs (n: v: { inherit (def) file; value = v; }) def.value) defs);
            emptyValue = { value = {}; };
            getSubOptions = prefix: elemType.getSubOptions (prefix ++ ["<name>"]);
            getSubModules = elemType.getSubModules;
            substSubModules = m: lazyAttrsOf (elemType.substSubModules m);
            functor = (defaultFunctor name) // { wrapped = elemType; };
            nestedTypes.elemType = elemType;
          };
      
          # TODO: deprecate this in the future:
          loaOf = elemType: types.attrsOf elemType // {
            name = "loaOf";
            deprecationMessage = "Mixing lists with attribute values is no longer"
              + " possible; please use `types.attrsOf` instead. See"
              + " https://github.com/NixOS/nixpkgs/issues/1800 for the motivation.";
            nestedTypes.elemType = elemType;
          };
      
          # Value of given type but with no merging (i.e. `uniq list`s are not concatenated).
          uniq = elemType: mkOptionType rec {
            name = "uniq";
            inherit (elemType) description descriptionClass check;
            merge = mergeOneOption;
            emptyValue = elemType.emptyValue;
            getSubOptions = elemType.getSubOptions;
            getSubModules = elemType.getSubModules;
            substSubModules = m: uniq (elemType.substSubModules m);
            functor = (defaultFunctor name) // { wrapped = elemType; };
            nestedTypes.elemType = elemType;
          };
      
          unique = { message }: type: mkOptionType rec {
            name = "unique";
            inherit (type) description descriptionClass check;
            merge = mergeUniqueOption { inherit message; };
            emptyValue = type.emptyValue;
            getSubOptions = type.getSubOptions;
            getSubModules = type.getSubModules;
            substSubModules = m: uniq (type.substSubModules m);
            functor = (defaultFunctor name) // { wrapped = type; };
            nestedTypes.elemType = type;
          };
      
          # Null or value of ...
          nullOr = elemType: mkOptionType rec {
            name = "nullOr";
            description = "null or ${optionDescriptionPhrase (class: class == "noun" || class == "conjunction") elemType}";
            descriptionClass = "conjunction";
            check = x: x == null || elemType.check x;
            merge = loc: defs:
              let nrNulls = count (def: def.value == null) defs; in
              if nrNulls == length defs then null
              else if nrNulls != 0 then
                throw "The option `${showOption loc}` is defined both null and not null, in ${showFiles (getFiles defs)}."
              else elemType.merge loc defs;
            emptyValue = { value = null; };
            getSubOptions = elemType.getSubOptions;
            getSubModules = elemType.getSubModules;
            substSubModules = m: nullOr (elemType.substSubModules m);
            functor = (defaultFunctor name) // { wrapped = elemType; };
            nestedTypes.elemType = elemType;
          };
      
          functionTo = elemType: mkOptionType {
            name = "functionTo";
            description = "function that evaluates to a(n) ${optionDescriptionPhrase (class: class == "noun" || class == "composite") elemType}";
            descriptionClass = "composite";
            check = isFunction;
            merge = loc: defs:
              fnArgs: (mergeDefinitions (loc ++ [ "<function body>" ]) elemType (map (fn: { inherit (fn) file; value = fn.value fnArgs; }) defs)).mergedValue;
            getSubOptions = prefix: elemType.getSubOptions (prefix ++ [ "<function body>" ]);
            getSubModules = elemType.getSubModules;
            substSubModules = m: functionTo (elemType.substSubModules m);
            functor = (defaultFunctor "functionTo") // { wrapped = elemType; };
            nestedTypes.elemType = elemType;
          };
      
          # A submodule (like typed attribute set). See NixOS manual.
          submodule = modules: submoduleWith {
            shorthandOnlyDefinesConfig = true;
            modules = toList modules;
          };
      
          # A module to be imported in some other part of the configuration.
          deferredModule = deferredModuleWith { };
      
          # A module to be imported in some other part of the configuration.
          # `staticModules`' options will be added to the documentation, unlike
          # options declared via `config`.
          deferredModuleWith = attrs@{ staticModules ? [] }: mkOptionType {
            name = "deferredModule";
            description = "module";
            descriptionClass = "noun";
            check = x: isAttrs x || isFunction x || path.check x;
            merge = loc: defs: {
              imports = staticModules ++ map (def: lib.setDefaultModuleLocation "${def.file}, via option ${showOption loc}" def.value) defs;
            };
            inherit (submoduleWith { modules = staticModules; })
              getSubOptions
              getSubModules;
            substSubModules = m: deferredModuleWith (attrs // {
              staticModules = m;
            });
            functor = defaultFunctor "deferredModuleWith" // {
              type = types.deferredModuleWith;
              payload = {
                inherit staticModules;
              };
              binOp = lhs: rhs: {
                staticModules = lhs.staticModules ++ rhs.staticModules;
              };
            };
          };
      
          # The type of a type!
          optionType = mkOptionType {
            name = "optionType";
            description = "optionType";
            descriptionClass = "noun";
            check = value: value._type or null == "option-type";
            merge = loc: defs:
              if length defs == 1
              then (head defs).value
              else let
                # Prepares the type definitions for mergeOptionDecls, which
                # annotates submodules types with file locations
                optionModules = map ({ value, file }:
                  {
                    _file = file;
                    # There's no way to merge types directly from the module system,
                    # but we can cheat a bit by just declaring an option with the type
                    options = lib.mkOption {
                      type = value;
                    };
                  }
                ) defs;
                # Merges all the types into a single one, including submodule merging.
                # This also propagates file information to all submodules
                mergedOption = fixupOptionType loc (mergeOptionDecls loc optionModules);
              in mergedOption.type;
          };
      
          submoduleWith =
            { modules
            , specialArgs ? {}
            , shorthandOnlyDefinesConfig ? false
            , description ? null
            }@attrs:
            let
              inherit (lib.modules) evalModules;
      
              allModules = defs: map ({ value, file }:
                if isAttrs value && shorthandOnlyDefinesConfig
                then { _file = file; config = value; }
                else { _file = file; imports = [ value ]; }
              ) defs;
      
              base = evalModules {
                inherit specialArgs;
                modules = [{
                  # This is a work-around for the fact that some sub-modules,
                  # such as the one included in an attribute set, expects an "args"
                  # attribute to be given to the sub-module. As the option
                  # evaluation does not have any specific attribute name yet, we
                  # provide a default for the documentation and the freeform type.
                  #
                  # This is necessary as some option declaration might use the
                  # "name" attribute given as argument of the submodule and use it
                  # as the default of option declarations.
                  #
                  # We use lookalike unicode single angle quotation marks because
                  # of the docbook transformation the options receive. In all uses
                  # &gt; and &lt; wouldn't be encoded correctly so the encoded values
                  # would be used, and use of `<` and `>` would break the XML document.
                  # It shouldn't cause an issue since this is cosmetic for the manual.
                  _module.args.name = lib.mkOptionDefault "‹name›";
                }] ++ modules;
              };
      
              freeformType = base._module.freeformType;
      
              name = "submodule";
      
            in
            mkOptionType {
              inherit name;
              description =
                if description != null then description
                else freeformType.description or name;
              check = x: isAttrs x || isFunction x || path.check x;
              merge = loc: defs:
                (base.extendModules {
                  modules = [ { _module.args.name = last loc; } ] ++ allModules defs;
                  prefix = loc;
                }).config;
              emptyValue = { value = {}; };
              getSubOptions = prefix: (base.extendModules
                { inherit prefix; }).options // optionalAttrs (freeformType != null) {
                  # Expose the sub options of the freeform type. Note that the option
                  # discovery doesn't care about the attribute name used here, so this
                  # is just to avoid conflicts with potential options from the submodule
                  _freeformOptions = freeformType.getSubOptions prefix;
                };
              getSubModules = modules;
              substSubModules = m: submoduleWith (attrs // {
                modules = m;
              });
              nestedTypes = lib.optionalAttrs (freeformType != null) {
                freeformType = freeformType;
              };
              functor = defaultFunctor name // {
                type = types.submoduleWith;
                payload = {
                  inherit modules specialArgs shorthandOnlyDefinesConfig description;
                };
                binOp = lhs: rhs: {
                  modules = lhs.modules ++ rhs.modules;
                  specialArgs =
                    let intersecting = builtins.intersectAttrs lhs.specialArgs rhs.specialArgs;
                    in if intersecting == {}
                    then lhs.specialArgs // rhs.specialArgs
                    else throw "A submoduleWith option is declared multiple times with the same specialArgs \"${toString (attrNames intersecting)}\"";
                  shorthandOnlyDefinesConfig =
                    if lhs.shorthandOnlyDefinesConfig == null
                    then rhs.shorthandOnlyDefinesConfig
                    else if rhs.shorthandOnlyDefinesConfig == null
                    then lhs.shorthandOnlyDefinesConfig
                    else if lhs.shorthandOnlyDefinesConfig == rhs.shorthandOnlyDefinesConfig
                    then lhs.shorthandOnlyDefinesConfig
                    else throw "A submoduleWith option is declared multiple times with conflicting shorthandOnlyDefinesConfig values";
                  description =
                    if lhs.description == null
                    then rhs.description
                    else if rhs.description == null
                    then lhs.description
                    else if lhs.description == rhs.description
                    then lhs.description
                    else throw "A submoduleWith option is declared multiple times with conflicting descriptions";
                };
              };
            };
      
          # A value from a set of allowed ones.
          enum = values:
            let
              inherit (lib.lists) unique;
              show = v:
                     if builtins.isString v then ''"${v}"''
                else if builtins.isInt v then builtins.toString v
                else if builtins.isBool v then boolToString v
                else ''<${builtins.typeOf v}>'';
            in
            mkOptionType rec {
              name = "enum";
              description =
                # Length 0 or 1 enums may occur in a design pattern with type merging
                # where an "interface" module declares an empty enum and other modules
                # provide implementations, each extending the enum with their own
                # identifier.
                if values == [] then
                  "impossible (empty enum)"
                else if builtins.length values == 1 then
                  "value ${show (builtins.head values)} (singular enum)"
                else
                  "one of ${concatMapStringsSep ", " show values}";
              descriptionClass =
                if builtins.length values < 2
                then "noun"
                else "conjunction";
              check = flip elem values;
              merge = mergeEqualOption;
              functor = (defaultFunctor name) // { payload = values; binOp = a: b: unique (a ++ b); };
            };
      
          # Either value of type `t1` or `t2`.
          either = t1: t2: mkOptionType rec {
            name = "either";
            description = "${optionDescriptionPhrase (class: class == "noun" || class == "conjunction") t1} or ${optionDescriptionPhrase (class: class == "noun" || class == "conjunction" || class == "composite") t2}";
            descriptionClass = "conjunction";
            check = x: t1.check x || t2.check x;
            merge = loc: defs:
              let
                defList = map (d: d.value) defs;
              in
                if   all (x: t1.check x) defList
                     then t1.merge loc defs
                else if all (x: t2.check x) defList
                     then t2.merge loc defs
                else mergeOneOption loc defs;
            typeMerge = f':
              let mt1 = t1.typeMerge (elemAt f'.wrapped 0).functor;
                  mt2 = t2.typeMerge (elemAt f'.wrapped 1).functor;
              in
                 if (name == f'.name) && (mt1 != null) && (mt2 != null)
                 then functor.type mt1 mt2
                 else null;
            functor = (defaultFunctor name) // { wrapped = [ t1 t2 ]; };
            nestedTypes.left = t1;
            nestedTypes.right = t2;
          };
      
          # Any of the types in the given list
          oneOf = ts:
            let
              head' = if ts == [] then throw "types.oneOf needs to get at least one type in its argument" else head ts;
              tail' = tail ts;
            in foldl' either head' tail';
      
          # Either value of type `coercedType` or `finalType`, the former is
          # converted to `finalType` using `coerceFunc`.
          coercedTo = coercedType: coerceFunc: finalType:
            assert lib.assertMsg (coercedType.getSubModules == null)
              "coercedTo: coercedType must not have submodules (it’s a ${
                coercedType.description})";
            mkOptionType rec {
              name = "coercedTo";
              description = "${optionDescriptionPhrase (class: class == "noun") finalType} or ${optionDescriptionPhrase (class: class == "noun") coercedType} convertible to it";
              check = x: (coercedType.check x && finalType.check (coerceFunc x)) || finalType.check x;
              merge = loc: defs:
                let
                  coerceVal = val:
                    if coercedType.check val then coerceFunc val
                    else val;
                in finalType.merge loc (map (def: def // { value = coerceVal def.value; }) defs);
              emptyValue = finalType.emptyValue;
              getSubOptions = finalType.getSubOptions;
              getSubModules = finalType.getSubModules;
              substSubModules = m: coercedTo coercedType coerceFunc (finalType.substSubModules m);
              typeMerge = t1: t2: null;
              functor = (defaultFunctor name) // { wrapped = finalType; };
              nestedTypes.coercedType = coercedType;
              nestedTypes.finalType = finalType;
            };
      
          # Augment the given type with an additional type check function.
          addCheck = elemType: check: elemType // { check = x: elemType.check x && check x; };
      
        };
      };
      
      in outer_types // outer_types.types
    );
    "/Users/jeffhykin/repos/nixpkgs/lib/licenses.nix" = (# "/Users/jeffhykin/repos/nixpkgs/lib/licenses.nix"
      { lib }:
      
      lib.mapAttrs (lname: lset: let
        defaultLicense = rec {
          shortName = lname;
          free = true; # Most of our licenses are Free, explicitly declare unfree additions as such!
          deprecated = false;
        };
      
        mkLicense = licenseDeclaration: let
          applyDefaults = license: defaultLicense // license;
          applySpdx = license:
            if license ? spdxId
            then license // { url = "https://spdx.org/licenses/${license.spdxId}.html"; }
            else license;
          applyRedistributable = license: { redistributable = license.free; } // license;
        in lib.pipe licenseDeclaration [
          applyDefaults
          applySpdx
          applyRedistributable
        ];
      in mkLicense lset) ({
        /* License identifiers from spdx.org where possible.
         * If you cannot find your license here, then look for a similar license or
         * add it to this list. The URL mentioned above is a good source for inspiration.
         */
      
        abstyles = {
          spdxId = "Abstyles";
          fullName = "Abstyles License";
        };
      
        afl20 = {
          spdxId = "AFL-2.0";
          fullName = "Academic Free License v2.0";
        };
      
        afl21 = {
          spdxId = "AFL-2.1";
          fullName = "Academic Free License v2.1";
        };
      
        afl3 = {
          spdxId = "AFL-3.0";
          fullName = "Academic Free License v3.0";
        };
      
        agpl3Only = {
          spdxId = "AGPL-3.0-only";
          fullName = "GNU Affero General Public License v3.0 only";
        };
      
        agpl3Plus = {
          spdxId = "AGPL-3.0-or-later";
          fullName = "GNU Affero General Public License v3.0 or later";
        };
      
        aladdin = {
          spdxId = "Aladdin";
          fullName = "Aladdin Free Public License";
          free = false;
        };
      
        amazonsl = {
          fullName = "Amazon Software License";
          url = "https://aws.amazon.com/asl/";
          free = false;
        };
      
        amd = {
          fullName = "AMD License Agreement";
          url = "https://developer.amd.com/amd-license-agreement/";
          free = false;
        };
      
        aom = {
          fullName = "Alliance for Open Media Patent License 1.0";
          url = "https://aomedia.org/license/patent-license/";
        };
      
        apsl10 = {
          spdxId = "APSL-1.0";
          fullName = "Apple Public Source License 1.0";
          url = "https://web.archive.org/web/20040701000000*/http://www.opensource.apple.com/apsl/1.0.txt";
        };
      
        apsl20 = {
          spdxId = "APSL-2.0";
          fullName = "Apple Public Source License 2.0";
        };
      
        arphicpl = {
          fullName = "Arphic Public License";
          url = "https://www.freedesktop.org/wiki/Arphic_Public_License/";
        };
      
        artistic1 = {
          spdxId = "Artistic-1.0";
          fullName = "Artistic License 1.0";
        };
      
        artistic2 = {
          spdxId = "Artistic-2.0";
          fullName = "Artistic License 2.0";
        };
      
        asl20 = {
          spdxId = "Apache-2.0";
          fullName = "Apache License 2.0";
        };
      
        bitstreamVera = {
          spdxId = "Bitstream-Vera";
          fullName = "Bitstream Vera Font License";
        };
      
        bola11 = {
          url = "https://blitiri.com.ar/p/bola/";
          fullName = "Buena Onda License Agreement 1.1";
        };
      
        boost = {
          spdxId = "BSL-1.0";
          fullName = "Boost Software License 1.0";
        };
      
        beerware = {
          spdxId = "Beerware";
          fullName = "Beerware License";
        };
      
        blueOak100 = {
          spdxId = "BlueOak-1.0.0";
          fullName = "Blue Oak Model License 1.0.0";
        };
      
        bsd0 = {
          spdxId = "0BSD";
          fullName = "BSD Zero Clause License";
        };
      
        bsd1 = {
          spdxId = "BSD-1-Clause";
          fullName = "BSD 1-Clause License";
        };
      
        bsd2 = {
          spdxId = "BSD-2-Clause";
          fullName = ''BSD 2-clause "Simplified" License'';
        };
      
        bsd2Patent = {
          spdxId = "BSD-2-Clause-Patent";
          fullName = "BSD-2-Clause Plus Patent License";
        };
      
        bsd2WithViews = {
          spdxId = "BSD-2-Clause-Views";
          fullName = "BSD 2-Clause with views sentence";
        };
      
        bsd3 = {
          spdxId = "BSD-3-Clause";
          fullName = ''BSD 3-clause "New" or "Revised" License'';
        };
      
        bsdOriginal = {
          spdxId = "BSD-4-Clause";
          fullName = ''BSD 4-clause "Original" or "Old" License'';
        };
      
        bsdOriginalShortened = {
          spdxId = "BSD-4-Clause-Shortened";
          fullName = "BSD 4 Clause Shortened";
        };
      
        bsdOriginalUC = {
          spdxId = "BSD-4-Clause-UC";
          fullName = "BSD 4-Clause University of California-Specific";
        };
      
        bsdProtection = {
          spdxId = "BSD-Protection";
          fullName = "BSD Protection License";
        };
      
        bsl11 = {
          fullName = "Business Source License 1.1";
          url = "https://mariadb.com/bsl11";
          free = false;
        };
      
        cal10 = {
          fullName = "Cryptographic Autonomy License version 1.0 (CAL-1.0)";
          url = "https://opensource.org/licenses/CAL-1.0";
        };
      
        capec = {
          fullName = "Common Attack Pattern Enumeration and Classification";
          url = "https://capec.mitre.org/about/termsofuse.html";
        };
      
        clArtistic = {
          spdxId = "ClArtistic";
          fullName = "Clarified Artistic License";
        };
      
        cc0 = {
          spdxId = "CC0-1.0";
          fullName = "Creative Commons Zero v1.0 Universal";
        };
      
        cc-by-nc-sa-20 = {
          spdxId = "CC-BY-NC-SA-2.0";
          fullName = "Creative Commons Attribution Non Commercial Share Alike 2.0";
          free = false;
        };
      
        cc-by-nc-sa-25 = {
          spdxId = "CC-BY-NC-SA-2.5";
          fullName = "Creative Commons Attribution Non Commercial Share Alike 2.5";
          free = false;
        };
      
        cc-by-nc-sa-30 = {
          spdxId = "CC-BY-NC-SA-3.0";
          fullName = "Creative Commons Attribution Non Commercial Share Alike 3.0";
          free = false;
        };
      
        cc-by-nc-sa-40 = {
          spdxId = "CC-BY-NC-SA-4.0";
          fullName = "Creative Commons Attribution Non Commercial Share Alike 4.0";
          free = false;
        };
      
        cc-by-nc-30 = {
          spdxId = "CC-BY-NC-3.0";
          fullName = "Creative Commons Attribution Non Commercial 3.0 Unported";
          free = false;
        };
      
        cc-by-nc-40 = {
          spdxId = "CC-BY-NC-4.0";
          fullName = "Creative Commons Attribution Non Commercial 4.0 International";
          free = false;
        };
      
        cc-by-nd-30 = {
          spdxId = "CC-BY-ND-3.0";
          fullName = "Creative Commons Attribution-No Derivative Works v3.00";
          free = false;
        };
      
        cc-by-sa-25 = {
          spdxId = "CC-BY-SA-2.5";
          fullName = "Creative Commons Attribution Share Alike 2.5";
        };
      
        cc-by-30 = {
          spdxId = "CC-BY-3.0";
          fullName = "Creative Commons Attribution 3.0";
        };
      
        cc-by-sa-30 = {
          spdxId = "CC-BY-SA-3.0";
          fullName = "Creative Commons Attribution Share Alike 3.0";
        };
      
        cc-by-40 = {
          spdxId = "CC-BY-4.0";
          fullName = "Creative Commons Attribution 4.0";
        };
      
        cc-by-sa-40 = {
          spdxId = "CC-BY-SA-4.0";
          fullName = "Creative Commons Attribution Share Alike 4.0";
        };
      
        cddl = {
          spdxId = "CDDL-1.0";
          fullName = "Common Development and Distribution License 1.0";
        };
      
        cecill20 = {
          spdxId = "CECILL-2.0";
          fullName = "CeCILL Free Software License Agreement v2.0";
        };
      
        cecill21 = {
          spdxId = "CECILL-2.1";
          fullName = "CeCILL Free Software License Agreement v2.1";
        };
      
        cecill-b = {
          spdxId = "CECILL-B";
          fullName  = "CeCILL-B Free Software License Agreement";
        };
      
        cecill-c = {
          spdxId = "CECILL-C";
          fullName  = "CeCILL-C Free Software License Agreement";
        };
      
        cpal10 = {
          spdxId = "CPAL-1.0";
          fullName = "Common Public Attribution License 1.0";
        };
      
        cpl10 = {
          spdxId = "CPL-1.0";
          fullName = "Common Public License 1.0";
        };
      
        curl = {
          spdxId = "curl";
          fullName = "curl License";
        };
      
        doc = {
          spdxId = "DOC";
          fullName = "DOC License";
        };
      
        drl10 = {
          spdxId = "DRL-1.0";
          fullName = "Detection Rule License 1.0";
        };
      
        eapl = {
          fullName = "EPSON AVASYS PUBLIC LICENSE";
          url = "https://avasys.jp/hp/menu000000700/hpg000000603.htm";
          free = false;
        };
      
        efl10 = {
          spdxId = "EFL-1.0";
          fullName = "Eiffel Forum License v1.0";
        };
      
        efl20 = {
          spdxId = "EFL-2.0";
          fullName = "Eiffel Forum License v2.0";
        };
      
        elastic = {
          fullName = "ELASTIC LICENSE";
          url = "https://github.com/elastic/elasticsearch/blob/master/licenses/ELASTIC-LICENSE.txt";
          free = false;
        };
      
        epl10 = {
          spdxId = "EPL-1.0";
          fullName = "Eclipse Public License 1.0";
        };
      
        epl20 = {
          spdxId = "EPL-2.0";
          fullName = "Eclipse Public License 2.0";
        };
      
        epson = {
          fullName = "Seiko Epson Corporation Software License Agreement for Linux";
          url = "https://download.ebz.epson.net/dsc/du/02/eula/global/LINUX_EN.html";
          free = false;
        };
      
        eupl11 = {
          spdxId = "EUPL-1.1";
          fullName = "European Union Public License 1.1";
        };
      
        eupl12 = {
          spdxId = "EUPL-1.2";
          fullName = "European Union Public License 1.2";
        };
      
        fdl11Only = {
          spdxId = "GFDL-1.1-only";
          fullName = "GNU Free Documentation License v1.1 only";
        };
      
        fdl11Plus = {
          spdxId = "GFDL-1.1-or-later";
          fullName = "GNU Free Documentation License v1.1 or later";
        };
      
        fdl12Only = {
          spdxId = "GFDL-1.2-only";
          fullName = "GNU Free Documentation License v1.2 only";
        };
      
        fdl12Plus = {
          spdxId = "GFDL-1.2-or-later";
          fullName = "GNU Free Documentation License v1.2 or later";
        };
      
        fdl13Only = {
          spdxId = "GFDL-1.3-only";
          fullName = "GNU Free Documentation License v1.3 only";
        };
      
        fdl13Plus = {
          spdxId = "GFDL-1.3-or-later";
          fullName = "GNU Free Documentation License v1.3 or later";
        };
      
        ffsl = {
          fullName = "Floodgap Free Software License";
          url = "https://www.floodgap.com/software/ffsl/license.html";
          free = false;
        };
      
        free = {
          fullName = "Unspecified free software license";
        };
      
        ftl = {
          spdxId = "FTL";
          fullName = "Freetype Project License";
        };
      
        g4sl = {
          fullName = "Geant4 Software License";
          url = "https://geant4.web.cern.ch/geant4/license/LICENSE.html";
        };
      
        geogebra = {
          fullName = "GeoGebra Non-Commercial License Agreement";
          url = "https://www.geogebra.org/license";
          free = false;
        };
      
        generaluser = {
          fullName = "GeneralUser GS License v2.0";
          url = "http://www.schristiancollins.com/generaluser.php"; # license included in sources
        };
      
        gpl1Only = {
          spdxId = "GPL-1.0-only";
          fullName = "GNU General Public License v1.0 only";
        };
      
        gpl1Plus = {
          spdxId = "GPL-1.0-or-later";
          fullName = "GNU General Public License v1.0 or later";
        };
      
        gpl2Only = {
          spdxId = "GPL-2.0-only";
          fullName = "GNU General Public License v2.0 only";
        };
      
        gpl2Classpath = {
          spdxId = "GPL-2.0-with-classpath-exception";
          fullName = "GNU General Public License v2.0 only (with Classpath exception)";
        };
      
        gpl2ClasspathPlus = {
          fullName = "GNU General Public License v2.0 or later (with Classpath exception)";
          url = "https://fedoraproject.org/wiki/Licensing/GPL_Classpath_Exception";
        };
      
        gpl2Oss = {
          fullName = "GNU General Public License version 2 only (with OSI approved licenses linking exception)";
          url = "https://www.mysql.com/about/legal/licensing/foss-exception";
        };
      
        gpl2Plus = {
          spdxId = "GPL-2.0-or-later";
          fullName = "GNU General Public License v2.0 or later";
        };
      
        gpl3Only = {
          spdxId = "GPL-3.0-only";
          fullName = "GNU General Public License v3.0 only";
        };
      
        gpl3Plus = {
          spdxId = "GPL-3.0-or-later";
          fullName = "GNU General Public License v3.0 or later";
        };
      
        gpl3ClasspathPlus = {
          fullName = "GNU General Public License v3.0 or later (with Classpath exception)";
          url = "https://fedoraproject.org/wiki/Licensing/GPL_Classpath_Exception";
        };
      
        hpnd = {
          spdxId = "HPND";
          fullName = "Historic Permission Notice and Disclaimer";
        };
      
        hpndSellVariant = {
          fullName = "Historical Permission Notice and Disclaimer - sell variant";
          spdxId = "HPND-sell-variant";
        };
      
        # Intel's license, seems free
        iasl = {
          fullName = "iASL";
          url = "https://old.calculate-linux.org/packages/licenses/iASL";
        };
      
        ijg = {
          spdxId = "IJG";
          fullName = "Independent JPEG Group License";
        };
      
        imagemagick = {
          fullName = "ImageMagick License";
          spdxId = "imagemagick";
        };
      
        imlib2 = {
          spdxId = "Imlib2";
          fullName = "Imlib2 License";
        };
      
        inria-compcert = {
          fullName  = "INRIA Non-Commercial License Agreement for the CompCert verified compiler";
          url       = "https://compcert.org/doc/LICENSE.txt";
          free      = false;
        };
      
        inria-icesl = {
          fullName = "INRIA Non-Commercial License Agreement for IceSL";
          url      = "https://icesl.loria.fr/assets/pdf/EULA_IceSL_binary.pdf";
          free     = false;
        };
      
        ipa = {
          spdxId = "IPA";
          fullName = "IPA Font License";
        };
      
        ipl10 = {
          spdxId = "IPL-1.0";
          fullName = "IBM Public License v1.0";
        };
      
        isc = {
          spdxId = "ISC";
          fullName = "ISC License";
        };
      
        # Proprietary binaries; free to redistribute without modification.
        databricks = {
          fullName = "Databricks Proprietary License";
          url = "https://pypi.org/project/databricks-connect";
          free = false;
        };
      
        databricks-dbx = {
          fullName = "DataBricks eXtensions aka dbx License";
          url = "https://github.com/databrickslabs/dbx/blob/743b579a4ac44531f764c6e522dbe5a81a7dc0e4/LICENSE";
          free = false;
          redistributable = false;
        };
      
        issl = {
          fullName = "Intel Simplified Software License";
          url = "https://software.intel.com/en-us/license/intel-simplified-software-license";
          free = false;
        };
      
        lal12 = {
          spdxId = "LAL-1.2";
          fullName = "Licence Art Libre 1.2";
        };
      
        lal13 = {
          spdxId = "LAL-1.3";
          fullName = "Licence Art Libre 1.3";
        };
      
        lgpl2Only = {
          spdxId = "LGPL-2.0-only";
          fullName = "GNU Library General Public License v2 only";
        };
      
        lgpl2Plus = {
          spdxId = "LGPL-2.0-or-later";
          fullName = "GNU Library General Public License v2 or later";
        };
      
        lgpl21Only = {
          spdxId = "LGPL-2.1-only";
          fullName = "GNU Lesser General Public License v2.1 only";
        };
      
        lgpl21Plus = {
          spdxId = "LGPL-2.1-or-later";
          fullName = "GNU Lesser General Public License v2.1 or later";
        };
      
        lgpl3Only = {
          spdxId = "LGPL-3.0-only";
          fullName = "GNU Lesser General Public License v3.0 only";
        };
      
        lgpl3Plus = {
          spdxId = "LGPL-3.0-or-later";
          fullName = "GNU Lesser General Public License v3.0 or later";
        };
      
        lgpllr = {
          spdxId = "LGPLLR";
          fullName = "Lesser General Public License For Linguistic Resources";
        };
      
        libpng = {
          spdxId = "Libpng";
          fullName = "libpng License";
        };
      
        libpng2 = {
          spdxId = "libpng-2.0"; # Used since libpng 1.6.36.
          fullName = "PNG Reference Library version 2";
        };
      
        libssh2 = {
          fullName = "libssh2 License";
          url = "https://www.libssh2.org/license.html";
        };
      
        libtiff = {
          spdxId = "libtiff";
          fullName = "libtiff License";
        };
      
        llgpl21 = {
          fullName = "Lisp LGPL; GNU Lesser General Public License version 2.1 with Franz Inc. preamble for clarification of LGPL terms in context of Lisp";
          url = "https://opensource.franz.com/preamble.html";
        };
      
        llvm-exception = {
          spdxId = "LLVM-exception";
          fullName = "LLVM Exception"; # LLVM exceptions to the Apache 2.0 License
        };
      
        lppl12 = {
          spdxId = "LPPL-1.2";
          fullName = "LaTeX Project Public License v1.2";
        };
      
        lppl13c = {
          spdxId = "LPPL-1.3c";
          fullName = "LaTeX Project Public License v1.3c";
        };
      
        lpl-102 = {
          spdxId = "LPL-1.02";
          fullName = "Lucent Public License v1.02";
        };
      
        miros = {
          fullName = "MirOS License";
          url = "https://opensource.org/licenses/MirOS";
        };
      
        # spdx.org does not (yet) differentiate between the X11 and Expat versions
        # for details see https://en.wikipedia.org/wiki/MIT_License#Various_versions
        mit = {
          spdxId = "MIT";
          fullName = "MIT License";
        };
        # https://spdx.org/licenses/MIT-feh.html
        mit-feh = {
          spdxId = "MIT-feh";
          fullName = "feh License";
        };
      
        mitAdvertising = {
          spdxId = "MIT-advertising";
          fullName = "Enlightenment License (e16)";
        };
      
        mit0 = {
          spdxId = "MIT-0";
          fullName = "MIT No Attribution";
        };
      
        mpl10 = {
          spdxId = "MPL-1.0";
          fullName = "Mozilla Public License 1.0";
        };
      
        mpl11 = {
          spdxId = "MPL-1.1";
          fullName = "Mozilla Public License 1.1";
        };
      
        mpl20 = {
          spdxId = "MPL-2.0";
          fullName = "Mozilla Public License 2.0";
        };
      
        mspl = {
          spdxId = "MS-PL";
          fullName = "Microsoft Public License";
        };
      
        nasa13 = {
          spdxId = "NASA-1.3";
          fullName = "NASA Open Source Agreement 1.3";
          free = false;
        };
      
        ncsa = {
          spdxId = "NCSA";
          fullName  = "University of Illinois/NCSA Open Source License";
        };
      
        nposl3 = {
          spdxId = "NPOSL-3.0";
          fullName = "Non-Profit Open Software License 3.0";
        };
      
        obsidian = {
          fullName = "Obsidian End User Agreement";
          url = "https://obsidian.md/eula";
          free = false;
        };
      
        ocamlpro_nc = {
          fullName = "OCamlPro Non Commercial license version 1";
          url = "https://alt-ergo.ocamlpro.com/http/alt-ergo-2.2.0/OCamlPro-Non-Commercial-License.pdf";
          free = false;
        };
      
        odbl = {
          spdxId = "ODbL-1.0";
          fullName = "Open Data Commons Open Database License v1.0";
        };
      
        ofl = {
          spdxId = "OFL-1.1";
          fullName = "SIL Open Font License 1.1";
        };
      
        oml = {
          spdxId = "OML";
          fullName = "Open Market License";
        };
      
        openldap = {
          spdxId = "OLDAP-2.8";
          fullName = "Open LDAP Public License v2.8";
        };
      
        openssl = {
          spdxId = "OpenSSL";
          fullName = "OpenSSL License";
        };
      
        osl2 = {
          spdxId = "OSL-2.0";
          fullName = "Open Software License 2.0";
        };
      
        osl21 = {
          spdxId = "OSL-2.1";
          fullName = "Open Software License 2.1";
        };
      
        osl3 = {
          spdxId = "OSL-3.0";
          fullName = "Open Software License 3.0";
        };
      
        parity70 = {
          spdxId = "Parity-7.0.0";
          fullName = "Parity Public License 7.0.0";
          url = "https://paritylicense.com/versions/7.0.0.html";
        };
      
        php301 = {
          spdxId = "PHP-3.01";
          fullName = "PHP License v3.01";
        };
      
        postgresql = {
          spdxId = "PostgreSQL";
          fullName = "PostgreSQL License";
        };
      
        postman = {
          fullName = "Postman EULA";
          url = "https://www.getpostman.com/licenses/postman_base_app";
          free = false;
        };
      
        psfl = {
          spdxId = "Python-2.0";
          fullName = "Python Software Foundation License version 2";
          url = "https://docs.python.org/license.html";
        };
      
        publicDomain = {
          fullName = "Public Domain";
        };
      
        purdueBsd = {
          fullName = " Purdue BSD-Style License"; # also know as lsof license
          url = "https://enterprise.dejacode.com/licenses/public/purdue-bsd";
        };
      
        prosperity30 = {
          fullName = "Prosperity-3.0.0";
          free = false;
          url = "https://prosperitylicense.com/versions/3.0.0.html";
        };
      
        qhull = {
          spdxId = "Qhull";
          fullName = "Qhull License";
        };
      
        qpl = {
          spdxId = "QPL-1.0";
          fullName = "Q Public License 1.0";
        };
      
        qwt = {
          fullName = "Qwt License, Version 1.0";
          url = "https://qwt.sourceforge.io/qwtlicense.html";
        };
      
        ruby = {
          spdxId = "Ruby";
          fullName = "Ruby License";
        };
      
        sendmail = {
          spdxId = "Sendmail";
          fullName = "Sendmail License";
        };
      
        sgi-b-20 = {
          spdxId = "SGI-B-2.0";
          fullName = "SGI Free Software License B v2.0";
        };
      
        # Gentoo seems to treat it as a license:
        # https://gitweb.gentoo.org/repo/gentoo.git/tree/licenses/SGMLUG?id=7d999af4a47bf55e53e54713d98d145f935935c1
        sgmlug = {
          fullName = "SGML UG SGML Parser Materials license";
        };
      
        sleepycat = {
          spdxId = "Sleepycat";
          fullName = "Sleepycat License";
        };
      
        smail = {
          shortName = "smail";
          fullName = "SMAIL General Public License";
          url = "https://sources.debian.org/copyright/license/debianutils/4.9.1/";
        };
      
        sspl = {
          shortName = "SSPL";
          fullName = "Server Side Public License";
          url = "https://www.mongodb.com/licensing/server-side-public-license";
          free = false;
          # NOTE Debatable.
          # The license a slightly modified AGPL but still considered unfree by the
          # OSI for what seem like political reasons
          redistributable = true; # Definitely redistributable though, it's an AGPL derivative
        };
      
        stk = {
          shortName = "stk";
          fullName = "Synthesis Tool Kit 4.3";
          url = "https://github.com/thestk/stk/blob/master/LICENSE";
        };
      
        tcltk = {
          spdxId = "TCL";
          fullName = "TCL/TK License";
        };
      
        ucd = {
          fullName = "Unicode Character Database License";
          url = "https://fedoraproject.org/wiki/Licensing:UCD";
        };
      
        ufl = {
          fullName = "Ubuntu Font License 1.0";
          url = "https://ubuntu.com/legal/font-licence";
        };
      
        unfree = {
          fullName = "Unfree";
          free = false;
        };
      
        unfreeRedistributable = {
          fullName = "Unfree redistributable";
          free = false;
          redistributable = true;
        };
      
        unfreeRedistributableFirmware = {
          fullName = "Unfree redistributable firmware";
          redistributable = true;
          # Note: we currently consider these "free" for inclusion in the
          # channel and NixOS images.
        };
      
        unicode-dfs-2015 = {
          spdxId = "Unicode-DFS-2015";
          fullName = "Unicode License Agreement - Data Files and Software (2015)";
        };
      
        unicode-dfs-2016 = {
          spdxId = "Unicode-DFS-2016";
          fullName = "Unicode License Agreement - Data Files and Software (2016)";
        };
      
        unlicense = {
          spdxId = "Unlicense";
          fullName = "The Unlicense";
        };
      
        upl = {
          fullName = "Universal Permissive License";
          url = "https://oss.oracle.com/licenses/upl/";
        };
      
        vim = {
          spdxId = "Vim";
          fullName = "Vim License";
        };
      
        virtualbox-puel = {
          fullName = "Oracle VM VirtualBox Extension Pack Personal Use and Evaluation License (PUEL)";
          url = "https://www.virtualbox.org/wiki/VirtualBox_PUEL";
          free = false;
        };
      
        vol-sl = {
          fullName = "Volatility Software License, Version 1.0";
          url = "https://www.volatilityfoundation.org/license/vsl-v1.0";
        };
      
        vsl10 = {
          spdxId = "VSL-1.0";
          fullName = "Vovida Software License v1.0";
        };
      
        watcom = {
          spdxId = "Watcom-1.0";
          fullName = "Sybase Open Watcom Public License 1.0";
        };
      
        w3c = {
          spdxId = "W3C";
          fullName = "W3C Software Notice and License";
        };
      
        wadalab = {
          fullName = "Wadalab Font License";
          url = "https://fedoraproject.org/wiki/Licensing:Wadalab?rd=Licensing/Wadalab";
        };
      
        wtfpl = {
          spdxId = "WTFPL";
          fullName = "Do What The F*ck You Want To Public License";
        };
      
        wxWindows = {
          spdxId = "wxWindows";
          fullName = "wxWindows Library Licence, Version 3.1";
        };
      
        x11 = {
          spdxId = "X11";
          fullName = "X11 License";
        };
      
        xfig = {
          fullName = "xfig";
          url = "http://mcj.sourceforge.net/authors.html#xfig"; # https is broken
        };
      
        zlib = {
          spdxId = "Zlib";
          fullName = "zlib License";
        };
      
        zpl20 = {
          spdxId = "ZPL-2.0";
          fullName = "Zope Public License 2.0";
        };
      
        zpl21 = {
          spdxId = "ZPL-2.1";
          fullName = "Zope Public License 2.1";
        };
      } // {
        # TODO: remove legacy aliases
        agpl3 = {
          spdxId = "AGPL-3.0";
          fullName = "GNU Affero General Public License v3.0";
          deprecated = true;
        };
        gpl2 = {
          spdxId = "GPL-2.0";
          fullName = "GNU General Public License v2.0";
          deprecated = true;
        };
        gpl3 = {
          spdxId = "GPL-3.0";
          fullName = "GNU General Public License v3.0";
          deprecated = true;
        };
        lgpl2 = {
          spdxId = "LGPL-2.0";
          fullName = "GNU Library General Public License v2";
          deprecated = true;
        };
        lgpl21 = {
          spdxId = "LGPL-2.1";
          fullName = "GNU Lesser General Public License v2.1";
          deprecated = true;
        };
        lgpl3 = {
          spdxId = "LGPL-3.0";
          fullName = "GNU Lesser General Public License v3.0";
          deprecated = true;
        };
      })
    );
    "/Users/jeffhykin/repos/nixpkgs/lib/source-types.nix" = (# "/Users/jeffhykin/repos/nixpkgs/lib/source-types.nix"
      { lib }:
      
      let
        defaultSourceType = tname: {
          shortName = tname;
          isSource = false;
        };
      in lib.mapAttrs (tname: tset: defaultSourceType tname // tset) {
      
        fromSource = {
          isSource = true;
        };
      
        binaryNativeCode = {};
      
        binaryBytecode = {};
      
        binaryFirmware = {};
      }
    );
    "/Users/jeffhykin/repos/nixpkgs/lib/generators.nix" = (# "/Users/jeffhykin/repos/nixpkgs/lib/generators.nix"
      /* Functions that generate widespread file
       * formats from nix data structures.
       *
       * They all follow a similar interface:
       * generator { config-attrs } data
       *
       * `config-attrs` are “holes” in the generators
       * with sensible default implementations that
       * can be overwritten. The default implementations
       * are mostly generators themselves, called with
       * their respective default values; they can be reused.
       *
       * Tests can be found in ./tests/misc.nix
       * Documentation in the manual, #sec-generators
       */
      { lib }:
      with (lib).trivial;
      let
        libStr = lib.strings;
        libAttr = lib.attrsets;
      
        inherit (lib) isFunction;
      in
      
      rec {
      
        ## -- HELPER FUNCTIONS & DEFAULTS --
      
        /* Convert a value to a sensible default string representation.
         * The builtin `toString` function has some strange defaults,
         * suitable for bash scripts but not much else.
         */
        mkValueStringDefault = {}: v: with builtins;
          let err = t: v: abort
                ("generators.mkValueStringDefault: " +
                 "${t} not supported: ${toPretty {} v}");
          in   if isInt      v then toString v
          # convert derivations to store paths
          else if lib.isDerivation v then toString v
          # we default to not quoting strings
          else if isString   v then v
          # isString returns "1", which is not a good default
          else if true  ==   v then "true"
          # here it returns to "", which is even less of a good default
          else if false ==   v then "false"
          else if null  ==   v then "null"
          # if you have lists you probably want to replace this
          else if isList     v then err "lists" v
          # same as for lists, might want to replace
          else if isAttrs    v then err "attrsets" v
          # functions can’t be printed of course
          else if isFunction v then err "functions" v
          # Floats currently can't be converted to precise strings,
          # condition warning on nix version once this isn't a problem anymore
          # See https://github.com/NixOS/nix/pull/3480
          else if isFloat    v then libStr.floatToString v
          else err "this value is" (toString v);
      
      
        /* Generate a line of key k and value v, separated by
         * character sep. If sep appears in k, it is escaped.
         * Helper for synaxes with different separators.
         *
         * mkValueString specifies how values should be formatted.
         *
         * mkKeyValueDefault {} ":" "f:oo" "bar"
         * > "f\:oo:bar"
         */
        mkKeyValueDefault = {
          mkValueString ? mkValueStringDefault {}
        }: sep: k: v:
          "${libStr.escape [sep] k}${sep}${mkValueString v}";
      
      
        ## -- FILE FORMAT GENERATORS --
      
      
        /* Generate a key-value-style config file from an attrset.
         *
         * mkKeyValue is the same as in toINI.
         */
        toKeyValue = {
          mkKeyValue ? mkKeyValueDefault {} "=",
          listsAsDuplicateKeys ? false
        }:
        let mkLine = k: v: mkKeyValue k v + "\n";
            mkLines = if listsAsDuplicateKeys
              then k: v: map (mkLine k) (if lib.isList v then v else [v])
              else k: v: [ (mkLine k v) ];
        in attrs: libStr.concatStrings (lib.concatLists (libAttr.mapAttrsToList mkLines attrs));
      
      
        /* Generate an INI-style config file from an
         * attrset of sections to an attrset of key-value pairs.
         *
         * generators.toINI {} {
         *   foo = { hi = "${pkgs.hello}"; ciao = "bar"; };
         *   baz = { "also, integers" = 42; };
         * }
         *
         *> [baz]
         *> also, integers=42
         *>
         *> [foo]
         *> ciao=bar
         *> hi=/nix/store/y93qql1p5ggfnaqjjqhxcw0vqw95rlz0-hello-2.10
         *
         * The mk* configuration attributes can generically change
         * the way sections and key-value strings are generated.
         *
         * For more examples see the test cases in ./tests/misc.nix.
         */
        toINI = {
          # apply transformations (e.g. escapes) to section names
          mkSectionName ? (name: libStr.escape [ "[" "]" ] name),
          # format a setting line from key and value
          mkKeyValue    ? mkKeyValueDefault {} "=",
          # allow lists as values for duplicate keys
          listsAsDuplicateKeys ? false
        }: attrsOfAttrs:
          let
              # map function to string for each key val
              mapAttrsToStringsSep = sep: mapFn: attrs:
                libStr.concatStringsSep sep
                  (libAttr.mapAttrsToList mapFn attrs);
              mkSection = sectName: sectValues: ''
                [${mkSectionName sectName}]
              '' + toKeyValue { inherit mkKeyValue listsAsDuplicateKeys; } sectValues;
          in
            # map input to ini sections
            mapAttrsToStringsSep "\n" mkSection attrsOfAttrs;
      
        /* Generate an INI-style config file from an attrset
         * specifying the global section (no header), and an
         * attrset of sections to an attrset of key-value pairs.
         *
         * generators.toINIWithGlobalSection {} {
         *   globalSection = {
         *     someGlobalKey = "hi";
         *   };
         *   sections = {
         *     foo = { hi = "${pkgs.hello}"; ciao = "bar"; };
         *     baz = { "also, integers" = 42; };
         * }
         *
         *> someGlobalKey=hi
         *>
         *> [baz]
         *> also, integers=42
         *>
         *> [foo]
         *> ciao=bar
         *> hi=/nix/store/y93qql1p5ggfnaqjjqhxcw0vqw95rlz0-hello-2.10
         *
         * The mk* configuration attributes can generically change
         * the way sections and key-value strings are generated.
         *
         * For more examples see the test cases in ./tests/misc.nix.
         *
         * If you don’t need a global section, you can also use
         * `generators.toINI` directly, which only takes
         * the part in `sections`.
         */
        toINIWithGlobalSection = {
          # apply transformations (e.g. escapes) to section names
          mkSectionName ? (name: libStr.escape [ "[" "]" ] name),
          # format a setting line from key and value
          mkKeyValue    ? mkKeyValueDefault {} "=",
          # allow lists as values for duplicate keys
          listsAsDuplicateKeys ? false
        }: { globalSection, sections }:
          ( if globalSection == {}
            then ""
            else (toKeyValue { inherit mkKeyValue listsAsDuplicateKeys; } globalSection)
                 + "\n")
          + (toINI { inherit mkSectionName mkKeyValue listsAsDuplicateKeys; } sections);
      
        /* Generate a git-config file from an attrset.
         *
         * It has two major differences from the regular INI format:
         *
         * 1. values are indented with tabs
         * 2. sections can have sub-sections
         *
         * generators.toGitINI {
         *   url."ssh://git@github.com/".insteadOf = "https://github.com";
         *   user.name = "edolstra";
         * }
         *
         *> [url "ssh://git@github.com/"]
         *>   insteadOf = https://github.com/
         *>
         *> [user]
         *>   name = edolstra
         */
        toGitINI = attrs:
          with builtins;
          let
            mkSectionName = name:
              let
                containsQuote = libStr.hasInfix ''"'' name;
                sections = libStr.splitString "." name;
                section = head sections;
                subsections = tail sections;
                subsection = concatStringsSep "." subsections;
              in if containsQuote || subsections == [ ] then
                name
              else
                ''${section} "${subsection}"'';
      
            # generation for multiple ini values
            mkKeyValue = k: v:
              let mkKeyValue = mkKeyValueDefault { } " = " k;
              in concatStringsSep "\n" (map (kv: "\t" + mkKeyValue kv) (lib.toList v));
      
            # converts { a.b.c = 5; } to { "a.b".c = 5; } for toINI
            gitFlattenAttrs = let
              recurse = path: value:
                if isAttrs value && !lib.isDerivation value then
                  lib.mapAttrsToList (name: value: recurse ([ name ] ++ path) value) value
                else if length path > 1 then {
                  ${concatStringsSep "." (lib.reverseList (tail path))}.${head path} = value;
                } else {
                  ${head path} = value;
                };
            in attrs: lib.foldl lib.recursiveUpdate { } (lib.flatten (recurse [ ] attrs));
      
            toINI_ = toINI { inherit mkKeyValue mkSectionName; };
          in
            toINI_ (gitFlattenAttrs attrs);
      
        /* Generates JSON from an arbitrary (non-function) value.
          * For more information see the documentation of the builtin.
          */
        toJSON = {}: builtins.toJSON;
      
      
        /* YAML has been a strict superset of JSON since 1.2, so we
          * use toJSON. Before it only had a few differences referring
          * to implicit typing rules, so it should work with older
          * parsers as well.
          */
        toYAML = toJSON;
      
        withRecursion =
          {
            /* If this option is not null, the given value will stop evaluating at a certain depth */
            depthLimit
            /* If this option is true, an error will be thrown, if a certain given depth is exceeded */
          , throwOnDepthLimit ? true
          }:
            assert builtins.isInt depthLimit;
            let
              specialAttrs = [
                "__functor"
                "__functionArgs"
                "__toString"
                "__pretty"
              ];
              stepIntoAttr = evalNext: name:
                if builtins.elem name specialAttrs
                  then id
                  else evalNext;
              transform = depth:
                if depthLimit != null && depth > depthLimit then
                  if throwOnDepthLimit
                    then throw "Exceeded maximum eval-depth limit of ${toString depthLimit} while trying to evaluate with `generators.withRecursion'!"
                    else const "<unevaluated>"
                else id;
              mapAny = with builtins; depth: v:
                let
                  evalNext = x: mapAny (depth + 1) (transform (depth + 1) x);
                in
                  if isAttrs v then mapAttrs (stepIntoAttr evalNext) v
                  else if isList v then map evalNext v
                  else transform (depth + 1) v;
            in
              mapAny 0;
      
        /* Pretty print a value, akin to `builtins.trace`.
         * Should probably be a builtin as well.
         * The pretty-printed string should be suitable for rendering default values
         * in the NixOS manual. In particular, it should be as close to a valid Nix expression
         * as possible.
         */
        toPretty = {
          /* If this option is true, attrsets like { __pretty = fn; val = …; }
             will use fn to convert val to a pretty printed representation.
             (This means fn is type Val -> String.) */
          allowPrettyValues ? false,
          /* If this option is true, the output is indented with newlines for attribute sets and lists */
          multiline ? true,
          /* Initial indentation level */
          indent ? ""
        }:
          let
          go = indent: v: with builtins;
          let     isPath   = v: typeOf v == "path";
                  introSpace = if multiline then "\n${indent}  " else " ";
                  outroSpace = if multiline then "\n${indent}" else " ";
          in if   isInt      v then toString v
          # toString loses precision on floats, so we use toJSON instead. This isn't perfect
          # as the resulting string may not parse back as a float (e.g. 42, 1e-06), but for
          # pretty-printing purposes this is acceptable.
          else if isFloat    v then builtins.toJSON v
          else if isString   v then
            let
              lines = filter (v: ! isList v) (builtins.split "\n" v);
              escapeSingleline = libStr.escape [ "\\" "\"" "\${" ];
              escapeMultiline = libStr.replaceStrings [ "\${" "''" ] [ "''\${" "'''" ];
              singlelineResult = "\"" + concatStringsSep "\\n" (map escapeSingleline lines) + "\"";
              multilineResult = let
                escapedLines = map escapeMultiline lines;
                # The last line gets a special treatment: if it's empty, '' is on its own line at the "outer"
                # indentation level. Otherwise, '' is appended to the last line.
                lastLine = lib.last escapedLines;
              in "''" + introSpace + concatStringsSep introSpace (lib.init escapedLines)
                      + (if lastLine == "" then outroSpace else introSpace + lastLine) + "''";
            in
              if multiline && length lines > 1 then multilineResult else singlelineResult
          else if true  ==   v then "true"
          else if false ==   v then "false"
          else if null  ==   v then "null"
          else if isPath     v then toString v
          else if isList     v then
            if v == [] then "[ ]"
            else "[" + introSpace
              + libStr.concatMapStringsSep introSpace (go (indent + "  ")) v
              + outroSpace + "]"
          else if isFunction v then
            let fna = lib.functionArgs v;
                showFnas = concatStringsSep ", " (libAttr.mapAttrsToList
                             (name: hasDefVal: if hasDefVal then name + "?" else name)
                             fna);
            in if fna == {}    then "<function>"
                               else "<function, args: {${showFnas}}>"
          else if isAttrs    v then
            # apply pretty values if allowed
            if allowPrettyValues && v ? __pretty && v ? val
               then v.__pretty v.val
            else if v == {} then "{ }"
            else if v ? type && v.type == "derivation" then
              "<derivation ${v.name or "???"}>"
            else "{" + introSpace
                + libStr.concatStringsSep introSpace (libAttr.mapAttrsToList
                    (name: value:
                      "${libStr.escapeNixIdentifier name} = ${
                        builtins.addErrorContext "while evaluating an attribute `${name}`"
                          (go (indent + "  ") value)
                      };") v)
              + outroSpace + "}"
          else abort "generators.toPretty: should never happen (v = ${v})";
        in go indent;
      
        # PLIST handling
        toPlist = {}: v: let
          isFloat = builtins.isFloat or (x: false);
          expr = ind: x:  with builtins;
            if x == null  then "" else
            if isBool x   then bool ind x else
            if isInt x    then int ind x else
            if isString x then str ind x else
            if isList x   then list ind x else
            if isAttrs x  then attrs ind x else
            if isFloat x  then float ind x else
            abort "generators.toPlist: should never happen (v = ${v})";
      
          literal = ind: x: ind + x;
      
          bool = ind: x: literal ind  (if x then "<true/>" else "<false/>");
          int = ind: x: literal ind "<integer>${toString x}</integer>";
          str = ind: x: literal ind "<string>${x}</string>";
          key = ind: x: literal ind "<key>${x}</key>";
          float = ind: x: literal ind "<real>${toString x}</real>";
      
          indent = ind: expr "\t${ind}";
      
          item = ind: libStr.concatMapStringsSep "\n" (indent ind);
      
          list = ind: x: libStr.concatStringsSep "\n" [
            (literal ind "<array>")
            (item ind x)
            (literal ind "</array>")
          ];
      
          attrs = ind: x: libStr.concatStringsSep "\n" [
            (literal ind "<dict>")
            (attr ind x)
            (literal ind "</dict>")
          ];
      
          attr = let attrFilter = name: value: name != "_module" && value != null;
          in ind: x: libStr.concatStringsSep "\n" (lib.flatten (lib.mapAttrsToList
            (name: value: lib.optionals (attrFilter name value) [
            (key "\t${ind}" name)
            (expr "\t${ind}" value)
          ]) x));
      
        in ''<?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      ${expr "" v}
      </plist>'';
      
        /* Translate a simple Nix expression to Dhall notation.
         * Note that integers are translated to Integer and never
         * the Natural type.
        */
        toDhall = { }@args: v:
          with builtins;
          let concatItems = lib.strings.concatStringsSep ", ";
          in if isAttrs v then
            "{ ${
              concatItems (lib.attrsets.mapAttrsToList
                (key: value: "${key} = ${toDhall args value}") v)
            } }"
          else if isList v then
            "[ ${concatItems (map (toDhall args) v)} ]"
          else if isInt v then
            "${if v < 0 then "" else "+"}${toString v}"
          else if isBool v then
            (if v then "True" else "False")
          else if isFunction v then
            abort "generators.toDhall: cannot convert a function to Dhall"
          else if isNull v then
            abort "generators.toDhall: cannot convert a null to Dhall"
          else
            builtins.toJSON v;
      }
    );
    "/Users/jeffhykin/repos/nixpkgs/lib/cli.nix" = (# "/Users/jeffhykin/repos/nixpkgs/lib/cli.nix"
      { lib }:
      
      rec {
        /* Automatically convert an attribute set to command-line options.
      
           This helps protect against malformed command lines and also to reduce
           boilerplate related to command-line construction for simple use cases.
      
           `toGNUCommandLine` returns a list of nix strings.
           `toGNUCommandLineShell` returns an escaped shell string.
      
           Example:
             cli.toGNUCommandLine {} {
               data = builtins.toJSON { id = 0; };
               X = "PUT";
               retry = 3;
               retry-delay = null;
               url = [ "https://example.com/foo" "https://example.com/bar" ];
               silent = false;
               verbose = true;
             }
             => [
               "-X" "PUT"
               "--data" "{\"id\":0}"
               "--retry" "3"
               "--url" "https://example.com/foo"
               "--url" "https://example.com/bar"
               "--verbose"
             ]
      
             cli.toGNUCommandLineShell {} {
               data = builtins.toJSON { id = 0; };
               X = "PUT";
               retry = 3;
               retry-delay = null;
               url = [ "https://example.com/foo" "https://example.com/bar" ];
               silent = false;
               verbose = true;
             }
             => "'-X' 'PUT' '--data' '{\"id\":0}' '--retry' '3' '--url' 'https://example.com/foo' '--url' 'https://example.com/bar' '--verbose'";
        */
        toGNUCommandLineShell =
          options: attrs: lib.escapeShellArgs (toGNUCommandLine options attrs);
      
        toGNUCommandLine = {
          # how to string-format the option name;
          # by default one character is a short option (`-`),
          # more than one characters a long option (`--`).
          mkOptionName ?
            k: if builtins.stringLength k == 1
                then "-${k}"
                else "--${k}",
      
          # how to format a boolean value to a command list;
          # by default it’s a flag option
          # (only the option name if true, left out completely if false).
          mkBool ? k: v: lib.optional v (mkOptionName k),
      
          # how to format a list value to a command list;
          # by default the option name is repeated for each value
          # and `mkOption` is applied to the values themselves.
          mkList ? k: v: lib.concatMap (mkOption k) v,
      
          # how to format any remaining value to a command list;
          # on the toplevel, booleans and lists are handled by `mkBool` and `mkList`,
          # though they can still appear as values of a list.
          # By default, everything is printed verbatim and complex types
          # are forbidden (lists, attrsets, functions). `null` values are omitted.
          mkOption ?
            k: v: if v == null
                  then []
                  else [ (mkOptionName k) (lib.generators.mkValueStringDefault {} v) ]
          }:
          options:
            let
              render = k: v:
                if      builtins.isBool v then mkBool k v
                else if builtins.isList v then mkList k v
                else mkOption k v;
      
            in
              builtins.concatLists (lib.mapAttrsToList render options);
      }
    );
    "/Users/jeffhykin/repos/nixpkgs/lib/asserts.nix" = (# "/Users/jeffhykin/repos/nixpkgs/lib/asserts.nix"
      { lib }:
      
      rec {
      
        /* Throw if pred is false, else return pred.
           Intended to be used to augment asserts with helpful error messages.
      
           Example:
             assertMsg false "nope"
             stderr> error: nope
      
             assert assertMsg ("foo" == "bar") "foo is not bar, silly"; ""
             stderr> error: foo is not bar, silly
      
           Type:
             assertMsg :: Bool -> String -> Bool
        */
        # TODO(Profpatsch): add tests that check stderr
        assertMsg =
          # Predicate that needs to succeed, otherwise `msg` is thrown
          pred:
          # Message to throw in case `pred` fails
          msg:
          pred || builtins.throw msg;
      
        /* Specialized `assertMsg` for checking if `val` is one of the elements
           of the list `xs`. Useful for checking enums.
      
           Example:
             let sslLibrary = "libressl";
             in assertOneOf "sslLibrary" sslLibrary [ "openssl" "bearssl" ]
             stderr> error: sslLibrary must be one of [
             stderr>   "openssl"
             stderr>   "bearssl"
             stderr> ], but is: "libressl"
      
           Type:
             assertOneOf :: String -> ComparableVal -> List ComparableVal -> Bool
        */
        assertOneOf =
          # The name of the variable the user entered `val` into, for inclusion in the error message
          name:
          # The value of what the user provided, to be compared against the values in `xs`
          val:
          # The list of valid values
          xs:
          assertMsg
          (lib.elem val xs)
          "${name} must be one of ${
            lib.generators.toPretty {} xs}, but is: ${
              lib.generators.toPretty {} val}";
      
      }
    );
    "/Users/jeffhykin/repos/nixpkgs/lib/debug.nix" = (# "/Users/jeffhykin/repos/nixpkgs/lib/debug.nix"
      /* Collection of functions useful for debugging
         broken nix expressions.
      
         * `trace`-like functions take two values, print
           the first to stderr and return the second.
         * `traceVal`-like functions take one argument
           which both printed and returned.
         * `traceSeq`-like functions fully evaluate their
           traced value before printing (not just to “weak
           head normal form” like trace does by default).
         * Functions that end in `-Fn` take an additional
           function as their first argument, which is applied
           to the traced value before it is printed.
      */
      { lib }:
      let
        inherit (lib)
          isInt
          attrNames
          isList
          isAttrs
          substring
          addErrorContext
          attrValues
          concatLists
          concatStringsSep
          const
          elem
          generators
          head
          id
          isDerivation
          isFunction
          mapAttrs
          trace;
      in
      
      rec {
      
        # -- TRACING --
      
        /* Conditionally trace the supplied message, based on a predicate.
      
           Type: traceIf :: bool -> string -> a -> a
      
           Example:
             traceIf true "hello" 3
             trace: hello
             => 3
        */
        traceIf =
          # Predicate to check
          pred:
          # Message that should be traced
          msg:
          # Value to return
          x: if pred then trace msg x else x;
      
        /* Trace the supplied value after applying a function to it, and
           return the original value.
      
           Type: traceValFn :: (a -> b) -> a -> a
      
           Example:
             traceValFn (v: "mystring ${v}") "foo"
             trace: mystring foo
             => "foo"
        */
        traceValFn =
          # Function to apply
          f:
          # Value to trace and return
          x: trace (f x) x;
      
        /* Trace the supplied value and return it.
      
           Type: traceVal :: a -> a
      
           Example:
             traceVal 42
             # trace: 42
             => 42
        */
        traceVal = traceValFn id;
      
        /* `builtins.trace`, but the value is `builtins.deepSeq`ed first.
      
           Type: traceSeq :: a -> b -> b
      
           Example:
             trace { a.b.c = 3; } null
             trace: { a = <CODE>; }
             => null
             traceSeq { a.b.c = 3; } null
             trace: { a = { b = { c = 3; }; }; }
             => null
        */
        traceSeq =
          # The value to trace
          x:
          # The value to return
          y: trace (builtins.deepSeq x x) y;
      
        /* Like `traceSeq`, but only evaluate down to depth n.
           This is very useful because lots of `traceSeq` usages
           lead to an infinite recursion.
      
           Example:
             traceSeqN 2 { a.b.c = 3; } null
             trace: { a = { b = {…}; }; }
             => null
         */
        traceSeqN = depth: x: y:
          let snip = v: if      isList  v then noQuotes "[…]" v
                        else if isAttrs v then noQuotes "{…}" v
                        else v;
              noQuotes = str: v: { __pretty = const str; val = v; };
              modify = n: fn: v: if (n == 0) then fn v
                            else if isList  v then map (modify (n - 1) fn) v
                            else if isAttrs v then mapAttrs
                              (const (modify (n - 1) fn)) v
                            else v;
          in trace (generators.toPretty { allowPrettyValues = true; }
                     (modify depth snip x)) y;
      
        /* A combination of `traceVal` and `traceSeq` that applies a
           provided function to the value to be traced after `deepSeq`ing
           it.
        */
        traceValSeqFn =
          # Function to apply
          f:
          # Value to trace
          v: traceValFn f (builtins.deepSeq v v);
      
        /* A combination of `traceVal` and `traceSeq`. */
        traceValSeq = traceValSeqFn id;
      
        /* A combination of `traceVal` and `traceSeqN` that applies a
        provided function to the value to be traced. */
        traceValSeqNFn =
          # Function to apply
          f:
          depth:
          # Value to trace
          v: traceSeqN depth (f v) v;
      
        /* A combination of `traceVal` and `traceSeqN`. */
        traceValSeqN = traceValSeqNFn id;
      
        /* Trace the input and output of a function `f` named `name`,
        both down to `depth`.
      
        This is useful for adding around a function call,
        to see the before/after of values as they are transformed.
      
           Example:
             traceFnSeqN 2 "id" (x: x) { a.b.c = 3; }
             trace: { fn = "id"; from = { a.b = {…}; }; to = { a.b = {…}; }; }
             => { a.b.c = 3; }
        */
        traceFnSeqN = depth: name: f: v:
          let res = f v;
          in lib.traceSeqN
              (depth + 1)
              {
                fn = name;
                from = v;
                to = res;
              }
              res;
      
      
        # -- TESTING --
      
        /* Evaluate a set of tests.  A test is an attribute set `{expr,
           expected}`, denoting an expression and its expected result.  The
           result is a list of failed tests, each represented as `{name,
           expected, actual}`, denoting the attribute name of the failing
           test and its expected and actual results.
      
           Used for regression testing of the functions in lib; see
           tests.nix for an example. Only tests having names starting with
           "test" are run.
      
           Add attr { tests = ["testName"]; } to run these tests only.
        */
        runTests =
          # Tests to run
          tests: concatLists (attrValues (mapAttrs (name: test:
          let testsToRun = if tests ? tests then tests.tests else [];
          in if (substring 0 4 name == "test" ||  elem name testsToRun)
             && ((testsToRun == []) || elem name tests.tests)
             && (test.expr != test.expected)
      
            then [ { inherit name; expected = test.expected; result = test.expr; } ]
            else [] ) tests));
      
        /* Create a test assuming that list elements are `true`.
      
           Example:
             { testX = allTrue [ true ]; }
        */
        testAllTrue = expr: { inherit expr; expected = map (x: true) expr; };
      
      
        # -- DEPRECATED --
      
        traceShowVal = x: trace (showVal x) x;
        traceShowValMarked = str: x: trace (str + showVal x) x;
      
        attrNamesToStr = a:
          trace ( "Warning: `attrNamesToStr` is deprecated "
                + "and will be removed in the next release. "
                + "Please use more specific concatenation "
                + "for your uses (`lib.concat(Map)StringsSep`)." )
          (concatStringsSep "; " (map (x: "${x}=") (attrNames a)));
      
        showVal =
          trace ( "Warning: `showVal` is deprecated "
                + "and will be removed in the next release, "
                + "please use `traceSeqN`" )
          (let
            modify = v:
              let pr = f: { __pretty = f; val = v; };
              in   if isDerivation v then pr
                (drv: "<δ:${drv.name}:${concatStringsSep ","
                                       (attrNames drv)}>")
              else if [] ==   v then pr (const "[]")
              else if isList  v then pr (l: "[ ${go (head l)}, … ]")
              else if isAttrs v then pr
                (a: "{ ${ concatStringsSep ", " (attrNames a)} }")
              else v;
            go = x: generators.toPretty
              { allowPrettyValues = true; }
              (modify x);
          in go);
      
        traceXMLVal = x:
          trace ( "Warning: `traceXMLVal` is deprecated "
                + "and will be removed in the next release. "
                + "Please use `traceValFn builtins.toXML`." )
          (trace (builtins.toXML x) x);
        traceXMLValMarked = str: x:
          trace ( "Warning: `traceXMLValMarked` is deprecated "
                + "and will be removed in the next release. "
                + "Please use `traceValFn (x: str + builtins.toXML x)`." )
          (trace (str + builtins.toXML x) x);
      
        # trace the arguments passed to function and its result
        # maybe rewrite these functions in a traceCallXml like style. Then one function is enough
        traceCall  = n: f: a: let t = n2: x: traceShowValMarked "${n} ${n2}:" x; in t "result" (f (t "arg 1" a));
        traceCall2 = n: f: a: b: let t = n2: x: traceShowValMarked "${n} ${n2}:" x; in t "result" (f (t "arg 1" a) (t "arg 2" b));
        traceCall3 = n: f: a: b: c: let t = n2: x: traceShowValMarked "${n} ${n2}:" x; in t "result" (f (t "arg 1" a) (t "arg 2" b) (t "arg 3" c));
      
        traceValIfNot = c: x:
          trace ( "Warning: `traceValIfNot` is deprecated "
                + "and will be removed in the next release. "
                + "Please use `if/then/else` and `traceValSeq 1`.")
          (if c x then true else traceSeq (showVal x) false);
      
      
        addErrorContextToAttrs = attrs:
          trace ( "Warning: `addErrorContextToAttrs` is deprecated "
                + "and will be removed in the next release. "
                + "Please use `builtins.addErrorContext` directly." )
          (mapAttrs (a: v: addErrorContext "while evaluating ${a}" v) attrs);
      
        # example: (traceCallXml "myfun" id 3) will output something like
        # calling myfun arg 1: 3 result: 3
        # this forces deep evaluation of all arguments and the result!
        # note: if result doesn't evaluate you'll get no trace at all (FIXME)
        #       args should be printed in any case
        traceCallXml = a:
          trace ( "Warning: `traceCallXml` is deprecated "
                + "and will be removed in the next release. "
                + "Please complain if you use the function regularly." )
          (if !isInt a then
            traceCallXml 1 "calling ${a}\n"
          else
            let nr = a;
            in (str: expr:
                if isFunction expr then
                  (arg:
                    traceCallXml (builtins.add 1 nr) "${str}\n arg ${builtins.toString nr} is \n ${builtins.toXML (builtins.seq arg arg)}" (expr arg)
                  )
                else
                  let r = builtins.seq expr expr;
                  in trace "${str}\n result:\n${builtins.toXML r}" r
            ));
      }
    );
    "/Users/jeffhykin/repos/nixpkgs/lib/systems/doubles.nix" = (# "/Users/jeffhykin/repos/nixpkgs/lib/systems/doubles.nix"
      { lib }:
      let
        inherit (lib) lists;
        inherit (lib.systems) parse;
        inherit (lib.systems.inspect) predicates;
        inherit (lib.attrsets) matchAttrs;
      
        all = [
          # Cygwin
          "i686-cygwin" "x86_64-cygwin"
      
          # Darwin
          "x86_64-darwin" "i686-darwin" "aarch64-darwin" "armv7a-darwin"
      
          # FreeBSD
          "i686-freebsd13" "x86_64-freebsd13"
      
          # Genode
          "aarch64-genode" "i686-genode" "x86_64-genode"
      
          # illumos
          "x86_64-solaris"
      
          # JS
          "js-ghcjs"
      
          # Linux
          "aarch64-linux" "armv5tel-linux" "armv6l-linux" "armv7a-linux"
          "armv7l-linux" "i686-linux" "m68k-linux" "microblaze-linux"
          "microblazeel-linux" "mipsel-linux" "mips64el-linux" "powerpc64-linux"
          "powerpc64le-linux" "riscv32-linux" "riscv64-linux" "s390-linux"
          "s390x-linux" "x86_64-linux"
      
          # MMIXware
          "mmix-mmixware"
      
          # NetBSD
          "aarch64-netbsd" "armv6l-netbsd" "armv7a-netbsd" "armv7l-netbsd"
          "i686-netbsd" "m68k-netbsd" "mipsel-netbsd" "powerpc-netbsd"
          "riscv32-netbsd" "riscv64-netbsd" "x86_64-netbsd"
      
          # none
          "aarch64_be-none" "aarch64-none" "arm-none" "armv6l-none" "avr-none" "i686-none"
          "microblaze-none" "microblazeel-none" "msp430-none" "or1k-none" "m68k-none"
          "powerpc-none" "powerpcle-none" "riscv32-none" "riscv64-none" "rx-none"
          "s390-none" "s390x-none" "vc4-none" "x86_64-none"
      
          # OpenBSD
          "i686-openbsd" "x86_64-openbsd"
      
          # Redox
          "x86_64-redox"
      
          # WASI
          "wasm64-wasi" "wasm32-wasi"
      
          # Windows
          "x86_64-windows" "i686-windows"
        ];
      
        allParsed = map parse.mkSystemFromString all;
      
        filterDoubles = f: map parse.doubleFromSystem (lists.filter f allParsed);
      
      in {
        inherit all;
      
        none = [];
      
        arm           = filterDoubles predicates.isAarch32;
        armv7         = filterDoubles predicates.isArmv7;
        aarch64       = filterDoubles predicates.isAarch64;
        x86           = filterDoubles predicates.isx86;
        i686          = filterDoubles predicates.isi686;
        x86_64        = filterDoubles predicates.isx86_64;
        microblaze    = filterDoubles predicates.isMicroBlaze;
        mips          = filterDoubles predicates.isMips;
        mmix          = filterDoubles predicates.isMmix;
        power         = filterDoubles predicates.isPower;
        riscv         = filterDoubles predicates.isRiscV;
        riscv32       = filterDoubles predicates.isRiscV32;
        riscv64       = filterDoubles predicates.isRiscV64;
        rx            = filterDoubles predicates.isRx;
        vc4           = filterDoubles predicates.isVc4;
        or1k          = filterDoubles predicates.isOr1k;
        m68k          = filterDoubles predicates.isM68k;
        s390          = filterDoubles predicates.isS390;
        s390x         = filterDoubles predicates.isS390x;
        js            = filterDoubles predicates.isJavaScript;
      
        bigEndian     = filterDoubles predicates.isBigEndian;
        littleEndian  = filterDoubles predicates.isLittleEndian;
      
        cygwin        = filterDoubles predicates.isCygwin;
        darwin        = filterDoubles predicates.isDarwin;
        freebsd       = filterDoubles predicates.isFreeBSD;
        # Should be better, but MinGW is unclear.
        gnu           = filterDoubles (matchAttrs { kernel = parse.kernels.linux; abi = parse.abis.gnu; })
                        ++ filterDoubles (matchAttrs { kernel = parse.kernels.linux; abi = parse.abis.gnueabi; })
                        ++ filterDoubles (matchAttrs { kernel = parse.kernels.linux; abi = parse.abis.gnueabihf; })
                        ++ filterDoubles (matchAttrs { kernel = parse.kernels.linux; abi = parse.abis.gnuabin32; })
                        ++ filterDoubles (matchAttrs { kernel = parse.kernels.linux; abi = parse.abis.gnuabi64; })
                        ++ filterDoubles (matchAttrs { kernel = parse.kernels.linux; abi = parse.abis.gnuabielfv1; })
                        ++ filterDoubles (matchAttrs { kernel = parse.kernels.linux; abi = parse.abis.gnuabielfv2; });
        illumos       = filterDoubles predicates.isSunOS;
        linux         = filterDoubles predicates.isLinux;
        netbsd        = filterDoubles predicates.isNetBSD;
        openbsd       = filterDoubles predicates.isOpenBSD;
        unix          = filterDoubles predicates.isUnix;
        wasi          = filterDoubles predicates.isWasi;
        redox         = filterDoubles predicates.isRedox;
        windows       = filterDoubles predicates.isWindows;
        genode        = filterDoubles predicates.isGenode;
      
        embedded      = filterDoubles predicates.isNone;
      
        mesaPlatforms = ["i686-linux" "x86_64-linux" "x86_64-darwin" "armv5tel-linux" "armv6l-linux" "armv7l-linux" "armv7a-linux" "aarch64-linux" "powerpc64-linux" "powerpc64le-linux" "aarch64-darwin" "riscv64-linux"];
      }
    );
    "/Users/jeffhykin/repos/nixpkgs/lib/deprecated.nix" = (# "/Users/jeffhykin/repos/nixpkgs/lib/deprecated.nix"
      { lib }:
      let
          inherit (builtins) head tail isList isAttrs isInt attrNames;
      
      in
      
      with lib.lists;
      with lib.attrsets;
      with lib.strings;
      
      rec {
      
        # returns default if env var is not set
        maybeEnv = name: default:
          let value = builtins.getEnv name; in
          if value == "" then default else value;
      
        defaultMergeArg = x : y: if builtins.isAttrs y then
          y
        else
          (y x);
        defaultMerge = x: y: x // (defaultMergeArg x y);
        foldArgs = merger: f: init: x:
          let arg = (merger init (defaultMergeArg init x));
              # now add the function with composed args already applied to the final attrs
              base = (setAttrMerge "passthru" {} (f arg)
                              ( z: z // {
                                  function = foldArgs merger f arg;
                                  args = (lib.attrByPath ["passthru" "args"] {} z) // x;
                                } ));
              withStdOverrides = base // {
                override = base.passthru.function;
              };
              in
                withStdOverrides;
      
      
        # shortcut for attrByPath ["name"] default attrs
        maybeAttrNullable = maybeAttr;
      
        # shortcut for attrByPath ["name"] default attrs
        maybeAttr = name: default: attrs: attrs.${name} or default;
      
      
        # Return the second argument if the first one is true or the empty version
        # of the second argument.
        ifEnable = cond: val:
          if cond then val
          else if builtins.isList val then []
          else if builtins.isAttrs val then {}
          # else if builtins.isString val then ""
          else if val == true || val == false then false
          else null;
      
      
        # Return true only if there is an attribute and it is true.
        checkFlag = attrSet: name:
              if name == "true" then true else
              if name == "false" then false else
              if (elem name (attrByPath ["flags"] [] attrSet)) then true else
              attrByPath [name] false attrSet ;
      
      
        # Input : attrSet, [ [name default] ... ], name
        # Output : its value or default.
        getValue = attrSet: argList: name:
        ( attrByPath [name] (if checkFlag attrSet name then true else
              if argList == [] then null else
              let x = builtins.head argList; in
                      if (head x) == name then
                              (head (tail x))
                      else (getValue attrSet
                              (tail argList) name)) attrSet );
      
      
        # Input : attrSet, [[name default] ...], [ [flagname reqs..] ... ]
        # Output : are reqs satisfied? It's asserted.
        checkReqs = attrSet: argList: condList:
        (
          foldr lib.and true
            (map (x: let name = (head x); in
      
              ((checkFlag attrSet name) ->
              (foldr lib.and true
              (map (y: let val=(getValue attrSet argList y); in
                      (val!=null) && (val!=false))
              (tail x))))) condList));
      
      
        # This function has O(n^2) performance.
        uniqList = { inputList, acc ? [] }:
          let go = xs: acc:
                   if xs == []
                   then []
                   else let x = head xs;
                            y = if elem x acc then [] else [x];
                        in y ++ go (tail xs) (y ++ acc);
          in go inputList acc;
      
        uniqListExt = { inputList,
                        outputList ? [],
                        getter ? (x: x),
                        compare ? (x: y: x==y) }:
              if inputList == [] then outputList else
              let x = head inputList;
                  isX = y: (compare (getter y) (getter x));
                  newOutputList = outputList ++
                      (if any isX outputList then [] else [x]);
              in uniqListExt { outputList = newOutputList;
                               inputList = (tail inputList);
                               inherit getter compare;
                             };
      
        condConcat = name: list: checker:
              if list == [] then name else
              if checker (head list) then
                      condConcat
                              (name + (head (tail list)))
                              (tail (tail list))
                              checker
              else condConcat
                      name (tail (tail list)) checker;
      
        lazyGenericClosure = {startSet, operator}:
          let
            work = list: doneKeys: result:
              if list == [] then
                result
              else
                let x = head list; key = x.key; in
                if elem key doneKeys then
                  work (tail list) doneKeys result
                else
                  work (tail list ++ operator x) ([key] ++ doneKeys) ([x] ++ result);
          in
            work startSet [] [];
      
        innerModifySumArgs = f: x: a: b: if b == null then (f a b) // x else
              innerModifySumArgs f x (a // b);
        modifySumArgs = f: x: innerModifySumArgs f x {};
      
      
        innerClosePropagation = acc: xs:
          if xs == []
          then acc
          else let y  = head xs;
                   ys = tail xs;
               in if ! isAttrs y
                  then innerClosePropagation acc ys
                  else let acc' = [y] ++ acc;
                       in innerClosePropagation
                            acc'
                            (uniqList { inputList = (maybeAttrNullable "propagatedBuildInputs" [] y)
                                                 ++ (maybeAttrNullable "propagatedNativeBuildInputs" [] y)
                                                 ++ ys;
                                        acc = acc';
                                      }
                            );
      
        closePropagationSlow = list: (uniqList {inputList = (innerClosePropagation [] list);});
      
        # This is an optimisation of lib.closePropagation which avoids the O(n^2) behavior
        # Using a list of derivations, it generates the full closure of the propagatedXXXBuildInputs
        # The ordering / sorting / comparison is done based on the `outPath`
        # attribute of each derivation.
        # On some benchmarks, it performs up to 15 times faster than lib.closePropagation.
        # See https://github.com/NixOS/nixpkgs/pull/194391 for details.
        closePropagationFast = list:
          builtins.map (x: x.val) (builtins.genericClosure {
            startSet = builtins.map (x: {
              key = x.outPath;
              val = x;
            }) (builtins.filter (x: x != null) list);
            operator = item:
              if !builtins.isAttrs item.val then
                [ ]
              else
                builtins.concatMap (x:
                  if x != null then [{
                    key = x.outPath;
                    val = x;
                  }] else
                    [ ]) ((item.val.propagatedBuildInputs or [ ])
                      ++ (item.val.propagatedNativeBuildInputs or [ ]));
          });
      
        closePropagation = if builtins ? genericClosure
          then closePropagationFast
          else closePropagationSlow;
      
        # calls a function (f attr value ) for each record item. returns a list
        mapAttrsFlatten = f: r: map (attr: f attr r.${attr}) (attrNames r);
      
        # attribute set containing one attribute
        nvs = name: value: listToAttrs [ (nameValuePair name value) ];
        # adds / replaces an attribute of an attribute set
        setAttr = set: name: v: set // (nvs name v);
      
        # setAttrMerge (similar to mergeAttrsWithFunc but only merges the values of a particular name)
        # setAttrMerge "a" [] { a = [2];} (x: x ++ [3]) -> { a = [2 3]; }
        # setAttrMerge "a" [] {         } (x: x ++ [3]) -> { a = [  3]; }
        setAttrMerge = name: default: attrs: f:
          setAttr attrs name (f (maybeAttr name default attrs));
      
        # Using f = a: b = b the result is similar to //
        # merge attributes with custom function handling the case that the attribute
        # exists in both sets
        mergeAttrsWithFunc = f: set1: set2:
          foldr (n: set: if set ? ${n}
                              then setAttr set n (f set.${n} set2.${n})
                              else set )
                 (set2 // set1) (attrNames set2);
      
        # merging two attribute set concatenating the values of same attribute names
        # eg { a = 7; } {  a = [ 2 3 ]; } becomes { a = [ 7 2 3 ]; }
        mergeAttrsConcatenateValues = mergeAttrsWithFunc ( a: b: (toList a) ++ (toList b) );
      
        # merges attributes using //, if a name exists in both attributes
        # an error will be triggered unless its listed in mergeLists
        # so you can mergeAttrsNoOverride { buildInputs = [a]; } { buildInputs = [a]; } {} to get
        # { buildInputs = [a b]; }
        # merging buildPhase doesn't really make sense. The cases will be rare where appending /prefixing will fit your needs?
        # in these cases the first buildPhase will override the second one
        # ! deprecated, use mergeAttrByFunc instead
        mergeAttrsNoOverride = { mergeLists ? ["buildInputs" "propagatedBuildInputs"],
                                 overrideSnd ? [ "buildPhase" ]
                               }: attrs1: attrs2:
          foldr (n: set:
              setAttr set n ( if set ? ${n}
                  then # merge
                    if elem n mergeLists # attribute contains list, merge them by concatenating
                      then attrs2.${n} ++ attrs1.${n}
                    else if elem n overrideSnd
                      then attrs1.${n}
                    else throw "error mergeAttrsNoOverride, attribute ${n} given in both attributes - no merge func defined"
                  else attrs2.${n} # add attribute not existing in attr1
                 )) attrs1 (attrNames attrs2);
      
      
        # example usage:
        # mergeAttrByFunc  {
        #   inherit mergeAttrBy; # defined below
        #   buildInputs = [ a b ];
        # } {
        #  buildInputs = [ c d ];
        # };
        # will result in
        # { mergeAttrsBy = [...]; buildInputs = [ a b c d ]; }
        # is used by defaultOverridableDelayableArgs and can be used when composing using
        # foldArgs, composedArgsAndFun or applyAndFun. Example: composableDerivation in all-packages.nix
        mergeAttrByFunc = x: y:
          let
                mergeAttrBy2 = { mergeAttrBy = lib.mergeAttrs; }
                            // (maybeAttr "mergeAttrBy" {} x)
                            // (maybeAttr "mergeAttrBy" {} y); in
          foldr lib.mergeAttrs {} [
            x y
            (mapAttrs ( a: v: # merge special names using given functions
                if x ? ${a}
                   then if y ? ${a}
                     then v x.${a} y.${a} # both have attr, use merge func
                     else x.${a} # only x has attr
                   else y.${a} # only y has attr)
                ) (removeAttrs mergeAttrBy2
                               # don't merge attrs which are neither in x nor y
                               (filter (a: ! x ? ${a} && ! y ? ${a})
                                       (attrNames mergeAttrBy2))
                  )
            )
          ];
        mergeAttrsByFuncDefaults = foldl mergeAttrByFunc { inherit mergeAttrBy; };
        mergeAttrsByFuncDefaultsClean = list: removeAttrs (mergeAttrsByFuncDefaults list) ["mergeAttrBy"];
      
        # sane defaults (same name as attr name so that inherit can be used)
        mergeAttrBy = # { buildInputs = concatList; [...]; passthru = mergeAttr; [..]; }
          listToAttrs (map (n: nameValuePair n lib.concat)
            [ "nativeBuildInputs" "buildInputs" "propagatedBuildInputs" "configureFlags" "prePhases" "postAll" "patches" ])
          // listToAttrs (map (n: nameValuePair n lib.mergeAttrs) [ "passthru" "meta" "cfg" "flags" ])
          // listToAttrs (map (n: nameValuePair n (a: b: "${a}\n${b}") ) [ "preConfigure" "postInstall" ])
        ;
      
        nixType = x:
            if isAttrs x then
                if x ? outPath then "derivation"
                else "attrs"
            else if lib.isFunction x then "function"
            else if isList x then "list"
            else if x == true then "bool"
            else if x == false then "bool"
            else if x == null then "null"
            else if isInt x then "int"
            else "string";
      
        /* deprecated:
      
           For historical reasons, imap has an index starting at 1.
      
           But for consistency with the rest of the library we want an index
           starting at zero.
        */
        imap = imap1;
      
        # Fake hashes. Can be used as hash placeholders, when computing hash ahead isn't trivial
        fakeHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
        fakeSha256 = "0000000000000000000000000000000000000000000000000000000000000000";
        fakeSha512 = "00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
      }
    );
    "/Users/jeffhykin/repos/nixpkgs/lib/fetchers.nix" = (# "/Users/jeffhykin/repos/nixpkgs/lib/fetchers.nix"
      # snippets that can be shared by multiple fetchers (pkgs/build-support)
      { lib }:
      {
      
        proxyImpureEnvVars = [
          # We borrow these environment variables from the caller to allow
          # easy proxy configuration.  This is impure, but a fixed-output
          # derivation like fetchurl is allowed to do so since its result is
          # by definition pure.
          "http_proxy" "https_proxy" "ftp_proxy" "all_proxy" "no_proxy"
        ];
      
      }
    );
    "/Users/jeffhykin/repos/nixpkgs/lib/systems/parse.nix" = (# "/Users/jeffhykin/repos/nixpkgs/lib/systems/parse.nix"
      # Define the list of system with their properties.
      #
      # See https://clang.llvm.org/docs/CrossCompilation.html and
      # http://llvm.org/docs/doxygen/html/Triple_8cpp_source.html especially
      # Triple::normalize. Parsing should essentially act as a more conservative
      # version of that last function.
      #
      # Most of the types below come in "open" and "closed" pairs. The open ones
      # specify what information we need to know about systems in general, and the
      # closed ones are sub-types representing the whitelist of systems we support in
      # practice.
      #
      # Code in the remainder of nixpkgs shouldn't rely on the closed ones in
      # e.g. exhaustive cases. Its more a sanity check to make sure nobody defines
      # systems that overlap with existing ones and won't notice something amiss.
      #
      { lib }:
      with lib.lists;
      with lib.types;
      with lib.attrsets;
      with lib.strings;
      with (/*import:normal*/ _-_06294632224836068_-_."/Users/jeffhykin/repos/nixpkgs/lib/systems/inspect.nix" { inherit lib; }).predicates;
      
      let
        inherit (lib.options) mergeOneOption;
      
        setTypes = type:
          mapAttrs (name: value:
            assert type.check value;
            setType type.name ({ inherit name; } // value));
      
      in
      
      rec {
      
        ################################################################################
      
        types.openSignificantByte = mkOptionType {
          name = "significant-byte";
          description = "Endianness";
          merge = mergeOneOption;
        };
      
        types.significantByte = enum (attrValues significantBytes);
      
        significantBytes = setTypes types.openSignificantByte {
          bigEndian = {};
          littleEndian = {};
        };
      
        ################################################################################
      
        # Reasonable power of 2
        types.bitWidth = enum [ 8 16 32 64 128 ];
      
        ################################################################################
      
        types.openCpuType = mkOptionType {
          name = "cpu-type";
          description = "instruction set architecture name and information";
          merge = mergeOneOption;
          check = x: types.bitWidth.check x.bits
            && (if 8 < x.bits
                then types.significantByte.check x.significantByte
                else !(x ? significantByte));
        };
      
        types.cpuType = enum (attrValues cpuTypes);
      
        cpuTypes = with significantBytes; setTypes types.openCpuType {
          arm      = { bits = 32; significantByte = littleEndian; family = "arm"; };
          armv5tel = { bits = 32; significantByte = littleEndian; family = "arm"; version = "5"; arch = "armv5t"; };
          armv6m   = { bits = 32; significantByte = littleEndian; family = "arm"; version = "6"; arch = "armv6-m"; };
          armv6l   = { bits = 32; significantByte = littleEndian; family = "arm"; version = "6"; arch = "armv6"; };
          armv7a   = { bits = 32; significantByte = littleEndian; family = "arm"; version = "7"; arch = "armv7-a"; };
          armv7r   = { bits = 32; significantByte = littleEndian; family = "arm"; version = "7"; arch = "armv7-r"; };
          armv7m   = { bits = 32; significantByte = littleEndian; family = "arm"; version = "7"; arch = "armv7-m"; };
          armv7l   = { bits = 32; significantByte = littleEndian; family = "arm"; version = "7"; arch = "armv7"; };
          armv8a   = { bits = 32; significantByte = littleEndian; family = "arm"; version = "8"; arch = "armv8-a"; };
          armv8r   = { bits = 32; significantByte = littleEndian; family = "arm"; version = "8"; arch = "armv8-a"; };
          armv8m   = { bits = 32; significantByte = littleEndian; family = "arm"; version = "8"; arch = "armv8-m"; };
          aarch64  = { bits = 64; significantByte = littleEndian; family = "arm"; version = "8"; arch = "armv8-a"; };
          aarch64_be = { bits = 64; significantByte = bigEndian; family = "arm"; version = "8";  arch = "armv8-a"; };
      
          i386     = { bits = 32; significantByte = littleEndian; family = "x86"; arch = "i386"; };
          i486     = { bits = 32; significantByte = littleEndian; family = "x86"; arch = "i486"; };
          i586     = { bits = 32; significantByte = littleEndian; family = "x86"; arch = "i586"; };
          i686     = { bits = 32; significantByte = littleEndian; family = "x86"; arch = "i686"; };
          x86_64   = { bits = 64; significantByte = littleEndian; family = "x86"; arch = "x86-64"; };
      
          microblaze   = { bits = 32; significantByte = bigEndian;    family = "microblaze"; };
          microblazeel = { bits = 32; significantByte = littleEndian; family = "microblaze"; };
      
          mips          = { bits = 32; significantByte = bigEndian;    family = "mips"; };
          mipsel        = { bits = 32; significantByte = littleEndian; family = "mips"; };
          mipsisa32r6   = { bits = 32; significantByte = bigEndian;    family = "mips"; };
          mipsisa32r6el = { bits = 32; significantByte = littleEndian; family = "mips"; };
          mips64        = { bits = 64; significantByte = bigEndian;    family = "mips"; };
          mips64el      = { bits = 64; significantByte = littleEndian; family = "mips"; };
          mipsisa64r6   = { bits = 64; significantByte = bigEndian;    family = "mips"; };
          mipsisa64r6el = { bits = 64; significantByte = littleEndian; family = "mips"; };
      
          mmix     = { bits = 64; significantByte = bigEndian;    family = "mmix"; };
      
          m68k     = { bits = 32; significantByte = bigEndian; family = "m68k"; };
      
          powerpc  = { bits = 32; significantByte = bigEndian;    family = "power"; };
          powerpc64 = { bits = 64; significantByte = bigEndian; family = "power"; };
          powerpc64le = { bits = 64; significantByte = littleEndian; family = "power"; };
          powerpcle = { bits = 32; significantByte = littleEndian; family = "power"; };
      
          riscv32  = { bits = 32; significantByte = littleEndian; family = "riscv"; };
          riscv64  = { bits = 64; significantByte = littleEndian; family = "riscv"; };
      
          s390     = { bits = 32; significantByte = bigEndian; family = "s390"; };
          s390x    = { bits = 64; significantByte = bigEndian; family = "s390"; };
      
          sparc    = { bits = 32; significantByte = bigEndian;    family = "sparc"; };
          sparc64  = { bits = 64; significantByte = bigEndian;    family = "sparc"; };
      
          wasm32   = { bits = 32; significantByte = littleEndian; family = "wasm"; };
          wasm64   = { bits = 64; significantByte = littleEndian; family = "wasm"; };
      
          alpha    = { bits = 64; significantByte = littleEndian; family = "alpha"; };
      
          rx       = { bits = 32; significantByte = littleEndian; family = "rx"; };
          msp430   = { bits = 16; significantByte = littleEndian; family = "msp430"; };
          avr      = { bits = 8; family = "avr"; };
      
          vc4      = { bits = 32; significantByte = littleEndian; family = "vc4"; };
      
          or1k     = { bits = 32; significantByte = bigEndian; family = "or1k"; };
      
          js       = { bits = 32; significantByte = littleEndian; family = "js"; };
        };
      
        # GNU build systems assume that older NetBSD architectures are using a.out.
        gnuNetBSDDefaultExecFormat = cpu:
          if (cpu.family == "arm" && cpu.bits == 32) ||
             (cpu.family == "sparc" && cpu.bits == 32) ||
             (cpu.family == "m68k" && cpu.bits == 32) ||
             (cpu.family == "x86" && cpu.bits == 32)
          then execFormats.aout
          else execFormats.elf;
      
        # Determine when two CPUs are compatible with each other. That is,
        # can code built for system B run on system A? For that to happen,
        # the programs that system B accepts must be a subset of the
        # programs that system A accepts.
        #
        # We have the following properties of the compatibility relation,
        # which must be preserved when adding compatibility information for
        # additional CPUs.
        # - (reflexivity)
        #   Every CPU is compatible with itself.
        # - (transitivity)
        #   If A is compatible with B and B is compatible with C then A is compatible with C.
        #
        # Note: Since 22.11 the archs of a mode switching CPU are no longer considered
        # pairwise compatible. Mode switching implies that binaries built for A
        # and B respectively can't be executed at the same time.
        isCompatible = a: b: with cpuTypes; lib.any lib.id [
          # x86
          (b == i386 && isCompatible a i486)
          (b == i486 && isCompatible a i586)
          (b == i586 && isCompatible a i686)
      
          # XXX: Not true in some cases. Like in WSL mode.
          (b == i686 && isCompatible a x86_64)
      
          # ARMv4
          (b == arm && isCompatible a armv5tel)
      
          # ARMv5
          (b == armv5tel && isCompatible a armv6l)
      
          # ARMv6
          (b == armv6l && isCompatible a armv6m)
          (b == armv6m && isCompatible a armv7l)
      
          # ARMv7
          (b == armv7l && isCompatible a armv7a)
          (b == armv7l && isCompatible a armv7r)
          (b == armv7l && isCompatible a armv7m)
          (b == armv7a && isCompatible a armv8a)
          (b == armv7r && isCompatible a armv8a)
          (b == armv7m && isCompatible a armv8a)
          (b == armv7a && isCompatible a armv8r)
          (b == armv7r && isCompatible a armv8r)
          (b == armv7m && isCompatible a armv8r)
          (b == armv7a && isCompatible a armv8m)
          (b == armv7r && isCompatible a armv8m)
          (b == armv7m && isCompatible a armv8m)
      
          # ARMv8
          (b == armv8r && isCompatible a armv8a)
          (b == armv8m && isCompatible a armv8a)
      
          # XXX: not always true! Some arm64 cpus don’t support arm32 mode.
          (b == aarch64 && a == armv8a)
          (b == armv8a && isCompatible a aarch64)
      
          # PowerPC
          (b == powerpc && isCompatible a powerpc64)
          (b == powerpcle && isCompatible a powerpc64le)
      
          # MIPS
          (b == mips && isCompatible a mips64)
          (b == mipsel && isCompatible a mips64el)
      
          # RISCV
          (b == riscv32 && isCompatible a riscv64)
      
          # SPARC
          (b == sparc && isCompatible a sparc64)
      
          # WASM
          (b == wasm32 && isCompatible a wasm64)
      
          # identity
          (b == a)
        ];
      
        ################################################################################
      
        types.openVendor = mkOptionType {
          name = "vendor";
          description = "vendor for the platform";
          merge = mergeOneOption;
        };
      
        types.vendor = enum (attrValues vendors);
      
        vendors = setTypes types.openVendor {
          apple = {};
          pc = {};
          # Actually matters, unlocking some MinGW-w64-specific options in GCC. See
          # bottom of https://sourceforge.net/p/mingw-w64/wiki2/Unicode%20apps/
          w64 = {};
      
          none = {};
          unknown = {};
        };
      
        ################################################################################
      
        types.openExecFormat = mkOptionType {
          name = "exec-format";
          description = "executable container used by the kernel";
          merge = mergeOneOption;
        };
      
        types.execFormat = enum (attrValues execFormats);
      
        execFormats = setTypes types.openExecFormat {
          aout = {}; # a.out
          elf = {};
          macho = {};
          pe = {};
          wasm = {};
      
          unknown = {};
        };
      
        ################################################################################
      
        types.openKernelFamily = mkOptionType {
          name = "exec-format";
          description = "executable container used by the kernel";
          merge = mergeOneOption;
        };
      
        types.kernelFamily = enum (attrValues kernelFamilies);
      
        kernelFamilies = setTypes types.openKernelFamily {
          bsd = {};
          darwin = {};
        };
      
        ################################################################################
      
        types.openKernel = mkOptionType {
          name = "kernel";
          description = "kernel name and information";
          merge = mergeOneOption;
          check = x: types.execFormat.check x.execFormat
              && all types.kernelFamily.check (attrValues x.families);
        };
      
        types.kernel = enum (attrValues kernels);
      
        kernels = with execFormats; with kernelFamilies; setTypes types.openKernel {
          # TODO(@Ericson2314): Don't want to mass-rebuild yet to keeping 'darwin' as
          # the normalized name for macOS.
          macos    = { execFormat = macho;   families = { inherit darwin; }; name = "darwin"; };
          ios      = { execFormat = macho;   families = { inherit darwin; }; };
          # A tricky thing about FreeBSD is that there is no stable ABI across
          # versions. That means that putting in the version as part of the
          # config string is paramount.
          freebsd12 = { execFormat = elf;     families = { inherit bsd; }; name = "freebsd"; version = 12; };
          freebsd13 = { execFormat = elf;     families = { inherit bsd; }; name = "freebsd"; version = 13; };
          linux    = { execFormat = elf;     families = { }; };
          netbsd   = { execFormat = elf;     families = { inherit bsd; }; };
          none     = { execFormat = unknown; families = { }; };
          openbsd  = { execFormat = elf;     families = { inherit bsd; }; };
          solaris  = { execFormat = elf;     families = { }; };
          wasi     = { execFormat = wasm;    families = { }; };
          redox    = { execFormat = elf;     families = { }; };
          windows  = { execFormat = pe;      families = { }; };
          ghcjs    = { execFormat = unknown; families = { }; };
          genode   = { execFormat = elf;     families = { }; };
          mmixware = { execFormat = unknown; families = { }; };
        } // { # aliases
          # 'darwin' is the kernel for all of them. We choose macOS by default.
          darwin = kernels.macos;
          watchos = kernels.ios;
          tvos = kernels.ios;
          win32 = kernels.windows;
        };
      
        ################################################################################
      
        types.openAbi = mkOptionType {
          name = "abi";
          description = "binary interface for compiled code and syscalls";
          merge = mergeOneOption;
        };
      
        types.abi = enum (attrValues abis);
      
        abis = setTypes types.openAbi {
          cygnus       = {};
          msvc         = {};
      
          # Note: eabi is specific to ARM and PowerPC.
          # On PowerPC, this corresponds to PPCEABI.
          # On ARM, this corresponds to ARMEABI.
          eabi         = { float = "soft"; };
          eabihf       = { float = "hard"; };
      
          # Other architectures should use ELF in embedded situations.
          elf          = {};
      
          androideabi  = {};
          android      = {
            assertions = [
              { assertion = platform: !platform.isAarch32;
                message = ''
                  The "android" ABI is not for 32-bit ARM. Use "androideabi" instead.
                '';
              }
            ];
          };
      
          gnueabi      = { float = "soft"; };
          gnueabihf    = { float = "hard"; };
          gnu          = {
            assertions = [
              { assertion = platform: !platform.isAarch32;
                message = ''
                  The "gnu" ABI is ambiguous on 32-bit ARM. Use "gnueabi" or "gnueabihf" instead.
                '';
              }
              { assertion = platform: with platform; !(isPower64 && isBigEndian);
                message = ''
                  The "gnu" ABI is ambiguous on big-endian 64-bit PowerPC. Use "gnuabielfv2" or "gnuabielfv1" instead.
                '';
              }
            ];
          };
          gnuabi64     = { abi = "64"; };
          muslabi64    = { abi = "64"; };
      
          # NOTE: abi=n32 requires a 64-bit MIPS chip!  That is not a typo.
          # It is basically the 64-bit abi with 32-bit pointers.  Details:
          # https://www.linux-mips.org/pub/linux/mips/doc/ABI/MIPS-N32-ABI-Handbook.pdf
          gnuabin32    = { abi = "n32"; };
          muslabin32   = { abi = "n32"; };
      
          gnuabielfv2  = { abi = "elfv2"; };
          gnuabielfv1  = { abi = "elfv1"; };
      
          musleabi     = { float = "soft"; };
          musleabihf   = { float = "hard"; };
          musl         = {};
      
          uclibceabi   = { float = "soft"; };
          uclibceabihf = { float = "hard"; };
          uclibc       = {};
      
          unknown = {};
        };
      
        ################################################################################
      
        types.parsedPlatform = mkOptionType {
          name = "system";
          description = "fully parsed representation of llvm- or nix-style platform tuple";
          merge = mergeOneOption;
          check = { cpu, vendor, kernel, abi }:
                 types.cpuType.check cpu
              && types.vendor.check vendor
              && types.kernel.check kernel
              && types.abi.check abi;
        };
      
        isSystem = isType "system";
      
        mkSystem = components:
          assert types.parsedPlatform.check components;
          setType "system" components;
      
        mkSkeletonFromList = l: {
          "1" = if elemAt l 0 == "avr"
            then { cpu = elemAt l 0; kernel = "none"; abi = "unknown"; }
            else throw "Target specification with 1 components is ambiguous";
          "2" = # We only do 2-part hacks for things Nix already supports
            if elemAt l 1 == "cygwin"
              then { cpu = elemAt l 0;                      kernel = "windows";  abi = "cygnus";   }
            # MSVC ought to be the default ABI so this case isn't needed. But then it
            # becomes difficult to handle the gnu* variants for Aarch32 correctly for
            # minGW. So it's easier to make gnu* the default for the MinGW, but
            # hack-in MSVC for the non-MinGW case right here.
            else if elemAt l 1 == "windows"
              then { cpu = elemAt l 0;                      kernel = "windows";  abi = "msvc";     }
            else if (elemAt l 1) == "elf"
              then { cpu = elemAt l 0; vendor = "unknown";  kernel = "none";     abi = elemAt l 1; }
            else   { cpu = elemAt l 0;                      kernel = elemAt l 1;                   };
          "3" =
            # cpu-kernel-environment
            if elemAt l 1 == "linux" ||
               elem (elemAt l 2) ["eabi" "eabihf" "elf" "gnu"]
            then {
              cpu    = elemAt l 0;
              kernel = elemAt l 1;
              abi    = elemAt l 2;
              vendor = "unknown";
            }
            # cpu-vendor-os
            else if elemAt l 1 == "apple" ||
                    elem (elemAt l 2) [ "wasi" "redox" "mmixware" "ghcjs" "mingw32" ] ||
                    hasPrefix "freebsd" (elemAt l 2) ||
                    hasPrefix "netbsd" (elemAt l 2) ||
                    hasPrefix "genode" (elemAt l 2)
            then {
              cpu    = elemAt l 0;
              vendor = elemAt l 1;
              kernel = if elemAt l 2 == "mingw32"
                       then "windows"  # autotools breaks on -gnu for window
                       else elemAt l 2;
            }
            else throw "Target specification with 3 components is ambiguous";
          "4" =    { cpu = elemAt l 0; vendor = elemAt l 1; kernel = elemAt l 2; abi = elemAt l 3; };
        }.${toString (length l)}
          or (throw "system string has invalid number of hyphen-separated components");
      
        # This should revert the job done by config.guess from the gcc compiler.
        mkSystemFromSkeleton = { cpu
                               , # Optional, but fallback too complex for here.
                                 # Inferred below instead.
                                 vendor ? assert false; null
                               , kernel
                               , # Also inferred below
                                 abi    ? assert false; null
                               } @ args: let
          getCpu    = name: cpuTypes.${name} or (throw "Unknown CPU type: ${name}");
          getVendor = name:  vendors.${name} or (throw "Unknown vendor: ${name}");
          getKernel = name:  kernels.${name} or (throw "Unknown kernel: ${name}");
          getAbi    = name:     abis.${name} or (throw "Unknown ABI: ${name}");
      
          parsed = {
            cpu = getCpu args.cpu;
            vendor =
              /**/ if args ? vendor    then getVendor args.vendor
              else if isDarwin  parsed then vendors.apple
              else if isWindows parsed then vendors.pc
              else                     vendors.unknown;
            kernel = if hasPrefix "darwin" args.kernel      then getKernel "darwin"
                     else if hasPrefix "netbsd" args.kernel then getKernel "netbsd"
                     else                                   getKernel args.kernel;
            abi =
              /**/ if args ? abi       then getAbi args.abi
              else if isLinux parsed || isWindows parsed then
                if isAarch32 parsed then
                  if lib.versionAtLeast (parsed.cpu.version or "0") "6"
                  then abis.gnueabihf
                  else abis.gnueabi
                # Default ppc64 BE to ELFv2
                else if isPower64 parsed && isBigEndian parsed then abis.gnuabielfv2
                else abis.gnu
              else                     abis.unknown;
          };
      
        in mkSystem parsed;
      
        mkSystemFromString = s: mkSystemFromSkeleton (mkSkeletonFromList (lib.splitString "-" s));
      
        kernelName = kernel:
          kernel.name + toString (kernel.version or "");
      
        doubleFromSystem = { cpu, kernel, abi, ... }:
          /**/ if abi == abis.cygnus       then "${cpu.name}-cygwin"
          else if kernel.families ? darwin then "${cpu.name}-darwin"
          else "${cpu.name}-${kernelName kernel}";
      
        tripleFromSystem = { cpu, vendor, kernel, abi, ... } @ sys: assert isSystem sys; let
          optExecFormat =
            lib.optionalString (kernel.name == "netbsd" &&
                                gnuNetBSDDefaultExecFormat cpu != kernel.execFormat)
              kernel.execFormat.name;
          optAbi = lib.optionalString (abi != abis.unknown) "-${abi.name}";
        in "${cpu.name}-${vendor.name}-${kernelName kernel}${optExecFormat}${optAbi}";
      
        ################################################################################
      
      }
    );
    "/Users/jeffhykin/repos/nixpkgs/lib/path/default.nix" = (# "/Users/jeffhykin/repos/nixpkgs/lib/path/default.nix"
      # Functions for working with paths, see ./path.md
      { lib }:
      let
      
        inherit (builtins)
          isString
          split
          match
          ;
      
        inherit (lib.lists)
          length
          head
          last
          genList
          elemAt
          ;
      
        inherit (lib.strings)
          concatStringsSep
          substring
          ;
      
        inherit (lib.asserts)
          assertMsg
          ;
      
        # Return the reason why a subpath is invalid, or `null` if it's valid
        subpathInvalidReason = value:
          if ! isString value then
            "The given value is of type ${builtins.typeOf value}, but a string was expected"
          else if value == "" then
            "The given string is empty"
          else if substring 0 1 value == "/" then
            "The given string \"${value}\" starts with a `/`, representing an absolute path"
          # We don't support ".." components, see ./path.md#parent-directory
          else if match "(.*/)?\\.\\.(/.*)?" value != null then
            "The given string \"${value}\" contains a `..` component, which is not allowed in subpaths"
          else null;
      
        # Split and normalise a relative path string into its components.
        # Error for ".." components and doesn't include "." components
        splitRelPath = path:
          let
            # Split the string into its parts using regex for efficiency. This regex
            # matches patterns like "/", "/./", "/././", with arbitrarily many "/"s
            # together. These are the main special cases:
            # - Leading "./" gets split into a leading "." part
            # - Trailing "/." or "/" get split into a trailing "." or ""
            #   part respectively
            #
            # These are the only cases where "." and "" parts can occur
            parts = split "/+(\\./+)*" path;
      
            # `split` creates a list of 2 * k + 1 elements, containing the k +
            # 1 parts, interleaved with k matches where k is the number of
            # (non-overlapping) matches. This calculation here gets the number of parts
            # back from the list length
            # floor( (2 * k + 1) / 2 ) + 1 == floor( k + 1/2 ) + 1 == k + 1
            partCount = length parts / 2 + 1;
      
            # To assemble the final list of components we want to:
            # - Skip a potential leading ".", normalising "./foo" to "foo"
            # - Skip a potential trailing "." or "", normalising "foo/" and "foo/." to
            #   "foo". See ./path.md#trailing-slashes
            skipStart = if head parts == "." then 1 else 0;
            skipEnd = if last parts == "." || last parts == "" then 1 else 0;
      
            # We can now know the length of the result by removing the number of
            # skipped parts from the total number
            componentCount = partCount - skipEnd - skipStart;
      
          in
            # Special case of a single "." path component. Such a case leaves a
            # componentCount of -1 due to the skipStart/skipEnd not verifying that
            # they don't refer to the same character
            if path == "." then []
      
            # Generate the result list directly. This is more efficient than a
            # combination of `filter`, `init` and `tail`, because here we don't
            # allocate any intermediate lists
            else genList (index:
              # To get to the element we need to add the number of parts we skip and
              # multiply by two due to the interleaved layout of `parts`
              elemAt parts ((skipStart + index) * 2)
            ) componentCount;
      
        # Join relative path components together
        joinRelPath = components:
          # Always return relative paths with `./` as a prefix (./path.md#leading-dots-for-relative-paths)
          "./" +
          # An empty string is not a valid relative path, so we need to return a `.` when we have no components
          (if components == [] then "." else concatStringsSep "/" components);
      
      in /* No rec! Add dependencies on this file at the top. */ {
      
      
        /* Whether a value is a valid subpath string.
      
        - The value is a string
      
        - The string is not empty
      
        - The string doesn't start with a `/`
      
        - The string doesn't contain any `..` path components
      
        Type:
          subpath.isValid :: String -> Bool
      
        Example:
          # Not a string
          subpath.isValid null
          => false
      
          # Empty string
          subpath.isValid ""
          => false
      
          # Absolute path
          subpath.isValid "/foo"
          => false
      
          # Contains a `..` path component
          subpath.isValid "../foo"
          => false
      
          # Valid subpath
          subpath.isValid "foo/bar"
          => true
      
          # Doesn't need to be normalised
          subpath.isValid "./foo//bar/"
          => true
        */
        subpath.isValid = value:
          subpathInvalidReason value == null;
      
      
        /* Normalise a subpath. Throw an error if the subpath isn't valid, see
        `lib.path.subpath.isValid`
      
        - Limit repeating `/` to a single one
      
        - Remove redundant `.` components
      
        - Remove trailing `/` and `/.`
      
        - Add leading `./`
      
        Laws:
      
        - (Idempotency) Normalising multiple times gives the same result:
      
              subpath.normalise (subpath.normalise p) == subpath.normalise p
      
        - (Uniqueness) There's only a single normalisation for the paths that lead to the same file system node:
      
              subpath.normalise p != subpath.normalise q -> $(realpath ${p}) != $(realpath ${q})
      
        - Don't change the result when appended to a Nix path value:
      
              base + ("/" + p) == base + ("/" + subpath.normalise p)
      
        - Don't change the path according to `realpath`:
      
              $(realpath ${p}) == $(realpath ${subpath.normalise p})
      
        - Only error on invalid subpaths:
      
              builtins.tryEval (subpath.normalise p)).success == subpath.isValid p
      
        Type:
          subpath.normalise :: String -> String
      
        Example:
          # limit repeating `/` to a single one
          subpath.normalise "foo//bar"
          => "./foo/bar"
      
          # remove redundant `.` components
          subpath.normalise "foo/./bar"
          => "./foo/bar"
      
          # add leading `./`
          subpath.normalise "foo/bar"
          => "./foo/bar"
      
          # remove trailing `/`
          subpath.normalise "foo/bar/"
          => "./foo/bar"
      
          # remove trailing `/.`
          subpath.normalise "foo/bar/."
          => "./foo/bar"
      
          # Return the current directory as `./.`
          subpath.normalise "."
          => "./."
      
          # error on `..` path components
          subpath.normalise "foo/../bar"
          => <error>
      
          # error on empty string
          subpath.normalise ""
          => <error>
      
          # error on absolute path
          subpath.normalise "/foo"
          => <error>
        */
        subpath.normalise = path:
          assert assertMsg (subpathInvalidReason path == null)
            "lib.path.subpath.normalise: Argument is not a valid subpath string: ${subpathInvalidReason path}";
          joinRelPath (splitRelPath path);
      
      }
    );
    "/Users/jeffhykin/repos/nixpkgs/lib/systems/inspect.nix" = (# "/Users/jeffhykin/repos/nixpkgs/lib/systems/inspect.nix"
      { lib }:
      with /*import:normal*/ _-_06294632224836068_-_."/Users/jeffhykin/repos/nixpkgs/lib/systems/parse.nix" { inherit lib; };
      with lib.attrsets;
      with lib.lists;
      
      let abis_ = abis; in
      let abis = lib.mapAttrs (_: abi: builtins.removeAttrs abi [ "assertions" ]) abis_; in
      
      rec {
        patterns = rec {
          isi686         = { cpu = cpuTypes.i686; };
          isx86_32       = { cpu = { family = "x86"; bits = 32; }; };
          isx86_64       = { cpu = { family = "x86"; bits = 64; }; };
          isPower        = { cpu = { family = "power"; }; };
          isPower64      = { cpu = { family = "power"; bits = 64; }; };
          # This ABI is the default in NixOS PowerPC64 BE, but not on mainline GCC,
          # so it sometimes causes issues in certain packages that makes the wrong
          # assumption on the used ABI.
          isAbiElfv2 = [
            { abi = { abi = "elfv2"; }; }
            { abi = { name = "musl"; }; cpu = { family = "power"; bits = 64; }; }
          ];
          isx86          = { cpu = { family = "x86"; }; };
          isAarch32      = { cpu = { family = "arm"; bits = 32; }; };
          isArmv7        = map ({ arch, ... }: { cpu = { inherit arch; }; })
                             (lib.filter (cpu: lib.hasPrefix "armv7" cpu.arch or "")
                               (lib.attrValues cpuTypes));
          isAarch64      = { cpu = { family = "arm"; bits = 64; }; };
          isAarch        = { cpu = { family = "arm"; }; };
          isMicroBlaze   = { cpu = { family = "microblaze"; }; };
          isMips         = { cpu = { family = "mips"; }; };
          isMips32       = { cpu = { family = "mips"; bits = 32; }; };
          isMips64       = { cpu = { family = "mips"; bits = 64; }; };
          isMips64n32    = { cpu = { family = "mips"; bits = 64; }; abi = { abi = "n32"; }; };
          isMips64n64    = { cpu = { family = "mips"; bits = 64; }; abi = { abi = "64";  }; };
          isMmix         = { cpu = { family = "mmix"; }; };
          isRiscV        = { cpu = { family = "riscv"; }; };
          isRiscV32      = { cpu = { family = "riscv"; bits = 32; }; };
          isRiscV64      = { cpu = { family = "riscv"; bits = 64; }; };
          isRx           = { cpu = { family = "rx"; }; };
          isSparc        = { cpu = { family = "sparc"; }; };
          isWasm         = { cpu = { family = "wasm"; }; };
          isMsp430       = { cpu = { family = "msp430"; }; };
          isVc4          = { cpu = { family = "vc4"; }; };
          isAvr          = { cpu = { family = "avr"; }; };
          isAlpha        = { cpu = { family = "alpha"; }; };
          isOr1k         = { cpu = { family = "or1k"; }; };
          isM68k         = { cpu = { family = "m68k"; }; };
          isS390         = { cpu = { family = "s390"; }; };
          isS390x        = { cpu = { family = "s390"; bits = 64; }; };
          isJavaScript   = { cpu = cpuTypes.js; };
      
          is32bit        = { cpu = { bits = 32; }; };
          is64bit        = { cpu = { bits = 64; }; };
          isILP32        = map (a: { abi = { abi = a; }; }) [ "n32" "ilp32" "x32" ];
          isBigEndian    = { cpu = { significantByte = significantBytes.bigEndian; }; };
          isLittleEndian = { cpu = { significantByte = significantBytes.littleEndian; }; };
      
          isBSD          = { kernel = { families = { inherit (kernelFamilies) bsd; }; }; };
          isDarwin       = { kernel = { families = { inherit (kernelFamilies) darwin; }; }; };
          isUnix         = [ isBSD isDarwin isLinux isSunOS isCygwin isRedox ];
      
          isMacOS        = { kernel = kernels.macos; };
          isiOS          = { kernel = kernels.ios; };
          isLinux        = { kernel = kernels.linux; };
          isSunOS        = { kernel = kernels.solaris; };
          isFreeBSD      = { kernel = { name = "freebsd"; }; };
          isNetBSD       = { kernel = kernels.netbsd; };
          isOpenBSD      = { kernel = kernels.openbsd; };
          isWindows      = { kernel = kernels.windows; };
          isCygwin       = { kernel = kernels.windows; abi = abis.cygnus; };
          isMinGW        = { kernel = kernels.windows; abi = abis.gnu; };
          isWasi         = { kernel = kernels.wasi; };
          isRedox        = { kernel = kernels.redox; };
          isGhcjs        = { kernel = kernels.ghcjs; };
          isGenode       = { kernel = kernels.genode; };
          isNone         = { kernel = kernels.none; };
      
          isAndroid      = [ { abi = abis.android; } { abi = abis.androideabi; } ];
          isGnu          = with abis; map (a: { abi = a; }) [ gnuabi64 gnu gnueabi gnueabihf gnuabielfv1 gnuabielfv2 ];
          isMusl         = with abis; map (a: { abi = a; }) [ musl musleabi musleabihf muslabin32 muslabi64 ];
          isUClibc       = with abis; map (a: { abi = a; }) [ uclibc uclibceabi uclibceabihf ];
      
          isEfi          = map (family: { cpu.family = family; })
                             [ "x86" "arm" "aarch64" "riscv" ];
        };
      
        matchAnyAttrs = patterns:
          if builtins.isList patterns then attrs: any (pattern: matchAttrs pattern attrs) patterns
          else matchAttrs patterns;
      
        predicates = mapAttrs (_: matchAnyAttrs) patterns;
      }
    );
    "/Users/jeffhykin/repos/nixpkgs/lib/filesystem.nix" = (# "/Users/jeffhykin/repos/nixpkgs/lib/filesystem.nix"
      # Functions for copying sources to the Nix store.
      { lib }:
      
      let
        inherit (lib.strings)
          hasPrefix
          ;
      in
      
      {
        /*
          A map of all haskell packages defined in the given path,
          identified by having a cabal file with the same name as the
          directory itself.
      
          Type: Path -> Map String Path
        */
        haskellPathsInDir =
          # The directory within to search
          root:
          let # Files in the root
              root-files = builtins.attrNames (builtins.readDir root);
              # Files with their full paths
              root-files-with-paths =
                map (file:
                  { name = file; value = root + "/${file}"; }
                ) root-files;
              # Subdirectories of the root with a cabal file.
              cabal-subdirs =
                builtins.filter ({ name, value }:
                  builtins.pathExists (value + "/${name}.cabal")
                ) root-files-with-paths;
          in builtins.listToAttrs cabal-subdirs;
        /*
          Find the first directory containing a file matching 'pattern'
          upward from a given 'file'.
          Returns 'null' if no directories contain a file matching 'pattern'.
      
          Type: RegExp -> Path -> Nullable { path : Path; matches : [ MatchResults ]; }
        */
        locateDominatingFile =
          # The pattern to search for
          pattern:
          # The file to start searching upward from
          file:
          let go = path:
                let files = builtins.attrNames (builtins.readDir path);
                    matches = builtins.filter (match: match != null)
                                (map (builtins.match pattern) files);
                in
                  if builtins.length matches != 0
                    then { inherit path matches; }
                    else if path == ../filesystem.nix
                      then null
                      else go (dirOf path);
              parent = dirOf file;
              isDir =
                let base = baseNameOf file;
                    type = (builtins.readDir parent).${base} or null;
                in file == ../filesystem.nix || type == "directory";
          in go (if isDir then file else parent);
      
      
        /*
          Given a directory, return a flattened list of all files within it recursively.
      
          Type: Path -> [ Path ]
        */
        listFilesRecursive =
          # The path to recursively list
          dir:
          lib.flatten (lib.mapAttrsToList (name: type:
          if type == "directory" then
            lib.filesystem.listFilesRecursive (dir + "/${name}")
          else
            dir + "/${name}"
        ) (builtins.readDir dir));
      
      }
    );
    "/Users/jeffhykin/repos/nixpkgs/lib/systems/platforms.nix" = (# "/Users/jeffhykin/repos/nixpkgs/lib/systems/platforms.nix"
      # Note: lib/systems/default.nix takes care of producing valid,
      # fully-formed "platform" values (e.g. hostPlatform, buildPlatform,
      # targetPlatform, etc) containing at least the minimal set of attrs
      # required (see types.parsedPlatform in lib/systems/parse.nix).  This
      # file takes an already-valid platform and further elaborates it with
      # optional fields; currently these are: linux-kernel, gcc, and rustc.
      
      { lib }:
      rec {
        pc = {
          linux-kernel = {
            name = "pc";
      
            baseConfig = "defconfig";
            # Build whatever possible as a module, if not stated in the extra config.
            autoModules = true;
            target = "bzImage";
          };
        };
      
        pc_simplekernel = lib.recursiveUpdate pc {
          linux-kernel.autoModules = false;
        };
      
        powernv = {
          linux-kernel = {
            name = "PowerNV";
      
            baseConfig = "powernv_defconfig";
            target = "vmlinux";
            autoModules = true;
            # avoid driver/FS trouble arising from unusual page size
            extraConfig = ''
              PPC_64K_PAGES n
              PPC_4K_PAGES y
              IPV6 y
      
              ATA_BMDMA y
              ATA_SFF y
              VIRTIO_MENU y
            '';
          };
        };
      
        ##
        ## ARM
        ##
      
        pogoplug4 = {
          linux-kernel = {
            name = "pogoplug4";
      
            baseConfig = "multi_v5_defconfig";
            autoModules = false;
            extraConfig = ''
              # Ubi for the mtd
              MTD_UBI y
              UBIFS_FS y
              UBIFS_FS_XATTR y
              UBIFS_FS_ADVANCED_COMPR y
              UBIFS_FS_LZO y
              UBIFS_FS_ZLIB y
              UBIFS_FS_DEBUG n
            '';
            makeFlags = [ "LOADADDR=0x8000" ];
            target = "uImage";
            # TODO reenable once manual-config's config actually builds a .dtb and this is checked to be working
            #DTB = true;
          };
          gcc = {
            arch = "armv5te";
          };
        };
      
        sheevaplug = {
          linux-kernel = {
            name = "sheevaplug";
      
            baseConfig = "multi_v5_defconfig";
            autoModules = false;
            extraConfig = ''
              BLK_DEV_RAM y
              BLK_DEV_INITRD y
              BLK_DEV_CRYPTOLOOP m
              BLK_DEV_DM m
              DM_CRYPT m
              MD y
              REISERFS_FS m
              BTRFS_FS m
              XFS_FS m
              JFS_FS m
              EXT4_FS m
              USB_STORAGE_CYPRESS_ATACB m
      
              # mv cesa requires this sw fallback, for mv-sha1
              CRYPTO_SHA1 y
              # Fast crypto
              CRYPTO_TWOFISH y
              CRYPTO_TWOFISH_COMMON y
              CRYPTO_BLOWFISH y
              CRYPTO_BLOWFISH_COMMON y
      
              IP_PNP y
              IP_PNP_DHCP y
              NFS_FS y
              ROOT_NFS y
              TUN m
              NFS_V4 y
              NFS_V4_1 y
              NFS_FSCACHE y
              NFSD m
              NFSD_V2_ACL y
              NFSD_V3 y
              NFSD_V3_ACL y
              NFSD_V4 y
              NETFILTER y
              IP_NF_IPTABLES y
              IP_NF_FILTER y
              IP_NF_MATCH_ADDRTYPE y
              IP_NF_TARGET_LOG y
              IP_NF_MANGLE y
              IPV6 m
              VLAN_8021Q m
      
              CIFS y
              CIFS_XATTR y
              CIFS_POSIX y
              CIFS_FSCACHE y
              CIFS_ACL y
      
              WATCHDOG y
              WATCHDOG_CORE y
              ORION_WATCHDOG m
      
              ZRAM m
              NETCONSOLE m
      
              # Disable OABI to have seccomp_filter (required for systemd)
              # https://github.com/raspberrypi/firmware/issues/651
              OABI_COMPAT n
      
              # Fail to build
              DRM n
              SCSI_ADVANSYS n
              USB_ISP1362_HCD n
              SND_SOC n
              SND_ALI5451 n
              FB_SAVAGE n
              SCSI_NSP32 n
              ATA_SFF n
              SUNGEM n
              IRDA n
              ATM_HE n
              SCSI_ACARD n
              BLK_DEV_CMD640_ENHANCED n
      
              FUSE_FS m
      
              # systemd uses cgroups
              CGROUPS y
      
              # Latencytop
              LATENCYTOP y
      
              # Ubi for the mtd
              MTD_UBI y
              UBIFS_FS y
              UBIFS_FS_XATTR y
              UBIFS_FS_ADVANCED_COMPR y
              UBIFS_FS_LZO y
              UBIFS_FS_ZLIB y
              UBIFS_FS_DEBUG n
      
              # Kdb, for kernel troubles
              KGDB y
              KGDB_SERIAL_CONSOLE y
              KGDB_KDB y
            '';
            makeFlags = [ "LOADADDR=0x0200000" ];
            target = "uImage";
            DTB = true; # Beyond 3.10
          };
          gcc = {
            arch = "armv5te";
          };
        };
      
        raspberrypi = {
          linux-kernel = {
            name = "raspberrypi";
      
            baseConfig = "bcm2835_defconfig";
            DTB = true;
            autoModules = true;
            preferBuiltin = true;
            extraConfig = ''
              # Disable OABI to have seccomp_filter (required for systemd)
              # https://github.com/raspberrypi/firmware/issues/651
              OABI_COMPAT n
            '';
            target = "zImage";
          };
          gcc = {
            arch = "armv6";
            fpu = "vfp";
          };
        };
      
        # Legacy attribute, for compatibility with existing configs only.
        raspberrypi2 = armv7l-hf-multiplatform;
      
        zero-gravitas = {
          linux-kernel = {
            name = "zero-gravitas";
      
            baseConfig = "zero-gravitas_defconfig";
            # Target verified by checking /boot on reMarkable 1 device
            target = "zImage";
            autoModules = false;
            DTB = true;
          };
          gcc = {
            fpu = "neon";
            cpu = "cortex-a9";
          };
        };
      
        zero-sugar = {
          linux-kernel = {
            name = "zero-sugar";
      
            baseConfig = "zero-sugar_defconfig";
            DTB = true;
            autoModules = false;
            preferBuiltin = true;
            target = "zImage";
          };
          gcc = {
            cpu = "cortex-a7";
            fpu = "neon-vfpv4";
            float-abi = "hard";
          };
        };
      
        utilite = {
          linux-kernel = {
            name = "utilite";
            maseConfig = "multi_v7_defconfig";
            autoModules = false;
            extraConfig = ''
              # Ubi for the mtd
              MTD_UBI y
              UBIFS_FS y
              UBIFS_FS_XATTR y
              UBIFS_FS_ADVANCED_COMPR y
              UBIFS_FS_LZO y
              UBIFS_FS_ZLIB y
              UBIFS_FS_DEBUG n
            '';
            makeFlags = [ "LOADADDR=0x10800000" ];
            target = "uImage";
            DTB = true;
          };
          gcc = {
            cpu = "cortex-a9";
            fpu = "neon";
          };
        };
      
        guruplug = lib.recursiveUpdate sheevaplug {
          # Define `CONFIG_MACH_GURUPLUG' (see
          # <http://kerneltrap.org/mailarchive/git-commits-head/2010/5/19/33618>)
          # and other GuruPlug-specific things.  Requires the `guruplug-defconfig'
          # patch.
          linux-kernel.baseConfig = "guruplug_defconfig";
        };
      
        beaglebone = lib.recursiveUpdate armv7l-hf-multiplatform {
          linux-kernel = {
            name = "beaglebone";
            baseConfig = "bb.org_defconfig";
            autoModules = false;
            extraConfig = ""; # TBD kernel config
            target = "zImage";
          };
        };
      
        # https://developer.android.com/ndk/guides/abis#v7a
        armv7a-android = {
          linux-kernel.name = "armeabi-v7a";
          gcc = {
            arch = "armv7-a";
            float-abi = "softfp";
            fpu = "vfpv3-d16";
          };
        };
      
        armv7l-hf-multiplatform = {
          linux-kernel = {
            name = "armv7l-hf-multiplatform";
            Major = "2.6"; # Using "2.6" enables 2.6 kernel syscalls in glibc.
            baseConfig = "multi_v7_defconfig";
            DTB = true;
            autoModules = true;
            preferBuiltin = true;
            target = "zImage";
            extraConfig = ''
              # Serial port for Raspberry Pi 3. Wasn't included in ARMv7 defconfig
              # until 4.17.
              SERIAL_8250_BCM2835AUX y
              SERIAL_8250_EXTENDED y
              SERIAL_8250_SHARE_IRQ y
      
              # Hangs ODROID-XU4
              ARM_BIG_LITTLE_CPUIDLE n
      
              # Disable OABI to have seccomp_filter (required for systemd)
              # https://github.com/raspberrypi/firmware/issues/651
              OABI_COMPAT n
      
              # >=5.12 fails with:
              # drivers/net/ethernet/micrel/ks8851_common.o: in function `ks8851_probe_common':
              # ks8851_common.c:(.text+0x179c): undefined reference to `__this_module'
              # See: https://lore.kernel.org/netdev/20210116164828.40545-1-marex@denx.de/T/
              KS8851_MLL y
            '';
          };
          gcc = {
            # Some table about fpu flags:
            # http://community.arm.com/servlet/JiveServlet/showImage/38-1981-3827/blogentry-103749-004812900+1365712953_thumb.png
            # Cortex-A5: -mfpu=neon-fp16
            # Cortex-A7 (rpi2): -mfpu=neon-vfpv4
            # Cortex-A8 (beaglebone): -mfpu=neon
            # Cortex-A9: -mfpu=neon-fp16
            # Cortex-A15: -mfpu=neon-vfpv4
      
            # More about FPU:
            # https://wiki.debian.org/ArmHardFloatPort/VfpComparison
      
            # vfpv3-d16 is what Debian uses and seems to be the best compromise: NEON is not supported in e.g. Scaleway or Tegra 2,
            # and the above page suggests NEON is only an improvement with hand-written assembly.
            arch = "armv7-a";
            fpu = "vfpv3-d16";
      
            # For Raspberry Pi the 2 the best would be:
            #   cpu = "cortex-a7";
            #   fpu = "neon-vfpv4";
          };
        };
      
        aarch64-multiplatform = {
          linux-kernel = {
            name = "aarch64-multiplatform";
            baseConfig = "defconfig";
            DTB = true;
            autoModules = true;
            preferBuiltin = true;
            extraConfig = ''
              # Raspberry Pi 3 stuff. Not needed for   s >= 4.10.
              ARCH_BCM2835 y
              BCM2835_MBOX y
              BCM2835_WDT y
              RASPBERRYPI_FIRMWARE y
              RASPBERRYPI_POWER y
              SERIAL_8250_BCM2835AUX y
              SERIAL_8250_EXTENDED y
              SERIAL_8250_SHARE_IRQ y
      
              # Cavium ThunderX stuff.
              PCI_HOST_THUNDER_ECAM y
      
              # Nvidia Tegra stuff.
              PCI_TEGRA y
      
              # The default (=y) forces us to have the XHCI firmware available in initrd,
              # which our initrd builder can't currently do easily.
              USB_XHCI_TEGRA m
            '';
            target = "Image";
          };
          gcc = {
            arch = "armv8-a";
          };
        };
      
        apple-m1 = {
          gcc = {
            arch = "armv8.3-a+crypto+sha2+aes+crc+fp16+lse+simd+ras+rdm+rcpc";
            cpu = "apple-a13";
          };
        };
      
        ##
        ## MIPS
        ##
      
        ben_nanonote = {
          linux-kernel = {
            name = "ben_nanonote";
          };
          gcc = {
            arch = "mips32";
            float = "soft";
          };
        };
      
        fuloong2f_n32 = {
          linux-kernel = {
            name = "fuloong2f_n32";
            baseConfig = "lemote2f_defconfig";
            autoModules = false;
            extraConfig = ''
              MIGRATION n
              COMPACTION n
      
              # nixos mounts some cgroup
              CGROUPS y
      
              BLK_DEV_RAM y
              BLK_DEV_INITRD y
              BLK_DEV_CRYPTOLOOP m
              BLK_DEV_DM m
              DM_CRYPT m
              MD y
              REISERFS_FS m
              EXT4_FS m
              USB_STORAGE_CYPRESS_ATACB m
      
              IP_PNP y
              IP_PNP_DHCP y
              IP_PNP_BOOTP y
              NFS_FS y
              ROOT_NFS y
              TUN m
              NFS_V4 y
              NFS_V4_1 y
              NFS_FSCACHE y
              NFSD m
              NFSD_V2_ACL y
              NFSD_V3 y
              NFSD_V3_ACL y
              NFSD_V4 y
      
              # Fail to build
              DRM n
              SCSI_ADVANSYS n
              USB_ISP1362_HCD n
              SND_SOC n
              SND_ALI5451 n
              FB_SAVAGE n
              SCSI_NSP32 n
              ATA_SFF n
              SUNGEM n
              IRDA n
              ATM_HE n
              SCSI_ACARD n
              BLK_DEV_CMD640_ENHANCED n
      
              FUSE_FS m
      
              # Needed for udev >= 150
              SYSFS_DEPRECATED_V2 n
      
              VGA_CONSOLE n
              VT_HW_CONSOLE_BINDING y
              SERIAL_8250_CONSOLE y
              FRAMEBUFFER_CONSOLE y
              EXT2_FS y
              EXT3_FS y
              REISERFS_FS y
              MAGIC_SYSRQ y
      
              # The kernel doesn't boot at all, with FTRACE
              FTRACE n
            '';
            target = "vmlinux";
          };
          gcc = {
            arch = "loongson2f";
            float = "hard";
            abi = "n32";
          };
        };
      
        # can execute on 32bit chip
        gcc_mips32r2_o32 = { gcc = { arch = "mips32r2"; abi =  "32"; }; };
        gcc_mips32r6_o32 = { gcc = { arch = "mips32r6"; abi =  "32"; }; };
        gcc_mips64r2_n32 = { gcc = { arch = "mips64r2"; abi = "n32"; }; };
        gcc_mips64r6_n32 = { gcc = { arch = "mips64r6"; abi = "n32"; }; };
        gcc_mips64r2_64  = { gcc = { arch = "mips64r2"; abi =  "64"; }; };
        gcc_mips64r6_64  = { gcc = { arch = "mips64r6"; abi =  "64"; }; };
      
        # based on:
        #   https://www.mail-archive.com/qemu-discuss@nongnu.org/msg05179.html
        #   https://gmplib.org/~tege/qemu.html#mips64-debian
        mips64el-qemu-linux-gnuabi64 = {
          linux-kernel = {
            name = "mips64el";
            baseConfig = "64r2el_defconfig";
            target = "vmlinuz";
            autoModules = false;
            DTB = true;
            # for qemu 9p passthrough filesystem
            extraConfig = ''
              MIPS_MALTA y
              PAGE_SIZE_4KB y
              CPU_LITTLE_ENDIAN y
              CPU_MIPS64_R2 y
              64BIT y
              CPU_MIPS64_R2 y
      
              NET_9P y
              NET_9P_VIRTIO y
              9P_FS y
              9P_FS_POSIX_ACL y
              PCI y
              VIRTIO_PCI y
            '';
          };
        };
      
        ##
        ## Other
        ##
      
        riscv-multiplatform = {
          linux-kernel = {
            name = "riscv-multiplatform";
            target = "Image";
            autoModules = true;
            baseConfig = "defconfig";
            DTB = true;
            extraConfig = ''
              SERIAL_OF_PLATFORM y
            '';
          };
        };
      
        # This function takes a minimally-valid "platform" and returns an
        # attrset containing zero or more additional attrs which should be
        # included in the platform in order to further elaborate it.
        select = platform:
          # x86
          /**/ if platform.isx86 then pc
      
          # ARM
          else if platform.isAarch32 then let
            version = platform.parsed.cpu.version or null;
            in     if version == null then pc
              else if lib.versionOlder version "6" then sheevaplug
              else if lib.versionOlder version "7" then raspberrypi
              else armv7l-hf-multiplatform
      
          else if platform.isAarch64 then
            if platform.isDarwin then apple-m1
            else aarch64-multiplatform
      
          else if platform.isRiscV then riscv-multiplatform
      
          else if platform.parsed.cpu == lib.systems.parse.cpuTypes.mipsel then (/*import:normal*/ _-_06294632224836068_-_."/Users/jeffhykin/repos/nixpkgs/lib/systems/examples.nix" { inherit lib; }).mipsel-linux-gnu
      
          else if platform.parsed.cpu == lib.systems.parse.cpuTypes.powerpc64le then powernv
      
          else { };
      }
    );
    "/Users/jeffhykin/repos/nixpkgs/lib/systems/architectures.nix" = (# "/Users/jeffhykin/repos/nixpkgs/lib/systems/architectures.nix"
      { lib }:
      
      rec {
        # gcc.arch to its features (as in /proc/cpuinfo)
        features = {
          default        = [ ];
          # x86_64 Intel
          westmere       = [ "sse3" "ssse3" "sse4_1" "sse4_2"         "aes"                                    ];
          sandybridge    = [ "sse3" "ssse3" "sse4_1" "sse4_2"         "aes" "avx"                              ];
          ivybridge      = [ "sse3" "ssse3" "sse4_1" "sse4_2"         "aes" "avx"                              ];
          haswell        = [ "sse3" "ssse3" "sse4_1" "sse4_2"         "aes" "avx" "avx2"          "fma"        ];
          broadwell      = [ "sse3" "ssse3" "sse4_1" "sse4_2"         "aes" "avx" "avx2"          "fma"        ];
          skylake        = [ "sse3" "ssse3" "sse4_1" "sse4_2"         "aes" "avx" "avx2"          "fma"        ];
          skylake-avx512 = [ "sse3" "ssse3" "sse4_1" "sse4_2"         "aes" "avx" "avx2" "avx512" "fma"        ];
          cannonlake     = [ "sse3" "ssse3" "sse4_1" "sse4_2"         "aes" "avx" "avx2" "avx512" "fma"        ];
          icelake-client = [ "sse3" "ssse3" "sse4_1" "sse4_2"         "aes" "avx" "avx2" "avx512" "fma"        ];
          icelake-server = [ "sse3" "ssse3" "sse4_1" "sse4_2"         "aes" "avx" "avx2" "avx512" "fma"        ];
          cascadelake    = [ "sse3" "ssse3" "sse4_1" "sse4_2"         "aes" "avx" "avx2" "avx512" "fma"        ];
          cooperlake     = [ "sse3" "ssse3" "sse4_1" "sse4_2"         "aes" "avx" "avx2" "avx512" "fma"        ];
          tigerlake      = [ "sse3" "ssse3" "sse4_1" "sse4_2"         "aes" "avx" "avx2" "avx512" "fma"        ];
          # x86_64 AMD
          btver1         = [ "sse3" "ssse3" "sse4_1" "sse4_2"                                                  ];
          btver2         = [ "sse3" "ssse3" "sse4_1" "sse4_2"         "aes" "avx"                              ];
          bdver1         = [ "sse3" "ssse3" "sse4_1" "sse4_2" "sse4a" "aes" "avx"                 "fma" "fma4" ];
          bdver2         = [ "sse3" "ssse3" "sse4_1" "sse4_2" "sse4a" "aes" "avx"                 "fma" "fma4" ];
          bdver3         = [ "sse3" "ssse3" "sse4_1" "sse4_2" "sse4a" "aes" "avx"                 "fma" "fma4" ];
          bdver4         = [ "sse3" "ssse3" "sse4_1" "sse4_2" "sse4a" "aes" "avx" "avx2"          "fma" "fma4" ];
          znver1         = [ "sse3" "ssse3" "sse4_1" "sse4_2" "sse4a" "aes" "avx" "avx2"          "fma"        ];
          znver2         = [ "sse3" "ssse3" "sse4_1" "sse4_2" "sse4a" "aes" "avx" "avx2"          "fma"        ];
          znver3         = [ "sse3" "ssse3" "sse4_1" "sse4_2" "sse4a" "aes" "avx" "avx2"          "fma"        ];
          # other
          armv5te        = [ ];
          armv6          = [ ];
          armv7-a        = [ ];
          armv8-a        = [ ];
          mips32         = [ ];
          loongson2f     = [ ];
        };
      
        # a superior CPU has all the features of an inferior and is able to build and test code for it
        inferiors = {
          # x86_64 Intel
          default        = [ ];
          westmere       = [ ];
          sandybridge    = [ "westmere"    ] ++ inferiors.westmere;
          ivybridge      = [ "sandybridge" ] ++ inferiors.sandybridge;
          haswell        = [ "ivybridge"   ] ++ inferiors.ivybridge;
          broadwell      = [ "haswell"     ] ++ inferiors.haswell;
          skylake        = [ "broadwell"   ] ++ inferiors.broadwell;
          skylake-avx512 = [ "skylake"     ] ++ inferiors.skylake;
      
          # x86_64 AMD
          # TODO: fill this (need testing)
          btver1         = [ ];
          btver2         = [ ];
          bdver1         = [ ];
          bdver2         = [ ];
          bdver3         = [ ];
          bdver4         = [ ];
          # Regarding `skylake` as inferior of `znver1`, there are reports of
          # successful usage by Gentoo users and Phoronix benchmarking of different
          # `-march` targets.
          #
          # The GCC documentation on extensions used and wikichip documentation
          # regarding supperted extensions on znver1 and skylake was used to create
          # this partial order.
          #
          # Note:
          #
          # - The successors of `skylake` (`cannonlake`, `icelake`, etc) use `avx512`
          #   which no current AMD Zen michroarch support.
          # - `znver1` uses `ABM`, `CLZERO`, `CX16`, `MWAITX`, and `SSE4A` which no
          #   current Intel microarch support.
          #
          # https://www.phoronix.com/scan.php?page=article&item=amd-znver3-gcc11&num=1
          # https://gcc.gnu.org/onlinedocs/gcc/x86-Options.html
          # https://en.wikichip.org/wiki/amd/microarchitectures/zen
          # https://en.wikichip.org/wiki/intel/microarchitectures/skylake
          znver1         = [ "skylake" ] ++ inferiors.skylake;
          znver2         = [ "znver1"  ] ++ inferiors.znver1;
          znver3         = [ "znver2"  ] ++ inferiors.znver2;
      
          # other
          armv5te        = [ ];
          armv6          = [ ];
          armv7-a        = [ ];
          armv8-a        = [ ];
          mips32         = [ ];
          loongson2f     = [ ];
        };
      
        predicates = let
          featureSupport = feature: x: builtins.elem feature features.${x} or [];
        in {
          sse3Support    = featureSupport "sse3";
          ssse3Support   = featureSupport "ssse3";
          sse4_1Support  = featureSupport "sse4_1";
          sse4_2Support  = featureSupport "sse4_2";
          sse4_aSupport  = featureSupport "sse4a";
          avxSupport     = featureSupport "avx";
          avx2Support    = featureSupport "avx2";
          avx512Support  = featureSupport "avx512";
          aesSupport     = featureSupport "aes";
          fmaSupport     = featureSupport "fma";
          fma4Support    = featureSupport "fma4";
        };
      }
    );
    "/Users/jeffhykin/repos/nixpkgs/lib/sources.nix" = (# "/Users/jeffhykin/repos/nixpkgs/lib/sources.nix"
      # Functions for copying sources to the Nix store.
      { lib }:
      
      # Tested in lib/tests/sources.sh
      let
        inherit (builtins)
          match
          readDir
          split
          storeDir
          tryEval
          ;
        inherit (lib)
          boolToString
          filter
          getAttr
          isString
          pathExists
          readFile
          ;
      
        /*
          Returns the type of a path: regular (for file), symlink, or directory.
        */
        pathType = path: getAttr (baseNameOf path) (readDir (dirOf path));
      
        /*
          Returns true if the path exists and is a directory, false otherwise.
        */
        pathIsDirectory = path: if pathExists path then (pathType path) == "directory" else false;
      
        /*
          Returns true if the path exists and is a regular file, false otherwise.
        */
        pathIsRegularFile = path: if pathExists path then (pathType path) == "regular" else false;
      
        /*
          A basic filter for `cleanSourceWith` that removes
          directories of version control system, backup files (*~)
          and some generated files.
        */
        cleanSourceFilter = name: type: let baseName = baseNameOf (toString name); in ! (
          # Filter out version control software files/directories
          (baseName == ".git" || type == "directory" && (baseName == ".svn" || baseName == "CVS" || baseName == ".hg")) ||
          # Filter out editor backup / swap files.
          lib.hasSuffix "~" baseName ||
          match "^\\.sw[a-z]$" baseName != null ||
          match "^\\..*\\.sw[a-z]$" baseName != null ||
      
          # Filter out generates files.
          lib.hasSuffix ".o" baseName ||
          lib.hasSuffix ".so" baseName ||
          # Filter out nix-build result symlinks
          (type == "symlink" && lib.hasPrefix "result" baseName) ||
          # Filter out sockets and other types of files we can't have in the store.
          (type == "unknown")
        );
      
        /*
          Filters a source tree removing version control files and directories using cleanSourceFilter.
      
          Example:
                   cleanSource ./.
        */
        cleanSource = src: cleanSourceWith { filter = cleanSourceFilter; inherit src; };
      
        /*
          Like `builtins.filterSource`, except it will compose with itself,
          allowing you to chain multiple calls together without any
          intermediate copies being put in the nix store.
      
          Example:
              lib.cleanSourceWith {
                filter = f;
                src = lib.cleanSourceWith {
                  filter = g;
                  src = ./.;
                };
              }
              # Succeeds!
      
              builtins.filterSource f (builtins.filterSource g ./.)
              # Fails!
      
        */
        cleanSourceWith =
          {
            # A path or cleanSourceWith result to filter and/or rename.
            src,
            # Optional with default value: constant true (include everything)
            # The function will be combined with the && operator such
            # that src.filter is called lazily.
            # For implementing a filter, see
            # https://nixos.org/nix/manual/#builtin-filterSource
            # Type: A function (path -> type -> bool)
            filter ? _path: _type: true,
            # Optional name to use as part of the store path.
            # This defaults to `src.name` or otherwise `"source"`.
            name ? null
          }:
          let
            orig = toSourceAttributes src;
          in fromSourceAttributes {
            inherit (orig) origSrc;
            filter = path: type: filter path type && orig.filter path type;
            name = if name != null then name else orig.name;
          };
      
        /*
          Add logging to a source, for troubleshooting the filtering behavior.
          Type:
            sources.trace :: sourceLike -> Source
        */
        trace =
          # Source to debug. The returned source will behave like this source, but also log its filter invocations.
          src:
          let
            attrs = toSourceAttributes src;
          in
            fromSourceAttributes (
              attrs // {
                filter = path: type:
                  let
                    r = attrs.filter path type;
                  in
                    builtins.trace "${attrs.name}.filter ${path} = ${boolToString r}" r;
              }
            ) // {
              satisfiesSubpathInvariant = src ? satisfiesSubpathInvariant && src.satisfiesSubpathInvariant;
            };
      
        /*
          Filter sources by a list of regular expressions.
      
          Example: src = sourceByRegex ./my-subproject [".*\.py$" "^database.sql$"]
        */
        sourceByRegex = src: regexes:
          let
            isFiltered = src ? _isLibCleanSourceWith;
            origSrc = if isFiltered then src.origSrc else src;
          in lib.cleanSourceWith {
            filter = (path: type:
              let relPath = lib.removePrefix (toString origSrc + "/") (toString path);
              in lib.any (re: match re relPath != null) regexes);
            inherit src;
          };
      
        /*
          Get all files ending with the specified suffices from the given
          source directory or its descendants, omitting files that do not match
          any suffix. The result of the example below will include files like
          `./dir/module.c` and `./dir/subdir/doc.xml` if present.
      
          Type: sourceLike -> [String] -> Source
      
          Example:
            sourceFilesBySuffices ./. [ ".xml" ".c" ]
        */
        sourceFilesBySuffices =
          # Path or source containing the files to be returned
          src:
          # A list of file suffix strings
          exts:
          let filter = name: type:
            let base = baseNameOf (toString name);
            in type == "directory" || lib.any (ext: lib.hasSuffix ext base) exts;
          in cleanSourceWith { inherit filter src; };
      
        pathIsGitRepo = path: (_commitIdFromGitRepoOrError path)?value;
      
        /*
          Get the commit id of a git repo.
      
          Example: commitIdFromGitRepo <nixpkgs/.git>
        */
        commitIdFromGitRepo = path:
          let commitIdOrError = _commitIdFromGitRepoOrError path;
          in commitIdOrError.value or (throw commitIdOrError.error);
      
        # Get the commit id of a git repo.
      
        # Returns `{ value = commitHash }` or `{ error = "... message ..." }`.
      
        # Example: commitIdFromGitRepo <nixpkgs/.git>
        # not exported, used for commitIdFromGitRepo
        _commitIdFromGitRepoOrError =
          let readCommitFromFile = file: path:
              let fileName       = path + "/${file}";
                  packedRefsName = path + "/packed-refs";
                  absolutePath   = base: path:
                    if lib.hasPrefix "/" path
                    then path
                    else toString (../sources.nix + "${base}/${path}");
              in if pathIsRegularFile path
                 # Resolve git worktrees. See gitrepository-layout(5)
                 then
                   let m   = match "^gitdir: (.*)$" (lib.fileContents path);
                   in if m == null
                      then { error = "File contains no gitdir reference: " + path; }
                      else
                        let gitDir      = absolutePath (dirOf path) (lib.head m);
                            commonDir'' = if pathIsRegularFile "${gitDir}/commondir"
                                          then lib.fileContents "${gitDir}/commondir"
                                          else gitDir;
                            commonDir'  = lib.removeSuffix "/" commonDir'';
                            commonDir   = absolutePath gitDir commonDir';
                            refFile     = lib.removePrefix "${commonDir}/" "${gitDir}/${file}";
                        in readCommitFromFile refFile commonDir
      
                 else if pathIsRegularFile fileName
                 # Sometimes git stores the commitId directly in the file but
                 # sometimes it stores something like: «ref: refs/heads/branch-name»
                 then
                   let fileContent = lib.fileContents fileName;
                       matchRef    = match "^ref: (.*)$" fileContent;
                   in if  matchRef == null
                      then { value = fileContent; }
                      else readCommitFromFile (lib.head matchRef) path
      
                 else if pathIsRegularFile packedRefsName
                 # Sometimes, the file isn't there at all and has been packed away in the
                 # packed-refs file, so we have to grep through it:
                 then
                   let fileContent = readFile packedRefsName;
                       matchRef = match "([a-z0-9]+) ${file}";
                       isRef = s: isString s && (matchRef s) != null;
                       # there is a bug in libstdc++ leading to stackoverflow for long strings:
                       # https://github.com/NixOS/nix/issues/2147#issuecomment-659868795
                       refs = filter isRef (split "\n" fileContent);
                   in if refs == []
                      then { error = "Could not find " + file + " in " + packedRefsName; }
                      else { value = lib.head (matchRef (lib.head refs)); }
      
                 else { error = "Not a .git directory: " + toString path; };
          in readCommitFromFile "HEAD";
      
        pathHasContext = builtins.hasContext or (lib.hasPrefix storeDir);
      
        canCleanSource = src: src ? _isLibCleanSourceWith || !(pathHasContext (toString src));
      
        # -------------------------------------------------------------------------- #
        # Internal functions
        #
      
        # toSourceAttributes : sourceLike -> SourceAttrs
        #
        # Convert any source-like object into a simple, singular representation.
        # We don't expose this representation in order to avoid having a fifth path-
        # like class of objects in the wild.
        # (Existing ones being: paths, strings, sources and x//{outPath})
        # So instead of exposing internals, we build a library of combinator functions.
        toSourceAttributes = src:
          let
            isFiltered = src ? _isLibCleanSourceWith;
          in
          {
            # The original path
            origSrc = if isFiltered then src.origSrc else src;
            filter = if isFiltered then src.filter else _: _: true;
            name = if isFiltered then src.name else "source";
          };
      
        # fromSourceAttributes : SourceAttrs -> Source
        #
        # Inverse of toSourceAttributes for Source objects.
        fromSourceAttributes = { origSrc, filter, name }:
          {
            _isLibCleanSourceWith = true;
            inherit origSrc filter name;
            outPath = builtins.path { inherit filter name; path = origSrc; };
          };
      
      in {
        inherit
          pathType
          pathIsDirectory
          pathIsRegularFile
      
          pathIsGitRepo
          commitIdFromGitRepo
      
          cleanSource
          cleanSourceWith
          cleanSourceFilter
          pathHasContext
          canCleanSource
      
          sourceByRegex
          sourceFilesBySuffices
      
          trace
          ;
      }
    );
    "/Users/jeffhykin/repos/nixpkgs/lib/systems/examples.nix" = (# "/Users/jeffhykin/repos/nixpkgs/lib/systems/examples.nix"
      # These can be passed to nixpkgs as either the `localSystem` or
      # `crossSystem`. They are put here for user convenience, but also used by cross
      # tests and linux cross stdenv building, so handle with care!
      { lib }:
      let
        platforms = /*import:normal*/ _-_06294632224836068_-_."/Users/jeffhykin/repos/nixpkgs/lib/systems/platforms.nix" { inherit lib; };
      
        riscv = bits: {
          config = "riscv${bits}-unknown-linux-gnu";
        };
      in
      
      rec {
        #
        # Linux
        #
        powernv = {
          config = "powerpc64le-unknown-linux-gnu";
        };
        musl-power = {
          config = "powerpc64le-unknown-linux-musl";
        };
      
        ppc64 = {
          config = "powerpc64-unknown-linux-gnuabielfv2";
        };
        ppc64-musl = {
          config = "powerpc64-unknown-linux-musl";
          gcc = { abi = "elfv2"; };
        };
      
        sheevaplug = {
          config = "armv5tel-unknown-linux-gnueabi";
        } // platforms.sheevaplug;
      
        raspberryPi = {
          config = "armv6l-unknown-linux-gnueabihf";
        } // platforms.raspberrypi;
      
        remarkable1 = {
          config = "armv7l-unknown-linux-gnueabihf";
        } // platforms.zero-gravitas;
      
        remarkable2 = {
          config = "armv7l-unknown-linux-gnueabihf";
        } // platforms.zero-sugar;
      
        armv7l-hf-multiplatform = {
          config = "armv7l-unknown-linux-gnueabihf";
        };
      
        aarch64-multiplatform = {
          config = "aarch64-unknown-linux-gnu";
        };
      
        armv7a-android-prebuilt = {
          config = "armv7a-unknown-linux-androideabi";
          rustc.config = "armv7-linux-androideabi";
          sdkVer = "28";
          ndkVer = "24";
          useAndroidPrebuilt = true;
        } // platforms.armv7a-android;
      
        aarch64-android-prebuilt = {
          config = "aarch64-unknown-linux-android";
          rustc.config = "aarch64-linux-android";
          sdkVer = "28";
          ndkVer = "24";
          useAndroidPrebuilt = true;
        };
      
        aarch64-android = {
          config = "aarch64-unknown-linux-android";
          sdkVer = "30";
          ndkVer = "24";
          libc = "bionic";
          useAndroidPrebuilt = false;
          useLLVM = true;
        };
      
        pogoplug4 = {
          config = "armv5tel-unknown-linux-gnueabi";
        } // platforms.pogoplug4;
      
        ben-nanonote = {
          config = "mipsel-unknown-linux-uclibc";
        } // platforms.ben_nanonote;
      
        fuloongminipc = {
          config = "mipsel-unknown-linux-gnu";
        } // platforms.fuloong2f_n32;
      
        # can execute on 32bit chip
        mips-linux-gnu                = { config = "mips-unknown-linux-gnu";                } // platforms.gcc_mips32r2_o32;
        mipsel-linux-gnu              = { config = "mipsel-unknown-linux-gnu";              } // platforms.gcc_mips32r2_o32;
        mipsisa32r6-linux-gnu         = { config = "mipsisa32r6-unknown-linux-gnu";         } // platforms.gcc_mips32r6_o32;
        mipsisa32r6el-linux-gnu       = { config = "mipsisa32r6el-unknown-linux-gnu";       } // platforms.gcc_mips32r6_o32;
      
        # require 64bit chip (for more registers, 64-bit floating point, 64-bit "long long") but use 32bit pointers
        mips64-linux-gnuabin32        = { config = "mips64-unknown-linux-gnuabin32";        } // platforms.gcc_mips64r2_n32;
        mips64el-linux-gnuabin32      = { config = "mips64el-unknown-linux-gnuabin32";      } // platforms.gcc_mips64r2_n32;
        mipsisa64r6-linux-gnuabin32   = { config = "mipsisa64r6-unknown-linux-gnuabin32";   } // platforms.gcc_mips64r6_n32;
        mipsisa64r6el-linux-gnuabin32 = { config = "mipsisa64r6el-unknown-linux-gnuabin32"; } // platforms.gcc_mips64r6_n32;
      
        # 64bit pointers
        mips64-linux-gnuabi64         = { config = "mips64-unknown-linux-gnuabi64";         } // platforms.gcc_mips64r2_64;
        mips64el-linux-gnuabi64       = { config = "mips64el-unknown-linux-gnuabi64";       } // platforms.gcc_mips64r2_64;
        mipsisa64r6-linux-gnuabi64    = { config = "mipsisa64r6-unknown-linux-gnuabi64";    } // platforms.gcc_mips64r6_64;
        mipsisa64r6el-linux-gnuabi64  = { config = "mipsisa64r6el-unknown-linux-gnuabi64";  } // platforms.gcc_mips64r6_64;
      
        muslpi = raspberryPi // {
          config = "armv6l-unknown-linux-musleabihf";
        };
      
        aarch64-multiplatform-musl = {
          config = "aarch64-unknown-linux-musl";
        };
      
        gnu64 = { config = "x86_64-unknown-linux-gnu"; };
        gnu32  = { config = "i686-unknown-linux-gnu"; };
      
        musl64 = { config = "x86_64-unknown-linux-musl"; };
        musl32  = { config = "i686-unknown-linux-musl"; };
      
        riscv64 = riscv "64";
        riscv32 = riscv "32";
      
        riscv64-embedded = {
          config = "riscv64-none-elf";
          libc = "newlib";
        };
      
        riscv32-embedded = {
          config = "riscv32-none-elf";
          libc = "newlib";
        };
      
        mmix = {
          config = "mmix-unknown-mmixware";
          libc = "newlib";
        };
      
        rx-embedded = {
          config = "rx-none-elf";
          libc = "newlib";
        };
      
        msp430 = {
          config = "msp430-elf";
          libc = "newlib";
        };
      
        avr = {
          config = "avr";
        };
      
        vc4 = {
          config = "vc4-elf";
          libc = "newlib";
        };
      
        or1k = {
          config = "or1k-elf";
          libc = "newlib";
        };
      
        m68k = {
          config = "m68k-unknown-linux-gnu";
        };
      
        s390 = {
          config = "s390-unknown-linux-gnu";
        };
      
        s390x = {
          config = "s390x-unknown-linux-gnu";
        };
      
        arm-embedded = {
          config = "arm-none-eabi";
          libc = "newlib";
        };
        armhf-embedded = {
          config = "arm-none-eabihf";
          libc = "newlib";
          # GCC8+ does not build without this
          # (https://www.mail-archive.com/gcc-bugs@gcc.gnu.org/msg552339.html):
          gcc = {
            arch = "armv5t";
            fpu = "vfp";
          };
        };
      
        aarch64-embedded = {
          config = "aarch64-none-elf";
          libc = "newlib";
        };
      
        aarch64be-embedded = {
          config = "aarch64_be-none-elf";
          libc = "newlib";
        };
      
        ppc-embedded = {
          config = "powerpc-none-eabi";
          libc = "newlib";
        };
      
        ppcle-embedded = {
          config = "powerpcle-none-eabi";
          libc = "newlib";
        };
      
        i686-embedded = {
          config = "i686-elf";
          libc = "newlib";
        };
      
        x86_64-embedded = {
          config = "x86_64-elf";
          libc = "newlib";
        };
      
        #
        # Redox
        #
      
        x86_64-unknown-redox = {
          config = "x86_64-unknown-redox";
          libc = "relibc";
        };
      
        #
        # Darwin
        #
      
        iphone64 = {
          config = "aarch64-apple-ios";
          # config = "aarch64-apple-darwin14";
          sdkVer = "14.3";
          xcodeVer = "12.3";
          xcodePlatform = "iPhoneOS";
          useiOSPrebuilt = true;
        };
      
        iphone32 = {
          config = "armv7a-apple-ios";
          # config = "arm-apple-darwin10";
          sdkVer = "14.3";
          xcodeVer = "12.3";
          xcodePlatform = "iPhoneOS";
          useiOSPrebuilt = true;
        };
      
        iphone64-simulator = {
          config = "x86_64-apple-ios";
          # config = "x86_64-apple-darwin14";
          sdkVer = "14.3";
          xcodeVer = "12.3";
          xcodePlatform = "iPhoneSimulator";
          darwinPlatform = "ios-simulator";
          useiOSPrebuilt = true;
        };
      
        iphone32-simulator = {
          config = "i686-apple-ios";
          # config = "i386-apple-darwin11";
          sdkVer = "14.3";
          xcodeVer = "12.3";
          xcodePlatform = "iPhoneSimulator";
          darwinPlatform = "ios-simulator";
          useiOSPrebuilt = true;
        };
      
        aarch64-darwin = {
          config = "aarch64-apple-darwin";
          xcodePlatform = "MacOSX";
          platform = {};
        };
      
        x86_64-darwin = {
          config = "x86_64-apple-darwin";
          xcodePlatform = "MacOSX";
          platform = {};
        };
      
        #
        # Windows
        #
      
        # 32 bit mingw-w64
        mingw32 = {
          config = "i686-w64-mingw32";
          libc = "msvcrt"; # This distinguishes the mingw (non posix) toolchain
        };
      
        # 64 bit mingw-w64
        mingwW64 = {
          # That's the triplet they use in the mingw-w64 docs.
          config = "x86_64-w64-mingw32";
          libc = "msvcrt"; # This distinguishes the mingw (non posix) toolchain
        };
      
        # BSDs
      
        x86_64-freebsd = {
          config = "x86_64-unknown-freebsd13";
          useLLVM = true;
        };
      
        x86_64-netbsd = {
          config = "x86_64-unknown-netbsd";
        };
      
        # this is broken and never worked fully
        x86_64-netbsd-llvm = {
          config = "x86_64-unknown-netbsd";
          useLLVM = true;
        };
      
        #
        # WASM
        #
      
        wasi32 = {
          config = "wasm32-unknown-wasi";
          useLLVM = true;
        };
      
        # Ghcjs
        ghcjs = {
          config = "js-unknown-ghcjs";
        };
      }
    );
    "/Users/jeffhykin/repos/nixpkgs/lib/systems/flake-systems.nix" = (# "/Users/jeffhykin/repos/nixpkgs/lib/systems/flake-systems.nix"
      # See [RFC 46] for mandated platform support and ../../pkgs/stdenv for
      # implemented platform support. This list is mainly descriptive, i.e. all
      # system doubles for platforms where nixpkgs can do native compilation
      # reasonably well are included.
      #
      # [RFC 46]: https://github.com/NixOS/rfcs/blob/master/rfcs/0046-platform-support-tiers.md
      { }:
      
      [
        # Tier 1
        "x86_64-linux"
        # Tier 2
        "aarch64-linux"
        "x86_64-darwin"
        # Tier 3
        "armv6l-linux"
        "armv7l-linux"
        "i686-linux"
        "mipsel-linux"
      
        # Other platforms with sufficient support in stdenv which is not formally
        # mandated by their platform tier.
        "aarch64-darwin"
        "armv5tel-linux"
        "powerpc64le-linux"
        "riscv64-linux"
      
        # "x86_64-freebsd" is excluded because it is mostly broken
      ]
    );
    "/Users/jeffhykin/repos/nixpkgs/lib/kernel.nix" = (# "/Users/jeffhykin/repos/nixpkgs/lib/kernel.nix"
      { lib }:
      
      with lib;
      {
      
      
        # Keeping these around in case we decide to change this horrible implementation :)
        option = x:
            x // { optional = true; };
      
        yes      = { tristate    = "y"; optional = false; };
        no       = { tristate    = "n"; optional = false; };
        module   = { tristate    = "m"; optional = false; };
        freeform = x: { freeform = x; optional = false; };
      
        /*
          Common patterns/legacy used in common-config/hardened/config.nix
         */
        whenHelpers = version: {
          whenAtLeast = ver: mkIf (versionAtLeast version ver);
          whenOlder   = ver: mkIf (versionOlder version ver);
          # range is (inclusive, exclusive)
          whenBetween = verLow: verHigh: mkIf (versionAtLeast version verLow && versionOlder version verHigh);
        };
      
      }
    );
    "/Users/jeffhykin/repos/nixpkgs/lib/systems/default.nix" = (# "/Users/jeffhykin/repos/nixpkgs/lib/systems/default.nix"
      { lib }:
        let inherit (lib.attrsets) mapAttrs; in
      
      rec {
        doubles = /*import:first*/ _-_06294632224836068_-_."/Users/jeffhykin/repos/nixpkgs/lib/systems/doubles.nix" { inherit lib; };
        parse = /*import:first*/ _-_06294632224836068_-_."/Users/jeffhykin/repos/nixpkgs/lib/systems/parse.nix" { inherit lib; };
        inspect = /*import:first*/ _-_06294632224836068_-_."/Users/jeffhykin/repos/nixpkgs/lib/systems/inspect.nix" { inherit lib; };
        platforms = /*import:first*/ _-_06294632224836068_-_."/Users/jeffhykin/repos/nixpkgs/lib/systems/platforms.nix" { inherit lib; };
        examples = /*import:first*/ _-_06294632224836068_-_."/Users/jeffhykin/repos/nixpkgs/lib/systems/examples.nix" { inherit lib; };
        architectures = /*import:first*/ _-_06294632224836068_-_."/Users/jeffhykin/repos/nixpkgs/lib/systems/architectures.nix" { inherit lib; };
      
        /* List of all Nix system doubles the nixpkgs flake will expose the package set
           for. All systems listed here must be supported by nixpkgs as `localSystem`.
      
           **Warning**: This attribute is considered experimental and is subject to change.
        */
        flakeExposed = /*import:first*/ _-_06294632224836068_-_."/Users/jeffhykin/repos/nixpkgs/lib/systems/flake-systems.nix" { };
      
        # Elaborate a `localSystem` or `crossSystem` so that it contains everything
        # necessary.
        #
        # `parsed` is inferred from args, both because there are two options with one
        # clearly preferred, and to prevent cycles. A simpler fixed point where the RHS
        # always just used `final.*` would fail on both counts.
        elaborate = args': let
          args = if lib.isString args' then { system = args'; }
                 else args';
          final = {
            # Prefer to parse `config` as it is strictly more informative.
            parsed = parse.mkSystemFromString (if args ? config then args.config else args.system);
            # Either of these can be losslessly-extracted from `parsed` iff parsing succeeds.
            system = parse.doubleFromSystem final.parsed;
            config = parse.tripleFromSystem final.parsed;
            # Determine whether we can execute binaries built for the provided platform.
            canExecute = platform:
              final.isAndroid == platform.isAndroid &&
              parse.isCompatible final.parsed.cpu platform.parsed.cpu
              && final.parsed.kernel == platform.parsed.kernel;
            isCompatible = _: throw "2022-05-23: isCompatible has been removed in favor of canExecute, refer to the 22.11 changelog for details";
            # Derived meta-data
            libc =
              /**/ if final.isDarwin              then "libSystem"
              else if final.isMinGW               then "msvcrt"
              else if final.isWasi                then "wasilibc"
              else if final.isRedox               then "relibc"
              else if final.isMusl                then "musl"
              else if final.isUClibc              then "uclibc"
              else if final.isAndroid             then "bionic"
              else if final.isLinux /* default */ then "glibc"
              else if final.isFreeBSD             then "fblibc"
              else if final.isNetBSD              then "nblibc"
              else if final.isAvr                 then "avrlibc"
              else if final.isNone                then "newlib"
              # TODO(@Ericson2314) think more about other operating systems
              else                                     "native/impure";
            # Choose what linker we wish to use by default. Someday we might also
            # choose the C compiler, runtime library, C++ standard library, etc. in
            # this way, nice and orthogonally, and deprecate `useLLVM`. But due to
            # the monolithic GCC build we cannot actually make those choices
            # independently, so we are just doing `linker` and keeping `useLLVM` for
            # now.
            linker =
              /**/ if final.useLLVM or false      then "lld"
              else if final.isDarwin              then "cctools"
              # "bfd" and "gold" both come from GNU binutils. The existence of Gold
              # is why we use the more obscure "bfd" and not "binutils" for this
              # choice.
              else                                     "bfd";
            extensions = rec {
              sharedLibrary =
                /**/ if final.isDarwin  then ".dylib"
                else if final.isWindows then ".dll"
                else                         ".so";
              staticLibrary =
                /**/ if final.isWindows then ".lib"
                else                         ".a";
              library =
                /**/ if final.isStatic then staticLibrary
                else                        sharedLibrary;
              executable =
                /**/ if final.isWindows then ".exe"
                else                         "";
            };
            # Misc boolean options
            useAndroidPrebuilt = false;
            useiOSPrebuilt = false;
      
            # Output from uname
            uname = {
              # uname -s
              system = {
                linux = "Linux";
                windows = "Windows";
                darwin = "Darwin";
                netbsd = "NetBSD";
                freebsd = "FreeBSD";
                openbsd = "OpenBSD";
                wasi = "Wasi";
                redox = "Redox";
                genode = "Genode";
              }.${final.parsed.kernel.name} or null;
      
               # uname -m
               processor =
                 if final.isPower64
                 then "ppc64${lib.optionalString final.isLittleEndian "le"}"
                 else if final.isPower
                 then "ppc${lib.optionalString final.isLittleEndian "le"}"
                 else if final.isMips64
                 then "mips64"  # endianness is *not* included on mips64
                 else final.parsed.cpu.name;
      
               # uname -r
               release = null;
            };
            isStatic = final.isWasm || final.isRedox;
      
            # Just a guess, based on `system`
            inherit
              ({
                linux-kernel = args.linux-kernel or {};
                gcc = args.gcc or {};
                rustc = args.rust or {};
              } // platforms.select final)
              linux-kernel gcc rustc;
      
            linuxArch =
              if final.isAarch32 then "arm"
              else if final.isAarch64 then "arm64"
              else if final.isx86_32 then "i386"
              else if final.isx86_64 then "x86_64"
              # linux kernel does not distinguish microblaze/microblazeel
              else if final.isMicroBlaze then "microblaze"
              else if final.isMips32 then "mips"
              else if final.isMips64 then "mips"    # linux kernel does not distinguish mips32/mips64
              else if final.isPower then "powerpc"
              else if final.isRiscV then "riscv"
              else if final.isS390 then "s390"
              else final.parsed.cpu.name;
      
            qemuArch =
              if final.isAarch32 then "arm"
              else if final.isx86_64 then "x86_64"
              else if final.isx86 then "i386"
              else final.uname.processor;
      
            # Name used by UEFI for architectures.
            efiArch =
              if final.isx86_32 then "ia32"
              else if final.isx86_64 then "x64"
              else if final.isAarch32 then "arm"
              else if final.isAarch64 then "aa64"
              else final.parsed.cpu.name;
      
            darwinArch = {
              armv7a  = "armv7";
              aarch64 = "arm64";
            }.${final.parsed.cpu.name} or final.parsed.cpu.name;
      
            darwinPlatform =
              if final.isMacOS then "macos"
              else if final.isiOS then "ios"
              else null;
            # The canonical name for this attribute is darwinSdkVersion, but some
            # platforms define the old name "sdkVer".
            darwinSdkVersion = final.sdkVer or (if final.isAarch64 then "11.0" else "10.12");
            darwinMinVersion = final.darwinSdkVersion;
            darwinMinVersionVariable =
              if final.isMacOS then "MACOSX_DEPLOYMENT_TARGET"
              else if final.isiOS then "IPHONEOS_DEPLOYMENT_TARGET"
              else null;
          } // (
            let
              selectEmulator = pkgs:
                let
                  qemu-user = pkgs.qemu.override {
                    smartcardSupport = false;
                    spiceSupport = false;
                    openGLSupport = false;
                    virglSupport = false;
                    vncSupport = false;
                    gtkSupport = false;
                    sdlSupport = false;
                    pulseSupport = false;
                    smbdSupport = false;
                    seccompSupport = false;
                    hostCpuTargets = [ "${final.qemuArch}-linux-user" ];
                  };
                  wine = (pkgs.winePackagesFor "wine${toString final.parsed.cpu.bits}").minimal;
                in
                if final.parsed.kernel.name == pkgs.stdenv.hostPlatform.parsed.kernel.name &&
                  pkgs.stdenv.hostPlatform.canExecute final
                then "${pkgs.runtimeShell} -c '\"$@\"' --"
                else if final.isWindows
                then "${wine}/bin/wine${lib.optionalString (final.parsed.cpu.bits == 64) "64"}"
                else if final.isLinux && pkgs.stdenv.hostPlatform.isLinux
                then "${qemu-user}/bin/qemu-${final.qemuArch}"
                else if final.isWasi
                then "${pkgs.wasmtime}/bin/wasmtime"
                else if final.isMmix
                then "${pkgs.mmixware}/bin/mmix"
                else null;
            in {
              emulatorAvailable = pkgs: (selectEmulator pkgs) != null;
      
              emulator = pkgs:
                if (final.emulatorAvailable pkgs)
                then selectEmulator pkgs
                else throw "Don't know how to run ${final.config} executables.";
      
          }) // mapAttrs (n: v: v final.parsed) inspect.predicates
            // mapAttrs (n: v: v final.gcc.arch or "default") architectures.predicates
            // args;
        in assert final.useAndroidPrebuilt -> final.isAndroid;
           assert lib.foldl
             (pass: { assertion, message }:
               if assertion final
               then pass
               else throw message)
             true
             (final.parsed.abi.assertions or []);
          final;
      }
    );
  };
  output = (
    /* Library of low-level helper functions for nix expressions.
     *
     * Please implement (mostly) exhaustive unit tests
     * for new functions in `./tests.nix`.
     */
    let
    
      inherit (/*import:first*/ _-_06294632224836068_-_."/Users/jeffhykin/repos/nixpkgs/lib/fixed-points.nix" { inherit lib; }) makeExtensible;
    
      lib = makeExtensible (self: let
        callLibs = file: import file { lib = self; };
      in {
    
        # often used, or depending on very little
        trivial =         /*import:first*/ _-_06294632224836068_-_."/Users/jeffhykin/repos/nixpkgs/lib/trivial.nix"                { lib = self; };
        fixedPoints =     /*import:normal*/ _-_06294632224836068_-_."/Users/jeffhykin/repos/nixpkgs/lib/fixed-points.nix"           { lib = self; };
    
        # datatypes
        attrsets =        /*import:first*/ _-_06294632224836068_-_."/Users/jeffhykin/repos/nixpkgs/lib/attrsets.nix"               { lib = self; };
        lists =           /*import:first*/ _-_06294632224836068_-_."/Users/jeffhykin/repos/nixpkgs/lib/lists.nix"                  { lib = self; };
        strings =         /*import:first*/ _-_06294632224836068_-_."/Users/jeffhykin/repos/nixpkgs/lib/strings.nix"                { lib = self; };
        stringsWithDeps = /*import:first*/ _-_06294632224836068_-_."/Users/jeffhykin/repos/nixpkgs/lib/strings-with-deps.nix"      { lib = self; };
    
        # packaging
        customisation =   /*import:first*/ _-_06294632224836068_-_."/Users/jeffhykin/repos/nixpkgs/lib/customisation.nix"          { lib = self; };
        derivations =     /*import:first*/ _-_06294632224836068_-_."/Users/jeffhykin/repos/nixpkgs/lib/derivations.nix"            { lib = self; };
        maintainers = /*import:first*/ _-_06294632224836068_-_."/Users/jeffhykin/repos/nixpkgs/maintainers/maintainer-list.nix";
        teams =           /*import:first*/ _-_06294632224836068_-_."/Users/jeffhykin/repos/nixpkgs/maintainers/team-list.nix" { lib = self; };
        meta =            /*import:first*/ _-_06294632224836068_-_."/Users/jeffhykin/repos/nixpkgs/lib/meta.nix"                   { lib = self; };
        versions =        /*import:first*/ _-_06294632224836068_-_."/Users/jeffhykin/repos/nixpkgs/lib/versions.nix"               { lib = self; };
    
        # module system
        modules =         /*import:first*/ _-_06294632224836068_-_."/Users/jeffhykin/repos/nixpkgs/lib/modules.nix"                { lib = self; };
        options =         /*import:first*/ _-_06294632224836068_-_."/Users/jeffhykin/repos/nixpkgs/lib/options.nix"                { lib = self; };
        types =           /*import:first*/ _-_06294632224836068_-_."/Users/jeffhykin/repos/nixpkgs/lib/types.nix"                  { lib = self; };
    
        # constants
        licenses =        /*import:first*/ _-_06294632224836068_-_."/Users/jeffhykin/repos/nixpkgs/lib/licenses.nix"               { lib = self; };
        sourceTypes =     /*import:first*/ _-_06294632224836068_-_."/Users/jeffhykin/repos/nixpkgs/lib/source-types.nix"           { lib = self; };
        systems =         /*import:first*/ _-_06294632224836068_-_."/Users/jeffhykin/repos/nixpkgs/lib/systems/default.nix"                    { lib = self; };
    
        # serialization
        cli =             /*import:first*/ _-_06294632224836068_-_."/Users/jeffhykin/repos/nixpkgs/lib/cli.nix"                    { lib = self; };
        generators =      /*import:first*/ _-_06294632224836068_-_."/Users/jeffhykin/repos/nixpkgs/lib/generators.nix"             { lib = self; };
    
        # misc
        asserts =         /*import:first*/ _-_06294632224836068_-_."/Users/jeffhykin/repos/nixpkgs/lib/asserts.nix"                { lib = self; };
        debug =           /*import:first*/ _-_06294632224836068_-_."/Users/jeffhykin/repos/nixpkgs/lib/debug.nix"                  { lib = self; };
        misc =            /*import:first*/ _-_06294632224836068_-_."/Users/jeffhykin/repos/nixpkgs/lib/deprecated.nix"             { lib = self; };
    
        # domain-specific
        fetchers =        /*import:first*/ _-_06294632224836068_-_."/Users/jeffhykin/repos/nixpkgs/lib/fetchers.nix"               { lib = self; };
    
        # Eval-time filesystem handling
        path =            /*import:first*/ _-_06294632224836068_-_."/Users/jeffhykin/repos/nixpkgs/lib/path/default.nix"                       { lib = self; };
        filesystem =      /*import:first*/ _-_06294632224836068_-_."/Users/jeffhykin/repos/nixpkgs/lib/filesystem.nix"             { lib = self; };
        sources =         /*import:first*/ _-_06294632224836068_-_."/Users/jeffhykin/repos/nixpkgs/lib/sources.nix"                { lib = self; };
    
        # back-compat aliases
        platforms = self.systems.doubles;
    
        # linux kernel configuration
        kernel =          /*import:first*/ _-_06294632224836068_-_."/Users/jeffhykin/repos/nixpkgs/lib/kernel.nix"                 { lib = self; };
    
        inherit (builtins) add addErrorContext attrNames concatLists
          deepSeq elem elemAt filter genericClosure genList getAttr
          hasAttr head isAttrs isBool isInt isList isPath isString length
          lessThan listToAttrs pathExists readFile replaceStrings seq
          stringLength sub substring tail trace;
        inherit (self.trivial) id const pipe concat or and bitAnd bitOr bitXor
          bitNot boolToString mergeAttrs flip mapNullable inNixShell isFloat min max
          importJSON importTOML warn warnIf warnIfNot throwIf throwIfNot checkListOfEnum
          info showWarnings nixpkgsVersion version isInOldestRelease
          mod compare splitByAndCompare
          functionArgs setFunctionArgs isFunction toFunction
          toHexString toBaseDigits inPureEvalMode;
        inherit (self.fixedPoints) fix fix' converge extends composeExtensions
          composeManyExtensions makeExtensible makeExtensibleWithCustomName;
        inherit (self.attrsets) attrByPath hasAttrByPath setAttrByPath
          getAttrFromPath attrVals attrValues getAttrs catAttrs filterAttrs
          filterAttrsRecursive foldAttrs collect nameValuePair mapAttrs
          mapAttrs' mapAttrsToList concatMapAttrs mapAttrsRecursive mapAttrsRecursiveCond
          genAttrs isDerivation toDerivation optionalAttrs
          zipAttrsWithNames zipAttrsWith zipAttrs recursiveUpdateUntil
          recursiveUpdate matchAttrs overrideExisting showAttrPath getOutput getBin
          getLib getDev getMan chooseDevOutputs zipWithNames zip
          recurseIntoAttrs dontRecurseIntoAttrs cartesianProductOfSets
          updateManyAttrsByPath;
        inherit (self.lists) singleton forEach foldr fold foldl foldl' imap0 imap1
          concatMap flatten remove findSingle findFirst any all count
          optional optionals toList range partition zipListsWith zipLists
          reverseList listDfs toposort sort naturalSort compareLists take
          drop sublist last init crossLists unique intersectLists
          subtractLists mutuallyExclusive groupBy groupBy';
        inherit (self.strings) concatStrings concatMapStrings concatImapStrings
          intersperse concatStringsSep concatMapStringsSep
          concatImapStringsSep makeSearchPath makeSearchPathOutput
          makeLibraryPath makeBinPath optionalString
          hasInfix hasPrefix hasSuffix stringToCharacters stringAsChars escape
          escapeShellArg escapeShellArgs
          isStorePath isStringLike
          isValidPosixName toShellVar toShellVars
          escapeRegex escapeXML replaceChars lowerChars
          upperChars toLower toUpper addContextFrom splitString
          removePrefix removeSuffix versionOlder versionAtLeast
          getName getVersion
          mesonOption mesonBool mesonEnable
          nameFromURL enableFeature enableFeatureAs withFeature
          withFeatureAs fixedWidthString fixedWidthNumber
          toInt toIntBase10 readPathsFromFile fileContents;
        inherit (self.stringsWithDeps) textClosureList textClosureMap
          noDepEntry fullDepEntry packEntry stringAfter;
        inherit (self.customisation) overrideDerivation makeOverridable
          callPackageWith callPackagesWith extendDerivation hydraJob
          makeScope makeScopeWithSplicing;
        inherit (self.derivations) lazyDerivation;
        inherit (self.meta) addMetaAttrs dontDistribute setName updateName
          appendToName mapDerivationAttrset setPrio lowPrio lowPrioSet hiPrio
          hiPrioSet getLicenseFromSpdxId getExe;
        inherit (self.sources) pathType pathIsDirectory cleanSourceFilter
          cleanSource sourceByRegex sourceFilesBySuffices
          commitIdFromGitRepo cleanSourceWith pathHasContext
          canCleanSource pathIsRegularFile pathIsGitRepo;
        inherit (self.modules) evalModules setDefaultModuleLocation
          unifyModuleSyntax applyModuleArgsIfFunction mergeModules
          mergeModules' mergeOptionDecls evalOptionValue mergeDefinitions
          pushDownProperties dischargeProperties filterOverrides
          sortProperties fixupOptionType mkIf mkAssert mkMerge mkOverride
          mkOptionDefault mkDefault mkImageMediaOverride mkForce mkVMOverride
          mkFixStrictness mkOrder mkBefore mkAfter mkAliasDefinitions
          mkAliasAndWrapDefinitions fixMergeModules mkRemovedOptionModule
          mkRenamedOptionModule mkRenamedOptionModuleWith
          mkMergedOptionModule mkChangedOptionModule
          mkAliasOptionModule mkDerivedConfig doRename
          mkAliasOptionModuleMD;
        inherit (self.options) isOption mkEnableOption mkSinkUndeclaredOptions
          mergeDefaultOption mergeOneOption mergeEqualOption mergeUniqueOption
          getValues getFiles
          optionAttrSetToDocList optionAttrSetToDocList'
          scrubOptionValue literalExpression literalExample literalDocBook
          showOption showOptionWithDefLocs showFiles
          unknownModule mkOption mkPackageOption mkPackageOptionMD
          mdDoc literalMD;
        inherit (self.types) isType setType defaultTypeMerge defaultFunctor
          isOptionType mkOptionType;
        inherit (self.asserts)
          assertMsg assertOneOf;
        inherit (self.debug) addErrorContextToAttrs traceIf traceVal traceValFn
          traceXMLVal traceXMLValMarked traceSeq traceSeqN traceValSeq
          traceValSeqFn traceValSeqN traceValSeqNFn traceFnSeqN traceShowVal
          traceShowValMarked showVal traceCall traceCall2 traceCall3
          traceValIfNot runTests testAllTrue traceCallXml attrNamesToStr;
        inherit (self.misc) maybeEnv defaultMergeArg defaultMerge foldArgs
          maybeAttrNullable maybeAttr ifEnable checkFlag getValue
          checkReqs uniqList uniqListExt condConcat lazyGenericClosure
          innerModifySumArgs modifySumArgs innerClosePropagation
          closePropagation mapAttrsFlatten nvs setAttr setAttrMerge
          mergeAttrsWithFunc mergeAttrsConcatenateValues
          mergeAttrsNoOverride mergeAttrByFunc mergeAttrsByFuncDefaults
          mergeAttrsByFuncDefaultsClean mergeAttrBy
          fakeHash fakeSha256 fakeSha512
          nixType imap;
        inherit (self.versions)
          splitVersion;
      });
    in lib
  );
}.output)