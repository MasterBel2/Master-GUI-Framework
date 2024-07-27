# File Loading

MasterFramework has 3 file load stages, that load in the following order: `Utils`, `Framework`, and `Constants`. `Utils` & `Framework` automatically load all files with no guarantee about load order, while `Constants` is loaded in a manually specified order to allow for dependencies. All are loaded with the same environment.