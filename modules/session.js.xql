xquery version "3.0";

import module namespace security="http://exist-db.org/mods/security" at "search/security.xqm";
import module namespace config = "http://exist-db.org/mods/config" at "config.xqm";

declare namespace exist = "http://exist.sourceforge.net/NS/exist";

declare option exist:serialize "method=text media-type=application/javascript";

(:~
: Provides a JavaScript alert to the client, before their
: session times out, allowing them to renew the session
: or logout
:)

if (security:get-user-credential-from-session()[1] ne $security:GUEST_CREDENTIALS[1]) then
    text {
        (
            fn:concat('var sessionTimeout = ', $config:max-inactive-interval-in-minutes * 60 * 1000, ';'),
        
            "
            var beforeTimeout = 1000 * 60 * 5; //5 mins before the session timeout
            var sessionWarningTimeout = sessionTimeout - beforeTimeout;
            
            var timeoutId = setTimeout(showWarning, sessionWarningTimeout);
            
            function getIndexPath() {
                if (window.location.toString().indexOf('/search/') > -1){
                    return 'index.html';
                } else if (window.location.toString().indexOf('/edit/') > -1) {
                    return '../search/index.html';
                } else {
                    return 'search/index.html';
                }
            }
            
            function showWarning() {
            
                var beforeWarningTime = new Date().getTime();
                
                if (confirm('Your session is about to expire. Do you want to continue using Tamboti?' + '\n\n' + 'If you do, click \'OK\'.' + '\n\n' + 'If you do not, then clicking \'Cancel\' will log you out.' + '\n\n' + 'If you postpone replying for five minutes, you will be logged out automatically. You will then have to log in again in order to access your home folder and edit records.')) {
                    
                    if (new Date().getTime() - beforeWarningTime >= beforeTimeout) {
                        alert('You have waited too long before confirming your intention to stay logged in to Tamboti, so you have been logged out.' + '\n\n' + 'A Tamboti session lasts 30 minutes.');
                        window.location = getIndexPath() + '?logout=1';
                    } else {
                        var params = { action: 'no-op' };
                        $.get(getIndexPath(), params, function (data) {
                            resetSessionTimeoutWarning();
                        });
                    }
                } else {
                    window.location = getIndexPath() + '?logout=1';
                }
            }
            
            function resetSessionTimeoutWarning() {
                clearTimeout(timeoutId);
                timeoutId = setTimeout(showWarning, sessionWarningTimeout);
            };
            
            //intercept ajax requests and reset the session warning
            $(window).ajaxComplete(function() {
                if (typeof sessionWarningTimeout != 'undefined') {
                    resetSessionTimeoutWarning();
                }
            });
            "
        )
    }
else ()