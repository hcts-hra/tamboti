xquery version "3.1";

module namespace retrieve = "http://hra.uni-heidelberg.de/ns/tamboti/retrieve";

import module namespace config="http://exist-db.org/mods/config" at "../config.xqm";

import module namespace mods-hra-framework = "http://hra.uni-heidelberg.de/ns/mods-hra-framework" at "/db/apps/tamboti/frameworks/mods-hra/mods-hra.xqm";
import module namespace vra-hra-framework = "http://hra.uni-heidelberg.de/ns/vra-hra-framework" at "/db/apps/tamboti/frameworks/vra-hra/vra-hra.xqm";
import module namespace tei-hra-framework = "http://hra.uni-heidelberg.de/ns/tei-hra-framework" at "/db/apps/tamboti/frameworks/tei-hra/tei-hra.xqm";
import module namespace svg-hra-framework = "http://hra.uni-heidelberg.de/ns/svg-hra-framework" at "/db/apps/tamboti/frameworks/svg-hra/svg-hra.xqm";
import module namespace wiki-hra-framework = "http://hra.uni-heidelberg.de/ns/wiki-hra-framework" at "/db/apps/tamboti/frameworks/wiki-hra/wiki-hra.xqm";

import module namespace security = "http://exist-db.org/mods/security" at "security.xqm";
import module namespace clean = "http://exist-db.org/xquery/mods/cleanup" at "../../../modules/search/cleanup.xql";
import module namespace kwic = "http://exist-db.org/xquery/kwic" at "resource:org/exist/xquery/lib/kwic.xql";

import module namespace functx = "http://www.functx.com";

declare namespace mods = "http://www.loc.gov/mods/v3";
declare namespace vra = "http://www.vraweb.org/vracore4.htm";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace atom = "http://www.w3.org/2005/Atom";

declare variable $retrieve:USER := security:get-user-credential-from-session()[1];
declare variable $retrieve:USERPASS := security:get-user-credential-from-session()[2];

declare variable $retrieve:THUMB_SIZE_FOR_GRID := 64;
declare variable $retrieve:THUMB_SIZE_FOR_GALLERY := 128;
declare variable $retrieve:THUMB_SIZE_FOR_DETAIL_VIEW := 256;
declare variable $retrieve:THUMB_SIZE_FOR_LIST_VIEW := 128;

declare variable $retrieve:loading-image := $config:app-http-root || "/resources/images/ajax-loader.gif";

declare function retrieve:get-item-uri($item-id as xs:string) {
    fn:concat(
        request:get-scheme(),
        "://",
        request:get-server-name(),
        if((request:get-scheme() eq "http" and request:get-server-port() eq 80) or (request:get-scheme() eq "https" and request:get-server-port() eq 443))then "" else fn:concat(":", request:get-server-port()),
        
        fn:replace(request:get-uri(), "/exist/([^/]*)/([^/]*)/.*", "/exist/$1/$2"),
        
        (:fn:substring-before(request:get-url(), "/modules"), :)
        "/item/",
        $item-id
    )
};

declare function local:basic-get-http($uri,$username,$password) {
  let $credentials := concat($username,":",$password)
  let $credentials := util:string-to-binary($credentials)
  let $headers  := 
    <headers>
      <header name="Authorization" value="Basic {$credentials}"/>
    </headers>
  return httpclient:get(xs:anyURI($uri),false(), $headers)
};


(:This is the default which gets called if retrieve:list-view-table() does not know how to handle what is passed to it.:)
declare function retrieve:plain-list-view-table($item as node(), $currentPos as xs:int) {
    let $kwic := kwic:summarize($item, <config xmlns="" width="40"/>)
    let $id := concat(document-uri(root($item)), '#', util:node-id($item))
    let $stored := session:get-attribute("personal-list")
    let $saved := exists($stored//*[@id = $id])
    (:NB: This gives NEP 2013-03-16, but Wolfgang has a fix. :)
    let $titleField := ft:get-field($item/@uri, "Title")
    let $title := if ($titleField) then $titleField else replace($item/@uri, "^.*/([^/]+)$", "$1")
    let $clean := clean:cleanup($item)
    let $collection := util:collection-name($item)
    let $collection-short := functx:replace-first($collection, '/db/', '')
    return
        <tr xmlns="http://www.w3.org/1999/xhtml" class="pagination-item list">
            <td class="pagination-number">{$currentPos}</td>
            {
            <td class="actions-cell">
                <a id="save_{$id}" href="#{$currentPos}" class="save">
                    <img title="Save Record to My List" src="resources/images/{if ($saved) then 'disk_gew.gif' else 'disk.gif'}" class="{if ($saved) then 'stored' else ''}"/>
                </a>
            </td>
            }
            <td class="list-type">
                <a href="{substring($item/@uri, 2)}" target="_new">
                { mods-hra-framework:get-icon($retrieve:THUMB_SIZE_FOR_GALLERY, $item, $currentPos)}
                </a>
            </td>
            {
            <td class="pagination-toggle">
                <span>{
                        try {
                            mods-hra-framework:format-list-view(string($currentPos), $clean, $collection-short)
                        } catch * {
                            util:log("DEBUG", "Code: " || $err:code || "Descr.: " || $err:description || " Value: " || $err:value ),
                            <td class="error" colspan="2">
                                {$config:error-message-before-link} 
                                <a href="{$config:error-message-href}{$item/@ID/string()}.">{$config:error-message-link-text}</a>
                                {$config:error-message-after-link}
                                <p>Caught error {$err:code}: {$err:description}. {("(line ", $err:line-number, ", column ", $err:column-number, ")")}</p>
                                <p>Collection '{$collection-short}', record '{$item}'</p>
                            </td>
                        }
                }</span>
                <h4>{$title}</h4>
                { $kwic }
            </td>
            }
        </tr>
};

(:NB: If an element is returned which is not covered by this typeswitch, the following error occurs, i.e. it defaults to kwic:summarize():
the actual cardinality for parameter 1 does not match the cardinality declared in the function's signature: kwic:summarize($hit as element(), $config as element()) element()*. Expected cardinality: exactly one, got 0. [at line 349, column 34, source: /db/apps/tamboti/modules/session.xql]
:)
(:NB: each element checked for here should appear in retrieve:view-table(), otherwise the detail view will show the list view.:)
declare function retrieve:list-view-table($item as node(), $currentPos as xs:int) {
(:    let $useless := util:log("INFO", $item):)
(::)
(:    return:)
        if (namespace-uri($item/*[1]) = "http://www.w3.org/2000/svg")
        then svg-hra-framework:format-list-view($item, $currentPos)
        else
            typeswitch ($item)
                case element(mods:mods) return mods-hra-framework:list-view-table($item, $currentPos)
                case element(vra:vra) return vra-hra-framework:list-view-table($item, $currentPos)
                case element(tei:person) return tei-hra-framework:list-view-table($item, $currentPos)
                case element(tei:p) return tei-hra-framework:list-view-table($item, $currentPos)
                case element(tei:term) return tei-hra-framework:list-view-table($item, $currentPos)
                case element(tei:head) return tei-hra-framework:list-view-table($item, $currentPos)
                case element(tei:TEI) return tei-hra-framework:list-view-table($item, $currentPos)
                case element(tei:bibl) return tei-hra-framework:list-view-table($item, $currentPos)
                case element(tei:titleStmt) return tei-hra-framework:list-view-table($item, $currentPos)
                case element(atom:entry) return wiki-hra-framework:list-view-table($item, $currentPos)
                default return retrieve:plain-list-view-table($item, $currentPos)
};

declare function retrieve:view-table($cached as item()*, $stored as item()*, $start as xs:int, $count as xs:int, $available as xs:int, $total as xs:int) {
    <table xmlns="http://www.w3.org/1999/xhtml">
    {
        for $item at $pos in subsequence($cached, $start, $available)
        let $currentPos := $start + $pos - 1
        return
            if($count eq 1) then 
                if ($item instance of element(mods:mods)) then 
                    mods-hra-framework:detail-view-table($item, $currentPos)
                else if ($item instance of element(vra:vra)) then
                    vra-hra-framework:detail-view-table($item, $currentPos)
                else if ($item instance of element(tei:TEI)) then
                    tei-hra-framework:detail-view-table($item, $currentPos)
                else if ($item instance of element(tei:person)) then
                    tei-hra-framework:detail-view-table($item, $currentPos)
                else if ($item instance of element(tei:p)) then
                    tei-hra-framework:detail-view-table($item, $currentPos)
                else if ($item instance of element(tei:term)) then 
                    tei-hra-framework:detail-view-table($item, $currentPos)
                else if ($item instance of element(tei:head)) then
                    tei-hra-framework:detail-view-table($item, $currentPos)
                else if ($item instance of element(tei:bibl)) then
                    tei-hra-framework:detail-view-table($item, $currentPos) 
                else if ($item instance of element(atom:entry)) then
                    wiki-hra-framework:detail-view-table($item, $currentPos)
                else if (namespace-uri($item) = "http://www.w3.org/2000/svg") then 
                    svg-hra-framework:format-detail-view($item, $currentPos)
                else
                    ()
            else retrieve:list-view-table($item, $currentPos)
    }
    </table>
};

declare function retrieve:view-all($cached as item()*) {
    let $result := 
        for $resource in $cached
        return
            typeswitch ($resource)
                case element(mods:mods) return data($resource/@ID)
                case element(vra:vra) return data($resource/vra:work/@id)
                default return ()
    return
        (
            "{&quot;"
            ,
            string-join($result, "&quot;: 1, &quot;")
            ,
            "&quot;: 1}"
        )
};

(:~
    Main function: retrieves query results from session cache and
    checks which display mode to use.
:)

 declare function retrieve:get-resource($start as xs:int, $count as xs:int){
 
  let $resouce := session:get-attribute("tamboti:cache")
 
  return $resouce
 };
 
 
declare function retrieve:retrieve($start as xs:int, $count as xs:int) {
    let $mode := request:get-parameter("mode", "gallery")
    let $cached := session:get-attribute("tamboti:cache")
    let $stored := session:get-attribute("personal-list")    
    let $total := count($cached)
    let $available :=
        if ($start + $count gt $total)
        then $total - $start + 1
        else $count
    return
        (: A single entry is always shown in table view for now :)
        if ($mode eq "ajax" and $count eq 1) 
        then retrieve:view-table($cached, $stored, $start, $count, $available, $total)
        else
            switch ($mode)
(:                case "gallery" return:)
(:                    retrieve:view-gallery($mode, $cached, $stored, $start, $count, $available):)
(:                case "grid" return:)
(:                    retrieve:view-gallery($mode, $cached, $stored, $start, $count, $available):)
                case "multiple-selection" return
                    retrieve:view-all($cached)
                default return
                    retrieve:view-table($cached, $stored, $start, $count, $available, $total)
};
