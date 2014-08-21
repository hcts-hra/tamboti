xquery version "3.0";
(: author dulip withanage 
import module namespace uu="http://exist-db.org/mods/uri-util" at "uri-util.xqm";
:)

import module namespace config="http://exist-db.org/mods/config" at "../config.xqm";
import module namespace security="http://exist-db.org/mods/security" at "security.xqm";


declare namespace upload = "http://exist-db.org/eXide/upload";
declare namespace functx = "http://www.functx.com";
declare namespace vra="http://www.vraweb.org/vracore4.htm";
declare namespace mods="http://www.loc.gov/mods/v3";

declare variable $user := $config:dba-credentials[1];
declare variable $userpass := $config:dba-credentials[2];
declare variable $rootdatacollection:='/db/resources/';
declare variable $message := 'uploaded';
declare variable $image_col := 'VRA_images';

declare function local:string-exists($input as xs:string)
{
    let $uout :=
        if (contains($input, ())) then
            $input
        else
            ''
    return $uout
};

declare function functx:substring-before-last($arg as xs:string?, $delim as xs:string)
as xs:string
{
    if (matches($arg, functx:escape-for-regex($delim))) then
        replace($arg, concat('^(.*)', functx:escape-for-regex($delim), '.*'), '$1')
    else
        ''
};

declare function upload:list-data()
{
    let $directory-list := system:as-user($user, $userpass, file:directory-list($newcol, '*.*'))
    return $directory-list
};


 declare function functx:escape-for-regex($arg as xs:string?)
 as xs:string
 {
     replace($arg, '(\.|\[|\]|\\|\||\-|\^|\$|\?|\*|\+|\{|\}|\(|\))', '\\$1')
 };
 
 
declare function functx:substring-after-last($arg as xs:string?, $delim as xs:string)
as xs:string
{
    replace($arg, concat('^.*', functx:escape-for-regex($delim)), '')
};


 
declare function local:generate-vra-image($uuid, $file-uuid, $title, $workrecord)
{
    let $vra-content :=
        <vra xmlns="http://www.vraweb.org/vracore4.htm" xmlns:ext="http://exist-db.org/vra/extension" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemalocation="http://www.vraweb.org/vracore4.htm
    http://cluster-schemas.uni-hd.de/vra-strictCluster.xsd">
            <image id="{ $uuid }" source="Tamboti" refid="" href="{ $file-uuid }">
                <titleSet>
                    <display/>
                        <title type="generalView">{xmldb:decode(concat('Image record ', $title))}</title>
                </titleSet>
                <relationSet>
                    <relation type="imageOf" relids="{$workrecord}" refid="" source="Tamboti">attachment</relation>
                </relationSet>
            </image>
        </vra>
    return $vra-content
};



declare function upload:generate-object($size, $mimetype, $uuid, $title, $file-uuid, $doc-type, $workrecord)
{
    let $vra-content := local:generate-vra-image($uuid, $file-uuid, $title, $workrecord)
    let $out-put :=
        if ($doc-type eq 'image') then
            $vra-content
        else
            ()
    return $out-put
};





declare function upload:mkcol-recursive($collection, $components)
{
    if (exists($components)) then
        let $newColl := concat($collection, "/", $components[1])
        return
            (xmldb:create-collection($collection, $components[1]),
            upload:mkcol-recursive($newColl, subsequence($components, 2)))
    else
        ()
};




(: Helper function to recursively create a collection hierarchy. :)
declare function upload:mkcol($collection, $path)
{
    upload:mkcol-recursive($collection, tokenize($path, "/"))[last()]
};

declare function local:recurse-items($collection-path as xs:string, $username as xs:string, $mode as xs:string)
{
    local:apply-perms($collection-path, $username, $mode),
    for $child in xmldb:get-child-resources($collection-path)
    let $resource-path := fn:concat($collection-path, "/", $child)
    return
        local:apply-perms($resource-path, $username, $mode),
    for $child in xmldb:get-child-collections($collection-path)
    let $child-collection-path := fn:concat($collection-path, "/", $child)
    return
        local:recurse-items($child-collection-path, $username, $mode)
};

declare function local:apply-perms($path as xs:string, $username as xs:string, $mode as xs:string)
{
    sm:add-user-ace(xs:anyURI($path), $username, true(), $mode)
};


declare function local:recurse-items($collection-path as xs:string, $username as xs:string, $mode as xs:string)
{
    local:apply-perms($collection-path, $username, $mode),
    for $child in xmldb:get-child-resources($collection-path)
    let $resource-path := fn:concat($collection-path, "/", $child)
    return
        local:apply-perms($resource-path, $username, $mode),
    for $child in xmldb:get-child-collections($collection-path)
    let $child-collection-path := fn:concat($collection-path, "/", $child)
    return
        local:recurse-items($child-collection-path, $username, $mode)
};



declare function local:apply-perms($path as xs:string, $username as xs:string, $mode as xs:string) {
    sm:add-user-ace(xs:anyURI($path), $username, true(), $mode)    

};



declare function upload:upload( $filetype , $filesize,  $filename, $data, $doc-type, $workrecord) {
     let $myuuid := concat('i_',util:uuid())
     let $parentcol :=
     if (exists(collection($rootdatacollection)//vra:work[@id=$workrecord]/@id))
    then 
        util:collection-name(collection($rootdatacollection)//vra:work[@id=$workrecord]/@id)
    else if (exists(collection($rootdatacollection)//mods:mods[@ID=$workrecord]/@ID))
    then 
        util:collection-name(collection($rootdatacollection)//mods:mods[@ID=$workrecord]/@ID)
    else ()
   
    
    let $parentdoc_path := concat($parentcol,'/',$workrecord,'.xml')
    let $none := util:log('ERROR',$parentcol)
    let $tag-changed := upload:add-tag-to-parent-doc($parentdoc_path, upload:determine-type($workrecord), $myuuid)
    
    (:set the image VRA folder by adding the suffix:)
  
    let $upload :=  if (exists($parentcol))
        then
        system:as-user($user, $userpass, 
            (   let $newcol := $parentcol
                let $mkdir := if (xmldb:collection-available($newcol)) then()
                else
                (
                 let $none := upload:mkcol('/',$newcol)
                 let $none := security:apply-parent-collection-permissions(xs:anyURI($newcol))
                 return $none
                )
(:                let $create-image-folder := xmldb:create-collection($newcol, $image_col):)
                (:create image folder:)
                let $newcol-vra := concat($newcol, '/', $image_col)

                let $none := if (not(xmldb:collection-available($newcol-vra))) then (
                    let $none := xmldb:create-collection($newcol, $image_col)
                    (: to be sure that the collection owner's group is the intended one :)
                    let $change-group := sm:chgrp(xs:anyURI($newcol-vra), $config:biblio-users-group)                    
                    let $none := security:apply-parent-collection-permissions(xs:anyURI($newcol-vra))
                    return $none
                    
                )
                
                else()
                
                (: update the xml object  :)
                let $file-uuid := concat($myuuid, '.',functx:substring-after-last($filename, '.'))
                let $xml-object := upload:generate-object($filesize, $filetype,$myuuid, $filename, $file-uuid,$doc-type,$workrecord)
                (:save the xml file:)
                let $xml-uuid := concat($myuuid,'.xml')
                let $xmlupload := xmldb:store($newcol-vra,$xml-uuid , $xml-object)
                (:save binary file:)
                let $upload := xmldb:store($newcol-vra, $file-uuid,$data)
                
                (::let $none := security:apply-parent-collection-permissions(xs:anyURI($newcol)):)
                let $none := sm:chown(xs:anyURI(concat($newcol-vra,'/', $file-uuid)),security:get-user-credential-from-session()[1])
                let $none := sm:chmod(xs:anyURI(concat($newcol-vra,'/', $file-uuid)),'rwxr-xr-x')
                let $none := sm:chgrp(xs:anyURI(concat($newcol-vra,'/', $file-uuid)), $config:biblio-users-group)
                
                
                let $none := sm:chown(xs:anyURI(concat($newcol-vra,'/', $xml-uuid)),security:get-user-credential-from-session()[1])
                let $none := sm:chmod(xs:anyURI(concat($newcol-vra,'/', $xml-uuid)),'rwxr-xr-x')
                let $none := sm:chgrp(xs:anyURI(concat($newcol-vra,'/', $xml-uuid)), $config:biblio-users-group)
                
                let $none := security:apply-parent-collection-permissions(xs:anyURI(concat($newcol-vra, '/' , $file-uuid)))
                let $none := security:apply-parent-collection-permissions(xs:anyURI(concat($newcol-vra, '/' , $xml-uuid)))
                                
                return concat(xmldb:decode($filename),' ' ,$message)
            )
        )
       else ()
      return $upload
        
 };
 
declare function upload:add-tag-to-parent-doc($parentdoc_path , $parent_type as xs:string, $myuuid){
    let $parentdoc := doc($parentdoc_path)
    let $add :=
        if  ($parent_type eq 'vra')
            then
                (
                let $vra_insert := <vra:relation type="imageIs" relids="{$myuuid}" source="Tamboti" refid=""  pref="true">general view</vra:relation>
                let $relationTag := $parentdoc/vra:vra/vra:work/vra:relationSet
                return
                    let $vra-insert := $parentdoc
                    let $insert_or_updata := 
                        if (not($relationTag))
                        then (update insert <vra:relationSet></vra:relationSet> into $vra-insert/vra:vra/vra:work)
                        else ()
                    let $vra-update := update insert $vra_insert into $parentdoc/vra:vra/vra:work/vra:relationSet
                    return  $vra-update
                )
            else if ($parent_type eq 'mods')
            then
                (
                    let $mods-insert := <mods:relatedItem  xmlns:mods="http://www.loc.gov/mods/v3" type="constituent">
                        <mods:typeOfResource>still image</mods:typeOfResource>
                            <mods:location>
                                <mods:url displayLabel="Illustration" access="preview">{$myuuid}</mods:url>
                            </mods:location>
                        </mods:relatedItem>
                    let $mods-insert-tag := $parentdoc
                    let $mods-update := update insert  $mods-insert into $mods-insert-tag/mods:mods
                    return  $mods-update
                )
            else  ()
    
    return $add
};

declare function upload:determine-type($workrecord)
 {
     let $vra_image := collection($rootdatacollection)//vra:work[@id = $workrecord]/@id
     let $type :=
         if (exists($vra_image)) then
             ('vra')
         else
             (let $mods := collection($rootdatacollection)//mods:mods[@ID = $workrecord]/@ID
             let $mods_type :=
                 if (exists($mods)) then
                     ('mods')
                 else
                     ()
             return $mods_type)
     return $type
};

let $types := ('png', 'jpg', 'gif', 'tiff', 'PNG', 'JPG', 'jpeg', 'tif', 'TIF')
let $uploadedFile := 'uploadedFile'
let $data := request:get-uploaded-file-data($uploadedFile)
let $filename := request:get-uploaded-file-name($uploadedFile)
let $filesize := request:get-uploaded-file-size($uploadedFile)


let $result := for $x in (1 to count($data))
    let $filetype := functx:substring-after-last($filename[$x],'.')
    let $doc-type := if (contains($filetype,'png') or contains($filetype, 'jpg') or contains($filetype,'gif') or contains ($filetype,'tif')
                    or contains($filetype,'PNG') or contains($filetype, 'JPG') or contains($filetype,'GIF') or contains ($filetype,'TIF') or   
                     contains ($filetype,'jpeg'))
                        then ( 'image')
                    else('')
    return
        if ($doc-type eq 'image')
            then(
                let $workrecord := if (fn:string-length(request:get-header('X-File-Parent'))>0)
                then (
                    xmldb:encode(request:get-header('X-File-Parent'))
                )
                else()
                let $upload := if (exists($workrecord))
                    then (
                    upload:upload($filetype, $filesize[$x], xmldb:encode-uri($filename[$x]), $data[$x], $doc-type,$workrecord)
                    )
                    else (
                        (:record for the collection:)
                        let $collection-folder :=  xmldb:encode-uri(request:get-header('X-File-Folder'))
                        (: if the collection file exists in the file folder:)
                        (:read the collection uuid:)
                        let $collection_vra := collection($config:mods-root)//vra:collection
                        let $collection_uuid :=  if  (exists($collection_vra))
                            then (  $collection_vra/@id)
                            else ( concat ('c_',util:uuid())
                            )
                        
                        (:else generate the new collection file:)
                        let $none := if (exists($collection_vra/@id))
                            then ()
                            else (
                                let $vra-collection-xml := 
                                <vra xmlns="http://www.vraweb.org/vracore4.htm" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.vraweb.org/vracore4.htm http://cluster-schemas.uni-hd.de/vra-strictCluster.xsd" xmlns:ext="http://exist-db.org/vra/extension">
                                <collection id="{$collection_uuid}" source="" refid="{$collection_uuid}"></collection> </vra>
                                (:let $store := system:as-user($user, $userpass, xmldb:store($collection-folder,concat($collection_uuid,'.xml') , $vra-collection-xml))
                                return $store
                                :)
                                return ()
                            )
                         
                        (:generate the  work record , if collection xml exists:)
                        let $work-xml-generate :=if (exists($collection_uuid))
                            then (
                                let $work_uuid := concat('w_',util:uuid())
                                let $vra-work-xml := <vra xmlns="http://www.vraweb.org/vracore4.htm" xmlns:hra="http://cluster-schemas.uni-hd.de" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.vraweb.org/vracore4.htm http://cluster-schemas.uni-hd.de/vra-strictCluster.xsd">
                                <work id="{$work_uuid}" source="Kurs" refid="{$collection_uuid}">
                                 <titleSet><display/><title type="generalView">
                                    {xmldb:decode(concat('Work record ', $filename[$x]))}</title></titleSet>  
                                    
                                </work></vra>
                                let $store :=  system:as-user($user, $userpass,xmldb:store($collection-folder,concat($work_uuid,'.xml') , $vra-work-xml))
                                (: let $none := system:as-user($user, $userpass,security:apply-parent-collection-permissions(xs:anyURI(concat($collection-folder,'/', $work_uuid,'.xml')))) :)
                                 let $none := system:as-user($user, $userpass,sm:chown(xs:anyURI(concat($collection-folder,'/', $work_uuid,'.xml')),security:get-user-credential-from-session()[1]))
                                let $none := system:as-user($user, $userpass,sm:chmod(xs:anyURI(concat($collection-folder,'/', $work_uuid,'.xml')),'rwxr-xr-x'))
                                let $none := system:as-user($user, $userpass,sm:chgrp(xs:anyURI(concat($collection-folder,'/', $work_uuid,'.xml')), $config:biblio-users-group))
                                
                                (:store the binary file and generate the  image vra file:)
                                let $store := upload:upload( $filetype , $filesize[$x],$filename[$x], $data[$x], $doc-type, $work_uuid)
                                
                                return $message
                            )
                            else()
                    return concat($filename[$x],' ',$message)
                    )
                    return $upload
         )           
        else (let $upload:='unsupported file format'
                return $upload
        )
     
 (:     
 let $reindex :=   system:as-user('admin', '', xmldb:reindex($config:mods-root))
:)
return $result
