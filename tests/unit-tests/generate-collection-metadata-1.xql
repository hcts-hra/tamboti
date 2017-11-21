xquery version "3.1";

declare namespace file = "http://exist-db.org/xquery/file";
declare namespace contents = "http://exist.sourceforge.net/NS/exist";

declare function local:date-from-dateTime($date-time) {
    format-dateTime($date-time, "[Y0001]-[M01]-[D01]")
};

declare function local:get-collection-metadata($directory) {
    let $contents-files := 
        for $contents-file in file:directory-list($directory, "**/__contents__.xml")/file:file
        return $contents-file
        
    let $main-contents-file := parse-xml(file:read($directory || "/" || $contents-files[not(@subdir)]/@name))
    let $collection := xmldb:decode($main-contents-file/*/@name)
    let $owner := $main-contents-file/*/@owner
    let $owner-1 := if ($owner = 'bq_aengler@ad.uni-heidelberg.de') then 'editor' else $owner
    
    let $content-files :=
        for $content-file-description in $contents-files
        let $content-file-path := $directory || "/" || $content-file-description/@subdir  || "/" || $content-file-description/@name
        let $content-file := file:read($content-file-path)
        
        return parse-xml($content-file)//contents:resource
    let $number-of-files := count($content-files)
    let $modification-datetimes := distinct-values($content-files/@modified) ! local:date-from-dateTime(.)
    let $latest-modification-datetime := max($modification-datetimes)
     
    return string-join(($collection, $owner-1, $number-of-files, $latest-modification-datetime), ',') || "&#10;"
};

let $base-directories := ("/home/claudius/tamboti/full20171110-0300/db/resources/commons", "/home/claudius/tamboti/full20171110-0300/db/resources/users")


return
    xmldb:store("/db/resources", "collection-metadata.xml",
        <metadata>
            {
                for $base-directory in $base-directories
                
                return
                    for $directory-name in file:list($base-directory)/*/@name[. != '__contents__.xml']
                    
                    return local:get-collection-metadata($base-directory || "/" || $directory-name)
            }
        </metadata>
    )    
