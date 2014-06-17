xquery version "3.0";

(:let $col-name := "/db/resources/commons/JSIT":)
let $col-name := "/db/resources/users/vma-editor/VMA-Collection"

(:let $col-name := request:get-attribute("col"):)
let $showRes := true()

let $col := xmldb:get-child-collections($col-name)
return
    <result>
        {
            (
                sm:get-permissions(xs:anyURI($col-name)),
                    for $scol in $col
                        return
                            <col name="{$scol}">
                                <colPermissions>
                                {
                                    sm:get-permissions(xs:anyURI($col-name || "/" || $scol))
                                }
                                </colPermissions>
                                {
                                if ($showRes) then
                                    <resources>
                                        {
                                            for $res in xmldb:get-child-resources($col-name || "/" || $scol)
                                                return
                                                    <res name="{$col-name || "/" || $scol || "/" || $res}">
                                                        {
                                                            sm:get-permissions(xs:anyURI($col-name || "/" || $scol || "/" || $res))
                                                        }
                                                    </res>
                                        }
                                    </resources>
                                else
                                    ""
            
                                }
                            </col>
            )
        }
    </result>