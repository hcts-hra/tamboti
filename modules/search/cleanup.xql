(:~
    Module to clean up a MODS record. Removes empty elements, empty attributes and elements without required subelements.
:)

module namespace clean="http://exist-db.org/xquery/mods/cleanup";

declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace functx = "http://www.functx.com";

(: Removes empty attributes. Attributes are often left empty by the Tamboti editor. :)
declare function clean:remove-empty-attributes($element as element()) as element() {
element { node-name($element)}
{ $element/@*[string-length(.) ne 0],
for $child in $element/node( )
return 
    if ($child instance of element())
    then clean:remove-empty-attributes($child)
    else $child }
};

(: Removes empty attributes except @transliteration. Since transliterated title have @type value "translated", just as translated titles, the existence of @transliteration is necessary to distinguish between the two-
Attributes are often left empty by the Tamboti editor. :)
declare function clean:remove-empty-attributes-except-transliteration($element as element()) as element() {
element { node-name($element)}
{ $element/@*[string-length(.) ne 0 or name(.) eq 'transliteration'],
for $child in $element/node( )
return 
    if ($child instance of element())
    then clean:remove-empty-attributes-except-transliteration($child)
    else $child }
};

(: Removes an element if it is empty or contains whitespace only. 
A mods:relatedItem should be allowed to be empty if it has an @xlink:href.
A vra:relationSet should be allowed to be empty if its vra:relation has an idrefs.
:)
(: Derived from functx:remove-elements-deep. :)
(: Contains functx:all-whitespace. :)
declare function clean:remove-empty-elements($nodes as node()*)  as node()* {
   for $node in $nodes
   return
     if ($node instance of element())
     then if ((normalize-space($node) = '') and (not($node/@xlink:href or $node//@relids)))
          then ()
          else element { node-name($node)}
                { $node/@*,
                  clean:remove-empty-elements($node/node())}
     else if ($node instance of document-node())
     then clean:remove-empty-elements($node/node())
     else $node
 } ;

(: The function called in session.xql which passes search results to retrieve-mods.xql after cleaning them. It remove all empty attributes except @transliteration, since the transliteration attribute is used, even if empty. :)
declare function clean:cleanup($node as node()) {
        let $result := clean:remove-empty-elements($node)
        return
            let $result := clean:remove-empty-attributes-except-transliteration($result)
            return
                $result
            };

(: The function called in source.xql which cleans records before presenting them in XML view, for import into other tools. This removes all empty attributes. :) 
 declare function clean:cleanup-for-code-view($node as node()) {
    let $result := clean:remove-empty-attributes($node)
    return
        let $result := clean:remove-empty-elements($result)
        return
            $result
            };