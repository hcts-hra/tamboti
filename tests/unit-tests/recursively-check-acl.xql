xquery version "3.0";

declare function local:collection-permissions($col-path, $col, $show-res) {
    <collection name="{$col}">
            <colPermissions>
                {
                    sm:get-permissions(xs:anyURI($col-path || "/" || $col))
                }
            </colPermissions>
            {
                if ($show-res) then
                    <resources>
                        {
                            for $res in xmldb:get-child-resources($col-path || "/" || $col)
                                return
                                    <res name="{$col-path || "/" || $col || "/" || $res}">
                                        {
                                            sm:get-permissions(xs:anyURI($col-path || "/" || $col || "/" || $res))
                                        }
                                    </res>
                        }
                    </resources>
                else
                    ""
            }
            {
                for $scol in xmldb:get-child-collections($col-path || "/" || $col)
                    return
                        local:collection-permissions($col-path || "/" || $col, $scol, $show-res)
            }
    </collection>

};

(:let $col-name := "/db/resources/commons/JSIT":)
(:let $col-name := "/db/resources/users/matthias.guth@ad.uni-heidelberg.de/aaatest":)

(:let $col-name := request:get-attribute("col"):)
(:let $showRes := true():)

(:return:)
    local:collection-permissions("/resources/users/matthias.guth@ad.uni-heidelberg.de", "123123123", true())
