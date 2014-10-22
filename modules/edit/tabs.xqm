xquery version "3.0";

module namespace mods = "http://www.loc.gov/mods/v3";

import module namespace config="http://exist-db.org/mods/config" at "../config.xqm";

declare namespace xf="http://www.w3.org/2002/xforms";
declare namespace xforms="http://www.w3.org/2002/xforms";
declare namespace ev="http://www.w3.org/2001/xml-events";

declare variable $mods:tabs-data := concat($config:edit-app-root, '/tab-data.xml');

(: Display the tabs in a div using triggers that hide or show sub-tabs and tabs. :)
declare function mods:tabs($tab-id as xs:string, $record-id as xs:string, $data-collection as xs:string) as node()  {
(: Get the type and transliterationOfResource params from the URL. :)
let $type := request:get-parameter("type", '')
(: When a new Tamboti record is created, '-latin', and '-transliterated' are not appended, but in old Tamboti records they are. The easiest thing is to strip them, if there, and construct them again. :)
(:NB: It is unclear why space has to be normalized here; at least 'insert-templates' has space appended when received here.:) 
let $type := normalize-space(replace(replace(replace($type, '-latin', ''), '-transliterated', ''), '-compact', ''))
let $transliterationOfResource := request:get-parameter("transliterationOfResource", "")
(: Construct the full types. :)
let $type := 
        if ($type = ('suebs-tibetan', 'suebs-chinese', 'insert-templates', 'new-instance', 'mads'))
        (: NB: These document types do not divide into latin and transliterated. :)
        then $type
        else
            if (contains($type, '-transliterated') or contains($type, '-latin')) 
            then $type
            else
                if ($transliterationOfResource) 
                then concat($type, '-transliterated') 
                else 
                    if ($type)
                    then concat($type, '-latin')
                    else ()
(: Get the top-tab-number param from the URL.
If it is empty, it is because the record has just been initialised, because a record not made with Tamboti is loaded; 
or because it is a non-basic template. In these cases, set it to 2 to show Citation Forms/Title Information (and hide the Basic Input Forms tab). 
Otherwise set it to 1 to show Basic Input Forms/Main Publication. :)
let $top-tab-number := xs:integer(request:get-parameter("top-tab-number", 0))
let $top-tab-number := 
    (: If a top-tab-number is passed, use it. :)
    if ($top-tab-number gt 0) 
    then $top-tab-number 
    else
        (: If a top-tab-number is not passed, construct it.
        If the record is not made in Tamboti (does not have a type) or if the type is not one that Basic Forms handle, serve the second tab (Citation Forms). :)
        if ($type = ('insert-templates','new-instance') or not($type))
        then 2
        else
            (: For (future) mads records, serve the mads tab. :)
            if ($type = 'mads')
            then 5
            (: A Basic Input Forms record. :)
            else 1
(: Get the tabs data. :)

let $tabs-data := doc($mods:tabs-data)/tabs/tab

return
<div class="tabs">
    <table class="top-tabs" width="100%">
        <tr>
            {
            for $top-tab-label in distinct-values($tabs-data/top-tab-label)
            (: Do not show the Basic Input Forms tab for records not created with Basic Input Forms. :)
            where not((not($type) or $type = ('insert-templates','new-instance')) and $top-tab-label eq 'Basic Input Forms')
            return
            <td style="{
                if ($tabs-data[top-tab-label = $top-tab-label]/top-tab-number = $top-tab-number) 
                then "background:white;border-bottom-color:white;" 
                else "background:#EDEDED"
            }">
            {attribute{'width'}{25}}
                <xf:trigger appearance="minimal">
                    <xf:label>
                        <div class="label" style="{
                            if ($tabs-data[top-tab-label = $top-tab-label]/top-tab-number = $top-tab-number) 
                            then "font-weight:bold;color:#3681B3;" 
                            else "font-weight:bold;color:darkgray"
                        }">
                    <span class="tab-text">{$top-tab-label}</span>
                    </div>
                    </xf:label>
                    <xf:action ev:event="DOMActivate">
                        <!--When clicking on the top tabs, save the record. -->
                        <xf:send submission="save-submission"/>
                        <!--When clicking on a top tab, select the first of the bottom tabs that belongs to it. -->
                        <xf:load resource="edit.xq?tab-id={$tabs-data[top-tab-label = $top-tab-label][1]/tab-id[1]}&amp;id={$record-id}&amp;top-tab-number={$tabs-data[top-tab-label = $top-tab-label][1]/top-tab-number[1]}&amp;type={$type}&amp;collection={$data-collection}" show="replace"/>
                    </xf:action>
                </xf:trigger>                
            </td>
            }
            </tr>
            </table>
            <table class="bottom-tabs">                    
                <tr>
                {
                for $tab in $tabs-data[top-tab-number = $top-tab-number]
                let $tab-for-type := $tab/*[local-name() = $type]/text()
				let $tab-count := count($tabs-data[top-tab-label/text() = $tab/top-tab-label/text()])
                (: There are no containers for periodicals. :)
                where $tab-for-type != ('periodical-latin', 'periodical-transliterated', 'newspaper-latin', 'newspaper-transliterated') or $top-tab-number gt 1
                return
                <td style="{
                    if ($tab-id eq $tab/tab-id) 
                    then "background:white;border-bottom-color:white;color:#3681B3;" 
                    else "background:#EDEDED"}
                    ">
                    {attribute{'width'}
                    {100 div $tab-count}}
                    <xf:trigger appearance="minimal">
                        <xf:label>
                            <div class="label" style="{
                                if ($tab-id eq $tab/tab-id) 
                                then "color:#3681B3;font-weight:bold;" 
                                else "color:darkgray;font-weight:bold"
                            }">{
                        if ($tab-for-type) 
                        then $tab-for-type 
                        else $tab/label
                        }</div>
                        </xf:label>
                        <xf:action ev:event="DOMActivate">
                            <xf:send submission="save-submission"/>
                            <!--When clicking on the bottom tabs, keep the top-tab-number the same. -->
                            <xf:load resource="edit.xq?tab-id={$tab/tab-id/text()}&amp;id={$record-id}&amp;top-tab-number={$top-tab-number}&amp;type={$type}&amp;collection={$data-collection}" show="replace"/>
                        </xf:action>
                    </xf:trigger>
                </td>
                }
                </tr>
            </table>
</div>
};