package haxe;

@:coreApi class Utf8 {

  var __b:StringBuf;

  public function new(?size:Int)
    __b = new StringBuf();

  public inline function addChar(c:Int):Void 
    if (c < 0x80)
      __b.addChar(c);
    else
      addComplex(c);
        
  function addComplex(c:Int):Void {
    var bound = 0x800,
        num = 1;
    while (c >= bound) {
      num++;
      bound <<= 5;
      if (bound < 0) break;
    }
    __b.addChar(c >> 6 * num | @:privateAccess Utf8Iterator.thresholds[num - 1]);
    while (num > 0)
      __b.addChar((c >> (--num * 6) & 0x3F) | 0x80);
  }
  
  public inline function toString():String 
    return __b.toString();
  
  static public inline function iter(s:String, chars:Int->Void):Void
    for (c in new Utf8Iterator(s))
      chars(c);

  static public function encode(s:String):String {
    var ret = new Utf8();
    for (i in 0...s.length)
      ret.addChar(StringTools.fastCodeAt(s, i));
    return ret.toString();
  }

  static public function decode(s:String):String {
    var buf = new StringBuf();
    for (c in new Utf8Iterator(s))
      buf.addChar(c);
    return buf.toString();
  }

  static public function charCodeAt(s:String, index:Int):Int {
    for (c in new Utf8Iterator(s))
      if (index-- == 0) 
        return c;
    return -1;
  }

  static public inline function validate(s:String):Bool {
    for (c in new Utf8Iterator(s))
      if (c == -1) 
        return false;
    
    return true;
  }

  static public inline function length(s:String):Int {
    var ret = 0;
    for (_ in new Utf8Iterator(s)) ret++;
    return ret;
  }

  static public function compare(a:String, b:String):Int {
    return Reflect.compare(a, b);
    /**
     * Because of utf8's structure, strings can be compared normally.
     * 
     * Consider the following:
     * 
     * If two characters require the same amount of bytes for encoding, 
     * then bytewise comparison will lead to the right result, 
     * because utf8 has its payload bits ordered in "big endian like" manner.
     * 
     * If two characters require different amounts of bytes, 
     * then the character that requires more bytes is also the one with the greater code point,
     * and also the one who's first byte as the most consecutive leading bits set.
     * Therefore bytewise comparison will determine it to be greater just after the first byte.
     * 
     * For what it's worth, one can still go through the trouble of decoding code points like so:
     * 
     *   var a = new Utf8Iterator(a),
     *       b = new Utf8Iterator(b);
     *       
     *   while (true) 
     *     switch [a.hasNext(), b.hasNext()] {
     *       case [false, false]: return 0;
     *       case [true, false]: return 1;
     *       case [false, true]: return -1;
     *       default:
     *         switch a.next() - b.next() {
     *           case 0:
     *           case v: return v;
     *         }
     *     }
     *   
     *   return 0;
     */
  }

  static public function sub(s:String, pos:Int, len:Int):String {
    var i = new Utf8Iterator(s);
        
    while (pos-- > 0)
        if (i.hasNext()) i.next();
      else return '';
    
    var start = i.pos;
    
    while (len-- > 0)
        if (i.hasNext()) i.next();
      else return s.substr(start);
    
    return s.substring(start, i.pos);
    
  }

}

class Utf8Iterator {
    public var s(default, null):String;
    public var pos(default, null):Int = 0;
    
    var len:Int;
    
    public function new(s) {
      this.s = s;
      this.len = s.length;
    }
    
    public inline function hasNext() return pos < len;
    public inline function next():Int {
      var c = StringTools.fastCodeAt(s, pos++);
      return
        if (c < 0x80) c;
        else complexChar(c); 
    } 
    
    static var thresholds = {
			var p = 0x80;
      [for (i in 0...6) p = p >> 1 | p];
    }
    
    function complexChar(firstByte:Int) {
        
      inline function next()
        return StringTools.fastCodeAt(s, pos++);
            
      return        
        if (firstByte < thresholds[0]) -1;
        else {   
          var c = -1;
          for (t in 1...thresholds.length) 
            if (firstByte < thresholds[t] && firstByte >= thresholds[t-1]) {
              
              c = firstByte ^ thresholds[t-1];
              for (_ in 0...t)
                c = (c << 6) | (next() & 0x3F);
              break;
            }
              
          c;
        }
        
        
    }
}