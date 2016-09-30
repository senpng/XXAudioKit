//
//  XXAudioWaveView.swift
//

import UIKit

let kDefaultIdleAmplitude: CGFloat = 0.01;

@IBDesignable
public class XXAudioWaveView: UIView {
    
    /// Define the wave's number, default is 1
    @IBInspectable public var numberOfWaves: Int = 1;
    /// Define the wave's background color
    @IBInspectable public var waveColor: UIColor = UIColor.redColor();
    /// Define the wave's width
    @IBInspectable public var waveWidth: CGFloat = 1.0;
    /// Define the wave's amplitude, default is 1.0
    @IBInspectable public var amplitude: CGFloat = 1.0;
    /// Define the wave's density, default is 1.0
    @IBInspectable public var density: CGFloat = 1.0;
    /// Define the wave's frequency, default is 2.0
    @IBInspectable public var frequency: CGFloat = 2.0;
    
    /// Define the wave's phaseShift, default is -0.15
    @IBInspectable public var phaseShift: CGFloat = -0.15;
    /// Define the wave's phase, default is 0.0
    @IBInspectable public var phase: CGFloat = 0.0;
    
    public func updateWithLevel(level: CGFloat) {
        phase = phase + phaseShift;
        amplitude = fmax(level, kDefaultIdleAmplitude);
        
        setNeedsDisplay();
    }
    
    override public func drawRect(rect: CGRect) {
        
        guard let ctx = UIGraphicsGetCurrentContext() else {
            return;
        }
        CGContextClearRect(ctx, rect);
        
        backgroundColor?.set();
        CGContextFillRect(ctx, rect);
        
        for i in 0..<numberOfWaves {
            
            CGContextSetLineWidth(ctx, waveWidth);
            
            let halfHeight = CGRectGetHeight(rect) / 2.0;
            let width = CGRectGetWidth(rect);
            let mid = width / 2.0;
            
            let maxAmplitude = halfHeight - 4.0;
            
            let progress = 1.0 - CGFloat(i) / CGFloat(numberOfWaves);
            let normedAmplitude = (1.5 * progress - 0.5) * amplitude
            
            let multiplier = min(1.0, (progress / 3.0 * 2.0) + (1.0 / 3.0));
            waveColor.colorWithAlphaComponent(multiplier * CGColorGetAlpha(waveColor.CGColor)).set()
            
            for x in CGFloat(0.0).stride(to: (width + density), by: density) {
                
                let scaling = -pow(1 / mid * (x - mid), 2) + 1;
                let y = scaling * maxAmplitude * normedAmplitude * CGFloat(sinf(Float(CGFloat(2.0) * CGFloat(M_PI) * (x / width) * frequency + phase))) + halfHeight;
                
                if x == 0 {
                    CGContextMoveToPoint(ctx, x, y);
                } else {
                    CGContextAddLineToPoint(ctx, x, y);
                }
            }
            
            CGContextStrokePath(ctx);
        }
    }
    
}
                         