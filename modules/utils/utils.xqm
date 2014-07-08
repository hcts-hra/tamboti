xquery version "3.0";

module namespace tamboti-utils = "http://hra.uni-heidelberg.de/ns/tamboti/utils";

import module namespace config = "http://exist-db.org/mods/config" at "../../modules/config.xqm";

declare function tamboti-utils:get-username-from-path($path as xs:string?) as xs:string? {
    substring-before(substring-after($path, $config:users-collection || "/"), "/")
};
