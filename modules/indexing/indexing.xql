xquery version "3.1";

import module namespace catalog-resolver = "http://hra.uni-heidelberg.de/ns/tamboti/catalog-resolver/" at "../catalogs/catalog-resolver.xqm";

declare function local:set-computed-indexes($resource) {
    let $document-uri := $resource/root()/document-uri(.)
    let $document-root-namespace-uri := $resource/root()/*/namespace-uri()
    let $document-root-local-name := $resource/root()/*/local-name()
    let $document-type-identifier := "{" || $document-root-namespace-uri || "}" || $document-root-local-name
    
    let $module-details := catalog-resolver:resolve-clark-notation-system-id($document-type-identifier)
    let $module-namespace-uri := $module-details("namespace-uri")
    let $module-location-uri := $module-details("location-uri")
    let $module := load-xquery-module($module-namespace-uri, map {"location-hints": $module-location-uri})
    let $computed-indexes := $module("functions")(QName($module-namespace-uri, "generate-computed-indexes"))(1)($resource)

    return ( 
        ft:remove-index($document-uri) 
        ,
        ft:index( 
            $document-uri
            ,
            <doc>
                <field name="author" store="yes">{$computed-indexes("author")}</field>
            </doc>
        )
        ,
        $computed-indexes
    )
};

for $resource in collection("/data/commons/Cluster%20Publications")

return ft:has-index($resource/root()/document-uri(.)) 
(:    local:set-computed-indexes($resource):)