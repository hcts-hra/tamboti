xquery version "3.0";

import module namespace config = "http://exist-db.org/mods/config" at "../../modules/config.xqm";

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

(:let $col-name := request:get-attribute("col"):)
(:let $showRes := true():)

(:return:)
    local:collection-permissions($config:users-collection || "/", "vma-editor", false())
