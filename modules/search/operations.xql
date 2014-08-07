xquery version "3.0";

import module namespace security="http://exist-db.org/mods/security" at "security.xqm";
import module namespace sharing="http://exist-db.org/mods/sharing" at "sharing.xqm";
import module namespace config="http://exist-db.org/mods/config" at "../config.xqm";
import module namespace uu="http://exist-db.org/mods/uri-util" at "uri-util.xqm";

declare namespace group = "http://commons/sharing/group";
declare namespace op="http://exist-db.org/xquery/biblio/operations";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace response="http://exist-db.org/xquery/response";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace xmldb="http://exist-db.org/xquery/xmldb";

declare namespace mods="http://www.loc.gov/mods/v3";
declare namespace vra="http://www.vraweb.org/vracore4.htm";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace functx = "http://www.functx.com"; 

declare variable $HTTP-FORBIDDEN := 403;

declare function functx:substring-after-last-match 
  ( $arg as xs:string? ,
    $regex as xs:string )  as xs:string? {
       
   replace($arg,concat('^(.*)',$regex,'.*'),'$1')
 } ;
 
declare function functx:substring-after-last 
  ( $arg as xs:string? ,
    $delim as xs:string )  as xs:string {
       
   replace ($arg,concat('^.*',functx:escape-for-regex($delim)),'')
 } ;
 
declare function functx:escape-for-regex 
  ( $arg as xs:string? )  as xs:string {
       
   replace($arg,
           '(\.|\[|\]|\\|\||\-|\^|\$|\?|\*|\+|\{|\}|\(|\))','\\$1')
 } ;

(:~
: Creates a collection inside a parent collection
:
: The new collection inherits the owner, group and permissions of the parent
:
: @param $parent the parent collection container
: @param $name the name for the new collection
:)
declare function op:create-collection($parent as xs:string, $name as xs:string) as element(status) {
    let $parent-collection-owner := xmldb:get-owner($parent)
    let $parent-collection-group := xmldb:get-group($parent)

    let $create-collection :=
        system:as-user(security:get-user-credential-from-session()[1], security:get-user-credential-from-session()[2],
    
                let $collection := xmldb:create-collection($parent, $name)
                (:let $collection := xmldb:create-collection($parent, uu:escape-collection-path($name)):)
                (:escaped:)
                
                (: inherit ACE from parent collection to new collection:)
                let $inherit-ACE := security:duplicate-acl($parent, $parent || "/" || $name)
        
                (: just the owner has full access - to start with :)
                let $null := sm:chmod(xs:anyURI($collection), "rwxr-xr-x")
    
                (: to be sure that the collection owner's group is the intended one :)
                let $change-group := sm:chgrp(xs:anyURI($collection), $parent-collection-group)
                return ()
        )
    let $change-owner :=
        system:as-user($config:dba-credentials[1], $config:dba-credentials[2], 
                (: set parent collection owner as owner for new collection :)
                sm:chown(xs:anyURI($parent || "/" || $name), $parent-collection-owner)
        )
    return
(:<status id="created">{uu:unescape-collection-path($collection)}</status>:)
        <status id="created">{xmldb:decode-uri(xs:anyURI($parent || "/" || $name))}</status>

};

declare function op:move-collection($collection as xs:string, $to-collection as xs:string) as element(status) {
    (:let $to-collection := uu:escape-collection-path($to-collection) return
    let $null := xmldb:move($collection, $to-collection):)
    let $collection := xmldb:encode-uri($collection)
    let $to-collection := xmldb:encode-uri($to-collection)

    return
        let $null := xmldb:move($collection, $to-collection) return
        
            (:
            if this collection was created
            inside a different users collection,
            allow the owner of the parent collection access 
            :)
            let $null := security:grant-parent-owner-access-if-foreign-collection($to-collection) return
        
                (:<status id="moved" from="{uu:unescape-collection-path($collection)}">{$to-collection}</status>:)
                <status id="moved" from="{xmldb:decode-uri($collection)}">{xmldb:decode-uri($to-collection)}</status>
};

declare function op:rename-collection($path as xs:string, $name as xs:string) as element(status) {
    system:as-user(security:get-user-credential-from-session()[1], security:get-user-credential-from-session()[2],
        let $null := xmldb:rename($path, $name)
        return
            (:<status id="renamed" from="{uu:unescape-collection-path($path)}">{$name}</status>:)
            <status id="renamed" from="{xmldb:decode-uri($path)}">{xmldb:decode-uri($name)}</status>
    )
};

declare function op:remove-collection($collection as xs:string) as element(status) {
    (:Only allow deletion of a collection if none of the records in it are referred to in xlinks outside the collection itself.:)
    (:Get the ids of the records in the collection that the user wants to delete.:)
    let $collection := xmldb:encode-uri($collection)
    (:escaped:)
    let $collection-ids := collection($collection)//@ID
    (:Get the ids of the records that are linked to the records in the collection that the user wants to delete.:)
    let $xlinked-rec-ids :=
        string-join(
        for $collection-id in $collection-ids
            let $xlink := concat('#', $collection-id)
            let $xlink-recs := collection($config:mods-root-minus-temp)//mods:relatedItem[@xlink:href eq $xlink]/ancestor::mods:mods/@ID
            return
                (:It is OK to delete a record using an ID as an xlink if the record is inside the folder to be deleted.:)
                if (not($xlink-recs = $collection-ids))
                then $xlink-recs
                else ''
                (:This should return '' for each iteration for deletion to proceed.:)
                ,'')
    let $null := 
         (:If $xlinked-rec-ids is not empty, do not delete.:)
         if ($xlinked-rec-ids)
         then ()
         (:else xmldb:remove($collection):)
         else system:as-user(security:get-user-credential-from-session()[1], security:get-user-credential-from-session()[2], xmldb:remove(xmldb:decode-uri($collection))) 
             return
                (:<status id="removed">{uu:unescape-collection-path($collection)}</status>:)
                <status id="removed">{xmldb:decode-uri($collection)}</status>
};

(:~
:
: @resource-id is the uuid of the MODS or VRA record
:)
declare function op:remove-resource($resource-id as xs:string) as element(status)* {
    let $mods-doc := collection($config:mods-root-minus-temp)//mods:mods[@ID eq $resource-id]
    let $xlink := concat('#', $resource-id)
    (:since xlinks are also inserted manually, check also for cases when the pound sign has been forgotten:)
    let $mods-xlink-recs := collection($config:mods-root-minus-temp)//mods:relatedItem[@xlink:href = ($xlink, $resource-id)]
    (:let $base-uri := concat(util:collection-name($doc), '/', util:document-name($doc)):)
    (:NB: we assume that @relids (plural) can hold several values:)
    
    let $vra-work := collection($config:mods-root-minus-temp)//vra:vra/vra:work[@id eq $resource-id]
    let $vra-images := collection($config:mods-root-minus-temp)//vra:vra[vra:image/vra:relationSet/vra:relation[contains(@relids, $resource-id)]]
    (:NB: we assume that all image files are in the same collection as their metadata and that all image records belonging to a work record are in the same collection:)
    let $vra-image-collection := util:collection-name($vra-images[1])
    let $vra-binary-names := $vra-images/vra:image/@href    
    let $vra-docs := ($vra-work, $vra-images)
    
    let $docs := if ($mods-doc) then $mods-doc else $vra-docs 
    
    for $doc in $docs return
(:    
    let $location := util:collection-name($doc)
    let $name := util:document-name($doc)
    let $last-modified := xmldb:last-modified($location, $name)
    let $created := xmldb:created($location, $name)
    let $size := xmldb:size($location, $name)
    let $owner := xmldb:get-owner($location, $name)
    let $group := xmldb:get-group($location, $name)
    let $time := current-dateTime()
    let $user := request:get-parameter("username",())
    let $record :=
    <record>
        <name>{$name}</name>
        <location>{$location}</location>
        <created>{$created}</created>
        <last-modified>{$last-modified}</last-modified>
        <size>{$size}</size>
        <owner>{$owner}</owner>
        <group>{$group}</group>
        <deletion-time>{$time}</deletion-time>
        <deleting-user>{$user}</deleting-user>
    </record>

    return
:) 
    (
        (:do not remove records which erroneously have the same ID:)
        (:NB: inform user that this is the case:)
        if (count($doc) eq 1)
        then
            (:do not remove records which are linked to from other records:)
            (:NB: inform user that this is the case:)
            if (count($mods-xlink-recs/..) eq 0) 
            then
                    system:as-user(security:get-user-credential-from-session()[1], security:get-user-credential-from-session()[2], xmldb:remove(util:collection-name($doc), util:document-name($doc)))
            else ()
        else()
        (:
        ,
        update insert $record into doc('/db/resources/temp/deletions.xml')/records
        :)
        ,
        if (count($vra-binary-names) gt 0) then
            for $vra-binary-name in $vra-binary-names
                return
                    (:NB: since this iterates inside another iteration, files are attempted deleted which have been deleted already, causing the script to halt. However,:)
                    (:the existence of the file to be deleted should first be checked, in order to prevent the function from halting in case the file does not exist.:)
                    if (util:binary-doc-available(concat($vra-image-collection, '/', $vra-binary-name))) then
                    system:as-user(security:get-user-credential-from-session()[1], security:get-user-credential-from-session()[2], xmldb:remove($vra-image-collection, $vra-binary-name))
                    else ()
        else ()
        ,
        <status id="removed">{$resource-id}</status>
    )
};



(:~
:
: @ resource-id has the format db-document-path#node-id e.g. /db/mods/eXist/exist-articles.xml#1.36
:)
declare function op:move-resource($resource-id as xs:string, $destination-collection as xs:string) as element(status) {
    let $destination-collection := uu:escape-collection-path($destination-collection) return
        let $path := substring-before($resource-id, "#")
        let $id := substring-after($resource-id, "#")
        let $destination-resource-name := replace($path, ".*/", "")
        let $destination-path := concat($destination-collection, "/", $destination-resource-name)
        let $sourceDoc := doc($path)
        return
            if (contains($id, ".")) then
                let $resource := util:node-by-id($sourceDoc, $id)
                let $mods-destination := 
                    if(doc-available($destination-path))then
                        doc($destination-path)/mods:modsCollection
                    else
                        let $mods-collection-doc-path := xmldb:store($destination-collection, $destination-resource-name, <modsCollection xmlns="http://www.loc.gov/mods/v3" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.loc.gov/mods/v3 ../../webapp/WEB-INF/entities/mods-3-3.xsd"/>) return
                            let $null := security:apply-parent-collection-permissions($mods-collection-doc-path) return
                                doc($mods-collection-doc-path)/mods:modsCollection
                return
                (
                    update insert util:node-by-id(doc($path), $id) into $mods-destination,
                    update delete util:node-by-id(doc($path), $id),
                    
                    <status id="moved" from="{$resource-id}">{$destination-path}</status>
                )
            else
                let $moved := xmldb:move(util:collection-name($sourceDoc), $destination-collection, util:document-name($sourceDoc)) return
                    let $null := security:apply-parent-collection-permissions(fn:document-uri(fn:root($sourceDoc))) return
                
                        <status id="moved" from="{$resource-id}">{$destination-path}</status>
};

declare function op:set-ace-writeable($collection as xs:anyURI, $id as xs:int, $is-writeable as xs:boolean) as element(status) {
    let $collection-result := sharing:set-collection-ace-writeable($collection, $id, $is-writeable)
    let $vra-images-result := 
        if(xmldb:collection-available(xs:anyURI($collection || "/VRA_images"))) then
            sharing:set-collection-ace-writeable(xs:anyURI($collection || "/VRA_images"), $id, $is-writeable)
        else
            ()
    return
        if(exists($collection-result)) then
            <status id="ace">updated</status>
        else
            (
                response:set-status-code($HTTP-FORBIDDEN),
                <status id="ace">Permission Denied</status>
            )
};

 
(:~
 : toggles the ACE writable bit by target (USER/GROUP) and name
 : @param $collection the collection to remove ACE from
 : @param $target USER or GROUP
 : @param $name User- or groupname
 : @param $is-writeable writeable or not
 :)

declare function op:set-ace-writeable-by-name($collection as xs:anyURI, $target as xs:string, $name as xs:string, $is-writeable as xs:boolean) as element(status) {
    let $collection-result := sharing:set-collection-ace-writeable-by-name($collection, $target, $name, $is-writeable)
    let $vra-images-result := 
        if(xmldb:collection-available(xs:anyURI($collection || "/VRA_images"))) then
            sharing:set-collection-ace-writeable-by-name(xs:anyURI($collection || "/VRA_images"), $target, $name, $is-writeable)
        else
            ()
    return
        if(exists($collection-result)) then
            <status id="ace">updated</status>
        else
            (
                response:set-status-code($HTTP-FORBIDDEN),
                <status id="ace">Permission Denied</status>
            )
};


declare function op:remove-ace($collection as xs:anyURI, $id as xs:int) as element(status) {
    let $parent-collection-result := sharing:remove-collection-ace($collection, $id)
    let $vra-images-result := 
        if(xmldb:collection-available(xs:anyURI($collection || "/VRA_images"))) then
            sharing:remove-collection-ace(xs:anyURI($collection || "/VRA_images"), $id)
        else
            true()
    return
        if(exists($parent-collection-result) and exists($vra-images-result)) then
            <status id="ace">removed</status>
        else(
            response:set-status-code($HTTP-FORBIDDEN),
            <status id="ace">Permission Denied</status>
            )
      
};

(:~
 : removes ACE by target (USER/GROUP) and name
 : @param $collection the collection to remove ACE from
 : @param $target USER or GROUP
 : @param $name User- or groupname
 :)
declare function op:remove-ace-by-name($collection as xs:anyURI, $target as xs:string, $name as xs:string) as element(status) {
    let $parent-collection-result := sharing:remove-collection-ace-by-name($collection, $target, $name)
    let $vra-images-result := 
        if(xmldb:collection-available(xs:anyURI($collection || "/VRA_images"))) then
            sharing:remove-collection-ace-by-name(xs:anyURI($collection || "/VRA_images"), $target, $name)
        else
            true()
    return
        if(exists($parent-collection-result) and exists($vra-images-result)) then
            <status id="ace">removed</status>
        else
            (
                response:set-status-code($HTTP-FORBIDDEN),
                <status id="ace">Permission denied</status>
            )

};

declare function op:add-user-ace($collection as xs:anyURI, $username as xs:string) as element(status) {
    let $ace-id := sharing:add-collection-user-ace($collection, $username)
    let $vra-images-result := 
        if(xmldb:collection-available(xs:anyURI($collection || "/VRA_images"))) then
            sharing:add-collection-user-ace(xs:anyURI($collection || "/VRA_images"), $username)
        else
            ()
    return
        if ($ace-id != -1) then
            <status ace-id="{$ace-id}">added</status>
        else
            ( 
                response:set-status-code($HTTP-FORBIDDEN),
                <status ace-id="{$ace-id}">Permission Denied</status>
            )
};

declare function op:add-group-ace($collection as xs:anyURI, $groupname as xs:string) as element(status) {
    
    let $ace-id := sharing:add-collection-group-ace($collection, $groupname)    
    let $vra-images-result := 
        if(xmldb:collection-available(xs:anyURI($collection || "/VRA_images"))) then
            sharing:add-collection-group-ace(xs:anyURI($collection || "/VRA_images"), $groupname)
        else
            ()
    
    return
        if ($ace-id != -1)
            then <status ace-id="{$ace-id}">added</status>
        else
            ( 
                response:set-status-code($HTTP-FORBIDDEN),
                <status ace-id="{$ace-id}">Permission Denied</status>
            ) 
};

declare function op:is-valid-user-for-share($username as xs:string) as element(status) {
    if (sharing:is-valid-user-for-share($username))
    then <status id="user">valid</status>
    else
        (
            response:set-status-code($HTTP-FORBIDDEN),
            <status id="user">invalid</status>
        )
};

declare function op:get-child-collection-paths($start-collection as xs:anyURI) {
    for $child-collection in xmldb:get-child-collections($start-collection)
        return
            (concat($start-collection, '/', $child-collection), 
            op:get-child-collection-paths(concat($start-collection, '/', $child-collection) cast as xs:anyURI))
};

declare function op:get-move-folder-list($chosen-collection as xs:anyURI) as element(select) {
    <select>{
        (:the user can move records to their home folder and to folders that are shared with the user:)
        let $available-collection-paths := (security:get-home-collection-uri(security:get-user-credential-from-session()[1]))
        let $move-folder-list :=
        for $available-collection-path in $available-collection-paths 
            return (op:get-child-collection-paths($available-collection-path),
            sharing:get-shared-collection-roots(true()))
            for $path in distinct-values($move-folder-list)
            (:let $log := util:log("DEBUG", ("##$path): ", $path)):)
            (:let $log := util:log("DEBUG", ("##$chosen-collection): ", $chosen-collection)):)
            (:let $log := util:log("DEBUG", ("##$starts-with): ", starts-with($path, $chosen-collection))):)
            (:let $log := util:log("DEBUG", ("##$home): ", security:get-home-collection-uri(security:get-user-credential-from-session()[1]))):)
            (:let $log := util:log("DEBUG", ("##$shared): ", sharing:get-shared-collection-roots(true()))):)

                let $display-path := substring-after($path, '/db/')
                let $user := xmldb:get-current-user()
                let $display-path := replace($path, concat('users/', $user), 'Home')
                order by $display-path
            return
            (:leave out the folder that the user has marked, since you cannot move something to itself:)
            (:leave out descendant folders, since you cannot move a folders into a descendant:)
                (:if (contains($path, $chosen-collection) or contains($chosen-collection, $path)):)
                if ($path eq $chosen-collection)
                then () 
                else
                    (
                        <option value="{xmldb:decode-uri($path)}">{xmldb:decode-uri($display-path)}</option>
                    )
    }</select>
};

declare function op:get-move-resource-list($collection as xs:anyURI) as element(select) {
    op:get-move-folder-list($collection)
};

declare function op:is-valid-group-for-share($groupname as xs:string) as element(status) {
    if(sharing:is-valid-group-for-share($groupname))then
        <status id="group">valid</status>
    else(
        response:set-status-code($HTTP-FORBIDDEN),
        <status id="group">invalid</status>
    )
};

declare function op:unknown-action($action as xs:string) {
        response:set-status-code($HTTP-FORBIDDEN),
        <p>Unknown action: {$action}.</p>
};


declare function op:upload($collection, $path, $data) {
    let $upload := 
        (: authenticate as the user account set in the app's repo.xml, since we need write permissions to
         : upload the file.  then set the uploaded file's permissions to allow guest/world to delete the file 
         : for the purposes of the demo :)
        system:as-user('admin', '', 
            (
            let $mkdir := if (xmldb:collection-available($collection)) then() else ()
            let $upload := xmldb:store($collection, $path, $data)
            let $chmod := sm:chmod(xs:anyURI($upload), 'o+rw')
            return ()
            )
        )
    return ()
 };
 
 
 
    
declare function op:upload-file($name, $data ,$collection) {
 op:upload(xmldb:encode-uri($collection), xmldb:encode-uri($name), $data)
  
};

(:let $action := request:get-parameter("action", ()),
$collection := uu:escape-collection-path(request:get-parameter("collection", ())):)
let $action := request:get-parameter("action", ())
let $collection := request:get-parameter("collection", ())
let $collection := if($collection)then xmldb:decode(xmldb:encode-uri($collection)) else ()

return
    if($action eq "create-collection")then
        op:create-collection($collection, request:get-parameter("name",()))
    else if($action eq "move-collection")then
        (:op:move-collection($collection, request:get-parameter("path",())):)
        op:move-collection(xmldb:decode-uri($collection), request:get-parameter("path",()))
    else if($action eq "rename-collection")then
        op:rename-collection($collection, request:get-parameter("name",()))
    else if($action eq "remove-collection")then
        op:remove-collection($collection)
    else if($action eq "remove-resource")then
        op:remove-resource(request:get-parameter("resource",()))
    else if($action eq "move-resource")then
        op:move-resource(request:get-parameter("resource",()), request:get-parameter("path",()))
    else if($action eq "set-ace-writeable")then
        op:set-ace-writeable(xs:anyURI($collection), xs:int(request:get-parameter("id",())), xs:boolean(request:get-parameter("is-writeable", false())))
    else if($action eq "set-ace-writeable-by-name")then
        op:set-ace-writeable-by-name(xs:anyURI($collection), xs:string(request:get-parameter("target",())), xs:string(request:get-parameter("name",())), xs:boolean(request:get-parameter("is-writeable", false())))
    else if($action eq "remove-ace")then
        op:remove-ace(xs:anyURI($collection), xs:int(request:get-parameter("id",())))
    else if($action eq "remove-ace-by-name")then
        op:remove-ace-by-name(xs:anyURI($collection), xs:string(request:get-parameter("target", ())) , xs:string(request:get-parameter("name", ())))
    else if($action eq "add-user-ace")then
        op:add-user-ace(xs:anyURI($collection), request:get-parameter("username",()))
    else if($action eq "is-valid-user-for-share")then
        op:is-valid-user-for-share(request:get-parameter("username",()))
    else if($action eq "add-group-ace")then
        op:add-group-ace(xs:anyURI($collection), request:get-parameter("groupname",()))
    else if($action eq "is-valid-group-for-share")then
        op:is-valid-group-for-share(request:get-parameter("groupname",()))
    else if($action eq "get-move-folder-list")then
        op:get-move-folder-list($collection)
     else if($action eq "get-move-resource-list")then
        op:get-move-resource-list($collection)
     else if($action eq "upload-file") then
        let $name := request:get-uploaded-file-name('files[]')
        let $data := request:get-uploaded-file-data('files[]')
        return
         op:upload-file($name,$data,$collection)
        
     else
        op:unknown-action($action)
