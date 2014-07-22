xquery version "3.0";

module namespace tamboti-utils = "http://hra.uni-heidelberg.de/ns/tamboti/utils";

import module namespace config = "http://exist-db.org/mods/config" at "../../modules/config.xqm";

declare function tamboti-utils:get-username-from-path($path as xs:string?) as xs:string? {
    let $substring-1 := substring-after($path, $config:users-collection || "/")
    
    return if (contains($substring-1, '/')) then substring-before($substring-1, "/") else $substring-1
};
