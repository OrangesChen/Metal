
import MetalKit

public class EIView: MTKView {
    
    var renderer: MTKViewDelegate!

    required public init(coder: NSCoder) {

        super.init(coder: coder)

        device = MTLCreateSystemDefaultDevice()!
//
//        arcBall = AddGesture.init(viewBounds: bounds)
//
//        addGestureRecognizer(UIPanGestureRecognizer.init(
//            target: arcBall,
//            action: #selector(AddGesture.arcBallPanHandler)))

    }
}
