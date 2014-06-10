xquery version "3.0";
declare option exist:serialize "method=xhtml media-type=text/html";

declare function local:recurse-items($collection-path as xs:string, $username as xs:string, $mode as xs:string, $admin-password as xs:string) {
    
    system:as-user("admin", $admin-password,local:apply-perms($collection-path, $username, $mode)),
    
    for $child in xmldb:get-child-resources($collection-path)
    let $resource-path := fn:concat($collection-path, "/", $child) return
         system:as-user("admin",$admin-password,local:apply-perms($resource-path, $username, $mode))
    ,
    
    for $child in xmldb:get-child-collections($collection-path)
    let $child-collection-path := fn:concat($collection-path, "/", $child) return
        local:recurse-items($child-collection-path, $username, $mode, $admin-password)
};

declare function local:apply-perms($path as xs:string, $username as xs:string, $mode as xs:string) {
    sm:add-user-ace(xs:anyURI($path), $username,true(), $mode)    
    
};


let $collection := "/db/resources/commons/Priya_Paul_Collection"
let $username := "dulip.withanage@ad.uni-heidelberg.de"
let $mode := "rwx"
let $admin-password := "xyz"
    return
    <TABLE>
    <TR>
    <TD>Udated successfully</TD>
    <td>{local:recurse-items($collection, $username, $mode, $admin-password)}</td>
    </TR>
    </TABLE>
