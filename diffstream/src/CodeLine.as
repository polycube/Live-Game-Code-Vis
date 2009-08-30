package  
{
	
	/**
	 * ...
	 * @author Anna Zajaczkowski
	 */
	public class CodeLine 
	{
		public static var equal:uint = 0;
		public static var inserted:uint = 1;
		public static var deleted:uint = 2;
		
		public var chars:Array;
		public var type:uint = equal;
		
		public function CodeLine() 
		{
			chars = new Array();
		}
		
		public function get lineLength():uint
		{
			return chars.length;
		}
		
	}
	
}