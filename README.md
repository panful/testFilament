# Filament学习记录

## Filament 编译
```
cmake .. -DFILAMENT_SUPPORTS_VULKAN=ON
cmake build .
cmake --install . --config debug
```
## 使用 Filament
设置环境变量`Filament_DIR`，该环境变量就是编译 Filament 时的 install 目录
