xquery version "3.1";

import module namespace catalog-resolver = "http://hra.uni-heidelberg.de/ns/tamboti/catalog-resolver/" at "/apps/tamboti/modules/catalogs/catalog-resolver.xqm";

declare function local:set-computed-indexes($resource) {
    let $document-uri := $resource/root()/document-uri(.)
    let $document-root-namespace-uri := $resource/root()/*/namespace-uri()
    let $document-root-local-name := $resource/root()/*/local-name()
    let $document-type-identifier := "urn:" || $document-root-namespace-uri || ":" || $document-root-local-name
    
    let $module-details := catalog-resolver:resolve-system-id($document-type-identifier)
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
                <field name="authors" store="yes">{$computed-indexes("authors")}</field>
                <field name="names" store="yes">{$computed-indexes("names")}</field>
                <field name="year" store="yes">{$computed-indexes("year")}</field>
                <field name="title" store="yes">{$computed-indexes("title")}</field>
            </doc>
        )
        ,
        $computed-indexes
    )
};



for $resource in collection("/data/commons")/*[@ID = "uuid-6128d855-45dd-3f72-af14-f72def28caa4"]/root()

return (
     local:set-computed-indexes($resource/*)
     ,
     parse-xml(ft:get-field($resource/root()/document-uri(.), "title"))
(:     ,:)
(:     ft:get-field($resource/root()/document-uri(.), "names"):)
)
    
(:    local:set-computed-indexes($resource):)
