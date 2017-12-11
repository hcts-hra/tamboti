xquery version "3.1";

declare default element namespace "http://www.loc.gov/mods/v3";

declare namespace zapi="http://zotero.org/ns/api";
declare namespace atom="http://www.w3.org/2005/Atom";
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace z="http://www.zotero.org/namespaces/export#";
declare namespace dc="http://purl.org/dc/elements/1.1/";
declare namespace dcterms="http://purl.org/dc/terms/";

import module namespace functx="http://www.functx.com";

declare function local:rec-get-items($uri as xs:anyURI, $api-key as xs:string) {
    let $body := httpclient:get(xs:anyURI($uri || "&amp;key=" || $api-key) , true(), ())/httpclient:body/*
    let $self := $body/atom:link[@rel="self"]/@href/string()
    let $next := $body/atom:link[@rel="next"]/@href/string()
    let $last := $body/atom:link[@rel="last"]/@href/string()
    let $entries := $body/atom:entry

    return
        if (not($next) or $self = $last) then
            $body/atom:entry
        else
            (
                $entries,
                local:rec-get-items(xs:anyURI($next), $api-key)
            )
};

(:let $api-key := "":)
(:let $init-uri := xs:anyURI("https://api.zotero.org/users/475425/collections/9KH9TNSJ/items/top?format=atom&amp;content=mods&amp;limit=100&amp;itemType=-attachment"):)

let $api-key := ""
let $init-uri := xs:anyURI("https://api.zotero.org/groups/2023208/items?")
let $content :=
    [
      map {
        "itemType" : "book",
        "title" : "My Book 22",
        "creators" : [
          map {
            "creatorType":"author",
            "firstName" : "Sam",
            "lastName" : "McAuthor"
          },
          map {
            "creatorType":"editor",
            "name" : "John T. Singlefield"
          }
        ],
        "tags" : [
          map {"tag" : "awesome" },
          map {"tag" : "rad", "type" : 1 }
        ],
        "collections" : [
          
        ],
        "relations" : map {
          "owl:sameAs" : "http://zotero.org/groups/1/items/JKLM6543",
          "dc:relation" : "http://zotero.org/groups/1/items/PQRS6789",
          "dc:replaces" : "http://zotero.org/users/1/items/BCDE5432"
        }
      }
    ]
let $serialized-content := 
	serialize(
		$content,
		<output:serialization-parameters xmlns:output="http://www.w3.org/2010/xslt-xquery-serialization">
			<output:method value="json" />
		</output:serialization-parameters>
	)    

return util:base64-decode(httpclient:post(xs:anyURI($init-uri || "&amp;key=" || $api-key), $serialized-content, true(), ()))