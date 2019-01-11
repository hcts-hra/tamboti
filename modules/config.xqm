xquery version "3.1";

module namespace config = "http://exist-db.org/mods/config";

(:~ Credentials for the dba admin user :)
declare variable $config:dba-credentials := ("admin", "");
declare variable $config:enforced-realm-id := "ldap-server.yourdomain.com";


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

declare variable $config:exist-context := request:get-context-path();
declare variable $config:web-context := '/apps';

declare variable $config:app-id := "tamboti";
(: this will replace $config:app-id when theming will be solved :)
declare variable $config:actual-app-id := "tamboti";
declare variable $config:app-version := "${project.version}";

declare variable $config:db-path-to-app := concat('/apps/', $config:actual-app-id);
declare variable $config:web-path-to-app := $config:exist-context || $config:web-context || "/" || $config:actual-app-id;

(:~ Biblio security - admin user and users group :)
declare variable $config:biblio-admin-user := "editor";
declare variable $config:biblio-users-group := "biblio.users";
declare variable $config:users-login-blacklist := ("admin", "guest", "SYSTEM");

(:~ Various permissions :)
declare variable $config:resource-mode := "rw-------";
declare variable $config:collection-mode := "rwx------";
declare variable $config:temp-collection-mode := "rwxrwxrwx";
declare variable $config:temp-resource-mode := "rwx------";
declare variable $config:public-collection-mode := "rwxr-xr-x";
declare variable $config:public-resource-mode := "rw-r--r--";

(: Sharing permission definition :)
declare variable $config:sharing-permissions := map {
        "readonly" := map {"rank" := 1, "name" := "Read only",  "collection" := "r-x", "resource" := "r--"},
(:        "write" := map {"rank" := 2, "name" := "Write", "collection" := "r-x", "resource" := "rw-"},:)
        "full" := map {"rank" := 3, "name" := "Full Access", "collection" := "rwx", "resource" := "rwx"}
};

declare variable $config:data-collection-name := "data";
declare variable $config:content-root := "/" || $config:data-collection-name || "/";
declare variable $config:mods-root := "/" || $config:data-collection-name;
declare variable $config:mods-commons := $config:content-root || "commons";
declare variable $config:users-collection := xs:anyURI($config:content-root || "users");
declare variable $config:mods-root-minus-temp := ($config:mods-commons, $config:users-collection);

declare variable $config:url-image-size := "256";

(: modules :)
declare variable $config:db-path-to-modules := $config:db-path-to-app || "/modules";

declare variable $config:search-app-root := concat($config:app-root, "/modules/search");

(: frameworks :)
declare variable $config:web-path-to-tei-hra-framework := $config:web-path-to-app || "/frameworks/tei-hra";

(: APIs:)
declare variable $config:web-path-to-apis := $config:web-path-to-app || "/api";
declare variable $config:web-path-to-editors-apis := $config:web-path-to-apis || "/editors";
declare variable $config:web-path-to-mods-editor-api := $config:web-path-to-editors-apis || "/hra-mods-editor";
declare variable $config:web-path-to-tei-editor-api := $config:web-path-to-editors-apis || "/tei-editor";

(: DB paths to the default editors :)
declare variable $config:db-path-to-mods-editor-home := $config:web-context || "/hra-mods-editor";
declare variable $config:web-path-to-mods-editor-home := $config:exist-context || $config:web-context || "/hra-mods-editor";
declare variable $config:web-path-to-tei-editor-home := $config:exist-context || $config:web-context || "/teian";
declare variable $config:db-path-to-mods-editor := $config:db-path-to-mods-editor-home || "/index.xq";
declare variable $config:web-path-to-mods-editor := $config:web-path-to-mods-editor-home || "/index.xq";
declare variable $config:web-path-to-tei-editor := $config:web-path-to-tei-editor-home || "/core/teian.html";

declare variable $config:canvas-editor-path := 
    if (repo:list() = "http://hra.uni-heidelberg.de/ns/annycan") then
        concat(request:get-context-path(), "/apps/svgedit/index.html")
    else
        ();

declare variable $config:force-lower-case-usernames as xs:boolean := true();

declare variable $config:mads-collection := "/db/" || $config:mods-root || "/mads";

declare variable $config:themes := concat($config:app-root, "/themes");

declare variable $config:images-subcollection := ("VRA_images");

declare variable $config:app-http-root := "/exist" || substring-after($config:app-root, "/db");

(: email invitation settings :)
declare variable $config:send-notification-emails := false();
declare variable $config:smtp-server := "smtp.yourdomain.com";
declare variable $config:smtp-from-address := "exist@yourdomain.com";

(: MongoDB Setup:)
declare variable $config:mongo-url := "mongodb://localhost";
declare variable $config:mongo-database := "tamboti";
declare variable $config:mongo-anno-collection := "annotations";

(:~ 
: Function hook which allows you to modify the username of the user
: before they are authenticated.
: Allows you to force a realm id etc.
: 
: @param username The username as entered by the user
: @return the modified username which will be used for authentication
:)
declare function config:rewrite-username($username as xs:string) as xs:string {
    
    let $username := 
        if ($config:force-lower-case-usernames) then
            fn:lower-case($username)
        else
            $username
    return
        (: if @ad is spared in login formular, check if ad user exists and concat @ with ldap-real, if not use $username without  :)
        if (not(fn:contains($username, "@")) and xmldb:exists-user($username || "@" || $config:enforced-realm-id)) then
            $username || "@" || $config:enforced-realm-id
        else
            $username
};

declare variable $config:max-inactive-interval-in-minutes := 480;

declare variable $config:error-message-before-link := "An error occurred when displaying this record. In order to have this error fixed, please send us an email identifying the record by clicking on the following link: ";
declare variable $config:error-message-after-link := " Clicking on the link will open your default email client.";
declare variable $config:error-message-href := " mailto:hra@asia-europe.uni-heidelberg.de?Subject=Tamboti%20Display%20Problem&amp;body=Fix%20display%20of%20record%20";
declare variable $config:error-message-link-text := "Send email.";

(: paginator component :)
declare variable $config:number-of-items-per-page := 20;
