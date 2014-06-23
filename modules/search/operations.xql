xquery version "3.0";

import module namespace security="http://exist-db.org/mods/security" at "security.xqm";
import module namespace sharing="http://exist-db.org/mods/sharing" at "sharing.xqm";
import module namespace config="http://exist-db.org/mods/config" at "../config.xqm";
import module namespace vra-hra-framework = "http://hra.uni-heidelberg.de/ns/vra-hra-framework" at "../../frameworks/vra-hra/vra-hra.xqm";
import module namespace mods-hra-framework = "http://hra.uni-heidelberg.de/ns/mods-hra-framework" at "../../frameworks/mods-hra/mods-hra.xqm";

declare namespace group = "http://commons/sharing/group";
declare namespace op="http://exist-db.org/xquery/biblio/operations";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace response="http://exist-db.org/xquery/response";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace xmldb="http://exist-db.org/xquery/xmldb";

declare namespace mods="http://www.loc.gov/mods/v3";
declare namespace vra="http://www.vraweb.org/vracore4.htm";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace functx="http://www.functx.com"; 

declare variable $HTTP-FORBIDDEN := 403;

declare function functx:substring-before-last
  ( $arg as xs:string? ,
    $delim as xs:string )  as xs:string {

   if (matches($arg, functx:escape-for-regex($delim)))
   then replace($arg,
            concat('^(.*)', functx:escape-for-regex($delim),'.*'),
            '$1')
   else ''
 } ;
 
declare function functx:escape-for-regex 
  ( $arg as xs:string? )  as xs:string {
       
   replace($arg,
           '(\.|\[|\]|\\|\||\-|\^|\$|\?|\*|\+|\{|\}|\(|\))','\\$1')
 } ;

(:TODO: if collection names use higher Unicode characters, 
the buttons do not show up (except Delete Folder).:)

(:~
: Creates a collection inside a parent collection
:
: The new collection inherits the owner, group and permissions of the parent
:
: @param $parent-collection-uri the parent collection uri
: @param $new-collection-name the name for the new collection
:)
(:NB: creation does not take place if the new name is already taken.:)
(:TODO: notify user if the new name is already taken.:)
declare function op:create-collection($parent-collection-uri as xs:string, $new-collection-name as xs:string) as element(status) {
    system:as-user(security:get-user-credential-from-session()[1], security:get-user-credential-from-session()[2],
        let $new-collection :=  xmldb:create-collection($parent-collection-uri, $new-collection-name)
        (:just the owner has write access to start with:)
        let $null := sm:chmod(xs:anyURI($new-collection), "rwxr-xr-x")
        (:if this collection was created inside a different user's collection,
        allow the owner of the parent collection access:)
        let $null := security:grant-parent-owner-access-if-foreign-collection($new-collection)
        (: to be sure that the collection owner's group is the intended one :)
        let $change-group := sm:chgrp(xs:anyURI($new-collection), $config:biblio-users-group)         

        return
            <status id="created">{$new-collection}</status>    
    )
};

(:TODO: Perform search for contents of collection after it has been moved.:)
declare function op:move-collection($collection-to-move as xs:string, $new-parent-collection as xs:string) as element(status) {
    
    let $null := xmldb:move($collection-to-move, $new-parent-collection) return
    
        (:if this collection was created inside a different user's collection,
        allow the owner of the parent collection access:)
        let $null := security:grant-parent-owner-access-if-foreign-collection($new-parent-collection) 
        
        return
            <status id="moved" from="{$collection-to-move}">{$new-parent-collection}</status>
};

(:NB: name change does not take place if the new name is already taken.:)
(:TODO: notify user if the new name is already taken.:)
declare function op:rename-collection($collection-uri as xs:string, $new-collection-name as xs:string) as element(status) {

    let $null := xmldb:rename($collection-uri, $new-collection-name) 
    return
        <status id="renamed" from="{$collection-uri}">{$new-collection-name}</status>
};

(:TODO: After removal, perform search in Home collection:)
(:TODO: Implement for VRA records:)
declare function op:remove-collection($collection as xs:string) as element(status) {

    (:Only allow deletion of a collection if none of the MODS records in it are referred to in xlinks outside the collection itself.:)
    (:Get the ids of the records in the collection that the user wants to delete.:)
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
                )
    let $null := 
        (:If $xlinked-rec-ids is not empty, do not delete.:)
        if ($xlinked-rec-ids)
        then ()
        else system:as-user(security:get-user-credential-from-session()[1], security:get-user-credential-from-session()[2], xmldb:remove($collection)) 
    return
        if ($xlinked-rec-ids)
        then <status id="removed">{collection}</status>
        else <status id="not-removed">{$collection}</status>
};

(:~
:
: @resource-id is the UUID of the MODS or VRA record
TODO: Perform search for contents of the collection that the removed resource belonged to.
:)
declare function op:remove-resource($resource-id as xs:string) as element(status)* {
    let $mods-record := collection($config:mods-root-minus-temp)//mods:mods[@ID eq $resource-id]
    let $xlink-to-mods-record := concat('#', $resource-id)
    (:since xlinks are also inserted manually, check also for cases when the pound sign has been forgotten:)
    let $xlinked-mods-records := collection($config:mods-root-minus-temp)//mods:relatedItem[@xlink:href = ($xlink-to-mods-record, $resource-id)]
    
    let $vra-work-record := collection($config:mods-root-minus-temp)//vra:vra/vra:work[@id eq $resource-id]
    (:NB: we assume that @relids (plural) can hold several values:)
    let $vra-image-records := collection($config:mods-root-minus-temp)//vra:vra[vra:image/vra:relationSet/vra:relation[contains(@relids, $resource-id)]]
    (:NB: we assume that all image files are in the same collection as their metadata 
    and that all image records belonging to a work record are in the same collection:)
    let $vra-image-record-collection := util:collection-name($vra-image-records[1])
    let $vra-binary-file-names := $vra-image-records/vra:image/@href    
    let $vra-records := ($vra-work-record, $vra-image-records)
    
    let $records := 
        if ($mods-record) 
        then $mods-record 
        else $vra-records 
    
    for $record in $records 
    return
    (
        (:do not remove records which erroneously have the same ID:)
        (:TODO: inform user that this is the case:)
        if (count($record) eq 1)
        then
            (:do not remove a record which is xlinked to from one or more other records:)
            (:TODO: inform user that this is the case:)
            if (count($xlinked-mods-records) eq 0) 
            then system:as-user(security:get-user-credential-from-session()[1], security:get-user-credential-from-session()[2], xmldb:remove(util:collection-name($record), util:document-name($record)))
            else ()
        else ()
        ,
        if (count($vra-binary-file-names) gt 0) 
        then
            for $vra-binary-name in $vra-binary-file-names
            return
                (:NB: since this iterates inside another iteration, files are attempted deleted which have been deleted already, 
                causing the script to halt. However, the existence of the file to be deleted should first be checked, 
                in order to prevent the function from halting in case the file does not exist.:)
                if (util:binary-doc-available(concat($vra-image-record-collection, '/', $vra-binary-name))) 
                then system:as-user(security:get-user-credential-from-session()[1], security:get-user-credential-from-session()[2], xmldb:remove($vra-image-record-collection, $vra-binary-name))
                else ()
        else ()
(:        ,:)
(:        response:set-status-code($HTTP-FORBIDDEN),:)
(:        <p>Unknown action: Movee.</p>:)
    )
};



(:~
: @ resource-id has the format db-document-path#node-id e.g. /db/mods/eXist/exist-articles.xml#1.36
TODO: Perform search for record after it has been moved. 
:)
declare function op:move-resource($resource-id as xs:string, $destination-collection as xs:string) as element(status) {

    let $resource := collection($config:mods-root-minus-temp)//(mods:mods[@ID eq $resource-id][1] | vra:vra[vra:work[@id eq $resource-id]][1])
    let $record-namespace := namespace-uri($resource)
    let $move-record :=
        switch($record-namespace)
            case "http://www.loc.gov/mods/v3"
                return mods-hra-framework:move-resource($resource-id, $destination-collection)
            case "http://www.vraweb.org/vracore4.htm"
                return vra-hra-framework:move-resource($resource-id, $destination-collection)
            default return ()

        return $move-record

};

declare function op:set-ace-writeable($collection as xs:anyURI, $id as xs:int, $is-writeable as xs:boolean) as element(status) {
  
    if(exists(sharing:set-collection-ace-writeable($collection, $id, $is-writeable)))then  
        <status id="ace">updated</status>
    else(
        response:set-status-code($HTTP-FORBIDDEN),
        <status id="ace">Permission Denied</status>
    )
};

declare function op:remove-ace($collection as xs:anyURI, $id as xs:int) as element(status) {
  
    if(exists(sharing:remove-collection-ace($collection, $id)))then
        <status id="ace">removed</status>
    else(
        response:set-status-code($HTTP-FORBIDDEN),
        <status id="ace">Permission Denied</status>
    )
  
};

declare function op:add-user-ace($collection as xs:anyURI, $username as xs:string) as element(status) {
    
    let $ace-id := sharing:add-collection-user-ace($collection, $username)

    return
        if ($ace-id != -1)
        then <status ace-id="{$ace-id}">added</status>
        else
            ( 
                response:set-status-code($HTTP-FORBIDDEN),
                <status ace-id="{$ace-id}">Permission Denied</status>
            )
};

declare function op:add-group-ace($collection as xs:anyURI, $groupname as xs:string) as element(status) {
    
    let $ace-id := sharing:add-collection-group-ace($collection, $groupname)    
    
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
    if(sharing:is-valid-user-for-share($username))then
        <status id="user">valid</status>
    else(
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

(:A collection cannot be moved into itself or into its parent, nor can it be moved into a subcollection, 
so it is necessary to check against the path of the collection that is to be moved.
A file cannot, by stipulation, be moved into the top level of the home collection, nor can it be moved to its own parent collection.:)
(:TODO: capture the collection that the resource to be moved belongs to.:)
declare function op:get-move-list($chosen-collection as xs:anyURI, $type as xs:string) as element(select) {
    <select>{
        let $user := security:get-user-credential-from-session()[1]
        let $home-collection := security:get-home-collection-uri($user)
        let $shared-collection-roots := sharing:get-shared-collection-roots(true())
        let $resource-collection := '' (:NB: capture collection!:)
        let $move-folder-list := ($home-collection, op:get-child-collection-paths($home-collection), $shared-collection-roots)
        let $move-folder-list := distinct-values($move-folder-list)[not(ends-with(., 'VRA_images'))]
        let $chosen-collection-parent := functx:substring-before-last($chosen-collection, "/")
        for $path in $move-folder-list
            [
                if ($type eq 'folder')
                then not(. eq $chosen-collection-parent) and not(starts-with(concat(., '/'), concat($chosen-collection, '/')))
                else not(. eq $resource-collection) and not(. eq $home-collection) 
            ]
        (:"/" is appended in order not to omit a collection called "new folder" when comparing with a collection called "new":)
        (:"starts-with" also eliminates the chosen-folder itself from the list of targets.:)
        let $display-path := substring-after($path, '/db/')
        let $display-path := replace($path, concat('users/', $user), 'Home')
        order by $display-path
            return
            <option value="{xmldb:decode-uri($path)}">{xmldb:decode-uri($display-path)}</option>
    }</select>
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

let $action := request:get-parameter("action", ())
let $collection := config:process-request-parameter(request:get-parameter("collection", ()))

return
    if ($action eq "create-collection") then
        op:create-collection($collection, request:get-parameter("name",()))
    else if ($action eq "move-collection") then
        op:move-collection($collection, config:process-request-parameter(request:get-parameter("path",())))
    else if ($action eq "rename-collection") then
        op:rename-collection($collection, request:get-parameter("name",()))
    else if ($action eq "remove-collection") then
        op:remove-collection($collection)
    else if ($action eq "remove-resource") then
        op:remove-resource(request:get-parameter("resource",()))
    else if ($action eq "move-resource") then
        op:move-resource(request:get-parameter("resource",()), request:get-parameter("path",()))
    else if ($action eq "set-ace-writeable") then
        op:set-ace-writeable(xs:anyURI($collection), xs:int(request:get-parameter("id",())), xs:boolean(request:get-parameter("is-writeable", false())))
    else if ($action eq "remove-ace") then
        op:remove-ace(xs:anyURI($collection), xs:int(request:get-parameter("id",())))
    else if ($action eq "add-user-ace") then
        op:add-user-ace(xs:anyURI($collection), request:get-parameter("username",()))
    else if ($action eq "is-valid-user-for-share") then
        op:is-valid-user-for-share(request:get-parameter("username",()))
    else if ($action eq "add-group-ace") then
        op:add-group-ace(xs:anyURI($collection), request:get-parameter("groupname",()))
    else if ($action eq "is-valid-group-for-share") then
        op:is-valid-group-for-share(request:get-parameter("groupname",()))
    else if ($action eq "get-move-folder-list") then
        op:get-move-list($collection, 'folder')
     else if ($action eq "get-move-resource-list") then
        op:get-move-list($collection, 'resource')
     else
        op:unknown-action($action)
