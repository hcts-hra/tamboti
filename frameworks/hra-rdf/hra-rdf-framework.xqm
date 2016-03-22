xquery version "3.0";
(:~
 : Tamboti RDF Framework Module
 : 
 : @version 0.1
 : @author Matthias Guth
 :)

module namespace hra-rdf-framework = "http://hra.uni-heidelberg.de/ns/hra-rdf-framework";
import module namespace tamboti-config = "http://exist-db.org/mods/config" at "../../modules/config.xqm";
import module namespace tamboti-security = "http://exist-db.org/mods/security" at "../../modules/search/security.xqm";
import module namespace functx="http://www.functx.com";

declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace oa="http://www.w3.org/ns/oa#";


(: ToDo: dynamically get namespaces according to existing Tamboti frameworks :)

declare namespace mods = "http://www.loc.gov/mods/v3";
declare namespace vra = "http://www.vraweb.org/vracore4.htm";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace atom = "http://www.w3.org/2005/Atom";
declare namespace html = "http://www.w3.org/1999/xhtml";
declare namespace svg="http://www.w3.org/2000/svg";


declare variable $hra-rdf-framework:IRI-resolver-prefix := "/tamboti/api/resource/";

(:~
: returns rdf annotations with resource(-parts) as subject
: @param $tamboti-uuid tamboti-uuid for resource
: @param $format default: xml
: @return RDF annotations serialized to the format.
:)
declare function hra-rdf-framework:is-subject($tamboti-uuid as xs:string, $format as xs:string?) {
    let $col := collection($tamboti-config:content-root)
    let $format := if ($format) then $format else "xml"
    let $anno := $col/rdf:RDF/oa:Annotation[./oa:hasBody[contains(@rdf:resource, $hra-rdf-framework:IRI-resolver-prefix || $tamboti-uuid)]]
    let $format := 
        if ($format) then 
            $format
        else
            "xml"
    return
        switch ($format)
            case "map" return
                let $nodes := $anno/oa:hasBody[contains(@rdf:resource, $hra-rdf-framework:IRI-resolver-prefix || $tamboti-uuid)]
                return
                    map{
                        "anno" := $anno,
                        "node" := $nodes[1]
                    }
            default return
                $anno
};

declare function hra-rdf-framework:is-object($tamboti-uuid as xs:string, $format as xs:string?) {
    let $col := collection($tamboti-config:content-root)
    let $anno := $col/rdf:RDF/oa:Annotation[./oa:hasTarget[contains(@rdf:resource, $hra-rdf-framework:IRI-resolver-prefix || $tamboti-uuid)]]
    let $format := 
        if ($format) then 
            $format
        else
            "xml"
    return
        switch ($format)
            case "map" return
                let $nodes := $anno/oa:hasTarget[contains(@rdf:resource, $hra-rdf-framework:IRI-resolver-prefix || $tamboti-uuid)]
                return
                    map{
                        "anno" := $anno,
                        "node" := $nodes[1]
                    }
            default return
                $anno

};

declare function hra-rdf-framework:get-subject($anno as element(oa:Annotation)) {
    $anno/oa:hasTarget
};

declare function hra-rdf-framework:get-object($anno as element(oa:Annotation)) {
    $anno/oa:hasObject
};


(:~
: parses an rfc3986 IRI according to http://tools.ietf.org/html/rfc3986#appendix-B
: @param $iri the IRI 
: @param $format return format: xml or map? default: xml
: @return the parsed IRI as $format
:)

declare function hra-rdf-framework:parse-iri($iri as xs:string, $format as xs:string?) {

    let $fragment := substring-after($iri, "#")
    let $rest := functx:substring-before-if-contains($iri, "#")
    let $query := substring-after($rest, "?")
    let $rest := functx:substring-before-if-contains($rest, "?")
    let $scheme := substring-before($rest, "://")
    let $rest := functx:substring-after-if-contains($rest, "://")
    let $authority := functx:substring-before-if-contains($rest, "/")
    let $path := substring-after($rest, "/")
    let $resource := functx:substring-after-last($path, "/")
    
    return

        switch($format)
            case "map" return
                map {
                    "iri" := $iri,
                    "scheme" := $scheme,
                    "authority" := $authority,
                    "path" := $path,
                    "query" := $query,
                    "fragment" := $fragment,
                    "resource" := $resource
                }
            default return
                <parsedIri>
                    <iri>{$iri}</iri>
                    <scheme>{$scheme}</scheme>
                    <authority>{$authority}</authority>
                    <path>{$path}</path>
                    <query>{$query}</query>
                    <resource>{$resource}</resource>
                </parsedIri>
};

(:~
: parses a node string
: @param $node-or-iri node() with @rdf:resource attribute containing IRI or IRI as xs:string 
: @param $format xml or map? default: xml
: @return the parsed IRI
:)
declare function hra-rdf-framework:parse-node($node-or-iri, $format as xs:string) {
    let $IRI := 
        if ($node-or-iri instance of node()) then
            $node-or-iri/@rdf:resource/string()
        else
            $node-or-iri

    return 
        hra-rdf-framework:parse-iri($IRI, $format)
};


(:~
 : resolves a complete tamboti IRI
 :
 : 
 : 
 : 
 :)

declare function hra-rdf-framework:resolve-tamboti-iri($iri as xs:anyURI) {
    let $parsed := hra-rdf-framework:parse-iri($iri, "xml")
    
    let $query := xmldb:decode($parsed/query/string())
    return
        hra-rdf-framework:get-tamboti-resource($parsed/resource/string(), $query)
};

(:~
 : get a Tamboti resource and eval the query string if any
 :
 : 
 : 
 : 
 :)

declare function hra-rdf-framework:get-tamboti-resource($uuid as xs:string, $query-string as xs:string?) as node()*{
    let $xquery := "root(tamboti-security:get-resource(""" || $uuid || """))" || $query-string

    (: preload namespaces from node   :)
    (:    let $load-namespace := :)
    (:        for $prefix in in-scope-prefixes($node-with-resource-element):)
    (:        where not($prefix="xml"):)
    (:        return:)
    (:            util:declare-namespace($prefix, namespace-uri-for-prefix($prefix, $node-with-resource-element)):)
     
    (: do the query    :)
    let $result := util:eval($xquery)
    (: to keep the singularity of an IRI return only the first result if there are more :)
    return 
        $result[1]
};