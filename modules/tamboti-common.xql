xquery version "3.0";

module namespace tamboti-common="http://exist-db.org/tamboti/common";

declare namespace mods="http://www.loc.gov/mods/v3";

(:
tamboti-common:get-query-as-regex
tamboti-common:highlight-matches()
:)

(: Later move
tamboti-common:clean-up-punctuation()
tamboti-common:simple-row()
tamboti-common:add-part()
tamboti-common:serialize-list()
tamboti-common:remove-parent-with-missing-required-node()
functx:capitalize-first()
functx:camel-case-to-words()
functx:trim()
:)

(:~
: The tamboti-common:highlight-matches function highlights the search result in detail view with the search string, including 
: searches made with wildcards. Slightly adapted from Joe Wicentowski's function in order to deal with Lucene casing.
: @author Joe Wicentowski
: @param $nodes the search result to apply highlighting to
: @param $pattern the regex used for applying highlighting
: @param $highlight the highlight function
: @return one or more items
: @see https://gist.github.com/joewiz/5937897
:)
declare function tamboti-common:highlight-matches($nodes as node()*, $pattern as xs:string, $highlight as function(xs:string) as item()* ) { 
    for $node in $nodes
    return
        typeswitch ( $node )
            case element() return
                element { name($node) } { $node/@*, tamboti-common:highlight-matches($node/node(), $pattern, $highlight) }
            case text() return
                let $normalized := replace($node, '\s+', ' ')
                (:apply case-insensitive search for use with Lucene:)
                for $segment in analyze-string($normalized, $pattern, 'i')/node()
                return
                    if ($segment instance of element(fn:match)) then 
                        $highlight($segment/string())
                    else 
                        $segment/string()
            case document-node() return
                document { tamboti-common:highlight-matches($node/node(), $pattern, $highlight) }
            default return
                $node
};

