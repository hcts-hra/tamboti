xquery version "3.1";

declare default element namespace "http://www.loc.gov/mods/v3";

declare variable $api-key := "";
declare variable $api-key-parameter := "?key=" || $api-key;
declare variable $base-uri := xs:anyURI("https://api.zotero.org/groups/2023208");

declare function local:write-resource($collection-key, $resource) {
    let $titleInfo := $resource/(titleInfo[not(@*)], titleInfo[@type = 'translated' and @lang = 'eng'])
    let $originInfo := $resource/originInfo
    
    let $title := string-join($titleInfo/(title, subTitle)[. != ''], ': ')
    let $itemType := map:get($genre-mappings, $resource/genre[1])
    let $creators :=
        for $name in $resource/name
        let $firstName := $name/namePart[@type = 'given']/text()
        let $lastName := $name/namePart[@type = 'family']/text()
        
        return
            for $role in $name/role/roleTerm[. != '']
            
            return
                map {
                    "creatorType": map:get($role-mappings, $role),
                    "firstName" : $firstName,
                    "lastName" : $lastName
                }        
    let $language := string-join($resource/language/element(), '-')
    let $isbn := $resource/identifier[@type = 'isbn'][1]/string(.)
    let $doi := $resource/identifier[@type = 'doi'][1]/string(.)
    let $shortTitle := $titleInfo/title/string(.)  
    
    let $content :=
        [
          map {
            "itemType" : $itemType,
            "title" : $title,
            "creators" : array {$creators},
            "language": $language,        
            "ISBN": $isbn,
            "DOI": $doi,
            "shortTitle": $shortTitle,
            "tags" : [],
            "collections" : array {$collection-key},
            "relations" : map {}
          }
        ]
    let $serialized-content := 
    	serialize(
    		$content,
    		<output:serialization-parameters xmlns:output="http://www.w3.org/2010/xslt-xquery-serialization">
    			<output:method value="json" />
    		</output:serialization-parameters>
    	)    
    (:return $content:)
    return util:base64-decode(httpclient:post(xs:anyURI($base-uri || "/items" || $api-key-parameter), $serialized-content, true(), ()))    
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

let $resources := collection(xmldb:encode('/data/commons/Buddhism Bibliography'))/mods

return
    for $resource in $resources
    
    return local:write-resource("BW6V63FQ", $resource)
