xquery version "3.0";

import module namespace reports = "http://hra.uni-heidelberg.de/ns/tamboti/reports" at "../../reports/reports.xqm";

<result>
    {
        for $item in $reports:items-with-duplicated-aces
        let $actual-item := map:get($item, "item")
        let $item-type := $actual-item/local-name()
        let $duplicated-whos := map:get($item, "duplicated-whos")
        let $item-path := xs:anyURI($actual-item/@path)
        return
            (
                element {$item-type} {
                    attribute duplicated-aces {count($duplicated-whos)},
                    attribute path {$item-path},
                    for $duplicated-who in $duplicated-whos
                    let $duplicated-aces := reverse($actual-item//sm:ace[@who = $duplicated-who][position() > 1])
                    return
                        <ace>
                            {
                                (
                                    for $duplicated-ace in $duplicated-aces
                                    return
                                        (
                                            $duplicated-ace,
                                            try {
                                                sm:remove-ace($item-path, xs:int(data($duplicated-ace/@index)))
                                            } catch * {
                                                <error>{"Error '" || $err:description || "' at: " || $duplicated-ace}</error>
                                            }
                                        )
                                )
                            }
                        </ace>
                }
            )
    }
</result>
