xquery version "3.0";

module namespace mods-hra-framework = "http://hra.uni-heidelberg.de/ns/mods-hra-framework";

import module namespace config = "http://exist-db.org/mods/config" at "../../modules/config.xqm";
import module namespace security = "http://exist-db.org/mods/security" at "../../modules/search/security.xqm";

declare namespace mods = "http://www.loc.gov/mods/v3";

declare function mods-hra-framework:move-resource($resource-id as xs:string, $destination-collection as xs:string) as element(status) {
    
    let $resource := collection($config:mods-root-minus-temp)//mods:mods[@ID eq $resource-id][1]
    let $resource-name := $resource-id || ".xml"    
    let $resource-collection := substring-before(base-uri($resource), $resource-name)
    let $destination-path := $destination-collection || "/" || $resource-name
    let $move-record :=
        (
            xmldb:move($resource-collection, $destination-collection, $resource-name),
            security:apply-parent-collection-permissions($destination-path)
        )
        
    return <status moved="{$resource-name}" from="{$resource-collection}" to="{$destination-collection}" />
    
};