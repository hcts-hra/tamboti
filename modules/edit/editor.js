modsEditor = {};

$(document).ready(function() {
    $("#tabs").tabs({
        activate: function(ev, ui) {
            $("div.subtabs", ui.newPanel).tabs("option", "active", 0);
            fluxProcessor.dispatchEventType("main-content", "load-subform", {
                "subform-id": $("div.subtabs li:first-child", ui.newPanel).attr('aria-controls')
            }); 
        },
        active: 0
    });
    $(".subtabs").tabs({
        activate: function(event, ui){
            fluxProcessor.dispatchEventType("main-content", "load-subform", {
                "subform-id": ui.newTab.attr('aria-controls')
            });             
        }        
    });
  
  
});
