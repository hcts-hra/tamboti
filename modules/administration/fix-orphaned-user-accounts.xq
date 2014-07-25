xquery version "3.0";

import module namespace reports = "http://hra.uni-heidelberg.de/ns/tamboti/reports" at "../../reports/reports.xqm";
import module namespace tamboti-utils = "http://hra.uni-heidelberg.de/ns/tamboti/utils" at "../utils/utils.xqm";

<result>
    {
        for $item in $reports:items-with-orphaned-users
        let $actual-item := map:get($item, "item")
        let $item-type := $actual-item/local-name()
        let $orphaned-username := map:get($item, "orphaned-username")
        let $item-path := xs:anyURI($actual-item/@path)
        return
            (
                element {$item-type} {
                    attribute orphaned-username {$orphaned-username},
                    attribute path {$item-path},
                    for $ace in $actual-item//sm:ace[@who = $orphaned-username]
                    let $index := $ace/@index
                    let $who := tamboti-utils:get-username-from-path($item-path)
                    let $access_type := if ($ace/@access_type = 'ALLOWED') then true() else false()
                    let $mode := $ace/@mode
                    return
                        <ace>
                            {
                                sm:remove-ace($item-path, $index),
                                sm:insert-user-ace($item-path, $index, $who, $access_type, $mode),
                                $actual-item
                            }
                        </ace>
                }
            )
    }
</result>
