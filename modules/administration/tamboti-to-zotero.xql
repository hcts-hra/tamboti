xquery version "3.1";

declare namespace atom="http://www.w3.org/2005/Atom";
declare namespace zapi="http://zotero.org/ns/api";

declare variable $api-key := "";
declare variable $api-key-parameter := "?key=" || $api-key;
declare variable $base-uri := xs:anyURI("https://api.zotero.org/groups/2023208");

declare function local:create-collection($collection-name, $parent-collection-key) {
    let $subcollections := local:get-subcollections($parent-collection-key)
    
    return 
        if (empty(index-of($subcollections, $collection-name)))
        then
            let $content :=
                [
                  map {
                    "name": $collection-name,
                    "parentCollection": if (empty($parent-collection-key)) then false() else $parent-collection-key
                  }
                ]  
            let $serialized-content := serialize( 
            		$content,
            		<output:serialization-parameters xmlns:output="http://www.w3.org/2010/xslt-xquery-serialization">
            			<output:method value="json"/>
            		</output:serialization-parameters>
            ) 
            let $request-headers :=
                <headers>
                    <header name="Content-Type" value="application/xml" />
                    <header name="Zotero-Write-Token" value="{replace(util:uuid(), '-', '')}" />
                </headers>            
        	
            return httpclient:post(xs:anyURI($base-uri || "/collections" || $api-key-parameter || "&amp;format=atom"), $serialized-content, true(), $request-headers)/httpclient:body/*
        else ()
};

declare function local:delete-collection($collection-key, $if-unmodified-since-version) {
    let $collection-uri := xs:anyURI($base-uri || "/collections/" || $collection-key || $api-key-parameter || "&amp;format=atom")
    let $expected-version :=
        if (empty($if-unmodified-since-version))
        then httpclient:get($collection-uri, true(), ())/httpclient:body//zapi:version/text()
        else $if-unmodified-since-version
    let $request-headers :=
        <headers>
            <header name="If-Unmodified-Since-Version" value="{$expected-version}" />
        </headers>        
    
    return httpclient:delete($collection-uri, true(), $request-headers)
};

declare function local:delete-item($item-key, $if-unmodified-since-version) {
    let $item-uri := xs:anyURI($base-uri || "/items/" || $item-key || $api-key-parameter || "&amp;format=atom")
    let $expected-version :=
        if (empty($if-unmodified-since-version))
        then httpclient:get($item-uri, true(), ())/httpclient:body//zapi:version/text()
        else $if-unmodified-since-version
    let $request-headers :=
        <headers>
            <header name="If-Unmodified-Since-Version" value="{$expected-version}" />
        </headers>        
    
    return httpclient:delete($item-uri, true(), $request-headers)
};

declare function local:get-subcollections($collection-key) {
    let $subcollections-path :=
        if ($collection-key != "")
        then "/" || $collection-key || "/collections"
        else ""
    let $response := httpclient:get(xs:anyURI($base-uri || "/collections" || $subcollections-path || $api-key-parameter || "&amp;format=atom"), true(), ())/httpclient:body//atom:entry/atom:title/text()
    
    return distinct-values($response)
};

let $collection-name := "Buddhism Bibliography"


return ( 
(:    for $entry in httpclient:get(xs:anyURI($base-uri || "/collections" || $api-key-parameter || "&amp;format=atom"), true(), ())/httpclient:body//atom:entry:)
(:    :)
(:    return local:delete-collection($entry/zapi:key, ()):)
(:    ,:)

    local:create-collection($collection-name, ())


(:    for $entry in httpclient:get(xs:anyURI($base-uri || "/items" || $api-key-parameter || "&amp;format=atom"), true(), ())/httpclient:body//atom:entry:)
(:    :)
(:    return local:delete-item($entry/zapi:key, ()):)
)
