xquery version "3.1";

import module namespace config = "http://exist-db.org/mods/config" at "modules/config.xqm";

declare variable $home external;
declare variable $target external;

declare function local:set-special-permissions($path as xs:anyURI) {
    (
        sm:chown($path, "admin")
        ,
        sm:chgrp($path, "dba")
        ,
        sm:chmod($path, "rwsr-xr-x")
    )
};

(    
    (: set special permissions for xquery scripts :)
    sm:chmod(xs:anyURI($target || "/modules/upload/upload.xq"), "rwsr-xr-x")
    ,
    sm:chmod(xs:anyURI($target || "/modules/search/collections.xql"), "rwsr-xr-x") 
    ,
    sm:chmod(xs:anyURI($target || "/modules/search/simple-search.xql"), "rwsr-xr-x")     
    ,
    sm:chmod(xs:anyURI($target || "/modules/search/advanced-search.xql"), "rwsr-xr-x") 
    ,
    local:set-special-permissions(xs:anyURI($target || "/frameworks/vra-hra/vra-hra.xqm"))
    ,
    sm:chmod(xs:anyURI($target || "/docs/controller.xql"), "rwxr-xr-x")
    ,
    local:set-special-permissions(xs:anyURI($target || "/frameworks/hra-annotations/annotations.xq"))
    ,
    local:set-special-permissions(xs:anyURI($config:content-root))
)
