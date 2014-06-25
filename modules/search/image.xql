xquery version "3.0";
(:author  Dulip withanage:)
declare namespace vra="http://www.vraweb.org/vracore4.htm";
declare namespace upload = "http://exist-db.org/eXide/upload";
import module namespace util = "http://exist-db.org/xquery/util";

declare namespace mods="http://www.loc.gov/mods/v3";

import module namespace config="http://exist-db.org/mods/config" at "../../modules/config.xqm";
declare option exist:serialize "method=json media-type=text/javascript";
import module namespace json="http://www.json.org";

declare variable $col := $config:mods-root;
declare variable $user := $config:dba-credentials[1];
declare variable $userpass := $config:dba-credentials[2];
declare variable $rootdatacollection:='/db/resources/';


(:
let $results :=   collection($col)//vra:work[@id="w_186f5b16-e799-5bb5-b0c6-831575278973"]/vra:relationset/vra:relation
let $images := for $entry in $results
                    (:return <img src="{$entry/@relids}"/>:)
                    let $image := collection($col)//vra:image[@id=$entry/@relids]
                   return <img src="{concat(request:get-scheme(),'://',request:get-server-name(),':',request:get-server-port(),request:get-context-path(),'/rest', util:collection-name($image),"/" ,$image/@href)}" />
     
     
let $result_set := if (not($results)) then <xml>image uuid not found</xml> else ($results)


:)
 (:
    let $mods := collection($rootdatacollection)//mods:mods[@ID=$uuid]/@ID
    
    let $mods_col := if (exists($mods))
    then  util:collection-name($mods)
    else (
        let $vra_work := collection($rootdatacollection)//vra:work[@id=$uuid]/@id
        let $col := if (exists($vra_work))
        then 
          util:collection-name($vra_work)
            else()
          return $col
     )
    return $mods_col
     :)
 
 declare function upload:get-collection($uuid){
    system:as-user($user, $userpass, (
    let $vra_image := collection($rootdatacollection)//vra:image[@id=$uuid]
    let $col := if (exists($vra_image))
    then 
    util:collection-name($vra_image/@id)
    else()
    return <json:value>
                <collection>{$col}</collection>
                <filename>{data($vra_image/@href)}</filename>
            </json:value>
            )
     )
            
}; 
(:
let $x := system:as-user($user, $userpass,xmldb:reindex($rootdatacollection))
:)

let $uuid := request:get-parameter('uuid',())
let $results := upload:get-collection($uuid)
return   $results
