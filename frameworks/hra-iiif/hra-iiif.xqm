xquery version "3.1";

module namespace hra-iiif="http://hra.uni-heidelberg.de/ns/hra-iiif";

declare namespace json="http://www.json.org";
declare namespace vra="http://www.vraweb.org/vracore4.htm";
declare namespace svg="http://www.w3.org/2000/svg";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

import module namespace http="http://expath.org/ns/http-client";
import module namespace security = "http://exist-db.org/mods/security" at "/apps/tamboti/modules/search/security.xqm";
import module namespace image-service="http://hra.uni-heidelberg.de/ns/image-service" at "/apps/tamboti/modules/display/image-service.xqm";
import module namespace iiif-functions = "http://hra.uni-heidelberg.de/ns/iiif-functions" at "/apps/tamboti/modules/display/iiif-functions.xqm";

import module namespace mongodb = "http://expath.org/ns/mongo" at "java:org.exist.mongodb.xquery.MongodbModule";

declare variable $hra-iiif:mongo-url := "mongodb://localhost";
declare variable $hra-iiif:mongo-database := "tamboti-test";
declare variable $hra-iiif:mongo-manifest-collection := "manifests";

declare variable $hra-iiif:data-collection := collection("/db/data");
declare variable $hra-iiif:tamboti-uri := "http://kjc-ws118.kjc.uni-heidelberg.de:8080/exist/apps/tamboti";

declare variable $hra-iiif:tamboti-api := $hra-iiif:tamboti-uri || "/api";

declare variable $hra-iiif:json-serialize-parameters :=
    <output:serialization-parameters xmlns:output="http://www.w3.org/2010/xslt-xquery-serialization">
        <output:method value="json"/>
        <output:media-type value="text/javascript"/>
    </output:serialization-parameters>;


declare variable $hra-iiif:sequence-default-metadata := 
    <sequence-metadata>
        <label>Current Page Order</label>
        <viewingDirection>left-to-right</viewingDirection>
        <viewingHint>paged</viewingHint>
    </sequence-metadata>;

declare variable $hra-iiif:manifest-default-metadata := 
    map {
        "@context": "http://iiif.io/api/presentation/2/context.json",
        "@type": "sc:Manifest",
        "label": "Tamboti Collection",
        "attribution": "Provided by Cluster of Excellence &quot;Asia &amp; Europe&quot;",
        "viewingDirection": "left-to-right",
        "viewingHint": "paged"
    };


declare function hra-iiif:generate-canvas($vra-image-xml as node()) {
    (: Get image info.json and parse it to xml if no canvas svg present :)
    let $image-uuid := $vra-image-xml/@id/string()
    
    let $iiif-image-uri := $hra-iiif:tamboti-api || "/iiif/" || $image-uuid

    let $iiif-parameters := iiif-functions:parse-iiif-call($image-uuid || "/info.json")

    let $image-info := image-service:get-info($vra-image-xml, $iiif-parameters)
    let $image-info := parse-json($image-info)

(::)
(:        (::)
(:            ToDo: handle percentages?:)
(:        :):)
    let $canvas-width := 
            if ($image-info?width < 1200) then
                $image-info?width * 2
            else
                $image-info?width

    let $canvas-height := 
            if ($image-info?height < 1200) then
                $image-info?height * 2
            else
                $image-info?height
    let $canvas-uri := $hra-iiif:tamboti-api || "/canvas/" || util:uuid()
        (: ToDo: read primary canvas container out of SVG. Until this, the "starting crop" is "full" :)
    let $pageSegment := "full"

    let $json-map :=
            map{
                "@id": $canvas-uri,
                "@type": "sc:Canvas",
                "label": $vra-image-xml/vra:titleSet/vra:title[1]/string(),
                "width": $canvas-width,
                "height": $canvas-height,
                "images":
                    array{
                        map{
                            "@type": "oa:Annotation",
                            "motivation": "sc:painting",
                            "on": $canvas-uri,
                            "resource":
                                map{
                                    "@id": $iiif-image-uri || "/" || $pageSegment || "/full/0/default.jpg",
                                    "@type": "dctypes:Image",
                                    "format": "image/jpeg",
                                    "width": $canvas-width,
                                    "height": $canvas-height,
                                    "service": array{
                                        map{
                                          "@context": "http://iiif.io/api/image/2/context.json",
                                          "@id": $iiif-image-uri,
                                          "profile": "http://iiif.io/api/image/2/profiles/level2.json"
                                        }
                                        ,
                                        "http://kjc-ws118.kjc.uni-heidelberg.de:8080/exist/apps/tamboti/modules/login.html"
                                    }
                                }
                        }
                    }
                }

    return
        $json-map
};

(:declare function hra-iiif:collection-canvases($collection-name as xs:anyURI) {:)
(:    let $imageUUIDs := :)
(:        for $imageIs-relations in collection($collection-name)//vra:work/vra:relationSet/vra:relation[@type="imageIs"]:)
(:            let $pref-image :=:)
(:                if ($imageIs-relations[@pref="true"]) then :)
(:                    $imageIs-relations[@pref="true"]:)
(:                else:)
(:                    $imageIs-relations[1]:)
(:            return $pref-image/@relids:)
(:    let $log := util:log("INFO", count($imageUUIDs)):)
(:    let $imageVRAs := collection("/db/data")//vra:image[@id = $imageUUIDs]:)
(:    let $log := util:log("INFO", count($imageVRAs)):)
(:    return:)
(:        hra-iiif:canvases-generate($imageVRAs):)
(::)
(:};:)

declare function hra-iiif:generate-canvases($image-VRAs as node()*) {
    
(:    let $log := util:log("INFO", $image-VRAs):)
    let $canvases-json-array :=
        array{
(:                for $imageIs-relations in collection($collection-name)//vra:work/vra:relationSet/vra:relation[@type="imageIs"]:)
            for $vra in $image-VRAs
                let $canvas-json-map := hra-iiif:generate-canvas($vra)
                return
                    $canvas-json-map
            }
    return 
        $canvases-json-array
};

declare function hra-iiif:generate-manifest($manifest-metadata as map(), $manifest-uuid as xs:string?) {
(:    let $manifest-metadata := :)
(:        if ($manifest-metadata) then :)
(:            $manifest-metadata:)
(:        else :)
(:            $hra-iiif:manifest-default-metadata:)

    let $manifest-uuid := 
        if ($manifest-uuid) then 
            $manifest-uuid
        else 
            util:uuid()

    (: get the default values as metadata, overwrite it with submitted metadata :)
    let $metadata := 
        map:new((
                $hra-iiif:manifest-default-metadata,
                $manifest-metadata,
                map{"@id": $hra-iiif:tamboti-api || "/manifest/" || $manifest-uuid}
        ))
    return
        $metadata
(:        map:new($metadata):)

};

declare function hra-iiif:generate-sequence($sequence-metadata as node()?, $vra-images) {
    let $log := util:log("INFO", request:get-parameter-names())
    let $sequence-uuid := util:uuid()
    let $sequence-metadata := 
        if ($sequence-metadata) then $sequence-metadata
        else $hra-iiif:sequence-default-metadata
        
    let $map := map{
        "@context":"http://iiif.io/api/presentation/2/context.json",
        "@id": $hra-iiif:tamboti-api || "/sequence/" || $sequence-uuid || "/normal",
        "@type":"sc:Sequence",
        "canvases": hra-iiif:generate-canvases($vra-images) 
    }
    return
        map:new(($map, 
            map:new(
                for $meta in $sequence-metadata/*
                    return
                    map:entry(name($meta), $meta/string())
            )
        ))
};

declare function hra-iiif:generate-auth-service(){
   array{
        map{
          "@context": "http://iiif.io/api/auth/0/context.json",
          "@id": "http://kjc-ws118.kjc.uni-heidelberg.de:8080/exist/apps/tamboti/modules/login.html",
          "profile": "http://iiif.io/api/auth/0/login",
          "label": "Protected Material",
          "description": "You have to login into Tamboti to get access",
          "service": array{
            map{
              "@context": "http://iiif.io/api/auth/0/context.json",
              "@id": "https://wellcomelibrary.org/iiif/tokenterms",
              "profile": "http://iiif.io/api/auth/0/token"
            },
            map{
              "@context": "http://iiif.io/api/auth/0/context.json",
              "@id": "http://kjc-ws118.kjc.uni-heidelberg.de:8080/exist/apps/tamboti/modules/login.html?action=logout",
              "profile": "http://iiif.io/api/auth/0/logout",
              "label": "Log out of Tamboti",
              "description": "Log out of Tamboti"
            }
          }
        }
    }  
};

declare function hra-iiif:generate-collection-manifest($collection-name as xs:anyURI, $manifest-uuid as xs:string?, $manifest-metadata as map(), $orderBy as xs:string?) {
    let $cookie-value := request:get-cookie-value("T-AUTH")
    let $cookie-user := security:iiifauth-validate-cookie($cookie-value)
    let $log := util:log("INFO", request:get-cookie-names())
    let $log := util:log("INFO", "COOKIE VALUE FOUND: " || $cookie-value)

    let $user := 
        if ($cookie-user) then
            let $log := util:log("INFO", "COOKIE USER: " || $cookie-user)
            return
                $cookie-user
        else
            security:get-user-credential-from-session()[1]
    
    let $user-read := security:user-has-access($user, $collection-name, "r.x")
    (: if user does not have access, provide login service:)
    let $manifest-metadata := 
(:        if($user-read) then:)
(:            map{}:)
(:        else:)
            map{
                "service": hra-iiif:generate-auth-service()
            }

    let $orderBy := 
        if ($orderBy) then $orderBy
        else
            "root($imageIs-relations)/vra:titleSet/vra:title[1]/string() ascending"
    let $manifest := hra-iiif:generate-manifest($manifest-metadata, $manifest-uuid)
    return
        try {
            (:  get all pref (or first) Images :)
            let $imageUUIDs := 
(:                system:as-user(security:get-user-credential-from-session()[1],security:get-user-credential-from-session()[2],:)
                    for $imageIs-vra in collection($collection-name)//vra:work[./vra:relationSet/vra:relation[@type="imageIs"]]
            (:        order by data($imageIs-vra/vra:titleSet/vra:title[1]) ascending:)
                        return
            (:                let $log := util:log("INFO", $imageIs-vra/vra:titleSet/vra:title[1]/string()):)
                            let $imageIs-relations := $imageIs-vra//vra:work/vra:relationSet/vra:relation[@type="imageIs"]
                            let $pref-image :=
                                if ($imageIs-relations[@pref="true"]) then 
                                    $imageIs-relations[@pref="true"]
                                else
                                    $imageIs-relations[1]
                            return $pref-image/@relids/string()
(:                ):)
        let $imageVRAs := collection($collection-name)//vra:image[@id=$imageUUIDs]
(:        let $log := util:log("INFO", $imageVRAs):)
(:        let $imageVRAs := security:get-resources($imageUUIDs):)
        let $sequences := hra-iiif:generate-sequence((), $imageVRAs)
        return
(:            $manifest:)

            map:new(($manifest, 
                map{
                    "sequences": 
                        array{
                            $sequences
                        }
                    }
                    ))
    } catch * {
        let $log := util:log("INFO", $err:code || ": " || $err:description)
        let $manifest := hra-iiif:generate-manifest($manifest-metadata, $manifest-uuid)
        return
            $manifest
    }
};

declare function hra-iiif:store-manifest($manifest-map as map(*)) {
    (: connect to mongodb :)
    let $mongodbClientId := mongodb:connect($hra-iiif:mongo-url)
    
    (: first look for existence of the manifest in mongodb  :)
    let $manifest-id := $manifest-map?("@id")
(:    let $manifest-iri := $hra-iiif:tamboti-api || "/manifest/" || $manifest-uuid:)
    
    let $found := mongodb:find($mongodbClientId, $hra-iiif:mongo-database, $hra-iiif:mongo-manifest-collection, "{'@id': '" || $manifest-id || "'}")

    let $log := util:log("INFO", "{'@id': '" || $manifest-id || "'}")
    let $log := util:log("INFO", $found)
    let $result := 
        if ($found) then
            mongodb:update($mongodbClientId, $hra-iiif:mongo-database, $hra-iiif:mongo-manifest-collection, "{'@id': '" || $manifest-id || "'}", serialize($manifest-map, $hra-iiif:json-serialize-parameters), true(), false())
        else
            mongodb:insert($mongodbClientId, $hra-iiif:mongo-database, $hra-iiif:mongo-manifest-collection, serialize($manifest-map, $hra-iiif:json-serialize-parameters))

            
            
(:            "not found":)
(:let $json-text := mongodb:findAndModify($mongodbClientId, $database, $collection, '{ "@id": "http://kjc-ws118.kjc.uni-heidelberg.de:8080/exist/apps/tamboti/api/manifest/e3b1489e-4149-42c5-81d0-349d243f6b2f"})', '{ "@id": "12345"}'):)
(:let $json := parse-json($json-text):)
    
    return $result
};