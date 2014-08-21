module namespace theme="http://exist-db.org/xquery/biblio/theme";

import module namespace config="http://exist-db.org/mods/config" at "config.xqm";

declare variable $theme:error := QName("http://exist-db.org/xquery/tamboti", "error");

(:~
 : Locate the specified resource for the selected theme. The theme is determined
 : from the URL prefix. If a resource cannot be found within the theme collection,
 : the function falls back to the theme "default" and tries to locate the resource
 : there.
 :
 : @param $prefix the URL prefix as passed in from the controller
 : @param $root the db root of this app as passed in from the controller
 : @param $resource path to a resource in the theme collection
 : @return resolved path to the resource to be used for forwarding in controller
 :)

declare function theme:resolve-uri($prefix as xs:string?, $root as xs:string, $resource as xs:string) {
    let $theme := theme:theme-for-resource($prefix, $resource)
    let $path :=
        concat(
            substring-after($config:themes, theme:normalize-path($root)),
            "/", $theme, "/",
            $resource
        )
    (:let $log := util:log("DEBUG", ("resolved theme path: ", $path)):)
    return
        $path
};

(:~
 : Locate the specified resource for the selected theme. The theme is determined
 : from the URL prefix. If a resource cannot be found within the theme collection,
 : the function falls back to the theme "default" and tries to locate the resource
 : there.
 :
 : @param $prefix the URL prefix as passed in from the controller
 : @param $root the db root of this app as passed in from the controller
 : @param $resource path to a resource in the theme collection
 : @return resolved path to the resource to be used for forwarding in controller
 :)

declare function theme:resolve($prefix as xs:string?, $root as xs:string, $resource as xs:string) {
    let $theme := theme:theme-for-resource($prefix, $resource)
    let $path :=
        concat(
            $config:themes,
            "/", $theme, "/",
            $resource
        )
    (:let $log := util:log("DEBUG", ("resolved theme path: ", $path, " prefix: ", $prefix, " root: ", $root,
        " $config:themes: ", $config:themes)):)
    return
        $path
};

(:~
 : Locate the element with the given id attribute value for the selected theme. The theme is determined
 : from the URL prefix. If a resource cannot be found within the theme collection,
 : the function falls back to the theme "default" and tries to locate the resource
 : there.
 :
 : @param $prefix the URL prefix as passed in from the controller
 : @param $root the db root of this app as passed in from the controller
 : @param $resource path to a resource in the theme collection
 : @return resolved path to the resource to be used for forwarding in controller
 :)

declare function theme:resolve-by-id($root as xs:string, $id as xs:string) {
    let $prefix := request:get-attribute("exist:prefix")
    return
        if (empty($prefix)) then
            error(QName("http://exist-db.org/xquery/tamboti", "error"), ("No prefix set!"))
        else
            (:let $log := util:log("DEBUG", ("Checking for id ", $id, " in ", $root)):)
            let $theme := theme:check-for-id($id, theme:theme-for-prefix($prefix))
            let $path :=
                concat(
                    $config:themes, "/", $theme
                )
            (:let $log := util:log("DEBUG", ("resolved theme path: ", $path)):)
            return
                collection($path)//*[@id = $id]
};

(:~
 :
 :)
declare function theme:get-path() {
    concat(substring-after($config:themes, "/db"), "/default")
};

(:~
 : Lookup the prefix and return the name of theme to be applied
 :)
declare function theme:theme-for-prefix($prefix as xs:string?) {
    if (not($prefix)) then
        "default"
    else
        let $theme :=
            doc($config:theme-config)//map[@path = $prefix]/@theme/string()
        return
            if ($theme) then
                $theme
            else
                "default"
};

declare function theme:get-root() {
    let $prefix := request:get-attribute("exist:prefix")
    return
        if (empty($prefix)) then
            error(QName("http://exist-db.org/xquery/tamboti", "error"), ("No prefix set!"))
        else
            theme:get-root($prefix)
};

declare function theme:get-root($prefix as xs:string?) as xs:string {
    let $theme := theme:theme-for-prefix($prefix)
    return
        if ($theme eq "default") then
            $config:mods-commons
        else
            doc($config:theme-config)//map[@theme = $theme]/@root/string()
};

(:~
 : Determine the theme to use and try to locate the resource. If it does not
 : exist, fall back to the theme "default"
 :)
declare function theme:theme-for-resource($prefix as xs:string, $resource as xs:string) {
    let $theme := theme:theme-for-prefix($prefix)
    return
        theme:check-for($resource, $theme)
};

(:~
 : Check if the resource is available within the theme. If yes, return the
 : theme's name, if not, the default theme "default"
 :)
declare function theme:check-for($resource as xs:string, $theme as xs:string) {
    let $path := concat($config:themes, "/", $theme, "/", $resource)
    return
        if (util:binary-doc-available($path) or doc-available($path)) then
            $theme
        else
            "default"
};

(:~
 : Check if an element with the given id is available within the theme collection. 
 : If yes, return the theme's name, if not, the default theme "default"
 :)
declare function theme:check-for-id($id as xs:string, $theme as xs:string) {
    let $path := concat($config:themes, "/", $theme)
    return
        if (collection($path)//*[@id = $id]) then
            $theme
        else
            "default"
};

(:~
 :
 :)
declare function theme:normalize-path($rawPath as xs:string) {
    if (starts-with($rawPath, "xmldb:exist://")) then
        if (starts-with($rawPath, "xmldb:exist://embedded-eXist-server")) then
            substring($rawPath, 36)
        else
            substring($rawPath, 15)
    else
        $rawPath
};

declare function theme:apply-template($page as element()) {
    let $prefix := request:get-attribute("exist:prefix")
    let $theme := theme:theme-for-resource($prefix, "template.xml")
    let $template := doc(concat($config:themes, "/", $theme, "/template.xml"))
    return
        theme:merge-html($page, $template)
};

declare function theme:merge-html($node, $template) {
    typeswitch ($node)
        case document-node() return
            for $child in $node/node() return theme:merge-html($child, $template)
        case element(head) return
            <head>
                { $node/node(), $template//head/node() }
            </head>
        case element(body) return
            <body>
                {
                    $template//body/div[@id = "template-head"],
                    $node/node(), 
                    $template//body/node() except $template//body/div[@id = "template-head"]
                }
            </body>
        case element() return
            element { node-name($node) } {
                $node/@*, for $child in $node/node() return theme:merge-html($child, $template)
            }
        default return
            $node
};
