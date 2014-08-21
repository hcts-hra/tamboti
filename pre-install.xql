xquery version "1.0";

(:
    TODO KISS - This file should be removed in favour of a convention based approach + some small metadata for users/groups/permissions (added by AR)
:)

import module namespace util="http://exist-db.org/xquery/util";
import module namespace xdb="http://exist-db.org/xquery/xmldb";

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

(:~ Biblio security - admin user and users group :)
declare variable $biblio-admin-user := "editor";
declare variable $biblio-users-group := "biblio.users";

(:~ Collection names :)
declare variable $modules-collection-name := "modules";
declare variable $editor-collection-name := "edit";
declare variable $code-tables-collection-name := "code-tables";

declare variable $resources-collection-name := "resources";
declare variable $users-collection-name := "users";
declare variable $groups-collection-name := "groups";
declare variable $temp-collection-name := "temp";
declare variable $commons-collection-name := "commons";
declare variable $samples-collection-name := "Samples";
declare variable $sociology-collection-name := "Sociology";
declare variable $exist-db-collection-name := "eXist-db";
(:declare variable $mads-collection-name := "mads";:)

(:~ Collection paths :)
declare variable $app-collection := $target;
declare variable $modules-collection := fn:concat($app-collection, "/", $modules-collection-name);
declare variable $editor-collection := fn:concat($modules-collection, "/", $editor-collection-name);
declare variable $editor-code-tables-collection := fn:concat($editor-collection, "/", $code-tables-collection-name);

declare variable $resources-collection := fn:concat($db-root, "/", $resources-collection-name);
declare variable $temp-collection := fn:concat($resources-collection, "/", $temp-collection-name);
declare variable $users-collection := fn:concat($resources-collection, "/", $users-collection-name);
declare variable $groups-collection := fn:concat($resources-collection, "/", $groups-collection-name);
declare variable $commons-collection := fn:concat($resources-collection, "/", $commons-collection-name);
declare variable $sociology-collection := fn:concat($commons-collection, "/", $samples-collection-name, "/", $sociology-collection-name);
declare variable $exist-db-collection := fn:concat($commons-collection, "/", $samples-collection-name, "/", $exist-db-collection-name);
(:declare variable $mads-collection := fn:concat($commons-collection, "/", $mads-collection-name);:)

declare function local:mkcol-recursive($collection, $components) {
    if (exists($components)) then
        let $newColl := concat($collection, "/", $components[1])
        return (
            xdb:create-collection($collection, $components[1]),
            local:mkcol-recursive($newColl, subsequence($components, 2))
        )
    else
        ()
};

(: Helper function to recursively create a collection hierarchy. :)
declare function local:mkcol($collection, $path) {
    local:mkcol-recursive($collection, tokenize($path, "/"))
};

declare function local:set-collection-resource-permissions($collection as xs:string, $owner as xs:string, $group as xs:string, $permissions as xs:int) {
    for $resource in xdb:get-child-resources($collection) return
        xdb:set-resource-permissions($collection, $resource, $owner, $group, $permissions)
};

declare function local:strip-prefix($str as xs:string, $prefix as xs:string) as xs:string? {
    fn:replace($str, $prefix, "")
};


util:log($log-level, "Script: Running pre-install script ..."),
util:log($log-level, fn:concat("...Script: using $home '", $home, "'")),
util:log($log-level, fn:concat("...Script: using $dir '", $dir, "'")),

(: Create users and groups :)
util:log($log-level, fn:concat("Security: Creating user '", $biblio-admin-user, "' and group '", $biblio-users-group, "' ...")),
    if (xdb:group-exists($biblio-users-group)) then ()
    else xdb:create-group($biblio-users-group),
    if (xdb:exists-user($biblio-admin-user)) then ()
    else xdb:create-user($biblio-admin-user, $biblio-admin-user, $biblio-users-group, ()),
util:log($log-level, "Security: Done."),

(: Load collection.xconf documents :)
util:log($log-level, "Config: Loading collection configuration ..."),
    local:mkcol($config-collection, $editor-code-tables-collection),
    xdb:store-files-from-pattern(fn:concat($config-collection, $editor-code-tables-collection), $dir, "data/xconf/code-tables/*.xconf"),
    local:mkcol($config-collection, $resources-collection),
    xdb:store-files-from-pattern(fn:concat($config-collection, $resources-collection), $dir, "data/xconf/resources/*.xconf"),
    (:local:mkcol($config-collection, $mads-collection),:)
    (:xdb:store-files-from-pattern(fn:concat($config-collection, $mads-collection), $dir, "data/xconf/mads/*.xconf"),:) 
util:log($log-level, "Config: Done."),


(: Create temp collection :)
util:log($log-level, fn:concat("Config: Creating temp collection '", $temp-collection, "'...")),
    local:mkcol($db-root, local:strip-prefix($temp-collection, fn:concat($db-root, "/"))),
    xdb:set-collection-permissions($temp-collection, $biblio-admin-user, $biblio-users-group, util:base-to-integer(0770, 8)),
util:log($log-level, "Config: Done."),


(: Create resources/commons :)
util:log($log-level, fn:concat("Config: Creating commons collection '", $commons-collection, "'...")),
    for $col in ($sociology-collection, $exist-db-collection(:, $mads-collection:)) return
    (
        local:mkcol($db-root, local:strip-prefix($col, fn:concat($db-root, "/"))),
        xdb:set-collection-permissions($col, $biblio-admin-user, $biblio-users-group, util:base-to-integer(0755, 8))
    ),
    util:log($log-level, "...Config: Uploading samples data..."),
        xdb:store-files-from-pattern($sociology-collection, $dir, "data/sociology/*.xml"),
        local:set-collection-resource-permissions($sociology-collection, $biblio-admin-user, $biblio-users-group, util:base-to-integer(0755, 8)),
        xdb:store-files-from-pattern($exist-db-collection, $dir, "data/eXist/*.xml"),
        local:set-collection-resource-permissions($exist-db-collection, $biblio-admin-user, $biblio-users-group, util:base-to-integer(0755, 8)),
    util:log($log-level, "...Config: Done Uploading samples data."),
util:log($log-level, "Config: Done."), 


(: Create users and groups collections :)
util:log($log-level, fn:concat("Config: Creating users '", $users-collection, "' and groups '", $groups-collection, "' collections")),
    local:mkcol($db-root, $resources-collection-name),
    for $col in ($users-collection, $groups-collection) return
    (
        local:mkcol($db-root, local:strip-prefix($col, fn:concat($db-root, "/"))),
        xdb:set-collection-permissions($col, $biblio-admin-user, $biblio-users-group, util:base-to-integer(0771, 8))
    ),
util:log($log-level, "Config: Done."),

util:log($log-level, "Script: Done.")
