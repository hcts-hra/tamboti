xquery version "3.0";

let $cred := "ecpo-admin" || ":" || "edit4Ecpo!"
return
    util:string-to-binary(xs:string($cred))