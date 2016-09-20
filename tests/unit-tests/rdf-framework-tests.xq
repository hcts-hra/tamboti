xquery version "3.0";
import module namespace hra-rdf-framework="http://hra.uni-heidelberg.de/ns/hra-rdf-framework" at "/db/apps/tamboti/frameworks/hra-rdf/hra-rdf-framework.xqm";

import module namespace functx="http://www.functx.com";
(:declare default element namespace "http://www.w3.org/2000/10/XMLSchema"; :)

declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";

declare namespace vra = "http://www.vraweb.org/vracore4.htm";


(:let $vra-image-uuid := "i_ac340682-56b9-428b-828b-566cdabff105":)
(:let $svg-uuid := "uuid-d4a6d813-2b9b-4ff2-b026-2a378bf9f287":)
(:let $annos-object := hra-rdf-framework:is-object($svg-uuid, "map"):)
(:let $annos-subject := hra-rdf-framework:is-subject($vra-image-uuid, "map"):)

let $iris := ( "http://localhost:8080/exist/apps/tamboti/api/resource/uuid-4bfac9c7-972e-47e2-8026-c226d1551e1e?%2F%2Fsvg%3Asvg",
            "http://localhost:8080/exist/apps/tamboti/api/resource/uuid-442d98bc-18c7-405b-8a66-72fd86a2a2d3?%2F%2Fsvg%3Asvg")

(:let $anno := $annos[1]:)

(:let $iri := $anno//*:Canvas/@*:resource/string():)

(:let $parsed-node := hra-rdf-framework:parse-node($annos-object("node"), "map"):)

return
    hra-rdf-framework:get-annotator-configs()
(:    $parsed-node:)
(:    $annos-object("node"):)
 
(:    hra-rdf-framework:is-object($svg-uuid, "xml"):)
(:    hra-rdf-framework:is-subject($vra-image-uuid, "xml"):)
(:    for $iri in $iris:)
(:    return :)
(:        hra-rdf-framework:resolve-tamboti-iri($iri):)
    
(:    hra-rdf-framework:parse-IRI("samurai@test.org#asd", "xml"):)


    