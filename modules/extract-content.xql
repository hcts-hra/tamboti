xquery version "1.0";

import module namespace content="http://exist-db.org/xquery/contentextraction"
    at "java:org.exist.contentextraction.xquery.ContentExtractionModule";
import module namespace config="http://exist-db.org/mods/config" at "config.xqm";

declare namespace extract="http://www.asia-europe.uni-heidelberg.de/tamboti/content-extraction";
declare namespace xhtml="http://www.w3.org/1999/xhtml";

declare function extract:do-index($fieldName as xs:string, $value as xs:string?, $path as xs:anyURI) {
    let $index :=
        <doc>
            <field name="{$fieldName}" store="yes">{$value}</field>
        </doc>
    let $null := ft:index($path, $index, false())
    return
        ()
};

declare function extract:index-callback($root as element(), $path as xs:anyURI, $page as xs:integer?) {
    typeswitch ($root)
        case element(xhtml:meta) return
            ( extract:do-index($root/@name, $root/@content/string(), $path), $page )
        case element(xhtml:title) return
            let $log := util:log("DEBUG", ("TITLE: ", $root/text())) return
            ( extract:do-index("Title", $root/text(), $path), $page)
        default return
            if ($root/@class eq 'page') then
                let $page := if (empty($page)) then 1 else $page + 1
                return
                    ( extract:do-index("page", concat("[[", $page, "]]", string-join($root//xhtml:p/string(), " ")), $path), $page)
            else
                $page
};

declare function extract:index($uri as xs:anyURI) {
    let $doc := util:binary-doc($uri)
    return
        if (ends-with($uri, ".pdf")) then
            let $callback := util:function(xs:QName("extract:index-callback"), 3)
            let $namespaces := 
                <namespaces><namespace prefix="xhtml" uri="http://www.w3.org/1999/xhtml"/></namespaces>
            let $index :=
                content:stream-content($doc, ("//xhtml:meta", "//xhtml:title", "//xhtml:div"), $callback, $namespaces, $uri)
            return
                ft:close()
        else
            let $content := content:get-metadata-and-content($doc)
            let $idxDoc :=
                <doc>
                    <field name="page" store="yes">{string-join($content//xhtml:body//text(), " ")}</field>
                </doc>
            return
                ft:index($uri, $idxDoc, true())
};

declare function extract:scan-resources($collection as xs:string) {
    for $resource in xmldb:get-child-resources($collection)
    let $path := concat($collection, "/", $resource)
    where util:is-binary-doc($path)
    return
        extract:index(xs:anyURI($path)),
    for $child in xmldb:get-child-collections($collection)
    return
        extract:scan-resources(concat($collection, "/", $child))
};

extract:scan-resources($config:mods-root)