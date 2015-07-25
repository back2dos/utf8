package;

import haxe.io.Bytes;
import haxe.Timer;
import haxe.unit.TestCase;
import haxe.unit.TestRunner;
import haxe.Utf8;

class Main extends TestCase {
  static function test() {
    var t = new TestRunner();
    t.add(new Main());
    t.run();
  }
  
  static function aseq(upto:Int, ?shift = 1) 
    return [for (i in 0...upto) 1 + (i << shift)];

  static function seq(upto:Int, ?shift = 1) {
    var u = new Utf8(upto);
    
    for (c in aseq(upto, shift)) 
      u.addChar(c);
      
    return u.toString();
  }
  
  function testIter() {
    var total = 0x1000;
    var s = seq(total, 5);//0x1000 << 5 is 0x20000, and thus beyond BMP which ends at U+FFFF
    var a = aseq(total, 5);
    var i = 0;
    
    Utf8.iter(s, function (c) {
      assertEquals(a[i++], c);
    });
    assertEquals(total, i);
    
  }
  
  function testCodec() {
    
    var ascii = {
      var buf = new StringBuf();
      for (i in 0...0x100)
        buf.addChar(i);
      buf.toString();
    };
    
    var utf8 = Utf8.encode(ascii);
    
    assertEquals(ascii.length, Utf8.length(utf8));
    
    var i = 0;
    
    Utf8.iter(utf8, function (c) {
      assertEquals(ascii.charCodeAt(i++), c);
    });
    
    assertEquals(0x100, i);
    
    assertEquals(ascii, Utf8.decode(utf8));
  }
  
  function testCompare() {
    var str = "あéい";
    var buf = new Utf8();
    
    buf.addChar(0x3042);
    buf.addChar(0xE9);
    buf.addChar(0x3044);
    
    assertEquals(str, buf.toString());
    
    assertEquals(0, Utf8.compare(Utf8.sub(str, 0, 3), str));
    assertEquals(0, Utf8.compare(Utf8.sub(str, 0, 2), "あé"));
    assertEquals(0, Utf8.compare(Utf8.sub(str, 1, 2), "éい"));
    assertEquals(0, Utf8.compare(Utf8.sub(str, 0, 0), ""));
    assertEquals(0, Utf8.compare(Utf8.sub(str, 1, 0), ""));
    
  }
  
  function testCharAt() {
    var i = 0,
        total = 0x200;
        
    var s = seq(total, 8);
    
    Utf8.iter(s, function (c) {
      assertEquals(c, Utf8.charCodeAt(s, i++));
    });
    
    assertEquals(total, i);
  }
  
  function testSub() {
    var total = 0x1000;
    var s = seq(total, 5);
    
    for (window in [256, 257, 791, 1034]) {//Fairly chosen by dice roll ;)
      function measure(from:Int)
        return Utf8.length(Utf8.sub(s, from, window));
      
      for (i in 0...window)  
        assertEquals(i, measure(total-i));
      
      for (start in 0...total-window) {
        assertEquals(window, measure(start));
      }
      
    }      
  }
  
  static function main() {
    test();
    benchmark();
  }
  
  static function benchmark() {
    var count = 10000;
    
    for (s in [seq(100), seq(200)]) {
      trace('old iter');
      Timer.measure(function () for (_ in 0...count) OldUtf8.iter(s, function (_) {}));
      trace('new iter');
      Timer.measure(function () for (_ in 0...count) Utf8.iter(s, function (_) { } ));
      
      trace('old bad loop');
      Timer.measure(function () for (_ in 0...count) for (i in 0...OldUtf8.length(s)) OldUtf8.charCodeAt(s, i));      
      trace('new bad loop');
      Timer.measure(function () for (_ in 0...count) for (i in 0...haxe.Utf8.length(s)) Utf8.charCodeAt(s, i));
      
      var s2 = s.substr(0, s.length - 1) + s.charAt(s.length - 1);
      trace('old compare');
      Timer.measure(function () for (_ in 0...count) OldUtf8.compare(s, s2));      
      trace('new compare');
      Timer.measure(function () for (_ in 0...count) Utf8.compare(s, s2));
    }
  }
  
}