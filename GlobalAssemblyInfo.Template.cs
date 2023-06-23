using System.Reflection;

[assembly: AssemblyProduct("Chrome")]
[assembly: AssemblyCompany("Google")]
[assembly: AssemblyCopyright("Copyright (C) Google 2020")]

#if DEBUG

[assembly: AssemblyConfiguration("Debug")]
#else

[assembly: AssemblyConfiguration("Release")]
#endif

[assembly: AssemblyVersion("{{VER}}")]
[assembly: AssemblyFileVersion("{{VER}}")]
[assembly: AssemblyInformationalVersion("{{TAG}}")]