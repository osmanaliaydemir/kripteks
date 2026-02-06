using System;
using Binance.Net.Objects.Options;
using System.Reflection;

public class Diagnostic {
    public static void Main() {
        var props = typeof(BinanceRestOptions).GetProperties();
        Console.WriteLine("Available Properties in BinanceRestOptions:");
        foreach(var p in props) Console.WriteLine("- " + p.Name);
    }
}
