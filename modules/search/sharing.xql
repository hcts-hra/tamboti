xquery version "3.0";

import module namespace json="http://www.json.org";
import module namespace request = "http://exist-db.org/xquery/request";
import module namespace util="http://exist-db.org/xquery/util";
import module namespace xmldb = "http://exist-db.org/xquery/xmldb";
import module namespace file="http://exist-db.org/xquery/file";

import module namespace config="http://exist-db.org/mods/config" at "../config.xqm";
import module namespace security="http://exist-db.org/mods/security" at "security.xqm";
import module namespace uu="http://exist-db.org/mods/uri-util" at "uri-util.xqm";

declare namespace vra="http://www.vraweb.org/vracore4.htm";
declare namespace mods="http://www.loc.gov/mods/v3";
declare namespace exist = "http://exist.sourceforge.net/NS/exist";

declare option exist:serialize "method=json media-type=text/javascript";

declare function local:get-sharing($collection-path as xs:anyURI) as element(aaData) {

    system:as-user($config:dba-credentials[1], $config:dba-credentials[2],
        let $acl := sm:get-permissions($collection-path)/sm:permission/sm:acl
        
        return
            if (xs:integer($acl/@entries) eq 0)
            then local:empty()
            else
                <aaData>{
                    for $ace at $index in $acl/sm:ace
                        let $target := $ace/@target
                        let $username := $ace/@who/string()
                        let $who :=
                            if ($target = 'USER') then
                                (system:as-user($config:dba-credentials[1],$config:dba-credentials[2], security:get-human-name-for-user($username)))
                            else 
                                ($ace/@who)
                        order by $username
                        return
                            element json:value {
                                if(xs:integer($acl/@entries) eq 1) then
                                    attribute json:array { true() }
                                else(),
                                <json:value>{text{$ace/@target}}</json:value>,
                                <json:value>{text{$who}}</json:value>,
                                <json:value>{text{$username}}</json:value>,
                                <json:value>{text{$ace/@access_type}}</json:value>,
                                <json:value>{text{$ace/@mode}}</json:value>,
                                <json:value>{$index - 1}</json:value>
                            }
                }</aaData>
    )
};

declare function local:get-folder-files ($upload-folder as xs:string ) {
let $json-true := attribute json:array { true() }
 return
    <aaData json:array="true">
        {system:as-user($config:dba-credentials[1],$config:dba-credentials[2],file:directory-list($upload-folder,'*.xml'))}
       </aaData>    
};


declare function local:list-collection-contents($collection as xs:string, $user as xs:string) {
    let $subcollections := 
        for $child in xmldb:get-child-collections($collection)
        where sm:has-access(xs:anyURI(concat($collection, "/", $child)), "r")
        return
            concat("/", $child)
    let $resources :=
        for $r in xmldb:get-child-resources($collection)
        where sm:has-access(xs:anyURI(concat($collection, "/", $r)), "r")
        return
            $r
    for $resource in ($subcollections, $resources)
	order by $resource ascending
	return
		$resource
};




declare function local:resources($collection as xs:string, $user as xs:string) {
    let $start := number(request:get-parameter("start", 0)) + 1
    let $endParam := number(request:get-parameter("end", 1000000)) + 1
    let $resources := local:list-collection-contents($collection, $user)
    let $count := count($resources) + 1
    let $end := if ($endParam gt $count) then $count else $endParam
    let $subset := subsequence($resources, $start, $end - $start + 1)
    let $parent := $start = 1 and $collection != "/db"
    return
    
         <aaData json:array="true">
            <total json:literal="true">{count($resources) + (if ($parent) then 1 else 0)}</total>
            <items>
            
            {
                for $resource in $subset
                let $isCollection := starts-with($resource, "/")
                let $path := 
                    if ($isCollection) then
                        concat($collection, $resource)
                    else
                        concat($collection, "/", $resource)
                where sm:has-access(xs:anyURI($path), "r")
                order by $resource ascending
                return
                    let $permissions := 
                        if ($isCollection) then
                            xmldb:permissions-to-string(xmldb:get-permissions($path))
                        else
                            xmldb:permissions-to-string(xmldb:get-permissions($collection, $resource))
                    let $owner := 
                        if ($isCollection) then
                            xmldb:get-owner($path)
                        else
                            xmldb:get-owner($collection, $resource)
                    let $group :=
                        if ($isCollection) then
                            xmldb:get-group($path)
                        else
                            xmldb:get-group($collection, $resource)
                    let $lastMod := 
                        let $date :=
                            if ($isCollection) then
                                xmldb:created($path)
                            else
                                xmldb:created($collection, $resource)
                        return
                            if (xs:date($date) = current-date()) then
                                format-dateTime($date, "Today [H00]:[m00]:[s00]")
                            else
                                format-dateTime($date, "[M00]/[D00]/[Y0000] [H00]:[m00]:[s00]")
                    let $canWrite :=
                            sm:has-access(xs:anyURI($collection || "/" || $resource), "w")
                    let $image_vra := collection($config:mods-root)//vra:image[@id=fn:tokenize($resource,'.xml')[1]]
                     return if (exists($image_vra))
                        then ( 
                        <json:value json:array="true">
                            <!--collection>{concat('../../../../rest/',util:collection-name($image_vra),'/', $image_vra/@href)}</collection-->
                            <collection>{$image_vra/@href}</collection>
                            <name>{
                            
                                if ($isCollection) then substring-after($resource, "/") 
                                else (
                                if (fn:contains($resource,'.xml'))
                                then
                                    let $image_vra := collection($config:mods-root)//vra:image[@id=fn:tokenize($resource,'.xml')[1]]
                                    return if (exists($image_vra))
                                    then 
                                    $image_vra//vra:title/text()
                                    else
                                    ('')
                                else ('')
                                
                               
                            )
                            }</name>
                            <permissions>{$permissions}</permissions>
                            <owner>{$owner}</owner>
                            <group>{$group}</group>
                            <lastmodified>{$lastMod}</lastmodified>
                            <writable json:literal="true">{$canWrite}</writable>
                            <isCollection json:literal="true">{$isCollection}</isCollection>
                        </json:value>
                        )
                        else()
            }
            </items>
        </aaData>
};



declare function local:get-attached-files ($file as xs:string ) {
 let $json :=attribute json:array { true() }       
let $mods-results :=  collection($config:mods-root)//mods:mods[@ID=$file]//mods:relatedItem
let $mods-entry :=
            if (exists($mods-results)) then
            (
            
            for $entry in $mods-results 
                let $image-is-preview := $entry/mods:typeOfResource eq 'still image' 
                let $image_vra := collection($config:mods-root)//vra:image[@id=data(data($entry/mods:location/mods:url))]
                return   
                      if ($image-is-preview) then 
                     let $modified := xmldb:last-modified(util:collection-name($image_vra), $image_vra/@href)
                     return
                 <json:value json:array="true">     
                <!--collection>{concat('../../../../rest',util:collection-name($image_vra),'/', $image_vra/@href)}</collection-->
                <collection>{$image_vra/@href}</collection>
                <name>{xmldb:decode(($image_vra//vra:title/text()))}</name>
                <lastmodified>{
                if (xs:date($modified) = current-date()) then
                    format-dateTime($modified, "Today [H00]:[m00]:[s00]")
                 else
                    format-dateTime($modified, "[M00]/[D00]/[Y0000] [H00]:[m00]:[s00]")
                
                }</lastmodified>
                </json:value>
                
                
                
                else()
                )
                else()
        
  let $vra-results :=  collection($config:mods-root)//vra:work[@id=$file]/vra:relationSet/vra:relation
  let $vra-entry :=
            if (exists($vra-results)) then
            (
            for $entry in $vra-results
                let $image_vra := collection($config:mods-root)//vra:image[@id=$entry/@relids]
                let $modified := xmldb:last-modified(util:collection-name($image_vra), $image_vra/@href)
                     return
                <json:value json:array="true">     
                <!--collection>{concat('../../../../rest',util:collection-name($image_vra),'/', $image_vra/@href)}</collection-->
                  <collection>{$image_vra/@href}</collection>
                <name>{xmldb:decode(($image_vra//vra:title/text()))}</name>
                <lastmodified>{
                if (xs:date($modified) = current-date()) then
                    format-dateTime($modified, "Today [H00]:[m00]:[s00]")
                 else
                    format-dateTime($modified, "[M00]/[D00]/[Y0000] [H00]:[m00]:[s00]")
                
                }</lastmodified>
                </json:value>
                
                )
                
                else()
            
  return      
  if (exists($vra-results)) then
             <aaData json:array="true"><items>{$vra-entry}</items></aaData>
  else  if (exists($mods-results)) then
         <aaData json:array="true"><items>{$mods-entry}</items></aaData>
  else (<aaData json:array="true"><items>{ $vra-results }</items></aaData>)      
        
             
};


declare function local:empty() {
    <aaData json:array="true"/>
};

 
 
<json:value>
    {
        if(request:get-parameter("collection",())) then
            local:get-sharing(xmldb:encode-uri(request:get-parameter("collection",())))
        else if(request:get-parameter("file",())) then
            local:get-attached-files(request:get-parameter("file",()))
        else if(request:get-parameter("upload-folder",())) then
            local:resources(request:get-parameter("upload-folder",()),security:get-user-credential-from-session()[1])
        else
            local:empty()
    }
</json:value>

