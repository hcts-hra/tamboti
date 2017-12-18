xquery version "3.1";

declare default element namespace "http://www.loc.gov/mods/v3";

declare variable $genre-mappings :=

map {
"Ph.D." : "",
"Encyclopedia" : "",
"N/A" : "",
"forum" : "",
"forumPost" : "",
"interview" : "",
"Travelogue" : "",
"speech" : "",
"Status Report" : "",
"law" : "",
"magazineArticle" : "",
"interactive" : "",
"blogPost" : "",
"Bibliography" : "",
"blog" : "",
"Blog" : "",
"editedVolume" : "",
"whitepaper" : "",
"Diary" : "",
"Anthology" : "",
"diary" : "",
"webpage" : "",
"film" : "",
"Digest" : "",
"Link collection" : "",
"Autobiography" : "",
"Family" : "",
"Blo" : "",
"periodical" : "",
"letter" : "",
"Executive Summary Report" : "",
"FP7 project" : "",
"manuscript" : "",
"Fantasy" : "",
"radioBroadcast" : "",
"Secondary Source" : "",
"PhD Dissertation" : "",
"Software" : "",
"Drama" : "",
"Religious Blog" : "",
"Entertainment" : "",
"Education" : "",
"computerProgram" : "",
"book" : "book",
"Master thesis" : "",
"Diploma Thesis" : "",
"Muromachi" : "",
"Collected Works" : "",
"portal" : "",
"thesis" : "",
"Ph.D. Thesis" : "",
"text" : "",
"Text" : "",
"Thesis (PhD level)" : "",
"documentary" : "",
"International Standard" : "",
"sound" : "",
"e-Journal" : "",
"newspaper article" : "",
"guideline" : "",
"Musical" : "",
"Survey Results" : "",
"conferencePaper" : "",
"The Chronicle of Higher Education" : "",
"Seminararbeit" : "",
"Adventure" : "",
"other" : "",
"Wiki" : "",
"canonical scripture" : "",
"Translation" : "",
"Report of the Annual Conference of the Cluster of Excellence &#34;Asia and Europe in a Global Context&#34;" : "",
"Crime" : "",
"contract" : "",
"web site" : "",
"Conference or Workshop Item" : "",
"workshop paper" : "",
"educational" : "",
"Dissertation" : "",
"Biography" : "",
"report" : "",
"interim report" : "",
"ppt" : "",
"motion picture" : "",
"digital essay" : "",
"Service" : "",
"software evaluation" : "",
"liturgical text" : "",
"Dictionary" : "",
"article" : "",
"Textbook" : "",
"Action" : "",
"Présentation" : "",
"e-journal (but coins for Z not working)" : "",
"Project page" : "",
"videoRecording" : "",
"videorecording" : "",
"encyclopediaArticle" : "",
"Conference Website" : "",
"series" : "",
"Series" : "",
"memorandum" : "",
"journal" : "",
"technical report" : "",
"Technical Report" : ""
,
"best practice" : ""
,
"Final Draft International Standard" : ""
,
"Thriller" : ""
,
"Conference report" : ""
,
"MA level" : ""
,
"Documents" : ""
,
"MA thesis" : ""
,
"Phdthesis" : ""
,
"Review" : ""
,
"Primary Source" : ""
,
"issue" : ""
,
"newspaper" : ""
,
"Comedy" : ""
,
"Survey Report" : ""
,
"declaration" : ""
,
"Forum - Q&A" : ""
,
"presentation" : ""
,
"student-paper" : ""
,
"Deutscher Bundestag Pressestelle" : ""
,
"document" : ""
,
"SSRN Scholarly Paper" : ""
,
"Personal Website" : ""
,
"audioRecording" : ""
,
"Masters Thesis" : ""
,
"dictionaryEntry" : ""
,
"novel" : ""
,
"guide" : ""
,
"bookSection" : ""
,
"Dissertation (Microform)" : ""
,
"multimedia and multi-layered presentation" : ""
,
"newspaperArticle" : ""
,
"essay" : ""
,
"Festschrift" : ""
,
"festschrift" : ""
,
"Thesis (MA level)" : ""
,
"Diplomarbeit" : ""
,
"petition" : ""
,
"Habilitation" : ""
,
"IPI PAN Reports" : ""
,
"Mystery" : ""
,
"journalArticle" : ""
,
"Romance" : ""
,
"treaty" : ""
,
"Deliverable" : ""
};

declare variable $role-mappings :=
    map {
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

let $resource := doc(xmldb:encode('/data/commons/Buddhism Bibliography/uuid-01754502-1003-4f5c-9825-a5ef073232b0.xml'))/mods
let $titleInfo := $resource/(titleInfo[not(@*)], titleInfo[@type = 'translated' and @lang = 'eng'])
let $originInfo := $resource/originInfo

let $title := $titleInfo/title/string(.)
let $language := string-join($resource/language/element(), '-')
let $isbn := $resource/identifier[@type = 'isbn'][1]/string(.)
let $doi := $resource/identifier[@type = 'doi'][1]/string(.)
let $shortTitle := $titleInfo/subTitle/string(.)

let $api-key := "MQGEe8SzWRCbPj8COl4VDlvP"
let $init-uri := xs:anyURI("https://api.zotero.org/groups/2023208/items?")
let $content :=
    [
      map {
        "itemType" : $resource/genre/text(),
        "title" : $title,
        "creators" : [
          map {
            "creatorType":"castMember",
            "firstName" : "Sam",
            "lastName" : "McAuthor"
          },
          map {
            "creatorType":"editor",
            "name" : "John T. Singlefield"
          }
        ],
        "language": $language,        
        "ISBN": $isbn,
        "DOI": $doi,
        "shortTitle": $shortTitle,
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
(:return $content:)
return util:base64-decode(httpclient:post(xs:anyURI($init-uri || "&amp;key=" || $api-key), $serialized-content, true(), ()))