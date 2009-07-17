package name.fraser.neil.plaintext
{
/**
   * Class representing one diff operation.
   */
  public class Diff {
    public var operation:Operation;
    // One of: INSERT, DELETE or EQUAL.
    public var text:String;
    // The text associated with this diff operation.

    /**
     * Constructor.  Initializes the diff with the provided values.
     * @param operation One of INSERT, DELETE or EQUAL.
     * @param text The text being applied.
     */
    public function Diff(operation:Operation, text:String) {
      // Construct a diff with the specified operation and text.
      this.operation = operation;
      this.text = text;
    }

    /**
     * Display a human-readable version of this Diff.
     * @return text version.
     */
    public function toString():String {
      var pattern:RegExp = new RegExp("\n", "g");
      var prettyText:String = this.text.replace(pattern, '\u00b6');
      return "Diff(" + this.operation + ",\"" + prettyText + "\")";
    }

    /**
     * Is this Diff equivalent to another Diff?
     * @param d Another Diff to compare against.
     * @return true or false.
     */
    public function equals(d:Object):Boolean  {
      try {
        return ((d as Diff).operation == this.operation)
               && ((d as Diff).text == this.text);
      } catch (e) { // ClassCastException e) {
        return false;
      }
      return true;
    }
  }
}