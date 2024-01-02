//
//  AdvancedTutorialViewController.swift
//  SwiftScraperExample
//
//  Created by Ken Ko on 18/5/17.
//  Copyright © 2017 Ken Ko. All rights reserved.
//
#if canImport(UIKit)
import UIKit
import SwiftSoup
import WebKit
import CoreXLSX
import SwiftUI
import HealthKit
import LabKitUI
import CommonKit

/*
 Viktigt!
 Det är inte tillåtet att, direkt eller indirekt, bereda sig tillgång till uppgifter i Journalen utan Ineras skriftliga godkännande. Exempel på sådan beredning är "scraping" eller annan liknande metod som innebär att data extraheras från Journalen. Att extrahera data från Journalen för att tillgängligöra till andra betraktar Inera också som ett utlämnande genom översändande, spridning eller annat tilhandahållande av uppgifter enligt Personuppgiftslagen (1998:204)
 */


public typealias JSON = [String: Any]
typealias Parameters = [String: String?]

/// This example does a google image search, and then keeps scrolling down to the bottom,
/// until there are no more new images loaded.
public class VardguidenViewController: UIViewController {

    @Binding var model: ObservationsViewModel
    
    public var salt:String?
    var stepRunner: StepRunner!
    var notes = [JournalNote]()
    var hasLoggedIn = false

    public init(model: Binding<ObservationsViewModel>) {
        _model = model
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func postJSON(parameters: Parameters, urlString: String, headers: [String:String], completion: @escaping (Data?, Error?) -> Void) {
        
        guard let url = URL(string: urlString), let data = try? JSONEncoder().encode(parameters) else {
            let error = NSError()
            completion(nil, error)
            return
        }
        var request = URLRequest(url: url)
        for key in headers.keys {
            if let value = headers[key] {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        request.httpMethod = "POST"
        request.httpBody = data
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                logger.info("\(urlString) \(String(describing: error))")
                completion(nil, error)
                return
            }
            completion(data, nil)
        }
        task.resume()
    }
    
    func getXLSX(parameters: Parameters, urlString: String, headers: [String:String], completion: @escaping (Data?, Error?) -> Void) {
        logger.info("1177: getXLSX")
        guard let url = URL(string: urlString) else {
            let error = NSError()
            logger.error("1177: \(error)")
            completion(nil, error)
            return
        }
        var request = URLRequest(url: url)
        for key in headers.keys {
            if let value = headers[key] {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                logger.error("1177: \(urlString) \(String(describing: error))")
                completion(nil, error)
                return
            }
            logger.info("1177: returning data");
            completion(data, nil)
        }
        task.resume()
    }
    
    func parseNoteDetails(doc: SwiftSoup.Document) {
        
        do {
            
            let posts = try doc.select("li[class='nc-list-post']")
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "YYYY-MM-DD"
            
            for post in posts {
                
                logger.debug("JOURNAL: post \(try post.html())")
                
                var noteType: NoteType?
                var noteDate: Date?
                var noteActor: Actor?
                var noteOrganisation: Organisation?
                
                // FIXME: Is this the date of the procedure or when the note was written?
                let dateSpan = try post.select("span[class='iu-hide-sm nu-display-block']")
                if !dateSpan.isEmpty() {
                    let dateText = try dateSpan.text(trimAndNormaliseWhitespace: true)
                    noteDate = dateFormatter.date(from: dateText)
                    logger.debug("JOURNAL: noteDate \(String(describing: noteDate))")
                } else {
                    logger.error("JOURNAL: no date")
                }
                
                let typeSpan = try post.select("span[class='ellipsis-two-line']")
                if !typeSpan.isEmpty() {
                    let typeText = try typeSpan.text(trimAndNormaliseWhitespace: true).trimmingCharacters(in: .whitespacesAndNewlines)
                    noteType = NoteType(rawValue: typeText)
                    if noteType == nil {
                        logger.error("JOURNAL: typeText \(typeText)")
                    }
                    logger.debug("JOURNAL: noteType \(String(describing: noteType))")
                    
                } else {
                    logger.error("JOURNAL: no typeSpan")
                }
                
                // <span class="ellipsis" aria-hidden="true" title="Kerstin Jonsson (Sjuksköterska)">Kerstin Jonsson (Sjuksköterska)</span>
                //<span class="ellipsis" aria-hidden="true" title="Täby Centrum Doktorn">Täby Centrum Doktorn</span>

                var author: String?
                var clinic: String?
                let authorSpan = try post.select("span[class='ellipsis']")
                if !authorSpan.isEmpty() {
                    
                    
                    for (index,el) in authorSpan.array().enumerated() {
                        logger.debug("1177: el \(index) html \(try el.html())  text \(try el.text(trimAndNormaliseWhitespace: true))")
                        if index == 0 {
                            author = try el.text(trimAndNormaliseWhitespace: true)
                        } else if index == 1 {
                            clinic = try el.text(trimAndNormaliseWhitespace: true)
                        }
                    }
                    logger.debug("JOURNAL: author \(String(describing: author)) clinic \(String(describing: clinic))")
                } else {
                    logger.error("JOURNAL: no authorSpan")
                }
                
                if let author {
                    let comp = author.components(separatedBy: " (")
                    if comp.count == 2 {
                        let actorName = comp[0]
                        let tmp = comp[1]
                        let rawqualification = tmp.components(separatedBy: ")")[0]
                        // FIXME let qualification = Qualification(rawValue: rawqualification)
                        noteActor = Actor(name: actorName, qualification: rawqualification)
                    }
                }
                
                if let clinic {
                    noteOrganisation = Organisation(name: clinic)
                }
                //<div class="information-details">
                
                let detailsElements = try post.select("div[class='information-details']")
                let html = try post.html()
                if !detailsElements.isEmpty() {
                    var details = ""
                    for (_, el) in detailsElements.array().enumerated() {
                        details += try el.text(trimAndNormaliseWhitespace: true)
                    }
                    logger.debug("JOURNAL: details \(details)")
                } else {
                    logger.error("JOURNAL: no detailsElements \(html)")
                }
                
                if let noteDate, let noteType, let noteActor, let noteOrganisation {
                    let note = JournalNote(date: noteDate, type: noteType, actor: noteActor, organisation: noteOrganisation, details: [])
                    DispatchQueue.global().async {
                        note.save()
                    }
                } else {
                    logger.error("JOURNAL: did not get all attributes noteDate \(String(describing: noteDate)) noteType \(String(describing: noteType)) noteActor \(String(describing: noteActor)) noteOrganisation \(String(describing: noteOrganisation))")
                }
            }
        } catch {
            logger.error("JOURNAL: \(error.localizedDescription)")
        }
    }
    
    
    func parseDiagnosis(doc: SwiftSoup.Document) {
        
        do {
            
            let posts = try doc.select("li[class='nc-list-post']")
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "YYYY-MM-DD"
            
            for post in posts {
                
                logger.debug("DIAGNOSIS: post \(try post.html())")
                
                var noteType: NoteType?
                var noteDate: Date?
                var noteActor: Actor?
                var noteOrganisation: Organisation?
                
                // FIXME: Is this the date of the procedure or when the note was written?
                let dateSpan = try post.select("span[class='iu-hide-sm nu-display-block']")
                if !dateSpan.isEmpty() {
                    let dateText = try dateSpan.text(trimAndNormaliseWhitespace: true)
                    noteDate = dateFormatter.date(from: dateText)
                    logger.debug("DIAGNOSIS: noteDate \(String(describing: noteDate))")
                } else {
                    logger.error("DIAGNOSIS: no date")
                }
                
                /*
                let typeSpan = try post.select("span[class='ellipsis-two-line']")
                if !typeSpan.isEmpty() {
                    let typeText = try typeSpan.text(trimAndNormaliseWhitespace: true).trimmingCharacters(in: .whitespacesAndNewlines)
                    noteType = NoteType(rawValue: typeText)
                    if noteType == nil {
                        logger.error("DIAGNOSIS: typeText \(typeText)")
                    }
                    logger.debug("DIAGNOSIS: noteType \(String(describing: noteType))")
                    
                } else {
                    logger.error("DIAGNOSIS: no typeSpan")
                }
                */
                noteType = .diagnosis
                
                // <span class="ellipsis" aria-hidden="true" title="Kerstin Jonsson (Sjuksköterska)">Kerstin Jonsson (Sjuksköterska)</span>
                //<span class="ellipsis" aria-hidden="true" title="Täby Centrum Doktorn">Täby Centrum Doktorn</span>

                var author: String?
                var clinic: String?
                let authorSpan = try post.select("span[class='ellipsis']")
                if !authorSpan.isEmpty() {
                    for (index,el) in authorSpan.array().enumerated() {
                        logger.debug("DIAGNOSIS: el \(index) html \(try el.html())  text \(try el.text(trimAndNormaliseWhitespace: true))")
                        if index == 0 {
                            author = try el.text(trimAndNormaliseWhitespace: true)
                        } else if index == 1 {
                            clinic = try el.text(trimAndNormaliseWhitespace: true)
                        }
                    }
                    logger.debug("DIAGNOSIS: author \(String(describing: author)) clinic \(String(describing: clinic))")
                } else {
                    logger.error("DIAGNOSIS: no authorSpan")
                }
                
                if let author {
                    let comp = author.components(separatedBy: " (")
                    if comp.count == 2 {
                        let actorName = comp[0]
                        let tmp = comp[1]
                        let rawqualification = tmp.components(separatedBy: ")")[0]
                        // FIXME let qualification = Qualification(rawValue: rawqualification)
                        noteActor = Actor(name: actorName, qualification: rawqualification)
                    }
                }
                
                if let clinic {
                    noteOrganisation = Organisation(name: clinic)
                }
                //<div class="information-details">
                /*
                let detailsElements = try post.select("div[class='information-details']")
                let html = try post.html()
                if !detailsElements.isEmpty() {
                    var details = ""
                    for (_, el) in detailsElements.array().enumerated() {
                        details += try el.text(trimAndNormaliseWhitespace: true)
                    }
                    logger.debug("DIAGNOSIS: details \(details)")
                } else {
                    logger.error("DIAGNOSIS: no detailsElements \(html)")
                }
                */
                let expandButton = try post.select("div[class='nc-list-post-expander']")
                if !expandButton.isEmpty() {
                    for (_, el) in expandButton.array().enumerated() {
                        let text = try el.text(trimAndNormaliseWhitespace: true)
                        logger.info("DIAGNOSIS: text \(text)")
                    }
                    let dataid = try expandButton.attr("data-id")
                    let date = try expandButton.attr("data-date")
                    logger.info("DIAGNOSIS: dataid \(dataid) date \(date)")
                }
               
                if let noteDate, let noteType, let noteActor, let noteOrganisation {
                    let note = JournalNote(date: noteDate, type: noteType, actor: noteActor, organisation: noteOrganisation, details: [])
                    DispatchQueue.global().async {
                        note.save()
                    }
                } else {
                    logger.error("DIAGNOSIS: did not get all attributes noteDate \(String(describing: noteDate)) noteType \(String(describing: noteType)) noteActor \(String(describing: noteActor)) noteOrganisation \(String(describing: noteOrganisation))")
                }
            }
        } catch {
            logger.error("DIAGNOSIS: \(error.localizedDescription)")
        }
    }

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stepRunner = nil
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
       
        let step1 = OpenPageStep(path: "https://e-tjanster.1177.se/mvk/login/login.xhtml")
        let step2 = PageChangeStep(functionName: "gotoBankID")
        let longWait = WaitStep(waitTimeInSeconds: 30)
        let waitStep = WaitForConditionStep(assertionName: "isLoggedin", timeoutInSeconds: 120)
        let toJournalen = PageChangeStep(functionName: "setPage", params: "https://journalen.1177.se")
        let canProceed = WaitStep(waitTimeInSeconds: 10)
        let careDocumentation = PageChangeStep(functionName: "setPage", params: "/JournalCategories/CareDocumentation")
        let diagnosis = PageChangeStep(functionName: "setPage", params: "/JournalCategories/Diagnosis")
        let bookedTimes = OpenPageStep(path: "https://bokadetider.1177.se")
        
        let medicines = PageChangeStep(functionName: "setPage", params: "https://lakemedelskollen.ehalsomyndigheten.se/lmkoll-web/secured/my-prescriptions.xhtml")
        
        let getMedicines = ScriptStep(functionName: "getSource", params: []) { (response, model) -> StepFlowResult in
            
            logger.info("MEDICINE: source response \(String(describing: response)) model \(model)")
            
            guard let html = response as? String else {
                return .failure(NSError(domain: "health.invivo.diagnostics", code: -1))
            }
            
            do {
                let doc: SwiftSoup.Document = try SwiftSoup.parse(html)
                print("MEDICINE: \(doc)")
            } catch let error {
                logger.error("MEDICINE: \(error)")
                return .failure(NSError(domain: "health.invivo.diagnostics", code: -1))
            }

            return .proceed
        }
        
        let getBookings = ScriptStep(functionName: "getSource", params: []) { (response, model) -> StepFlowResult in
            
            logger.info("1177: source response \(String(describing: response)) model \(model)")
            
            guard let html = response as? String else {
                return .failure(NSError(domain: "health.invivo.diagnostics", code: -1))
            }
            
            do {
                let doc: SwiftSoup.Document = try SwiftSoup.parse(html)
                let text = try doc.text(trimAndNormaliseWhitespace: true)
                if text.contains("Inga bokade tider") {
                    return .proceed
                } else {
                    print("BOOKED: text \(text)")
                }
            } catch let error {
                logger.error("\(error)")
                return .failure(NSError(domain: "health.invivo.diagnostics", code: -1))
            }

            return .proceed
        }
        
        let clickToProceed = ScriptStep(functionName: "clickToProceed", params: []) { (response, model) -> StepFlowResult in
            logger.info("1177: response \(String(describing: response)) model \(model)")
            return .proceed
        }
        
        let done = ScriptStep(functionName: "clickToProceed", params: []) { (response, model) -> StepFlowResult in
            defer {
                DispatchQueue.main.async {
                    self.dismiss(animated: true)
                }
            }
            return .proceed
        }
    
        struct RequestParameters: Codable {
            let id: String
            let param1: String?
        }
        
        let processCareDocumentation = ScriptStep(functionName: "getCareDocumentation", params: []) { (response, model) -> StepFlowResult in
            
            guard let html = response as? String else {
                return .failure(NSError(domain: "health.invivo.diagnostics", code: -1))
            }
            
            do {
                let doc: SwiftSoup.Document = try SwiftSoup.parse(html)
                logger.info("processCareDocumentation \(doc)")
                let _ = self.parseNoteDetails(doc: doc)
            } catch let error {
                logger.error("\(error)")
                return .failure(NSError(domain: "health.invivo.diagnostics", code: -1))
            }
            return .proceed
            
        }
        
        let processDiagnosis = ScriptStep(functionName: "getDiagnosis", params: []) { (response, model) -> StepFlowResult in
            
            guard let html = response as? String else {
                return .failure(NSError(domain: "health.invivo.diagnostics", code: -1))
            }
            
            do {
                let doc: SwiftSoup.Document = try SwiftSoup.parse(html)
                logger.info("DIAGNOSIS: processDiagnosis \(doc)")
                let _ = self.parseDiagnosis(doc: doc)
            } catch let error {
                logger.error("\(error)")
                return .failure(NSError(domain: "health.invivo.diagnostics", code: -1))
            }
            return .proceed
        }

        let getExcelFile = ScriptStep(functionName: "getExcel", params: []) { (response, model) -> StepFlowResult in
            if let res = response as? JSON , let meta = res["meta"] as? JSON, let token = meta["token"] as? String, let useragent = meta["useragent"] as? String {
                logger.debug("1177: getExcelFile: res \(res)")
                let store = self.stepRunner.browser.webView.configuration.websiteDataStore
                store.httpCookieStore.getAllCookies { (cookies) in
                    let cookie = HTTPCookie.requestHeaderFields(with: cookies)
                    let serialized_cookie = cookie["Cookie"]!
                    let req = NSMutableURLRequest()
                    req.allHTTPHeaderFields = cookie
                    let headers: [String: String] = [
                        "cache-control": "no-cache, must-revalidate",
                        "Expires": "-1",
                        "Accept-Encoding": "br, gzip, deflate",
                        "Host": "journalen.1177.se",
                        "Accept-Language": "en-us",
                        "Connection": "keep-alive",
                        "Accept": "application/json, text/javascript, */*; q=0.01",
                        "Content-Type": "application/json; charset=UTF-8",
                        "Origin": "https://journalen.1177.se",
                        "Referer": "https://journalen.1177.se/JournalCategories/LaboratoryOutcome",
                        "__RequestVerificationToken": token,
                        "User-Agent": useragent,
                        "X-Requested-With": "XMLHttpRequest",
                        "Cookie" : serialized_cookie
                    ]
                    
                    logger.debug("1177: serialized_cookie \(serialized_cookie)")
                    
                    let urlstring = "https://journalen.1177.se/JournalCategories/LaboratoryOutcome/ExportToExcelFile"
                    self.getXLSX(parameters: [:], urlString: urlstring, headers: headers) { data, error in
                        if let error {
                            logger.error("1177: getExcelFile: \(error)")
                        } else if let data {
                            logger.debug("1177: getXLSX got data")
                            do {
                                try Reader1177.shared.readXLSX(data: data) { model, error in
                                    if let error {
                                        logger.error("1177: \(error)")
                                        let alertController = UIAlertController(title: "Error", message: "Critical error; \(error.localizedDescription)", preferredStyle: .alert)
                                        let okAction = UIAlertAction(title: "OK", style: .default) {_ in
                                            self.dismiss(animated: true)
                                        }
                                        alertController.addAction(okAction)
                                        /*
                                        DispatchQueue.main.async {
                                            self.present(alertController, animated: true)
                                        }*/
                                    } else if let model {
                                        //logger.info("1177: success")
                                        self.model = model
                                    }
                                }
                            }  catch let error {
                                logger.error("1177: \(error)")
                                let alertController = UIAlertController(title: "Error", message: "Critical error; \(error.localizedDescription)", preferredStyle: .alert)
                                let okAction = UIAlertAction(title: "OK", style: .default) {_ in
                                    self.dismiss(animated: true)
                                }
                                alertController.addAction(okAction)
                                /*
                                DispatchQueue.main.async {
                                    self.present(alertController, animated: true)
                                }
                                 */
                            }
                        }
                    }
                }
            }
            return .proceed
        }
 
        let userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.0.3 Safari/605.1.15"
        stepRunner = StepRunner(moduleName: "VardGuiden",
                                customUserAgent: userAgent,
                                steps:  [step1, step2, longWait, waitStep, toJournalen, canProceed, clickToProceed, canProceed, getExcelFile, careDocumentation, canProceed, processCareDocumentation, canProceed, diagnosis, canProceed, processDiagnosis, canProceed, bookedTimes, canProceed, getBookings, medicines, canProceed, getMedicines, done])
        
        let instructionsLabel = UILabel()
        instructionsLabel.textColor = .systemRed
        instructionsLabel.numberOfLines = 0
        instructionsLabel.text = "After logging in with Bankid you need to manually go back to the app."
        instructionsLabel.textAlignment = .center
        instructionsLabel.sizeToFit()
        view.addSubview(instructionsLabel)
        let browserView = UIView()
        view.addSubview(browserView)
        instructionsLabel.translatesAutoresizingMaskIntoConstraints = false
        browserView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            instructionsLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor, constant: 8.0),
            instructionsLabel.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor, constant: -8.0),
            instructionsLabel.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),

            browserView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            browserView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            browserView.topAnchor.constraint(equalTo: instructionsLabel.bottomAnchor, constant: 8.0),
            browserView.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor)
            
        ])
        
        stepRunner.insertWebViewIntoView(parent: browserView)

        stepRunner.state.afterChange.add { change in
            logger.debug("----- \(change.newValue) -----")
            switch change.newValue {
            case .inProgress(let index):
                logger.debug("1177: About to run step at index \(index)")
            case .failure(let error):
                logger.error("1177: Failed: \(error)")
                self.stepRunner = nil
                if let error = error as? SwiftScraperError {
                    let alertController = UIAlertController(title: "Error", message: "Temporary error; \(error.localizedDescription). Please try again.", preferredStyle: .alert)
                      let okAction = UIAlertAction(title: "OK", style: .default) {_ in
                        self.dismiss(animated: true)
                    }
                    alertController.addAction(okAction)
                    self.present(alertController, animated: true)
                }
                // TODO: Tell the user
            case .success:
                logger.debug("1177: Finished successfully \(self.stepRunner.model)")
            default:
                break
            }
        }
        
        stepRunner.run()
        
    }
    
}



/* Some snippets:
 
 
 if let res = response as? JSON , let meta = res["meta"] as? JSON, let arr = res["notes"] as? [JSON] {
     print("processCareDocumentation res \(res)")
     let store = self.stepRunner.browser.webView.configuration.websiteDataStore
     store.httpCookieStore.getAllCookies { (cookies) in
         let cookie = HTTPCookie.requestHeaderFields(with: cookies)
         let serialized_cookie = cookie["Cookie"]!
         let urlstring = "https://journalen.1177.se/JournalCategories/CareDocumentation/DetailView"

         arr.forEach { json in
             
             if let id = json["id"] as? String, let dat = json["date"] as? String, let type = json["type"] as? String, let actor = json["actor"] as? String, let clinic = json["clinic"] as? String, let url = URL(string: urlstring) {

                 let param = RequestParameters(id: id, param1: nil)
                 if let data = try? JSONEncoder().encode(param) {
                     var request = URLRequest(url: url)

                     request.setValue("no-cache, must-revalidate", forHTTPHeaderField: "cache-control")
                     request.setValue("-1", forHTTPHeaderField: "Expires")
                     request.setValue("br, gzip, deflate", forHTTPHeaderField: "Accept-Encoding")
                     request.setValue("journalen.1177.se", forHTTPHeaderField: "Host")
                     request.setValue("en-us", forHTTPHeaderField: "Accept-Language")
                     request.setValue("keep-alive", forHTTPHeaderField: "Connection")
                     //request.setValue("application/json, text/javascript, star/star q=0.01", forHTTPHeaderField: "Accept")
                     request.setValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-Type")
                     request.setValue("https://journalen.1177.se", forHTTPHeaderField: "Origin")
                     request.setValue("https://journalen.1177.se/JournalCategories/CareDocumentation", forHTTPHeaderField: "Referer")
                     request.setValue(meta["token"] as! String, forHTTPHeaderField: "__RequestVerificationToken")
                     request.setValue(meta["useragent"] as! String, forHTTPHeaderField: "User-Agent")
                     request.setValue("XMLHttpRequest", forHTTPHeaderField: "X-Requested-With")
                     request.setValue(serialized_cookie, forHTTPHeaderField: "Cookie")
                     request.httpMethod = "POST"
                     request.httpBody = data

                     let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                         
                         if let error {
                             logger.error("\(error)")
                         } else if let data {
                             logger.info("response \(response)")
                             let str = String(data: data, encoding: .utf8)
                             logger.debug("1177: json \(str)")
                         }
                         
                         /*
                         switch response.result {
                         case .success:
                             if let json = response.value, let html = json["PartialView"] {
                                 print("processCareDocumentation \(json) \(html)")
                                 do {
                                     let doc: SwiftSoup.Document = try SwiftSoup.parse(html)
                                     let details = self.parseNoteDetails(doc: doc)
                                     
                                     let note = Note(id: id, datestring: dat, typestring: type, actor: actor, organisation: clinic, details: details, jsonArr: nil)
                                     
                                     self.notes.append(note)
                                     print("processCareDocumentation \(note)")
                                     let noteObject = NoteObject(note: note)
                                     print("processCareDocumentation \(noteObject)")
                                     
                                     self.realmManager.createOrUpdate(model: note, with: NoteObject.init)
                                     
                                     DispatchQueue.main.async {
                                         self.tableView.reloadData()
                                     }
                                     
                                 } catch Exception.Error(let type, let message) {
                                     print("processCareDocumentation \(type) \(message)")
                                 } catch {
                                     print("processCareDocumentation \(error)")
                                 }
                             } else if let json = response.value {
                                 print("processCareDocumentation did not get PartialView \(json)")
                             } else {
                                 print("processCareDocumentation did not get JSON \(String(describing: response.value))")
                             }
                         case .failure(let error):
                             print("processCareDocumentation \(error)")
                         }*/
                     }
                     task.resume()
                 }
             }
         }
     }
 }
 return .proceed
 
 
 */
#endif
