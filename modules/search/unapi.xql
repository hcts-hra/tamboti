xquery version "3.0";

(:~
: Implementation of unAPI v1.0 - http://unapi.info/
:
: @author Adam Retter <adam@existsolutions.com>
:)

import module namespace config="http://exist-db.org/mods/config" at "../config.xqm";
import module namespace clean="http://exist-db.org/xquery/mods/cleanup" at "cleanup.xql";
import module namespace request = "http://exist-db.org/xquery/request";
import module namespace response = "http://exist-db.org/xquery/response";
import module namespace util = "http://exist-db.org/xquery/util";
import module namespace xmldb = "http://exist-db.org/xquery/xmldb";

declare namespace unapi = "http://unapi.info/";
declare namespace mods = "http://www.loc.gov/mods/v3";

declare variable $HTTP_NOT_MODIFIED := xs:int(304);
declare variable $HTTP_NOT_FOUND := xs:int(404);
declare variable $HTTP_NOT_ACCEPTABLE := xs:int(406);

declare option exist:serialize "omit-xml-declaration=no";

(:~
: Retrieves all formats for all objects
:)
declare function unapi:list-formats-for-all-objects() as element(formats) {
    <formats>
        <format name="mods" type="application/xml"/>
        <format name="web" type="text/html"/>
    </formats>
};

declare function unapi:extract-uuid-from-uri($uri as xs:string) as xs:string {
    fn:substring-after($uri, "/item/")
};

(:~
: Gets the format for a specific resource id
:)
declare function unapi:list-formats-for-id($id as xs:string) as element(formats) {
    <formats id="{$id}">
        <format name="web" type="text/html" />
        <format name="mods" type="application/xml"/>
    </formats>
};

(:~
: Gets a specific object identified by its $id, in the format identified by $format
:)
declare function unapi:get-object($id as xs:string, $format as xs:string, $resource as element(mods:mods)) as element()? {
    if($format eq "mods")then
    (
        response:set-header("Content-Type", "application/xml"),
        <modsCollection version="3.5" xmlns="http://www.loc.gov/mods/v3" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://cluster-schemas.uni-hd.de/modsCluster.xsd">
        {
            clean:cleanup($resource)
        }
        </modsCollection>
    )
    else if($format eq "web")then
    (
        response:set-header("Content-Type", "text/html"),
        util:declare-option("exist:serialize", "doctype-public=-//W3C//DTD&#160;XHTML&#160;1.1//EN doctype-system=http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd"),
        <html>
            <head>
                <title>{$id}</title>
            </head>
            <body>
                <p>{$resource//text()}</p>
            </body>
        </html>
    )
    else
        response:set-status-code($HTTP_NOT_ACCEPTABLE)
};

(:~
: Get a mods resource from the database
:)
declare function local:get-resource($id as xs:string) as element(mods:mods)? {
    fn:collection($config:mods-root)//mods:mods[@ID eq unapi:extract-uuid-from-uri($id)]
};

(:~
: Generates an Etag for a mods resource based on the format requested
:
: ETag format is SHA1 encoding of {$format}-{$id}-{$last-modified}
:)
declare function local:generate-etag-for-resource-format($id as xs:string, $format as xs:string, $resource as element(mods:mods)) as xs:string {
    let $resource-uri := fn:document-uri(fn:root($resource)),
    $last-modified := xmldb:last-modified(fn:replace($resource-uri, "(.*)/.*", "$1"), fn:replace(".*/", "", $resource-uri)) return
        util:hash(fn:concat($format, "-", $id, "-", $last-modified), "SHA1")
};


(: 
    Code below handles the QueryString requests for the unAPI
    
    It is slightly more complicated than it strictly needs to be,
    as we use the HTTP Etag header to control the caching of the
    results in an effort to reduce un-nessecary traffic for
    resources which have not changed.
:)

(: get the unAPI request parameters :)
let $id := request:get-parameter("id", ()),
$format := request:get-parameter("format", ()) return


if(empty($id) and empty($format))then
(
    (: get all formats of all objects :)
    if(request:get-header("If-None-Match") eq "all")then
        response:set-status-code($HTTP_NOT_MODIFIED)
    else
        unapi:list-formats-for-all-objects()
    ,
    response:set-header("Etag", "all")
)
else
    let $resource := local:get-resource($id) return
        if(empty($resource)) then
            (: the inicated resource does not exist :)
            response:set-status-code($HTTP_NOT_FOUND)
        else
            if(not(empty($id)) and not(empty($format)))then
            (
                (: get specific format of a specific resource :)
                let $etag := local:generate-etag-for-resource-format($id, $format, $resource) return
                (
                    if(request:get-header("If-None-Match") eq $etag)then
                        response:set-status-code($HTTP_NOT_MODIFIED)
                    else
                        unapi:get-object($id, $format, $resource),
                    response:set-header("Etag", $etag)
                )
            )
            else if(not(empty($id)))then
            (
                (: get the formats available for a specific resource :)
                let $etag := fn:concat("formats-", $id) return
                (
                    if(request:get-header("If-None-Match") eq $etag)then
                        response:set-status-code($HTTP_NOT_MODIFIED)
                    else
                        unapi:list-formats-for-id($id)
                    ,
                    response:set-header("Etag", $etag)
                )
            )
            else
                response:set-status-code($HTTP_NOT_FOUND)