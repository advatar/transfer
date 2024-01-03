var VardGuiden = (function () {
    
    
    function getRequestVerificationToken() {
         let tokenInput = document.getElementsByName("__RequestVerificationToken");
         var antiForgeryToken = tokenInput.length > 0 ? tokenInput[0].value : null;
         //let x = Jpn.Modules.Shared.performJsonPost;
         //Jpn.Modules.Shared.isMobile = function() { return false};
         //console.log(x);
         var options = {"url": "https://journalen.1177.se/JournalCategories/CareDocumentation/DetailView",
                        data: { "id":antiForgeryToken, "param1" : null}
         };
         Jpn.Modules.shared.performJsonPost(options);
         return {"token": antiForgeryToken, "cookie": document.cookie, "useragent": navigator.userAgent};
    }
    
    function redirect() {
        
        // <form id="mvk-saml-redirect" name="form-redirect" action="https://bokadetider.1177.se/Shibboleth.sso/SAML2/POST" method="post">
        // <textarea rows="10" cols="80" name="SAMLResponse" style="display: none">
        // <textarea rows="10" cols="80" name="RelayState" style="display: none">ss:mem:e7c80b0d8590793a3bb6a28ad5e105a9911340e868353fc62526142abb3f6992</textarea>
    

        let tokenInput = document.getElementsByName("SAMLResponse");
        var samlToken = tokenInput.length > 0 ? tokenInput[0].value : null;

        let stateInput = document.getElementsByName("RelayState");
        var stateToken = stateInput.length > 0 ? stateInput[0].value : null;

        var options = {"url": "https://bokadetider.1177.se/Shibboleth.sso/SAML2/POST",
                       data: { "SAMLResponse":samlToken, "RelayState": stateToken }
        };
        
        Jpn.Modules.shared.performJsonPost(options);

        return document.documentElement.innerHTML;
    }
    
    function getSource() {
        return document.documentElement.innerHTML;
    }

    function getExcel() {
        let tokenInput = document.getElementsByName("__RequestVerificationToken");
        if (tokenInput) {
            var antiForgeryToken = tokenInput.length > 0 ? tokenInput[0].value : null;
            if (antiForgeryToken) {
                let meta = {"token": antiForgeryToken, "cookie": document.cookie, "useragent": navigator.userAgent};
                return { "meta": meta, "error": "no error"};
            } else {
                return { "meta": {}, "error": "no token"};
            }
        } else {
            return { "meta": {}, "error": "no tokenInput"};
        }
    }

    function getDiagnosis() {
        return document.documentElement.innerHTML;

    }
    
    function getCareDocumentation() {
        
        let tbodies = document.getElementsByClassName("ic-section ic-section--no-margin ic-section--no-padding");
        let tbody = tbodies[0];
        
        return tbody.innerHTML;
        
        var notes = [];
        var note = {};
        var hasDetails = false;

        if (tbody) {
            for (var j = 0; j < tbody.rows.length; j++) {
                var row = tbody.rows[j];
                if (row.className == "subrow") {
                    var details = {};
                    hasDetails = true;
                    note.hasDetails = true;
                    note.subrow = row.innerHTML;
                    //let headlines = row.querySelectorAll('div.style="margin-left: 10px"');
                    let headlines10 = Array.from(row.querySelectorAll('div[style="margin-left: 10px"]'));
                    let headlines20 = Array.from(row.querySelectorAll('div[style="margin-left: 20px"]'));
                    let headlines = headlines10.concat(headlines20);
                    let hlength = headlines.length;
                    var row = {};
                    details.rows = [];
                    for (i = 0; i<hlength ;i++ ) {
                        let headline = headlines[i];
                        if (headline.className == "hidden-print visible-phone ") {
                            let top = headline.querySelectorAll('div')[0];
                            if (top) {
                                let bot = top.querySelectorAll('div')[0];
                                if (bot) {
                                    let summary = bot.innerHTML.trim();
                                    row.text = summary;
                                    details.rows.push(row);
                                }
                            }
                        } else {
                            let title = headline.querySelectorAll('strong')[0].innerHTML;
                            row = {};
                            row.title = title;
                        }
                    }
                    
                    note.details = details;
                    notes.push(note);
                } else {
                    note = {};
                    var l = 0;
                    let attr = row.attributes["data-id"];
                    if (attr) {
                        var id = attr.value;
                        note.id = id;
                    } else {
                        note.id = "";
                    }
                    for (var k = 0; k < row.cells.length; k++) {
                        var cell = row.cells[k];
                        if (cell.className == "visible-phone") { // the
                            var datum= cell.querySelectorAll('strong')[0].innerHTML;
                            note.date = datum;
                        }
                        let txt =  cell.innerHTML.trim();
                        if (cell.className == "hidden-phone") {
                            if (l==0) {
                                note.type = txt;
                            } else if (l==1) {
                                note.actor = txt;
                            } else if (l==2) {
                                note.clinic = txt;
                            }
                            l++;
                        }
                    }
                    if (!hasDetails) {
                        notes.push(note);
                    }
                }
            }
            let tokenInput = document.getElementsByName("__RequestVerificationToken");
            var antiForgeryToken = tokenInput.length > 0 ? tokenInput[0].value : null;
            if (antiForgeryToken) {
                let meta = {"token": antiForgeryToken, "cookie": document.cookie, "useragent": navigator.userAgent};
                return { "meta": meta, "notes": notes};
            } else {
                return { "meta": {}, "notes": notes};
            }
        } else {
            return document.documentElement.innerHTML;
        }
    }
    
    function gotoBankID() {
        let elements = document.getElementsByClassName("ic-card__body");
        if (elements && elements.length > 0) {
            let url = String(elements.item(0).children.item(0).children.item(0).children.item(0).href);
            document.location.href = url;
        } else {
            throw "Page did not load";
        }
    }

    function setPage(url) {
        document.location.href = url;
        return document.innerText;
    }

    function clickToProceed() {
        let elements = document.getElementsByClassName('ic-button ic-button--primary enable-respite');
        let button = elements.item(0);
        if (button) {
            console.log("click");
            button.click();
            return "didClick";
        } else {
            return document.innerText;
        }
    }

    function isLoggedin() {
        if (document.location.href) {
            return document.location.href == "https://e-tjanster.1177.se/mvk/";
        } else {
            return false;
        }
    }

    return {
        setPage: setPage,
        clickToProceed: clickToProceed,
        getSource: getSource,
        gotoBankID: gotoBankID,
        getExcel: getExcel,
        getCareDocumentation: getCareDocumentation,
        redirect: redirect,
        getDiagnosis: getDiagnosis,
        isLoggedin: isLoggedin
    };
    
})()
