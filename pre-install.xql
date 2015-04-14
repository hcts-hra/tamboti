xquery version "3.0";

(:
    TODO KISS - This file should be removed in favour of a convention based approach + some small metadata for users/groups/permissions (added by AR)
:)

import module namespace util = "http://exist-db.org/xquery/util";
import module namespace security = "http://exist-db.org/mods/security" at "modules/search/security.xqm";
import module namespace config = "http://exist-db.org/mods/config" at "modules/config.xqm";

(: The following external variables are set by the repo:deploy function :)

(: file path pointing to the exist installation directory :)
declare variable $home external;
(: path to the directory containing the unpacked .xar package :)
declare variable $dir external;
(: the target collection into which the app is deployed :)
declare variable $target external;

declare variable $log-level := "INFO";
declare variable $db-root := "/db";
declare variable $config-collection := fn:concat($db-root, "/system/config");

(:~ Collection names :)
declare variable $modules-collection-name := "modules";
declare variable $editor-collection-name := "edit";
declare variable $code-tables-collection-name := "code-tables";

declare variable $users-collection-name := "users";
declare variable $temp-collection-name := "temp";
declare variable $commons-collection-name := "commons";
declare variable $samples-collection-name := "Samples";

(:~ Collection paths :)
declare variable $app-collection := $target;
declare variable $modules-collection := fn:concat($app-collection, "/", $modules-collection-name);
declare variable $editor-collection := fn:concat($modules-collection, "/", $editor-collection-name);
declare variable $editor-code-tables-collection := fn:concat($editor-collection, "/", $code-tables-collection-name);

declare variable $resources-collection := fn:concat($db-root, "/", $config:data-collection-name);
declare variable $temp-collection := fn:concat($resources-collection, "/", $temp-collection-name);
declare variable $users-collection := fn:concat($resources-collection, "/", $users-collection-name);
declare variable $commons-collection := fn:concat($resources-collection, "/", $commons-collection-name);

declare function local:mkcol-recursive($collection, $components, $permissions as xs:string) {
    if (exists($components))
    then
        let $newColl := concat($collection, "/", $components[1])
        return (
            if (not(xmldb:collection-available($newColl)))
            then
                (
                    xmldb:create-collection($collection, $components[1])
                    ,
                    local:set-resource-properties(xs:anyURI($newColl), $permissions)
                )
            else ()
            ,
            local:mkcol-recursive($newColl, subsequence($components, 2), $permissions)
        )
    else ()
};

(: Helper function to recursively create a collection hierarchy. :)
declare function local:mkcol($collection, $path, $permissions as xs:string) {
    local:mkcol-recursive($collection, tokenize($path, "/"), $permissions)
};

declare function local:set-resource-properties($resource-path as xs:anyURI, $permissions as xs:string) {
    (
        security:set-resource-permissions($resource-path, $config:biblio-admin-user, $config:biblio-users-group, $permissions)        
    )
};

declare function local:set-resources-properties($collection-path as xs:anyURI, $permissions as xs:string) {
    for $resource-name in xmldb:get-child-resources($collection-path) return local:set-resource-properties(xs:anyURI(concat($collection-path, '/', $resource-name)), $permissions)
};

declare function local:strip-prefix($str as xs:string, $prefix as xs:string) as xs:string? {
    fn:replace($str, $prefix, "")
};


util:log($log-level, "Script: Running pre-install script ..."),
util:log($log-level, fn:concat("...Script: using $home '", $home, "'")),
util:log($log-level, fn:concat("...Script: using $dir '", $dir, "'")),

(: create $config:data-collection-name collection :)
if (not(xmldb:collection-available($config:content-root)))
then
    (
        xmldb:create-collection("/db", $config:data-collection-name),
        local:set-resource-properties(xs:anyURI($config:content-root), $config:public-collection-mode)
    )
else ()
,
(: Create users and groups :)
util:log($log-level, fn:concat("Security: Creating user '", $config:biblio-admin-user, "' and group '", $config:biblio-users-group, "' ..."))
,
if (xmldb:group-exists($config:biblio-users-group))
then ()
else xmldb:create-group($config:biblio-users-group)
,
if (xmldb:exists-user($config:biblio-admin-user))
then ()
else xmldb:create-user($config:biblio-admin-user, $config:biblio-admin-user, $config:biblio-users-group, ())
,
util:log($log-level, "Security: Done.")
,

(: Load collection.xconf documents :)
util:log($log-level, "Config: Loading collection configuration ...")
,
local:mkcol($config-collection, $editor-code-tables-collection, $config:public-collection-mode)
,
xmldb:store-files-from-pattern(fn:concat($config-collection, $editor-code-tables-collection), $dir, "data/xconf/code-tables/*.xconf")
,
local:mkcol($config-collection, $resources-collection, $config:public-collection-mode)
,
xmldb:store-files-from-pattern(fn:concat($config-collection, $resources-collection), $dir, "data/xconf/resources/*.xconf")
,
(:local:mkcol($config-collection, $mads-collection),:)
(:xmldb:store-files-from-pattern(fn:concat($config-collection, $mads-collection), $dir, "data/xconf/mads/*.xconf"),:) 
util:log($log-level, "Config: Done.")
,

(: Create temp collection :)
util:log($log-level, fn:concat("Config: Creating temp collection '", $temp-collection, "'..."))
,
local:mkcol($db-root, local:strip-prefix($temp-collection, fn:concat($db-root, "/")), $config:temp-collection-mode)
,
util:log($log-level, "Config: Done.")
,

(: Create "commons" collections :)
util:log($log-level, fn:concat("Config: Creating commons collection '", $commons-collection, "'..."))
,
local:mkcol($db-root, local:strip-prefix($commons-collection, fn:concat($db-root, "/")), $config:collection-mode)
,

(: Create users and groups collections :)
util:log($log-level, fn:concat("Config: Creating users '", $users-collection, "' collections"))
,
local:mkcol($db-root, local:strip-prefix($users-collection, fn:concat($db-root, "/")), $config:collection-mode)
,
util:log($log-level, "Config: Done.")
,
util:log($log-level, "Script: Done.")
