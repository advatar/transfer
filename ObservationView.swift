//
//  SwiftUIView.swift
//  
//
//  Created by Johan Sellström on 2022-09-03.
//
#if os(iOS) && canImport(UIKit) && canImport(ResearchKit)

import SwiftUI
import UIKit

import CareKit
import CareKitUI
import CareKitStore

import HealthKit
import Charts
import CoreML
import Vision
import DateToolsSwift
import LabKitUI
import CommonKit

import LabKitStore
import LabKitAssess


// TODO: Are there cases where the middle is best?
public class SheetDismisserDelegate: ObservableObject {
    weak public var host: UIHostingController<AnyView>? = nil

    public init() {}
    
    public func dismiss() {
        host?.dismiss(animated: true)
    }
}




fileprivate struct ChartData {
    /// A data series for the lines.
    struct Series: Identifiable {
        /// The name of the city.
        let name: String
        
        /// Average daily sales for each weekday.
        /// The `weekday` property is a `Date` that represents a weekday.
        let values: [MyChartPoint]
        
        let lineWidth: CGFloat
        
        /// The identifier for the series.
        var id: String { name }
    }
    
    /// Sales by location and weekday for the last 30 days.
    var curve: [Series] = [ ]

}




public struct ObservationView: View {
    @State var type: MySampleType

    public var body: some View {
        Text("\(type.title)")
    }
}

public struct ImageDetailView: View {
    
    var item: Dummy
    
    public var body: some View {
        GeometryReader { geo in
            List {
                
                DicomDetailView(data: nil)
                /*
                 
                 Text("MRI")
                
                if !item.values.isEmpty, item.values.count>1  {
                    ChartView(curve: item.values, low: item.range?.low, high: item.range?.high, average: item.range?.populationAverage)
                        .listRowInsets(.init(top: 0, leading: 0, bottom: 8, trailing: 0))
                        .listRowSeparator(.hidden)
                }
                if let about = item.about {
                    HStack {
                        Text(about).multilineTextAlignment(.leading)
                        Spacer()
                    }.listRowSeparator(.hidden)
                }
                ForEach(item.values.reversed()) { value in
                    SampleView(item: item, value: value)
                        .listRowInsets(.init(top: 0, leading: 0, bottom: 8, trailing: 0)).listRowSeparator(.hidden)
                }
                if !item.type.ids.isEmpty, let range = item.range {
                    GeneticsView(ids: item.type.ids, isHigh: range.isHigh, isLow: range.isLow)
                }
                 */
            }.padding(EdgeInsets())
        }
        .navigationTitle(item.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    if let url = URL(string: "https://www.google.com") {
                        ShareLink(item: url)
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
    }
}

struct CardoView: View {
    var body: some View {
        Text("Being implemented now...")
    }
}



     
extension HKCategorySample: Identifiable {
    
}


public struct SymptomsChartView: View {
    
    let samples: [HKCategorySample]
    
    @State var points: [MyChartPoint] = []
    @State var showAverageLine = false
    
    public init(samples: [HKCategorySample]) {
        self.samples = samples
    }
    let labels: [String] = ["Not Present","Present","Mild","Moderate","Severe"]
    let gradient = Gradient(colors: [.red, .yellow, .green])
    private func normalize(_ value: Int) -> Double {
        switch value {
        case 0: // Present
            return 1.0
        case 1:
            return 0.0
        case 2:
            return 2.0
        case 3:
            return 3.0
        case 4:
            return 4.0
        default:
            return -1.0
        }
    }
    
    let dateformatter = DateFormatter()
    
    public var body: some View {
        List {
            //CardView {
                Chart {
                    ForEach(points, id: \.date) {
                        PointMark(
                            x: .value("Minute", $0.date),
                            y: .value("Severity", $0.value)
                        )
                        .foregroundStyle(showAverageLine ? .gray.opacity(0.3) : .blue)
                        .symbol {
                            Image(systemName: "smallcircle.filled.circle")
                                .zIndex(10)
                                .background(Color(UIColor.systemBackground).mask(Circle()))
                                .font(.caption)
                        }
                    }.symbolSize(300)
                }.task {
                    points = []
                    for sample in samples {
                        let point = MyChartPoint(value: normalize(sample.value), date: sample.startDate)
                        points.append(point)
                    }
                }.padding()
                    .chartYAxis {
                        AxisMarks(values: [0,1,2,3,4]) {
                            let value = $0.as(Int.self)!
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel {
                                Text("\(labels[value])")
                            }
                        }
                    }.frame(height: 300)
            //}
            //List {
            Section("All data") {
                ForEach(points, id: \.date) { point in
                    HStack {
                        Text("\(labels[Int(point.value)])")
                        Spacer()
                        Text("\(point.date.timeAgoSinceNow)")
                            .fontWeight(.medium)
                            .font(.caption)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            //}
        }
    }
}

public struct MedicationsSectionView: View {
    
    @Environment(\.storeManager) private var storeManager
    @State var medications: [OCKTask] = []
    @State var medicationAdherences: [MedicationAdherence] = []
    @State var isPresentingAddMedication = false
    
    public init() {
        
    }
    
    struct MedicationAdherence: Identifiable {
        public let id = UUID()
        let medication: String
        let adherence: [MyChartPoint]
        let average: Double
        public init(medication: String, adherence: [MyChartPoint]) {
            self.medication = medication
            self.adherence = adherence
            var sum=0.0
            for a in adherence {
                sum += a.value
            }
            if adherence.count > 0 {
                average = 100.0*sum/Double(adherence.count)
            } else {
                average = 0.0
            }
        }
    }
    
    public var body: some View {
        Section("Medication Adherence") {
            Section {
                // Loop over all tasks
                if medicationAdherences.isEmpty  {
                    Text("No medications")
                } else {
                    ForEach(medicationAdherences) { medicationAdherence in
                        NavigationLink {
                            Chart {
                                ForEach(medicationAdherence.adherence, id: \.date) {
                                    LineMark(
                                        x: .value("Date", $0.date),
                                        y: .value("Adherence", $0.value)
                                    )
                                }
                            }
                            .padding()
                            .navigationBarTitle(medicationAdherence.medication, displayMode: .inline )
                        } label: {
                            HStack {
                                Text(medicationAdherence.medication)
                                Spacer()
                                Text("\(medicationAdherence.average.string(toPlaces: 0)) %")
                                    .multilineTextAlignment(.trailing)
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                }
            }
        }.sheet(isPresented: $isPresentingAddMedication) {
            NavigationView {
                AddMedicationsView(isPresentingAddMedications: $isPresentingAddMedication)
                //.presentationDetents([.large])
            }
        }
        .navigationTitle("Medication Diary")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isPresentingAddMedication = true
                } label: {
                    Text("Add Medication")
                }
            }
        }.task {
            var query = OCKTaskQuery()
            query.excludesTasksWithNoEvents = true
            query.groupIdentifiers = ["medication"]
            
            if medications.isEmpty {
                if let tasks = try? await storeManager.store.fetchAnyTasks(query: query) as? [OCKTask], !tasks.isEmpty {
                    logger.info("tasks \(tasks)")
                    medications = tasks
                }
            }
           
            let range = CalendarRange(calendar: Calendar.current, component: .day, epoch: Date(), values: -3_0 ... 1)
            
            var adherenceArray: [String: [MyChartPoint]] = [:]
            
            // FIXME: Only when there is an event
            if medicationAdherences.isEmpty {
                Task {
                    if let tasks = try? await storeManager.store.fetchAnyTasks(query: query), !tasks.isEmpty {
                        
                        for task in tasks {
                            logger.info("ADHERENCE: start \(task.schedule.startDate())")
                            let startDate = task.schedule.startDate()
                            for date in range  {
                                if date >= startDate {
                                    let aDayAgo = Calendar.current.date(byAdding: .day, value: -1, to: date)!
                                    let interval = DateInterval(start: aDayAgo, end: date)
                                    var query = OCKAdherenceQuery(taskIDs: [task.id], dateInterval: interval, aggregator: .percentOfTargetValuesMet)
                                    query.aggregator = CareKitStore.OCKAdherenceAggregator.percentOfOutcomeValuesThatExist
                                    if let adherences = try? await storeManager.store.fetchAdherence(query: query) {
                                        
                                        var progress = -1.0
                                        
                                        for adherence in adherences {
                                            
                                            switch adherence {
                                            case .noTasks:
                                                progress = 0.0
                                                break
                                            case .noEvents:
                                                progress = 0.0
                                                break
                                            case .progress(let double):
                                                progress = double
                                            }
                                            let point = MyChartPoint(value: progress, date: date)
                                            if let arr = adherenceArray[task.id] {
                                                adherenceArray[task.id] = arr + [point]
                                            } else {
                                                adherenceArray[task.id] = [point]
                                            }
                                            
                                            //if progress > 0 {
                                            //logger.info("ADHERENCE: \(task.id) interval \(interval) adherence \(adherence) progress \(progress)")
                                        }
                                    } else {
                                        //logger.info("ADHERENCE: adherence missing")
                                    }
                                }
                            }
                        }
                        //logger.info("ADHERENCE: \(adherenceArray)")
                        medicationAdherences = []
                        for key in adherenceArray.keys {
                            for task in tasks {
                                if key == task.id, let arr = adherenceArray[key] {
                                    let medAdh = MedicationAdherence(medication: task.id, adherence: arr)
                                    medicationAdherences.append(medAdh)
                                }
                            }
                        }
                    } else {
                        //logger.info("tasks missing")
                    }
                }
            }
        }
    }
}

struct InsightsView: View {
    
    @Binding var isPresentingInsights: Bool
    
    @State private var path = NavigationPath()

    //var picker: DocumentPicker
    
    @State var conditionAge: Double = -1.0
    @State var hrvAge: Double = -1.0
    @State var age: Double = 0.0
    @State var bioAge: Double = 0.0
    @State var bioAges: [BioAge] = []
    @State var metabolicFitness: Double = 0.0
    @State private var image: UIImage?
    @State private var isPresentingImagePicker = false
    @Binding private var isPresenting23andme: Bool
    @State private var predictionLabel: String = ""
    @State var hasMicrobiome = false
    @State var hasGenome = false
    let config = LabConfig()
    let vo2MaxType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.vo2Max)!
    let hrvType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRateVariabilitySDNN)!

    @State var lipidQuotas = [MyChartPoint]()
    
    @State var microbiomeDiversity: Double = 0.0
    @State var microbiomeComment = ""
    @State var levine: LevineInput = LevineInput()

    var biologicalSex = LabConfig().biologicalSex!
    
    public init(isPresentingInsights: Binding<Bool>, isPresenting23andme: Binding<Bool>) {
        _isPresentingInsights = isPresentingInsights
        _isPresenting23andme = isPresenting23andme
    }
    
    func detectAge(image: CIImage) {
        
        // Load the ML model through its generated class
        let config = MLModelConfiguration()
        guard  let m = try? AgeNet(configuration: config).model, let model = try? VNCoreMLModel(for: m) else {
            fatalError("can't load AgeNet model")
        }
        
        // Create request for Vision Core ML model created
        let request = VNCoreMLRequest(model: model) { request, error in
            guard let results = request.results as? [VNClassificationObservation],
                let topResult = results.first else {
                    fatalError("unexpected result type from VNCoreMLRequest")
            }
            
            // Update UI on main queue
            DispatchQueue.main.async {
                self.predictionLabel = "I think your age is \(topResult.identifier) years!"
            }
        }
        
        // Run the Core ML AgeNet classifier on global dispatch queue
        let handler = VNImageRequestHandler(ciImage: image)
        DispatchQueue.global(qos: .userInteractive).async {
            do {
                try handler.perform([request])
            } catch {
                print(error)
            }
        }
    }
    
    
    struct CardioSectionView: View {
        
        @Binding var conditionAge: Double
        @Binding var hrvAge: Double
        @Binding var lipidQuotas: [MyChartPoint]
        @State var lipidItem: ObservationsListItem?
        
        var biologicalSex: HKBiologicalSex
        
        func lipidIndicator() -> any View {
            let count = lipidQuotas.count
            if count > 1 {
                let diff = lipidQuotas[count-1].value - lipidQuotas[count-2].value
                if diff > 0 {
                    return Image(systemName: "arrow.up.forward.circle.fill").foregroundColor(.red)
                } else if diff < 0 {
                    return Image(systemName: "arrow.down.forward.circle.fill").foregroundColor(.green)
                } else if diff == 0 {
                    return Image(systemName: "arrow.right.circle.fill").foregroundColor(.gray)
                }
            }
            return Image(systemName: "questionmark.circle.fill").foregroundColor(.gray)
        }
        
        var body: some View {
            
            
            Section("Cardio") {
                if conditionAge > 0.0 {
                    NavigationLink {
                        Text("Nothing to see yet..")
                    } label: {
                        HStack {
                            Text("Fitness:").fontWeight(.bold)
                            Spacer()
                            Text("\(self.conditionAge.string(toPlaces: 0)) y").multilineTextAlignment(.trailing)
                            Image(systemName: "arrow.right.circle.fill").foregroundColor(.orange)
                        }
                    }
                } else {
                    NavigationLink {
                        Text("You need a smartwatch like Apple Watch to get these values.")
                    } label: {
                        HStack {
                            Text("Fitness").fontWeight(.medium)
                            Spacer()
                            Image(systemName: "questionmark.circle.fill").foregroundColor(.black)
                        }
                    }
                }
                
                if !self.lipidQuotas.isEmpty, let lastPoint = self.lipidQuotas.last {
                    NavigationLink {
                        if let lipidItem  {
                            DetailView(item: lipidItem, biologicalSex: biologicalSex)
                        }
                    } label: {
                        HStack {
                            Text("Lipid Quota:").fontWeight(.medium)
                            Spacer()
                            // TODO: It should be a range
                            Text("\(lastPoint.value.string(toPlaces: 1))").multilineTextAlignment(.trailing).foregroundColor(lastPoint.value < 1.2 ? Color.green:Color.red)
                            //lipidIndicator()
                            if lipidQuotas.count > 1 {
                                let diff = lipidQuotas[lipidQuotas.count-1].value - lipidQuotas[lipidQuotas.count-2].value
                                if diff > 0 {
                                    Image(systemName: "arrow.up.forward.circle.fill").foregroundColor(.red)
                                } else if diff < 0 {
                                    Image(systemName: "arrow.down.forward.circle.fill").foregroundColor(.green)
                                } else if diff == 0 {
                                    Image(systemName: "arrow.right.circle.fill").foregroundColor(.gray)
                                }
                            }
                        }
                    }
                }
                
                if self.hrvAge > 0 {
                    NavigationLink {
                        Text("Nothing to see yet..")
                    } label: {
                        HStack {
                            Text("HRV").fontWeight(.medium)
                            Spacer()
                            Text("\(self.hrvAge.string(toPlaces: 0)) y").multilineTextAlignment(.trailing)
                            Image(systemName: "arrow.right.circle.fill").foregroundColor(.orange)
                        }
                    }
                } else {
                    NavigationLink {
                        Text("You need a smartwatch like Apple Watch to get these values.")
                    } label: {
                        HStack {
                            Text("HRV").fontWeight(.medium)
                            Spacer()
                            Image(systemName: "questionmark.circle.fill").foregroundColor(.black)
                        }
                    }
                }
                
                HStack {
                    Text("Risk Score").fontWeight(.medium)
                    Spacer()
                    Text("coming soon")
                }
                
            }.task {
                if !self.lipidQuotas.isEmpty, let lastPoint = self.lipidQuotas.last, let gender = LabConfig().biologicalSex, let age = LabConfig().birthDay?.age() {
                    let current = lastPoint.value
                    let type = MySampleType.lipidQuota
                    let sources = lipidQuotas.map { x in
                        "System"
                    }
                    let range = type.referenceRange(current: current, gender: gender, age: Double(age))
                    lipidItem = ObservationsListItem(
                        date: lastPoint.date,
                        type: type,
                        recentValue: lastPoint.value,
                        recentStatus: nil,
                        values: lipidQuotas,
                        linearTrend: [],
                        linearSlope: 0.0,
                        range: range,
                        sources: sources,
                        wasUserEntered: false,
                        about: type.about,
                        report: nil)
                }
            }
        }
    }
    
    
    struct ConditionsSectionView: View {
        
        @Environment(\.storeManager) private var storeManager
        @State var conditions: [Condition] = []
        
        var body: some View {
            
            Section(header: HStack {
                NavigationLink {
                    ConditionsView()
                } label: {
                    Text("Personal Risk Assessments")
                        .font(.system(size: 13.0))
                        .fontWeight(.thin)
                        .foregroundColor(Color(uiColor: .label))
                    Spacer()
                    Text("More")
                        .font(.system(size: 13.0))
                        .textInputAutocapitalization(.never)
                }
            }) {
                Section {
                    // Loop over all tasks
                    ForEach(conditions) { condition in
                        NavigationLink {
                            Text("\(condition.rawValue)")
                        } label: {
                            HStack {
                                Text("\(condition.rawValue)")
                                Spacer()
                                HStack {
                                    //Text("risk:")
                                    //    .font(.caption)
                                    Text("\(condition.risk != nil ? condition.risk!.string(toPlaces: 0):"?") %")
                                        .multilineTextAlignment(.trailing)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                            }
                        }
                    }
                }
            }.task {
                conditions = Condition.allCases.filter({ c in
                    c.atRisk
                })
            }
        }
    }
    
    
    
    /*
    struct BiologicalAgeSectionView: View {
        
        @Binding var age: Double
        @Binding var bioAge: Double
        @Binding var bioAges: [BioAge]
        @Binding var levine: LevineInput
        let biologicalSex: HKBiologicalSex
        
        var body: some View {
            Section("Biological Age") {
                if bioAges.isEmpty {
                    AgeView(age: age, bioAge: BioAge(type: .levinePhenotypic), levine: $levine)
                        .padding()
                        .disabled(true)
                        .foregroundStyle(.opacity(0.4))
                    Text("You need to upload some results first.")
                        .foregroundColor(.red)
                } else if age>=30 && age<=75 {
                    ForEach(bioAges) { bioAge in
                        AgeView(age: age, bioAge: bioAge, levine: $levine)
                            .padding(.vertical)
                    }
                } else {
                    Text("Sorry, our algorithm has only been validated for ages 30-75 years.")
                        .padding()
                }
            }
        }
    }*/
    
    var body: some View {
        List {
                MedicationsSectionView()
            
        }
        .navigationBarTitle("Insights", displayMode: .inline)
        .onChange(of: image, perform: { newValue in
            print("has image")
            if let image = newValue, let ciImage = CIImage(image: image) {
                detectAge(image: ciImage)
            }
        })
        .sheet(isPresented: $isPresentingImagePicker) {
#if targetEnvironment(simulator)
            let sourceType: UIImagePickerController.SourceType = .photoLibrary
#else
            let sourceType: UIImagePickerController.SourceType = .camera
#endif
            ImagePicker(sourceType: sourceType, selectedImage: $image)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("OK") {
                    isPresentingInsights = false
                }
            }
        }.task {
            hasGenome = config.genes != nil
            let config = LabConfig()
            
            if let age = config.birthDay?.age(), let _ = config.biologicalSex, bioAges.isEmpty {
                self.age = Double(age)
                var numberOfParameters = 0
                if let items = LabConfig().observationsViewModel?.listItems {
                    let albumin = items.filter { item in
                        item.type == .PAlbumin
                    }
                    let albuminQuantity: HKQuantity?
                    if let albuminValue = albumin.last?.recentValue {
                        let type = MySampleType.PAlbumin
                        let unit = type.unit
                        albuminQuantity = HKQuantity(unit: unit, doubleValue: albuminValue)
                        print("BIO: albuminValue \(albuminValue) \(unit)")
                        numberOfParameters += 1
                    } else {
                        albuminQuantity = nil
                    }
                    let creatinine = items.filter { item in
                        item.type == .PKreatinin
                    }
                    let creatinineQuantity: HKQuantity?
                    if let creatinineValue = creatinine.last?.recentValue {
                        let type = MySampleType.PKreatinin
                        let unit = type.unit
                        creatinineQuantity = HKQuantity(unit: unit, doubleValue: creatinineValue)
                        print("BIO: creatinineValue \(creatinineValue) \(unit)")
                        numberOfParameters += 1
                    } else {
                        creatinineQuantity = nil
                    }
                    let glucose = items.filter { item in
                        item.type == .PGlukos
                    }
                    let glucoseQuantity: HKQuantity?
                    if let glucoseValue = glucose.last?.recentValue {
                        let type = MySampleType.PGlukos
                        let unit = type.unit
                        glucoseQuantity = HKQuantity(unit: unit, doubleValue: glucoseValue)
                        print("BIO: glucoseValue \(glucoseValue) \(unit)")
                        numberOfParameters += 1
                    } else {
                        glucoseQuantity = nil
                    }
                    let crp = items.filter { item in
                        item.type == .PCRP
                    }
                    let crpQuantity: HKQuantity?
                    if let crpValue = crp.last?.recentValue {
                        let type = MySampleType.PCRP
                        let unit = type.unit
                        crpQuantity = HKQuantity(unit: unit, doubleValue: crpValue)
                        print("BIO: crpValue \(crpValue) \(unit)")
                        numberOfParameters += 1
                    } else {
                        crpQuantity = nil
                    }
                    // FIXME: What is it called?
                    let lymphocyte = items.filter { item in
                        item.type == .BLPK
                    }
                    let lymphocyteQuantity: HKQuantity?
                    if let lymphocyteValue = lymphocyte.last?.recentValue {
                        let type = MySampleType.BLPK
                        let unit = type.unit
                        lymphocyteQuantity = HKQuantity(unit: unit, doubleValue: lymphocyteValue)
                        print("BIO: lymphocyteValue \(lymphocyteValue) \(unit)")
                        numberOfParameters += 1
                    } else {
                        let unit = HKUnit.percent()
                        lymphocyteQuantity = HKQuantity(unit: unit, doubleValue: 28.0)
                        numberOfParameters += 1
                    }
                    
                    let mcv = items.filter { item in
                        item.type == .BMCV
                    }
                    let mcvQuantity: HKQuantity?
                    if let mcvValue = mcv.last?.recentValue {
                        let type = MySampleType.BMCV
                        let unit = type.unit
                        mcvQuantity = HKQuantity(unit: unit, doubleValue: mcvValue)
                        print("BIO: mcv \(mcvValue) \(unit)")
                        numberOfParameters += 1
                    } else {
                        mcvQuantity = nil
                    }
                    let rdw = items.filter { item in
                        item.type == .BRDW
                    }
                    let rdwQuantity: HKQuantity?
                    if let rdwValue = rdw.last?.recentValue {
                        let type = MySampleType.BRDW
                        let unit = type.unit
                        rdwQuantity = HKQuantity(unit: unit, doubleValue: rdwValue)
                        print("BIO: rdw \(rdwValue) \(unit)")
                        numberOfParameters += 1
                    } else {
                        //let type = MySampleType.BRDW
                        let unit = HKUnit.percent()
                        rdwQuantity = HKQuantity(unit: unit, doubleValue: 13.4)
                        print("BIO: rdw \(13.4) \(unit)")
                        numberOfParameters += 1
                    }
                    let alp = items.filter { item in
                        item.type == .PALP
                    }
                    let alpQuantity: HKQuantity?
                    if let alpValue = alp.last?.recentValue  {
                        let type = MySampleType.PALP
                        let unit = type.unit
                        alpQuantity = HKQuantity(unit: unit, doubleValue: alpValue)
                        print("BIO: alp \(alpValue) \(unit)")
                        numberOfParameters += 1
                    } else {
                        alpQuantity = nil
                    }
                    let wbc = items.filter { item in
                        item.type == .BLeukocyter
                    }
                    let wbcQuantity: HKQuantity?
                    if let wbcValue = wbc.last?.recentValue {
                        let type = MySampleType.BLeukocyter
                        let unit = type.unit
                        wbcQuantity = HKQuantity(unit: unit, doubleValue: wbcValue)
                        print("BIO: wbc \(wbcValue) \(unit)")
                        numberOfParameters += 1
                    } else {
                        wbcQuantity = nil
                    }
                    
                    numberOfParameters += 1 // age
                    
                    print("BIO: had numberOfParameters \(numberOfParameters)")
                    levine = LevineInput(albumin: albuminQuantity, creatinine: creatinineQuantity, glucose: glucoseQuantity, CRP: crpQuantity, lymphocyte: lymphocyteQuantity, MCV: mcvQuantity, RDW: rdwQuantity, ALP: alpQuantity, WBC: wbcQuantity, age: Double(age))
                    let output = Levine.shared.calculate(input: levine)
                    logger.info("BIO: quota \(output.parameterQuota) missing \(output.missing)")
                    let p = BioAge(type: .levinePhenotypic, value: output.phenotypicAge, percent: 100.0*output.parameterQuota, missing: output.missing)
                    self.bioAges.append(p)
                    let d = BioAge(type: .levineDNA, value: output.estDNAmAge, percent: 100.0*output.parameterQuota, missing: output.missing)
                    self.bioAges.append(d)
                    self.bioAge = output.phenotypicAge
        
                }
                
            }
        }
    }
}


struct VardguidenView: View {
    
    @Binding var isPresenting1177: Bool
    @Binding var model: ObservationsViewModel

    public init(isPresenting1177: Binding<Bool>, model: Binding<ObservationsViewModel>) {
        _isPresenting1177 = isPresenting1177
        _model = model
    }
    
    var body: some View {
        VardGuidenWrappedView(model: $model)
            .navigationBarTitle("Vårdguiden 1177", displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Cancel") {
                    isPresenting1177 = false
                }
            }
        }
    }
}


struct SvenskProvtagningView: View {
    
    @Binding var isPresentingSvenskProvtagning: Bool
    @Binding var model: ObservationsViewModel

    public init(isPresentingSvenskProvtagning: Binding<Bool>, model: Binding<ObservationsViewModel>) {
        _isPresentingSvenskProvtagning = isPresentingSvenskProvtagning
        _model = model
    }
    
    var body: some View {
        SvenskProvtagningWrappedView(model: $model)
            .navigationBarTitle("Svensk Provtagning", displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Cancel") {
                    isPresentingSvenskProvtagning = false
                }
            }
        }
    }
}

struct BlodkollenView: View {
    
    @Binding var isPresentingBlodkollen: Bool
    @Binding var model: ObservationsViewModel

    public init(isPresentingBlodkollen: Binding<Bool>, model: Binding<ObservationsViewModel>) {
        _isPresentingBlodkollen = isPresentingBlodkollen
        _model = model
    }
    
    var body: some View {
        BlodkollenWrappedView(model: $model)
            .navigationBarTitle("Blodkollen", displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Cancel") {
                    isPresentingBlodkollen = false
                }
            }
        }
    }
}


struct WerLabKitUI: View {
    
    @Binding var isPresentingWerlabs: Bool
    @Binding var model: ObservationsViewModel

    public init(isPresentingWerlabs: Binding<Bool>, model: Binding<ObservationsViewModel>) {
        _isPresentingWerlabs = isPresentingWerlabs
        _model = model
    }
    
    var body: some View {
        WerlabsWrappedView(model: $model)
            .navigationBarTitle("Werlabs", displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Cancel") {
                    isPresentingWerlabs = false
                }
            }
        }
    }
}

struct LifeCompView: View {
    
    @Binding var isPresentingLifeComp: Bool
    @Binding var model: ObservationsViewModel

    public init(isPresentingLifeComp: Binding<Bool>, model: Binding<ObservationsViewModel>) {
        _isPresentingLifeComp = isPresentingLifeComp
        _model = model
    }
    
    var body: some View {
        LifeCompWrappedView(model: $model)
            .navigationBarTitle("LifeComp", displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Cancel") {
                    isPresentingLifeComp = false
                }
            }
        }
    }
}

struct MediseraView: View {
    
    @Binding var isPresentingMedisera: Bool
    @Binding var model: ObservationsViewModel

    public init(isPresentingMedisera: Binding<Bool>, model: Binding<ObservationsViewModel>) {
        _isPresentingMedisera = isPresentingMedisera
        _model = model
    }
    
    var body: some View {
        MediseraWrappedView(model: $model)
            .navigationBarTitle("Medisera", displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Cancel") {
                    isPresentingMedisera = false
                }
            }
        }
    }
}
// FIXME
/*
struct InstructionsView: View {
    
    @Binding var isPresentingInstructions: Bool
    @Binding var isPresentingAddValue: Bool
    @Binding var listItems: [ObservationsListItem]

    public init(isPresentingInstructions: Binding<Bool>,  isPresentingAddValue: Binding<Bool>, listItems: Binding<[ObservationsListItem]>) {
        _isPresentingInstructions = isPresentingInstructions
        _isPresentingAddValue = isPresentingAddValue
        _listItems = listItems
        var config = LabConfig()
        config.didShowInstructions = true
    }
    
    var body: some View {
        VStack {
            Form {
                Section("A. Download") {
                    Image("excel-export", bundle: Bundle.module).resizable().scaledToFit()
                    Text("1.\tJournalen\n2.\tProvsvar\n3.\t'EXPORTERA TILL EXCEL'")
                }
                /*
                Section("B. Convert") {
                    Image("numbers-export", bundle: Bundle.module).resizable().scaledToFit()
                    Text("1.\tOpen in Excel/Numbers\n2.\tExport to CSV")
                }*/
                Section("B. Upload") {
                    Text("Tap '**Add Records**' to pick and upload the file")
                }
            }
            /*
            Button("OK") {
                isPresentingInstructions = false
            }.buttonStyle(.borderedProminent)*/
        }
        .navigationTitle("Instructions")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Done") {
                    isPresentingInstructions = false
                }
            }
        }
    }
    
}*/

struct AddValueView: View {
    
    @Binding var isPresentingAddValue: Bool
    @Binding var listItems: [ObservationsListItem]
    @Binding var model: ObservationsViewModel
    @State var selectedValue: String = ""
    @State var selectedIndex = 1
    
    let sampleTypes = MySampleType.allCases.sorted { a, b in
        return a.title < b.title
    }

    let quantities = MySampleType.allCases.map { q in
        q.title
    }.sorted { a, b in
        return a < b
    }
    
    @State var valueText: String = ""
    @State var date = Date()
    @State var time = Date()
    @State var range: MySampleRange?
    
    public init(isPresentingAddValue: Binding<Bool>, listItems: Binding<ObservationsListItems>, model: Binding<ObservationsViewModel>) {
        _isPresentingAddValue = isPresentingAddValue
        _listItems = listItems
        _model = model
    }
    
    private func saveObservation() {
        let sample = sampleTypes[selectedIndex]
        logger.info("selectedIndex \(selectedIndex) sample \(sample)")
        if let value = Double(valueText) {
            logger.info("SAVE: date \(date) time \(time) quantity \(sample) value \(value)")
            let observation = MyObservation(type: sample, doubleValue: value, unitString: sample.unit.unitString, date: date, lowerLimit: nil, upperLimit: nil, wasUserEntered: true)
            observation.save { error in
                if let error = error {
                    logger.error("SAVE: \(error)")
                } else {
                    logger.info("SAVE: saved \(observation)")
                    DemoManager.shared.reset(type: .lab)
                    HealthKitManager.shared.cacheObservations(force: true) { model, error in
                        if let error {
                            logger.error("\(error)")
                        } else if let model {
                            self.model = model
                            listItems = model.listItems.sorted(by: { a, b in
                                return a.type.title < b.type.title
                            })
                        }
                    }
                }
            }
        } else {
            logger.error("SAVE: Could not parse double value \(valueText)")
        }
    }
    
    var body: some View {
        Form {
            DatePicker("Date", selection: $date, displayedComponents: [.date,.hourAndMinute]).pickerStyle(.wheel)
            Picker(selection: $selectedIndex, label: Text("Quantity")) {
                ForEach(0 ..< quantities.count, id: \.self) { index in
                    if index > 0 {
                        Text(quantities[index]).font(.caption2)
                    }
                }
            }.pickerStyle(MenuPickerStyle())
            
            HStack{
                Text(quantities[selectedIndex])
                Spacer()
                HStack {
                    TextField(quantities[selectedIndex], text: $valueText, prompt: Text("0.0")).multilineTextAlignment(.trailing)
                    Text( sampleTypes[selectedIndex].unitString)
                }
            }
            
            HStack {
                Text("Range")
                Spacer()
                if let range  {
                    HStack {
                        if let low = range.low {
                            Text(low.string(toPlaces: 1))
                        }
                        Text("-")
                        if let high = range.high {
                            Text(high.string(toPlaces: 1))
                        }
                    }
                } else {
                    EmptyView()
                }
            }
        }.task {
            range = sampleTypes[selectedIndex].referenceRange(gender: LabConfig().biologicalSex!, age: Double(LabConfig().birthDay!.age()))
        }
        .onChange(of: selectedIndex, perform: { newValue in
            range = sampleTypes[newValue].referenceRange(gender: LabConfig().biologicalSex!, age: Double(LabConfig().birthDay!.age()))
        })
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    isPresentingAddValue = false
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Save") {
                    saveObservation()
                    isPresentingAddValue = false
                }
            }
        }.navigationBarTitle("Add Value")
    }
}


public struct Dummy: Hashable {
    let name: String
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}


public struct ObservationsView: View {
    
    @State var microbiomeItems: [ObservationsListItem] = []
    
    @Binding var listItems: [ObservationsListItem]
    @Binding var inRange: [ObservationsListItem]
    @Binding var outOfRange: [ObservationsListItem]

    @Binding var model: ObservationsViewModel
    @Binding var path: NavigationPath
    @Environment(\.dismiss) var dismiss
    @ObservedObject var delegate: SheetDismisserDelegate

    var wasPushed = false
    var hideNavigationBar = false
    var isStandaloneApp = true
    
    @State var isPresentingAddNote = false
    @State var isPresentingAddValue = false
    @State var isPresenting1177 = false
    @State var isPresentingSvenskProvtagning = false
    @State var isPresentingBlodkollen = false
    @State var isPresentingWerlabs = false
    @State var isPresentingLifeComp = false
    @State var isPresentingMedisera = false
    @State var isPresenting23andme = false
    @State var isPresentingAtlas = false
    @State var isPresentingCarbiotix = false
    @State var isPresentingAddRecords = false
    @State var isPresentingInstructions = false
    @State var isPresentingDICOM = false
    @State var isPresentingInsights = false
    @State var isPresentingSymptoms = false
    @State var isPresentingMedications = false
    @State var isPresentingChatGPT = false

    @State var isLoading = false

    let biologicalSex: HKBiologicalSex
    
    let gradient = Gradient(colors: [.red, .orange, .yellow, .green])

    var percentInRange = 0.0
    var color: Color = .green
    @State var dummy: Bool = false
    
    let config = LabConfig()
    
    public init(
        items: Binding <ObservationsListItems>,
        inRange: Binding <ObservationsListItems>,
        outOfRange: Binding <ObservationsListItems>,
        model: Binding <ObservationsViewModel>,
        path: Binding <NavigationPath>,
        filterBy: SampleImpact? = nil,
        delegate:  SheetDismisserDelegate? = nil,
        wasPushed: Bool = false,
        hideNavigationBar: Bool = false,
        biologicalSex: HKBiologicalSex) {
        self.biologicalSex = biologicalSex
        _path = path
        _model = model
        _inRange = inRange
        _outOfRange = outOfRange
        
        _listItems = items
        if let delegate = delegate {
            self.delegate = delegate
            isStandaloneApp = false
        } else {
            self.delegate = SheetDismisserDelegate()
            isStandaloneApp = true
        }
        if _inRange.count + _outOfRange.count > 0 {
            self.percentInRange = (100.0*Double(_inRange.count)/Double(_inRange.count + _outOfRange.count)).rounded(toPlaces: 0)
        } else {
            self.percentInRange = -1.0
        }
        
        if self.percentInRange < 30 {
            color = .red
        } else if self.percentInRange >= 30 && self.percentInRange < 70 {
            color = .orange
        } else if self.percentInRange >= 70 {
            color = .green
        }
        
        self.wasPushed = wasPushed
        self.hideNavigationBar = hideNavigationBar
    }
    
    func isLast(_ item: ObservationsListItem) -> Bool {
        return inRange.last == item || outOfRange.last == item
    }
    
    func refresh() {
        
        logger.info("DEMO: config.isResultsDemo \(config.isResultsDemo)")
        if config.isResultsDemo, let model = config.observationsViewModel  {
            self.model = model
            self.listItems = model.listItems.sorted(by: { a, b in
                return a.type.title < b.type.title
            })
            inRange = self.listItems.filter({ item in
                item.range != nil ? item.range!.isInRange:false
            })
            outOfRange = self.listItems.filter({ item in
                item.range != nil ? !item.range!.isInRange:false
            })
        } else {
            HealthKitManager.shared.cacheObservations(force: true)  { model, error in
                if let error {
                    logger.error("\(error)")
                    self.listItems = []
                    self.outOfRange  = []
                    self.inRange = []
                } else if let model {
                    self.model = model
                    self.listItems = model.listItems
                    self.inRange = self.listItems.filter({ item in
                        item.range != nil ? item.range!.isInRange:false
                    })
                    self.outOfRange = self.listItems.filter({ item in
                        item.range != nil ? !item.range!.isInRange:false
                    })
                }
            }
        }
    }
    
    
    
    public var body: some View {
        NavigationStack(path: $path) {
            TabView {
                NotesView(isPresentingAddNote: $isPresentingAddNote, isPresentingSymptoms: $isPresentingSymptoms)
                    .navigationTitle("Diary")
                    .padding(.vertical, 20)
                
                List {
                    
#if targetEnvironment(simulator)
                    HStack {
                        Spacer()
                        Button {
                            DemoManager.shared.cacheDemo()
                        } label: {
                            Text("Cache Demo")
                        }
                        .buttonStyle(.borderedProminent)
                        .multilineTextAlignment(.center)
                        .tint(.red)
                        Button {
                            isLoading = true
                            DispatchQueue.main.async {
                                DemoManager.shared.reset()
                                refresh()
                                isLoading = false
                            }
                        } label: {
                            Text("Reset Demo")
                        }
                        .buttonStyle(.borderedProminent)
                        .multilineTextAlignment(.center)
                        .tint(.red)
                        Spacer()
                    } .listRowSeparator(.hidden)
#endif
                    if listItems.isEmpty || config.isDemo {
                        HStack {
                            Text("Tap + to upload a file or connect a lab.")
                        }.listRowSeparator(.hidden)
                    }
                    
                    if (!config.isDemo && (listItems.isEmpty || config.carbiotixReports == nil || config.genes == nil))  {
                        HStack {
                            Spacer()
                            if isLoading {
                                ProgressView()
                            } else {
                                Button {
                                    isLoading = true
                                    // Always include extension
                                    Task {
                                        await DemoManager.shared.load(
                                            labResultsFiles: ["demoObservations.json"],
                                            microbiomeFiles: ["raw_data_699.362.012.xlsx", "Carbiotix.json"],
                                            genomeFiles: ["genome_Johan_Sellstrom_v4_Full_20220511141623.txt", "genome_Johan_Sellstrom_v5_Full_20220512060226.txt"])
                                        refresh()
                                        isLoading = false
                                    }
                                } label: {
                                    Text("Load Demo")
                                }
                                .buttonStyle(.borderedProminent)
                                .listRowSeparator(.hidden)
                                .multilineTextAlignment(.center)
                            }
                            Spacer()
                        }
                    }
                    
                    if self.percentInRange >= 0 {
                        HStack {
                            Spacer()
                            VStack {
                                Gauge(value: self.percentInRange, in: 0...100) {
                                } currentValueLabel: {
                                    Text("\(Int(percentInRange))").foregroundColor(color)
                                } minimumValueLabel: {
                                    Text("0").foregroundColor(Color.red)
                                } maximumValueLabel: {
                                    Text("100").foregroundColor(Color.green)
                                }
                                .scaleEffect(2)
                                .gaugeStyle(.accessoryCircular)
                                .tint(gradient)
                                .padding()
                                Text("% In Range").font(.caption)
                            }
                            Spacer()
                        }.padding()
                    }
                    
                    if !outOfRange.isEmpty {
                        HStack {
                            Text("Out Of Range").fontWeight(.bold).foregroundColor(.red)
                            Spacer()
                            Text("How to improve?").font(.caption)
                        }
                        
                        ForEach(outOfRange) { item in
                            Button {
                                path.append(item)
                            } label: {
                                TypeRow(item: item)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(.init(top: 4, leading: 0, bottom: 8, trailing: 0))
                            }
                            .buttonStyle(.plain)
                            .listRowInsets(.init(top: 4, leading: 0, bottom: 8, trailing: 0)).listRowSeparator(.hidden)
                            
                            if isLast(item) && inRange.isEmpty {
                                Button {
                                    path.append(Dummy(name: "Brain Scan"))
                                } label: {
                                    ImageRow(item: item)
                                        .listRowSeparator(.hidden)
                                        .listRowInsets(.init(top: 4, leading: 0, bottom: 8, trailing: 0))
                                }
                                .buttonStyle(.plain)
                                .listRowInsets(.init(top: 4, leading: 0, bottom: 8, trailing:0)).listRowSeparator(.hidden)
                            }
                        }
                    }
                    
                    
                    if !inRange.isEmpty {
                        Text("In Range").fontWeight(.bold).foregroundColor(.green)
                        ForEach(inRange) { item in
                            Button {
                                path.append(item)
                            } label: {
                                TypeRow(item: item)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(.init(top: 4, leading: 0, bottom: 8, trailing: 0))
                            }
                            .buttonStyle(.plain)
                            .listRowInsets(.init(top: 4, leading: 0, bottom: 8, trailing: 0)).listRowSeparator(.hidden)
                            
                            if isLast(item) {
                                Button {
                                    path.append(Dummy(name: "Brain Scan"))
                                } label: {
                                    ImageRow(item: item)
                                        .listRowSeparator(.hidden)
                                        .listRowInsets(.init(top: 4, leading: 0, bottom: 8, trailing: 0))
                                }.buttonStyle(.plain)
                                    .listRowInsets(.init(top: 4, leading: 0, bottom: 8, trailing: 0)).listRowSeparator(.hidden)
                            }
                        }
                    }
                    
                    
                    if !microbiomeItems.isEmpty {
                        /*
                         Diversity
                         Short Chain Amino Acids
                         Quality
                         */
                        Text("Microbiom").fontWeight(.bold).foregroundColor(.blue)
                        ForEach(microbiomeItems) { item in
                            Button {
                                path.append(item)
                            } label: {
                                TypeRow(item: item)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(.init(top: 4, leading: 0, bottom: 8, trailing: 0))
                            }
                            .buttonStyle(.plain)
                            .listRowInsets(.init(top: 4, leading: 0, bottom: 8, trailing: 0)).listRowSeparator(.hidden)
                        }
                    }
                }.padding(.vertical, 20)
            }
            .floatingActionButton(
                 color: Color(uiColor: .systemBlue),
                 image:
                 Image(systemName:"pills")
                 .foregroundColor(.white)
                 .font(Font.system(.title)),
                 alignment:
                 .leading)
                 {
                 isPresentingMedications = true
                 }
                 .opacity(0.8).disabled(isLoading)
                 .floatingActionButton(
                 color: Color(uiColor: .systemBlue),
                 image:
                 Image(systemName: "medical.thermometer")
                 .foregroundColor(.white)
                 .font(Font.system(.title))
                 .symbolRenderingMode(SymbolRenderingMode.monochrome),
                 alignment: .trailing)
                 {
                 isPresentingSymptoms = true
                 }
                 .opacity(0.8)
                 .disabled(isLoading)
                .lineSpacing(8)
                .listRowSeparator(.hidden)
                    .navigationDestination(for: Dummy.self) { item in
                        ImageDetailView(item: item).listRowInsets(.init(top: 0, leading: 0, bottom: 8, trailing: 0))
                    }
                    .navigationDestination(for: ObservationsListItem.self) { item in
                        DetailView(item: item, biologicalSex: biologicalSex).listRowInsets(.init(top: 0, leading: 0, bottom: 8, trailing: 0))
                    }
                    .onChange(of: isPresentingWerlabs, perform: { newValue in
                        if !newValue {
                            refresh()
                        }
                    })
                    .onChange(of: isPresenting1177, perform: { newValue in
                        if !newValue {
                            refresh()
                        }
                    })
                    .onChange(of: isPresentingLifeComp, perform: { newValue in
                        if !newValue {
                            refresh()
                        }
                    })
                    .onChange(of: isPresentingMedisera, perform: { newValue in
                        if !newValue {
                            refresh()
                        }
                    })
                    .onChange(of: isPresentingAddRecords, perform: { newValue in
                        if !newValue {
                            refresh()
                        }
                    })
                    .onChange(of: isPresentingAtlas, perform: { newValue in
                        if !newValue {
                            refresh()
                        }
                    })
                    .onChange(of: isPresentingCarbiotix, perform: { newValue in
                        if !newValue {
                            refresh()
                        }
                    })
                    .onChange(of: isPresentingSvenskProvtagning, perform: { newValue in
                        if !newValue {
                            refresh()
                        }
                    })
                    .onChange(of: isPresentingBlodkollen, perform: { newValue in
                        if !newValue {
                            refresh()
                        }
                    })
                    .onChange(of: isPresentingAddValue, perform: { newValue in
                        if !newValue {
                            refresh()
                        }
                    })
                    .sheet(isPresented: $isPresenting1177) {
                        NavigationView {
                            VardguidenView(isPresenting1177: $isPresenting1177, model: $model)
                        }.presentationDetents([ .large])
                    }
                    .sheet(isPresented: $isPresentingLifeComp) {
                        NavigationView {
                            LifeCompView(isPresentingLifeComp: $isPresentingLifeComp, model: $model)
                        }.presentationDetents([ .large])
                    }
                    .sheet(isPresented: $isPresentingWerlabs) {
                        NavigationView {
                            WerLabKitUI(isPresentingWerlabs: $isPresentingWerlabs, model: $model)
                        }.presentationDetents([ .large])
                    }
                    .sheet(isPresented: $isPresentingMedisera) {
                        NavigationView {
                            MediseraView(isPresentingMedisera: $isPresentingMedisera, model: $model)
                        }.presentationDetents([ .large])
                    }
                    .sheet(isPresented: $isPresenting23andme) {
                        DocumentPicker(model: $model, isPresenting: $isPresenting23andme, dataSource: .twenty3andme) { report, error in
                            
                        }
                    }
                    .sheet(isPresented: $isPresentingAddRecords) {
                        DocumentPicker(model: $model, isPresenting: $isPresentingAddRecords, dataSource: .vardguiden1177) { model, error in
                            
                        }
                    }
                    .sheet(isPresented: $isPresentingAtlas) {
                        DocumentPicker(model: $model, isPresenting: $isPresentingAtlas, dataSource: .atlas) { report, error in
                            
                        }
                    }
                    .sheet(isPresented: $isPresentingCarbiotix) {
                        DocumentPicker(model: $model, isPresenting: $isPresentingCarbiotix, dataSource: .carbiotix) { report, error in
                            
                        }
                    }
                    .sheet(isPresented: $isPresentingSvenskProvtagning) {
                        NavigationView {
                            SvenskProvtagningView(isPresentingSvenskProvtagning: $isPresentingSvenskProvtagning, model: $model)
                        }.presentationDetents([ .large])
                    }
                    .sheet(isPresented: $isPresentingBlodkollen) {
                        NavigationView {
                            BlodkollenView(isPresentingBlodkollen: $isPresentingBlodkollen, model: $model)
                        }.presentationDetents([ .large])
                    }
            /* FIXME
                    .sheet(isPresented: $isPresentingInstructions) {
                        NavigationView {
                            InstructionsView(isPresentingInstructions: $isPresentingInstructions, isPresentingAddValue: $isPresentingAddValue, listItems: $listItems)
                        }.presentationDetents([ .large])
                    }
             */
                    .sheet(isPresented: $isPresentingSymptoms) {
                        NavigationView {
                            AddSymptomsView(isPresentingSymptoms: $isPresentingSymptoms)
                        }.presentationDetents([.large])
                    }
                    /*.sheet(isPresented: $isPresentingMedications) {
                        NavigationView {
                            MedicationsView()
                        }.presentationDetents([.large])
                    }*/
                    .sheet(isPresented: $isPresentingInsights) {
                        NavigationView {
                            InsightsView(isPresentingInsights: $isPresentingInsights, isPresenting23andme: $isPresenting23andme).presentationDetents([.large])
                        }.presentationDetents([.large])
                    }
                    .sheet(isPresented: $isPresentingDICOM) {
                        NavigationView {
                            InsightsView(isPresentingInsights: $isPresentingInsights, isPresenting23andme: $isPresenting23andme).presentationDetents([.large])
                        }.presentationDetents([.large])
                    }
                    .sheet(isPresented: $isPresentingAddNote) {
                        NavigationView {
                            AddNoteView(isPresentingAddNote: $isPresentingAddNote)
                        }.presentationDetents([.fraction(0.45), .medium, .large])
                    }
                    .sheet(isPresented: $isPresentingAddValue) {
                        NavigationView {
                            AddValueView(isPresentingAddValue: $isPresentingAddValue, listItems: $listItems, model: $model)
                        }.presentationDetents([.medium])
                    }
                    .onChange(of: isPresentingAddNote) { newValue in
                        print("isPresentingAddNote \(newValue)")
                    }
                    .edgesIgnoringSafeArea(.bottom)
                    .navigationBarHidden(hideNavigationBar)
                    .navigationTitle(listItems.isEmpty ? "No Lab Results":"Lab Results")
            
                    .toolbar {
                        if !isStandaloneApp {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button {
                                    self.delegate.dismiss()
                                } label: {
                                    //Image(systemName: "xmark.circle")
                                    Text("Done")
                                }
                            }
                        } else {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button {
                                    isPresentingInsights = true
                                } label: {
                                    Text("Insights")
                                }
                            }
                        }
                        
                        ToolbarItem(placement: isStandaloneApp ? .navigationBarLeading:.navigationBarTrailing) {
                            Menu { // Label is doing localization automatically
                                Group {
                                    Button(action: {
                                        isPresentingAddNote = true
                                    }) {
                                        Label(loc("Add Note"), systemImage:"note.text")
                                    }
                                    Menu("Connect") {
                                        /*
                                         Button(action: {
                                         isPresentingChatGPT = true
                                         }) {
                                         Label(loc("ChatGPT"), systemImage: "brain")
                                         }*/
                                        Button(action: {
                                            isPresenting1177 = true
                                        }) {
                                            Label(loc("Vårdguiden 1177"), systemImage: "globe")
                                        }
                                        
                                        Button(action: {
                                            isPresentingBlodkollen = true
                                        }) {
                                            Label(loc("Blodkollen"), systemImage: "globe")
                                        }.disabled(true)
                                        
                                        Button(action: {
                                            isPresentingSvenskProvtagning = true
                                        }) {
                                            Label(loc("Svensk Provtagning"), systemImage: "globe")
                                        }
                                        
                                        Button(action: {
                                            isPresentingWerlabs = true
                                        }) {
                                            Label(loc("Werlabs"), systemImage: "globe")
                                        }
                                        
                                        Button(action: {
                                            isPresentingLifeComp = true
                                        }) {
                                            Label(loc("LifeComp"), systemImage: "globe")
                                        }.disabled(true)
                                        
                                        Button(action: {
                                            isPresentingMedisera = true
                                        }) {
                                            Label(loc("Medisera"), systemImage: "globe")
                                        }.disabled(true)
                                    }.disabled(config.birthDay == nil || config.biologicalSex == nil)
                                    Menu("Upload") {
                                        Button(action: {
                                            isPresenting23andme = true
                                        }) {
                                            Label(loc("23andme"), systemImage: "staroflife")
                                        }
                                        
                                        if config.didShowInstructions {
                                            Button(action: {
                                                isPresentingAddRecords = true
                                                //path.append(picker)
                                                /*
                                                 #if targetEnvironment(simulator)
                                                 DocumentPickerViewController.developmentFile()
                                                 #else
                                                 path.append(picker)
                                                 #endif
                                                 */
                                            }) {
                                                Label(loc("Records"), systemImage: "list.bullet.clipboard")
                                            }
                                        } else {
                                            Button(action: {
                                                isPresentingInstructions = true
                                            }) {
                                                Label(loc("Records"), systemImage: "menucard")
                                            }
                                        }
                                        
                                        Button(action: {
                                            isPresentingAtlas = true
                                        }) {
                                            Label(loc("Atlas Microbiome"), systemImage: "microbe")
                                        }
                                        
                                        Button(action: {
                                            isPresentingAtlas = true
                                        }) {
                                            Label(loc("Carbiotix Microbiome"), systemImage: "microbe")
                                        }
                                        
                                        // TODO: Read DICOM images
                                        
                                        Button(action: {
                                            isPresentingDICOM = true
                                        }) {
                                            Label(loc("Upload MRI/XRay"), systemImage: "brain")
                                        }.disabled(true)
                                        
                                        if config.didShowInstructions {
                                            Button(action: {
                                                isPresentingInstructions = true
                                            }) {
                                                Label(loc("1177 Upload Instructions"), systemImage: "info.circle")
                                            }
                                        }
                                    }
                                }
                                Group {
                                    Button(action: {
                                        isPresentingAddValue = true
                                    }) {
                                        Label(loc("Add Value"), systemImage:"123.rectangle")
                                    }
                                }
                            } label: {
                                Label(loc("Settings"), systemImage: "plus")
                            }
                        }
                    }
            
            .listStyle(.plain)
            .disabled(isLoading)
         }
        .tabViewStyle(.page)
        .onAppear {
            setupAppearance()
        }
    }
    
    func setupAppearance() {
        UIPageControl.appearance().currentPageIndicatorTintColor = .black
        UIPageControl.appearance().pageIndicatorTintColor = UIColor.black.withAlphaComponent(0.2)
    }
    
}

public struct FilteredObservationsView: View {
    
    @Binding var listItems: [ObservationsListItem]
    @State private var path = NavigationPath()
 
    public var body: some View {
        NavigationStack(path: $path) {
            List {
                ForEach(listItems) { item in
                    Button {
                        path.append(item)
                    } label: {
                        TypeRow(item: item)
                            .listRowSeparator(.hidden)
                            .listRowInsets(.init(top: 4, leading: 0, bottom: 8, trailing: 0))
                    }
                    .buttonStyle(.plain)
                    .listRowInsets(.init(top: 4, leading: 0, bottom: 8, trailing: 0)).listRowSeparator(.hidden)
                }
            }
            .lineSpacing(8)
            .listRowSeparator(.hidden)
        }.listStyle(.plain)
    }
}

/*
public struct MetabolicObservationsView: View {
    var listItems: [ObservationsListItem]
    public init(items: [ObservationsListItem]) {
        self.listItems = items
    }
    
    public var body: some View {
        Group {
            ForEach(listItems) { item in
                if item.range != nil {
                    TypeDetail(item: item)
                        .listRowSeparator(.hidden)
                        .listRowInsets(.init(top: 0, leading: 0, bottom: 8, trailing: 0))
                }
            }
        }
    }
}
*/

extension OCKAnyTask {      // << just extension
    var id: String  { id }
}

extension OCKTask: Identifiable {
    
}



/*
 if MedConfig().hasMedications {
 MedicationsSectionView()
 }
 */
//FIXME: refactor

/*if hasMicrobiome {
 MicrobiomeSectionView(current: $microbiomeDiversity, comment: $microbiomeComment)
 } else {*/
/*
 Section("Microbiome") {
 HStack {
 Spacer()
 Button {
 Task {
 await DemoManager.shared.load(
 labResultsFiles: [],
 microbiomeFiles: ["raw_data_699.362.012.xlsx", "Carbiotix.json"],
 genomeFiles: [])
 hasMicrobiome = true
 }
 } label: {
 Text("Load Demo")
 }
 .buttonStyle(.borderedProminent)
 .listRowSeparator(.hidden)
 .multilineTextAlignment(.center)
 Spacer()
 }
 }
 */
//}
/*
 BiologicalAgeSectionView(age: $age, bioAge: $bioAge, bioAges: $bioAges, levine: $levine, biologicalSex: LabConfig().biologicalSex!)
 .task {
 if let reports = GeneConfig().carbiotixReports, let lastReport = reports.last, let lastVial = lastReport.vials.last {
 hasMicrobiome = true
 microbiomeDiversity = lastVial.result.gut_score
 if microbiomeDiversity < 30.0 {
 microbiomeComment = "Poor"
 } else if microbiomeDiversity >= 30.0 &&  microbiomeDiversity < 65.0 {
 microbiomeComment = "Good"
 } else if microbiomeDiversity >= 65.0 {
 microbiomeComment = "Optimal"
 }
 }
 if let model = LabConfig().observationsViewModel, let hdl = model.listItems.filter({ item in item.type == .PHDL }).first, let tri = model.listItems.filter({ item in item.type == .fpTri }).first {
 let hdlValues = hdl.values
 let triValues = tri.values
 print("hdl \(hdlValues) tri \(triValues)")
 print("hdl count \(hdlValues.count) tri \(triValues.count)")
 if hdlValues.count == triValues.count {
 for i in 0..<hdlValues.count {
 if hdlValues[i].date == triValues[i].date {
 let quota = (triValues[i].value/hdlValues[i].value).rounded(toPlaces:2)
 let point = MyChartPoint(value: quota, date: hdlValues[i].date)
 lipidQuotas.append(point)
 }
 }
 }
 lipidQuotas = Array(Set(lipidQuotas)).sorted(by: { p1, p2 in
 p1.date < p2.date
 })
 }
 
 HealthKitManager.shared.getMostRecentSampleAsync(for: vo2MaxType) { sample, error in
 if let error {
 logger.error("\(error)")
 } else if let sample {
 // mL/kg/min
 let mL = HKUnit.literUnit(with: .milli)
 let kg = HKUnit.gramUnit(with: .kilo)
 let mlperkg = mL.unitDivided(by: kg)
 let min = HKUnit.minute()
 let unit = mlperkg.unitDivided(by: min)
 let vo2max = sample.quantity.doubleValue(for: unit)
 self.conditionAge = VO2MaxAge.shared.age(v: vo2max)
 }
 }
 
 //let hrvAverage = await OCKHealthKit.getAverageValuesPerInterval(identifier: .heartRateVariabilitySDNN, dayInterval: 30)
 //print("hrvAverage \(hrvAverage)")
 let now = Date()
 let offSetStart: TimeInterval = -30.0*24*60*60
 let startDate   = now.addingTimeInterval(offSetStart)
 
 let interval = DateInterval(start: startDate, end: now)
 print("hrvAverage interval \(interval)")
 
 HealthKitManager.shared.averageQuery(quantity: hrvType,  unit: HKUnit.secondUnit(with: .milli), in: [interval]) { result in
 print("hrvAverage \(result)")
 switch result {
 case let .failure(error):
 print("hrvAverage \(error)")
 case let .success(res):
 print("hrvAverage samples \(String(describing: res.last)) \(String(describing: res.last?.values))")
 if let lastResult = res.last, let lastValue = lastResult.values.last {
 
 self.hrvAge = HRVAge.shared.age(v: lastValue, biologicalSex: LabConfig().biologicalSex!)
 }
 }
 }
 }*/

//ConditionsSectionView()

//CardioSectionView(conditionAge: $conditionAge, hrvAge: $hrvAge, lipidQuotas: $lipidQuotas)
/*
Section("Genetic Profiling") {
    if hasGenome {
        
        let report = GeneticReport(biologicalSex: LabConfig().biological)
        if !report.increasedRisk.isEmpty {
            SectionView(title: "Increased risk", items: report.increasedRisk, type: .increasedRisk, biologicalSex: LabConfig().biologicalSex!)
        }
        if !report.decreasedRisk.isEmpty {
            SectionView(title: "Decreased risk", items: report.decreasedRisk, type: .decreasedRisk, biologicalSex: LabConfig().biologicalSex!)
        }
        if !report.higherLevels.isEmpty {
            SectionView(title: "Higher Levels", items: report.higherLevels, type: .higherLevels, biologicalSex: LabConfig().biologicalSex!)
        }
        if !report.lowerLevels.isEmpty {
            SectionView(title: "Lower Levels", items: report.lowerLevels, type: .lowerLevels, biologicalSex: LabConfig().biologicalSex!)
        }
        if !report.supplements.isEmpty {
            SectionView(title: "Recommended supplements", items: report.supplements, type: .supplements, biologicalSex: LabConfig().biologicalSex!)
        }
    } else {
        HStack {
            Spacer()
            Button {
                Task {
                    await DemoManager.shared.load(
                        labResultsFiles: [],
                        microbiomeFiles: [],
                        genomeFiles: ["genome_Johan_Sellstrom_v4_Full_20220511141623.txt", "genome_Johan_Sellstrom_v5_Full_20220512060226.txt"])
                    hasGenome = true
                }
            } label: {
                Text("Load Demo")
            }
            .buttonStyle(.borderedProminent)
            .listRowSeparator(.hidden)
            .multilineTextAlignment(.center)
            Spacer()
        }
    }
}
*/
#endif
