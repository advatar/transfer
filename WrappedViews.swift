//
//  File.swift
//  
//
//  Created by Johan Sellström on 2022-10-27.
//
#if canImport(UIKit)
import Foundation
import UIKit
import SwiftUI
import LabKitUI


public struct VardGuidenWrappedView: UIViewControllerRepresentable {
    @Binding var model: ObservationsViewModel
    
    public init(model: Binding <ObservationsViewModel>) {
        _model = model
    }
    
    public func makeUIViewController(context: Context) -> VardguidenViewController {
        let vc = VardguidenViewController(model: $model)
        return vc
    }
    public func updateUIViewController(_ uiViewController: VardguidenViewController, context: Context) {
    }
}

public struct SvenskProvtagningWrappedView: UIViewControllerRepresentable {
    @Binding var model: ObservationsViewModel

    public init(model: Binding <ObservationsViewModel>) {
        _model = model
    }

    public func makeUIViewController(context: Context) -> SvenskProvtagningViewController {
        let vc = SvenskProvtagningViewController()
        return vc
    }
    public func updateUIViewController(_ uiViewController: SvenskProvtagningViewController, context: Context) {
    }
}

public struct BlodkollenWrappedView: UIViewControllerRepresentable {
    @Binding var model: ObservationsViewModel
    
    public init(model: Binding <ObservationsViewModel>) {
        _model = model
    }

    public func makeUIViewController(context: Context) -> BlodkollenViewController {
        let vc = BlodkollenViewController()
        return vc
    }
    public func updateUIViewController(_ uiViewController: BlodkollenViewController, context: Context) {
    }
}

public struct WerlabsWrappedView: UIViewControllerRepresentable {
    @Binding var model: ObservationsViewModel

    public init(model: Binding <ObservationsViewModel>) {
        _model = model
    }

    public func makeUIViewController(context: Context) -> WerLabKitUIController {
        let vc = WerLabKitUIController(model: $model)
        return vc
    }
    public func updateUIViewController(_ uiViewController: WerLabKitUIController, context: Context) {
    }
}

public struct LifeCompWrappedView: UIViewControllerRepresentable {
    @Binding var model: ObservationsViewModel

    public init(model: Binding <ObservationsViewModel>) {
        _model = model
    }

    public func makeUIViewController(context: Context) -> LifeCompViewController {
        let vc = LifeCompViewController()
        return vc
    }
    public func updateUIViewController(_ uiViewController: LifeCompViewController, context: Context) {
    }
}

public struct MediseraWrappedView: UIViewControllerRepresentable {
    @Binding var model: ObservationsViewModel

    public init(model: Binding <ObservationsViewModel>) {
        _model = model
    }

    public func makeUIViewController(context: Context) -> MediseraViewController {
        let vc = MediseraViewController()
        return vc
    }
    public func updateUIViewController(_ uiViewController: MediseraViewController, context: Context) {
    }
}
#endif
