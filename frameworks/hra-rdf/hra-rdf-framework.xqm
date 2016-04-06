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
declare variable $hra-rdf-framework:anno-IRI-resolver-prefix := "/tamboti/api/annotation/";

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
                <parsedIri xmlns="http://hra.uni-heidelberg.de/ns/hra-rdf-framework">
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

    let $query := xmldb:decode($parsed/hra-rdf-framework:query/text() )
    return
        hra-rdf-framework:get-tamboti-resource($parsed/hra-rdf-framework:resource/string(), $query)
        
};

(:~
 : get a Tamboti resource and eval the query string if any
 :
 : 
 : 
 : 
 :)

declare function hra-rdf-framework:get-tamboti-resource($uuid as xs:string, $query-string as xs:string?){
    let $document := tamboti-security:get-resource($uuid)
    return
        if($document) then
            let $xquery := "root($document)" || $query-string
            (: preload namespaces from document   :)
            let $load-namespace := 
                for $prefix in in-scope-prefixes($document)
                where not($prefix="xml")
                return
                    util:declare-namespace($prefix, namespace-uri-for-prefix($prefix, $document))
             
            (: do the query :)
            let $result := util:eval($xquery)
            (: to keep the singularity of an IRI return only the first result if there are more :)
            let $result := $result[1]
            return
                if($result instance of node()) then
                    $result
                else
                    <span>{$result}</span>
        else
            <span />
};

declare function hra-rdf-framework:add-annotation($resourceUUID as xs:string, $annotationXML as document-node()) {
    let $col := collection($tamboti-config:content-root)
    return
        try {
            for $new-anno in $annotationXML/rdf:RDF/oa:Annotation
                (: get the annotation UUID :)
                let $anno-iri := $new-anno/@rdf:about/string()
                (: check as dba, if annotation exists:)
                let $existing-anno := system:as-user($tamboti-config:dba-credentials[1], $tamboti-config:dba-credentials[2], 
                    $col//rdf:RDF/oa:Annotation[@rdf:about=$anno-iri]
                )
                return
                    (: if the annotation exists, try to update it  :)
                    if ($existing-anno) then
                        let $result := update replace $existing-anno with $new-anno
                        return
                            <success>annotation {$anno-iri} updated successfully</success>
                    (: Anno does not exist, so try to create it in the anno file for the body resource:)
                    else
(:                        let $log := util:log("DEBUG", "try to insert anno"):)
                        (: annotation document's name is the same as the resource's name (without extension), appending _anno.rdf   :)
                        let $col := collection($tamboti-config:content-root)
                        (: if get-resource is successful, user has at least read access and though is allowed to annotate :)
                        let $document-node := tamboti-security:get-resource($resourceUUID)
                        (:  check if annotation document is available :)

                        let $document-col := util:collection-name(root($document-node))
                        let $document-name := util:document-name(root($document-node))

                        let $anno-doc-name := functx:substring-before-last($document-name, ".") || "_anno.rdf"
                        let $anno-doc-uri := xs:anyURI($document-col || "/" || $anno-doc-name)
                        (: if file exists: try to insert the anno, else store anno as ne resource :)
                        let $result := 
                            if(not(exists(doc($anno-doc-uri)/rdf:RDF))) then 
                                let $document-node := 
                                    <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:oa="http://www.w3.org/ns/oa#"/>
                                return tamboti-security:store-resource($document-col, $anno-doc-name, $document-node)
                            else 
                                ()
                        let $result := update insert $new-anno into doc($anno-doc-uri)/rdf:RDF

                        return
                            <success>Annotation {$anno-iri} added successfully!</success>
                            
                            
        } catch * {
            let $log := util:log("ERROR", "Error: adding annotation failed with exception: " ||  $err:code || ": " || $err:description)
            return
                <error>Error: adding annotation failed with exception: {$err:code}: {$err:description}</error>
        }
};

declare function hra-rdf-framework:get-annotation($annotation-uuid as xs:string) {
    let $col := collection($tamboti-config:content-root)
    let $result := $col/rdf:RDF/oa:Annotation[ends-with(@rdf:about, $annotation-uuid)]
    return
        if ($result) then
            <rdf:RDF>
                {
                    $result
                }
            </rdf:RDF>
        else
            ()
}; 