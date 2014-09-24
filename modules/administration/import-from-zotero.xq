xquery version "3.0";

declare namespace zapi="http://zotero.org/ns/api";
declare namespace atom="http://www.w3.org/2005/Atom";
declare default element namespace "http://www.loc.gov/mods/v3";

import module namespace functx="http://www.functx.com";
import module namespace security="http://exist-db.org/mods/security" at "../search/security.xqm";

(: Where to store the imported MODS files? :)
let $target-collection := "/resources/users/editor/import-folder"

(: The collection to import (open example: https://api.zotero.org/users/475425/collections/9KH9TNSJ ):)
let $collections-uri := xs:anyURI("https://api.zotero.org/users/475425/collections/9KH9TNSJ")
(: $api-key: API key created https://www.zotero.org/settings/keys/new:)
let $api-key := "" 

(: First amount of items in collection :)
let $amount := data(httpclient:get(xs:anyURI($collections-uri || "?key=" || $api-key), true(), ())/httpclient:body//atom:entry//zapi:numItems)

(: now get all:)
let $limit := 100
let $runs := xs:integer(ceiling($amount div $limit))

return 
    (
        <runs>
            {
                for $run in 0 to $runs
                    return
                        <run>
                            {
                                let $this-start := $run * $limit
                                let $this-limit := ($run + 1) * $limit
                                let $call := xs:anyURI($collections-uri || "/items?format=atom&amp;content=mods&amp;start=" || $this-start || "&amp;limit=" || $this-limit || "&amp;key=" || $api-key)
                                let $response := httpclient:get($call, true(), ())//httpclient:body
                                return
                                    (
                                        <call>
                                            {$call}
                                        </call>
                                        ,
                                        for $entry in $response/atom:feed/atom:entry
                                            let $zotero-id := data($entry/atom:id)
                                            let $uuid := "uuid-" || util:uuid($zotero-id)
                                            let $filename := $uuid || ".xml"
                                            let $mods-cleanedup := functx:change-element-ns-deep($entry//mods, "http://www.loc.gov/mods/v3", "")
                                            let $doc-uri := xmldb:store($target-collection, $filename, $mods-cleanedup)
                                            let $doc :=doc($doc-uri) 
                                            let $update-id-attribute := update insert attribute ID{$uuid} into $doc/mods
                                            (: copyrightDate-Fix for cluster publications:)
                                            (: let $update-copyright-date := update rename $doc//copyrightDate as 'dateIssued' :)
                                            let $insert-zotero-id :=
                                                if(exists($doc//mods/recordInfo)) then
                                                    update insert 
                                                            <recordContentSource>
                                                                {$zotero-id}
                                                            </recordContentSource>
                                                    into $doc//mods/recordInfo
                                                else 
                                                    update insert 
                                                        <recordInfo>
                                                            <recordContentSource>
                                                                {$zotero-id}
                                                            </recordContentSource>
                                                        </recordInfo>
                                                    into $doc//mods
                                            return
                                                <document>{$doc-uri}</document>
                                    )
                            }
                        </run>
            }
        </runs>,
        <setPermissions>
            {
               security:recursively-inherit-collection-acl($target-collection),
               security:recursively-set-owner-and-group($target-collection, xmldb:get-owner($target-collection), xmldb:get-group($target-collection))
            }
        </setPermissions>
    )