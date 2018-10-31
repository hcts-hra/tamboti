xquery version "3.1";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:method "html5";
declare option output:media-type "text/html";

let $bilder :=  ( "kjc-sv016/commons/Priya%20Paul%20Collection/t_metadata.f_preview.119395-118002-original.tif", "kjc-sv016/commons/Priya%20Paul%20Collection/t_metadata.f_preview.120632-119227-original.tif", "kjc-sv016/commons/Priya%20Paul%20Collection/t_metadata.f_preview.108133-105100-original.tif", "kjc-sv016/commons/Priya%20Paul%20Collection/t_metadata.f_preview.108401-105294-original.tif", "kjc-sv016/commons/Priya%20Paul%20Collection/t_metadata.f_preview.108857-105787-original.tif", "kjc-sv016/commons/Priya%20Paul%20Collection/t_metadata.f_preview.109920-106991-original.tif", "kjc-sv016/commons/Priya%20Paul%20Collection/t_metadata.f_preview.108310-105231-original.tif", "kjc-sv016/commons/Priya%20Paul%20Collection/t_metadata.f_preview.120493-119088-original.tif", "kjc-sv016/commons/Priya%20Paul%20Collection/t_metadata.f_preview.108375-105274-original.tif", "kjc-sv016/commons/Priya%20Paul%20Collection/t_metadata.f_preview.118625-117153-original.tif", "kjc-sv016/commons/Priya%20Paul%20Collection/t_metadata.f_preview.120687-119282-original.tif", "kjc-sv016/commons/Priya%20Paul%20Collection/t_metadata.f_preview.120171-118766-original.tif", "kjc-sv016/commons/Priya%20Paul%20Collection/t_metadata.f_preview.119777-118372-original.tif", "kjc-sv016/commons/Priya%20Paul%20Collection/t_metadata.f_preview.118309-116837-original.tif", "kjc-sv016/commons/Priya%20Paul%20Collection/t_metadata.f_preview.118451-267173-original.tif", "kjc-sv016/commons/Priya%20Paul%20Collection/t_metadata.f_preview.120917-119512-original.tif", "kjc-sv016/commons/Priya%20Paul%20Collection/t_metadata.f_preview.119052-117634-original.tif", "kjc-sv016/commons/Priya%20Paul%20Collection/t_metadata.f_preview.119488-118088-original.tif", "kjc-sv016/commons/Priya%20Paul%20Collection/t_metadata.f_preview.108065-105040-original.tif", "kjc-sv016/commons/Priya%20Paul%20Collection/t_metadata.f_preview.108876-105805-original.tif", "kjc-sv016/commons/Priya%20Paul%20Collection/t_metadata.f_preview.120539-119134-original.tif", "kjc-sv016/commons/Priya%20Paul%20Collection/t_metadata.f_preview.120496-119091-original.tif", "kjc-sv016/commons/Priya%20Paul%20Collection/t_metadata.f_preview.118810-117370-original.tif", "kjc-sv016/commons/Priya%20Paul%20Collection/t_metadata.f_preview.108773-105704-original.tif", "kjc-sv016/commons/Priya%20Paul%20Collection/t_metadata.f_preview.118090-116618-original.tif", "kjc-sv016/commons/Priya%20Paul%20Collection/t_metadata.f_preview.118501-117027-original.tif", "kjc-sv016/commons/Priya%20Paul%20Collection/t_metadata.f_preview.108307-105228-original.tif", "kjc-sv016/commons/Priya%20Paul%20Collection/t_metadata.f_preview.119120-117702-original.tif", "kjc-sv016/commons/Priya%20Paul%20Collection/t_metadata.f_preview.109881-106954-original.tif", "kjc-sv016/commons/Priya%20Paul%20Collection/t_metadata.f_preview.118875-117444-original.tif")

let $t-ids := ( "i_306846ac-29b4-5ac6-b6ae-7a3d46e7cb04", "i_72dc4032-11b4-59c9-803c-616517b50549", "i_503f3ff9-c677-5628-8793-1d3a426ea1b6", "i_0f847509-491f-58fb-9d16-3a38458e7fd1", "i_3c65096a-48a4-5813-b3a9-1c6b42107a3f", "i_6824dfdc-cdd7-524c-b2af-faf92d316ac0", "i_039893e5-8d86-59d2-9487-c285211cad8a", "i_ac64b3df-4279-555a-8b31-16be05017c66", "i_e752e1cf-4087-5aa3-8e78-ff17ec2ac7e4", "i_104ed741-632d-58dd-afdc-8de5f68873e5", "i_64942231-eacb-5240-8102-5ed5d458a5c6", "i_8f6cdb77-1d41-5c91-9f16-df07f13870e4", "i_894db7ff-433f-5bc5-90b4-3d37ed56a37c", "i_8f1e0a8d-6f8b-559a-a815-baabbd2234df", "i_cc61d9e3-d4d1-5089-a105-e79ee329ba70", "i_e9786af2-c24f-5ee9-8876-91093118a834", "i_c4b98b84-1756-5ae4-9220-b16dfee73425", "i_91ee8cc5-0ef5-5a2c-a58b-03e9167c8e20", "i_11fbdd08-4047-5fa5-a165-f1d90dbe707f", "i_836e06a0-4ddc-52a5-aad1-ae0987a2edca", "i_9e077469-23b6-56a0-9af3-80f54ec38855", "i_351d4f82-c98d-5150-92cc-f3a5c0ed081d", "i_b66b4f0d-9158-59f7-8d74-859284871f2c", "i_106920f8-52df-520b-adfe-d57a2f973b08", "i_d4e600e5-e121-5536-b1ef-27b7877c9236", "i_e4deec97-8521-5a2d-82c2-4ba2bdcd34d9", "i_ba21fd4f-9966-5b35-977a-3335f89503dc", "i_8ff69614-5a04-53d3-9d38-4782ed015c9b", "i_05b6cfd2-0464-5a64-b0c2-a7a3a5540e00", "i_7723f499-0559-5960-8312-015e45f19c67")

return
    <div>
        <div>
            {    
                let $uri-prefix := "http://kjc-sv002.kjc.uni-heidelberg.de:6081/iiif/"
                let $uri-suffix := "/full/!128,128/0/default.jpg"
                return
                    for $bild in $bilder
                    return
                        <img src="{$uri-prefix}{$bild}{$uri-suffix}"/>
            }
        </div>
        <div>
            <hr/>
        </div>
        <div>
            {    
                let $uri-prefix := "http://kjc-sv002.kjc.uni-heidelberg.de:6081/iiif/"
                let $uri-suffix := "/full/!128,128/0/default.jpg"
                return
                    for $bild in $bilder
                        let $response := httpclient:get(xs:anyURI($uri-prefix || $bild || $uri-suffix), true(), ())
                        let $body := $response/httpclient:body/data()
                        return
                            <img src="data:image/jpeg;charset=utf-8;base64,{$body}"/>
            }
        </div>
        <div>
            <hr/>
        </div>
        <div>
            {    
                let $uri-prefix := "/exist/apps/tamboti/iiif/"
                let $uri-suffix := "/full/!128,128/0/default.jpg"
                return
                    for $id in $t-ids
                    return
                        <img src="{$uri-prefix}{$id}{$uri-suffix}"/>
            }
        </div>
    </div>