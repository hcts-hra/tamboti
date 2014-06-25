xquery version "1.0";

import module namespace config = "http://exist-db.org/mods/config" at "../config.xqm";
declare namespace mods = "http://www.loc.gov/mods/v3";
declare namespace mads = "http://www.loc.gov/mads/";

(: get-instance.xq - gets the instance data to load into the editor and prunes the mods record to only load the instance data that is needed for a given tab.
Note that the instance that this script returns MUST include an ID for saving.
:)

(: This is the id of the document we are going to edit if we are not creating a new record :)
let $id := request:get-parameter('id', '')
(:called once:)

(: This is the ID of the tab but we just use tab in the URL. If no tab-id is
   specified, then we use the title tab.  :)
let $tab-id := request:get-parameter('tab-id', 'title')

let $collection := $config:mods-temp-collection

(: Get the document with the parameter id in temp. :)
let $instance := collection($collection)//mods:mods[@ID = $id]

(: Get the tab data for the tab-id. :)
let $tab-data := doc(concat($config:edit-app-root, '/tab-data.xml'))/tabs/tab[tab-id = $tab-id]

(: Get a list of all the XPath expressions to include in this instance used by the form :)
let $paths := $tab-data/path

(: build up a string of prefix:element pairs for doing an eval :)
let $path-string := string-join($paths, ', ')

(: now get the eval string ready for use :)
let $eval-string := concat('$instance/', '(', $path-string, ')')
(:let $log := util:log("DEBUG", ("##$eval-string): ", $eval-string)):)
return
if ($tab-id eq 'mads')
then 
    <mads:mads ID="{$id}">
      { (: this is where we run the query that gets just the data we need for this tab :)
      util:eval($eval-string)}
    </mads:mads>
else
    <mods:mods ID="{$id}">
      { (: this is where we run the query that gets just the data we need for this tab :)
      util:eval($eval-string)}
    </mods:mods>