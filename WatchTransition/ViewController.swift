//
//  ViewController.swift
//  WatchTransition
//
//  Created by Ken Ferry on 4/27/15.
//  Copyright (c) 2015 Understudy. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet var crownSlider: UISlider! = nil
    @IBAction func crownSliderDidChange(sender: UISlider) {
        masterTiming = Double(crownSlider.value)
    }
    var masterTiming : Double = 0 {
        didSet {
            updateForAnimation()
        }
    }

    @IBOutlet var contentView: UIView!
    @IBOutlet var clockTruthView: UIImageView!
    @IBOutlet var otherAppsView : UIView!
    @IBOutlet var tickLabels : [UILabel]!
    @IBOutlet var complicationViews : [UIImageView]!
    
    var positioningLayer : CALayer!
    
    // the "mini" representation when it's on the home screen
    var watchBezelMiniLayer : CALayer!
    var hourHandMiniLayer : CAShapeLayer!
    var minuteHandMiniLayer : CAShapeLayer!
    var secondHandMiniLayer : CALayer!
    var orangeCapMiniLayer : CALayer!
    var miniLayers : [CALayer] {
        return [watchBezelMiniLayer,
            hourHandMiniLayer,
            minuteHandMiniLayer,
            secondHandMiniLayer,
            secondHandMiniLayer,
            orangeCapMiniLayer]
    }
    
    var maskLayer : CALayer!
    
    var dialLayer : CAShapeLayer!
    var hourHandLayer : CAShapeLayer!
    var minuteHandLayer : CAShapeLayer!
    var whiteCapLayer : CALayer!
    var secondHandLayer : CALayer!
    var orangeCapLayer : CALayer!
    var blackCapLayer : CALayer!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        makeLayers()

        let spec = KFTunableSpec(named:"MainSpec")
        view.addGestureRecognizer(KFTunableSpec(named:"MainSpec").twoFingerTripleTapGestureRecognizer())
        
        let configAffectingSpecKeys = [ "ClockRadius", "LineWidth", "LargeTickWidth", "SmallTickWidth", "SecondHandOverhang", "PatternPhase", "SecondHandMiniThickness", "OarCurveLen" ]
        for key in configAffectingSpecKeys {
            spec.withDoubleForKey(key, owner: self) { (owner, _) in
                let props = spec.dictionaryRepresentation() as! Dictionary<String,CGFloat>
                owner.configureLayers()
            }
        }
        
        masterTiming = Double(crownSlider.value)
        
        let anim = CABasicAnimation(keyPath:"transform.rotation")
        anim.fromValue = 0
        anim.toValue = 2*M_PI
        anim.duration = 60;
        anim.repeatCount = 1e100;
        secondHandLayer.addAnimation(anim, forKey: "tick")
        secondHandMiniLayer.addAnimation(anim, forKey: "tick")
    }

    func makeLayers() {
        positioningLayer = CALayer(superlayer: contentView.layer, position: centerScreen)
        watchBezelMiniLayer = CALayer(superlayer: positioningLayer, backgroundColor:.whiteColor())
        hourHandMiniLayer = CAShapeLayer(superlayer:positioningLayer, fillColor:.blackColor())
        minuteHandMiniLayer = CAShapeLayer(superlayer:positioningLayer, fillColor:.blackColor())
        secondHandMiniLayer = CALayer(superlayer: positioningLayer, backgroundColor: secondHandColor)
        orangeCapMiniLayer = CALayer(superlayer: positioningLayer, backgroundColor: secondHandColor)
        
        maskLayer = CALayer(superlayer: positioningLayer, backgroundColor: UIColor.blackColor())
        
        dialLayer = CAShapeLayer(superlayer:maskLayer, strokeColor:.whiteColor())
        hourHandLayer = CAShapeLayer(superlayer:maskLayer, fillColor:hourHandColor)
        minuteHandLayer = CAShapeLayer(superlayer:maskLayer, fillColor:minuteHandColor)
        whiteCapLayer = CALayer(superlayer: maskLayer, backgroundColor: .whiteColor())
        secondHandLayer = CALayer(superlayer: maskLayer, backgroundColor: secondHandColor)
        orangeCapLayer = CALayer(superlayer: maskLayer, backgroundColor: secondHandColor)
        blackCapLayer = CALayer(superlayer: maskLayer, backgroundColor: .blackColor())
    }
    
    // this is separated from makeLayers because we want to use KFTunableSpec to change design values.
    // we rerun this method whenever that happens.
    func configureLayers() {
        let spec = KFTunableSpec(named:"MainSpec")
        
        let outsideRadius = CGFloat(spec.doubleForKey("ClockRadius"))
        let tickThickness = CGFloat(spec.doubleForKey("LineWidth"))
        let bigTickWidth = CGFloat(spec.doubleForKey("LargeTickWidth"))
        let smallTickWidth = CGFloat(spec.doubleForKey("SmallTickWidth"))
        let secondHandOverhang = CGFloat(spec.doubleForKey("SecondHandOverhang"))
        let tickPatternPhase = CGFloat(spec.doubleForKey("PatternPhase"))
        let secondHandMiniThickness = CGFloat(spec.doubleForKey("SecondHandMiniThickness"))
        let pi = CGFloat(M_PI)
        let watchFaceBounds = CGRect(center: CGPointZero, width: 2 * outsideRadius, height: 2 * outsideRadius)
        
        // these are random, where the watch hands point.
        let hourHandRotationXForm = CGAffineTransformMakeRotation(0.66 * 2 * pi)
        let minuteHandRotationXForm = CGAffineTransformMakeRotation(0.25 * 2 * pi)
        
        //    whiteDiskLayer
        watchBezelMiniLayer.bounds = watchFaceBounds
        watchBezelMiniLayer.cornerRadius = watchFaceBounds.size.height/2
        
        //    hourHandMiniLayer
        let minuteHandLength = outsideRadius - tickThickness - 0.5 /* 0.5 == half a point == 1 pixel is taken visually from the design */
        let hourHandLength = minuteHandLength * 2 / 3
        let handleLen = CGFloat(7)
        let handleThickness : CGFloat = 2
        let miniBladeThickness : CGFloat = 8
        let bladeThickness : CGFloat = 6
        
        hourHandMiniLayer.path = OarShapedBezier(handleLength: handleLen, totalLength: hourHandLength, handleThickness: handleThickness, bladeThickness: miniBladeThickness)
        hourHandMiniLayer.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        hourHandMiniLayer.setAffineTransform(hourHandRotationXForm)
        
        //    minuteHandMiniLayer
        minuteHandMiniLayer.path = OarShapedBezier(handleLength: handleLen, totalLength: minuteHandLength, handleThickness: handleThickness, bladeThickness: miniBladeThickness)
        minuteHandMiniLayer.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        minuteHandMiniLayer.setAffineTransform(minuteHandRotationXForm)
        
        //    secondHandMiniLayer
        func handRect(#thickness:CGFloat, #length:CGFloat, overhang:CGFloat = 0)->CGRect {
            return CGRect(x: -thickness/2, y: -overhang, width: thickness, height: length)
        }
        
        let secondHandMiniLength = minuteHandLength + secondHandOverhang
        secondHandMiniLayer.bounds = handRect(thickness:secondHandMiniThickness, length:secondHandMiniLength, overhang:secondHandOverhang)
        secondHandMiniLayer.anchorPoint = CGPoint(x: 0.5, y: secondHandOverhang / secondHandMiniLength)
        
        // orangeCapMiniLayer
        let orangeCapMiniLayerRadius = CGFloat(5)
        
        orangeCapMiniLayer.bounds = CGRect(center: CGPointZero, width: 2 * orangeCapMiniLayerRadius, height: 2 * orangeCapMiniLayerRadius)
        orangeCapMiniLayer.cornerRadius = orangeCapMiniLayerRadius
        
        // that's it for the mini representation
        
        // dialLayer
        let radiusToTickMiddle = outsideRadius - tickThickness/2
        let tickMiddleCircumference = pi * 2 * radiusToTickMiddle
        let tickNominalGapWidth = tickMiddleCircumference / 60
        let tickBigToSmallGapWidth = tickNominalGapWidth - bigTickWidth/2 - smallTickWidth/2
        let tickSmalToSmallGapWidth = tickNominalGapWidth - smallTickWidth
        let dialRotation = pi/2 + 2*pi*tickPatternPhase/tickMiddleCircumference
        
        let tickPattern : [NSNumber] = [
            bigTickWidth,
            tickBigToSmallGapWidth,
            smallTickWidth,
            tickSmalToSmallGapWidth,
            smallTickWidth,
            tickSmalToSmallGapWidth,
            smallTickWidth,
            tickSmalToSmallGapWidth,
            smallTickWidth,
            tickBigToSmallGapWidth]
        
        dialLayer.path = UIBezierPath(ovalInRect:CGRect(center: CGPointZero, width: radiusToTickMiddle * 2, height: radiusToTickMiddle * 2)).CGPath
        dialLayer.bounds = watchFaceBounds
        dialLayer.lineWidth = tickThickness
        dialLayer.setAffineTransform(CGAffineTransformMakeRotation(-dialRotation))
        dialLayer.lineDashPattern = tickPattern
        
        //    hourHandLayer
        
        hourHandLayer.path = OarShapedBezier(handleLength: handleLen, totalLength: hourHandLength, handleThickness: handleThickness, bladeThickness: bladeThickness)
        hourHandLayer.anchorPoint = CGPoint(x: 0.5, y:0)
        hourHandLayer.setAffineTransform(hourHandRotationXForm)
        hourHandLayer.shadowPath = hourHandLayer.path
        hourHandLayer.shadowOpacity = 1
        hourHandLayer.shadowOffset = CGSizeZero
        
        //    minuteHandLayer
        minuteHandLayer.path = OarShapedBezier(handleLength: handleLen, totalLength: minuteHandLength, handleThickness: handleThickness, bladeThickness: bladeThickness)
        minuteHandLayer.anchorPoint = CGPoint(x: 0.5, y:0)
        minuteHandLayer.setAffineTransform(minuteHandRotationXForm)
        minuteHandLayer.shadowPath = minuteHandLayer.path
        minuteHandLayer.shadowOpacity = 1
        minuteHandLayer.shadowOffset = CGSizeZero
        
        //    whiteCapLayer
        whiteCapLayer.bounds = CGRectMake(-3, -3, 6, 6)
        whiteCapLayer.cornerRadius = 3
        
        //    secondHandLayer
        let secondHandLength = outsideRadius + secondHandOverhang
        let secondHandThickness : CGFloat = 1
        secondHandLayer.bounds = handRect(thickness:secondHandThickness, length:secondHandLength, overhang:secondHandOverhang)
        secondHandLayer.anchorPoint = CGPoint(x: 0.5, y: secondHandOverhang / secondHandLength)
        
        //    orangeCapLayer
        orangeCapLayer.bounds = CGRectMake(-2, -2, 4, 4)
        orangeCapLayer.cornerRadius = 2
        
        //    blackCapLayer
        blackCapLayer.bounds = CGRectMake(-1, -1, 2, 2)
        blackCapLayer.cornerRadius = 1
    }
    
    func updateForAnimation() {
        CATransaction.setAnimationDuration(0)
        
        // the start times and end times of various separate animations
        // the curves here aren't real, since we're driving our animation entirely through a slider
        let blackCircleGrowthRange = 0.0..<0.5
        let rotaryDialRange = 0.6...0.95
        let scaleAllContentRange = 0.0..<1.0
        let complicationsScaleRange = 0.86..<1.0
        
        // blackCircleGrowth animation
        switch progressInRange(blackCircleGrowthRange, masterTiming) {
        case .Before:
            maskLayer.masksToBounds = false
            maskLayer.backgroundColor = nil
            
            for layer in miniLayers {
                layer.hidden = false
            }
        case let .During(progress):
            maskLayer.masksToBounds = true
            maskLayer.backgroundColor = UIColor.blackColor().CGColor
            maskLayer.bounds = CGRectApplyAffineTransform(dialLayer.bounds, CGAffineTransformMakeScale(progress, progress))
            maskLayer.cornerRadius = maskLayer.bounds.size.width/2
            
            for layer in miniLayers {
                layer.hidden = false
            }
        case .After:
            maskLayer.masksToBounds = false
            maskLayer.backgroundColor = nil
            maskLayer.bounds = dialLayer.bounds
            
            for layer in miniLayers {
                layer.hidden = true
            }
        }
        
        // showing the watch dial as a rotary sweep
        switch progressInRange(rotaryDialRange, masterTiming) {
        case .Before:
            dialLayer.hidden = true
            for label in tickLabels {
                label.hidden = true
            }
        case let .During(progress):
            dialLayer.hidden = false
            dialLayer.strokeEnd = progress
            for i in 0..<tickLabels.count {
                let ithAnimRange = (Double(i)/12)..<((Double(i)+0.7)/12)
                switch progressInRange(ithAnimRange, Double(progress)) {
                case .Before:
                    tickLabels[i].hidden = true
                case let .During(prog):
                    tickLabels[i].hidden = false
                    tickLabels[i].transform = CGAffineTransformMakeScale(prog, prog)
                case .After:
                    tickLabels[i].hidden = false
                    tickLabels[i].transform = CGAffineTransformIdentity
                }
            }
        case .After:
            dialLayer.hidden = false
            dialLayer.strokeEnd = 1.0
            for i in 0..<tickLabels.count {
                tickLabels[i].hidden = false
                tickLabels[i].transform = CGAffineTransformIdentity
            }
        }
        
        // zooming in on everything
        // turns out we need two separate scalings – the other apps need to zoom in and move offscreen faster than the watch app for the effect to look correct.
        let startScaleForMiniWatch = KFTunableSpec(named: "MainSpec").doubleForKey("MinScale")
        let contentScaleRange = startScaleForMiniWatch...1.0
        let otherAppsScaleRange = 1.0...5.0
        
        switch progressInRange(scaleAllContentRange, masterTiming) {
        case .Before:
            let contentScale = CGFloat(contentScaleRange.start)
            contentView.transform = CGAffineTransformMakeScale(contentScale, contentScale)
            otherAppsView.transform = CGAffineTransformIdentity
        case let .During(progress):
            func linearInterpolate(time:CGFloat, interval:ClosedInterval<Double>)->CGFloat {
                return CGFloat(interval.start + Double(time) * (interval.end - interval.start))
            }

            let contentScale = linearInterpolate(progress, contentScaleRange)
            contentView.transform = CGAffineTransformMakeScale(contentScale, contentScale)
            
            let otherAppsScale = linearInterpolate(progress, otherAppsScaleRange)
            otherAppsView.transform = CGAffineTransformMakeScale(otherAppsScale, otherAppsScale)
        case .After:
            contentView.transform = CGAffineTransformIdentity
            let otherAppsScale = CGFloat(otherAppsScaleRange.end)
            otherAppsView.transform = CGAffineTransformMakeScale(otherAppsScale, otherAppsScale)
        }
        
        // showing the complications
        switch progressInRange(complicationsScaleRange, masterTiming) {
        case .Before:
            for view in complicationViews {
                view.hidden = true
            }
        case let .During(progress):
            for view in complicationViews {
                view.hidden = false
                view.transform = CGAffineTransformMakeScale(progress, progress)
            }
        case .After:
            for view in complicationViews {
                view.hidden = false
                view.transform = CGAffineTransformIdentity
            }
        }
    }
}

let centerScreen = CGPoint(x: 312.0/4, y: 390.0/4)
let secondHandColor = UIColor(red: 255.0/255.0, green: 149.0/255.0, blue: 3.0/255.0, alpha: 1.0)
let hourHandColor = UIColor.whiteColor()
let minuteHandColor = UIColor.whiteColor()

extension CALayer {
    convenience init(superlayer:CALayer, position:CGPoint = CGPointZero, backgroundColor : UIColor? = nil) {
        self.init()
        superlayer.addSublayer(self)
        self.position = position
        self.backgroundColor = backgroundColor?.CGColor
    }
}

extension CAShapeLayer {
    convenience init(superlayer:CALayer, position:CGPoint = CGPointZero, strokeColor:UIColor? = nil, fillColor:UIColor? = nil) {
        self.init()
        superlayer.addSublayer(self)
        self.position = position
        self.strokeColor = strokeColor?.CGColor
        self.fillColor = fillColor?.CGColor
        self.edgeAntialiasingMask = CAEdgeAntialiasingMask.LayerLeftEdge | CAEdgeAntialiasingMask.LayerRightEdge | CAEdgeAntialiasingMask.LayerBottomEdge | CAEdgeAntialiasingMask.LayerTopEdge
    }
}

extension CGRect {
    init(center:CGPoint, width:CGFloat, height:CGFloat) {
        self = CGRect(x:center.x - width/2, y: center.y - height/2, width:width, height:height)
    }
}

func OarShapedBezier(#handleLength:CGFloat, #totalLength:CGFloat, #handleThickness:CGFloat, #bladeThickness:CGFloat)->CGPath {
    let path = UIBezierPath()
    // the oar is sticking straight up, with the blade in the air and sitting centered on 0,0
    // trace around it, starting at 0,0 and moving left first
    let lengthWithoutCap = totalLength - bladeThickness
    let transitionLen = CGFloat(KFTunableSpec(named: "MainSpec").doubleForKey("OarCurveLen"))
    
    path.moveToPoint(CGPointZero)
    path.addLineToPoint(CGPoint(x: -handleThickness/2, y: 0)) // bottom left
    path.addLineToPoint(CGPoint(x: -handleThickness/2, y: handleLength)) // up the handle
    path.addCurveToPoint(CGPoint(x:-bladeThickness/2, y:handleLength + transitionLen), // curve out to the blade
        controlPoint1: CGPoint(x: -handleThickness/2, y: handleLength + transitionLen/2),
        controlPoint2: CGPoint(x: -bladeThickness/2, y: handleLength + transitionLen/2))
    path.addLineToPoint(CGPoint(x: -bladeThickness/2, y:lengthWithoutCap)) // up to the top
    
    // we're at the top now. Put a cap on the end
    path.addArcWithCenter(CGPoint(x:0,y:lengthWithoutCap), radius: bladeThickness/2, startAngle: CGFloat(M_PI), endAngle: 0, clockwise: false)
    
    // and back down
    path.addLineToPoint(CGPoint(x: bladeThickness/2, y:handleLength + transitionLen)) // down to where we start to curve in
    path.addCurveToPoint(CGPoint(x:handleThickness/2, y:handleLength), // curve out to the blade
        controlPoint1: CGPoint(x: bladeThickness/2, y: handleLength + transitionLen/2),
        controlPoint2: CGPoint(x: handleThickness/2, y: handleLength + transitionLen/2))
    
    path.addLineToPoint(CGPoint(x: handleThickness/2, y:0)) // down the handle
    path.addLineToPoint(CGPoint(x: 0, y:0)) // back left to the center
    
    return path.CGPath
}

enum ProgressInRange {
    case Before
    case During(CGFloat)
    case After
}

func progressInRange<T:IntervalType where T.Bound == Double>(r:T, t:T.Bound)->ProgressInRange {
    if t < r.start {
        return .Before
    } else if r ~= t {
        let progress = CGFloat((t - r.start) / (r.end -  r.start))
        return .During(progress)
    } else {
        return .After
    }
}


