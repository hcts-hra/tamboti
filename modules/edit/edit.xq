xquery version "3.0";

(:TODO: change all 'monograph' to 'book' in tabs-data.xml and compact body files:)
(:TODO: delete all '-compact' from ext:template in records, then delete all code that removes this from type in session.xql, edit.xql, tabs.xqm.:)
(:TODO: Code related to MADS files.:)
(:TODO move code into security module:)

declare default element namespace "http://www.w3.org/1999/xhtml";
declare namespace xf="http://www.w3.org/2002/xforms";
declare namespace ev="http://www.w3.org/2001/xml-events";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace ext="http://exist-db.org/mods/extension";
declare namespace mads="http://www.loc.gov/mads/";
declare namespace mods-editor = "http://hra.uni-heidelberg.de/ns/mods-editor/";

import module namespace mods = "http://www.loc.gov/mods/v3" at "tabs.xqm";
import module namespace mods-common = "http://exist-db.org/mods/common" at "../mods-common.xql";
import module namespace config = "http://exist-db.org/mods/config" at "../config.xqm";
import module namespace security = "http://exist-db.org/mods/security" at "../search/security.xqm"; (:TODO move security module up one level:)
import module namespace functx = "http://www.functx.com";

(:The following variables are used for a kind of dynamic theming.:)
declare variable $theme := substring-before(substring-after(request:get-url(), "/apps/"), "/modules/edit/edit.xq");
declare variable $header-title := if ($theme eq "tamboti") then "Tamboti Metadata Framework - MODS Editor" else "eXist Bibliographical Demo - MODS Editor";
declare variable $tamboti-css := if ($theme eq "tamboti") then "tamboti.css" else ();
declare variable $img-left-src := if ($theme eq "tamboti") then "../../themes/tamboti/images/tamboti.png" else "../../themes/default/images/logo.jpg";
declare variable $img-left-title := if ($theme eq "tamboti") then "Tamboti Metadata Framework" else "eXist-db: Open Source Native XML Database";
declare variable $img-right-href := if ($theme eq "tamboti") then "http://www.asia-europe.uni-heidelberg.de/en/home.html" else "";
declare variable $img-right-src := if ($theme eq "tamboti") then "../../themes/tamboti/images/cluster_logo.png" else ();
declare variable $img-right-title := if ($theme eq "tamboti") then "The Cluster of Excellence &quot;Asia and Europe in a Global Context: Shifting Asymmetries in Cultural Flows&quot; at Heidelberg University" else ();
declare variable $img-right-width := if ($theme eq "tamboti") then "200" else ();
 
declare function local:create-new-record($id as xs:string, $type-request as xs:string, $target-collection as xs:string) as empty() {
    (:Copy the template and store it with the ID as file name.:)
    (:First, get the right template, based on the type-request and the presence or absence of transliteration.:)
    let $transliterationOfResource := request:get-parameter("transliterationOfResource", '')
    let $template-request := 
        if ($type-request = '')
        then 'insert-templates'
        else
            if ($type-request = (
                        'suebs-tibetan', 
                        'suebs-chinese', 
                        'insert-templates', 
                        'new-instance', 
                        'mads'))
            (:These document types do not divide into latin and transliterated.:)
            then $type-request
            else
                (:Append '-transliterated' if there is transliteration, otherwise append '-latin'.:)
                if ($transliterationOfResource) 
                then concat($type-request, '-transliterated') 
                else concat($type-request, '-latin') 
    let $template := doc(concat($config:edit-app-root, '/data-templates/', $template-request, '.xml'))
    
    (:Then give it a name based on a uuid, store it in the temp collection and set restrictive permissions on it.:)
    let $doc-name := concat($id, '.xml')
    let $stored := xmldb:store($config:mods-temp-collection, $doc-name, $template)   

    (:Make the record accessible to the user alone in the temp collection.:)
    let $permissions := 
        (
            sm:chmod(xs:anyURI($stored), $config:temp-resource-mode)
        )
    
    (:If the record is created in a collection inside commons, it should be visible to all.:)
    (:let $null := 
        if (contains($target-collection, $config:mods-commons)) 
        then security:set-resource-permissions(xs:anyURI(concat($config:mods-temp-collection, "/", $doc-name)), $config:biblio-admin-user, $config:biblio-users-group, $config:collection-mode)
        else ():)
    
    (:Get the remaining parameters that are to be stored, in addition to transliterationOfResource (which was fetched above).:)
    let $scriptOfResource := request:get-parameter("scriptOfResource", '')
    let $languageOfResource := request:get-parameter("languageOfResource", '')
    let $languageOfCataloging := request:get-parameter("languageOfCataloging", '')
    let $scriptOfCataloging := request:get-parameter("scriptOfCataloging", '')           
    (:Parameter 'host' is used when related records with type "host" are created.:)
    let $host := request:get-parameter('host', '')
    
    let $doc := doc($stored)
    
    (:Note that we cannot use "update replace" if we want to keep the default namespace.:)
    return
       (
           (:Update the record with ID attribute.:)
           update insert attribute ID {$id} into $doc/mods:mods
           ,
           update insert attribute ID {$id} into $doc/mads:mads
      ,
      (:Save the language and script of the resource.:)
      (:If namespace is not applied in the updates, the elements will be in the empty namespace.:)
      let $language-insert :=
          <language xmlns="http://www.loc.gov/mods/v3">
              <languageTerm authority="iso639-2b" type="code">
                  {$languageOfResource}
              </languageTerm>
              <scriptTerm authority="iso15924" type="code">
                  {$scriptOfResource}
              </scriptTerm>
          </language>
      return
      update insert $language-insert into $doc/mods:mods
      ,
      (:Save the library reference, the creation date, and the language and script of cataloguing:)
      (:To simplify input, resource language and language of cataloging are identical be default.:) 
      let $recordInfo-insert :=
          <recordInfo xmlns="http://www.loc.gov/mods/v3" lang="eng" script="Latn">
              <recordContentSource authority="marcorg">DE-16-158</recordContentSource>
              <recordCreationDate encoding="w3cdtf">
                  {current-date()}
              </recordCreationDate>
              <recordChangeDate encoding="w3cdtf"/>
              <languageOfCataloging>
                  <languageTerm authority="iso639-2b" type="code">
                      {$languageOfResource}
                  </languageTerm>
                  <scriptTerm authority="iso15924" type="code">
                      {$scriptOfResource}
              </scriptTerm>
              </languageOfCataloging>
          </recordInfo>            
      return
      update insert $recordInfo-insert into $doc/mods:mods
      ,
      (:Save the name of the template used, transliteration scheme used, 
      and an empty catalogingStage into mods:extension.:)  
      update insert
          <extension xmlns="http://www.loc.gov/mods/v3" xmlns:ext="http://exist-db.org/mods/extension">
              <ext:template>{$template-request}</ext:template>
              <ext:transliterationOfResource>{$transliterationOfResource}</ext:transliterationOfResource>
              <ext:catalogingStage/>
          </extension>
      into $doc/mods:mods
      ,
      (:If the user requests to create a related record, 
      a record which refers to the record being browsed, 
      insert the ID into @xlink:href on the first empty <relatedItem> in the new record.:)
      if ($host)
      then
        (
            update value doc($stored)/mods:mods/mods:relatedItem[string-length(@type) eq 0][1]/@type with "host",
            update value doc($stored)/mods:mods/mods:relatedItem[@type eq 'host'][1]/@xlink:href with concat('#', $host)
        )
      else ()
      
    )
};

declare function local:create-xf-model($id as xs:string, $tab-id as xs:string, $instance-id as xs:string, $target-collection as xs:string, $host as xs:string, $data-template-name as xs:string) as element(xf:model) {
    let $transliterationOfResource := request:get-parameter("transliterationOfResource", '')
    let $instance-src := concat('get-data-instance.xq?id=', $id, '&amp;data-template-name=', $data-template-name)
    let $ui-file-path := "user-interfaces/" || $instance-id || ".xml"
    let $log := util:log("INFO", "$data-template-name = " || $data-template-name)
    
    return
        <xf:model id="m-main">
            <xf:instance id="i-configuration">
                <configuration xmlns="">
                    <current-username>{xmldb:get-current-user()}</current-username>
                    <languageOfResource>{request:get-parameter("languageOfResource", '')}</languageOfResource>
                    <scriptOfResource>{request:get-parameter("scriptOfResource", '')}</scriptOfResource>
                    <template>{$data-template-name}</template>
                    <host>{request:get-parameter('host', '')}</host>
                </configuration>
            </xf:instance>   

            <xf:instance id="i-variables">
                <variables xmlns="">
                    <subform-relative-path />
                </variables>
            </xf:instance>            
            
           <xf:instance src="{$instance-src}" id="save-data">
                <mods xmlns="http://www.loc.gov/mods/v3" xmlns:xlink="http://www.w3.org/1999/xlink" />
           </xf:instance>

         
           <!--The instance insert-templates contain an almost full embodiment of the MODS schema, version 3.5; 
           It is used mainly to insert attributes and uncommon elements, 
           but it can also be chosen as a template.-->
           <xf:instance xmlns:mods="http://www.loc.gov/mods/v3" src="data-templates/insert-templates.xml" id="insert-templates">
                <mods xmlns="http://www.loc.gov/mods/v3" />
           </xf:instance>
           
           <!--A basic selection of elements and attributes from the MODS schema, 
           used inserting basic elements, but it can also be chosen as a template.-->
           <xf:instance xmlns="http://www.loc.gov/mods/v3" src="data-templates/new-instance.xml" id="new-instance">
                <mods xmlns="http://www.loc.gov/mods/v3" />
           </xf:instance>
           
           <!--A selection of elements and attributes from the MADS schema used for default records.-->
           <!--not used at present-->
           <!--<xf:instance xmlns="http://www.loc.gov/mads/" src="data-templates/mads.xml" id='mads' readonly="true"/>-->
    
           <!--Elements and attributes for insertion of special configurations of elements into the compact forms.-->
           <xf:instance src="data-templates/compact-template.xml" id="compact-template"> 
                <mods xmlns="http://www.loc.gov/mods/v3" />
           </xf:instance>

           <xf:instance id="i-hint-codes" src="code-tables/hint.xml">
                <code-table xmlns="http://hra.uni-heidelberg.de/ns/mods-editor/" />
            </xf:instance>
           
           <!--Having binds would prevent a tab from being saved when clicking on another tab, 
           so binds are not used.--> 
           <!--
           <xf:bind nodeset="instance('save-data')/mods:titleInfo/mods:title" required="true()"/>       
           -->
           
           <!--The different submission types, called by their id.-->
           <!--Save in temp-->
           <xf:submission
                id="save-submission" 
                method="post"
                ref="instance('save-data')"
                resource="save.xq?collection={$config:mods-temp-collection}&amp;action=save" replace="none">
           </xf:submission>
           
           <!--Save in target collection-->
           <xf:submission 
                id="save-and-close-submission" 
                method="post"
                ref="instance('save-data')"
                resource="save.xq?collection={$target-collection}&amp;action=close" replace="none">
                    <xf:action ev:event="xforms-submit-done">
                        <script type="text/javascript">
                            window.close();
                        </script>
                    </xf:action>
                    <xf:message ev:event="xforms-submit-error" level="ephemeral">A submission error (<xf:output value="event('response-reason-phrase')"/>) occurred. Details: 'response-status-code' = '<xf:output value="event('response-status-code')"/>', 'resource-uri' = '<xf:output value="event('resource-uri')"/>'.</xf:message>
           </xf:submission>

            <xf:action ev:event="xforms-ready">
               <xf:load show="embed" targetid="user-interface-container">
                    <xf:resource value="'{$ui-file-path}#user-interface-container'"/>
                </xf:load>
                <xf:setvalue ref="instance('save-data')/mods:language/mods:languageTerm" value="instance('i-configuration')/languageOfResource" />
                <xf:setvalue ref="instance('save-data')/mods:language/mods:scriptTerm" value="instance('i-configuration')/scriptOfResource" />
                <xf:setvalue ref="instance('save-data')/mods:recordInfo/mods:recordCreationDate" value="local-date()" />
                <xf:setvalue ref="instance('save-data')/mods:recordInfo/mods:languageOfCataloging/mods:languageTerm" value="instance('i-configuration')/languageOfResource" />
                <xf:setvalue ref="instance('save-data')/mods:recordInfo/mods:languageOfCataloging/mods:scriptTerm" value="instance('i-configuration')/scriptOfResource" />
                <xf:setvalue ref="instance('save-data')/mods:extension/ext:template" value="instance('i-configuration')/template" />
                <xf:action if="string-length(instance('i-configuration')/host) > 0">
                    <xf:setvalue ref="instance('save-data')/mods:relatedItem[@type eq 'host'][1]/@xlink:href" value="concat('#', instance('i-configuration')/host)" />                
                </xf:action>
            </xf:action>
            <xf:action ev:event="load-subform" ev:observer="main-content">
                <xf:setvalue ref="instance('i-variables')/subform-relative-path" value="concat('user-interfaces/', event('subform-id'), '.xml')" />
                <xf:load show="embed" targetid="user-interface-container">
                    <xf:resource value="instance('i-variables')/subform-relative-path" />
                    <xf:extension includeCSS="false" includeScript="false" />
                </xf:load>
                <xf:refresh model="m-main"/>                
            </xf:action>            
           <xf:action ev:event="save-and-close-action" ev:observer="main-content">
               <xf:send submission="save-and-close-submission" />
           </xf:action>
        </xf:model>
};

declare function local:create-page-content($id as xs:string, $tab-id as xs:string, $type-request as xs:string, $target-collection as xs:string, $instance-id as xs:string, $record-data as xs:string, $type-data as xs:string) as element(div) {
    (:Get the part of the form that belongs to the active tab.:)
    let $user-interface := collection(concat($config:edit-app-root, '/user-interfaces'))/*[local-name() = 'div'][@tab-id eq $instance-id]

    (:Get the time of the last save to the temp collection and parse it.:)
    let $last-modified := xmldb:last-modified($config:mods-temp-collection, concat($id,'.xml'))
    let $last-modified-hour := hours-from-dateTime($last-modified)
    let $last-modified-minute := minutes-from-dateTime($last-modified)
    let $last-modified-minute := functx:pad-integer-to-length($last-modified-minute, 2)
    
    (:If the record is hosted by a record linked to through an xlink:href, 
    display the title of this record. 
    Only the xlink on the first relatedItem with type host is processed.:)
    let $host := request:get-parameter('host', '')
    let $related-item-xlink := doc($record-data)/mods:mods/mods:relatedItem[@type = 'host'][1]/@xlink:href
    let $related-publication-id := 
        if ($related-item-xlink) 
        then replace($related-item-xlink[1]/string(), '^#?(.*)$', '$1') 
        else ()
    let $related-publication-title := 
        if ($related-publication-id) 
        then mods-common:get-short-title(collection($config:mods-root)//mods:mods[@ID eq $related-publication-id][1])
        else ()
    let $related-publication-title :=
        (:Check for no string contents - the count may still be 1.:)
        if ($related-item-xlink eq '')
        then ()
            else 
            if (count($related-item-xlink) eq 1)
            then
            (<span class="intro">The publication is included in </span>, <a href="../../modules/search/index.html?search-field=ID&amp;value={$related-publication-id}&amp;query-tabs=advanced-search-form&amp;default-operator=and" target="_blank">{$related-publication-title}</a>,<span class="intro">.</span>)
            else
                (:Can the following occur, given that only one xlink is retrieved?:)
                if (count($related-item-xlink) gt 1) 
                then (<span class="intro">The publication is included in more than one publication.</span>)
                else ()
                
        return
        <div id="main-content" xmlns="http://www.w3.org/1999/xhtml" class="content">
            <span class="info-line">
            {
                if ($type-request)
                then
                    (:Remove any '-latin' and '-transliterated' appended the original type request. :)
                    let $type-request := replace(replace($type-request, '-latin', ''), '-transliterated', '')
                    let $type-label := doc($type-data)/*/*[3]/*[*[local-name() = 'value'] eq $type-request and *[local-name() = 'classifier'] = ('stand-alone', 'related')]/*[local-name() = 'label']
                    (:This is the hint text informing the user aboiut the specific document type and its options.:)
                    let $type-hint := doc($type-data)/*/*[3]/*[*[local-name() = 'value'] eq $type-request]/*[local-name() = 'hint']
                        return
                        (
                        'Editing record of type ', 
                        <xf:output value="'{$type-label}'">
                            {
                                if ($type-hint) 
                                then <xf:hint>{$type-hint/text()}</xf:hint>
                                else ()                                
                            }
                        </xf:output>                        
                        ) 
                else 'Editing record'
                ,
                let $publication-title := concat(doc($record-data)/mods:mods/mods:titleInfo[string-length(@type) eq 0][1]/mods:nonSort, ' ', doc($record-data)/mods:mods/mods:titleInfo[string-length(@type) eq 0][1]/mods:title)
                return
                    (:Why the space here?:)
                    if ($publication-title ne ' ') 
                    then (' with the title ', <strong>{$publication-title}</strong>) 
                    else ()
                }, to be saved in <strong> {
                    let $target-collection-display := replace(replace(xmldb:decode-uri($target-collection), '/db' || $config:users-collection || '/', ''), '/db' || $config:mods-commons || '/', '')
                    return
                        if ($target-collection-display eq security:get-user-credential-from-session()[1])
                        then $config:data-collection-name || '/Home'
                        else $target-collection-display
                }</strong> (Last saved: {$last-modified-hour}:{$last-modified-minute}).
            </span>
            {
                doc("user-interfaces/tabs/" || $type-request || "-stand-alone.xml")
            
            }
            <div class="save-buttons-top">    
                 <xf:trigger>
                    <xf:label>
                        <xf:output value="'Finish Editing'" class="hint-icon">
                            <xf:hint ref="id('hint-code_save',instance('i-hint-codes'))/*:help" />
                        </xf:output>
                    </xf:label>
                    <xf:dispatch ev:event="DOMActivate" name="save-and-close-action" targetid="main-content"/>
                </xf:trigger>
                <span class="related-title">
                        {$related-publication-title}
                </span>
            </div>            
            <div id="user-interface-container"/>
            <div class="save-buttons-bottom">    
                <!--<xf:submit submission="save-submission">
                    <xf:label>Save</xf:label>
                </xf:submit>-->
                <xf:trigger>
                    <xf:label>Cancel Editing</xf:label>
                    <xf:action ev:event="DOMActivate">
                        <script type="text/javascript">
                            window.close();
                        </script>
                    </xf:action>
                 </xf:trigger>
                 <xf:trigger>
                    <xf:label>
                        <xf:output value="'Finish Editing'" class="hint-icon">
                            <xf:hint ref="id('hint-code_save',instance('i-hint-codes'))/*:help" />
                        </xf:output>
                    </xf:label>
                    <xf:dispatch ev:event="DOMActivate" name="save-and-close-action" targetid="main-content"/>
                </xf:trigger>
            </div>              
        </div>
};

(:The compact-a template (in 00-compact-main) is the same for all resource types; 
filtering is performed inside the form to display the elements needed for a particular template.
The compact-b temples (in 00-compact-related-X) are different according to their resource type; 
the only filtering that is performed is for transliteration.
The compact-c temples (in 00-compact-contents) is the same for all resource types; 
the only filtering that is performed is for transliteration.:)
declare function local:get-tab-id($tab-id as xs:string, $type-request as xs:string) {
    (:Remove any '-latin' and '-transliterated' appended the original type request. :)
    let $log := util:log("INFO", "$type-request = " || $type-request)
    let $type-request := replace(replace($type-request, '-latin', ''), '-transliterated', '')
    let $log := util:log("INFO", "$type-request = " || $type-request)
    
    return
        if ($tab-id ne 'compact-b')
        (:Only treat compact-b types.:)
        then $tab-id
        else
            switch ($type-request) 
                case "article-in-periodical" return "compact-b-article"
                case "newspaper-article" return "compact-b-newspaper-article"
                case "moving-images" return "compact-b-moving-images"
                case "contribution-to-edited-volume" return "compact-b-edited-volume"
                case "monograph" return "compact-b-monograph"
                case "edited-volume" return "compact-b-monograph"
                case "book-review" return "compact-b-review"
                case "suebs-tibetan" return "compact-b-suebs-tibetan"
                case "suebs-chinese" return "compact-b-suebs-chinese"
                case "mads" return "mads"
                    default return "compact-b-xlink"
                    (:compact-b-xlink is used for records related to other records through an xlink:href.:)
                    (:NB: Should be split up in three: article, book review and contribution.:)
};

(:Main:)
(:Find the record.:)
let $record-id := request:get-parameter('id', '')
let $temp-record-path := concat($config:mods-temp-collection, "/", $record-id,'.xml')

(:If the record has been made with Tamoboti, it will have a template stored in <mods:extension>. 
If a new record is being created, the template name has to be retrieved from the URL in order to serve the right subform.:)

(:Get the type parameter which shows which record template has been chosen.:) 
let $type-request := request:get-parameter('type', ())

(:Get the path to the document containing the document type information.:)
let $type-data := concat($config:edit-app-root, '/code-tables/document-type.xml')

(:Sorting data is retrieved from the type-data.:)
(:Sorting is done in session.xql in order to present the different template options in an intellegible way.:)
(:If type-sort is '1', it is a compact form and the Basic Input Forms should be shown;
If type-sort is '2', it is a compact form and the Basic Input Forms should be shown;
if type-sort is 4, it is a mads record and the MADS forms should be shown; 
otherwise it is a record not made with Tamboti and Title Information should be shown.:)
let $type-request := replace(replace(replace($type-request, '-latin', ''), '-transliterated', ''), '-compact', '')
let $type-sort := xs:integer(doc($type-data)/mods-editor:code-table/mods-editor:items/mods-editor:item[mods-editor:value eq $type-request]/mods-editor:sort)
(:Get the tab-id for the upper tab to be shown. 
If no tab is specified, default to the compact-a tab when there is a template to be used with Basic Input Forms;
otherwise default to Title Information.:)
let $tab-id :=
    if ($type-sort = (1, 2))
    then 'compact-a'
    else
        if ($type-sort eq 4)
        then 'mads'
        else 'title'        
(:However, if a tab-id is passed, use this instead of the default.:)
let $tab-id := request:get-parameter('tab-id', $tab-id)

(:Get the chosen location for the record.:)
let $target-collection := xmldb:encode-uri(request:get-parameter("collection", ''))

(:Get the id of the record, if it has one; otherwise mark it "new" in order to give it one.:)
let $id-param := request:get-parameter('id', 'new')
let $new-record := xs:boolean($id-param eq '' or $id-param eq 'new')
(:If we do not have an incoming ID (the record has been made outside Tamboti) or if the record is new (made with Tamboti), then create an ID with util:uuid().:)
let $id :=
    if ($new-record)
    then ''
    else $id-param

(:If we are creating a new record, then we need to call get-data-instance.xq with new=true to tell it to get a new template and store it in temp; 
if we are editing an existing record, we copy the record from the target collection to temp, unless there is already a record in temp with the same name.:)
(:NB: What if A edits a certain record, leaving it in temp, and B edits the same record - does B then start off where A left off?:)
(:let $create-new-from-template :=:)
(:    if ($new-record) :)
(:    (:Create a new record, knows its type and target-collection (but store it for the time being in temp.:):)
(:    then local:create-new-record($id, $type-request, $target-collection):)
(:    else:)
(:        (:If it is an old record and the document is not in temp already, copy it there.:):)
(:        if (not(doc-available(concat($config:mods-temp-collection, '/', $id, '.xml')))):)
(:        (:Otherwise copy the old record to temp.:):)
(:        then xmldb:copy($target-collection, $config:mods-temp-collection, concat($id, '.xml')):)
(:        else ():)
(:    let $set-mode := sm:chmod(xs:anyURI($config:mods-temp-collection || "/" || $id || '.xml'), $config:resource-mode):)

(:For a compact-b form, determine which subform to serve, based on the template.:)

let $transliterationOfResource := request:get-parameter("transliterationOfResource", '')
let $data-template-name := 
    if ($type-request = '')
    then 'insert-templates'
    else
        if ($type-request = (
                    'suebs-tibetan', 
                    'suebs-chinese', 
                    'insert-templates', 
                    'new-instance', 
                    'mads'))
        (:These document types do not divide into latin and transliterated.:)
        then $type-request
        else
            (:Append '-transliterated' if there is transliteration, otherwise append '-latin'.:)
            if ($transliterationOfResource) 
            then concat($type-request, '-transliterated') 
            else concat($type-request, '-latin')    
let $log := util:log("INFO", "$tab-id = " || $tab-id)
let $instance-id := local:get-tab-id($tab-id, $type-request)
(:NB: $style appears to be introduced in order to use the xf namespace in css.:)
let $model := local:create-xf-model($id, $tab-id, $instance-id, $target-collection, request:get-parameter('host', ''), $data-template-name)
let $content := local:create-page-content($id, $tab-id, $data-template-name, $target-collection, $instance-id, $temp-record-path, $type-data)

return 
    (:Set serialization options.:)
    (util:declare-option("exist:serialize", "method=xhtml5 media-type=text/html output-doctype=yes indent=yes encoding=utf-8")
    ,
    (:Construct the editor page.:)
    <html xmlns="http://www.w3.org/1999/xhtml" xmlns:xf="http://www.w3.org/2002/xforms" xmlns:ev="http://www.w3.org/2001/xml-events" xmlns:mods="http://www.loc.gov/mods/v3" xmlns:ext="http://exist-db.org/mods/extension" xmlns:xlink="http://www.w3.org/1999/xlink">
        <head>
            <title>
                {$header-title}
            </title>
            <script type="text/javascript" src="../../resources/scripts/jquery-1.11.2/jquery-1.11.2.min.js">/**/</script>
            <script type="text/javascript" src="../../resources/scripts/jquery-ui-1.11.4/jquery-ui.min.js">/**/</script>
            <script type="text/javascript" src="editor.js">/**/</script>
            <link rel="stylesheet" type="text/css" href="../../resources/scripts/jquery-ui-1.11.4/jquery-ui.min.css" />
            <link rel="stylesheet" type="text/css" href="edit.css"/>
            <link rel="stylesheet" type="text/css" href="{$tamboti-css}"/>              
            {$model}
        </head>
        <body>
    <div id="page-head">
        <div id="page-head-left">
            <a href="../.." style="text-decoration: none">
                <img src="{$img-left-src}" title="{$img-left-title}" alt="{$img-left-title}" style="border-style: none;" width="250px"/>
            </a>
            <div class="documentation-link"><a href="../../docs/" style="text-decoration: none" target="_blank">Help</a></div>
        </div>
        <div id="page-head-right">
            <a href="{$img-right-href}" target="_blank">
                <img src="{$img-right-src}" title="{$img-right-title}" alt="{$img-right-title}" width="{$img-right-width}" style="border-style: none"/>
            </a>
        </div>
    </div>
            <div>
            <div class="container">
                <div>
                    {$content}
                </div>
            </div>
            </div>
        </body>
    </html>
)
