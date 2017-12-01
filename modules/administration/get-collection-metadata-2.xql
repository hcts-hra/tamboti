xquery version "3.1";

declare namespace file = "http://exist-db.org/xquery/file";
declare namespace contents = "http://exist.sourceforge.net/NS/exist";

declare function local:date-from-dateTime($date-time) {
    format-dateTime($date-time, "[Y0001]-[M01]-[D01]")
};

declare function local:get-collection-size($directory, $file-list) {
    let $images-directory := $directory || "/VRA_images"
    
    return
        if (file:exists($images-directory))
        then format-number(sum(file:list($images-directory)//file:file[not(ends-with(@name, '.xml'))]/@size ! (xs:integer(.) div 1048576)),"#,##0.00")
        else 0
};

declare function local:get-collection-metadata($directory) {
    let $file-list := file:list($directory)
    let $size := local:get-collection-size($directory, $file-list)
        
    let $contents-file := parse-xml(file:read($directory || "/" || "__contents__.xml"))
    let $collection := xmldb:decode($contents-file/*/@name)
    let $owner-1 := $contents-file/*/@owner
    let $owner-2 := if ($owner-1 = 'bq_aengler@ad.uni-heidelberg.de') then 'editor' else $owner-1
    
    let $resources := $contents-file//contents:resource
    let $number-of-resources := count($resources)
    
    let $modification-datetimes := distinct-values($resources/@modified) ! local:date-from-dateTime(.)
    let $latest-modification-datetime := max($modification-datetimes)
     
    return (
        string-join(($collection, $owner-2, $number-of-resources, $size, $latest-modification-datetime), ',') || "&#10;"
        ,
        for $subcollection in $file-list//file:directory[@name != 'VRA_images']
        
        return local:get-collection-metadata($directory || "/" || $subcollection/@name)
    )
};

let $base-directories := ("/home/claudius/tamboti/full20171110-0300/db/resources/commons", "/home/claudius/tamboti/full20171110-0300/db/resources/users")


return
    xmldb:store("/db/resources", "collection-metadata.xml",
        <metadata>
            {(
                "Path,Owner,Number of records,Size (MB), Last modification date"
                ,
                for $base-directory in $base-directories
                
                return
                    for $directory-name in file:list($base-directory)/*/@name[. != '__contents__.xml']
                    
                    return local:get-collection-metadata($base-directory || "/" || $directory-name)
            )}
        </metadata>
    ) 