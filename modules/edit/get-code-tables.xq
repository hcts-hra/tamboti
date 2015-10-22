xquery version "3.0";

import module namespace config = "http://exist-db.org/mods/config" at "../config.xqm";
import module namespace request = "http://exist-db.org/xquery/request";
import module namespace xmldb = "http://exist-db.org/xquery/xmldb";

declare namespace xf = "http://www.w3.org/2002/xforms";
declare namespace mods-editor = "http://hra.uni-heidelberg.de/ns/mods-editor/";
declare option exist:serialize "method=xml media-type=text/xml indent=yes";

(: get-code-tables.xq
   This module will load all the code tables for a specific tab of a large multi-part form.
   Created for the MODS form.
   
   Input parameter: the list of needed code table id-s
   Output: a list of all the code tables used by the tab in XML
   
   Author: Dan McCreary
   Date: Aug. 2010

   Revised: Jens Petersen
   Date: Aug. 2012
   
   Refactored: Claudius Teodorescu
   Date: October 2015
:)

(:~
: Gets the most recent modified time for a number of resources in the same collection
:
: @param collection-path The collection of the resources
: @param resources-name The filenames of the resources in the $collection-path to examine
:
: @return The most recently modified date of all the resources
:)
declare function local:get-last-modified($collection-path as xs:string, $resource-names as xs:string+) as xs:dateTime {
    fn:max(
        for $resource-name in $resource-names
        return xmldb:last-modified($collection-path, $resource-name)
    )
};

let $code-table-ids := request:get-parameter('code-table-ids', '')
let $code-table-ids := tokenize($code-table-ids, ',')

let $code-table-collection := concat($config:edit-app-root, '/code-tables/')
let $code-tables :=
    for $code-table-id in $code-table-ids
    return collection($code-table-collection)/mods-editor:code-table[@xml:id = $code-table-id]

(: generate etag :)
let $last-modified := local:get-last-modified($code-table-collection,
    for $code-table-id in $code-table-ids
    return concat($code-table-id, '.xml')
)

(:NB: hint.xml is not covered by etag.:)
let $etag := $last-modified

return
    (
        (: set some caching http headers :)
        response:set-header("Etag", $last-modified),
        response:set-header("Last-Modified", $last-modified),
    
        (: have we previously made the same request for the same un-modified code-tables? :)
        if (request:get-header("If-None-Match") eq $etag)
            then
                (
                    (: yes, so send not modified :)
                    response:set-status-code(304)
                )
            else
                (
                    (: no, so process the request:)
                    <code-tables xmlns="http://hra.uni-heidelberg.de/ns/mods-editor/">
                        {
                            $code-tables
                        }
                    </code-tables>
                )
    )
(:
   Before Etag support was implemented, fastest response was 35ms
   After ETag support was implemented, fastest response is 39ms, however when Etag is used, response is just 14ms :-)
:)
