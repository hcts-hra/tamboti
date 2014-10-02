xquery version "3.0";

module namespace config = "http://exist-db.org/mods/config";

(: 
    Determine the application root collection from the current module load path.
:)
declare variable $config:app-root := 
    let $rawPath := system:get-module-load-path()
    let $modulePath :=
        (: strip the xmldb: part :)
        if (starts-with($rawPath, "xmldb:exist://")) then
            if (starts-with($rawPath, "xmldb:exist://embedded-eXist-server")) then
                substring($rawPath, 36)
            else
                substring($rawPath, 15)
        else
            $rawPath
    return
        substring-before($modulePath, "/modules")
;

declare variable $config:app-id := "tamboti";
(: this will replace $config:app-id when theming will be solved :)
declare variable $config:actual-app-id := "tamboti";

(:~ Biblio security - admin user and users group :)
declare variable $config:biblio-admin-user := "editor";
declare variable $config:biblio-users-group := "biblio.users";
declare variable $config:special-users := ("admin", $config:biblio-admin-user, "guest", "testuser1", "testuser2", "testuser3", "heraeditor", "vma-editor", "freizo-editor");

(:~ Various permissions :)
declare variable $config:commons-collections-permissions := "rwxrwxr-x";
declare variable $config:resource-mode := "rw-------";
declare variable $config:collection-mode := "rwxr-xr-x";

declare variable $config:mods-root := "/resources";
declare variable $config:mods-root-minus-temp := ("/resources/commons","/resources/users", "/resources/groups");
declare variable $config:mods-commons := fn:concat($config:mods-root, "/commons");
declare variable $config:content-root := fn:concat($config:mods-root, "/commons");
declare variable $config:url-image-size := "256";

declare variable $config:search-app-root := concat($config:app-root, "/modules/search");
declare variable $config:edit-app-root := concat($config:app-root, "/modules/edit");

declare variable $config:force-lower-case-usernames as xs:boolean := true();
declare variable $config:enforced-realm-id := "ad.uni-heidelberg.de";

declare variable $config:users-collection := xs:anyURI(fn:concat($config:mods-root, "/users"));
declare variable $config:groups-collection := fn:concat($config:mods-root, "/groups");

declare variable $config:mods-temp-collection := "/resources/temp";
declare variable $config:mads-collection := "/db/resources/mads";

declare variable $config:themes := concat($config:app-root, "/themes");
declare variable $config:theme-config := concat($config:themes, "/configuration.xml");

declare variable $config:resources := concat($config:app-root, "/resources");
declare variable $config:images := concat($config:app-root, "/resources/images");

(: If the user has not specified a query, should he see the entire collection contents?
 : Set to true() if a query must be specified, false() to list the entire collection.
 : On large databases, false() will most likely lead to problems.
 :)
declare variable $config:require-query := true();

(: email invitation settings :)
declare variable $config:send-notification-emails := false();
declare variable $config:smtp-server := "smtp.yourdomain.com";
declare variable $config:smtp-from-address := "exist@yourdomain.com";

(:~ Credentials for the dba admin user :)
declare variable $config:dba-credentials := ("admin", "");

declare variable $config:allow-origin := "";

(:~ 
: Function hook which allows you to modify the username of the user
: before they are authenticated.
: Allows you to force a realm id etc.
: 
: @param username The username as entered by the user
: @return the modified username which will be used for authentication
:)
declare function config:rewrite-username($username as xs:string) as xs:string {
    
    let $username := if($config:force-lower-case-usernames)then
        fn:lower-case($username)
    else
        $username
    return
    
        if(fn:ends-with(fn:lower-case($username), fn:concat("@", $config:enforced-realm-id)) or fn:lower-case($username) = $config:special-users) then
            $username
        else
            fn:concat($username, "@", $config:enforced-realm-id)
};

declare variable $config:max-inactive-interval-in-minutes := 480;
