xquery version "3.1";

declare default element namespace "http://www.loc.gov/mods/v3";

declare variable $api-key := "1tV4KC897ZouMWhVWyyikJYv";
declare variable $api-key-parameter := "?key=" || $api-key;
declare variable $base-uri := xs:anyURI("https://api.zotero.org/groups/2023208");

declare function local:write-resource($collection-key, $resource) {
    let $itemType := map:get($genre-mappings, $resource/genre[1])
    
    let $content := array {
        map:new((
            local:generate-general-fields($resource, $itemType)
            ,
            switch($itemType)
                case "book" return local:generate-fields-for-book-itemType($resource)
                default return ()
            ,
            local:generate-accessing-fields($resource)
            ,
            local:generate-additional-fields($resource)
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
    let $result := parse-json(util:base64-decode(httpclient:post(xs:anyURI($base-uri || "/items" || $api-key-parameter), $serialized-content, true(), ())))
    
    return map:get(map:get($result, 'success'), '0')
};

declare variable $genre-mappings := map {
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

declare variable $role-mappings := map {
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

declare function local:generate-general-fields($resource, $itemType) {
    let $titleInfo := $resource/(titleInfo[not(@*)], titleInfo[@type = 'translated' and @lang = 'eng'])[string(.) != '']
    let $originInfo := $resource/originInfo

    let $title := string-join($titleInfo/(title, subTitle)[. != ''], ': ')
    let $creators :=
        for $name in $resource/name
        let $firstName := $name/namePart[@type = 'given']/text()
        let $lastName := $name/namePart[@type = 'family']/text()
        
        return
            for $role in $name/role/roleTerm[. != '']
            
            return map {
                "creatorType": map:get($role-mappings, $role),
                "firstName" : $firstName,
                "lastName" : $lastName
            }
    let $abstract := $resource/abstract/string(.)
    let $date := $originInfo/dateIssued/string(.)
    let $shortTitle := $titleInfo/title/string(.)
    let $language := string-join($resource/language/element(), '-')
    
    
    return map {
        "itemType": $itemType,
        "title": $title,
        "creators": array {$creators},
        "abstractNote": "",
        "date": "",
        "shortTitle": $shortTitle,
        "language": $language
    }
};

declare function local:generate-fields-for-book-itemType($resource) {
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

declare function local:generate-accessing-fields($resource) {
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

declare function local:generate-additional-fields($resource) {
    let $rights := $resource/accessCondition/string(.)
    
    return map {
        "rights": $rights,
        "extra": ""
    }
};

declare function local:add-attachment-to-item($parent-item-key, $tamboti-id) {
    let $content := array {
        map {
            "itemType": "attachment",
            "parentItem": $parent-item-key,
            "linkMode": "imported_file",
            "title": $tamboti-id,
            "accessDate": "2012-03-14T17:45:54Z",
            "url": "http://example.com/doc.pdf",
            "note": "",
            "tags": [],
            "relations": map {},
            "contentType": "application/xml",
            "charset": "UTF-8",
            "filename": $tamboti-id || ".xml"
        }
    }
    let $serialized-content := serialize(
        $content,
        <output:serialization-parameters xmlns:output="http://www.w3.org/2010/xslt-xquery-serialization">
        	<output:method value="json" />
        </output:serialization-parameters>
    )
    let $result := parse-json(util:base64-decode(httpclient:post(xs:anyURI($base-uri || "/items" || $api-key-parameter), $serialized-content, true(), ())))
    
    return $result
};

let $resources := collection(xmldb:encode('/data/commons/Buddhism Bibliography'))[position() = (1 to 7)]/mods

return local:add-attachment-to-item("DJCNC7HW", "tamboti-id")

(:    for $resource in $resources:)
(:    :)
(:    return local:write-resource("BW6V63FQ", $resource):)
