xquery version "3.0";

let $collection := xs:anyURI("/db/resources/users/editor/new")
let $set-perms := sm:chmod($collection, "rwx------")
let $get-perms-1 := sm:get-permissions($collection)
let $set-ace := sm:add-user-ace($collection, "vma-editor", true(), "rwx")
let $get-perms-2 := sm:get-permissions($collection)
let $list-child-collections := system:as-user("vma-editor", "Edit4VMA!", xmldb:get-child-collections($collection))

return
    (
    <result>
        <permsissions-after-setting-perms>{$get-perms-1}</permsissions-after-setting-perms>
        <permsissions-after-setting-ace>{$get-perms-2}</permsissions-after-setting-ace>
    </result>,
    <child-collections>{$list-child-collections}</child-collections>,
    if (count(sm:get-permissions($collection)//sm:ace) > 0) then (sm:remove-ace($collection, 0)) else ()
    )