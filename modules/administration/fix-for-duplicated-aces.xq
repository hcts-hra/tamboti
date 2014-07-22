xquery version "3.0";

import module namespace reports = "http://hra.uni-heidelberg.de/ns/tamboti/reports" at "../../reports/reports.xqm";

let $items-with-duplicated-aces := 
    for $item in $reports:permission-elements
    let $who-attribute-values := $item/*[1]//sm:ace/@who/string()
    let $multiplicated-who-attribute-values := count($who-attribute-values[index-of($who-attribute-values, .)[2]])
    return 
        if ($multiplicated-who-attribute-values gt 0)
        then 
            for $i in (1, $multiplicated-who-attribute-values - 1)
            return $i
        else () 
        
return
    <result>
        {
            for $item in $reports:items-with-duplicated-aces
            let $actual-item := map:get($item, "item")
            let $item-type := $actual-item/local-name()
            let $duplicated-whos := map:get($item, "duplicated-whos")
            let $item-path := xs:anyURI($actual-item/@path)
            return
                (
        (:            $actual-item,:)
                    element {$item-type} {
                        attribute duplicated-aces {count($duplicated-whos)},
                        attribute path {$item-path},
                        for $duplicated-who in $duplicated-whos
                        let $duplicated-aces := $actual-item//sm:ace[@who = $duplicated-who]
                        return
                            <ace>
                                {
                                    (
                                        for $duplicated-ace in $duplicated-aces[position() > 1]
                                        return
                                            (
                                                $duplicated-ace,
                                                try {
                                                    sm:remove-ace($item-path, data($duplicated-ace/@index))
                                                } catch * {
                                                    <error>{"Error at: " || $duplicated-ace}</error>
                                                }
                                            )
                                    )
                                }
                            </ace>
                    }
                )
        }
    </result>