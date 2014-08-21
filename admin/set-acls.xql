xquery version "1.0";
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


(: 
 :         for $user-name  in $usernames 
 : return sm:add-user-ace($collection, concat($user-name,"@ad.uni-heidelberg.de"), true(), $mode) 

zzz_testfolder
 : :)
let $collection := ""

(:let $usernames := ("tony.buchwald", "marnold1", "vp090", "johannes.alisch", "a02", "simon.gruening", "eb5", "eric.decker", "christiane.brosius", "cbrosius", "laila.abu-er-rub", "melissa.butcher", "hu405", "m2b", "j0k", "p0i", "m5c", "y8c", "labuerr5", "n6n", "v4a", "f8h", "g05", "hg7","dulip.withanage","matthias.guth"):)

let $usernames := ("tony.buchwald")

let $mode := "rwx"
let $admin-password := "sdfsadfsdf"
    return
    <TABLE>
    <TR>
    <TD>Udated successfully</TD>
    <td>{

     for $user-name  in $usernames
     
   return sm:add-user-ace($collection, concat($user-name,"@ad.uni-heidelberg.de"), true(), $mode) 
   
        }
        
    </td>
    
    
    </TR>
    </TABLE>
