xquery version "3.1";

declare namespace mods = "http://www.loc.gov/mods/v3";

let $tamboti-collection := xmldb:encode('/data/commons/Buddhism Bibliography')
let $zotero-collection-key := "BWDUZNUA"

let $tamboti-resources := collection($tamboti-collection)/mods:mods
let $number-of-tamboti-resources := count($tamboti-resources)

let $job-parameters :=
    <parameters>
        <param name="tamboti-collection" value="{$tamboti-collection}" />
        <param name="zotero-collection-key" value="{$zotero-collection-key}" />
    </parameters>

return (
    update value doc("counters.xml")//write-record-to-zotero with 1
    ,
    scheduler:schedule-xquery-periodic-job("/apps/tamboti/modules/tamboti2zotero/write-record-to-zotero.xql", 6000, "write-record-to-zotero", $job-parameters, 0, $number-of-tamboti-resources - 1)
)
