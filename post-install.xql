xquery version "3.1";

import module namespace config = "http://exist-db.org/mods/config" at "modules/config.xqm";

declare variable $home external;
declare variable $target external;

declare function local:set-special-permissions($path as xs:anyURI) {
    (
        sm:chown($path, "admin")
        ,
        sm:chgrp($path, "biblio.users")
        ,
        sm:chmod($path, "rwsr-xr-x")
    )
};

(    
    (: set special permissions for xquery scripts :)
    local:set-special-permissions(xs:anyURI($target || "/modules/upload/upload.xq"))
    ,
    local:set-special-permissions(xs:anyURI($target || "/modules/search/collections.xql")) 
    ,
    local:set-special-permissions(xs:anyURI($target || "/modules/search/operations.xql"))
    ,
    local:set-special-permissions(xs:anyURI($target || "/modules/search/sharing.xql"))
    ,
    local:set-special-permissions(xs:anyURI($target || "/modules/search/sharing.xqm")) 
    ,
    local:set-special-permissions(xs:anyURI($target || "/modules/search/security.xqm")) 
    ,
    local:set-special-permissions(xs:anyURI($target || "/modules/session.xql")) 
    ,    
    local:set-special-permissions(xs:anyURI($target || "/modules/search/simple-search.xql"))     
    ,
    local:set-special-permissions(xs:anyURI($target || "/modules/search/advanced-search.xql"))
    ,
    local:set-special-permissions(xs:anyURI($target || "/modules/search/autocomplete-username.xql"))    
    ,
    local:set-special-permissions(xs:anyURI($target || "/modules/search/autocomplete.xql"))   
    ,
    local:set-special-permissions(xs:anyURI($target || "/modules/search/user.xql")) 
    ,
    local:set-special-permissions(xs:anyURI($target || "/modules/search/checkuser.xql"))       
    ,
    local:set-special-permissions(xs:anyURI($target || "/frameworks/hra-rdf/hra-rdf-framework.xqm"))     
    ,
    local:set-special-permissions(xs:anyURI($target || "/frameworks/tei-hra/get-data.xq"))     
    ,
    local:set-special-permissions(xs:anyURI($target || "/frameworks/vra-hra/vra-hra.xqm"))
    ,
    local:set-special-permissions(xs:anyURI($target || "/frameworks/mods-hra/mods-hra.xqm"))    
    ,
    local:set-special-permissions(xs:anyURI($target || "/modules/utils/utils.xqm"))    
    ,
    sm:chmod(xs:anyURI($target || "/docs/controller.xql"), "rwxr-xr-x")
    ,
    local:set-special-permissions(xs:anyURI($target || "/frameworks/hra-annotations/annotations.xq"))
    ,
    local:set-special-permissions(xs:anyURI($config:content-root))
)
