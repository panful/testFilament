# Filament学习记录

## 一、Filament 编译
```
cmake .. -DFILAMENT_SUPPORTS_VULKAN=ON
cmake build .
cmake --install . --config debug
```
## 二、使用 Filament
设置环境变量`Filament_DIR`，该环境变量就是编译 Filament 时的 install 目录

## 三、Filament 中的自定义类型说明
### 1. Window
为渲染提供一个上下文和显示目标，与`SwapChain`绑定，`Renderer`使用这个`SwapChain`作为渲染目标。
### 2. View
视图或视口，关联一个相机，会持有一个或多个光源、渲染参数（清除色、渲染模式等）以及场景内容(Scene)
### 3. Renderer
渲染过程的管理者，协调所有渲染组件并与GPU通信，使用`SwapChain`对`View`进行渲染，通过`beginFrame() endFrame()`进行显示缓冲的切换。
```C++
renderer->beginFrame(swapChain);
renderer->render(view);
renderer->endFrame();
```
### 4. Scene
持有所有需要被渲染对象的容器，包括`Entity Light` 
### 5. Renderable
定义了实体的几何信息（网格、顶点缓冲）、材质、包围盒等。

## 四、FrameGraph
是`Renderer`的内部工具，Renderer调用FrameGraph来定义和调度复杂的渲染管线步骤。View、Scene、Renderable 提供具体的渲染内容，FrameGraph负责高效地渲染这些内容。

Scene 将 Drawable 传递给 RenderPassBuilder，然后利用 RenderPassBuilder 创建一个 RenderPass("Color Pass")，在这个 RenderPass 中将 Primitive 的绘制命令添加到 Command 中，最后在 "Color Pass" 的 Execute 中异步执行这段绘制命令。
## 五、源码
### 1. 关键类
```
class Engine {
  mDriverThread(std::thread) // 执行 FEngine::loop，从 mCommandBufferQueue 获取一个 buffer 并执行
  mJobSystem(JobSystem)
  mDriver(Driver) // 在 FEngine::loop 中由 mPlatform 创建一个指定的后端(VK GL)
}
class VulkanDriver : DriverBase {
  mServiceThread(std::thread) // 为用户回调提供服务
  mPlatform(VulkanPlatform) // 通过 pimpl 管理 VkInstance VkPhysicalDevice VkDevice VkQueue QueueIndex 等
  mCommands(VulkanCommands) // 10个 VulkanCommandBuffer
  mPipelineCache(VulkanPipelineCache) // 管理渲染管线
  mDescriptorSetManager(VulkanDescriptorSetManager) // 管理描述符集
}
class JobSystem {
  mThreadStates // 内部有一个 std::thread 用来执行 JobSystem::loop
  class Job {
    function // void(*)(void*, JobSystem&, Job*) 函数指针，线程执行的任务
  }
}
class VulkanCommandBuffer {
  mBuffer(VkCommandBuffer)
  mPipeline(VkPipeline)
}
class RenderPass {
  class Executor {
    mCommands(utils::Slice<Command>)
  }
  class PrimitiveInfo {
    Vertex
    Index
    IndexCount
    Material
    PrimitiveType
    InstanceCount
    hasSkinning
    hasMorphing
    // ...
  }
}
```
### 2. 子线程
`FEngine::loop()->FEngine::execute()`执行`mCommandBufferQueue(CommandBufferQueue)`中的命令
`CommandBufferQueue::waitForCommands()`将`mCommandBuffersToExecute`中的命令移动到`mCommandBufferQueue`
### 3. 主线程
`CommandBufferQueue::flush()`将`mCircularBuffer`命令的开始和结尾添加到`mCommandBuffersToExecute`
`CommandStream::allocateCommand`将命令保存到`CommandStream::mCurrentBuffer`（`CommandStream::mCurrentBuffer`就是`mCircularBuffer`，`CommandStream`别名是`DriverApi`），调用`CommandStream`中宏定义的函数(DriverAPI.inc)，宏定义会调用`CommandStream::allocateCommand`
### 4. DriverAPI.inc
`DriverAPI.inc`中使用了大量的宏替换操作，将设备接口进行封装或打包。在 `CommandStream.h Driver.h(OpenGLDriver.h VulkanDriver.h)`中对这个文件都进行了`include`，`CommandStream.h`通过`placement new`在`CommandStream::mCurrentBuffer`上添加一个命令，`Driver.h`负责执行GPU命令。
### 5. Samples 的 Run() 函数调用
```
Run()
  创建窗口 Window
    创建引擎 FEngine
      JobSystem 是 FEngine 的成员，JobSystem::loop JobSystem::execute JobSystem::finish
      FEngine::create 创建线程并执行 FEngine::loop 
    创建 SwapChain
    创建 Renderer
  创建深度材质 DepthMaterial
  创建透明材质 TransparentMaterial
  创建场景 Scene
  LoadDirt()
  LoadIBL()
  执行回调函数 setupCallback => Vertex Index Material 
  while(!window_closed) 窗口事件循环
    events...
    CameraManipulator::update()
    FilamentApp::Window::getRenderer()
    Renderer::beginFrame(FilamentApp::Window::getSwapChain())
      SwapChain::makeCurrent()
      Driver::updateStreams()
      Driver::tick()
      Driver::beginFrame()
      Engine::prepare()
      Engine::flush()
    Renderer::render(View)
      Renderer::renderJob()
        View::prepare()
        FrameGraph::addPass() ...
        FrameGraph::forwardResource()
        FrameGraph::present()
        FrameGraph::compile()
        FrameGraph::execute()
      Engine::flush()
      JobSystem::runAndWait()
    Renderer::endFrame()
      SwapChain::commit()
      Driver::endFrame()
      Driver::tick()
      Engine::flush()
      JobSystem::runAndWait()
```
