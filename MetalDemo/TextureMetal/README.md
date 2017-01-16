
# 这一个Demo主要是实现了纹理的添加，以及使用MetalKit将正方体画到MTKView上，不用单独再设置MetalLayer
# 将Render渲染方法单独写成一个类，遵守MTKViewDelegate代理协议，新建一个继承于MTKView的子类，调用Render

[注：将Main.Storyboard中的View改为自己创建的继承于MTKView的子类]

#渲染步骤在以下代理方法中实现

[public func draw(in view: MTKView)]
