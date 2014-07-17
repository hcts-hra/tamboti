xquery version "3.0";

import module namespace config = "http://exist-db.org/mods/config" at "../modules/config.xqm";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:method "html5";
declare option output:media-type "text/html";

declare function local:get-aces($collection-path as xs:anyURI) as element()* {
    (
        try {
            <collection path="{$collection-path}">{sm:get-permissions($collection-path)/*}</collection>
        } catch * {
            <error>{"Error at: " || $collection-path}</error>
        },
        for $subcollection in xmldb:get-child-collections($collection-path)
        return local:get-aces(xs:anyURI($collection-path || "/" || $subcollection)),
        for $resource in xmldb:get-child-resources($collection-path)
        let $resource-path := xs:anyURI($collection-path || "/" || $resource)
        return
            try {
                <resource path="{$resource-path}">{sm:get-permissions($resource-path)/*}</resource>
            } catch * {
                <error>{"Error at: " || $resource-path}</error>
            }            
            
            
    )
};

let $legal-groups := ($config:biblio-users-group)

let $local-users := sm:get-group-members($config:biblio-users-group)

let $orphaned-users := ("a02", "am370", "anna.grasskamp", "anna.vinogradova", "ce372", "chenying.pi", "christiane.brosius", "co402", "daniel.stumm", "eric.decker", "f8h", "fx400", "g05", "ge414", "gf395", "hg7", "hx405", "j0k", "j35", "jens.petersen", "johannes.alisch", "kd416", "kjc_hyperimage", "labuerr5", "lucie.bernroider", "m2b", "m5c", "marnold1", "matthias.arnold", "melissa.butcher", "mw385", "mz404", "nina.nessel", "qd418", "rg399", "roos.gerritsen", "simon.gruening", "swithan3", "ty403", "ud011", "ug400", "v4a", "vk383", "vu067", "wg397", "wmeier", "wu399")

let $permission-elements :=
    for $subcollection in xmldb:get-child-collections($config:users-collection)
        return local:get-aces(xs:anyURI($config:users-collection || "/" || $subcollection))

let $permission-elements-number := count($permission-elements//sm:permission)

let $items-with-different-mode := 
    for $item in $permission-elements
    return
        if ($item/sm:permission/@mode = ($config:resource-mode, $config:collection-mode))
        then ()
        else $item
        
let $items-with-different-owner := 
    for $item in $permission-elements
    let $user-name := substring-after($item/@path, $config:users-collection || "/")
    let $user-name := if (contains($user-name, "/")) then (substring-before($user-name, "/")) else ($user-name)
    return
        if ($item/sm:permission[@owner != $user-name])
        then $item
        else ()
        
let $items-with-duplicated-aces := 
    for $item in $permission-elements
    let $whos := $item/*[1]//sm:ace/@who/string()
    let $duplicated-whos := $whos[index-of($whos, .)[2]]
    return
        if (count($duplicated-whos) gt 0)
        then map{
            "item" := $item,
            "duplicated-whos" := $duplicated-whos
        }
        else ()    


return
    <html>
        <head>
            <title/>
            <style type="text/css">
                .item-name {{
                    color: green;
                    font-weight: bold;
                }}
                .item-attribute {{
                    color: red;
                    font-weight: bold;                    
                }}
            </style>
        </head>
        <body>
            <h2>Data inconsistencies</h2>
            <ul>
                <li><a href="#different-group">Different group</a></li>
                <li><a href="#different-mode">Different mode</a></li>
                <li><a href="#different-owner">Different owner</a></li>
                <li><a href="#duplicated-aces">Duplicated ACEs</a></li>
            </ul>
            {
                let $items := $permission-elements//sm:permission[@group != $legal-groups]/parent::*
                return
                    (
                        <h3 id="different-group">Different group (there are {count($items)} of {$permission-elements-number} items)</h3>,
                        <h5>Groups presented: {string-join(distinct-values($permission-elements//sm:permission/@group), ', ')}</h5>,
                        for $item in $items
                        let $item-type := $item/local-name()                        
                        return
                            (
                                "The ",
                                $item-type,
                                " '",
                                <span class="item-name">{$item/@path/string()}</span>,
                                "' is having the owner '",
                                <span class="item-name">{$item/*[1]/@owner/string()}</span>,
                                "' and the group '",
                                <span class="item-attribute">{$item/*[1]/@group/string()}</span>,
                                "'.",
                                <br />
                            )
                    )
            }
            {
                    (
                        <h3 id="different-mode">Different mode (there are {count($items-with-different-mode)} of {$permission-elements-number} items)</h3>,
                        for $item in $items-with-different-mode
                        let $item-type := $item/local-name()
                        return
                            (
                                "The ",
                                $item-type,
                                " '",
                                <span class="item-name">{$item/@path/string()}</span>,
                                "' is having the mode '",
                                <span class="item-attribute">{$item/*[1]/@mode/string()}</span>,
                                "'.",
                                <br />
                            )
                    )
            }
            {
                    (
                        <h3 id="different-owner">Different owner (there are {count($items-with-different-owner)} of {$permission-elements-number} items)</h3>,
                        for $item in $items-with-different-owner
                        let $item-type := $item/local-name()                        
                        return
                            (
                                "The ",
                                $item-type,
                                " '",
                                <span class="item-name">{$item/@path/string()}</span>,
                                "' is having the owner '",
                                <span class="item-attribute">{$item/*[1]/@owner/string()}</span>,
                                "'.",
                                <br />
                            )
                    )
            }
            {
                    (
                        <h3 id="duplicated-aces">Duplicated ACEs (there are {count($items-with-duplicated-aces)} of {$permission-elements-number} items)</h3>,
                        for $item in $items-with-duplicated-aces
                        let $actual-item := map:get($item, "item")
                        return
                            (
                                "The item '",
                                <span class="item-name">{$actual-item/@path/string()}</span>,
                                "' is having the ACE with recipient '",
                                <span class="item-attribute">{map:get($item, "duplicated-whos")}</span>,
                                "' inserted multiple times.",
                                <br />
                            )                            
                    )
            }            
        </body>
    </html>
