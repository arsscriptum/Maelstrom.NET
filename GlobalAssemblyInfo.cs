using System.Reflection;

[assembly: AssemblyProduct("Chrome")]
[assembly: AssemblyCompany("Google")]
[assembly: AssemblyCopyright("Copyright (C) Google 2020")]

#if DEBUG

[assembly: AssemblyConfiguration("Debug")]
#else

[assembly: AssemblyConfiguration("Release")]
#endif

[assembly: AssemblyVersion("1.0.0.38")]
[assembly: AssemblyFileVersion("1.0.0.38")]
[assembly: AssemblyInformationalVersion("v1.0.0-38-g7889971")]