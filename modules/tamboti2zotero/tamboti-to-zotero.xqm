xquery version "3.1";

module namespace tamboti2zotero = "http://hra.uni-heidelberg.de/ns/tamboti/tamboti2zotero/";

import module namespace crypto = "http://expath.org/ns/crypto";

declare default element namespace "http://www.loc.gov/mods/v3";

declare namespace atom="http://www.w3.org/2005/Atom";
declare namespace zapi="http://zotero.org/ns/api";

declare variable $tamboti2zotero:api-key := "";
declare variable $tamboti2zotero:api-key-parameter := "?key=" || $tamboti2zotero:api-key;
(:declare variable $tamboti2zotero:base-uri := xs:anyURI("https://api.zotero.org/groups/2023208");:)
declare variable $tamboti2zotero:base-uri := xs:anyURI("https://api.zotero.org/users/4588859/");
declare variable $tamboti2zotero:genre-mappings := map {
    "Encyclopedia" : "encyclopediaArticle",
    "forumPost" : "forumPost",
    "interview" : "interview",
    "Travelogue" : "book",
    "speech" : "presentation",
    "law" : "statute",
    "magazineArticle" : "magazineArticle",
    "blogPost" : "blogPost",
    "Bibliography" : "bookSection",
    "blog" : "blogPost",
    "Blog" : "blogPost",
    "editedVolume" : "book",
    "whitepaper" : "presentation",
    "Diary" : "book",
    "Anthology" : "book",
    "diary" : "book",
    "webpage" : "webpage",
    "film" : "film",
    "Digest" : "journalArticle",
    "Autobiography" : "book",
    "periodical" : "journalArticle",
    "letter" : "letter",
    "manuscript" : "manuscript",
    "radioBroadcast" : "radioBroadcast",
    "Secondary Source" : "document",
    "computerProgram" : "computerProgram",
    "book" : "book",
    "Muromachi" : "book",
    "Collected Works" : "document",
    "thesis" : "thesis",
    "text" : "document",
    "newspaper article" : "newspaperArticle",
    "conferencePaper" : "conferencePaper",
    "other" : "document",
    "canonical scripture" : "book",
    "Translation" : "book",
    "contract" : "statute",
    "Biography" : "book",
    "report" : "report",
    "motion picture" : "film",
    "liturgical text" : "book",
    "Dictionary" : "dictionaryEntry",
    "article" : "journalArticle",
    "Textbook" : "book",
    "videoRecording" : "videoRecording",
    "videorecording" : "videoRecording",
    "encyclopediaArticle" : "encyclopediaArticle",
    "series" : "book",
    "Series" : "book",
    "memorandum" : "book",
    "journal" : "journalArticle",
    "technical report" : "report",
    "Documents" : "book",
    "Phdthesis" : "thesis",
    "Primary Source" : "book",
    "issue" : "book",
    "newspaper" : "newspaperArticle",
    "declaration" : "report",
    "presentation" : "presentation",
    "document" : "document",
    "audioRecording" : "audioRecording",
    "dictionaryEntry" : "dictionaryEntry",
    "novel" : "book",
    "bookSection" : "bookSection",
    "newspaperArticle" : "newspaperArticle",
    "essay" : "book",
    "Festschrift" : "book",
    "festschrift" : "book",
    "Diplomarbeit" : "thesis",
    "petition" : "report",
    "journalArticle" : "journalArticle",
    "treaty" : "statute"
};

declare variable $tamboti2zotero:role-mappings := map {
    "aut": "author",
    "translator": "translator",
    "author": "author",
    "editor": "editor",
    "co-editor": "editor",
    "edt": "editor",
    "ctb": "contributor",
    "trl": "translator",
    "com": "editor",
    "drt": "director",
    "pro": "producer",
    "act": "castMember",
    "sdr": "contributor",
    "cre": "creator",
    "cwt": "commenter",
    "cmp": "composer",
    "Monograph": "contributor"
};

declare function tamboti2zotero:create-collection($collection-name, $parent-collection-key) {
    let $subcollections := tamboti2zotero:get-subcollections($parent-collection-key)
    
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
        	
            return httpclient:post(xs:anyURI($tamboti2zotero:base-uri || "collections" || $tamboti2zotero:api-key || "&amp;format=atom"), $serialized-content, true(), $request-headers)/httpclient:body/*
        else ()
};

declare function tamboti2zotero:delete-collection($collection-key, $if-unmodified-since-version) {
    let $collection-uri := xs:anyURI($tamboti2zotero:base-uri || "collections/" || $collection-key || $tamboti2zotero:api-key-parameter || "&amp;format=atom")
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

declare function tamboti2zotero:delete-item($item-key, $if-unmodified-since-version) {
    let $item-uri := xs:anyURI($tamboti2zotero:base-uri || "items/" || $item-key || $tamboti2zotero:api-key-parameter || "&amp;format=atom")
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

declare function tamboti2zotero:get-subcollections($collection-key) {
    let $subcollections-path :=
        if ($collection-key != "")
        then "/" || $collection-key || "/collections"
        else ""
    let $response := httpclient:get(xs:anyURI($tamboti2zotero:base-uri || "collections" || $subcollections-path || $tamboti2zotero:api-key-parameter || "&amp;format=atom"), true(), ())/httpclient:body//atom:entry/atom:title/text()
    
    return distinct-values($response)
};

declare function tamboti2zotero:write-resource($collection-key, $tamboti-resource) {
    let $tamboti-genre := if (exists($tamboti-resource/genre[1])) then $tamboti-resource/genre[1] else "book"
    let $itemType := map:get($tamboti2zotero:genre-mappings, $tamboti-genre)
    
    let $content := array {
        map:new((
            tamboti2zotero:generate-general-fields($tamboti-resource, $itemType)
            ,
            switch($itemType)
                case "book" return tamboti2zotero:generate-fields-for-book-itemType($tamboti-resource)
                default return ()
            ,
            tamboti2zotero:generate-accessing-fields($tamboti-resource)
            ,
            tamboti2zotero:generate-additional-fields($tamboti-resource)
            ,
            map {
                "tags" : [],
                "collections" : array {$collection-key},
                "relations" : map {}
            }
        ))
    }
    let $serialized-content := serialize(
        $content,
        <output:serialization-parameters xmlns:output="http://www.w3.org/2010/xslt-xquery-serialization">
        	<output:method value="json" />
        </output:serialization-parameters>
    )
    let $result :=
        try {
            parse-json(util:base64-decode(httpclient:post(xs:anyURI($tamboti2zotero:base-uri || "items" || $tamboti2zotero:api-key-parameter), $serialized-content, true(), ())))
        }
        catch * {
            map {
                "error": "Error for " || $serialized-content
            }
        }    
    let $zotero-item-key :=
        let $zotero-item-key-success := map:get($result, 'success')
        
        return
            if (exists($zotero-item-key-success))
            then map:get($zotero-item-key-success, '0')
            else ()
    let $failed := map:get(map:get($result, 'failed'), '0')
    
    return (
        if (exists($zotero-item-key))
        then
            let $zotero-child-attachment-item-key := tamboti2zotero:create-zotero-child-attachment-item($zotero-item-key, $tamboti-resource)
            let $zotero-child-attachment-item-key-success := map:get($zotero-child-attachment-item-key, "success")
            
            return
                if (exists($zotero-child-attachment-item-key-success))
                then tamboti2zotero:upload-tamboti-resource($tamboti-resource, map:get($zotero-child-attachment-item-key-success, '0'))
                else $zotero-child-attachment-item-key
        else ()
        ,
        if (exists($failed))
        then $failed
        else ()        
    )
};

declare function tamboti2zotero:generate-general-fields($resource, $itemType) {
    let $titleInfo := $resource/(titleInfo[not(@*)], titleInfo[@type = 'translated' and @lang = 'eng'])[string(.) != '']
    let $originInfo := $resource/originInfo

    let $title-1 := string-join($titleInfo/(nonSort, title)[. != ''], ' ')
    let $title-2 := string-join(($title-1, $titleInfo/subTitle)[. != ''], ': ')
    let $creators :=
        for $name in $resource/name
        let $firstName := $name/namePart[@type = 'given']/text()
        let $lastName := $name/namePart[@type = 'family']/text()
        
        return
            for $role in $name/role/roleTerm[. != '']
            
            return map {
                "creatorType": map:get($tamboti2zotero:role-mappings, $role),
                "firstName" : $firstName,
                "lastName" : $lastName
            }
    let $abstract := $resource/abstract/string(.)
    let $date := $originInfo/dateIssued/string(.)
    let $shortTitle := $titleInfo/title/string(.)
    let $language := string-join($resource/language/element(), '-')
    
    
    return map {
        "itemType": $itemType,
        "title": $title-2,
        "creators": array {$creators},
        "abstractNote": "",
        "date": "",
        "shortTitle": $shortTitle,
        "language": $language
    }
};

declare function tamboti2zotero:generate-fields-for-book-itemType($resource) {
    let $series := $resource/relatedItem[@type = 'series']
    let $originInfo := $resource/originInfo
    
    let $seriesTitle := string-join($series/titleInfo[string(.) != '']/(title, subTitle), ': ')
    let $seriesNumber := $series/part/detail[@type = 'volume']/number/string(.)
    let $place := string-join($originInfo/place/placeTerm[string(.) != '']/(title, subTitle), ', ')
    let $publisher := $originInfo/publisher[not(@*)]/string(.)
    let $numPages := $resource/physicalDescription/extent[@unit = 'pages']/string(.)
    let $isbn := $resource/identifier[@type = 'isbn'][1]/string(.)

    return map {
        "volume": $seriesTitle,
        "numberOfVolumes": "",
        "edition": "",
        "series": $seriesTitle,
        "seriesNumber": $seriesNumber,
        "place": $place,
        "publisher": $publisher,
        "numPages": $numPages,
        "ISBN": $isbn
    }    
};

declare function tamboti2zotero:generate-accessing-fields($resource) {
    let $location := $resource/location
    
    let $accessDate := $location/url/@dateLastAccessed/string(.)
    let $doi := $resource/identifier[@type = 'doi'][1]/string(.)
    let $url := $location/url/string(.)
    
    return map {
        "accessDate": $accessDate,
        "DOI": $doi,
        "url": $url,
        "archive": "",
        "archiveLocation": "",
        "libraryCatalog": "",
        "callNumber": ""
    }
};

declare function tamboti2zotero:generate-additional-fields($resource) {
    let $rights := $resource/accessCondition/string(.)
    
    return map {
        "rights": $rights,
        "extra": ""
    }
};

declare function tamboti2zotero:create-zotero-child-attachment-item($parent-item-key, $tamboti-resource) {
    let $tamboti-resource-uri := $tamboti-resource/root()/document-uri(.)
    let $tamboti-resource-mime-type := xmldb:get-mime-type($tamboti-resource-uri)
    let $tamboti-resource-name := util:document-name($tamboti-resource)
    let $tamboti-resource-md5 := crypto:hash($tamboti-resource, "MD5", "hex")
    
    let $content := array {
        map {
            "itemType": "attachment",
            "parentItem": $parent-item-key,
            "linkMode": "imported_file",
            "title": $tamboti-resource-name,
            "accessDate": "",
            "url": "",
            "note": "",
            "tags": [],
            "relations": map {},
            "contentType": $tamboti-resource-mime-type,
            "charset": "UTF-8",
            "filename": $tamboti-resource-name           
        }
    }
    let $serialized-content := serialize(
        $content,
        <output:serialization-parameters xmlns:output="http://www.w3.org/2010/xslt-xquery-serialization">
        	<output:method value="json" />
        </output:serialization-parameters>
    )
    let $request-result := httpclient:post(xs:anyURI($tamboti2zotero:base-uri || "items" || $tamboti2zotero:api-key-parameter), $serialized-content, true(), ())
    let $result :=
        try {
            parse-json(util:base64-decode($request-result))
        }
        catch * {
            map {
                "error": "Error for " || $request-result
            }
        }    
    
    return $result
};

declare function tamboti2zotero:upload-tamboti-resource($tamboti-resource, $zotero-child-attachment-item-key) {
    let $tamboti-resource-uri := $tamboti-resource/root()/document-uri(.)
    
    let $tamboti-resource-collection := util:collection-name($tamboti-resource)
    let $tamboti-resource-mime-type := xmldb:get-mime-type($tamboti-resource-uri)
    let $serialized-tamboti-resource := tamboti2zotero:serialize-resource($tamboti-resource, $tamboti-resource-mime-type)
    
    let $tamboti-resource-md5 := crypto:hash($serialized-tamboti-resource, "MD5", "hex")
    let $tamboti-resource-name := util:document-name($tamboti-resource)
    let $serialized-tamboti-resource-size := string-length($serialized-tamboti-resource)
    
    let $upload-authorization-result := tamboti2zotero:get-upload-authorization($tamboti-resource-md5, $tamboti-resource-name, $serialized-tamboti-resource-size, $tamboti-resource-mime-type, $zotero-child-attachment-item-key)
    let $file-exists := map:get($upload-authorization-result, 'exists')
    let $file-doesnt-exist := map:get($upload-authorization-result, 'url')
    let $error := map:get($upload-authorization-result, 'error')

    return (
        if (exists($file-doesnt-exist))
        then 
            let $uploadKey := tamboti2zotero:perform-upload($serialized-tamboti-resource, $upload-authorization-result)
            let $register-upload := tamboti2zotero:register-upload($uploadKey, $zotero-child-attachment-item-key)
            
            return ()
        else ()
        ,
        if (exists($file-exists))
        then ()
        else ()
        ,
        if (exists($error))
        then $upload-authorization-result
        else ()        
    )
};

declare function tamboti2zotero:get-upload-authorization($tamboti-resource-md5, $tamboti-resource-name, $serialized-tamboti-resource-length, $tamboti-resource-mime-type, $zotero-child-attachment-item-key) {
    let $request-content := 
        map {
            "md5": $tamboti-resource-md5,
            "filename": $tamboti-resource-name,
            "filesize": $serialized-tamboti-resource-length,
            "mtime": (current-dateTime() - xs:dateTime("1970-01-01T00:00:00-00:00")) div xs:dayTimeDuration('PT0.001S'),
            "contentType": $tamboti-resource-mime-type
        }
    let $serialized-request-content := string-join(for-each(map:keys($request-content), function($key) {$key || "=" || map:get($request-content, $key)}), "&amp;")
    let $request-headers :=
        <headers>
            <header name="Content-Type" value="application/x-www-form-urlencoded" />
            <header name="If-None-Match" value="*" />
        </headers>
    let $request-result := httpclient:post(xs:anyURI($tamboti2zotero:base-uri || "items/" || $zotero-child-attachment-item-key || "/file" || $tamboti2zotero:api-key-parameter), $serialized-request-content, true(), $request-headers)
    let $result :=
        try {
            parse-json(util:base64-decode($request-result))
        }
        catch * {
            map {
                "error": ("Error for " || $zotero-child-attachment-item-key, $request-result)
            }
        }    
    
    return $result
};

declare function tamboti2zotero:perform-upload($serialized-tamboti-resource, $upload-authorization) {
    let $url := map:get($upload-authorization, 'url')
    let $prefix := map:get($upload-authorization, 'prefix')
    let $suffix := map:get($upload-authorization, 'suffix')
    let $contentType := map:get($upload-authorization, 'contentType')
    let $uploadKey := map:get($upload-authorization, 'uploadKey')
    
    let $request-content := $prefix || $serialized-tamboti-resource || $suffix
    let $request-headers := 
        <headers>
            <header name="Content-Type" value="{$contentType}" />
        </headers> 
    let $result := httpclient:post(xs:anyURI($url), $request-content, true(), $request-headers)
    
    return $uploadKey
};

declare function tamboti2zotero:register-upload($uploadKey, $zotero-child-attachment-item-key) {
    let $request-content := "upload=" || $uploadKey
    let $request-headers := 
        <headers>
            <header name="Content-Type" value="application/x-www-form-urlencoded" />
            <header name="If-None-Match" value="*" />
        </headers>    
    
    return httpclient:post(xs:anyURI($tamboti2zotero:base-uri || "items/" || $zotero-child-attachment-item-key || "/file" || $tamboti2zotero:api-key-parameter), $request-content, true(), $request-headers)
};

declare function tamboti2zotero:serialize-resource($tamboti-resource, $tamboti-resource-mime-type) {
    switch ($tamboti-resource-mime-type)
    case "application/xml" return tamboti2zotero:serialize-xml-resource($tamboti-resource)
    default return ()
};

declare function tamboti2zotero:serialize-xml-resource($tamboti-resource) {
    serialize (
        $tamboti-resource,
        <output:serialization-parameters xmlns:output="http://www.w3.org/2010/xslt-xquery-serialization">
        	<output:method value="xml" />
        </output:serialization-parameters>
    )        
};
