package name.fraser.neil.plaintext
{
	public class Operation
	{
	   /**-
	   * The data structure representing a diff is a Linked list of Diff objects:
	   * {Diff(Operation.DELETE, "Hello"), Diff(Operation.INSERT, "Goodbye"),
	   *  Diff(Operation.EQUAL, " world.")}
	   * which means: delete "Hello", add "Goodbye" and keep " world."
	   */
		public static var DELETE:Operation = new Operation("DELETE");
		public static var INSERT:Operation = new Operation("INSERT");
		public static var EQUAL:Operation = new Operation("EQUAL");
		
		private var value:String;
		
		public function Operation(value:String)
		{
			this.value = value;
		}
		
		public function toString():String {
			return value;
		}

	}
}