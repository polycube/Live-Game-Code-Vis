package name.fraser.neil.plaintext
{
/**
   * Class representing one patch operation.
   */
  public class Patch {
    public var diffs:Array; // LinkedList<Diff> diffs;
    public var start1:int;
    public var start2:int;
    public var length1:int;
    public var length2:int;

    /**
     * Constructor.  Initializes with an empty list of diffs.
     */
    public function Patch() {
      this.diffs = new Array();// LinkedList<Diff>();
    }

    /**
     * Emmulate GNU diff's format.
     * Header: @@ -382,8 +481,9 @@
     * Indicies are printed as 1-based, not 0-based.
     * @return The GNU diff string.
     */
    public function toString():String {
      var coords1:String, coords2:String;
      if (this.length1 == 0) {
        coords1 = this.start1 + ",0";
      } else if (this.length1 == 1) {
        coords1 = ""+(this.start1 + 1);
      } else {
        coords1 = (this.start1 + 1) + "," + this.length1;
      }
      if (this.length2 == 0) {
        coords2 = this.start2 + ",0";
      } else if (this.length2 == 1) {
        coords2 = "" + (this.start2 + 1);
      } else {
        coords2 = (this.start2 + 1) + "," + this.length2;
      }
      //StringBuilder text = new StringBuilder();
      var text:String = "";
      text = text.concat("@@ -").concat(coords1).concat(" +").concat(coords2)
          .concat(" @@\n");
      // Escape the body of the patch with %xx notation.
      for each (var aDiff:Diff in this.diffs) {
        switch (aDiff.operation) {
        case Operation.INSERT:
          text = text.concat('+');
          break;
        case Operation.DELETE:
          text = text.concat('-');
          break;
        case Operation.EQUAL:
          text = text.concat(' ');
          break;
        }
        try {
//          text.concat(URLEncoder.encode(aDiff.text, "UTF-8").replace('+', ' '))
//              .concat("\n");
			var pattern:RegExp = new RegExp("%20", "g");
			text = text.concat(escape(aDiff.text).replace(pattern, ' ')).concat("\n");
        } catch (e) { // UnsupportedEncodingException e) {
          // Not likely on modern system.
          throw new Error("This system does not support UTF-8.", e);
        }
      }
      return unescapeForEncodeUriCompatability(text.toString());
    }
    
      function unescapeForEncodeUriCompatability(str:String):String {
  	    var pat21:RegExp = new RegExp("%21", "g");
  	    var pat7E:RegExp = new RegExp("%7E", "g");
  	    var pat27:RegExp = new RegExp("%27", "g");
  	    var pat28:RegExp = new RegExp("%28", "g");
  	    var pat29:RegExp = new RegExp("%29", "g");
  	    var pat3B:RegExp = new RegExp("%3B", "g");
  	    var pat2F:RegExp = new RegExp("%2F", "g");
  	    var pat3F:RegExp = new RegExp("%3F", "g");
  	    var pat3A:RegExp = new RegExp("%3A", "g");
  	    var pat40:RegExp = new RegExp("%40", "g");
  	    var pat26:RegExp = new RegExp("%26", "g");
  	    var pat3D:RegExp = new RegExp("%3D", "g");
  	    var pat2B:RegExp = new RegExp("%2B", "g");
  	    var pat24:RegExp = new RegExp("%24", "g");
  	    var pat2C:RegExp = new RegExp("%2C", "g");
  	    var pat23:RegExp = new RegExp("%23", "g");
  	    
	    return str.replace(pat21, "!").replace(pat7E, "~")
	        .replace(pat27, "'").replace(pat28, "(").replace(pat29, ")")
	        .replace(pat3B, ";").replace(pat2F, "/").replace(pat3F, "?")
	        .replace(pat3A, ":").replace(pat40, "@").replace(pat26, "&")
	        .replace(pat3D, "=").replace(pat2B, "+").replace(pat24, "$")
	        .replace(pat2C, ",").replace(pat23, "#");
	  }
  }
}