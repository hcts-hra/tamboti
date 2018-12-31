var dragon;
var mouseTracker;
$( document ).ready(function() {
    dragon = OpenSeadragon({
            // debugMode: true,
            timeout: 120000,
            id: "openseadragon1",
            prefixUrl: "openseadragon/images/",
            tileSources: [
                "http://kjc-sv002.kjc.uni-heidelberg.de:8080/fcgi-bin/iipsrv.fcgi?IIIF=kjc-sv016/commons/Faizulloev/i_a81901a2-a203-40b9-ba4c-3a793d457c8d.tif/info.json",
                "http://kjc-sv002.kjc.uni-heidelberg.de:8080/fcgi-bin/iipsrv.fcgi?IIIF=kjc-sv016/KMH_Grabungsplaene/Bilddokumentation/1975%20Fotonegative%20SW/Film07_1975_07_24/01.tif/info.json",
                "http://kjc-sv002.kjc.uni-heidelberg.de:8080/fcgi-bin/iipsrv.fcgi?IIIF=kjc-sv016/KMH_Grabungsplaene/Grabungspl%C3%A4ne/1975%20Fl.%205%20Detailzeichnung%20Pferdegeschirr%20im%20Planum/comb/Fl5_Barackenschicht_B62.tif/info.json",
                "http://kjc-ws2.kjc.uni-heidelberg.de:6081/exist/apps/tamboti/modules/display/image.xql?schema=IIIF&call=/i_b24f7d95-5d49-5a16-a80f-6e3acc408d54/info.json",
                "http://kjc-ws2.kjc.uni-heidelberg.de:6081/exist/apps/tamboti/modules/display/image.xql?schema=IIIF&call=/i_c610c420-cae4-4013-9825-23294de346df/info.json",
                "http://kjc-ws2.kjc.uni-heidelberg.de:8650/exist/apps/tamboti/modules/display/image.xql?schema=IIIF&call=/i_c610c420-cae4-4013-9825-23294de346df/info.json"
        ],
            sequenceMode: true,
            initialPage: 1,
            imageLoaderLimit: 10,
            showNavigator: true,
            showRotationControl: true,
        });

});