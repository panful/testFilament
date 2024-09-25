
#include <filament/Engine.h>
#include <iostream>

int main()
{
    filament::Engine* engine = filament::Engine::create();

    std::cout << engine << '\n';

    filament::Engine::destroy(&engine);
}
