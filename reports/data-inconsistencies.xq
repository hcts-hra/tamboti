xquery version "3.0";

import module namespace reports = "http://hra.uni-heidelberg.de/ns/tamboti/reports" at "reports.xqm";
import module namespace config = "http://exist-db.org/mods/config" at "../modules/config.xqm";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:method "html5";
declare option output:media-type "text/html";

let $legal-groups := ($config:biblio-users-group)

let $items-with-different-group := $reports:permission-elements//sm:permission[@group != $legal-groups]/parent::*
        
let $items-with-different-mode := 
    for $item in $reports:permission-elements
    return
        if ($item/sm:permission/@mode = ($config:resource-mode, $config:collection-mode))
        then ()
        else $item
        
let $items-with-different-owner := 
    for $item in $reports:permission-elements
    let $user-name := substring-after($item/@path, $config:users-collection || "/")
    let $user-name := if (contains($user-name, "/")) then (substring-before($user-name, "/")) else ($user-name)
    return
        if ($item/sm:permission[@owner != $user-name])
        then $item
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
                <li><a href="#orphaned-users">Orphaned usernames</a></li>
                <li><a href="#encoded-at-sign">Encoded at sign</a></li>
            </ul>
            {
                (
                    <h3 id="different-group">Different group (there are {count($items-with-different-group)} of {$reports:permission-elements-number} items)</h3>,
                    <h5>Existing groups: {string-join(distinct-values($reports:permission-elements//sm:permission/@group), ', ')}</h5>,
                    for $item in $items-with-different-group
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
                        <h3 id="different-mode">Different mode (there are {count($items-with-different-mode)} of {$reports:permission-elements-number} items)</h3>,
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
                        <h3 id="different-owner">Different owner (there are {count($items-with-different-owner)} of {$reports:permission-elements-number} items)</h3>,
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
                        <h3 id="duplicated-aces">Duplicated ACEs (there are {count($reports:items-with-duplicated-aces)} of {$reports:permission-elements-number} items)</h3>,
                        for $item in $reports:items-with-duplicated-aces
                        let $actual-item := map:get($item, "item")
                        let $item-type := $actual-item/local-name()  
                        return
                            (
                                "The ",
                                $item-type,
                                " '",
                                <span class="item-name">{$actual-item/@path/string()}</span>,
                                "' is having the ACE with recipient '",
                                <span class="item-attribute">{map:get($item, "duplicated-whos")}</span>,
                                "' inserted multiple times.",
                                <br />
                            )                            
                    )
            }
            {
                    (
                        <h3 id="orphaned-users">Orpahed usernames as owners (there are {count($reports:items-with-orphaned-users)} of {$reports:permission-elements-number} items)</h3>,
                        <h5>Existing orphaned user accounts ({count($reports:orphaned-users)}): {string-join($reports:orphaned-users, ', ')}</h5>,
                        for $item in $reports:items-with-orphaned-users
                        let $actual-item := map:get($item, "item")
                        let $item-type := $actual-item/local-name()  
                        return
                            (
                                "The ",
                                $item-type,
                                " '",
                                <span class="item-name">{$actual-item/@path/string()}</span>,
                                "' is having the orphaned username '",
                                <span class="item-attribute">{map:get($item, "orphaned-username")}</span>,
                                "' as owner.",
                                <br />
                            )                            
                    )
            }

            {
                    (
                        <h3 id="encoded-at-sign">Encoded at sign (there are {count($reports:items-with-encoded-at-sign)} of {$reports:permission-elements-number} items)</h3>,
                        for $item in $reports:items-with-encoded-at-sign
                        let $item-type := $item/local-name()  
                        return
                            (
                                "The ",
                                $item-type,
                                " '",
                                <span class="item-name">{$item/@path/string()}</span>,
                                "' is having encoded at sign in name.",
                                <br />
                            )                            
                    )
            }            
        </body>
    </html>
