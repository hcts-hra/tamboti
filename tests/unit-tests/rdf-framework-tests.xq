xquery version "3.0";
import module namespace hra-rdf-framework="http://hra.uni-heidelberg.de/ns/hra-rdf-framework" at "/db/apps/tamboti/frameworks/hra-rdf/hra-rdf-framework.xqm";

import module namespace functx="http://www.functx.com";
(:declare default element namespace "http://www.w3.org/2000/10/XMLSchema"; :)

declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";

declare namespace vra = "http://www.vraweb.org/vracore4.htm";


let $vra-image-uuid := "i_56c3ef80-0f9a-4842-911d-4a47ba24dd77"
let $svg-uuid := "uuid-d4a6d813-2b9b-4ff2-b026-2a378bf9f287"
let $annos-object := hra-rdf-framework:is-object($svg-uuid, "map")
let $annos-subject := hra-rdf-framework:is-subject($vra-image-uuid, "map")

(:let $anno := $annos[1]:)

(:let $iri := $anno//*:Canvas/@*:resource/string():)

let $parsed-node := hra-rdf-framework:parse-node($annos-object("node"), "map")

return
    hra-rdf-framework:get-annotation("anno-13eaade-43dc-44a0-bd0f-8341e7b8c846")
(:    $parsed-node('iri'):)
(:    $parsed-node:)
(:    $annos-object("node"):)
 
(:    hra-rdf-framework:is-subject($vra-image-uuid, "xml"):)
(:    hra-rdf-framework:resolve-tamboti-iri($parsed-node("iri")):)
    
(:    hra-rdf-framework:parse-IRI("samurai@test.org#asd", "xml"):)


    