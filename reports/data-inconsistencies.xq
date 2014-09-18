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
    let $item-path := $item/@path
    let $username :=
        if (contains($item-path, $config:users-collection))
        then
            let $raw-username := substring-after($item/@path, $config:users-collection || "/")
            return if (contains($raw-username, "/")) then (substring-before($raw-username, "/")) else ($raw-username)
        else $reports:users-for-public-resources
        
    return
        if ($item/sm:permission[not(contains($username, @owner))])
        then $item
        else ()
        
let $items-with-different-group-number := count($items-with-different-group)
let $items-with-different-mode-number := count($items-with-different-mode)
let $items-with-different-owner-number := count($items-with-different-owner)
let $items-with-duplicated-aces-number := count($reports:items-with-duplicated-aces)
let $items-with-orphaned-users-number := count($reports:items-with-orphaned-users)
let $items-with-encoded-at-sign-number := count($reports:items-with-encoded-at-sign)

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
            <h2>Data inconsistencies for collections {string-join(for $collection-path in $reports:collections return "'" || $collection-path || "'", ', ')}</h2>
            <ul>
                <li><a href="#different-group">Different group</a> ({$items-with-different-group-number} items)</li>
                <li><a href="#different-mode">Different mode</a> ({$items-with-different-mode-number} items)</li>
                <li><a href="#different-owner">Different owner</a> ({$items-with-different-owner-number} items)</li>
                <li><a href="#duplicated-aces">Duplicated ACEs</a> ({$items-with-duplicated-aces-number} items)</li>
                <li><a href="#orphaned-users">Orphaned usernames</a> ({$items-with-orphaned-users-number} items)</li>
                <li><a href="#encoded-at-sign">Encoded at sign</a> ({$items-with-encoded-at-sign-number} items)</li>
            </ul>
            {
                (
                    <h3 id="different-group">Different group (there are {$items-with-different-group-number} of {$reports:permission-elements-number} items)</h3>
                    ,
                    <h5>Existing groups: {string-join(distinct-values($reports:permission-elements//sm:permission/@group), ', ')}</h5>
                    ,
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
                        <h3 id="different-mode">Different mode (there are {$items-with-different-mode-number} of {$reports:permission-elements-number} items)</h3>
                        ,
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
                        <h3 id="different-owner">Different owner (there are {$items-with-different-owner-number} of {$reports:permission-elements-number} items)</h3>
                        ,
                        for $collection-path in $reports:collections
                        return <h5>Existing owners for collection {$collection-path}: {string-join(distinct-values(reports:get-aces(xs:anyURI($collection-path))//sm:permission/@owner), ', ')}.</h5>
                        ,
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
                        <h3 id="duplicated-aces">Duplicated ACEs (there are {$items-with-duplicated-aces-number} of {$reports:permission-elements-number} items)</h3>
                        ,
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
                        <h3 id="orphaned-users">Orpahed usernames as owners (there are {$items-with-orphaned-users-number} of {$reports:permission-elements-number} items)</h3>
                        ,
                        <h5>Existing orphaned user accounts ({count($reports:orphaned-users)}): {string-join($reports:orphaned-users, ', ')}</h5>
                        ,
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
                        <h3 id="encoded-at-sign">Encoded at sign (there are {$items-with-encoded-at-sign-number} of {$reports:permission-elements-number} items)</h3>
                        ,
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
