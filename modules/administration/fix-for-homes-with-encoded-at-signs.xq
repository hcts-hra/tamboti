xquery version "3.0";

let $col := xs:anyURI("/resources/users")

return
<result>
    {
        for $subcol in xmldb:get-child-collections($col)
            return 
                if (contains($subcol, "@")) then
                    if (xmldb:collection-available(xmldb:encode-uri($col || "/" || $subcol))) then
                        let $new-col := xmldb:create-collection(xmldb:encode-uri($col), xmldb:encode-uri($subcol))
                        let $chown := sm:chown($new-col, xmldb:get-owner($col || "/" || $subcol))
                        let $chgrp := sm:chgrp($new-col, xmldb:get-group($col || "/" || $subcol))
                        let $chmod := sm:chmod($new-col, "rwxr-xr-x")
                        (: copy move all collections in unencoded-@-homefolder to encoded one :)
        (:                xmldb:remove($col || "/" || $subcol):)
                        let $moved-collections :=
                            for $subsubcol in xmldb:get-child-collections($col || "/" || $subcol)
                                return
        (:                                xmldb:encode-uri($col || "/" || $subcol || "/" || $subsubcol):)
                                    if(xmldb:move(xs:anyURI($col || "/" || $subcol || "/" || $subsubcol), xmldb:encode-uri($col || "/" || $subcol))) then
                                        <success>{xmldb:encode-uri($col || "/" || $subcol || "/" || $subsubcol)}</success>
                                    else
                                        <failed>{xmldb:encode-uri($col || "/" || $subcol || "/" || $subsubcol)}</failed>
    (:                    let $delete-unencoded:)
                        let $moved-resources :=
                            for $res in xmldb:get-child-resources($col || "/" || $subcol)
                                return
        (:                                xmldb:encode-uri($col || "/" || $subcol || "/" || $subsubcol):)
                                    if(xmldb:move($col || "/" || $subcol, xmldb:encode-uri($col || "/" || $subcol), $res)) then
                                        <success>{xmldb:encode-uri($col || "/" || $subcol || "/" || $res)}</success>
                                    else
                                        <failed>{xmldb:encode-uri($col || "/" || $subcol || "/" || $res)}</failed>
    (:                    let $delete-unencoded:)
                        return
                            <found>
                                <originalName>{$col || "/" || $subcol}</originalName>
                                <newName>{$new-col}</newName>
                                    <movedCollections>
                                        {
                                            $moved-collections
                                        }
                                    </movedCollections>
                                    <movedResources>
                                        {
                                            $moved-resources
                                        }
                                    </movedResources>
                            </found>
                    else
                        <renamed>
                            {
                                xmldb:rename(xs:anyURI($col || "/" || $subcol), xmldb:encode-uri($subcol)),
                                <from>
                                    {
                                        xs:anyURI($col || "/" || $subcol)
                                    }
                                </from>,
                                <to>
                                    {
                                        xmldb:encode-uri($subcol)
                                    }
                                </to>
                            }
                        </renamed>
                else
                    ()
    }
</result>