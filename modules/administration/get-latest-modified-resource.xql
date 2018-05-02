xquery version "3.0";

declare namespace file = "http://exist-db.org/xquery/file";
declare namespace contents = "http://exist.sourceforge.net/NS/exist";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:method "text";
declare option output:media-type "text/plain";

declare function local:date-from-dateTime($date-time) {
    format-dateTime($date-time, "[Y0001]-[M01]-[D01]")
};

declare function local:get-collection-metadata($directory) {
    let $contents-files := 
        for $contents-file in file:directory-list($directory, "**/__contents__.xml")/file:file
        return $contents-file
        
    let $main-contents-file := parse-xml(file:read($directory || "/" || $contents-files[not(@subdir)]/@name))
    let $collection := xmldb:decode($main-contents-file/*/@name)
    
    let $content-files :=
        for $content-file-description in $contents-files
        let $content-file-path := $directory || "/" || $content-file-description/@subdir  || "/" || $content-file-description/@name
        let $content-file := file:read($content-file-path)
        
        return parse-xml($content-file)//contents:resource
    let $modification-datetimes := distinct-values($content-files/@modified) ! local:date-from-dateTime(.)
    let $latest-modification-datetime := max($modification-datetimes)
     
    return <collection latest-modification-datetime="{$latest-modification-datetime}">{$collection}</collection>
};

let $base-directories := ("/media/sdb/backup/full/tamboti/full20180502-0300/db/resources/commons", "/media/sdb/backup/full/tamboti/full20180502-0300/db/resources/users")

let $metadata-records :=
        for $base-directory in $base-directories
        
        return
            for $directory-name in file:list($base-directory)/*/@name[. != '__contents__.xml']
            
            return local:get-collection-metadata($base-directory || "/" || $directory-name)

let $result :=
    for $metadata-record in $metadata-records
    let $latest-modification-datetime := data($metadata-record/@latest-modification-datetime)
    order by $latest-modification-datetime descending
    
    return string-join(($metadata-record/text(), $latest-modification-datetime), " ") || "&#10;"
    

return $result[position() < 10]